use strict;
use warnings;
use Math::Permutation;
use Test::More;
use v5.24.0;
 
eval "use PDL";
eval "use Test::PDL qw{is_pdl}";
if ($@) {
    plan skip_all => "PDL or Test::PDL is not installed."
}
else {
    plan tests => 5;
}

my $a = Math::Permutation->cycles([[1,2,3,4]]);
my $b = Math::Permutation->cycles([[1,3],[2,4]]);

$a->comp($a);

is_pdl(pdl($a->matrix), pdl($b->matrix));

for (2..5) {
    my $c = Math::Permutation->random(10);
    my $d = Math::Permutation->init(10);
    $d->clone($c);
    $d->inverse;

    is_pdl(pdl($d->matrix), pdl($c->matrix)->inv);
}

done_testing;
