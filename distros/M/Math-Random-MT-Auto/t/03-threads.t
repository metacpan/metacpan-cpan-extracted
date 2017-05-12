# Tests for OO thread safety

use strict;
use warnings;

use Config;
BEGIN {
    if (! $Config{useithreads} || $] < 5.008) {
        print("1..0 # Skip Threads not supported\n");
        exit(0);
    }
    if ($] == 5.008) {
        print("1..0 # Skip Thread support not working for Perl 5.8.0\n");
        exit(0);
    }
}

use threads;
use Test::More 'tests' => 94;

use Math::Random::MT::Auto;

# 'Empty subclass' test  (cf. perlmodlib)
{
    package IMA::Subclass;
    use Object::InsideOut qw(Math::Random::MT::Auto);
}

# Create PRNG
my $prng;
eval { $prng = IMA::Subclass->new(); };
if (! ok(! $@, '->new worked')) {
    diag('->new died: ' . $@);
}

isa_ok($prng, 'Math::Random::MT::Auto');
isa_ok($prng, 'IMA::Subclass');
can_ok($prng, qw(rand irand gaussian exponential erlang poisson binomial
                 shuffle srand get_seed set_seed get_state set_state));

# Get random numbers from thread
my $rands = threads->create(
                        sub {
                            my @rands;
                            for (0 .. 9) {
                                my $rand = $prng->irand();
                                push(@rands, $rand);
                            }
                            for (0 .. 9) {
                                my $rand = $prng->rand(3);
                                push(@rands, $rand);
                            }
                            return (\@rands);
                        }
                    )->join();

# Check that parent gets the same numbers
my $rand;
for my $ii (0 .. 9) {
    eval { $rand = $prng->irand(); };
    ok(! $@,                     '$prng->irand() died: ' . $@);
    ok(defined($rand),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rand), 'Is a number: ' . $rand);
    ok(int($rand) == $rand,      'Integer: ' . $rand);
    ok($$rands[$ii] == $rand,    'Values equal: ' . $$rands[$ii] . ' ' . $rand);
}
for my $ii (10 .. 19) {
    eval { $rand = $prng->rand(3); };
    ok(! $@,                     '$prng->rand(3) died: ' . $@);
    ok(defined($rand),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rand), 'Is a number: ' . $rand);
    ok($$rands[$ii] == $rand,    'Values equal: ' . $$rands[$ii] . ' ' . $rand);
}

exit(0);

# EOF
