# Test gaussian()

use strict;
use warnings;

use Test::More 'tests' => 7;

my $CNT = 500000;

use_ok('Math::Random::MT::Auto', qw/gaussian/);
can_ok('Math::Random::MT::Auto', qw/gaussian/);
can_ok('main', qw/gaussian/);

# Cumulative distribution function
sub cdf
{
    my $z = $_[0];

    my $sum = 1.0 * $z;
    my $k = 1;
    my $factK = 1.0;

    my $term;
    do {
        $term = ($z**($k+$k+1)) / (($k+$k+1) * (2.0**$k) * $factK);
        $sum -= $term;
        $k++;
        $factK *= $k;

        $term = ($z**($k+$k+1)) / (($k+$k+1) * (2.0**$k) * $factK);
        $sum += $term;
        $k++;
        $factK *= $k;
    } while (abs($term) > 1e-50);

    $sum *= .398942280401432678;
    $sum += 0.5;

    return ($sum);
}

my %df;
for my $ii (-40 .. 39) {
    $df{$ii} = cdf(($ii+1)/10) * $CNT;
}
for (my $ii=39; $ii > -40; $ii--) {
    $df{$ii} -= $df{$ii-1};
}


### - Gaussian Function - ###

my (%bell, $x, $dev);

# Get random numbers and put them in bins
my $loops = 3;
LOOP1:
undef(%bell);
for (1 .. $CNT) {
    eval { $x = gaussian(10); };
    if ($@) {
        fail('gaussian(10) failed: ' . $@);
        exit(1);
    }

    # Handle 'rounding' using int()
    if ($x < 0) {
        $x = int($x) - 1;
    } else {
        $x = int($x);
    }

    # Make sure the tails don't overflow
    if ($x > 39) {
        $x = 40;
    } elsif ($x < -39) {
        $x = -40;
    }

    $bell{$x}++;
}

$dev = 0;
for my $ii (-40 .. 39) {
    my $bar1 = 3 * sqrt($df{$ii});
    my $bar2 = .025 * $df{$ii};
    my $bar = ($bar1 < $bar2) ? $bar2 : $bar1;
    if (($bell{$ii} < ($df{$ii}-$bar)) || (($df{$ii}+$bar) < $bell{$ii})) {
        $dev++;
    }
}

if (($dev > 3) && $loops--) {
    goto LOOP1;
}
ok($dev <= 3, 'Looks like a bell curve');


### - Gaussian OO - ###

my $prng;
eval { $prng = Math::Random::MT::Auto->new(); };
if (! ok(! $@, '->new() worked')) {
    diag('->new() died: ' . $@);
}
can_ok($prng, qw/rand irand gaussian exponential erlang poisson binomial
                 shuffle srand get_seed set_seed get_state set_state/);

# Get random numbers and put them in bins
$loops = 3;
LOOP2:
undef(%bell);
for (1 .. $CNT) {
    eval { $x = $prng->gaussian(10); };
    if ($@) {
        fail('$prng->gaussian(10) failed: ' . $@);
        exit(1);
    }

    # Handle 'rounding' using int()
    if ($x < 0) {
        $x = int($x) - 1;
    } else {
        $x = int($x);
    }

    # Make sure the tails don't overflow
    if ($x > 39) {
        $x = 40;
    } elsif ($x < -39) {
        $x = -40;
    }

    $bell{$x}++;
}

$dev=0;
for my $ii (-40 .. 39) {
    my $bar1 = 3 * sqrt($df{$ii});
    my $bar2 = .025 * $df{$ii};
    my $bar = ($bar1 < $bar2) ? $bar2 : $bar1;
    if (($bell{$ii} < ($df{$ii}-$bar)) || (($df{$ii}+$bar) < $bell{$ii})) {
        $dev++;
    }
}

if (($dev > 3) && $loops--) {
    goto LOOP2;
}
ok($dev <= 3, 'Looks like a bell curve');

exit(0);

# EOF
