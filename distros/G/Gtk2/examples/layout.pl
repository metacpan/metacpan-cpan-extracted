#!/usr/bin/perl -w

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
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
#
# $Id$
#

use strict;
use Gtk2;
use Glib ':constants';

# Initialize GTK
Gtk2->init;

my $window = Gtk2::Window->new("toplevel");
$window->set_title("Damnit");
$window->set_default_size(640,480);

my $scwin = Gtk2::ScrolledWindow->new(undef, undef);
$scwin->set_policy('automatic', 'automatic');
$window->add($scwin);

$window->signal_connect( "destroy" => sub {
		Gtk2->main_quit;
	});

$window->set_border_width(10);

my $layout = Gtk2::Layout->new(undef,undef);
$layout->set_size(640, 480);
$scwin->add($layout);

my $btn = Gtk2::Button->new_from_stock("gtk-quit");
$btn->set_size_request(100, 50);
$layout->put($btn, 100, 120);
my $i = 1;
$btn->signal_connect( 'enter' => sub {
		if( $i > 14 )
		{
			$_[0]->set_label("Ok, Fine Then.");
			$_[0]->signal_connect( "clicked" => sub {
					Gtk2->main_quit;
				});
			return 1;
		}
		elsif( $i > 9 )
		{
			$_[0]->set_label("Quit Already!");
		}
		elsif( $i > 4 )
		{
			$_[0]->set_label("Perhaps, X");
		}
		elsif( $i > 0 )
		{
			$_[0]->set_label("Ha-Ha");
		}
		$_[1][1]->move($_[0], rand(520), rand(410));
		$i++;
		1;
	}, [ $window, $layout ]  );

$window->show_all;


# Enter the event loop
Gtk2->main;

exit 0;
