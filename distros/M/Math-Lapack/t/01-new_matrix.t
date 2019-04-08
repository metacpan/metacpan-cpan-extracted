#!perl

use Test2::V0;
use Math::Lapack::Matrix;

# Zeros
my $z = Math::Lapack::Matrix->zeros(3,4);
isa_ok $z, ['Math::Lapack::Matrix'], "Zeros returned a matrix";

_float($z->get_element(0,0), 0, "Zeros: Right element at 0,0");
_float($z->get_element(0,1), 0, "Zeros: Right element at 0,1");
_float($z->get_element(0,2), 0, "Zeros: Right element at 0,2");
_float($z->get_element(0,3), 0, "Zeros: Right element at 0,3");
_float($z->get_element(1,0), 0, "Zeros: Right element at 1,0");
_float($z->get_element(1,1), 0, "Zeros: Right element at 1,1");
_float($z->get_element(1,2), 0, "Zeros: Right element at 1,2");
_float($z->get_element(1,3), 0, "Zeros: Right element at 1,3");
_float($z->get_element(2,0), 0, "Zeros: Right element at 2,0");
_float($z->get_element(2,1), 0, "Zeros: Right element at 2,1");
_float($z->get_element(2,2), 0, "Zeros: Right element at 2,2");
_float($z->get_element(2,3), 0, "Zeros: Right element at 2,3");


# Ones    
my $o = Math::Lapack::Matrix->ones(6,2);

isa_ok $o, ['Math::Lapack::Matrix'], "Ones returned a matrix";

_float($o->get_element(0,0), 1, "Ones: Right element at 0,0");
_float($o->get_element(0,1), 1, "Ones: Right element at 0,0");
_float($o->get_element(1,0), 1, "Ones: Right element at 0,0");
_float($o->get_element(1,1), 1, "Ones: Right element at 0,0");
_float($o->get_element(2,0), 1, "Ones: Right element at 0,0");
_float($o->get_element(2,1), 1, "Ones: Right element at 0,0");
_float($o->get_element(3,0), 1, "Ones: Right element at 0,0");
_float($o->get_element(3,1), 1, "Ones: Right element at 0,0");
_float($o->get_element(4,0), 1, "Ones: Right element at 0,0");
_float($o->get_element(4,1), 1, "Ones: Right element at 0,0");
_float($o->get_element(5,0), 1, "Ones: Right element at 0,0");
_float($o->get_element(5,1), 1, "Ones: Right element at 0,0");

#random
my $r = Math::Lapack::Matrix->random(10,10);

isa_ok $r, ['Math::Lapack::Matrix'], "Random returned a matrix";


my $false = 0;
my $k = 0;
for my $i (0..9) {
	for my $j (0..9) {
		my $v = $r->get_element($i, $j);
		$k++ if $v == 0;	
		$false = 1 if $v < 0 || $v > 1;
	}
}

ok($k !=4, "Didn't get a zero");
is($false, 0, "Values in limits");

#identity
my $id = Math::Lapack::Matrix->identity(4);

isa_ok $id, ['Math::Lapack::Matrix'], "Identify returned a matrix";

_float($id->get_element(0,0), 1, "Identity: right element at 0,0");
_float($id->get_element(0,1), 0, "Identity: right element at 0,1");
_float($id->get_element(0,2), 0, "Identity: right element at 0,2");
_float($id->get_element(0,3), 0, "Identity: right element at 0,3");
_float($id->get_element(1,0), 0, "Identity: right element at 1,0");
_float($id->get_element(1,1), 1, "Identity: right element at 1,1");
_float($id->get_element(1,2), 0, "Identity: right element at 1,2");
_float($id->get_element(1,3), 0, "Identity: right element at 1,3");
_float($id->get_element(2,0), 0, "Identity: right element at 2,0");
_float($id->get_element(2,1), 0, "Identity: right element at 2,1");
_float($id->get_element(2,2), 1, "Identity: right element at 2,2");
_float($id->get_element(2,3), 0, "Identity: right element at 2,3");
_float($id->get_element(3,0), 0, "Identity: right element at 3,0");
_float($id->get_element(3,1), 0, "Identity: right element at 3,1");
_float($id->get_element(3,2), 0, "Identity: right element at 3,2");
_float($id->get_element(3,3), 1, "Identity: right element at 3,3");

#new
my $n = Math::Lapack::Matrix->new([[1, 2, 3], [4, 5, 6]]);

isa_ok $n, ['Math::Lapack::Matrix'], "New returned a matrix";

_float($n->get_element(0,0), 1, "New: Element correct at 0,0");
_float($n->get_element(0,1), 2, "New: Element correct at 0,1");
_float($n->get_element(0,2), 3, "New: Element correct at 0,2");
_float($n->get_element(1,0), 4, "New: Element correct at 1,0");
_float($n->get_element(1,1), 5, "New: Element correct at 1,1");
_float($n->get_element(1,2), 6, "New: Element correct at 1,2");




done_testing;


sub _float {
  my ($a, $b, $c) = @_;
  is($a, float($b, tolerance => 0.000001), $c);
}
