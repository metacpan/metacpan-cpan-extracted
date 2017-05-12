#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception::LessClever;

sub test { $_[-1]->( @_ ) }

BEGIN {
    use_ok( 'Devel::Declare::Parser::Method' );
    Devel::Declare::Interface::enhance( 'main', 'test', 'method' );
}

our $ran = 1;

test a {
    $ran++;
    is( $self, 'a', "shifted self" );
}
is( $ran, 2, "ran multiline block no semicolon" );

test a {
    $ran++;
    is( $self, 'a', "shifted self" );
};
is( $ran, 3, "ran multiline block with semicolon" );

test a { $ran++; is( $self, 'a', "shifted self" ); };
is( $ran, 4, "ran singleline block with semicolon" );

test a { $ran++; is( $self, 'a', "shifted self" ); }
is( $ran, 5, "ran singleline block no semicolon" );

test 'quoted name' {
    $ran++;
    is( $self, 'quoted name', "got ' quoted name" );
}
is( $ran, 6, "ran singleline block no semicolon" );

test "quoted name" {
    $ran++;
    is( $self, 'quoted name', 'got " quoted name' );
}
is( $ran, 7, "ran singleline block no semicolon" );

test {
    $ran++;
    is( $self, undef, 'no name' );
}
is( $ran, 8, "ran with no name" );

test a {
    $ran++;
    is( $self, 'a', 'a name' );
} if 1;
is( $ran, 9, "ran with postfix conditional" );


ok( !eval 'test a b c { "Should not get here" } 1', "invalid syntax" );
like( $@, qr/Syntax error near: 'b' and 'c' at /, "Useful message" );

done_testing();
