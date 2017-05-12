
BEGIN {print "1..8\n";}
END {print "not ok 1\n" unless $loaded;}
use Logfile::Rotate;
$loaded = 1;
print "ok 1\n";

use File::Copy;

###############################################################################
#               T E S T    S I G N A L    A T T R I B U T E
###############################################################################
my $i = 2;

copy('t/rotate.log', 't/rotate.tmp');

$cnt = 3;
$file_no = 1;

print "not "
	unless $log = new Logfile::Rotate( File  => 't/rotate.tmp', 
	                                   Count => $cnt,
	                                   Gzip  => 'no',
									   Signal => sub { print "ok "; },
									 );
print "ok ",$i++,"\n";

while($cnt-- > 0) {
	$log->rotate() or print "not ";
	print $i++,"\n"; ## rotate print's ok

	my $f = "t/rotate.tmp." . $file_no++;
	print "not " unless ( -f $f );
	print "ok ",$i++,"\n";

	copy('t/rotate.log', 't/rotate.tmp');
}

while($file_no-- > 0) {
	my $f = "t/rotate.tmp." . $file_no;
	unlink $f;
}

unlink('t/rotate.tmp');

1;
