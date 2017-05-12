
my ($ok1, $ok2);

my $a= double(  pdl [[2,0,1,4],[0,2,1,5],[1,0,1,3]] );
my ($b, $c,$d);

diag_($b,$a);
diag_($c,$b);
$d= sec($a,0,2,0,2) - $c;
diag_($b,$d) ;

p " diag_ error 1 : $b  " unless $ok1= min( $b == 0 );

$b = diag( $a );
$c = diag( $b, 4,3 );

p " diag error 2 : " unless $ok2 = ( max(diag( $c != $a )) == 0 ) ;

$ok1 && $ok2; 

