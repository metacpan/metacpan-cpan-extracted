#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception::LessClever;

sub line {
    ( undef, undef, my $line ) = caller;
    return $line;
}

sub test {
    $_[0]->();
    $_[0];
}

BEGIN {
    use_ok( 'Devel::Declare::Parser::Codeblock' );
    Devel::Declare::Interface::enhance( 'main', 'test', 'codeblock' );
#    Devel::Declare::Parser::Codeblock->DEBUG(1);
}

our $ran;

test( sub { $ran++ });
ok( $ran, "ran enclosed" );

test { $ran++ }

is( $ran, 2, "ran block no semicolon" );

test { $ran++ };

is( $ran, 3, "ran block with semicolon" );

is( line(), 36, "Line numbers have not changed" );

test
{
    $ran++
}

is( $ran, 4, "ran newline block" );

ok( !eval 'test sub {1}; 1', "invalid syntax" );
like( $@, qr/Syntax error near: 'sub' at /, "Useful message" );

ok( !eval 'test a b c {1}; 1', "invalid syntax again" );
like( $@, qr/Syntax error near: 'a' and 'b' and 'c' at /, "Useful message again" );

test(
    sub { $ran++ }
);
is( $ran, 5, "ran enclosed" );

test(
    sub {
        $ran++
    }
);
is( $ran, 6, "ran enclosed" );

test
(
    sub {
        $ran++
    }
);
is( $ran, 7, "ran enclosed" );

my $ran2 = 0;
test( sub{ $ran++ }) && $ran2++;
ok( $ran2, "Works in check" );

is( line(), 75, "Line numbers have not changed" );


done_testing();
