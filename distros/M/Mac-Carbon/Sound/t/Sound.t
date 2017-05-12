#!/usr/bin/perl -w
use File::Spec::Functions;
use Test::More;
use strict;

BEGIN { plan tests => 14 }

use Mac::Resources;
use Mac::Sound;

SKIP: {
	skip "Set MAC_CARBON_SOUND in env to run tests", 4
		unless $ENV{MAC_CARBON_SOUND};

	my $vol = GetDefaultOutputVolume();
	ok(defined($vol),			'get current volume');
	SysBeep(30);
	sleep(1); # allow user to hear

	# let's not blast out people's speakers or eardrums
	ok(1,					'set high volume');
#	ok(SetDefaultOutputVolume(2**32),	'set high volume');
#	SysBeep(30);
#	sleep(1);

	ok(SetDefaultOutputVolume(0),		'set low volume');
	SysBeep(30);
	sleep(1);

	ok(SetDefaultOutputVolume($vol),	'set default volume');
	SysBeep(30);
	sleep(1);
}


my($res, $snd);
SKIP: {
#	skip "Mac::Sound Resource", 7;

	my $ofil = 'Scream.rsrc';
	my $otyp = soundListRsrc();
	my $oid  = 129;
	my $onam = 'Original';

	my $dir1 = catfile(curdir(), 't'); #, $ofil);
	my $dir2 = catfile(curdir(), 'Sound', 't'); #, $ofil);
	my $dir  = -e $ofil			? curdir()
		:  -e catfile($dir1, $ofil)	? $dir1
		:  -e catfile($dir2, $ofil)	? $dir2
		: '';

	my $file = catdir($dir, $ofil);

	if ($file && $^O eq 'MacOS') {
		$res = FSpOpenResFile($file, 0);
	} elsif ($file) {
		$res = FSOpenResourceFile($file, 'rsrc', 0) ||
		       FSOpenResourceFile($file, 'data', 0);
	}

	if ($res) {
		ok($res,				'open resource file');
		is(CurResFile(), $res,			'check current resource file');

		is(Count1Resources($otyp), 1,		'count resources');
		ok($snd = GetResource($otyp, $oid),	'get resource');

		my($id, $type, $name) = GetResInfo($snd);
		is($type, $otyp,			'resource type');
		is($id, $oid,				'resource id');
		is($name, $onam,			'resource name');
	}

	else {
		ok(1, "Can't open $ofil") for 1..2;

		my $n = Count1Resources($otyp);
		ok($n,					"count resources: $n");
		ok($snd = GetIndResource($otyp, $n),	'get resource');

		my($id, $type, $name) = GetResInfo($snd);
		TODO: {
			local $TODO = "For some reason, it is not getting the type back"
				if $^O eq 'darwin';
			is($type, $otyp,		"resource type: $type");
		}
		ok($id,					"resource id: $id");

		ok(1, "Can't open $ofil");
	}
}

SKIP: {
	skip "Set MAC_CARBON_SOUND in env to run tests", 3
		unless $ENV{MAC_CARBON_SOUND};

	ok(my $chan = SndNewChannel(0, 0),		'new sound channel');
	ok(SndPlay($chan, $snd, 0),			'play sound');
	ok(SndDisposeChannel($chan, 0),			'dispose sound');

	CloseResFile($res) if $res;
}

__END__
