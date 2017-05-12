#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;
use Devel::Declare::Lexer qw/ test /;

use Test::More;

#BEGIN { $Devel::Declare::Lexer::DEBUG = 1; }

my $tests = 0;

BEGIN {
    Devel::Declare::Lexer::lexed(test => sub {
        my ($stream_r) = @_;
        return $stream_r;
    });
}

my $s;

test $s = 'Single quoted string';
++$tests && is($s, 'Single quoted string', 'Single quotes');

test $s = "Double quoted string";
++$tests && is($s, 'Double quoted string', 'Double quotes');

test $s = "Some string interpolation using '$s'";
++$tests && is($s, "Some string interpolation using 'Double quoted string'", 'String interpolation');

test $s = q(the q operator);
++$tests && is($s, 'the q operator', 'q operator');

test $s = qq(the qq operator);
++$tests && is($s, 'the qq operator', 'qq operator');

test $s = qq(Some string interpolation with '$s');
++$tests && is($s, "Some string interpolation with 'the qq operator'", 'String interpolation with qq operator');

my $a = <<EOF
This is a heredoc
EOF
;
test $s = <<EOF
This is a heredoc
EOF
;
++$tests && is($s, $a, 'Heredocs');

my $b = "Multiline
test
with
double
quotes";
test $s = "Multiline
test
with
double
quotes";
++$tests && is($s, $b, 'Double quoted multiline');

# This is an odd one... since q is equivalent to ', a \n doesn't get
# turned into a newline, at least not when we re-output the code from
# the lexer... and since we can't output across multiple lines,
# we end up with a string literally containing \n's!
my $c = q(A multiline q test);
test $s = q(
A multiline q test
);
++$tests && is($s, $c, 'Multiline q test');

my $d = qq(A multiline qq test);
test $s = qq(
A multiline qq test
);
++$tests && is($s, $d, 'Multiline qq test');

my $e = qq(String interpolation in a '$s');
test $s = qq(
String interpolation in a '$s'
);
++$tests && is($s, $e, 'String interpolation in multiline qq');

++$tests && is(__LINE__, 86, 'Line numbering (CHECK WHICH LINE THIS IS ON)');

done_testing $tests;

#100 / 0;
