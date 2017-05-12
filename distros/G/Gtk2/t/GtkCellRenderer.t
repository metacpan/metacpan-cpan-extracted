#!/usr/bin/perl -w

# $Id$

use Gtk2::TestHelper tests => 46;
use strict;

##########################################################################
# custom cell renderer
package Mup::CellRendererPopup;

use Test::More;

use Glib::Object::Subclass
	Gtk2::CellRendererText::,
	;

my %hits;

sub INIT_INSTANCE { $hits{init}++; }

sub GET_SIZE { $hits{size}++;  shift->SUPER::GET_SIZE (@_) }
sub RENDER { $hits{render}++;  shift->SUPER::RENDER (@_) }
sub ACTIVATE { $hits{activate}++;  shift->SUPER::ACTIVATE (@_) }
sub START_EDITING { $hits{edit}++;  shift->SUPER::START_EDITING (@_) }

##########################################################################
# custom cell renderer in the style of 1.02x, to check for regressions of
# backward compatibility.
package Mup::CellRendererPopupCompat;

use Test::More;

use Glib::Object::Subclass
	Gtk2::CellRendererText::,
	;

__PACKAGE__->_install_overrides;

my %hits_compat;

sub INIT_INSTANCE { $hits_compat{init}++; }

sub on_get_size { $hits_compat{size}++;  shift->parent_get_size (@_) }
sub on_render { $hits_compat{render}++;  shift->parent_render (@_) }
sub on_activate { $hits_compat{activate}++;  shift->parent_activate (@_) }
sub on_start_editing { $hits_compat{edit}++;  shift->parent_start_editing (@_) }

##########################################################################
# custom cell renderer with newly created entry in START_EDITING
package My::CellRendererNewEntry;
use strict;
use warnings;
use Glib::Object::Subclass 'Gtk2::CellRendererText';
my %hits_newentry;
sub INIT_INSTANCE { $hits_newentry{init}++; }
sub GET_SIZE { $hits_newentry{size}++;  shift->SUPER::GET_SIZE (@_) }
sub RENDER { $hits_newentry{render}++;  shift->SUPER::RENDER (@_) }
sub ACTIVATE { $hits_newentry{activate}++;  shift->SUPER::ACTIVATE (@_) }
sub START_EDITING { $hits_newentry{edit}++;
                    my $entry = Gtk2::Entry->new;
                    $entry->signal_connect (destroy => \&_editable_destroy);
                    return $entry;
                  }
sub _editable_destroy { $hits_newentry{editable_destroy}++ }

##########################################################################
# driver code
package main;

my $window = Gtk2::Window->new;
$window->set_title ('cell renderer test');
$window->signal_connect (delete_event => sub { Gtk2->main_quit; 0; });

my $vbox = Gtk2::VBox->new;
$window->add ($vbox);

my $label = Gtk2::Label->new;
$label->set_markup ('<big>F-Words</big>');
$vbox->pack_start ($label, 0, 0, 0);

# create and load the model
my $model = Gtk2::ListStore->new ('Glib::String', 'Glib::Scalar', 'Glib::Int');
foreach (qw/foo fluffy flurble frob frobnitz ftang fire truck/) {
	my $iter = $model->append;
	$model->set ($iter, 0, $_);
}

# now a view
my $treeview = Gtk2::TreeView->new ($model);

#
# custom cell renderer
#
ok (my $renderer = Mup::CellRendererPopup->new, 'Mup::CellRendererPopup->new');
$renderer->set (mode => 'editable');
$renderer->set (editable => 1);
my $column = Gtk2::TreeViewColumn->new_with_attributes ('selector', $renderer,
                                                        text => 0,);
# this handler commits the user's selection to the model.  compare with
# the one for the typical text renderer -- the only difference is a var name.
$renderer->signal_connect (edited => sub {
		my ($cell, $text_path, $new_text, $model) = @_;
		my $path = Gtk2::TreePath->new_from_string ($text_path);
		my $iter = $model->get_iter ($path);
		$model->set ($iter, 2, $new_text);
	}, $model);
$treeview->append_column ($column);

#
# custom cell renderer, compat mode
#
ok (my $renderer_compat = Mup::CellRendererPopupCompat->new, 'Mup::CellRendererPopupCompat->new');
$renderer_compat->set (mode => 'editable');
$renderer_compat->set (editable => 1);
my $column_compat = Gtk2::TreeViewColumn->new_with_attributes ('selector', $renderer_compat,
                                                               text => 0,);
# this handler commits the user's selection to the model.  compare with
# the one for the typical text renderer -- the only difference is a var name.
$renderer_compat->signal_connect (edited => sub {
		my ($cell, $text_path, $new_text, $model) = @_;
		my $path = Gtk2::TreePath->new_from_string ($text_path);
		my $iter = $model->get_iter ($path);
		$model->set ($iter, 2, $new_text);
	}, $model);
$treeview->append_column ($column_compat);

#
# new entry cell renderer
#
my $renderer_newentry = My::CellRendererNewEntry->new;
$renderer_newentry->set (mode => 'editable');
my $column_newentry = Gtk2::TreeViewColumn->new_with_attributes
    ('new-entry', $renderer_newentry, text => 0,);
$treeview->append_column ($column_newentry);

#
# plain core CellRendererText
#
my $renderer_text = Gtk2::CellRendererText->new;
$renderer_text->set (editable => 1);
my $column_text = Gtk2::TreeViewColumn->new_with_attributes
    ('core-text', $renderer_text, text => 0,);
$treeview->append_column ($column_text);

##########################################################################

$vbox->pack_start ($treeview, 1, 1, 0);

$window->show_all;

##########################################################################

#
# test the vfunc-involving stuff for all renderers
#
my $rect = Gtk2::Gdk::Rectangle->new (5, 5, 10, 10);
my $event = Gtk2::Gdk::Event->new ("button-press");
foreach my $r ($renderer, $renderer_compat, $renderer_newentry, $renderer_text) {
	my @size = $r->get_size ($treeview, $rect);
	is (@size, 4);
	like($size[0], qr/^\d+$/);
	like($size[1], qr/^\d+$/);
	like($size[2], qr/^\d+$/);
	like($size[3], qr/^\d+$/);

	$r->render ($window->window, $treeview, $rect, $rect, $rect, [qw(sorted prelit)]);
	ok(!$r->activate ($event, $treeview, "0", $rect, $rect, qw(selected)));

	{
	  my $editable = $r->start_editing ($event, $treeview, "0", $rect, $rect, qw(selected));
	  isa_ok ($editable, "Gtk2::Entry");
	  my $destroyed = 0;
	  $editable->signal_connect (destroy => sub { $destroyed = 1 });
	  undef $editable;
	  is ($destroyed, 1,
	      "editable from start_editing using $r destroyed when forgotten");
	}
}

#
# test the normal stuff just for one renderer
#
isa_ok ($renderer, "Gtk2::CellRenderer");

$renderer->set_fixed_size (23, 42);
is_deeply([$renderer->get_fixed_size], [23, 42]);

SKIP: {
	skip "editing_canceled is new in 2.4", 0
		unless Gtk2->CHECK_VERSION (2, 4, 0);

	my $renderer = Gtk2::CellRendererText->new;
	$renderer->editing_canceled;
}

SKIP: {
	skip "stop_editing is new in 2.6", 0
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	my $renderer = Gtk2::CellRendererText->new;
	$renderer->stop_editing (FALSE);
}

SKIP: {
	skip 'new 2.18 stuff', 6
		unless Gtk2->CHECK_VERSION(2, 18, 0);

	my $renderer = Gtk2::CellRendererText->new;

	$renderer->set_visible (TRUE);
	ok ($renderer->get_visible);

	$renderer->set_sensitive (TRUE);
	ok ($renderer->get_sensitive);

	$renderer->set_alignment (0.5, 0.5);
	my ($x, $y) = $renderer->get_alignment;
	delta_ok ($x, 0.5);
	delta_ok ($y, 0.5);

	$renderer->set_padding (23, 42);
	($x, $y) = $renderer->get_padding;
	is ($x, 23);
	is ($y, 42);
}

##########################################################################

run_main sub {
	# set the cursor on the various columns, with editing mode on, to
	# trigger the vfuncs
	$treeview->set_cursor (Gtk2::TreePath->new_from_string ('0'),
	                       $column, 1);
	$treeview->set_cursor (Gtk2::TreePath->new_from_string ('0'),
	                       $column_compat, 1);
	$treeview->set_cursor (Gtk2::TreePath->new_from_string ('0'),
	                       $column_newentry, 1);

        # and not editing any more
	$treeview->set_cursor (Gtk2::TreePath->new_from_string ('0'),
	                       $column_text, 0);
};


is_deeply ([ sort keys %hits ], [ qw/edit init render size/ ], 'callbacks encountered');
is_deeply ([ sort keys %hits_compat ], [ qw/edit init render size/ ], 'callbacks encountered');

# one start_editing programmatically, and one from set_cursor of $treeview
is ($hits_newentry{edit}, 2);
is ($hits_newentry{editable_destroy}, 2,
   'the otherwise unreferenced GtkEntry should be destroyed');

__END__

Copyright (C) 2003-2005, 2009 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
