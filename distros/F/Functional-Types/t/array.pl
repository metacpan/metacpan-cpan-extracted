use warnings;
use 5.016;
use Data::Dumper;

use Functional::Types;


my $a1=[];

for my $i (1..10) {
    push @{$a1},$i;
}

my @a2=();

for my $i (1..10) {
    push @a2,$i;
}

sub PostCode { newtype String,@_ }

type my $a= Array PostCode;
say "TYPE:".show($a);

for my $i (1..10) {
    $a->push(PostCode "G$i");
}

say "LENGTH:".$a->length();
say show($a);
my $uv= untype $a->at(4) ;
say "UNTYPED VAL $uv";


for my $elt ($a->elts()) {
    say untype $elt;
}

# Try assigning bare array
type my $a2 = Array(Int);
say "ARRAY a2:".show($a2);
bind $a2, [1,2,3];
say show($a2);

