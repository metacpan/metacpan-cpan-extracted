use strict;
use utf8;

use Test::More tests => 2 + 36;

BEGIN {
    use_ok('Email::MIME::RFC2047::Decoder');
};

my $decoder = Email::MIME::RFC2047::Decoder->new();
ok(defined($decoder), 'new');

my @tests = (
    # invalid encoded words
    '=?iso-8859-1?Q?text text?=', '=?iso-8859-1?Q?text text?=',
    '=?iso-8859-1?Q?text?text?=', '=?iso-8859-1?Q?text?text?=',
    'text=?iso-8859-1?q?text?=', 'text=?iso-8859-1?q?text?=',
    '=?iso-8859-1?q?text?=text', '=?iso-8859-1?q?text?=text',
    '=?iso-8859-1?b?----?=', '=?iso-8859-1?b?----?=',
    '"=?US-ASCII?Q?text?="', '=?US-ASCII?Q?text?=',
    '" =?US-ASCII?Q?text?= "', '=?US-ASCII?Q?text?=',
    '=?utf-8?Q?C=c3?= text =?US-ASCII?Q?text?=', '=?utf-8?Q?C=c3?= text text',
    '"text"=?US-ASCII?Q?text?=', 'text=?US-ASCII?Q?text?=',
    # whitespace
    '  "  a  "  b  "  c  "  ', 'a b c',
    ' a "b" c ', 'a b c',
    ' a" b" c ', 'a b c',
    ' a"b"c ', 'abc',
    ' =?US-ASCII?Q?text?= a =?US-ASCII?Q?text?= ', 'text a text',
    # nasty characters
    '=?US-ASCII?Q?a=00b=1fc=7fd?=', 'abcd',
    # unknown encoding
    '=?foo-bar?q?unknown?=', '=?foo-bar?q?unknown?=',
    # comments
    '(this is a (nested) comment)x', 'x',
    '("text")x', 'x',
    '( =?US-ASCII?Q?text?= ) abc', 'abc',
    '(' x 100 . 'c' . ')' x 100 . 'x', 'x',
    '(a' x 100 . 'b' . 'c)' x 100 . 'x', 'x',
    # obsolete syntax
    'Alfred E. Neumann', 'Alfred E. Neumann',
    # examples from the RFC
    '=?US-ASCII?Q?Keith_Moore?=', 'Keith Moore',
    '=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?=', 'Keld Jørn Simonsen',
    '=?ISO-8859-1?Q?Andr=E9?= Pirard', 'André Pirard',
    "=?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?=\n =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?=", 'If you can read this you understand the example.',
    '=?ISO-8859-1?Q?Olle_J=E4rnefors?=', 'Olle Järnefors',
    '=?ISO-8859-1?Q?Patrik_F=E4ltstr=F6m?=', 'Patrik Fältström',
    '=?iso-8859-8?b?7eXs+SDv4SDp7Oj08A==?=', 'םולש ןב ילטפנ',
    '=?ISO-8859-1?Q?a?=', 'a',
    '=?ISO-8859-1?Q?a?= b', 'a b',
    '=?ISO-8859-1?Q?a?= =?ISO-8859-1?Q?b?=', 'ab',
    '=?ISO-8859-1?Q?a?=  =?ISO-8859-1?Q?b?=', 'ab',
    "=?ISO-8859-1?Q?a?=\n    =?ISO-8859-1?Q?b?=", 'ab',
    '=?ISO-8859-1?Q?a_b?=', 'a b',
    '=?ISO-8859-1?Q?a?= =?ISO-8859-2?Q?_b?=', 'a b',
);

for (my $i=0; $i<@tests; $i+=2) {
    my ($encoded, $expect) = ($tests[$i], $tests[$i+1]);

    my $decoded = $decoder->decode_phrase($encoded);
    is($decoded, $expect, "decode_phrase $encoded");
}

