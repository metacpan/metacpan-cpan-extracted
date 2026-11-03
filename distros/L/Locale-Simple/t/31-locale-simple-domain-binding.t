#!/usr/bin/env perl

# The domain helpers bind a domain to the l_dir() directory on its first
# use, the way ltd() does, and leave the default domain where it is. A later
# l_dir() moves every bound domain along, whichever call bound it.

use strict;
use warnings;
use Test::More;
use utf8;

use File::Copy qw( copy );
use File::Path qw( make_path );
use File::Temp qw( tempdir );
use FindBin qw( $Bin );

use Locale::Simple;

my $locale = $Bin.'/data/locale';

l_dir($locale);
ltd('test');
l_lang('de_DE');

is(
	ld('othertest','Hello'),
	'Anderes Hallo',
	'a domain no ltd() has bound translates on first use',
);

is(
	l('Hello'),
	'Hallo',
	'the default domain stays after a domain lookup',
);

is(
	ldn('othertest','You have %d message','You have %d messages',4),
	'Du hast 4 AndereNachrichten',
	'plural lookup in the domain bound on first use',
);

# A second directory that holds the two catalogs swapped.
my $swapped = tempdir( CLEANUP => 1 );
my $messages = $swapped.'/de_DE/LC_MESSAGES';
make_path($messages);
copy( $locale.'/de_DE/LC_MESSAGES/othertest.mo', $messages.'/test.mo' )
  or die 'copy othertest.mo: '.$!;
copy( $locale.'/de_DE/LC_MESSAGES/test.mo', $messages.'/othertest.mo' )
  or die 'copy test.mo: '.$!;

l_dir($swapped);

is(
	l('Hello'),
	'Anderes Hallo',
	'l_dir moves the domain ltd bound',
);

is(
	ld('othertest','Hello'),
	'Hallo',
	'l_dir moves the domain bound on first use',
);

l_dir($locale);

is(
	l('Hello'),
	'Hallo',
	'l_dir moves the ltd domain back',
);

is(
	ld('othertest','Hello'),
	'Anderes Hallo',
	'l_dir moves the first-use domain back',
);

done_testing;
