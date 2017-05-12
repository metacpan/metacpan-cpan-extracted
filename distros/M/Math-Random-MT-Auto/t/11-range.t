# Tests the Math::Random::MT::Auto::Range class

use strict;
use warnings;

use Config;

my @WARN;
BEGIN {
    # Warning signal handler
    $SIG{__WARN__} = sub { push(@WARN, @_); };

    # Try to use threads
    if ($Config{useithreads} && $] > 5.008) {
        require threads;
        threads->import();
    }
}

use Test::More 'tests' => 227;

use Math::Random::MT::Auto;
use Math::Random::MT::Auto::Range;

# Create PRNG object
my $prng;
eval { $prng = Math::Random::MT::Auto::Range->new(lo=>100, hi=>199); };
if (! ok(! $@, '->new works')) {
    diag('->new died: ' . $@);
}
isa_ok($prng, 'Math::Random::MT::Auto');
isa_ok($prng, 'Math::Random::MT::Auto::Range');
can_ok($prng, qw(rand irand gaussian exponential erlang poisson binomial
                 shuffle srand get_seed set_seed get_state set_state
                 new get_range_type set_range_type get_range set_range rrand));

# Verify hidden 'init' subroutine
if ($] > 5.006) {
    eval { $prng->_init({}); };
    if (my $e = OIO->caught()) {
        ok($e->error =~ /hidden/i, '->_init() hidden: ' . $e->error);
    } else {
        ok($@, '->_init() visible - this is bad');
    }
} else {
    ok(1, 'SKIPPED');
}

# Check for warnings
if (! ok(! @WARN, 'Acquired seed data')) {
    diag('Seed warnings: ' . join(' | ', @WARN));
}
undef(@WARN);

ok($prng->get_range_type() eq 'INTEGER', 'Int range type');
my ($lo, $hi) = $prng->get_range();
ok($lo == 100 && $hi == 199, "Range: $lo $hi");

# Test several values from rrand()
my $rr;
for my $ii (0 .. 9) {
    eval { $rr = $prng->rrand(); };
    ok(! $@,                        '$prng->rrand() died: ' . $@);
    ok(defined($rr),                'Got a random number');
    ok(Scalar::Util::looks_like_number($rr),      'Is a number: ' . $rr);
    ok(int($rr) == $rr,             'Integer: ' . $rr);
    ok($rr >= 100 && $rr <= 199,    'In range: ' . $rr);
}

# Test several values from irand()
for my $ii (0 .. 9) {
    eval { $rr = $prng->irand(); };
    ok(! $@,                        '$prng->irand() died: ' . $@);
    ok(defined($rr),                'Got a random number');
    ok(Scalar::Util::looks_like_number($rr),      'Is a number: ' . $rr);
    ok(int($rr) == $rr,             'Integer: ' . $rr);
    ok($rr >= 0,                    'Postive int: ' . $rr);
}


# New PRNG
my $prng2 = $prng->new(lo=>100, hi=>199, type=>'double');
isa_ok($prng2, 'Math::Random::MT::Auto');
isa_ok($prng2, 'Math::Random::MT::Auto::Range');
can_ok($prng2, qw(rand irand gaussian exponential erlang poisson binomial
                 shuffle srand get_seed set_seed get_state set_state
                 new get_range_type set_range_type get_range set_range rrand));

# Check for warnings
if (! ok(! @WARN, 'Acquired seed data')) {
    diag('Seed warnings: ' . join(' | ', @WARN));
}
undef(@WARN);

ok($prng2->get_range_type() eq 'DOUBLE', 'Double range type');
($lo, $hi) = $prng2->get_range();
ok($lo == 100 && $hi == 199, "Range: $lo $hi");

# Test several values from rrand()
my $ints = 0;
for my $ii (0 .. 9) {
    eval { $rr = $prng2->rrand(); };
    ok(! $@,                    '$prng2->rrand() died: ' . $@);
    ok(defined($rr),            'Got a random number');
    ok(Scalar::Util::looks_like_number($rr),  'Is a number: ' . $rr);
    if (int($rr) == $rr) {
        $ints++;
    }
    ok($rr >= 100 && $rr < 199, 'In range: ' . $rr);
}
ok($ints < 10, 'Rands not ints: ' . $ints);


### Clone

# New PRNG
my $prng3 = $prng2->clone();
isa_ok($prng3, 'Math::Random::MT::Auto');
isa_ok($prng3, 'Math::Random::MT::Auto::Range');
can_ok($prng3, qw(rand irand gaussian exponential erlang poisson binomial
                 shuffle srand get_seed set_seed get_state set_state
                 new get_range_type set_range_type get_range set_range rrand));
ok($prng3->get_range_type() eq 'DOUBLE', 'Double range type');
($lo, $hi) = $prng3->get_range();
ok($lo == 100 && $hi == 199, "Range: $lo $hi");

# Get rands from parent
my @rands2;
for (0 .. 9) {
    push(@rands2, $prng2->rrand());
}

# Get rands from clone
my @rands3;
for (0 .. 9) {
    push(@rands3, $prng3->rrand());
}

# Compare
is_deeply(\@rands2, \@rands3);


### Subclassing a subclass

# 'Empty subclass' test  (cf. perlmodlib)
{
    package Math::Random::MT::Auto::Range::Sub;
    use Object::InsideOut qw(Math::Random::MT::Auto::Range);
}

# Create PRNG object
my $prng4;
eval { $prng4 = Math::Random::MT::Auto::Range::Sub->new(lo=>-100, hi=>100); };
if (! ok(! $@, '->new works')) {
    diag('->new died: ' . $@);
}
isa_ok($prng4, 'Math::Random::MT::Auto');
isa_ok($prng4, 'Math::Random::MT::Auto::Range');
isa_ok($prng4, 'Math::Random::MT::Auto::Range::Sub');
can_ok($prng4, qw(rand irand gaussian exponential erlang poisson binomial
                 shuffle srand get_seed set_seed get_state set_state
                 new get_range_type set_range_type get_range set_range rrand));

# Check for warnings
if (! ok(! @WARN, 'Acquired seed data')) {
    diag('Seed warnings: ' . join(' | ', @WARN));
}
undef(@WARN);


### Threads with subclass

SKIP: {
if (! $threads::threads) {
    skip 'Threads not supported', 60;
}

# Get random numbers from thread
my $rands = threads->create(
                        sub {
                            my @rands;
                            for (0 .. 9) {
                                push(@rands, $prng4->rrand());
                            }
                            return (\@rands);
                        }
                    )->join();

# Check that parent gets the same numbers
my $rand;
for my $ii (0 .. 9) {
    eval { $rand = $prng4->rrand(); };
    ok(! $@,                          '$prng->rrand() died: ' . $@);
    ok(defined($rand),                'Got a random number');
    ok(Scalar::Util::looks_like_number($rand),      'Is a number: ' . $rand);
    ok(int($rand) == $rand,           'Integer: ' . $rand);
    ok($rand >= -100 && $rand <= 100, 'In range: ' . $rand);
    ok($$rands[$ii] == $rand,         'Values equal: ' . $$rands[$ii] . ' ' . $rand);
}
}

exit(0);

# EOF
