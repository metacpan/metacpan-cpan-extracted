#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 8;

use Locale::Object::Country;
use Locale::Object::Language;

my $eng = Locale::Object::Language->new( code_alpha2 => 'en' );
                                      
#1
isa_ok( $eng, 'Locale::Object::Language');

#2
is( $eng->name, 'English', 'it has the right name' );

#3
is( $eng->code_alpha3, 'eng', 'it has the right alpha3 code' );

my @countries = @{$eng->countries};

my $count = scalar @countries;

#4
ok( $count > 0, 'found at least one country with English language' );

my $copy = Locale::Object::Language->new( code_alpha2 => 'en' );

#5
ok( $copy eq $eng, 'the object is a singleton' );

my $gb  = Locale::Object::Country->new(  code_alpha2 => 'gb'  );
my $wel = Locale::Object::Language->new( code_alpha3 => 'cym' );

#6
is( $eng->official($gb), 'true', "it's official in the correct country" );

#7
is( $wel->official($gb), 'false', "a secondary language isn't official" );

my ($wrong, $wrong_defined);

{
  # We can hide the warning, this is only a test.
  local $SIG{__WARN__} = sub {};
  eval {
    $wrong = Locale::Object::Language->new( code_alpha3 => 'XYZ' );
  };
}

defined $wrong ? $wrong_defined = 1 : $wrong_defined = 0;

#8
is( $wrong_defined, 0, 'an object was not made for an incorrect code' );

# Remove __END__ to get a dump of the data structures created by this test.
__END__
print "\n==========================\n";
print "| DATA STRUCTURE FOLLOWS |\n";
print "==========================\n\n";

use Data::Dumper;
print Dumper $eng;
