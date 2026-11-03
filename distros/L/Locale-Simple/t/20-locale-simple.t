#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use utf8;

use FindBin qw($Bin);

use Locale::Simple;

l_dir($Bin.'/data/locale');
ltd('test');
l_lang('de_DE');

is(
	l('Hello'),
	'Hallo',
	'simple'
);

is(
	ln('You have %d message','You have %d messages',4),
	'Du hast 4 Nachrichten',
	'plural test with plural'
);

is(
	ln('You have %d message','You have %d messages',1),
	'Du hast 1 Nachricht',
	'plural test with single'
);

is(
	ln('You have %d message of %s','You have %d messages of %s',1,'harry'),
	'Du hast 1 Nachricht von harry',
	'plural test with single and additional placeholder'
);

is(
	ln('You have %d message of %s','You have %d messages of %s',4,'harry'),
	'Du hast 4 Nachrichten von harry',
	'plural test with plural and additional placeholder'
);

is(
	ln('%2$s brought %1$d message','%2$s brought %1$d messages',1,'harry'),
	'1 Nachricht gebracht von harry',
	'changed order plural test with single and additional placeholder'
);

is(
	ln('%2$s has %1$d message','%2$s has %1$d messages',4,'harry'),
	'harry hat 4 Nachrichten',
	'other changed order plural test with plural and additional placeholder'
);

is(
	l('Change order test %s %s',1,2),
	'Andere Reihenfolge hier 2 1',
	'changing position test'
);

is(
	l('Other change order test %s %s %s',1,2,3),
	'Verhalten aus http://perldoc.perl.org/functions/sprintf.html 3 1 1',
	'other changing position test'
);

is(
	lp('alien','Hello'),
	'Hallo Ausserirdischer',
	'simple test with context'
);

is(
	l(''),
	'',
	'empty msgid comes back empty'
);

# Argument values go in as they are; a % in them is never read as a format.
# %% in the format gives one %. The same cases run in python/test.py.
is(l('%1$s','100%'),'100%','positional value with a percent sign');
is(l('%s','100%'),'100%','plain value with a percent sign');
is(l('%s and %s','%s','50%'),'%s and 50%','plain values that look like formats');
is(l('%2$s / %1$s','%1$s','5%'),'5% / %1$s','positional values that look like formats');
is(
	ln('%2$s has %1$d message','%2$s has %1$d messages',3,'%d%%'),
	'%d%% hat 3 Nachrichten',
	'translated plural with a percent value',
);
is(l('100%% of %s','%s','extra'),'100% of %s','percent escape in the format, extra argument');
is(l('%%s %s %%','x'),'%s x %','percent escapes around a placeholder');

done_testing;
