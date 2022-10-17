use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Refcount;

use Future;

# retain
{
   my @args;
   foreach my $method (qw( cancel done fail )) {
      my $f = Future->new;
      is_oneref( $f, 'start with refcount 1' );

      is( $f->retain, $f, '->retain returns original Future' );

      is_refcount( $f, 2, 'refcount is now increased' );

      ok( $f->$method( @args ), "can call ->$method" );
      is_oneref( $f, 'refcount drops when completed' );

      push @args, 'x';
   }
}

done_testing;
