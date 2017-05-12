#!perl -T

use strict;
use warnings;
use Test::More tests=>4;

my $m = Ham::Resources::Utils->new();
BEGIN { use_ok('Ham::Resources::Utils') };

# Check SEXAG2DEC() function
my %coord = (
	lat  => "41N13",
	long => "2W11"
);
 
ok( defined $m			, 'new() creation');

my %sexag = $m->sexag2dec(%coord);

ok( $sexag{"lat_dec"} =~  /41.216/		, 'latitude ok');
ok( $sexag{"long_dec"} =~ /-2.183/		, 'longitude ok');


done_testing();

