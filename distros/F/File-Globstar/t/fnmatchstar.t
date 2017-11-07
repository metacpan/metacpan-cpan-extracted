# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>, 
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use strict;

use Test::More;

use File::Globstar qw(fnmatchstar translatestar);

# Tests are defined as: PATTERN, STRING, EXPECT, TESTNAME
# EXPECT and TESTNAME are optional.
my @tests = (
    ['foobar', 'foobar', 1, 'regular match'],
    ['foobar', 'barbaz', 0, 'regular mismatch'],
    ['*bar', 'foobar', 1, 'asterisk'],
    ['*bar', 'foo/bar', 0, 'slash matched asterisk'],
    ['**/baz', 'foo/bar/baz', 1, 'leading double asterisk'],
    ['foo/**/baz', 'foo/bar/bar/bar/bar/baz', 1, 'double asterisk'],
    ['foo/**', 'foo/bar/bar/bar/bar/baz', 1, 'trailing double asterisk'],
    ['foo/b***ar', 'foo/b***ar', undef, 'three asterisks are not allowed'],
    ['foo/b?r', 'foo/bar', 1, 'question mark'],
    ['foo?bar', 'foo/bar', 0, 'question mark matched slash'],
    ['foob[abc]r', 'foobar', 1, 'simple range'],
    ['foo[]bar', 'foo[]bar', 1, 'empty range not ignored'],
    ['foob[a-c]r', 'foobar', 1, 'beginning of ranged not matched'],
    ['foo[a-c]ar', 'foobar', 1, 'inner characters of ranged not matched'],
    ['fo[a-o]bar', 'foobar', 1, 'end of ranged not matched'],
    ['fo[!n-p]bar', 'foobar', 0, 'negated range matched'],
    ['fo[!a-np-z]bar', 'foobar', 1, 'negated range did not match'],
    ['foo[-xzy]bar', 'foo-bar', 1, 'leading hyphen did not work'],
    ['foo[xzy-]bar', 'foo-bar', 1, 'trailing hyphen did not work'],
    ['foo[]xyz]bar', 'foo]bar', 1, 'closing bracket not allowed as first range char'],
    ['foo[[:lower:]]ar', 'foobar', 1, 'character class did not work'],
    ['foo[[=a=]]bar', 'foo=bar', 0, 'equivalence class #1'],
    ['foo[[=a=]bar', 'foo=bar', 1, 'equivalence class #2'],
    ['foo[[.a.]]bar', 'foo.bar', 0, ' collating class #1'],
    ['foo[[.a.]bar', 'foo.bar', 1, 'collating class #2'],
    ['foo[[.a.]bar', 'foo.bar', 1, 'collating class #2'],
    ['foo[ab\\xy]bar', 'foo\\bar', 1, 'backslash inside range'],
    ['', 'foobar', 0, 'empty matches a string'],
    ['', '', 1, 'empty string does not match an empty pattern'],
);

foreach my $test (@tests) {
   my ($pattern, $string, $expect, $name) = @$test;
   my $got = fnmatchstar $pattern, $string;
   $name = '' if !defined $name;
   my $translated = eval { translatestar $pattern };
   my $x = $@;
   $translated = "[exception thrown: $x]" if defined $x;

   $name .= " (pattern '$pattern' -> '$translated')";
   if (defined $expect) {
       ok $got ^ !$expect, $name;
   } else {
       $name = $test->[-1];
       $name .= " (pattern '$pattern': no exception was thrown)";
       ok $x, $name;
   }
}

ok fnmatchstar 'foobar', 'fOobAr', ignoreCase => 1;
ok !fnmatchstar 'foobar', 'fOobAr', ignoreCase => 0;

done_testing(2 + scalar @tests);
