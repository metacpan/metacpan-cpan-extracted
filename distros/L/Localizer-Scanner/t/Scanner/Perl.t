use strict;
use warnings;
use Test::More;

use File::Spec;
use File::Temp;

# We should split this plugin from the core dist.
use Localizer::Dictionary;
use Localizer::Scanner::Perl;

my $result = Localizer::Dictionary->new();
my $ext    = Localizer::Scanner::Perl->new();
$ext->scan_file($result, 't/dat/Scanner/perl.pl');
is_deeply $result->_entries,
{
    "%*(%1) counts" => {
        position => [ [ "t/dat/Scanner/perl.pl", 10 ] ]
    },
    "%1 is happy" => {
        position => [ [ "t/dat/Scanner/perl.pl", 8 ] ]
    },
    123 => {
        position => [ [ "t/dat/Scanner/perl.pl", 6 ] ]
    },
    "123\n" => {
        position => [ [ "t/dat/Scanner/perl.pl", 46 ] ]
    },
    "I \"think\" you're a cow." => {
        position => [ [ "t/dat/Scanner/perl.pl", 39 ] ]
    },
    "I'll poke you like a \"cow\" man." => {
        position => [ [ "t/dat/Scanner/perl.pl", 40 ] ]
    },
    "[*,_1,_2] counts" => {
        position => [ [ "t/dat/Scanner/perl.pl", 11 ], [ "t/dat/Scanner/perl.pl", 12 ] ]
    },
    "[*,_1] counts" => {
        position => [ [ "t/dat/Scanner/perl.pl", 9 ] ]
    },
    "[_1] is happy" => {
        position => [ [ "t/dat/Scanner/perl.pl", 7 ] ]
    },
    "example\n" => {
        position => [ [ "t/dat/Scanner/perl.pl", 71 ], [ "t/dat/Scanner/perl.pl", 77 ] ]
    },
    "foo\bar" => {
        position => [ [ "t/dat/Scanner/perl.pl", 24 ], [ "t/dat/Scanner/perl.pl", 32 ], [ "t/dat/Scanner/perl.pl", 38 ] ]
    },
    "foo\nbar" => {
        position => [ [ "t/dat/Scanner/perl.pl", 18 ], [ "t/dat/Scanner/perl.pl", 19 ], [ "t/dat/Scanner/perl.pl", 20 ] ]
    },
    "foo\nbar\n" => {
        position => [ [ "t/dat/Scanner/perl.pl", 65 ] ]
    },
    "foo \"bar\" baz" => {
        position => [ [ "t/dat/Scanner/perl.pl", 25 ], [ "t/dat/Scanner/perl.pl", 26 ], [ "t/dat/Scanner/perl.pl", 33 ], [ "t/dat/Scanner/perl.pl", 34 ] ]
    },
    "foo bar" => {
        position => [ [ "t/dat/Scanner/perl.pl", 16 ], [ "t/dat/Scanner/perl.pl", 27 ], [ "t/dat/Scanner/perl.pl", 35 ] ]
    },
    "foo\$bar" => {
        position => [ [ "t/dat/Scanner/perl.pl", 14 ]
        ]
    },
    "foo\$bar\n" => {
        position => [ [ "t/dat/Scanner/perl.pl", 58 ] ]
    },
    "foo\\\$bar" => {
        position => [ [ "t/dat/Scanner/perl.pl", 13 ] ]
    },
    "foo\\\$bar\\'baz\n" => {
        position => [ [ "t/dat/Scanner/perl.pl", 52 ] ]
    },
    "foo\\\\bar" => {
        position => [ [ "t/dat/Scanner/perl.pl", 23 ], [ "t/dat/Scanner/perl.pl", 29 ], [ "t/dat/Scanner/perl.pl", 31 ], [ "t/dat/Scanner/perl.pl", 37 ] ]
    },
    "foo\\bar" => {
        position => [ [ "t/dat/Scanner/perl.pl", 22 ], [ "t/dat/Scanner/perl.pl", 28 ], [ "t/dat/Scanner/perl.pl", 30 ], [ "t/dat/Scanner/perl.pl", 36 ] ]
    },
    "foo\\nbar" => {
        position => [ [ "t/dat/Scanner/perl.pl", 17 ] ]
    },
    "foo\\x20bar" => {
        position => [ [ "t/dat/Scanner/perl.pl", 15 ] ]
    },
    "foobar\n" => {
        position => [ [ "t/dat/Scanner/perl.pl", 21 ] ]
    },
};

done_testing;
