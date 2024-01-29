# Based on a demo script provided provided by Trizen.
# See https://github.com/sisyphus/math-gmpz/issues/5

use Math::MPFR;
use Test::More;

package Number; #{

    sub new {
        my ($class, $n) = @_;
        bless \$n, $class;
    }

    sub add {
        my ($self, $n) = @_;
        Number->new($$self + $$n);
    }

    my $srand = 1352406084;
    my $state = Math::MPFR::Rmpfr_randinit_mt();
    Math::MPFR::Rmpfr_randseed_ui($state, $srand);

    sub irand2 { # Rmpfr_urandomb
        my ($self) = @_;
        my $x = Math::MPFR->new($$self);
        Math::MPFR::Rmpfr_urandomb($x, $state);
        return Number->new($x);
    }
#}

package main;

my $x = Number->new(420);
my $second;

$second = ${$x->add($x->irand2)};

cmp_ok($$x,     '==', 420, 'TEST 1: Rmpfr_urandomb ok');
cmp_ok($second, '>=', 420, 'TEST 2: Rmpfr_urandomb ok');
cmp_ok($second, '<',  421, 'TEST 3: Rmpfr_urandomb ok');

done_testing();



