#!/usr/bin/env perl
# A new ithread must not clone clients or handles: its copies would DESTROY
# the parent's C structs when the thread exits
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Config;
use Test::More;

BEGIN {
    plan skip_all => 'perl built without ithreads' unless $Config{useithreads};
    eval { require threads; threads->import; 1 } or plan skip_all => 'threads unavailable';
    eval { require EV; 1 } or plan skip_all => 'EV required';
}
use EV;
use EV::Etcd;
use IO::Socket::INET;
use Scalar::Util 'blessed';

my $endpoint = '127.0.0.1:2379';
plan skip_all => "etcd not available on $endpoint"
    unless IO::Socket::INET->new(PeerAddr => $endpoint, Timeout => 2);

sub put_ok {
    my ($client, $key) = @_;
    my $ok;
    $client->put($key, 'v', sub { $ok = !$_[1]; EV::break });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    return $ok;
}

my $key = "/test_threads_$$";
my $client = EV::Etcd->new(endpoints => [$endpoint]);
ok(put_ok($client, $key), 'client works before the thread');

my ($created, @events);
my $watch = $client->watch("$key/w", sub {
    my ($resp) = @_;
    return unless $resp;
    $created ||= $resp->{created};
    push @events, @{ $resp->{events} || [] };
    EV::break;
});
{
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
}
ok($created, 'watch created');

my $seen = threads->create(sub {
    join ',', map { blessed($_) // 'unblessed' } $client, $watch;
})->join;
is($seen, 'unblessed,unblessed', 'the thread gets no client or handle object');

ok(put_ok($client, "$key/w"), 'client still works after the thread exited');
unless (@events) {
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
}
ok(scalar @events, 'watch still delivers after the thread exited');

$watch->cancel(sub {});
$client->delete($key, { prefix => 1 }, sub { EV::break });
{
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
}

done_testing();
