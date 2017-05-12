#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.

package main;
use strict;
use warnings;
use Carp;
use Gtk2 '-init';
use Gtk2::Ex::DateSpinner::CellRenderer;

use FindBin;
my $progname = $FindBin::Script;

use constant DEBUG => 0;

Glib->install_exception_handler (\&exception_handler);
sub exception_handler {
  my ($msg) = @_;
  print "Error: ", $msg;

  if (eval { require Devel::StackTrace; }) {
    my $trace = Devel::StackTrace->new;
    print $trace->as_string;
  }
  return 1; # stay installed
}

if (0) {
  my $entry = Gtk2::Entry->new;
  $entry->signal_connect (destroy => sub { print "destroy\n"; });
  exit 0;
}

my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('2008-01-01',
                 '2007-06-06',
                 '2007-06-06',
                 '2007-06-06',
                 '2007-06-06',
                 '2007-06-06',
                 '2007-06-06',
                 '2007-06-06',
                 '2007-06-06',
                ) {
  $liststore->set_value ($liststore->append, 0 => $str);
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $scrolled = Gtk2::ScrolledWindow->new;
$toplevel->add ($scrolled);

my $treeview = Gtk2::TreeView->new;
$treeview->set (model => $liststore,
                reorderable => 1);
$scrolled->add ($treeview);

my $column = Gtk2::TreeViewColumn->new;
$treeview->append_column ($column);

{
  my $cellrenderer = Gtk2::Ex::DateSpinner::CellRenderer->new
    (editable => 1);
  $column->pack_start ($cellrenderer, 0);
  $column->add_attribute ($cellrenderer, text => 0);
  renderer_edited_set_value ($cellrenderer, $column, 0);
  $cellrenderer->signal_connect
    (editing_started => sub {
       print "$progname: renderer editing_started\n";
     });
  $cellrenderer->signal_connect
    (editing_canceled => sub {
       print "$progname: renderer editing_canceled\n";
     });
  $cellrenderer->signal_connect
    (edited => sub {
       print "$progname: renderer edited\n";
     });
}
{
  my $cellrenderer = Gtk2::CellRendererText->new;
  $cellrenderer->set(editable => 1);
  $column->pack_start ($cellrenderer, 0);
  $column->add_attribute ($cellrenderer, text => 0);
  renderer_edited_set_value ($cellrenderer, $column, 0);
}
{
  my $cellrenderer = Gtk2::Ex::DateSpinner::CellRenderer->new
    (editable => 1,
     xalign => 0.8);
  $column->pack_start ($cellrenderer, 0);
  $column->add_attribute ($cellrenderer, text => 0);
  renderer_edited_set_value ($cellrenderer, $column, 0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;


sub renderer_edited_set_value {
  my ($renderer, $dest, $col_num) = @_;
  (defined $col_num) || croak 'No column number supplied';
  my @userdata = ($dest, $col_num);
  require Scalar::Util;
  Scalar::Util::weaken ($userdata[0]);
  $renderer->signal_connect (edited => \&_renderer_edited_set_value_handler,
                             \@userdata);
}
sub _renderer_edited_set_value_handler {
  my ($renderer, $pathstr, $newtext, $userdata) = @_;
  my ($dest, $col_num) = @$userdata;

  if ($dest->can('get_tree_view')) {
    # on Gtk2::TreeViewColumn go to the Gtk2::TreeView
    $dest = $dest->get_tree_view || croak 'No viewer from get_tree_view';
  }
  if ($dest->can('get_model')) {
    # on Gtk2::TreeView, or Gtk2::CellView, etc, go to the Gtk2::TreeModel
    $dest = $dest->get_model || croak 'No model from get_model';
  }
  my $path = Gtk2::TreePath->new_from_string ($pathstr);
  my $iter = $dest->get_iter ($path) || croak "Path $pathstr not found in model";
  if (DEBUG) { print "edited_treecolumn_set_value(): set_value path=$pathstr col=$col_num\n"; }
  $dest->set_value ($iter, $col_num, $newtext);
}


__END__

#   if (DEBUG) {
#     require Devel::FindBlessedRefs;
#     my %selves;
#     my %entries;
#     Devel::FindBlessedRefs::find_refs_by_coderef
#         (sub {
#            my $obj = shift;
#            my $class = Scalar::Util::blessed($obj) || return;
#            if ($class eq 'Gtk2::Entry') {
#              $entries{$obj+0} = $obj;
#            } elsif ($class eq __PACKAGE__) {
#              $selves{$obj+0} = $obj;
#            }
#          });
# 
#     local $,= ' ';
#     print "  entries ",values %entries,"\n";
#     print "  selves ",values %selves,"\n";
# 
# #     require Devel::FindRef;
# #     print Devel::FindRef::track(values %selves);
#   }




  #   require Gtk2::Ex::KeySnooper;
  #   $self->{'snooper'} = Gtk2::Ex::KeySnooper->new
  #     (\&_do_key_snooper, $ref_weak_self);

  $accelgroup->connect (Gtk2::Gdk->keyval_from_name('Escape'), [], [],
                        sub {
                          my ($accelgroup, $widget, $keyval, $modifiers) = @_;
                          if (DEBUG) { print "accel tab\n"; }
                          my $self = $widget->get_toplevel;
                          print "  focus ",$self->child_focus('tab-forward'),"\n";
                          print "  to ",$self->get_focus,"\n";
                          return 1;
                        });


sub _do_key_snooper {
  my ($widget, $event, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "_do_snooper $widget ",
                 Gtk2::Gdk->keyval_name($event->keyval), "\n";}

  if (($widget == $self || $widget->is_ancestor($self))
      && $event->type eq 'key-press') {
    if ($event->keyval == Gtk2::Gdk->keyval_from_name ('Return')) {
      _do_activate ($widget, $ref_weak_self);
      return 1;  # Gtk2::EVENT_STOP
    }
    if ($event->keyval == Gtk2::Gdk->keyval_from_name ('Escape')) {
      _do_cancel ($widget, $ref_weak_self);
      return 1;  # Gtk2::EVENT_STOP
    }

  }
  if (my $entry = $self->{'entry'}) {
    if ($widget == $entry
        && $event->keyval == Gtk2::Gdk->keyval_from_name ('Escape')) {
      $entry->{'editing_cancelled'} = 1;
    }
  }
  return 0;  # Gtk2::EVENT_PROPAGATE
}

