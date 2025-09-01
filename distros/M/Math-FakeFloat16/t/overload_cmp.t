use strict;
use warnings;
use Math::FakeFloat16 qw(:all);

use Test::More;

my($have_gmpf, $have_gmpq) = (0, 0);

eval { require Math::GMPf };
$have_gmpf = 1 unless $@;

eval { require Math::GMPq };
$have_gmpq = 1 unless $@;

my $mpfr = Math::MPFR->new(3.875);

my @inputs = ('1.5', '-1.75', 2.625, Math::FakeFloat16->new($mpfr), 42);

if($have_gmpf) {
  my $f = Math::GMPf->new(5.25);
  push (@inputs, Math::FakeFloat16->new($f));
}
if($have_gmpq) {
  my $q = Math::GMPq->new('3/4');
  push(@inputs, Math::FakeFloat16->new($q));
}

my $nan = Math::FakeFloat16->new();

for my $v (@inputs) {
  cmp_ok($nan, '!=', $v, "NaN != $v");
  cmp_ok(defined($nan <=> $v), '==', 0, "$v: spaceship operator returns undef");
  cmp_ok(defined($v <=> $nan), '==', 0, "$v (reversed): spaceship operator returns undef");
}



for my $p(@inputs) {
  for my $q(@inputs) {
    cmp_ok(Math::FakeFloat16->new($q), '==', $p, "$q == $p") if Math::FakeFloat16->new($p) == $q;
    cmp_ok(Math::FakeFloat16->new($q), '>', $p, "$q > $p") if Math::FakeFloat16->new($p) < $q;
    cmp_ok(Math::FakeFloat16->new($q), '<', $p, "$q < $p") if Math::FakeFloat16->new($p) > $q;
    cmp_ok(Math::FakeFloat16->new($q), '>=', $p, "$q >= $p") if Math::FakeFloat16->new($p) <= $q;
    cmp_ok(Math::FakeFloat16->new($q), '<=', $p, "$q <= $p") if Math::FakeFloat16->new($p) >= $q;
    my $x = (Math::FakeFloat16->new($q) <=> $p);
    my $y = (Math::FakeFloat16->new($p) <=> $q);
    cmp_ok($x, '==', -$y, "$q <=> $p");
  }
}

my $bf = Math::FakeFloat16->new(42.5);

cmp_ok($bf, '==', 42.5, "== NV");
cmp_ok($bf, '==', '42.5', "== PV");
cmp_ok($bf, '==', Math::FakeFloat16->new(Math::MPFR->new(42.5)), "== from MPFR");

cmp_ok($bf, '<', 44.5, "< NV");
cmp_ok($bf, '<', '44.5', "< PV");
cmp_ok($bf, '<', Math::FakeFloat16->new(Math::MPFR->new(44.5)), "< from MPFR");

cmp_ok($bf, '<=', 44.5, "<= NV");
cmp_ok($bf, '<=', '44.5', "<= PV");
cmp_ok($bf, '<=', Math::FakeFloat16->new(Math::MPFR->new(44.5)), "<= from MPFR");

cmp_ok($bf, '<=', 42.5, "<= equiv NV");
cmp_ok($bf, '<=', '42.5', "<= equiv PV");
cmp_ok($bf, '<=', Math::FakeFloat16->new(Math::MPFR->new(42.5)), "<= from equiv MPFR");

cmp_ok($bf, '>=', 42.5, ">= equiv NV");
cmp_ok($bf, '>=', '42.5', ">= equiv PV");
cmp_ok($bf, '>=', Math::FakeFloat16->new(Math::MPFR->new(42.5)), ">= from equiv MPFR");

cmp_ok($bf, '>=', 40.5, ">= NV");
cmp_ok($bf, '>=', '40.5', ">= PV");
cmp_ok($bf, '>=', Math::FakeFloat16->new(Math::MPFR->new(40.5)), ">= from MPFR");

cmp_ok($bf, '>', 40.5, "> NV");
cmp_ok($bf, '>', '40.5', "> PV");
cmp_ok($bf, '>', Math::FakeFloat16->new(Math::MPFR->new(40.5)), "> from MPFR");

cmp_ok(($bf <=> 42.5), '==', 0, "<=> equiv NV");
cmp_ok(($bf <=> '42.5'), '==', 0, "<=> equiv PV");
cmp_ok(($bf <=> Math::FakeFloat16->new(Math::MPFR->new(42.5))), '==', 0, "<=> from equiv MPFR");

cmp_ok(($bf <=> 40.5), '==', 1, "<=> smaller NV");
cmp_ok(($bf <=> '40.5'), '==', 1, "<=> smaller PV");
cmp_ok(($bf <=> Math::FakeFloat16->new(Math::MPFR->new(40.5))), '==', 1, "<=> from smaller MPFR");

cmp_ok(($bf <=> 44.5), '==', -1, "<=> bigger NV");
cmp_ok(($bf <=> '44.5'), '==', -1, "<=> bigger PV");
cmp_ok(($bf <=> Math::FakeFloat16->new(Math::MPFR->new(44.5))), '==', -1, "<=> from bigger MPFR");

my $uv = ~0;
cmp_ok(Math::FakeFloat16->new($uv), '==', Math::FakeFloat16->new("$uv"), 'IV assignment == PV assignment');

###############
# Error Tests #
###############

eval{ my $x = (Math::FakeFloat16->new(1) == Math::MPFR->new(25));};
like($@, qr/^Unrecognized 2nd argument passed/, "== Math::MPFR object: \$\@ set as expected");

eval{ my $x = (Math::FakeFloat16->new() != Math::MPFR->new(25));};
like($@, qr/^Unrecognized 2nd argument passed/, "!= Math::MPFR object: \$\@ set as expected");

eval{ my $x = (Math::FakeFloat16->new() <= Math::MPFR->new(25));};
like($@, qr/^Unrecognized 2nd argument passed/, "<= Math::MPFR object: \$\@ set as expected");

eval{ my $x = (Math::FakeFloat16->new() >= Math::MPFR->new(25));};
like($@, qr/^Unrecognized 2nd argument passed/, ">= Math::MPFR object: \$\@ set as expected");

eval{ my $x = (Math::FakeFloat16->new() <=> Math::MPFR->new(25));};
like($@, qr/^Unrecognized 2nd argument passed/, "<=> Math::MPFR object: \$\@ set as expected");

eval{ my $x = (Math::FakeFloat16->new() < Math::MPFR->new(25));};
like($@, qr/^Unrecognized 2nd argument passed/, "< Math::MPFR object: \$\@ set as expected");

eval{ my $x = (Math::FakeFloat16->new() > Math::MPFR->new(25));};
like($@, qr/^Unrecognized 2nd argument passed/, "> Math::MPFR object: \$\@ set as expected");

if($have_gmpf) {
  eval{ my $x = (Math::FakeFloat16->new(1) == Math::GMPf->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "== Math::GMPf object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() != Math::GMPf->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "!= Math::GMPf object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() <= Math::GMPf->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "<= Math::GMPf object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() >= Math::GMPf->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, ">= Math::GMPf object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() <=> Math::GMPf->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "<=> Math::GMPf object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() < Math::GMPf->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "< Math::GMPf object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() > Math::GMPf->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "> Math::GMPf object: \$\@ set as expected");
}

if($have_gmpq) {
  eval{ my $x = (Math::FakeFloat16->new(1) == Math::GMPq->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "== Math::GMPq object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() != Math::GMPq->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "!= Math::GMPq object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() <= Math::GMPq->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "<= Math::GMPq object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() >= Math::GMPq->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, ">= Math::GMPq object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() <=> Math::GMPq->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "<=> Math::GMPq object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() < Math::GMPq->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "< Math::GMPq object: \$\@ set as expected");

  eval{ my $x = (Math::FakeFloat16->new() > Math::GMPq->new(25));};
  like($@, qr/^Unrecognized 2nd argument passed/, "> Math::GMPq object: \$\@ set as expected");
}

done_testing();
