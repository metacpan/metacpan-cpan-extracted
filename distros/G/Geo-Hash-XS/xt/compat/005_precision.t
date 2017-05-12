use strict;
use warnings;
use Test::More;
use Geo::Hash;

my $gh = Geo::Hash->new;
is $gh->precision('45', '-120'), 4;
is $gh->precision('45.0', '-120'), 5;
is $gh->precision('45', '-120.0'), 5;
is $gh->precision('45.00', '-120'), 6;
is $gh->precision('45', '-120.00'), 6;
is $gh->precision('45.000', '-120'), 7;
is $gh->precision('45', '-120.000'), 8;
is $gh->precision('45.00000', '-120'), 10;
is $gh->precision('45', '-120.00000'), 10;

done_testing;
