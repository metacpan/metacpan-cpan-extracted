#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;
use Devel::Declare::Lexer qw/ test function /;

use Test::More;

#BEGIN { $Devel::Declare::Lexer::DEBUG = 1; }

my $tests = 0;

BEGIN {
    Devel::Declare::Lexer::lexed(test => sub {
        my ($stream_r) = @_;
        return $stream_r;
    });
    Devel::Declare::Lexer::lexed(function => sub {
        my ($stream_r) = @_;

        my @stream = @{$stream_r};
        my @start = @stream[0..1];
        my @end = @stream[2..$#stream];

        my @output;
        tie @output, 'Devel::Declare::Lexer::Stream';

        shift @stream; # remove keyword
        shift @stream; # remove whitespace
        my $name = shift @stream; # get function name

        my @vars = ();
        while($stream[0]->{value} !~ /{/) {
            my $tok = shift @stream;
            next if ref($tok) =~ /Devel::Declare::Lexer::Token::(Left|Right)Bracket/;
            next if ref($tok) =~ /Devel::Declare::Lexer::Token::Operator/;
            next if ref($tok) =~ /Devel::Declare::Lexer::Token::Whitespace/;
           
            if(ref($tok) =~ /Devel::Declare::Lexer::Token::Variable/) {
                push @vars, [
                    $tok,
                    shift @stream
                ];
            }
        }

        push @output, @start;
        # Terminate the existing statement
        push @output, new Devel::Declare::Lexer::Token::Bareword( value => '1' );
        push @output, new Devel::Declare::Lexer::Token::EndOfStatement( value => ';' );

        # Add the sub keyword/name
        push @output, new Devel::Declare::Lexer::Token::Bareword( value => 'sub' );
        push @output, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
        push @output, $name;
        push @output, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );

        # Output the 'my (...) = @_;' line
        push @output, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
        push @output, shift @stream; # consume the {
        push @output, new Devel::Declare::Lexer::Token::Bareword( value => 'my' );
        push @output, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
        push @output, new Devel::Declare::Lexer::Token::LeftBracket( value => '(' );
        for my $var (@vars) {
            push @output, @$var;
            push @output, new Devel::Declare::Lexer::Token::Operator( value => ',' );
        }
        pop @output; # one too many commas
        push @output, new Devel::Declare::Lexer::Token::RightBracket( value => ')' );
        push @output, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
        push @output, new Devel::Declare::Lexer::Token::Operator( value => '=' );
        push @output, new Devel::Declare::Lexer::Token::Whitespace( value => ' ' );
        push @output, new Devel::Declare::Lexer::Token::Variable( value => '@_' );
        push @output, new Devel::Declare::Lexer::Token::EndOfStatement( value => ';' );

        # Stick everything else back on the end
        push @output, @stream;

        return \@output;
    });
}

my $s;
test $s = sub {
    my $a = shift;
    my $b = shift;
    my $c = $a + $b;
    $c *= 5;
    return $c;
};
++$tests && is(&$s(1,2), 15, 'Multiline subs');

# This is a bit strange.
# What actually happens is the lexer only gets as far as the first semi-colon on the second line, then exits.
# Its fine because the rest doesn't matter, for this example, and all remaining lines are left intact!
# 
# This also means that any Lexer keywords used after the first line of the function will get parsed properly
#
# FIXME this probably means the lexers understanding of blocks needs improving - i.e., nested bracket tracking
# TODO add a callback to control when the lexer ends, so we can stop at the first {
# (or skip past the first ;?
function something ($a, $b) {
    return 5 * ($a + $b);
};
++$tests && is(something(1,2), 15, 'Function definition');

++$tests && is(__LINE__, 109, 'Line numbering (CHECK WHICH LINE THIS IS ON)');

done_testing $tests;

#100 / 0;
