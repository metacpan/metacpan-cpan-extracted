#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 5;

use Locale::Object::Continent;
use Locale::Object::Country;

my $asia = Locale::Object::Continent->new( name => 'Asia' );

#1
isa_ok( $asia, 'Locale::Object::Continent' );

my $cont_name = $asia->name;

#2
is( $cont_name, 'Asia', 'it has the correct name' );

#3
is( scalar @{$asia->countries}, 47, 'it has the correct number of countries in it' );

my %countries;

# Fill up a hash with the alpha2 codes of countries in $asia.
foreach my $where ($asia->countries)
{
  # Get the alpha2 code of the country we're looking at.
  my $where_code = $where->code_alpha2;
  $countries{$where_code} = undef;
}

#4
ok( exists $countries{'af'}, 'a country in it has the right name' );

my $copy = Locale::Object::Continent->new( name => 'Asia' );

#5
ok( $copy eq $asia, 'the object is a singleton' );

# Remove __END__ to get a dump of the data structures created by this test.
__END__
print "\n==========================\n";
print "| DATA STRUCTURE FOLLOWS |\n";
print "==========================\n\n";

use Data::Dumper;
print Dumper $asia;
