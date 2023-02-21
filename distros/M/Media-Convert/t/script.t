#!/usr/bin/perl -w

use v5.24;

use Test::More;

use feature "signatures";
no warnings "experimental::signatures";

my $scriptpath;

if(-f "/usr/bin/mc-encode") {
	$scriptpath = "/usr/bin";
} else {
	$scriptpath = "./scripts";
}

sub run (@command) { ## no critic(ProhibitSubroutinePrototypes)
	print "running: '", join("' '", @command), "'\n";
	system(@command) == 0 or die "system @command failed: $?";
}

run("perl", "-I", $INC[0], "$scriptpath/mc-encode", "--input", "t/testvids/bbb.mp4", "--output", "bbb.webm", "--multipass", "--profile", "webm");
ok(-f "bbb.webm", "mc-encode creates a video");

done_testing;
