
BEGIN {print "1..8\n";}
END {print "not ok 1\n" unless $loaded;}
use Config;
use Logfile::Rotate;
$loaded = 1;
print "ok 1\n";

use File::Copy;

###############################################################################
#               T E S T    C O M P R E S S    A T T R I B U T E 
###############################################################################


# skip if perl does not know about gzip
# my $Config; $Config{'gzip'} = undef;
unless (defined ($Config{'gzip'})) {
	for ($i=2; $i<9; $i++) {
		print "ok $i # skipped on your platform\n";
	} 
	exit 0;
}

$i=2;
$cnt = 3;
$file_no = 1;

copy('t/rotate.log', 't/rotate.tmp');

print "not "
	unless $log = new Logfile::Rotate( File  => 't/rotate.tmp', 
	                                   Count => $cnt );
print "ok ",$i++,"\n";

while($cnt-- > 0) {
	$log->rotate() or print "not ";
	print "ok ",$i++,"\n";

	my $f = "t/rotate.tmp." . $file_no++ . ".gz";
	print "not "
		unless( -f $f );
	print "ok ",$i++,"\n";

	copy('t/rotate.log', 't/rotate.tmp');
}

while($file_no-- > 0) {
	my $f = "t/rotate.tmp." . $file_no . ".gz";
	unlink $f;
}

unlink('t/rotate.tmp');

1;
