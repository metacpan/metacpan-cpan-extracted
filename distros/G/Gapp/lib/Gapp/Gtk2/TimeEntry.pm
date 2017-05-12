package Gapp::Gtk2::TimeEntry;
{
  $Gapp::Gtk2::TimeEntry::VERSION = '0.60';
}
use strict;
use warnings;
use Carp;

use Gtk2;

use Glib qw(TRUE FALSE);

use Glib::Object::Subclass
    Gtk2::Entry::,
    interfaces  => [ 'Gtk2::CellEditable' ],
    properties  => [
        Glib::ParamSpec->string(
            'value'                                  ,
            'value'                                  ,
            'ISO format time string like 13:00'      ,
            ''                                       , #default value
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
        $newval = $self->_parse_input($newval);
        # set the new value if it is different
        if (!defined $self->{$pname} && defined $newval || $self->{$pname} ne $newval) {
            $self->{$pname} = $newval;
            $self->signal_emit('value-changed');
        }
        else {
            # update the display
            $self->set_text($self->_format_output($self->get_value));
        }
    }
    else {
        $self->{$pname} = $newval;
    }
}

sub get_value {
    my $self = shift;
    $self->get('value');
}

sub set_value {
    my $self = shift;
    my $new_value = shift;
    $self->set('value', $new_value);
}

sub set_now {
    my $self = shift;
    my ($hour, $minute) = (localtime time)[2,1];
    
    my $value = sprintf '%02d:%02d', $hour, $minute;
    
    $self->set_value( $value );
}

sub _do_value_changed {
    my $self = shift;
    my $value = $self->get_value;
    $self->set_text($self->_format_output($self->get_value));
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
        if    ($selected eq 'all'     ) { $self->set_selected_component('meridiem')}
        elsif ($selected eq 'hours'   ) { return FALSE;                            }
        elsif ($selected eq 'minutes' ) { $self->set_selected_component('hours')   }
        elsif ($selected eq 'meridiem') { $self->set_selected_component('minutes') }
        return TRUE;
    }
}

sub _do_key_right {
    my $self = shift;
    my $selected = $self->get_selected_component;
    $self->_select_closest_component('right') and return TRUE if !$selected;

    if (! $selected) {
        return FALSE if $self->get_position == 0;
        $self->_select_closest_component('left');
        return TRUE;
    }
    else {
        if    ($selected eq 'all'     ) { $self->set_selected_component('hours')    }
        elsif ($selected eq 'hours'   ) { $self->set_selected_component('minutes')  }
        elsif ($selected eq 'minutes' ) { $self->set_selected_component('meridiem') }
        elsif ($selected eq 'meridiem') { return FALSE;  }
        return TRUE;
    }
}

sub _do_key_up {
    my $self = shift;
    my $selected = $self->get_selected_component;
    $self->_select_closest_component('up') and return TRUE unless $selected;
    
    my ($hours, $minutes) = split /:/, $self->get_value;
    
    if ($selected eq 'hours') {
        $hours++;
    }
    elsif ($selected eq 'minutes') {
        $minutes++;
    }
    elsif ($selected eq 'meridiem') {
        $hours+=12;
    }
    elsif ($selected eq 'all') {
        $minutes+=15;
    }
    
    my $new_value = join ':', $hours, $minutes;
    $self->set_value($new_value);
    $self->set_selected_component($selected);
    
    return TRUE;
}

sub _do_key_down {
    my $self = shift;
    my $selected = $self->get_selected_component;
    $self->_select_closest_component('down') and return TRUE unless $selected;
    
    my ($hours, $minutes, $seconds) = split /:/, $self->get_value;
    
    if ($selected eq 'hours') {
        $hours--;
    }
    elsif ($selected eq 'minutes') {
        $minutes--;
    }
    elsif ($selected eq 'meridiem') {
        $hours-=12;
    }
    elsif ($selected eq 'all') {
        $minutes-=15;
    }

    if ($minutes < 0) {        
        # get the absolute value
        my $absolute_minutes = $minutes * -1;
        
        # hours to subtract
        my $delta_hours = int ($absolute_minutes / 60) + 1;
        $hours -= $delta_hours;
        
        # minutes to subtract (from 60)
        my $delta_minutes = $absolute_minutes % 60;
        $minutes = 60 - $delta_minutes;
    }
    if ($hours < 0) {
        # get the absolute value
        my $absolute_hours = $hours * -1;
        my $delta_hours = $absolute_hours % 24;
        $hours = 24 - $delta_hours;
    }
    
    my $new_value = sprintf '%02d:%02d', $hours, $minutes;
    $self->set_value($new_value);
    $self->set_selected_component($selected);
    return TRUE;
}

sub _format_output {
    my $self  = shift;
    my $value = shift;
    
    # throw exception unless passed a time in a valid format
    carp  q[Usage is $self->_format_output($value) where ] .
          q[$value is a valid time in the format HH:MM:SS: ] .
         qq[you supplied ($value)]
         unless defined $value && $value !~ /^\d\d:\d\d:\s\s$/;
    
    # return empty string if no value
    return '' if $value eq '';
    
    # format the value if there is one
    my ($hours, $minutes, $seconds) = split /:/, $value;
    my $ampm;
    
    if ($hours == 0) {
        $hours = 12;
        $ampm  = 'AM';
    }
    elsif ($hours == 12) {
        $ampm = 'PM';
    }
    elsif ($hours > 12) {
        $hours -= 12;
        $ampm = 'PM';
    }
    else {
        $ampm = 'AM';
    }
    
    
    return sprintf qq[%02d:%02d $ampm], $hours, $minutes;

}

sub get_selected_component {
    my $self = shift;
    
    my ($select_start, $select_end) = $self->get_selection_bounds;
    $select_start = 0 unless $select_start;
    $select_end = 0 unless $select_end;
    
    my $selected = $select_end - $select_start;
    return unless $selected == 2 || 8;
    
    if ($select_start == 0 && $select_end == 2) {
        return 'hours';
    }
    elsif ($select_start == 3 && $select_end == 5) {
        return 'minutes';
    }
    elsif ($select_start == 6 && $select_end == 8) {
        return 'meridiem';
    }
    elsif ($select_start == 0 && $select_end == 8) {
        return 'all';
    }
    else {
        return undef;
    }
}

sub set_selected_component {
    my $self = shift;
    my $field = shift;
    
    # throw exception if $field var is not valid
    confess  q[Usage is $self->set_selected_component($field) where field is one of ] .
             q[hours, minutes, ampm, meridiem, all, or an empty string: ] .
            qq[you supplied($field)]
            and return unless $field =~ /(hours|minutes|ampm|meridiem|all|none)/
            || $field eq '';
    
    if ($field eq 'hours') {
        $self->select_region(0,2);
    }
    elsif ($field eq 'minutes') {
        $self->select_region(3,5);
    }
    elsif ($field =~ /ampm|meridiem/) {
        $self->select_region(6,8);
    }
    elsif ($field eq 'all') {
        $self->select_region(0,8);
    }
    elsif ($field eq 'none' || $field eq '') {
        $self->select_region(0,0);
    }
    else {
        confess qq[Invalid argument passed: $field];
    }
}

sub _select_closest_component {
    my $self      = shift;
    my $direction = shift;
    my $cursor = $self->get_position;
    
    if ($cursor == 0 || $cursor == 1) {
        $self->set_selected_component('hours');
    }
    elsif ($cursor == 2 && $direction ne 'right') {
        $self->set_selected_component('hours');
    }
    elsif ($cursor == 2 && $direction eq 'right') {
        $self->set_selected_component('minutes');
    }
    elsif ($cursor == 3 && $direction eq 'left') {
        $self->set_selected_component('hours');
    }
    elsif ($cursor == 3 && $direction ne 'left') {
        $self->set_selected_component('minutes');
    }
    elsif ($cursor == 4) {
        $self->set_selected_component('minutes');
    }
    elsif ($cursor == 5 && $direction ne 'right') {
        $self->set_selected_component('minutes');
    }
    elsif ($cursor == 5 && $direction eq 'right') {
        $self->set_selected_component('meridiem');
    }
    elsif ($cursor == 6 && $direction eq 'left') {
        $self->set_selected_component('minutes');
    }
    elsif ($cursor == 6 && $direction ne 'left') {
        $self->set_selected_component('meridiem');
    }
    elsif ($cursor == 7 || $cursor == 8) {
        $self->set_selected_component('meridiem');
    }
    
    return TRUE;
}

sub _parse_input {
    my $self  = shift;
    my $value = shift || '';
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return '' unless $value;
    
    my ($h, $m, $s);
    if ($value =~ /^(\d{1,2})$/) {
        $h = $1;
        $m = 0;
        $s = 0;
    }
    elsif ($value =~ /^([012]?[0-9]):?([0-5][0-9]):?([0-5][0-9])?$/) {
        $h = $1;
        $m = $2;
        $s = $3 || 0;
    }
    elsif ($value =~ /^([012]?[0-9]):?([0-9][0-9])?\s*(am|pm)?$/i) {
        $h = $1;
        $m = $2 || 0;
        $s = 0;
        $h -= 12 if $h == 12 && lc $3 eq 'am';
        $h += 12 if $h <12 && lc $3 eq 'pm';
    }
    elsif ($value eq '') {
        return '';
    }
    else {
        return $self->get_value;
    }
    
    if ($s > 59) {
        $m++;
        $s = $s % 60;
    }
    
    if ($m > 59) {
        $h++;
        $m = $m % 60;
    }
    
    # roll over 24 hours to the eqivelent time
    if ($h >= 24) {
        $h -= int($h / 24) * 24;
    }
    
    my $parsed = sprintf '%02d:%02d:%02d', $h, $m, $s;
    return $parsed;
}


1;


__END__

=head1 NAME

Gapp::Gtk2::TimeEntry -- Widget for entering times

=head1 SYNOPSIS

 use Gapp::Gtk2::TimeEntry;
 $te = Gapp::Gtk2::TimeEntry->new (value => '13:00:00');
 $te->set_value('1pm');
 $te->get_value;

=head1 WIDGET HIERARCHY

    Gtk2::Widget
      Gtk2::Entry
        Gapp::Gtk2::TimeEntry

=head1 DESCRIPTION

C<Gapp::Gtk2::TimeEntry> displays and edits a time in HH::MM PM format with some
convienence functions.

Use the up and down keys to modify the invidual components of the value, and the
left and right keys to navigate between them. Pressing up or down while the
entire contents of the entry is selected (such as when you focus-in) modifies
the value in 15 minute increments.

The time is stored in HH:MM:SS format (but displayed in HH:MM PM format). If you
enter a value 24:00:00 or higher, it will loop back around.

You can also type a time into the entry in various formats, which will be
parsed and then displayed in the entry in HH:MM PM format. Here are some
examples of things you can enter into the widget and the resulting internal and
display values.

=over 4

    INPUT       VALUE       DISPLAY
    1           01:00:00    01:00 AM
    10          10:00:00    10:00 AM
    120         01:20:00    01:20 AM
    1:20        01:20:00    01:20 AM
    120pm       13:20:00    01:20 PM
    01:20 PM    13:20:00    01:20 PM
    30:20:00    04:20:00    04:20 AM

=back 4

=head1 FUNCTIONS

=over 4

=item C<< $te = Gapp::Gtk2::TimeEntry->new (key=>value,...) >>

Create and return a new TimeEntry widget.  Optional key/value pairs set
initial properties per C<< Glib::Object->new >>.  Eg.

    my $te = Gapp::Gtk2::TimeEntry->new (value => '16:00:00');

=item C<< $te->get_selected_component >>

Returns the name of the currently selected component.  Valid values are
I<hours, minutes, meridiem,> and I<all>. An emptry string will be returned if
the selection bounds contains less than 1 individual component, or more than 1
component but less than all of them.

=item C<< $te->set_selected_component($component) >>

Highlights the given component, which can then be edited by typing over it or
pressing the arrow keys up or down. Acceptable values are I<hours, minutes,
meridiem,> and I<all>.

=item C<< $te->set_now >>

Set the widget value to the current time. 

=back

=head1 PROPERTIES

=over 4

=item C<value (string, default '')>

The current time format in HH:MM:SS format. Can be set to an empty string
for no time. When setting the value you, you may pass any acceptable value
outlined in the widget description, but the time will always be stored in
HH:MM:SS format.

=back

=head1 SIGNALS

=over 4

=item C<value-changed>

Emitted after a succesful value change.

=back

=head1 SEE ALSO

L<Gapp::Gtk2::DateEntry>

=head1 AUTHOR

Jeffrey Ray Hallock <jeffrey.ray at ragingpony dot com>

=head1 BUGS

None known. Please send bugs to <jeffrey.ray at ragingpony dot com>.
Patches and suggestions welcome.

=head1 LICENSE

Gapp-Gtk2-TimeEntry is Copyright 2009 Jeffrey Hallock

Gapp-Gtk2-TimeEntry is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gapp-Gtk2-TimeEntry is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gapp-Gtk2-TimeEntry.  If not, see L<http://www.gnu.org/licenses/>.

=cut
