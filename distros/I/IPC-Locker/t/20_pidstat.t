#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#
# Copyright 1999-2019 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use lib "./blib/lib";
use Test::More;
use Sys::Hostname;
use strict;
use vars qw (%SLArgs $Serv_Pid);

BEGIN { plan tests => 15 }
BEGIN { require "./t/test_utils.pl"; }

END { kill 'TERM', $Serv_Pid; }

#########################
# Constructor

use IPC::PidStat;
$IPC::PidStat::Debug=1;
ok(1);
print "IPC::PidStat VERSION $IPC::PidStat::VERSION\n";

#########################
# Static checks
ok (IPC::PidStat::local_pid_exists($$), 'local_pid_exists');
ok (!IPC::PidStat::local_pid_doesnt_exist($$), 'local_pid_doesnt_exist');

#########################
# Server Constructor

use IPC::PidStat::PidServer;
%SLArgs = (port=>socket_find_free(12345));

if ($Serv_Pid = fork()) {
} else {
    IPC::PidStat::PidServer->new(%SLArgs)->start_server ();
    exit(0);
}
ok (1, 'forked');
sleep(1); #Let server get established

#########################
# User Constructor

my $exister = new IPC::PidStat
    (%SLArgs,
     );
ok ($exister, 'new');

# Send request and check return
# These will (probably) use the local path, not the daemon
ok (check_stat($exister, 'localhost', 66666));

ok (check_stat($exister, 'localhost', $$));

# Send request and check return
# These will use the remote path
%IPC::PidStat::Local_Hostnames = ();  # Hack so we go remotely

ok (check_stat($exister, hostname(), 66666));

ok (check_stat($exister, hostname(), $$));


# Destructor
undef $exister;
ok (1, 'destroy');

#########################
# pidwatch

# We use init's pid (1), which had better be running :)
{   print "pidwatch ok:\n";
    my $cmd = "$PERL script/pidwatch --port $SLArgs{port} --pid 1 echo hello";
    my $rtn = run_rtn($cmd);
    ok($rtn);
    is($rtn, "hello", "pidwatch result for: $cmd");
}

SKIP: {
    print "pidwatch fail:\n";
    my $nonexist_pid = 999999;  # not even legal
    my $cmd = "$PERL script/pidwatch --port $SLArgs{port} --pid $nonexist_pid \"sleep 1 ; echo never_executed\"";
    my $rtn = run_rtn($cmd);
    if ($rtn ne "" && !$ENV{IPCLOCKER_AUTHOR_SITE}) {
	skip("pidwatch non-existance failed, but ok on slow systems (harmless)",1);
    }
    is($rtn, "", "pidwatch result for: $cmd");
}

{   print "pidwatch immediate exit:\n";
    my $cmd = "$PERL script/pidwatch --port $SLArgs{port} --pid 1 --foreground $$";
    my $rtn = run_rtn($cmd);
    ok(1);
}

#########################
# Nagios script check

print "check_pidstat:\n";
SKIP: {
    if (!-d "/usr/lib/nagios/plugins") {
	skip("nagios not installed (harmless)",1);
    }
    # Note we may not be running as root, so need to check $$, not init.
    my $cmd = "$PERL nagios/check_pidstatd --port $SLArgs{port} --pid $$";
    my $rtn = run_rtn($cmd);
    like($rtn, qr/OK/, "nagios result for: $cmd");
}

######################################################################

sub check_stat {
    my $exister = shift;
    my $host = shift;
    my $pid = shift;

    my $tries = 5;   # Number of messages to send.  We'll hope one gets
    # through to the server.  Since it's the local host, that seems almost
    # certain.

    my $pid_pre_exists = kill(0,$pid);
    my @recved = $exister->pid_request_recv(pid=>$pid,host=>$host);
    my $pid_post_exists = kill(0,$pid);  # Test again, may have changed state when request in flight.
    if (!defined $recved[0]) {
	warn "\n%Error: Null response for pid $pid: @recved,";
	warn "%Error: Perhaps you forgot to './pidstatd &' for this test?\n";
	return 0;
    } elsif ($recved[0]!=$pid) {
	warn "%Error: Bad PID response for pid $pid: @recved,";
	return 0;
    } elsif ($recved[1]!=$pid_pre_exists && $recved[1]!=$pid_post_exists) {
	warn "%Error: Bad Exists for pid $pid: @recved,";
	return 0;
    }
    return 1;
}
