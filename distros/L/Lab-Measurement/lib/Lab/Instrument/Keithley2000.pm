package Lab::Instrument::Keithley2000;
#ABSTRACT: Keithley 2000 digital multimeter
$Lab::Instrument::Keithley2000::VERSION = '3.881';
use v5.20;

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our @ISA = ('Lab::Instrument');

our %fields = (
    supported_connections =>
        [ 'VISA', 'VISA_GPIB', 'GPIB', 'RS232', 'VISA_RS232', 'DEBUG' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => undef,
        gpib_address => undef,
        timeout      => 2,
    },

    device_settings => {},

    device_cache => {

        }

);

# ---------------------- Init DMM --------------------------------------------------------
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);
    $self->write('INIT:CONT OFF');
    return $self;
}

sub reset {    # basic
    my $self = shift;
    $self->write("*RST");
    return;
}

# ----------------------- Config DMM ------------------------------------------------------

sub set_function {    # basic
    my $self = shift;
    my ($function) = $self->_check_args( \@_, ['function'] );

    if ( $function
        =~ /\b(PERIOD|period|PER|per|FREQUENCY|frequency|FREQ|freq|TEMPERATURE|temperature|TEMP|temp|DIODE|diode|DIOD|diod","CURRENT|current|CURR|curr|CURRENT:AC|current:ac|CURR:AC|curr:ac","CURRENT:DC|current:dc|CURR:DC|curr:dc|VOLTAGE|voltage|VOLT|volt|VOLTAGE:AC|voltage:ac|VOLT:AC|volt:ac|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc|RESISTANCE|resisitance|RES|res|FRESISTANCE|fresistance|FRES|fres)\b/
        ) {
        return $self->query(
            sprintf( ":SENSE:FUNCTION '%s'; FUNCTION?", $function ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value in sub config_function. Function can be CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, PERIOD, FREQUENCY, TEMPERATURE, DIODE"
        );
    }
}

sub get_function {
    my $self     = shift;
    my $function = $self->query(":SENSE:FUNCTION?");
    return substr( $function, 1, -1 );    # cut off quotes ""
}

sub set_range {                           # basic
    my $self = shift;
    my ( $range, $function )
        = $self->_check_args( \@_, [ 'range', 'function' ] );

    # return settings

    if ( not defined $function ) {
        $function = $self->get_function();
    }

    #set range
    if ( $function
        =~ /\b(CURRENT|current|CURR|curr|CURRENT:AC|current:ac|CURR:AC|curr:ac","CURRENT:DC|current:dc|CURR:DC|curr:dc)\b/
        ) {
        if ( $range =~ /\b(AUTO|auto|MIN|min|MAX|max|DEF|def)\b/ ) {

            #pass
        }
        elsif ( ( $range >= 0 && $range <= 3.03 ) ) {
            $range = sprintf( "%.2f", $range );
        }
        else {
            Lab::Exception::CorruptParameter->throw( error =>
                    "unexpected value in sub config_range for 'RANGE'. Must be between 0 and 3.03."
            );
        }
    }

    elsif ( $function =~ /\b(VOLTAGE:AC|voltage:ac|VOLT:AC|volt:ac)\b/ ) {
        if ( $range =~ /\b(AUTO|auto|MIN|min|MAX|max|DEF|def)\b/ ) {

            #pass
        }
        elsif ( ( $range >= 0 && $range <= 757.5 ) ) {
            $range = sprintf( "%.1f", $range );
        }
        else {
            Lab::Exception::CorruptParameter->throw( error =>
                    "unexpected value in sub config_range for 'RANGE'. Must be between 0 and 757.5."
            );
        }
    }
    elsif ( $function
        =~ /\b(VOLTAGE|voltage|VOLT|volt|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc)\b/
        ) {
        if ( $range =~ /\b(AUTO|auto|MIN|min|MAX|max|DEF|def)\b/ ) {

            #pass
        }
        elsif ( ( $range >= 0 && $range <= 1010 ) ) {
            $range = sprintf( "%.1f", $range );
        }
        else {
            Lab::Exception::CorruptParameter->throw( error =>
                    "unexpected value in sub config_range for 'RANGE'. Must be between 0 and 1010."
            );
        }
    }
    elsif ( $function
        =~ /\b(RESISTANCE|resisitance|RES|res|FRESISTANCE|fresistance|FRES|fres)\b/
        ) {
        if ( $range =~ /\b(AUTO|auto|MIN|min|MAX|max|DEF|def)\b/ ) {

            #pass
        }
        elsif ( ( $range >= 0 && $range <= 101e6 ) ) {
            $range = sprintf( "%d", $range );
        }
        else {
            Lab::Exception::CorruptParameter->throw( error =>
                    "unexpected value in sub config_range for 'RANGE'. Must be between 0 and 101E6."
            );
        }
    }
    elsif ( $function =~ /\b(DIODE|DIOD|diode|diod)\b/ ) {
        $function = "DIOD:CURRENT";
        if ( $range < 0 || $range > 1e-3 ) {
            Lab::Exception::CorruptParameter->throw( error =>
                    "unexpected value in sub config_range for 'RANGE'. Must be between 0 and 1E-3."
            );
        }
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value in sub set_range. Function can be CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE"
        );
    }

    # set range
    if ( $range =~ /\b(AUTO|auto)\b/ ) {
        $self->write( sprintf( ":SENSE:%s:RANGE:AUTO ON", $function ) );
    }
    elsif ( $range =~ /\b(MIN|min|MAX|max|DEF|def)\b/ ) {
        $self->write( sprintf( ":SENSE:%s:RANGE %s", $function, $range ) );
    }
    else {
        $self->write( sprintf( ":SENSE:%s:RANGE %.2f", $function, $range ) );
    }
    return;

}

sub get_range {
    my $self = shift;
    my ($function) = $self->_check_args( \@_, ['function'] );

    if ( not defined $function ) {
        $function = $self->get_function();
    }
    if (
        not $function
        =~ /\b(PERIOD|period|PER|per|FREQUENCY|frequency|FREQ|freq|TEMPERATURE|temperature|TEMP|temp|DIODE|diode|DIOD|diod","CURRENT|current|CURR|curr|CURRENT:AC|current:ac|CURR:AC|curr:ac","CURRENT:DC|current:dc|CURR:DC|curr:dc|VOLTAGE|voltage|VOLT|volt|VOLTAGE:AC|voltage:ac|VOLT:AC|volt:ac|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc|RESISTANCE|resisitance|RES|res|FRESISTANCE|fresistance|FRES|fres)\b/
        ) {
        Lab::Exception::CorruptParameter->throw(
            error => "unexpected value for FUNCTION in sub get_range." );
    }

    my $range = $self->query(":SENSE:$function:RANGE?");
    return $range;
}

sub set_nplc {    # basic
    my $self = shift;
    my ( $nplc, $function )
        = $self->_check_args( \@_, [ 'nplc', 'function' ] );

    # return settings if no new values are given
    if ( not defined $function ) {
        $function = $self->get_function();
    }

    if ( ( $nplc < 0.01 && $nplc > 10 )
        and not $nplc =~ /\b(MAX|max|MIN|min|DEF|def)\b/ ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for NPLC in sub set_sense_nplc. Expected values are between 0.01 and 1000 POWER LINE CYCLES or MIN/MAX/DEF."
        );
    }

    if ( $function
        =~ /\b(CURRENT|CURR|current|curr|VOLTAGE|VOLT|voltage|volt|RESISTANCE|RES|resistance|res)\b/
        ) {
        if ( $nplc =~ /\b(MAX|max|MIN|min|DEF|def)\b/ ) {
            return $self->query(
                sprintf( ":SENSE:%s:NPLC %s; NPLC?", $function, $nplc ) );
        }
        elsif ( $nplc =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ ) {
            return $self->query(
                sprintf( ":SENSE:%s:NPLC %e; NPLC?", $function, $nplc ) );
        }
        else {
            Lab::Exception::CorruptParameter->throw( error =>
                    "unexpected value for NPLC in sub set_sense_nplc. Expected values are between 0.01 and 10 POWER LINE CYCLES or MIN/MAX/DEF."
            );
        }
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for FUNCTION in sub set_sense_nplc. Expected values are CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, TEMPERATURE"
        );
    }
}

sub get_nplc {
    my $self = shift;
    my ($function) = $self->_check_args( \@_, ['function'] );

    if ( not defined $function ) {
        $function = $self->get_function();
    }
    if (
        not $function
        =~ /\b(PERIOD|period|PER|per|FREQUENCY|frequency|FREQ|freq|TEMPERATURE|temperature|TEMP|temp|DIODE|diode|DIOD|diod","CURRENT|current|CURR|curr|CURRENT:AC|current:ac|CURR:AC|curr:ac","CURRENT:DC|current:dc|CURR:DC|curr:dc|VOLTAGE|voltage|VOLT|volt|VOLTAGE:AC|voltage:ac|VOLT:AC|volt:ac|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc|RESISTANCE|resisitance|RES|res|FRESISTANCE|fresistance|FRES|fres)\b/
        ) {
        Lab::Exception::CorruptParameter->throw(
            error => "unexpected value for FUNCTION in sub get_nplc." );
    }

    my $nplc = $self->query(":SENSE:$function:NPLC?");

    return $nplc;
}

sub set_averaging {    # advanced
    my $self = shift;
    my ( $count, $mode, $function )
        = $self->_check_args( \@_, [ 'count', 'mode', 'function' ] );

    if ( not defined $function ) {
        $function = $self->get_function();    # get selected function
    }

    if ( not defined $mode ) {
        $mode = "REPEAT";
    }    # set REPeating as standard value; MOVing would be 2nd option

    if ( $mode =~ /\b(REPEAT|repeat|MOVING|moving)\b/ ) {
        if ( $count >= 0.5 and $count <= 100.5 ) {

            # set averaging
            $self->write(":SENSE:$function:AVERAGE:STATE ON");
            $self->write(":SENSE:$function:AVERAGE:TCONTROL $mode");

            if (   $count =~ /\b(MIN|min|MAX|max|DEF|def)\b/
                or $count =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ ) {
                $count
                    = $self->query(
                    ":SENSE:$function:AVERAGE:COUNT $count; STATE?; COUNT?; TCONTROL?"
                    );
                my $result;
                (
                    $result->{'state'}, $result->{'count'},
                    $result->{'tcontrol'}
                ) = split( /;/, $count );
                return $result;
            }
        }
        elsif ( $count =~ /\b(OFF|off)\b/ or $count == 0 ) {
            $self->write(":SENSE:$function:AVERAGE:STATE OFF")
                ;    # switch OFF Averaging
            $count = $self->query(
                ":SENSE:$function:AVERAGE:STATE?; COUNT?; TCONTROL?");
            my $result;
            ( $result->{'state'}, $result->{'count'}, $result->{'tcontrol'} )
                = split( /;/, $count );
            return $result;
        }
        else {
            Lab::Exception::CorruptParameter->throw( error =>
                    "unexpected value for COUNT in sub set_averaging. Expected values are between 1 ... 100 or MIN/MAX/DEF/OFF."
            );
        }

    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for FILTERMODE in sub set_averaging. Expected values are REPEAT and MOVING."
        );
    }

}

sub get_averaging {
    my $self = shift;
    my ($function) = $self->_check_args( \@_, ['function'] );

    if ( not defined $function ) {
        $function = $self->get_function();
    }

    my $count
        = $self->query(":SENSE:$function:AVERAGE:STATE?; COUNT?; TCONTROL?");
    my $result;
    ( $result->{'state'}, $result->{'count'}, $result->{'tcontrol'} )
        = split( /;/, $count );
    return $result;

}

# ----------------------------------------- MEASUREMENT ----------------------------------

sub get_value {    # basic
    my $self = shift;
    my ($function) = $self->_check_args( \@_, ['function'] );

    if ( not defined $function ) {
        $self->device_cache()->{value} = $self->query(':READ?');
        return $self->device_cache()->{value};

    }
    elsif ( $function
        =~ /\b(PERIOD|period|PER|per|FREQUENCY|frequency|FREQ|freq|TEMPERATURE|temperature|TEMP|temp|DIODE|diode|DIOD|diod|CURRENT|current|CURR|curr|CURRENT:AC|current:ac|CURR:AC|curr:ac|CURRENT:DC|current:dc|CURR:DC|curr:dc|VOLTAGE|voltage|VOLT|volt|VOLTAGE:AC|voltage:ac|VOLT:AC|volt:ac|VOLTAGE:DC|voltage:dc|VOLT:DC|volt:dc|RESISTANCE|resisitance|RES|res|FRESISTANCE|fresistance|FRES|fres)\b/
        ) {
        my $cmd = sprintf( ":MEASURE:%s?", $function );
        $self->device_cache()->{value} = $self->query($cmd);
        return $self->device_cache()->{value};
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for 'function' in sub measure. Function can be CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, PERIOD, FREQUENCY, TEMPERATURE, DIODE"
        );
    }
}

sub config_measurement {    # basic
    my $self = shift;

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

    $self->set_function($function);
    print "sub config_measurement: set FUNCTION: "
        . $self->set_function() . "\n";

    $self->set_range( $function, $range );
    print "sub config_measurement: set RANGE: " . $self->set_range() . "\n";

    my $nplc = ( $time * 50 ) / $nop;
    if ( $nplc < 0.01 ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for TIME in sub config_measurement. Expected values are between 0.5 ... 50000 sec."
        );
    }
    $self->set_nplc( $function, $nplc );
    print "sub config_measurement: set NPLC: " . $self->set_nplc() . "\n";

    $self->_init_buffer($nop);
    print "sub config_measurement: init BUFFER: "
        . $self->_init_buffer($nop) . "\n";

    $self->_init_trigger($trigger);
    print "sub config_measurement: init TRIGGER: "
        . $self->_init_trigger($trigger) . "\n";

    return $nplc;

}

sub trg {    # basic
    my $self = shift;
    $self->write("*TRG");
}

sub abort {    # basic
    my $self = shift;
    $self->write("ABORT");
}

sub wait {     # basic
    my $self    = shift;
    my $timeout = shift;

    if ( not defined $timeout ) {
        $timeout = 100;
    }

    my $status = Lab::VISA::viSetAttribute(
        $self->{vi}->{instr},
        $Lab::VISA::VI_ATTR_TMO_VALUE, $timeout
    );
    if ( $status != $Lab::VISA::VI_SUCCESS ) {
        Lab::Exception::CorruptParameter->throw(
            error => "Error while setting baud: $status" );
    }

    print "waiting for data ... \n";
    while (1) {
        if ( $self->query(":STATUS:OPERATION:CONDITION?") >= 1024 ) {
            last;
        }    # check if measurement has been finished
        else { usleep(1e3); }
    }

    my $status = Lab::VISA::viSetAttribute(
        $self->{vi}->{instr},
        $Lab::VISA::VI_ATTR_TMO_VALUE, 3000
    );
    if ( $status != $Lab::VISA::VI_SUCCESS ) {
        Lab::Exception::CorruptParameter->throw(
            error => "Error while setting baud: $status" );
    }

}

sub active {    # basic
    my $self = shift;
    my ($timeout) = $self->_check_args( \@_, ['value'] );

    if ( not defined $timeout ) {
        $timeout = 100;
    }

    my $status = Lab::VISA::viSetAttribute(
        $self->{vi}->{instr},
        $Lab::VISA::VI_ATTR_TMO_VALUE, $timeout
    );
    if ( $status != $Lab::VISA::VI_SUCCESS ) {
        Lab::Exception::CorruptParameter->throw(
            error => "Error while setting baud: $status" );
    }

    # check if measurement has been finished
    if ( $self->query(":STATUS:OPERATION:CONDITION?") >= 1024 ) {
        return 0;
    }
    else {
        return 1;
    }

    my $status = Lab::VISA::viSetAttribute(
        $self->{vi}->{instr},
        $Lab::VISA::VI_ATTR_TMO_VALUE, 3000
    );
    if ( $status != $Lab::VISA::VI_SUCCESS ) {
        Lab::Exception::CorruptParameter->throw(
            error => "Error while setting baud: $status" );
    }
}

sub get_data {    # basic
    my $self = shift;
    return $self->_read_buffer();
}

# ------------------------------------ DATA BUFFER ----------------------------------------

sub _clear_buffer {    # internal
    my $self = shift;
    $self->write(":DATA:CLEAR");
    return $self->query(":DATA:FREE?");
}

sub _init_buffer {     # internal
    my $self = shift;
    my ($nop) = $self->_check_args( \@_, ['value'] );

    $self->_clear_buffer();

    if ( $nop >= 2 && $nop <= 1024 ) {
        $self->write("*CLS");
        $self->write(":STATUS:OPERATION:ENABLE 16")
            ;          # enable status bit for measuring/idle status
        $self->write("INIT:CONT OFF");    # set DMM to IDLE-state
        $self->_init_trigger("BUS")
            ; # trigger-count = 1, trigger-delay = 0s, trigger-source = IMM/EXT/TIM/MAN/BUS
        $self->_set_triggercount(1);
        $self->_set_triggerdelay(0);
        my $return_nop = $self->_set_samplecount($nop);
        $self->write(":INIT");  # set DMM from IDLE to WAIT-FOR_TRIGGER status
        return $return_nop;
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value in sub set_nop_for_buffer. Must be between 2 and 1024."
        );
    }
}

sub _read_buffer {              # basic
    my $self = shift;
    my ($print) = $self->_check_args( \@_, ['value'] );

    # wait until data are available
    $self->wait();

    #read data
    $self->write(":FORMAT:DATA ASCII; :FORMAT:ELEMENTS READING")
        ;                       # select Format for reading DATA
    my $data = $self->{vi}->LongQuery(":DATA:DATA?");
    chomp $data;
    my @data = split( ",", $data );

    #print data
    if ( $print eq "PRINT" ) {
        foreach my $item (@data) { print $item. "\n"; }
    }

    return @data;
}

# -------------------------------------- TRIGGER ----------------------------------------------

sub _init_trigger {    # internal
    my $self = shift;
    my ($source) = $self->_check_args( \@_, ['source'] );

    if ( not defined $source ) {
        $source = "BUS";
    }                  # set BUS as default trigger source

    $self->_set_triggercount("DEF");    # DEF = 1
    $self->_set_triggerdelay("DEF");    # DEF = 0
    $self->_set_triggersource("BUS");

    return "trigger initiated";

}

sub _set_triggersource {                # internal
    my $self = shift;
    my ($triggersource) = $self->_check_args( \@_, ['source'] );

    #return setting
    if ( not defined $triggersource ) {
        $triggersource = $self->query(":TRIGGER:SOURCE?");
        chomp($triggersource);
        return $triggersource;
    }

    #set triggersoource
    if ( $triggersource =~ /\b(IMM|imm|EXT|ext|TIM|tim|MAN|man|BUS|bus)\b/ ) {
        return $self->query(
            sprintf( ":TRIGGER:SOURCE %s; SOURCE?", $triggersource ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for SOURCE in sub _init_trigger. Must be IMM, EXT, TIM, MAN or BUS."
        );
    }
}

sub _set_samplecount {    # internal
    my $self = shift;
    my ($samplecount) = $self->_check_args( \@_, ['value'] );

    #return setting
    if ( not defined $samplecount ) {
        $samplecount = $self->query(":SAMPLE:COUNT?");
        chomp($samplecount);
        return $samplecount;
    }

    #set samplecount
    if ( $samplecount >= 1 && $samplecount <= 1024 ) {
        return $self->query(
            sprintf( ":SAMPLE:COUNT %d; COUNT?", $samplecount ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for SAMPLECOUNT in  sub _set_samplecount. Must be between 1 and 1024."
        );
    }

}

sub _set_triggercount {    # internal
    my $self = shift;
    my ($triggercount) = $self->_check_args( \@_, ['value'] );

    #return setting
    if ( not defined $triggercount ) {
        $triggercount = $self->query(":TRIGGER:COUNT?");
        chomp($triggercount);
        return $triggercount;
    }

    #set triggercount
    if ( ( $triggercount >= 1 && $triggercount <= 1024 )
        or $triggercount =~ /\b(MIN|min|MAX|max|DEF|def)\b/ ) {
        return $self->query(":TRIGGER:COUNT $triggercount; COUNT?");
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for TRIGGERCOUNT in  sub _set_triggercount. Must be between 1 and 1024 or MIN/MAX/DEF."
        );
    }
}

sub _set_triggerdelay {    # internal
    my $self = shift;
    my ($triggerdelay) = $self->_check_args( \@_, ['value'] );

    #return setting
    if ( not defined $triggerdelay ) {
        $triggerdelay = $self->query(":TRIGGER:DELAY?");
        chomp($triggerdelay);
        return $triggerdelay;
    }

    #set triggerdelay
    if ( ( $triggerdelay >= 0 && $triggerdelay <= 999999.999 )
        or $triggerdelay =~ /\b(MIN|min|MAX|max|DEF|def)\b/ ) {
        return $self->query(":TRIGGER:DELAY $triggerdelay; DELAY?");
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for TRIGGERDELAY in  sub _set_triggerdelay. Must be between 0 and 999999.999sec or MIN/MAX/DEF."
        );
    }
}

sub set_timer {    # advanced
    my $self = shift;
    my ($timer) = $self->_check_args( \@_, ['value'] );

    #return setting
    if ( not defined $timer ) {
        $timer = $self->query(":TRIGGER:TIMER?");
        chomp($timer);
        return $timer;
    }

    #set timer
    if ( ( $timer >= 1e-3 && $timer <= 999999.999 )
        or $timer =~ /\b(MIN|min|MAX|max|DEF|def)\b/ ) {
        return $self->query(":TRIGGER:TIMER $timer; TIMER?");
    }
    else {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for TIMER in  sub set_timer. Must be between 0 and 999999.999sec or MIN/MAX/DEF."
        );
    }
}

# -----------------------------------------DISPLAY --------------------------------

sub display {    # basic
    my $self = shift;
    my ($data) = $self->_check_args( \@_, ['state'] );

    if ( not defined $data ) {
        return $self->_display_text();
    }
    elsif ( $data =~ /\b(ON|on)\b/ ) {
        return $self->_display_on();
    }
    elsif ( $data =~ /\b(OFF|off)\b/ ) {
        return $self->_display_off();
    }
    elsif ( $data =~ /\b(CLEAR|clear)\b/ ) {
        return $self->_display_clear();
    }
    else {
        return $self->_display_text($data);
    }

}

sub display_on {    # for internal/advanced use only
    my $self = shift;
    $self->write(":DISPLAY:ENABLE ON");
}

sub display_off {    # for internal/advanced use only
    my $self = shift;
    $self->write(":DISPLAY:ENABLE OFF")
        ; # when display is disabled, the instrument operates at a higher speed. Frontpanel commands are frozen.
}

sub display_text {    # for internal/advanced use only
    my $self = shift;
    my ($text) = $self->_check_args( \@_, ['text'] );

    if ($text) {
        chomp( $text
                = $self->query("DISPLAY:TEXT:DATA '$text'; STATE 1; DATA?") );
        $text =~ s/\"//g;
        return $text;
    }
    else {
        chomp( $text = $self->query("DISPLAY:TEXT:DATA?") );
        $text =~ s/\"//g;
        return $text;
    }
}

sub display_clear {    # for internal/advanced use only
    my $self = shift;
    $self->write("DISPlay:TEXT:STATE 0");
}

# ----------------------------------------------------------------------------------------

sub beep {
    my $self = shift;
    $self->write("BEEP");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::Keithley2000 - Keithley 2000 digital multimeter

=head1 VERSION

version 3.881

=head1 SYNOPSIS

	use Lab::Instrument::Keithley2000;
	my $DMM=new Lab::Instrument::Keithley2000(0,22);
	print $DMM->get_value('VOLTAGE:DC');

=head1 DESCRIPTION

The Lab::Instrument::Keithley2000 class implements an interface to the Keithley 2000 digital multimeter.

=head1 CONSTRUCTOR

	my $DMM=new(\%options);

=head1 METHODS

=head2 get_value

	$value=$DMM->get_value($function);

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

=head2 get_T

	$value=$DMM->get_value($sensor, $function, $range);

Make a measurement defined by $function with the previously specified range
and integration time.

=over 4

=item $sensor

 SENSOR  can be one of the Temperature-Diodes defined in Lab::Instrument::TemperatureDiodes.

=item $function

 FUNCTION  can be one of the measurement methods of the Keithley2000.

	"diode" --> read out temperatuer diode
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $range

 RANGE  is given in terms of amps or ohms and can be   1e-5 | 1e-4 | 1e-3 | MIN | MAX | DEF   or   0...101e6 | MIN | MAX | DEF | AUTO  .
 DEF  is default  AUTO  activates the AUTORANGE-mode.
 DEF  will be set, if no value is given.

=back

=head2 config_measurement

	$K2000->config_measurement($function, $number_of_points, $time, $range);

Preset the Keithley2000 for a TRIGGERED measurement.

WARNING: It's not recomended to perform triggered measurments with the KEITHLEY 2000 DMM due to unsolved timing problems!!!!!

=over 4

=item $function

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

=item $range

 RANGE  is given in terms of amps, volts or ohms and can be   0...+3,03A | MIN | MAX | DEF | AUTO  ,   0...757V(AC)/1010V(DC) | MIN | MAX | DEF | AUTO   or   0...101e6 | MIN | MAX | DEF | AUTO  .	
 DEF  is default  AUTO  activates the AUTORANGE-mode.
 DEF  will be set, if no value is given.

=back

=head2 trg

	$K2000->trg();

Sends a trigger signal via the GPIB-BUS to start the predefined measurement.
The LabVisa-script can immediatally be continued, e.g. to start another triggered measurement using a second Keithley2000.

=head2 abort

	$K2000->abort();

Aborts current (triggered) measurement.

=head2 active

	$K2400->abort();

Returns '1' if the current triggered measurement is still active and '0' if the current triggered measurement has allready been finished.

=head2 wait

	$K2400->abort();

WAIT until triggered measurement has been finished.

=head2 get_data

	@data = $K2000->get_data();

Reads all recorded values from the internal buffer and returnes them as an array of floatingpoint values.
Reading the buffer will start immediately after the triggered measurement has finished. The LabVisa-script cannot be continued until all requested readings have been recieved.

=head2 set_function

	$K2000->set_function($function);

Set a new value for the measurement function of the Keithley2000.

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

=head2 set_range

	$K2000->set_range($function,$range);

Set a new value for the predefined  RANGE  for the measurement function $function of the Keithley2000.

=over 4

=item $function

 FUNCTION  can be one of the measurement methods of the Keithley2000.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $range

 RANGE  is given in terms of amps, volts or ohms and can be   0...+3,03A | MIN | MAX | DEF | AUTO  ,   0...757V(AC)/1010V(DC) | MIN | MAX | DEF | AUTO   or   0...101e6 | MIN | MAX | DEF | AUTO  .	
 DEF  is default  AUTO  activates the AUTORANGE-mode.
 DEF  will be set, if no value is given.

=back

=head2 set_nplc

	$K2000->set_nplc($function,$nplc);

Set a new value for the predefined  NUMBER of POWER LINE CYCLES  for the measurement function $function of the Keithley2000.

=over 4

=item $function

 FUNCTION  can be one of the measurement methods of the Keithley2000.

	"current:dc" --> DC current measurement 
	"current:ac" --> AC current measurement 
	"voltage:dc" --> DC voltage measurement 
	"voltage:ac" --> AC voltage measurement 
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $nplc

Preset the  NUMBER of POWER LINE CYCLES  which is actually something similar to an integration time for recording a single measurement value.
The values for $nplc can be any value between 0.01 ... 10.

Example:
Assuming $nplc to be 10 and assuming a netfrequency of 50Hz this results in an integration time of 10*50Hz = 0.2 seconds for each measured value. Assuming $number_of_points to be 100 it takes in total 20 seconds to record all values for the trace.

=back

=head2 set_averaging

	$K2000->set_averaging($count, $filter);

Set a new value for the predefined  NUMBER of POWER LINE CYCLES  for the measurement function $function of the Keithley2000.

=over 4

=item $count

 COUNT  is the number of readings to be taken to fill the  AVERAGING FILTER .  COUNT  can be 1 ... 100.

=item $filter

 FILTER  can be  MOVING  or  REPEAT . A detailed description is refered to the user manual.

=back

=head2 display_on

	$K2000->display_on();

Turn the front-panel display on.

=head2 display_off

	$K2000->display_off();

Turn the front-panel display off.

=head2 display_text

	$K2000->display_text($text);
	print $K2000->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.

=head2 display_clear

	$K2000->display_clear();

Clear the message displayed on the front panel.

=head2 reset

	$K2000->reset();

Reset the multimeter to its power-on configuration.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013-2014  Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
