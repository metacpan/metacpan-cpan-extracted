package Lab::Instrument::Keithley2400;
#ABSTRACT: Keithley 2400 SourceMeter
$Lab::Instrument::Keithley2400::VERSION = '3.899';
use v5.20;

use strict;
use Lab::Instrument;
use Lab::Instrument::Source;
use Time::HiRes qw/usleep/, qw/time/;
use Carp;

our @ISA = ('Lab::Instrument');

our %fields = (
    supported_connections =>
        [ 'VISA', 'VISA_GPIB', 'VISA_RS232', 'RS232', 'GPIB', 'DEBUG' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
        timeout      => 2
    },

    device_settings => {
        gate_protect            => 0,
        gp_equal_level          => 1e-5,
        gp_max_units_per_second => 0.002,
        gp_max_units_per_step   => 0.001,
        gp_max_step_per_second  => 2,

        read_default => 'device'
    },

    device_cache => { id => 'Keithley 2400' }

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->{armed} = 0;
    return $self;
}

sub _device_init {
    my $self = shift;

    $self->set_source_autooutputoff(0);
    $self->set_sense_concurrent('ON');

    #$self->set_sense_onfunction('ALL');  <-- Don't know why this was here, but it changes the sense function at the device init (bad idea)

    $self->clear_sweep();
}

sub reset {
    my $self = shift;
    $self->write("*RST");
    return "RESET";
}

# ------------------------------------ OUTPUT ---------------------------------------------

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
        $self->write(":OUTPUT ON");

        if ( defined $current_level ) {
            $self->set_level($current_level);
        }

    }
    elsif ( $value == 0 ) {
        $self->write(":OUTPUT OFF");

    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "$value is not a valid output status (on = 1 | off = 0)");
    }

    return $self->{'device_cache'}->{'output'} = $self->get_output();
}

sub get_output {    # basic setting
    my $self = shift;
    my ($read_mode) = $self->_check_args( \@_, ['read_from'] );

    if ( not defined $read_mode or not $read_mode =~ /device|cache/ ) {
        $read_mode = $self->device_settings()->{read_default};
    }

    if ( $read_mode eq 'cache'
        and defined $self->{'device_cache'}->{'output'} ) {
        return $self->{'device_cache'}->{'output'};
    }

    return $self->{'device_cache'}->{'output'} = $self->query(":OUTPUT?");
}

sub set_output_offstate {    # advanced settings
    my $self     = shift;
    my $offstate = shift;

    if ( not defined $offstate ) {
        return $self->query(":OUTPUT:SMODE?");
    }
    elsif ( $offstate
        =~ /\b(HIMPEDANCE|HIMP|himpedance|himp|NORMAL|NORM|normal|norm|ZERO|zero|GUARD|GUAR|guard|guar)\b/
        ) {
        return $self->query(":OUTPUT:SMODE $offstate; :OUTPUT:SMODE?");
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for OUTPUT OFF STATE in sub set_output_off_state. Expected values are HIMPEDANCE, NORMAL, ZERO or GUARD."
        );
    }
}

#--------------------------------------SOURCE----------------------------------------------

# ------------------------------------ SENSE 1 subsystem -----------------------------------

sub set_sense_terminals {    # advanced settings
    my $self      = shift;
    my $terminals = shift;

    if ( $terminals =~ /\b(FRONT|FRON|front|fron|REAR|rear)\b/ ) {
        return $self->query(
            sprintf( ":ROUTE:TERMINALS %s; :ROUTE:TERMINALS?", $terminals ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for TERMINAL in sub set_terminals. Expected values are FRONT or REAR."
        );
    }
}

sub set_sense_concurrent {    # advanced settings
    my $self  = shift;
    my $value = shift;

    if ( $value =~ /\b(ON|on|1|OFF|off|0)\b/ ) {
        return $self->query(
            sprintf( ":SENSE:FUNCTION:CONCURRENT %s; CONCURRENT?", $value ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub set_concurrent. Expected values are ON, OFF, 1 or 0."
        );
    }
}

sub set_sense_onfunction {    # advanced settings
    my $self = shift;
    my $list = shift;
    my @list = split( ",", $list );

    if ( not defined $list ) {
        goto RETURN;
    }

    # switch all function off first
    $self->write(":SENSE:FUNCTION:OFF:ALL");

    # switch on/off the concurrent-mode
    if ( ( my $length = @list ) > 1 or $list =~ /\b(ALL|all)\b/ ) {
        $self->set_sense_concurrent('ON');
    }
    else {
        $self->set_sense_concurrent('OFF');
    }

    # check input data
    foreach my $onfunction (@list) {
        if ( $onfunction
            =~ /\b(CURRENT|CURR|current|curr|VOLTAGE|VOLT|voltage|volt)\b/ ) {
            $self->write( sprintf( ":SENSE:FUNCTION:ON '%s'", $onfunction ) );
            $self->write(":FORMAT:DATA ASCII; :FORMAT:ELEMENTS $onfunction")
                ;    # select Format for reading DATA
        }
        elsif ( $onfunction =~ /\b(RESISTANCE|RES|resistance|res)\b/ ) {
            $self->write( sprintf( ":SENSE:FUNCTION:ON '%s'", $onfunction ) );
            $self->write(":FORMAT:DATA ASCII; :FORMAT:ELEMENTS $onfunction")
                ;    # select Format for reading DATA
            $self->set_sense_resistancemode('MAN');
            $self->set_sense_resistance_zerocompensated('OFF');
        }
        elsif ( $onfunction =~ /\b(ALL|all)\b/ ) {
            $self->write(":SENSE:FUNCTION:ON:ALL");
            $self->write(":FORMAT:DATA ASCII; :FORMAT:ELEMENTS $onfunction")
                ;    # select Format for reading DATA
            $self->set_sense_resistancemode('MAN');
            $self->set_sense_resistance_zerocompensated('OFF');
        }
        elsif ( $onfunction =~ /\b(OFF|off|NONE|none)\b/ ) {
            $self->write(":SENSE:FUNCTION:OFF:ALL");
            return;
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value in sub set_onfunction. Expected values are CURRENT, VOLTAGE, RESISTNCE and ALL."
            );
        }
    }

    # read out onfunctions
RETURN:
    my $onfunctions = $self->query(":SENSE:FUNCTION:ON?");
    my @onfunctions = split( ",", $onfunctions );
    $onfunctions = "";
    foreach my $onfunction (@onfunctions) {
        if ( $onfunction
            =~ /(VOLTAGE|VOLT|voltage|volt|CURRENT|CURR|current|curr|RESISTANCE|RES|resistance|res)/
            ) {
            $onfunction = $1;
        }
        else {
            $onfunction = "NONE";
        }
    }
    $onfunctions = join( ",", @onfunctions );

    return $onfunctions;
}

sub set_sense_resistancemode {    # advanced settings
    my $self = shift;
    my $mode = shift;

    if ( $mode =~ /\b(AUTO|auto|MAN|man)\b/ ) {
        $self->write( sprintf( ":SENSE:RESISTANCE:MODE %s", $mode ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for MODE in sub set_resistancemode. Expected values are AUTO or MAN."
        );
    }
}

sub set_sense_resistance_zerocompensated {    # advanced settings
    my $self             = shift;
    my $zerocompensation = shift;

    if ( $zerocompensation =~ /\b(ON|on|1|OFF|off|0)\b/ ) {
        $self->query(
            sprintf( ":SENSE:RES:OCOM %s; OCOM?", $zerocompensation ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for ZEROCOMPENSTION in sub set_resistance_zerocompensated. Expected values are ON, OFF, 1 or 0."
        );
    }
}

sub set_sense_range {    # basic setting
    my $self     = shift;
    my $function = shift;
    my $range    = shift;
    my $llimit   = shift;
    my $ulimit   = shift;

    if ( $function =~ /\b(CURRENT|CURR|current|curr)\b/ ) {
        if ( $range
            =~ /\b(AUTO|auto|UP|up|DOWN|down|MIN|min|MAX|max|DEF|def)\b/ ) {

            #pass
        }
        elsif ( ( $range >= -1.05 && $range <= 1.05 ) ) {
            $range = sprintf( "%.5f", $range );
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value for 'RANGE' in sub set_sense_range. Expected values are between -1.05 and 1.05."
            );
        }
    }

    elsif ( $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ ) {
        if ( $range
            =~ /\b(AUTO|auto|UP|up|DOWN|down|MIN|min|MAX|max|DEF|def)\b/ ) {

            #pass
        }
        elsif ( ( $range >= -210 && $range <= 210 ) ) {
            $range = sprintf( "%.1f", $range );
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value for 'RANGE' in sub set_sense_range. Expected values are between -210 and 210."
            );
        }
    }

    elsif ( $function =~ /\b(RESISTANCE|RES|resistance|res)\b/ ) {
        if ( $range
            =~ /\b(AUTO|auto|UP|up|DOWN|down|MIN|min|MAX|max|DEF|def)\b/ ) {

            #pass
        }
        elsif ( ( $range >= 0 && $range <= 2.1e8 ) ) {
            $range = sprintf( "%.1f", $range );
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value in sub set_sense_range for 'RANGE'. Expected values are between 0 and 2.1E8."
            );
        }
    }

    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for FUNCTION in sub set_range. Function can be CURRENT[:DC], VOLTAGE[:DC] or RESISTANCE"
        );
    }

    # set range
    my $cmd;
    if ( $range =~ /\b(AUTO|auto)\b/ ) {
        if (    defined $llimit
            and defined $ulimit
            and $llimit <= $ulimit
            ) # warning: the values for llimit and ulimit are not checked by this function
        {
            $cmd = sprintf(
                ":SENSE:%s:RANGE:AUTO ON; LLIMIT %.5f; ULIMIT %.5f; :SENSE:%s:RANGE?",
                $function, $llimit, $ulimit, $function
            );
        }
        else {
            $cmd = sprintf(
                ":SENSE:%s:RANGE:AUTO ON; :SENSE:%s:RANGE?",
                $function, $function
            );
        }
    }
    else {

        if ( $range > $self->set_complience($function) ) {
            print Lab::Exception::CorruptParameter->new(
                "Error setting RANGE. Can't exceed Complience.");
            $range = $self->set_complience($function);
        }
        $cmd = sprintf(":SENSE:$function:RANGE $range; RANGE?");
    }
    my $return_range = $self->query($cmd);

    printf( "set RANGE for %s to %s.", $function, $return_range );
    return $return_range;
}

sub set_compliance {    # basic setting
    my $self = shift;
    my ( $complience, $function )
        = $self->_check_args( \@_, [ 'value', 'function' ] );

    if ( not defined $function and not defined $complience ) {
        $function = $self->set_source_mode();
        return $self->query(
            sprintf( ":SENSE:%s:PROTECTION:LEVEL?", $function ) );
    }
    elsif ( not defined $complience
        and $function =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/
        or $function =~ /\b(MIN|min|MAX|max|DEF|def|AUTO|auto)\b/ ) {
        $complience = $function;
        $function   = $self->set_source_mode();
    }
    elsif ( not defined $complience ) {
        return $self->query(
            sprintf( ":SENSE:%s:PROTECTION:LEVEL?", $function ) );
    }

    if ( not defined $function ) {
        $function = $self->get_source_function();
    }

    if ( $function =~ /\b(CURRENT|CURR|current|curr)\b/ ) {
        if ( $complience < -210 or $complience > 210 ) {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value for COMPLIENCE in sub set_comlience. Expected values are between -210 and +210V."
            );
        }
    }

    elsif ( $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ ) {
        if ( $complience < -1.05 or $complience > 1.05 ) {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value for COMPLIENCE in sub set_comlience. Expected values are between -1.05 and +1.05A."
            );
        }
    }

    # check if $complience is valid with respect to the selected RANGE; $comlience >= 0.1%xRANGE
    #if ($complience < 0.001*$self->query(sprintf(":SENSE:%s:RANGE?",$function))){
    #	Lab::Exception::CorruptParameter->throw("unexpected value for COMPLIENCE in sub set_complience. COMPLIENCE must be greater than 0.001xRANGE.");
    #	}

    # set complience

    if ( $function =~ /\b(CURRENT|CURR|current|curr)\b/ ) {
        return $self->query(
            sprintf(
                ":SENSE:VOLTAGE:PROTECTION:LEVEL %e; LEVEL?", $complience
            )
        );
    }
    elsif ( $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ ) {
        return $self->query(
            sprintf(
                ":SENSE:CURRENT:PROTECTION:LEVEL %e; LEVEL?", $complience
            )
        );
    }
}

sub set_sense_nplc {    # basic setting
    my $self     = shift;
    my $function = shift;
    my $nplc     = shift;

    # return settings if no new values are given
    if ( not defined $nplc ) {
        if ( not defined $function ) {
            $function = $self->query(":SOURCE:FUNCTION:MODE?");
            chomp $function;
            $nplc = $self->query(":SENSE:$function:NPLC?");
            chomp($nplc);
            return $nplc;
        }
        elsif ( $function
            =~ /\b(CURRENT|CURR|current|curr|VOLTAGE|VOLT|voltage|volt|RESISTANCE|RES|resistance|res)\b/
            ) {
            $nplc = $self->query(":SENSE:$function:NPLC?");
            chomp($nplc);
            return $nplc;
        }
        elsif ( ( $function >= 0.01 && $function <= 1000 )
            or $function =~ /\b(MAX|max|MIN|min|DEF|def)\b/ ) {
            $nplc     = $function;
            $function = $self->query(":SOURCE:FUNCTION:MODE?");
            chomp $function;
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value for FUNCTION in sub set_sense_nplc. Expected values are CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, TEMPERATURE"
            );
        }

    }

    if ( ( $nplc < 0.01 && $nplc > 1000 )
        and not $nplc =~ /\b(MAX|max|MIN|min|DEF|def)\b/ ) {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for NPLC in sub set_sense_nplc. Expected values are between 0.01 and 1000 POWER LINE CYCLES or MIN/MAX/DEF."
        );
    }

    if ( $function
        =~ /\b(CURRENT|CURR|current|curr|VOLTAGE|VOLT|voltage|volt|RESISTANCE|RES|resistance|res)\b/
        ) {
        if ( $nplc > 10 ) {
            my $averaging = $nplc / 10;
            print "sub set_nplc: use AVERAGING of "
                . $self->set_sense_averaging($averaging) . "\n";
            $nplc /= $averaging;
        }
        else {
            $self->set_sense_averaging('OFF');
        }
        if ( $nplc =~ /\b(MAX|max|MIN|min|DEF|def)\b/ ) {
            return $self->query(
                sprintf( ":SENSE:%s:NPLC %s; NPLC?", $function, $nplc ) );
        }
        elsif ( $nplc =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ ) {
            return $self->query(
                sprintf( ":SENSE:%s:NPLC %e; NPLC?", $function, $nplc ) );
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value for NPLC in sub set_sense_nplc. Expected values are between 0.01 and 10 POWER LINE CYCLES or MIN/MAX/DEF."
            );
        }
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for FUNCTION in sub set_sense_nplc. Expected values are CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, TEMPERATURE"
        );
    }
}

sub get_sense_nplc {
    my $self     = shift;
    my $function = shift;

    my $nplc;

    if ( not defined $function ) {
        $function = $self->query(":SOURCE:FUNCTION:MODE?");
        chomp $function;
        $nplc = $self->query(":SENSE:$function:NPLC?");
        chomp($nplc);
        return $nplc;
    }
    elsif ( $function
        =~ /\b(CURRENT|CURR|current|curr|VOLTAGE|VOLT|voltage|volt|RESISTANCE|RES|resistance|res)\b/
        ) {
        $nplc = $self->query(":SENSE:$function:NPLC?");
        chomp($nplc);
        return $nplc;
    }

}

sub set_sense_averaging {    # advanced settings
    my $self   = shift;
    my $count  = shift;
    my $filter = shift;

    if ( not defined $count and not defined $filter ) {
        return $self->query(":SENSE:AVERAGE:COUNT?");
    }

    if ( $count >= 1 and $count <= 100 ) {
        if (
            defined $filter
            and
            ( $filter =~ /\b(REPEAT|REP|repeat|rep|MOVING|MOV|moving|mov)\b/ )
            ) {
            return $self->query(
                sprintf(
                    ":SENSE:AVERAGE:TCONTROL %s; COUNT %d; STATE ON; COUNT?",
                    $filter, $count
                )
            );
        }
        elsif ( not defined $filter ) {
            return $self->query(
                sprintf(
                    ":SENSE:AVERAGE:TCONTROL MOV; COUNT %d; STATE ON; COUNT?",
                    $count
                )
            );
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value for FILTER in sub set_averaging. Expected values are REPEAT or MOVING."
            );
        }
    }
    elsif ( $count =~ /\b(OFF|off|0)\b/ ) {
        return $self->query(
            sprintf(":SENSE:AVERAGE:STATE OFF; TCONTROL MOV; STATE?") );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for COUNT in sub set_averaging. Expected values are between 1 and 100 or 0 or OFF to turn off averaging"
        );
    }
}

# ------------------------------------ SOURCE subsystem -----------------------------------

sub set_source_autooutputoff {    # advanced settings
    my $self = shift;
    my $mode = shift;

    if ( $mode =~ /\b(ON|on|1|OFF|off|0)\b/ ) {
        return $self->query(
            sprintf( ":SOURCE:CLEAR:AUTO %s; :SOURCE:CLEAR:AUTO?", $mode ) );
    }
    elsif ( not defined $mode ) {
        return $self->query(":SOURCE:CLEAR:AUTO OFF; :SOURCE:CLEAR:AUTO?");
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for MODE in sub set_sourceautooutputoff. Expected values are ON, OFF, 1 or 0."
        );
    }
}

sub set_source_sourcingmode {    # advanced settings
    my $self     = shift;
    my $function = shift;
    my $mode     = shift;

    if (   $function =~ /\b(CURRENT|CURR|current|curr)\b/
        or $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ ) {
        if (   $mode =~ /\b(FIXED|FIX|fixed|fix)\b/
            or $mode =~ /\b(LIST|list)\b/
            or $mode =~ /\b(SWEEP|SWE|sweep|swe)\b/ ) {
            return $self->query(
                sprintf(
                    ":SOURCE:%s:MODE %s; :SOURCE:%s:MODE?",
                    $function, $mode, $function
                )
            );
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value for MODE in sub set_sourcingmode. Expected values are FIXED, LIST or SWEEP."
            );
        }
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for FUNCTION in sub set_sourcingmode. Expected values are CURRENT or VOLTAGE."
        );
    }
}

sub set_source_range {    # basic setting
    my $self     = shift;
    my $function = shift;
    my $range    = shift;

    if ( not defined $function and not defined $range ) {
        $function = $self->set_source_mode();
        return $self->query( sprintf( ":SOURCE:%s:RANGE?", $function ) );
    }
    elsif ( not defined $range
        and $function =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/
        or $function =~ /\b(MIN|min|MAX|max|DEF|def|AUTO|auto)\b/ ) {
        $range    = $function;
        $function = $self->set_source_mode();
    }

    if ( $function =~ /\b(CURRENT|CURR|current|curr)\b/ ) {
        if ( ( $range >= -1.05 && $range <= 1.05 ) || $range eq "AUTO" ) {
            $range = sprintf( "%.5f", $range );
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value in sub set_source_range for 'RANGE'. Expected values are between -1.05 and 1.05."
            );
        }
    }

    elsif ( $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ ) {
        if ( ( $range >= -210 && $range <= 210 ) || $range eq "AUTO" ) {
            $range = sprintf( "%.1f", $range );
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "unexpected value in sub set_source_range for 'RANGE'. Expected values are between -210 and 210."
            );
        }
    }

    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub set_source_range. Function can be CURRENT or VOLTAGE"
        );
    }

    # set range
    if ( $range =~ /\b(AUTO|auto)\b/ ) {
        $self->query( sprintf( ":SENSE:%s:RANGE:AUTO ON", $function ) );
        return "AUTO";
    }
    elsif ( $range =~ /\b(MIN|min|MAX|max|DEF|def)\b/ ) {
        return $self->query(
            sprintf( ":SOURCE:%s:RANGE %s; RANGE?", $function, $range ) );
    }
    else {
        return $self->query(
            sprintf( ":SOURCE:%s:RANGE %.5f; RANGE?", $function, $range ) );
    }
}

sub _set_source_amplitude {    # internal/advanced use only
    my $self     = shift;
    my $function = shift;
    my $value    = shift;

    # check trigger status
    my $triggerstatus = $self->query("TRIGGER:SEQUENCE:SOURCE?");

    # check input data
    if ( not defined $value and not defined $function ) {
        $function = $self->set_source_mode();
        return $self->query( sprintf( ":SOURCE:%s?", $function ) );
    }
    elsif (
        not defined $value
        and (  $function =~ /\b(CURRENT|CURR|current|curr)\b/
            or $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ )
        ) {
        if ( $triggerstatus =~ /\b(IMMEDIATE|IMM|immediate|imm)\b/ ) {
            return $self->query( sprintf( ":SOURCE:%s?", $function ) );
        }
        else {
            return $self->query(
                sprintf( ":SOURCE:%s:TRIGGERED?", $function ) );
        }
    }

    elsif ( not defined $value and $function >= -210 and $function <= 210 ) {
        $value    = $function;
        $function = $self->set_source_mode();
    }

    if (
        (
                $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/
            and $value >= -210
            and $value <= 210
        )
        or (    $function =~ /\b(CURRENT|CURR|current|curr)\b/
            and $value >= -1.05
            and $value <= 1.05 )
        ) {
        # check if new value is within the current range
        if ( $value <= $self->set_source_range($function) ) {
            print Lab::Exception::CorruptParameter->new(
                "WARNING: setting new OUTPUT value. Value not within current range setting. Change range setting to fit with new output setting."
            );
            $self->set_source_range( $function, $value );
        }

        # set source output amplitude
        if ( $triggerstatus =~ /\b(IMMEDIATE|IMM|immediate|imm)\b/ ) {
            if ( $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ ) {
                if ( $self->get_output('STATE') =~ /\b(OFF|off)\b/ ) {
                    return $self->_set_voltage($value);
                }
                else {
                    return $self->set_voltage($value);
                }
            }
            else {
                return $self->set_current($value);
            }
        }
        else {
            return $self->query(
                sprintf(
                    ":SOURCE:%s:TRIGGERED %e; TRIGGERED?",
                    $function, $value
                )
            );
        }
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_source_amplitude. Expected values are between -210.. +210 V or -1.05..+1.05 A"
        );
    }
}

sub set_source_voltagelimit {    # advanced settings
    my $self  = shift;
    my $limit = shift;

    if ( not defined $limit ) {
        return $self->query(":SOURCE:VOLTAGE:PROTECTION:LIMIT?");
    }

    elsif ( $limit >= -210 and $limit <= 210 ) {
        return $self->query(
            sprintf(
                ":SOURCE:VOLTAGE:PROTECTION:LIMIT 
		; LIMIT?", $limit
            )
        );
    }
    elsif ( $limit =~ /\b(NONE|none|MIN|min|MAX|max|DEF|def)\b/ ) {
        return $self->query(
            sprintf( ":SOURCE:VOLTAGE:PROTECTION:LIMIT %s; LIMIT?", $limit )
        );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for VOLTAGE LIMIT in sub set_source_voltagelimit. Expected values are between -210..+210 V."
        );
    }

}

sub _set_source_delay {    # internal/advanced use only
    my $self  = shift;
    my $delay = shift;

    if ( not defined $delay ) {
        $delay = $self->query(":SOURCE:DELAY?");
        return chomp $delay;
    }

    if ( $delay >= 0 and $delay <= 999.9999 ) {
        $self->write(":SOURCE:DELAY:AUTO OFF");
        return $self->query(
            sprintf( ":SOURCE:DELAY %.4f; :SOURCE:DELAY?", $delay ) );
    }
    elsif ( $delay =~ /\b(MIN|min|MAX|max|DEF|def)\b/ ) {
        $self->write(":SOURCE:DELAY:AUTO OFF");
        return $self->query(
            sprintf( ":SOURCE:DELAY %s; :SOURCE:DELAY?", $delay ) );
    }
    elsif ( $delay =~ /\b(AUTO|auto)\b/ ) {
        return $self->query(":SOURCE:DELAY:AUTO ON; :SOURCE:DELAY:AUTO?");
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for DELAY in sub _set_source_delay. Expected values are between 0..999.9999 or AUTO"
        );
    }
}

sub init_source {    #
    my $self       = shift;
    my $function   = shift;
    my $range      = shift;
    my $complience = shift;

    my $sense;
    print "init source ...";
    $self->set_source_autooutputoff("OFF");
    $self->set_source_sourcingmode( $function, 'FIXED' );
    $self->_set_source_delay('DEF');

    if ( $self->set_sense_onfunction()
        =~ /\b(RESISTANCE|RES|resistance|res)\b/ ) {
        $self->set_sense_resistancemode('MAN');
        $sense = 'RES';
    }
    $self->set_source_mode($function);
    $self->set_sense_onfunction(
        $function =~ /\b(CURRENT|CURR|current|curr)\b/ ? 'VOLT' : 'CURR' )
        ;    # important for always beeing able to set the complience
    $self->set_source_range( $function, $range );
    if ( defined $complience ) {
        $self->set_complience( $function, $complience );
    }
    if ( defined $sense ) {
        $self->set_sense_onfunction($sense);
    }
    $self->set_output("ON");
    print "ok!\n";
    return;
}

#--------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!------------------------------------------
sub set_source_function {    # basic setting
    my $self = shift;
    my ($function) = $self->_check_args( \@_, ['function'] );

    if (   $function =~ /\b(CURRENT|CURR|current|curr)\b/
        or $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/ ) {
        return $self->query(
            sprintf(
                ":SOURCE:FUNCTION:MODE %s; :SOURCE:FUNCTION:MODE?",
                $function
            )
        );
    }
    else {
        Lab::Exception::CorruptParameter->throw( $self->get_id()
                . ": unexpected value for MODE in sub set_sourcemode. Expected values are ON, OFF, 1 or 0."
        );
    }
}

sub get_source_function {
    my $self = shift;

    my $function = $self->query(":SOURCE:FUNCTION:MODE?");
    chomp $function;
    if    ( $function eq 'CURR' ) { $function = 'CURRENT'; }
    elsif ( $function eq 'VOLT' ) { $function = 'VOLTAGE'; }
    return $function;
}

sub _set_level {
    my $self = shift;
    my ( $value, $function )
        = $self->_check_args( \@_, [ 'value', 'function' ] );

    if ( not defined $function ) {
        $function = $self->get_source_function();
    }

    $self->write( sprintf( ":SOURCE:$function %3.5f;", $value ) );
}

sub get_level {
    my $self = shift;
    my ($function) = $self->_check_args( \@_, ['function'] );

    if ( not defined $function ) {
        $function = $self->get_source_function();
    }

    return $self->query(":SOURCE:$function?");
}

sub _sweep_to_level {
    my $self = shift;
}

sub sweep_to_level {
    my $self = shift;

    $self->config_sweep(@_);
    $self->trg();
    $self->wait();
}

sub config_sweep {
    my $self = shift;
    my ( $target, $time, $rate, $function )
        = $self->_check_args( \@_, [ 'points', 'time', 'rate', 'function' ] );

    $self->{armed} = 0;

    if ( not defined $function ) {
        $function = $self->get_source_function();
    }

    if ( not $self->get_output() ) {
        Lab::Exception::Error->throw( error => $self->get_id()
                . " :Can't configure a sweep when output is off!" );
    }

    my $nplc_max = 10;
    my $points_max
        = 2500;    # maximum possible number of points, see manual 5.66

    my $start = $self->get_level($function);

    if ( defined $time and defined $rate ) {
        croak('Please give either a time OR rate. Not both!');
    }
    elsif ( defined $rate and not defined $time ) {
        $time = abs( $start - $target ) / $rate;
    }

    if ( $target == $start ) { return; }

    my $points;

    $self->set_sense_nplc(0.01);

    my $points = int( $time / ( 0.01 / 50 ) );
    my $delay = 0;

    if ( $points > $points_max ) {
        $points = $points_max;

        $delay = ( $time / $points ) - ( 0.01 / 50 );
    }

    my $t0 = time;
    $self->write("SOURCE:SWEEP:DIRECTION UP");

    $self->write("SOUR:SWE:SPAC LIN");

    $self->write( sprintf( "SOUR:%s:STAR %3.5f", $function, $start ) );

    $self->write( sprintf( "SOUR:%s:STOP %3.5f", $function, $target ) );

    $self->write("SOUR:SWE:POIN $points");

    $self->write( sprintf( "SOUR:DEL %3.4f", $delay ) );

    $self->write("TRIG:COUN $points");

    $self->{armed} = 1;

    my $t1 = time;

    #print "TIME TO PROGRAM: ".($t1-$t0)."\n";
}

sub trg {    # basic setting
    my $self = shift;
    if ( !$self->{armed} ) { return; }

    my $function = $self->get_source_function();
    $self->write("SOUR:$function:MODE SWE");
    $self->write(":INITIATE:IMMEDIATE");
}

sub wait {    # basic
    my $self    = shift;
    my $timeout = shift;

    if ( not defined $timeout ) {
        $timeout = 100;
    }

    #my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, $timeout);
    #if ($status != $Lab::VISA::VI_SUCCESS) { Lab::Exception::CorruptParameter->throw("Error while setting baud: $status");}

    print "waiting for data ... \n";
    while ( $self->active() ) {
        usleep(1e3);
    }

    #my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, 3000);
    #if ($status != $Lab::VISA::VI_SUCCESS) { Lab::Exception::CorruptParameter->throw("Error while setting baud: $status");}
}

sub active {    # basic
    my $self    = shift;
    my $timeout = shift;

    if ( not defined $timeout ) {
        $timeout = 100;
    }

    # check if measurement has been finished
    if ( $self->query( ":STATUS:OPERATION:CONDITION?", { timeout => 100 } )
        >= 1024 ) {
        $self->{armed} = 0;
        my $current_level = $self->get_level();
        my $function      = $self->get_source_function();

        $self->clear_sweep();

        #$self->write("SOURCE:SWEEP:DIRECTION DOWN");

        return 0;
    }
    else {
        return 1;
    }
}

# -------------------------------------- CONFIG MEASUREMNT and SOURCE SWEEP --------------------------------
#
#
# sweep is working, but you can't define the duration of the sweep properly when performing also measurements.
# If no ONFUNCTIONS are defined, the duration of the sweep is well defined.
#
#
# In the case of doing source-measurement-sweeps, the duration of the sweep is enlarged and depends on the settings like ...
# The number of points per sweep as well as the integration time (NPLC) give a nonlinear contribution to the total duration of the sweep.
# It alo depends on the number of ONFUNCTIONS.
# Example: Points = 2500, NPLC = 0.01, averaging = OFF, all other delays for source and trigger are set to 0
#			--> sweep takes   9 sec --> 2500 x NPLC/50Hz = 0.5 sec
#          Points = 2500, NPLC = 0.02, averaging = OFF, all other delays for source and trigger are set to 0
#			--> sweep takes  11 sec --> 2500 x NPLC/50Hz = 1.0 sec
#          Points = 2500, NPLC = 0.10, averaging = OFF, all other delays for source and trigger are set to 0
#			--> sweep takes  37 sec --> 2500 x NPLC/50Hz = 5.0 sec
#          Points = 2500, NPLC = 1.00, averaging = OFF, all other delays for source and trigger are set to 0
#			--> sweep takes 158 sec --> 2500 x NPLC/50Hz = 50.0 sec
# It is similar when choosing e.g. 1000 Points. Maybe you won't see the Problem when choosing only 100 points.
#
# BUT: Where does the difference come from ???
#
# It's the same when performing only a triggered measurment operation.
#

sub get_value {    # basic setting
    my $self = shift;
    my ( $function, $read_mode )
        = $self->_check_args( \@_, [ 'function', 'read_mode' ] );
    my $result;
    $result = $self->write(":TRIG:COUN 1");
    if ( not defined $function ) {
        $result = $self->device_cache()->{value} = $self->query(':READ?');
    }

    elsif ( $function
        =~ /\b(CURRENT|current|CURR|curr|VOLTAGE|voltage|VOLT|volt|RESISTANCE|resistance|RES|res)\b/
        ) {
        $result = $self->query( ":MEASURE:" . $function . "?" );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for 'function' in sub get_value. Function can be CURRENT:AC, CURRENT:DC, VOLTAGE:AC, VOLTAGE:DC, RESISTANCE, FRESISTANCE, PERIOD, FREQUENCY, TEMPERATURE, DIODE"
        );
    }

    my @result = split( /,/, $result );
    return $self->device_cache()->{value} = $result[1];
}

sub config_measurement {    #
    my $self     = shift;
    my $function = shift;
    my $nop      = shift;
    my $time     = shift;
    my $range    = shift;

    if ( not defined $range ) {
        $range = "AUTO";
    }

    $self->set_sense_onfunction($function);

    if ( $function =~ /\b(RESISTANCE|RES|resistance|res)\b/ ) {
        $self->set_sense_resistancemode('MAN');
        $self->set_sense_resistance_zerocompensated('OFF');
    }

    if ( $function eq $self->set_source_mode() ) {
        $self->set_source_range( $self->set_source_mode(), $range );
    }
    elsif ( $function =~ /\b(ALL|all)\b/ ) {
        $self->set_source_range( $self->set_source_mode(), $range );
    }
    else {
        if ( $range <= $self->set_complience() ) {
            $self->set_sense_range( $function, $range );
        }
        else {
            $self->set_sense_range( $function, $self->set_complience() );
        }
    }

    my $nplc = ( $time * 50 ) / $nop;
    if ( $nplc < 0.01 ) {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for TIME in sub config_measurement. Expected values are between 0.21 ... 20000 sec."
        );
    }
    print "nplc = " . $self->set_sense_nplc($nplc) . "\n";
    $self->_set_source_delay(0);
    $self->_set_trigger_delay(0);

    $self->_init_buffer($nop);
}

sub clear_sweep {    #
    my $self     = shift;
    my $function = $self->get_source_function();
    $self->write("SOURCE:$function:MODE FIX");
}

sub config_sweep2 {    # basic setting
    my $self = shift;
    my $stop = shift;
    my $nop  = shift;
    my $time = shift;

    if ( $time >= 2 ) {
        $time = $time - 2
            ; # this is a correction, because a typical sweep alwas takes 2 seconds longer than programmed. Reason unknown!
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for TIME in sub config_sweep. Expected values are between 2 ... 9999."
        );
    }

    my $function = $self->query(":SOURCE:FUNCTION:MODE?");
    chomp $function;

    print "set output = " . $self->set_output("ON") . "\n";
    my $start = $self->_set_source_amplitude();

    print "--- config SWEEP ----\n";
    print "start = " . $self->_set_sweep_start($start);
    if ( $start != $self->_set_source_amplitude() ) {
        $self->_set_source_amplitude($start);
    }
    print "stop = " . $self->_set_sweep_stop($stop);
    print "nop = " . $self->_set_sweep_nop($nop);
    print "step = " . $self->query(":SOURCE:$function:STEP?") . "\n";

    print "source_delay = " . $self->_set_source_delay( ($time) / $nop );
    print "trigger_delay = " . $self->_set_trigger_delay(0);
    print "integrationtime = ";
    my $tc = $self->set_sense_nplc(10) / 50;
    print "$tc\n\n";

    print "set_sourcingmode: "
        . $self->set_source_sourcingmode( $function, "SWEEP" );
    print "ranging = " . $self->_set_sweep_ranging('FIXED');
    print "spacing = " . $self->_set_sweep_spacing('LIN');
    print "set ONFUNCTIONS = " . $self->set_sense_onfunction('OFF');
    print "set sourc mode = " . $self->set_source_mode($function);

    print "init BUFFER: " . $self->_init_buffer($nop) . "\n";

    print "ready to SWEEP\n";
}

sub config_IV {    # basic setting
    my $self    = shift;
    my $start   = shift;
    my $stop    = shift;
    my $nop     = shift;
    my $nplc    = shift;
    my $ranging = shift;
    my $spacing = shift;

    # check DATA
    if ( not defined $spacing ) {
        $spacing = 'LIN';
    }
    if ( not defined $ranging ) {
        $ranging = 'FIXED';
    }
    if ( not defined $nplc ) {
        $nplc = 1;
    }
    if ( not defined $nop ) {
        $nop = 2500;
    }

    # config SWEPP parameters
    print "\n--- config SWEEP ----\n";

    print "set sourc mode = " . $self->set_source_mode('VOLT');
    print "set ONFUNCTIONS = " . $self->set_sense_onfunction('CURR,VOLT');
    print "set output = " . $self->set_output("ON") . "\n";

    print "start = " . $self->_set_sweep_start($start);
    if ( $start != $self->_set_source_amplitude() ) {
        $self->_set_source_amplitude($start);
    }
    print "stop = " . $self->_set_sweep_stop($stop);
    print "nop = " . $self->_set_sweep_nop($nop);
    print "step = " . $self->query(":SOURCE:VOLT:STEP?") . "\n";

    print "source_delay = " . $self->_set_source_delay(0);
    print "trigger_delay = " . $self->_set_trigger_delay(0);
    print "integrationtime = ";
    my $tc = $self->set_sense_nplc($nplc) / 50;
    print "$tc\n\n";

    print "set_sourcingmode: "
        . $self->set_source_sourcingmode( 'VOLT', "SWEEP" );
    print "ranging = " . $self->_set_sweep_ranging($ranging);
    print "spacing = " . $self->_set_sweep_spacing($spacing);
    print "init BUFFER: " . $self->_init_buffer($nop) . "\n";

    print "ready to record an IV-trace.\n";
}

sub config_VI {    # basic setting
    my $self    = shift;
    my $start   = shift;
    my $stop    = shift;
    my $nop     = shift;
    my $nplc    = shift;
    my $ranging = shift;
    my $spacing = shift;

    # check DATA
    if ( not defined $spacing ) {
        $spacing = 'LIN';
    }
    if ( not defined $ranging ) {
        $ranging = 'FIXED';
    }
    if ( not defined $nplc ) {
        $nplc = 1;
    }
    if ( not defined $nop ) {
        $nop = 2500;
    }

    # config SWEPP parameters
    print "\n--- config SWEEP ----\n";

    print "set sourc mode = " . $self->set_source_mode('CURR');
    print "set ONFUNCTIONS = " . $self->set_sense_onfunction('VOLT,CURR');
    print "set output = " . $self->set_output("ON") . "\n";

    print "start = " . $self->_set_sweep_start($start);
    if ( $start != $self->_set_source_amplitude() ) {
        $self->_set_source_amplitude($start);
    }
    print "stop = " . $self->_set_sweep_stop($stop);
    print "nop = " . $self->_set_sweep_nop($nop);
    print "step = " . $self->query(":SOURCE:CURR:STEP?") . "\n";

    print "source_delay = " . $self->_set_source_delay(0);
    print "trigger_delay = " . $self->_set_trigger_delay(0);
    print "integrationtime = ";
    my $tc = $self->set_sense_nplc($nplc) / 50;
    print "$tc\n\n";

    print "set_sourcingmode: "
        . $self->set_source_sourcingmode( 'CURR', "SWEEP" );
    print "ranging = " . $self->_set_sweep_ranging($ranging);
    print "spacing = " . $self->_set_sweep_spacing($spacing);

    print "init BUFFER: " . $self->_init_buffer($nop) . "\n";

    print "ready to record an VI-trace.\n";
}

sub get_data {    # basic setting
    my $self = shift;
    my @data = $self->_read_buffer();
    $self->_clear_buffer();
    $self->write(':TRIGGER:CLEAR');
    $self->write( sprintf( ":TRIGGER:COUNT %d", 1 ) );
    return @data;
}

sub abort {       # basic
    my $self = shift;
    $self->write(":ABORT");
}

sub _set_sweep_ranging {    # internal/advanced use only
    my $self    = shift;
    my $ranging = shift;

    if ( $ranging =~ /\b(BEST|best|FIXED|FIX|fixed|fix|AUTO|auto)\b/ ) {
        return $self->query(
            sprintf(
                ":SOURCE:SWEEP:RANGING %s; :SOURCE:SWEEP:RANGING?",
                $ranging
            )
        );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected vlaue for RANGING in sub _set_sweep_ranging. Expected values are BEST, FIXED or AUTO."
        );
    }
}

sub _set_sweep_spacing {    # internal/advanced use only
    my $self    = shift;
    my $spacing = shift;

    if ( $spacing
        =~ /\b(LINEAR|LIN|linear|lin|LOGARITHMIC|LOG|logarithmic|log)\b/ ) {
        return $self->query(
            sprintf(
                ":SOURCE:SWEEP:SPACING %s; :SOURCE:SWEEP:SPACING?",
                $spacing
            )
        );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected vlaue for SPACING in sub set_sweep_spaceing. Expected values are LIN or LOG."
        );
    }
}

sub _set_sweep_start {    # internal/advanced use only
    my $self     = shift;
    my $function = shift;
    my $start    = shift;

    if ( not defined $start and $function >= -210 and $function <= 210 ) {
        $start    = $function;
        $function = $self->query(":SOURCE:FUNCTION:MODE?");
        chomp $function;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_start. Expected values are between -210.. +210 V or -1.05..+1.05 A"
        );
    }

    if ( $function =~ /\b(CURRENT|CURR|current|curr)\b/
        and ( $start < -1.05 or $start > 1.05 ) ) {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_start. Expected values are between -1.05 and 1.05."
        );
    }
    elsif ( $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/
        and ( $start < -210 or $start > 210 ) ) {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_start. Expected values are between -210 and 210."
        );
    }
    elsif ($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/
        or $function =~ /\b(CURRENT|CURR|current|curr)\b/ ) {

        # set startvalue for sweep
        return $self->query(
            sprintf(
                ":SOURCE:%s:START %.11f; :SOURCE:%s:START?",
                $function, $start, $function
            )
        );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_start. Function can be CURRENT or VOLTAGE, startvalue is expected to be between -1.05...+1.05A or -210...+210V"
        );
    }
}

sub _set_sweep_stop {    # internal/advanced use only
    my $self     = shift;
    my $function = shift;
    my $stop     = shift;

    if ( not defined $stop and $function >= -210 and $function <= 210 ) {
        $stop     = $function;
        $function = $self->query(":SOURCE:FUNCTION:MODE?");
        chomp $function;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_stop. Expected values are between -210.. +210 V or -1.05..+1.05 A"
        );
    }

    if ( $function =~ /\b(CURRENT|CURR|current|curr)\b/
        and ( $stop < -1.05 or $stop > 1.05 ) ) {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_start. Expected values are between -1.05 and 1.05."
        );
    }
    elsif ( $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/
        and ( $stop < -210 or $stop > 210 ) ) {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_start. Expected values are between -210 and 210."
        );
    }
    elsif ($function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/
        or $function =~ /\b(CURRENT|CURR|current|curr)\b/ ) {

        # set stop value for sweep
        return $self->query(
            sprintf(
                ":SOURCE:%s:STOP %.11f; :SOURCE:%s:STOP?",
                $function, $stop, $function
            )
        );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_stop. Function can be CURRENT or VOLTAGE, startvalue is expected to be between -1.05...+1.05A or -210...+210V"
        );
    }
}

sub _set_sweep_step {    # internal/advanced use only
    my $self     = shift;
    my $function = shift;
    my $step     = shift;

    if ( not defined $step and $function >= -420 and $function <= 420 ) {
        $step     = $function;
        $function = $self->query(":SOURCE:FUNCTION:MODE?");
        chomp $function;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_step. Expected values are between -420.. +420V or -2.1..+2.1A"
        );
    }

    if ( $function =~ /\b(CURRENT|CURR|current|curr)\b/
        and ( $step < -2.1 or $step > 2.1 ) ) {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_step. Expected values are between -2.1 and 2.1A."
        );
    }
    elsif ( $function =~ /\b(VOLTAGE|VOLT|voltage|volt)\b/
        and ( $step < -420 or $step > 420 ) ) {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_step. Expected values are between -420 and 420A."
        );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_step. Function can be CURRENT or VOLTAGE, startvalue is expected to be between -420.. +420V or -2.1..+2.1A"
        );
    }

    # check if step matches to start and stop values
    my $start = $self->query(":SOURCE:%s:START?");
    my $stop  = $self->query(":SOURCE:%s:STOP?");

    if ( int( ( $stop - $start ) / $step ) != ( $stop - $start ) / $step ) {
        Lab::Exception::CorruptParameter->throw(
            "ERROR in sub _set_sweep_step. STOP-START/STEP must be an integer value."
        );
    }

    # set startvalue for sweep
    $self->query( sprintf( ":SOURCE:%s:STEP %f.11", $function, $step ) );
    return abs( ( $stop - $start ) / $step + 1 );    # return number of points
}

sub _set_sweep_nop {    # internal/advanced use only
    my $self = shift;
    my $nop  = shift;

    if ( $nop >= 1 and $nop <= 2500 ) {
        $self->_set_trigger_count($nop);
        return $self->query(
            sprintf( ":SOURCE:SWEEP:POINTS %d; POINTS?", $nop ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub _set_sweep_step. Expected values are between 1..2500"
        );
    }
}

# ------------------------------------ DATA BUFFER ----------------------------------------

sub _clear_buffer {    # internal/advanced use only
    my $self = shift;
    $self->write(":DATA:FEED:CONTROL NEVER");
    $self->write(":DATA:CLEAR");
}

sub _init_buffer {     # internal/advanced use only
    my $self = shift;
    my $nop  = shift;

    $self->_clear_buffer();

    my $function = $self->set_sense_onfunction();
    if ( $function eq "NONE" ) {
        $self->query(
            sprintf(
                ":FORMAT:DATA ASCII; :FORMAT:ELEMENTS %s; ELEMENTS?",
                $self->set_source_mode()
            )
        );    # select Format for reading DATA
    }
    else {
        $self->query(
            sprintf(
                ":FORMAT:DATA ASCII; :FORMAT:ELEMENTS %s; ELEMENTS?",
                $function
            )
        );    # select Format for reading DATA
    }

    if ( $nop >= 2 && $nop <= 2500 ) {
        my $return_nop = $self->query(
            sprintf( ":DATA:POINTS %d; :DATA:POINTS?", $nop ) );
        $self->write(":DATA:FEED SENSE");    # select raw-data to be stored.
        $self->write(":DATA:FEED:CONTROL NEXT");    # enable data storage
        $self->write( sprintf( ":TRIGGER:COUNT %d", $return_nop ) )
            ; # set samplecount to buffersize. this setting may not be most general.
        return $return_nop;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value in sub set_nop_for_buffer. Must be between 2 and 2500."
        );
    }
}

sub _read_buffer {    # internal/advanced use only
    my $self  = shift;
    my $print = shift;

    # wait until data are available
    $self->wait();

    # get number of ONFUNCTIONS
    my $onfunctions        = $self->set_sense_onfunction();
    my @list               = split( ",", $onfunctions );
    my $num_of_onfunctions = @list;

    # enlarge Query-TIMEOUT
    my $status = Lab::VISA::viSetAttribute(
        $self->{vi}->{instr},
        $Lab::VISA::VI_ATTR_TMO_VALUE, 20000
    );
    if ( $status != $Lab::VISA::VI_SUCCESS ) {
        Lab::Exception::CorruptParameter->throw(
            "Error while setting baud: $status");
    }

    # read data
    print "please wait while reading DATA ... \n";
    my $data = $self->connection()->LongQuery("DATA:DATA?");
    chomp $data;
    my @data = split( ",", $data );

    # Query-TIMEOUT back to default value
    my $status = Lab::VISA::viSetAttribute(
        $self->{vi}->{instr},
        $Lab::VISA::VI_ATTR_TMO_VALUE, 3000
    );
    if ( $status != $Lab::VISA::VI_SUCCESS ) {
        Lab::Exception::CorruptParameter->throw(
            "Error while setting baud: $status");
    }

    # split data ( more than one onfunction )
    if ( $num_of_onfunctions > 1 ) {
        my @DATA;
        my $num = @data;

        for ( my $i = 0; $i < @data; $i++ ) {
            $DATA[ $i % $num_of_onfunctions ]
                [ int( $i / $num_of_onfunctions ) ] = $data[$i];
        }

        if ( $print eq "PRINT" ) {
            foreach my $item (@DATA) {
                foreach my $i (@$item) {
                    print "$i\t";
                }
                print "\n";
            }
        }

        return @DATA;
    }

    if ( $print eq "PRINT" ) {
        foreach my $i (@data) {
            print $i. "\n";
        }
    }

    return @data;
}

# -------------------------------------- TRIGGER ----------------------------------------------

sub _set_trigger_count {    # internal/advanced use only
    my $self         = shift;
    my $triggercount = shift;

    if ( $triggercount >= 1 && $triggercount <= 2500 ) {
        return $self->query(
            sprintf( ":TRIGGER:COUNT %d; COUNT?", $triggercount ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for TRIGGERCOUNT in  sub _set_trigger_count. Must be between 1 and 2500."
        );
    }
}

sub _set_trigger_delay {    # internal/advanced use only
    my $self         = shift;
    my $triggerdelay = shift;

    if ( not defined $triggerdelay ) {
        $triggerdelay = $self->query(":TRIGGER:DELAY?");
        return chomp $triggerdelay;
    }

    if ( $triggerdelay >= 0 && $triggerdelay <= 999999.999 ) {
        print "triggerdelay = " . $triggerdelay . "\n";
        return $self->query(
            sprintf( ":TRIGGER:DELAY %.3f; DELAY?", $triggerdelay ) );
    }
    elsif ( $triggerdelay =~ /\b(MIN|min|MAX|max|DEF|def)\b/ ) {
        print "triggerdelay = " . $triggerdelay . "\n";
        return $self->query(
            sprintf( ":TRIGGER:DELAY %s; DELAY?", $triggerdelay ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for TRIGGERDELAY in  sub _set_trigger_delay. Must be between 0 and 999999.999sec."
        );
    }
}

sub _set_timer {    # internal/advanced use only
    my $self  = shift;
    my $timer = shift;

    if ( $timer >= 0 && $timer <= 999999.999 ) {
        $self->write( sprintf( ":ARM:TIMER %.3f", $timer ) );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "unexpected value for TIMER in  sub _set_timer. Must be between 0 and 999999.999sec."
        );
    }
}

# -----------------------------------------DISPLAY --------------------------------

sub display_on {    #
    my $self = shift;
    $self->write(":DISPLAY:ENABLE ON");
}

sub display_off {    #
    my $self = shift;
    $self->write(":DISPLAY:ENABLE OFF")
        ; # when display is disabled, the instrument operates at a higher speed. Frontpanel commands are frozen.
}

sub display {
    my $self = shift;
    my $data = shift;

    if ( not defined $data ) {
        return $self->display_text();
    }
    elsif ( $data =~ /\b(ON|on)\b/ ) {
        return $self->display_on();
    }
    elsif ( $data =~ /\b(OFF|off)\b/ ) {
        return $self->display_off();
    }
    elsif ( $data =~ /\b(CLEAR|clear)\b/ ) {
        return $self->display_clear();
    }
    else {
        return $self->display_text($data);
    }
}

sub display_text {    #
    my $self = shift;
    my $text = shift;

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

sub display_clear {    #
    my $self = shift;
    $self->write("DISPlay:TEXT:STATE 0");
}

# ----------------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::Keithley2400 - Keithley 2400 SourceMeter (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

	use Lab::Instrument::Keithley2400;
	my $DMM=new Lab::Instrument::Keithley2400(0,GPIB-address);
	print $DMM->get_value();

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

The Lab::Instrument::Keithley2400 class implements an interface to the Keithley 2400 digital multimeter.

=head1 CAVEATS

The Keithley2400 instrument driver is in a quite bad condition and would need a major revision.
However it works within the XPRESS Voltage sweep for list and step mode pretty well.

=head1 CONSTRUCTOR

	my $DMM=new(\%options);

=head1 METHODS

=head2 get_value

	$value=$DMM->get_value(<$function>);

Request a measurement value using the current instrument settings. 
$function is an optional parameter. If $function is defined, a measurement using $function as the operating mode will be requested.

=over 4

=item <$function>

C<FUNCTION> can be one of the measurement methods of the Keithley2000.

	"current" --> DC current measurement 
	"voltage" --> DC voltage measurement 
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=back

=head2 get_temperature

	$value=$DMM->get_value($sensor, <$function>, <$range>);

Make a measurement defined by $function with the previously specified range
and integration time.

=over 4

=item $sensor

C<SENSOR> can be one of the Temperature-Diodes defined in Lab::Instrument::TemperatureDiodes.

=item <$function>

FUNCTION can be one of the measurement methods of the Keithley2400.

	"diode" --> read out temperatuer diode
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item <$range>

RANGE is given in terms of amps or ohms and can be C< 1e-5 | 1e-4 | 1e-3 | MIN | MAX | DEF > or C< 0...101e6 | MIN | MAX | DEF | AUTO >.	
C<DEF> is default C<AUTO> activates the AUTORANGE-mode.
C<DEF> will be set, if no value is given.

=back

=head2 set_output

	$output = $K6221->set_output($value);

Switch device OUTPUT ON/OFF or set new OUTPUT value.
If no parameter is given, the current device output value will be returned.

=over

=item $value

VALUE can be any numeric value within the current range setting or ON/OFF to switch the device OUTPUT ON/OFF.

=back

=head2 get_output

	$output = $K6221->get_output(<$mode>);

Returns the current device output value or state.
If no parameter is given, the current device output value will be returned.

=over

=item <$mode>

MODE can be 'STATE' to request the current output state (ON/OFF) or 'VALUE' to request the current output value.

=back

=head2 config_measurement

	$K2400->config_measurement($function, $number_of_points, <$time>, <$range>);

Preset the Keithley2400 for a TRIGGERED measurement.

WARNING: It's not recomended to perform triggered measurments with the KEITHLEY 2000 DMM due to unsolved timing problems!!!!!

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Keithley2000.

	"current" --> DC current measurement 
	"voltage" --> DC voltage measurement 
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $number_of_points

Preset the NUMBER OF POINTS to be taken for one measurement trace.
The single measured points will be stored in the internal memory of the Keithley2400.
For the Keithley2400 the internal memory is limited to 1024 values.

=item <$time>

Preset the TIME duration for one full trace. From TIME the integration time value for each measurement point will be derived [NPLC = (TIME *50Hz)/NOP].
Expected values are between 0.5 ... 50000 seconds.

=item <$range>

RANGE is given in terms of amps, volts or ohms and can be C< 0...+3,03A | MIN | MAX | DEF | AUTO >, C< 0...757V(AC)/1010V(DC) | MIN | MAX | DEF | AUTO > or C< 0...101e6 | MIN | MAX | DEF | AUTO >.	
C<DEF> is default C<AUTO> activates the AUTORANGE-mode.
C<DEF> will be set, if no value is given.

=back

=head2 trg

	$K2400->trg();

Sends a trigger signal via the GPIB-BUS to start the predefined measurement.
The LabVisa-script can immediatally be continued, e.g. to start another triggered measurement using a second Keithley2400.

=head2 abort

	$K2400->abort();

Aborts current (triggered) measurement.

=head2 active

	$K2400->abort();

Returns '1' if the current triggered measurement is still active and '0' if the current triggered measurement has allready been finished.

=head2 wait

	$K2400->abort();

WAIT until triggered measurement has been finished.

=head2 get_data

	@data = $K2400->get_data();

Reads all recorded values from the internal buffer and returnes them as an array of floatingpoint values.
Reading the buffer will start immediately after the triggered measurement has finished. The LabVisa-script cannot be continued until all requested readings have been recieved.

=head2 set_function

	$K2400->set_function($function);

Set a new value for the measurement function of the Keithley2400.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Keithley2000.

	"current" --> DC current measurement 
	"voltage" --> DC voltage measurement 
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=back

=head2 set_range

	$K2400->set_range($function,$range);

Set a new value for the predefined RANGE for the measurement function $function of the Keithley2400.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Keithley2000.

	"current" --> DC current measurement 
	"voltage" --> DC voltage measurement 
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $range

RANGE is given in terms of amps, volts or ohms and can be C< 0...+3,03A | MIN | MAX | DEF | AUTO >, C< 0...757V(AC)/1010V(DC) | MIN | MAX | DEF | AUTO > or C< 0...101e6 | MIN | MAX | DEF | AUTO >.	
C<DEF> is default C<AUTO> activates the AUTORANGE-mode.
C<DEF> will be set, if no value is given.

=back

=head2 set_nplc

	$K2400->set_nplc($function,$nplc);

Set a new value for the predefined NUMBER of POWER LINE CYCLES for the measurement function $function of the Keithley2400.

=over 4

=item $function

C<FUNCTION> can be one of the measurement methods of the Keithley2000.

	"current" --> DC current measurement 
	"voltage" --> DC voltage measurement 
	"resisitance" --> resistance measurement (2-wire)
	"fresistance" --> resistance measurement (4-wire)

=item $nplc

Preset the NUMBER of POWER LINE CYCLES which is actually something similar to an integration time for recording a single measurement value.

The values for $nplc can be any value between 0.01 ... 10.

Example: 
Assuming $nplc to be 10 and assuming a netfrequency of 50Hz this results in an integration time of 10*50Hz = 0.2 seconds for each measured value. Assuming $number_of_points to be 100 it takes in total 20 seconds to record all values for the trace.

=back

=head2 set_averaging

	$K2400->set_averaging($count, <$filter>);

Set a new value for the predefined NUMBER of POWER LINE CYCLES for the measurement function $function of the Keithley2400.

=over 4

=item $count

COUNT is the number of readings to be taken to fill the AVERAGING FILTER. COUNT can be 1 ... 100.

=item <$filter>

FILTER can be MOVING or REPEAT. A detailed description is refered to the user manual.

=back

=head2 display_on

	$K2400->display_on();

Turn the front-panel display on.

=head2 display_off

	$K2400->display_off();

Turn the front-panel display off.

=head2 display_text

	$K2400->display_text($text);
	print $K2400->display_text();

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.
Without parameter the displayed message is returned.

=head2 display_clear

	$K2400->display_clear();

Clear the message displayed on the front panel.

=head2 reset

	$K2400->reset();

Reset the multimeter to its power-on configuration.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2015       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
