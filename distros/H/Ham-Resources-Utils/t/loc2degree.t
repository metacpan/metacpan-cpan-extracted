#!perl -T

use strict;
use warnings;
use Test::More tests=>4;

my $m = Ham::Resources::Utils->new();
BEGIN { use_ok('Ham::Resources::Utils') };

# Check LOC2DEGREE() function
my $loc = "JN11cj";

ok( defined $m			, 'new() creation');


my @degrees = $m->loc2degree($loc);

ok( $degrees[0] == 41.23	, 'loc2degree: degree ok');
ok( $degrees[1] ==  2.12	, 'loc2degree: minutes ok');


done_testing();

