package Lab::Instrument::YokogawaGS200;
#ABSTRACT: Yokogawa GS200 DC source
$Lab::Instrument::YokogawaGS200::VERSION = '3.899';
use v5.20;

use strict;
use warnings;

use feature "switch";
use Lab::Instrument;
use Lab::Instrument::Source;
use Data::Dumper;
use Lab::SCPI;

our @ISA = ('Lab::Instrument::Source');

our %fields = (
    supported_connections => [ 'VISA_GPIB', 'GPIB', 'VISA' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => 22,
    },

    device_settings => {

        gate_protect            => 1,
        gp_equal_level          => 1e-5,
        gp_max_units_per_second => 0.05,
        gp_max_units_per_step   => 0.005,
        gp_max_step_per_second  => 10,

        stepsize => 0.01,    # default stepsize for sweep without gate protect

        max_sweep_time => 3600,
        min_sweep_time => 0.1,
    },

    # If class does not provide set_$var for those, AUTOLOAD will take care.
    device_cache => {
        function => undef,
        range    => undef,
        level    => undef,
        output   => undef,
    },

    device_cache_order => [ 'function', 'range' ],
    request            => 0
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->configure( $self->config() );

    return $self;
}

sub set_voltage {
    my $self    = shift;
    my $voltage = shift;

    my $function = $self->get_function( { read_mode => 'cache' } );

    if ( $function ne 'VOLT' ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is in mode $function. Can't set voltage level." );
    }

    return $self->set_level( $voltage, @_ );
}

sub set_voltage_auto {
    my $self    = shift;
    my $voltage = shift;

    my $function = $self->get_function();

    if ( $function ne 'VOLT' ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is in mode $function. Can't set voltage level." );
    }

    if ( abs($voltage) > 32. ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is not capable of voltage level > 32V. Can't set voltage level."
        );
    }

    $self->set_level_auto( $voltage, @_ );
}

sub set_current_auto {
    my $self    = shift;
    my $current = shift;

    my $function = $self->get_function();

    if ( $function ne 'CURR' ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is in mode $function. Can't set current level." );
    }

    if ( abs($current) > 0.200 ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is not capable of current level > 200mA. Can't set current level."
        );
    }

    $self->set_level_auto( $current, @_ );
}

sub set_current {
    my $self    = shift;
    my $current = shift;

    my $function = $self->get_function();

    if ( $self->get_function() ne 'CURR' ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is in mode $function. Can't set current level." );
    }

    $self->set_level( $current, @_ );
}

sub _set_level {
    my $self     = shift;
    my $value    = shift;
    my $srcrange = $self->get_range();

    ( my $dec, my $exp ) = ( $srcrange =~ m/(^\d+)E([-\+]\d+)$/ );

    $srcrange = eval("$dec*10**$exp+2*$dec*10**($exp-1)");

    if ( abs($value) <= $srcrange ) {
        my $cmd = sprintf( ":SOURce:LEVel %f", $value );

        #print $cmd;
        $self->write($cmd);
        return $self->{'device_cache'}->{'level'} = $value;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            error => "Level $value is out of curren range $srcrange." );
    }

}

sub set_level_auto {
    my $self  = shift;
    my $value = shift;

    my $cmd = sprintf( ":SOURce:LEVel:AUTO %e", $value );

    $self->write($cmd);

    $self->{'device_cache'}->{'range'} = $self->get_range( from_device => 1 );

    return $self->{'device_cache'}->{'level'} = $value;

}

sub program_run {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    # print "Running program\n";
    $self->write( ":PROG:RUN", $tail );

}

sub program_pause {
    my $self = shift;

    my $cmd = sprintf(":PROGram:PAUSe");
    $self->write("$cmd");
}

sub program_continue {
    my $self  = shift;
    my $value = shift;
    my $cmd   = sprintf(":PROGram:CONTinue");
    $self->write("$cmd");

}

sub program_halt {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    $self->write( ":PROG:HALT", $tail );
}

sub start_program {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    #print "Start program\n";
    $self->write( ":PROG:EDIT:START", $tail );
}

sub end_program {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    #print "End program\n";
    $self->write( ":PROG:EDIT:END", $tail );
}

sub set_setpoint {
    my $self = shift;
    my ( $value, $tail ) = $self->_check_args( \@_, ['value'] );
    my $cmd = sprintf(":SOUR:LEV $value");

    #print "Do $cmd";
    $self->write( $cmd, { error_check => 1 }, $tail );
}

sub config_sweep {
    my $self = shift;
    my ( $start, $target, $duration, $sections, $tail )
        = $self->check_sweep_config(@_);

    $self->write( ":PROG:REP 0", $tail );
    $self->write( "*CLS",        $tail );
    $self->set_output( 1, $tail );

    $self->start_program($tail);

    #print "Program:\n";
    for ( my $i = 1; $i <= $sections; $i++ ) {
        $self->set_setpoint( $start + ( $target - $start ) / $sections * $i );
        printf "sweep to setpoint: %+.4e\n",
            $start + ( $target - $start ) / $sections * $i;
    }
    $self->end_program($tail);

    $self->set_time( $duration, $duration, $tail );

}

sub set_time {    # internal use only
    my $self = shift;
    my ( $sweep_time, $interval_time, $tail )
        = $self->_check_args( \@_, [ 'sweep_time', 'interval_time' ] );
    if ( $sweep_time < $self->device_settings()->{min_sweep_time} ) {
        print Lab::Exception::CorruptParameter->new( error =>
                " Sweep Time: $sweep_time smaller than $self->device_settings()->{min_sweep_time} sec!\n Sweep time set to $self->device_settings()->{min_sweep_time} sec"
        );
        $sweep_time = $self->device_settings()->{min_sweep_time};
    }
    elsif ( $sweep_time > $self->device_settings()->{max_sweep_time} ) {
        print Lab::Exception::CorruptParameter->new( error =>
                " Sweep Time: $sweep_time> $self->device_settings()->{max_sweep_time} sec!\n Sweep time set to $self->device_settings()->{max_sweep_time} sec"
        );
        $sweep_time = $self->device_settings()->{max_sweep_time};
    }
    if ( $interval_time < $self->device_settings()->{min_sweep_time} ) {
        print Lab::Exception::CorruptParameter->new( error =>
                " Interval Time: $interval_time smaller than $self->device_settings()->{min_sweep_time} sec!\n Interval time set to $self->device_settings()->{min_sweep_time} sec"
        );
        $interval_time = $self->device_settings()->{min_sweep_time};
    }
    elsif ( $interval_time > $self->device_settings()->{max_sweep_time} ) {
        print Lab::Exception::CorruptParameter->new( error =>
                " Interval Time: $interval_time> $self->device_settings()->{max_sweep_time} sec!\n Interval time set to $self->device_settings()->{max_sweep_time} sec"
        );
        $interval_time = $self->device_settings()->{max_sweep_time};
    }
    $self->write( ":PROG:SLOP $sweep_time",   $tail );
    $self->write( ":PROG:INT $interval_time", $tail );

}

sub wait {
    my $self   = shift;
    my ($tail) = $self->_check_args( \@_ );
    my $flag   = 1;
    local $| = 1;

    while (1) {

        #my $status = $self->get_status();

        my $current_level
            = $self->get_level( { read_mode => 'device' }, $tail );
        if ( $flag <= 1.1 and $flag >= 0.9 ) {
            print "\t\t\t\t\t\t\t\t\t\r";
            print $self->get_id() . " is sweeping ($current_level )\r";

        }
        elsif ( $flag <= 0 ) {
            print "\t\t\t\t\t\t\t\t\t\r";
            print $self->get_id() . " is          ($current_level ) \r";
            $flag = 2;
        }
        $flag -= 0.5;

        if ( $self->active($tail) == 0 ) {
            print "\t\t\t\t\t\t\t\t\t\r";
            $| = 0;
            last;
        }
    }

}

sub _sweep_to_level {
    my $self = shift;
    my ( $target, $time, $tail )
        = $self->_check_args( \@_, [ 'points', 'time' ] );

    $self->config_sweep( { points => $target, time => $time }, $tail );

    $self->program_run($tail);

    $self->wait($tail);
    my $current = $self->get_level($tail);

    my $eql = $self->get_gp_equal_level();

    if ( abs( $current - $target ) > $eql ) {
        print "YokogawaGS200.pm: error current neq target\n";
        Lab::Exception::CorruptParameter->throw(
            "Sweep failed: $target not equal to $current. \n");
    }

    $self->{'device_cache'}->{'level'} = $target;

    return $target;
}

sub trg {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );
    $self->write( "*CLS", $tail );
    $self->program_run($tail);
}

sub abort {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );
    $self->program_halt($tail);
}

sub get_voltage {
    my $self = shift;

    my $function = $self->get_function();

    if ( !$function eq 'VOLT' ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is in mode $function. Can't get voltage level." );
    }

    return $self->get_level(@_);
}

sub active {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    $self->write( "STAT:ENAB 128", $tail );
    if ( $self->get_status( "EES", $tail ) == 1 ) {
        return 0;
    }
    else {
        return 1;
    }

}

sub get_status {
    my $self = shift;
    my ( $request, $tail ) = $self->_check_args( \@_, ['request'] );

    # The status byte is read

    my $status = int( $self->query( '*STB?', $tail ) );

    #printf "Status: %i",$status;

    my @flags  = qw/NONE EES ESB MAV NONE EAV MSS NONE/;
    my $result = {};
    for ( 0 .. 7 ) {
        $result->{ $flags[$_] } = $status & 1;
        $status >>= 1;
    }

    #print "EOP: $result->{'EOP'}\n";
    return $result->{$request} if defined $request;
    return $result;

}

sub get_current {
    my $self = shift;

    my $function = $self->get_function();

    if ( !$self->get_function() eq 'CURR' ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is in mode $function. Can't get current level." );
    }

    return $self->get_level(@_);
}

sub get_level {
    my $self   = shift;
    my ($tail) = $self->_check_args( \@_ );
    my $cmd    = ":SOUR:LEV?";

    return $self->request( $cmd, $tail );
}

sub get_function {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    my $cmd = ":SOURce:FUNCtion?";
    return $self->query( $cmd, $tail );
}

sub get_range {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    my $cmd = ":SOUR:RANG?";
    return $self->query( $cmd, $tail );

}

sub set_function {
    my $self = shift;
    my $func = shift;

    if ( scpi_match( $func, 'current|voltage' ) ) {
        my $cmd = ":SOURce:FUNCtion " . $func;

        #print "$cmd\n";
        $self->write($cmd);
        return $self->{'device_cache'}->{'function'} = $func;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            error => "source function $func not defined for this device.\n" );
    }

}

sub set_range {
    my $self  = shift;
    my $range = shift;

    my $srcf = $self->get_function();

    $self->write( "SOURce:RANGe $range", error_check => 1 );
    return $self->{'device_cache'}->{'range'}
        = $self->get_range( from_device => 1 );

}

sub set_output {
    my $self  = shift;
    my $value = shift;

    if ( $value =~ /(on|1)/i ) {
        $value = 1;
    }
    elsif ( $value =~ /(off|0)/i ) {
        $value = 0;
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "set_output accepts only on or off (case non-sensitive) and 1 or 0. $value is not valid."
        );
    }

    return $self->{"device_cache"}->{"output"} = $self->write(":OUTP $value");
}

sub get_output {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    return $self->query( ":OUTP?", $tail );
}

sub set_voltage_limit {
    my $self  = shift;
    my $value = shift;
    my $cmd   = ":SOURce:PROTection:VOLTage $value";

    if ( $value > 30. || $value < 1. ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "The voltage limit $value is not within the allowed range.\n"
        );
    }

    $self->connection()->write($cmd);

    return $self->device_cache()->{'voltage_limit'} = $value;

}

sub set_current_limit {
    my $self  = shift;
    my $value = shift;
    my $cmd   = ":SOURce:PROTection:CURRent $value";

    if ( $value > 0.2 || $value < 0.001 ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "The current limit $value is not within the allowed range.\n"
        );
    }

    $self->connection()->write($cmd);

    return $self->device_cache()->{'current_limit'} = $value;

}

sub get_error {
    my $self = shift;

    my $cmd = ":SYSTem:ERRor?";

    return $self->query($cmd);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::YokogawaGS200 - Yokogawa GS200 DC source (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

    use Lab::Instrument::YokogawaGS200;
    
    my $gate14=new Lab::Instrument::YokogawaGS200(
      connection_type => 'LinuxGPIB',
      gpib_address => 22,
      function => 'VOLT',
      level => 0.4,
    );
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

The Lab::Instrument::YokogawaGS200 class implements an interface to the
discontinued voltage and current source GS200 by Yokogawa. This class derives from
L<Lab::Instrument::Source> and provides all functionality described there.

=head1 CONSTRUCTORS

=head2 new( %configuration_HASH )

HASH is a list of tuples given in the format

key => value,

please supply at least the configuration for the connection:
		connection_type 		=> "LinxGPIB"
		gpib_address =>

you might also want to have gate protect from the start (the default values are given):

		gate_protect => 1,

		gp_equal_level          => 1e-5,
		gp_max_units_per_second  => 0.05,
		gp_max_units_per_step    => 0.005,
		gp_max_step_per_second  => 10,
		gp_max_units_per_second  => 0.05,
		gp_max_units_per_step    => 0.005,

		max_sweep_time=>3600,
		min_sweep_time=>0.1,

Additinally there is support to set parameters for the device "on init":		

		function			=> undef, # 'VOLT' - voltage, 'CURR' - current
		range			=> undef,
		level			=> undef,
		output					=> undef,

If those values are not specified, they are read from the device.

=head1 METHODS

=head2 sweep_to_level

	$src->sweep_to_level($lvl,$time)

Sweep to the level $lvl in $time seconds.

=head2 set_voltage

	$src->set_voltage($voltage)

Sets the output voltage to $voltage.
Returns the newly set voltage. 

=head2 get_voltage

Returns the currently set $voltage. The value is read from the driver cache by default. Provide the option

	device_cache => 1

to read directly from the device. 

=head2 set_current

	$src->set_current($current)

Sets the output current to $current.
Returns the newly set current. 

=head2 get_current

Returns the currently set $current. The value is read from the driver cache by default. Provide the option

	device_cache => 1

to read directly from the device.

=head2 set_level

	$src->set_level($lvl)

Sets the level $lvl in the current operation mode.

=head2 get_level

	$lvl = $src->get_level()

Returns the currently set level. Use 

	device_cache => 1

to enforce a reading directly from the device. 

=head2 set_range($range)

    Fixed voltage mode
    10E-3    10mV
    100E-3   100mV
    1E+0     1V
    10E+0    10V
    30E+0    30V

    Fixed current mode
    1E-3   		1mA
    10E-3   	10mA
    100E-3   	100mA
    200E-3		200mA
    
    Please use the format on the left for the range command.

=head2 program_run($program)

Runs a program stored on the YokogawaGS200. If no prgram name is given, the currently loaded program is executed.

=head2 program_pause

Pauses the currently running program.

=head2 program_continue

Continues the paused program.

=head2 set_function($function)

Sets the source function. The Yokogawa supports the values 

"CURR" for current mode and
"VOLT" for voltage mode.

Returns the newly set source function.

=head2 set_voltage_limit($limit)

Sets a voltage limit to protect the device.
Returns the new voltage limit.

=head2 set_current_limit($limit)

See set_voltage_limit.

=head2 output_on()

Sets the output switch to on and returns the new value of the output status.

=head2 output_off()

Sets the output switch to off. The instrument outputs no voltage
or current then, no matter what voltage you set. Returns the new value of the output status.

=head2 get_error()

Queries the error code from the device. This is a very useful thing to do when you are working remote and the source is not responding.

=head2 get_output()

=head2 get_range()

=head1 CAVEATS

probably many

=head1 SEE ALSO

=over 4

=item * Lab::Instrument

The YokogawaGP200 class is a Lab::Instrument (L<Lab::Instrument>).

=item * Lab::Instrument::Source

The YokogawaGP200 class is a Source (L<Lab::Instrument::Source>)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2005-2006  Daniel Schroeer
            2009       Andreas K. Huettel, Daniela Taubert
            2010       Andreas K. Huettel, Daniel Schroeer
            2011       Andreas K. Huettel, David Kalok, Florian Olbrich
            2012       Alois Dirnaichner, Andreas K. Huettel, Florian Olbrich
            2013       Andreas K. Huettel, Christian Butschkow
            2014       Alois Dirnaichner, Christian Butschkow
            2015       Alois Dirnaichner
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
