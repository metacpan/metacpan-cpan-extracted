use Forks::Super ':test';
use Test::More tests => 10;
use Carp;
use strict;
use warnings;

# can we set priority, cpu affinity on daemon jobs?
# do daemon jobs recognize names? delays? dependencies?

our $CWD = &Cwd::getcwd;
if (${^TAINT}) {
    ($CWD) = $CWD =~ /(.*)/;
}

# need a separate test for MSWin32
if ($^O eq 'MSWin32') {
  SKIP: {
      skip "test $0 not for use with MSWin32", 10;
    }
    exit;
}

my $pid = fork sub { sleep 5 };
my $base_priority = get_os_priority($pid);
my $np = Forks::Super::Config::CONFIG_module("Sys::CpuAffinity")
    ? Sys::CpuAffinity::getNumCpus() : 0;

my $daemon = fork sub { sleep 10 }, {
    daemon => 1,
    os_priority => $base_priority + 1,
    cpu_affinity => $np > 1 ? 2 : 1
};

# it may take a second or three after the background process is launched
# for F::S to update its priority and CPU affinity

my ($new_priority, $affinity);
$affinity = "<not set>";
for (1..10) {

    $new_priority = get_os_priority($daemon);
    if ($new_priority != -99) {
	if ($np > 1 && Forks::Super::Config::CONFIG('Sys::CpuAffinity')) {
	    $affinity = Sys::CpuAffinity::getAffinity($daemon);
	    last if $new_priority != $base_priority && $affinity == 2;
	} else {
	    last if $new_priority != $base_priority;
	}
    }
    if ($_ == 8) {
	warn "priority/affinity $new_priority/$affinity still not ",
	    "at expected levels after 8 seconds";
    }
    sleep 1;
}

SKIP: {
    if ($base_priority == 19 && $new_priority == 19) {
	# why did it take until 0.70 for this issue to show up?
	skip "can't lower priority (19) of daemon process any more", 1;
    }

    # on FreeBSD lowest priority is 20 ?
    if ($^O =~ /bsd/i && $base_priority == 20 && $new_priority == 20) {
	skip "can't lower priority (20) of daemon process any more", 1;
    }

    ok($new_priority == $base_priority + 1,		        ### 1 ###
       "set os priority on daemon process")
	or diag("failed to update priority $base_priority => $new_priority");
}

SKIP: {
    if ($np <= 1) {
	skip "one processor, can't test set CPU affinity", 1;
    }
    if (!Forks::Super::Config::CONFIG('Sys::CpuAffinity')) {
	skip 'Sys::CpuAffinity not avail. Skip CPU affinity test', 1;
    }
    ok($affinity == 2, "set CPU affinity on daemon process")    ### 2 ###
	or diag("affinity of $daemon was $affinity, expected 2; ",
	        "Sys::CpuAffinity v. $Sys::CpuAffinity::VERSION");
}
$daemon->kill('KILL');


my $t = Time::HiRes::time();
my $d1 = fork sub { sleep 5 }, {
    daemon => 1,
    delay => 3
};
ok($d1->{state} eq 'DEFERRED', 'daemon job was delayed');	### 3 ###
for (1..5) {
    Forks::Super::pause(1) while $d1->{state} eq 'DEFERRED';
}
ok($d1->{state} ne 'DEFERRED', 'daemon job was started');	### 4 ###
ok(!Forks::Super::Util::isValidPid($d1->{pid}),"pid is for deferred job");
ok(Forks::Super::Util::isValidPid($d1->{real_pid}),"real pid is valid");

my $n1 = fork sub {
        print time-$^T," DAEMON 1 MONITOR START\n";
	sleep 1 while CORE::kill 0, $d1->{real_pid};
        print time-$^T," DAEMON 1 MONITOR COMPLETE\n";
    },
    daemon => 0,
    name => 'daemon1 monitor';

sleep 1;

my $d2 = fork {
    daemon => 1,
    name => 'daemon2',
    depend_on => 'daemon1 monitor',
    sub => sub { sleep 1 },
    on_busy => 'queue',
    debug => 0,
};

ok($d2->{state} eq 'DEFERRED', '2nd daemon is deferred');	### 7 ###
Forks::Super::Util::pause(6);

ok($d1 && $d2, "daemon procs launched") or diag("d1=$d1, d2=$d2");
ok($d1->{start} > $t + 2, "daemon1 launch was delayed");
ok($d2->{start} >= ($n1->{end} || 0),                          ### 10 ###
   "daemon2 launch waited for daemon1")
    or diag("expected d2 start $d2->{start} >= $n1->{end} d1 monitor end");


#############################################################################

sub get_os_priority {
    my ($pid) = @_;

    # freebsd: on error, getpriority returns -1 and sets $!

    my $p;
    local $! = 0;
    eval {
	$p = getpriority(0, $pid);
    };
    if ($@ eq '') {
	if ($p == -1 && $!) {
	    carp "get_os_priority($pid): $!";
	    return -99;
	}
	return $p;
    }

    if ($^O eq 'MSWin32') {
	return Forks::Super::Job::OS::Win32::get_priority($pid);
    }
    return;
}
