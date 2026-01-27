use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Hypersonic;

# Skip if we can't fork
plan skip_all => 'fork not available' unless $^O ne 'MSWin32';

# Create temp directory with test files
my $static_dir = tempdir(CLEANUP => 1);

# Create test files
make_path("$static_dir/css");
make_path("$static_dir/js");
make_path("$static_dir/images");

# HTML file
open my $fh, '>', "$static_dir/index.html" or die $!;
print $fh '<html><body><h1>Hello World</h1></body></html>';
close $fh;

# CSS file
open $fh, '>', "$static_dir/css/style.css" or die $!;
print $fh 'body { color: red; }';
close $fh;

# JS file
open $fh, '>', "$static_dir/js/app.js" or die $!;
print $fh 'console.log("hello");';
close $fh;

# JSON file
open $fh, '>', "$static_dir/data.json" or die $!;
print $fh '{"key":"value"}';
close $fh;

# Binary file (fake PNG header)
open $fh, '>:raw', "$static_dir/images/logo.png" or die $!;
print $fh "\x89PNG\r\n\x1a\n" . ("x" x 100);
close $fh;

my $port = 23000 + ($$ % 1000);
my $cache_dir = "_test_static_$$";

my $pid = fork();
die "Fork failed: $!" unless defined $pid;

if ($pid == 0) {
    # Child - run server
    my $server = Hypersonic->new(cache_dir => $cache_dir);

    # Serve static files from temp directory
    $server->static('/static' => $static_dir, {
        max_age => 3600,
        etag    => 1,
    });

    # Also add a regular route to ensure they coexist
    $server->get('/api/status' => sub { '{"status":"ok"}' });

    $server->compile();
    $server->run(port => $port);
    exit(0);
}

# Parent - run tests
sleep(1);

sub make_request {
    my ($path) = @_;

    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 2,
    );
    return undef unless $sock;

    print $sock "GET $path HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n";

    local $/;
    my $response = <$sock>;
    close($sock);
    return $response;
}

subtest 'HTML file' => sub {
    my $resp = make_request('/static/index.html');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Status 200');
    like($resp, qr/Content-Type: text\/html/, 'Content-Type: text/html');
    like($resp, qr/<h1>Hello World<\/h1>/, 'HTML content');
    like($resp, qr/Cache-Control: public, max-age=3600/, 'Cache-Control header');
    like($resp, qr/ETag: "[a-f0-9]+"/, 'ETag header');
};

subtest 'CSS file' => sub {
    my $resp = make_request('/static/css/style.css');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Status 200');
    like($resp, qr/Content-Type: text\/css/, 'Content-Type: text/css');
    like($resp, qr/color: red/, 'CSS content');
};

subtest 'JavaScript file' => sub {
    my $resp = make_request('/static/js/app.js');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Status 200');
    like($resp, qr/Content-Type: application\/javascript/, 'Content-Type: application/javascript');
    like($resp, qr/console\.log/, 'JS content');
};

subtest 'JSON file' => sub {
    my $resp = make_request('/static/data.json');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Status 200');
    like($resp, qr/Content-Type: application\/json/, 'Content-Type: application/json');
    like($resp, qr/"key":"value"/, 'JSON content');
};

subtest 'Binary file (PNG)' => sub {
    my $resp = make_request('/static/images/logo.png');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Status 200');
    like($resp, qr/Content-Type: image\/png/, 'Content-Type: image/png');
};

subtest 'Regular route still works' => sub {
    my $resp = make_request('/api/status');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 200/, 'Status 200');
    like($resp, qr/"status":"ok"/, 'Regular route content');
};

subtest '404 for missing files' => sub {
    my $resp = make_request('/static/missing.txt');
    ok($resp, 'Got response');
    like($resp, qr/HTTP\/1\.1 404/, 'Status 404');
};

# Cleanup
END {
    if ($pid) {
        kill(9, $pid);
        waitpid($pid, 0);
        system("rm -rf $cache_dir");
    }
}

done_testing();
