#!/usr/bin/perl -w

use strict;
use integer;

use Lingua::EN::NameCase qw( NameCase nc );
use Test::More  tests => 31;

my $debugging = 0;

# Set up data for the tests.
my @proper_names = (
    "Keith",            "Leigh-Williams",       "McCarthy",
    "O'Callaghan",      "St. John",             "von Streit",
    "van Dyke",         "Van",                  "ap Llwyd Dafydd",
    "al Fahd",          "Al",
    "el Grecco",
    "Ben Gurion",       "Ben",  
    "da Vinci",
    "di Caprio",        "du Pont",              "de Legate",
    "del Crond",        "der Sind",             "van der Post",
    "von Trapp",        "la Poisson",           "le Figaro",
    "Mack Knife",       "Dougal MacDonald",
);

# Mac exceptions
my @mac_names = (
    "Machin",           "Machlin",              "Machar",
    "Mackle",           "Macklin",              "Mackie",
    "Macquarie",        "Machado",              "Macevicius",
    "Maciulis",         "Macias",               "MacMurdo",
    "Mackrell",         "Maclin",               "McConnachie",
);

# Roman numerals
my @roman_names = (
    "Henry VIII",       "Louis III",            "Louis XIV",
    "Charles II",       "Fred XLIX",
);

push @proper_names, @mac_names, @roman_names;

# Set up some module globals.
my @lowercase_names = map { lc } @proper_names;
my @names = @lowercase_names;
my @result;
my $name;
my $fixed_name;

$" = ", " ; #"

# Print the original.
diag("\tOriginal:\n@lowercase_names.\n") if $debugging;

# Test an array without changing the array's contents; print the first result.
@result = NameCase( @names );
diag("\tResult:\n@result.\n")                                   if $debugging;
diag("\nArray assignment with source array passed by copy...")  if $debugging;

is_deeply( \@names,  \@lowercase_names, 'Array assignment with source array passed by copy' );
is_deeply( \@result, \@proper_names,    '.. fixed' );

# Test an array without changing the array's contents;
# but pass the array by reference.
@result = ();
@result = NameCase( \@names );
is_deeply( \@names,  \@lowercase_names, 'Array assignment with source array passed by reference' );
is_deeply( \@result, \@proper_names,    '.. fixed' );

# Test an array in-place.
NameCase( \@names );
is_deeply( \@names, \@proper_names, 'In-place with source array passed by reference' );

# Test a scalar in-place.
$name = $lowercase_names[1];
NameCase( \$name );
is( $name, $lowercase_names[1], 'In-place scalar (null operation)' );

# Test a scalar.
$name = $lowercase_names[1];
$fixed_name = NameCase( $name );
is( $fixed_name, $proper_names[1], 'Scalar...' );

# Test a literal scalar.
$fixed_name = NameCase( "john mcvey" );
is( $fixed_name, "John McVey", 'Literal scalar...' );

# Test a literal array.
@result = NameCase( "nancy", "drew" );
is_deeply( \@result, [ "Nancy", "Drew" ], 'Literal array...' );

# Test a scalar.
$name = $lowercase_names[1];
$fixed_name = nc $name;
is( $fixed_name, $proper_names[1], 'Scalar as list operator...' );

# Test a literal scalar.
$fixed_name = nc "john mcvey";
is( $fixed_name, "John McVey", 'Literal scalar as list operator...' );

# Test a reference to a scalar.
$name = $lowercase_names[1];
$fixed_name = nc( \$name );
is( $name, $lowercase_names[1],'Reference to a scalar using nc...' );
is( $fixed_name, $proper_names[1],'.. fixed' );

# Test a scalar in an array context.
$name = $lowercase_names[1];
@result = nc $name;
is( $result[0], $proper_names[1], 'Scalar in a list context using nc...');

# Test a reference to a scalar in an array context.
$name = $lowercase_names[1];
@result = nc \$name;
print "Reference to a scalar in a list context using nc..."
if $debugging;
print "" . ( $name eq $lowercase_names[1] ? "ok" : "not ok\a" )
if $debugging;
is( $name, $lowercase_names[1], 'Reference to a scalar in a list context using nc...');
is( $result[0], $proper_names[1], '.. fixed');

# Test a reference to a scalar.
$name = $lowercase_names[1];
$fixed_name = NameCase( \$name );
is( $name, $lowercase_names[1], 'Reference to a scalar using NameCase...' );
is( $fixed_name, $proper_names[1], '.. fixed' );

# Test a scalar in an array context.
$name = $lowercase_names[1];
@result = NameCase $name;
is( $result[0], $proper_names[1], 'Scalar in a list context using NameCase...' );

# Test a reference to a scalar in an array context.
$name = $lowercase_names[1];
@result = NameCase \$name;
is( $name, $lowercase_names[1], 'Reference to a scalar in a list context using NameCase...' );
is( $result[0], $proper_names[1], '.. fixed');

$Lingua::EN::NameCase::SPANISH = 1;
is( nc( 'El Paso' ), 'El Paso', 'spanish' );
is( nc( 'La Luna' ), 'La Luna', 'spanish' );
$Lingua::EN::NameCase::SPANISH = 0;
is( nc( 'El Paso' ), 'el Paso', 'not spanish' );
is( nc( 'La Luna' ), 'la Luna', 'not spanish' );

$Lingua::EN::NameCase::ROMAN = 1;
is( nc( 'Na Li' ), 'Na LI', 'roman numerals' );
$Lingua::EN::NameCase::ROMAN = 0;
is( nc( 'Na Li' ), 'Na Li', 'not roman numerals' );

$Lingua::EN::NameCase::POSTNOMINAL = 1;
is( nc( 'Barbie PHD' ), 'Barbie PhD', 'post nominal initials' );
$Lingua::EN::NameCase::POSTNOMINAL = 0;
is( nc( 'Barbie PHD' ), 'Barbie Phd', 'not post nominal initials' );

$Lingua::EN::NameCase::HEBREW = 1;
is( nc( 'Aharon BEN Amram Ha-Kohein' ), 'Aharon ben Amram Ha-Kohein', 'hebrew' );
$Lingua::EN::NameCase::HEBREW = 0;
is( nc( 'Aharon BEN Amram Ha-Kohein' ), 'Aharon Ben Amram Ha-Kohein', 'not hebrew' );
