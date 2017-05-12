# Copyright 2008, 2009, 2010, 2013 Kevin Ryde

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

package Gtk2::Ex::DateSpinner;
use 5.008;
use strict;
use warnings;
use Date::Calc;
use Gtk2;
use Glib::Ex::ObjectBits 'set_property_maybe';
# 1.16 for turn_utf_8_on()
use Locale::Messages 1.16 'dgettext', 'turn_utf_8_on';

our $VERSION = 9;

# uncomment this to run the ### lines
# use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::HBox',
  properties => [Glib::ParamSpec->string
                 ('value',
                  'Date value',
                  'ISO format date string like 2008-07-25.',
                  '2000-01-01',
                  Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  ### DateSpinner INIT_INSTANCE() ...

  $self->{'value'} = '2000-01-01';

  my $year_adj = Gtk2::Adjustment->new (2000,    # initial
                                        0, 9999, # range
                                        1,       # step increment
                                        10,      # page_increment
                                        0);      # page_size (not applicable)
  my $year = $self->{'year'} = Gtk2::SpinButton->new ($year_adj, 1, 0);
  $year->signal_connect (insert_text => \&_do_spin_insert_text);
  $year->show;
  $self->pack_start ($year, 0,0,0);

  my $month_adj = Gtk2::Adjustment->new (1,      # initial
                                         0, 99,  # range
                                         1,      # step_increment
                                         1,      # page_increment
                                         0);     # page_size (not applicable)
  my $month = $self->{'month'} = Gtk2::SpinButton->new ($month_adj, 1, 0);
  $month->signal_connect (insert_text => \&_do_spin_insert_text);
  $month->show;
  $self->pack_start ($month, 0,0,0);

  my $day_adj = Gtk2::Adjustment->new (1,      # initial
                                       0, 99,  # range
                                       1,      # step_increment
                                       1,      # page_increment
                                       0);     # page_size (not applicable)
  my $day = $self->{'day'} = Gtk2::SpinButton->new ($day_adj, 1, 0);
  $day->signal_connect (insert_text => \&_do_spin_insert_text);
  $day->show;
  $self->pack_start ($day, 0,0,0);

  # translations from Gtk itself
  # eg. from /usr/share/locale/de/LC_MESSAGES/gtk20-properties.mo
  # tooltip-text new in Gtk 2.10
  set_property_maybe ($year,  tooltip_text =>
                      turn_utf_8_on(dgettext('gtk20-properties','Year')));
  set_property_maybe ($month, tooltip_text =>
                      turn_utf_8_on(dgettext('gtk20-properties','Month')));
  set_property_maybe ($day,   tooltip_text =>
                      turn_utf_8_on(dgettext('gtk20-properties','Day')));

  my $dow = $self->{'dayofweek_label'}
    = Gtk2::Label->new (_ymd_to_wday_str(2000,1,1));
  $dow->show;
  $self->pack_start ($dow, 0,0,0);

  $year->signal_connect  (value_changed => \&_spin_value_changed);
  $month->signal_connect (value_changed => \&_spin_value_changed);
  $day->signal_connect   (value_changed => \&_spin_value_changed);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### DateSpinner SET_PROPERTY() ...

  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'value') {
    my ($year, $month, $day) = split /-/, $newval;
    $self->{'year'}->set_value ($year);
    $self->{'month'}->set_value ($month);
    $self->{'day'}->set_value ($day);
  }
}

sub _do_spin_insert_text {
  my ($spin, $text, $len) = @_;
  ### DateSpinner insert: $text
  $text =~ s/^\s+//;
  $text =~ s/\s+$//;
  if ($text =~ /^\d\d\d\d-\d\d-\d\d$/) {
    my $self = $spin->parent;
    $self->set (value => $text);
    $spin->signal_stop_emission_by_name ('insert-text');
  }
  return;
}

# Signal handler for 'value-changed' on the year,month,day SpinButtons.
# $spin is one of $self->{'year'},'month', or 'day
sub _spin_value_changed {
  my ($spin) = @_;
  ### DateSpinner _spin_value_changed() ...
  my $self = $spin->parent;

  if ($self->{'update_in_progress'}) { return; }
  local $self->{'update_in_progress'} = 1;

  my $year_spin  = $self->{'year'};
  my $month_spin = $self->{'month'};
  my $day_spin   = $self->{'day'};

  my $year  = $year_spin->get_value;
  my $month = $month_spin->get_value;
  my $day   = $day_spin->get_value;
  ### DateSpinner update: "$year, $month, $day"

  ($year, $month, $day) = Date::Calc::Add_Delta_YMD
    (2000, 1, 1, $year-2000, $month-1, $day-1);

  $year_spin->set_value ($year);
  $month_spin->set_value ($month);
  $day_spin->set_value ($day);

  $self->{'dayofweek_label'}->set_text (_ymd_to_wday_str($year,$month,$day));

  my $value = sprintf ('%04d-%02d-%02d', $year, $month, $day);
  ### new value: $value
  ### old value: $self->{'value'}
  if ($value ne $self->{'value'}) {
    ### notify ...
    $self->{'value'} = $value;
    $self->notify('value');
  }
}

# $year is 2000 etc, $month is 1 to 12, $day is 1 to 31.
# Return a wide-char string which is the short name of the day of the week
# to show, such as " Fri ".
#
# Prefer strftime over Date::Calc's localized names, on the basis that
# strftime will probably know more languages, and setlocale() is done
# automatically when perl starts.
#
# These modules are required for the initial value when a DateSpinner is
# created.  Deferring them until this time (rather than BEGIN time) might
# let you load DateSpinner without yet dragging in the other big stuff.
#
sub _ymd_to_wday_str {
  my ($year,$month,$day) = @_;
  require POSIX;
  require I18N::Langinfo;
  require Encode;
  my $wday = Date::Calc::Day_of_Week ($year, $month, $day); # 1=Mon,7=Sun,...
  my $str = POSIX::strftime (' %a ', 0,0,0, 1,1,100, $wday%7);# 0=Sun,1=Mon,..
  my $charset = I18N::Langinfo::langinfo (I18N::Langinfo::CODESET());
  return Encode::decode ($charset, $str);
}

sub get_value {
  my ($self) = @_;
  return $self->{'value'};
}

sub set_today {
  my ($self) = @_;
  my ($year, $month, $day) = Date::Calc::Today();
  $self->set (value => sprintf ('%04d-%02d-%02d', $year, $month, $day));
}

1;
__END__

=for stopwords SpinButtons YYYY-MM-DD Whitespace localizations startup Gtk tooltips DateSpinner Gtk2-Ex-DateSpinner Eg Ryde

=head1 NAME

Gtk2::Ex::DateSpinner -- year/month/day date entry using SpinButtons

=head1 SYNOPSIS

 use Gtk2::Ex::DateSpinner;
 my $ds = Gtk2::Ex::DateSpinner->new (value => '2008-06-14');

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::DateSpinner> is (currently) a subclass of C<Gtk2::HBox>, though
it's probably not a good idea to rely on that.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Box
          Gtk2::HBox
            Gtk2::Ex::DateSpinner

=head1 DESCRIPTION

C<Gtk2::Ex::DateSpinner> displays and changes a year, month, day date using
three C<Gtk2::SpinButton> fields.  The day of the week is shown to the
right.

        +------+   +----+   +----+
        | 2008 |^  |  6 |^  | 14 |^   Sat
        +------+v  +----+v  +----+v

There's many ways to enter or display a date.  This style is good for
clicking to a nearby date but also allows a date to be typed in if a long
way away.

If a click or entered value takes the day outside the days in the month then
it wraps around to the next or previous month.  Likewise the month wraps
around to the next or previous year.  When typing in a number the day of the
week display updates when you press enter.

A paste of an ISO format YYYY-MM-DD date into any of the day, month or year
fields sets the three fields to that value.  Whitespace at the start or end
of a paste is ignored.

Day of the week and date normalization calculations use C<Date::Calc> so
they're not limited to the system C<time_t> (which may be as little as 1970
to 2038 on a 32-bit system).  The day of the week uses L<POSIX/strftime> and
so gets the usual C<LC_TIME> localizations which are established at Perl
startup or Gtk initialization.  The year/month/day tooltips use Gtk message
translations.

See F<examples/simple.pl> for a complete program creating a DateSpinner.
See F<examples/builder.pl> for similar using C<Gtk2::Builder>.

=head1 FUNCTIONS

=over 4

=item C<< $ds = Gtk2::Ex::DateSpinner->new (key=>value,...) >>

Create and return a new DateSpinner widget.  Optional key/value pairs set
initial properties per C<< Glib::Object->new >>.  Eg.

    my $ds = Gtk2::Ex::DateSpinner->new (value => '2008-06-14');

=item C<< $ds->set_today >>

Set the C<value> in C<$ds> to today's date (today in the local timezone).

=back

=head1 PROPERTIES

=over 4

=item C<value> (string, default "2000-01-01")

The current date value, as an ISO format "YYYY-MM-DD" string.  When you read
this the day and month are always "normalized", so MM is 01 to 12 and DD is
01 to 28,29,30 or 31 (according to  how many days in the particular month).

The default 1 January 2000 is meant to be fairly useless and you should set
it to something that makes sense for the particular application.

There's very limited validation on the C<value> string, so don't set
garbage.

=back

=head1 SEE ALSO

L<Gtk2::Ex::DateSpinner::CellRenderer>,
L<Date::Calc>

L<Gtk2::SpinButton>,
L<Gtk2::Calendar>,
L<Gtk2::Ex::CalendarButton>,
L<Gtk2::Ex::DateRange>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-datespinner/index.html>

=head1 LICENSE

Gtk2-Ex-DateSpinner is Copyright 2008, 2009, 2010, 2013 Kevin Ryde

Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-DateSpinner.  If not, see L<http://www.gnu.org/licenses/>.

=cut
