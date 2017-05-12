use strict;
use Test;
BEGIN {
           plan(tests => 2) ;
}

use Data::Dumper;
$Data::Dumper::Terse= 1;
$Data::Dumper::Indent= 0;
sub structeq {
   return (Dumper($_[0]) eq Dumper($_[1])) +0;
}   
         

use Inline Octave => "DATA";

my $h= hilb(5);
my $i= inv($h);
my $ih= invhilb(5);
my $d= mse( $i, $ih);

ok ( $d->as_scalar() < .00001 );

my $m1= $i ->as_matrix();
my $m2= $ih->as_matrix();

my $sum=0;
for (my $i1= 0; $i1<5; $i1++ ) {
   for (my $i2= 0; $i2<5; $i2++ ) {
      $sum+= ( $m1->[$i1]->[$i2] -
               $m2->[$i1]->[$i2] ) ** 2;
   }
}   
      

ok ( sqrt($sum) < .00001 );



__DATA__

__Octave__
## Inline::Octave::hilb    (nargout=1)  => hilb
## Inline::Octave::invhilb (nargout=1)  => invhilb
## Inline::Octave::inv     (nargout=1)  => inv
function d=mse (a,b)
   d= sqrt( sumsq( a(:)-b(:) ) );
endfunction   

