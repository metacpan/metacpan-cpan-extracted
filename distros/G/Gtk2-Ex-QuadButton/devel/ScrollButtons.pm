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

package Gtk2::Ex::ScrollButtons;
use 5.008;
use strict;
use warnings;
use List::Util 'min', 'max';
use Gtk2;
use Locale::Messages 'dgettext';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 1;

use Glib::Object::Subclass
  'Gtk2::Table',
  signals => {
             },
  properties => [ Glib::ParamSpec->enum
                  ('orientation',
                   (do {
                     my $str = 'Orientation';
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'Horizontal or vertical button positioning.',
                   'Gtk2::Orientation',
                   'horizontal',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->enum
                  ('button-orientation',
                   'Button Orientation', # __('')
                   'Horizontal or vertical button positioning.',
                   'Gtk2::Orientation',
                   'horizontal',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('adjustment',
                   'adjustment',
                   'Adjustment to act on.',
                   'Gtk2::Adjustment',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('inverted',
                   (do {
                     my $str = 'Inverted';
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'Whether to invert the movement direction on the adjustment.',
                   0, # default no
                   Glib::G_PARAM_READWRITE),

                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set (n_columns => 2,
              n_rows => 2);
  foreach my $bnum (0, 1) {
    my $button = $self->{$bnum} = Gtk2::Button->new;
    my $arrow = Gtk2::Arrow->new ('left', 'out');
    $arrow->set_name ('My_scroll_arrow');
    $button->add ($arrow);
    $button->signal_connect (clicked => \&_do_clicked);
    $button->show_all;
    $self->attach ($button, 0+$bnum,1+$bnum, 0,1,
                   ['fill','shrink'],['fill','shrink'],0,0);
  }
}

my @to_atype = ({ horizontal => 'left',
                  vertical   => 'up' },
                { horizontal => 'right',
                  vertical   => 'down' });

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;
  ### Enum SET_PROPERTY: $pname, $newval

  if ($pname eq 'orientation') {
    foreach my $bnum (0, 1) {
      my $button = $self->{$bnum};
      $button ->get_child->set_property
        (arrow_type => $to_atype[$bnum]->{$newval});
    }
  }
  if ($pname eq 'button_orientation') {
    foreach my $bnum (0, 1) {
      my $h_bnum = ($newval eq 'horizontal' ? $bnum : 0);
      my $v_bnum = ($newval eq 'vertical' ? $bnum : 0);
      $self->child_set_property ($self->{$bnum},
                                 left_attach   => 0 + $h_bnum,
                                 right_attach  => 1 + $h_bnum,
                                 top_attach    => 0 + $v_bnum,
                                 bottom_attach => 1 + $v_bnum);
    }
  }
}

sub _do_clicked {
  my ($button) = @_;
  my $self = $button->get_parent || return;
  my $adj = $self->{'adjustment'} || return;

  _adj_add ($adj,
            $adj->step_increment
            * ($button == $self->{0} ? -1 : 1)
            * ($self->{'inverted'} ? -1 : 1));
}

sub _adj_add {
  my ($adj, $amount) = @_;
  $adj->value (max ($adj->lower,
                    min ($adj->upper - $adj->page_size,
                         $adj->value + $amount)));
  $adj->notify ('value');
  $adj->signal_emit ('value-changed');
}

1;
__END__

=for stopwords Gtk2-Ex-QuadButton enum ParamSpec GType pspec Enum Ryde boolean

=head1 NAME

Gtk2::Ex::ScrollButtons -- group of buttons up, down, left, right

=head1 SYNOPSIS

 use Gtk2::Ex::ScrollButtons;
 my $sb = Gtk2::Ex::ScrollButtons->new
               (adjustment => $adj,
                orientation => 'vertical');

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::ScrollButtons> is a subclass of
C<Gtk2::DrawingArea>, but don't rely on more than C<Gtk2::Widget> for now.

    Gtk2::Widget
      Gtk2::DrawingArea
        Gtk2::Ex::ScrollButtons

# =head1 DESCRIPTION
#
=head1 FUNCTIONS

=over 4

=item C<< $sb = Gtk2::Ex::ScrollButtons->new (key=>value,...) >>

Create and return a new C<ScrollButtons> widget.  Optional key/value pairs
set initial properties per C<< Glib::Object->new >>.

    my $sb = Gtk2::Ex::ScrollButtons->new
               (adjustment => $adj);

=back

=head1 PROPERTIES

=over 4

=item C<adjustment> (C<Gtk2::Adjustment> object, default C<undef>)

=item C<inverted> (boolean, default false)

Whether to swap the direction the adjustment is moved.  Normally
C<adjustment> increases to the left or upwards.  Inverting goes instead to
the right or downwards.

=item C<orientation> (C<Gtk2::Orientation> enum, default C<"horizontal">)

Whether to drawn buttons horizontally or vertically.

=back

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
