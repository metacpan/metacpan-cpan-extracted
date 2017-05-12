package Gtk2::Ex::Spinner;

use strict;
use warnings;
use Gtk2;

our $VERSION = 0.21;

use constant DEBUG => 0;

use Glib::Object::Subclass
  Gtk2::HBox::,
  properties => [Glib::ParamSpec->string
                 ('value',
                  'value',
                  'Integer',
                  1,
                  Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'value'} = 1;

  my $spin_adj = Gtk2::Adjustment->new (1,    # initial
                                        0, 9999, # range
                                        1,       # step increment
                                        10,      # page_increment
                                        0);      # page_size (not applicable)
  my $spin = $self->{'spin'} = Gtk2::SpinButton->new ($spin_adj, 1, 0);
  $spin->show;
  $self->pack_start ($spin, 0,0,0);

  $spin->signal_connect   (value_changed => \&_update);
  _update ($spin);
}

sub SET_PROPERTY {
  	my ($self, $pspec, $newval) = @_;
  	my $pname = $pspec->get_name;
  	$self->{$pname} = $newval;  # per default GET_PROPERTY

	$self->{'spin'}->set_value ($newval) if $pname eq 'value';
}

sub _update {
  my ($spin) = @_;
  my $self = $spin->parent;

  if ($self->{'update_in_progress'}) { return; }
  local $self->{'update_in_progress'} = 1;

  my $value = $self->{'spin'}->get_value;
  if ($value ne $self->{'value'}) {
    $self->{'value'} = $value;
    $self->notify('value');
  }
}

sub get_value {
  my ($self) = @_;
  return $self->{'value'};
}

1;
__END__

=head1 NAME

Gtk2::Ex::Spinner -- integer entry using SpinButtons

=head1 SYNOPSIS

 use Gtk2::Ex::Spinner;
 my $is = Gtk2::Ex::Spinner->new (value => 5);

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::Spinner> is (currently) a subclass of C<Gtk2::HBox>, though
it's probably not a good idea to rely on that.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Box
          Gtk2::HBox
            Gtk2::Ex::Spinner

=head1 DESCRIPTION

C<Gtk2::Ex::Spinner> is based on a great L<Gtk2::Ex::DateSpinner>, so
in most cases documentation is the same. License is (of course) the same too :-).

C<Gtk2::Ex::Spinner> displays and changes a integer using one 
C<Gtk2::SpinButton> fields. The value is shown as below:

        +------+   
        |   99 |^  
        +------+v  

There's lots ways to enter/display an integer. This style is good for clicking
to a nearby value, but also allows a value to be typed in if a long way away.

=head1 FUNCTIONS

=over 4

=item C<< $ds = Gtk2::Ex::Spinner->new (key=>value,...) >>

Create and return a new Spinner widget.  Optional key/value pairs set
initial properties per C<< Glib::Object->new >>.  Eg.

    my $s = Gtk2::Ex::Spinner->new (value => 99);

=back

=head1 SEE ALSO

L<Gtk2::Ex::DateSpinner>
L<Gtk2::Ex::DateSpinner::CellRenderer>, L<Date::Calc>, L<Gtk2::Calendar>,
L<Gtk2::SpinButton>, L<Gtk2::Ex::CalendarButton>, L<Gtk2::Ex::DateRange>


=head1 LICENSE

Gtk2-Ex-Spinner is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Spinner is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Spinner.  If not, see L<http://www.gnu.org/licenses/>.

=cut
