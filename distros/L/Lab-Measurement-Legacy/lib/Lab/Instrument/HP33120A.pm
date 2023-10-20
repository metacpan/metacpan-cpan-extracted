package Lab::Instrument::HP33120A;
#ABSTRACT: HP 33120A 15MHz function/arbitrary waveform generator
$Lab::Instrument::HP33120A::VERSION = '3.899';
use v5.20;

use strict;
use warnings;
use Lab::Instrument;
use Try::Tiny;
use Carp;
use English;

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => ['GPIB'],

    #default settings for connections

    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
    },

    device_settings => {},

    scpi_override => {},

    device_cache => {
        id         => undef,
        shape      => undef,
        frequency  => undef,
        amplitude  => undef,
        offset     => undef,
        duty_cycle => undef,
        load       => undef,
        sync       => undef,
        vunit      => undef,

        user_waveform  => undef,
        trigger_source => undef,
        trigger_slope  => undef,
        display        => undef,
        am_depth       => undef,
        am_shape       => undef,
        am_frequency   => undef,
        am_source      => undef,

        fm_deviation => undef,
        fm_shape     => undef,
        fm_frequency => undef,

        burst_cycles => undef,
        burst_phase  => undef,
        burst_rate   => undef,
        burst_source => undef,

        fsk_frequency => undef,
        fsk_rate      => undef,
        fsk_source    => undef,

        sweep_start_frequency => undef,
        sweep_stop_frequency  => undef,
        sweep_spacing         => undef,
        sweep_time            => undef,

        modulation => undef,
    },

    waveforms => {
        user => [],
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

    # when NI-GPIB-USB-HS initially plugged in, first write
    # fails with timeout, so try a 'write nothing significant', let it
    # fail, after that it should be okay

    my $self = shift;
    try {
        $self->write( command => ' ', );
    }
    catch { 1; };

}


sub get_id {
    my $self = shift;
    return $self->query('*IDN?');
}


sub get_status {
    my $self = shift;
    my $stb  = $self->query("*STB?");
    my $esr  = $self->query("*ESR?");

    my (%status);
    $status{'DATA'}  = ( $stb & 0x10 ) == 0 ? 0 : 1;
    $status{'ERROR'} = ( $esr & 0x3C ) == 0 ? 0 : 1;
    $status{'QERR'}  = ( $esr & 0x04 ) == 0 ? 0 : 1;
    $status{'DERR'}  = ( $esr & 0x08 ) == 0 ? 0 : 1;
    $status{'EERR'}  = ( $esr & 0x10 ) == 0 ? 0 : 1;
    $status{'CERR'}  = ( $esr & 0x20 ) == 0 ? 0 : 1;
    $status{'PON'}   = ( $esr & 0x80 ) == 0 ? 0 : 1;
    $status{'OPC'}   = ( $esr & 0x01 ) == 0 ? 0 : 1;
    return %status;
}


sub get_error {
    my $self = shift;
    my $err  = $self->query("SYST:ERR?");
    if ( $err =~ /^\s*\+?0+\s*,/ ) {
        return ( 0, '' );    # no error
    }

    my ( $code, $msg ) = split( /,/, $err );
    return ( $code, $msg );
}


our $rst_cache = {
    shape     => 'SIN',
    frequency => 1000,
    amplitude => 0.1,
    offset    => 0,
    load      => 50,
    sync      => 1,
    vunit     => 'VPP',

    trigger_source => 'IMM',
    display        => 1,
    am_depth       => 100,
    am_shape       => 'SIN',
    am_frequency   => 100,
    am_source      => 'INT',

    fm_deviation => 100,
    fm_shape     => 'SIN',
    fm_frequency => 10,

    burst_cycles => 1,
    burst_phase  => 0,
    burst_rate   => 100,
    burst_source => 'INT',

    fsk_frequency => 100,
    fsk_rate      => 10,
    fsk_source    => 'INT',

    sweep_start_frequency => 100,
    sweep_stop_frequency  => 1000,
    sweep_spacing         => 'LIN',
    sweep_time            => 1,

    modulation => 'NONE',
};

sub reset {
    my $self = shift;

    my $mod = $self->get_modulation( { read_mode => 'cache' } );

    $self->write('*RST');
    $self->write('*CLS');
    $self->wait_complete();

    # set cache to *RST values

    foreach my $k ( keys( %{$rst_cache} ) ) {
        $self->{device_cache}->{$k} = $rst_cache->{$k};
    }

    if ( $mod =~ /^SWE/i ) {
        $self->{device_cache}->{sweep_start_frequency} = 0.01;
        $self->{device_cache}->{sweep_stop_frequency}  = 15000000;
    }

}


sub get_trigger_slope {
    my $self = shift;
    return $self->query('TRIG:SLOP?');
}


sub set_trigger_slope {
    my $self = shift;
    my $in   = shift;
    my $sl;
    if ( $in =~ /^\s*[p+]/i ) {
        $sl = 'POS';
    }
    elsif ( $in =~ /^\s*[n\-]/i ) {
        $sl = 'NEG';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid trigger slope '$in' [POS|NEG]\n");
        return;
    }
    $self->write("TRIG:SLOP $sl");
}


sub wait_complete {
    my $self = shift;
    $self->write('*WAI');
}


sub trigger {
    my $self = shift;
    $self->write('*TRG');
    $self->wait_complete();
}


sub get_trigger_source {
    my $self = shift;
    return $self->query("TRIG:SOUR?");
}


sub set_trigger_source {
    my $self = shift;
    my $in   = shift;
    my $s;
    if ( $in =~ /^\s*IMM/i ) {
        $s = 'IMM';
    }
    elsif ( $in =~ /^\s*BUS/i ) {
        $s = 'BUS';
    }
    elsif ( $in =~ /^\s*EXT/i ) {
        $s = 'EXT';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Set_trigger_source invalid input '$in' [IMM|BUS|EXT]\n");
        return;
    }
    $self->write("TRIG:SOUR $s");
}


sub set_display {
    my $self = shift;
    my $in   = shift;
    my $state;
    if ( $in =~ /^\s*(1|on|t|y)/i ) {
        $state = 1;
    }
    elsif ( $in =~ /^\s*(0|of|f|n)/i ) {
        $state = 0;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid display setting '$in' [ON|OFF]\n");
        return;
    }
    $self->write("DISP $state");
}


sub get_display {
    my $self = shift;
    return $self->query("DISP?");
}


sub set_text {
    my $self = shift;
    my $in   = shift;
    $in =~ s/\'/''/g;
    $self->write("DISP:TEXT '$in'");
}


sub get_text {
    my $self = shift;
    my $txt  = $self->query('DISP:TEXT?');
    my (@s)  = _parseStrings($txt);
    return $s[0];
}


sub clear_text {
    my $self = shift;
    $self->write("DISP:TEXT:CLE");
}


sub beep {
    my $self = shift;
    $self->write("SYST:BEEP");
}


sub get_sync {
    my $self = shift;
    return $self->query("OUTP:SYNC?");
}


sub set_sync {
    my $self = shift;
    my $in   = shift;
    my $sync;
    if ( $in =~ /^\s*(1|on|t|y)/i ) {
        $sync = 1;
    }
    elsif ( $in =~ /^\s*(0|of|f|n)/i ) {
        $sync = 0;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Sync '$in' not recognized as boolean \n");
        return;
    }
    $self->write("OUTP:SYNC $sync");
}


sub save_setup {
    my $self = shift;
    my $n    = shift;
    $n = int( $n + 0.5 );
    if ( $n < 0 || $n > 3 ) {
        Lab::Exception::CorruptParameter->throw(
            "Save '$n' out of range (0..3)\n");
        return;
    }
    $self->write("*SAV $n");
}


sub recall_setup {
    my $self = shift;
    my $n    = shift;
    $n = int( $n + 0.5 );
    if ( $n < 0 || $n > 3 ) {
        Lab::Exception::CorruptParameter->throw(
            "Recall '$n' out of range (0..3)\n");
        return;
    }
    $self->write("*RCL $n");

    # invalidate the cache
    $self->reset_device_cache();
}


sub delete_setup {
    my $self = shift;
    my $n    = shift;
    $n = int( $n + 0.5 );

    if ( $n < 0 || $n > 3 ) {
        Lab::Exception::CorruptParameter->throw(
            "Delete '$n' out of range (0..3)\n");
        return;
    }
    $self->write("MEM:STAT:DEL $n");
}


sub get_load {
    my $self = shift;
    my $z    = $self->query("OUTP:LOAD?");
    $z = 'INF' if $z > 1000;
    return $z;
}


sub set_load {
    my $self = shift;
    my $in   = shift;
    my $z;

    if ( $in =~ /^\s*inf/i ) {
        $z = 'INF';
    }
    else {
        my $zin = _parseNRf( $in, 'ohm' );
        if ( $zin =~ /^ERR/i ) {
            Lab::Exception::CorruptParameter->throw(
                "Parse error in load impedance '$in': $zin\n");
            return;
        }

        if ( $zin ne 'MIN' && $zin ne 'MAX' ) {
            if ( $zin > 40 && $zin < 60 ) {
                $z = 50;
            }
            elsif ( $zin > 50e3 ) {
                $z = 'INF';
            }
            else {
                Lab::Exception::CorruptParameter->throw(
                    "Invalid load impedance '$in' [MIN,MAX,INF,50]\n");
                return;
            }
        }
        else {
            $z = $zin;
        }
    }
    $self->write("OUTP:LOAD $z");
}


sub get_shape {
    my $self = shift;
    return $self->query('FUNC:SHAP?');
}


sub set_shape {
    my $self  = shift;
    my $shape = shift;
    my $s;
    if ( $shape =~ /^SIN/i ) {
        $s = 'SIN';
    }
    elsif ( $shape =~ /^SQU/i ) {
        $s = 'SQU';
    }
    elsif ( $shape =~ /^TRI/i ) {
        $s = 'TRI';
    }
    elsif ( $shape =~ /^RAMP/i ) {
        $s = 'RAMP';
    }
    elsif ( $shape =~ /^NOIS/i ) {
        $s = 'NOIS';
    }
    elsif ( $shape =~ /^DC/i ) {
        $s = 'DC';
    }
    elsif ( $shape =~ /^USER/i ) {
        $s = 'USER';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid function shape '$shape'\n");
        return;
    }
    $self->write("FUNC:SHAP $s");
}


sub get_frequency {
    my $self = shift;
    return $self->query("FREQ?");
}


sub set_frequency {
    my $self = shift;
    my $freq = shift;
    my $f    = _parseNRf( $freq, 'hz' );

    if ( $f =~ /^ERR/i ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing frequency '$freq': $f\n");
        return;
    }

    if ( $f ne 'MIN' && $f ne 'MAX' ) {
        $f = sprintf( '%.11e', $f );
        my $shape = $self->get_shape( { read_mode => 'cache' } );
        my $maxf = 15e6;
        $maxf = 100e3 if $shape eq 'RAMP' || $shape eq 'TRI';
        $maxf = 5e6 if $shape eq 'USER';    # fix, points dependent

        if ( $f < 100e-6 || $f > $maxf ) {
            Lab::Exception::CorruptParameter->throw(
                "Frequency '$freq' out of valid range 100uHz..${maxf}Hz\n");
            return;
        }
    }
    $self->write("FREQ $f");
}


sub get_duty_cycle {
    my $self = shift;
    return $self->query('PULS:DCYC?');
}


sub set_duty_cycle {
    my $self = shift;
    my $in   = shift;
    my $dc   = _parseNRf( $in, '' );

    if ( $dc =~ /^ERR/i ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing duty-cycle '$in': $dc\n");
        return;
    }
    if ( $dc ne 'MIN' && $dc ne 'MAX' ) {
        my $f = $self->get_frequency( { read_mode => 'cache' } );

        $dc = int( $dc + 0.5 );
        my $dcmin = 20;
        my $dcmax = 80;
        if ( $f > 5e6 ) {
            $dcmin = 40;
            $dcmax = 60;
        }
        if ( $dc < $dcmin || $dc > $dcmax ) {
            Lab::Exception::CorruptParameter->throw(
                "Duty-cycle '$in' outside valid range ($dcmin..$dcmax)\n");
            return;
        }
    }
    $self->write("PULS:DCYC $dc");
}


sub get_amplitude {
    my $self = shift;
    return $self->query("volt?");
}


sub set_amplitude {
    my $self = shift;
    my $in   = shift;
    my $v    = _parseNRf( $in, 'v', 'db', 'dbv' );

    if ( $v =~ /^ERR/i ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing amplitude '$in': $v\n");
        return;
    }
    if ( $v ne 'MIN' && $v ne 'MAX' ) {
        $v = sprintf( '%.4e', $v );
        my $z = $self->get_load( { read_mode => 'cache' } );
        my $u = $self->get_vunit( { read_mode => 'cache' } );
        my $s = $self->get_shape( { read_mode => 'cache' } );
        my $voff = $self->get_offset( { read_mode => 'cache' } );

        my $vpp;
        if ( $u eq 'VPP' ) {
            $vpp = $v;
        }
        elsif ( $u eq 'VRMS' || $u eq 'DBM' ) {
            my $vrms = $v;
            $vrms = 0.224 * ( 10**( $v / 20 ) );
            if ( $s eq 'SQU' ) {
                $vpp = 2 * $vrms;
            }
            elsif ( $s eq 'DC' ) {
                $vpp = $vrms;
            }
            elsif ( $s eq 'SIN' ) {
                $vpp = 2 * sqrt(2) * $vrms;
            }
            elsif ( $s eq 'TRI' || $s eq 'RAMP' ) {
                $vpp = 2 * sqrt(3) * $vrms;
            }
            elsif ( $s eq 'NOIS' ) {
                $vpp = 6.6 * $vrms;    # a guess, 99.9% of the time
            }
            elsif ( $s eq 'USER' ) {
                $vpp = 2 * sqrt(2) * $vrms;    # a guess, fix later
            }
        }

        my $vmin = 100e-3;
        my $vmax = 20;
        $vmin = 50e-3 if $z == 50;
        $vmax = 10    if $z == 50;

        if ( $vpp < $vmin || $vpp > $vmax ) {
            Lab::Exception::CorruptParameter->throw(
                "Amplitude '$in' out of range ($vmin..$vmax)\n");
            return;
        }

        if ( abs($voff) > 2 * $vpp ) {
            Lab::Exception::CorruptParameter->throw(
                "Amplitude '$in' gives |Voff| > 2Vpp\n");
            return;
        }
        if ( abs($voff) + 0.5 * $vpp > $vmax ) {
            Lab::Exception::CorruptParameter->throw(
                "Amplitude '$in' gives |Voff|+Vpp/2 > Vmax\n");
            return;
        }

    }
    $self->write("VOLT $v");
}


sub get_vunit {
    my $self = shift;
    return $self->query("VOLT:UNIT?");
}


sub set_vunit {
    my $self = shift;
    my $in   = shift;
    $in =~ s/^\s+//;
    $in =~ s/\s+$//;
    my $u;
    if ( $in =~ /pp/i ) {
        $u = 'VPP';
    }
    elsif ( $in =~ /rms/i ) {
        $u = 'VRMS';
    }
    elsif ( $in =~ /dbm/i ) {
        $u = 'DBM';
    }
    elsif ( $in =~ /def/i ) {
        $u = 'DEF';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid vunit '$in' [VPP,VRMS,DBM,DEFAULT]\n");
        return;
    }
    $self->write("VOLT:UNIT $u");
}


sub get_offset {
    my $self = shift;
    return $self->query("VOLT:OFFS?");
}


sub set_offset {
    my $self = shift;
    my $in   = shift;

    my $voff = _parseNRf( $in, 'v' );
    if ( $voff =~ /^ERR/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing '$in': $voff\n");
        return;
    }
    if ( $voff ne 'MIN' && $voff ne 'MAX' ) {
        $voff = sprintf( '%.4e', $voff );
        my $u = $self->get_vunit( { read_mode => 'cache' } );
        my $vpp;
        if ( $u ne 'VPP' ) {
            $self->set_vunit('VPP');
            $vpp = $self->get_amplitude( { read_mode => 'device' } );
            $self->set_vunit($u);
            $self->get_amplitude( { read_mode => 'device' } );   # reset cache
        }
        else {
            $vpp = $self->get_amplitude( { read_mode => 'cache' } );
        }
        my $z = $self->get_load( { read_mode => 'cache' } );
        my $vmax = 20;
        $vmax = 10 if $z == 50;
        if ( abs($voff) > 2 * $vpp ) {
            Lab::Exception::CorruptParameter->throw(
                "|Voffset| > 2*Vpp: $voff\n");
            return;
        }
        if ( abs($voff) + 0.5 * $vpp > $vmax ) {
            Lab::Exception::CorruptParameter->throw(
                "|Voffset|+Vpp/2 > $vmax: Voffset = $voff\n");
            return;
        }
    }
    $self->write("VOLT:OFFS $voff");
}

# use a "special" cache for this, because we need to store
# an array of names


sub get_waveform_list {
    my $self = shift;

    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );
    $read_mode = 'device' unless defined($read_mode);

    if (   $read_mode eq 'cache'
        && $#{ $self->{waveform}->{user} } >= 0
        && !$self->{config}->{no_cache} ) {
        return ( @{ $self->{waveform}->{user} } );
    }

    my $wfs = $self->query("DATA:CAT?");
    $self->{waveform}->{user} = [ _parseStrings($wfs) ];
    return ( @{ $self->{waveform}->{user} } );
}


sub get_user_waveform {
    my $self = shift;
    return $self->query("FUNC:USER?");
}


sub set_user_waveform {
    my $self = shift;
    my $in   = shift;
    $in =~ s/^\s+//;
    $in =~ s/\s+$//;

    if ( $in !~ /^[a-z]\w+$/i || length($in) > 8 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid arbitrary waveform name '$in' (a-z,0-9,_; len < 9) \n");
        return;
    }
    $in = uc($in);

    my (@w) = $self->get_waveform_list( { read_mode => 'cache' } );

    my $got = 0;
    foreach my $wf ( @w, 'VOLATILE' ) {
        $got++ if $wf eq $in;
    }
    if ( $got == 0 ) {
        Lab::Exception::CorruptParameter->throw(
            "Unknown USER waveform '$in' for set_user_waveform\n");
        return;
    }
    $self->write("FUNC:USER $in");
}


sub load_waveform {
    my $self = shift;
    my $arg  = shift;
    my $fwfd;
    my $dac;

    if ( ref($arg) eq 'HASH' ) {
        if ( exists( $arg->{waveform} )
            && ref( $arg->{waveform} ) eq 'ARRAY' ) {
            $fwfd = $arg->{waveform};
        }
        elsif ( exists( $arg->{dac} ) && ref( $arg->{dac} ) eq 'ARRAY' ) {
            $dac = $arg->{dac};
        }
    }
    else {
        if ( ref($arg) eq 'ARRAY' ) {
            $fwfd = $arg;
        }
        elsif ( ref($arg) eq '' ) {
            $fwfd = [ $arg, @_ ];
        }

        if ( defined($fwfd) ) {
            my ( $minv, $maxv );
            foreach my $v ( @{$fwfd} ) {
                $minv = $v unless defined($minv) && $minv < $v;
                $maxv = $v unless defined($maxv) && $maxv > $v;
            }
            if ( $minv < -1 && $maxv > 1 ) {
                $dac  = $fwfd;
                $fwfd = undef;
            }
        }
    }

    if ( !defined($fwfd) && !defined($dac) ) {
        Lab::Exception::CorruptParameter->throw("No waveform data\n");
        return;
    }

    my $npts;
    my $cmd;
    if ( defined($dac) ) {
        $cmd  = 'DATA:DAC VOLATILE';    # maybe use gpib data block?
        $npts = $#{$dac} + 1;
        for ( my $j = 0; $j < $npts; $j++ ) {
            my $d = int( $dac->[$j] + 0.5 );
            if ( abs($d) > 2047 ) {
                Lab::Exception::CorruptParameter->throw(
                    "Waveform DAC data point $j ($) out of range -2047..2047  \n"
                );
                return;
            }
            $cmd .= ',' . $d;
        }

    }

    if ( defined($fwfd) ) {
        $cmd  = 'DATA VOLATILE';
        $npts = $#{$fwfd} + 1;
        for ( my $j = 0; $j < $npts; $j++ ) {
            my $v = sprintf( '%.3f', $fwfd->[$j] );
            if ( abs($v) > 1 ) {
                Lab::Exception::CorruptParameter->throw(
                    "Waveform data point $j ($v) out of range -1..1  \n");
                return;
            }
            $cmd .= "," . $v;
        }
    }

    if ( $npts < 8 || $npts > 16000 ) {
        Lab::Exception::CorruptParameter->throw(
            "Number of Waveform data points $npts out of range 8..16000  \n");
        return;
    }
    $self->write($cmd);
}


sub get_waveform_average {
    my $self = shift;
    my $name = shift;
    if ( !defined($name) ) {
        return $self->query("DATA:ATTR:AVER?");
    }
    my (@w) = $self->get_waveform_list( { read_mode => 'cache' } );

    my $got = 0;
    $name = uc($name);
    foreach my $s (@w) {
        $got++ if uc($s) eq $name;
        last   if $got;
    }
    if ( !$got ) {
        Lab::Exception::CorruptParameter->throw(
            "No such stored waveform '$name' \n");
        return;
    }
    return $self->query("DATA:ATTR:AVER? $name");
}


sub get_waveform_crestfactor {
    my $self = shift;
    my $name = shift;
    if ( !defined($name) ) {
        return $self->query("DATA:ATTR:CFAC?");
    }
    my (@w) = $self->get_waveform_list( { read_mode => 'cache' } );

    my $got = 0;
    $name = uc($name);
    foreach my $s (@w) {
        $got++ if uc($s) eq $name;
        last   if $got;
    }
    if ( !$got ) {
        Lab::Exception::CorruptParameter->throw(
            "No such stored waveform '$name' \n");
        return;
    }
    return $self->query("DATA:ATTR:CFAC? $name");
}


sub get_waveform_points {
    my $self = shift;
    my $name = shift;
    if ( !defined($name) ) {
        return $self->query("DATA:ATTR:POIN?");
    }
    my (@w) = $self->get_waveform_list( { read_mode => 'cache' } );

    my $got = 0;
    $name = uc($name);
    foreach my $s (@w) {
        $got++ if uc($s) eq $name;
        last   if $got;
    }
    if ( !$got ) {
        Lab::Exception::CorruptParameter->throw(
            "No such stored waveform '$name' \n");
        return;
    }
    return $self->query("DATA:ATTR:POIN? $name");
}


sub get_waveform_peak2peak {
    my $self = shift;
    my $name = shift;
    if ( !defined($name) ) {
        return $self->query("DATA:ATTR:PTP?");
    }
    my (@w) = $self->get_waveform_list( { read_mode => 'cache' } );

    my $got = 0;
    $name = uc($name);
    foreach my $s (@w) {
        $got++ if uc($s) eq $name;
        last   if $got;
    }
    if ( !$got ) {
        Lab::Exception::CorruptParameter->throw(
            "No such stored waveform '$name' \n");
        return;
    }
    return $self->query("DATA:ATTR:PTP? $name");
}


sub store_waveform {
    my $self = shift;
    my $name = shift;
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    if ( $name !~ /^[a-z]\w+$/i ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid waveform name '$name' [a-z][a-z,0-9,_]+\n");
        return;
    }
    if ( length($name) > 8 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid waveform name '$name' length > 8\n");
        return;
    }
    $name = uc($name);
    if (   $name eq 'SINC'
        || $name eq 'NEG_RAMP'
        || $name eq 'EXP_RISE'
        || $name eq 'EXP_FALL'
        || $name eq 'CARDIAC'
        || $name eq 'VOLATILE' ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid waveform name '$name' for copy\n");
        return;
    }

    my (@w) = $self->get_waveform_list( { read_mode => 'cache' } );
    my $got = 0;
    foreach my $s (@w) {
        $got++ if uc($s) eq $name;
        last   if $got;
    }
    if ( !$got && $#w == 9 ) {
        Lab::Exception::CorruptParameter->throw(
            "Waveform storage is full, delete something \n");
        return;
    }
    $self->write("DATA:COPY $name");
}


sub delete_waveform {
    my $self = shift;
    my $name = shift;
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    if ( $name !~ /^[a-z]\w+$/i ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid waveform name '$name' [a-z][a-z,0-9,_]+\n");
        return;
    }
    if ( length($name) > 8 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid waveform name '$name' length > 8\n");
        return;
    }
    $name = uc($name);
    if (   $name eq 'SINC'
        || $name eq 'NEG_RAMP'
        || $name eq 'EXP_RISE'
        || $name eq 'EXP_FALL'
        || $name eq 'CARDIAC' ) {
        Lab::Exception::CorruptParameter->throw(
            "Built-in waveform '$name' , not deletable\n");
        return;
    }

    my (@w) = $self->get_waveform_list( { read_mode => 'cache' } );
    my $got = 0;
    foreach my $s ( @w, 'VOLATILE' ) {
        $got++ if uc($s) eq $name;
        last   if $got;
    }
    if ( !$got ) {
        Lab::Exception::CorruptParameter->throw("No such waveform '$name'\n");
        return;
    }
    $self->write("DATA:DEL $name");
}


sub get_waveform_free {
    my $self = shift;
    return $self->query('DATA:NVOL:FREE?');
}


sub get_modulation {
    my $self = shift;
    my $mod  = 'NONE';

    $mod = 'AM'    if $self->query("AM:STAT?");
    $mod = 'FM'    if $self->query("FM:STAT?");
    $mod = 'BURST' if $self->query("BM:STAT?");
    $mod = 'FSK'   if $self->query("FSK:STAT?");
    $mod = 'SWEEP' if $self->query("SWE:STAT?");

    return $mod;
}


sub set_modulation {
    my $self = shift;
    my $in   = shift;
    $in = 'NONE' unless defined($in);
    $in = 'NONE' if $in eq '';
    $in =~ s/^\s+//;
    my $m;

    if ( $in =~ /^NO/i || $in =~ /^OF/i ) {
        $m = 'NONE';
    }
    elsif ( $in =~ /^AM/i ) {
        $m = 'AM';
    }
    elsif ( $in =~ /^FM/i ) {
        $m = 'FM';
    }
    elsif ( $in =~ /^BUR/i ) {
        $m = 'BM';
    }
    elsif ( $in =~ /^FSK/i ) {
        $m = 'FSK';
    }
    elsif ( $in =~ /^SWE/i ) {
        $m = 'SWE';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid modulation type '$in', should be NONE|AM|FM|BURST|FSK|SWEEP\n"
        );
        return;
    }

    my $cm = $self->get_modulation( { read_mode => 'cache' } );
    $cm = 'BM'  if $cm eq 'BURST';
    $cm = 'SWE' if $cm eq 'SWEEP';
    if ( $m eq 'NONE' ) {
        $self->write("$cm:STAT 0");
    }
    else {
        if ( $cm ne 'NONE' ) {
            $self->write("$cm:STAT 0");
        }
        $self->write("$m:STAT 1");
    }
}


sub set_am_depth {
    my $self = shift;
    my $in   = shift;
    my $d    = _parseNRf($in);
    if ( $d =~ /^ERR:/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid AM modulation depth '$in' $d\n");
        return;
    }
    if ( $d ne 'MIN' && $d ne 'MAX' ) {
        $d = sprintf( '%.1f', $d );
        if ( $d < 0 || $d > 120 ) {
            Lab::Exception::CorruptParameter->throw(
                "Invalid AM modulation depth '$in' [0..120|MIN|MAX]\n");
            return;
        }
    }
    $self->write("AM:DEPT $d");
}


sub get_am_depth {
    my $self = shift;
    return $self->query("AM:DEPT?");
}


sub get_am_shape {
    my $self = shift;
    return $self->query("AM:INT:FUNC?");
}


sub set_am_shape {
    my $self = shift;
    my $in   = shift;
    $in =~ s/^\s+//;
    my $s;

    if ( $in =~ /^sin/i ) {
        $s = 'SIN';
    }
    elsif ( $in =~ /^squ/i ) {
        $s = 'SQU';
    }
    elsif ( $in =~ /^tri/i ) {
        $s = 'TRI';
    }
    elsif ( $in =~ /^ram/i ) {
        $s = 'RAMP';
    }
    elsif ( $in =~ /^noi/i ) {
        $s = 'NOIS';
    }
    elsif ( $in =~ /^use/i ) {
        $s = 'USER';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid AM modulation shape '$in' [SIN|SQU|TRI|RAMP|NOIS|USER]\n"
        );
        return;
    }
    $self->write("AM:INT:FUNC $s");
}


sub get_am_frequency {
    my $self = shift;
    return $self->query("AM:INT:FREQ?");
}


sub set_am_frequency {
    my $self = shift;
    my $in   = shift;

    my $f = _parseNRf( $in, 'Hz' );

    if ( $f =~ /^ERR:/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid AM modulation frequency '$in' $f\n");
        return;
    }

    if ( $f ne 'MIN' && $f ne 'MAX' ) {
        if ( $f < 10e-3 || $f > 20e3 ) {
            Lab::Exception::CorruptParameter->throw(
                "AM modulation frequency '$in' out of range 10mHz..20kHz\n");
            return;
        }
    }
    $self->write("AM:INT:FREQ $f");
}


sub get_am_source {
    my $self = shift;
    return $self->query("AM:SOUR?");
}


sub set_am_source {
    my $self = shift;
    my $in   = shift;
    my $s;

    if ( $in =~ /^\s*BOTH/i ) {
        $s = 'BOTH';
    }
    elsif ( $in =~ /^\s*INT/i ) {
        $s = 'BOTH';
    }
    elsif ( $in =~ /^\s*EXT/i ) {
        $s = 'EXT';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid AM modulation source '$in' [BOTH|EXT]\n");
        return;
    }
    $self->write("AM:SOUR $s");
}


sub get_fm_deviation {
    my $self = shift;
    return $self->query("FM:DEV?");
}


sub set_fm_deviation {
    my $self = shift;
    my $in   = shift;
    my $d    = _parseNRf( $in, 'hz' );

    if ( $d ne 'MIN' && $d ne 'MAX' ) {
        my $s = $self->get_shape( { read_mode => 'cache' } );
        my $f = $self->get_frequency( { read_mode => 'cache' } );
        my $fmax = 15.1e6;
        $fmax = 200e3 if $s eq 'TRI' || $s eq 'RAMP';
        $fmax = 5.1e6 if $s eq 'USER';

        if ( $d < 10e-3 || $d > $f || $d + $f > $fmax ) {
            Lab::Exception::CorruptParameter->throw(
                "FM modulation '$in' out of range\n");
            return;
        }
    }
    $self->write("FM:DEV $d");
}


sub get_fm_shape {
    my $self = shift;
    return $self->query("FM:INT:FUNC?");
}


sub set_fm_shape {
    my $self = shift;
    my $in   = shift;
    $in =~ s/^\s+//;
    my $s;

    if ( $in =~ /^sin/i ) {
        $s = 'SIN';
    }
    elsif ( $in =~ /^squ/i ) {
        $s = 'SQU';
    }
    elsif ( $in =~ /^tri/i ) {
        $s = 'TRI';
    }
    elsif ( $in =~ /^ram/i ) {
        $s = 'RAMP';
    }
    elsif ( $in =~ /^noi/i ) {
        $s = 'NOIS';
    }
    elsif ( $in =~ /^use/i ) {
        $s = 'USER';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid FM modulation shape '$in' [SIN|SQU|TRI|RAMP|NOIS|USER]\n"
        );
        return;
    }
    $self->write("FM:INT:FUNC $s");
}


sub get_fm_frequency {
    my $self = shift;
    return $self->query("FM:INT:FREQ?");
}


sub set_fm_frequency {
    my $self = shift;
    my $in   = shift;

    my $f = _parseNRf( $in, 'Hz' );

    if ( $f =~ /^ERR:/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid FM modulation frequency '$in' $f\n");
        return;
    }

    if ( $f ne 'MIN' && $f ne 'MAX' ) {
        if ( $f < 10e-3 || $f > 10e3 ) {
            Lab::Exception::CorruptParameter->throw(
                "FM modulation frequency '$in' out of range 10mHz..10kHz\n");
            return;
        }
    }
    $self->write("FM:INT:FREQ $f");
}


sub get_burst_cycles {
    my $self = shift;
    return $self->query("BM:NCYC?");
}


sub set_burst_cycles {
    my $self = shift;
    my $in   = shift;
    my $ncyc;
    if ( $in =~ /^\s*min/i ) {
        $ncyc = 'MIN';
    }
    elsif ( $in =~ /\s*max/i ) {
        $ncyc = 'MAX';
    }
    elsif ( $in =~ /\s*inf/i ) {
        $ncyc = 'INF';
    }
    elsif ( $in =~ /\s*(\d+)/ ) {
        $ncyc = $1;

        my $f = $self->get_frequency( { read_mode => 'cache' } );
        my $s = $self->get_shape( { read_mode => 'cache' } );

        my $nmax = 50000;
        $nmax = int( 500 * $f ) if $f <= 100;
        my $nmin = 1;
        if ( $s eq 'SIN' || $s eq 'SQU' || $s eq 'USER' ) {
            if ( $f <= 1e6 ) {
                $nmin = 1;
            }
            elsif ( $f <= 2e6 ) {
                $nmin = 2;
            }
            elsif ( $f <= 3e6 ) {
                $nmin = 3;
            }
            elsif ( $f <= 4e6 ) {
                $nmin = 4;
            }
            elsif ( $f < 5e6 ) {
                $nmin = 5;
            }
        }

        if ( $ncyc < $nmin || $ncyc > $nmax ) {
            Lab::Exception::CorruptParameter->throw(
                "Burst count '$in' out of range\n");
            return;
        }
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing burst count '$in'\n");
        return;
    }

    $self->write("BM:NCYC $ncyc");
}


sub get_burst_phase {
    my $self = shift;
    return $self->query("BM:PHAS?");
}


sub set_burst_phase {
    my $self = shift;
    my $in   = shift;
    my $ph   = _parseNRf( $in, 'deg' );

    if ( $ph =~ /^ERR:/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing burst phase '$in' $ph\n");
        return;
    }

    if ( $ph ne 'MIN' && $ph ne 'MAX' ) {
        $ph = sprintf( "%.3f", $ph );
        if ( $ph < -360 || $ph > 360 ) {
            Lab::Exception::CorruptParameter->throw(
                "Burst phase '$in' out of range -360..360\n");
            return;
        }
    }

    $self->write("BM:PHAS $ph");
}


sub get_burst_rate {
    my $self = shift;
    return $self->query("BM:INT:RATE?");
}


sub set_burst_rate {
    my $self = shift;
    my $in   = shift;

    my $f = _parseNRf( $in, 'Hz' );

    if ( $f =~ /^ERR:/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Burst rate parse '$in' $f\n");
        return;
    }

    if ( $f ne 'MIN' && $f ne 'MAX' ) {
        if ( $f < 10e-3 || $f > 50e3 ) {
            Lab::Exception::CorruptParameter->throw(
                "Burst rate '$in' out of range 10mHz..50kHz\n");
            return;
        }
    }
    $self->write("BM:INT:RATE $f");
}


sub get_burst_source {
    my $self = shift;
    return $self->query("BM:SOUR?");
}


sub set_burst_source {
    my $self = shift;
    my $in   = shift;
    my $s;
    if ( $in =~ /^\s*IN/i ) {
        $s = 'INT';
    }
    elsif ( $in =~ /^\s*EX/i ) {
        $s = 'EXT';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid burst source '$in', should be INT or EXT\n");
        return;
    }
    $self->write("BM:SOUR $s");
}


sub get_fsk_frequency {
    my $self = shift;
    return $self->query("FSK:FREQ?");
}


sub set_fsk_frequency {
    my $self = shift;
    my $in   = shift;

    my $f = _parseNRf( $in, 'Hz' );

    if ( $f =~ /^ERR:/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid FSK hop frequency '$in' $f\n");
        return;
    }

    if ( $f ne 'MIN' && $f ne 'MAX' ) {
        my $s = $self->get_shape( { read_mode => 'cache' } );
        my $fmax = 15e6;
        $fmax = 100e3 if $s eq 'TRI' || $s eq 'RAMP';
        if ( $f < 10e-3 || $f > $fmax ) {
            Lab::Exception::CorruptParameter->throw(
                "FSK hop frequency '$in' out of range\n");
            return;
        }
    }
    $self->write("FSK:FREQ $f");
}


sub get_fsk_rate {
    my $self = shift;
    return $self->query("FSK:INT:RATE?");
}


sub set_fsk_rate {
    my $self = shift;
    my $in   = shift;

    my $f = _parseNRf( $in, 'Hz' );

    if ( $f =~ /^ERR:/ ) {
        Lab::Exception::CorruptParameter->throw("FSK rate parse '$in' $f\n");
        return;
    }

    if ( $f ne 'MIN' && $f ne 'MAX' ) {
        if ( $f < 10e-3 || $f > 50e3 ) {
            Lab::Exception::CorruptParameter->throw(
                "FSK rate '$in' out of range 10mHz..50kHz\n");
            return;
        }
    }
    $self->write("FSK:INT:RATE $f");
}


sub get_fsk_source {
    my $self = shift;
    return $self->query("FSK:SOUR?");
}


sub set_fsk_source {
    my $self = shift;
    my $in   = shift;
    my $s;
    if ( $in =~ /^\s*IN/i ) {
        $s = 'INT';
    }
    elsif ( $in =~ /^\s*EX/i ) {
        $s = 'EXT';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid FSK source '$in', should be INT or EXT\n");
        return;
    }
    $self->write("FSK:SOUR $s");
}


sub get_sweep_start_frequency {
    my $self = shift;
    return $self->query("FREQ:STAR?");
}


sub get_sweep_stop_frequency {
    my $self = shift;
    return $self->query("FREQ:STOP?");
}


sub set_sweep_start_frequency {
    my $self = shift;
    my $in   = shift;

    my $f = _parseNRf( $in, 'Hz' );

    if ( $f =~ /^ERR:/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid SWEEP start frequency '$in' $f\n");
        return;
    }

    if ( $f ne 'MIN' && $f ne 'MAX' ) {
        if ( $f < 10e-3 || $f > 15e6 ) {
            Lab::Exception::CorruptParameter->throw(
                "SWEEP start frequency '$in' out of range (10mHz..15MHz)\n");
            return;
        }
    }
    $self->write("FREQ:STAR $f");
}


sub set_sweep_stop_frequency {
    my $self = shift;
    my $in   = shift;

    my $f = _parseNRf( $in, 'Hz' );

    if ( $f =~ /^ERR:/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid SWEEP stop frequency '$in' $f\n");
        return;
    }

    if ( $f ne 'MIN' && $f ne 'MAX' ) {
        if ( $f < 10e-3 || $f > 15e6 ) {
            Lab::Exception::CorruptParameter->throw(
                "SWEEP stop frequency '$in' out of range (10mHz..15MHz)\n");
            return;
        }
    }
    $self->write("FREQ:STOP $f");
}


sub get_sweep_spacing {
    my $self = shift;
    return $self->query("SWE:SPAC?");
}


sub set_sweep_spacing {
    my $self = shift;
    my $in   = shift;
    my $s;

    if ( $in =~ /^\s*LIN/i ) {
        $s = 'LIN';
    }
    elsif ( $in =~ /^\s*LOG/i ) {
        $s = 'LOG';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "invalid SWEEP spacing '$in', should be LIN or LOG\n");
        return;
    }
    $self->write("SWE:SPAC $s");
}


sub get_sweep_time {
    my $self = shift;
    return $self->query("SWE:TIME?");
}


sub set_sweep_time {
    my $self = shift;
    my $in   = shift;

    my $t = _parseNRf( $in, 's' );
    if ( $t =~ /ERR/i ) {
        Lab::Exception::CorruptParameter->throw(
            "Parse error in sweep time '$in': $t\n");
        return;
    }
    if ( $t ne 'MIN' && $t ne 'MAX' ) {
        if ( $t < 1e3 || $t > 500 ) {
            Lab::Exception::CorruptParameter->throw(
                "SWEEP time '$in' out of range (1ms..500s)\n");
            return;
        }
    }
    $self->write("SWE:TIME $t");
}

# parse a delimited set of strings, return an array of the strings

sub _parseStrings($) {
    my $str = shift;
    $str =~ s/^\s+//;
    $str .= ' ,' if $str !~ /,\s*$/;
    my $x;
    my (@results) = ();

    while ( $str ne '' ) {
        if ( $str =~ /^\"(([^\"]|\"\")+)\"\s*,/i ) {
            $x = $1;
            $x =~ s/\"\"/"/g;
            $str = $POSTMATCH;
            push( @results, $x );
        }
        elsif ( $str =~ /^\'(([^\']|\'\')+)\'\s*,/i ) {
            $x = $1;
            $x =~ s/\'\'/'/g;
            $str = $POSTMATCH;
            push( @results, $x );
        }
        elsif ( $str =~ /^([^,]*[^,\s])\s*,/i ) {
            $x   = $1;
            $str = $POSTMATCH;
            push( @results, $x );
        }
        else {
            carp("problems parsing strings '$str'");
            last;
        }
        $str =~ s/^\s+//;
    }
    return (@results);
}

# parse a GPIB number with suffix, units
# $result = _parseNRf($numberstring,$unit1[,$unit2,...])
# _parseNRf('maximum','foo) -> 'MAX'
# _parseNRf('-3.7e+3kJ','j') -> -3.7e6
# _parseNRf('2.3ksec','s','sec') -> 2300   ('s' and 'sec' alternate units)
# note special cases for suffixes: MHZ, MOHM, MA
# if problem, string returned starts 'ERR: ..message...'
# see IEEE std 488-2 7.7.3

sub _parseNRf($\[$@];@) {
    my $in = shift;
    $in = shift if ref($in) eq 'HASH';    # $self->_parseNRf handling...
    my $un = shift;
    $un = '' unless defined $un;
    my $us;

    if ( ref($un) eq 'ARRAY' ) {
        $us = $un;
    }
    elsif ( ref($un) eq 'SCALAR' ) {
        $us = [ $$un, @_ ];
    }
    elsif ( ref($un) eq '' ) {
        $us = [ $un, @_ ];
    }
    my $str = $in;

    $str =~ s/^\s+//;
    $str =~ s/\s+$//;

    if ( $str =~ /^MIN/i ) {
        return 'MIN';
    }
    if ( $str =~ /^MAX/i ) {
        return 'MAX';
    }

    my $mant = 0;
    my $exp  = 0;
    if ( $str =~ /^([+\-]?(\d+\.\d*|\d+|\d*\.\d+))\s*/i ) {
        $mant = $1;
        $str  = $POSTMATCH;
        return $mant if $str eq '';
        if ( $str =~ /^e\s*([+\-]?\d+)\s*/i ) {
            $exp = $1;
            $str = $POSTMATCH;
        }
        return $mant * ( 10**$exp ) if $str eq '';

        my $kexp = $exp;
        my $kstr = $str;
        foreach my $u ( @{$us} ) {
            $u =~ s/^\s+//;
            $u =~ s/\s+$//;

            $str = $kstr;
            $exp = $kexp;
            if ( $u =~ /^db/i ) {    # db(magnitude_suffix)?(V|W|... unit)?
                my $dbt = $POSTMATCH;
                if ( $str =~ /^dBex(${dbt})?$/i ) {
                    $exp += 18;
                }
                elsif ( $str =~ /^dBpe(${dbt})?$/i ) {
                    $exp += 15;
                }
                elsif ( $str =~ /^dBt(${dbt})?$/i ) {
                    $exp += 12;
                }
                elsif ( $str =~ /^dBg(${dbt})?$/i ) {
                    $exp += 9;
                }
                elsif ( $str =~ /^dBma(${dbt})$/i ) {
                    $exp += 6;
                }
                elsif ( $str =~ /^dBk(${dbt})?$/i ) {
                    $exp += 3;
                }
                elsif ( $str =~ /^dBm(${dbt})?$/i ) {
                    $exp -= 3;
                }
                elsif ( $str =~ /^dBu(${dbt})?$/i ) {
                    $exp -= 6;
                }
                elsif ( $str =~ /^dBn(${dbt})?$/i ) {
                    $exp -= 9;
                }
                elsif ( $str =~ /^dBp(${dbt})?$/i ) {
                    $exp -= 12;
                }
                elsif ( $str =~ /^dBf(${dbt})?$/i ) {
                    $exp -= 15;
                }
                elsif ( $str =~ /^dB${dbt}$/i ) {
                    $exp += 0;
                }
                else {
                    next;
                }
            }
            else {    # regular units stuff: (magnitude_suffix)(unit)?
                if ( $str =~ /^ex(${u})?$/i ) {
                    $exp += 18;
                }
                elsif ( $str =~ /^pe(${u})?$/i ) {
                    $exp += 15;
                }
                elsif ( $str =~ /^t(${u})?$/i ) {
                    $exp += 12;
                }
                elsif ( $str =~ /^g(${u})?$/i ) {
                    $exp += 9;
                }
                elsif ( $u =~ /(HZ|OHM)/i && $str =~ /^ma?(${u})$/i ) {
                    $exp += 6;
                }
                elsif ( $u =~ /A/i && $str =~ /^ma$/i ) {
                    $exp -= 3;
                }
                elsif ( $u !~ /(HZ|OHM)/i && $str =~ /^ma(${u})?$/i ) {
                    $exp += 6;
                }
                elsif ( $str =~ /^k(${u})?$/i ) {
                    $exp += 3;
                }
                elsif ( $str =~ /^m(${u})?$/i ) {
                    $exp -= 3;
                }
                elsif ( $str =~ /^u(${u})?$/i ) {
                    $exp -= 6;
                }
                elsif ( $str =~ /^n(${u})?$/i ) {
                    $exp -= 9;
                }
                elsif ( $str =~ /^p(${u})?$/i ) {
                    $exp -= 12;
                }
                elsif ( $str =~ /^f(${u})?$/i ) {
                    $exp -= 15;
                }
                elsif ( $str =~ /^${u}$/i ) {
                    $exp += 0;
                }
                else {
                    next;
                }
            }
            return $mant * ( 10**$exp );
        }
    }
    return "ERR: '$str' number parsing problem";

}

1;    # End of Lab::Instrument::HP33120A

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::HP33120A - HP 33120A 15MHz function/arbitrary waveform generator (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

    use Lab::Instrument::HP33120A;

    my $g = new Lab::Instrument::HP33120A (
                connection_type => 'LinuxGPIB',
                gpib_address => 10
               );
    $g->set_frequency('3.78kHz');
    $g->set_shape('square');

    ...

=head1 Getting started, system control

=head2 new

$g = new Lab::Instrument::HP33120A->(%options);

      options:  gpib_board => 0,
                gpib_address => 10,
                connection_type => 'LinuxGPIB',
                no_cache => 1,  # turn off cache

=head2 get_id

$id = $g->get_id();

reads the *IDN? string from device

=head2 get_status

%status = $g->get_status();

return a hash with status bits
{ ERROR => .., DATA=> .. 

=head2 get_error

$errmsg = $g->get_error();

Fetch the first error in the error queue.  Returns
($code,$message); code == 0 means 'no error'

=head2 reset

$g->reset();

reset the function generator (*RST, *CLS)

=head2 get_trigger_slope

$slope = $g->get_trigger_slope();

fetch the trigger slope, returns POS or NEG

=head2 set_trigger_slope

$g->set_trigger_slope($slope);

set the slope of the signal used to trigger
$slope = 'POS','+' or 'NEG','-'

=head2 wait_complete

$g->wait_complete();

Wait for operations to be completed

TODO: probably need to revise, with a *OPC? checking loop

=head2 trigger

$g->trigger();

Send a bus trigger to the function generator, wait 
until trigger complete.

=head2 get_trigger_source

$src = $g->get_trigger_source();

fetch the 'trigger source' from the function generator.
Possible values are 'IMM', 'BUS' or 'EXT'.  IMM => immediate
self-triggering; BUS => gpib/serial trigger input, such as *TRG;
EXT => external trigger input.

=head2 set_trigger_source

$g->set_trigger_source($src);

Set the trigger source for the function generator. Possible
values are 'IMM' (immediate, i.e., internal free-running self-trigger)
'BUS' GPIB *TRG type triggering; 'EXT' trigger from external input.

=head2 set_display

$g->set_display(BOOL);

turn the display off (BOOL = false) or on (BOOL = true)

=head2 get_display

$display_on = $g->get_display();

get the state of the display (boolean)

=head2 set_text

$g->set_text("text to show");

display text on the function generator, in the place
of the usual voltage/frequency/etc. Text is truncated
at 11 chars, comma, semicolon, period are combined with
char, so not counted in length

=head2 get_text

$mytext = $g->get_text();

fetches the text shown on the display with set_text

=head2 clear_text

$g->clear_text();

remove the text from the display

=head2 beep

$g->beep();

Cause the function generator to 'beep'

=head2 get_sync

$sync = $g->get_sync();

fetch boolean value indicating whether 'sync' output on the
front panel is enabled

=head2 set_sync

$g->set_sync($sync);

enable or disable SYNC output on front panel. $sync is
a boolean (1/true/yes/on) => sync output enabled

=head2 save_setup

$g->save_setup($n);

save function generator setup to internal non-volatile
memory.  $n = 0..3.  

NOTE: $n=0 is overwritten by the 'current
setup' when the generator is turned off.

=head2 recall_setup

$g->recall_setup($n);

restore function generator configuration from internal 
non-volatile memory. $n=0..3

=head2 delete_setup

$g->delete_setup($n);

delete one of the internal non-volatile setups
$n=0..3

=head2 get_load

$zload = $g->get_load();

fetch the output load impedance of the generator. Possible 
values are '50' and 'INF'. This does NOT make any physical
changes in the generator, but affects the internal calculation
of amplitudes.

=head2 set_load

$g->set_load($z);

Tell the function generator what load impedance the output
is being terminated to, so that other characteristics can be
correctly calculated.  Possible values are '50', 'INF', 'MIN', 'MAX'
(can also use '50ohm', '0.05kohm', etc)

=head1 Basic waveform output routines

=head2 get_shape

$shape = $g->get_shape();

returns the waveform shape = SIN|SQU|TRI|RAMP|USER

=head2 set_shape

$g=>set_shape($shape);

Sets the output function shape = SIN|SQU|TRI|RAMP|USER
USER = arbitary waveform, separately selected

=head2 get_frequency

$f = $g->get_frequency();

reads the function generator frequency, in Hz

=head2 set_frequency

$g->set_frequency($f);

sets the function generator frequency in Hz. The
frequency limits are 10mHz to 15MHz . The frequency
can be specified as a simple number (in Hz), MIN, MAX
or a string in standard IEEE488-2 NRf format. 
NOTE: if you use the  Hz unit, the standard is
to interpret mHz as megahertz. 

=over

set_frequency(10)    10Hz

set_frequency('0.01kHz')  10Hz

set_frequency('1mHz')    1E6 Hz

set_frequency('10m')     10e-3 Hz (note, without Hz, `m' means `milli')

=back

The upper frequency limit depends on the function shape

=head2 get_duty_cycle

$dc = $g->get_duty_cycle()'

fetch the duty cycle, in percent; only relevent for
square waves

=head2 set_duty_cycle

$g->set_duty_cycle(percent);

sets the square wave duty cycle,  in percent. The available
range depends on frequency, so percent = 20..80 for  <= 5MHz
and percent = 40..60 for higher frequencies

=head2 get_amplitude

$vamp = $g->get_amplitude();

fetch the function amplitude, default is amplitude in volts 
peak-to-peak (Vpp), but depending on the  units setting
[see get_vunit()], so might be Vrms or dBm.

=head2 set_amplitude

$g->set_amplitude($vamp);

sets the function amplitude,  in units from the 
set_vunit() call, defaults to Vpp.

The amplitude can be either a number,
or string with magnitude (and optionally, units), 
MAX or MIN.

Examples: `100uV', `50mV', `123E-3', `20dBm', `5.5E1dBmV'.

NOTE: attaching units with $vamp does not change vunit,
so if vunit=`VPP' and you set $vamp=`5.5e1dBmV', you'll
get 55mVpp. 

The minimum and maximum
amplitudes depend on the output load selection,
the function shape, and the DC offset.

Max output voltage is +-20V into a high-Z load,
+-10V into 50 ohm load.

TODO: automatically adjust units based on 
input text: 4Vpp, 3.5Vrms, 7.3dbm ...

Since limits are rather hard to determine, you should
check for errors after setting.

=head2 get_vunit

$unit = $g->get_vunit()

Fetch the units that are being used to specify the output amplitude
Possible values are VPP, VRMS, DBM, or DEF (default, VPP)

=head2 set_vunit

$g->set_vunit($unit);

Set the way that amplitudes are specified. Possible 
values are Vpp, Vrms, dBm or DEF (default = Vpp)

=head2 get_offset

$voff = $g->get_offset();

Get the DC offset in volts (not affected by vunit)

=head2 set_offset

$g->set_offset($voff);

Set the DC offset, either as a number (volts), as a string
'100mV', '0.01kV' '1e3u', MIN or MAX.  The specification of
the DC offset is not affected by the selection of vunit.

Note that the DC offset is limited in combination with the
output load, amplitude, and function shape. 

=head1 Arbitrary 'user' waveforms

=head2 get_waveform_list

@list = $g->get_waveform_list();

Get a list of the available 'user' waveforms. Five of these
are built-in, up to four are user-storable in non-volatile
memory, and possibly VOLATILE for a waveform in volatile memory

The names of the five built-in arbitrary waveforms are:
SINC, NEG_RAMP, EXP_RISE, EXP_FALL, and CARDIAC.

=head2 get_user_waveform

$wname = $g->get_user_waveform();

Fetches the name of the currently selected 'user' waveform.

=head2 set_user_waveform

$g->set_user_waveform($wname);

Sets the name of the current 'user' waveform. This
should be a name from the $g->get_waveform_list()
set of nonvolatile waveforms, or 'VOLATILE'.

=head2 load_waveform

$g->load_waveform(...);

store waveform as 'volatile' data (can be used by selecting 'volatile'
user waveform) perhaps for persistant storage.

=over

load_waveform(v1,v2,v3...)   voltages   |v(j)| <= 1

load_waveform(d1,d2,d3...)   DAC values |d(j)| < 2048

load_waveform(\@array)       voltages or DAC values

load_waveform(waveform=>[voltage array ref]);

load_waveform(dac=>[DAC array ref]);

=back

number of data points 8..16000

In the first three cases above, where it is not specified "voltage"
or "DAC" values, it is assumed to be voltages if the quantities are
within the range -1..+1, and otherwise assumed to be DAC values. 

=head2 get_waveform_average

$vavg = $g->get_waveform_average($name);

calculates and returns the 'average voltage' of 
waveform $name (nonvolatile stored waveform, or VOLATILE)

=head2 get_waveform_crestfactor

$vcr = $g->get_waveform_crestfactor($name);

calculates and returns the voltage 'crest factor' 
(ratio of Vpeak/Vrms) for the waveform stored in $name.

=head2 get_waveform_points

$npts = $g->get_waveform_points($name)
Returns the number of points in the waveform $name

=head2 get_waveform_peak2peak

$vpp = $g->get_waveform_peak2peak($name);

calculates and returns the peak-to-peak voltage
of waveform $name

=head2 store_waveform

$g->store_waveform($name);

Stores the waveform in VOLATILE to non-volatile
memory as $name.  Note that $name cannot be one
of the 'hard-coded' names, is a maximum of 8 characters
in length, must start with a-z, and contain only
alphanumeric and underscore (_) characters. All
names are converted to uppercase.

There is memory for 4 user waveforms to be stored, 
after which some must be deleted to allow further
storage.

=head2 delete_waveform

$g->delete_waveform($name);

Delete one of the non-volatile user waveforms (or VOLATILE).
Note that the 5 'built-in' user waveforms cannot be deleted.

=head2 get_waveform_free

$n = $g->get_waveform_free();

returns the number of 'free' user waveform storage 
areas (0..4) that can be used for $g->store_waveform

=head1 Modulation

=head2 get_modulation

$mod = $g->get_modulation();

Fetch the type of modulation being used: NONE,AM,FM,BURST,FSK,SWEEP

=head2 set_modulation

$g->set_modulation($mod);

Set the type of modulation to use: NONE,AM,FM,BURST,FSK,SWEEP
if $mod='' or 'off', selects NONE.

=head2 set_am_depth

$g->set_am_depth(percent);

set AM modulation depth percent: 0..120, MIN, MAX

=head2 get_am_depth

$depth = $g->get_am_depth();

get the AM modulation depth, in percent

=head2 get_am_shape

$shape = $g->get_am_shape();

gets the waveform used for AM modulation
returns $shape = (SIN|SQU|TRI|RAMP|NOIS|USER)

=head2 set_am_shape

$g->set_am_shape($shape);

sets the waveform used for AM modulation
$shape = (SIN|SQU|TRI|RAMP|NOIS|USER)

=head2 get_am_frequency

$freq = $g->get_am_frequency();

get the frequency of the AM modulation

=head2 set_am_frequency

$g->set_am_frequency($f);

sets the frequency of AM modulation 
$f = value in Hz,  10mHz..20kHz, MIN, MAX

Note that $f can be a string, with suffixes, and that 
'mHz' suffix -> MEGAHz   'm' suffix with no 'Hz' -> millihertz

=head2 get_am_source

$source = $g->get_am_source();

get the source of the AM modulation signal: BOTH|EXT

=head2 set_am_source

$g->set_am_source(BOTH|EXT);

set the source of the AM modulation; BOTH = internal+external
EXT = external only.   INT = translated to BOTH

=head2 get_fm_deviation

$dev = $g->get_fm_deviation();

fetch the FM modulation deviation, in Hz

=head2 set_fm_deviation

$g->set_fm_deviation($dev);

Set the FM modulation deviation in Hz. $dev can be a simple
number, in Hz, or a string with suffixes, or MIN or MAX.

Ex: $dev='10.3kHz'  $dev='1.2MHZ' $dev='200m'
NOTE: MHZ -> megahertz (case independent). A simple 'm' suffix => millihertz

dev range 10mHz .. 7.5MHz
carrier frequency must be >= deviation frequency
carrier + deviation < peak frequency for carrier waveform + 100kHz
So: 15.1MHz for sine and square
200kHz for triangle and ramp
5.1MHz for 'user' waveforms

=head2 get_fm_shape

$shape = $g->get_fm_shape();

gets the waveform used for FM modulation
returns $shape = (SIN|SQU|TRI|RAMP|NOIS|USER)

=head2 set_fm_shape

$g->set_fm_shape($shape);

sets the waveform used for FM modulation
$shape = (SIN|SQU|TRI|RAMP|NOIS|USER)

NOTE: NOISE and DC cannot be used as FM carrier

=head2 get_fm_frequency

$freq = $g->get_fm_frequency();

get the frequency of the FM modulation, in Hz

=head2 set_fm_frequency

$g->set_fm_frequency($f);

sets the frequency of AM modulation 
$f = value in Hz,  10mHz..10kHz, MIN, MAX

Note that $f can be a string with the usual suffixes,
but XmHz -> X megahz   Xm-> X millihz

=head2 get_burst_cycles

$ncyc = $g->get_burst_cycles();

Fetch the number of cycles in burst modulation

=head2 set_burst_cycles

$g->set_burst_cycles($ncyc);

Set the number of cycles in burst modulation. 
$ncyc is an integer 1..50,000  or MIN or MAX or INF

For SIN, SQU, or USER waveform shapes, the minumim number of cycles
is related to the carrier frequency.
<= 1MHz   min 1 cycle
1..2MHz   min 2 cycles
2..3MHz   min 3 cycles
3..4MHz   min 4 cycles
4..5MHz   min 5 cycles

For carrier frequency <= 100Hz, cycles <= 500sec * carrier freq

=head2 get_burst_phase

$ph = $g->get_burst_phase();

Fetches the starting phase of the burst, in degrees, when
bursts are triggered. 

=head2 set_burst_phase

$g->set_burst_phase($ph);

Sets the starting phase of burst, in degrees (or MIN or MAX)
from -360 to 360 in 0.001 degree increments.

phase examples: 30.1, '20deg', 'min', 'max'

=head2 get_burst_rate

$rate = $g->get_burst_rate();

Fetch the burst rate (in Hz) for internally triggered bursts

=head2 set_burst_rate

$g->set_burst_rate($rate);

Set the burst rate (in Hz) for internally triggered bursts.
$rate can be a simple number, or a string with the usual
suffixes.  Note that 'mHz' (case independent) -> megahertz
while 'm' -> millihertz.   Rate 10mHz .. 50kHz  or MIN or MAX

If the burst rate is too large for the carrier frequency and
burst count, the function generator will (silently) adjust to
continually retrigger.

=head2 get_burst_source

$source = $g->get_burst_source();

Fetch the source of the burst modulation: INT or EXT

=head2 set_burst_source

$g->set_burst_source($source);

Set the source of burst modulation: $source = 'INT' or 'EXT'.
If source is external, burst cycle count, rate, are ignored.

=head2 get_fsk_frequency

$freq = $g->get_fsk_frequency();

get the FSK 'hop' frequency, in Hz

=head2 set_fsk_frequency

$g->set_fsk_frequency($f);

sets the FSK 'hop' frequency 
$f = value in Hz,  10mHz..15MHz, MIN, MAX
(max freq 100kHz for TRIANGLE and RAMP shapes)

Note that $f can be a string with the usual suffixes,
but XmHz -> X megahz   Xm-> X millihz

=head2 get_fsk_rate

$rate = $g->get_fsk_rate();

Fetch the rate at which fsk shifts between frequencies (in Hz) for 
internally triggered modulation.

=head2 set_fsk_rate

$g->set_fsk_rate($rate);

Set the rate for fsk shifting between frequencies (in Hz) for 
internally triggered modulation.

$rate can be a simple number, or a string with the usual
suffixes.  Note that 'mHz' (case independent) -> megahertz
while 'm' -> millihertz.   Rate 10mHz .. 50kHz  or MIN or MAX

=head2 get_fsk_source

$source = $g->get_fsk_source();

Fetch the source of the FSK modulation: INT or EXT

=head2 set_fsk_source

$g->set_fsk_source($source);

Set the source of FSK modulation: $source = 'INT' or 'EXT'.
If source is external, FSK rate is ignored.

=head2 get_sweep_start_frequency

$g->get_sweep_start_frequency();

Fetch the starting frequency of the sweep, in Hz

=head2 get_sweep_stop_frequency

$g->get_sweep_stop_frequency();

Fetch the stopping frequency of the sweep, in Hz

=head2 set_sweep_start_frequency

$g->set_sweep_start_frequency($f);

sets the frequency sweep  starting frequency 
$f = value in Hz,  10mHz..15MHz, MIN, MAX

Note that $f can be a string with the usual suffixes,
but XmHz -> X megahz   Xm-> X millihz

if fstart>fstop, sweep decreases in frequency;
if fstart<fstop, sweep increases in frequency.

=head2 set_sweep_stop_frequency

$g->set_sweep_stop_frequency($f);

sets the frequency sweep  stopping frequency 
$f = value in Hz,  10mHz..15MHz, MIN, MAX

Note that $f can be a string with the usual suffixes,
but XmHz -> X megahz   Xm-> X millihz

if fstart>fstop, sweep decreases in frequency;
if fstart<fstop, sweep increases in frequency.

=head2 get_sweep_spacing

$spc = $g->get_sweep_spacing();

Fetches the sweep 'spacing', returns 'LIN' or 'LOG' for linear
or logarithmic spacing.

=head2 set_sweep_spacing

$g->set_sweep_spacing($spc);

Sets sweep to either LIN or LOG spacing

=head2 get_sweep_time

$time = $g->get_sweep_time();

Fetch the time (in seconds) to sweep from starting to stopping frequency.

=head2 set_sweep_time

$g->set_sweep_time($time);

Sets the time to sweep between starting and stopping frequencies. The
number of frequencies steps is internally calculated by the function
generator.

$time can be a simple number (in seconds) or a string with
suffices such as "5ms" "0.03ks", or MIN or MAX. The range of sweep
times is 1ms .. 500s

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Charles Lane, Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
