use warnings;
use 5.016;

use Functional::Types;
use Data::Dumper;

type my $h = Map( String,Int );
say "TYPE:".Dumper($h);
for my $i (1..10) {
    $h->insert("$i",$i);
   
}
say "INSERT:".show($h);
 
say "SIZE:".$h->size();
say $h->of('4');

for my $elt ($h->keys()) {
    say 'K:',$elt;
    say 'V:',$h->of($elt);
}

# Try assigning bare hash

type my $h2 = Map(String,Int);
say "HASH h2:".show($h2);
bind $h2, {'k1' =>1,'k2'=>2,'k3'=>3};
say show($h2);
say Dumper(untype($h2));

