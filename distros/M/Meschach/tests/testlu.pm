
my ($ok1, $ok2, $ok3, $ok4);

my $A= double( pdl [[2,0,1],[0,2,1],[1,0,1]] );
my $x=0;

# THIS HERE PRODUCES A PDL WITH STRANGE INCS :
# Note that on my system, uncommenting the next statement, and
# commenting the next statement makes the error "disapear".

# my $b= double( pdl [1],[4],[5] );
my $b= ~double( pdl [1,4,5] );

																#### LU Solve : Raw.

my $Perm ;

my $LU = $A + 0;								# Make a copy

lufac_($LU,$Perm);
lusolve_($x, $b, $LU,$Perm ); 

my $e = $b - $A x $x ;					# Check result
p "lusolve Error 1 : $b - $A x $x = $e " unless $ok1= min( $e == 0 );


																#### LU Solve : Friendly.

($LU,$Perm,$x) = lusolve( $b, $A );
$e = $b - $A x $x ;

p "lusolve Error 2 : $b - $A x $x = $e " unless $ok2= min( $e == 0 );



$x = lusolve( $b, $LU, $Perm );
$e = $b - $A x $x ;

p "lusolve Error 3 : $b - $A x $x = $e " unless $ok3= min( $e == 0 );

$LU= $A = pdl [[2,0],[0,0.33333]]; 
lufac_($LU,$Perm); 
p "lucond error : conditioning is $c instead of 6 " 
	unless $ok4 = (abs($c=lucond($LU,$Perm)-6) < 0.0001 ) ; 


$ok1 && $ok2 && $ok3 && $ok4; 

