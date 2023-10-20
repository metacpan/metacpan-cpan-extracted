# Based on a demo script provided provided by Trizen.
# See https://github.com/sisyphus/math-gmpz/issues/5

# This script is the same t/random3.t, except that it
# uses a syntax to create package Number that requires
# perl-5.14.0 or later

use Math::GMPf;
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
    my $state = Math::GMPf::fgmp_randinit_mt();
    Math::GMPf::fgmp_randseed_ui($state, $srand);

    sub irand2 { # mpf_urandomb
        my ($self) = @_;
        my $x = Math::GMPf->new($$self);
        Math::GMPf::Rmpf_urandomb($x, $state, "$x" + 0, 1);
        return Number->new($x);
    }

    sub irand3 { # mpf_random2
        my ($self) = @_;
        my $x = Math::GMPf->new($$self);
        Math::GMPf::Rmpf_random2($x, $state, "$x" + 0, 1);
        return Number->new($x);
    }
}

my $x = Number->new(420);
my $second;

$second = ${$x->add($x->irand2)};

cmp_ok($$x,     '==', 420, 'TEST 1: Rmpf_urandomb ok');
cmp_ok($second, '>=', 420, 'TEST 2: Rmpf_urandomb ok');
cmp_ok($second, '<', 421, 'TEST 3: Rmpf_urandomb ok');

eval{$second = ${$x->add($x->irand3)};};
unlike($@, qr/wrong args/i, "Rmpf_random2 did not croak");

done_testing();



