package Lab::Instrument::HP3458A;
#ABSTRACT: Agilent 3458A Multimeter
$Lab::Instrument::HP3458A::VERSION = '3.881';
use v5.20;

use strict;
use Lab::Instrument;
use Lab::Instrument::Multimeter;
use Time::HiRes qw (usleep sleep);

our @ISA = ("Lab::Instrument::Multimeter");

our %fields = (
    supported_connections => ['GPIB'],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
    },

    device_settings => {
        pl_freq => 50,
    },

    device_cache => {
        autozero => undef,
    },

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

    #$self->connection()->SetTermChar("\r\n");
    #$self->connection()->EnableTermChar(1);
    #print "hallo\n";
    $self->write( "END 2", error_check => 1 )
        ; # or ERRSTR? and other queries will time out, unless using a line/message end character
    $self->write( 'TARM AUTO',    error_check => 1 );    # keep measuring
    $self->write( 'TRIG AUTO',    error_check => 1 );    # keep measuring
    $self->write( 'NRDGS 1,AUTO', error_check => 1 );    # keep measuring
}

#
# utility methods
#

sub configure_voltage_dc {
    my $self = shift;

    my ( $range, $tint ) = $self->_check_args( \@_, [ 'range', 'tint' ] );

    my $range_cmd = "FUNC DCV ";

    if ( $range eq 'AUTO' || !defined($range) ) {
        $range_cmd = 'ARANGE ON';
    }
    elsif ( $range =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ) {
        $range_cmd = sprintf( "FUNC DCV %e", abs($range) );
    }
    elsif ( $range !~ /^(MIN|MAX)$/ ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Range has to be set to a decimal value or 'AUTO', 'MIN' or 'MAX' in "
                . ( caller(0) )[3]
                . "\n" );
    }

    if ( !defined($tint) || $tint eq 'DEFAULT' ) {
        $tint = 10;
    }
    elsif ( $tint =~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/
        && ( ( $tint >= 0 && $tint <= 1000 ) || $tint == -1 ) ) {

        # Convert seconds to PLC (power line cycles)
        $tint *= $self->pl_freq();
    }
    elsif ( $tint =~ /^MIN$/ ) {
        $tint = 0;
    }
    elsif ( $tint =~ /^MAX$/ ) {
        $tint = 1000;
    }
    elsif ( $tint !~ /^(MIN|MAX)$/ ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Integration time has to be set to a positive value or 'AUTO', 'MIN' or 'MAX' in "
                . ( caller(0) )[3]
                . "\n" );
    }

    # do it
    $self->write( $range_cmd,     error_check => 1 );
    $self->write( "NPLC ${tint}", error_check => 1 );

    #$self->write( "NPLC ${tint}", { error_check=>1 });
}

sub configure_voltage_dc_trigger {
    my $self = shift;

    my ( $range, $tint, $count, $delay )
        = $self->_check_args( \@_, [ 'range', 'tint', 'count', 'delay' ] );

    $count = 1 if !defined($count);
    Lab::Exception::CorruptParameter->throw(
        error => "Sample count has to be an integer between 1 and 512\n" )
        if ( $count !~ /^[0-9]*$/ || $count < 1 || $count > 16777215 );

    $delay = 0 if !defined($delay);
    Lab::Exception::CorruptParameter->throw(
        error => "Trigger delay has to be a positive decimal value\n" )
        if ( $count !~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ );

    $self->configure_voltage_dc( $range, $tint );

    #$self->write( "PRESET NORM" );
    if ( $count > 1 ) {
        $self->write( "INBUF ON", error_check => 1 );
    }
    else {
        $self->write( "INBUF OFF", error_check => 1 );
    }
    $self->write( "TARM AUTO",          error_check => 1 );
    $self->write( "TRIG HOLD",          error_check => 1 );
    $self->write( "NRDGS $count, AUTO", error_check => 1 );
    $self->write( "TIMER $delay",       error_check => 1 );

    #$self->write( "TRIG:DELay:AUTO OFF");
}

sub configure_voltage_dc_trigger_highspeed {
    my $self  = shift;
    my $range = shift || 10;    # in V, or "AUTO", "MIN", "MAX"
    my $tint  = shift
        || 1.4e-6
        ; # integration time in sec, "DEFAULT", "MIN", "MAX". Default of 1.4e-6 is the highest possible value for 100kHz sampling.
    my $count = shift || 10000;
    my $delay = shift;    # in seconds, 'MIN'

    if ( $range eq 'AUTO' || !defined($range) ) {
        $range = 'AUTO';
    }
    elsif ( $range =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ) {

        #$range = sprintf("%e",abs($range));
    }
    elsif ( $range !~ /^(MIN|MAX)$/ ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Range has to be set to a decimal value or 'AUTO', 'MIN' or 'MAX' in "
                . ( caller(0) )[3]
                . "\n" );
    }

    if ( $tint eq 'DEFAULT' || !defined($tint) ) {
        $tint = 1.4e-6;
    }
    elsif ( $tint =~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/
        && ( ( $tint >= 0 && $tint <= 1000 ) || $tint == -1 ) ) {

        # Convert seconds to PLC (power line cycles)
        #$tint*=$self->pl_freq();
    }
    elsif ( $tint =~ /^MIN$/ ) {
        $tint = 0;
    }
    elsif ( $tint =~ /^MAX$/ ) {
        $tint = 1000;
    }
    elsif ( $tint !~ /^(MIN|MAX)$/ ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Integration time has to be set to a positive value or 'AUTO', 'MIN' or 'MAX' in "
                . ( caller(0) )[3]
                . "\n" );
    }

    $count = 1 if !defined($count);
    Lab::Exception::CorruptParameter->throw(
        error => "Sample count has to be an integer between 1 and 512\n" )
        if ( $count !~ /^[0-9]*$/ || $count < 1 || $count > 16777215 );

    $delay = 0 if !defined($delay);
    Lab::Exception::CorruptParameter->throw(
        error => "Trigger delay has to be a positive decimal value\n" )
        if ( $count !~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ );

    $self->write( "PRESET FAST",        error_check => 1 );
    $self->write( "TARM HOLD",          error_check => 1 );
    $self->write( "APER " . $tint,      error_check => 1 );
    $self->write( "MFORMAT SINT",       error_check => 1 );
    $self->write( "OFORMAT SINT",       error_check => 1 );
    $self->write( "MEM FIFO",           error_check => 1 );
    $self->write( "NRDGS $count, AUTO", error_check => 1 );

    #$self->write( "TIMER $delay") if defined($delay);

}

sub triggered_read {
    my $self = shift;
    my $args
        = scalar(@_) % 2 == 0
        ? {@_}
        : ( ref( $_[0] ) eq 'HASH' ? $_[0] : undef );
    Lab::Exception::CorruptParameter->throw("Illegal parameter hash given!\n")
        if !defined($args);

    $args->{'timeout'} = $args->{'timeout'} || undef;

    my $value = $self->query( "TRIG SGL", $args );

    chomp $value;

    my @valarray = split( "\n", $value );

    return @valarray;
}

sub triggered_read_raw {
    my $self = shift;
    my $args
        = scalar(@_) % 2 == 0
        ? {@_}
        : ( ref( $_[0] ) eq 'HASH' ? $_[0] : undef );
    Lab::Exception::CorruptParameter->throw("Illegal parameter hash given!\n")
        if !defined($args);

    my $read_until_length = $args->{'read_until_length'};
    my $value             = '';
    my $fragment          = undef;

    {
        use bytes;
        $value = $self->query( "TARM SGL", $args );
        my $tmp = length($value);
        while ( defined $read_until_length
            && length($value) < $read_until_length ) {
            $value .= $self->read($args);
        }
    }

    return $value;
}

sub decode_SINT {
    use bytes;
    my $self       = shift;
    my $bytestring = shift;
    my $iscale     = shift || $self->query('ISCALE?');

    my @values      = split( //, $bytestring );
    my $ival        = 0;
    my $val_revb    = 0;
    my $tbyte       = 0;
    my $value       = 0;
    my @result_list = ();
    my $i           = 0;
    for ( my $v = 0; $v < $#values; $v += 2 ) {
        $ival = unpack( 'S', join( '', $values[$v], $values[ $v + 1 ] ) );

        # flipping the bytes to MSB,...,LSB
        $val_revb = 0;
        for ( $i = 0; $i < 2; $i++ ) {
            $val_revb = $val_revb
                | ( ( $ival >> $i * 8 & 0x000000FF ) << ( ( 1 - $i ) * 8 ) );
        }

        my $decval = 0;
        my $msb    = ( $val_revb >> 15 ) & 0x0001;
        $decval = $msb == 0 ? 0 : -1 * ( 2**15 );
        for ( $i = 14; $i >= 0; $i-- ) {
            $decval += ( ( ( $val_revb >> $i ) & 0x0001 ) * 2 )**$i;
        }
        push( @result_list, $decval * $iscale );
    }
    return @result_list;
}

sub set_oformat {
    my $self   = shift;
    my $format = shift;

    if ( $format !~ /^\s*(ASCII|1|SINT|2|DINT|3|SREAD|4|DREAL|5)\s*$/ ) {
        Lab::Exception::CorruptParameter->throw("Invalid OFORMAT specified.");
    }
    $format = $1;

    $self->write("OFORMAT $1");

    $self->check_errors();
}

sub get_oformat {
    my $self = shift;
    my $args
        = scalar(@_) % 2 == 0
        ? {@_}
        : ( ref( $_[0] ) eq 'HASH' ? $_[0] : undef );
    Lab::Exception::CorruptParameter->throw("Illegal parameter hash given!\n")
        if !defined($args);

    if ( $args->{direct_read} || !defined $self->device_cache()->{oformat} ) {
        return $self->device_cache()->{oformat}
            = $self->query( 'OFORMAT?', $args );
    }
    else {
        return $self->device_cache()->{oformat};
    }
}

sub get_autozero {
    my $self = shift;

    return $self->device_cache()->{autozero}
        = $self->query( 'AZERO?', @_, error_check => 0 );
}

sub set_autozero {
    my $self   = shift;
    my $enable = shift;

    my $command = "";
    my $cval    = undef;

    if ( $enable =~ /^ONCE$/i ) {
        $command = "AZERO ONCE";
        $cval    = 0;
    }
    elsif ( $enable =~ /^(ON|1)$/i ) {
        $command = "AZERO ON";
        $cval    = 1;
    }
    elsif ( $enable =~ /^(OFF|0)$/i ) {
        $command = "AZERO OFF";
        $cval    = 0;
    }
    else {
        Lab::Exception::CorruptParameter->throw( error => ( caller(0) )[3]
                . " can be set to 'ON'/1, 'OFF'/0 or 'ONCE'. Received '${enable}'\n"
        );
    }
    $self->write( $command, error_check => 1, @_ );

    $self->device_cache()->{autozero} = $cval;
}

sub get_voltage_dc {
    my $self = shift;

    $self->write( "DCV AUTO", @_ );
    $self->write( "TARM SGL", @_ );
    return $self->read(@_);
}

sub set_nplc {
    my $self = shift;
    my $n    = shift;

    $self->write( "NPLC $n", @_ );
}

sub selftest {
    my $self = shift;

    $self->write( "TEST", @_ );
}

sub autocalibration {
    my $self = shift;
    my $mode = shift;

    if ( $mode !~ /^(ALL|0|DCV|1|DIG|2|OHMS|4)$/i ) {
        Lab::Exception::CorruptParameter->throw(
            "preset(): Illegal preset mode given: $mode\n");
    }

    $self->write( "ACAL \U$mode\E", @_ );
}

sub reset {
    my $self = shift;

    $self->write( "PRESET NORM", @_ );
}

sub set_display_state {
    my $self  = shift;
    my $value = shift;

    if ( $value == 1 || $value =~ /on/i ) {
        $self->write( "DISP ON", @_ );
    }
    elsif ( $value == 0 || $value =~ /off/i ) {
        $self->write( "DISP OFF", @_ );
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "set_display_state(): Illegal parameter.\n");
    }
}

sub display_clear {
    my $self = shift;

    $self->write( "DISP CLR", @_ );
}

sub set_display_text {
    my $self = shift;
    my $text = shift;
    if ( $text
        !~ /^[A-Za-z0-9\ \!\#\$\%\&\'\(\)\^\\\/\@\;\:\[\]\,\.\+\-\=\<\>\?\_]*$/
        ) {    # characters allowed by the 3458A
        Lab::Exception::CorruptParameter->throw(
            "set_display_text(): Illegal characters in given text.\n");
    }
    $self->write("DISP MSG,\"$text\"");

    $self->check_errors();
}

sub beep {

    # It beeps!
    my $self = shift;
    $self->write( "BEEP", @_ );
}

sub get_status {
    my $self    = shift;
    my $request = shift;
    my $status  = {};
    (
        $status->{PRG_COMPLETE}, $status->{LIMIT_EXCEEDED},
        $status->{SRQ_EXECUTED}, $status->{POWER_ON},
        $status->{READY},        $status->{ERROR},
        $status->{SRQ},          $status->{DATA}
    ) = $self->connection()->serial_poll();
    return $status->{$request} if defined $request;
    return $status;
}

sub get_error {
    my $self = shift;
    my $error = $self->query( "ERRSTR?", brutal => 1, @_ );
    if ( $error !~ /0,\"NO ERROR\"/ ) {
        if ( $error =~ /^\+?([0-9]*)\,\"?([^\"].*[^\"])\"?$/m ) {
            return ( $1, $2 );    # ($code, $message)
        }
        else {
            Lab::Exception::DeviceError->throw(
                      "Reading the error status of the device failed in "
                    . ( caller(0) )[3]
                    . ". Something's going wrong here.\n" );
        }
    }
    else {
        return (0);
    }
}

sub preset {

    # Sets HP3458A into predefined configurations
    # 0 Fast
    # 1 Norm
    # 2 DIG
    my $self   = shift;
    my $preset = shift;
    if ( $preset !~ /^(FAST|0|NORM|1|DIG|2)$/i ) {
        Lab::Exception::CorruptParameter->throw(
            "preset(): Illegal preset mode given: $preset\n");
    }

    $self->write( "PRESET \U$preset\E", @_ );
}

sub get_id {
    my $self = shift;
    return $self->query( 'ID?', @_ );
}

sub trg {
    my $self = shift;
    $self->write( 'TRIG SGL', @_ );
}

sub get_value {

    my $self = shift;

    my $val = $self->read(@_);
    chomp $val;
    return $val;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::HP3458A - Agilent 3458A Multimeter

=head1 VERSION

version 3.881

=head1 SYNOPSIS

    use Lab::Instrument::HP3458A;
    
    my $dmm=new Lab::Instrument::HP3458A({
        gpib_board   => 0,
        gpib_address => 11,
    });
    print $dmm->get_voltage_dc();

=head1 DESCRIPTION

The Lab::Instrument::HP3458A class implements an interface to the Agilent / HP 
3458A digital multimeter. 

=head1 CONSTRUCTOR

    my $hp=new(%parameters);

=head1 METHODS

=head2 pl_freq
Parameter: pl_freq

    $hp->pl_freq($new_freq);
    $npl_freq = $hp->pl_freq();

Get/set the power line frequency at your location (50 Hz for most countries, which is the default). This
is the basis of the integration time setting (which is internally specified as a count of power
line cycles, or PLCs). The integration time will be set incorrectly if this parameter is set incorrectly.

=head2 get_voltage_dc

    $voltage=$hp->get_voltage_dc();

Make a dc voltage measurement. This also enables autoranging. For finer control, use configure_voltage_dc() and
triggered_read.

_head2 triggered_read

    @values = $hp->triggered_read();
    $value = $hp->triggered_read();

Trigger and read value(s) using the current device setup. This expects and digests a list of values in ASCII format,
as set up by configure_voltage_dc().

=head2 triggered_read_raw

    $result = $hp->triggered_read_raw( read_until_length => $length );

Trigger and read using the current device setup. This won't do any parsing and just return the answer from the device.
If $read_until_length (integer) is specified, it will try to continuously read until it has gathered this amount of bytes.

=head2 configure_voltage_dc

    $hp->configure_voltage_dc($range, $integration_time);

Configure range and integration time for the following DCV measurements.

$range is a voltage or one of "AUTO", "MIN" or "MAX".
$integration_time is given in seconds or one of "DEFAULT", "MIN" or "MAX".

=head2 configure_voltage_dc_trigger

    $hp->configure_voltage_dc_trigger($range, $integration_time, 
      $count, $delay);

Configures range, integration time, sample count and delay (between samples) for triggered
readings.

$range, $integration_time: see configure_voltage_dc().
$count is the sample count per trigger (integer).
$delay is the delay between the samples in seconds.

=head2 configure_voltage_dc_trigger_highspeed

    $hp->configure_voltage_dc_trigger_highspeed($range, 
      $integration_time, $count, $delay);

Same as configure_voltage_dc_trigger, but configures the device for maximum measurement speed.
Values are transferred in SINT format and can be fetched and decoded using triggered_read_raw()
and decode_SINT().
This mode allows measurements of up to about 100 kSamples/second.

$range: see configure_voltage_dc().
$integration_time: integration time in seconds. The default is 1.4e-6.
$count is the sample count per trigger (integer).
$delay is the delay between the samples in seconds.

=head2 set_display_state

    $hp->set_display_state($state);

Turn the front-panel display on/off. $state can be 
each of '1', '0', 'on', 'off'.

=head2 set_display_text

    $hp->set_display_text($text);

Display a message on the front panel. The multimeter will display up to 12
characters in a message; any additional characters are truncated.

=head2 display_clear

    $hp->display_clear();

Clear the message displayed on the front panel.

=head2 beep

    $hp->beep();

Issue a single beep immediately.

=head2 get_error

    ($err_num,$err_msg)=$hp->get_error();

Query the multimeter's error queue. Up to 20 errors can be stored in the
queue. Errors are retrieved in first-in-first out (FIFO) order.

=head2 check_errors

    $instrument->check_errors($last_command);
    
    # try
    eval { $instrument->check_errors($last_command) };
    # catch
    if ( my $e = Exception::Class->caught('Lab::Exception::DeviceError')) {
        warn "Errors from device!";
        @errors = $e->error_list();
        @devtype = $e->device_class();
        $command = $e->command();		
    } else {
        $e = Exception::Class->caught();
        ref $e ? $e->rethrow; die $e;
    }

Uses get_error() to check the device for occured errors. Reads all present error and throws a
Lab::Exception::DeviceError. The list of errors, the device class and the last issued command(s)
(if the script provided them) are enclosed.

=head2 set_nplc

    $hp->set_nplc($number);

Sets the integration time in units of power line cycles.

=head2 reset

    $hp->reset();

Reset the multimeter to its power-on configuration. Same as preset('NORM').

=head2 preset

    $hp->preset($config);

$config can be any of the following settings:

  'FAST'  / 0
  'NORM'  / 1
  'DIG'   / 2 

Choose one of several configuration presets.

=head2 selftest

    $hp->selftest();

Starts the internal self-test routine.

=head2 autocalibration

    $hp->autocalibration($mode);

Starts the internal autocalibration. Warning... this procedure takes 11 minutes with the 'ALL' mode!

$mode can be each of

  'ALL'  / 0
  'DCV'  / 1
  'AC'   / 2
  'OHMS' / 4

=head2 decode_SINT

    @values = $hp->decode_SINT( $SINT_data, <$iscale> );

Takes a data blob with SINT values and decodes them into a numeric list. The used $iscale parameter is
read from the device by default if omitted. Make sure the device still has the same settings as used to
obtain $SINT_data, or iscale will be off which leads to invalid data decoding.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item * L<Lab::Instrument>

=item * L<Lab::Instrument::Multimeter>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner, Andreas K. Huettel, Florian Olbrich
            2013       Alois Dirnaichner, Andreas K. Huettel
            2015       Alois Dirnaichner
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
