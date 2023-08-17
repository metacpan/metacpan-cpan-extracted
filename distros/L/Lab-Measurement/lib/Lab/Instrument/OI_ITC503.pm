package Lab::Instrument::OI_ITC503;
#ABSTRACT: Oxford Instruments ITC503 Intelligent Temperature Control
$Lab::Instrument::OI_ITC503::VERSION = '3.881';
use v5.20;

use strict;
use feature "switch";
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

our %fields = (
    auto_pid              => 1,
    supported_connections => [ 'IsoBus', 'LinuxGPIB', 'VISA_GPIB' ],

    connection_settings => {},
    device_settings     => {
        t_sensor => 3,
    },
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);
    printf "The ITC driver is work in progress. You have been warned.\n";
    $self->device_settings()->{t_sensor} = 3;

    if ( $self->auto_pid() ) {
        $self->itc_set_PID_auto(1);
    }

    return $self;
}

sub _device_init {
    my $self = shift;

    # Dont clear the instrument since that may make it unresponsive.
    # Instead, set the communication protocol to "Normal", which should
    # also clear all communication buffers.
    $self->connection()->SetTermChar( chr(13) );
    $self->connection()->EnableTermChar(1);
    $self->write("Q0\r");

    $self->set_control(3)
        ;    # Enable remote control, but leave the front panel unlocked
}

#
# evaluate a command response for error conditions (leading '?', check for correct command character if supplied)
#
sub parse_error {
    my $self       = shift;
    my $device_msg = shift;
    my $cmd        = shift;
    my $cmd_char   = defined $cmd ? substr( $cmd, 0, 1 ) : undef;

    my $status_char = substr( $device_msg, 0, 1 );
    if ( $status_char eq '?' ) {
        Lab::Exception::DeviceError->throw(
            error =>
                "ITC503 returned error '$device_msg' on command '$cmd'\n",
            device_class => ref $self,
            command      => $cmd,
            raw_message  => $device_msg
        );
    }
    elsif ( defined $cmd_char && $status_char ne $cmd_char ) {
        Lab::Exception::DeviceError->throw(
            error =>
                "Received an unexpected answer from ITC503. Expected '$cmd_char' prefix, received '$status_char' on command '$cmd'\n",
            device_class => ref $self,
            command      => $cmd,
            raw_message  => $device_msg
        );
    }
}

#
# query wrapper with error checking for the ITC
#
sub query {
    my $self = shift;
    my $cmd  = shift;

    # ITC query answers always start with the command character if successful with a question mark and the command char on failure
    my $cmd_char = substr( $cmd, 0, 1 );

    my $result = $self->SUPER::query( $cmd, @_ );

    $self->parse_error( $result, $cmd );
    chomp $result;

    return substr( $result, 1 );
}

# old remark, relevance?
# don't use it if you get an error message during reading out sensors:"Cading Sensor"
# device modes:
# 0 Local & Locked front panel
# 1 Remote & Locked panel
# 2 Local & Unlocked panel
# 3 Remote & Unlocked panel
sub set_control {
    my $self = shift;
    my $mode = shift;

    $mode =~ /^\s*(0|1|2|3)\s*$/ ? $mode
        = $1
        : $mode =~ /^\s*(locked)\s*$/ ? $mode
        = 1
        : $mode =~ /^\s*(unlocked)\s*$/ ? $mode
        = 3
        : Lab::Exception::CorruptParameter->throw(
        "Invalid control mode specified.");

    my $result = $self->query( "C${mode}\r", @_ );
    sleep(1);

}

sub itc_set_communications_protocol {

    # 0 "Normal" (default)
    # 2 Sends <LF> after each <CR>
    my $self = shift;
    my $mode = shift;
    $self->write("Q$mode\r");
}

sub set_T {
    my $self     = shift;
    my $temp     = shift;
    my $t_sensor = $self->device_settings()->{t_sensor};
    $DB::single = 1;

    if ( $temp < 1.5 && $t_sensor == 3 ) {
        $t_sensor = 2;
    }
    elsif ( $temp >= 1.5 && $t_sensor == 2 ) {
        $t_sensor = 3;
    }

    $self->itc_set_heater_auto(0);
    $self->itc_set_heater_sensor($t_sensor);
    $self->itc_set_heater_auto(1);
    $self->itc_T_set_point($temp);

    printf "Set temperature $temp with sensor $t_sensor.\n";
    $self->device_settings()->{t_sensor} = $t_sensor;

}

sub get_value {
    my $self     = shift;
    my $t_sensor = $self->device_settings()->{t_sensor};

    my $temp = $self->itc_read_parameter($t_sensor);
    $temp = $self->itc_read_parameter($t_sensor);
    $temp = $self->itc_read_parameter($t_sensor);

    if ( $temp < 1.5 && $t_sensor == 3 ) {
        $t_sensor = 2;
        $temp     = $self->itc_read_parameter($t_sensor);
        $temp     = $self->itc_read_parameter($t_sensor);
        $temp     = $self->itc_read_parameter($t_sensor);
        printf "Switching to sensor $t_sensor at temperature $temp\n";
    }
    elsif ( $temp >= 1.5 && $t_sensor == 2 ) {
        $t_sensor = 3;
        $temp     = $self->itc_read_parameter($t_sensor);
        $temp     = $self->itc_read_parameter($t_sensor);
        $temp     = $self->itc_read_parameter($t_sensor);
        printf "Switching to sensor $t_sensor at temperature $temp\n";
    }

    printf "Read temperature $temp with sensor $t_sensor.\n";

    $self->device_settings()->{t_sensor} = $t_sensor;

    return $temp;

}

sub itc_read_parameter {

    # 0 Demand SET TEMPERATURE     K
    # 1 Sensor 1 Temperature     K
    # 2 Sensor 2 Temperature     K
    # 3 Sensor 3 Temperature     K
    # 4 Temperature Error (+ve when SET>Measured)
    # 5 Heater O/P (as % of current limit)
    # 6 Heater O/P (as Volts, approx)
    # 7 Gas Flow O/P (arbitratry units)
    # 8 Proportional Band
    # 9 Integral Action Time
    #10 Derivative Actionb Time
    #11 Channel 1 Freq/4
    #12 Channel 2 Freq/4
    #13 Channel 3 Freq/4

    my $self      = shift;
    my $parameter = shift;
    my $cmd       = "R$parameter\r";
    my $result    = $self->query( $cmd, @_ );

    return sprintf( "%e", $result );
}

sub itc_set_wait {

    # delay before each character is sent
    # in millisecond
    my $self = shift;
    my $wait = shift;
    $wait = sprintf( "%d", $wait );
    $self->query("W$wait\r");
}

sub itc_examine {

    # Examine Status
    my $self = shift;
    $self->query("X\r");
}

sub set_heatercontrol {
    my $self = shift;
    my $mode = shift;

    if ( $mode == 'MAN' ) {
        $self->itc_set_heater_auto(0);
    }
    elsif ( $mode == 'AUTO' ) {
        $self->itc_set_heater_auto(1);
    }
    else {
        printf "set_heatercontrol received an invalid parameter: $mode";
    }

}

sub itc_set_heater_auto {

    # 0 Heater Manual, Gas Manual;
    # 1 Heater Auto, Gas Manual
    # 2 Heater Manual, Gas Auto
    # 3 Heater Auto, Gas Auto
    my $self = shift;
    my $mode = shift;
    $mode = sprintf( "%d", $mode );
    return $self->query("A$mode\r");
}

sub set_PID {
    my $self = shift;
    my $p    = shift;
    my $i    = shift;
    my $d    = shift;

    $self->itc_set_proportional_value($p);
    $self->itc_set_integral_value($i);
    $self->itc_set_derivative_value($d);
}

sub itc_set_proportional_value {
    my $self  = shift;
    my $value = shift;

    $self->itc_set_PID_auto(0);
    $value = sprintf( "%d", $value );
    $self->query("P$value\r");
}

sub itc_set_integral_value {
    my $self  = shift;
    my $value = shift;

    $self->itc_set_PID_auto(0);
    $value = sprintf( "%d", $value );
    $self->query("I$value\r");
}

sub itc_set_derivative_value {
    my $self  = shift;
    my $value = shift;

    $self->itc_set_PID_auto(0);
    $value = sprintf( "%d", $value );
    $self->query("D$value\r");
}

sub itc_set_heater_sensor {

    # 1 Sensor 1
    # 2 Sensor 2
    # 3 Sensor 3
    my $self  = shift;
    my $value = shift;
    $value = sprintf( "%d", $value );
    return $self->query("H$value\r");
}

sub itc_set_PID_auto {

    # 0 PID Auto Off
    # 1 PID on
    my $self  = shift;
    my $value = shift;
    $value = sprintf( "%d", $value );
    $self->query("L$value\r");
}

sub itc_set_max_heater_voltage {

    # in 0.1 V
    # 0 dynamical varying limit
    my $self  = shift;
    my $value = shift;
    $value = sprintf( "%d", $value );
    $self->query("M$value\r");
}

sub itc_set_heater_output {

    # from 0 to 0.999
    # 0 dynamical varying limit
    my $self  = shift;
    my $value = shift;
    $value = sprintf( "%d", 1000 * $value );
    $self->query("O$value\r");
}

sub itc_T_set_point {

    #  Setpoint
    my $self  = shift;
    my $value = shift;
    $value = sprintf( "%.3f", $value );
    return $self->query("T$value\r");
}

sub itc_sweep {

    # 0 Stop Sweep
    # 1 Start Sweep
    #nn=2P-1 Sweeping to step P
    #nn=2P Sweeping to step P
    my $self  = shift;
    my $value = shift;
    $value = sprintf( "%d", $value );
    $self->query("S$value\r");
}

sub itc_set_pointer {

    # Sets Pointer in internal ITC memory
    my $self = shift;
    my $x    = shift;
    my $y    = shift;
    if ( $x < 0 or $x > 128 ) {
        printf "x=$x no valid ITC Pointer value\n";
        die;
    }
    if ( $y < 0 or $y > 128 ) {
        printf "y=$y no valid ITC Pointer value\n";
        die;
    }
    my $cmd = sprintf( "x%d\r", $x );
    $self->query($cmd);
    $cmd = sprintf( "y%d\r", $y );
    $self->query($cmd);
}

sub itc_program_sweep_table {
    my $self      = shift;
    my $setpoint  = shift;    #K Sweep Stop Point
    my $sweeptime = shift;    #Min. Total Sweep Time
    my $holdtime  = shift;    #sec. Hold Time

    if ( $setpoint < 0. or $setpoint > 9.9 ) {
        printf "Cannot reach setpoint: $setpoint\n";
        die;
    }

    $self->itc_set_pointer( 1, 1 );
    $setpoint = sprintf( "%1.4f", $setpoint );
    $self->query("s$setpoint\r");

    $self->itc_set_pointer( 1, 2 );
    $sweeptime = sprintf( "%.4f", $sweeptime );
    $self->query("s$sweeptime\r");

    $self->itc_set_pointer( 1, 3 );
    $holdtime = sprintf( "%.4f", $holdtime );
    $self->query("s$holdtime\r");

    $self->itc_set_pointer( 0, 0 );
}

sub itc_read_sweep_table {

    # Clears Sweep Program Table
    my $self = shift;
    $self->query("r\r");
}

sub itc_clear_sweep_table {

    # Clears Sweep Program Table
    my $self = shift;
    $self->query("w\r");
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::OI_ITC503 - Oxford Instruments ITC503 Intelligent Temperature Control

=head1 VERSION

version 3.881

=head1 SYNOPSIS

    use Lab::Instrument::OI_ITC503;
    
    my $itc=new Lab::Instrument::OI_ITC503(
	isobus_address=>3,
    );

=head1 DESCRIPTION

The Lab::Instrument::OI_ITC503 class implements an interface to the Oxford Instruments 
ITC intelligent temperature controller (tested with the ITC503). This driver is still
work in progress and also lacks documentation.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011-2012  Andreas K. Huettel, Florian Olbrich
            2013       Andreas K. Huettel
            2015       Alois Dirnaichner
            2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
