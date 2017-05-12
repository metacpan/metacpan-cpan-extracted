#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

# Tests for the Perl module IPC::Run3::Shell
# 
# Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use IPC_Run3_Shell_Testlib;

# These tests are here to test out some of the behaviors of IPC::Run3,
# which may change over time, so they shouldn't be part of normal testing.
# It's documented that this module just passes through IPC::Run3's behavior,
# and that we assume that IPC::Run3 is tested enough.

use Test::More $AUTHOR_TESTS && !$DEVEL_COVER ? (tests=>13)
	: (skip_all=>$DEVEL_COVER?'skipping during Devel::Cover tests':'author tests');

use IPC::Run3::Shell;
use warnings FATAL=>'IPC::Run3::Shell';

my $s = IPC::Run3::Shell->new();

# Possible To-Do for Later: The following two tests fail when run as part of the harness when builing for Perl 5.8.9
# (they work just fine when run individually)
output_is { $s->perl({stdout=>\*STDERR},'-MIO::Handle','-e','print STDOUT "ooo\n"; STDOUT->flush; print STDERR "eee\n"'); 1 }
	"", "ooo\neee\n", 'stdout -> stderr';
output_is { $s->perl({stderr=>\*STDOUT},'-MIO::Handle','-e','print STDOUT "ooo\n"; STDOUT->flush; print STDERR "eee\n"'); 1 }
	"ooo\neee\n", "", 'stderr -> stdout';

# NOTE the following tests show that the way IPC::Run3 (currently!) apparently works is that the stderr redirection
# takes effect first, and after that the stdout redirection takes effect.
# If IPC::Run3 ever changes that, these tests will break (and the TO DO tests below may start passing)
{
	my $e;
	output_is { $s->perl({stdout=>\*STDERR,stderr=>\$e},'-MIO::Handle','-e','print STDOUT "ooo\n"; STDOUT->flush; print STDERR "eee\n"'); 1 }
		"", "ooo\n", 'stdout -> stderr w/ capt';
	is $e, "eee\n", 'stderr';
}
{
	my $o;
	output_is { $s->perl({stdout=>\$o,stderr=>\*STDOUT},'-MIO::Handle','-e','print STDOUT "ooo\n"; STDOUT->flush; print STDERR "eee\n"'); 1 }
		"", "", 'stderr -> stdout w/ capt';
	is $o, "ooo\neee\n", 'stdout';
}
# NOTE this test checks the current state of things;
# the TO DO swap test below might be a "nice-to-have" feature?
output_is { $s->perl({stdout=>\*STDERR,stderr=>\*STDOUT},'-MIO::Handle','-e','print STDOUT "ooo\n"; STDOUT->flush; print STDERR "eee\n"'); 1 }
	"", "ooo\neee\n", 'stderr <-> stdout';

# not using output_is here because that doesn't seem to work with the the TO DO block
use Capture::Tiny 'capture';
# check IPC::Run3 first cause that's the source of the issue
use IPC::Run3 'run3';
my ($out0, $err0) = capture { run3(['perl','-e','print STDOUT "ooo\n"; print STDERR "eee\n"'],undef,\*STDERR,\*STDOUT) };
is $?, 0, 'run3 swap exit code';
my ($out1, $err1) = capture { $s->perl({stdout=>\*STDERR,stderr=>\*STDOUT},'-e','print STDOUT "ooo\n"; print STDERR "eee\n"') };
is $?, 0, 'our swap exit code';
TODO: { local $TODO = "swapping of STDOUT / STDERR not supported (yet??)";
	is $out0, "eee\n", 'run3 swapped stdout';
	is $err0, "ooo\n", 'run3 swapped stderr';
	is $out1, "eee\n", 'our swapped stdout';
	is $err1, "ooo\n", 'our swapped stderr';
}

