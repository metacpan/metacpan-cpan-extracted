# Added for v0.2

use strict;
use warnings;

use Test::More tests => 3 + 4 * 8;
use MIDI::Morph qw(event_distance);

ok(!defined event_distance(undef, undef));
ok(!defined event_distance([], []));

my $e = ['note', 100, 96, 1, 60, 90];
my %e_higher = (
    start    => ['note', 120, 76,  1, 60, 90],
    end      => ['note', 100, 116, 1, 60, 90],
    pitch    => ['note', 100, 96,  1, 80, 90],
    velocity => ['note', 100, 96,  1, 60, 110]);

my %e_lower = (
    start    => ['note', 80,  116, 1, 60, 90],
    end      => ['note', 100, 76, 1, 60, 90],
    pitch    => ['note', 100, 96, 1, 40, 90],
    velocity => ['note', 100, 96, 1, 60, 70]);

my $e_higher  = ['note', 100, 96, 1, 90, 90];
my $e_softer  = ['note', 100, 96, 1, 60, 60];
my $e_later   = ['note', 60,  96, 1, 60, 90];
my $e_earlier = ['note', 140, 96, 1, 60, 90];

is(event_distance($e, $e), 0);

# test single weights
foreach (qw(start end pitch velocity)) {
    is(event_distance($e, $e_higher{$_}, {$_ => 0}),   0);
    is(event_distance($e, $e_higher{$_}, {$_ => 0.5}), 10);
    is(event_distance($e, $e_higher{$_}, {$_ => 1}),   20);
    is(event_distance($e, $e_higher{$_}, {$_ => 2}),   40);

    is(event_distance($e, $e_lower{$_}, {$_ => 0}),   0);
    is(event_distance($e, $e_lower{$_}, {$_ => 0.5}), 10);
    is(event_distance($e, $e_lower{$_}, {$_ => 1}),   20);
    is(event_distance($e, $e_lower{$_}, {$_ => 2}),   40);
}
