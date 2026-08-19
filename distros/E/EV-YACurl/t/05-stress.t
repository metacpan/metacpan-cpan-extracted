use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestServer;
use EV::YACurl ':constants';

TestServer::watchdog(120);

my $server = TestServer->new(sub {
    my ($request) = @_;
    (my $n = $request->{path}) =~ s{^/}{};
    return (200, [], "req:$n");
});

my $base = $server->base_url;

plan tests => 6;

{
    my $client = EV::YACurl->new({
        CURLMOPT_MAX_TOTAL_CONNECTIONS => 20,
    });

    my $n = 50;
    my $completed = 0;
    my @results;

    for my $i (1..$n) {
        $client->request(sub {
            my ($response, $error) = @_;
            push @results, {
                i => $i,
                code => $response ? $response->getinfo(CURLINFO_RESPONSE_CODE) : undef,
                error => $error,
            };
            $completed++;
        }, {
            CURLOPT_URL => "$base/$i",
            CURLOPT_WRITEFUNCTION => sub { },
        });
    }

    EV::run until $completed >= $n;

    is($completed, $n, "All $n concurrent requests completed");
    my @success = grep { $_->{code} && $_->{code} == 200 } @results;
    is(scalar @success, $n, "All returned 200");
}

{
    my $client = EV::YACurl->new({});
    my $success = 0;

    for my $i (1..20) {
        my $done = 0;
        my ($response, $error);

        $client->request(sub {
            ($response, $error) = @_;
            $done = 1;
        }, {
            CURLOPT_URL => "$base/seq-$i",
            CURLOPT_WRITEFUNCTION => sub { },
        });

        EV::run until $done;
        $success++ if $response && $response->getinfo(CURLINFO_RESPONSE_CODE) == 200;
    }

    is($success, 20, "20 sequential requests succeeded");
}

{
    my @clients = map { EV::YACurl->new({}) } 1..5;
    my $completed = 0;
    my $n = scalar(@clients) * 10;

    for my $client (@clients) {
        for my $i (1..10) {
            $client->request(sub {
                $completed++;
            }, {
                CURLOPT_URL => "$base/multi-$i",
                CURLOPT_WRITEFUNCTION => sub { },
            });
        }
    }

    EV::run until $completed >= $n;
    is($completed, $n, "Multiple clients: $n requests completed");
}

{
    my $client = EV::YACurl->new({
        CURLMOPT_MAX_TOTAL_CONNECTIONS => 50,
    });

    my $completed = 0;
    my $total = 100;

    for my $i (1..$total) {
        $client->request(sub { $completed++ }, {
            CURLOPT_URL => "$base/rapid-$i",
            CURLOPT_WRITEFUNCTION => sub { },
        });
    }

    EV::run until $completed >= $total;
    is($completed, $total, "Rapid fire: $total requests completed");
}

{
    my $client = EV::YACurl->new({});
    my @bodies;
    my $completed = 0;
    my $n = 10;

    for my $i (1..$n) {
        my $body = '';
        $client->request(sub {
            push @bodies, $body;
            $completed++;
        }, {
            CURLOPT_URL => "$base/$i",
            CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
        });
    }

    EV::run until $completed >= $n;

    my @correct = grep { /^req:\d+$/ } @bodies;
    is(scalar @correct, $n, "All bodies correctly accumulated");
}
