package ThreadFacade;

use threads;
use threads::shared;

use strict;
use warnings;

my $global : shared;
my $ring;

sub run {
	$ring = shift;
	my ($testno, $reporter) = @_;

	my $thrd = threads->create(\&readGlobal);

	my $result = $ring->setGlobalMsg('A' x 10000);
	&$reporter($testno, $result, 'set global msg');
#
#	wait for thread
#	NOTE: join() seems to hang in some instances, so we'll sleep
#
#$thrd->join();
	sleep 1;

	&$reporter($testno, defined($global) &&
		(length($global) == 10000) && ($global eq ('A' x 10000)),
		'get global msg');
}

sub readGlobal {
	$global = $ring->getGlobalMsg();
#	print STDERR "Thread read the msg of length ", length($global), "\n";
	return length($global);
}

1;