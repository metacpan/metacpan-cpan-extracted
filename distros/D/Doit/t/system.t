#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use lib $FindBin::RealBin;

use File::Temp qw(tempdir);
use Test::More;

plan 'no_plan';

use Doit;
use Doit::Util qw(in_directory);

use Errno qw(ENOENT);

use TestUtil qw(signal_kill_num);
my $KILL = signal_kill_num;
my $KILLrx = qr{$KILL};

my $r = Doit->init;

is $r->system($^X, '-e', 'exit 0'), 1;
pass 'no exception';

SKIP: {
    skip "Requires Capture::Tiny", 1
	if !eval { require Capture::Tiny; 1 };
    in_directory {
	my($stdout, $stderr) = Capture::Tiny::capture
	    (sub {
		 $r->system({show_cwd=>1}, 'echo', 'hello');
	     });
	is $stdout, "hello\n";
	my $rootdir = $^O eq 'MSWin32' ? qr{.:/} : qr{/};
	like $stderr, qr{INFO:.*echo hello \(in $rootdir\)};
    } "/";
}

SKIP: {
    skip "Requires Capture::Tiny", 1
	if !eval { require Capture::Tiny; 1 };
    in_directory {
	my($stdout, $stderr) = Capture::Tiny::capture
	    (sub {
		 $r->system({quiet=>1}, 'echo', 'hello');
	     });
	is $stdout, "hello\n";
	is $stderr, '', 'quiet mode';
    } "/";
}

eval { $r->system($^X, '-e', 'exit 1') };
like $@, qr{^Command exited with exit code 1};
is $@->{exitcode}, 1;

eval { $r->system('this-cmd-does-not-exist-'.$$.'-'.time) };
if ($^O eq 'MSWin32') {
    # Different error message on Windows systems
    like $@, qr{^Command exited with exit code 1 at .*t\\system.t line \d+};
    is $@->{exitcode}, 1;
} else {
    like $@, qr{^Could not execute command: .* at .*system.t line \d+};
    is $@->{errno}+0, ENOENT;
    is $@->{exitcode}, -1;
}

SKIP: {
    skip "kill TERM not supported on Windows' system()", 3 if $^O eq 'MSWin32';
    eval { $r->system($^X, '-e', 'kill TERM => $$') };
    like $@, qr{^Command died with signal 15, without coredump};
    is $@->{signalnum}, 15;
    is $@->{coredump}, 'without';
}

eval { $r->system($^X, '-e', 'kill KILL => $$') };
if ($^O eq 'MSWin32') {
    # There does not seem to be any signal handling on Windows
    # --- exit(9) and kill KILL is indistinguishable here.
    like $@, qr{^Command exited with exit code $KILLrx};
} else {
    like $@, qr{^Command died with signal $KILLrx, without coredump};
    is $@->{signalnum}, $KILL;
    is $@->{coredump}, 'without';
}

SKIP: {
    skip "No BSD::Resource available", 1
	if !eval { require BSD::Resource; 1 };
    skip "coredumps disabled", 1
	if BSD::Resource::getrlimit(BSD::Resource::RLIMIT_CORE()) < 4096; # minimum of 4k needed on linux to actually do coredumps
    eval { $r->system($^X, '-e', 'kill ABRT => $$') };
    like $@, qr{^Command died with signal 6, with coredump};
    is $@->{signalnum}, 6;
    is $@->{coredump}, 'with';
}

{
    local @ARGV = ('--dry-run');
    my $tempdir = tempdir('doit_XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
    my $dry_run = Doit->init;

    {
	my $no_create_file = "$tempdir/should_never_happen";
	is $dry_run->system($^X, '-e', 'open my $fh, ">", $ARGV[0] or die $!', $no_create_file), 1, 'returns 1 in dry-run mode';
	ok ! -e $no_create_file, 'dry-run mode, no file was created';
    }

    {
	my $create_file = "$tempdir/should_happen";
	is $dry_run->info_system($^X, '-e', 'open my $fh, ">", $ARGV[0] or die $!', $create_file), 1, 'returns 1 as info_system call';
	ok -e $create_file, 'info_system runs even in dry-run mode';
	$r->unlink($create_file);
    }

    {
	my $create_file = "$tempdir/should_happen";
	is $dry_run->system({info=>1}, $^X, '-e', 'open my $fh, ">", $ARGV[0] or die $!', $create_file), 1, 'returns 1 as system call with info=>1 option';
	ok -e $create_file, 'system with info=>1 option runs even in dry-run mode';
	$r->unlink($create_file);
    }
}

__END__
