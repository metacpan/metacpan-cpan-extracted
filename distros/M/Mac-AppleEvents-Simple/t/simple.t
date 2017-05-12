#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN {
	$|++;
	plan tests => 23;
	use_ok('Mac::AppleEvents::Simple');
}


use Mac::AppleEvents::Simple 1.03;
use Mac::AppleEvents::Simple ':all';

use Mac::Files;
use Mac::Processes;
use MacPerl qw(Volumes $Version);

my $target = 'MACS';
(my $volume = scalar Volumes()) =~ s/^.+://;
my $psn = GetCurrentProcess();

# get parent, if one exists, for non-MacPerl
if ($^O ne 'MacOS') {
	my $info = $Process{$psn};
	$psn = $Process{$info->processLauncher}->processNumber
		if $Process{$info->processLauncher};
}

SKIP: {
	skip "Not MacPerl", 1 if $^O ne 'MacOS';
	$Version =~ /^(.+)\s+.*$/;
	cmp_ok($1, 'ge', '5.2.0r4', 'Check $MacPerl::Version');
}

SKIP: {
#	skip "Mac::AppleEvents::Simple", 8;

	# open startup volume by property name
	my $data = <<EOT;
'----':obj {
	form:prop, want:type(prop), seld:type(pnam), from:obj {
		form:prop, want:type(prop), seld:type(sdsk), from:'null'()
	}
}
EOT

	# get startup volume name
	ok(my $evt = do_event(qw(core getd), $target, $data), "Create and do event");
	cmp_ok($!, '==', 0, "No error");

	ok(my $get = $evt->get, "Get value");
	is($get, $volume, "Check value");
	cmp_ok($!, '==', 0, "No error");

	ok(my $get2 = $evt->get(keyDirectObject), "Get value");
	is($get2, $volume, "Check value");
	cmp_ok($!, '==', 0, "No error");
}

SKIP: {
#	skip "Mac::AppleEvents::Simple", 11;

	ok(do_event(qw(misc actv MACS)), "Activate $target");

	# open startup volume by alias
	ok(my $evt = build_event(qw(aevt odoc), $target,
		"'----':alis(\@\@)", NewAliasMinimal(scalar Volumes())
	), "Build event");
	ok($evt->send_event, "Send event");
	cmp_ok($!, '==', 0, "No error");

	# window and name objects
	my $win = "obj { form:indx, want:type(cwin), seld:long(1), from:'null'() }";
	my $nam = "obj { form:prop, want:type(prop), seld:type(pnam), from:$win  }";

	ok(my $evt2 = do_event(qw(core getd), $target, "'----':$nam"), "Get window name");
	cmp_ok($!, '==', 0, "No error");

	ok(my $get = $evt2->get, "Get value");
	is($get, $volume, "Check value");
	cmp_ok($!, '==', 0, "No error");

	ok(do_event(qw(core clos), $target, "'----':$win"), "Close window");
	cmp_ok($!, '==', 0, "No error");
}

SKIP: {
	skip "Not regular process", 2
		unless $Process{$psn}->processType;

	ok(do_event(qw(misc actv), { typeProcessSerialNumber() => pack_psn($psn) }),
		"Activate original process");
	cmp_ok($!, '==', 0, "No error");
}

__END__
