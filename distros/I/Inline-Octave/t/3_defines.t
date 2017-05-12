use strict;
use Test;
BEGIN {
           plan(tests => 4) ;
}

use Data::Dumper;
$Data::Dumper::Terse= 1;
$Data::Dumper::Indent= 0;
sub structeq {
   return (Dumper($_[0]) eq Dumper($_[1])) +0;
}   
         

use Inline Octave => "DATA";

my $c= new Inline::Octave::Matrix([ [1.5,2,3],[4.5,1,-1] ]);
   
my ($b, $t)= jnk2( $c, [4,4],[5,6] );

ok ( structeq( [$t->as_list()], ["6"] ) );

ok ( structeq( $b->as_matrix(),
              [['46.5','47','48'],['49.5','46','44']]
             ));

ok ( structeq( $c->sub_matrix([2,1],[2,3]) ,
              [['1','-1'],['2','3']]
             ));

my $idx= new Inline::Octave::Matrix( [ 1 .. 3 ] );

ok ( structeq( $c->sub_matrix([2,1], $idx->transpose() ),
              [['4.5','1','-1'],['1.5','2','3']]
             ));




__DATA__

__Octave__
   function [b,t]=jnk2(x,a,b);
      b=x+1+a'*b;
      t=6;
   endfunction

