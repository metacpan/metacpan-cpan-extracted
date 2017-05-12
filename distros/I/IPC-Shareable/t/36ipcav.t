BEGIN {
    $^W = 1;
    $| = 1;
    $SIG{INT} = sub { die };
    print "1..3\n";
}

use strict;
use Carp;
use IPC::Shareable;
my $t  = 1;
my $ok = 1;

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my $pid = fork;
defined $pid or die "Cannot fork: $!";
if ($pid == 0) {
    sleep unless $awake;
    $awake = 0;
    my @av;
    my $ipch = tie(@av, 'IPC::Shareable', "foco", {
	create    => 1,
	exclusive => 0,
	mode      => 0666,
	size      => 1024*512,
	destroy   => 0,
    }) or undef $ok;
    @av = ();
    print $ok ? "ok $t\n" : "not ok $t\n";
    
    for (my $i = 1; $i <= 10; $i++) {
	$ipch->shlock;
	push(@av, $i);
	$ipch->shunlock;
    }

    sleep unless $awake;
    ++$t;
    $ok = 1;
    @av and undef $ok;
    print $ok ? "ok $t\n" : "not ok $t\n";
    exit;

} else {
    my @av;
    my $ipch = tie(@av, 'IPC::Shareable', "foco", {
	create    => 1,
	exclusive => 0,
	mode      => 0666,
	size      => 1024*512,
	destroy   => 'yes',
    });
    @av = ();
    kill ALRM => $pid;
    
    my %seen;
    sleep 1 until @av;
    while (@av) {
	$ipch->shlock;
	my $line = shift @av;
	if ($seen{$line}) {
	    undef $ok;
	}
	++$seen{$line};
	$ipch->shunlock;
    }
    kill ALRM => $pid;
    waitpid($pid, 0);
    $t += 2;
    $ok = 1;
    @av and undef $ok;
    print $ok ? "ok $t\n" : "not ok $t\n";
}

# --- Done!
exit;
