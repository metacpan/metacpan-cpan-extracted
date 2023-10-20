package Lab::Instrument::TemperatureControl::TLK43;
#ABSTRACT: Electronic process controller TLKA41/42/43 (SIKA GmbH) with RS485 MODBUS-RTU interface
$Lab::Instrument::TemperatureControl::TLK43::VERSION = '3.899';
use v5.20;

use strict;
use Lab::Instrument;
use Lab::Bus::MODBUS_RS232;
use feature "switch";
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => ['MODBUS_RS232'],
    slave_address         => undef,
    connection            => undef,

    MemTable => {
        Measurement      => 0x0200,    # measured value
        Decimal          => 0x0201,    # decimal points dP
        CalculatedPower  => 0x0202,    # calculated power
        HeatingPower     => 0x0203,    # available heating power
        CoolingPower     => 0x0204,    # available cooling power
        State_Alarm1     => 0x0205,    # state of alarm 1
        State_Alarm2     => 0x0206,    # state of alarm 2
        State_Alarm3     => 0x0207,    # state of alarm 3
        Setpoint         => 0x0208,    # current setpoint
        State_AlarmLBA   => 0x020A,    # state of alarm LBA
        State_AlarmHB    => 0x020B,    # state of alarm HB (heater break)
        CurrentHB_closed => 0x020C,    # current for HB with closed circuit
        CurrentHB_open   => 0x020D,    # current for HB with open circuit
        State_Controller => 0x020F
        , # state of controller (0: Off, 1: auto. Reg., 2: Tuning, 3: man. Reg.
        PreliminaryTarget => 0x0290,    # preliminary target value (TLK43)
        AnalogueRepeat => 0x02A0, # value to repeat on analogue output (TLK43)

        # SP group (parameters relative to setpoint)
        nSP  => 0x2800,           # number of programmable setpoints
        SPAt => 0x2801,           # selects active setpoint
        SP1  => 0x2802,           # setpoint 1
        SP2  => 0x2803,           # setpoint 2
        SP3  => 0x2804,           # setpoint 3
        SP4  => 0x2805,           # setpoint 4
        SPLL => 0x2806,           # low setpoint limit
        SPHL => 0x2807,           # high setpoint limit

        # InP group (parameters relative to the measure input)
        HCFG => 0x2808,    # type of input with universal input configuration
        SEnS => 0x2809,    # type of sensor (depends on HCFG)
        rEFL => 0x2857,    # coefficient of reflection
        SSC  => 0x280A,    # start of scale
        FSC  => 0x280B,    # full scale deflection
        dP   => 0x280C,    # decimal points (for measurement)
        Unit => 0x280D,    # 0=°C, 1=F
        FiL  => 0x280E,    # digital filter on input (OFF .. 20.0 sec)
        OFSt => 0x2810
        ,    # offset of measurement with dP decimal points (-1999..9999) ?
        rot => 0x2811,    # rotation of the measuring straight line
        InE => 0x2812
        ,   # "OPE" functioning in case of measuring error (0=OR, 1=Ur, 2=OUr)
        OPE => 0x2813,   # output power in case of measuring error (-100..100)
        dIF => 0x2858,   # digital input function

        # O1 group (parameteres relative to output 1)
        O1F => 0x2814
        ,  # functioning of output 1 (0=OFF, 1=1.rEg, 2=2.rEg, 3=Alno, 4=ALnc)
        Aor1 => 0x2859,   # Beginning of analogue output 1 scale (0=0, 1=no_0)
        Ao1F => 0x285A
        , # functioning of analogue output 1 (0=OFF, 1=inp, 2=err, 3=r.SP, 4=r.SEr)
        Ao1L => 0x285B
        , # Minimum reference for analogical output 1 for signal transmission (with dP, -1999..9999)
        A01H => 0x285C
        , # Maximum reference for analogical output 1 for signal transmission (with dP, A01L..9999)

        # O2 group (parameteres relative to output 2)
        O2F => 0x2815
        ,  # functioning of output 2 (0=OFF, 1=1.rEg, 2=2.rEg, 3=Alno, 4=ALnc)
        Aor2 => 0x285D,   # Beginning of analogue output 2 scale (0=0, 1=no_0)
        Ao2F => 0x285E
        , # functioning of analogue output 2 (0=OFF, 1=inp, 2=err, 3=r.SP, 4=r.SEr)
        Ao2L => 0x285F
        , # Minimum reference for analogical output 2 for signal transmission (with dP, -1999..9999)
        A02H => 0x2860
        , # Maximum reference for analogical output 2 for signal transmission (with dP, A02L..9999)

        # O3 group (parameteres relative to output 3)
        O3F => 0x2816
        ,  # functioning of output 3 (0=OFF, 1=1.rEg, 2=2.rEg, 3=Alno, 4=ALnc)
        Aor3 => 0x2861,   # Beginning of analogue output 3 scale (0=0, 1=no_0)
        Ao3F => 0x2862
        , # functioning of analogue output 3 (0=OFF, 1=inp, 2=err, 3=r.SP, 4=r.SEr)
        Ao3L => 0x2863
        , # Minimum reference for analogical output 3 for signal transmission (with dP, -1999..9999)
        A03H => 0x2864
        , # Maximum reference for analogical output 3 for signal transmission (with dP, A03L..9999)

        # O4 group (parameters relative to output 4)
        O4F => 0x2817
        ,  # functioning of output 4 (0=OFF, 1=1.rEg, 2=2.rEg, 3=Alno, 4=ALnc)

        # Al1 group (parameteres relative to alarm 1
        OAL1 => 0x2818
        , # Output where alarm AL1 is addressed (0=OFF, 1=Out1, 2=Out2, 3=Out3, 4=Out4)
        AL1t => 0x2819
        ,    # Alarm AL1 type (0=LoAb, 1=HiAb, 2=LHAb, 3=LodE, 4=HidE, 5=LHdE)
        Ab1 => 0x281A
        , # Alarm AL1 functioning (0=no function, 1=alarm hidden at startup, 2=alarm delayed, 4=alarm stored, 8=alarm acknowledged
        AL1  => 0x281B,    # Alarm AL1 threshold (with dP, -1999..9999)
        AL1L => 0x281C
        , # Low threshold band alarm AL1 or Minimum set alarm AL1 for high or low alarm (with dP, -1999..9999)
        AL1H => 0x281D
        , # High threshold band alarm AL1 or Maximum set alarm AL1 for high or low alarm (with dP, -1999..9999)
        HAL1 => 0x281E,    # Alarm AL1 hysteresis (with dP, 0=OFF..9999)
        AL1d =>
            0x281F,  # Activation delay of alarm AL1 (with dP, 9=OFF..9999sec)
        AL1i => 0x2820
        ,    # Alarm AL1 activation in case of measuring error (0=no, 1=yes)

        # rEG group (parameters relative to controller
        Cont => 0x283B,  # Control type (0=PID, 1=On.Fa, 2=On.FS, 3=nr, 4=3Pt)
        Func => 0x283C,  # functioning mode output 1rEg (0=Heat, 1=Cool)
        Auto => 0x283D,  # Autotuning Fast enable
        SELF => 0x283E,  # Selftuning enable (0=No, 1=Yes)
        HSEt => 0x283F,  # Hysteresis of ON/OFF Control (9999 ... -1999)
        Pb   => 0x2840,  # Proportional band (0...9999)
        Int  => 0x2841,  # Integral time (0=OFF...9999sec)
        dEr  => 0x2842,  # Derivative time (0=OFF...9999sec)
        FuOc => 0x2843,  # Fuzzy overshoot control (0.00...2.00)
        tcr1 => 0x2833,  # Cycle time of output 1rEg (0.1...130sec)
        Prat => 0x2845,  # Power ration 2rEg/1rEg (0.1...999.9)
        tcr2 => 0x2846,  # Cycle time of 2rEg (0.1...130sec)
        rS   => 0x2847,  # Manual reset (-100%...100%)
        tcor => 0x2866,  # Time for motorised actuator run (4...1000sec)
        SHrl =>
            0x2867, # Minimum value for motorised actuator control (0.1...10%)
        PoSI => 0x2868
        ,  # Switch on position for motorised actuator (0=No, 1=close, 2=open)
        SLor => 0x2849,    # Gradient of rise ramp (0.00...99.99)
        durt => 0x284A,    # Duration time
        SLoF => 0x284B,    # Gradient of fall ramp
        ro1L => 0x2869,    # Minimum power in ouput from 1rEG (0...100%)
        ro1H => 0x286A,    # Maximum power ... (ro1L...100%)
        ro2L => 0x286B,    # Minimum power in output from 2rEG (0...100%)
        ro2H => 0x286C,    # Maximum power... (ro2L...100%)
        tHr1 => 0x286D,    # Split Range Power threshold of output 1rEG
        tHr2 => 0x286E,    # ... of output 2rEG
        OPS1 =>
            0x286F,  # Power variation speed in output from 1rEG (0...50%/sec)
        OPS2 => 0x2870,    # ... from 2rEG
        StP  => 0x284C,    # Soft-start power (-100, -101=OFF, 100)
        SSt  => 0x284D,    # Soft-start time (0=OFF...7.59 h.min)

        # to be continued

    },

    MemCache =>
        { # used by read_int_cached and write_int_cached to cache 16bit values
        },
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);    # sets $self->config
    $self->_construct( __PACKAGE__, \%fields )
        ;    # this sets up all the object fields out of the inheritance tree.
             # also, it does generic connection setup.

    return $self;
}

sub read_temperature {
    my $self   = shift;
    my @Result = ();
    my $Temp   = undef;
    my $dP     = 0;

    #return undef unless defined($dP = $self->read_int_cached({ mem_address => 'dP' }));
    if ( !defined( $dP = $self->read_int_cached( { mem_address => 'dP' } ) ) )
    {
        print "Error in cached read of dP\n";
        return undef;
    }

    return undef
        unless defined( $Temp
            = $self->read_address_int( $self->MemTable()->{'Measurement'} ) );

    $Temp == 10001
        ? warn(
        "Warning: Measurement exception $Temp received. Sensor disconnected.\n"
        )
        : $Temp == 10000 ? warn(
        "Warning: Measurement exception $Temp received. Measuring value underrange.\n"
        )
        : $Temp == -10000 ? warn(
        "Warning: Measurement exception $Temp received. Measuring value overrange.\n"
        )
        : $Temp == 10003 ? warn(
        "Warning: Measurement exception $Temp received. Measured variable not available.\n"
        )
        : return $Temp / 10**$dP;

    return undef;
}

sub read_int_cached {    # { mem_address => $mem_address, ForceRead => (1,0) }
    my $self        = shift;
    my $args        = shift;
    my $mem_address = $args->{'mem_address'} || undef;
    my $ForceRead   = $args->{'ForceRead'};
    if ( $mem_address !~ /^[0-9]*$/ ) {
        $mem_address = $self->MemTable()->{$mem_address} || undef;
    }

    if (   !$ForceRead
        && exists( $self->MemCache()->{$mem_address} )
        && defined( $self->MemCache()->{$mem_address} ) ) {
        return $self->MemCache()->{$mem_address};
    }
    else {
        return undef
            unless defined( $self->MemCache()->{$mem_address}
                = $self->read_address_int($mem_address) );
        return $self->MemCache()->{$mem_address};
    }
}

sub write_int_cached
{ # { mem_address => $mem_address, mem_value => $Value }  stores mem_value as number (int)
    my $self        = shift;
    my $args        = shift;
    my $mem_address = $args->{mem_address} || undef;
    my $mem_value   = int( $args->{mem_value} ) || undef;
    if ( $mem_address !~ /^[0-9]*$/ ) {
        $mem_address = $self->MemTable()->{$mem_address} || undef;
    }

    return undef
        unless $self->write_address(
        { mem_address => $mem_address, mem_value => $mem_value } );
    return ( ( $self->MemCache()->{$mem_address} = $mem_value ) );
}

sub set_setpoint {    # { Slot => (1..4), Value => Int }
    my $self       = shift;
    my $args       = shift;
    my $TargetTemp = $args->{'Value'};
    my $Slot       = $args->{'Slot'};
    my $nSP        = 1;
    my $dP         = 0;

    return undef unless defined( $nSP = $self->read_int_cached('nSP') );
    return undef unless defined( $dP  = $self->read_int_cached('dP') );

    if ( $Slot > $nSP || $Slot < 1 ) {
        return undef;
    }
    else {
        $TargetTemp = sprintf( "%.${dP}f", $TargetTemp )
            * 10**$dP;    # rounding, shifting decimal places
        return undef
            if ( $TargetTemp > 32767 || $TargetTemp < -32768 )
            ;    # still fitting in a signed 16bit int?
                 #$TargetTemp = ( $TargetTemp + 2**16  ) if $TargetTemp < 0;
        return $self->write_address(
            {
                mem_address => $self->MemTable()->{'Setpoint'} + $Slot - 1,
                mem_value   => $TargetTemp
            }
        );
    }
}

sub set_active_setpoint {    # $value
    my $self       = shift;
    my $TargetTemp = shift;
    my $Slot       = 1;
    my $dP         = 0;
    return undef
        unless defined( $Slot
            = $self->read_int_cached( { mem_address => 'SPAt' } ) );
    return undef
        unless
        defined( $dP = $self->read_int_cached( { mem_address => 'dP' } ) );

    $TargetTemp = sprintf( "%.${dP}f", $TargetTemp )
        * 10**$dP;    # rounding, shifting decimal places
    return undef
        if ( $TargetTemp > 32767 || $TargetTemp < -32768 )
        ;    # still fitting in a signed 16bit int?
             #$TargetTemp = ( $TargetTemp + 2**16  ) if $TargetTemp < 0;
    return $self->write_address(
        {
            mem_address => $self->MemTable()->{'SP1'} + $Slot - 1,
            mem_value   => $TargetTemp
        }
    );
}

sub set_setpoint_slot {    # { Slot => (1..4) }
    my $self = shift;
    my $args = shift;
    my $Slot = int( $args->{'Slot'} ) || return undef;
    my $nSP  = undef;
    return undef unless defined( $nSP = $self->read_int_cached('nSP') );

    if ( $Slot > $nSP || $Slot < 1 ) {
        return undef;
    }
    else {
        return $self->write_address(
            {
                mem_address => $self->MemTable()->{'SPAt'},
                mem_value   => $Slot
            }
        );
    }
}

sub set_Precision {    # $Precision
    my $self      = shift;
    my $precision = int(shift);

    return undef if ( $precision < 0 || $precision > 3 );
    return $self->write_address(
        { mem_address => $self->MemTable()->{'sP'}, mem_value => $precision }
    );
}

sub set_speed
{ # set speed of temperature increase and decrease, in deg/minute. set "off" to disable (infinite speed)
    my $self  = shift;
    my $speed = shift;

    $speed = 100 if ( $speed =~ /off/i );
    $speed = sprintf( "%.2f", $speed )
        * 100;    # 2 decimal places hardwired, transferred as int

    $self->write_address(
        { mem_address => $self->MemTable()->{'SLoF'}, mem_value => $speed } );
    $self->write_address(
        { mem_address => $self->MemTable()->{'SLor'}, mem_value => $speed } );
    return 1;
}

sub set_speed_rising
{ # set speed of temperature increase, in deg/minute. set "off" to disable (infinite speed)
    my $self  = shift;
    my $speed = shift;

    $speed = 100 if ( $speed =~ /off/i );
    $speed = sprintf( "%.2f", $speed )
        * 100;    # 2 decimal places hardwired, transferred as int

    return $self->write_address(
        { mem_address => $self->MemTable()->{'SLor'}, mem_value => $speed } );
}

sub set_speed_falling
{ # set speed of temperature decrease, in deg/minute. set "off" to disable (infinite speed)
    my $self  = shift;
    my $speed = shift;

    $speed = 100 if ( $speed =~ /off/i );
    $speed = sprintf( "%.2f", $speed )
        * 100;    # 2 decimal places hardwired, transferred as int

    return $self->write_address(
        { mem_address => $self->MemTable()->{'SLoF'}, mem_value => $speed } );
}

sub read_range
{ # { mem_address => Address (16bit), MemCount => Count (8bit, (1..4), default 1)
    my $self        = shift;
    my $args        = shift;
    my $mem_address = $args->{mem_address} || undef;
    my $MemCount    = $args->{MemCount} || 1;
    $MemCount = int($MemCount);
    if ( $mem_address !~ /^[0-9]*$/ ) {
        $mem_address = $self->MemTable()->{$mem_address} || undef;
    }

    if (   !$mem_address
        || !$MemCount
        || $mem_address > 0xFFFF
        || $mem_address < 0x0200
        || $MemCount > 4
        || $MemCount <= 0 ) {
        return undef;
    }
    else {
        return $self->connection()->Read(
            function    => 3,
            mem_address => $mem_address,
            MemCount    => $MemCount
        );
    }
}

sub read_address_int {    # $Address
    my $self        = shift;
    my @Result      = ();
    my $SignedValue = 0;
    my $mem_address = shift || undef;
    if ( $mem_address !~ /^[0-9]*$/ ) {
        $mem_address = $self->MemTable()->{$mem_address} || undef;
    }

    if ( !$mem_address || $mem_address > 0xFFFF || $mem_address < 0x0200 ) {
        print "Address invalid\n";
        return undef;
    }
    else {
        @Result = $self->connection()->Read(
            function    => 3,
            mem_address => $mem_address,
            MemCount    => 1
        );
        if ( scalar(@Result) == 2 )
        {    # correct answer has to be two bytes long
            $SignedValue = unpack( 'n!', join( '', @Result ) );
        }
        else {
            warn "Error on bus level\n";
            return undef;
        }
    }
}

sub write_address
{    # { mem_address => Address (16bit), mem_value => Value (16 bit word) }
    my $self        = shift;
    my $args        = shift;
    my $mem_address = $args->{mem_address} || undef;
    my $mem_value   = int( $args->{mem_value} ) || undef;

    if ( $mem_address !~ /^[0-9]*$/ ) {
        $mem_address = $self->MemTable()->{$mem_address} || undef;
    }

    if (   !$mem_address
        || ( !$mem_value && $mem_value != 0 )
        || $mem_address > 0xFFFF
        || $mem_address < 0x0200
        || $mem_value > 0xFFFF
        || $mem_value < 0 ) {
        return undef;
    }
    else {
        return $self->connection()->Write(
            function    => 6,
            mem_address => $mem_address,
            mem_value   => $mem_value
        );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::TemperatureControl::TLK43 - Electronic process controller TLKA41/42/43 (SIKA GmbH) with RS485 MODBUS-RTU interface (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

    use Lab::Instrument::TLK43;
    
    my $tlk=new Lab::Instrument::TLK43({ Port => '/dev/ttyS0', slave_address => 1, Baudrate => 19200, Parity => 'none', Databits => 8, Stopbits => 1, Handshake => 'none'  });

	or

	my $Bus = new Lab::Bus::MODBUS({ Port => '/dev/ttyS0', Interface => 'RS232', slave_address => 1, Baudrate => 19200, Parity => 'none', Databits => 8, Stopbits => 1, Handshake => 'none' });
	my $tlk=new Lab::Instrument::TLK43({ Bus => $Bus });

    print $tlk->read_temperature();
	$tlk->set_setpoint(200);

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

The Lab::Instrument::TLK43 class implements an interface to SIKA GmbH's TLK41/42/43 process controllers. The devices
have to be equipped with the optional RS485 interface. The device can be fully programmed using RS232 and an interface
converter (e.g. "GRS 485 ISO" RS232 - RS485 Converter).

The following parameter list configures the RS232 port correctly for a setup with the GRS485 converter and a speed of 19200 baud:
Port => '/dev/ttyS0', Interface => 'RS232', Baudrate => 19200, Parity => 'none', Databits => 8, Stopbits => 1, Handshake => 'none'

=head1 CONSTRUCTOR

    my $tlk=new(\%options);

=head1 METHODS

=head2 read_temperature

    $temp = read_temperature();

Returns the currently measured temperature, or undef on errors.

=head2 set_setpoint

    $success=$tlk->set_setpoint({ Slot => $Slot, Value => $Value })

Set the value of setpoint slot $Slot.

=over 4

=item $Slot

The TLK controllers provide 4 setpoint slots. $Slot has to be a number of (1..4) and may not
exceed the nSP-parameter set in the device (set_setpoint return undef in this case)

=item $Value

Float value to set the setpoint to. Internally this is held by a 16bit number.
set_setpoint() will cut off the decimal values according to the value of the "dP" parameter of the device.
(dP=0..3 meaning 0..3 decimal points. only 0,1 work for temperature sensors)

=back

=head2 set_active_setpoint

    $success=$tlk->set_active_setpoint($Value);

Set the value of the currently active setpoint slot.

=over 4

=item $Value

Float value to set the setpoint to. Internally this is held by a 16bit number.
set_setpoint() will cut off the decimal values according to the value of the "dP" parameter of the device.
(dP=0..3 meaning 0..3 decimal points. only 0,1 work for temperature sensors)

=back

=head2 read_range

    $value=$tlk->read_range({ mem_addresss => (0x0200..0xFFFF || Name), MemCount => (1..4) })

Read the values of $MemCount memory slots from $mem_address on. The Address may be specified as a 16bit Integer in the valid range,
or as an address name (see TLK43.pm, %fields{'MemTable'}). $MemCount may be in the range 1..4.
Returns the memory as an array (one byte per field)

=head2 read_address_int

    $value=$tlk->read_range({ mem_addresss => (0x0200..0xFFFF || Name), MemCount => (1..4) })

Read the value of the 16bit word at $mem_address on. The Address may be specified as a 16bit Integer in the valid range,
or as an address name (see TLK43.pm, %fields{'MemTable'}).
Returns the value as unsigned integer (internally (byte1 << 8) + byte2)

=head2 write_address

    $success=$tlk->write_address({ mem_address => (0x0200...0xFFFF || Name), mem_value => Value (16 bit word) });

Write $Value to the given address. The Address may be specified as a 16bit Integer in the valid range,
or as an address name (see TLK43.pm, %fields{'MemTable'}).

=head2 set_setpoint_slot

    $success=$tlk->set_setpoint_slot({ Slot => $Slot })

Set the active setpoint to slot no. $Slot.

=over 4

=item $Slot

The TLK controllers provide 4 setpoint slots. $Slot has to be a number of (1..4) and may not
exceed the nSP-parameter set in the device (set_setpoint_slot return undef in this case)

=back

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
