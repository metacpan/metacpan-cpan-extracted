#!perl -T
use strict;
use warnings;
use Test::More tests => 10;
use LWP::Simple;
#use Data::Dump qw(dump);

use_ok( 'Geo::Coder::Yahoo' );

ok(my $g = Geo::Coder::Yahoo->new(appid => 'perl-geocoder-test'), 'new geocoder');
isa_ok($g, 'Geo::Coder::Yahoo', 'isa');

SKIP: {
   skip 'Requires a network connection allowing HTTP', 5 unless get('http://www.yahoo.com/');

   ok(my $p = $g->geocode(location => 'Hollywood & Highland, Los Angeles, CA'), 'geocode Hollywood & Highland');
   ok(@$p == 1, 'got just one result');
   is($p->[0]->{zip}, '90028', 'got the right zip');

   #use Data::Dumper; 
   #warn Data::Dumper->Dump([\$p], [qw(p)]);

   ok($p = $g->geocode(city => 'Springfield'), 'geocode "Springfield"');
   #dump($p);
   ok( @$p > 5, 'there are many Springfields...');

}

ok(! eval { Geo::Coder::Yahoo->geocode() }, 'no appid');
like($@, qr/appid parameter required/, '$@ error message');
