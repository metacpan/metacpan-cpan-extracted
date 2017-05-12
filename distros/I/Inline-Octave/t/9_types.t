use strict;
use Test;
 
BEGIN {
           plan(tests => 5) ;
}
         
use Inline Octave => q{ };

use Math::Complex;

{
   my $v= [1,1,2,3 + 6*i,4];
   my $c= Inline::Octave::ComplexMatrix->new($v);
   my @l1= $c->as_list();
   ok(alleq ($v, \@l1));

   my @l2= (5*$c)->as_list();
   ok(alleq ([5,5,10,15+30*i,20], \@l2));

   my @l3= ([5-1*i]*$c)->as_list();
   ok(alleq ([5-1*i,5-1*i,10-2*i,21+27*i,20-4*i], \@l3));
}

{
   my $v= [4, -9 , 16 ];
   my $c= Inline::Octave::Matrix->new($v);
   my @l= $c->sqrt()->as_list();

   ok(alleq ([ 2, 3*i, 4], \@l));
}

   use Inline Octave => q{
      function out = countstr( str )
         out= "";
         for i=1:size(str,1)
            out= [out,sprintf("idx=%d row=(%s)\n",i, str(i,:) )];
         end
      endfunction
   };

{
   my $str= new Inline::Octave::String([ "asdf","b" ] );
   my $x=   countstr( $str );

   ok( $x->disp, "idx=1 row=(asdf)\nidx=2 row=(b   )\n");
}
  

sub alleq {
   my @l1= @{shift()};
   my @l2= @{shift()};
   for( my $i=0 ; $i < @l1; $i++) {
      return 0 unless $l1[$i] == $l2[$i];
   }
   return 1;
}
