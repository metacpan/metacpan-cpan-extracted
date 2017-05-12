#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 17;

use DateTime::TimeZone;
use Locale::Object::Country;

my $afghanistan = Locale::Object::Country->new( code_alpha2 => 'af' );
                                      
#1
isa_ok( $afghanistan, 'Locale::Object::Country' );

#2
is( $afghanistan->name, 'Afghanistan', 'it has the correct country name');

#3
is( $afghanistan->code_alpha3, 'afg', 'it has the correct 3-letter code');

#4
is( $afghanistan->code_numeric, '004', 'it has the correct numeric code');

#5
is( $afghanistan->dialing_code, '93', 'it has the right dialing code');

#6
is( $afghanistan->currency->name, 'afghani', 'it has the correct currency');

#7
is( $afghanistan->continent->name, 'Asia', "it's on the correct continent");

my %countries;

# Fill up a hash with the alpha2 codes of countries in the same continent
foreach my $where ($afghanistan->continent->countries)
{
  # Get the alpha2 code of the country we're looking at.
  my $where_code = $where->code_alpha2;
  $countries{$where_code} = undef;
}

#8
ok( exists $countries{'tj'}, 'it has a correct neighbor on its continent');

my $copy = Locale::Object::Country->new( code_alpha2 => 'af' );

#9
is( $afghanistan->timezone->name, 'Asia/Kabul', 'it had the right timezone');

#10
ok( $copy eq $afghanistan, 'the object is a singleton');

#11
is( ($afghanistan->languages)[0]->name, 'Pushto', 'a correct language is spoken in it');

#12
is( ($afghanistan->languages_official)[0]->name, 'Pushto', 'the official language is correct');
 
my ($wrong, $wrong_defined);

{
  # We can hide the warning, this is only a test.
  local $SIG{__WARN__} = sub {};
  eval {
    $wrong = Locale::Object::Country->new( code_alpha2 => 'zz' );
  };
}

defined $wrong ? $wrong_defined = 1 : $wrong_defined = 0;

#13
is( $wrong_defined, 0, 'an object was not made for an incorrect code' );

my $britain = Locale::Object::Country->new( code_alpha2 => 'gb' );

#14
is( $britain->all_timezones->[0]->name, 'Europe/London', 'all timezones');
is( $britain->all_timezones->[1]->name, DateTime::TimeZone->links->{'Europe/Belfast'}, 'belfast is a deprecated alias for London');

ok( my $antarctica = Locale::Object::Country->new( code_alpha2 => 'aq' ), 'load Antarctica');

ok( my $congo = Locale::Object::Country->new( code_alpha2 => 'cd' ), 'load Congo');
