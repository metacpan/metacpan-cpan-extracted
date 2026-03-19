#!/usr/bin/env perl
#
# Example: Mirror an etcd prefix into a local nested hash using Data::Path::XS
#
# etcd keys like /myapp/db/host -> "localhost" become:
#   $config = { db => { host => "localhost" } }
#
# Data::Path::XS builds the tree incrementally from watch events.
#
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use EV;
use EV::Etcd;
use Data::Path::XS qw(path_get path_set path_delete);
use Data::Dumper;

my $prefix = "/myapp/";
my %config;

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);

# Seed some data
print "=== Seeding config ===\n";
$client->txn(
    compare => [],
    success => [
        { put => { key => "${prefix}db/host",    value => "localhost" } },
        { put => { key => "${prefix}db/port",    value => "5432" } },
        { put => { key => "${prefix}cache/host", value => "redis.local" } },
        { put => { key => "${prefix}cache/ttl",  value => "3600" } },
    ],
    failure => [],
    sub {
        my ($resp, $err) = @_;
        die "Seed failed: $err->{message}" if $err;
        EV::break;
    }
);
my $t0 = EV::timer(5, 0, sub { die "timeout" });
EV::run;

# Load initial snapshot into tree
$client->get($prefix, { prefix => 1 }, sub {
    my ($resp, $err) = @_;
    die "Load failed: $err->{message}" if $err;

    for my $kv (@{$resp->{kvs} || []}) {
        my $path = substr($kv->{key}, length($prefix) - 1); # keep leading /
        path_set(\%config, $path, $kv->{value});
    }

    print "Initial config tree:\n", Dumper(\%config);

    # Watch from next revision — no gap between load and watch
    my $rev = $resp->{header}{revision} + 1;

    $client->watch($prefix, { prefix => 1, start_revision => $rev }, sub {
        my ($resp, $err) = @_;
        if ($err) {
            print "Watch error: $err->{message}\n";
            return;
        }
        for my $ev (@{$resp->{events} || []}) {
            my $path = substr($ev->{kv}{key}, length($prefix) - 1);
            if (($ev->{type} // 'PUT') eq 'DELETE') {
                path_delete(\%config, $path);
                print "DELETE $path\n";
            } else {
                path_set(\%config, $path, $ev->{kv}{value});
                print "PUT    $path = $ev->{kv}{value}\n";
            }
        }
        print "Config tree:\n", Dumper(\%config);
    });

    EV::break;
});
my $t1 = EV::timer(5, 0, sub { die "timeout" });
EV::run;

# Make some changes and let watch process them
my @ops = (
    sub { $client->put("${prefix}db/pool_size", "20", sub { EV::break }) },
    sub { $client->put("${prefix}cache/ttl", "7200", sub { EV::break }) },
    sub { $client->delete("${prefix}cache/host", sub { EV::break }) },
);

for my $op (@ops) {
    $op->();
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    # let watch callback fire
    my $d = EV::timer(0.2, 0, sub { EV::break });
    EV::run;
}

# Read values back from tree
print "\n=== Reading from local tree ===\n";
print "db/host:      ", path_get(\%config, "/db/host")      // "(deleted)", "\n";
print "db/pool_size: ", path_get(\%config, "/db/pool_size") // "(deleted)", "\n";
print "cache/ttl:    ", path_get(\%config, "/cache/ttl")    // "(deleted)", "\n";
print "cache/host:   ", path_get(\%config, "/cache/host")   // "(deleted)", "\n";

# Cleanup
$client->delete($prefix, { prefix => 1 }, sub { EV::break });
my $tc = EV::timer(5, 0, sub { EV::break });
EV::run;
print "\nDone.\n";
