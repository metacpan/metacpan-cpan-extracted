#
# $Id$
#

#########################
# Gtk2 Tests
# 	- rm
#########################

$ENV{LANG} = 'C';

use Gtk2;
use Test::More;

if( Gtk2->init_check )
{
	plan tests => 8;
	require_ok('Gtk2::Spell');
}
else
{
	plan skip_all =>
		'Gtk2->init_check failed, probably unable to open DISPLAY';
}

use constant TRUE => 1;
use constant FALSE => 0;

Gtk2->init;

my $view = Gtk2::TextView->new;
$view->set_wrap_mode('word');
ok(1);

# could be $spell = Gtk2::Spell->new;
ok( my $spell = Gtk2::Spell->new_attach($view) );

my $scroll = Gtk2::ScrolledWindow->new( );
$scroll->set_policy('automatic', 'automatic');
$scroll->set_shadow_type('in');
$scroll->add($view);
ok(1);

my $box = Gtk2::VBox->new( FALSE, 5 );
$box->pack_start(Gtk2::Label->new("Type some text into the text box.\n".
		"Try misspelling some words.  Then right-click on them."),
				FALSE, FALSE, 0);
$box->pack_start($scroll, TRUE, TRUE, 0);
$box->show_all;
ok(1);

my $win = Gtk2::Window->new;
$win->set_default_size(400, 300);
$win->set_title("Simple GtkSpell Demonstration");
$win->set_border_width(10);
$win->add($box);
$win->show;
ok(1);

Glib::Idle->add( sub {
		$buf = $view->get_buffer;
		ok(1);
		$buf->insert_at_cursor("Hello world, this is a teast, with "
			              ."various mis-speellings on puorpuse.");
		ok(1);
		Gtk2->main_quit;
		0;
	});

Gtk2->main;

1;
__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.
