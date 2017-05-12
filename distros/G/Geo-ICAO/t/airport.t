#!perl
# 
# This file is part of Geo-ICAO
# 
# This software is copyright (c) 2007 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 

use strict;
use warnings;

use Geo::ICAO qw[ :airport ];
use Test::More tests => 23;


#--
# all_airport_codes()
# - limiting to a country
my @codes = all_airport_codes('LA');
my %start = (); $start{ substr $_,0, 2 }++ foreach @codes;
is( scalar @codes, 9, 'all_airport_codes() basic country usage' );
is( $start{LA},    9, 'all_airport_codes() - all codes belong to the country' );
@codes = all_airport_codes('HK');
is( scalar @codes, 26, 'all_airport_codes() - rewinding' );
# - limiting to a region
@codes = all_airport_codes('H');
%start=(); $start{ substr $_,0, 1 }++ foreach @codes;
is( scalar @codes, 187, 'all_airport_codes() - limiting to a region' );
is( $start{H},     187, 'all_airport_codes() - limiting to a region' );
# - error handling
eval { @codes = all_airport_codes('I'); };
like( $@, qr/^'I' is not a valid region or country code/,
      'all_airport_codes() - limiting to a non-existent region' );
eval { @codes = all_airport_codes('SZ'); };
like( $@, qr/^'SZ' is not a valid region or country code/,
      'all_airport_codes() - limiting to a non-existent country' );


#--
# all_airport_names()
# - limiting to a country
my @names = all_airport_names('LA');
%start=(); $start{ substr airport2code($_), 0, 2 }++ foreach @names;
is( scalar @names, 9, 'all_airport_names() basic country usage' );
is( $start{LA},    9, 'all_airport_names() - all names belong to the country' );
@codes = all_airport_names('HK');
is( scalar @codes, 26, 'all_airport_names() - rewinding' );
# - limiting to a region
@names = all_airport_names('B');
%start=(); $start{ substr airport2code($_), 0, 1 }++ foreach @names;
is( scalar @names, 87, 'all_airport_names() - limiting to a region' );
is( $start{B},     87, 'all_airport_names() - limiting to a region' );
# - error handling
eval { @codes = all_airport_names('I'); };
like( $@, qr/^'I' is not a valid region or country code/,
      'all_airport_names() - limiting to a non-existent region' );
eval { @codes = all_airport_names('SZ'); };
like( $@, qr/^'SZ' is not a valid region or country code/,
      'all_airport_names() - limiting to a non-existent country' );


#--
# code2airport()
is  ( code2airport('LFLY'), 'Lyon Bron Airport', 'code2airport() basic usage' );
like( code2airport('LFLL'), qr/^Lyon-Saint Exu/, 'code2airport() - rewinding' );
is  ( code2airport('IIII'), undef,               'code2airport() - unknown code' );
my @details = code2airport('LFLY');
is( scalar @details, 2,      'code2airport() - list context' );
is( $details[1],     'Lyon', 'code2airport() - location' );


#--
# airport2code()
is( airport2code('Lyon Bron Airport'),  'LFLY', 'airport2code() basic usage' );
is( airport2code('Courchevel Airport'), 'LFLJ', 'airport2code() - rewinding' );
is( airport2code('Foobar Airport'),     undef,  'airport2code() - unknown name' );
is( airport2code('lyon bron airport'),  'LFLY', 'airport2code() - case insensitive' );


exit;
