
my ($ok1, $ok2, $ok3, $b, $c, $V,$l);

my $a= double( pdl [[10,0,0],[0,2,0],[0,0,3]] );


$ok1= symmeig_($V,$l,$a);


# Orthogonal basis
$a = double( pdl 
						[1/sqrt(3),1/sqrt(3),1/sqrt(3)],
						[1/sqrt(6),-2/sqrt(6),1/sqrt(6)],
						[-1/sqrt(2),0,1/sqrt(2)]
						); 

# Orthogonal matrix
my $x= $a x ~$a ;
if( $ok2 = symmeig_($V,$l,$x) ){
	my $e = $x x $V - $V ;
	p " Error in symmeig_ result : $x -> $V , $l \n" unless
		$ok2 &=  
			(max(abs($e))<0.000001) && (max(abs($l-1))<0.0000001) ;
}

($V,$l) = symmeig($x);
my $e = $x x $V - $V ;
p " Error in symmeig_ result : $x -> $V , $l \n" unless
	$ok3 =  
	(max(abs($e))<0.000001) && (max(abs($l-1))<0.0000001) ;

	
$ok1 && $ok2 && $ok3;


