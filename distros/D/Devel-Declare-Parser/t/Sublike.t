#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception::LessClever;

sub test { $_[-1]->( @_ ) }

BEGIN {
    use_ok( 'Devel::Declare::Parser::Sublike' );
    Devel::Declare::Interface::enhance( 'main', 'test', 'sublike' );
}

our $ran;

test( 'a', sub { $ran++, is( $_[0], 'a', "got name" ) });
is( $ran, 1, "ran enclosed" );

test a {
    $ran++;
    is( $_[0], 'a', "got name" );
}
is( $ran, 2, "ran multiline block no semicolon" );

test a {
    $ran++;
    is( $_[0], 'a', "got name" );
};
is( $ran, 3, "ran multiline block with semicolon" );

test a { $ran++; is( $_[0], 'a', "got name" ); };
is( $ran, 4, "ran singleline block with semicolon" );

test a { $ran++; is( $_[0], 'a', "got name" ); }
is( $ran, 5, "ran singleline block no semicolon" );

test 'quoted name' {
    $ran++;
    is( $_[0], 'quoted name', "got ' quoted name" );
}
is( $ran, 6, "ran singleline block no semicolon" );

test "quoted name" {
    $ran++;
    is( $_[0], 'quoted name', 'got " quoted name' );
}
is( $ran, 7, "ran singleline block no semicolon" );

test {
    $ran++;
    is( $_[0], undef, 'no name' );
}
is( $ran, 8, "ran with no name" );

ok( !eval 'test a b c { "Should not get here" } 1', "invalid syntax" );
like( $@, qr/Syntax error near: 'b' and 'c' at /, "Useful message" );

done_testing();
