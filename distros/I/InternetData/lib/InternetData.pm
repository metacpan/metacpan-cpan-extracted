package InternetData;

use strict;
use warnings;

use Carp ();
use Mojo::IOLoop;
use Mojo::Promise;
use Mojo::URL;
use Mojo::UserAgent;
use Scalar::Util ();

use InternetData::Database;
use InternetData::Error;

our $VERSION = '1.3.0';

use constant DEFAULT_BASE_URL => 'https://internetdata.io';

my %OPTIONS = map { $_ => 1 } qw(api_key base_url retries timeout ua);

sub new {
    my ($class, %args) = @_;
    my @unknown = sort grep { !$OPTIONS{$_} } keys %args;
    Carp::croak("InternetData->new: unknown option(s): @unknown") if @unknown;

    my $retries = defined $args{retries} ? $args{retries} : 2;
    Carp::croak('InternetData->new: retries cannot be negative') if $retries < 0;

    my $self = bless {
        api_key => $args{api_key},
        base_url => _base_url($args{base_url}),
        retries => $retries,
        ua => $args{ua} || Mojo::UserAgent->new,
    }, $class;

    # Mojo::UserAgent does not follow redirects by default, but MOJO_MAX_REDIRECTS
    # in the environment turns that on for every agent in the process. Setting it
    # here is what stops a download's 302 being chased into a multi-gigabyte
    # transfer, on a machine whose environment we do not own.
    $self->{ua}->max_redirects(0);
    $self->{ua}->request_timeout(defined $args{timeout} ? $args{timeout} : 30);
    $self->{ua}->transactor->name("internetdata-perl/$VERSION");
    return $self;
}

# The licensed database downloads, which is every call this API has. Built per
# call rather than held, so the client and its sub-API never form a reference
# cycle.
sub database {
    my ($self) = @_;
    return InternetData::Database->_new($self);
}

# One file transfer. Every chunk is handed to $on_chunk and none is kept, so a
# body costs the same in memory whether it is 264 bytes or 5.34 GiB. Resolves
# with the number of bytes handed over.
sub _stream_p {
    my ($self, $url, $on_chunk) = @_;
    # Built here rather than through _get_p, which is the only place the API key
    # is ever attached: the presigned link authorizes itself, so carrying the key
    # would hand it to a host with no business holding it. Object storage answers
    # 400 to a presigned GET that also carries an Authorization header, so this
    # is not merely a leak - it breaks the download too.
    my $tx = $self->{ua}->build_tx(GET => $url);

    # Mojo asks for gzip on every request it builds. A published file is already
    # compressed, so the only thing that would buy is a Content-Length counting
    # bytes that never reach the sink, and that length is the only evidence the
    # transfer arrived whole.
    $tx->req->headers->remove('Accept-Encoding');
    # Mojo aborts a response past max_message_size, counting every byte it parses
    # whether or not it keeps any of them. Mojo::Message::Response defaults to
    # 2 GiB, which the catalog is already past, and MOJO_MAX_MESSAGE_SIZE lowers
    # it for every response in the process, on a machine whose environment we do
    # not own.
    $tx->res->max_message_size(0);

    my $received = 0;
    # Unsubscribing Mojo's own reader is what stops the body being collected into
    # the message. The subscriber hangs off the transaction, so holding the
    # transaction strongly inside it would be a cycle the interpreter never
    # collects; the user agent keeps it alive for as long as bytes are arriving.
    my $weak = $tx;
    Scalar::Util::weaken($weak);
    $tx->res->content->unsubscribe('read')->on(read => sub {
        my (undef, $bytes) = @_;
        # An error body is neither written out nor held: the status is what
        # separates a lapsed link from a refused one, and nothing bounds the size
        # of what a storage host puts in the body of a refusal.
        return unless $weak && ($weak->res->code || 0) == 200;
        $received += length $bytes;
        $on_chunk->($bytes);
    });

    return $self->_start_untimed_p($tx)->then(sub {
        my $res = shift->res;
        # No body to read: the handler above kept nothing that was not a 200,
        # because nothing bounds the size of what a storage host puts in a
        # refusal. So the message names where the refusal came from, and the
        # status still decides the kind - which is what says whether the link
        # lapsed or was never good.
        die InternetData::Error->from_response(
            $res->code, $res->headers, undef,
            'object storage refused the download link with status ' . $res->code,
        ) unless $res->code == 200;

        # A body that stops early reaches Perl as an ordinary end of stream: the
        # status was 200 and Mojo reports no error, so without this a half
        # transfer is a short file nobody notices.
        my $declared = $res->headers->content_length;
        die InternetData::Error->new(
            kind => 'network',
            message => "the transfer ended after $received of $declared bytes",
        ) if defined $declared && length $declared && $declared != $received;
        return $received;
    });
}

# request_timeout bounds the WHOLE response and Mojo::UserAgent has no
# per-transaction form of it, so the 30 seconds that is right for a metadata call
# is wrong for a gigabyte. It is lifted only across the hand-over: start_p reaches
# the agent synchronously, so no other request can be started inside the window.
sub _start_untimed_p {
    my ($self, $tx) = @_;
    my $ua = $self->{ua};
    my $bound = $ua->request_timeout;
    $ua->request_timeout(0);
    my $promise = eval { $ua->start_p($tx) };
    my $failed = $@;
    $ua->request_timeout($bound);
    die InternetData::Error->wrap($failed) unless $promise;
    return $promise->catch(sub {
        die InternetData::Error->new(kind => 'network', message => "$_[0]");
    });
}

# Recurses through $self rather than through a self-referential closure, which
# in Perl would be a reference cycle the interpreter never collects.
sub _retry_p {
    my ($self, $left, $attempt) = @_;
    return $attempt->()->catch(sub {
        my $error = InternetData::Error->wrap(shift);
        die $error if $left <= 0 || !$error->retryable;
        # A server-supplied delay is honored with a TIMER, never a sleep: this
        # promise may share an event loop with a Mojolicious application, and
        # sleeping here would stall every other thing on it.
        return Mojo::Promise->timer($error->retry_after || 0)
            ->then(sub { $self->_retry_p($left - 1, $attempt) });
    });
}

sub _json_p {
    my ($self, $url) = @_;
    return $self->_get_p($url)->then(sub {
        my $res = shift->res;
        die InternetData::Error->from_response($res->code, $res->headers, $res->json)
            unless $res->is_success;
        my $body = $res->json;
        die InternetData::Error->new(
            kind => 'server_error', status => $res->code,
            message => 'the API did not answer with a JSON object',
        ) unless ref $body eq 'HASH';
        return $body;
    });
}

# Mojo::UserAgent rejects with a plain string when the request never got far
# enough to have a status, which is exactly the transport failure the retry rule
# treats as worth another attempt.
sub _get_p {
    my ($self, $url) = @_;
    return $self->{ua}->get_p($url => $self->_headers)->catch(sub {
        die InternetData::Error->new(kind => 'network', message => "$_[0]");
    });
}

sub _headers {
    my ($self) = @_;
    my %headers = (Accept => 'application/json');
    # One scheme. The v1 endpoints on this same host take `?apikey=` with a
    # different key vocabulary, so sending a v2 key that way would make it look
    # plausible on the version it does not belong to, and query strings end up in
    # logs. An empty key counts as none at all: that is what an unset
    # `${{ secrets.X }}` interpolates to, and `Bearer ` is a worse answer than no
    # header.
    $headers{Authorization} = "Bearer $self->{api_key}"
        if defined $self->{api_key} && length $self->{api_key};
    return \%headers;
}

sub _url {
    my ($self, $path, %query) = @_;
    my $url = Mojo::URL->new($self->{base_url} . $path);
    $url->query(%query) if %query;
    return $url;
}

sub _wait {
    my ($self, $promise) = @_;
    my ($value, $error, $failed);
    $promise->then(sub { $value = shift }, sub { ($error, $failed) = (shift, 1) })->wait;
    die $error if $failed;
    return $value;
}

# Checked BEFORE the promise is built, not after: Mojo::UserAgent starts a
# transaction as soon as one is created, so croaking later would still have spent
# a request from the caller's allowance.
sub _assert_blocking_ok {
    my ($self, $method) = @_;
    return unless Mojo::IOLoop->is_running;
    Carp::croak(
        "InternetData::$method cannot block inside a running Mojo::IOLoop; "
        . "call ${method}_p instead, which returns a Mojo::Promise"
    );
}

sub _check_options {
    my ($self, $method, $options, @allowed) = @_;
    my %allowed = map { $_ => 1 } @allowed;
    my @unknown = sort grep { !$allowed{$_} } keys %$options;
    Carp::croak("InternetData::$method: unknown option(s): @unknown") if @unknown;
}

sub _base_url {
    my ($url) = @_;
    $url = DEFAULT_BASE_URL unless defined $url && length $url;
    $url =~ s{/+\z}{};
    return $url;
}

1;

__END__

=head1 NAME

InternetData - the official Perl client for the InternetData API

=head1 SYNOPSIS

    use InternetData;

    my $client = InternetData->new(api_key => $ENV{INTERNETDATA_API_KEY});

    for my $db (@{ $client->database->list }) {
        next unless $db->{standing} eq 'licensed';
        my $id = $db->{versions}[-1]{id};
        $client->database->download($id, 'csvgz', "./$id.csv.gz");
    }

=head1 DESCRIPTION

Downloads InternetData's licensed IP and network databases, and reads what the
API publishes about them: the catalog, per-database metadata, checksums, and
your organization's recent download attempts.

Every endpoint published today needs a key carrying the C<db.download> scope.
L</new> takes one as an option rather than requiring it: a client built without
a key sends no C<Authorization> header at all, which is what a database served
without a licence would need.

=head1 METHODS

The seven calls live on L<InternetData::Database>, reached as L</database>.
Each has a C<_p> twin returning a L<Mojo::Promise> and takes a per-call
C<retries> option. Failures die with an L<InternetData::Error>.

=head2 new

    my $client = InternetData->new(api_key => '...', %options);

=over 4

=item api_key

A console-issued key carrying the C<db.download> scope. Keys are default-deny,
so an existing key does not reach these endpoints until the scope is added to
it. Optional: omit it, or pass an empty string, and no C<Authorization> header
is sent. Every endpoint published today answers C<401> without one.

=item base_url

Defaults to C<https://internetdata.io>.

=item retries

Attempts after a retryable failure. Defaults to 2, and is overridable per call.

=item timeout

Per-request timeout in seconds. Defaults to 30. It is lifted for a file
transfer, which is not a request whose duration a caller can predict.

=item ua

Your own L<Mojo::UserAgent>, for a proxy or custom TLS settings. The client sets
C<max_redirects> to 0 on whichever agent it is given: the download endpoint
answers C<302> and that redirect is the answer, so following it would pull a
multi-gigabyte file into memory.

=back

=head2 database

    my $databases = $client->database->list;

The licensed database downloads, which is every call this API has. See
L<InternetData::Database>.

=head1 NON-BLOCKING USE

Every call has a C<_p> twin returning a L<Mojo::Promise>, so the library drops
into a Mojolicious application without a worker. The blocking forms are those
promises plus a C<wait>, so nothing is duplicated and both paths retry
identically.

    $client->database->list_p
        ->then(sub { say $_->{base} for @{ shift() } })
        ->catch(sub { warn shift })
        ->wait;

Inside an already running L<Mojo::IOLoop> the blocking forms cannot work and
croak saying so. Use the C<_p> forms there.

=head1 SEE ALSO

L<InternetData::Database>, L<InternetData::Error>.

=head1 LICENSE

MIT. Copyright Mslm Dev.

=cut
