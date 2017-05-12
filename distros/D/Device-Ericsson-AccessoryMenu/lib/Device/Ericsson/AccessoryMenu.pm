use strict;
package Device::Ericsson::AccessoryMenu;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw( states menu port debug callback ) );
use vars qw( $VERSION );
$VERSION = '0.8';

=head1 NAME

Device::Ericsson::AccessoryMenu - allows use of a T68i as a remote control

=head1 SYNOPSIS

 my $remote = Device::Ericsson::AccessoryMenu->new;
 $remote->menu( [ 'Remote' => [ pause  => sub { ... },
                                Volume => [ up   => sub { ... },
                                            down => sub { ... },
                                          ],
                              ],
                ] );

 # on Win32, Win32::SerialPort should be equivalent
 my $port = Device::SerialPort->new('/dev/rfcomm0')
    or die "couldn't connect to T68i";
 $remote->port( $port );

 $remote->register_menu;

 while (1) {
     $remote->control;
 }

=head1 DESCRIPTION

Device::Ericsson::AccessoryMenu provides a framework for adding an
accessory menu to devices that obey the EAM set of AT commands.

This allows you to write programs with similar function to the Romeo
and Clicker applications for OSX, only instead of applescript your
actions invoke perl subroutines (which of course may invoke
applescript events, if that's your desire).

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    $class->SUPER::new({ menu => [], @_ });
}

=head2 menu

your menus and actions.

If your action is a subroutine, it will be invoked with the
Device::Ericsson::AccesoryMenu object as its first parameter.

If the action returns a scalar, this is sent on to the phone via
C<send_text>

If your action is, or returns an array reference, then it's taken as a
sub menu.

=head2 port

The serial port to communicate over.

This may be real serial port, or a bluetooth RFCOMM device, just so
long as it looks like a Device::SerialPort or Win32::SerialPort.

=head2 send( $what )

send bytes over the serial port to the phone

=cut

sub send {
    my $self = shift;
    my $what = shift;
    my $count = $self->port->write( "$what\r" );
    $self->port->write_drain;
    print "# send '$what'\n" if $self->debug;
    return $count == length $what;
}


# Lifted from Device::Modem
sub expect {
    my $self = shift;
    my ($expect, $timeout) = @_;

    $timeout ||= 2000;

    my $time_slice = 100;                       # single cycle wait time
    $time_slice = 20 if $timeout < 200;
    my $max_cycles = $timeout / $time_slice;
    my $max_idle_cycles = $max_cycles;

    # If we expect something, we must first match against serial input
    my $done;# = (defined $expect and $expect eq '');

    # Main read cycle
    my ($answer, $cycles, $idle_cycles);
    do {
        my ($howmany, $what) = $self->port->read($time_slice);

        # Timeout count incremented only on empty readings
        if ( defined $what && $howmany > 0 ) {
            $answer .= $what;
            $idle_cycles = 1;
            #$max_idle_cycles = $max_cycles;
        }
        else {
            ++$idle_cycles;
        }

        ++$done if $expect && $answer && $answer =~ $expect;
        ++$done if $idle_cycles >= $max_idle_cycles;
        ++$done if ++$cycles >= $max_cycles;
        select(undef, undef, undef, $time_slice/1000) unless $done;
    } while ( not $done );

    # Flush receive and trasmit buffers
    $self->port->purge_all;

    # Trim result of beginning and ending CR+LF (XXX)
    if( defined $answer ) {
        $answer =~ s/^[\r\n]+//;
        $answer =~ s/[\r\n]+$//;
    }

    print "# got '$answer'\n" if $self->debug && defined $answer;
    return $answer;
}


=head2 register_menu

Notify the phone that there's an accessory connected

=cut

sub register_menu {
    my $self = shift;

    $self->states( [] );

    # Phone, Kree!
    $self->send( "ATZ" );
    $self->expect( "OK", 5000 );
    # turn off echo
    $self->send( "ATE=0" );
    $self->expect( "OK" );
    $self->send( 'AT*EAM="'. $self->menu->[0] . '"' );
    $self->expect( "OK" );
    $self->send( 'AT+CSCS="8859-1"' );
    $self->expect( "OK" );

}

sub enter_state {
    my $self = shift;
    my $class = shift;

    $class = __PACKAGE__."::$class";
    eval "require $class" or die $@;

    my $entering =  $class->new( parent => $self, @_ );
    unshift @{ $self->states }, $entering;

    print "entering $entering\n" if $self->debug;
    $entering->on_enter;
    return;
}

sub exit_state {
    my $self = shift;

    my $leaving = shift @{ $self->states };
    print "leaving $leaving\n" if $self->debug;
    $leaving->on_exit;
    my ($current) = @{ $self->states };
    $current->on_enter if $current;
    return;
}

sub current_state {
    my $self = shift;
    my ($state) = @{ $self->states };
    return $state;
}


=head2 send_text( $title, @lines )

Send the text as a message dialog and wait for user input.

=cut

sub send_text {
    my $self = shift;
    my $title = shift;
    @_ = ($title) unless @_;

    $self->enter_state( 'Text', title => $title, lines => \@_ );
}


=head2 percent_slider( %args )

 %args = (
    title    => 'Slider',
    steps    => 10,    # 1..10
    value    => 50,
    callback => undef, # a subroutine ref, will be called with the new value
 );

=cut

sub percent_slider {
    my $self = shift;
    my %args = @_;

    my $value = defined $args{value} ? $args{value}: 50;
    $self->enter_state( 'Slider', ( title => $args{title} || 'Slider',
                                    steps => $args{steps}  || 10,
                                    value => $value,
                                    callback => $args{callback} ) );
}

=head2 mouse_mode( %args )

Put the T68i into a fullscan mode.  Returns keyboard events for every
key pressed and released.

 %args = (
    title    => 'Mouse',
    callback => sub ( $key, $updown ) {}, # will be called with the key and
                                          # the updown event (1 = key
                                          # down, 0 = key up)

 );

=cut

sub mouse_mode {
    my $self = shift;
    my %args = @_;

    $self->enter_state( 'Mouse', ( title => $args{title} || 'Mouse',
                                   callback => $args{callback} ) );
}


=head2 control

Respond to what the phone is sending back over the port, invoking
callbacks and all that jazz.

=cut

sub control {
    my $self = shift;
    my ($timeout) = @_;

    # $self->port->modemlines; may be the key to 'it's attached, it's
    # not attached' stuff

    my $line = $self->expect("\r", $timeout);
    return unless $line;

    print "# control '$line'\n" if $self->debug;

    if ( my $state = $self->current_state ) {
        $state->handle( $line );
        return;
    }

    if ($line =~ /EAAI/) { # top level menu
        $self->enter_state( 'Menu', data => $self->menu );
        return;
    }

    warn "control got unexpected '$line'\n";
}

1;
__END__

=head1 CAVEATS

I have only tested this with a T68i, and with Device::SerialPort.
I've consulted the R320 command set, and this seems portable across
Ericsson devices, but only time will tell.  Feedback welcome.

=head1 TODO

Convenience methods for other C<EAID> values, like the percent input
dialog.

Disconnection (and reconnection) detection.  For a straight serial
port this isn't really much of a win, but for bluetooth devices it'd
be nifty to do a "they've entered/exited the zone" check.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

Based on the source of bluexmms by Tom Gilbert.

=head1 COPYRIGHT

Copyright (C) 2003, Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<bluexmms|http://www.linuxbrit.net/bluexmms/>,
L<Romeo|http://www.irowan.com/arboreal/>, L<Device::SerialPort>

=cut
