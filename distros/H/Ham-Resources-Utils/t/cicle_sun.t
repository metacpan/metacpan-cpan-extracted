#!perl -T

use strict;
use warnings;
use Test::More tests=>5;

my $m = Ham::Resources::Utils->new();
BEGIN { use_ok('Ham::Resources::Utils') };

# Check CICLE_SUN() function
my %coord = (
	lat  => "41N13",
	long => "2W11"
);

my $date = "28-6-2012";

 
ok( defined $m			, 'new() creation');
my %sexag = $m->sexag2dec(%coord);
my %sun = $m->cicle_sun($sexag{"lat_dec"}, $sexag{"long_dec"}, $date);

ok( $sun{"sunrise"} eq "4h 38m"		, 'sunrise calculation');
ok( $sun{"sunset"} eq "19h 45m"		, 'sunset calculation');
ok( $sun{"midday"} eq "12h 12m"		, 'midday calculation');

done_testing();

