#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;

use Test::More;

use Data::Dumper;
use Devel::Declare::Lexer qw( test );
use Devel::Declare::Lexer::Tokens;

our $DEBUG = 0;

BEGIN {
    $Devel::Declare::Lexer::DEBUG = $Devel::Declare::Lexer::t::DEBUG;

    Devel::Declare::Lexer::lexed(test => sub {
        my $stream_r = shift;

        my @stream = @$stream_r;
        my @vars = $stream[7]->deinterpolate;
        my @varargs;
        my $i = 0;
        for my $var (@vars) {
            $i++;
            push @varargs, $i;
        }
        $stream[7]->{value} = $stream[7]->interpolate(@varargs);

        return \@stream;
    });
}

my $tests = 0;
my $str = undef;

use vars qw/ $a $b $c @d /;

test $str = "This is $a string\n";
++$tests && is($str, "This is 1 string\n", 'Interpolated a variable');

test $str = "This is $a $b $c string\n";
++$tests && is($str, "This is 1 2 3 string\n", 'Interpolated multiple variables');

test $str = "This is $a$b$c string\n";
++$tests && is($str, "This is 123 string\n", 'Interpolated multiple variables without whitespace');

test $str = "This is @d string\n";
++$tests && is($str, "This is 1 string\n", 'Interpolated array variable');

test $str = "This is $Devel::Declare::Lexer::t::a string\n";
++$tests && is($str, "This is 1 string\n", 'Interpolated variable with package name');

done_testing($tests);

exit;
