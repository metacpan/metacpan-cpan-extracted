
BEGIN {print "1..30\n";}
END {print "not ok 1\n" unless $loaded;}
use Logfile::Rotate;
$loaded = 1;
print "ok 1\n";

use File::Copy;

###############################################################################
#               T E S T  S T R A I G H T  R O T A T I O N
###############################################################################
my $i = 2;
my @bool = qw (yes no);

$|=1;

while ($bool = pop @bool) {
	print "\ntesting persist: $bool\n";

	my $cnt = 3;
	my $file_no = 1;

	copy('t/rotate.log', 't/rotate.tmp');

	print "not "
		unless $log = new Logfile::Rotate( File  => 't/rotate.tmp', 
				Count => $cnt ,
				Persist => $bool ,
				Gzip  => 'no' );
	print "ok ",$i++,"\n";

	while($cnt-- > 0) {
		$log->rotate() or print "not ";
		print "ok ",$i++,"\n";

		my $f = "t/rotate.tmp." . $file_no++;
		print "not "
			unless ( -f $f );
		print "ok ",$i++,"\n";

		if ($bool eq 'yes') {
			my @old_stat = stat 't/rotate.tmp';
			my @new_stat = stat $f;
			print "not " unless $old_stat[2] == $new_stat[2];
			print "ok ",$i++,"\n";
			print "not " unless $old_stat[8] == $new_stat[8];
			print "ok ",$i++,"\n";
			print "not " unless $old_stat[9] == $new_stat[9];
			print "ok ",$i++,"\n";
			print "not " unless $old_stat[4] == $new_stat[4];
			print "ok ",$i++,"\n";
			print "not " unless $old_stat[5] == $new_stat[5];
			print "ok ",$i++,"\n";
		}

		copy('t/rotate.log', 't/rotate.tmp');
	}

	while($file_no-- > 0) {
		my $f = "t/rotate.tmp." . $file_no;
		unlink $f;
	}
	unlink('t/rotate.tmp');
}


1;
