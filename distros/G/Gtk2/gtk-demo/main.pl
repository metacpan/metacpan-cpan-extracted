#!/usr/bin/perl -w
#
# $Id$
#

our $PROGDIR = $0;
$PROGDIR =~ s/main.pl$//;

use strict;
use Carp;
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::Pango;
use Gtk2;


use vars qw/ @testgtk_demos /;

# lists of demo code descriptions.
# the func is a plain string in each of these, as a sentinel value to tell
# row_activated_cb that the file containing that function hasn't been 
# loaded yet.
my @child0 = (
  { title => "Editable Cells", filename => "editable_cells.pl", func => 'stub', },
  { title => "List Store",     filename => "list_store.pl",     func => 'stub', },
  { title => "Tree Store",     filename => "tree_store.pl",     func => 'stub', },
);

my @child1 = (
  { title => "Hypertext",       filename => "hypertext.pl",  func => 'stub', }, 
  { title => "Multiple Views",  filename => "textview.pl",   func => 'stub', }, 
);

@testgtk_demos = (
  { title => "Application main window",     filename => "appwindow.pl",     func => 'stub', }, 
  { title => "Assistant",                   filename => "assistant.pl",     func => 'stub', available => sub { Gtk2->CHECK_VERSION (2, 10, 0); } },
  { title => "Builder",                     filename => "builder.pl",       func => 'stub', available => sub { Gtk2->CHECK_VERSION (2, 12, 0); } },
  { title => "Button Boxes",                filename => "button_box.pl",    func => 'stub', }, 
  { title => "Change Display",              filename => "changedisplay.pl", func => 'stub', }, 
  { title => "Color Selector",              filename => "colorsel.pl",      func => 'stub', }, 
  { title => "Combo boxes",                 filename => "combobox.pl",      func => 'stub', available => sub { Gtk2->CHECK_VERSION (2, 4, 0); } }, 
  { title => "Dialog and Message Boxes",    filename => "dialog.pl",        func => 'stub', }, 
  { title => "Drawing Area",                filename => "drawingarea.pl",   func => 'stub', }, 
  { title => "Images",                      filename => "images.pl",        func => 'stub', }, 
  { title => "Item Factory",                filename => "item_factory.pl",  func => 'stub', }, 
  { title => "Menus",                       filename => "menus.pl",         func => 'stub', }, 
  { title => "Paned Widgets",               filename => "panes.pl",         func => 'stub', }, 
  { title => "Pixbufs",                     filename => "pixbufs.pl",       func => 'stub', }, 
  { title => "Size Groups",                 filename => "sizegroup.pl",     func => 'stub', }, 
  { title => "Stock Item and Icon Browser", filename => "stock_browser.pl", func => 'stub', }, 
  { title => "Text Widget", children => \@child1 },
  { title => "Tree View",   children => \@child0 },
);

push @testgtk_demos,
  { title => "Entry Completion", filename => "entry_completion.pl", func => 'stub', },
  { title => "UI Manager",       filename => "ui_manager.pl",       func => 'stub', }
	if Gtk2->CHECK_VERSION (2, 4, 0);

push @testgtk_demos,
  { title => "Rotated Text", filename => "rotated_text.pl", func => 'stub', },
	if Gtk2->CHECK_VERSION (2, 6, 0);

# some globals.
my $info_buffer;
my $source_buffer;

my $current_file;

# clean names for column numbers.
use constant TITLE_COLUMN    => 0;
use constant FILENAME_COLUMN => 1;
use constant FUNC_COLUMN     => 2;
use constant ITALIC_COLUMN   => 3;
use constant NUM_COLUMNS     => 4;


#/**
# * demo_find_file:
# * @base: base filename
# * @err:  location to store error, or %NULL.
# * 
# * Looks for @base first in the current directory, then in the
# * location GTK+ where it will be installed on make install,
# * returns the first file found.
# * 
# * Return value: the filename, if found or %NULL
# **/
sub demo_find_file {
	my $base = shift;

	return $base if -e $base;

	my $filename = $PROGDIR.$base;
	croak "Cannot find demo data file $base ($filename)\n"
		unless -e $filename;

	return $filename;
}

sub window_closed_cb {
	my ($window, $cbdata) = @_;

	my $iter = $cbdata->{model}->get_iter ($cbdata->{path});
	my ($italic) = $cbdata->{model}->get ($iter, ITALIC_COLUMN);
	$cbdata->{model}->set ($iter, ITALIC_COLUMN, !$italic)
		if $italic;
}


#
# Stupid syntax highlighting.
#
# No regex was used in the making of this highlighting.
# It should only work for simple cases.  This is good, as
# that's all we should have in the demos.
#
# This code should not be used elsewhere, except perhaps as an example of how
# to iterate through a text buffer.
#
use constant STATE_NORMAL => 0;
use constant STATE_IN_COMMENT => 1;

=out

static gchar *tokens[] =
{
  "/*",
  "\"",
  NULL
};

static gchar *types[] =
{
  "static",
  "const ",
  "void",
  "gint",
  "int ",
  "char ",
  "gchar ",
  "gfloat",
  "float",
  "gint8",
  "gint16",
  "gint32",
  "guint",
  "guint8",
  "guint16",
  "guint32",
  "guchar",
  "glong",
  "gboolean" ,
  "gshort",
  "gushort",
  "gulong",
  "gdouble",
  "gldouble",
  "gpointer",
  "NULL",
  "GList",
  "GSList",
  "FALSE",
  "TRUE",
  "FILE ",
  "GtkObject ",
  "GtkColorSelection ",
  "GtkWidget ",
  "GtkButton ",
  "GdkColor ",
  "GdkRectangle ",
  "GdkEventExpose ",
  "GdkGC ",
  "GdkPixbufLoader ",
  "GdkPixbuf ",
  "GError",
  "size_t",
  NULL
};

static gchar *control[] =
{
  " if ",
  " while ",
  " else",
  " do ",
  " for ",
  "?",
  ":",
  "return ",
  "goto ",
  NULL
};
void
parse_chars (gchar     *text,
	     gchar    **end_ptr,
	     gint      *state,
	     gchar    **tag,
	     gboolean   start)
{
  gint i;
  gchar *next_token;

  /* Handle comments first */
  if (*state == STATE_IN_COMMENT)
    {
      *end_ptr = strstr (text, "*/");
      if (*end_ptr)
	{
	  *end_ptr += 2;
	  *state = STATE_NORMAL;
	  *tag = "comment";
	}
      return;
    }

  *tag = NULL;
  *end_ptr = NULL;

  /* check for comment */
  if (!strncmp (text, "/*", 2))
    {
      *end_ptr = strstr (text, "*/");
      if (*end_ptr)
	*end_ptr += 2;
      else
	*state = STATE_IN_COMMENT;
      *tag = "comment";
      return;
    }

  /* check for preprocessor defines */
  if (*text == '#' && start)
    {
      *end_ptr = NULL;
      *tag = "preprocessor";
      return;
    }

  /* functions */
  if (start && * text != '\t' && *text != ' ' && *text != '{' && *text != '}')
    {
      if (strstr (text, "("))
	{
	  *end_ptr = strstr (text, "(");
	  *tag = "function";
	  return;
	}
    }
  /* check for types */
  for (i = 0; types[i] != NULL; i++)
    if (!strncmp (text, types[i], strlen (types[i])))
      {
	*end_ptr = text + strlen (types[i]);
	*tag = "type";
	return;
      }

  /* check for control */
  for (i = 0; control[i] != NULL; i++)
    if (!strncmp (text, control[i], strlen (control[i])))
      {
	*end_ptr = text + strlen (control[i]);
	*tag = "control";
	return;
      }

  /* check for string */
  if (text[0] == '"')
    {
      gint maybe_escape = FALSE;

      *end_ptr = text + 1;
      *tag = "string";
      while (**end_ptr != '\000')
	{
	  if (**end_ptr == '\"' && !maybe_escape)
	    {
	      *end_ptr += 1;
	      return;
	    }
	  if (**end_ptr == '\\')
	    maybe_escape = TRUE;
	  else
	    maybe_escape = FALSE;
	  *end_ptr += 1;
	}
      return;
    }

  /* not at the start of a tag.  Find the next one. */
  for (i = 0; tokens[i] != NULL; i++)
    {
      next_token = strstr (text, tokens[i]);
      if (next_token)
	{
	  if (*end_ptr)
	    *end_ptr = (*end_ptr<next_token)?*end_ptr:next_token;
	  else
	    *end_ptr = next_token;
	}
    }

  for (i = 0; types[i] != NULL; i++)
    {
      next_token = strstr (text, types[i]);
      if (next_token)
	{
	  if (*end_ptr)
	    *end_ptr = (*end_ptr<next_token)?*end_ptr:next_token;
	  else
	    *end_ptr = next_token;
	}
    }

  for (i = 0; control[i] != NULL; i++)
    {
      next_token = strstr (text, control[i]);
      if (next_token)
	{
	  if (*end_ptr)
	    *end_ptr = (*end_ptr<next_token)?*end_ptr:next_token;
	  else
	    *end_ptr = next_token;
	}
    }
}

=cut

#
# While not as cool as c-mode, this will do as a quick attempt at highlighting 
#
sub fontify {
  my $text;
  my ($end_ptr, $tag);

  my $state = STATE_NORMAL;

  my $start_iter = $source_buffer->get_iter_at_offset (0);

##  my $next_iter = $start_iter->copy;
  my $next_iter = $start_iter;
  while ($next_iter = $next_iter->forward_line) {
      my $start = TRUE;
      my $start_ptr = $text = $start_iter->get_text ($next_iter);

      do {
	  ($end_ptr, $tag) = parse_chars ($start_ptr, $state, $start);
	  my $tmp_iter;

	  $start = FALSE;
	  if ($end_ptr) {
##	      $tmp_iter = $start_iter->copy;
	      $tmp_iter = $start_iter;
	      $tmp_iter->forward_chars ($end_ptr - $start_ptr);
	  } else {
##	      $tmp_iter = $next_iter->copy;
	      $tmp_iter = $next_iter;
	  }
	  if ($tag) {
	    $source_buffer->apply_tag_by_name ($tag, $start_iter, $tmp_iter);
	  }

	  $start_iter = $tmp_iter;
	  $start_ptr = $end_ptr;
      } while ($end_ptr);

##      $start_iter = $next_iter->copy;
      $start_iter = $next_iter;
    }
}


sub load_file {
  my $filename = shift;
  my $state = 0;
  my $in_para = 0;

  return if defined $current_file and $current_file eq $filename;

  $current_file = $filename;

  $info_buffer->delete ($info_buffer->get_bounds);

  $source_buffer->delete ($source_buffer->get_bounds);

  my $full_filename;
  eval { $full_filename = demo_find_file ($filename); };
  if ($@) { warn $@; }

  local *IN;
  open IN, $full_filename
      or warn("cannot open $full_filename: $!\n"), return;

  my $start = $info_buffer->get_iter_at_offset (0);
  while (<IN>) {
       if ($state == 0) {
         # Reading title
	 if (/^#!/) {
              # skip the interpreter line...
	 } elsif (/^\s*#?\s*$/) {
              # skip blank lines preceding the title
	 } else {
              # this must be the title!
	      s/^#\s*//;
	      s/\s*$//;

##              my $end = $start->copy;
              my $end = $start;
              $info_buffer->insert ($end, $_);
##              $start = $end;
###print "$start $end\n";

#	      gtk_text_iter_backward_chars (&start, len_chars);
$start = $info_buffer->get_iter_at_offset (0);
              $info_buffer->apply_tag_by_name ("title", $start, $end);
#
	      $start = $end;

	      $state++;
	 }

       } elsif ($state == 1) {
          # Reading body of info section
          if (/^\s*$/) {
              # completely blank line ends the info section.
              $state++;
          } else {
              # strip leading junk
              s/^#?\s+//;

              # strip trailing junk
              s/\s+$//;

	      if (length($_) > 0) {
		  $info_buffer->insert ($start, " ")
			if $in_para;

		  $info_buffer->insert ($start, $_);
		  $in_para = 1;
	      } else {
		  $info_buffer->insert ($start, "\n");
		  $in_para = 0;
              }
	  }

       } elsif ($state == 2) {
          # Skipping blank lines
	  s/^\s+//;
	  if (length ($_)) {
	    $state++;
	    $start = $source_buffer->get_iter_at_offset (0);
            $source_buffer->insert ($start, $_);
          }
       } elsif ($state == 3) {
          # Reading program body
          $source_buffer->insert ($start, $_);
       }
   }

#  fontify ();
}

sub row_activated_cb {
   my ($tree_view, $path, $column) = @_;

   my $model = $tree_view->get_model;

   my $iter = $model->get_iter ($path);
   my ($filename, $func, $italic) = $model->get ($iter, 
                                                 FILENAME_COLUMN, 
                                                 FUNC_COLUMN,
                                                 ITALIC_COLUMN);

   # this is rather a bit of a departure from the C version.
   # in the C version, the various demos are in separate modules that 
   # get compiled into the program.  perl doesn't work that way.  so, we 
   # have the code in external files that define a package with the same
   # name as the file (sans the .pl).  if the demo has never been run,
   # the func column will contain a string; when we see that, we'll
   # require the file, set the func column to point to the "do" method
   # within that file's declared package, and then retrieve that function
   # pointer again.  it's a kind of hackish lazy loading mechanism.
   # don't try this at home.
   if ('CODE' ne ref $func) {
       my $pkg = $filename;
       $filename = demo_find_file($filename);
       require $filename;
       $pkg =~ s/\.pl$//;
       eval '$model->set ($iter, FUNC_COLUMN, \&'.$pkg.'::do);';
       ($func) = $model->get ($iter, FUNC_COLUMN);
   }

   if ($func) {
       # set this row italic to show that the demo is running...
       $model->set ($iter, ITALIC_COLUMN, !$italic);
       my $window = $func->($tree_view->get_toplevel);
       if ($window) {
          # unset the italics when the window closes.
	  $window->signal_connect (destroy => \&window_closed_cb, 
	                           { model => $model, path => $path->copy });
       }
   }
}

sub selection_cb {
  my ($selection, $model) = @_;

  my $iter = $selection->get_selected;
  return unless defined $iter;

  my ($name) = $model->get ($iter, FILENAME_COLUMN);

  load_file ($name) if $name;
}

sub create_text {
  my ($buffer_ref, $is_source) = @_;

  my $scrolled_window = Gtk2::ScrolledWindow->new;
  $scrolled_window->set_policy ('automatic', 'automatic');
  $scrolled_window->set_shadow_type ('in');

  my $text_view = Gtk2::TextView->new;

  $$buffer_ref = Gtk2::TextBuffer->new (undef);
  $text_view->set_buffer ($$buffer_ref);
  $text_view->set_editable (FALSE);
  $text_view->set_cursor_visible (FALSE);

  $scrolled_window->add ($text_view);

  if ($is_source) {
       my $font_desc = Gtk2::Pango::FontDescription->from_string ("Courier 12");
       $text_view->modify_font ($font_desc);

       $text_view->set_wrap_mode ('none');
  } else {
       # Make it a bit nicer for text.
       $text_view->set_wrap_mode ('word');
       $text_view->set_pixels_above_lines (2);
       $text_view->set_pixels_below_lines (2);
  }
  
  return $scrolled_window;
}

sub create_tree {

   my $model = Gtk2::TreeStore->new ('Glib::String', 'Glib::String', 'Glib::Scalar', 'Glib::Boolean');
   my $tree_view = Gtk2::TreeView->new;
   $tree_view->set_model ($model);
   my $selection = $tree_view->get_selection;

   $selection->set_mode ('browse');
   $tree_view->set_size_request (200, -1);

   #
   # this code only supports 1 level of children. If we
   # want more we probably have to use a recursing function.
   #
   foreach my $d (@testgtk_demos) {
      next if ($d->{available} && !$d->{available}->());
      my $iter = $model->append (undef);

      $model->set ($iter,
                   TITLE_COLUMN,    $d->{title},
                   FILENAME_COLUMN, $d->{filename} || '',
                   FUNC_COLUMN,     $d->{func}     || '',
                   ITALIC_COLUMN,   FALSE);

      next unless $d->{children};

      foreach my $child (@{ $d->{children} }) {
         my $child_iter = $model->append ($iter);

         $model->set ($child_iter,
                      TITLE_COLUMN,    $child->{title},
                      FILENAME_COLUMN, $child->{filename},
                      FUNC_COLUMN,     $child->{func},
                      ITALIC_COLUMN,   FALSE);
      }
   }

   my $cell = Gtk2::CellRendererText->new;

  $cell->set ('style' => 'italic');
  
  my $column = Gtk2::TreeViewColumn->new_with_attributes
 					("Widget (double click for demo)",
                                        $cell,
                                        'text' => TITLE_COLUMN,
                                        'style_set' => ITALIC_COLUMN);

  $tree_view->append_column ($column);

  $selection->signal_connect (changed => \&selection_cb, $model);
  $tree_view->signal_connect (row_activated => \&row_activated_cb, $model);

  $tree_view->expand_all;
  return $tree_view;
}

sub setup_default_icon {
  my $pixbuf;
  eval { $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file 
      				(demo_find_file ("gtk-logo-rgb.gif")); };
  if ($@) {
     my $dialog = Gtk2::MessageDialog->new (undef, [], 'error', 'close',
                                            "Failed to read icon file: $@");
     $dialog->signal_connect (response => sub { $_[0]->destroy; 1 });
  }

  if ($pixbuf) {
    # The gtk-logo-rgb icon has a white background, make it transparent 
    my $transparent = $pixbuf->add_alpha (TRUE, 0xff, 0xff, 0xff);

    # only one item on the parameter list, but the parameter list is a list
    Gtk2::Window->set_default_icon_list ($transparent);
  }
}

Gtk2->init;

setup_default_icon ();
  
my $window = Gtk2::Window->new;
$window->set_title ("Gtk2-Perl Code Demos");
$window->signal_connect (destroy => sub { Gtk2->main_quit; 1 });

my $hbox = Gtk2::HBox->new (FALSE, 0);
$window->add ($hbox);

my $tree = create_tree ();
$hbox->pack_start ($tree, FALSE, FALSE, 0);

my $notebook = Gtk2::Notebook->new;
$hbox->pack_start ($notebook, TRUE, TRUE, 0);

$notebook->append_page (create_text (\$info_buffer, FALSE),
			Gtk2::Label->new_with_mnemonic ("_Info"));

$notebook->append_page (create_text (\$source_buffer, TRUE),
			Gtk2::Label->new_with_mnemonic ("_Source"));

  my $tag;
   $tag = $info_buffer->create_tag ("title", font => "Sans 18");

   $tag = $source_buffer->create_tag ("comment", foreground => "red");
   $tag = $source_buffer->create_tag ("type", foreground => "ForestGreen");
   $tag = $source_buffer->create_tag ("string", 
                                      foreground => "RosyBrown",
                                      weight => PANGO_WEIGHT_BOLD);
   $tag = $source_buffer->create_tag ("control", "foreground", "purple");
   $tag = $source_buffer->create_tag ('preprocessor', 
                                      style => 'oblique',
                                      foreground => 'burlywood4');
   $tag = $source_buffer->create_tag ('function',
                                      weight => PANGO_WEIGHT_BOLD, 
                                      foreground => 'DarkGoldenrod4');

   $window->set_default_size (600, 400);
   $window->show_all;

# this happens anyway, when the list selects the first item on show
#  load_file ($testgtk_demos[0]{filename});
 
  Gtk2->main;
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
with this library; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
