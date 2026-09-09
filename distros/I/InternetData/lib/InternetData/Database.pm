package InternetData::Database;

use strict;
use warnings;

use Carp ();

use InternetData::Error;

our $VERSION = '1.2.3';

# Every database this organization may see, with where each one stands.
#
# NOT only the licensed ones: `standing` says whether a database is yours today,
# was, or has never been bought, so a caller can see what else is published
# without a sales email.
#
# What comes back is the SERVER's answer for THIS key and nothing else. A
# database commissioned for a single customer is absent entirely from a listing
# for anyone else, rather than present with an `unlicensed` standing, so a
# catalog held from one key is not an answer for another and is not a catalog of
# what exists. Nothing here is cached for exactly that reason.
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
    $client->_check_options('database->download_url', \%options, 'retries');
    my $url = $client->_url('/api/v2/database/download', id => $id, format => $format);
    my $retries = defined $options{retries} ? $options{retries} : $client->{retries};
    return $client->_retry_p($retries, sub {
        $client->_get_p($url)->then(sub {
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

# The 302 is followed as a SECOND request, and that transfer is issued exactly
# once: `retries` covers the API call that hands out the link, not a transfer
# that may have moved gigabytes before it failed.
sub _transfer_p {
    my ($self, $method, $id, $format, $options, $on_chunk) = @_;
    my $client = $self->{client};
    $client->_check_options("database->$method", $options, 'retries');
    return $self->download_url_p($id, $format, %$options)
        ->then(sub { $client->_stream_p(shift, $on_chunk) });
}

sub _body_p {
    my ($self, $method, $options, $path, @query) = @_;
    my $client = $self->{client};
    $client->_check_options("database->$method", $options, 'retries');
    my $url = $client->_url($path, @query);
    my $retries = defined $options->{retries} ? $options->{retries} : $client->{retries};
    return $client->_retry_p($retries, sub { $client->_json_p($url) });
}

sub _assert_database {
    my ($method, $id, $format) = @_;
    Carp::croak("database->$method: expected a database id") if !defined $id || !length $id;
    Carp::croak("database->$method: expected a format") if !defined $format || !length $format;
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
takes a per-call C<retries> option. Failures die with an L<InternetData::Error>.

=head1 METHODS

=head2 list

    my $databases = $client->database->list;

An array reference of the database B<families> this organization may see. A
licence is held against a family, and each family carries every published
version of itself:

    {
        base => 'bogon_ip',              # what a licence is held against
        name => 'Bogon IP',
        summary => 'IP ranges that cannot legitimately appear on the internet.',
        standing => 'licensed',          # licensed, expired or unlicensed
        license_type => 'standard',    # evaluation, standard, redistribute or undef
        starts => '2026-09-04T07:49:45.118Z',
        expires => undef,                # undef when the licence has no end date
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

=head3 The listing is not the same for everyone

C<standing> reports where your organization stands against a database, so an
unlicensed one is listed and you can see that it exists. A B<private> database
is different: it was commissioned for a single customer, so it is B<absent
entirely> from a listing for anyone else rather than present with an
C<unlicensed> standing. Listing it would advertise that customer.

The server decides this per key. So do not reconstruct a catalog from any other
source, do not hold one listing and reuse it for a different key, and do not
treat what you got as a list of what InternetData publishes. Nothing here is
cached for that reason.

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
magnitude, from C<bogon_asn_v1> at 264 bytes to C<resproxy_ip_14d_v1> at
5.34 GiB. Reach for it at the small end, where the bytes go straight into a
parser, and use L</download> for anything you have not measured; L</metadata>
publishes the size per format without transferring anything, which is how you
find out which end you are at.

=head1 TRANSFERS

C<download> and C<download_bytes> follow the redirect as a second request
carrying B<no credential>: the link authorizes itself, so forwarding the API key
would hand it to a host with no business holding it - and object storage answers
C<400> to a presigned GET that also carries an C<Authorization> header, so it
would break the download too.

That transfer is issued exactly once. C<retries> covers the API call that hands
out the link, not a transfer that may already have moved gigabytes before it
failed, and the per-request timeout that bounds an API call is lifted for it.

=head1 SEE ALSO

L<InternetData>, L<InternetData::Error>.

=head1 LICENSE

MIT. Copyright Mslm Dev.

=cut
