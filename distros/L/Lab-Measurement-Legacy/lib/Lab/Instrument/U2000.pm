package Lab::Instrument::U2000;
#ABSTRACT: Agilent U2000 series USB Power Sensor
$Lab::Instrument::U2000::VERSION = '3.899';
use v5.20;

use strict;
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => ['USBtmc'],

    connection_settings => {
        usb_vendor  => "0957",
        usb_product => "2a18"
    },

    device_settings => {
        frequency => 10e6,
    },

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);
    $self->clear();

    #TODO: Device clear
    $self->write("SYST:PRES");    # Load presets
    $self->{trigger_mode} = "AUTO";
    $self->{average_on}   = "1";
    return $self;
}

# template functions for inheriting classes

sub id {
    my $self = shift;
    return $self->query('*IDN?');
}

sub selftest {
    my $self = shift;
    return $self->query("*TST");
}

#TODO: EXT mode not tested
sub set_trigger {
    my $self = shift;
    my $type = shift || "AUTO";    #AUTO, BUS, INT, EXT, IMM
    my $args;
    if   ( ref $_[0] eq 'HASH' ) { $args = shift }
    else                         { $args = {@_} }
    my $delay = $args->{'delay'}; #AUTO, MIN, MAX, DEF, -0.15s to +0.15s
    my $level = $args->{'level'}; #DEF, MIN, MAX, sensor dependent range in dB
    my $hysteresis = $args->{'hysteresis'};    #DEF, MIN, MAX, 0 to 3dB
    my $holdoff    = $args->{'holdoff'};       #DEF, MIN, MAX, 1µs to 400ms
    my $slope      = $args->{'edge'};          #POS, NEG

    if ( $type eq "AUTO" ) {
        $self->write("INIT:CONT ON");
    }
    else {
        $self->write("INIT:CONT OFF");
    }

    if ( $self->{average_on} && ( $type eq "INT" || $type eq "EXT" ) ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Can't switch to internal or external trigger while average mode is on. Change mode using set_mode(\"NORM\"). Error in U2000::set_trigger(). \n"
        );
    }
    if ( $type eq "INT" || $type eq "EXT" || $type eq "IMM" ) {
        $self->write("TRIG:SOUR $type");
        $self->{trigger_mode} = $type;
    }
    elsif ( $type eq "BUS" ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "'BUS' trigger mode is not supported by this library in U2000::set_trigger()\n"
        );
    }
    elsif ( $type ne "AUTO" ) {
        Lab::Exception::CorruptParameter->throw(
            error => "Unknown trigger mode in HP34401A::set_trigger()\n" );
    }

    if ( defined($delay) ) {
        if ( $delay eq "AUTO" ) {
            $self->write("TRIG:DEL:AUTO ON");
        }
        else {
            $self->write("TRIG:DEL:AUTO OFF");
            $self->write("TRIG:DEL $delay");
        }
    }

    if ( defined($holdoff) ) {
        $self->write("TRIG:HOLD $holdoff");
    }

    if ( defined($level) ) {
        $self->write("TRIG:LEV $level");
    }

    if ( defined($hysteresis) ) {
        $self->write("TRIG:HYST $hysteresis");
    }

    if ( defined($slope) ) {
        $self->write("TRIG:SLOP $slope");
    }
}

sub set_power_unit {
    my $self = shift;
    my $unit = shift || "DBM";    #DBM, W
    $self->write("UNIT:POW $unit");
}

sub set_average {
    my $self = shift;
    my $count = shift || "AUTO";    #OFF, AUTO, DEF, MIN, MAX, 1 to 1024

    if ( $count eq "OFF" ) {
        $self->write("AVER OFF");
        $self->set_mode("NORM");
        return;
    }
    else {
        $self->write("AVER ON");
        $self->set_mode("AVER");
    }

    if ( $count eq "AUTO" ) {
        $self->write("AVER:COUN:AUTO ON");
    }
    else {
        #Automatic averaging is disabled by this command
        $self->write("AVER:COUN $count");
    }
}

sub set_mode {
    my $self = shift;
    my $mode = shift || "AVER";

    if ( $mode eq "AVER" ) {
        $self->{trigger_mode} = "AUTO";
    }
    elsif ( $mode eq "NORM" ) {
        if ( $self->{trigger_mode} eq "IMM" ) {
            $self->{trigger_mode} = "INT";
        }
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            error => "Unknown  mode in HP34401A::set_mode()\n" );
    }
    $self->{average_on} = $mode eq "AVER";
    $self->write("DET:FUNC $mode");
}

sub set_step_detect {
    my $self = shift;
    my $state = shift || "ON";    # ON, OFF
    $self->write("AVER:SDET $state");
}

sub set_frequency {
    my $self = shift;
    my $freq = shift || "DEF";    # DEF, MIN, MAX, 1kHz to 1000GHz
    $self->write("FREQ $freq");
}

sub set_sample_rate {
    my $self = shift;
    my $rate = shift || "NORM";    # MIN, MAX, NORM, DOUBLE, FAST, 1-110
    if ( $rate =~ /(NORM,DOUB, FAST)/ ) {
        $self->write("MRAT $rate");
    }
    elsif ( $rate eq "MIN" || $rate <= 20 ) {
        $self->write("MRAT NORM");
    }
    elsif ( $rate <= 40 ) {
        $self->write("MRAT DOUB");
    }
    elsif ( $rate eq "MAX" || $rate <= 110 ) {
        $self->write("MRAT FAST");
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "Unsuppoerted sample rate in HP34401A::set_sample_rate()\n" );
    }
}

#TODO: Device hangs after a read has timed out and a new read was
# issued during which the trigger condition is satisifed.
# (in INT trigger mode and possibly others as well)
sub read {
    my $self = shift;
    if ( $self->{trigger_mode} eq "AUTO" ) {

        #No trigger needed for AUTO MODE
        return $self->query("FETC?");
    }
    elsif ( $self->{trigger_mode} eq "IMM" ) {

        #Automatically send trigger for immediate mode
        return $self->query("READ?");
    }

    #TODO: Check other modes
    return $self->query("READ?");

}

sub get_error {
    my $self          = shift;
    my $current_error = "";
    my $all_errors    = "";
    my $max_errors    = 5;
    while ( $max_errors-- ) {
        $current_error = $self->query('SYST:ERR?');
        if ( $current_error eq "" ) {
            $all_errors .= "Could not read error message!\n";
            last;
        }
        if ( $current_error =~ m/^\+?0,/ ) { last; }
        $all_errors .= $current_error . "\n";
    }
    if ( !$max_errors ) { $all_errors .= "Maximum Error count reached!\n"; }
    $self->write("*CLS");    #Clear errors
    chomp($all_errors);
    return $all_errors;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::U2000 - Agilent U2000 series USB Power Sensor (deprecated)

=head1 VERSION

version 3.899

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

The Lab::Instrument::U2000 class implements an interface to the U2000 series
power sensors from Agilent.

=head1 CONSTRUCTOR

    my $power=new(\%options);

=head1 METHODS

=head2 get_value

    $value=$power->read();

Read out the current measurement value, for whatever type of measurement
the sensor is currently configured. Waits for trigger.

=head2 id

    $id=$power->id();

Returns the instruments ID string.

=head2 set_sample_rate
    $power->set_sample_rate(string);

Valid values are MIN, MAX, NORM, DOUBLE, FAST and 1-110 (rate in Hz).

=head2 set_step_detect
    $power->set_step_detect(string);

Valid values are ON and OFF.

=head2 set_frequency
    $power->set_frequency(string or number)

Sets frequency for internal frequency correction (in Hz).
Valid values are DEF, MIN, MAX and 1kHz to 1000GHz.

=head1 CAVEATS/BUGS

Sometimes the sensor hangs for a short amount of time. Very seldom it 
completely stops working. This is probably either a bug in the firmware or
in the kernel driver as not even a reset of the USB port reenable communication.

Error handling needs to be improved. Neither timeouts nor errors are handled correctly.
Error reporting from the kernel driver is bad.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Hermann Kraus
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
