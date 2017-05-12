# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-History is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-History.  If not, see <http://www.gnu.org/licenses/>.


# popup menu for items
#    Goto
#    Copy to Selection


package Gtk2::Ex::History::Dialog;
use 5.008;
use strict;
use warnings;
use Gtk2;
use List::Util;
use POSIX ();

use Gtk2::Ex::History;
use Gtk2::Ex::Units;

use Locale::TextDomain ('Gtk2-Ex-History');
use Locale::Messages;
BEGIN {
  Locale::Messages::bind_textdomain_codeset ('Gtk2-Ex-History','UTF-8');
  Locale::Messages::bind_textdomain_filter ('Gtk2-Ex-History',
                                            \&Locale::Messages::turn_utf_8_on);
}

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 8;

use Glib::Object::Subclass
  'Gtk2::Dialog',
  properties => [ Glib::ParamSpec->object
                  ('history',
                   __('History object'),
                   'The history object to present and act on.',
                   'Gtk2::Ex::History',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  ### History-Dialog INIT_INSTANCE()

  $self->set_title (__x('{appname}: History',
                        appname => Glib::get_application_name()));
  $self->add_buttons ('gtk-close' => 'close');
  $self->signal_connect (response => \&_do_response);

  my $vbox = $self->vbox;

  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xalign => 0, ypad => 0);

  {
    my $hbox = Gtk2::HBox->new;
    $vbox->pack_start ($hbox, 0,0,0);

    $hbox->pack_start (Gtk2::Label->new (__('Current')),
                       0,0,0);

    my $treeview = $self->{'current_treeview'} = Gtk2::TreeView->new;
    $treeview->{'way'} = 'current';
    $treeview->enable_model_drag_dest
      (['move'], { target => 'GTK_TREE_MODEL_ROW',
                   flags  => ['same-app'] },
       { target => 'text/plain' });
    $treeview->signal_connect (row_activated => \&_do_row_activated);
    # must expand/fill to give a width, otherwise Gtk 2.20.1 gets errors
    # about width==-1 when model is empty
    $hbox->pack_start ($treeview, 1,1,
                       POSIX::ceil(Gtk2::Ex::Units::width($treeview,'2 em'))),

    my $column = Gtk2::TreeViewColumn->new_with_attributes ('', $renderer);
    $column->set_cell_data_func ($renderer, \&_do_cell_data);
    $treeview->append_column ($column);

    $hbox->show_all;
  }

  my $table = Gtk2::Table->new (1, 2);
  $vbox->pack_start ($table, 1,1,0);

  my $tpos = 0;
  my @scrolled_list;
  foreach my $way ('back', 'forward') {
    my $scrolled = Gtk2::ScrolledWindow->new;
    push @scrolled_list, $scrolled;
    $scrolled->set (hscrollbar_policy => 'automatic',
                    vscrollbar_policy => 'automatic');
    $table->attach ($scrolled, $tpos, $tpos+1, 0,1,
                    ['fill','shrink','expand'],
                    ['fill','shrink','expand'],
                    POSIX::ceil(Gtk2::Ex::Units::width($scrolled,'.2 em')),
                    0);
    $tpos++;

    my $treeview = $self->{"${way}_treeview"} = Gtk2::TreeView->new;
    $treeview->{'way'} = $way;
    $treeview->set (reorderable => 1);
    $treeview->enable_model_drag_dest
      (['move'], { target => 'GTK_TREE_MODEL_ROW',
                   flags  => ['same-app'] },
       { target => 'text/plain' });
    $treeview->signal_connect (row_activated => \&_do_row_activated);
    $scrolled->add ($treeview);

    my $name = ($way eq 'back' ? __('Back') : __('Forward'));
    my $column = Gtk2::TreeViewColumn->new_with_attributes ($name, $renderer);
    $column->set_cell_data_func ($renderer, \&_do_cell_data);
    $column->set (clickable => 1);
    $treeview->append_column ($column);
    $column->signal_connect (clicked => \&_do_column_clicked);
  }

  $vbox->show_all;

  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self,
       map {[$_, '20 em', '15 lines']} @scrolled_list);
  ### default size: $self->get_default_size
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### History-Dialog SET_PROPERTY(): $pname
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'history') {
    my $history = $newval;

    foreach my $way ('current', 'back', 'forward') {
      my $treeview = $self->{"${way}_treeview"};
      $treeview->set_model ($history && $history->model($way));
    }
    # workaround for 2.18 sizing bug
    $self->{'current_treeview'}->set_headers_visible (! $history);
  }
}

# 'response' signal handler
sub _do_response {
  my ($self, $response) = @_;
  ### HistoryDialog response: $response

  if ($response eq 'close') {
    # as per a keyboard close, defaults to raising 'delete-event', which in
    # turn defaults to a destroy
    $self->signal_emit ('close');
  }
}

# 'set_cell_data' handler on TreeViewColumn
sub _do_cell_data {
  my ($column, $renderer, $model, $iter) = @_;
  my $treeview = $column->get_tree_view || return;
  my $self = $treeview->get_ancestor(__PACKAGE__) || return;
  my $history = $self->{'history'} || return;
  my $str = $history->signal_emit ('place-to-text', $model->get($iter,0));
  my $field = ($history->get('use-markup') ? 'markup' : 'text');
  $renderer->set ($field => $str);
}

# 'clicked' signal on TreeViewColumn
sub _do_column_clicked {
  my ($column) = @_;
  my $treeview = $column->get_tree_view;
  my $self = $treeview->get_ancestor (__PACKAGE__);
  my $history = $self->{'history'} || return;  # perhaps not yet set
  my $way = $treeview->{'way'};
  $history->$way;
}

# 'row-activated' signal on a TreeView
sub _do_row_activated {
  my ($treeview, $path, $treeviewcolumn) = @_;
  my $self = $treeview->get_ancestor (__PACKAGE__);
  my $history = $self->{'history'} || return;  # in case gone somehow
  my ($n) = $path->get_indices;
  my $way = $treeview->{'way'};
  $history->$way ($n+1);
}

# Not sure about this yet, might prefer general Gtk2::Ex::ToplevelBits find
# and popup.
#
# =item C<< Gtk2::Ex::History::Dialog->popup ($history) >>
# 
# =item C<< Gtk2::Ex::History::Dialog->popup ($history, $parent) >>
# 
# Popup a C<History::Dialog> for the given C<Gtk2::Ex::History> object,
# possibly re-using an existing dialog if there's one showing it already.
# 
# Optional C<$parent> is a widget the popup originates from.  If a dialog
# already exists on the same screen as C<$parent> (or the default screen) then
# it's re-presented, otherwise a new dialog is created on the screen of
# C<$parent> (or the default screen).

sub popup {
  my ($class, $history, $parent) = @_;
  ### History-Dialog popup(): "$history"
  ### parent: $parent && "$parent"

  my $screen = ($parent ? $parent->get_screen : Gtk2::Gdk::Screen->get_default);
  my $dialog = (List::Util::first
                { $_->isa($class)
                    && $_->get_screen == $screen
                      && $_->get('history') == $history
                    } Gtk2::Window->list_toplevels)
    || do {
      ### new dialog
      $class->new (history => $history,
                   screen  => $screen);
    };
  ### dialog: "$dialog"
  ### screen: $dialog->get_screen
  ### children: $dialog->get_children

  $dialog->present;
  return $dialog;
}

# sub find {
#   my ($class, $history) = @_;
#   foreach my $widget (Gtk2::Window->list_toplevels) {
#     $widget->isa($class) || next;
#     my $this_history = $widget->get('history') || next;
#     if ($this_history == $history) {
#       return $widget;
#     }
#   }
#   return $class->new (history => $history);
# }

1;
__END__

=for stopwords popup Ryde Gtk2-Ex-History

=head1 NAME

Gtk2::Ex::History::Dialog -- dialog of history "back" and "forward" places

=for test_synopsis my ($history, $parent_widget)

=head1 SYNOPSIS

 use Gtk2::Ex::History::Dialog;
 Gtk2::Ex::History::Dialog->popup ($history, $parent_widget);

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::History::Dialog> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              Gtk2::Ex::History::Dialog

=head1 DESCRIPTION

A C<Gtk2::Ex::History::Dialog> displays the "current", "back" and "forward"
places of a C<Gtk2::Ex::History> object.

    +--------------------------------------------------+
    | Current: Thing now displayed                     |
    | +--------------------+    +--------------------+ |
    | | Back               |    | Forward            | |
    | +--------------------+    +--------------------+ |
    | | Thing last visited |    | Thing forward      | |
    | | The thing before   |    | Further forward    | |
    | | An old thing       |    |                    | |
    | +--------------------+    +--------------------+ |
    +--------------------------------------------------+
    |                                           Close  |
    +--------------------------------------------------+

Clicking on a back or forward item moves to make it current.  Clicking on
the Back and Forward headings moves by one in that direction.  Drag and drop
can rearrange items.  Dropping on the "current" moves to make that item
current, extracting it from the back or forward.

=head1 FUNCTIONS

=over 4

=item C<< $dialog = Gtk2::Ex::History::Dialog->new (key => value, ...) >>

Create and return a new history dialog.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.  The C<history> property
is what to display.

    my $dialog = Gtk2::Ex::History::Dialog->new
                 (history => $my_history);

=back

=head1 PROPERTIES

=over 4

=item C<history> (C<Gtk2::Ex::History> object, default C<undef>)

The history object to display and act on.

=back

=head1 SEE ALSO

L<Gtk2::Ex::History>,
L<Gtk2::Ex::History::Menu>,
L<Gtk2::Dialog>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-history/index.html>

=head1 LICENSE

Gtk2-Ex-History is Copyright 2010, 2011 Kevin Ryde

Gtk2-Ex-History is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-History is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-History.  If not, see L<http://www.gnu.org/licenses/>.

=cut
