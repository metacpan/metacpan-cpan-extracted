#!/usr/bin/perl -w

#
# Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the full
# list)
# 
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
# 
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
# more details.
# 
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330, Boston, MA  02111-1307  USA.
#
# $Id$
#

use strict;

use Gtk2;
use Gtk2::Spell;

use constant TRUE => 1;
use constant FALSE => 0;

Gtk2->init;

my $view = Gtk2::TextView->new;
$view->set_wrap_mode('word');

# could be $spell = Gtk2::Spell->new;
# croaks on error
my $spell = Gtk2::Spell->new_attach($view);

my $scroll = Gtk2::ScrolledWindow->new( undef, undef );
$scroll->set_policy('automatic', 'automatic');
$scroll->set_shadow_type('in');
$scroll->add($view);

my $box = Gtk2::VBox->new( FALSE, 5 );
$box->pack_start(Gtk2::Label->new("Type some text into the text box.\n".
		"Try misspelling some words.  Then right-click on them."),
				FALSE, FALSE, 0);
$box->pack_start($scroll, TRUE, TRUE, 0);
$box->show_all;

my $win = Gtk2::Window->new;
$win->set_default_size(400, 300);
$win->set_title("Simple GtkSpell Demonstration");
$win->set_border_width(10);
$win->signal_connect( 'destroy' => sub {
		Gtk2->main_quit;
	});
$win->add($box);

$win->show;

Gtk2->main;
