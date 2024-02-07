package t::RoutineTester;

use v5.14;
use warnings;

sub test_routine
{
   my ( $in, $out ) = @_;

   while( my $ref = $in->recv ) {
      my $value = $$ref;
      $out->send( \ uc $value );
   }
}

0x55AA;
