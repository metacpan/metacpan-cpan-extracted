1;

my ($ok1, $ok2, $ok3, $ok4, $a , $b );

$a= double( pdl [[2,0,1],[0,2,1],[1,0,1]] );

$b = mrand($a);

p "mrand error 1 : $a != $b  " unless $ok1= min($a == $b);

$b = mrand(4);

p "mrand error 2  " unless $ok2= cl([dims($b)],[4]);

$b = mrand(3,2);
p "mrand error 3   " unless $ok3= cl([dims($b)],[3,2]);

# DON'T DO THAT (bus error may follow)
# $b = mrand(2,2,2);
# p "mrand error 4 " unless $ok4= cl([dims($b)],[2,2,2]);


# $ok1 && $ok2 && $ok3 && $ok4; 
 
$ok1 && $ok2 && $ok3; 
