package main;

use strict;
use warnings;

use Test::More 0.40;

{
    my $warning;

    local $SIG{__WARN__} = sub {
	$warning = $_[0];
    };

    require_ok('Geo::Coder::Geocoder::US');

    my $re = qr/ \A \Q@{[
	Geo::Coder::Geocoder::US->RETRACTION_MESSAGE() ]}\E /smx;

    like $warning, $re, 'Got correct retraction message on load';

    can_ok( 'Geo::Coder::Geocoder::US', qw{ new debug geocode response ua } );

    $warning = undef;

    my $ms = Geo::Coder::Geocoder::US->new();

    isa_ok($ms, 'Geo::Coder::Geocoder::US');

    like $warning, $re, 'Got correct retraction message on instantiation';

}

done_testing;

1;
