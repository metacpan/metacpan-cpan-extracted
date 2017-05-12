#!/usr/bin/perl -w
use File::Spec::Functions 'devnull';
use Test::More;
use strict;

BEGIN { plan tests => 11 }

use Mac::Memory;
use Mac::Notification;
use Mac::Processes;
use MacPerl 'DoAppleScript';

SKIP: {
	skip "Set MAC_CARBON_GUI in env to run tests", 11
		unless $ENV{MAC_CARBON_GUI};

	my($process, $name, $back);
	if ($^O eq 'MacOS') {
		$name = 'MacPerl';
		$process = GetCurrentProcess();
	} else {
		# current process is "perl"!  We want the parent,
		# e.g., Terminal, as it is hard to put a non-application
		# process in the "background"
		my $current = $Process{ GetCurrentProcess() };
		my $parent  = $Process{ $current->processLauncher };

		# if no parent app, get Finder
		if (!$parent) {
			while (my($psn, $psi) = each %Process) {
				$parent = $psi, last if $psi->processName eq 'Finder';
			}
		}
		# we'll use perl if we have to, i suppose ...
		$current = $parent if $parent;

		$name      = $current->processName;
		$process   = $current->processNumber;
	}

	ok($process, 'process number');
	ok($name, 'process name');

	if (is_front($process)) {
		ok(my $notification = NMRec->new(
			nmStr	=> "Switch $name to the background, please.  " .
				"I'll switch in 30 seconds if you don't."
		), 'create notification');

		ok(NMInstall($notification),	'install notification');

		my $count = 0;
		while (is_front($process)) {
			sleep 1;
			if (++$count >= 30) {
				# fails if Finder is not running ... but we don't want to
				# wait around forever
				DoAppleScript('tell app "Finder" to activate');
				last;
			}
		}
		$back = GetFrontProcess();
		ok(NMRemove($notification),	'remove notification');
	} else {
		ok(1, "$name is in background") for 1..3;
	}

	ok(my $notification = NMRec->new(
		nmSound => Handle->new(-1),
		nmStr	=> "Please wait a few seconds, I will bring $name to the front.",
	), 'create notification');

	ok(NMInstall($notification),	'install notification');
	sleep 1;
	if ($back) {
		ok(SetFrontProcess($back),      'make sure in background');
	} else {
		pass('make sure in background');
	}

	my $count = 0;
	until (is_front($process)) {
		sleep 1;
		last if ++$count >= 3;
	}

	ok(NMRemove($notification),	'remove notification');
	sleep 1;
#	ok(SetFrontProcess($process),   'switching back');
	ok(my $lp = new LaunchParam(
		launchAppSpec		=> $Mac::Processes::Process{$process}->processAppSpec,
		launchControlFlags	=> launchContinue(),
	), 'create launch param');
	ok(LaunchApplication($lp),	'switching back');
}

sub is_front {
	my($process) = @_;
	return 1 if SameProcess($process, GetFrontProcess());

	my $name = $Process{GetFrontProcess()}->processName;
	return 1 if $name eq 'SystemUIServer' || $name eq 'UserNotificationCenter';

	return 0;
}

__END__

# notification with sound is broken.  can we fix it?  test for it?
# notification with app icon ... how to specify app icon, when "app"
# is perl?  any way?

#
# Notify with custom sound and application icon only. 
# Sample from pitchshifter's _www.pitchshifter.com_ used with 
# permission.
#
$file = -d 't' ? 't/Notification.rsrc' : 'Notification.rsrc';
($res = FSpOpenResFile($file, 0)) or die $^E;
$snd = GetResource("snd ", 128);
DoNotify(new NMRec(nmMark=>0, nmSound=>$snd));
CloseResFile($res);
