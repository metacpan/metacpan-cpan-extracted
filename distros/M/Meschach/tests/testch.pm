
my ($ok1, $ok2, $ok3 );

																#### Symmetric positive
my $A= double( pdl [[2,0,1],[0,2,1],[1,0,1]] );
$A += ~ $A;
my $x=0;

# THIS HERE PRODUCES A PDL WITH STRANGE INCS :
# Note that on my system, uncommenting the next statement, and
# commenting the next statement makes the error "disapear".

# my $b= double( pdl [1],[4],[5] );
my $b= ~double( pdl [1,4,5] );



																#### CH Solve : Raw.


my $CH = $A + 0;								# Make a copy
# p $b, $A, $x;

chfac_($CH);
chsolve_($x, $b, $CH ); 

my $e = $b - $A x $x ;					# Check result
p "CHsolve Error 1 : $b - $A x $x = $e " unless $ok1= min( $e == 0 );


																#### CH Solve : Friendly.
($CH,$x) = chsolve( $b, $A );
$e = $b - $A x $x ;

p "CHsolve Error 2 : $b - $A x $x = $e " unless $ok2= min( $e == 0 );



$x = chsolve( $b, $CH, 1 );
$e = $b - $A x $x ;

p "CHsolve Error 3 : $b - $A x $x = $e " unless $ok3= min( $e == 0 );

$ok1 && $ok2 && $ok3; 

