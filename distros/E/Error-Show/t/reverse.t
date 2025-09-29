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
  
  eval {throw "Die now"};
  if($@){

    my $error=$@;
    say STDERR "==========";
    my $reverse=Error::Show::context $error, reverse=>1;
    say STDERR $reverse;
    my @rlines=$reverse=~/(\d+)=>/gms;
    pop @rlines;

     my $normal=Error::Show::context $error;
    say STDERR $normal;
    my @nlines=$normal=~/(\d+)=>/gms;
    shift @nlines;
    #say STDERR "@rlines";
    #say STDERR "@nlines";




    my $ok=1;

    $i=0;
    $ok&&=($_==$nlines[$i++]) for reverse @rlines;

    ok $ok, "Stack trace reversed";


  }
}
sub middle {
  top;
}
sub bottom {
 middle;
}

bottom;

done_testing;
