package Lab::Instrument::TRMC2;
#ABSTRACT: ABB TRMC2 temperature controller
$Lab::Instrument::TRMC2::VERSION = '3.881';
use v5.20;

use strict;
use warnings;
use Lab::Instrument;
use Lab::Instrument::TemperatureControl;
use IO::File;
use Time::HiRes qw/usleep/;
use Time::HiRes qw/sleep/;

our @ISA = ("Lab::Instrument::TemperatureControl");

our %fields = ( supported_connections => ['none'], );

my $WAIT    = 0.3;    #sec. waiting time for each reading;
my $mounted = 0;      # Ist sie schon mal angemeldet

my $buffin
    = "C:\\Program Files\\Trmc2\\buffin.txt";    # Hierhin gehen die Befehle
my $buffout
    = "C:\\Program Files\\Trmc2\\buffout.txt";  # Hierher kommen die Antworten

my $TRMC2_LSP = 0.02;                           #Lower Setpoint Limit
my $TRMC2_HSP = 1;                              #Upper Setpoint Limit

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub TRMC2init {

    # Checks input and output buffer for TRMC2 commands
    my $self = shift;
    if ( $mounted == 1 ) { die "TRMC already Initialized\n" }

    #files Ã¶ffnen und schliessen
    if ( !open FHIN, "<$buffin" ) {
        die "could not open command file $buffin: $!\n";
    }
    close(FHIN);
    if ( !open FHOUT, "<$buffout" ) {
        die "could not open reply file $buffout: $!\n";
    }
    close(FHOUT);

    #sleep($WAIT);
    $mounted = 1;
}

sub TRMC2off {

    # "Unmounts" the TRMC
    $mounted = 0;
}

sub set_heatercontrol {

}

sub TRMC2_Heater_Control_On {

    # Switch the Heater Control (The coupling heater and set point NOT the heater switch in the main menu)
    # 1 On
    # 0 Off
    my $self  = shift;
    my $state = shift;
    if ( $state != 0 && $state != 1 ) {
        die
            "TRMC heater control can be turned off or on by 0 and 1 not by $state\n";
    }
    my $cmd = sprintf( "MAIN:ON=%d\0", $state );
    TRMC2_Write( $cmd, 0.3 );
}

sub TRMC2_Prog_On {
    my $self  = shift;
    my $state = shift;
    if ( $state != 0 && $state != 1 ) {
        die "TRMC Program can be turned off or on by 0 and 1 not by $state\n";
    }
    my $cmd = sprintf( "MAIN:PROG=%d\0", $state );
    TRMC2_Write( $cmd, 1.0 );
}

sub TRMC2_get_SetPoint {
    my $cmd = sprintf("MAIN:SP?");
    my @value = TRMC2_Query( $cmd, 0.1 );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return $value[0];
}

sub set_T {
    return TRMC2_set_SetPoint(@_);
}

sub TRMC2_set_SetPoint {
    my $self       = shift;
    my $Setpoint   = shift;
    my $FrSetpoint = MakeFrenchComma( sprintf( "%.6E", $Setpoint ) );
    my $cmd        = sprintf("MAIN:SP=$FrSetpoint");
    TRMC2_Write( $cmd, 0.2 );
}

sub TRMC2_Set_T {
    my $self = shift;
    my $T    = shift;
    $T = sprintf( "%.6E", $T );

    #printf "T_SET=$T\n";
    my $Tfr = MakeFrenchComma( sprintf( "%.6E", $T ) );

    #printf "Frensh T_SET=$Tfr\n";
    my $cmd = sprintf("MAIN:SP=$Tfr");
    my @value = TRMC2_Query( $cmd, 0.1 );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return $value[0];
}

sub get_value {
    return TRMC2_get_PV(@_);
}

sub TRMC2_get_PV {

    my $cmd = sprintf("MAIN:PV?");
    my @value = TRMC2_Query( $cmd, 0.2 );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return $value[0];
}

sub TRMC2_AllMEAS {
    my $cmd = sprintf("ALLMEAS?");
    my @value = TRMC2_Query( $cmd, 0.2 );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return @value;

}

sub TRMC2_get_T {    #------------Reads Out Temperature-------------
                     # Sensor Number:
                     # 1 Heater
                     # 2 Output
                     # 3 Sample
                     # 4 Still
                     # 5 Mixing Chamber
                     # 6 Cernox
    my $self   = shift;
    my $sensor = shift;

    if ( $sensor < 0 || $sensor > 6 ) {
        die "Sensor# $sensor not available\n";
    }
    my $cmd = sprintf("ALLMEAS?");
    my @value = TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);

        #printf "$val\n";
    }
    my @sensorval = split( /;/, $value[$sensor] );
    my $T = $sensorval[1];
    return $T;

}

sub TRMC2_get_R {    #------------Reads Out Resistance-------------
                     # Sensor Number:
                     # 1 Heater
                     # 2 Output
                     # 3 Sample
                     # 4 Still
                     # 5 Mixing Chamber
                     # 6 Cernox
    my $self   = shift;
    my $sensor = shift;

    if ( $sensor < 0 || $sensor > 6 ) {
        die "Sensor# $sensor not available\n";
    }
    my $cmd = sprintf("ALLMEAS?");
    my @value = TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);

        #printf "$val\n";
    }
    my @sensorval = split( /;/, $value[$sensor] );
    my $R = $sensorval[0];
    return $R;

}

sub TRMC2_get_RT
{ #------------Reads Out Resistance and Temperature simoultaneously-------------
        # Sensor Number:
        # 1 Heater
        # 2 Output
        # 3 Sample
        # 4 Still
        # 5 Mixing Chamber
        # 6 Cernox
    my $self   = shift;
    my $sensor = shift;

    if ( $sensor < 0 || $sensor > 6 ) {
        die "Sensor# $sensor not available\n";
    }
    my $cmd = sprintf("ALLMEAS?");
    my @value = TRMC2_Query( $cmd, 0.2 );

    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);

        #printf "$val\n";
    }
    my @sensorval = split( /;/, $value[$sensor] );
    my $R         = $sensorval[0];
    my $T         = $sensorval[1];
    return ( $R, $T );

}

sub TRMC2_Read_Prog {    #------------Reads Heater Batch Job-------------
    my $self  = shift;
    my $cmd   = sprintf("MAIN:PROG_Table?\0");
    my @value = TRMC2_Query( $cmd, 0.2 );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);

        #printf "$val\n";
    }
    return @value;

}

sub TRMC2_Set_T_Sweep {    #------------Set T_Sweep-------------
        # TRMC2_Set_T_Sweep(SetPoint,Sweeprate,Holdtime=0)
        # Programs the built in Temperature Sweep.
        # After Activation it will sweep from the current Temperature
        # to the Set Temperature with the given Sweeprate.
        # The Sweep can be started with TRMC2_Start_Sweep(1)
        # Variables:
        # SetPoint in K
        # Sweeprate in K/Min
        # Holdtime=0
    my $arg_cnt = @_;

    #printf "#of variables=$arg_cnt\n";
    my $self      = shift;
    my $Setpoint  = shift;    #K
    my $Sweeprate = shift;    #K/min
    my $Holdtime  = 0.;       #sec.
    if ( $arg_cnt == 4 ) { $Holdtime = shift }
    my $FrSetpoint  = MakeFrenchComma( sprintf( "%.6E", $Setpoint ) );
    my $FrSweeprate = MakeFrenchComma( sprintf( "%.6E", $Sweeprate ) );
    my $FrHoldtime  = MakeFrenchComma( sprintf( "%.6E", $Holdtime ) );
    my $cmd         = sprintf("MAIN:PROG_Table=1\0");

    #printf $cmd;
    TRMC2_Write( $cmd, 0.5 );
    $cmd = sprintf(
        "PROG_TABLE(%d)=%s;%s;%s\n",
        0, $FrSetpoint, $FrSweeprate, $FrHoldtime
    );

    #printf $cmd;
    TRMC2_Write( $cmd, 0.5 );
}

sub TRMC2_Start_Sweep
{ #---Start/Stops The Sweep---Provided Heater in TRMC2 Window is turned ON------
        # 1 Start Sweep
        # 0 Stop Sweep leaves power on;
    my $self  = shift;
    my $state = shift;
    if ( $state != 0 && $state != 1 ) {
        die "Sweep can be turned off or on by 0 and 1 not by $state\n";
    }
    if ( $state == 1 ) { $self->TRMC2_Heater_Control_On($state); }
    $self->TRMC2_Prog_On($state);
}

sub TRMC2_All_CHANNEL {

    # Reads Out All Channels and Values and returns an Array
    my $cmd = sprintf("*CHANNEL");
    my @value = TRMC2_Query( $cmd, 0.1 );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return @value;

}

sub TRMC2_Active_CHANNEL {

    my $cmd = sprintf("CHANNEL?");
    my @value = TRMC2_Query( $cmd, $WAIT );
    foreach my $val (@value) {
        chomp $val;
        $val = RemoveFrenchComma($val);
    }
    return @value;

}

sub TRMC2_Shut_Down {

    # Will Stop the Sweep and the Heater Control
    my $self = shift;
    $self->TRMC2_Start_Sweep(0);
    $self->TRMC2_Heater_Control_On(0);
}

sub TRMC2_Write {

    # TRMC2_Write($cmd, $wait_write=$WAIT)
    # Sends a command to the TRMC and will wait $wait_write
    my $arg_cnt    = @_;
    my $cmd        = shift;
    my $wait_write = $WAIT;
    if ( $arg_cnt == 2 ) { $wait_write = shift }
    if ( !open FHIN, ">$buffin" ) {
        die "could not open command file $buffin: $!\n";
    }

    #printf "$cmd\n";
    printf FHIN $cmd;    #put $cmd it in buffin!
    close(FHIN);

    #printf "Wait Write=$wait_write\n";
    sleep($wait_write);
}

sub TRMC2_Query {

    # TRMC2_Query($cmd, $wait_query=$WAIT)
    # Sends a command to the TRMC and will wait $wait_query sec long
    # and returns the result
    my $arg_cnt = @_;

    #printf "# Variables=$arg_cnt\n";
    my $cmd        = shift;
    my $wait_query = $WAIT;
    if ( $arg_cnt == 2 ) { $wait_query = shift }

    #----Open Command File---------
    if ( !open FHIN, ">$buffin" ) {
        die "could not open command file $buffin: $!\n";
    }

    #printf "Command $cmd\n";
    printf FHIN $cmd;    #put $cmd it in buffin!
    close(FHIN);

    #printf "Wait Query=$wait_query\n";
    #-----------End Of Setting Command-----------
    sleep($wait_query);

    #--------Reading Value----------------------
    if ( !open FHOUT, "<$buffout" ) {
        die "could not open reply file $buffout: $!\n";
    }
    my @line = <FHOUT>;
    close(FHOUT);

    #printf "read lines are:@line\n";
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::TRMC2 - ABB TRMC2 temperature controller

=head1 VERSION

version 3.881

=head1 SYNOPSIS

    use Lab::Instrument::TRMC2;

=head1 DESCRIPTION

The Lab::Instrument::ILM class implements an interface to the ABB TRMC2 temperature 
controller. The driver works, but documentation is lacking.

=head1 CONSTRUCTOR

    my $trmc=...

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner, Andreas K. Huettel
            2013       Alois Dirnaichner
            2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
