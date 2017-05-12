# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Language-Logo.t'

#########################

use Test::More tests => 16;
BEGIN { use_ok('Language::Logo') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Global variables
my @colors  = qw( blue red green yellow blue );
my @names   = qw( BLUE RED GREEN YELLOW LINES );
my @sizes   = qw( 1 2 3 4 5 );
my $w       = 500;
my $h       = 500;

# Main program


# Create 5 Logo objects

my @objs = ( );
my @opts = (width => $w, height => $h, update => 1);
for (my $i = 0; $i < 5; $i++) {
	($i > 0) and @opts = ( );
	push @opts, name => $names[$i];
	my $lo = new Logo(@opts);
	my $size = $sizes[$i];
	my $color = $colors[$i];
	$lo->cmd("ps $size; co $color; ht; pendown");
	push @objs, $lo;
}

# Create closures for each object
my $pclosures = ( );
push @$pclosures, create_scribble_sub($objs[0], 30, 35, 89, 91, 100, 800);
push @$pclosures, create_spiral_sub($objs[1], 2,   2, 500, 90);
push @$pclosures, create_spiral_sub($objs[2], 2,   2, 400, 91);
push @$pclosures, create_spiral_sub($objs[3], 0.5, 2, 300, 36.5);
push @$pclosures, create_lines_sub($objs[4], 1, 999, 50);


# Iterate the closures to produce colorful lines and spirals
while (@$pclosures > 0) {
	foreach my $p (shift @$pclosures) {
		$p->() and push @$pclosures, $p;
	}
}

# Disconnect only the last object
$objs[4]->disconnect();
sleep 1;


# Query global states
my $p = $objs[0];
my ($nticks, $count, $total) = $p->query('nticks', 'count', 'total');
diag("Total number of ticks ........ $nticks");
ok($nticks > 2000, "At least 4000 ticks have occurred");
ok(4 == $count,    "There are 4 clients still connected");
ok(5 == $total,    "A total of 5 clients were connected");

# Query client states
for (my $i = 0; $i < 4; $i++) {
	my $idx = $i + 1;
	my $color = $colors[$i];
	my $size  = $sizes[$i];
	my $lo = $objs[$i];
	my $pparams = $lo->cmd("noop");
	ok($pparams->{'color'} eq $color, "Object $idx color is '$color'");
	ok($pparams->{'size'}  eq $size,  "Object $idx pensize is '$size'");
	ok($pparams->{'pen'}   eq "1",    "Object $idx pen state is down");
}

# Pause, then disconnect final 4 objects
sleep 1;
$objs[0]->disconnect();
$objs[1]->disconnect();
$objs[2]->disconnect();
$objs[3]->disconnect();


# Subroutines
sub create_scribble_sub {
	my ($lo, $mindist, $maxdist, $minang, $maxang, $nticks, $ntimes) = @_;
	my $tickcnt = 0;
	my $pparams = $lo->cmd("noop");
	my $startcolor = $pparams->{'color'};
	my $psub = sub {
		if (--$ntimes <= 0) {
			$lo->command("color $startcolor");   # Reset starting color
			return 0;
		}
		$lo->cmd("fd random $mindist $maxdist"); # Random distance forward
		$lo->cmd("lt random $minang $maxang");   # Random left turn
		if ($nticks and ++$tickcnt >= $nticks) {
			# Change the turtle's color
			$lo->cmd("co random");
			$tickcnt = 0;
		}
		return 1;
	};
	return $psub;
}

sub create_spiral_sub {
	my ($lo, $incr, $size, $max, $angle) = @_;
	my $psub = sub {
		($size >= $max) and return 0;
		$lo->cmd("forward $size");		# Move turtle forward and draw
		$lo->cmd("right $angle");       # Turn right by the given angle
		$size += $incr;
		return 1;
	};
	return $psub;
}

sub create_lines_sub {
	my ($lo, $size, $dist, $nlines) = @_;
	$lo->command("wrap 1");
	my $psub = sub {
		(--$nlines < 0) and return 0;
		$lo->command("ps $size");			# Change the pensize
		$lo->command("color random");		# Choose a new, random color
		$lo->command("fd $dist");			# Move forward
		$lo->command("rt random 29 31");	# Turn a random angle
		++$size;							# Increment the pensize
		return 1;
	};
	return $psub;
}


