use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 6;
use TestServer;
use EV::YACurl ':constants';

TestServer::watchdog(120);

my $server = TestServer->new(sub {
    my ($request) = @_;
    my ($id) = $request->{path} =~ m{/(\d+)};
    return (200, [], 'reply ' . ($id // 0));
});
my $base = $server->base_url;

{
    my $client = EV::YACurl->new({ CURLMOPT_MAX_TOTAL_CONNECTIONS => 4 });
    my $n = 8;
    my (%bodies, %codes);
    my $completed = 0;

    for my $i (1 .. $n) {
        my $body = '';
        $client->request(sub {
            my ($response, $error) = @_;
            $codes{$i} = $response ? $response->getinfo(CURLINFO_RESPONSE_CODE) : "error: $error";
            $bodies{$i} = $body;
            $completed++;
        }, {
            CURLOPT_URL => "$base/$i",
            CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
        });
    }

    EV::run until $completed >= $n;

    is($completed, $n, "all $n concurrent requests completed");
    is_deeply([sort { $a <=> $b } keys %codes], [1 .. $n], 'every request called back exactly once');
    is_deeply([grep { $_ ne '200' } values %codes], [], 'all returned 200')
        or diag explain \%codes;
    is_deeply([map { $bodies{$_} } 1 .. $n], [map { "reply $_" } 1 .. $n],
              'each callback saw its own response body');
}

# Sequential requests on one client must reuse the connection.
{
    my $client = EV::YACurl->new({});
    my @connections;
    my $completed = 0;

    for (1 .. 3) {
        my $done = 0;
        $client->request(sub {
            push @connections, $_[0]->getinfo(CURLINFO_NUM_CONNECTS);
            $completed++;
            $done = 1;
        }, { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
        EV::run until $done;
    }

    is($completed, 3, 'client is reusable for sequential requests');
    is_deeply([@connections[1, 2]], [0, 0], 'later requests opened no new connection')
        or diag "num_connects: @connections";
}
