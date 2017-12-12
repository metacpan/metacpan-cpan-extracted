#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;

plan 'no_plan';

use Doit;
use Doit::Util qw(in_directory);

use Errno qw(ENOENT);

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
    like $@, qr{^Command exited with exit code 9};
} else {
    like $@, qr{^Command died with signal 9, without coredump};
    is $@->{signalnum}, 9;
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

__END__
