use strict;
use Test;
BEGIN {
           plan(tests => 13) ;
}

         

use Inline Octave => q{
   function jnk0(x,a,b);
      t=x+a+b;
   endfunction
   function a1 =jnk1(x,a,b);
      t=x+a+b;
      a1=t;
   endfunction
   function [a1] =jnk2(x,a,b);
      t=x+a+b;
      a1=t;
   endfunction
   function [a1,a2] =jnk3(x,a,b);
      t=x+a+b;
      a1=t;
      a2=t+1;
   endfunction
   function [a1,a2,a3,a4,a5,a6,a7,a8,a9] =jnk9(x,a,b);
      t=x+a+b;
      a1=t;
      a2=t+1;
      a3=t+2;
      a4=t+3;
      a5=t+4;
      a6=t+5;
      a7=t+6;
      a8=t+7;
      a9=t+8;
   endfunction
   function [a1,a2,a3,a4,a5,a6,a7,a8,a9,a10] =jnk10(x,a,b);
      t=x+a+b;
      a1=t;
      a2=t+1;
      a3=t+2;
      a4=t+3;
      a5=t+4;
      a6=t+5;
      a7=t+6;
      a8=t+7;
      a9=t+8;
      a10=t+9;
   endfunction
   function [a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11] =jnk11(x,a,b);
      t=x+a+b;
      a1=t;
      a2=t+1;
      a3=t+2;
      a4=t+3;
      a5=t+4;
      a6=t+5;
      a7=t+6;
      a8=t+7;
      a9=t+8;
      a10=t+9;
      a11=t+10;
   endfunction

   function t=alleq(a,b); t= all(a==b); endfunction
};   

sub listeq {
   my @l1= @{$_[0]};
   my @l2= @{$_[1]};

   return 0 unless length( @l1 ) == length( @l2 );
   for (my $i=0; $i< @l1; $i++) {
      return 0 unless $l1[$i] == $l2[$i];
   }
   return 1;
}   
      

sub flatten_scalars {
   my @retval;
   foreach (@_) {
      push @retval, $_->as_scalar;
   }
   return @retval;
}   


ok ( not defined ( jnk0(4,2,1) ) );
my @v;

#perl compare
@v= flatten_scalars( jnk1 (4,2,1) );
ok ( listeq( \@v, [ 7 ] ) );

@v= flatten_scalars( jnk2 (4,2,1) );
ok ( listeq( \@v, [ 7 ] ) );

@v= flatten_scalars( jnk3 (4,2,1) );
ok ( listeq( \@v, [ 7,8 ] ) );

@v= flatten_scalars( jnk9 (4,2,1) );
ok ( listeq( \@v, [ 7..15 ] ) );

@v= flatten_scalars( jnk10(4,2,1) );
ok ( listeq( \@v, [ 7..16 ] ) );

@v= flatten_scalars( jnk11(4,2,1) );
ok ( listeq( \@v, [ 7..17 ] ) );




# octave compare
@v= flatten_scalars( jnk1 (4,2,1) );
ok ( alleq( \@v, [ 7 ] )->as_scalar );

@v= flatten_scalars( jnk2 (4,2,1) );
ok ( alleq( \@v, [ 7 ] )->as_scalar );

@v= flatten_scalars( jnk3 (4,2,1) );
ok ( alleq( \@v, [ 7,8 ] )->as_scalar );

@v= flatten_scalars( jnk9 (4,2,1) );
ok ( alleq( \@v, [ 7..15 ] )->as_scalar );

@v= flatten_scalars( jnk10(4,2,1) );
ok ( alleq( \@v, [ 7..16 ] )->as_scalar );

@v= flatten_scalars( jnk11(4,2,1) );
ok ( alleq( \@v, [ 7..17 ] )->as_scalar );



