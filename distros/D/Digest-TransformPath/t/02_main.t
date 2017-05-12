#!/usr/bin/perl -w

# Load test the Digest::TransformPath module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}





# Does everything load?
use Test::More 'tests' => 28;
use Digest::TransformPath ();





#####################################################################
# ->new

is( Digest::TransformPath->new,        undef, 'Bad ->new returns undef' );
is( Digest::TransformPath->new(undef), undef, 'Bad ->new returns undef' );
is( Digest::TransformPath->new( \"foo" ), undef, 'Bad ->new returns undef' );
is( Digest::TransformPath->new( [ 'foo' ] ), undef, 'Bad ->new returns undef' );
is( Digest::TransformPath->new( { foo => 'bar' } ), undef, 'Bad ->new returns undef' );
is_deeply( Digest::TransformPath->new( 'Foo' ), (bless [ 'Foo' ], 'Digest::TransformPath'), 'Bad ->new returns undef' );





#####################################################################
# ->add

my $Foo = Digest::TransformPath->new('Foo');
isa_ok( $Foo, 'Digest::TransformPath' );
is( $Foo->add, undef, 'Bad ->add fails' );
is( $Foo->add(undef), undef, 'Bad ->add fails' );
is( $Foo->add(['Foo']), undef, 'Bad ->add files' );
is( $Foo->add('Bar'), 1, '->add returns true for legal value' );
is_deeply( $Foo, (bless [ 'Foo', 'Bar' ], 'Digest::TransformPath'),
	'Handles addition correctly' );
is( $Foo->add('This and that'), 1, '->add returns true for legal value' );
is_deeply( $Foo, (bless [ 'Foo', 'Bar', 'This and that' ], 'Digest::TransformPath'),
	'Handles multiple addition correctly' );




#####################################################################
# ->source_id

is( $Foo->source_id, 'Foo', '->source_id returns correct value' );





#####################################################################
# ->digest

is( $Foo->digest(undef), undef, 'Bad ->digest call returns undef' );
is( $Foo->digest([]),    undef, 'Bad ->digest call returns undef' );
is( $Foo->digest(0),     undef, 'Bad ->digest call returns undef' );
is( $Foo->digest(33),    undef, 'Bad ->digest call returns undef' );

is( $Foo->digest,     'ee12781a3ab0d1d1de99d0cb9a82fe21', '->digest     returns correct' );
is( $Foo->digest(1),  'e',                                '->digest(1)  returns correct' );
is( $Foo->digest(2),  'ee',                               '->digest(2)  returns correct' );
is( $Foo->digest(10), 'ee12781a3a',                       '->digest(10) returns correct' );
is( $Foo->digest(31), 'ee12781a3ab0d1d1de99d0cb9a82fe2',  '->digest(31) returns correct' );
is( $Foo->digest(32), 'ee12781a3ab0d1d1de99d0cb9a82fe21', '->digest(32) returns correct' );





#####################################################################
# ->new and ->add in one step

my $Foo2 = Digest::TransformPath->new( 'Foo', 'Bar', 'This and that' );
isa_ok( $Foo2, 'Digest::TransformPath' );
is_deeply( $Foo, $Foo2, '->new(id, transform) matches normal way' );
is( $Foo->digest, $Foo2->digest, '->digest for both ways match' );

1;
