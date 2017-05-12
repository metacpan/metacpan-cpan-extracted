package t::Unrandom;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw( unrandomly );

our $randhook;
*CORE::GLOBAL::rand = sub { $randhook ? $randhook->( $_[0] ) : rand $_[0] };

use constant VALUE => 0;
use constant BELOW => 1;

sub unrandomly(&)
{
   my $code = shift;

   my @rands;
   my $randidx;
   local $randhook = sub {
      my ( $below ) = @_;
      if( $randidx > $#rands ) {
         push @rands, [ 0, $below ];
         $randidx++;
         return 0;
      }

      if( $below != $rands[$randidx][BELOW] ) {
         die "ARGH! The function under test is nondeterministic!\n";
      }

      if( $randidx < $#rands and $rands[$randidx+1][VALUE] == $rands[$randidx+1][BELOW]-1 ) {
         die "Fell off the edge" if $rands[$randidx][VALUE] == $rands[$randidx][BELOW]-1;
         splice @rands, $randidx+1, @rands-$randidx, ();
         $rands[$randidx][VALUE]++;
         return $rands[$randidx++][VALUE];
      } 
      elsif( $randidx == $#rands ) {
         $rands[$randidx][VALUE]++;
         return $rands[$randidx++][VALUE];
      }
      else {
         return $rands[$randidx++][VALUE];
      }
   };

   while(1) {
      my $more = 0;
      $_->[VALUE] < $_->[BELOW]-1 and $more = 1 for @rands;
      last if @rands and !$more;

      $randidx = 0;
      $code->();
   }
}

1;
