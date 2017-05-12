#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN { plan tests => 38 }

use vars '$PAUSE';
use Time::HiRes 'time';
use Mac::Files;
use Mac::Speech;

my(@voicefiles, $voicedir, $voice, $desc, $channel, $desd);
SKIP: {
#	skip "Mac::Speech", 9;

	$voicedir = FindFolder(kOnSystemDisk, kVoicesFolderType);
	if (opendir(my $dh, $voicedir)) {
		@voicefiles = grep /\w/, readdir $dh;
		closedir $dh;
	}
	# this can fail if some voices don't load, or if there are
	# non-voice files installed in the directory
	# +1 for bad voice on Panther that won't load ...
	cmp_ok(CountVoices()+1, '>=', scalar @voicefiles, 'count voices');

	# start with Cellos
	ok($voice   = $Mac::Speech::Voice{Cellos},	'load voice');
	ok($desc    = GetVoiceDescription($voice),	'get description');
	ok($channel = NewSpeechChannel($voice),	'new channel');

	is('Cellos',		$desc->name,		'check name');
	is(kNeuter,		$desc->gender,		'check gender');
	is(50,			$desc->age,		'check age');
	is($voice->creator,	$desc->voice->creator,	'check creator');
	is($voice->id,		$desc->voice->id,	'check id');
}

SKIP: {
	skip "Set MAC_CARBON_SOUND in env to run tests", 3
		unless $ENV{MAC_CARBON_SOUND};

	# sing
	speak($channel, 'Do you like my Cello Voice?',	'sing');
	ok(SetSpeechPitch($channel, 1.2*GetSpeechPitch($channel)),
							'adjust pitch');
	speak($channel, 'Wanna take you higher',	'sing!');
}

SKIP: {
#	skip "Mac::Speech", 10;

	ok(DisposeSpeechChannel($channel),		'dispose channel');

	# try again with default voice
	ok($voice   = $Mac::Speech::Voice{undef},	'load default voice');
	ok($desc    = GetVoiceDescription($voice),	'get description');
	ok($desd    = GetVoiceDescription(),		'get description');
	ok($channel = NewSpeechChannel(),		'new channel');

	is($desc->name,		$desd->name,		'check name');
	is($desc->gender,	$desd->gender,		'check gender');
	is($desc->age,		$desd->age,		'check age');
	is($voice->creator,	$desd->voice->creator,	'check creator');
	is($voice->id,		$desd->voice->id,	'check id');
}

SKIP: {
	skip "Set MAC_CARBON_SOUND in env to run tests", 11
		unless $ENV{MAC_CARBON_SOUND};

	speak($channel, $desc->comment,			'speak default comment');

	# other forms of Speak
	speak('Howdy',					'SpeakString');
	speak($channel, 'Bonjour',
		kNoEndingProsody + kNoSpeechInterrupt,
							'SpeakBuffer');
	speak($channel, 'Como?', kPreflightThenPause,	'SpeakBuffer (shhhh)');

	{
		local $PAUSE = 1;
		speak($channel, <<EOS,			'speak some long text');
$ENV{USER}, welcome, it is very good to see you using Mac Carbon.
Antidisestablishmentarianism is a long word you won't get to the end of.
Trust me, we'll never get here!
EOS

		ok(SpeechBusy(),			'busy');
		sleep 1;

		ok(PauseSpeechAt($channel, kEndOfSentence),
							'pause end of sentence');
		sleep 6;

		ok(ContinueSpeech($channel),		'continue');
		sleep 1;

		ok(PauseSpeechAt($channel, kEndOfWord),	'pause end of word');
		sleep 4;

		ok(ContinueSpeech($channel),		'continue');
		sleep 2;

		ok(StopSpeechAt($channel, kImmediate),	'stop now');
	}
}

SKIP: {
#	skip "Mac::Speech", 1;

	skip 'TextToPhonemes() does not work with Cepstral voices', 1
		if $desc->name =~ /^Cepstral /;

	like(TextToPhonemes($channel, 'Stop all the clocks disconnect the phone'),
		qr/^_st1AAp/, # _st1AAp _1AOl ~DAX _kl1AAks% _d2IHskAXn1EHkt ~DAX _f1OWn.',
							'phonemes');
}

SKIP: {
	skip "Set MAC_CARBON_SOUND in env to run tests", 3
		unless $ENV{MAC_CARBON_SOUND};
	my $file = './testfile.aiff';
	ok(SpeechToFile($channel, $file),		'SpeechToFile');
	speak($channel, 'This is a test file',		'speak to file');
	ok(-s $file,					'file exists');
	unlink $file;
}


SKIP: {
#	skip "Mac::Speech", 1;
	ok(DisposeSpeechChannel($channel),		'dispose channel');
}

sub speak {
	my $msg = pop;
	if (@_ == 2) {
		ok(SpeakText(@_), $msg);
	} elsif (@_ == 1) {
		ok(SpeakString(@_), $msg);
	} elsif (@_ == 3) {
		ok(SpeakBuffer(@_), $msg);
	} else {
		ok(0, 'Bad arguments to speak()');
	}

	unless ($PAUSE) {
		sleep 1 while SpeechBusy();
	}
}

__END__
