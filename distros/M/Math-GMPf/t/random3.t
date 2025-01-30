# Based on a demo script provided provided by Trizen.
# See https://github.com/sisyphus/math-gmpz/issues/5

# This script is the same t/random2.t, except that it
# uses a more portable syntax to create package Number

use Math::GMPf;
use Test::More;

package Number;

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
package main;

my $x = Number->new(420);
my $second;

$second = ${$x->add($x->irand2)};

cmp_ok($$x,     '==', 420, 'TEST 1: Rmpf_urandomb ok');
cmp_ok($second, '>=', 420, 'TEST 2: Rmpf_urandomb ok');
cmp_ok($second, '<', 421, 'TEST 3: Rmpf_urandomb ok');

eval{$second = ${$x->add($x->irand3)};};
unlike($@, qr/wrong args/i, "Rmpf_random2 did not croak");

done_testing();



