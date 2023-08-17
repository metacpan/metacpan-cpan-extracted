# Please note: The Oxford IPS expects a \r after all commands, no matter 
# which connection is used. For rs232 connection, additionally \n has to be added.
# Hence termchar => \n. For Isobus connection, no additional termchar must be added. 
# Hence IsoEnableTermChar => 0.

package Lab::Instrument::IPS;
#ABSTRACT: Oxford Instruments IPS Magnet Power Supply
$Lab::Instrument::IPS::VERSION = '3.881';
use v5.20;

use strict;
use Time::HiRes qw/usleep/, qw/time/;

#use Lab::VISA;
use Lab::Instrument;
use Carp;

our @ISA = ('Lab::Instrument');

my $default_config = {
    can_reverse              => 1,
    can_use_negative_current => 1,
};

our %fields = (
    supported_connections => [
        'VISA', 'VISA_GPIB', 'GPIB', 'VISA_RS232', 'RS232', 'IsoBus', 'DEBUG'
    ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board        => undef,
        gpib_address      => undef,
        baudrate          => 9600,
        databits          => 8,
        stopbits          => 2,
        parity            => 'none',
        handshake         => 'none',
        termchar          => "\r",
        IsoEnableTermChar => 0,
        timeout           => 2,
    },

    device_settings => {
        id               => 'Oxford IPS',
        has_switchheater => 0,
        read_default     => 'device'
    },

    device_cache => {
        targetfield     => undef,
        rate            => undef,
        field           => undef,
        persistent_mode => 0

        }

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->{LIMITS} = {
        'magneticfield'          => 0,
        'field_intervall_limits' => [ 0, 0, 0, 0 ],
        'rate_intervall_limits'  => [ 0, 0, 0, 0 ]
    };

    return $self;
}

sub get_version {    # internal only
        # returns the VERSION of the POWERSUPPLY, e.g. IPS180-20 or IPS120-10
    my $self    = shift;
    my $version = $self->query("V\r");

    return $version;
}

sub _device_init {    # internal only
    my $self   = shift;
    my $magnet = shift;

    $self->connection()->SetTermChar( chr(13) );
    $self->connection()->EnableTermChar(1);
    $self->{SWEEP_CONFIG_ARMED} = 0;
    $self->_set_control(3);

    my $device_settings = $self->device_settings();
    if ( $device_settings->{has_switchheater} ) {

        #print "Try to switch on the SWITCHHEATER ...";
        $self->set_persistent_mode(0);

        my $switchheater = $self->get_switchheater();
        if ( $switchheater == 0 || $switchheater == 2 ) {
            Lab::Exception::CorruptParameter->throw( error =>
                    "PSU != Magnet --> SWITCHHEATER cannot be switched on." );
        }

        #print "done\n!";
    }

    #print "Set Communication Protocol to Extended Resolution...";
    $self->_set_communicationsprotocol(4);

    #print "done!\n";
    #print "Set Magnet to Remote and Unlocked...";

    $self->_set_mode(9);

    #print "done!\n";

    #print "Clamp Magnet and Set to Hold...";
    $self->abort(0);
    usleep(5e5);

    #print "done!\n";
}

# sub _set_limits { # internal only
# my $self = shift;
# my $magnet = shift;

# # set limits
# if( $magnet =~ /\b(KRYO1|kryo1)\b/ )
# {
# %LIMITS = ( 'magneticfield' => 14, 'field_intervall_limits' => [0, 9, 11.5, 13], 'rate_intervall_limits' => [1.98, 0.66, 0.36, 0.18]);
# }
# elsif( $magnet =~ /\b(KRYO2|kryo2)\b/ )
# {
# %LIMITS = ( 'magneticfield' => 10, 'field_intervall_limits' => [0, 10], 'rate_intervall_limits' => [1.98, 1.98]);
# }
# elsif( $magnet =~ /\b(MISCHER|mischer)\b/ )
# {
# %LIMITS = ( 'magneticfield' => 17, 'field_intervall_limits' => [0, 10.99, 13.73, 16.48], 'rate_intervall_limits' => [0.660, 0.552, 0.276, 0.138]);
# }
# elsif( $magnet =~ /\b(VECTRO|vector|VECTORMAGNET|vectormagnet|3D|3d)\b/ )
# {
# %LIMITS = ( 'magneticfield' => 1.01, 'field_intervall_limits' => [0, 1.01], 'rate_intervall_limits' => [0.6, 0.6]);
# }
# else
# {
# die "unexpected value for MAGNET in sub _set_limits";
# }

# }

sub set_switchheater {    # internal only
        # 0 Heater Off                  (close switch)
        # 1 Heater On if PSU=Magnet     (open switch)
        #  (only perform operation
        #   if recorded magnet current==present power supply output current)
        # 2 Heater On, no Checks        (open switch)
    my $self = shift;
    my ( $mode, $tail ) = $self->_check_args( \@_, ['value'] );

    warn "Try to use switchheater: No switchheater installed!"
        if not $self->{device_settings}->{has_switchheater};

    #print "Trying to switch switchheater to mode $mode\n";

    if ( $mode == 0 ) {
        my $switchheater = $self->get_switchheater();
        while ( !( $switchheater == 0 || $switchheater == 2 ) ) {
            $self->query( "H$mode\r", $tail );
            sleep(1);
        }
    }
    elsif ( $mode == 1 ) {
        while ( not $self->get_switchheater() == 1 ) {

            $self->query( "H$mode\r", $tail );
            sleep(1);
        }
    }
    else {
        print Lab::Exception::Warning->new(
            "Mode $mode is not allowed for the switchheater. Select 0 (off) or 1 (on)."
        );
    }
    sleep(10);    # wait for heater to open the switch
}

sub get_switchheater {    # internal only
    my $self = shift;
    warn "Try to use switchheater: No switchheater installed!"
        if not $self->{device_settings}->{has_switchheater};

    my $result = $self->query( "X\r", @_ );
    $result =~ /X[0-9][0-9]A[0-9]C[0-9]H(.)/;
    return $1;
}

sub _set_control {        # internal only

    # 0 Local & Locked
    # 1 Remote & Locked
    # 2 Local & Unlocked
    # 3 Remote & Unlocked
    my $self = shift;
    my ( $mode, $tail ) = $self->_check_args( \@_, ['mode'] );

    $self->query( "C$mode\r", $tail );
}

sub _set_mode {    # internal only

    #       Display     Magnet Sweep
    # 0     Amps        Fast
    # 1     Tesla       Fast
    # 4     Amps        Slow
    # 5     Tesla       Slow
    # 8     Amps        Unaffected
    # 9     Tesla       Unaffected
    my $self = shift;
    my ( $mode, $tail ) = $self->_check_args( \@_, ['mode'] );

    if (    $mode != 0
        and $mode != 1
        and $mode != 4
        and $mode != 5
        and $mode != 8
        and $mode != 9 ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for MODE in sub _set_mode. Expected values are:\n\n\tDisplay\tMagnet Sweep\n 0\tAmps\tFast\n 1\tTesla\tFast\n 4\tAmps\tSlow\n 5\tTesla\tSlow\n 8\tAmps\tUnaffected\n 9\tTesla\tUnaffected"
        );
    }

    $self->query("M$mode\r");
}

sub _set_communicationsprotocol {    # internal only

    # 0 "Normal" (default)
    # 2 Sends <LF> after each <CR>
    # 4 Extended Resolution
    # 6 Extended Resolution. Sends <LF> after each <CR>.
    my $self = shift;
    my $mode = shift;

    if ( ref($mode) eq "HASH" ) {
        $mode = $mode->{mode};
    }

    if ( $mode != 0 and $mode != 2 and $mode != 4 and $mode != 6 ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for MODE in sub _set_communicationsprotocol. Expected values are:\n\n 0 --> Normal (default)\n 2 --> Sends <LF> after each <CR>\n 4 --> Extended Resolution\n 6 --> Extended Resolution. Sends <LF> after each <CR>."
        );
    }

    $self->write("Q$mode\r");    #no aswer from IPS expected
}

sub hold {
    my $self = shift;

    $self->_set_activity(0);
}

sub tosetpoint {
    my $self = shift;

    $self->_set_activity(1);

    sleep(1) while $self->active();
}

sub tozero {
    my $self = shift;

    $self->_set_activity(2);

    while ( $self->active() ) {
        sleep(1);
    }

}

sub _set_activity {    # internal only

    # 0 Hold
    # 1 To Set Point
    # 2 To Zero
    # 4 Clamp (clamp the power supply output)
    my $self = shift;
    my ( $mode, $tail ) = $self->_check_args( \@_, ['mode'] );

    if ( not 0 <= $mode && $mode <= 4 ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for MODE in sub _set_activity. Expected values are:\n\n 0 --> Hold\n 1 --> To Set Point\n 2 --> To Zero\n 4 --> Clamp (clamp the power supply output)"
        );
    }

    $self->query("A$mode\r");
}

sub set_rate {
    my $self = shift;
    my ($targetrate) = $self->_check_args( \@_, ['value'] );

    if ( $targetrate < 0.0001 ) {
        $targetrate = 0.0001;
    }

    $self->query( sprintf( "T%.5f\r", $targetrate ) );

    #printf("$self->{ID}: T%.5f\r\n", $targetrate);

    return;

}

sub get_rate {
    my $self = shift;

    my ($tail) = $self->_check_args( \@_ );

    return $self->get_parameter( 9, $tail );
}

sub set_targetfield {
    my $self = shift;
    my ($targetfield) = $self->_check_args( \@_, ['value'] );

    $self->query( sprintf( "J%.5f\r", $targetfield ) );

    #printf("$self->{ID}: J%.5f\r\n", $targetfield);

    return;

}

sub get_targetfield {
    my $self = shift;

    my ($tail) = $self->_check_args( \@_ );

    return $self->get_parameter( 8, $tail );
}

sub get_parameter {    # advanced

    # 0 --> Demand current (output current)     amp
    # 1 --> Measured power supply voltage       volt
    # 2 --> Measured magnet current             amp
    # 3 --> -
    # 4 --> -
    # 5 --> Set point (target current)          amp
    # 6 --> Current sweep rate                  amp/min
    # 7 --> Demand field (output field)         tesla
    # 8 --> Set point (target field)            tesla
    # 9 --> Field sweep rate                    tesla/minute
    #10 --> - 14 -
    #15 --> Software voltage limit              volt
    #16 --> Persistent magnet current           amp
    #17 --> Trip current                        amp
    #18 --> Persistent magnet field             tesla
    #19 --> Trip field                          tesla
    #20 --> Switch heater current               milliamp
    #21 --> Safe current limit, most negative   amp
    #22 --> Safe current limit, most positive   amp
    #23 --> Lead resistance                     milliohm
    #24 --> Magnet inductance                   henry
    my $self = shift;
    my ($parameter) = $self->_check_args( \@_, ['param'] );

    if (    $parameter != 0
        and $parameter != 1
        and $parameter != 2
        and $parameter != 3
        and $parameter != 4
        and $parameter != 5
        and $parameter != 6
        and $parameter != 7
        and $parameter != 8
        and $parameter != 9
        and $parameter != 10
        and $parameter != 15
        and $parameter != 16
        and $parameter != 17
        and $parameter != 18
        and $parameter != 19
        and $parameter != 20
        and $parameter != 21
        and $parameter != 22
        and $parameter != 23
        and $parameter != 24 ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "\n 0 --> Demand current (output current)     amp\n 1 --> Measured power supply voltage       volt\n 2 --> Measured magnet current             amp\n 3 --> -\n 4 --> -\n 5 --> Set point (target current)          amp\n 6 --> Current sweep rate                  amp/min\n 7 --> Demand field (output field)         tesla\n 8 --> Set point (target field)            tesla\n 9 --> Field sweep rate                    tesla/minute\n10 --> - 14 -\n15 --> Software voltage limit              volt\n16 --> Persistent magnet current           amp\n17 --> Trip current                        amp\n18 --> Persistent magnet field             tesla\n19 --> Trip field                          tesla\n20 --> Switch heater current               milliamp\n21 --> Safe current limit, most negative   amp\n22 --> Safe current limit, most positive   amp\n23 --> Lead resistance                     milliohm\n24 --> Magnet inductance                   henry"
        );
    }

    my $result = $self->query("R$parameter\r");
    $result =~ s/^R//;
    return $result;
}

sub get_value {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );
    return $self->get_field($tail);
}

sub get_field {    # basic
                   # returns the current value of the magnetic field

    my $self = shift;

    my ($tail) = $self->_check_args( \@_ );

    my $persistent_mode
        = $self->get_persistent_mode( { read_mode => 'cache' } );

    if ($persistent_mode) {
        return $self->get_persistent_field();
    }

    my $result = $self->query( "R7\r", $tail );
    $result =~ s/R//g;
    return $result;

}

sub set_persistent_mode {
    my $self = shift;

    my ( $mode, $tail ) = $self->_check_args( \@_, ['mode'] );

    return 0 if not $self->{device_settings}->{has_switchheater};

    my $switch = $self->get_switchheater();

    #print "We are in mode $current_mode \n";

    if ( $mode == 1 ) {

        $self->hold();
        $self->set_switchheater(0);

        $self->tozero();

        #$current_mode = 1;

    }
    elsif ( $mode == 0 and $switch == 2 ) {

        my $setpoint = $self->get_persistent_field();

        $self->set_targetfield($setpoint);

        $self->tosetpoint();

        #print "Try to start switchheater...\n";
        $self->set_switchheater(1);

        #print "Switchheater has status ".$self->get_switchheater();

    }
    elsif ( $mode == 0 and $switch == 0 ) {
        print "Zero magnetic field. Switch on switchheater.\n";
        $self->set_switchheater(1);

    }

}

sub get_persistent_mode {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    return 0 if not $self->{device_settings}->{has_switchheater};

    my $sh = $self->get_switchheater();
    my $field = $self->get_field( { read_mode => 'cache' } );

    # Are we really in persistent mode?

    if ( $field == 0 && $sh == 2 ) {
        return 1;
    }
    else {
        return 0;
    }

}

sub get_persistent_field {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    # Are we really in persistent mode?

    return $self->get_parameter(18);

}

sub wait {    # basic

    # waits during magnet is sweeping
    my $self = shift;

    my $flag = 1;
    local $| = 1;

    while (1) {

        my $current_field = $self->get_field();
        if ( $flag <= 1.1 and $flag >= 0.9 ) {
            print "\t\t\t\t\t\t\t\t\t\r";
            print $self->get_id() . " is sweeping ($current_field )\r";
            usleep(5e5);
        }
        elsif ( $flag <= 0 ) {
            print "\t\t\t\t\t\t\t\t\t\r";
            print $self->get_id() . " is          ($current_field ) \r";
            $flag = 2;
        }
        $flag -= 0.5;
        if ( not $self->active() ) {
            print "\t\t\t\t\t\t\t\t\t\r";
            $| = 0;
            last;
        }
    }
    return 0;

}

sub active {    # basic
     # returns a value > 0 if MAGNET is SWEEPING. Else MAGNET is not sweeping.
    my $self = shift;

    $self->_check_magnet();

    my $status = $self->query("X\r");

    #print "status is $status\n";
    my $sweepstatus
        = substr( $status, 11, 1 );   # MAGNET is SWEEPING if $sweepstatus > 0

    if ( !$sweepstatus and ( @{ $self->{SWEEP_QUEUE} }[1] ) ) {
        shift( @{ $self->{SWEEP_QUEUE} } );
        $self->trg();
        $sweepstatus = 1;
    }
    elsif ( !$sweepstatus ) {
        $self->query("A0\r")
            ;    #Set Magnet-status to hold when no more sweeps in queue.
    }

    #print "Sweepstatus is $sweepstatus\n";
    return $sweepstatus;

}

sub _check_limits {    # for internal use only
    my $self          = shift;
    my $current_field = shift;
    my $target_field  = shift;
    my $rate          = shift;

    #print "CF=$current_field\n TF = $target_field\n RATE = $rate\n";

    # check field limits:
    if (   not defined $target_field
        or abs($target_field) > $self->{LIMITS}{'magneticfield'}
        or not $target_field =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ ) {
        return
            "unexpected value for FIELD in sub ips_set_target_field. Expected values are between -/+ $self->{LIMITS}->{'magneticfield'} (Tesla)";
    }

    # check limits for sweeprate
    my $max_rate;
    my $check_field;
    if ( abs($target_field) > abs($current_field) ) {
        $check_field = abs($target_field);
    }
    else { $check_field = abs($current_field); }

    my @len = @{ $self->{LIMITS}->{'field_intervall_limits'} };
    my $len = @len;
    $max_rate = 0;
    for ( my $i = $len; $i < 0; $i-- ) {
        if ( $check_field > $self->{LIMITS}->{'field_intervall_limits'}[$i] )
        {
            print "maxrate = $i\n";
            $max_rate = $i;
        }
    }

    if (   not defined $rate
        or $rate < 0
        or $rate > $self->{LIMITS}->{'rate_intervall_limits'}[$max_rate]
        or not $rate =~ /\b\d+(e\d+|E\d+|exp\d+|EXP\d+)?\b/ ) {
        return
            "unexpected value for RATE ($rate) in sub config_sweep. Look up individual limits for the sweeping rates for different fieldranges.";
    }

    return 0;

}

sub _calculate_trace {

}

sub _check_magnet {    # for internal use only
    my $self = shift;

    # get current field
    my $current_field = $self->get_field();

    if ( @{ $self->{SWEEP_QUEUE} }[0] != 0 ) {
        my $sweepdirection
            = ( $current_field >= @{ $self->{SWEEP_QUEUE}[0][0] }[-1] )
            ? -1
            : 1;

        if ( ( @{ $self->{SWEEP_QUEUE}[0][0] }[0] - $current_field )
            * $sweepdirection < 0 ) {
            shift( @{ $self->{SWEEP_QUEUE}[0][1] } );
            shift( @{ $self->{SWEEP_QUEUE}[0][0] } );

            $self->set_rate( @{ $self->{SWEEP_QUEUE}[0][1] }[0] );
            print $self->{ID}
                . ":  Changed rate to "
                . ( @{ $self->{SWEEP_QUEUE}[0][1] }[0] )
                . " T/min at "
                . $current_field . " T\n";
        }
    }

}

sub trg {    # basic
             # start configurated sweep
    my $self = shift;
    if ( @{ $self->{SWEEP_QUEUE} }[0] == 0 ) {
        print "\nIPS: Sweep is not configured. Can't start sweeping.\n";
    }
    else {
        $self->set_targetfield( @{ $self->{SWEEP_QUEUE}[0][0] }[-1] );
        $self->set_rate( @{ $self->{SWEEP_QUEUE}[0][1] }[0] );

        $self->query("A1\r");    # go to setpoint
        my $current_field = $self->get_field();
        print $self->{ID}
            . ":  New target-field set "
            . ( @{ $self->{SWEEP_QUEUE}[0][0] }[-1] )
            . " with rate "
            . ( @{ $self->{SWEEP_QUEUE}[0][1] }[0] )
            . "T/min at "
            . $current_field . " T\n";

    }

}

sub abort {    # basic
               # stop sweep
    my $self = shift;
    $self->query("A0\r");
    $self->{SWEEP_CONFIG_ARMED} = 0;
}

sub _prepare_sweep_sequence {
    my $self         = shift;
    my $sweep_points = shift;
    my $sweep_rates  = shift;

    if ( ref($sweep_points) eq "HASH" ) {
        my $parameters = $sweep_points;
        $sweep_points = $parameters->{points};
        $sweep_rates  = $parameters->{rates};
    }

    my @sweep_points = @$sweep_points;
    my @sweep_rates  = @$sweep_rates;

    print "prepare_sweep_sequence\n";
    my $j   = 0;
    my $len = @sweep_points;
    if ( $len > 2 ) {
        @{ $self->{SWEEP_QUEUE} }[$j] = ( [], [] );
        for ( my $i = 1; $i < $len - 1; $i++ ) {

            my $sign_1
                = ( ( @sweep_points[$i] - @sweep_points[ $i - 1 ] ) >= 0 )
                ? -1
                : 1;
            my $sign_2
                = ( ( @sweep_points[ $i + 1 ] - @sweep_points[$i] ) >= 0 )
                ? -1
                : 1;
            if ( $sign_1 == $sign_2 ) {
                push( @{ $self->{SWEEP_QUEUE}[$j][0] }, @sweep_points[$i] );
                push(
                    @{ $self->{SWEEP_QUEUE}[$j][1] },
                    @sweep_rates[ $i - 1 ]
                );
            }
            else {
                push( @{ $self->{SWEEP_QUEUE}[$j][0] }, @sweep_points[$i] );
                push(
                    @{ $self->{SWEEP_QUEUE}[$j][1] },
                    @sweep_rates[ $i - 1 ]
                );
                $j++;
                @{ $self->{SWEEP_QUEUE} }[$j] = ( [], [] );
            }
        }

        # take care of the last sweep_point ...
        push( @{ $self->{SWEEP_QUEUE}[$j][0] }, @sweep_points[-1] );
        push( @{ $self->{SWEEP_QUEUE}[$j][1] }, @sweep_rates[-1] );

    }
    else {
        shift(@sweep_points);
        @{ $self->{SWEEP_QUEUE}[0][0] } = @sweep_points;
        @{ $self->{SWEEP_QUEUE}[0][1] } = @sweep_rates;
    }

    $len = @{ $self->{SWEEP_QUEUE} };
    for ( my $i = 0; $i < $len; $i++ ) {
        print("Sequence Sweep $i: \n");
        print("SP:\t");

        foreach my $item ( @{ $self->{SWEEP_QUEUE}[$i][0] } ) {
            print $item. "\t";
        }
        print("\n");
        print("SR:\t");

        foreach my $item ( @{ $self->{SWEEP_QUEUE}[$i][1] } ) {
            print $item. "\t";
        }
        print("\n");
    }

}

sub config_sweep {    # basic
    my $self = shift;

    my ( $field, $rate, $interval )
        = $self->_check_args( \@_, [ 'points', 'rates', 'interval' ] );

    my @sweep_points;
    my @sweep_rates;

    print "$self->{ID}: config_sweep\n";

    if ( not defined $interval ) {
        $interval = 1;
    }

    if ( not defined $rate ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "too view parameters given in sub config_sweep. Expected parameters are FIELD, RATE, <INTERVAL>."
        );
    }

    if ( ref($field) eq "ARRAY" ) {

        @sweep_points = @$field;

        if ( ref($rate) eq "ARRAY" ) {
            @sweep_rates = @$rate;
        }
    }

    # split and check $field and $rate
    else {
        @sweep_points = split( ',', $field );
        @sweep_rates  = split( ',', $rate );
    }

    # rounding of the received values.
    my $len = @sweep_points;
    for ( my $i; $i < $len; $i++ ) {
        @sweep_points[$i] = sprintf( "%.5f", @sweep_points[$i] );
        @sweep_rates[$i]  = sprintf( "%.5f", @sweep_rates[$i] );
        if ( @sweep_rates[$i] == 0 ) {
            @sweep_rates[$i] = 0.01;
        }
    }

    if ( ( my $i = @sweep_points ) != ( my $j = @sweep_rates ) ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Sweep-points-list and Sweep-rates-list must have the same length!.\n"
        );
    }

    # get current field
    my $current_field = $self->get_field();
    unshift( @sweep_points, $current_field );

    # check sequence
    my $sequences = @sweep_rates;
    for my $i ( 0 .. $sequences - 1 ) {
        if (
            my $status = $self->_check_limits(
                @sweep_points[$i], @sweep_points[ $i + 1 ],
                @sweep_rates[$i]
            )
            ) {
            Lab::Exception::CorruptParameter->throw( error => $status );
        }
    }

    $self->_prepare_sweep_sequence( \@sweep_points, \@sweep_rates );

    # calculate trace
    my @trace;
    foreach my $item ( @{ $self->{SWEEP_QUEUE} } ) {
        my @item           = @$item;
        my @points         = @{ $item[0] };
        my @rates          = @{ $item[1] };
        my $sweepdirection = ( $points[-1] - $current_field ) >= 0 ? 1 : -1;
        my $len_points     = @points;
        while ($len_points) {
            for (
                $current_field;
                ( $points[0] - $current_field ) * $sweepdirection > 0;
                $current_field
                += ( $rates[0] / 60 ) * $interval * $sweepdirection
                ) {
                push( @trace, $current_field );
            }
            $current_field -= $rates[0] * 60 * $interval * $sweepdirection;
            shift(@points);
            shift(@rates);
            $len_points = @points;
        }
    }
    if ( ( my $len_trace = @trace ) == 0 ) {
        push( @trace, $current_field );
    }

    return @trace;

}

sub sweep_to_field {
    my $self = shift;

    my ( $target, $rate ) = $self->_check_args( \@_, [ 'target', 'rate' ] );

    my $current_field = $self->get_value();

    my $current_field_interval = 0;
    my $target_field_interval  = 0;

    my @targets;
    my @rates;

    if ( abs($target) > $self->{LIMITS}->{magneticfield} ) {
        croak("Target-Field exceeds maximum field value! \n");
    }
    if ( not defined $rate ) {
        $rate = @{ $self->{LIMITS}->{rate_intervall_limits} }[0];
    }
    my $sweep_direction = ( $current_field < $target ) ? 1 : -1;

    foreach
        my $field_limit ( @{ $self->{LIMITS}->{field_intervall_limits} } ) {
        if ( abs($current_field) > $field_limit and $field_limit != 0 ) {
            $current_field_interval++;
        }
        if ( abs($target) > $field_limit and $field_limit != 0 ) {
            $target_field_interval++;
        }
    }

    $current_field_interval
        = ( $current_field < 0 )
        ? $current_field_interval * (-1)
        : $current_field_interval;
    $target_field_interval
        = ( $target < 0 )
        ? $target_field_interval * (-1)
        : $target_field_interval;

    # add interval limits:
    my $interval = $current_field_interval;

    while (1) {
        my $vergleichswert
            = ( ( $interval >= 0 ) ? 1 : -1 )
            * @{ $self->{LIMITS}->{field_intervall_limits} }[
            ( $interval * $sweep_direction >= 0 )
            ? abs($interval) + 1
            : abs($interval)
            ];
        if ( $interval == 0 ) {
            $vergleichswert *= $sweep_direction;
        }

        my $index = abs($interval);

        if (
            $target * $sweep_direction <= $vergleichswert * $sweep_direction
            or (
                abs($interval)
                >= @{ $self->{LIMITS}->{field_intervall_limits} } - 1
                and $interval != $current_field_interval )
            ) {
            push( @targets, $target );

            if ( $rate > @{ $self->{LIMITS}->{rate_intervall_limits} }[$index]
                or not defined $rate ) {
                push(
                    @rates,
                    @{ $self->{LIMITS}->{rate_intervall_limits} }[$index]
                );
            }
            else {
                push( @rates, $rate );
            }

            last;

        }

        if ( $vergleichswert != $current_field ) {
            push( @targets, $vergleichswert );
            if ( $rate > @{ $self->{LIMITS}->{rate_intervall_limits} }
                [ abs($interval) ]
                or not defined $rate ) {
                push(
                    @rates,
                    @{ $self->{LIMITS}->{rate_intervall_limits} }
                        [ abs($interval) ]
                );
            }
            else {
                push( @rates, $rate );
            }
        }

        $interval += $sweep_direction;
    }

    $self->config_sweep( \@targets, \@rates );
    $self->trg();
    $self->wait();

}

sub sweep_to_level {

    my $self = shift;
    return $self->sweep_to_field(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::IPS - Oxford Instruments IPS Magnet Power Supply

=head1 VERSION

version 3.881

=head1 SYNOPSIS

	use Lab::Instrument::IPS;
	my $ips=new Lab::Instrument::IPS($isobus,2);
	print $ips->get_field();

.

=head1 DESCRIPTION

The Lab::Instrument::IPS class implements an interface to the Oxford Instruments 
IPS magnet power supply.

.

=head1 CONSTRUCTOR

	my $ips=new Lab::Instrument::IPS($isobus,$addr);

Instantiates a new IPS object, for example attached to the IsoBus device 
(of type  Lab::Instrument::IsoBus )  $IsoBus , with IsoBus address  $addr . 
All constructor forms of  Lab::Instrument  are available.

.

=head1 METHODS

=head2 get_field

	$field=$ips->get_field();

reads out the current applied magnetic field.

.

=head2 config_sweep

	@sweep = $ips->config_sweep($targetfield, $rate, <$interval>)

Predefine the target value, the sweeprate and optional the measurement interval for a magnetic field sweep.
Returns the calculated sweep TRACE in steps of $rate*$interval as an array.

=over 4

=item $targetfield

 TARGETFIELD  is the target magnetic tield value to sweep to. It must be within the magnet's limits.

=item $rate

 RATE  is the sweep rate in  TESLA per MINUTE . It must be within the magnet's limits.

=item $interval

 INTERVAL  defines the planed measurement interval in seconds. This parameter is necessary to calculate the  TRACE  correctly.
Default is 1 second.

=item ADVANCED SWEEP

$targetfield and $rate can also be a series of values to define a multiple step sweep.
Note: The multiple step sweep cannot reverse sweeping direction.

Example:
starting at 0 tesla: $targetfield = "1.0, 1.5, 3" and $rate = "0.1, 0.5, 1"

	--> this defines a sweep from 0T --> 3T with sweeprates of 
		0.1T/m for 0T->1T,
		0.5T/m for 1T->1.5T and 
		1T/m for 1.5T->3T.

Important: This kinde of 'advanced' sweep works only in combination with the subroutines wait() or active().

	--> wait() will simply wait until the sweep has been finished. 
	--> active() can be used as the condition-parameter within a 'while-loop'.

Example:

	$ips->config_sweep("1.0, 1.5, 3", "0.1, 0.5, 1"); # define an advanced sweep
	$ips->trg(); # start sweep
	while($ips->active())
		{
		# do something while the sweep is running
		}

=back

.

=head2 trg

	$ips->trg();

starts a configured sweep.

.

=head2 abort

	$ips->abort();

aborts the current sweep.

.

=head2 wait

	$ips->wait(<$seconds>);

Waits ...

=over 4

=item $seconds

SECONDS is an optional paramter. 
Wait until $seconds have been passed or if $seconds is not defined until the current sweep has been finished.

=back

=head2 active

	$ips->active();

Returns a value > 0 if magnet is currently sweeping and '0' if magnet is not sweeping.

=head1 CAVEATS/BUGS

probably many

.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Christian Butschkow, Stefan Geissler
            2013       Alois Dirnaichner, Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2014-2015  Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
