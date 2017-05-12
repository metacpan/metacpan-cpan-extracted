#!perl -T

use strict;
use warnings;

use Test::More;
use Hash::Args;


{
  my $args = hash;

  ok( ref   $args eq 'HASH', 'empty list' );
  ok( keys %$args == 0,      'empty list' );
}

_fail( 'odd list',      'LIST with odd number of elements',            qw( fail ) );
_fail( 'uknown ref',    'unknown reference type (SCALAR)',             \'fail' );
_fail( 'odd array ref', 'ARRAY reference with odd number of elements', [qw( fail )] );

{
  my %args = ( foo => 'Foo', qux => 'Qux' );

  _fooqux( 'array ref', \%args, [ %args ] );
  _fooqux( 'hash ref',  \%args, \%args );
  _fooqux( 'list',      \%args,  %args );
}

{
  my $object = bless { }, 'Foo';
  my $args   = hash( $object );

  ok( "$object" eq "$args", 'object' );
}

done_testing;


sub _fail {
  my ( $test, $from, @args ) = @_;

  eval { hash( @args ) }
    and die q{A test that should have failed... well... didn't.};

  like( $@, qr/^Unable to coerce to HASH reference from \Q$from\E/, $test );
}


sub _fooqux {
  my ( $text, $source, $args ) = ( shift, shift, hash( @_ ) );

  is( $args->{$_}, $source->{$_}, $text. ' (key: '. $_. ')' )
    for keys %$source;
}
