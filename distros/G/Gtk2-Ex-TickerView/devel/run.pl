#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2::Ex::TickerView;

use Gtk2 '-init';
use Glib::Ex::ConnectProperties;

use FindBin;
my $progname = $FindBin::Script;

print "$progname: ",
  Gtk2::Ex::TickerView->isa('Gtk2::Buildable')?'yes':'not'," buildable\n";

sub exception_handler {
  my ($msg) = @_;
  print "$progname: ", $msg;
  if (eval { require Devel::StackTrace; 1 }) {
    my $trace = Devel::StackTrace->new;
    print $trace->as_string;
  }
  return 1; # stay installed
}
Glib->install_exception_handler (\&exception_handler);


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (500, -1);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $hbox = Gtk2::HBox->new (0, 0);
$toplevel->add ($hbox);

my $left_vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($left_vbox, 0,0,0);

my $right_vbox = Gtk2::VBox->new (0, 0);
$hbox->pack_start ($right_vbox, 1,1,0);


my $model = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('yy', 'zz-bb', '<b>xx</b>', 'fjdks', '32492', "abc\ndef") {
  my $iter = $model->append;
  $model->set_value ($iter, 0, $str);
}

Gtk2::Rc->parse_string (<<'HERE');
style "my_style" {
  fg[ACTIVE]   = { 1.0, 1.0, 1.0 }
  text[ACTIVE] = { 1.0, 1.0, 1.0 }
  bg[ACTIVE]   = { 0, 0, 0 }
  base[ACTIVE] = { 0, 0, 0 }
}
widget "*.Gtk2__Ex__TickerView" style "my_style"
HERE

my $ticker = Gtk2::Ex::TickerView->new (model => $model,
                                        frame_rate => 2,
                                        speed => 20,
                                        run => 0,
                                        # orientation => 'vertical',
                                       );
print "$progname: ticker name=", $ticker->get_name || 'undef',
  " initial flags: ", $ticker->flags,
  " orientation '",$ticker->get('orientation'),"'\n";
{ my $color = $ticker->get_style->fg('normal');
  print "$progname: ticker fg[NORMAL]: ", $color->to_string, "\n";
}
{ my $color = $ticker->get_style->fg('active');
  print "$progname: ticker fg[ACTIVE]: ", $color->to_string, "\n";
}

my $renderer = Gtk2::CellRendererText->new;
# $renderer->set (width=>0);
$ticker->pack_start ($renderer, 1);
$ticker->set_attributes ($renderer, text => 0);
$ticker->set_cell_data_func
  ($renderer, sub {
     my ($ticker, $renderer, $model, $iter) = @_;
     $renderer->set (foreground_gdk => $ticker->get_style->fg($ticker->state),
                     foreground_set => 1);
   });

if (1) {
  my $renderer = Gtk2::CellRendererText->new;
  $ticker->pack_start ($renderer, 1);
  $ticker->set_attributes ($renderer, markup => 0);
}
if (0) {
  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (text => 'VIS');
  $ticker->pack_start ($renderer, 1);
  $ticker->set_cell_data_func
    ($renderer, sub {
       my ($ticker, $renderer, $model, $iter) = @_;
       my $len = length ($model->get ($iter, 0));
       $renderer->set('visible', $len != 5);
     });
}

$ticker->signal_connect
  (notify => sub {
     my ($ticker, $pspec) = @_;
     my $pname = $pspec->get_name;
     my $newval = $ticker->get($pname);
     $newval = (defined $newval ? "'$newval'" : 'undef');
     print "$progname: ticker notify '$pname' now $newval\n";
   });
$ticker->signal_connect
  (destroy => sub {
     print "$progname: ticker destroy signal\n";
   });
$ticker->signal_connect
  (button_press_event => sub {
     print "$progname: ticker button press\n";
     my ($self, $event) = @_;
     if ($event->button == 3) {
       my $x = $event->x;
       my $y = $event->y;
       my @ret = $ticker->get_path_at_pos ($x, $y);
       require Data::Dumper;
       print "  get_path_at_pos($x,$y) ",
         Data::Dumper::Dumper(\@ret);
       if (my $path = $ret[0]) {
         print "  path '",$path->to_string,"'",
           " elem ",$model->get_value($model->get_iter($path),0),"\n";
       }
     }
     return 0; # Gtk2::EVENT_PROPAGATE
   });
$right_vbox->pack_start ($ticker, 0,0,0);

if (0) {
  my $menu = $ticker->menu;
  $menu->signal_connect (destroy => sub {
                           print "$progname: menu destroy signal\n";
                         });
  require Gtk2::Ex::CheckMenuItem::Property;
  my $item = Gtk2::Ex::CheckMenuItem::Property->new_with_label ('Foo');
  $item->show;
  $menu->append ($item);
}

{ my $button = Gtk2::CheckButton->new_with_label ('Run');
  $left_vbox->pack_start ($button, 0, 0, 0);
  Glib::Ex::ConnectProperties->new ([$ticker,'run'],
                                    [$button,'active']);
}
{ my $button = Gtk2::CheckButton->new_with_label ('Show');
  $left_vbox->pack_start ($button, 0, 0, 0);
  Glib::Ex::ConnectProperties->new ([$ticker,'visible'],
                                    [$button,'active']);
}
{ my $button = Gtk2::CheckButton->new_with_label ('Sensitive');
  $left_vbox->pack_start ($button, 0, 0, 0);
  Glib::Ex::ConnectProperties->new ([$ticker,'sensitive'],
                                    [$button,'active']);
}
{ my $button = Gtk2::CheckButton->new_with_label ('Fixed Height');
  $left_vbox->pack_start ($button, 0, 0, 0);
  Glib::Ex::ConnectProperties->new ([$ticker,'fixed-height-mode'],
                                    [$button,'active']);
}
{ my $button = Gtk2::CheckButton->new_with_label ('Forced Height');
  $button->signal_connect (toggled => sub {
                             $ticker->set (height_request
                                           => $button->get_active
                                           ? 50 : -1);
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{ my $button = Gtk2::CheckButton->new_with_label ('Model');
  $button->set_active ($ticker->get('model'));
  $button->signal_connect (toggled => sub {
                             $ticker->set (model => ($button->get_active
                                                     ? $model : undef));
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{ my $button = Gtk2::CheckButton->new_with_label ('pointer-motion-hint');
  $button->signal_connect (toggled => sub {
                             my $window = $ticker->window;
                             my $events = $window->get_events;
                             if ($button->get_active) {
                               $events = $events + 'pointer-motion-hint-mask';
                             } else {
                               $events = $events - 'pointer-motion-hint-mask';
                             }
                             $window->set_events ($events);
                             print "$progname: events $events\n";
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);

  # As of Gtk 2.12.10 _gtk_tooltip_handle_event() very rudely does a
  # gdk_event_request_motions() even when there's no 'has-tooltip' or
  # anything tooltip set for the relevant widget.  (The call to
  # _gtk_tooltip_handle_event() is hard-coded in gtk_main_do_event().)
  #
  # request_motions() can be avoided by sticking the tooltip into "keyboard
  # mode" with a show-help call.  This makes it possible to see if the
  # is_hint handling in the ticker is doing the right thing, as opposed to
  # the tooltip always doing the server request.
  #
  print "$progname:show-help tooltip ",
    $ticker->signal_emit ('show-help', 'tooltip'), "\n";
}
{
  my $button = Gtk2::Button->new_with_label ('Redraw');
  $button->signal_connect (clicked => sub { $ticker->queue_draw; });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{ my $orient_hbox = Gtk2::HBox->new;
  $left_vbox->pack_start ($orient_hbox, 0,0,0);

  $orient_hbox->pack_start (Gtk2::Label->new('Orient'), 0,0,0);

  my $orient_combo = My::EnumComboBox->new (enum_type => 'Gtk2::Orientation');
  $orient_hbox->pack_start ($orient_combo, 1,1,0);
  Glib::Ex::ConnectProperties->new ([$ticker,'orientation'],
                                    [$orient_combo,'value']);
}
{ my $dir_hbox = Gtk2::HBox->new;
  $left_vbox->pack_start ($dir_hbox, 0,0,0);

  $dir_hbox->pack_start (Gtk2::Label->new('Direction'), 0,0,0);

  my $dir_combo = My::EnumComboBox->new (enum_type => 'Gtk2::TextDirection',
                                         value => $ticker->get_direction);
  $dir_hbox->pack_start ($dir_combo, 1,1,0);
  $dir_combo->signal_connect (changed => sub {
                                my $dir = $dir_combo->get('value');
                                print "$progname: set_direction $dir\n";
                                $ticker->set_direction ($dir);
                              });
  $ticker->signal_connect
    (direction_changed => sub {
       my $dir = $ticker->get_direction;
       print "$progname: ticker direction changed to $dir\n";
       $dir_combo->set (value => $dir);
     });
}
{
  my $state_hbox = Gtk2::HBox->new;
  $left_vbox->pack_start ($state_hbox, 0,0,0);

  $state_hbox->pack_start (Gtk2::Label->new('State'), 0,0,0);

  my $state_combo = My::EnumComboBox->new (enum_type => 'Gtk2::StateType',
                                           value => $ticker->state);
  $state_hbox->pack_start ($state_combo, 1,1,0);
  $state_combo->signal_connect (changed => sub {
                                  my $state = $state_combo->get('value');
                                  print "$progname: set state $state\n";
                                  $ticker->set_state ($state);
                                });
  $ticker->signal_connect
    (state_changed => sub {
       my $state = $ticker->state;
       print "$progname: ticker state changed to $state\n";
       $state_combo->set (value => $state);
     });
}
{
  my $button = Gtk2::Button->new_with_label ('Goto Start');
  $button->signal_connect (clicked => sub { $ticker->scroll_to_start; });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Scroll');
  $button->signal_connect (clicked => sub { $ticker->scroll_pixels (10); });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Scroll Back');
  $button->signal_connect (clicked => sub { $ticker->scroll_pixels (-10); });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Unparent');
  $button->signal_connect (clicked => sub { $right_vbox->remove ($ticker); });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Destroy');
  $button->signal_connect (clicked => sub { $ticker->destroy; });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::CheckButton->new_with_label ('DebugUps');
  $button->set_tooltip_markup ("Set Gtk2::Gdk::Window->set_debug_updates to flash invalidated regions");
  $button->set_active (0);
  $button->signal_connect (toggled => sub {
                             Gtk2::Gdk::Window->set_debug_updates
                                 ($button->get_active);
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Reorder Reverse');
  $button->signal_connect (clicked => sub {
                             my $rows = $model->iter_n_children (undef);
                             $model->reorder (reverse 0 .. $rows-1);
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Change First');
  $button->signal_connect (clicked => sub {
                             my $iter = $model->get_iter_first;
                             my $value = $model->get_value ($iter, 0);
                             $value .= 'Z';
                             $model->set ($iter, 0 => $value);
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Delete First');
  $button->signal_connect (clicked => sub {
                             $model->remove ($model->get_iter_first);
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Delete Last');
  $button->signal_connect (clicked => sub {
                             my $rows = $model->iter_n_children (undef);
                             $model->remove ($model->get_iter_from_string
                                             ($rows-1));
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
my $insert_count = 1;
{
  my $button = Gtk2::Button->new_with_label ('Insert First');
  $button->signal_connect (clicked => sub {
                             $model->insert_with_values (0, 0,
                                                         "x$insert_count");
                             $insert_count++;
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Insert Last');
  $button->signal_connect (clicked => sub {
                             my $rows = $model->iter_n_children (undef);
                             $model->insert_with_values ($rows, 0,
                                                         "x$insert_count\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\nx\n");
                             $insert_count++;
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Renderer Add');
  $button->signal_connect (clicked => sub {
                             $renderer = Gtk2::CellRendererText->new;
                             $renderer->set (text => 'Foo');
                             $ticker->pack_start ($renderer, 0);
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Renderers Clear');
  $button->signal_connect (clicked => sub {
                             print "$progname: ticker renderers clear\n";
                             $ticker->clear;
                           });
  $left_vbox->pack_start ($button, 0, 0, 0);
}
{
  my $pspec = $ticker->find_property ('frame-rate');
  my $adj = Gtk2::Adjustment->new (0,
                                   $pspec->get_minimum,
                                   $pspec->get_maximum,
                                   1, 10, 0);
  my $hbox = Gtk2::HBox->new;
  $left_vbox->pack_start ($hbox, 0,0,0);
  $hbox->pack_start (Gtk2::Label->new('frame-rate'), 0,0,0);
  my $spin = Gtk2::SpinButton->new ($adj, 1.0, 0);
  $hbox->pack_start ($spin, 1,1,0);
  Glib::Ex::ConnectProperties->new ([$ticker,'frame-rate'],
                                    [$spin,'value']);
}
{
  my $pspec = $ticker->find_property ('speed');
  my $adj = Gtk2::Adjustment->new (0,
                                   $pspec->get_minimum,
                                   $pspec->get_maximum,
                                   1, 10, 0);
  my $hbox = Gtk2::HBox->new;
  $left_vbox->pack_start ($hbox, 0,0,0);
  $hbox->pack_start (Gtk2::Label->new('speed'), 0,0,0);
  my $spin = Gtk2::SpinButton->new ($adj, 1, 0);
  $hbox->pack_start ($spin, 1,1,0);
  Glib::Ex::ConnectProperties->new ([$ticker,'speed'],
                                    [$spin,'value']);
}
{
  my $button = Gtk2::Button->new_with_label ('Quit');
  $button->signal_connect (clicked => sub { $toplevel->destroy; });
  $left_vbox->pack_start ($button, 0, 0, 0);
}



{
  my $treeview = Gtk2::TreeView->new_with_model ($model);
  $treeview->set (reorderable => 1);
  $right_vbox->pack_start ($treeview, 1,1,0);

  my $column = Gtk2::TreeViewColumn->new_with_attributes
    ("Item", $renderer, text => 0);
  $column->set (resizable => 1);
  $treeview->append_column ($column);
}


{
  my $hbox = Gtk2::HBox->new;
  $right_vbox->pack_start ($hbox, 0,0,0);

  my $button = Gtk2::Button->new_with_label ('Grab Shortly');
  $hbox->pack_start ($button, 1,1,0);

  my $area = Gtk2::DrawingArea->new;
  $hbox->pack_start ($area, 1,1,0);

  $button->signal_connect
    (clicked => sub {
       Glib::Timeout->add
           (1500, sub {
              print "$progname: pointer_grab\n";
              my $status = Gtk2::Gdk->pointer_grab ($area->window,
                                                    0,     # owner events
                                                    [],
                                                    undef, # confine win
                                                    undef, # cursor inherited
                                                    0);    # current time
              print "$progname: grab $status\n";
              return 0; # Glib::SOURCE_REMOVE
            });
     });
}

{ my $req = $ticker->size_request;
  print "$progname: ticker size_request is ",$req->width,"x",$req->height,
    " (for '",$ticker->get('orientation'),"')\n";
}
$ticker->set_size_request (100,100);

$toplevel->show_all;
Gtk2->main;
exit 0;


package My::EnumComboBox;
use strict;
use warnings;
use Gtk2;

use Glib::Object::Subclass
  'Gtk2::ComboBox',
  signals => { changed => \&_do_changed },
  properties => [ (Glib::ParamSpec->can('type')  # GType params coming soon...
                   ? Glib::ParamSpec->type
                   ('enum-type',
                    'enum-type',
                    'Blurb.',
                    'Gtk2::Enum',  # subtype of Enum
                    Glib::G_PARAM_READWRITE)
                   : Glib::ParamSpec->string
                   ('enum-type',
                    'enum-type',
                    'Blurb.',
                    '',  # default
                    Glib::G_PARAM_READWRITE)),

                  Glib::ParamSpec->scalar
                  ('value',
                   'value',
                   'Blurb.',
                   Glib::G_PARAM_READWRITE),
                ];

# gtk_combo_box_new_text() is quite close to what's wanted here, but there's
# no "set_active_text()" to go to a named value and the format of the
# underlying model might be meant to be a secret ...
#
sub INIT_INSTANCE {
  my ($self) = @_;
  my $renderer = Gtk2::CellRendererText->new;
  $self->pack_start ($renderer, 0);
  $self->set_attributes ($renderer, text => 0);
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'value') {
    my $iter = $self->get_active_iter || return undef;
    my $model = $self->get_model;
    $model->get ($iter, 0);
  } elsif ($pname eq 'enum_type') {
    my $model = $self->get_model || return undef;
    return $model->get('enum-type');
  } else {
    return $self->{$pname};
  }
}
sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;

  if ($pname eq 'enum_type') {
    my $value = $self->get('value');
    my $model;
    if ($newval) {
      $model = ($self->get_model || My::EnumModel->new);
      $model->set_property (enum_type => $newval);
    }
    $self->set (model => $model,
                value => $value);

  } elsif ($pname eq 'value') {
    my $found = 0;
    if (! defined $newval) {
      $self->set_active (-1);
      return;
    }
    my $model = $self->get_model;
    $model->foreach (sub {
                       my ($model, $path, $iter) = @_;
                       if ($newval eq ($model->get($iter, 0))) {
                         $self->set_active_iter ($iter);
                         $found = 1;
                         return 1; # stop looping
                       }
                       return 0; # continue
                     });
    if (! $found) {
      $self->set_active (-1);
    }

  } else {
    $self->{$pname} = $newval;
  }
}

# 'changed' class closure from Gtk2::ComboBox
sub _do_changed {
  my ($self) = @_;
  $self->signal_chain_from_overridden;
  $self->notify ('value');
}

package My::EnumModel;
use strict;
use warnings;

use Glib::Object::Subclass
  'Gtk2::ListStore',
  properties => [ Glib::ParamSpec->string  # ->gtype when available
                  ('enum-type',
                   'enum-type',
                   'Blurb.',
                   'Gtk2::TreeModel',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set_column_types ('Glib::String');
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'enum_type') {
    my $type = $newval;
    $self->clear;

    foreach my $info (Glib::Type->list_values($type)) {
      my $state = $info->{'nick'};
      $self->set ($self->append, 0 => $state);
    }
  }
}

1;
__END__
