#!/usr/bin/env perl
#
# Example: Use compiled Data::Path::XS paths to extract fields from watch events
#
# Watch responses are nested hashes — compiled paths avoid repeated parsing
# when extracting the same fields from every event in a hot loop.
#
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use EV;
use EV::Etcd;
use Data::Path::XS qw(pathc_get path_compile);

# Pre-compile paths for fields we extract from every event
my $p_type  = path_compile('/type');
my $p_key   = path_compile('/kv/key');
my $p_value = path_compile('/kv/value');
my $p_rev   = path_compile('/kv/mod_revision');
my $p_lease = path_compile('/kv/lease');
my $p_prev  = path_compile('/prev_kv/value');

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
my $prefix = "/events-demo/";

# Seed data
$client->put("${prefix}sensor/temp", "22.5", sub { EV::break });
my $t0 = EV::timer(5, 0, sub { die "timeout" });
EV::run;

print "=== Watching $prefix with prev_kv ===\n";
print "(Compiled paths extract fields from each event)\n\n";

my $event_count = 0;

$client->watch($prefix, { prefix => 1, prev_kv => 1 }, sub {
    my ($resp, $err) = @_;
    if ($err) {
        print "Watch error: $err->{message}\n";
        EV::break;
        return;
    }
    return if $resp->{created};

    for my $ev (@{$resp->{events} || []}) {
        $event_count++;

        # Extract fields using compiled paths — no string parsing per event
        my $type  = pathc_get($ev, $p_type) // 'PUT';
        my $key   = pathc_get($ev, $p_key);
        my $value = pathc_get($ev, $p_value) // '';
        my $rev   = pathc_get($ev, $p_rev);
        my $lease = pathc_get($ev, $p_lease);
        my $prev  = pathc_get($ev, $p_prev);

        printf "#%d [rev %d] %s %s", $event_count, $rev, $type, $key;
        if ($type eq 'DELETE') {
            printf " (was: %s)", $prev // '?' ;
        } elsif (defined $prev) {
            printf " = %s (was: %s)", $value, $prev;
        } else {
            printf " = %s", $value;
        }
        printf " [lease:%d]", $lease if $lease;
        print "\n";
    }
});

# Give watch time to set up
my $tw = EV::timer(0.3, 0, sub { EV::break });
EV::run;

# Generate events
my @ops = (
    sub { $client->put("${prefix}sensor/temp", "23.1", sub { EV::break }) },
    sub { $client->put("${prefix}sensor/humidity", "65", sub { EV::break }) },
    sub { $client->put("${prefix}sensor/temp", "23.8", sub { EV::break }) },
    sub { $client->delete("${prefix}sensor/humidity", sub { EV::break }) },
);

for my $op (@ops) {
    $op->();
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    my $d = EV::timer(0.2, 0, sub { EV::break });
    EV::run;
}

print "\nProcessed $event_count events.\n";

# Cleanup
$client->delete($prefix, { prefix => 1 }, sub { EV::break });
my $tc = EV::timer(5, 0, sub { EV::break });
EV::run;
print "Done.\n";
