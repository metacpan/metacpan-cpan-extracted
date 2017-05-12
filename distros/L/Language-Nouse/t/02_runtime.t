use Test::Simple tests => 32;

use Language::Nouse;

my $nouse = new Language::Nouse;
ok($nouse);

#
# load a program
#

$nouse->clear();
$nouse->load_linenoise('#r<a>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0');
ok($nouse->get_linenoise() eq '#r<a>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0');

#$nouse->run();
#exit;

my @expected = (
	'>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r',
	'+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y',
	'>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0^f',
	'+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0',
	'>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w',
	'>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0',
	'+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4',
	'>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z',
	'+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1',
	'>z>0#r>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c',
	'+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z',
	'>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z',
	'+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z',
	'>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c',
	'#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z',
	'>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0',
	'+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0>z>0?z^0+z>z+9<x#1',
	'>t:4+z#0>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z',
	'+z>c>z>t:4+z#0>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y',
	'>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0>z>0?z^0+z>z+9<x#1+z:3',
	'+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0>z>0?z^0+z>z+9<x#1+z:3>w>z#r',
	'>z>t:4+z#0>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c',
	'+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0>z>0?z^0',
	'>y^y+z>c>z>t:4+z#0>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x',
	'+z#0>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4',
	'>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0',
	':3>w>z#r+i^0>c>z>0#r>z+x>y^y+z>c>z>t:4+z#0>z>0?z^0+z>z+9<x#1+z',
	'^y+z>c>z>t:4+z#0>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>1>z>0#r>z+x>y',
	'#h',
	''
);

$nouse->set_put(\&null);

for(@expected){
	$nouse->step();
	ok($_ eq $nouse->get_linenoise());
}


sub null {
}
