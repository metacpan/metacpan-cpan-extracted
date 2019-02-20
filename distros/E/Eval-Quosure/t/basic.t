#!perl

use strict;
use warnings;

use Test2::V0;

use Eval::Quosure;

sub foo {
    my $a = 2;
    my $b = 3;
    return Eval::Quosure->new('bar($a, $b, $c)');
}

sub bar {
    my ( $a, $b, $c ) = @_;
    return $a * $b * $c;
}

my $q = foo();

my $a = 0;    # This is not used when evaluating the quosure.
is( $q->eval( { '$c' => 7 } ), 42 );
is( $q->eval( { '$c' => 2 } ), 12 );
is( $q->eval( { '$b' => 1, '$c' => 2 } ), 4 );

sub baz {
    my $b = 7;
    return quux();
}

sub quux {
    return Eval::Quosure->new( 'bar($a, $b, $c)', 1 );
}

my $q1 = baz();

is( $q1->eval( { '$a' => 2, '$c' => 3 } ), 42 );

done_testing;
