#!/usr/bin/perl

package Devel::Declare::Lexer::Factory::t;

use strict;
use warnings;
use Devel::Declare::Lexer qw/ test /;
use Devel::Declare::Lexer::Factory qw ( _stream );
use Devel::Declare::Lexer::Token::Raw;

use Test::More;

#BEGIN { $Devel::Declare::Lexer::DEBUG = 1; }

my $tests = 0;

BEGIN {
    Devel::Declare::Lexer::lexed(test => sub {
        my ($stream_r) = @_;

        # Create a new stream from the old one (consumes declarator and whitespace)
        my @stream = _stream($stream_r, [ new Devel::Declare::Lexer::Token::Raw ( value => <<EOF
1;
sub abc
{
    my (\$a, \$b) = \@_;
    return \$a * \$b;
}
EOF
        ) ]);

        return \@stream;
    });
}

my $test;
test "abc";
++$tests && is(abc(10,10), 100, 'Using raw token');

++$tests && is(__LINE__, 40, 'Line numbering (CHECK WHICH LINE THIS IS ON)');

done_testing $tests;

#100 / 0;
