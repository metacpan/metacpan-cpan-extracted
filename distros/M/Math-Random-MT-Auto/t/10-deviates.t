# Tests the various random deviates

use strict;
use warnings;

use Test::More 'tests' => 950;

my @WARN;
BEGIN {
    # Warning signal handler
    $SIG{__WARN__} = sub { push(@WARN, @_); };
}

use_ok('Math::Random::MT::Auto', qw(exponential erlang poisson
                                    binomial shuffle));
can_ok('Math::Random::MT::Auto', qw(exponential erlang poisson
                                    binomial shuffle));
can_ok('main', qw(exponential erlang poisson
                                    binomial shuffle));

# Check for warnings
if (! ok(! @WARN, 'Acquired seed data')) {
    diag('Seed warnings: ' . join(' | ', @WARN));
}
undef(@WARN);

my (@rn);

# Test several values from exponential()
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = exponential(); };
    ok(! $@,                        'exponential() died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok($rn[$ii] > 0.0,              'Positive: ' . $rn[$ii]);
    for my $jj (0 .. $ii-1) {
        ok($rn[$jj] != $rn[$ii],    'Randomized');
    }
}

# Test several values from erlang() for small order
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = erlang(3); };
    ok(! $@,                        'erlang(3) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok($rn[$ii] > 0.0,              'Positive: ' . $rn[$ii]);
    for my $jj (0 .. $ii-1) {
        ok($rn[$jj] != $rn[$ii],    'Randomized');
    }
}

# Test several values from erlang() for larger order
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = erlang(10); };
    ok(! $@,                        'erlang(10) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok($rn[$ii] > 0.0,              'Positive: ' . $rn[$ii]);
    for my $jj (0 .. $ii-1) {
        ok($rn[$jj] != $rn[$ii],    'Randomized');
    }
}

# Test several values from poisson() for small order
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = poisson(3); };
    ok(! $@,                        'poisson(3) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii] &&
       $rn[$ii] >= 0,               'Non-neg integer: ' . $rn[$ii]);
}

# Test several values from poisson() for large order
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = poisson(30); };
    ok(! $@,                        'poisson(30) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii] &&
       $rn[$ii] >= 0,               'Non-neg integer: ' . $rn[$ii]);
}

# Test several values from binomial() for small trial count
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = binomial(0.5, 15); };
    ok(! $@,                        'binomial(0.5, 15) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii] &&
       $rn[$ii] >= 0,               'Non-neg integer: ' . $rn[$ii]);
}

# Test several values from binomial() for small mean
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = binomial(0.01, 30); };
    ok(! $@,                        'binomial(0.01, 30) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii] &&
       $rn[$ii] >= 0,               'Non-neg integer: ' . $rn[$ii]);
}

# Test several values from binomial()
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = binomial(0.8, 50); };
    ok(! $@,                        'binomial(0.8, 50) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii] &&
       $rn[$ii] >= 0,               'Non-neg integer: ' . $rn[$ii]);
}

# Test of shuffle()
my @data = (
    [ 'xyz' ], 'abc', 1, 0.0, 1e-3, { 'q' => 42 }, sub { return (99); }
);
my $shuf;
eval { $shuf = shuffle(@data); };
ok(! $@, 'shuffle okay');
for my $x (@$shuf) {
    my $found = 0;
    for my $y (@data) {
        if (ref($x) eq 'CODE') {
            if (ref($y) eq 'CODE') {
                pass('shuffle - code ref okay');
                $found = 1;
                last;
            }
        } elsif (ref($x) eq 'ARRAY') {
            if (ref($y) eq 'ARRAY') {
                is_deeply($x, $y, 'shuffle - array okay');
                $found = 1;
                last;
            }
        } elsif (ref($x) eq 'HASH') {
            if (ref($y) eq 'HASH') {
                is_deeply($x, $y, 'shuffle - hash okay');
                $found = 1;
                last;
            }
        } elsif (Scalar::Util::looks_like_number($x)) {
            if (Scalar::Util::looks_like_number($y) && ($x == $y)) {
                pass("shuffle - $x okay");
                $found = 1;
                last;
            }
        } elsif (! ref($y) && ! Scalar::Util::looks_like_number($y) && ($x eq $y)) {
            pass("shuffle - $x okay");
            $found = 1;
            last;
        }
    }
    if (! $found) {
        fail('shuffle element not found');
    }
}
my @shuf;
eval { @shuf = shuffle(@data); };
ok(! $@, 'shuffle okay');
for my $x (@shuf) {
    my $found = 0;
    for my $y (@data) {
        if (ref($x) eq 'CODE') {
            if (ref($y) eq 'CODE') {
                pass('shuffle - code ref okay');
                $found = 1;
                last;
            }
        } elsif (ref($x) eq 'ARRAY') {
            if (ref($y) eq 'ARRAY') {
                is_deeply($x, $y, 'shuffle - array okay');
                $found = 1;
                last;
            }
        } elsif (ref($x) eq 'HASH') {
            if (ref($y) eq 'HASH') {
                is_deeply($x, $y, 'shuffle - hash okay');
                $found = 1;
                last;
            }
        } elsif (Scalar::Util::looks_like_number($x)) {
            if (Scalar::Util::looks_like_number($y) && ($x == $y)) {
                pass("shuffle - $x okay");
                $found = 1;
                last;
            }
        } elsif (! ref($y) && ! Scalar::Util::looks_like_number($y) && ($x eq $y)) {
            pass("shuffle - $x okay");
            $found = 1;
            last;
        }
    }
    if (! $found) {
        fail('shuffle element not found');
    }
}
eval { shuffle(\@data); };
ok(! $@, 'shuffle okay');
for my $x (@data) {
    my $found = 0;
    for my $y (@data) {
        if (ref($x) eq 'CODE') {
            if (ref($y) eq 'CODE') {
                pass('shuffle - code ref okay');
                $found = 1;
                last;
            }
        } elsif (ref($x) eq 'ARRAY') {
            if (ref($y) eq 'ARRAY') {
                is_deeply($x, $y, 'shuffle - array okay');
                $found = 1;
                last;
            }
        } elsif (ref($x) eq 'HASH') {
            if (ref($y) eq 'HASH') {
                is_deeply($x, $y, 'shuffle - hash okay');
                $found = 1;
                last;
            }
        } elsif (Scalar::Util::looks_like_number($x)) {
            if (Scalar::Util::looks_like_number($y) && ($x == $y)) {
                pass("shuffle - $x okay");
                $found = 1;
                last;
            }
        } elsif (! ref($y) && ! Scalar::Util::looks_like_number($y) && ($x eq $y)) {
            pass("shuffle - $x okay");
            $found = 1;
            last;
        }
    }
    if (! $found) {
        fail('shuffle element not found');
    }
}


# Create PRNG object
my $prng;
eval { $prng = Math::Random::MT::Auto->new(); };
if (! ok(! $@, '->new works')) {
    diag('->new died: ' . $@);
}
isa_ok($prng, 'Math::Random::MT::Auto');
can_ok($prng, qw(rand irand gaussian exponential erlang poisson binomial
                 shuffle get_seed set_seed get_state set_state));

# Check for warnings
if (! ok(! @WARN, 'Acquired seed data')) {
    diag('Seed warnings: ' . join(' | ', @WARN));
}
undef(@WARN);

# Test several values from exponential()
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = $prng->exponential(2); };
    ok(! $@,                        '$prng->exponential() died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok($rn[$ii] > 0.0,              'Positive: ' . $rn[$ii]);
    for my $jj (0 .. $ii-1) {
        ok($rn[$jj] != $rn[$ii],    'Randomized');
    }
}

# Test several values from erlang() for small order
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = $prng->erlang(3); };
    ok(! $@,                        '$prng->erlang(3) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok($rn[$ii] > 0.0,              'Positive: ' . $rn[$ii]);
    for my $jj (0 .. $ii-1) {
        ok($rn[$jj] != $rn[$ii],    'Randomized');
    }
}

# Test several values from erlang() for larger order
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = $prng->erlang(10); };
    ok(! $@,                        '$prng->erlang(10) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok($rn[$ii] > 0.0,              'Positive: ' . $rn[$ii]);
    for my $jj (0 .. $ii-1) {
        ok($rn[$jj] != $rn[$ii],    'Randomized');
    }
}

# Test several values from poisson() for small order
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = $prng->poisson(3); };
    ok(! $@,                        '$prng->poisson(3) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii] &&
       $rn[$ii] >= 0,               'Non-neg integer: ' . $rn[$ii]);
}

# Test several values from poisson() for large order
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = $prng->poisson(30); };
    ok(! $@,                        '$prng->poisson(30) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii] &&
       $rn[$ii] >= 0,               'Non-neg integer: ' . $rn[$ii]);
}

# Test several values from binomial() for small trial count
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = $prng->binomial(0.5, 15); };
    ok(! $@,                        '$prng->binomial(0.5, 15) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii] &&
       $rn[$ii] >= 0,               'Non-neg integer: ' . $rn[$ii]);
}

# Test several values from binomial() for small mean
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = $prng->binomial(0.01, 30); };
    ok(! $@,                        '$prng->binomial(0.01, 30) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii] &&
       $rn[$ii] >= 0,               'Non-neg integer: ' . $rn[$ii]);
}

# Test several values from binomial()
undef(@rn);
for my $ii (0 .. 9) {
    eval { $rn[$ii] = $prng->binomial(0.8, 50); };
    ok(! $@,                        '$prng->binomial(0.8, 50) died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii] &&
       $rn[$ii] >= 0,               'Non-neg integer: ' . $rn[$ii]);
}

# Test of shuffle()
eval { $shuf = $prng->shuffle($shuf); };
ok(! $@, '$prng->shuffle okay');
for my $x (@$shuf) {
    my $found = 0;
    for my $y (@data) {
        if (ref($x) eq 'CODE') {
            if (ref($y) eq 'CODE') {
                pass('$prng->shuffle - code ref okay');
                $found = 1;
                last;
            }
        } elsif (ref($x) eq 'ARRAY') {
            if (ref($y) eq 'ARRAY') {
                is_deeply($x, $y, '$prng->shuffle - array okay');
                $found = 1;
                last;
            }
        } elsif (ref($x) eq 'HASH') {
            if (ref($y) eq 'HASH') {
                is_deeply($x, $y, '$prng->shuffle - hash okay');
                $found = 1;
                last;
            }
        } elsif (Scalar::Util::looks_like_number($x)) {
            if (Scalar::Util::looks_like_number($y) && ($x == $y)) {
                pass("\$prng->shuffle - $x okay");
                $found = 1;
                last;
            }
        } elsif (! ref($y) && ! Scalar::Util::looks_like_number($y) && ($x eq $y)) {
            pass("\$prng->shuffle - $x okay");
            $found = 1;
            last;
        }
    }
    if (! $found) {
        fail('shuffle element not found');
    }
}

exit(0);

# EOF
