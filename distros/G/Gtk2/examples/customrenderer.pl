#!/usr/bin/perl -w

=doc

Implement a custom CellRenderer with a multi-line editor, by deriving a
TextView subclass which implements the CellEditable GInterface.

=cut

#
# Copyright (C) 2003 by muppet.
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

use Gtk2 -init;
use Gtk2::Gdk::Keysyms;

#############################################################################
# First, we need a TextView which implements CellEditable.

package Mup::MultilineEntry;

use Data::Dumper;
use constant TRUE => 1;
use constant FALSE => 0;

use Glib::Object::Subclass
	Gtk2::TextView::,
	# tell Glib that this new type will implement the CellEditable
	# GInterface.
	interfaces => [ Gtk2::CellEditable:: ],
	;

sub set_text { shift->get_buffer->set_text (shift); }
sub get_text {
	my $buffer = shift->get_buffer;
	$buffer->get_text ($buffer->get_start_iter,
	                   $buffer->get_end_iter, TRUE);
}

sub START_EDITING { warn "start editing\n"; }
sub EDITING_DONE { warn "editing done\n"; }
sub REMOVE_WIDGET { warn "remove widget\n"; }

###############################################################################
# and now, a CellRenderer that uses Mup::MultilineEntry for editing.

package Mup::CellRendererMultiline;

use Glib qw(TRUE FALSE);

use Glib::Object::Subclass
	"Gtk2::CellRendererText",
;

sub START_EDITING {
	my ($cell, $event, $view, $path, $background_area,
	    $cell_area, $flags) = @_;

	my $entry = Mup::MultilineEntry->new;
	$entry->set (border_width => $cell->get ('ypad'));
	$entry->set_text ($cell->get ('text'));
	$entry->grab_focus;

	$entry->signal_connect (key_press_event => sub {
		my ($widget, $event) = @_;

		if (($event->keyval == $Gtk2::Gdk::Keysyms{Return} ||
		     $event->keyval == $Gtk2::Gdk::Keysyms{KP_Enter})
		    and not $event->state & 'control-mask') {
			$cell->signal_emit (edited => $path, $entry->get_text);
			$entry->destroy;
			return TRUE;
		}

		return FALSE;
	});

	# Make sure the entry has the correct height.  On some versions of
	# gtk+, the entry would otherwise be just a few pixels tall.
	$entry->set (height_request => $cell_area->height);

	$entry->show;

	return $entry;
}


###############################################################################
# driver code.

package main;

use Glib qw(TRUE FALSE);

my $window = Gtk2::Window->new;
$window->set_title ("Multiline CellRenderer");
$window->signal_connect (delete_event => sub { Gtk2->main_quit; FALSE });

my $model = Gtk2::ListStore->new (qw(Glib::String));
my $view = Gtk2::TreeView->new ($model);

foreach ('this is a test',
         "here's some text\nwith newlines in\nain't it cool\nno rubbish bin",
	 "try editing with both\nrenderers.",
	 "in the custom one\nuse Ctrl+Enter to\nadd a new line") {
	$model->set ($model->append, 0 => $_);
}

sub cell_edited {
	my ($cell, $path, $new_value) = @_;
	my $iter = Gtk2::TreePath->new_from_string ($path);
	$model->set ($model->get_iter ($iter), 0 => $new_value);
}

my $renderer = Mup::CellRendererMultiline->new;
$renderer->set (editable => TRUE);
$renderer->signal_connect (edited => \&cell_edited);
my $column = Gtk2::TreeViewColumn->new_with_attributes ("custom renderer",
                                                        $renderer,
                                                        text => 0);

$view->append_column ($column);

$renderer = Gtk2::CellRendererText->new;
$renderer->set (editable => TRUE);
$renderer->signal_connect (edited => \&cell_edited);
$column = Gtk2::TreeViewColumn->new_with_attributes ("standard renderer",
                                                     $renderer,
                                                     text => 0);

$view->append_column ($column);

my $scroller = Gtk2::ScrolledWindow->new;
$scroller->set_policy (qw(automatic automatic));
$scroller->add ($view);

my $check = Gtk2::CheckButton->new ('resizable columns');
$check->set_active (FALSE);
$check->signal_connect (toggled => sub {
	map { $_->set_resizable ($check->get_active); } $view->get_columns;
});

my $box = Gtk2::VBox->new;
$box->add ($scroller);
$box->pack_start ($check, FALSE, FALSE, 0);
$window->add ($box);
$window->set_default_size (300, 200);
$window->show_all;

Gtk2->main;
