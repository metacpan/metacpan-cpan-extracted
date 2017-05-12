package t::TimeAbout;

use Test::More;
use Time::HiRes qw( time );

use constant AUT => $ENV{TEST_QUICK_TIMERS} ? 0.1 : 1;

use Exporter 'import';
our @EXPORT = qw( time_about );

# Kindof like Test::Timer only we use Time::HiRes
# We'll be quite lenient on the time taken, in case of heavy test machine load
sub time_about
{
   my ( $code, $target, $name ) = @_;

   my $lower = $target*0.75;
   my $upper = $target*1.5 + 1;

   my $now = time;
   $code->();
   my $took = (time - $now) / AUT;

   cmp_ok( $took, '>', $lower, "$name took at least $lower" );
   cmp_ok( $took, '<', $upper * 3, "$name took no more than $upper" );
   if( $took > $upper and $took <= $upper * 3 ) {
      diag( "$name took longer than $upper - this may just be an indication of a busy testing machine rather than a bug" );
   }
}

0x55AA;
