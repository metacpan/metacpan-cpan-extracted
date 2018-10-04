#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 25;

ok require Datify, 'Required Datify';


my @strings = (
    ['Hello'],
    ['Hello "world"'],
    ['Hello world \o/'],
    [''],

    # Printable ASCII
    [
        printable =>
            join( ', ', map { sprintf "%02x:%s", $_, chr } 0x20 .. 0x7e )
    ],
    #map { [ sprintf "%02x:%s", $_, chr ] } 0x20 .. 0x7e,

    # ASCII Control characters
    [
        control =>
            join( ', ', map { sprintf "%02x:%s", $_, chr } 0 .. 0x1f, 0x7f )
    ],
    #map { [ sprintf "%02x:%s", $_, chr ] } 0 .. 0x1f, 0x7f,

    # Historical extended range
    [
        historical =>
            join( ', ', map { sprintf "%02x:%s", $_, chr } 0x80 .. 0xff )
    ],
    #map { [ sprintf "%02x:%s", $_, chr ] } 0x80 .. 0xff,

    # Special characters
    # \x22 = ", \x24 = $, \x40 = @, \x5c = \
    [
        specials => join( ', ',
            map { sprintf "%02x:%s", $_, chr } 0x22, 0x24, 0x40, 0x5c )
    ],
    #map( { [ sprintf "%02x:%s", $_, chr ] } 0x22, 0x24, 0x40, 0x5c ),
);
foreach my $pair (@strings) {
    my ( $name, $string ) = @$pair;
    $string = $name unless defined $string;

    my $escapes;
    my $str;

    $str = Datify->stringify1($string);
    # \x27 = ', \x5c = \
    $escapes = $string =~ tr/\x27\x5c// + $string =~ tr/\x5c//;
    is $str =~ tr/\x5c//, $escapes, "Proper escapes for '$name'";

    $str = Datify->stringify2($string);
    # \x22 = ", \x24 = $, \x40 = @, \x5c = \
    $escapes = $string =~ s/([[:cntrl:]\x22\x24\x40\x5c\x80-\x9f])/$1/g
             + $string =~ s/([\x5c])/$1/g;
    is $str =~ tr/\x5c//, $escapes, "Proper escapes for \"$name\"";

    $str = Datify->stringify($string);
    if ( $string =~ /[[:cntrl:]\x80-\x9f]/ ) {
        # \x22 = ", \x24 = $, \x40 = @, \x5c = \
        $escapes = $string =~ s/([[:cntrl:]\x22\x24\x40\x5c\x80-\x9f])/$1/g
                 + $string =~ s/([\x5c])/$1/g;
    } else {
        # \x27 = ', \x5c = \
        $escapes = $string =~ tr/\x27\x5c// + $string =~ tr/\x5c//;
    }
    is $str =~ tr/\x5c//, $escapes, "Proper escapes for  $name";
}

