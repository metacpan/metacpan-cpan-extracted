package Lab::Moose::Instrument::ABB_TRMC2;
$Lab::Moose::Instrument::ABB_TRMC2::VERSION = '3.930';
#ABSTRACT: ABB TRMC2 temperature controller

use v5.20;

use Moose;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;

carp "The ABB_TRMC2 driver is untested so far. Feedback welcome...";

extends 'Lab::Moose::Instrument';

has max_setpoint => (
    is      => 'ro',
    isa     => 'Lab::Moose::PosNum',
    default => 1
);

has min_setpoint => (
    is      => 'ro',
    isa     => 'Lab::Moose::PosNum',
    default => 0.02
);

has read_delay => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.3
);

has buffin => (
    is      => 'ro',
    isa     => 'Str',
    default => 'C:\Program Files\Trmc2\buffin.txt'
);

has buffout => (
    is      => 'ro',
    isa     => 'Str',
    default => 'C:\Program Files\Trmc2\buffout.txt'
);

has initialized => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);


sub set_T {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    $self->TRMC2_set_SetPoint($value);

    # what do we need to return here?
    #return TRMC2_set_SetPoint(@_);
}


sub get_T {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->TRMC2_get_T(5);
}


sub TRMC2init {
    my $self = shift;
    if ( $self->initialized ) { die "TRMC already Initialized\n" }

    if ( !open FHIN, "<", $self->buffin ) {    ## no critic
        die "could not open command file " . $self->buffin . ": $!\n";
    }
    close(FHIN);
    if ( !open FHOUT, "<", $self->buffout ) {    ## no critic
        die "could not open reply file " . $self->buffout . ": $!\n";
    }
    close(FHOUT);

    $self->initialized(1);
}


sub TRMC2off {
    my $self = shift;
    $self->initialized(0);
}


sub TRMC2_Heater_Control_On {
    my $self  = shift;
    my $state = shift;

    if ( $state != 0 && $state != 1 ) {
        die
            "TRMC heater control can be turned off or on by 0 and 1 not by $state\n";
    }
    my $cmd = sprintf( "MAIN:ON=%d\0", $state );
    $self->TRMC2_Write( $cmd, 0.3 );
}


sub TRMC2_Prog_On {
    my $self  = shift;
    my $state = shift;

    if ( $state != 0 && $state != 1 ) {
        die "TRMC Program can be turned off or on by 0 and 1 not by $state\n";
    }

    my $cmd = sprintf( "MAIN:PROG=%d\0", $state );
    $self->TRMC2_Write( $cmd, 1.0 );
}


sub TRMC2_get_SetPoint {
    my $self = shift;

    my $cmd = "MAIN:SP?";
    my @value = $self->TRMC2_Query( $cmd, 0.1 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }

    return $value[0];
}


sub TRMC2_set_SetPoint {
    my $self     = shift;
    my $setpoint = shift;

    if ( $setpoint > $self->max_setpoint ) {
        croak
            "setting temperatures above $self->max_setpoint K is forbidden\n";
    }
    if ( $setpoint < $self->min_setpoint ) {
        croak
            "setting temperatures below $self->max_setpoint K is forbidden\n";
    }

    my $FrSetpoint = MakeFrenchComma( sprintf( "%.6E", $setpoint ) );

    my $cmd = "MAIN:SP=$FrSetpoint";
    $self->TRMC2_Write( $cmd, 0.2 );
}


sub TRMC2_get_PV {
    my $self = shift;

    my $cmd = "MAIN:PV?";
    my @value = $self->TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return $value[0];
}


sub TRMC2_AllMeas {
    my $self = shift;

    my $cmd = "ALLMEAS?";
    my @value = $self->TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }

    return @value;
}


sub TRMC2_get_T {
    my $self   = shift;
    my $sensor = shift;

    if ( $sensor < 0 || $sensor > 6 ) {
        die "Sensor# $sensor not available\n";
    }

    my @value = $self->TRMC2_AllMeas();

    my @sensorval = split( /;/, $value[$sensor] );
    my $T = $sensorval[1];
    return $T;
}


sub TRMC2_get_R {
    my $self   = shift;
    my $sensor = shift;

    if ( $sensor < 0 || $sensor > 6 ) {
        die "Sensor# $sensor not available\n";
    }

    my @value = $self->TRMC2_AllMeas();

    my @sensorval = split( /;/, $value[$sensor] );
    my $R = $sensorval[0];
    return $R;
}


sub TRMC2_get_RT {
    my $self   = shift;
    my $sensor = shift;

    if ( $sensor < 0 || $sensor > 6 ) {
        die "Sensor# $sensor not available\n";
    }

    my @value = $self->TRMC2_AllMeas();

    my @sensorval = split( /;/, $value[$sensor] );
    my $R         = $sensorval[0];
    my $T         = $sensorval[1];
    return ( $R, $T );
}


sub TRMC2_Read_Prog {
    my $self = shift;

    my $cmd = "MAIN:PROG_Table?\0";
    my @value = $self->TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return @value;
}


sub TRMC2_Set_T_Sweep {
    my $arg_cnt = @_;

    my $self      = shift;
    my $Setpoint  = shift;    #K
    my $Sweeprate = shift;    #K/min
    my $Holdtime  = 0.;       #sec.
    if ( $arg_cnt == 4 ) { $Holdtime = shift }
    my $FrSetpoint  = MakeFrenchComma( sprintf( "%.6E", $Setpoint ) );
    my $FrSweeprate = MakeFrenchComma( sprintf( "%.6E", $Sweeprate ) );
    my $FrHoldtime  = MakeFrenchComma( sprintf( "%.6E", $Holdtime ) );

    my $cmd = "MAIN:PROG_Table=1\0";
    $self->TRMC2_Write( $cmd, 0.5 );

    $cmd = sprintf(
        "PROG_TABLE(%d)=%s;%s;%s\n",
        0, $FrSetpoint, $FrSweeprate, $FrHoldtime
    );
    $self->TRMC2_Write( $cmd, 0.5 );
}


sub TRMC2_Start_Sweep {
    my $self  = shift;
    my $state = shift;

    if ( $state != 0 && $state != 1 ) {
        die "Sweep can be turned off or on by 0 and 1 not by $state\n";
    }
    if ( $state == 1 ) { $self->TRMC2_Heater_Control_On($state); }
    $self->TRMC2_Prog_On($state);
}


sub TRMC2_All_Channels {
    my $self = shift;

    my $cmd = "*CHANNEL";
    my @value = $self->TRMC2_Query( $cmd, 0.1 );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return @value;
}


sub TRMC2_Active_Channel {
    my $self = shift;

    my $cmd = "CHANNEL?";
    my @value = $self->TRMC2_Query( $cmd, $self->read_delay );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return @value;
}


sub TRMC2_Shut_Down {
    my $self = shift;

    $self->TRMC2_Start_Sweep(0);
    $self->TRMC2_Heater_Control_On(0);
}


sub TRMC2_Write {
    my $self = shift;

    my $arg_cnt    = @_;
    my $cmd        = shift;
    my $wait_write = $self->read_delay;
    if ( $arg_cnt == 2 ) { $wait_write = shift }
    if ( !open FHIN, ">", $self->buffin ) {    ## no critic
        die "could not open command file " . $self->buffin . ": $!\n";
    }

    printf FHIN $cmd;
    close(FHIN);

    sleep($wait_write);
}


sub TRMC2_Query {
    my $self = shift;

    my $arg_cnt = @_;

    my $cmd        = shift;
    my $wait_query = $self->read_delay;
    if ( $arg_cnt == 2 ) { $wait_query = shift }

    #----Open Command File---------
    if ( !open FHIN, ">", $self->buffin ) {    ## no critic
        die "could not open command file " . $self->buffin . ": $!\n";
    }

    printf FHIN $cmd;
    close(FHIN);

    #-----------End Of Setting Command-----------
    sleep($wait_query);

    #--------Reading Value----------------------
    if ( !open FHOUT, "<", $self->buffout ) {    ## no critic
        die "could not open reply file " . $self->buffout . ": $!\n";
    }
    my @line = <FHOUT>;
    close(FHOUT);

    return @line;
}


sub RemoveFrenchComma {
    my $value = shift;
    $value =~ s/,/./g;
    return $value;
}


sub MakeFrenchComma {
    my $value = shift;
    $value =~ s/\./,/g;
    return $value;
}


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::ABB_TRMC2 - ABB TRMC2 temperature controller

=head1 VERSION

version 3.930

=head1 SYNOPSIS

 use Lab::Moose;
 
 my $trmc = instrument(
      type => 'ABB_TRMC2'
 );
 
 my $temp = $trmc->get_T();

Warning: Due to the rather unique (and silly) way of device communication, the 
TRMC2 driver does not use the connection layer.

=head1 External interface

=head2 set_T

 $trmc->set_T(value => 0.1);

Program the TRMC to regulate the temperature towards a specific value (in K).
The function returns immediately; this means that the target temperature most
likely has not been reached yet.

Possible values are in the range [min_setpoint, max_setpoint], by default
[0.02, 1.0].

=head2 get_T

 $trmc->get_T();

This is a shortcut for reading out temperature channel 5, typically the mixing chamber temperature.

TODO: Which channel is typically used for the control loop here?

=head1 Internal / hardware-specific functions

=head2 TRMC2init

Checks input and output buffer for TRMC2 commands and tests the file communication.

=head2 TRMC2off

Unmounts, i.e., releases control of the TRMC

=head2 TRMC2_Heater_Control_On

Switch the Heater Control (The coupling heater and set point NOT the heater switch in the main menu); 1 on, 0 off

=head2 TRMC2_Prog_On

What does this precisely do?

=head2 TRMC2_get_SetPoint

 my $target = $trmc->TRMC2_get_SetPoint();

Return the current setpoint of the TRMC2 in Kelvin.

=head2 TRMC2_set_SetPoint

 $trmc->TRMC2_set_SetPoint(0.1);

Program the TRMC to regulate the temperature towards a specific value (in K).
The function returns immediately; this means that the target temperature most
likely has not been reached yet.

Possible values are in the range [min_setpoint, max_setpoint], by default
[0.02, 1.0].

=head2 TRMC2_get_PV

What does this do?

=head2 TRMC2_AllMeas

Read out all sensor channels.

=head2 TRMC2_get_T

 my $t = $trmc->TRMC2_get_T($channel);

Reads out temperature of a sensor channel.

Sensor number:
 1 Heater
 2 Output
 3 Sample
 4 Still
 5 Mixing Chamber
 6 Cernox

=head2 TRMC2_get_R

  my $r = $trmc->TRMC2_get_R($channel);

Reads out resistance of a sensor channel.

Sensor number:
 1 Heater
 2 Output
 3 Sample
 4 Still
 5 Mixing Chamber
 6 Cernox

=head2 TRMC2_get_RT

  my ($r, $t) = $trmc->TRMC2_get_RT();

Reads out resistance and temperature simultaneously. 

Sensor number: 
 1 Heater
 2 Output
 3 Sample
 4 Still
 5 Mixing Chamber
 6 Cernox

=head2 TRMC2_Read_Prog

Reads Heater Batch Job

=head2 TRMC2_Set_T_Sweep

 $trmc->TRMC2_Set_T_Sweep(SetPoint, Sweeprate, Holdtime)

Programs the built in temperature sweep. After Activation it will sweep from the 
current temperature to the set temperature with the given sweeprate. The Sweep 
can be started with TRMC2_Start_Sweep(1).

Variables: SetPoint in K, Sweeprate in K/Min, Holdtime in s (defaults to 0)

=head2 TRMC2_Start_Sweep

 $trmc->TRMC2_Start_Sweep(1);

Starts (1) / stops (0) the sweep --- provided the heater in TRMC2 window is 
turned ON. At a sweep stop the power is left on.

=head2 TRMC2_All_Channels

Reads out all channels and values and returns an array

=head2 TRMC2_Active_Channel

Reads out the active channel (?)

=head2 TRMC2_Shut_Down

Stops the sweep and the heater control

=head2 TRMC2_Write

 TRMC2_Write($cmd, $wait_write=$WAIT)

Sends a command to the TRMC and will wait $wait_write.

=head2 TRMC2_Query

 TRMC2_Query($cmd, $wait_query=$WAIT)

Sends a command to the TRMC and will wait $wait_query sec long and returns the 
result.

=head2 RemoveFrenchComma

Replace "," in a number with "." (yay for French hardware!)

=head2 MakeFrenchComma

Replace "." in a number with "," (yay for French hardware!)

=head2 Consumed Roles

This driver consumes no roles.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner, Andreas K. Huettel
            2013       Alois Dirnaichner
            2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2021       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
