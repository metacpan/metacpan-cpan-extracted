use strict;
use Math::Complex;
use Test;
BEGIN {
           plan(tests => 115) ;
}



use Inline Octave => q{
   function t=alleq(a,b); t= all(all( abs(a-b)<100*eps )); endfunction
};   


my $a= new Inline::Octave([ [1,2,3],[4,5,6] ]);
my $b= new Inline::Octave([ [1,1,1],[2,2,2] ]);

ok ( alleq( $a + $b
          , [ [2,3,4],[6,7,8] ])->as_scalar );
ok ( alleq( $a - $b
          , [ [0,1,2],[2,3,4] ])->as_scalar );
ok ( alleq( $a * $b
          , [ [1,2,3],[8,10,12] ])->as_scalar );
ok ( alleq( $a / $b
          , [ [1,2,3],[2,2.5,3] ])->as_scalar );
ok ( alleq( $a x $b->transpose
          , [ [6,12],[15,30] ])->as_scalar );

#
# test function calls
#

ok ( alleq( Inline::Octave::zeros( 2,3 ),
            [ [0,0,0],[0,0,0] ])->as_scalar );
ok ( alleq( Inline::Octave::ones( 2,3 ),
            [ [1,1,1],[1,1,1] ])->as_scalar );
ok ( alleq( Inline::Octave::linspace( 1,3,5 )->transpose(),
            [ 1,1.5,2,2.5,3   ])->as_scalar );

#
# test methods
#

my $r= new Inline::Octave(  3.1415/4 );
my $c= new Inline::Octave( cplx(.5,.5) );


my %methods = (
    abs=>[0.785375, 0.707106781186548, 0],
    acos=>[0.667494636365011, 1.11851787964371, -0.530637530952518],
    all=>[1, 1, 0],
    angle=>[0, 0.785398163397448, 0],
    any=>[1, 1, 0],
    asin=>[0.903301690429886, 0.452278447151191, 0.530637530952518],
    asinh=>[0.72120727202285, 0.530637530952518, 0.452278447151191],
    atan=>[0.66575942361951, 0.553574358897045, 0.402359478108525],
    atanh=>[1.05924571848258, 0.402359478108525, 0.553574358897045],
    ceil=>[1, 1, 1],
    conj=>[0.785375, 0.5, -0.5],
    cos=>[0.70712315999226, 0.98958488339992, -0.249826397500462],
    cosh=>[1.32458896823663, 0.98958488339992, 0.249826397500462],
    cumprod=>[0.785375, 0.5, 0.5],
    cumsum=>[0.785375, 0.5, 0.5],
    diag=>[0.785375, 0.5, 0.5],
    erf=>[0.733297320648467, 0, 0],
    erfc=>[0.266702679351533, 0, 0],
    exp=>[2.19322924750887, 1.44688903658417, 0.790439083213615],
    eye=>[1, 0, 0],
    finite=>[1, 1, 0],
    fix=>[0, 0, 0],
    floor=>[0, 0, 0],
    gamma=>[1.18107044739768, 0, 0],
    gammaln=>[0.166421186069287, 0, 0],
    imag=>[0, 0.5, 0],
    islogical=>[0, 0, 0],
    iscomplex=>[0, 1, 0],
    islist=>[0, 0, 0],
    ismatrix=>[1, 1, 0],
    isstruct=>[0, 0, 0],
    iscell=>[0, 0, 0],
    isempty=>[0, 0, 0],
    isfinite=>[1, 1, 0],
    isieee=>[1, 1, 0],
    isinf=>[0, 0, 0],
    islogical=>[0, 0, 0],
    isnan=>[0, 0, 0],
    isnumeric=>[1, 1, 0],
    isreal=>[1, 0, 0],
    length=>[1, 1, 0],
    lgamma=>[0.166421186069287, 0, 0],
    log=>[-0.241593968259026, -0.346573590279973, 0.785398163397448],
    log10=>[-0.104922927276004, -0.150514997831991, 0.34109408846046],
    ones=>[1, 0, 0],
    prod=>[0.785375, 0.5, 0.5],
    real=>[0.785375, 0.5, 0],
    round=>[1, 1, 1],
    sign=>[1, 0.707106781186548, 0.707106781186548],
    sin=>[0.707090402001441, 0.540612685713153, 0.457304153184249],
    sinh=>[0.868640279272249, 0.457304153184249, 0.540612685713153],
    size=>[1, 1, 0],
    sqrt=>[0.88621385680884, 0.776886987015019, 0.321797126452791],
    sum=>[0.785375, 0.5, 0.5],
    sumsq=>[0.616813890625, 0.5, 0],
    tan=>[0.999953674278156, 0.403896455316026, 0.564083141267498],
    tanh=>[0.655781000825211, 0.564083141267498, 0.403896455316026],
    zeros=>[0, 0, 0],
);


my %notcomplex= (
    "erf"=>1, "erfc"=>1 , "gamma"=>1, "gammaln"=>1, "lgamma"=>1,
    "eye"=>1, "ones"=>1,  "zeros"=>1);

foreach my $meth (sort keys %methods) {
   my $vv= $methods{$meth};

   my $s= $r->$meth;
   my $ans= $vv->[0];
#  print $s->disp."    ".$ans."\n";
   ok ( alleq( $s, $ans )->as_scalar() );

   unless ($notcomplex{$meth}) {
      $s= $c->$meth;
      $ans= cplx( $vv->[1], $vv->[2]);
#     print $s->disp."    ".$ans."\n";
      ok ( alleq( $s, $ans )->as_scalar() );
   }
}

my $s= new Inline::Octave::String( "asdf" );

## TODO: this doesn't work yet
my %str_methods = (
#   'isalnum' => 0,
#   'isalpha' => 0,
#   'isascii' => 1,
#   'iscntrl' => 1,
#   'isdigit' => 0,
);

foreach my $meth (sort keys %str_methods) {
   my $ss= $s->$meth;
   my $v1= $s->as_scalar;
   my $v2= $methods{$meth};
   ok ($v1,$v2);
}

#
# replacement methods
#
use Inline Octave => q{
function a=makea()
   a=zeros(4);
   a( [1,3] , :)= [ 1,2,3,4 ; 5,6,7,8 ];
   a( : , [2,4])= [ 2,4; 2,4; 2,4; 2,4 ];
   a( [1,4],[1,4])= [8,7;6,5];
endfunction
};

my $ao= makea();

my $an = Inline::Octave::zeros(4);
$an->replace_rows( [1,3], [ [1,2,3,4],[5,6,7,8] ] );
$an->replace_cols( [2,4], [ [2,4],[2,4],[2,4],[2,4] ] );
$an->replace_matrix( [1,4], [1,4], [ [8,7],[6,5] ] );

ok ( alleq( $an, $ao ) ->as_scalar );
