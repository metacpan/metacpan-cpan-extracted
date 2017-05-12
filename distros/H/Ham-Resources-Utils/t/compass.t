#!perl -T

use strict;
use warnings;
use Test::More tests=>3;

my $m = Ham::Resources::Utils->new();
BEGIN { use_ok('Ham::Resources::Utils') };

# Check COMPASS() function
my $degree_dec = "-15.125";

ok( defined $m			, 'new() creation');


my $compass = $m->compass($degree_dec);

ok( $compass eq 'NbW',		'compass conversion completed');


done_testing();

