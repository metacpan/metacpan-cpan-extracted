# Same as random3.t, but uses a different syntax (that doesn't port back
# beyond perl-5.14) to create the Number package.

# The following assignments to $second triggered an error in Math-GMPz-0.59.
# Unfortunately, there were no tests in the test suite to detect those failures.
# This script, which does detect the problem, was provided by Trizen. (Slightly
# modified and expanded by sisyhpus.)
# See https://github.com/sisyphus/math-gmpz/issues/5

use Math::GMPz;
use Test::More;

BEGIN {
  if($] < 5.014) {
    warn "Skipping all tests - version 5.14.0 or later required\n";
    is(1, 1,);
    done_testing();
    exit 0;
  }
};

package Number {

    sub new {
        my ($class, $n) = @_;
        bless \$n, $class;
    }

    sub add {
        my ($self, $n) = @_;
        Number->new($$self + $$n);
    }

    my $srand = 1171043305;
    my $state = Math::GMPz::zgmp_randinit_mt();
    Math::GMPz::zgmp_randseed_ui($state, $srand);


    sub irand1 { # mpz_urandomm
        my ($self) = @_;
        my $x = Math::GMPz->new($$self);
        Math::GMPz::Rmpz_urandomm($x, $state, $x, 1);
        return Number->new($x);
    }

    sub irand2 { # mpz_urandomb
        my ($self) = @_;
        my $x = Math::GMPz->new($$self);
        Math::GMPz::Rmpz_urandomb($x, $state, "$x" + 0, 1);
        return Number->new($x);
    }

    sub irand3 { # mpz_rrandomb
        my ($self) = @_;
        my $x = Math::GMPz->new($$self);
        Math::GMPz::Rmpz_rrandomb($x, $state, "$x" + 0, 1);
        return Number->new($x);
    }
}

my $x = Number->new(42);
my $second;

$second = ${$x->add($x->irand1)};

cmp_ok($$x,     '==', 42, 'TEST 1: Rmpz_urandomm ok');
cmp_ok($second, '>=', 42, 'TEST 2: Rmpz_urandomm ok');
cmp_ok($second, '<=', 83, 'TEST 3: Rmpz_urandomm ok');



$second = ${$x->add($x->irand2)};

cmp_ok($$x,           '==', 42,           'TEST 4: Rmpz_urandomb ok');
cmp_ok($second,      '>=',  42,           'TEST 5: Rmpz_urandomb ok');
cmp_ok($second - 42, '<',  (2 ** 42) - 1, 'TEST 6: Rmpz_urandomb ok');

$second = ${$x->add($x->irand3)};

cmp_ok($second - 42,  '>=',  0,            'TEST 7: Rmpz_rrandomb ok');
cmp_ok($second - 42,  '<',  (2 ** 42) - 1, 'TEST 8: Rmpz_rrandomb ok');
cmp_ok($second - 42, '>=', 2 ** 41,        'TEST 9: Rmpz_rrandomb ok');

done_testing();



