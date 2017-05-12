use Test;
BEGIN { plan tests => 8 };

# ============================================================
# Test loading module
use MP3::Player::PktConcert;

ok(1); 
# ============================================================
# Test creating new object
my $pocket_concert = new MP3::Player::PktConcert();

ok(2);
# ============================================================
# Test mounting MP3::Player::PktConcert
my $proc_port = $pocket_concert->mount or 
	die	"Can't find Intel PocketConcert on USB bus!\n".
		"Be sure it's plugged in.\n";
	printf 
		"You'll find the file descriptors for your USB ".
		"Intel PocketConcert at\n /proc/bus/usb/%03d\n",$proc_port 
		if( $^O =~ /linux/ );

ok(3);
# ============================================================
# Test opening mounted MP3::Player::PktConcert
$pocket_concert->open or do {
		print "Can't open USB connection to your Intel PocketConcert!\n";
		printf 
			"Make sure you have read/write permission to\n".
			"the file descriptors in /proc/bus/usb/%03d\n",$proc_port 
		if( $^O =~ /linux/ );
		exit;
	};

ok(4);
# ============================================================
# Test getters/setters
printf 
	"Internal data structures:\n".
	"bfree:  %d\n".
	"btotal: %d\n".
	"lid:    %d\n".
	"hid:    %d\n".
	"psize:  %d\n".
	"bulkep: %d\n".
	"ucache: %d\n".
	"tcache: %d\n".
	"usedids:\n%s\n",

	$pocket_concert->bfree,
	$pocket_concert->btotal,
	$pocket_concert->lid,
	$pocket_concert->hid,
	$pocket_concert->psize,
	$pocket_concert->bulkep,
	$pocket_concert->ucache,
	$pocket_concert->tcache,
	$pocket_concert->usedids;

ok(5);
# ============================================================
# Test usage() method
my ($free,$total) = $pocket_concert->usage();
	my $used = $total - $free;
	$free = human_readable_memory( $free );
	$used = human_readable_memory( $used );
	$total = human_readable_memory( $total );

	print "$used out of $total, with $free remaining.\n";

ok(6);
# ============================================================
# Test tracks() method
my @tracks = $pocket_concert->tracks();
	my $memory_usage = 0;
	foreach ( sort { $a->name cmp $b->name } @tracks) {
		printf "%4d %-60s %12s\n", 
			$_->id,
			$_->name,
			human_readable_memory( $_->size );
		$memory_usage += $_->size;
	}
	print "Totalling: ", human_readable_memory( $memory_usage ), "\n";

ok(7);
# ============================================================
# Test closing mounted MP3::Player::PktConcert
$pocket_concert->close();

ok(8);
# ============================================================

sub human_readable_memory {
	my $memory = shift;
	my $k = 1024;
	my $m = $k*1024;

	if( $memory > $m ) { $memory = sprintf("%.2f Mb",$memory/$m) }
	if( $memory > $k ) { $memory = sprintf("%.2f Kb",$memory/$k) }

	$memory;
}
