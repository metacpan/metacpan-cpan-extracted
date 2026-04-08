#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# High-volume fire-and-forget inserts.
# No callbacks = minimal Perl overhead per command.

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { die "error: @_\n" },
);

my $total = 50000;
my $value = 'x' x 200;
my $t0 = EV::now;

print "Inserting $total keys (fire-and-forget)...\n";

for my $i (1..$total) {
    $mc->set("batch:$i", $value);  # no callback
}

# NOOP fence: when this response arrives, all prior SETs are done
$mc->noop(sub {
    my $elapsed = EV::now - $t0;
    printf "Done: %d keys in %.3fs (%.0f ops/s)\n",
        $total, $elapsed, $total / $elapsed;

    # Verify a random sample
    my @sample = map { "batch:" . int(rand($total) + 1) } 1..5;
    my $checked = 0;
    for my $key (@sample) {
        $mc->get($key, sub {
            my ($val, $err) = @_;
            printf "  %s => %s\n", $key,
                defined $val ? length($val) . " bytes" : "MISS";
            if (++$checked == 5) {
                $mc->disconnect;
            }
        });
    }
});

EV::run;
