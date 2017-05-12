#!perl -T

use strict;
use warnings;
use Test::More tests=>3;

my $m = Ham::Resources::Utils->new();
BEGIN { use_ok('Ham::Resources::Utils') };

# Check DEC2SEXAG() function
my $degree_dec = -15.125;

ok( defined $m			, 'new() creation');


my $degree_sexag = $m->dec2sexag($degree_dec);

ok( $degree_sexag == -15.7	, 'dec2sexag ok');


done_testing();

