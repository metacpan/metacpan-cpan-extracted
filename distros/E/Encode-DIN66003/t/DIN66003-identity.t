#!perl -w
use strict;
use Test::More;
use charnames ':full';
use Encode 'encode', 'decode';
use Encode::DIN66003;

my @tests = (
    { known => "Hello World", bytes_66003 => "Hello World" },
    { known => "\N{LATIN CAPITAL LETTER A WITH DIAERESIS}", bytes_66003 => "\x5B" },
    { known => "\N{LATIN CAPITAL LETTER O WITH DIAERESIS}", bytes_66003 => "\x5C" },
    { known => "\N{LATIN CAPITAL LETTER U WITH DIAERESIS}", bytes_66003 => "\x5D" },
    { known => "\N{LATIN SMALL LETTER A WITH DIAERESIS}",   bytes_66003 => "\x7B" },
    { known => "\N{LATIN SMALL LETTER O WITH DIAERESIS}",   bytes_66003 => "\x7C" },
    { known => "\N{LATIN SMALL LETTER U WITH DIAERESIS}",   bytes_66003 => "\x7D" },
    { known => "\N{LATIN CAPITAL LETTER U WITH DIAERESIS}", bytes_66003 => "\x5D" },
    { known => "\N{SECTION SIGN}",                          bytes_66003 => "\x40" },
);

plan tests => 3*@tests;

for my $test (@tests) {
    my( $name ) = $test->{name} || $test->{known};
    is encode( 'DIN66003', $test->{known} ), $test->{bytes_66003}, "Encoding for '$name'";
    is decode( 'DIN66003', encode( 'DIN66003', $test->{known} )), $test->{known}, "Roundtrip for '$name'";
    is decode( 'DIN66003', $test->{bytes_66003}), $test->{known}, "Decoding for '$name'";
};

done_testing;
