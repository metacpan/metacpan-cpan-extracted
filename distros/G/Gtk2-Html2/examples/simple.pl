#!/usr/bin/perl -w
#
#   Copyright (C) 2004 muppet
#   Copyright (C) 2000 CodeFactory AB
#   Copyright (C) 2000 Jonas Borgstr\366m <jonas@codefactory.se>
#   Copyright (C) 2000 Anders Carlsson <andersca@codefactory.se>
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Library General Public
#   License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#   Library General Public License for more details.
#
#   You should have received a copy of the GNU Library General Public License
#   along with this library; see the file COPYING.LIB.  If not, see
#   <https://www.gnu.org/licenses/>.
#

use strict;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Gtk2::Html2;
use File::Spec;

#include <gtk/gtk.h>
#include <libxml/debugXML.h>
#include <string.h>

#include "gtkhtmlcontext.h"
#include "graphics/htmlpainter.h"
#include "layout/htmlbox.h"
#include "view/htmlview.h"

#include "dom/dom-types.h"

my $document; # HtmlDocument *document;
my $parser; # HtmlParser *parser;
my $view; # GtkWidget *view;

my @documents = (
	{ title => "alex test",        filename => "alex.html" },
	{ title => "andersca test",    filename => "andersca.html" },
	{ title => "jborg test",       filename => "jborg.html" },
	{ title => "floats test",      filename => "floats.html" },
	{ title => "table test",       filename => "tables.html" },
	{ title => "table stresstest", filename => "table.html" },
	{ title => "position test",    filename => "position.html" },
	{ title => "Large file",       filename => "gtkwidget.html" },
	{ title => "Status",           filename => undef },
	{ title => "Testcases",        filename => undef }
);

my @status_documents = (
	{ title => "HTML",   filename => "status/html.html" },
	{ title => "XML",    filename => "status/xml.html" },
	{ title => "DOM",    filename => "status/dom.html" },
	{ title => "CSS",    filename => "css-support.html" },
	{ title => "DBaron", filename => "dbaron-status.html" },
);

use constant TITLE_COLUMN => 0;
use constant FILENAME_COLUMN => 1;
use constant NUM_COLUMNS => 2;
use constant GTKHTML_SAMPLES_DIRECTORY => '/tmp';

sub add_status_docs {
	my ($model, $parent) = @_;

	foreach my $d (@status_documents) {
		my $iter = $model->append ($parent);
		$model->set ($iter,
			    TITLE_COLUMN, $d->{title},
			    FILENAME_COLUMN, $d->{filename});
	}
}

sub url_requested_timeout {
	my $context = shift; # Fetch Context

	my $path;

	if (File::Spec->path_is_absolute ($context->{url})) {
		$path = $context->{url};
	} else {
		$path = File::Spec->catfile (GTKHTML_SAMPLES_DIRECTORY,
		                             $context->{url});
	}

	if (-f $path) {
		my $i;
		my $buf;
		open IN, $path;
		
		while (($i = read IN, $buf, 4096) != 0) {
			print "i: %d\n", $i;
			#$context->{stream}->write ($buf, $i);
			$context->{stream}->write ($buf);
			
			Gtk2->main_iteration while Gtk2->events_pending;
		}

		warn ("time to close!\n");
		$context->{stream}->close;
		close IN;
	}
	else {
		warn ("eeek, wrong!\n");
		$context->{stream}->close;
	}

	return FALSE;
}

#static gboolean
#dom_mouse_down (HtmlDocument *doc, DomMouseEvent *event, gpointer data)
#{
#  //	g_print ("mouse down!\n");
#
#	return FALSE;
#}
#
#static gboolean
#dom_mouse_up (HtmlDocument *doc, DomMouseEvent *event, gpointer data)
#{
#  //	g_print ("mouse up!\n");
#
#	return FALSE;
#}
#
#static gboolean
#dom_mouse_click (HtmlDocument *doc, DomMouseEvent *event, gpointer data)
#{
#	g_print ("mouse click.!\n");
#
#	return FALSE;
#}
#
#static gboolean
#dom_mouse_over (HtmlDocument *doc, DomMouseEvent *event, gpointer data)
#{
#	g_print ("mouse over!\n");
#
#	return FALSE;
#}
#
#static gboolean
#dom_mouse_out (HtmlDocument *doc, DomMouseEvent *event, gpointer data)
#{
#	g_print ("mouse out!\n");
#
#	return FALSE;
#}

sub link_clicked {
	my ($doc, $url) = @_;
	print "link clicked: $url!\n";
}

sub url_requested {
	my ($doc, $url, $stream) = @_;

	my %context = (
		stream => $stream,
		url => $url,
	);

	print "URL IS REQUESTED!!!!!!!\n";
	print "context is: $url\n";
	
	Glib::Timeout->add (200, \&url_requested_timeout, \%context);
	
	return TRUE;
}

sub load_file {
	my $filename = shift;

#	return unless $filename;

#	my $path = File::Spec->catfile (GTKHTML_SAMPLES_DIRECTORY, $filename);
my $path = $filename;
#	timer = g_timer_new ();
		
#	memset (buffer, 0, sizeof (buffer));
	
	$view->set_document (undef);
	$document->clear;
	$view->set_document ($document);

	open FILE, $path or return;

	if ($document->open_stream ("text/html")) {
	  my $i;
	  my $buffer;
	  while (($i = read (FILE, $buffer, 10))) {
	    $document->write_stream ($buffer, $i);
	  }
	  
	  $document->close_stream;
	} else {
		warn "open_stream failed";
	}

#	elapsed_time = g_timer_elapsed (timer, NULL);

#	g_print ("Parsing time is %f secs\n", elapsed_time);
}

sub selection_cb {
	my ($selection, $model) = @_;

	my $iter = $selection->get_selected;
	return unless $iter;

	load_file ($model->get ($iter, FILENAME_COLUMN));
}


sub create_tree {
	my $model = Gtk2::TreeStore->new (qw(Glib::String Glib::String));
	my $tree_view = Gtk2::TreeView->new ($model);

	my $selection = $tree_view->get_selection;
	$selection->set_mode ('single');

	$selection->signal_connect (changed => \&selection_cb, $model);

	foreach my $d (@documents) {
		my $iter = $model->append (undef);

		$model->set ($iter,
			     TITLE_COLUMN, $d->{title},
			     FILENAME_COLUMN, $d->{filename});

		add_status_docs ($model, $iter)
			if $d->{title} eq 'Status';
	}

	my $cell = Gtk2::CellRendererText->new;
	my $column = Gtk2::TreeViewColumn->new_with_attributes
				("Tests", $cell, "text", TITLE_COLUMN);
	$tree_view->append_column ($column);

	return $tree_view;
}

sub cb_clear_doc {
	$view->set_document (undef);
  	$document->clear;
	$view->set_document ($document);
	return FALSE;
}

#static void
#debug_dump_boxes (HtmlBox *root, gint indent, gboolean has_node, xmlNode *n)
#{
#	HtmlBox *box;
#	gint i;
#
#	if (!root)
#		return;
#	
#	if (has_node) {
#		if (root->dom_node != NULL && root->dom_node->xmlnode != n)
#			return;
#	}
#	
#	box = root->children;
#	
#	
#	for (i = 0; i < indent; i++)
#		g_print (" ");
#
#	g_print ("Type: %s (%p, %p, %p) (%d %d %d %d)\n",
#		 G_OBJECT_TYPE_NAME (root), root, root->dom_node, HTML_BOX_GET_STYLE (root), root->x, root->y, root->width, root->height);
#
#	while (box) {
#	  debug_dump_boxes (box, indent + 1, has_node, n);
#	  box = box->next;
#	}
#}

sub cb_dump_boxes {
	my ($widget, $view) = @_;

#	debug_dump_boxes (HTML_VIEW (view)->root, 0, FALSE, NULL);  
}

sub request_object {
	my ($view, $widget) = @_;
	
	my $sel = Gtk2::ColorSelection->new;
	$sel->show;

	$widget->add ($sel);

	return TRUE;
}

{
	# Set properties
	Gtk2::Html2::Context->get()->set (debug_painting => FALSE);
	
	# Create the document
	$document = Gtk2::Html2::Document->new;
	#g_signal_connect (G_OBJECT (document), "dom_mouse_down",
	#		  G_CALLBACK (dom_mouse_down), NULL);
	#g_signal_connect (G_OBJECT (document), "dom_mouse_up",
	#		  G_CALLBACK (dom_mouse_up), NULL);
	#g_signal_connect (G_OBJECT (document), "dom_mouse_click",
	#		  G_CALLBACK (dom_mouse_click), NULL);
	#g_signal_connect (G_OBJECT (document), "dom_mouse_over",
	#		  G_CALLBACK (dom_mouse_over), NULL);
	#g_signal_connect (G_OBJECT (document), "dom_mouse_out",
	#		  G_CALLBACK (dom_mouse_out), NULL);

	$document->signal_connect (request_url => \&url_requested);
	$document->signal_connect (link_clicked => \&link_clicked);
	
	# And the view
	$view = Gtk2::Html2::View->new;

	$view->signal_connect (request_object => \&request_object);

	#	gtk_widget_set_double_buffered (GTK_WIDGET (view), FALSE);
	
	my $sw = Gtk2::ScrolledWindow->new ($view->get_hadjustment,
	                                    $view->get_vadjustment);
	$sw->add ($view);
	
	# Create the window
	my $window = Gtk2::Window->new;
	$window->set_default_size (600, 400);
	
	$window->signal_connect (delete_event => sub {Gtk2->main_quit; 0});

	my $hpaned = Gtk2::HPaned->new;

	my $tree_view = create_tree ();
	
	my $frame = Gtk2::Frame->new (undef);
	$frame->set_shadow_type ('in');
	$frame->add ($tree_view);
	$hpaned->add1 ($frame);

	$frame = Gtk2::Frame->new (undef);
	$frame->set_shadow_type ('in');
	$frame->add ($sw);
	$hpaned->add2 ($frame);

	my $vbox = Gtk2::VBox->new (FALSE, 0);
	$vbox->pack_start ($hpaned, TRUE, TRUE, 0);
	$window->add ($vbox);

	my $hbox = Gtk2::HBox->new (FALSE, 0);
	$vbox->pack_start ($hbox, FALSE, FALSE, 0);

	my $button = Gtk2::Button->new ("Dump tree");
	$button->signal_connect (clicked => \&cb_dump_boxes, $view);
	$hbox->pack_start ($button, FALSE, FALSE, 0);

	$button = Gtk2::Button->new ("Clear document");
	$button->signal_connect (clicked => \&cb_clear_doc, $view);
	$hbox->pack_start ($button, FALSE, FALSE, 0);

	$button = Gtk2::Button->new ("Choose file");
	$button->signal_connect (clicked => sub {
		load_file ("/usr/share/doc/aspell/dev-html/devel.html");
	});
	$hbox->pack_start ($button, FALSE, FALSE, 0);

	# FIXME: ugly ugly!
	$view->set_document ($document);
	$window->show_all;

	Gtk2->main;
}
