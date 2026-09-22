use strict;
use warnings;

use lib 't/lib';

use File::Temp ();
use Mojo::UserAgent;
use Test::More;
use InternetData;
use InternetDataTest::Origin;

# The file transfers: the redirect, what the second request carries, and the ways
# a transfer can end badly.

my $DATABASE = 'x' x 4096;

# A test origin that answers the download endpoint with a 302 and then serves the
# file from a second path, which is how the real API works. $storage decides what
# that second request gets.
sub origin_for {
    my ($storage) = @_;
    return InternetDataTest::Origin->new(sub {
        my ($c, $o) = @_;
        if ($c->req->url->path->to_string eq '/api/v2/database/download') {
            $c->res->headers->location($o->url . '/presigned');
            return $c->rendered(302);
        }
        $storage->($c);
    });
}

sub whole_database {
    my ($c) = @_;
    $c->res->headers->content_type('application/octet-stream');
    $c->render(data => $DATABASE);
}

sub temp_path {
    my $dir = File::Temp->newdir;
    return ($dir, $dir->dirname . '/bogon_ip_v1.csv.gz');
}

sub client_for {
    my ($origin, %options) = @_;
    return InternetData->new(base_url => $origin->url, api_key => 'secret-key', %options);
}

subtest 'a database is streamed to a path and lands whole' => sub {
    my $origin = origin_for(\&whole_database);
    my ($dir, $path) = temp_path();
    my $client = client_for($origin);

    my $written = $client->database->download('bogon_ip_v1', 'csvgz', $path);

    is($written, length $DATABASE, 'the byte count is reported');
    is(-s $path, length $DATABASE, 'and the file on disk is that long');
    ok(!-e "$path.part", 'the .part file did not outlive a successful transfer');
    open my $fh, '<', $path or die $!;
    binmode $fh;
    is(do { local $/; <$fh> }, $DATABASE, 'the bytes are the database');
    is_deeply([$origin->paths], ['/api/v2/database/download', '/presigned'],
        'the link was fetched, then the file');
};

subtest 'the presigned request carries no credential and no encoding preference' => sub {
    my $origin = origin_for(\&whole_database);
    my ($dir, $path) = temp_path();

    client_for($origin)->database->download('bogon_ip_v1', 'csvgz', $path);

    my ($api, $storage) = $origin->requests;
    is($api->{headers}{Authorization}, 'Bearer secret-key', 'the API call is authenticated');
    # Mojo::UserAgent strips Authorization when it follows a redirect ITSELF
    # (Mojo::UserAgent::Transactor::redirect removes it along with Cookie, Host
    # and Referer), but this client never follows one: the transfer is a request
    # of its own, built with build_tx rather than through the one place a key is
    # attached. Leaving the key off is this library's job, not the framework's -
    # and object storage answers 400 to a presigned GET that also carries an
    # Authorization header, so a leak here breaks the download too.
    ok(!exists $storage->{headers}{Authorization},
        'and the object storage request carries no Authorization');
    ok(!exists $storage->{headers}{'X-Api-Key'}, 'nor an X-Api-Key');
    is_deeply($storage->{query}, {}, 'nor an apikey query parameter');

    # Mojo asks for gzip on every request it builds. A published file is already
    # compressed, so the only thing that would buy is a Content-Length counting
    # bytes that never reach the sink, and that length is the only evidence a
    # transfer arrived whole.
    is($api->{headers}{'Accept-Encoding'}, 'gzip', 'a JSON call still negotiates compression');
    ok(!exists $storage->{headers}{'Accept-Encoding'}, 'a transfer does not');
};

subtest 'a caller-supplied agent does not smuggle the key onto the link' => sub {
    # A Mojo::UserAgent carrying a default Authorization header would put the key
    # on the presigned request even though the client never sets one, which the
    # test above cannot see because it uses the client's own agent.
    my $ua = Mojo::UserAgent->new;
    my $origin = origin_for(\&whole_database);
    my ($dir, $path) = temp_path();

    client_for($origin, ua => $ua)->database->download('bogon_ip_v1', 'csvgz', $path);

    my (undef, $storage) = $origin->requests;
    ok(!exists $storage->{headers}{Authorization}, 'the transfer is still credential-free');
    is(-s $path, length $DATABASE, 'and it still arrived');
};

subtest 'the bytes variant agrees with the streamed copy' => sub {
    my $origin = origin_for(\&whole_database);
    my ($dir, $path) = temp_path();
    my $client = client_for($origin);

    my $streamed = $client->database->download('bogon_ip_v1', 'csvgz', $path);
    my $bytes = $client->database->download_bytes('bogon_ip_v1', 'csvgz');

    is(length $bytes, $streamed, 'the same length');
    open my $fh, '<', $path or die $!;
    binmode $fh;
    is($bytes, do { local $/; <$fh> }, 'and the same bytes');
};

subtest 'a truncated transfer fails loudly and leaves nothing behind' => sub {
    # Announces the whole file, sends a third of it, then hangs up. Nothing in the
    # protocol distinguishes that from a complete body except the length that was
    # promised: Mojo only synthesizes `Premature connection close` when no status
    # was parsed, so a client that does not check writes a short file and reports
    # success.
    my $origin = origin_for(sub {
        my ($c) = @_;
        $c->res->headers->content_type('application/octet-stream');
        $c->res->headers->content_length(length $DATABASE);
        $c->write(substr($DATABASE, 0, 1365) => sub { shift->finish });
    });
    my ($dir, $path) = temp_path();

    my $written = eval { client_for($origin, timeout => 5)->database->download('bogon_ip_v1', 'csvgz', $path) };

    ok(!defined $written, 'the transfer did not report success');
    isa_ok($@, 'InternetData::Error', 'it failed with');
    like($@->message, qr/ended after 1365 of 4096 bytes/, 'and says how short it stopped');
    ok(!-e $path, 'no short file reads as a whole database');
    ok(!-e "$path.part", 'and no partial file survives either');
    # Retries are budgeted for the part before any byte reaches the caller.
    # Repeating a transfer whose bytes were already written would append a second
    # copy to them, and a doubled file passes every length check there is.
    is(scalar(grep { $_ eq '/presigned' } $origin->paths), 1, 'a half-written body was not fetched again');
};

subtest 'object storage failing before the first byte is retried, and the file holds one copy' => sub {
    my $attempts = 0;
    my $origin = origin_for(sub {
        my ($c) = @_;
        return $c->render(text => '<Error><Code>SlowDown</Code></Error>', status => 503) if $attempts++ < 1;
        whole_database($c);
    });
    my ($dir, $path) = temp_path();

    my $written = eval { client_for($origin, retries => 2)->database->download('bogon_ip_v1', 'csvgz', $path) };

    is(scalar(grep { $_ eq '/presigned' } $origin->paths), 2, 'the 503 was retried');
    is($written, length $DATABASE, 'the transfer then succeeded');
    is(-s $path, length $DATABASE, 'with exactly one copy on disk');
};

subtest 'a database the organization does not license is refused once' => sub {
    my $origin = InternetDataTest::Origin->new(sub {
        shift->render(json => { rc => 'NOT_LICENSED' }, status => 403);
    });
    my $client = client_for($origin, retries => 3);
    my ($dir, $path) = temp_path();

    for my $call (
        ['download', sub { $client->database->download('vpn_ip_v1', 'csvgz', $path) }],
        ['download_bytes', sub { $client->database->download_bytes('vpn_ip_v1', 'csvgz') }],
        ['download_url', sub { $client->database->download_url('vpn_ip_v1', 'csvgz') }],
    ) {
        my ($name, $run) = @$call;
        $origin->reset;
        my $got = eval { $run->() };
        ok(!defined $got, "$name failed");
        is($@->kind, 'forbidden', "$name: classified as forbidden");
        is($@->status, 403, "$name: carries the status");
        # The API says WHICH refusal this is, under `rc`. Falling back to the
        # status means the envelope went unread.
        is($@->message, 'NOT_LICENSED', "$name: carries the API's rc");
        is($@->retryable, 0, "$name: a license refusal is not worth retrying");
        is($origin->count, 1, "$name: and was asked exactly once");
    }
    ok(!-e "$path.part", 'a refused download leaves no partial file');
};

subtest 'object storage refusing the link is reported as such' => sub {
    my $origin = origin_for(sub {
        # XML, not this API's `rc` envelope: the refusal comes from a different
        # system on the other end of the link.
        shift->render(text => '<Error><Code>AccessDenied</Code></Error>', status => 403);
    });
    my ($dir, $path) = temp_path();

    my $written = eval { client_for($origin)->database->download('bogon_ip_v1', 'csvgz', $path) };

    ok(!defined $written, 'the transfer failed');
    like($@->message, qr/object storage refused the download link with status 403/,
        'and names where the refusal came from');
    is($@->kind, 'forbidden', 'still classified on the status');
    is($@->retryable, 0, 'so a dead link is not hammered');
    is(scalar(grep { $_ eq '/presigned' } $origin->paths), 1, 'and it was asked once');
    ok(!-e "$path.part", 'leaving no partial file');
};

subtest 'no response size cap applies to a transfer' => sub {
    # Mojo aborts a response past max_message_size, counting every byte it parses
    # whether or not it keeps any of them. Mojo::Message::Response defaults to
    # 2 GiB, but MOJO_MAX_MESSAGE_SIZE in the ENVIRONMENT lowers it for every
    # response in the process, exactly as MOJO_MAX_REDIRECTS does for redirects,
    # so a transfer that does not set its own limit is at the mercy of a machine
    # we do not own. One kilobyte here stands in for a multi-gigabyte file.
    local $ENV{MOJO_MAX_MESSAGE_SIZE} = 1024;
    my $origin = origin_for(\&whole_database);
    my ($dir, $path) = temp_path();

    my $written = client_for($origin)->database->download('bogon_ip_v1', 'csvgz', $path);

    is($written, length $DATABASE, 'a file four times the cap still arrived');
    is(-s $path, length $DATABASE, 'and reached the disk');
};

subtest 'a transfer outlives the per-request timeout that bounds an API call' => sub {
    my $megabytes = 24;
    my $origin = origin_for(sub {
        my ($c) = @_;
        $c->res->headers->content_type('application/octet-stream');
        $c->res->headers->content_length($megabytes * 1024 * 1024);
        my $left = $megabytes;
        my $write;
        $write = sub {
            my $writer = shift;
            return $writer->finish unless $left--;
            $writer->write('y' x (1024 * 1024) => sub { $write->(shift) });
        };
        $c->write('' => sub { $write->(shift) });
    });
    my ($dir, $path) = temp_path();
    # One second per request, against a body that takes longer than that to
    # arrive. request_timeout bounds the whole response and Mojo has no
    # per-transaction form of it, so without lifting it a database is cut off at
    # whatever bound suits a metadata call.
    my $client = client_for($origin, timeout => 1);

    my $written = $client->database->download('bogon_ip_v1', 'csvgz', $path);

    is($written, $megabytes * 1024 * 1024, "all ${megabytes} MiB arrived");
    is(-s $path, $megabytes * 1024 * 1024, 'and reached the disk');
};

subtest 'the per-request timeout is restored after a transfer' => sub {
    my $origin = origin_for(\&whole_database);
    my ($dir, $path) = temp_path();
    my $ua = Mojo::UserAgent->new;

    client_for($origin, timeout => 7, ua => $ua)->database->download('bogon_ip_v1', 'csvgz', $path);

    is($ua->request_timeout, 7, 'the agent is left as the caller configured it');
};

subtest 'an unwritable destination costs no request' => sub {
    my $origin = origin_for(\&whole_database);
    my $client = client_for($origin);

    eval { $client->database->download('bogon_ip_v1', 'csvgz', '/nonexistent-directory/bogon_ip_v1.csv.gz') };

    like($@, qr/cannot open/, 'the destination is refused up front');
    is($origin->count, 0, 'so no quota was spent finding out');
};

subtest 'the promise forms transfer too' => sub {
    my $origin = origin_for(\&whole_database);
    my ($dir, $path) = temp_path();
    my $client = client_for($origin);

    my ($written, $bytes, $url);
    $client->database->download_p('bogon_ip_v1', 'csvgz', $path)
        ->then(sub { $written = shift; $client->database->download_bytes_p('bogon_ip_v1', 'csvgz') })
        ->then(sub { $bytes = shift; $client->database->download_url_p('bogon_ip_v1', 'csvgz') })
        ->then(sub { $url = shift })
        ->wait;

    is($written, length $DATABASE, 'download_p resolves with the byte count');
    is($bytes, $DATABASE, 'download_bytes_p resolves with the bytes');
    is($url, $origin->url . '/presigned', 'download_url_p resolves with the link');
};

subtest 'a transfer refuses arguments it cannot use' => sub {
    my $client = InternetData->new(api_key => 'k');

    eval { $client->database->download('bogon_ip_v1', 'csvgz') };
    like($@, qr/expected a destination path/, 'download needs somewhere to write');
    eval { $client->database->download('', 'csvgz', '/tmp/x') };
    like($@, qr/expected a database id/, 'and a database id');
    eval { $client->database->download_bytes('bogon_ip_v1') };
    like($@, qr/expected a format/, 'download_bytes needs a format');
    eval { $client->database->download_bytes('bogon_ip_v1', 'csvgz', retres => 1) };
    like($@, qr/unknown option/, 'and refuses a typo rather than ignoring it');
};

done_testing();
