use strict;
use Test;
BEGIN {
           plan(tests => 16) ;
}

         

use Inline Octave => q{
   function t=jnk(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15)
      t=10;
      for i=1:nargin
         t+= eval( sprintf("a%d",i) );
      end
   endfunction
};   

      

#perl compare
ok ( 10, jnk()->as_scalar );
ok ( 11, jnk(1)->as_scalar );
ok ( 13, jnk(1,2)->as_scalar );
ok ( 16, jnk(1,2,3)->as_scalar );
ok ( 20, jnk(1,2,3,4)->as_scalar );
ok ( 25, jnk(1,2,3,4,5)->as_scalar );
ok ( 31, jnk(1,2,3,4,5,6)->as_scalar );
ok ( 38, jnk(1,2,3,4,5,6,7)->as_scalar );
ok ( 46, jnk(1,2,3,4,5,6,7,8)->as_scalar );
ok ( 55, jnk(1,2,3,4,5,6,7,8,9)->as_scalar );
ok ( 65, jnk(1,2,3,4,5,6,7,8,9,10)->as_scalar );
ok ( 76, jnk(1,2,3,4,5,6,7,8,9,10,11)->as_scalar );
ok ( 88, jnk(1,2,3,4,5,6,7,8,9,10,11,12)->as_scalar );
ok ( 101,jnk(1,2,3,4,5,6,7,8,9,10,11,12,13)->as_scalar );
ok ( 115,jnk(1,2,3,4,5,6,7,8,9,10,11,12,13,14)->as_scalar );
ok ( 130,jnk(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)->as_scalar );

