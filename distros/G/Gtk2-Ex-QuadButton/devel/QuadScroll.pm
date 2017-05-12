# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::QuadScroll;
use 5.008;
use strict;
use warnings;
use Gtk2;
use List::Util 'min', 'max';

use Gtk2::Ex::AdjustmentBits 40;  # new v.40
use Gtk2::Ex::AdjustmentBits;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 1;

use Glib::Object::Subclass
  'Gtk2::Table',
  signals => { scroll_event => \&Gtk2::Ex::AdjustmentBits::scroll_widget_event_vh,

               set_scroll_adjustments =>
               { param_types => ['Gtk2::Adjustment',
                                 'Gtk2::Adjustment'],
                 return_type => undef,
                 class_closure => \&_do_set_scroll_adjustments },

               'change-value' =>
               { param_types => ['Gtk2::ScrollType'],
                 return_type => undef,
                 class_closure => \&_do_change_value,
                 flags => ['run-first','action'] },
             },

  properties => [ Glib::ParamSpec->object
                  ('hadjustment',
                   (do {
                     my $str = 'Horizontal adjustment';
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'Blurb.',
                   'Gtk2::Adjustment',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('vadjustment',
                   (do {
                     my $str = 'Vertical adjustment';
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'Blurb.',
                   'Gtk2::Adjustment',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('hinverted',
                   'Horizontal inverted',
                   'Blurb.',
                   0,
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('vinverted',
                   'Vertical inverted',
                   'Blurb.',
                   0, # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->double
                  ('xalign',
                   (do {
                     my $str = 'Horizontal alignment';
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'Blurb.',
                   0, 1.0, # min,max
                   0.5,    # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->double
                  ('yalign',
                   (do {
                     my $str = 'Vertical alignment';
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'Blurb.',
                   0, 1.0, # min,max
                   0.5,    # default
                   Glib::G_PARAM_READWRITE),
                ];

# priority level "gtk" treating this as widget level default, for overriding
# by application or user RC
Gtk2::Rc->parse_string (<<'HERE');
binding "Gtk2__Ex__QuadScroll_keys" {
  bind "Up"          { "change-value" (step-up) }
  bind "Down"        { "change-value" (step-down) }
  bind "<Ctrl>Up"    { "change-value" (page-up) }
  bind "<Ctrl>Down"  { "change-value" (page-down) }
  bind "Left"        { "change-value" (step-left) }
  bind "Right"       { "change-value" (step-right) }
  bind "<Ctrl>Left"  { "change-value" (page-left) }
  bind "<Ctrl>Right" { "change-value" (page-right) }
  bind "Page_Up"     { "change-value" (page-up) }
  bind "Page_Down"   { "change-value" (page-down) }
}
class "Gtk2__Ex__QuadScroll" binding:gtk "Gtk2__Ex__QuadScroll_keys"
HERE

use constant _DIRECTIONS => ('up', 'down', 'left', 'right');
my %dir_to_x = (left  => 0,
                right => 0,
                up   => 1,
                down => 1);
my %dir_to_y = (left  => 0,
                right => 1,
                up   => 0,
                down => 1);

sub INIT_INSTANCE {
  my ($self) = @_;
  ### QuadScroll INIT_INSTANCE()
  $self->can_focus (1);

  foreach my $dir (_DIRECTIONS) {
    my $arrow = $self->{$dir}
      = Gtk2::Ex::ArrowButton->new
        (arrow_type => $dir,
         visible => 1);
    my $x = $dir_to_x{$dir};
    my $y = $dir_to_y{$dir};
    ### attach: "x=$x, y=$y"
    $self->attach ($arrow, $x,$x+1, $y,$y+1,
                   ['fill','shrink'],['fill','shrink'],0,0);
  }
}

# 'set-scroll-adjustments' class closure
sub _do_set_scroll_adjustments {
  my ($self, $hadj, $vadj) = @_;
  $self->set (hadjustment => $hadj,
              vadjustment => $vadj);
}

my %dir_to_neg = (left  => 1,
                  right => 0,
                  up    => 1,
                  down  => 0);

sub _do_change_value {
  my ($self, $scrolltype) = @_;
  scroll_by_type ($self->{'hadjustment'},
                  $self->{'vadjustment'},
                  $scrolltype,
                  $self->{'hinvert'},
                  $self->{'vinvert'});

  # my $adj = $self->{"${vh}adjustment"} || return;
  # if ($scrolltype =~ /(page|step)-(up|down|left|right)/) {
  #   my $amount_method = "${1}_increment";
  #   my $add = $adj->$amount_method;
  #   if ($dir_to_neg{$2} ^ !!$self->{"${vh}inverted"}) {
  #     $add = -$add;
  #   }
  #   Gtk2::Ex::AdjustmentBits::scroll_value ($adj, $add);
  # }
}

my %dir_to_arg = (left  => 0,
                  right => 0,
                  up    => 1,
                  down  => 1);

# what of forward-page, jump, etc
sub scroll_by_type {
  my ($hadj, $vadj, $scroll_type, $hinv, $vinv) = @_;

  if ($scroll_type =~ /(page|step)-(up|down|left|right)/) {
    my $arg = $dir_to_arg{$2};
    my $adj = $_[$arg];
    my $amount_method = "${1}_increment";
    my $add = $adj->$amount_method;
    if ($dir_to_neg{$2} ^ !!$_[3+$arg]) {
      $add = -$add;
    }
    Gtk2::Ex::AdjustmentBits::scroll_value ($adj, $add);
  }
}




# paint_polygon doesn't put a colour on the inside, or something
#
# $style->paint_polygon ($win,         # window
#                        'normal',# $state,       # state
#                        'none',       # shadow
#                        $event->area,
#                        $self,        # widget
#                        __PACKAGE__,  # detail
#                        1,            # fill
#                        # 0,0, 20,0, 0,20, 0,0
#                         @points_fg
#                       );


  # $self->{'square'} = 0;
  # if ($self->{'square'}) {
  #   my $w2 = int($width/2);
  #   my $h2 = int($height/2);
  # 
  #   if ($dir) {
  #     $win->draw_rectangle ($style->bg_gc('prelight'),
  #                           1, # fill,
  #                           ($dir eq 'left' || $dir eq 'right' ? 0 : $width-$w2),
  #                           ($dir eq 'left' || $dir eq 'up' ? 0 : $height-$h2),
  #                           $w2,$h2);
  #   }
  # 
  #   if ($self->has_focus) {
  #     $style->paint_focus ($win,   # window
  #                          $state,  # state
  #                          $event->area,
  #                          $self,        # widget
  #                          __PACKAGE__,  # detail
  #                          0,0,
  #                          $width,$height);
  #   }
  # 
  #   $style->paint_arrow ($win,   # window
  #                        $state,  # state
  #                        'none',  # shadow
  #                        $event->area,
  #                        $self,        # widget
  #                        __PACKAGE__,  # detail
  #                        'left',        # arrow type
  #                        1,             # fill
  #                        0,0,
  #                        $w2,$h2);
  # 
  #   $style->paint_arrow ($win,   # window
  #                        $state,  # state
  #                        'none',  # shadow
  #                        $event->area,
  #                        $self,        # widget
  #                        __PACKAGE__,  # detail
  #                        'right',        # arrow type
  #                        1,             # fill
  #                        0,$height-$h2,
  #                        $w2,$h2);
  # 
  #   $style->paint_arrow ($win,   # window
  #                        $state,  # state
  #                        'none',  # shadow
  #                        $event->area,
  #                        $self,        # widget
  #                        __PACKAGE__,  # detail
  #                        'up',        # arrow type
  #                        1,             # fill
  #                        $width-$w2,0,
  #                        $w2,$h2);
  # 
  #   $style->paint_arrow ($win,   # window
  #                        $state,  # state
  #                        'none',  # shadow
  #                        $event->area,
  #                        $self,        # widget
  #                        __PACKAGE__,  # detail
  #                        'down',        # arrow type
  #                        1,             # fill
  #                        $width-$w2,$height-$h2,
  #                        $w2,$h2);
  # 
  # } else {

    # if ($self->{'square'}) {
    #   if ($y >= 0 && $y < $height/2
    #       && $x >= 0 && $x < $width/2) {
    #     return 'left';
    #   }
    #   if ($y >= 0 && $y < $height/2
    #       && $x >= $width/2 && $x < $width) {
    #     return 'up';
    #   }
    #   if ($y >= $height/2 && $y < $height
    #       && $x >= 0 && $x < $width/2) {
    #     return 'right';
    #   }
    #   if ($y >= $height/2 && $y < $height
    #       && $x >= $width/2 && $x < $width) {
    #     return 'down';
    #   }
    # }




1;
__END__

=for stopwords Gtk2-Ex-QuadButton enum ParamSpec GType pspec Enum Ryde QuadScroll

=head1 NAME

Gtk2::Ex::QuadScroll -- group of buttons up, down, left, right

=head1 SYNOPSIS

 use Gtk2::Ex::QuadScroll;
 my $qb = Gtk2::Ex::QuadScroll->new;

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::QuadScroll> is a subclass of
C<Gtk2::DrawingArea>, but don't rely on more than C<Gtk2::Widget> for now.

    Gtk2::Widget
      Gtk2::DrawingArea
        Gtk2::Ex::QuadScroll

# =head1 DESCRIPTION
# 
=head1 FUNCTIONS

=over 4

=item C<< $qb = Gtk2::Ex::QuadScroll->new (key=>value,...) >>

Create and return a new QuadScroll object.  Optional key/value pairs set
initial properties per C<< Glib::Object->new >>.

    my $qb = Gtk2::Ex::QuadScroll->new;

=back

# =head1 PROPERTIES
# 
# =over 4
# 
# =item C<combobox> (C<Gtk2::ComboBox> object, default C<undef>)
# 
# =back

=head1 SEE ALSO

L<Gtk2::Button>,
L<Gtk2::Arrow>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-quadbutton/index.html>

=head1 LICENSE

Copyright 2010, 2011 Kevin Ryde

Gtk2-Ex-QuadButton is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-QuadButton.  If not, see L<http://www.gnu.org/licenses/>.

=cut
