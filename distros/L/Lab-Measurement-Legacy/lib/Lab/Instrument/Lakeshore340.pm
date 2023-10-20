package Lab::Instrument::Lakeshore340;
$Lab::Instrument::Lakeshore340::VERSION = '3.899';
#ABSTRACT: Lakeshore 340 temperature controller

use v5.20;

use warnings;
use strict;

use Lab::Instrument;

our @ISA = ('Lab::Instrument');

our %fields = (
    supported_connections => [ 'GPIB', 'VISA' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
        timeout      => 1
    },

    device_settings => {

    },

    device_cache => {
        T        => undef,
        setpoint => undef,
        range    => undef,
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

sub get_value {
    my $self = shift;

    return $self->get_T(@_);
}

sub get_T {

    my $self = shift;
    my ( $channel, $tail ) = $self->_check_args( \@_, ['channel'] );

    if ( not defined $channel ) {
        $channel = "A";
    }
    elsif ( not $channel =~ /\b(a|b|c|d)\b/i ) {
        die
            "unexpected value ($channel) for CHANNEL in sub get_T. Expected values are A or B.";
    }

    return $self->query( "KRDG? $channel", $tail );
}

sub set_T {
    my $self = shift;
    return $self->set_setpoint(@_);
}

sub get_setpoint {

    my $self = shift;

    my ( $loop, $tail ) = $self->_check_args( \@_, ['loop'] );

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub get_setpoint. Expected values are 1 or 2.";
    }

    return $self->query("SETP? $loop");
}

sub set_setpoint {
    my $self = shift;

    my ( $setpoint, $loop, $tail )
        = $self->_check_args( \@_, [ 'value', 'loop' ] );

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub set_T. Expected values are 1 or 2.";
    }

    if ( $setpoint < 0 or $setpoint > 300 ) {
        die
            "unexpected value ($setpoint) for SETPOINT in sub set_T. Expected values are between 0...300 K.";
    }

    # Device bug. The 340 cannot parse values with too many digits.
    $setpoint = sprintf( '%.6G', $setpoint );

    return $self->query( "SETP $loop,$setpoint; SETP? $loop", $tail );

}

sub set_range {
    my $self  = shift;
    my $range = shift;

    if ( $range =~ /\b(OFF)\b/i ) {
        $range = 0;
    }
    elsif ( $range =~ /\b(LOW)\b/i ) {
        $range = 1;
    }
    elsif ( $range =~ /\b(MEDIUM|MED)\b/i ) {
        $range = 2;
    }
    elsif ( $range =~ /\b(HIGH)\b/i ) {
        $range = 3;
    }
    elsif ( $range =~ /\b(GIANT)\b/i ) {
        $range = 4;
    }
    elsif ( $range =~ /\b(MAX)\b/i ) {
        $range = 5;
    }
    else {
        die
            "unexpected value ($range) for RANGE in sub set_range. Expected values are OFF, LOW, MEDIUM, HIGH, GIANT, MAX.";
    }

    # set range
    return $self->query("RANGE $range; RANGE?");

}

sub get_range {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_, [] );
    my $range = $self->query( "RANGE?", $tail );

    if ( $range == 0 ) {
        $range = 'OFF';
    }
    elsif ( $range == 1 ) {
        $range = 'LOW';
    }
    elsif ( $range == 2 ) {
        $range = 'MEDIUM';
    }
    elsif ( $range == 3 ) {
        $range = 'HIGH';
    }
    elsif ( $range == 4 ) {
        $range = 'GIANT';
    }
    elsif ( $range == 5 ) {
        $range = 'MAX';
    }
    else {
        die
            "unexpected value ($range) for RANGE in sub get_range. Expected values are OFF, LOW, MEDIUM, HIGH, GIANT, MAX.";
    }
}

sub set_heatercontrol {

}

sub set_control_mode {

    my $self = shift;

    my ( $mode, $loop, $tail )
        = $self->_check_args( \@_, [ 'value', 'loop' ] );

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub set_control_mode. Expected values are 1 or 2.";
    }

    if ( $mode =~ /\b(MANUAL|manual|MAN|man)\b/ ) {
        $mode = 1;
    }
    elsif ( $mode =~ /\b(ZONE|zone)\b/ ) {
        $mode = 2;
    }
    elsif ( $mode =~ /\b(OFF|off)\b/ ) {
        $mode = 3;
    }
    elsif ( $mode =~ /\b(AUTO_PID|auto_pid)\b/ ) {
        $mode = 4;
    }
    elsif ( $mode =~ /\b(AUTO_PI|auto_pi)\b/ ) {
        $mode = 5;
    }
    elsif ( $mode =~ /\b(AUTO_P|auto_p)\b/ ) {
        $mode = 6;
    }
    else {
        die
            "unexpected value ($mode) for CONTROL MODE in sub set_controlmode. Expected values are MANUAL, ZONE, AUTO_PID, AUTO_PI, AUTO_P and OFF.";
    }

    return $self->query("CMODE $loop,$mode; CMODE? $loop");

}

sub get_control_mode {
    my $self = shift;
    my ( $loop, $tail ) = $self->_check_args( \@_, ['loop'] );

    if ( not defined $loop ) {
        $loop = 1;
    }

    return $self->query( "CMODE? $loop", $tail );
}

sub get_R {

    my $self = shift;
    my ( $channel, $tail ) = $self->_check_args( \@_, ['channel'] );

    if ( not defined $channel ) {
        $channel = "A";
    }
    elsif ( not $channel =~ /\b(A|a|B|b)\b/ ) {
        die
            "unexpected value ($channel) for CHANNEL in sub get_R. Expected values are A or B.";
    }

    return $self->query( "SRDG? $channel", $tail );
}

sub set_control_loop {

    my $self = shift;

    my ( $channel, $loop, $units, $powerup, $display, $tail )
        = $self->_check_args(
        \@_,
        [ 'channel', 'loop', 'units', 'powerup', 'display' ]
        );

    # loop optinal parameter; Usually you alwas want to use control loop 1
    # units optinal parameter; 1 == Kelvin, 2 == Celsius, 3 == sensor units
    # powerup optinal parameter; 0 == power up enable off,  1 == power up enable on
    # display optinal parameter; 1 == current, 2 == power

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub set_control_loop. Expected values are 1 or 2.";
    }

    if ( not defined $units ) {
        $units = 1;
    }
    elsif ( $units =~ /\b(KELVIN|kelvin|K|k)\b/ ) {
        $units = 1;
    }
    elsif ( $units =~ /\b(CELSIUS|celsius|C|c)\b/ ) {
        $units = 2;
    }
    elsif ( $units =~ /\b(SENSOR|sensor|S|s)\b/ ) {
        $units = 3;
    }
    elsif ( $units != 1 and $units != 2 and $units != 3 ) {
        die
            "unexpected value ($units) for UNITS in sub set_control_loop. Expected values are KELVIN, CELSIUS or SENSOR.";
    }

    if ( not defined $powerup ) {
        $powerup = 1;
    }
    elsif ( $powerup =~ /\b(ON|on)\b/ ) {
        $powerup = 1;
    }
    elsif ( $powerup =~ /\b(OFF|off)\b/ ) {
        $powerup = 0;
    }
    elsif ( $powerup != 0 and $powerup != 1 ) {
        die
            "unexpected value ($powerup) for POWERUP in sub set_control_loop. Expected values are ON or OFF.";
    }

    if ( not defined $display ) {
        $display = 2;
    }
    elsif ( $display =~ /\b(CURRENT|current)\b/ ) {
        $display = 1;
    }
    elsif ( $display =~ /\b(POWER|power)\b/ ) {
        $display = 2;
    }
    elsif ( $display != 1 and $display != 2 ) {
        die
            "unexpected value ($display) for DISPLAY in sub set_control_loop. Expected values are CURRENT or POWER.";
    }

    if ( not $channel =~ /\b(A|a|B|b)\b/ ) {
        die
            "unexpected value ($channel) for CHANNEL in sub set_control_loop. Expected values are 'A' or 'B'.";
    }

    # set control loop:
    $loop = $self->query(
        "CSET $loop, $channel, $units, $powerup, $display; CSET? $loop",
        $tail
    );

    my @loop = split( /, /, $loop );
    return @loop;

}

sub get_control_loop {
    my $self = shift;

    my ( $loop, $tail ) = $self->_check_args( \@_, ['loop'] );

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub set_control_loop. Expected values are 1 or 2.";
    }

    my $result = $self->query( "CSET? $loop", $tail );

    return split( /, /, $result );

}

sub set_input_curve {

    my $self = shift;

    my ( $channel, $curve, $tail )
        = $self->_check_args( \@_, [ 'channel', 'curve' ] );

    if ( not defined $curve and not defined $channel ) {
        die
            "too fiew parameters given in sub set_input_curve. Expected parameters are CHANNEL and CURVE.";
    }
    elsif ( not $channel =~ /\b(A|a|B|b)\b/ ) {
        die
            "unexpected value ($channel) for CHANNEL in sub set_input_curve. Expected values are 'A' or 'B'.";
    }
    elsif ( $curve < 0 and $curve > 41 ) {
        die
            "unexpected value ($curve) for CURVE in sub set_input_curve. Expected values are between 0 ... 41.";
    }
    return $self->query("INCRV $channel,$curve; INCRV? $channel");
}

sub get_input_curve {
    my $self = shift;
    my ( $channel, $tail ) = $self->_check_args( \@_, ['channel'] );

    if ( not $channel =~ /\b(A|a|B|b)\b/ ) {
        die
            "unexpected value ($channel) for CHANNEL in sub set_input_curve. Expected values are 'A' or 'B'.";
    }

    return $self->query( "INCRV? $channel", $tail );
}

sub set_remote {
    my $self = shift;

    my ( $mode, $tail ) = $self->_check_args( \@_, ['mode'] );

    if ( not defined $mode ) {

    }
    elsif ( $mode =~ /\b(LOCAL|local)\b/ ) {
        $mode = 0;
    }
    elsif ( $mode =~ /\b(REMOTE|remote)\b/ ) {
        $mode = 1;
    }
    elsif ( $mode =~ /\b(LOCK|lock)\b/ ) {
        $mode = 2;
    }
    else {
        die
            "unexpected value ($mode) for MODE in sub set_remote. Expected values are between LOCAL, REMOTE and LOCK.";
    }

    $mode = $self->query("MODE $mode; MODE?");

    if ( $mode == 0 ) {
        $mode = "LOCAL";
    }
    elsif ( $mode == 1 ) {
        $mode = "REMOTE";
    }
    elsif ( $mode == 2 ) {
        $mode = "LOCK";
    }

    return $mode;
}

sub get_remote {
    my $self = shift;

    my ($tail) = $self->_check_args( \@_, [] );

    my $mode = $self->query( "MODE?", $tail );

    if ( $mode == 0 ) {
        $mode = "LOCAL";
    }
    elsif ( $mode == 1 ) {
        $mode = "REMOTE";
    }
    elsif ( $mode == 2 ) {
        $mode = "LOCK";
    }

    return $mode;
}

# Bin bis hier her gekommen

sub set_PID {
    my $self = shift;
    my $P    = shift;
    my $I    = shift;
    my $D    = shift;
    my $loop = shift
        ;    # optinal parameter; Usually you alwas want to use control loop 1

    if (    not defined $loop
        and not defined $D
        and not defined $I
        and not defined $P ) {
        $loop = 1;
        my $PID = $self->query("PID $loop, $P, $I, $D; PID?");
        chomp $PID;
        chomp $PID;
        my @PID = split( /, /, $PID );

        return @PID;
    }
    elsif ( not defined $loop
        and not defined $D
        and not defined $I
        and ( $P == 1 or $P == 2 ) ) {
        $loop = $P;
        my $PID = $self->query("PID $loop, $P, $I, $D; PID?");
        chomp $PID;
        chomp $PID;
        my @PID = split( /, /, $PID );

        return @PID;
    }
    elsif ( not defined $loop and not defined $D ) {
        die
            "too fiew parameters given in sub set_PID. Expected parameters are P, I, D.";
    }
    elsif ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub set_PID. Expected values are between 1 and 2.";
    }

    # else {
    #     die "unexpected values in sub set_PID.";
    # }

    if ( $D < 0 or $D > 200 ) {
        die
            "unexpected value ($D) for D in sub set_PID. Expected values are between 0 and 200.";
    }
    elsif ( $I < 0.1 or $I > 1000 ) {
        die
            "unexpected value ($I) for I in sub set_PID. Expected values are between 0.1 and 1000.";
    }
    elsif ( $P < 0.1 or $P > 1000 ) {
        die
            "unexpected value ($P) for P in sub set_PID. Expected values are between 0.1 and 1000.";
    }
    else {
        my $PID = $self->query("PID $loop, $P, $I, $D; PID? $loop");
        chomp $PID;
        chomp $PID;
        my @PID = split( /, /, $PID );

        return @PID;
    }

}

sub set_zone {

    my $self       = shift;
    my $zone       = shift;
    my $t_limit    = shift;
    my $P          = shift;
    my $I          = shift;
    my $D          = shift;
    my $range      = shift;
    my $man_output = shift;    # optional parameter, usually zero
    my $loop       = shift
        ;    # optinal parameter; Usually you alwas want to use control loop 1

    if ( defined $zone and ( $zone < 1 or $zone > 10 ) ) {
        die
            "unexpected value ($zone) for ZONE in sub set_zone. Expected values are all integer values from 1 to 10.";
    }

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub set_zone. Expected values are 1 or 2.";
    }

    if ( not defined $man_output ) {
        $man_output = 0;
    }
    elsif ( $man_output < 0 or $man_output > 100 ) {
        die
            "unexpected value ($man_output) for MANUAL OUTPUT in sub set_zone. Expected values are between 0 ... 100 %.";
    }

    if (    not defined $range
        and not defined $D
        and not defined $I
        and not defined $P
        and not defined $t_limit ) {
        return;
    }

    if ( not defined $range ) {
        die
            "too fiew parameters given for sub set_zone. Expected parameters are ZONE, T_LIMIT, P, I, D, RANGE and optional <MAN_OUTPUT> and <LOOP>.";
    }

    if ( $t_limit < 0 or $t_limit > 300 ) {
        die
            "unexpected value ($t_limit) for T_LIMIT in sub set_zone. Expected values are between 0 and 300 K.";
    }
    elsif ( $D < 0 or $D > 200 ) {
        die
            "unexpected value ($D) for D in sub set_zone. Expected values are between 0 and 200.";
    }
    elsif ( $I < 0.1 or $I > 1000 ) {
        die
            "unexpected value ($I) for I in sub set_zone. Expected values are between 0.1 and 1000.";
    }
    elsif ( $P < 0.1 or $P > 1000 ) {
        die
            "unexpected value ($P) for P in sub set_zone. Expected values are between 0.1 and 1000.";
    }

    if ( $range =~ /\b(OFF|off)\b/ ) {
        $range = 0;
    }
    elsif ( $range =~ /\b(LOW|low)\b/ ) {
        $range = 1;
    }
    elsif ( $range =~ /\b(MEDIUM|medium|MED|med)\b/ ) {
        $range = 2;
    }
    elsif ( $range =~ /\b(HIGH|high)\b/ ) {
        $range = 3;
    }
    else {
        die
            "unexpected value ($range) for RANGE in sub set_zone. Expected values are OFF, LOW, MEDIUM, HIGH.";
    }

    # set zone:
    $zone
        = $self->query(
        "ZONE $loop, $zone, $t_limit, $P, $I, $D, $man_output, $range; ZONE?"
        );
    chomp $zone;
    chomp $zone;
    my @zone = split( /, /, $zone );
    return @zone;

}

sub set_heateroutput {

    my $self   = shift;
    my $output = shift;
    my $loop   = shift
        ;    # optinal parameter; Usually you alwas want to use control loop 1

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub set_heater_output. Expected values are 1 or 2.";
    }

    if ( not defined $output ) {
        $output = $self->query("Mout? $loop");
        chomp $output;
        chomp $output;
        return $output;
    }
    elsif ( $output >= 0 and $output <= 100 ) {
        $output = $self->query("MOUT $loop, $output; Mout? $loop");
        chomp $output;
        chomp $output;
        return $output;
    }
    else {
        die
            "unexpected value ($output) for OUTPUT in sub set_heater_output. Expected values are between 0 ... 100 % of full heater range.";
    }

}

sub set_input_sensor {

    my $self         = shift;
    my $channel      = shift;
    my $sensor_type  = shift;
    my $compensation = shift;

    # check input parameter:

    if ( not defined $channel ) {
        $channel = $self->query(
            "INTYPE $channel, $sensor_type, $compensation; INTYPE? $channel");
        chomp $channel;
        chomp $channel;
        my @channel = split( /, /, $channel );
        return @channel;
    }
    elsif ( not $channel =~ /\b(A|a|B|b)\b/ ) {
        die
            "unexpected value ($channel) for CHANNEL in sub set_input_sensor. Expected values are 'A' or 'B'.";
    }

    if ( not defined $sensor_type ) {

        #	0 = Silicon Diode
        #	1 = GaAlAs Diode
        #	2 = Platinum 100/250 O
        #	3 = Platinum 100/500 O
        #	4 = Platinum 1000 O
        #	5 = NTC RTD 75mV 7.5 kO
        #	6 = Thermocouple 25 mV
        #	7 = Thermocouple 50 mV
        #	8 = NTC RTD 75mV 75 O
        #	9 = NTC RTD 75mV 750 O
        #	10 = NTC RTD 75mV 7.5 kO
        #	11 = NTC RTD 75mV 75 kO
        #	12 = NTC RTD 75mV Auto

        $sensor_type = 12;

    }
    elsif ( not( $sensor_type >= 1 and $sensor_type <= 12 ) ) {
        die
            "unexpected value ($sensor_type) for SENSOR_TYPE in sub set_input_sensor. Expected values are all integervalues between 0 ... 12.";
    }

    if ( not defined $compensation ) {
        $compensation = 0;    # 0 == OFF, 1 == ON
    }
    elsif ( $compensation =~ /\b(ON|on)\b/ ) {
        $compensation = 1;
    }
    elsif ( $compensation =~ /\b(OFF|off)\b/ ) {
        $compensation = 0;
    }
    elsif ( $compensation != 0 and $compensation != 1 ) {
        die
            "unexpected value ($compensation) for COMPENSATION in sub set_input_sensor. Expected values are ON or OFF.";
    }

    # set input sensor:

    $channel = $self->query(
        "INTYPE $channel, $sensor_type, $compensation; INTYPE? $channel");
    chomp $channel;
    chomp $channel;
    my @channel = split( /, /, $channel );
    return @channel;

}

sub set_filter {

    my $self    = shift;
    my $channel = shift;
    my $points  = shift;
    my $window  = shift;

    my $active = 1;    # set the filter active  after changing parameters

    # check input paramters:
    if ( defined $channel and not $channel =~ /\b(A|a|B|b)\b/ ) {
        die
            "unexpected value ($channel) for CHANNEL in sub set_filter. Expected values are between 'A' and 'B'.";
    }

    if (    not defined $window
        and not defined $points
        and not defined $channel ) {
        die
            "too fiew parameters given. Expected parameters are CHANNEL, POINTS, <WINDOW>";
    }
    elsif ( not defined $window and not defined $points ) {
        my $filter = $self->query("FILTER? $channel");
        chomp $filter;
        chomp $filter;

        my @filter = split( /, /, $filter );

        if ( $filter[0] == 0 ) {
            $filter[0] = 'OFF';
        }
        else {
            $filter[0] = 'ON';
        }

        return @filter;

    }
    elsif ( not defined $window ) {
        $window = 1;
    }
    elsif ( $window < 1 or $window > 10 ) {
        die
            "unexpected value ($window) for WINDOW in sub set_filter. Expected values are between 1 .. 10 % of full scale reading limits.";
    }

    if ( $points =~ /\b(OFF|off)\b/ ) {
        my $filter = $self->query("FILTER? $channel");
        chomp $filter;
        chomp $filter;
        my @filter = split( /, /, $filter );

        $active = 0;
        $points = $filter[1];
        $window = $filter[2];

    }
    if ( $points < 2 or $points > 64 ) {
        die
            "unexpected value ($points) for POINTS in sub set_filter. Expected values are between 2 .. 64.";
    }

    # set filter paramters:

    my $filter = $self->query(
        "FILTER $channel,$active,$points,$window; FILTER? $channel");
    chomp $filter;
    chomp $filter;
    my @filter = split( /, /, $filter );

    if ( $filter[0] == 0 ) {
        $filter[0] = 'OFF';
    }
    else {
        $filter[0] = 'ON';
    }

    return @filter;

}

sub config_sweep {
    my $self     = shift;
    my $setpoint = shift;
    my $rate     = shift;
    my $loop     = shift
        ;    # optinal parameter; Usually you alwas want to use control loop 1

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub config_sweep. Expected values are 1 or 2.";
    }

    if ( not defined $rate or $rate < 0.1 or $rate > 100 ) {
        die
            "unexpected value ($rate) for RATE in sub config_sweep. Expected values are between 0...100 K/min.";
    }
    elsif ( not defined $setpoint or $setpoint < 0 or $setpoint > 300 ) {
        die
            "unexpected value ($setpoint) for SETPOINT in sub config_sweep. Expected values are between 0...300 K.";
    }

    $rate     = $self->query("RAMP $loop,0,$rate; RAMP? $loop");
    $setpoint = $self->query("SETP $loop,$setpoint; SETP? $loop");

    return $setpoint, $rate;

}

sub trg {
    my $self = shift;
    my $loop = shift
        ;    # optinal parameter; Usually you alwas want to use control loop 1

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub trg. Expected values are 1 or 2.";
    }

    my $rate = $self->query("RAMP? $loop");
    $rate = $self->write("RAMP $loop,1,$rate");

    return 1;

}

sub halt {

    my $self = shift;
    my $loop = shift
        ;    # optinal parameter; Usually you alwas want to use control loop 1

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub halt. Expected values are 1 or 2.";
    }

    my $rate = $self->query("RAMP? $loop");
    $rate = $self->write("RAMP $loop,0,$rate");

    # get control loop channel
    my @channel = $self->set_control_loop();
    my $channel = $channel[0];

    # get current temperature
    my $temperature_now = $self->get_T($channel);
    $self->set_T($temperature_now);

    # stop sweeping
    $rate = $self->write("RAMP $loop,0,0.1");

    return 1;
}

sub active {

    my $self = shift;
    my $loop = shift
        ;    # optinal parameter; Usually you alwas want to use control loop 1

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub active. Expected values are 1 or 2.";
    }

    my $status = $self->query('RAMPST? $loop');
    chomp $status;
    chomp $status;
    return $status;
}

sub wait {

    my $self = shift;
    my $loop = shift
        ;    # optinal parameter; Usually you alwas want to use control loop 1

    if ( not defined $loop ) {
        $loop = 1;
    }
    elsif ( $loop != 1 and $loop != 2 ) {
        die
            "unexpected value ($loop) for LOOP in sub active. Expected values are 1 or 2.";
    }

    print "waiting for the temperature sweep to end.";
    while ( $self->active() ) {
        print $self->get_T('A') . ", " . $self->get_T('B') . "\n";
    }

    return;

}

sub id {
    my $self = shift;
    $self->query('*IDN?');
}

sub reset {

    my $self = shift;
    $self->write("*RST");

}

sub factory_reset {

    my $self = shift;
    $self->write("DFLT 99");

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::Lakeshore340 - Lakeshore 340 temperature controller (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

 use Lab::Measurement::Legacy;
 my $lake = Instrument('Lakeshore340', {
     connection_type => ...,
     gpib_address => ...
     });
     
 my $temp = $lake->get_T({channel => 'C'});
 
 $lake->set_T({value => 5.5, loop => 1});

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

The Lab::Instrument::Lakeshore340 class implements an interface to the
Lakeshore 340 AC Resistance Bridge.

For use in XPRESS temperature sweeps, see the example script
F<examples/XPRESS/lakeshore340_sweep.pl>.

=head1 METHODS

=head2 get_T

	$t = $lake->get_T(<$channel>);

Reads temperature in Kelvin (only possible if temperature curve is available, otherwise returns zero).

=over 4

=item $channel

CHANNEL is an optinal parameter to select the sensor channel (A/B/C/D) for the measurement.
If not defined the default channel 'A' will be selected.

=back

=head2 get_R

	$t = $lake->get_R(<$channel>);

Reads resistance in Ohm.

=over 4

=item $channel

CHANNEL is an optinal parameter to select the sensor channel (A/B/C/D) for the measurement.
If not defined the default channel 'A' will be selected.

=back

=head2 set_T

	$sp = $lake->set_T($setpoint, <$loop>);

Set new temperature SETPOINT for temperature control loop $loop. Returns the new setpoint.
If no parameters are given, the currently valid SETPOINT will be returned.

=over 4

=item $setpoint

New temperature Setpoint.

=item $loop

Optional prameter to select the temperature control loop for which the new setting will be valid.
If not defined the default value $loop = 1 will be selected.
Possible values are '1' and '2'.

=back

.

=head2 set_range

	$heater_range = $lake->set_range($range);

Set the HEATER RANGE.

=over 4

=item $range 

RANGE can be 'OFF', 'LOW', 'MEDIUM', 'HIGH', 'GIANT' or 'MAX'.

=back

.

=head2 set_input_curve

	$lake->set_input_curve($channel, $curve);

Set for SENSOR CHANNEL $channel the resistance-to-temperatur CURVE with the internal storage number $curve.

=over 4

=item $channel

CHANNEL selects the SENSOR CHANNEL and can be 'A' or 'B'.

=item $curve

CURVE reverse to one ov the internally stored resistance-to-temperatur CURVES and can be 0 .. 41.

=back

.

=head2 set_PID

	@PID = $lake->set_PID($P,$I,$D);

Set new values for the PID temperature control circuit.

=over 4

=item $P

The PROPORTIONAL term, also called gain must have a value greater then zero for the control loop to operate. It's maximum value is 1000.

=item $I

The INTEGRAL term looks at error over time to build the integral contribution to the output. Values are 0.1 ... 1000.

=item $D

The DERIVATIVE term acts aon the change in error with time to make its contribution to the output. Values: 0 ... 200.

=back

.

=head2 config_sweep

	$lake->config_sweep($setpoint, $rate);

Predefine a temperature sweep.

=over 4

=item $setpoint

Predefine the temperature target setpoint for a temperatue sweep. Values 0 .. 300 K.

=item $rate

Predefine sweep rate for a temperature sweep. Values 0.1 ... 100 K/minute.

=back

.

=head2 trg

	$lake->trg();

Start a predefined temperature sweep.

=head2 halt

	$lake->halt();

Stop running temperature sweep.

=head2 active

	$lake->active();

Returns 1 if a temperature sweep is running and 0 if not.

=head2 wait

	$lake->wait();

Wait until the currently active temperature sweep has been finished.

=head2 id

	$id=$sr780->id();

Returns the instruments ID string.

.

=head1 CAVEATS/BUGS

probably many

.

=head1 SEE ALSO

=over 4

=item Lab::Instrument

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013-2014  Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
