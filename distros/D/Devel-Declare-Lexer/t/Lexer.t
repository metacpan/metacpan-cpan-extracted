#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;
#use Devel::Declare::Lexer qw/ :lexer_test /; # creates a lexer_test keyword and places lexed code into runtime $lexed
use Devel::Declare::Lexer qw/ :lexer_test lexer_test2 /; # creates a lexer_test keyword and places lexed code into runtime $lexed

use Test::More;

#BEGIN { $Devel::Declare::Lexer::DEBUG = 1; }

my $tests = 0;
my $lexed;

BEGIN {
    Devel::Declare::Lexer::lexed(lexer_test2 => sub {
        my ($stream_r) = @_;
        my @stream = @$stream_r;

        my $string = $stream[2]; # keyword [whitespace] "string"
        $string->{value} =~ tr/pi/do/;

        my @ns = ();
        tie @ns, "Devel::Declare::Lexer::Stream";

        push @ns, (
            new Devel::Declare::Lexer::Token::Declarator( value => 'lexer_test2' ),
            new Devel::Declare::Lexer::Token::Whitespace( value => ' ' ),
            new Devel::Declare::Lexer::Token( value => 'my' ),
            new Devel::Declare::Lexer::Token::Variable( value => '$lexer_test2'),
            new Devel::Declare::Lexer::Token::Whitespace( value => ' ' ),
            new Devel::Declare::Lexer::Token::Operator( value => '=' ),
            new Devel::Declare::Lexer::Token::Whitespace( value => ' ' ),
            $string,
            new Devel::Declare::Lexer::Token::EndOfStatement,
            new Devel::Declare::Lexer::Token::Newline,
        );

        return \@ns;
    });
}

lexer_test2 "pigs in blankets";
++$tests && is($lexer_test2, q|dogs on blankets|, 'Lexer callback');

lexer_test "this is a test";
++$tests && is($lexed, q|lexer_test "this is a test";|, 'Strings');

lexer_test "this", "is", "another", "test";
++$tests && is($lexed, q|lexer_test "this", "is", "another", "test";|, 'List of strings');

lexer_test { "this", "is", "a", "test" };
++$tests && is($lexed, q|lexer_test { "this", "is", "a", "test" };|, 'Hashref list of strings');

lexer_test ( "this", "is", "a", "test" );
++$tests && is($lexed, q|lexer_test ( "this", "is", "a", "test" );|, 'Array of strings');

my $a = 1;
lexer_test ( $a + $a );
++$tests && is($lexed, q|lexer_test ( $a + $a );|, 'Variables and operators');
lexer_test ( $a != $a );
++$tests && is($lexed, q|lexer_test ( $a != $a );|, 'Inequality operator');

my $longer_name = 1234;
lexer_test ( !$longer_name );
++$tests && is($lexed, q|lexer_test ( !$longer_name );|, 'Negative operator and complex variable names');
lexer_test ( \$longer_name );
++$tests && is($lexed, q|lexer_test ( \$longer_name );|, 'Referencing operator');

my $ln_ref = \$longer_name;
lexer_test ( $$ln_ref );
++$tests && is($lexed, q|lexer_test ( $$ln_ref );|, 'Dereferencing operator');

lexer_test q(this is a string);
++$tests && is($lexed, q|lexer_test q(this is a string);|, 'q quoting operator');

lexer_test abc();
++$tests && is($lexed, q|lexer_test abc();|, 'sub call with parentheses');

lexer_test q(this
is
a
multiline);
++$tests && is($lexed, qq|lexer_test q(this\nis\na\nmultiline);|, 'q quoting operator with multiline');

lexer_test ( {
    abc => 2,
    def => 4,
} );
++$tests && is($lexed, q|lexer_test ( {
    abc => 2,
    def => 4,
} );|, 'Hashref multiline');

    lexer_test
        "test string",
        $a,
        $b
        ;
++$tests && is($lexed, q|lexer_test
        "test string",
        $a,
        $b
        ;|, 'Normal multiline');

# FIXME a \n inside a block breaks line numbering
lexer_test {
    print "1";
    print "2";
    print "3";
    print "...";
};
++$tests && is($lexed, q|lexer_test {
    print "1";
    print "2";
    print "3";
    print "...";
};|, 'Block');

lexer_test 1 || 1;
++$tests && is($lexed, q/lexer_test 1 || 1;/, 'Or in statement');

lexer_test 1 && 1;
++$tests && is($lexed, q/lexer_test 1 && 1;/, 'And in statement');

lexer_test 1 |= 1;
++$tests && is($lexed, q/lexer_test 1 |= 1;/, 'Or equals in statement');

++$tests && is(__LINE__, 131, 'Line numbering (CHECK WHICH LINE THIS IS ON)');

done_testing $tests;

#100 / 0;
