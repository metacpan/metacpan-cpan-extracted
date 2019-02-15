#! /usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
plan 49;

ok require Datify, 'Required Datify';


my @strings = (
    ['Hello'],
    ['Hello "world"'],
    ['Hello world \o/'],
    [''],

    # Printable ASCII
    [
        ascii_printable => join( ', ', map { sprintf "%02x:%c", $_, $_ }
            0x20 .. 0x7e
        )
    ],
    #map { [ sprintf "%02x:%c", $_, $_ ] } 0x20 .. 0x7e,

    # ASCII Control characters
    [
        ascii_control => join( ', ', map { sprintf "%02x:%c", $_, $_ }
            0 .. 0x1f, 0x7f
        )
    ],
    #map { [ sprintf "%02x:%c", $_, $_ ] } 0 .. 0x1f, 0x7f,

    # Historical extended range
    [
        historical => join( ', ', map { sprintf "%02x:%c", $_, $_ }
            0x80 .. 0xff
        )
    ],
    #map { [ sprintf "%02x:%c", $_, $_ ] } 0x80 .. 0xff,

    # Special characters
    # \x22 = ", \x24 = $, \x40 = @, \x5c = \
    [
        specials => join( ', ', map { sprintf "%02x:%c", $_, $_ }
            0x22, 0x24, 0x40, 0x5c
        )
    ],
    #map( { [ sprintf "%02x:%c", $_, $_ ] } 0x22, 0x24, 0x40, 0x5c ),

    # Wide characters
    [
        wide => join( ', ', map { sprintf( '%04x:%c', $_, $_ ) }
            #0x0100 .. 0xD7FF,
            #0xE000 .. 0xFFFF
            0x00bf,    # Inverted question mark
            0x00d7,    # Multiplication sign
            0x00f7,    # Division sign
            0x03bb,    # Greek small letter lambda
            0x203c,    # Double exclamation mark
        )
    ],

    # Very Wide characters
    [
        very_wide => join( ', ', map { sprintf( '%06x:%c', $_, $_ ) }
            #0x01_0000 .. 0x10FFFF
            0x1F4A9,    # Pile of poo
        )
    ],
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

# Test UTF-8 and UTF-16 encoding
my @chars = (
    # Wide

    # Name                    Ord    UTF-8               UTF-16
    [ INVERTED_QUESTION_MARK    =>
                            0x000bf, '\xc2\xbf',         '\u00bf' ],
    [ MULTIPLICATION_SIGN       =>
                            0x000d7, '\xc3\x97',         '\u00d7' ],
    [ DIVISION_SIGN             =>
                            0x000f7, '\xc3\xb7',         '\u00f7' ],
    [ GREEK_SMALL_LETTER_LAMBDA =>
                            0x003bb, '\xce\xbb',         '\u03bb' ],
    [ DOUBLE_EXCLAMATION_MARK   =>
                            0x0203c, '\xe2\x80\xbc',     '\u203c' ],

    # Very-Wide
    [ PILE_OF_POO =>        0x1F4A9, '\xf0\x9f\x92\xa9', '\ud83d\udca9' ],
);
foreach my $char (@chars) {
    my ( $name, $ord, $utf8s, $utf16s ) = @$char;
    my $string = sprintf( '%s %06x:%c', $name, $ord, $ord );

    my $encode2 = Datify->get('encode2');
    $encode2->{$ord} = undef;   # Force this character to get encoded

    {
        $encode2->{utf} = 0;
        @{ $encode2 }{qw( wide vwide )} = qw(
            \x{%04x} \x{%06x}
        );
        Datify->set( encode2 => $encode2 );

        my $utf0s = sprintf(
            $ord <= 255 ? '\x%02x' : $ord <= 65_535 ? '\x{%04x}' : '\x{%06x}',
            $ord
        );

        my $str = Datify->stringify2($string);
        # \x22 = ", \x24 = $, \x40 = @, \x5c = \
        is $str, sprintf( '"%s %06x:%s"', $name, $ord, $utf0s ),
            "Proper escapes for \"$name\" without UTF-?";

        delete @{ $encode2 }{qw( utf vwide wide )};
        Datify->set( encode2 => $encode2 );
    }

    {
        $encode2->{utf} = 8;
        @{ $encode2 }{qw( byte2 byte3 byte4 )} = qw(
            \x%02x\x%02x \x%02x\x%02x\x%02x \x%02x\x%02x\x%02x\x%02x
        );
        Datify->set( encode2 => $encode2 );

        my $str = Datify->stringify2($string);
        # \x22 = ", \x24 = $, \x40 = @, \x5c = \
        is $str, sprintf( '"%s %06x:%s"', $name, $ord, $utf8s ),
            "Proper escapes for \"$name\" with UTF-8";

        delete @{ $encode2 }{qw( byte2 byte3 byte4 utf )};
        Datify->set( encode2 => $encode2 );
    }

    {
        $encode2->{utf}   = 16;
        $encode2->{wide}  = '\u%04x';
        $encode2->{vwide} = '\u%04x\u%04x';
        Datify->set( encode2 => $encode2 );

        my $str = Datify->stringify2($string);
        # \x22 = ", \x24 = $, \x40 = @, \x5c = \
        is $str, sprintf( '"%s %06x:%s"', $name, $ord, $utf16s ),
            "Proper escapes for \"$name\" with UTF-16";

        delete @{ $encode2 }{qw( utf vwide wide )};
        Datify->set( encode2 => $encode2 );
    }
}

