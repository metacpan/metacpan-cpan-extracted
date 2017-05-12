
my ($ok1, $ok2, $ok3, $ok3);

my $A= double( pdl [[2,0,1],[0,2,1],[1,0,1]] );
my $b= double( pdl [1],[4],[5] );
my $x=0;

																#### QR Solve : Raw.

my $V ;

my $QR = $A + 0;								# Make a copy

qrfac_($QR,$V);
qrsolve_($x, $b, $QR,$V ); 

my $e = $b - $A x $x ;					# Check result
p "QRsolve Error 1 : $b - $A x $x = $e " unless $ok1= min( abs($e) < 0.000001 );

																#### LU Solve : Friendly.

($QR,$V,$x) = qrsolve( $b, $A );
$e = $b - $A x $x ;

p "qrsolve Error 2 : $b - $A x $x = $e " unless $ok2= min( abs($e) < 0.00001 );


$x = qrsolve( $b, $QR, $V );
$e = $b - $A x $x ;

p "qrsolve Error 3 : $b - $A x $x = $e " unless $ok3= min(  abs($e) < 0.00001 );

$QR= $A = pdl [[2,0],[0,0.33333]]; 
qrfac_($QR,$V); 
p "qrcond error : conditioning is $c instead of 6 " 
	unless $ok4 = (abs(($c=qrcond($QR))-6) < 0.0001 ) ; 


$ok1 && $ok2 && $ok3 && $ok4; 

