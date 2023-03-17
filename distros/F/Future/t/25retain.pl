use v5.10;
use strict;
use warnings;

use Test2::V0 0.000148; # is_refcount

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

      # Also test on immediate completed for
      #   https://rt.cpan.org/Public/Bug/Display.html?id=145168
      my $f_imm = Future->new;
      $f_imm->$method( @args );

      is( $f_imm->retain, $f_imm, '->retain on immediate returns original Future' );

      push @args, 'x';
   }
}

done_testing;
