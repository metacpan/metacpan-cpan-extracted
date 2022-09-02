#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use lib $FindBin::RealBin;

use Test::More;

plan 'no_plan';

use Doit;

use TestUtil qw(signal_kill_num);
my $KILL = signal_kill_num;
my $KILLrx = qr{$KILL};

{
    my $r = Doit->init;

    is $r->qx($^X, '-e', 'print 42'), 42, 'expected single-line result';

    is $r->qx($^X, '-e', 'print "first line\nsecond line\n"'), "first line\nsecond line\n", 'expected mulit-line result';

    eval { $r->qx($^X, '-e', 'kill TERM => $$') };
    if ($^O eq 'MSWin32') {
	# For some reason, TERM works with open2 on Windows. Still it
	# does not appear as a signal, but as a special exit code.
	# And sometimes it appear as exit code 116, and sometimes
	# it is not killed at all. So mark it as a TODO test.
	local $TODO = "Handling SIGTERM on Windows seems to be unreliable";
	like $@, qr{^Command exited with exit code 21};
    } else {
	like $@, qr{^Command died with signal 15, without coredump};
	is $@->{signalnum}, 15;
	is $@->{coredump}, 'without';
    }

    eval { $r->qx($^X, '-e', 'kill KILL => $$') };
    if ($^O eq 'MSWin32') {
	# There does not seem to be any signal handling on Windows
	# --- exit(9) and kill KILL is indistinguishable here.
	like $@, qr{^Command exited with exit code $KILLrx};
    } else {
	like $@, qr{^Command died with signal $KILLrx, without coredump};
	is $@->{signalnum}, $KILL;
	is $@->{coredump}, 'without';
    }

    is $r->qx({quiet=>1}, $^X, '-e', '#nothing'), '', 'nothing returned; command is also quiet';

    is $r->info_qx($^X, '-e', 'print 42'), 42, 'info_qx behaves as qx in non-dry-run mode';

    ok !eval { $r->info_qx($^X, '-e', 'exit 1'); 1 };
    like $@, qr{qx command '.* -e "?exit 1"?' failed: Command exited with exit code 1 at .* line \d+}, 'verbose error message with failed info_qx command';

    {
	my %status;
	is $r->qx({statusref => \%status}, $^X, '-e', 'print STDOUT "some output\n"; exit 0'), "some output\n";
	is $status{exitcode}, 0, 'status reference filled, exit code as expected (success)';
    }

    {
	my %status;
	is $r->qx({statusref => \%status}, $^X, '-e', 'print STDOUT "some output\n"; exit 1'), "some output\n";
	is $status{exitcode}, 1, 'status reference filled, exit code as expected (failure)';
    }
}

{
    local @ARGV = ('--dry-run');
    my $dry_run = Doit->init;
    is $dry_run->qx($^X, '-e', 'print 42'), undef, 'no output in dry-run mode';
    is $dry_run->qx({info=>1}, $^X, '-e', 'print 42'), 42, 'info=>1: there is output in dry-run mode';
    is $dry_run->info_qx($^X, '-e', 'print 42'), 42, 'info_qx behaves like info=>1';
}


__END__
