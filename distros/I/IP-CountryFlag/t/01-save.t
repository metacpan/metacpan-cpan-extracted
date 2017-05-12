#!perl

use strict; use warnings;
use IP::CountryFlag;
use Test::More tests => 4;

my $countryFlag = IP::CountryFlag->new;

eval { $countryFlag->save({ 'path' => './' }); };
like($@, qr/ERROR: Missing mandatory param: ip/);

eval { $countryFlag->save({ ip => '12.215.42.19' }); };
like($@, qr/ERROR: Missing mandatory param: path/);

eval { $countryFlag->save({ ip => '12.215.42.19', path => './tt' }); };
like($@, qr/ERROR: Received invalid Path/);

eval { $countryFlag->save({ ip => '215.42.19', path => './' }); };
like($@, qr/ERROR: Received invalid IP/);
