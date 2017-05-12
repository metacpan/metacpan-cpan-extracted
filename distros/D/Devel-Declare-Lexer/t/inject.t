#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;
use Devel::Declare::Lexer { test => sub { $Devel::Declare::Lexer::t::keyword_enabled } };

use Test::More;

#BEGIN { $Devel::Declare::Lexer::DEBUG = 1; }
our $keyword_enabled = 1;

my $tests = 0;

BEGIN {
    Devel::Declare::Lexer::lexed(test => sub {
        my ($stream_r) = @_;
        return $stream_r;
    });
}

my $v = 0;

test $v = 1;
++$tests && is($v, 1, 'v is set to 1');

$keyword_enabled = 0;
test $v = 5;
++$tests && isnt($v, 5, 'v is not set to 5');

$keyword_enabled = 1;
test $v = 10;
++$tests && is($v, 10, 'v is set to 10');

++$tests && is(__LINE__, 36, 'Line numbering (CHECK WHICH LINE THIS IS ON)');

done_testing $tests;

#100 / 0;
