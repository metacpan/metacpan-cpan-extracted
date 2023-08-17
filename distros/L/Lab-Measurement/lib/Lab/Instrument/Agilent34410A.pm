package Lab::Instrument::Agilent34410A;
#ABSTRACT: HP/Agilent/Keysight 34410A or 34411A digital multimeter
$Lab::Instrument::Agilent34410A::VERSION = '3.881';
use v5.20;



use warnings;
use strict;

use Time::HiRes qw (usleep);
use Lab::Instrument;
use Lab::Instrument::Multimeter;
use Lab::SCPI qw(scpi_match);
use Data::Dumper;
our @ISA = ("Lab::Instrument::Multimeter");

our %fields = (
    supported_connections => [ 'VISA_GPIB', 'GPIB', 'DEBUG', 'DUMMY' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
        timeout      => 2,
        read_default => "device",
        termchar     => "\n"
    },

    device_settings => {
        pl_freq => 50,
    },

    device_cache => {
        'function'   => undef,
        'range'      => undef,
        'nplc'       => undef,
        'resolution' => undef,
        'tc'         => undef,
        'bw'         => undef,
    },

    device_cache_order =>
        [ 'function', 'range', 'nplc', 'resolution', 'tc', 'bw' ],

);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->_construct($class);

    # Perform initial device clear.
    $self->clear();

    return $self;
}


sub get_value {
    my ( $self, $tail ) = _init_getter(@_);

    return $self->request( ":read?", $tail );
}


sub get_error {
    my $self = shift;
    chomp( my $err = $self->query("SYSTem:ERRor?") );
    my ( $err_num, $err_msg ) = split ",", $err;
    $err_msg =~ s/\"//g;
    return ( $err_num, $err_msg );
}


sub reset {    # basic
    my $self = shift;
    $self->write("*RST");
    $self->reset_device_cache();
}


# to be moved into Lab::Instrument::Multimeter??
sub assert_function {
    my $self    = shift;
    my $keyword = shift;

    my $function = $self->get_function( { read_mode => 'cache' } );
    if ( scpi_match( $function, $keyword ) == 0 ) {
        Lab::Exception::CorruptParameter->throw(
            "invalid function '$function': allowed choices are: $keyword");
    }
    return $function;
}

# ------------------------------- SENSE ---------------------------------

my $valid_functions
    = 'current[:dc]|current:ac|voltage[:dc]|voltage[:ac]|resistance|fresistance';


sub set_function {    # basic
    my $self = shift;

    my ( $function, $tail ) = $self->_check_args_strict( \@_, ['function'] );

    if ( not scpi_match( $function, $valid_functions ) ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Agilent 34410A:\n\nAgilent 34410A:\nunexpected value for FUNCTION in sub set_function. Expected values are VOLTAGE:DC, VOLTAGE:AC, CURRENT:DC, CURRENT:AC, RESISTANCE or FRESISTANCE.\n"
        );
    }

    $self->write( "FUNCTION '$function'", $tail );

}


sub get_function {
    my $self = shift;

    # read from cache or from device?
    my ($tail) = $self->_check_args( \@_, [] );

    # read from device:
    my $function = $self->query( "FUNCTION?", $tail );
    if ( $function =~ /([\w:]+)/ ) {
        return $1;
    }

    # FIXME: throw here?
}


sub _invalid_range {
    my $range = shift;
    Lab::Exception::CorruptParameter->throw( error =>
            "set_range: unexpected value '$range' for RANGE. Expected values are for CURRENT, VOLTAGE and RESISTANCE mode -3...+3A, 0.1...1000V or 0...1e9 Ohms respectivly"
    );
}

sub _check_range {
    my $function = shift;
    my $range    = shift;

    if ( scpi_match( $function, 'voltage[:dc]|voltage:ac' ) ) {
        if ( abs($range) > 1000 ) {
            _invalid_range($range);
        }
    }
    elsif ( scpi_match( $function, 'current[:dc]|current:ac' ) ) {
        if ( abs($range) > 3 ) {
            _invalid_range($range);
        }
    }
    elsif ( scpi_match( $function, 'resistance|fresistance' ) ) {
        if ( $range < 0 or $range > 1e9 ) {
            _invalid_range($range);
        }
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "set_range: Unexpected function '$function'. Expected values are VOLTAGE:DC, VOLTAGE:AC, CURRENT:DC, CURRENT:AC, RESISTANCE or FRESISTANCE."
        );
    }
}

sub set_range {    # basic
    my $self = shift;

    my ( $range, $tail ) = $self->_check_args_strict( \@_, ['range'] );
    my $function = $self->get_function( { read_mode => 'cache' } );

    # check if value of paramter 'range' is valid:

    if ( not scpi_match( $range, 'min|max|def|auto' ) ) {
        _check_range( $function, $range );
    }

    # set range
    if ( scpi_match( $range, 'min|max|def' )
        or $range =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ ) {
        $self->write( "$function:RANGE $range", $tail );
    }
    elsif ( scpi_match( $range, 'auto' ) ) {
        $self->write( sprintf( "%s:RANGE:AUTO ON", $function ), $tail );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            error => "anything's wrong in sub set_range!!" );
    }
}

sub _init_getter {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );
    return ( $self, $tail );
}


sub get_range {
    my ( $self, $tail ) = _init_getter(@_);

    my $function = $self->assert_function($valid_functions);

    return $self->query( "$function:RANGE?", $tail );
}


sub get_autorange {
    my ( $self, $tail ) = _init_getter(@_);
    my $function = $self->assert_function($valid_functions);

    return $self->query("$function:RANGE:AUTO?");
}

my $valid_dc_functions = 'current[:dc]|voltage[:dc]|resistance|fresistance';


sub set_nplc {    # basic
    my $self = shift;

    my ( $nplc, $tail ) = $self->_check_args_strict( \@_, ['nplc'] );

    # check if value of paramter 'nplc' is valid:
    if ( ( $nplc < 0.006 or $nplc > 100 ) and not $nplc =~ /^(min|max|def)$/ )
    {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for NPLC in sub set_nplc. Expected values are between 0.006 ... 100 power-line-cycles (50Hz)."
        );
    }

    # set nplc:
    my $function = $self->assert_function($valid_dc_functions);

    $self->write( "$function:NPLC $nplc", $tail );
}


sub get_nplc {
    my ( $self, $tail ) = _init_getter(@_);

    my $function = $self->assert_function($valid_dc_functions);

    return $self->query( "$function:NPLC?", $tail );
}


sub set_resolution {    # basic
    my $self = shift;
    my ( $resolution, $tail )
        = $self->_check_args_strict( \@_, ['resolution'] );
    my $function = $self->assert_function($valid_dc_functions);

    # check if value of paramter 'resolution' is valid:
    # FIXME: wiso read_mode 'device' ???
    my $range = $self->get_range( { read_mode => 'device' } );

    if ( $resolution < 0.3e-6 * $range
        and not $resolution =~ /^(min|max|def)$/ ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "\nAgilent 34410A:\nunexpected value for RESOLUTION in sub set_resolution. Expected values have to be greater than 0.3e-6*RANGE."
        );
    }

    # switch off autorange function if activated.
    $self->set_range($range);
    $self->write( "$function:RES $resolution", $tail );

}


sub get_resolution {
    my ( $self, $tail ) = _init_getter(@_);

    my $function = $self->assert_function($valid_functions);

    return $self->query( "$function:RES?", $tail );
}


sub set_tc {    # basic
    my $self = shift;

    my ( $tc, $tail ) = $self->_check_args_strict( \@_, ['tc'] );

    my $function = $self->assert_function($valid_dc_functions);

    # check if value of paramter 'tc' is valid:
    if ( ( $tc < 1e-4 or $tc > 1 ) and not $tc =~ /^(min|max|def)$/ ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for APERTURE in sub set_tc. Expected values are between 1e-4 ... 1 sec."
        );
    }

    # set tc:
    $self->write( ":$function:APERTURE $tc; APERTURE:ENABLED 1", $tail );
}


sub get_tc {
    my ( $self, $tail ) = _init_getter(@_);

    my $function = $self->assert_function($valid_dc_functions);

    return $self->query( "$function:APERTURE?", $tail );
}

my $valid_ac_functions = 'current:ac|voltage:ac';


sub set_bw {    # basic
    my $self = shift;
    my ( $bw, $tail ) = $self->_check_args_strict( \@_, ['bandwidth'] );

    my $function = $self->assert_function($valid_ac_functions);

    # check if value of paramter 'bw' is valid:
    if ( ( $bw < 3 or $bw > 200 ) and not $bw =~ /^(min|max|def)$/ ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "\nAgilent 34410A:\nunexpected value for BANDWIDTH in sub set_bw. Expected values are between 3 ... 200 Hz."
        );
    }

    # set bw:
    $self->write( "$function:BANDWIDTH $bw", $tail );
}


sub get_bw {
    my ( $self, $tail ) = _init_getter(@_);

    my $function = $self->assert_function($valid_ac_functions);

    return $self->query( "$function:BANDWIDTH?", $tail );
}

# ----------------------------- TAKE DATA ---------------------------------------------------------


sub config_measurement {    # basic
    my $self = shift;

    # parameter == hash??
    my ( $function, $nop, $time, $range, $trigger ) = $self->_check_args(
        \@_,
        [ 'function', 'nop', 'time', 'range', 'trigger' ]
    );

    # check input data
    if ( not defined $trigger ) {
        $trigger = 'BUS';
    }
    if ( not defined $range ) {
        $range = 'DEF';
    }
    if ( not defined $time ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "too view arguments given in sub config_measurement. Expected arguments are FUNCTION, #POINTS, TIME, <RANGE>, <TRIGGERSOURCE>"
        );
    }

    print "--------------------------------------\n";
    print "Agilent34410A: sub config_measurement:\n";

    # clear buffer
    my $points = $self->query( "DATA:POINTS?", { read_mode => 'device' } );
    if ( $points > 0 ) {
        $points = $self->connection()
            ->LongQuery( command => "DATA:REMOVE? $points" );
    }

    # set function
    print "set_function: " . $self->set_function($function) . "\n";

    # set range
    print "set_range: " . $self->set_range($range) . "\n";

    # set integration time
    my $tc = $time / $nop;
    print "set_tc: " . $self->set_tc($tc) . "\n";

    # set auto high impedance (>10GOhm) for VOLTAGE:DC for ranges 100mV, 1V, 10V
    if ( $function
        =~ /^(VOLTAGE|voltage|VOLT|volt|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc)$/
        ) {
        print "set_auto_high_impedance\n";
        $self->write("SENS:VOLTAGE:DC:IMPEDANCE:AUTO ON");
    }

    # perfome AUTOZERO and then disable
    if ( $function
        =~ /^(CURRENT|current|CURR|curr|CURRENT:DC|current:dc|CURR:DC|curr:dc|VOLTAGE|voltage|VOLT|volt|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc|RESISTANCE|resistance|RES|res|FRESISTANCE|fresistance|FRES|fres)$/
        ) {
        print "set_AUTOZERO OFF\n";
        $self->write( sprintf( "SENS:%s:ZERO:AUTO OFF", $function ) );
    }

    # triggering
    print "set Trigger Source: " . $self->_set_triggersource("BUS") . "\n";
    print "set Trigger Count: " . $self->_set_triggercount(1) . "\n";
    print "set Trigger Delay: " . $self->_set_triggerdelay("MIN") . "\n";

    print "set Sample Count: " . $self->_set_samplecount($nop) . "\n";
    print "set Sample Delay: " . $self->_set_sampledelay(0) . "\n";

    print "init()\n";
    $self->write("INIT");
    usleep(5e5);

    print "Agilent34410A: sub config_measurement complete\n";
    print "--------------------------------------\n";

}


sub trg {    # basic
    my $self = shift;
    $self->write("*TRG");
}


sub get_data {    # basic
    my $self = shift;
    my $data;
    my @data;

    # parameter == hash??
    my ($readings) = $self->_check_args( \@_, ['readings'] );

    if ( not defined $readings ) { $readings = "ALL"; }

    if ( $readings >= 1 and $readings <= 50000 ) {
        if ( $readings > $self->query("SAMPLE:COUNT?") ) {
            $readings = $self->query("SAMPLE:COUNT?");
        }
        for ( my $i = 1; $i <= $readings; $i++ ) {
            my $break = 1;
            while ($break) {
                $data = $self->connection()->LongQuery( command => "R? 1" );

                my $index;
                if ( index( $data, "+" ) == -1 ) {
                    $index = index( $data, "-" );
                }
                elsif ( index( $data, "-" ) == -1 ) {
                    $index = index( $data, "+" );
                }
                else {
                    $index
                        = ( index( $data, "-" ) < index( $data, "+" ) )
                        ? index( $data, "-" )
                        : index( $data, "+" );
                }
                $data = substr( $data, $index, length($data) - $index );
                if ( $data != 0 ) { $break = 0; }
                else              { usleep(1e5); }
            }
            push( @data, $data );
        }
        if   ( $readings == 1 ) { return $data; }
        else                    { return @data; }
    }
    elsif ( $readings eq "ALL" or $readings = "all" ) {

        # wait until data are available
        $self->wait();
        $data = $self->connection()->LongQuery( command => "FETC?" );

        @data = split( ",", $data );
        return @data;
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for number of readINGS in sub get_data. Expected values are from 1 ... 50000 or ALL."
        );
    }

}


sub abort {    # basic
    my $self = shift;
    $self->write("ABOR");
}


sub wait {     # basic
    my $self = shift;

    while (1) {
        if   ( $self->active() ) { usleep(1e3); }
        else                     { last; }
    }

    return 0;

}


sub active {    # basic
    my $self = shift;

    my $status = sprintf(
        "%.15b",
        $self->query( "STAT:OPER:COND?", { read_mode => 'device' } )
    );
    my @status = split( "", $status );
    if ( $status[5] == 1 && $status[10] == 0 ) {
        return 0;
    }
    else {
        return 1;
    }

}

# ------------------ TRIGGER and SAMPLE settings ---------------------- #

sub _set_triggersource {    # internal
    my $self = shift;

    # parameter == hash??
    my ($source) = $self->_check_args( \@_, ['trigger_source'] );

    if ( not defined $source ) {
        $source = $self->query( sprintf("TRIGGER:SOURCE?") );

        $self->{config}->{triggersource} = $source;
        return $source;
    }

    if ( $source =~ /^(IMM|imm|EXT|ext|BUS|bus|INT|int)$/ ) {
        $source = $self->query(
            sprintf( "TRIGGER:SOURCE %s; SOURCE?", $source ) );
        $self->{config}->{triggersource} = $source;
        return $source;
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "\nAgilent 34410A:\nunexpected value for TRIGGER_SOURCE in sub _set_triggersource. Expected values are:\n IMM  --> immediate trigger signal\n EXT  --> external trigger\n BUS  --> software trigger signal via bus\n INT  --> internal trigger signal\n"
        );
    }

}

sub _set_triggercount {    # internal
    my $self = shift;

    # parameter == hash??
    my ($count) = $self->_check_args( \@_, ['trigger_count'] );

    if ( not defined $count ) {
        $count = $self->query( sprintf("TRIGGER:COUNT?") );

        $self->{config}->{triggercount} = $count;
        return $count;
    }

    if ( $count >= 0 or $count <= 50000 ) {
        $count
            = $self->query( sprintf( "TRIGGER:COUNT %d; COUNT?", $count ) );
        $self->{config}->{triggercount} = $count;
        return $count;
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "\nAgilent 34410A:\nunexpected value for COUNT in sub _set_triggercount. Expected values are between 1 ... 50.000\n"
        );
    }

}

sub _set_triggerdelay {    # internal
    my $self = shift;

    # parameter == hash??
    my ($delay) = $self->_check_args( \@_, ['trigger_delay'] );

    if ( not defined $delay ) {
        $delay = $self->query( sprintf("TRIGGER:DELAY?") );

        $self->{config}->{triggerdely} = $delay;
        return $delay;
    }

    if ( $delay =~ /^(min|max|def)$/i or $delay >= 0 or $delay <= 3600 ) {
        $delay = $self->query("TRIGGER:DELAY $delay; DELAY?");
        $self->{config}->{triggerdely} = $delay;
        return $delay;
    }
    elsif ( $delay =~ /^(AUTO|auto)$/ ) {
        $delay = $self->query("TRIGGER:DELAY:AUTO ON; AUTO?");
        $self->{config}->{triggerdely} = "AUTO ON";
        return "AUTO ON";
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "\nAgilent 34410A:\nunexpected value for DELAY in sub _set_triggerdelay. Expected values are between 1 ... 3600, or 'MIN = 0', 'MAX = 3600' or 'AUTO'\n"
        );
    }
}

sub _set_samplecount {    # internal
    my $self = shift;

    # parameter == hash??
    my ($count) = $self->_check_args( \@_, ['sample_count'] );

    if ( not defined $count ) {
        $count = $self->query( sprintf("SAMPLE:COUNT?") );

        $self->{config}->{samplecount} = $count;
        return $count;
    }

    elsif ( $count < 0 or $count >= 50000 ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "\nAgilent 34410A:\nunexpected value for COUNT in sub _set_samplecount. Expected values are between 1 ... 50.000\n"
        );
    }
    else {
        $count = $self->query( sprintf( "SAMPLE:COUNT %d; COUNT?", $count ) );
        $self->{config}->{samplecount} = $count;
        return $count;
    }
}

sub _set_sampledelay {    # internal
    my $self = shift;

    # parameter == hash??
    my ($delay) = $self->_check_args( \@_, ['sample_delay'] );

    if ( not defined $delay ) {
        $delay = $self->query( sprintf("SAMPLE:TIMER?") );

        $self->{config}->{sampledelay} = $delay;
        return $delay;
    }

    if ( $delay =~ /^(MIN|min|MAX|max|DEF|def)$/ ) {
        $delay = $self->query( sprintf( "SAMPLE:TIMER %s; TIMER?", $delay ) );
        $self->write("SAMPLE:SOURCE TIM");
        $self->{config}->{samplecount} = $delay;
        return $delay;
    }
    elsif ( $delay >= 0 or $delay <= 3600 ) {
        $delay
            = $self->query( sprintf( "SAMPLE:TIMER  %.5f; TIMER?", $delay ) );
        $self->write("SAMPLE:SOURCE TIM");
        $self->{config}->{samplecount} = $delay;
        return $delay;
    }

    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "\nAgilent 34410A:\nunexpected value for DELAY in sub _set_sampledelay. Expected values are between 1 ... 3600, or 'MIN = 0', 'MAX = 3600'\n"
        );
    }

}

# ------------------------------- DISPLAY and BEEPER --------------------------------------------


sub display_text {    # basic
    my $self = shift;

    # parameter == hash??
    my ($text) = $self->_check_args( \@_, ['display_text'] );

    if ($text) {
        $self->write(qq(DISPlay:TEXT "$text"));
    }
    else {
        $text = $self->query(qq(DISPlay:TEXT?));
        $text =~ s/\"//g;
    }
    return $text;
}


sub display_on {    # basic
    my $self = shift;
    $self->write("DISPLAY ON");
}



sub display_off {    # basic
    my $self = shift;
    $self->write("DISPLAY OFF");
}


sub display_clear {    # basic
    my $self = shift;
    $self->write("DISPLAY:TEXT:CLEAR");
}


sub beep {             # basic
    my $self = shift;
    $self->write("SYSTEM:BEEPER");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::Agilent34410A - HP/Agilent/Keysight 34410A or 34411A digital multimeter

=head1 VERSION

version 3.881

=head1 SYNOPSIS

 use Lab::Instrument::Agilent34410A;
 my $multimeter = Lab::Instrument::Agilent34410A->new(%options);

 print $multimeter->get_value();

=head1 DESCRIPTION

The Lab::Instrument::Agilent34410A class implements an interface to the 34410A
and 34411A digital multimeters by Agilent (now Keysight, formerly HP).

=head1 METHODS

=head2 new(%options)

This method is described in L<Lab::Measurement::Tutorial> and
L<Lab::Instrument>.

=head2 get_value()

Perform data aquisition.

 my $value = $multimeter->get_value();

=head2 get_error()

 my ($err_num, $err_msg) = $agilent->get_error();

Query the multimeter's error queue. Up to 20 errors can be stored in the
queue. Errors are retrieved in first-in-first out (FIFO) order.

=head2 reset()

 $agilent->reset();

Reset the multimeter to its power-on configuration.

=head2 assert_function($keyword)

Throw if the instrument is not in one of the operating modes given in
C<$keyword>. See L<Lab::SCPI> for the keyword syntax.

=head2 set_function($function)

Set a new value for the measurement function of the Agilent34410A.

C<$function> can be one of the measurement methods of the Agilent34410A.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=head2 get_function()

Return the used measurement function.

=head2 set_range($range)

Set the range of the used measurement function to C<$range>.

C<RANGE> is given in terms of amps, volts or ohms and can be C<-3...+3A | MIN | MAX | DEF | AUTO>, C<100mV...1000V | MIN | MAX | DEF | AUTO> or C<0...1e9 | MIN | MAX | DEF | AUTO>.	
C<DEF> is default C<AUTO> activates the C<AUTORANGE-mode>.
C<DEF> will be set, if no value is given.

=head2 get_range()

Return the range of the used measurement function.

=head2 get_autorange()

Return non-zero, if autoranging is enabled.

=head2 set_nplc($nplc)

Set a new value for the predefined C<NUMBER of POWER LINE CYCLES> for the
used measurement function.

The C<NUMBER of POWER LINE CYCLES> is actually something similar to an integration time for recording a single measurement value.
The values for C<$nplc> can be any value between 0.006 ... 100 but internally the Agilent34410A selects the value closest to one of the following fixed values C< 0.006 | 0.02 | 0.06 | 0.2 | 1 | 2 | 10 | 100 | MIN | MAX | DEF >.

Example: 
Assuming C<$nplc> to be 10 and assuming a netfrequency of 50Hz this results in an integration time of 10*50Hz = 0.2 seconds for each measured value. 

NOTE:
1.) Only those integration times set to an integral number of power line cycles (1, 2, 10, or 100 PLCs) provide normal mode (line frequency noise) rejection.
2.) Setting the integration time also sets the resolution for the measurement. The following table shows the relationship between integration time and resolution. 

	Integration Time (power line cycles)		 Resolution
	0.001 PLC  (34411A only)			30 ppm x Range
	0.002 PLC  (34411A only)			15 ppm x Range
	0.006 PLC					6.0 ppm x Range
	0.02 PLC					3.0 ppm x Range
	0.06 PLC					1.5 ppm x Range
	0.2 PLC						0.7 ppm x Range
	1 PLC (default)					0.3 ppm x Range
	2 PLC						0.2 ppm x Range
	10 PLC						0.1 ppm x Range
	100 PLC 					0.03 ppm x Range

=head2 get_nplc()

Return the value of C<nplc> for the used measurement function.

=head2 set_resolution($resolution)

Set a new resolution for the used measurement function.

Give the current value C<RANGE> of the current range,
C<$resolution> is given in terms of C<$resolution * RANGE> or C<[MIN|MAX|DEF]>.
C<$resolution=0.0001> means 4 1/2 digits for example.
$resolution must be larger than 0.3e-6xRANGE.
The best resolution is range = 100mV ==> resoltuion = 3e-8V
C<DEF> will be set, if no value is given.

=head2 get_resolution()

Return the resolution of the used measurement function.

=head2 set_tc($tc)

Set a new value for the predefined C<INTEGRATION TIME> for the used measurement
function.

C<INTEGRATION TIME> $tc can be C< 1e-4 ... 1s | MIN | MAX | DEF>.

NOTE: 
1.) Only those integration times set to an integral number of power line cycles
(1, 2, 10, or 100 PLCs) provide normal mode (line frequency noise) rejection. 
2.) Setting the integration time also sets the resolution for the
measurement. The following table shows the relationship between integration
time and resolution.  

	Integration Time (power line cycles)		 Resolution
	0.001 PLC  (34411A only)			30 ppm x Range
	0.002 PLC  (34411A only)			15 ppm x Range
	0.006 PLC					6.0 ppm x Range
	0.02 PLC					3.0 ppm x Range
	0.06 PLC					1.5 ppm x Range
	0.2 PLC						0.7 ppm x Range
	1 PLC (default)					0.3 ppm x Range
	2 PLC						0.2 ppm x Range
	10 PLC						0.1 ppm x Range
	100 PLC 					0.03 ppm x Range

=head2 get_tc()

Return the C<INTEGRATION TIME> of the used measurement function.

=head2 set_bw($bw)

Set a new C<BANDWIDTH> for the used measurement function, which must be 
C<VOLTAGE:AC> or C<CURRENT:AC>.

C<$bw> can be C< 3 ... 200Hz | MIN | MAX | DEF>.

=head2 get_bw()

Return the bandwidth of the used measurement function, which must be
C<VOLTAGE:AC> or C<CURRENT:AC>.

=head2 config_measurement

	old style:
	$agilent->config_measurement($function, $number_of_points, <$time>, <$range>);
	
	new style:
	$agilent->config_measurement({
		'function' => $function, 
		'nop' => $number_of_points,
		'time' => <$time>, 
		'range' => <$range>
		});

Preset the Agilent34410A for a TRIGGERED measurement.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Agilent34410A.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resistance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $number_of_points

Preset the C<NUMBER OF POINTS> to be taken for one measurement trace.
The single measured points will be stored in the internal memory of the Agilent34410A.
For the Agilent34410A the internal memory is limited to 50.000 values.	

=item <$time>

Preset the C<TIME> duration for one full trace. From C<TIME> the integration time value for each measurement point will be derived [TC = (TIME *50Hz)/NOP].
Expected values are between 0.0001*NOP ... 1*NOP seconds.

=item <$range>

C<RANGE> is given in terms of amps, volts or ohms and can be C< -3...+3A | MIN | MAX | DEF | AUTO >, C< 100mV...1000V | MIN | MAX | DEF | AUTO > or C< 0...1e9 | MIN | MAX | DEF | AUTO >.	
C<DEF> is default C<AUTO> activates the AUTORANGE-mode.
C<DEF> will be set, if no value is given.

=back

=head2 trg()

 $agilent->trg();

Sends a trigger signal via the C<GPIB-BUS> to start the predefined measurement.
The LabVisa-script can immediatally be continued, e.g. to start another
triggered measurement using a second Agilent34410A. 

=head2 get_data($readings)

reads all recorded values from the internal buffer and returnes them as an array of floatingpoint values.
reading the buffer will start immediately. The LabVisa-script cannot be continued until all requested readings have been recieved.

=over 4

=item <$readings>

C<readINGS> can be a number between 1 and 50.000 or 'ALL' to specifiy the number of values to be read from the buffer.
If $readings is not defined, the default value "ALL" will be used.

=back

=head2 abort()

Aborts current (triggered) measurement.

=head2 wait()

Wait until triggered measurement has been finished.

=head2 active()

Returns '1' if the current triggered measurement is still active and '0' if the current triggered measurement has allready been finished.

=head2 display_text($text)

Display C<$text> on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.

Without parameter, the displayed message is returned.

=head2 display_on()

Turn the front-panel display on.

=head2 display_off()

Turn the front-panel display off.

=head2 display_off

	$agilent->display_off();

Turn the front-panel display off.

=head2 display_clear()

Clear the message displayed on the front panel.

=head2 beep()

Issue a single beep immediately.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Andreas K. Huettel, Stefan Geissler
            2013       Alois Dirnaichner, Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2014       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
