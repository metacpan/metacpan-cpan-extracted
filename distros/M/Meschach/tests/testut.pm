
my $ok1,  $ok2;

my $a= double(  pdl [[2,0,1,4],[0,2,1,5],[1,0,1,3]] );
my $b;
my $c;

ut_($b,$a);

ut_($c,@{$$a{Dims}});
$c *= $a;

my $e1 = $b - $c;

p " ut error : $b != $c  " unless $ok1= min( $e1 == 0 );

ut_($a);

my $e2 = $b - $a; 

p " ut error : $b != $a  " unless $ok2= min( $e2 == 0 );

$ok1 && $ok2;

