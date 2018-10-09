#!perl -T

use strict;
use warnings;
use Test::More tests=>3;

my $m = Ham::Resources::Utils->new();
BEGIN { use_ok('Ham::Resources::Utils') };

# Check DEGREE2LOC() function
my $lat_deg = "41N23";
my $long_deg = "2E11";


ok( defined $m			, 'new() creation');

my $loc = $m->degree2loc($lat_deg, $long_deg);

ok( uc($loc) eq "JN11CJ22"		, 'locator ok');


done_testing();
