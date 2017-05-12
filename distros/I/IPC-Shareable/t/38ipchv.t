BEGIN {
    $^W = 1;
    $| = 1;
    $SIG{INT} = sub { die };
    print "1..5\n";
}

use strict;
use Carp;
use IPC::Shareable;
my $t  = 1;
my $ok = 1;


my %shareOpts = (
		 create =>       'yes',
		 exclusive =>    0,
		 mode =>         0644,
		 destroy =>      'yes',
		 );

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my $pid = fork;
defined $pid or die "Cannot fork: $!";
if ($pid == 0) {
    # --- Kid
    sleep unless $awake;
    $awake = 0;
    my %hv;
    my $ipch = tie(%hv, 'IPC::Shareable', "data", {
	create    => 'yes',
	exclusive => 0,
	mode      => 0644,
	destroy   => 0,
    }) or undef $ok;
    print $ok ? "ok $t\n" : "not ok $t\n";

    for (qw(fee fie foe fum)) {
	$ipch->shlock();
	$hv{$_} = $$;
	$ipch->shunlock();
    }
    sleep unless $awake;
    $ok = 1;
    ++$t;
    for (qw(fee fie foe fum)) {
	$hv{$_} == $$ or undef $ok;
    }
    print $ok ? "ok $t\n" : "not ok $t\n";
    
    $ok = 1;
    ++$t;
    my $dad = getppid;
    $dad == 1 and die "Parent process has unexpectedly gone away";
    for (qw(eenie meenie minie moe)) {
	$hv{$_} == $dad or undef $ok;
    }
    print $ok ? "ok $t\n" : "not ok $t\n";
} else {
    # --- Parent
    my %hv;
    my $ipch = tie(%hv, 'IPC::Shareable', "data", {
	create    => 1,
	exclusive => 0,
	mode      => 0666,
	size      => 1024*512,
	destroy   => 'yes',
    });
    %hv = ();
    kill ALRM => $pid;
    sleep 1;           # Allow time for child to process the signal before next ALRM comes in
    
    for (qw(eenie meenie minie moe)) {
	$ipch->shlock();
	$hv{$_} = $$;
	$ipch->shunlock();
    }
    kill ALRM => $pid;
    waitpid($pid, 0);

    $t += 3;
    $ok = 1;
    for (qw(fee fie foe fum)) {
	$hv{$_} == $pid or undef $ok;
    }
    print $ok ? "ok $t\n" : "not ok $t\n";
    
    $ok = 1;
    ++$t;
    for (qw(eenie meenie minie moe)) {
	$hv{$_} == $$ or undef $ok;
    }
    print $ok ? "ok $t\n" : "not ok $t\n";
}

exit;
