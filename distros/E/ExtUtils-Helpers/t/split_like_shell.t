#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use ExtUtils::Helpers qw/split_like_shell/;

my @unix_splits =
  (
   { q{one t'wo th'ree f"o\"ur " "five" } => [ 'one', 'two three', 'fo"ur ', 'five' ] },
   { q{ foo bar }                         => [ 'foo', 'bar'                         ] },
   { q{ D\'oh f\{g\'h\"i\]\* }            => [ "D'oh", "f{g'h\"i]*"                 ] },
   { q{ D\$foo }                          => [ 'D$foo'                              ] },
   { qq{one\\\ntwo}                       => [ "one\ntwo"                           ] },  # TODO
  );

my @win_splits =
  (
   { 'a" "b\\c" "d'         => [ 'a b\c d'       ] },
   { '"a b\\c d"'           => [ 'a b\c d'       ] },
   { '"a b"\\"c d"'         => [ 'a b"c', 'd'    ] },
   { '"a b"\\\\"c d"'       => [ 'a b\c d'       ] },
   { '"a"\\"b" "a\\"b"'     => [ 'a"b a"b'       ] },
   { '"a"\\\\"b" "a\\\\"b"' => [ 'a\b', 'a\b'    ] },
   { '"a"\\"b a\\"b"'       => [ 'a"b', 'a"b'    ] },
   { 'a"\\"b" "a\\"b'       => [ 'a"b', 'a"b'    ] },
   { 'a"\\"b"  "a\\"b'      => [ 'a"b', 'a"b'    ] },
   { 'a           b'        => [ 'a', 'b'        ] },
   { "a\nb"                 => [ 'a', 'b'        ] },
   { 'a"\\"b a\\"b'         => [ 'a"b a"b'       ] },
   { '"a""b" "a"b"'         => [ 'a"b ab'        ] },
   { '\\"a\\"'              => [ '"a"'           ] },
   { '"a"" "b"'             => [ 'a"', 'b'       ] },
   { 'a"b'                  => [ 'ab'            ] },
   { 'a""b'                 => [ 'ab'            ] },
   { 'a"""b'                => [ 'a"b'           ] },
   { 'a""""b'               => [ 'a"b'           ] },
   { 'a"""""b'              => [ 'a"b'           ] },
   { 'a""""""b'             => [ 'a""b'          ] },
   { '"a"b"'                => [ 'ab'            ] },
   { '"a""b"'               => [ 'a"b'           ] },
   { '"a"""b"'              => [ 'a"b'           ] },
   { '"a""""b"'             => [ 'a"b'           ] },
   { '"a"""""b"'            => [ 'a""b'          ] },
   { '"a""""""b"'           => [ 'a""b'          ] },
   { ''                     => [                 ] },
   { ' '                    => [                 ] },
   { '""'                   => [ ''              ] },
   { '" "'                  => [ ' '             ] },
   { '""a'                  => [ 'a'             ] },
   { '""a b'                => [ 'a', 'b'        ] },
   { 'a""'                  => [ 'a'             ] },
   { 'a"" b'                => [ 'a', 'b'        ] },
   { '"" a'                 => [ '', 'a'         ] },
   { 'a ""'                 => [ 'a', ''         ] },
   { 'a "" b'               => [ 'a', '', 'b'    ] },
   { 'a " " b'              => [ 'a', ' ', 'b'   ] },
   { 'a " b " c'            => [ 'a', ' b ', 'c' ] },
);

if ($^O eq 'MSWin32') {
	plan tests => 2 * @win_splits;
	foreach my $test (@win_splits) {
		do_split_tests($test);
	}
}
else {
	plan tests => 2 * @unix_splits;
	foreach my $test (@unix_splits) {
		do_split_tests($test);
	}
}

sub do_split_tests {
	my ($test) = @_;

	my ($string, $expected) = %$test;
	my @result = split_like_shell($string);
	$string =~ s/\n/\\n/g;
	is(grep( !defined(), @result ), 0, "\"$string\" result all defined");
	is_deeply(\@result, $expected) or
	diag("split_like_shell error \n>$string< is not splitting as >" . join("|", @$expected) . '<');
}
