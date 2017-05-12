package Gapp::Gtk2::DateEntry;
{
  $Gapp::Gtk2::DateEntry::VERSION = '0.60';
}
use strict;
use warnings;
use Carp;

use Gtk2;
use DateTime;
use Glib qw(TRUE FALSE);


use Glib::Object::Subclass
    Gtk2::Entry::,
    interfaces  => [ 'Gtk2::CellEditable' ],
    properties  => [
        Glib::ParamSpec->scalar(
            'value'                                  ,
            'value'                                  ,
            'DateTime object'      ,
            Glib::G_PARAM_READWRITE
        ),
    ],
    signals => {
        value_changed => {
           class_closure => \&_do_value_changed,
           flags         => ['run-first']     ,
           return_type   => undef             ,
           param_types   => []                ,
        },
    }
;

sub INIT_INSTANCE {
    my $self = shift;
    $self->signal_connect('key-press-event' => \&_do_key_press_event);
    $self->signal_connect('focus-out-event' => \&_do_focus_out_event);
}

sub SET_PROPERTY {
    my ($self, $pspec, $newval) = @_;
    
    my $pname = $pspec->get_name;
    
    # handle changes to the value parameter (emit a signal on change)
    if ($pname eq 'value') {
        $self->set_value($newval);
    }
    else {
        $self->{$pname} = $newval;
    }
}

sub get_value {
    my $self = shift;
    $self->{datetime} ? $self->{datetime}->clone : undef;
}

sub set_value {
    carp 'usage $date_entry->set_value($new_value)' unless @_ == 2;
    my $self = shift;
    my $newval = shift;
   
    # parse the new value if defined
    if ( defined $newval && ! ref $newval ) {
        $newval = $self->_parse_input($newval);
    }
    my $oldval = $self->{datetime};
    
    if (! defined $oldval && ! defined $newval) {
        $self->_display_output;
    }
    elsif (! defined $oldval && defined $newval ||
           ! defined $newval && defined $oldval ||
           $oldval ne $newval) {
        $self->{datetime} = $newval;
        $self->signal_emit('value-changed');
    }
    else {
        $self->_display_output;
    }
    
}

sub set_today {
    my $self = shift;
    my ($hour, $minute) = (localtime time)[2,1];
    
    my $obj   = $self->{datetime};
    my $today = DateTime->now( time_zone => 'floating' );
    $today->set( hour => 0, minute => 0, second => 0 );
    
    if ($obj && $obj->ymd eq $today->ymd) {
        return;
    } else {
        $self->{datetime} = $today;
        $self->signal_emit('value-changed');
    }
}

sub _do_value_changed {
    my $self = shift;
    my $value = $self->get_value;
    $self->_display_output;
}

sub _do_focus_out_event {
    my $self = shift;
    $self->set_value($self->get_text);
    return FALSE;
}

sub _do_key_press_event {
    my $self = shift;
    my $key  = shift;
    my $key_val = $key->keyval;
    
    # entry pressed, parse input
    if ($key_val == 65293) {
        $self->set_value($self->get_text);
        return FALSE;
    }
    # laft arrow key pressed
    elsif ($key_val >= 65361 && $key_val <= 65364) {
        $self->set_value($self->get_text);
        return $self->_do_key_left  if $key_val == 65361;
        return $self->_do_key_right if $key_val == 65363;
        return $self->_do_key_up    if $key_val == 65362;
        return $self->_do_key_down  if $key_val == 65364;
    }
    # pass everything else on
    else {
        return FALSE;
    }
}

sub _do_key_left {
    my $self = shift;
    my $selected = $self->get_selected_component;
    
    if (! $selected) {
        return FALSE if $self->get_position == 0;
        $self->_select_closest_component('left');
        return TRUE;
    }
    else {
        if    ($selected eq 'all'  ) { $self->set_selected_component('year')  }
        elsif ($selected eq 'month') { return FALSE;                          }
        elsif ($selected eq 'day'  ) { $self->set_selected_component('month') }
        elsif ($selected eq 'year' ) { $self->set_selected_component('day')   }
    }
    
    return TRUE;
}

sub _do_key_right {
    my $self = shift;
    my $selected = $self->get_selected_component;
    
    if (! $selected) {
        return FALSE if $self->get_position == length $self->get_text;
        $self->_select_closest_component('right');
        return TRUE;
    }
    else {
        if    ($selected eq 'all'  ) { $self->set_selected_component('month') }
        elsif ($selected eq 'month') { $self->set_selected_component('day')   }
        elsif ($selected eq 'day'  ) { $self->set_selected_component('year')  }
        elsif ($selected eq 'year' ) { return FALSE;   }  
    }

    return TRUE;
}

sub _do_key_up {
    my $self = shift;
    my $selected = $self->get_selected_component;
    $self->_select_closest_component('up') and return TRUE unless $selected;
    
    my $obj = $self->{datetime};
    for ($selected) {
        if    ($_ eq 'all'  ) { $obj->add(days  => 7)  }
        elsif ($_ eq 'month') { $obj->add(months => 1) }
        elsif ($_ eq 'day'  ) { $obj->add(days  => 1)  }
        elsif ($_ eq 'year' ) { $obj->add(years => 1)  }
    }      

    $self->signal_emit('value-changed');
    $self->set_selected_component($selected);
    
    return TRUE;
}

sub _do_key_down {
    my $self = shift;
    my $selected = $self->get_selected_component;  
    $self->_select_closest_component('down') and return TRUE unless $selected;

    my $obj = $self->{datetime};
    for ($selected) {
        if    ($_ eq 'all'  ) { $obj->subtract(days  => 7) }
        elsif ($_ eq 'month') { $obj->subtract(months => 1) }
        elsif ($_ eq 'day'  ) { $obj->subtract(days  => 1) }
        elsif ($_ eq 'year' ) { $obj->subtract(years => 1) }
    }
    
    $self->signal_emit('value-changed');
    $self->set_selected_component($selected);
    return TRUE;
}

sub _display_output {
    my $self  = shift;
    
    my $obj = $self->{datetime};
    
    my $output = $obj ? sprintf ('%02d/%02d/%04d', $obj->month, $obj->day, $obj->year) : '';
    $self->set_text($output);
}


{
    my %pos = (
        month => [0,2],
        day   => [3,5],
        year  => [6,10],
        all   => [0,10]
    );


    sub get_selected_component {
        my $self = shift;
        
        
        my ($start, $end) = $self->get_selection_bounds;
        $start = 0 unless $start;
        $end = 0 unless $end;
        return undef if $start == $end;
        
        
        for my $name (keys %pos) {
            my $coords = $pos{$name};
            if ($start == $coords->[0] && $end == $coords->[1]) {
                return $name;
            }
        }
        
        # no componenet selected if we got here
        return undef;
    }
    
    
    sub set_selected_component {

        confess q[usage is $date_entry->set_selected_component($field)] unless @_ == 2;
        my $self  = shift;
        my $field = shift;
        
        if (! defined $field || $field eq 'none' || $field eq '') {
            $self->select_region(0,0);
        } else {
            # throw exception if not a valid component name
            confess q[$field must be one of undef, none, year, month, day]
                if ! exists $pos{$field};
            $self->select_region(@{$pos{$field}});
        }
    }
}  # end encapsulated %pos variable



sub _select_closest_component {
    my $self      = shift;
    my $direction = shift;
    my $cursor = $self->get_position;
    
    if ($cursor == 0 || $cursor == 1) {
        $self->set_selected_component('month');
    }
    elsif ($cursor == 2 && $direction ne 'right') {
        $self->set_selected_component('month');
    }
    elsif ($cursor == 2 && $direction eq 'right') {
        $self->set_selected_component('day');
    }
    elsif ($cursor == 3 && $direction eq 'left') {
        $self->set_selected_component('month');
    }
    elsif ($cursor == 3 && $direction ne 'left') {
        $self->set_selected_component('day');
    }
    elsif ($cursor == 4) {
        $self->set_selected_component('day');
    }
    elsif ($cursor == 5 && $direction ne 'right') {
        $self->set_selected_component('day');
    }
    elsif ($cursor == 5 && $direction eq 'right') {
        $self->set_selected_component('year');
    }
    elsif ($cursor == 6 && $direction eq 'left') {
        $self->set_selected_component('day');
    }
    elsif ($cursor == 6 && $direction ne 'left') {
        $self->set_selected_component('year');
    }
    elsif ($cursor >= 7) {
        $self->set_selected_component('year');
    }
    
    return TRUE;
}

sub _parse_input {
    my $self  = shift;
    my $value = shift || '';
    $value =~ s/\s//g;
    return undef if ! defined $value || $value eq '';
   
    my ($d, $m, $y);
    # when the user is just changing the day of the month
    if ($value =~ /^(\d{1,2})$/) {
        $d = $1;
        $m = 0;
        $y = 0;
    }
    # when the user is just changing the year
    elsif ($value =~ /^\d{4}$/ && int ($value) > 1231) {
        $m = 0;
        $d = 0;
        $y = $value;
    }
    # for parsing mm-dd-yyyy style objects (or mmddyy mmdd etc)
    elsif ($value =~ /^([01]?[0-9])([ \.\-\/\\])?([0-3][0-9])([ \.\-\/\\])?(([0-9]{2})|([0-9]{4}))?$/) {
        $m = $1 || 0;
        $d = $3 || 0;
        $y = $5 || 0;
        
        if ($y) {
            if    ($y <= 20) { $y += 2000 }
            elsif ($y <= 99) { $y += 1900 }
        }
    }
    # for parsing yyyy-mm-dd style dates - year must be 4 digits in this scenario
    elsif ($value =~ /^(\d{4})([ \.\-\/\\])?([01]?[0-9])([ \.\-\/\\])?([0-3][0-9])$/) {
        $y = $1;
        $m = $3;
        $d = $5;
    }
    else {
        return $self->{datetime};
    }
    
    # fill in missing values using the currently set date, or the current date
    my $obj = $self->{datetime};
    $obj = $obj ? $obj : DateTime->now( time_zone => 'floating' );
    
    my ($cd, $cm, $cy);
    $cd = $obj->day;
    $cm = $obj->month;
    $cy = $obj->year;
    
    $m = $m ? $m : $cm;
    $d = $d ? $d : $cd;
    $y = $y ? $y : $cy;

    return DateTime->new(day => $d, month => $m, year => $y, time_zone => 'floating' );
}


1;


__END__

=head1 NAME

Gtk2::Ex::DateEntry -- Widget for entering dates

=head1 SYNOPSIS

 use Gtk2::Ex::DateEntry;
 $de = Gtk2::Ex::DateEntry->new;
 $de->set_value('10132009');
 $de->get_value;

=head1 WIDGET HIERARCHY

    Gtk2::Widget
      Gtk2::Entry
        Gtk2::Ex::DateEntry

=head1 DESCRIPTION

C<Gtk2::Ex::DateEntry> displays and edits a date in MM/DD/YYYY format with some
convienence functions.

Use the up and down keys to modify the invidual components of the value, and the
left and right keys to navigate between them. Pressing up or down while the
entire contents of the entry is selected (such as when you focus-in) modifies
the value in 7 day increments.

The date is displayed in the widget in MM/DD/YYYY format, but the results from
C<get_value> are in the format YYYY-MM-DD. The reason being that dates are most
commonly (in the west) displayed as MM/DD/YYYY, however when programming it is
much more common to encounter dates in the format YYYY-MM-DD.

You can also type a date into the entry into various formats, which will be
parsed and then displayed in the entry in MM/DD/YYYY format. Below are some
examples of things you can enter into the widget and the resulting internal and
display values. Also note that whitespace is ignored during parsing.

=over 4

  INPUT         VALUE         DISPLAY
  08/11/1986    1986-08-11    08/11/1986
  08-11-1986    1986-08-11    08/11/1986
  08.11.1986    1986-08-11    08/11/1986
  08111986      1986-08-11    08/11/1986
  081186        1986-08-11    08/11/1986

=back

Entering a partial date (just year, month, day) will result in the remaining
components being filled in for you. If the widget is currently set to a date,
the current values will be used. If the widget is not set to a date, the
current system date will be used to fill in the missing values.

=over 4

  STARTING       INPUT     RESULT
  1986-08-11     10        1986-08-10  # 1-2 digits, setsday of month
  1986-08-11     1231      1986-12-31  # 3-4 digits sets month, day
  1986-08-11     2009      2009-12-31  # 4 digits (> 1231) sets year

=back

This may all seem confusing, just try playing around with the widget. It should
generally just do what you would expect.


=head1 FUNCTIONS

=over 4

=item C<< $te = Gtk2::Ex::DateEntry->new () >>

Create and return a new DateEntry widget. 

=item C<< $te->get_selected_component >>

Returns the currently selected component - any of 'month', 'day', 'year'.
An emptry string will be returned if the selection bounds contains more or less
than 1 individual component, and will return 'all' if all componentes are
selected.

=item C<< $te->set_selected_component($component) >>

Highlights the given component, which can then be edited by typing over it or
pressing the arrow keys up or down. You can pass the values 'month', 'day',
'year', 'all', 'none', undef, or an emptry string;

=item C<< $te->set_today >>

Set the widget to the current date.

=item C<< $te->get_value >>

Return the current date in YYYY-MM-DD format.

=item C<< $te->set_value ($value) >>

Parses the content of $value then sets the widget to the resulting date.

=back

=head1 SIGNALS

=over 4

=item C<value-changed>

Emitted after a succesful value change.

=back

=head1 SEE ALSO

L<Gtk2::Ex::DateEntry::CellRenderer>, L<Gtk2::Ex::FormFactory::DateEntry>

=head1 AUTHOR

Jeffrey Hallock <jeffrey.ray at ragingpony com>

=head1 BUGS

None known. Please send bugs to <jeffrey.ray at ragingpony dot com>.
Patches and suggestions welcome.

=head1 LICENSE

Gtk2-Ex-DateEntry is Copyright 2009 Jeffrey Ray Hallock

Gtk2-Ex-DateEntry is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-DateEntry is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-DateEntry.  If not, see L<http://www.gnu.org/licenses/>.

=cut
