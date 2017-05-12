#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 10;

use Locale::Object::Currency;

my $usd = Locale::Object::Currency->new( country_code => 'us' );
                                      
#1
isa_ok( $usd, 'Locale::Object::Currency' );

#2
is( $usd->name, 'dollar', 'it has the right name' );

#3
is( $usd->code, 'USD', 'it has the right code' );

#4
is( $usd->code_numeric, '840', 'it has the right numeric code' );

#5
is( $usd->symbol, '$', 'it has the right symbol' );

#6
is( $usd->subunit, 'cents', 'it has the right subunit' );

#7
is( $usd->subunit_amount, '100', 'it has the right subunit amount' );

my @countries = @{$usd->countries};

my $count = scalar @countries;

#8
is( $count, 12, 'the number of countries sharing it is correct' );

# The code/name mapping of objects in %countries should be consistent with this.
my %names = (
             as => "American Samoa",
             gu => "Guam",
             pw => "Palau",
             pr => "Puerto Rico",
             tc => "Turks and Caicos Islands",
             us => "United States",
             vi => "Virgin Islands, U.S.",
             vg => "Virgin Islands, British"
            );
            
my @places = keys %names;
my $where = $places[rand @places];

my $copy = Locale::Object::Currency->new( country_code => 'us' );

#9
ok( $copy eq $usd, 'the object is a singleton' );

my ($wrong, $wrong_defined);

{
  # We can hide the warning, this is only a test.
  local $SIG{__WARN__} = sub {};
  eval {
      $wrong = Locale::Object::Currency->new( code => 'xyz' );
  };
}

defined $wrong ? $wrong_defined = 1 : $wrong_defined = 0;

#10
is( $wrong_defined, 0, 'an object was not made for an incorrect code' );

# Remove __END__ to get a dump of the data structures created by this test.
__END__
print "\n==========================\n";
print "| DATA STRUCTURE FOLLOWS |\n";
print "==========================\n\n";

use Data::Dumper;
print Dumper $usd;
