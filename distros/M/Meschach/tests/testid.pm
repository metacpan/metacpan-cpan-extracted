
my ( $ok1 , $ok2 );

my $b = ident(3);
my $c = ident(3,3);

p " ident error 1 : $b != $c  " unless $ok1= min( $b == $c );

$b = ident(3,4);
$c = ident(4,3);

$b = diag($b); 
$c = diag($c); 

p " ident error 2 : $b != $c  " unless $ok2= min( $b == $c );

$ok1 && $ok2;
