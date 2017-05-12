use strict;
use warnings;

use Test::More tests => 8;
use_ok('Math::Symbolic');
use Math::Symbolic qw/:all/;
use_ok('Math::Symbolic::Custom::Contains');
use Math::Symbolic::Custom::Contains;

my $f = parse_from_string('m*a+c');
my $f2 = parse_from_string('g');

ok( defined($f->contains_operator(B_PRODUCT)), 'contains product' );
ok( defined($f->contains_operator(B_SUM)), 'contains sum' );
ok( !defined($f->contains_operator(B_DIVISION)), 'contains no division' );
ok( defined($f->contains_operator()), 'contains operator' );
ok( !defined($f2->contains_operator()), 'contains no operator' );

ok( $f->contains_operator(B_PRODUCT)->is_identical('m*a'), 'returns correct node' );

