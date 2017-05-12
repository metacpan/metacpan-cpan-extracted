# Tests for thread sharing

use strict;
use warnings;

use Config;
BEGIN {
    if (! $Config{useithreads} || $] < 5.008) {
        print("1..0 # Skip Threads not supported\n");
        exit(0);
    }
    if ($] == 5.008) {
        print("1..0 # Skip Thread sharing support not working for Perl 5.8.0\n");
        exit(0);
    }

    if ($^O eq 'MSWin32' && $] == 5.008001) {
        print("1..0 # Skip threads::shared not working for MSWin32 5.8.1\n");
        exit(0);
    }
}


use threads;
use threads::shared;

use Test::More 'tests' => 89;

BEGIN {
    $Math::Random::MT::Auto::shared = 1;
}
use Math::Random::MT::Auto qw(set_seed get_seed set_state get_state);
can_ok('main', qw(set_seed get_seed set_state get_state));

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

my $rand;
for my $ii (0 .. 9) {
    eval { $rand = $prng->irand(); };
    ok(! $@,                     '$prng->irand() died: ' . $@);
    ok(defined($rand),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rand), 'Is a number: ' . $rand);
    ok(int($rand) == $rand,      'Integer: ' . $rand);
}

set_seed(1, 2, 4);
my @main_state = get_state();

# Get random numbers from thread
my $thr_state = threads->create(sub {
            my @seed = get_seed();
            is_deeply(\@seed, [1,2,4] => 'SA seed');
            my @state = get_state();
            is_deeply(\@state, \@main_state => 'SA state');

            set_seed(99, 99, 99);

            my $rand;
            for my $ii (0 .. 9) {
                eval { $rand = $prng->irand(); };
                ok(! $@,                     '$prng->irand() died: ' . $@);
                ok(defined($rand),           'Got a random number');
                ok(Scalar::Util::looks_like_number($rand), 'Is a number: ' . $rand);
                ok(int($rand) == $rand,      'Integer: ' . $rand);
            }
            for my $ii (0 .. 2000) {
                $rand = $prng->irand();
            }
            my @thr_state = $prng->get_state();
            return (\@thr_state);
        }
    )->join();

my @state = $prng->get_state();
is_deeply($thr_state, \@state => 'States equal');

my @seed = get_seed();
is_deeply(\@seed, [99,99,99] => 'SA seed');

exit(0);

# EOF
