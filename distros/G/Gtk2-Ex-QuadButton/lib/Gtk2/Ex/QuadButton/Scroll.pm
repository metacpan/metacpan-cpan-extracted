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

package Gtk2::Ex::QuadButton::Scroll;
use 5.008;
use strict;
use warnings;
use Gtk2 1.220;
use Gtk2::Ex::AdjustmentBits 40;  # new v.40

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 1;

use Gtk2::Ex::QuadButton;
use Glib::Object::Subclass
  'Gtk2::Ex::QuadButton',
  signals => { clicked => \&_do_clicked,
             },
  properties => [ Glib::ParamSpec->object
                  ('hadjustment',
                   (do {
                     my $str = 'Horizontal adjustment';
                     # translation if available
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
                     # translation if available
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'Blurb.',
                   'Gtk2::Adjustment',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('hinverted',
                   'Horizontal inverted',
                   'Whether to invert horizontal movement, so left increases and right decreases.',
                   0, # default no
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('vinverted',
                   'Vertical inverted',
                   'Whether to invert vertical movement, so up increases and down decreases.',
                   0, # default no
                   Glib::G_PARAM_READWRITE),
                ];

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

# sub SET_PROPERTY {
#   my ($self, $pspec, $newval) = @_;
#   my $pname = $pspec->get_name;
#   $self->{$pname} = $newval;
#   ### Enum SET_PROPERTY: $pname, $newval
# }

sub _do_clicked {
  my ($self, $scroll_type) = @_;
  _scroll_vh_type ($self->{'hadjustment'}, $self->{'vadjustment'},
                  $scroll_type,
                  $self->{'hinverted'}, $self->{'vinverted'});

}

my %dir_to_argnum = (left  => 0,
                     right => 0,
                     up    => 1,
                     down  => 1);
my %dir_to_neg = (left  => 1,
                  right => 0,
                  up    => 1,
                  down  => 0);

# anything for GtkScrollType page-forward etc or jump ?
# 
sub _scroll_vh_type {
  my ($hadj, $vadj, $scroll_type, $hinv, $vinv) = @_;

  if ($scroll_type =~ /(page|step)-(up|down|left|right)/) {
    my $argnum = $dir_to_argnum{$2};
    my $adj = $_[$argnum];
    my $amount_method = "${1}_increment";
    my $add = $adj->$amount_method;
    if ($dir_to_neg{$2} ^ !!$_[3+$argnum]) {
      $add = -$add;
    }
    Gtk2::Ex::AdjustmentBits::scroll_value ($adj, $add);
  }
}

1;
__END__

# Is set_scroll_adjustments() sensible for a control widget, or is it meant
# to be only a display widget?
#
# set_scroll_adjustments =>
# { param_types => ['Gtk2::Adjustment',
#                   'Gtk2::Adjustment'],
#   return_type => undef,
#   class_closure => \&_do_set_scroll_adjustments },
#
# # 'set-scroll-adjustments' class closure
# sub _do_set_scroll_adjustments {
#   my ($self, $hadj, $vadj) = @_;
#   $self->set (hadjustment => $hadj,
#               vadjustment => $vadj);
# }
#
# =item C<< $qb->set_scroll_adjustments ($hadj, $vadj) >>
# 
# This is the usual C<Gtk2::Widget> method (see L<Gtk2::Widget>).  It sets the
# C<hadjustment> and C<vadjustment> properties to the adjusters to act on.


=for stopwords Gtk2-Ex-QuadButton Ryde QuadButton scrollbar scroller

=head1 NAME

Gtk2::Ex::QuadButton::Scroll -- buttons up, down, left, right scrolling adjustment objects

=for test_synopsis my ($vadj, $hadj)

=head1 SYNOPSIS

 use Gtk2::Ex::QuadButton::Scroll;
 my $qb = Gtk2::Ex::QuadButton::Scroll->new
            (vadjustment => $vadj,
             hadjustment => $hadj,
             vinverted => 1);

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::QuadButton::Scroll> is a subclass of
C<Gtk2::Ex::QuadButton>,

    Gtk2::Widget
      Gtk2::DrawingArea
        Gtk2::Ex::QuadButton
          Gtk2::Ex::QuadButton::Scroll

=head1 DESCRIPTION

This is a QuadButton which applies the up, left, etc clicks to given
vertical and horizontal C<Gtk2::Adjustment> objects.  Those adjusters will
usually be to control some sort of display widget.

"Inverted" settings swap the up/down or left/right direction of the clicks,
for a display widget which goes up the page instead of down, or left instead
of right.

=head1 FUNCTIONS

=over 4

=item C<< $qb = Gtk2::Ex::QuadButton::Scroll->new (key=>value,...) >>

Create and return a new C<QuadButton::Scroll> widget.  Optional key/value pairs set
initial properties per C<< Glib::Object->new >>.

    my $qb = Gtk2::Ex::QuadButton::Scroll->new;

=back

=head1 PROPERTIES

=over 4

=item C<hadjustment> (C<Gtk2::Adjustment> object, default C<undef>)

=item C<vadjustment> (C<Gtk2::Adjustment> object, default C<undef>)

The adjustment objects to change when the users clicks the button up, right,
etc.  If C<undef> then clicks in the respective horizontal or vertical
direction do nothing.

=item C<hinverted> (C<Gtk2::Adjustment> object, default C<undef>)

=item C<vinverted> (C<Gtk2::Adjustment> object, default C<undef>)

Swap the direction the respective adjustments are moved.  Normally a left
click decreases C<hadjustment> and a right click increases it, but with
C<hinverted> it's the other way around.  Similarly C<vinverted> for
C<vadjustment>.

The sense of this inverting is the as the C<Gtk2::Scrollbar> C<inverted>
property, so if you set C<inverted> on a scrollbar then do the same to this
QuadButton scroller.

=back

=head1 SEE ALSO

L<Gtk2::Ex::QuadButton>,
L<Gtk2::Adjustment>,
L<Gtk2::Scrollbar>

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
