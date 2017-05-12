#!/usr/bin/perl

# $Id$

use Gtk2::TestHelper tests => 3;

# --------------------------------------------------------------------------- #

package CellRendererFoo;

use Glib::Object::Subclass
	Gtk2::CellRendererText::,
	;

our $hits = 0;

sub GET_SIZE {
	#warn __PACKAGE__;
	$hits++;
	if ($hits > 50) {
		die 'Overflow';
	}
	shift->SUPER::GET_SIZE (@_);
}

package CellRendererBar;

use Glib::Object::Subclass
	CellRendererFoo::,
	;

our $hits = 0;

sub GET_SIZE {
	#warn __PACKAGE__;
	$hits++;
	shift->SUPER::GET_SIZE (@_);
}

# --------------------------------------------------------------------------- #

package CellRendererEmpty;

use Glib::Object::Subclass
	Gtk2::CellRendererText::,
	;

package ProxyDialog;

use Glib::Object::Subclass
	Gtk2::Dialog::
	;

sub INIT_INSTANCE {
	my ($self) = @_;

	my $vbox = $self->vbox;

	my $model = Gtk2::ListStore->new ('Glib::String');
	foreach (qw/foo fluffy flurble frob frobnitz ftang fire/) {
		my $iter = $model->append;
		$model->set ($iter, 0 => $_);
	}

	my $view = Gtk2::TreeView->new ($model);
	$vbox->add ($view);

	my $renderer = CellRendererEmpty->new;
	my $column = Gtk2::TreeViewColumn->new_with_attributes ('F-Words', $renderer,
	                                                        text => 0);
	$view->append_column ($column);

	# This eventually results in a call to CellRendererEmpty::GET_SIZE.
	$self->show_all;
}

# --------------------------------------------------------------------------- #

package main;

# Test that Perl renderers can chain up without endless loops ensuing.  Even if
# a Perl renderer inherits from a Perl renderer.
{
	my $model = Gtk2::ListStore->new ('Glib::String');
	foreach (qw/foo fluffy flurble frob frobnitz ftang fire/) {
		my $iter = $model->append;
		$model->set ($iter, 0 => $_);
	}

	my $view = Gtk2::TreeView->new ($model);

	my $renderer = CellRendererBar->new;
	my $column = Gtk2::TreeViewColumn->new_with_attributes ('F-Words', $renderer,
	                                                        text => 0);
	$view->append_column ($column);

	my $window = Gtk2::Window->new;
	$window->add ($view);

	ok (eval { $window->show_all; 1; }, 'no overflow');
	ok ($CellRendererFoo::hits == $CellRendererBar::hits,
	    'both classes were hit just as often');
}

# Test that calls to vfuncs from strange places (like
# ProxyDialog::INIT_INSTANCE) don't confuse the fallback functions in
# Gtk2::CellRenderer.
{
	ok (eval { my $dialog = ProxyDialog->new; 1; }, 'no exception');
}
