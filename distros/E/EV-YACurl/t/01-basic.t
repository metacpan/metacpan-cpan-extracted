use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 9;
use IO::Socket::INET;
use TestServer;
use EV::YACurl ':constants';

TestServer::watchdog(120);

my $server = TestServer->new(sub {
    my ($request) = @_;

    return (200, [], "POST:$request->{body}")     if $request->{path} eq '/post';
    return (200, [], $request->{headers}{'x-custom'} // 'none')
        if $request->{path} eq '/headers';
    return (200, [], 'GET OK');
});
my $base = $server->base_url;

sub fetch {
    my (%options) = @_;
    my $client = delete $options{client} || EV::YACurl->new({});
    my ($response, $error, $body) = (undef, undef, '');
    my $done = 0;

    $client->request(sub { ($response, $error) = @_; $done = 1 }, {
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
        %options,
    });
    EV::run until $done;

    return ($response, $error, $body);
}

{
    my ($response, $error, $body) = fetch(CURLOPT_URL => "$base/get");
    is($error, undef, 'GET: no error');
    is($response->getinfo(CURLINFO_RESPONSE_CODE), 200, 'GET: 200');
    is($body, 'GET OK', 'GET: body');
}

{
    my ($response, undef, $body) = fetch(
        CURLOPT_URL => "$base/post",
        CURLOPT_POSTFIELDS => 'hello=world',
    );
    is($response->getinfo(CURLINFO_RESPONSE_CODE), 200, 'POST: 200');
    is($body, 'POST:hello=world', 'POST: body echoed');
}

{
    my (undef, undef, $body) = fetch(
        CURLOPT_URL => "$base/headers",
        CURLOPT_HTTPHEADER => ['X-Custom: forty-two'],
    );
    is($body, 'forty-two', 'custom request header reached the server');
}

# A closed port is a deterministic connection failure, unlike anything
# that depends on name resolution.
{
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1, ReuseAddr => 1)
        or die "listen: $!";
    my $closed_port = $listener->sockport;
    close $listener;

    my ($response, $error) = fetch(CURLOPT_URL => "http://127.0.0.1:$closed_port/");
    is($response, undef, 'refused connection: no response');
    like($error, qr/connect|refused/i, "refused connection: error says why ($error)");
}

SKIP: {
    my ($response, $error) = fetch(CURLOPT_URL => 'http://no-such-host.invalid/');

    # A resolver that hijacks NXDOMAIN answers even for .invalid names.
    skip 'this resolver answers for .invalid names', 1 if $response;
    ok($error, "unresolvable host reports an error ($error)");
}
