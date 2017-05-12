#use strict;
use Test;
BEGIN {
           plan(tests => 2) ;
}

         

use Inline Octave => q{
   function t=jnk1(x,a,b); t=x+a+b; endfunction
};   


ok ( jnk1(4,2,1)->as_scalar == 7 );

ok ( jnk2(4,2,1)->as_scalar == 1 );




use Inline Octave => q{
   function t=jnk2(x,a,b); t=x-a-b; endfunction
};   
