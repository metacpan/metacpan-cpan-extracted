use strict;
use warnings;

use lib 't/lib';

use Mojo::JSON qw(false true);
use Test::More;
use Time::HiRes ();
use InternetData;
use InternetDataTest;
use InternetDataTest::Origin;

# A spent trial's or a reached cap's answer ends with a new UTC month or a raised
# cap, so it is cached for a minute at most rather than for the client's TTL.

my %FLAGS = (
    '45.83.91.1' => {},
    '45.83.91.2' => { trial_expired => false, cap_reached => false },
    '45.83.91.3' => { trial_expired => true },
    '45.83.91.4' => { cap_reached => true },
);

sub answer {
    my ($ip) = @_;
    return InternetDataTest::lookup(ip => $ip, %{ $FLAGS{$ip} });
}

my $origin = InternetDataTest::Origin->new(sub {
    my ($c) = @_;
    my $path = $c->req->url->path->to_string;
    if ($path eq '/batch') {
        my @ips = @{ $c->req->json->{ips} };
        return $c->render(json => { results => { map { ($_ => answer($_)) } @ips }, errors => {} });
    }
    (my $ip = $path) =~ s{^/}{};
    $c->render(json => answer($ip));
});

my @CASES = (
    ['45.83.91.1', 3600, 3600],
    ['45.83.91.2', 3600, 3600],
    ['45.83.91.3', 3600, 60],
    ['45.83.91.4', 3600, 60],
    ['45.83.91.3', 5, 5],
    ['45.83.91.4', 5, 5],
    ['45.83.91.1', 5, 5],
);

for my $how (qw(lookup lookup_batch)) {
    subtest "$how: each answer is cached as long as its flags allow" => sub {
        for my $case (@CASES) {
            my ($ip, $ttl, $want) = @$case;
            my $client = InternetData->new(base_url => $origin->url, cache_ttl => $ttl);

            my $before = Time::HiRes::time();
            if ($how eq 'lookup') {
                $client->lookup($ip);
            } else {
                $client->lookup_batch([$ip, '45.83.91.1']);
            }
            my $after = Time::HiRes::time();
            my $expires = $client->{cache}->expiry($ip);

            ok(defined $expires, "$ip under a $ttl s TTL is cached");
            cmp_ok($expires, '>=', $before + $want, "$ip under a $ttl s TTL lives at least $want s");
            cmp_ok($expires, '<=', $after + $want, "$ip under a $ttl s TTL lives at most $want s");
        }
    };
}

subtest 'a reduced answer is still cached, so a repeat sends nothing' => sub {
    $origin->reset;
    my $client = InternetData->new(base_url => $origin->url);

    $client->lookup('45.83.91.3');
    my $again = $client->lookup('45.83.91.3');

    is($again->trial_expired, 1, 'the repeat is the reduced answer');
    is($origin->count, 1, 'one request');
};

done_testing;
