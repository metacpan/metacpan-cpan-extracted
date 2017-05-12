
use MLDBM;

my $c = 'c';
my $d = 'd';
my $data = { a => 1, b => [0,1], c => \$c };
$data->{recurse} = $data;

my $err_array = { a => 1, b => [0,2], c => \$c };
$err_array->{recurse} = $err_array;

my $err_hash = { a => 2, b => [0,1], c => \$c };
$err_hash->{recurse} = $err_hash;

my $err_scalar = { a => 1, b => [0,1], c => \$d };
$err_scalar->{recurse} = $err_scalar;

my $err_recurse = { a => 1, b => [0,1], c => \$c };
$err_recurse->{recurse} = {};

print "1..6\n";

for ($err_array, $err_hash, $err_scalar, $err_recurse) {
    if(! &MLDBM::_compare($data, $_)) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
}

my $data_ok = { a => 1, b => [0,1], c => \$c };
$data_ok->{recurse} = $data;

for ($data, $data_ok) {
    if(&MLDBM::_compare($data, $_)) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
}





