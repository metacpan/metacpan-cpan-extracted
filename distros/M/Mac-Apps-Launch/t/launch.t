#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN {
	plan tests => 21;
	use_ok('Mac::Apps::Launch');
}

use Mac::Apps::Launch 1.80;
use Mac::Processes;
use POSIX 'SIGTERM';

use MacPerl '$Version';

SKIP: {
	skip "Not MacPerl", 1 if $^O ne 'MacOS';
	$Version =~ /^(.+)\s+.*$/;
	cmp_ok($1, 'ge', '5.1.4r4', 'Check $MacPerl::Version');
}

my $target = 'MACS';
my @bundles = qw(
	com.apple.calculator
	com.apple.TextEdit
);
my %paths  = map { ($_ => LSFindApplicationForInfo("", $_)) } @bundles;

TODO: {
	local $TODO = "no Mac::Apps::Launch Hide/Show on Mac OS X" if $^O eq 'darwin';

	ok(Hide($target), 'Hide');
	ok(Show($target), 'Show');
}

SKIP: {
#	skip "Mac::Apps::Launch", 3;

	ok(IsRunning($target),     'IsRunning');
	ok(!IsRunning(';;;;'),     'IsRunning');
	ok(SetFront($target),      'SetFront');

}

for my $bundle (keys %paths) { SKIP: {
	my $path = $paths{$bundle};
	skip "Mac::Apps::Launch", 3 unless -e $path;

	my $wasrunning = 0;
	for my $psn (keys %Process) {
		$wasrunning = 1, last if $Process{$psn}->processAppSpec =~ /\Q$path/;
	}
	is((IsRunning($bundle) ? 1 : 0), $wasrunning, 'IsRunning');

	ok(LaunchSpecs($path, 1),  'LaunchSpecs');
	ok((my $psn = IsRunning($bundle)), 'IsRunning');
	sleep 3;
	SKIP: {
		skip "$path was previously running", 1 if $wasrunning;
		my $pid = GetProcessPID($psn);
		ok($pid && kill(SIGTERM, $pid), "Kill $path");
		sleep 3;
	}

	SKIP: {
		skip "$path was previously running", 2 if $wasrunning;
		my $isrunning = 0;
		for my $psn (keys %Process) {
			$isrunning = 1, last if $Process{$psn}->processAppSpec =~ /\Q$path/;
		}
		ok(!$isrunning, "Don't find $path");
		ok(!IsRunning($bundle), 'IsRunning');
	}
} }

SKIP: {
	skip "Mac::Apps::Launch Quit/Launch Finder", 2 unless $ENV{QUITFINDER};

	ok(QuitApps($target),      'QuitApps');
	sleep 5;
	ok(LaunchApps($target),    'LaunchApps');
}

__END__
