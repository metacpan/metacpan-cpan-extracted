#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::All;
use utf8;

use Encode qw( encode );
use FindBin qw($Bin);

use Locale::Simple;

use File::Temp qw/ tempfile tempdir /;

my $tmpdir = tempdir();

l_dry($tmpdir.'/dryrun.po');

is(
	l("Hello"),
	"Hello",
	"simple"
);

is(
	ln("You have %d message","You have %d messages",4),
	'You have 4 messages',
	"dryrun simple plural test with plural"
);

is(
	ln("You have %d message","You have %d messages",1),
	'You have 1 message',
	"dryrun simple plural test with single"
);

is(
	ln("You have %d message of %s","You have %d messages of %s",1,'harry'),
	'You have 1 message of harry',
	"dryrun complex plural test with single"
);

is(
	ln("You have %d message of %s","You have %d messages of %s",4,'harry'),
	'You have 4 messages of harry',
	"dryrun complex plural test with plural"
);

is(io($tmpdir.'/dryrun.po')->slurp,<<__EOT__,'checking generated po');
msgid "Hello"

msgid "You have %d message"
msgid_plural "You have %d messages"

msgid "You have %d message"
msgid_plural "You have %d messages"

msgid "You have %d message of %s"
msgid_plural "You have %d messages of %s"

msgid "You have %d message of %s"
msgid_plural "You have %d messages of %s"

__EOT__

# The same calls as the dry_run_shared_format case in python/test.py: both
# runtimes write this file byte for byte.
my $shared = $tmpdir.'/shared.po';
l_dry($shared);

is_deeply(
	[
		l('Hello'),
		l(''),
		ld('othertest','Hello'),
		lp('alien','Hello'),
		ln('%2$s has %1$d message','%2$s has %1$d messages',2,'harry'),
		ldnp('othertest','inbox','You have %d message','You have %d messages',1),
		l("Say \"%s\"\\n\nGrüße",'hi'),
		l("Tab\there\rand CR"),
	],
	[
		'Hello',
		'',
		'Hello',
		'Hello',
		'harry has 2 messages',
		'You have 1 message',
		"Say \"hi\"\\n\nGrüße",
		"Tab\there\rand CR",
	],
	'dry run formats domain, context, plural and positional calls',
);

is(io($shared)->binary->all,encode('UTF-8',<<'__EOT__'),'dry-run file matches the shared expected bytes');
msgid "Hello"

# domain: othertest
msgid "Hello"

msgctxt "alien"
msgid "Hello"

msgid "%2$s has %1$d message"
msgid_plural "%2$s has %1$d messages"

# domain: othertest
msgctxt "inbox"
msgid "You have %d message"
msgid_plural "You have %d messages"

msgid "Say \"%s\"\\n\nGrüße"

msgid "Tab\there\rand CR"

__EOT__

# Leaving dry-run mode brings back the l_dir check, as in the siblings.
l_dry(undef);
eval { l('Hello') };
like($@,qr/please set a locale directory/,'l_dry(undef) brings back the l_dir check');

# The dry-run file has LF line ends on every platform. A child perl with
# the :crlf default layer that Windows uses writes the same bytes.
{
	local $ENV{PERLIO} = ':unix:crlf';
	my $crlf = $tmpdir.'/crlf.po';
	system( $^X, ( map { '-I'.$_ } grep { !ref } @INC ), '-MLocale::Simple',
	  '-e', 'l_dry(shift); ld(q(othertest),q(Hello))', $crlf ) == 0
	  or die 'child perl failed: '.$?;
	my $bytes = io($crlf)->binary->all;
	unlike($bytes,qr/\r/,'dry-run file holds no CR under a :crlf default layer');
	is($bytes,qq{# domain: othertest\nmsgid "Hello"\n\n},'dry-run file keeps LF line ends');
}

# "0" is a domain, msgctxt, msgid_plural and file name like any other string:
# it gets its line, and a msgid_plural of "0" puts n in front of the arguments
# and is picked for n != 1. python/test.py checks the same.
{
	my $zero = $tmpdir.'/zero.po';
	l_dry($zero);
	is_deeply(
		[ ld('0','Hello'), lp('0','Hello'), ln('%d file','0',1), ln('%d file','0',2) ],
		[ 'Hello', 'Hello', '1 file', '0' ],
		'"0" as domain, msgctxt and msgid_plural',
	);
	l_dry(undef);
	is(io($zero)->binary->all,<<'__EOT__','dry-run blocks keep their "0" lines');
# domain: 0
msgid "Hello"

msgctxt "0"
msgid "Hello"

msgid "%d file"
msgid_plural "0"

msgid "%d file"
msgid_plural "0"

__EOT__
	l_dry('0',1);
	is(eval { l('Hello') },'Hello','l_dry("0") switches dry-run mode on');
	l_dry(undef);
}

done_testing;
