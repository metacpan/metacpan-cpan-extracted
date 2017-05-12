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

my %h;
test %h = (
    a => 1,
    b => 2,
    c => 3
);
++$tests && is($h{'a'}, 1, 'Hash contains a => 1');
++$tests && is($h{'b'}, 2, 'Hash contains b => 2');
++$tests && is($h{'c'}, 3, 'Hash contains c => 3');

test $h{'a'} = 5;
++$tests && is($h{'a'}, 5, 'Hash value is updated a => 5');

my $h2;
test $h2 = {};
++$tests && is(ref($h2), 'HASH', '$h2 is hashref');

test $h2->{test} = 555;
++$tests && is($h2->{test}, 555, 'Hashref can be updated test => 555');

++$tests && is(__LINE__, 42, 'Line numbering (CHECK WHICH LINE THIS IS ON)');

done_testing $tests;

#100 / 0;
