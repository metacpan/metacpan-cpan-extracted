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

use Geo::ICAO qw[ :country ];
use Test::More tests => 22;


#--
# all_country_codes()
my @codes = all_country_codes();
my %length = (); $length{ length $_ }++ foreach @codes;
is( scalar @codes, 237, 'all_country_codes() returns 234 codes' );
is( $length{1},    5,   'all_country_codes() returns 5 countries with 1-letter code' );
is( $length{2},    232, 'all_country_codes() returns countries with 2-letters codes' );
#- limiting to a region
@codes = all_country_codes('H');
is( scalar @codes, 13, 'all_country_codes() - limiting to a region' );
eval { @codes = all_country_codes('I'); };
like( $@, qr/^'I' is not a valid region code/,
      'all_country_codes() - limiting to a non-existent region' );


#--
# all_country_names()
my @names = all_country_names();
is( scalar @names, 227, 'all_country_names() returns 226 names' );
# Brazil=5, Indonesia=4, Djibouti=2
# ==> 4+3+1=8 duplicated names not counted
@names = all_country_names('H');
is( scalar @names, 12, 'all_country_names() - limiting to a region' );
eval { @names = all_country_names('I'); };
like( $@, qr/^'I' is not a valid region code/,
      'all_country_names() - limiting to a non-existent region' );


#--
# code2country()
is( code2country('LF'),   'France', 'code2country() basic usage' );
is( code2country('K'),    'USA',    'code2country() - one-letter usage' );
is( code2country('LFLY'), 'France', 'code2country() - airport code' );
is( code2country('KJFK'), 'USA',    'code2country() - airport code + one-letter' );
is( code2country('IIII'), undef,    'code2country() - airport code + unknown code' );
is( code2country('II'),   undef,    'code2country() - unknown code' );
is( code2country('I'),    undef,    'code2country() - unknown code + one-letter' );


#--
# country2code()
@codes = country2code('France');
is( scalar @codes, 1,    'country2code() basic usage' );
is( $codes[0],     'LF', 'country2code() basic usage' );
@codes = country2code('Canada');
is( scalar @codes, 1,    'country2code() - single-letter usage' );
is( $codes[0],     'C',  'country2code() - single-letter usage' );
@codes = sort( +country2code('Brazil') ); # '+' desambiguates perl56 parsing
is( scalar @codes, 7,    'country2code() - multiple-codes usage' );
is( $codes[0],     'SB', 'country2code() - multiple-codes usage' );
is( country2code('Unknown'), undef, 'country2code() - unknown name' );


exit;
