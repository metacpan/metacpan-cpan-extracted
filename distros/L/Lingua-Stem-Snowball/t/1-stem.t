#!/usr/bin/perl

use strict;
use Test::More;
use Lingua::Stem::Snowball qw(:all);

my @languages = stemmers();

plan tests => scalar(@languages) + 17;

for my $language (@languages) {
    is( 'Lingua::Stem::Snowball',
        ref Lingua::Stem::Snowball->new( lang => $language ),
        "construct stemmer for lang => '$language'"
    );
}

my $stemmer;

$stemmer = Lingua::Stem::Snowball->new( lang => $languages[0] );
is( 'Lingua::Stem::Snowball', ref($stemmer), "constuct a stemmer" );
is( $stemmer->lang, $languages[0], "stemmer has the expected language" );

$stemmer = Lingua::Stem::Snowball->new();
is( 'Lingua::Stem::Snowball', ref($stemmer),
    "Construct stemmer with no args" );
is( $stemmer->lang, '', "stemmer has empty string for language" );
$stemmer->lang( $languages[0] );
is( $stemmer->lang, $languages[0], "reset the language", );
$stemmer->lang('nothing');
is( $stemmer->lang, $languages[0],
    "resetting the language to an invalid value silently fails" );
$stemmer->lang( uc( $languages[0] ) );
is( $stemmer->lang, $languages[0],
    "tolerate uppercase versions of ISO codes" );

$stemmer = Lingua::Stem::Snowball->new();
is( $stemmer->stem('foo'), undef, "with no lang, stem returns undef" );
is( $stemmer->stem(), undef, "with no input, stem returns undef" );

# Test for bug #7510 - [ not really, bug 7510 has to do with subclassing ]
is( stem( 'fr', 'été' ),    'été',  "functional interface" );
is( stem( 'en', 'horses' ), 'hors', "functional interface" );

# Tests for bug #7509
$stemmer = Lingua::Stem::Snowball->new();
is( 'Lingua::Stem::Snowball', ref($stemmer), "it's a Snowball, alright" );
is( $stemmer->lang, '', "empty language" );
$stemmer->lang('nothing');
is( $@,
    "Language 'nothing' does not exist",
    "correct error message for invalid language"
);

# Test for mixed case words
is( stem( 'fr', 'AIMERA' ),
    stem( 'fr', 'aimera' ),
    "stemmer lowercases uppercase source"
);

# Test for bug #13900
$stemmer = Lingua::Stem::Snowball->new( lang => 'en' );
my @stemmable = ( '', undef, 'foo', 'bar', '' );
my @stemmed = $stemmer->stem( \@stemmable );
is( scalar(@stemmable), scalar(@stemmed),
    "don't strip empty array elements" );

# Test for ticket #13898
$stemmer = Lingua::Stem::Snowball->new( lang => 'en' );
@stemmable = ( 'foo', 'ranger\'s', 'bar' );
my @stemmed_ok = ( 'foo', 'ranger', 'bar' );
$stemmer->strip_apostrophes(1);
@stemmed = $stemmer->stem( \@stemmable );
ok( eq_array( \@stemmed_ok, \@stemmed ), "apostrophe s" );

