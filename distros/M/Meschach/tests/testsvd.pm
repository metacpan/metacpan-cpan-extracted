
my ($ok1, $ok2,$u,$v,$l, $l2);

my $a= short( pdl [[10,0,0],[0,2,0],[0,0,3],[0,0,1]] );


																#### svd, raw version 

$ok1= svd_($u,$v,$l,$a);

my $e = $u x $a x $v - diag($l,dims($a)); 

p " $e = $u x $a x $v - diag($l,",join(',',dims($a))," " unless 
			 $ok1 &= min( abs($e)<0.000001 );


																#### svd, raw version 
$ok2 = svd_($l2,$a);

p "        svd_(\$l,\$a) -> $l2      \n".
	"whereas svd_(\$u,\v,\$l,\$a) -> $l\n" unless 
			 $ok2 &= min( abs($l - $l2)<0.0000001 );


																#### svd, friendly version 
($u,$v,$l) = svd($a);

my $e = $u x $a x $v - diag($l,dims($a)); 

p " $e = $u x $a x $v - diag($l,",join(',',dims($a))," " unless 
			 $ok3 = min( abs($e)<0.000001 );


$ok1 && $ok2 && $ok3;


