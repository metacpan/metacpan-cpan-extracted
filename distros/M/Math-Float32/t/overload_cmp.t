use strict;
use warnings;
use Math::Float32 qw(:all);

use Test::More;

my @inputs = ('1.5', '-1.75', 2.625, 42);

my $nan = Math::Float32->new();

for my $v (@inputs) {
  cmp_ok($nan, '!=', $v, "NaN != $v");
  cmp_ok(defined($nan <=> $v), '==', 0, "$v: spaceship operator returns undef");
  cmp_ok(defined($v <=> $nan), '==', 0, "$v (reversed): spaceship operator returns undef");
}



for my $p(@inputs) {
  for my $q(@inputs) {
    cmp_ok(Math::Float32->new($q), '==', $p, "$q == $p") if Math::Float32->new($p) == $q;
    cmp_ok(Math::Float32->new($q), '>', $p, "$q > $p") if Math::Float32->new($p) < $q;
    cmp_ok(Math::Float32->new($q), '<', $p, "$q < $p") if Math::Float32->new($p) > $q;
    cmp_ok(Math::Float32->new($q), '>=', $p, "$q >= $p") if Math::Float32->new($p) <= $q;
    cmp_ok(Math::Float32->new($q), '<=', $p, "$q <= $p") if Math::Float32->new($p) >= $q;
    my $x = (Math::Float32->new($q) <=> $p);
    my $y = (Math::Float32->new($p) <=> $q);
    cmp_ok($x, '==', -$y, "$q <=> $p");
  }
}

my $bf = Math::Float32->new(42.5);

cmp_ok($bf, '==', 42.5, "== NV");
cmp_ok($bf, '==', '42.5', "== PV");

cmp_ok($bf, '<', 44.5, "< NV");
cmp_ok($bf, '<', '44.5', "< PV");

cmp_ok($bf, '<=', 44.5, "<= NV");
cmp_ok($bf, '<=', '44.5', "<= PV");

cmp_ok($bf, '<=', 42.5, "<= equiv NV");
cmp_ok($bf, '<=', '42.5', "<= equiv PV");

cmp_ok($bf, '>=', 42.5, ">= equiv NV");
cmp_ok($bf, '>=', '42.5', ">= equiv PV");

cmp_ok($bf, '>=', 40.5, ">= NV");
cmp_ok($bf, '>=', '40.5', ">= PV");

cmp_ok($bf, '>', 40.5, "> NV");
cmp_ok($bf, '>', '40.5', "> PV");

cmp_ok(($bf <=> 42.5), '==', 0, "<=> equiv NV");
cmp_ok(($bf <=> '42.5'), '==', 0, "<=> equiv PV");

cmp_ok(($bf <=> 40.5), '==', 1, "<=> smaller NV");
cmp_ok(($bf <=> '40.5'), '==', 1, "<=> smaller PV");

cmp_ok(($bf <=> 44.5), '==', -1, "<=> bigger NV");
cmp_ok(($bf <=> '44.5'), '==', -1, "<=> bigger PV");

my $uv = ~0;
cmp_ok(Math::Float32->new($uv), '==', Math::Float32->new("$uv"), 'IV assignment == PV assignment');

done_testing();
