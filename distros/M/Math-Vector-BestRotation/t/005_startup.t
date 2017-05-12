#!perl -T

use strict;
use warnings;

use Test::More tests => 13;

BEGIN {
    use_ok('Math::Vector::BestRotation');
}

my $rot = Math::Vector::BestRotation->new;
ok(defined($rot), 'defined');
isa_ok($rot, 'Math::Vector::BestRotation', 'class ok');

isa_ok($rot->matrix_r, 'Math::MatrixReal');
for(my $i=0;$i<3;$i++) {
    for(my $j=0;$j<3;$j++) {
	is($rot->matrix_r->element($i+1, $j+1), 0, 'matrix_r init');
    }
}
