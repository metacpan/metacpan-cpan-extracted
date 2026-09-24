package InternetData::Database;

use strict;
use warnings;

use Carp ();

use InternetData::Error;

our $VERSION = '1.6.1';

# The formats a database is published in. Anything else is refused before it
# reaches the API, whose 400 would cost a round trip and name nothing to act on.
use constant FORMATS => qw(csvgz mmdb);
my %FORMAT = map { $_ => 1 } FORMATS;

# The values `list` reports for standing and license_type, so a caller can branch
# on each without spelling the list. license_type is undef for an unlicensed family.
use constant STANDINGS => qw(licensed expired unlicensed);
use constant LICENSE_TYPES => qw(evaluation standard redistribute);

# Every database this organization may see, with where each one stands.
#
# NOT only the licensed ones: `standing` says whether a database is yours today,
# was, or has never been bought, so a caller can see what else is published
# without a sales email.
#
# What comes back is the SERVER's answer for THIS key and nothing else, so a
# listing held from one key is not an answer for another. Nothing here is cached
# for exactly that reason.
sub list {
    my $self = shift;
    $self->_assert_blocking_ok('list');
    return $self->{client}->_wait($self->list_p(@_));
}

sub list_p {
    my ($self, %options) = @_;
    return $self->_body_p('list', \%options, '/api/v2/database/list')
        ->then(sub { $_[0]->{databases} });
}

# What is inside one database: schema, sample rows, row count and per-format
# sizes. Poll it to decide whether today's build is worth fetching, and read
# `$meta->{size}{$format}` to size a transfer before starting it.
sub metadata {
    my $self = shift;
    $self->_assert_blocking_ok('metadata');
    return $self->{client}->_wait($self->metadata_p(@_));
}

sub metadata_p {
    my ($self, $id, %options) = @_;
    Carp::croak('database->metadata: expected a database id') if !defined $id || !length $id;
    return $self->_body_p('metadata', \%options, '/api/v2/database/metadata', id => $id);
}

# The digests published alongside one file.
#
# Returns the WHOLE set rather than one algorithm: which digests a database
# publishes is the API's choice, not ours, and picking one here is how a caller
# ends up holding undef against a perfectly healthy API.
sub checksums {
    my $self = shift;
    $self->_assert_blocking_ok('checksums');
    return $self->{client}->_wait($self->checksums_p(@_));
}

sub checksums_p {
    my ($self, $id, $format, %options) = @_;
    _assert_database('checksums', $id, $format);
    return $self->_body_p(
        'checksums', \%options, '/api/v2/database/checksum', id => $id, format => $format,
    )->then(sub { $_[0]->{checksums} });
}

# Your organization's recent download attempts, newest first, refusals included:
# a denial is what answers "it stopped working", and its absence answers nothing.
sub downloads {
    my $self = shift;
    $self->_assert_blocking_ok('downloads');
    return $self->{client}->_wait($self->downloads_p(@_));
}

sub downloads_p {
    my ($self, %options) = @_;
    my $limit = delete $options{limit};
    return $self->_body_p(
        'downloads', \%options, '/api/v2/database/downloads',
        defined $limit ? (limit => $limit) : (),
    )->then(sub { $_[0]->{downloads} });
}

# The time-limited URL for one file.
#
# The API answers 302 and this returns the Location without following it, so the
# caller decides how to transfer a file that can run to gigabytes. The link
# carries its own authorization, which is what makes it safe to hand to another
# process: it names no credential of yours. It authorizes the START of a
# transfer, so one already running is not interrupted when it lapses.
sub download_url {
    my $self = shift;
    $self->_assert_blocking_ok('download_url');
    return $self->{client}->_wait($self->download_url_p(@_));
}

sub download_url_p {
    my ($self, $id, $format, %options) = @_;
    _assert_database('download_url', $id, $format);
    my $client = $self->{client};
    $client->_check_options('database->download_url', \%options, 'retries', 'timeout');
    my $url = $client->_url('/api/v2/database/download', id => $id, format => $format);
    my $retries = defined $options{retries} ? $options{retries} : $client->{retries};
    return $client->_retry_p($retries, sub {
        $client->_get_p($url, $options{timeout})->then(sub {
            my $res = shift->res;
            return _location($res) if $res->code == 302;
            # A 2xx here means the user agent followed the redirect and read the
            # database into memory. Naming the cause beats reporting a shape
            # mismatch a caller cannot act on.
            die InternetData::Error->new(
                kind => 'server_error', status => $res->code,
                message => 'expected a redirect to object storage but got '
                    . $res->code . '; the user agent must not follow redirects',
            ) if $res->is_success;
            die InternetData::Error->from_response($res->code, $res->headers, $res->json);
        });
    });
}

# Stream one file to a path, and return the bytes written.
sub download {
    my $self = shift;
    $self->_assert_blocking_ok('download');
    return $self->{client}->_wait($self->download_p(@_));
}

sub download_p {
    my ($self, $id, $format, $path, %options) = @_;
    # Everything a caller can get wrong is refused before the file is opened, so
    # a mistyped id cannot leave a stray .part behind.
    _assert_database('download', $id, $format);
    $self->{client}->_check_options('database->download', \%options, 'retries');
    Carp::croak('database->download: expected a destination path')
        if !defined $path || !length $path;

    # The bytes land beside the destination and are renamed into place, so a
    # transfer that dies half way leaves no short file that reads as a whole
    # database. Opened BEFORE the request: an unwritable path costs no quota.
    my $partial = "$path.part";
    open my $handle, '>', $partial
        or Carp::croak("database->download: cannot open $partial: $!");
    binmode $handle;

    return $self->_transfer_p('download', $id, $format, \%options, sub {
        # A failure writing is the caller's to read rather than ours to retry: a
        # full disk and a reset socket are different problems.
        print {$handle} $_[0] or die "could not write the database to $partial: $!";
    })->then(sub {
        my $written = shift;
        close $handle or die "could not write the database to $partial: $!";
        rename $partial, $path or die "could not move the database into place at $path: $!";
        return $written;
    })->catch(sub {
        my $error = shift;
        close $handle;
        unlink $partial;
        die $error;
    });
}

# One file's bytes, in memory.
sub download_bytes {
    my $self = shift;
    $self->_assert_blocking_ok('download_bytes');
    return $self->{client}->_wait($self->download_bytes_p(@_));
}

sub download_bytes_p {
    my ($self, $id, $format, %options) = @_;
    _assert_database('download_bytes', $id, $format);
    my $bytes = '';
    return $self->_transfer_p('download_bytes', $id, $format, \%options, sub {
        $bytes .= $_[0];
    })->then(sub { return $bytes });
}

sub _new {
    my ($class, $client) = @_;
    return bless { client => $client }, $class;
}

# The 302 is followed as a SECOND request. `retries` covers it only until the
# first byte reaches the caller: object storage failing before that is retried
# like any 5xx, but a transfer that dies part way is not repeated, or the second
# copy would append to the bytes already written. A per-call `timeout` is refused
# rather than spent on the link call alone, where a caller would read it as
# bounding the transfer, which nothing does.
sub _transfer_p {
    my ($self, $method, $id, $format, $options, $on_chunk) = @_;
    my $client = $self->{client};
    $client->_check_options("database->$method", $options, 'retries');
    my $retries = defined $options->{retries} ? $options->{retries} : $client->{retries};
    my $delivered = 0;
    my $count = sub {
        $delivered += length $_[0];
        $on_chunk->(@_);
    };
    return $self->download_url_p($id, $format, %$options)->then(sub {
        my $url = shift;
        return $client->_retry_p($retries, sub { $client->_stream_p($url, $count) }, sub { !$delivered });
    });
}

sub _body_p {
    my ($self, $method, $options, $path, @query) = @_;
    my $client = $self->{client};
    $client->_check_options("database->$method", $options, 'retries', 'timeout');
    my $url = $client->_url($path, @query);
    my $retries = defined $options->{retries} ? $options->{retries} : $client->{retries};
    return $client->_retry_p($retries, sub { $client->_json_p($url, $options->{timeout}) });
}

sub _assert_database {
    my ($method, $id, $format) = @_;
    Carp::croak("database->$method: expected a database id") if !defined $id || !length $id;
    Carp::croak("database->$method: expected a format") if !defined $format || !length $format;
    Carp::croak("database->$method: '$format' is not a published format; expected one of "
        . join(', ', FORMATS)) unless $FORMAT{$format};
}

sub _location {
    my ($res) = @_;
    my $location = $res->headers->location;
    die InternetData::Error->new(
        kind => 'server_error', status => $res->code,
        message => 'the API redirected without a Location header',
    ) if !defined $location || !length $location;
    return $location;
}

sub _assert_blocking_ok {
    my ($self, $method) = @_;
    $self->{client}->_assert_blocking_ok("database->$method");
}

1;

__END__

=head1 NAME

InternetData::Database - the licensed database downloads

=head1 SYNOPSIS

    my $db = $client->database;

    my $databases = $db->list;
    my $id = $databases->[0]{versions}[-1]{id};      # e.g. 'bogon_ip_v1'

    my $meta = $db->metadata($id);
    my $sums = $db->checksums($id, 'mmdb');

    my $url = $db->download_url($id, 'mmdb');        # transfer it yourself
    my $bytes = $db->download_bytes('bogon_asn_v1', 'csvgz');
    my $written = $db->download($id, 'mmdb', "./$id.mmdb");

=head1 DESCRIPTION

Every call this API has, reached through L<InternetData/database>. Access is
granted by contract rather than self-serve, and needs a key carrying the
C<db.download> scope.

The downloads are the whole of this API today, so this namespace covers one
domain rather than several. It is here because the sibling L<VPNDetection>
client spells the same seven calls the same way, and a program holding both
should not have to remember which one is flat.

Every method has a C<_p> twin returning a L<Mojo::Promise>, and every method
takes a per-call C<retries> option. Every method but the two transfers also
takes a per-call C<timeout> in seconds, replacing the client's for each attempt
of that call. Failures die with an L<InternetData::Error>.

=head1 METHODS

=head2 FORMATS

    my @formats = InternetData::Database::FORMATS;    # ('csvgz', 'mmdb')

The formats a database is published in. A method taking a C<$format> croaks on
anything else before it makes a request.

=head2 STANDINGS

    my @standings = InternetData::Database::STANDINGS;    # ('licensed', 'expired', 'unlicensed')

Every C<standing> L</list> reports.

=head2 LICENSE_TYPES

    my @types = InternetData::Database::LICENSE_TYPES;    # ('evaluation', 'standard', 'redistribute')

Every C<license_type> L</list> reports. A family you hold no license for carries
C<undef> instead, which is not a member.

=head2 list

    my $databases = $client->database->list;

An array reference of the database B<families> this organization may see. A
license is held against a family, and each family carries every published
version of itself:

    {
        base => 'bogon_ip',              # what a license is held against
        name => 'Bogon IP',
        summary => 'IP ranges that cannot legitimately appear on the internet.',
        standing => 'licensed',          # licensed, expired or unlicensed
        license_type => 'standard',    # evaluation, standard, redistribute or undef
        starts => '2026-09-04T07:49:45.118Z',
        expires => undef,                # undef when the license has no end date
        renews_at => undef,              # when a rolling license next turns over
        notice_due_at => undef,          # last day to give notice for that term
        versions => [
            {
                id => 'bogon_ip_v1',     # this is what you download
                version => 1,
                summary => 'IP ranges that cannot legitimately appear on the internet.',
                formats => ['csvgz', 'mmdb'],
            },
        ],
    }

The id every other method takes is C<< $version->{id} >>, never
C<< $family->{base} >>.

=head2 metadata($id)

One database's build document: C<updated>, C<entries>, per-format C<schema>,
C<sample> and C<size>. Poll it to decide whether today's build is worth
fetching, and read C<< $meta->{size}{$format} >> to size a transfer before
starting it.

=head2 checksums($id, $format)

The whole digest set for one published file, as a hash reference keyed by
algorithm.

=head2 downloads(%options)

Your organization's recent download attempts, newest first, refusals included.
C<limit> caps the number returned.

=head2 download_url($id, $format)

A time-limited URL for one file. The API answers C<302> and this returns the
C<Location> without following it. The link carries its own authorization and
names no credential of yours, so it is safe to hand to another process; it
authorizes the START of a transfer, so one already running is not interrupted
when it lapses.

=head2 download($id, $format, $path)

Streams one file to C<$path> and returns the bytes written. Nothing beyond one
chunk is ever held, whatever the database weighs.

The bytes land in a neighboring C<.part> file that is renamed on completion, so
a transfer that dies half way leaves nothing behind that reads as a whole
database. A body that stops early is raised rather than accepted: the file is
never left short and silent.

=head2 download_bytes($id, $format)

Downloads one file and returns its bytes.

B<This holds the entire file in memory>, and the catalog spans seven orders of
magnitude, from C<bogon_asn_v1> at 264 bytes to C<resproxy_ip_14d_v1> at 5.34
GiB. Reach for it at the small end, where the bytes go straight into a parser,
and use L<download|/"download($id, $format, $path)"> for anything you have not
measured; L<metadata|/"metadata($id)"> publishes the size per format without
transferring anything, which is how you find out which end you are at.

=head1 TRANSFERS

C<download> and C<download_bytes> follow the redirect as a second request
carrying B<no credential>: the link authorizes itself, so forwarding the API key
would hand it to a host with no business holding it - and object storage answers
C<400> to a presigned GET that also carries an C<Authorization> header, so it
would break the download too.

C<retries> covers that transfer only until its first byte reaches you: object
storage failing before then is retried like any server error, but a transfer
that dies part way is not repeated, since a second copy would append to the bytes
already written. The per-request timeout that bounds an API call is lifted for
it, which is why C<download> and C<download_bytes> refuse a per-call C<timeout>.

=head1 SEE ALSO

L<InternetData>, L<InternetData::Error>.

=head1 LICENSE

MIT. Copyright Mslm Dev.

=cut
