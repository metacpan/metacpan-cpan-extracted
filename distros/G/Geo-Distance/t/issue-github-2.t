#!/usr/bin/env perl
use strict;
use warnings;

# https://github.com/bluefeet/Geo-Distance/issues/2
# "^" used instead of "**"

use Test::More;
use Math::Trig qw( asin );

BEGIN { use_ok('Geo::Distance') }

my $geo = Geo::Distance->new();
$geo->formula('gcd');

my $new_value = $geo->distance( 'mile', "-81.044","35.244", "-80.8272","35.1935" );
my $old_value = old_gcd( $geo, 'mile', "-81.044","35.244", "-80.8272","35.1935" );

$geo->formula('hsin');
my $control_value = $geo->distance( 'mile', "-81.044","35.244", "-80.8272","35.1935" );

ok( abs($new_value - $control_value) < 0.00000000001, 'gcd now produces same result as hsin' ) or
    diag "$new_value is not equal to $control_value";

ok( abs($old_value - $control_value) > 0.00000000001, 'old gcd did not produce same result as hsin' ) or
    diag "$old_value is equal to $control_value";

sub old_gcd {
    my($geo,$unit,$lon1,$lat1,$lon2,$lat2) = @_;

    $unit = $geo->{units}->{$unit};

    my $c = 2*asin( sqrt(
        ( sin(($lat1-$lat2)/2) )^2 + 
        cos($lat1) * cos($lat2) * 
        ( sin(($lon1-$lon2)/2) )^2
    ) );

    return $unit * $c;
}

done_testing;
