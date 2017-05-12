#!/usr/bin/perl

#
# Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the full
# list, See LICENSE for full terms.)
# 
# -rm
# 
# $Id$
#

use strict;
use warnings;

use Gtk2 '-init';
use Gtk2::Gdk::Keysyms;

# this image was yanked from a gnome icon, and then modified (by adding the P).
# this is only an example of an inline image; the pixbuf data could come from
# anywhere, perhaps more likely from a file using new_from_file().
my @letter_portrait = (
                '48 48 9 1',
                ' 	c None',
                '.	c #808080',
                '+	c #FFFFFF',
                '@	c #000000',
                '#	c #E21818',
                '$	c #C0C0C0',
                '%	c #0000FF',
                '&	c #000080',
                '*	c #00FFFF',
                '      ...........................               ',
                '      .+++++++++++++++++++++++++.@              ',
                '      .+++++++++++++++++++++++++..@             ',
                '      .+++###########+++++++++++.$.@            ',
                '      .+++############%&%&%&%+++.+$.@           ',
                '      .+++#############+++++++++.++$.@          ',
                '      .+++####+++++#####++++++++.+++$.@         ',
                '      .+++####&%&%&%####&%&%%+++.++++$.@        ',
                '      .+++####++++++####++++++++.+++++$.@       ',
                '      .+++####++++++####++++++++.++++++$.@      ',
                '      .+++####%&%&%#####%&%&%+++.+++++++$.@     ',
                '      .+++#############+++++++++@@@@@@@@@@@@    ',
                '      .+++############+++++++++++..........@    ',
                '      .+++###########%&%&%&%&+++++$$$$$$$$$@    ',
                '      .+++####++++++++++++++++++++++++++++$@    ',
                '      .+++####++++++++++++++++++++++++++++$@    ',
                '      .+++####%&%&%&%&%&%&%&%&%&%&%&%&%+++$@    ',
                '      .+++####++++++++++++++++++++++++++++$@    ',
                '      .+++####++++++++++++++++++++++++++++$@    ',
                '      .+++####&%&%&%&%&%&%&%&%&%&%&%&%&+++$@    ',
                '      .+++####++++++++++++++++++++++++++++$@    ',
                '      .+++++++++++++++++++++++++++++++++++$@    ',
                '      .+++%&%&%&%&%&%&%&++.............+++$@    ',
                '      .+++++++++++++++++++.$$*******$$.+++$@    ',
                '      .+++++++++++++++++++.$$$+$+$+$$$.+++$@    ',
                '      .+++&%&%&%&%&%&%&%++.*$+$+$+$+$*.+++$@    ',
                '      .+++++++++++++++++++.*+$+$+$+$+*.+++$@    ',
                '      .+++++++++++++++++++.*$+$+$+$+$*.+++$@    ',
                '      .+++%&%&%&%&%&%&%&++.*+$+$+$+$+*.+++$@    ',
                '      .+++++++++++++++++++.*$+$+$+$+$*.+++$@    ',
                '      .+++++++++++++++++++.*+$+$+$+$+*.+++$@    ',
                '      .+++&%&%&%&%&%&%&%++.*$+$+$+$+$*.+++$@    ',
                '      .+++++++++++++++++++.$$$+$+$+$$$.+++$@    ',
                '      .+++++++++++++++++++.$$*******$$.+++$@    ',
                '      .+++%&%&%&%&%&%&%&++.............+++$@    ',
                '      .+++++++++++++++++++++++++++++++++++$@    ',
                '      .+++++++++++++++++++++++++++++++++++$@    ',
                '      .+++&%&%&%&%&%&%&%&%&%&%&%&%&%&%&+++$@    ',
                '      .+++++++++++++++++++++++++++++++++++$@    ',
                '      .+++++++++++++++++++++++++++++++++++$@    ',
                '      .+++%&%&%&%&%&%&%&%&%&%&%&++++++++++$@    ',
                '      .+++++++++++++++++++++++++++++++++++$@    ',
                '      .+++++++++++++++++++++++++++++++++++$@    ',
                '      .+++++++++++++++++++++++++++++++++++$@    ',
                '      .+++++++++++++++++++++++++++++++++++$@    ',
                '      .+++++++++++++++++++++++++++++++++++$@    ',
                '      .$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@    ',
                '      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    '
		);


# the stock id our stock item will be accessed with
my $stock_id = 'letter-portrait';

# add a new entry to the stock system with our id
Gtk2::Stock->add ({
		stock_id => $stock_id,
		label    => '_Letter Portrait',
		modifier => [],
		keyval   => $Gtk2::Gdk::Keysyms{L},
		translation_domain => 'gtk2-perl-example',
	});

# create an icon set, with only one member in this particular case
my $icon_set = Gtk2::IconSet->new_from_pixbuf (
		Gtk2::Gdk::Pixbuf->new_from_xpm_data (@letter_portrait));

# create a new icon factory to handle rendering the image at various sizes...
my $icon_factory = Gtk2::IconFactory->new;
# add our new stock icon to it...
$icon_factory->add ($stock_id, $icon_set);
# and then add this custom icon factory to the list of default places in
# which to search for stock ids, so any gtk+ code can find our stock icon.
$icon_factory->add_default;


#
# rest is just an example of using the stock icon.
#
my $win = Gtk2::Window->new;
$win->signal_connect (destroy => sub { Gtk2->main_quit; });

my $button = Gtk2::Button->new_from_stock ('letter-portrait');
$button->signal_connect (clicked => sub { Gtk2->main_quit; });
$win->add ($button);

$win->show_all;
Gtk2->main;

