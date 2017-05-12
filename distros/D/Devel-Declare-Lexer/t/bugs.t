#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;
use Devel::Declare::Lexer qw/ :lexer_test /; # creates a lexer_test keyword and places lexed code into runtime $lexed

use Test::More;

#BEGIN { $Devel::Declare::Lexer::DEBUG = 1; }

my $tests = 0;
my $lexed;

lexer_test "A [%s] B [%s]", $answer, $question [Consent, Validate];
++$tests && is($lexed, q/lexer_test "A [%s] B [%s]", $answer, $question [Consent, Validate];/, 'With $question');

done_testing $tests;

#100 / 0;
