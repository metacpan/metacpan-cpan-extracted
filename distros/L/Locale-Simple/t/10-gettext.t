#!/usr/bin/env perl

use strict;
use warnings;
use Test::More 0.98;

use FindBin qw($Bin);

use Locale::gettext_dumb qw(:locale_h :libintl_h);
use POSIX qw( setlocale );

bindtextdomain('test',$Bin.'/data/locale');
bind_textdomain_codeset('test','utf-8');
textdomain('test');

$ENV{LANG} = 'de_DE';
$ENV{LANGUAGE} = 'de_DE';
$ENV{LC_ALL} = 'de_DE';

# gettext ignores LANGUAGE while the messages locale is C or POSIX
# (libintl-perl >= 1.36, like GNU gettext), and most smokers start there.
# Set LC_MESSAGES the way l_lang() does: to the language, or else to a
# locale that is not C, so LANGUAGE picks the catalog.
if ( defined eval { POSIX::LC_MESSAGES() } ) {
	setlocale( LC_MESSAGES, 'de_DE' );
	my $now = setlocale( LC_MESSAGES );
	if ( !defined $now || $now eq 'C' || $now eq 'POSIX' ) {
		my $set;
		for my $fallback ( 'C.UTF-8', 'en_US.UTF-8' ) {
			last if $set = setlocale( LC_MESSAGES, $fallback );
		}
		plan skip_all => 'LC_MESSAGES stays C here: neither de_DE, C.UTF-8 nor en_US.UTF-8 can be set'
		  unless $set;
	}
}

is(gettext("Hello"),"Hallo","simple");
is(sprintf(ngettext("You have %d message","You have %d messages",4),4),'Du hast 4 Nachrichten',"simple plural test with plural");
is(sprintf(ngettext("You have %d message","You have %d messages",1),1),'Du hast 1 Nachricht',"simple plural test with single");
is(sprintf(ngettext("You have %d message of %s","You have %d messages of %s",1),1,'harry'),'Du hast 1 Nachricht von harry',"complex plural test with single");
is(sprintf(ngettext("You have %d message of %s","You have %d messages of %s",4),4,'harry'),'Du hast 4 Nachrichten von harry',"complex plural test with plural");

is(sprintf(gettext("Change order test %s %s"),1,2),'Andere Reihenfolge hier 2 1',"changing position test");

done_testing;
