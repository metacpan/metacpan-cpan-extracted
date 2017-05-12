package GappX::Gtk2::SSNEntry;
{
  $GappX::Gtk2::SSNEntry::VERSION = '0.02';
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
        $self->set_value($newval);
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
    carp 'usage $date_entry->set_value($new_value)' unless @_ == 2;
    my $self = shift;
    my $newval = shift;
    
    
    # parse the new value if defined
    if (defined $newval) {
        $newval = $self->_parse_input($newval);
    }
    my $oldval = $self->get_value;
    
    if (! defined $oldval && ! defined $newval) {
        $self->_display_output;
    }
    elsif (! defined $oldval && defined $newval ||
           ! defined $newval && defined $oldval ||
           $oldval ne $newval) {
        $self->{value} = $newval;
        $self->signal_emit('value-changed');
    }
    else {
        $self->_display_output;
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
    
    # enter pressed, parse input
    if ($key_val == 65293) {
        $self->set_value($self->get_text);
        return FALSE;
    }
    # arrow key pressed
    elsif ($key_val == 65361 || $key_val == 65363) {
        $self->set_value($self->get_text);
        return $self->_do_key_left  if $key_val == 65361;
        return $self->_do_key_right if $key_val == 65363;
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
        my $pos = $self->get_position;
        if ($pos == 4) {
            $self->set_selected_component(0);
        }
        elsif ($pos == 7) {
            $self->set_selected_component(1);
        }
        else {
            return FALSE;
        }
    }
    else {
        if    ($selected eq 'all'  ) { $self->set_selected_component(2)  }
        elsif ($selected == 0 ) { return FALSE;                    }
        elsif ($selected == 1 ) { $self->set_selected_component(0) }
        elsif ($selected == 2 ) { $self->set_selected_component(1) }
    }
    
    return TRUE;
}

sub _do_key_right {
    my $self = shift;
    my $selected = $self->get_selected_component;
    
    if (! $selected) {
        my $pos = $self->get_position;
        if ($pos == 3) {
            $self->set_selected_component(1);
        }
        elsif ($pos == 6) {
            $self->set_selected_component(2);
        }
        else {
            return FALSE;
        }
    }
    else {
        if    ($selected eq 'all'  ) { $self->set_selected_component(0) }
        elsif ($selected == 0 ) { $self->set_selected_component(1)   }
        elsif ($selected == 1 ) { $self->set_selected_component(2)  }
        elsif ($selected == 2 ) { return FALSE;   }  
    }

    return TRUE;
}

{
    my %pos = (
        0 => [0,3],
        1 => [4,6],
        2 => [7,11],
      all => [0,11],
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


sub _parse_input {
    my $self  = shift;
    my $value = shift || '';
    $value =~ s/\D//g;
    return undef if ! defined $value || $value eq '';
    return $value;
}

sub _display_output {
    my $self  = shift;
    my $value = $self->get_value;
    
    no warnings;
    my @parts = (
        substr($value,0,3),
        substr($value,3,2),
        substr($value,5,4)
    );
    use warnings;
    
    my $output = $value ? sprintf ('%03d-%02d-%04d', @parts) : '';
    $self->set_text($output);
}


1;


__END__

=head1 NAME

GappX::Gtk2::SSNEntry - Gtk2 widget for entering social security numbers

=head1 SYNOPSIS

  use GappX::Gtk2::SSNEntry;

  $w = GappX::Gtk2::SSNEntry->new( value => 0123456789 );

  $w->get_value;

=head1 WIDGET HIERARCHY

=over 4

=item Gtk2::Widget

=item +-- Gtk2::Entry

=item ....+-- GappX::Gtk2::SSNEntry

=head1 DESCRIPTION

GappX::Gtk2::SSNEntry displays and edits a social security number.

Navigate between the three components of a social security number using the
left and right arrow keys. The value of the widget will be stored internally
as a 9 character string consisting only of digits (i.e. "0123456789"). However,
the text that is displayed in the widget will be displayed with hyphens between
the components (i.e. "012-345-6789").

=head1 PROPERTIES

=over 4

=item B<value>

The value of the widget. 

=back

=head1 PROVIDED METHODS

=over 4

=item B<new>

Create and return a new SSN Entry widget. 

=item B<get_selected_component>

Returns the currently selected component - any of 0, 1, or 2;
An emptry string will be returned if the selection bounds contains more or less
than 1 individual component, and will return 'all' if all components are
selected.

=item B<set_selected_component $component>

Highlights the given component, which can then be edited by typing over it.
You can pass the values C<0>, C<1>, C<2>, C<all>, C<none>, or C<undef>.

=item B<get_value>

Return the internal value of the widget.

=item B<set_value $value>

Set the internal value of the widget.

=back

=head1 SIGNALS

=over 4

=item C<value-changed>

Emitted after a succesful value change.

=back

=head1 SEE ALSO

=over

=item L<GappX::SSNEntry>

=item L<Gapp>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
