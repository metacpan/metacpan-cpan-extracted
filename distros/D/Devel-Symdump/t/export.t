print "1..2\n";

use Devel::Symdump::Export "symdump";
$x = symdump();
if (length($x) > 500){
	print "ok 1\n";
} else {
	print "not ok 1\n", length($x), ":\n$x\n";
}

if ($x =~ /arrays.*functions.*hashes.*ios.*packages.*scalars.*unknowns/xs){
	print "ok 2\n";
} else {
	print "not ok 2 $x\n";
}

