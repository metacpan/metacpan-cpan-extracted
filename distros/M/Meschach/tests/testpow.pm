
my ($ok1, $ok2, $ok3, $ok4, $ok5);

my $a= double( pdl [[2,0,1],[0,2,1],[1,0,1]] );
my $b;

mpow_($b,$a,1);
my $e = $b - $a;
p "mpow error 1 : $a^1 = $b  " unless $ok1= min( $e == 0 );

mpow_($b,$a,2);
$e = $b - $a x $a ;
p "mpow error 2 :  $e " unless $ok2= min( $e == 0 );

mpow_($b,$a,-1);
$e = $b x $a - ident(3,3);
p "mpow error 3 :  $e " unless $ok3= min( $e == 0 );

$b = mpow($a,-1);
$e = $b x $a - ident(3);
p "mpow error 4 :  $e " unless $ok4= min( $e == 0 );

$b = inv($a);
$e = $b x $a - ident(3);
p "mpow error 5 :  $e " unless $ok5= min( $e == 0 );

$ok1 && $ok2 && ok3 && $ok4 && $ok5 ; 
