# Test if a frame stack is reversed when asked.
#
use strict;
use warnings;
use feature ":all";
use Test::More;

use Error::Show;

sub top {
  my @frames;
  my $i=0;
  push @frames, [caller $i++] while caller $i;
  my $normal=Error::Show::context frames=>\@frames;
  my @nlines=$normal=~/(\d+)=>/gms;


  my $reverse=Error::Show::context frames=>\@frames, reverse=>1;
  my @rlines=$reverse=~/(\d+)=>/gms;


  my $ok=1;

  $i=0;
  $ok&&=($_==$nlines[$i++]) for reverse @rlines;

  ok $ok, "Stack trace reversed";


}
sub middle {
  top;
}
sub bottom {
 middle;
}

bottom;

done_testing;
