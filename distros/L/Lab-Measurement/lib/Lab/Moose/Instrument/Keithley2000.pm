package Lab::Moose::Instrument::Keithley2000;
$Lab::Moose::Instrument::Keithley2000::VERSION = '3.802';
#ABSTRACT: Keithley 2000 digital multimeter

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw/enum/;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params validated_no_param_setter/;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use Time::HiRes qw (usleep);

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common
    Lab::Moose::Instrument::SCPI::Sense::Function
    Lab::Moose::Instrument::SCPI::Sense::NPLC
    Lab::Moose::Instrument::SCPI::Sense::Range
    Lab::Moose::Instrument::SCPI::Format
    Lab::Moose::Instrument::SCPI::Initiate
);

# ---------------------- Init DMM ----------------------------------------------
sub BUILD {
  my $self = shift;

  $self->clear();
  $self->cls();
  $self->initiate_continuous(value => 0);
}


# ----------------------- Config DMM ------------------------------------------------------

cache sense_average_state => ( getter => 'sense_average_state_query' );

sub sense_average_state_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $function = $self->sense_function_query();

    return $self->cached_sense_average_state(
        $self->query( command => "SENS:$function:AVER:STAT?", %args ) );
}

sub sense_average_state {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    my $function = $self->sense_function_query();

    $self->write( command => "SENS:$function:AVER $value", %args );
    return $self->cached_sense_average_state($value);
}

cache sense_average_count => (
    getter => 'sense_average_count_query',
    isa    => 'Int'
);

sub sense_average_count_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $function = $self->sense_function_query();

    return $self->cached_sense_average_state(
        $self->query( command => "SENS:$function:AVER:COUN?", %args ) );
}

sub sense_average_count {
    my ( $self, $value, %args ) = validated_setter( \@_,
        value => {isa => 'Int'}
    );

    my $function = $self->sense_function_query();

    $self->write( command => "SENS:$function:AVER:COUN $value", %args );
    return $self->cached_sense_average_state($value);
}

# ----------------------------------------- MEASUREMENT ----------------------------------


cache value => ( getter => 'get_value' );

sub get_value {    # basic
    my ( $self, %args ) = validated_getter( \@_ );

    my $function = $self->sense_function_query();

    if ( $function
        =~ /\b(PERIOD|period|PER|per|FREQUENCY|frequency|FREQ|freq|TEMPERATURE|temperature|TEMP|temp|DIODE|diode|DIOD|diod|CURRENT|current|CURR|curr|CURRENT:AC|current:ac|CURR:AC|curr:ac|CURRENT:DC|current:dc|CURR:DC|curr:dc|VOLTAGE|voltage|VOLT|volt|VOLTAGE:AC|voltage:ac|VOLT:AC|volt:ac|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc|RESISTANCE|resisitance|RES|res|FRESISTANCE|fresistance|FRES|fres)\b/
        ) {
            return $self->query(command => 'MEAS?' );
    }
    else {
        croak "unexpected value for 'function' in sub measure. Function can be CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, PERIOD, FREQUENCY, TEMPERATURE, DIODE";
    }
}


sub config_measurement {    # basic
    my ( $self, %args ) = validated_getter( \@_,
        function => {optional => 1},
        range => {default => 'DEF'},
        trigger => {default => 'BUS'},
        time => {isa => 'Num'},
        nop => {isa => 'Int'},

    );

    my $function = delete $args{function};
    my $nop = delete $args{nop};
    my $time = delete $args{time};
    my $range = delete $args{range};
    my $trigger = delete $args{trigger};


    # check input data
    if ( not defined $time ) {
        croak "too few arguments given in sub config_measurement. Expected arguments are FUNCTION, #POINTS, TIME, <RANGE>, <TRIGGERSOURCE>";
    }

    $self->sense_function(value => $function);
    print "sub config_measurement: set FUNCTION: "
        . $self->cached_sense_function() . "\n";

    $self->sense_range(value => $range );
    print "sub config_measurement: set RANGE: " . $self->cached_sense_range() . "\n";

    my $nplc = ( $time * 50 ) / $nop;
    if ( $nplc < 0.01 ) {
        croak "unexpected value for TIME in sub config_measurement. Expected values are between 0.5 ... 50000 sec.";
    }
    $self->sense_nplc(value => $nplc );
    print "sub config_measurement: set NPLC: " . $self->cached_sense_nplc() . "\n";

    print "sub config_measurement: init BUFFER: "
        . $self->_init_buffer(value => $nop) . "\n";

    print "sub config_measurement: init TRIGGER: "
        . $self->_init_trigger(value => $trigger) . "\n";

    return $nplc;

}


sub trg {    # basic
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write(command => "*TRG");
}


sub abort {    # basic
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write(command => "ABORT");
}


sub wait {     # basic
    my ( $self, $timeout, %args ) = validated_getter( \@_,
        timeout => {default => 100}
    );

    print "waiting for data ... \n";
    while (1) {
        if ( $self->query(command => ":STATUS:OPERATION:CONDITION?") >= 1024 ) {
            last;
        }    # check if measurement has been finished
        else { usleep(1e3); }
    }
}


sub active {    # basic
    my ( $self, %args ) = validated_no_param_setter( \@_,
        timeout => {default => 100}
    );

    my $timeout = delete $args{timeout};

    # check if measurement has been finished
    if ( $self->query(command => ":STATUS:OPERATION:CONDITION?") >= 1024 ) {
        return 0;
    }
    else {
        return 1;
    }
}


sub get_data {    # basic
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->_read_buffer();
}

# ------------------------------------ DATA BUFFER ----------------------------------------

sub _clear_buffer {    # internal
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write(command => ":DATA:CLEAR");
    return $self->query(command => ":DATA:FREE?");
}

sub _init_buffer {     # internal
    my ( $self, $value, %args ) = validated_setter( \@_ );

    $self->_clear_buffer();

    if ( $value >= 2 && $value <= 1024 ) {
        $self->cls();
        $self->write(command => ":STATUS:OPERATION:ENABLE 16");
            # enable status bit for measuring/idle status
        $self->write(command => "INIT:CONT OFF");    # set DMM to IDLE-state
        $self->_init_trigger(value => "BUS");
            # trigger-count = 1, trigger-delay = 0s, trigger-source = IMM/EXT/TIM/MAN/BUS
        $self->_set_triggercount(value => 1);
        $self->_set_triggerdelay(value => 0);
        my $return_nop = $self->_set_samplecount(value => $value);
        $self->write(command => ":INIT");  # set DMM from IDLE to WAIT-FOR_TRIGGER status
        return $return_nop;
    }
    else {
        croak "unexpected value in sub set_nop_for_buffer. Must be between 2 and 1024.";
    }
}

sub _read_buffer {              # basic
    my ( $self, $value, %args ) = validated_setter( \@_,
        value => {isa => 'Bool', default => 0}
    );

    # wait until data are available
    $self->wait();

    #read data
    $self->write(command => ":FORMAT:DATA ASCII; :FORMAT:ELEMENTS READING");

    # select Format for reading DATA
    my $data = $self->query(command => ":DATA:DATA?", read_length => 65536);
    chomp $data;
    my @data = split( ",", $data );

    #print data
    if ( $value) {
        foreach my $item (@data) { print $item. "\n"; }
    }

    return @data;
}

# -------------------------------------- TRIGGER ----------------------------------------------

sub _init_trigger {    # internal
    my ( $self, $value, %args ) = validated_setter( \@_,
        value => {isa => 'Str', default => 'BUS'} # set BUS as default trigger source
    );

    $self->_set_triggercount(value => "DEF");    # DEF = 1
    $self->_set_triggerdelay(value => "DEF");    # DEF = 0
    $self->_set_triggersource(value => "BUS");

    return "trigger initiated";
}

sub _set_triggersource {                # internal
    my ( $self, $value, %args ) = validated_setter( \@_,
        value => {optional => 1}
    );

    #return setting
    if ( not defined $value ) {
        $value = $self->query(command => ":TRIGGER:SOURCE?");
        chomp($value);
        return $value;
    }

    #set triggersoource
    if ( $value =~ /\b(IMM|imm|EXT|ext|TIM|tim|MAN|man|BUS|bus)\b/ ) {
        return $self->query(command =>
            sprintf( ":TRIGGER:SOURCE %s; SOURCE?", $value ) );
    }
    else {
        croak "unexpected value in sub _init_trigger. Must be IMM, EXT, TIM, MAN or BUS.";
    }
}

sub _set_samplecount {    # internal
    my ( $self, $value, %args ) = validated_setter( \@_,
        value => {optional => 1}
    );

    #return setting
    if ( not defined $value ) {
        $value = $self->query(command => ":SAMPLE:COUNT?");
        chomp($value);
        return $value;
    }

    #set samplecount
    if ( $value >= 1 && $value <= 1024 ) {
        return $self->query(command =>
            sprintf( ":SAMPLE:COUNT %d; COUNT?", $value ) );
    }
    else {
        croak "unexpected value in sub _set_samplecount. Must be between 1 and 1024.";
    }

}

sub _set_triggercount {    # internal
    my ( $self, $value, %args ) = validated_setter( \@_,
        value => {optional => 1}
    );

    #return setting
    if ( not defined $value ) {
        $value = $self->query(command => ":TRIGGER:COUNT?");
        chomp($value);
        return $value;
    }

    #set triggercount
    if ( ( $value >= 1 && $value <= 1024 )
        or $value =~ /\b(MIN|min|MAX|max|DEF|def)\b/ ) {
        return $self->query(command => ":TRIGGER:COUNT $value; COUNT?");
    }
    else {
        croak "unexpected value in sub _set_triggercount. Must be between 1 and 1024 or MIN/MAX/DEF.";
    }
}

sub _set_triggerdelay {    # internal
    my ( $self, $value, %args ) = validated_setter( \@_ );

    #return setting
    if ( not defined $value ) {
        $value = $self->query(command => ":TRIGGER:DELAY?");
        chomp($value);
        return $value;
    }

    #set triggerdelay
    if ( ( $value >= 0 && $value <= 999999.999 )
        or $value =~ /\b(MIN|min|MAX|max|DEF|def)\b/ ) {
        return $self->query(command => ":TRIGGER:DELAY $value; DELAY?");
    }
    else {
        croak "unexpected value in sub _set_triggerdelay. Must be between 0 and 999999.999sec or MIN/MAX/DEF.";
    }
}

sub set_timer {    # advanced
    my ( $self, $value, %args ) = validated_setter( \@_ );

    #return setting
    if ( not defined $value ) {
        $value = $self->query(command => ":TRIGGER:TIMER?");
        chomp($value);
        return $value;
    }

    #set timer
    if ( ( $value >= 1e-3 && $value <= 999999.999 )
        or $value =~ /\b(MIN|min|MAX|max|DEF|def)\b/ ) {
        return $self->query(command => ":TRIGGER:TIMER $value; TIMER?");
    }
    else {
        croak "unexpected value for TIMER in  sub set_timer. Must be between 0 and 999999.999sec or MIN/MAX/DEF.";
    }
}

# -----------------------------------------DISPLAY --------------------------------


sub display {    # basic
    my ( $self, $value, %args ) = validated_setter( \@_ );

    if ( not defined $value ) {
        return $self->_display_text();
    }
    elsif ( $value =~ /\b(ON|on)\b/ ) {
        return $self->_display_on();
    }
    elsif ( $value =~ /\b(OFF|off)\b/ ) {
        return $self->_display_off();
    }
    elsif ( $value =~ /\b(CLEAR|clear)\b/ ) {
        return $self->_display_clear();
    }
    else {
        return $self->_display_text(value => $value);
    }

}

sub _display_on {    # for internal/advanced use only
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write(command => ":DISPLAY:ENABLE ON");
}

sub _display_off {    # for internal/advanced use only
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write(command => ":DISPLAY:ENABLE OFF")
        ; # when display is disabled, the instrument operates at a higher speed. Frontpanel commands are frozen.
}

sub _display_text {    # for internal/advanced use only
    my ( $self, $value, %args ) = validated_setter( \@_,
        value => {optional => 1}
    );

    if ($value) {
        chomp( $value
                = $self->query(command => "DISPLAY:TEXT:DATA '$value'; STATE 1; DATA?") );
        $value =~ s/\"//g;
        return $value;
    }
    else {
        chomp( $value = $self->query(command => "DISPLAY:TEXT:DATA?") );
        $value =~ s/\"//g;
        return $value;
    }
}

sub _display_clear {    # for internal/advanced use only
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write(command => "DISPlay:TEXT:STATE 0");
}

# ----------------------------------------------------------------------------------------


sub beep {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write(command => "BEEP");
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Keithley2000 - Keithley 2000 digital multimeter

=head1 VERSION

version 3.802

=head1 SYNOPSIS

 use Lab::Moose;

 my $DMM= instrument(
     type => 'Keithley2000',
     connection_type => 'LinuxGPIB',
     connection_options => {gpib_address => 15},
 );

=head1 DESCRIPTION

The Lab::Moose::Instrument::Keithley2000 class implements an interface to the
Keithley 2000 digital multimeter.

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=item L<Lab::Moose::Instrument::SCPI::Sense::Function>

=item L<Lab::Moose::Instrument::SCPI::Sense::NPLC>

=item L<Lab::Moose::Instrument::SCPI::Sense::Range>

=item L<Lab::Moose::Instrument::SCPI::Format>

=item L<Lab::Moose::Instrument::SCPI::Initiate>

=back

=head2 get_value

	$DMM->get_value(value = $function);

Make a measurement defined by $function with the previously specified range
and integration time.

=over 4

=item $function

 FUNCTION  can be one of the measurement methods of the Keithley2000.

	"current:dc" --> DC current measurement
	"current:ac" --> AC current measurement
	"voltage:dc" --> DC voltage measurement
	"voltage:ac" --> AC voltage measurement
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=back

=head2 config_measurement

	$DMM->config_measurement(function => $function, $nop => $number_of_points, $time => time, range => $range, trigger => $trigger);

Preset the Keithley2000 for a TRIGGERED measurement.

WARNING: It's not recomended to perform triggered measurments with the KEITHLEY 2000 DMM due to unsolved timing problems!!!!!

=over 4

=item OPTIONAL $function

 FUNCTION  can be one of the measurement methods of the Keithley2000.

	"current:dc" --> DC current measurement
	"current:ac" --> AC current measurement
	"voltage:dc" --> DC voltage measurement
	"voltage:ac" --> AC voltage measurement
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $number_of_points

Preset the  NUMBER OF POINTS  to be taken for one measurement  TRACE .
The single measured points will be stored in the internal memory of the Keithley2000.
For the Keithley2000 the internal memory is limited to 1024 values.

=item $time

Preset the  TIME  duration for one full trace.
From  TIME  the integration time value for each measurement point will be derived [NPLC = (TIME *50Hz)/NOP].
Expected values are between 0.21 ... 20000 seconds.

=item OPTIONAL $range

 RANGE  is given in terms of amps, volts or ohms and can be   0...+3,03A | MIN | MAX | DEF | AUTO  ,   0...757V(AC)/1010V(DC) | MIN | MAX | DEF | AUTO   or   0...101e6 | MIN | MAX | DEF | AUTO  .
 DEF  is default  AUTO  activates the AUTORANGE-mode.
 DEF  will be set, if no value is given.

=item OPTIONAL $trigger

 Set the TRIGGER

=back

=head2 trg

    $DMM->trg();

Sends a trigger signal via the GPIB-BUS to start the predefined measurement.
The LabVisa-script can immediatally be continued, e.g. to start another triggered measurement using a second Keithley2000.

=head2 abort

	$DMM->abort();

Aborts current (triggered) measurement.

=head2 wait

	$DMM->wait();

WAIT until triggered measurement has been finished.

=head2 active

	$DMM->active();

Returns '1' if the current triggered measurement is still active and '0' if the current triggered measurement has allready been finished.

=head2 get_data

	@data = $DMM->get_data();

Reads all recorded values from the internal buffer and returnes them as an array of floatingpoint values.
Reading the buffer will start immediately after the triggered measurement has finished. The LabVisa-script cannot be continued until all requested readings have been recieved.

=head2 display

    $DMM->display(value => 'ON');

Control the K2000s display, $value can be

=over 4

=item ON

 Turn on the display

=item OFF

 Turn off the display

=item CLEAR

 Clear the display

=item your text

 Display a custom text

=back

=head2 beep

    $DMM->beep();

Make a beep sound

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2021       Andreas K. Huettel, Fabian Weinelt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
