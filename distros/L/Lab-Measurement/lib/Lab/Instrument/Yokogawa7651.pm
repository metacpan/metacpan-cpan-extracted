package Lab::Instrument::Yokogawa7651;
#ABSTRACT: Yokogawa 7651 DC source
$Lab::Instrument::Yokogawa7651::VERSION = '3.881';
use v5.20;

use warnings;
use strict;
use Time::HiRes qw/usleep/;



use Lab::Instrument;
use Lab::Instrument::Source;
use Data::Dumper;

our @ISA = ('Lab::Instrument::Source');

our %fields = (
    supported_connections => [ 'GPIB', 'VISA' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
        timeout      => 1
    },

    device_settings => {
        gate_protect => 1,

        #gp_equal_level          => 1e-5,
        gp_max_units_per_second => 0.005,
        gp_max_units_per_step   => 0.001,
        gp_max_step_per_second  => 5,

        max_sweep_time => 3600,
        min_sweep_time => 0.1,

        stepsize => 0.01,

    },

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

    return $self;
}

sub _device_init {
    my $self = shift;
    if ( $self->get_status('setting') ) {
        $self->end_program();
    }
}

sub set_voltage {
    my $self = shift;
    my ( $voltage, $tail ) = $self->_check_args( \@_, ['voltage'] );

    my $function = $self->get_function( { 'read_mode' => 'cache' }, $tail );

    if ( $function !~ /voltage/i ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is in mode $function. Can't set voltage level." );
    }

    return $self->set_level( $voltage, $tail );
}

sub set_current {
    my $self = shift;
    my ( $current, $tail ) = $self->_check_args( \@_, ['current'] );

    my $function = $self->get_function( { 'read_mode' => 'cache' }, $tail );

    if ( $function !~ /current/i ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is in mode $function. Can't set current level." );
    }

    $self->set_level( $current, $tail );
}

sub set_setpoint {
    my $self = shift;
    my ( $value, $tail ) = $self->_check_args( \@_, ['value'] );
    my $cmd = sprintf( "S%+.4e", $value );
    $self->write( $cmd, { error_check => 1 }, $tail );
}

sub _set_level {
    my $self = shift;
    my ( $value, $tail ) = $self->_check_args( \@_, ['value'] );

    my $range = $self->get_range( { read_mode => 'cache' }, $tail );

    if ( $value > $range || $value < -$range ) {
        Lab::Exception::CorruptParameter->throw(
            "The desired source level $value is not within the source range $range \n"
        );
    }

    my $cmd = sprintf( "S%ge", $value );

    $self->write( $cmd, { error_check => 1 }, $tail );

    return $self->{'device_cache'}->{'level'} = $value;

}

sub start_program {
    my $self   = shift;
    my ($tail) = $self->_check_args( \@_ );
    my $cmd    = sprintf("PRS");
    $self->write( $cmd, $tail );
}

sub end_program {
    my $self   = shift;
    my ($tail) = $self->_check_args( \@_ );
    my $cmd    = sprintf("PRE");
    $self->write( $cmd, $tail );
}

sub execute_program {

    # 0 HALT
    # 1 STEP
    # 2 RUN
    #3 Continue
    my $self = shift;
    my ( $value, $tail ) = $self->_check_args( \@_, ['value'] );
    my $cmd = sprintf( "RU%d", $value );
    $self->write( $cmd, $tail );
}

sub trg {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );
    $self->execute_program( 2, $tail );
}

sub config_sweep {
    my $self = shift;
    my ( $start, $target, $duration, $sections, $tail )
        = $self->check_sweep_config(@_);

    $self->set_output( 1, $tail );
    $self->set_run_mode( 'single', $tail );

    $self->start_program($tail);

    for ( my $i = 1; $i <= $sections; $i++ ) {
        $self->set_setpoint( $start + ( $target - $start ) / $sections * $i );
    }
    $self->end_program($tail);

    # programming sweep duration:

    $self->set_time( $duration, $duration, $tail );

    # calculate trace

}

sub configure_sweep {
    my $self = shift;
    my ( $target, $time, $rate, $tail )
        = $self->_check_args( \@_, [ 'points', 'time', 'rate' ] );

    $self->config_sweep( $target, $rate, $time, $tail );
}

sub wait_done {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    $self->wait($tail);

}

sub abort {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );
    $self->execute_program( 0, $tail );
}

sub active {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    if ( $self->get_status( "execution", $tail ) == 0 ) {
        return 0;
    }
    else {
        return 1;
    }

}

sub wait {
    my $self   = shift;
    my ($tail) = $self->_check_args( \@_ );
    my $flag   = 1;
    local $| = 1;

    while (1) {

        #my $status = $self->get_status();
        my $execution     = $self->get_status('execution');
        my $current_level = $self->get_level($tail);
        if ( $flag <= 1.1 and $flag >= 0.9 ) {
            print "\t\t\t\t\t\t\t\t\t\r";
            print $self->get_id() . " is sweeping ($current_level )\r";

            #usleep(5e5);
        }
        elsif ( $flag <= 0 ) {
            print "\t\t\t\t\t\t\t\t\t\r";
            print $self->get_id() . " is          ($current_level ) \r";
            $flag = 2;
        }
        $flag -= 0.5;
        if ( $execution == 0 ) {
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

    # print "Yokogawa7651.pm: configuring sweep $target $time\n";
    $self->config_sweep(
        {
            points => $target,
            time   => $time
        },
        $tail
    );

    # print "Yokogawa7651.pm: executing program\n";
    $self->execute_program( 2, $tail );

    # print "Yokogawa7651.pm: waiting until done\n";
    $self->wait($tail);

    # print "Yokogawa7651.pm: reading out source level\n";
    my $current = $self->get_level($tail);

    # print "Yokogawa7651.pm: source level is $current\n";

    my $eql = $self->get_gp_equal_level();

    # my $difference=$current-$target;
    # print "Yokogawa7651.pm: c $current t $target d $difference e $eql\n";

    if ( abs( $current - $target ) > $eql ) {
        print "Yokogawa7651.pm: error current neq target\n";
        Lab::Exception::CorruptParameter->throw(
            "Sweep failed: $target not equal to $current. \n");
    }

    # print "Yokogawa7651.pm: reaching return from _sweep_to_level\n";
    return $self->device_cache()->{'level'} = $target;
}

sub get_function {
    my $self = shift;

    my ($tail) = $self->_check_args( \@_ );

    my $cmd = "OD";
    my $result = $self->query( $cmd, $tail );
    if ( $result =~ /^...([VA])/ ) {
        return ( $1 eq "V" ) ? "voltage" : "current";
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Output of command OD is not valid. \n");
    }

}

sub get_level {
    my $self = shift;
    my $cmd  = "OD";
    my $result;

    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );

    if (   not defined $read_mode
        or not $read_mode =~ /device|cache|request|fetch/ ) {
        $read_mode = $self->device_settings()->{read_default};
    }

    if ( $read_mode eq 'cache'
        and defined $self->{'device_cache'}->{'level'} ) {
        return $self->{'device_cache'}->{'level'};
    }
    elsif ( $read_mode eq 'request' and $self->{request} == 0 ) {
        $self->{request} = 1;
        $self->write($cmd);
        return;
    }
    elsif ( $read_mode eq 'request' and $self->{request} == 1 ) {
        $result = $self->read();
        $self->write($cmd);
        return;
    }
    elsif ( $read_mode eq 'fetch' and $self->{request} == 1 ) {
        $self->{request} = 0;
        $result = $self->read();
    }
    else {
        if ( $self->{request} == 1 ) {
            $result          = $self->read();
            $self->{request} = 0;
            $result          = $self->query($cmd);
        }
        else {
            $result = $self->query($cmd);
        }
    }

    $result =~ /....([\+\-\d\.E]*)/;
    return $self->{'device_cache'}->{'level'} = $1;
}

sub get_voltage {
    my $self = shift;

    my $function = $self->get_function();

    if ( $function !~ /voltage/i ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is in mode $function. Can't get voltage level." );
    }

    return $self->get_level(@_);
}

sub get_current {
    my $self = shift;

    my $function = $self->get_function();

    if ( $function !~ /current/i ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Source is in mode $function. Can't get current level." );
    }

    return $self->get_level(@_);
}

sub set_function {
    my $self = shift;
    my ($function) = $self->_check_args( \@_, ['function'] );

    if ( $function !~ /(current|voltage)/i ) {
        Lab::Exception::CorruptParameter->throw(
            "$function is not a valid source mode. Choose 1 or 5 for current and voltage mode respectively. \n"
        );
    }

    if ( $self->get_function() eq $function ) {
        return $function;
    }

    if ( $self->get_output() and $self->device_settings()->{gate_protect} ) {
        Lab::Exception::Warning->throw(
            'Cannot switch function in gate-protection mode while output is activated.'
        );
    }

    my $my_function = ( $function =~ /current/i ) ? 5 : 1;

    my $cmd = sprintf( "F%de", $my_function );

    $self->write($cmd);
    return $self->{'device_cache'}->{'function'} = $function;

}

sub set_range {
    my $self = shift;
    my ($range) = $self->_check_args( \@_, ['range'] );

    my $function = $self->get_function();

    if ( $function =~ /voltage/i ) {
        if    ( $range <= 10e-3 )  { $range = 2; }
        elsif ( $range <= 100e-3 ) { $range = 3; }
        elsif ( $range <= 1 )      { $range = 4; }
        elsif ( $range <= 10 )     { $range = 5; }
        elsif ( $range <= 30 )     { $range = 6; }
        else {
            Lab::Exception::CorruptParameter->throw( error =>
                    "unexpected value for RANGE in sub set_range. Expected values are between 10mV ... 30V and 1mA ... 100mA for voltage and current mode."
            );
        }
    }
    elsif ( $function =~ /current/i ) {
        if    ( $range <= 1e-3 )   { $range = 4; }
        elsif ( $range <= 10e-3 )  { $range = 5; }
        elsif ( $range <= 100e-3 ) { $range = 6; }
        else {
            Lab::Exception::CorruptParameter->throw( error =>
                    "unexpected value for RANGE in sub set_range. Expected values are between 10mV ... 30V and 1mA ... 100mA for voltage and current mode."
            );
        }
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "$range is not a valid source range. Read the documentation for a list of allowed ranges in mode $function.\n"
        );
    }

    #fixed voltage mode
    # 2   10mV
    # 3   100mV
    # 4   1V
    # 5   10V
    # 6   30V
    #fixed current mode
    # 4   1mA
    # 5   10mA
    # 6   100mA

    my $cmd = sprintf( "R%ue", $range );

    $self->write($cmd);
    return $self->{'device_cache'}->{'range'} = $self->get_range();
}

sub get_info {
    my $self = shift;

    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );

    if ( not defined $read_mode or not $read_mode =~ /device|cache/ ) {
        $read_mode = $self->device_settings()->{read_default};
    }

    if ( $read_mode eq 'cache' and defined $self->{'device_cache'}->{'info'} )
    {
        return $self->{'device_cache'}->{'info'};
    }

    $self->write("OS");
    my @info;
    for ( my $i = 0; $i <= 10; $i++ ) {
        my $line = $self->connection()->Read( read_length => 300 );
        if ( $line =~ /END/ ) {last}
        chomp $line;
        $line =~ s/\r//;
        push( @info, sprintf($line) );
    }

    return @{ $self->{'device_cache'}->{'info'} } = @info;
}

sub get_range {
    my $self = shift;

    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );

    if ( not defined $read_mode or not $read_mode =~ /device|cache/ ) {
        $read_mode = $self->device_settings()->{read_default};
    }

    if ( $read_mode eq 'cache'
        and defined $self->{'device_cache'}->{'range'} ) {
        return $self->{'device_cache'}->{'range'};
    }

    my $range    = ( $self->get_info() )[1];
    my $function = $self->get_function();

    if ( $range =~ /F(\d)R(\d)/ ) {
        $range = $2;

        #    printf "rangenr=$range_nr\n";
    }

    if ( $function =~ /voltage/i ) {
        $range =~ /2/ ? $range
            = 0.012
            : $range =~ /3/ ? $range
            = 0.12
            : $range =~ /4/ ? $range
            = 1.2
            : $range =~ /5/ ? $range
            = 12
            : $range =~ /6/ ? $range
            = 32
            : Lab::Exception::CorruptParameter->throw(
            "$range is not a valid voltage range. Read the documentation for a list of allowed ranges in mode $function.\n"
            );
    }
    elsif ( $function =~ /current/i ) {
        $range =~ /4/ ? $range
            = 0.0012
            : $range =~ /5/ ? $range
            = 0.012
            : $range =~ /6/ ? $range
            = 0.12
            : Lab::Exception::CorruptParameter->throw(
            "$range is not a valid current range. Read the documentation for a list of allowed ranges in mode $function.\n"
            );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "$range is not a valid source range. Read the documentation for a list of allowed ranges in mode $function.\n"
        );
    }

    return $self->{'device_cache'}->{'range'} = $range;
}

sub set_run_mode {
    my $self = shift;
    my ($value) = $self->_check_args( \@_, ['value'] );

    # $value == 0 --> REPEAT-Mode
    # $value == 1 --> SINGLE-Mode

    if ( $value eq 'repeat' or $value eq 'REPEAT' ) { $value = 0; }
    if ( $value eq 'single' or $value eq 'SINGLE' ) { $value = 1; }

    if ( $value != 0 and $value != 1 ) {
        Lab::Exception::CorruptParameter->throw(
            error => "Run Mode $value not defined\n" );
    }
    my $cmd = sprintf( "M%u", $value );
    $self->write($cmd);
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
    my $cmd = sprintf( "PI%.1f", $interval_time );
    $self->write( $cmd, $tail );
    $cmd = sprintf( "SW%.1f", $sweep_time );
    $self->write( $cmd, $tail );
}

sub set_output {
    my $self = shift;
    my ($value) = $self->_check_args( \@_, ['value'] );

    my $current_level = undef;    # for internal use only

    if ( not defined $value ) {
        return $self->get_output();
    }

    if ( $self->device_settings()->{gate_protect} ) {
        if ( $self->get_output() == 1 and $value == 0 ) {
            $self->set_level(0);
        }
        elsif ( $self->get_output() == 0 and $value == 1 ) {
            $current_level = $self->get_level();
            $self->set_level(0);
        }
    }

    $self->wait();

    if ( $value == 1 ) {
        $self->write('O1');
        $self->write('E');
        if ( defined $current_level ) {
            $self->set_level($current_level);
        }

    }
    elsif ( $value == 0 ) {
        $self->write('O0');
        $self->write('E');

    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "$value is not a valid output status (on = 1 | off = 0)");
    }

    return $self->{'device_cache'}->{'output'} = $self->get_output();

}

sub get_output {
    my $self = shift;

    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );

    if ( not defined $read_mode or not $read_mode =~ /device|cache/ ) {
        $read_mode = $self->device_settings()->{read_default};
    }

    if ( $read_mode eq 'cache'
        and defined $self->{'device_cache'}->{'output'} ) {
        return $self->{'device_cache'}->{'output'};
    }

    my $res = $self->get_status();
    return $self->{'device_cache'}->{'output'} = $res->{'output'} / 128;
}

sub initialize {
    my $self = shift;
    $self->reset();
}

sub reset {
    my $self = shift;
    $self->write('RC');

    $self->_cache_init();
}

sub set_voltage_limit {
    my $self = shift;
    my ($value) = $self->_check_args( \@_, ['value'] );

    my $cmd = sprintf( "LV%e", $value );
    $self->write($cmd);

    $self->{'device_cache'}->{'voltage_limit'} = $value;
}

sub get_voltage_limit {
    my $self = shift;

    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );

    if ( not defined $read_mode or not $read_mode =~ /device|cache/ ) {
        $read_mode = $self->device_settings()->{read_default};
    }

    if ( $read_mode eq 'cache'
        and defined $self->{'device_cache'}->{'voltage_limit'} ) {
        return $self->{'device_cache'}->{'voltage_limit'};
    }

    # read from device:
    my $limit = @{ $self->get_info() }[3];

    my @limit = split( /LA/, $limit );
    @limit = split( /LV/, $limit[0] );
    return $self->{'device_cache'}->{'voltage_limit'} = $limit[1];

}

sub set_current_limit {
    my $self = shift;
    my ($value) = $self->_check_args( \@_, ['value'] );

    my $cmd = sprintf( "LA%e", $value );
    $self->write($cmd);

    $self->{'device_cache'}->{'current_limit'} = $value;
}

sub get_current_limit {
    my $self = shift;

    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );

    if ( not defined $read_mode or not $read_mode =~ /device|cache/ ) {
        $read_mode = $self->device_settings()->{read_default};
    }

    if ( $read_mode eq 'cache'
        and defined $self->{'device_cache'}->{'current_limit'} ) {
        return $self->{'device_cache'}->{'current_limit'};
    }

    # read from device:
    my $limit = @{ $self->get_info() }[3];

    my @limit = split( /LA/, $limit );
    return $self->{'device_cache'}->{'current_limit'} = $limit[1];

}

sub get_status {
    my $self    = shift;
    my $request = shift;

    my $status = $self->query('OC');

    $status =~ /STS1=(\d*)/;
    $status = $1;
    my @flags = qw/
        CAL_switch  memory_card calibration_mode    output
        unstable    ERROR   execution   setting/;
    my $result = {};
    for ( 0 .. 7 ) {
        $result->{ $flags[$_] } = $status & 128;
        $status <<= 1;
    }
    return $result->{$request} if defined $request;
    return $result;
}

#
# Accessor implementations
#

sub autorange() {
    my $self = shift;

    return $self->{'autorange'} if scalar(@_) == 0;
    my $value = shift;

    if ( $value == 0 ) {
        $self->{'autorange'} = 0;
    }
    elsif ( $value == 1 ) {
        warn(
            "Warning: Autoranging can give you some nice voltage spikes on the Yokogawa7651. You've been warned!\n"
        );
        $self->{'autorange'} = 1;
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "Illegal value for autorange(), only 1 or 0 accepted.\n" );
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::Yokogawa7651 - Yokogawa 7651 DC source

=head1 VERSION

version 3.881

=head1 SYNOPSIS

    use Lab::Instrument::Yokogawa7651;
    
    my $gate14=new Lab::Instrument::Yokogawa7651(
      connection_type => 'LinuxGPIB',
      gpib_address => 22,
      gate_protecet => 1,
      level => 0.5,
    );
    $gate14->set_voltage(0.745);
    print $gate14->get_voltage();

=head1 DESCRIPTION

The Lab::Instrument::Yokogawa7651 class implements an interface to the
discontinued voltage and current source 7651 by Yokogawa. This class derives from
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

If you want to use the sweep function without using gate protect, you should specify

		stepsize=>0.01

Additinally there is support to set parameters for the device "on init":		

		function			=> Voltage, # specify "Voltage" or "Current" mode, string is case insensitive
		range			=> undef,
		level			=> undef,
		output					=> undef,

If those values are not specified, the current device configuration is left unaltered.

=head1 METHODS

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

=head2 sweep_to_level

	$src->sweep_to_level($lvl,$time)

Sweep to the level $lvl in $time seconds.

=head2 set_range

	$src->set_range($range)

Set the output range for the device. $range should be either in decimal or scientific notation.
Returns the newly set range.

=head2 get_info

Returns the information provided by the instrument's 'OS' command, in the form of an array
with one entry per line. For display, use join(',',$yoko->get_info()); or similar.

=head2 set_output

	$src->set_output( $onoff )

Sets the output switch to "1" (on) or "0" (off).
Returns the new output state;

=head2 get_output

Returns the status of the output switch (0 or 1).

=head2 set_voltage_limit($limit)

=head2 set_current_limit($limit)

=head2 get_status()

Returns a hash with the following keys:

    CAL_switch
    memory_card
    calibration_mode
    output
    unstable
    error
    execution
    setting

The value for each key is either 0 or 1, indicating the status of the instrument.

=head1 INSTRUMENT SPECIFICATIONS

=head2 DC voltage

The stability (24h) is the value at 23 +- 1°C. The stability (90days),
accuracy (90days) and accuracy (1year) are values at 23 +- 5°C.
The temperature coefficient is the value at 5 to 18°C and 28 to 40°C.

 Range  Maximum     Resolution  Stability 24h   Stability 90d   
        Output                  +-(% of setting +-(% of setting  
                                + µV)           + µV)            
 ------------------------------------------------------------- 
 10mV   +-12.0000mV 100nV       0.002 + 3       0.014 + 4       
 100mV  +-120.000mV 1µV         0.003 + 3       0.014 + 5       
 1V     +-1.20000V  10µV        0.001 + 10      0.008 + 50      
 10V    +-12.0000V  100µV       0.001 + 20      0.008 + 100     
 30V    +-32.000V   1mV         0.001 + 50      0.008 + 200     



 Range  Accuracy 90d    Accuracy 1yr    Temperature
        +-(% of setting +-(% of setting Coefficient
        +µV)           +µV)           +-(% of setting
                                        +µV)/°C
 -----------------------------------------------------
 10mV   0.018 + 4       0.025 + 5       0.0018 + 0.7
 100mV  0.018 + 10      0.025 + 10      0.0018 + 0.7
 1V     0.01 + 100      0.016 + 120     0.0009 + 7
 10V    0.01 + 200      0.016 + 240     0.0008 + 10
 30V    0.01 + 500      0.016 + 600     0.0008 + 30



 Range   Maximum Output              Output Noise
         Output  Resistance          DC to 10Hz  DC to 10kHz
                                     (typical data)
 ----------------------------------------------------------
 10mV    -       approx. 2Ohm        3µVp-p      30µVp-p
 100mV   -       approx. 2Ohm        5µVp-p      30µVp-p
 1V      +-120mA less than 2mOhm     15µVp-p     60µVp-p
 10V     +-120mA less than 2mOhm     50µVp-p     100µVp-p
 30V     +-120mA less than 2mOhm     150µVp-p    200µVp-p

Common mode rejection:
120dB or more (DC, 50/60Hz). (However, it is 100dB or more in the
30V range.)

=head2 DC current

 Range   Maximum     Resolution  Stability (24 h)    Stability (90 days) 
         Output                  +-(% of setting     +-(% of setting      
                                 + µA)              + µA)               
 -----------------------------------------------------------------------
 1mA     +-1.20000mA 10nA        0.0015 + 0.03       0.016 + 0.1         
 10mA    +-12.0000mA 100nA       0.0015 + 0.3        0.016 + 0.5         
 100mA   +-120.000mA 1µA         0.004  + 3          0.016 + 5           


 Range   Accuracy (90 days)  Accuracy (1 year)   Temperature  
         +-(% of setting     +-(% of setting     Coefficient     
         + µA)               + µA)               +-(% of setting  
                                                 + µA)/°C
 -----   ------------------------------------------------------  
 1mA     0.02 + 0.1          0.03 + 0.1          0.0015 + 0.01   
 10mA    0.02 + 0.5          0.03 + 0.5          0.0015 + 0.1    
 100mA   0.02 + 5            0.03 + 5            0.002  + 1


 Range  Maximum     Output                   Output Noise
        Output      Resistance          DC to 10Hz  DC to 10kHz
                                                    (typical data)
 -----------------------------------------------------------------
 1mA    +-30 V      more than 100MOhm   0.02µAp-p   0.1µAp-p
 10mA   +-30 V      more than 100MOhm   0.2µAp-p    0.3µAp-p
 100mA  +-30 V      more than 10MOhm    2µAp-p      3µAp-p

Common mode rejection: 100nA/V or more (DC, 50/60Hz).

=head1 CAVEATS

probably many

=head1 SEE ALSO

=over 4

=item * Lab::Instrument

The Yokogawa7651 class is a Lab::Instrument (L<Lab::Instrument>).

=item * Lab::Instrument::Source

The Yokogawa7651 class is a Source (L<Lab::Instrument::Source>)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2005-2006  Daniel Schroeer
            2009       Andreas K. Huettel, Daniela Taubert
            2010       Andreas K. Huettel, Daniel Schroeer
            2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner, Andreas K. Huettel, Florian Olbrich, Stefan Geissler
            2013       Alois Dirnaichner, Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2014       Alexei Iankilevitch, Alois Dirnaichner, Christian Butschkow
            2015       Andreas K. Huettel, Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
