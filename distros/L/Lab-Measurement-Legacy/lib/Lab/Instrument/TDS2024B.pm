package Lab::Instrument::TDS2024B;
#ABSTRACT: Tektronix TDS2024B digital oscilloscope
$Lab::Instrument::TDS2024B::VERSION = '3.899';
use v5.20;

use strict;
use warnings;
use Lab::Instrument;
use Lab::SCPI;
use Carp;
use English;
use Time::HiRes qw(sleep);
use Clone 'clone';
use Data::Dumper;

our $DEBUG   = 0;
our @ISA     = ("Lab::Instrument");
our %fields  = (
    supported_connections => ['USBtmc'],

    #default settings for connections

    connection_settings => {
        connection_type => 'USBtmc',
        usb_vendor      => 0x0699,     #Tektronix
        usb_product     => 0x036a,     #TDS2024A
        usb_serial      => '*',        #any serial number
	read_buffer     => 1024,
    },

    device_settings => {},

    # too many characteristics can easily be "messed with" on the front
    # panel, so only allow changes when scope is "locked".

    device_cache => {},

    chan_cache         => {},
    default_chan_cache => {
        channel            => undef,
        chan_bwlimit       => undef,
        chan_coupling      => undef,
        chan_current_probe => undef,
        chan_invert        => undef,
        chan_position      => undef,
        chan_probe         => undef,
        chan_scale         => undef,
        chan_yunit         => undef,
        select             => undef,
    },

    # non-front-panel cache items
    NFP => [
        qw(
            ID
            HEADER
            VERBOSE
            LOCKED
            )
    ],

    shared_cache => {
        ID                => undef,
        HEADER            => undef,
        VERBOSE           => undef,
        LOCKED            => undef,
        acquire_mode      => undef,
        acquire_numavg    => undef,
        acquire_stopafter => undef,

        autorange_settings => undef,
        cursor_type        => undef,
        cursor_x1          => undef,
        cursor_x2          => undef,
        cursor_y1          => undef,
        cursor_y2          => undef,
        cursor_xunits      => undef,
        cursor_yunits      => undef,
        cursor_source      => undef,

        data_encoding    => undef,
        data_destination => undef,
        data_source      => undef,
        data_start       => undef,
        data_stop        => undef,
        data_width       => undef,

        display_contrast => undef,
        display_format   => undef,
        display_persist  => undef,
        display_style    => undef,
        hardcopy_format  => undef,
        hardcopy_layout  => undef,
        hardcopy_port    => undef,

        meas_source_imm => undef,
        meas_type_imm   => undef,
        meas_units_imm  => undef,

        meas_source_1 => undef,
        meas_type_1   => undef,
        meas_units_1  => undef,

        meas_source_2 => undef,
        meas_type_2   => undef,
        meas_units_2  => undef,

        meas_source_3 => undef,
        meas_type_3   => undef,
        meas_units_3  => undef,

        meas_source_4 => undef,
        meas_type_4   => undef,
        meas_units_4  => undef,

        meas_source_5 => undef,
        meas_type_5   => undef,
        meas_units_4  => undef,

        horiz_view     => undef,
        horiz_position => undef,
        horiz_scale    => undef,
        delay_position => undef,
        delay_scale    => undef,

        math_definition => undef,
        math_position   => undef,
        math_scale      => undef,
        fft_xposition   => undef,
        fft_xscale      => undef,
        fft_position    => undef,
        fft_scale       => undef,

        trig_type    => undef,
        trig_holdoff => undef,
        trig_mode    => undef,
        trig_level   => undef,

        etrig_source  => undef,
        trig_slope    => undef,
        trig_coupling => undef,

        ptrig_source        => undef,
        trig_pulse_width    => undef,
        trig_pulse_polarity => undef,
        trig_pulse_when     => undef,

        vtrig_source      => undef,
        trig_vid_line     => undef,
        trig_vid_polarity => undef,
        trig_vid_standard => undef,
        trig_vid_sync     => undef,

    },

    channel => undef,

    scpi_override => {
        ACQuire => {
            NUMACq    => undef,
            NUMAVg    => undef,
            STATE     => undef,
            STOPAfter => undef,
        },
        AUTORate => {
            STATE => undef,
        },
        AUTOScale => {

            #	'' => undef;
            SIGNAL => undef,
        },
        LOCk => undef,
        CH   => {
            BANDWIDth    => undef,
            CURRENTPRObe => undef,
            PRObe        => undef,
            SCAle        => undef,
            VOLt         => undef,
        },

        CURSor => {
            HBArs => {
                UNIts    => undef,
                POSITION => undef,
            },
            VBArs => {
                UNIts    => undef,
                POSITION => undef,
            },
            SELect => {
                SOUrce => undef,
            },
        },
        CURVe => undef,
        DATa  => {
            ENCdg  => undef,
            SOUrce => undef,
            TARget => undef,
            WIDth  => undef,
        },
        DISplay => {
            CONTRast => undef,
            STYle    => undef,
        },

        FILESystem => {
            DELEte    => undef,
            FREESpace => undef,
        },

        HARDCopy => {
            BUTTON => undef,
        },

        HORizontal => {
            SCAle        => undef,
            SECdiv       => undef,
            RECOrdlength => undef,
            MAIn         => {
                SCAle  => undef,
                SECdiv => undef,
            },
            DELay => {
                SCAle  => undef,
                SECdiv => undef,
            },
        },

        MATH => {
            DEFINE => undef,
            FFT    => {
                HORizontal => {
                    SCAle => undef,
                },
                VERtical => {
                    SCAle => undef,
                },
            },
            VERtical => {
                SCAle => undef,
            },
        },

        MEASUrement => {
            IMMed => {
                TYPe   => undef,
                UNIts  => undef,
                SOUrce => undef,
            },
            MEAS => {
                TYPe   => undef,
                UNIts  => undef,
                SOUrce => undef,
            },
        },

        TRIGger => {
            MAIn => {
                EDGE => {
                    SLOpe  => undef,
                    SOUrce => undef,
                },
                HOLDOff => {
                    VALue => undef,
                },
                MODe  => undef,
                TYPe  => undef,
                PULse => {
                    SOUrce => undef,
                    WIDth  => {
                        WIDth => undef,
                    },
                },
                VIDeo => {
                    SOUrce => undef,
                },
            },
            STATE => undef,
        },

        WFMPre => {
            BIT_Nr => undef,
            BYT_Nr => undef,
            BYT_Or => undef,
            ENCdg  => undef,
            PT_Off => undef,
            WFId   => undef,
            XINcr  => undef,
            XUNit  => undef,
            XZEro  => undef,
            YMUlt  => undef,
            YOFf   => undef,
            YUNit  => undef,
            YZEro  => undef,
            CH     => {
                WFId  => undef,
                XINcr => undef,
                XUNit => undef,
                XZEro => undef,
                YMUlt => undef,
                YOFf  => undef,
                YUNit => undef,
                YZEro => undef,
            },
            MATH => {
                WFId  => undef,
                XINcr => undef,
                XUNit => undef,
                XZEro => undef,
                YMUlt => undef,
                YOFf  => undef,
                YUNit => undef,
                YZEro => undef,
            },
            REFA => {
                WFId  => undef,
                XINcr => undef,
                XUNit => undef,
                XZEro => undef,
                YMUlt => undef,
                YOFf  => undef,
                YUNit => undef,
                YZEro => undef,
            },
            REFB => {
                WFId  => undef,
                XINcr => undef,
                XUNit => undef,
                XZEro => undef,
                YMUlt => undef,
                YOFf  => undef,
                YUNit => undef,
                YZEro => undef,
            },
            REFC => {
                WFId  => undef,
                XINcr => undef,
                XUNit => undef,
                XZEro => undef,
                YMUlt => undef,
                YOFf  => undef,
                YUNit => undef,
                YZEro => undef,
            },
            REFD => {
                WFId  => undef,
                XINcr => undef,
                XUNit => undef,
                XZEro => undef,
                YMUlt => undef,
                YOFf  => undef,
                YUNit => undef,
                YZEro => undef,
            },
        },
    },
);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    foreach my $k ( keys( %{ $fields{default_chan_cache} } ) ) {
        $fields{device_cache}->{$k} = $fields{default_chan_cache}->{$k};
    }

    foreach my $k ( keys( %{ $fields{shared_cache} } ) ) {
        $fields{device_cache}->{$k} = $fields{shared_cache}->{$k};
    }

    my $self = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->{connection_settings}->{READ_BUFFER} = 1024;  # TDS2024B limit?
    $self->{config}->{no_cache}          = 1;
    $self->{config}->{default_read_mode} = 'cache';
    $DEBUG = $self->{config}->{debug} if exists $self->{config}->{debug};

    # initialize channel caches
    foreach my $ch (qw(CH1 CH2 CH3 CH4 MATH REFA REFB REFC REFD)) {
        $self->{chan_cache}->{$ch} = {};
        foreach my $k ( keys( %{ $self->{default_chan_cache} } ) ) {
            $self->{chan_cache}->{$ch}->{$k}
                = $self->{default_chan_cache}->{$k};
        }
        $self->{chan_cache}->{$ch}->{channel} = $ch;
        foreach my $k ( keys( %{ $self->{shared_cache} } ) ) {
            $self->{chan_cache}->{$ch}->{$k} = $self->{shared_cache}->{$k};
        }
    }

    $self->{device_cache} = $self->{chan_cache}->{CH1};
    $self->{channel}      = "CH1";
    return $self;
}

#initialize scope.. this means setting up status bit masking
#for non-destructive testing for device errors

sub _device_init {
    my $self = shift;
    $self->write("*ESE 60")
        ;    # 0x3C -> CME+EXE+DDE+QYE to bit 5 of SBR (read with *STB?)
    $self->write("*CLS");    # clear status registers
}

{                            # keep perl from bitching about this stuff
    no warnings qw(redefine);

    # calling argument parsing; this is an extension of the
    # _check_args and _check_args_strict routines in Instrument.pm,
    # allowing more flexibility in how routines are called.
    # In particular  routine(a=>1,b=>2,..) and
    # routine({a=>1,b=>2,..}) can both be used.

    # note: if this code does not properly recognize the syntax,
    # then you have to use the {key=>value...} form.

    # calling:
    #   ($par1,$par2,$par3,$tail) = $self->_Xcheck_args(\@_,qw(par1 par2 par3));
    # or, for compatibility:
    #   ($par1,$par2,$par3,$tail) = $self->_Xcheck_args(\@_,[qw(par1 par2 par3)]);

    sub Lab::Instrument::_check_args {
        my $self   = shift;
        my $args   = shift;
        my $params = [@_];
        $params = $params->[0] if ref( $params->[0] ) eq 'ARRAY';
        my $arguments = {};

        if ( $#{$args} == 0 && ref( $args->[0] ) eq 'HASH' ) {    # case 3
            %{$arguments} = ( %{ $args->[0] } );
        }
        else {
            my $simple = 1;
            if ( $#{$args} & 1 == 1 ) {    # must have even # arguments
                my $found = {};
                for ( my $j = 0; $j <= $#{$args}; $j += 2 ) {
                    if ( ref( $args->[$j] ) ne '' ) {    # a ref for a key? no
                        $simple = 1;
                        last;
                    }
                    foreach my $p ( @{$params} ) {       # named param
                        $simple = 0 if $p eq $args->[$j];
                    }
                    if ( exists( $found->{ $args->[$j] } ) )
                    {                                    # key used 2x? no
                        $simple = 1;
                        last;
                    }
                    $found->{ $args->[$j] } = 1;
                }
            }

            if ($simple) {                               # case 1
                my $i = 0;
                foreach my $arg ( @{$args} ) {
                    if ( defined @{$params}[$i] ) {
                        $arguments->{ @{$params}[$i] } = $arg;
                    }
                    $i++;
                }
            }
            else {                                       # case 2
                %{$arguments} = ( @{$args} );
            }
        }

        my @return_args = ();

        foreach my $param ( @{$params} ) {
            if ( exists $arguments->{$param} ) {
                push( @return_args, $arguments->{$param} );
                delete $arguments->{$param};
            }
            else {
                push( @return_args, undef );
            }
        }

        push( @return_args, $arguments );

        if (wantarray) {
            return @return_args;
        }
        else {
            return $return_args[0];
        }
    }

    sub Lab::Instrument::_check_args_strict {
        my $self   = shift;
        my $args   = shift;
        my $params = [@_];
        $params = $params->[0] if ref( $params->[0] ) eq 'ARRAY';

        my @result = $self->_check_args( $args, $params );

        my $num_params = @result - 1;

        for ( my $i = 0; $i < $num_params; ++$i ) {
            if ( not defined $result[$i] ) {
                croak("missing mandatory argument '$params->[$i]'");
            }
        }

        if (wantarray) {
            return @result;
        }
        else {
            return $result[0];
        }
    }

}
#
# utility function: check header/verbose and parse
# query reply appropriately; remove quotes in present
# ex:  $self->_parseReply('ACQ:MODE average',qw{AVE PEAK SAM})
#  gives AVE
sub _parseReply {
    my $self = shift;
    my $in   = shift;

    my $h = $self->get_header();
    if ($h) {
        my $c;
        ( $c, $in ) = split( /\s+/, $in );
        return '' unless defined($in) && $in ne '';
    }

    # remove quotes on strings
    if ( $in =~ /^\"(.*)\"$/ ) {
        $in = $1;
        $in =~ s/\"\"/"/g;
    }
    elsif ( $in =~ /^\'(.*)\'$/ ) {
        $in = $1;
        $in =~ s/\'\'/'/g;
    }

    return $in unless $#_ > -1;
    my $v = $self->get_verbose();
    return $in unless $v;
    return _keyword( $in, @_ );
}

#
# select keyword
#  example:  $got = _keyword('input', qw{ IN OUT EXT } )
#  returns $got = 'IN'

sub _keyword {
    my $in = shift;
    $in = shift if ref($in) eq 'HASH';    # dispose of $self->_keyword form...
    my $r;

    $in =~ s/^\s+//;
    foreach my $k (@_) {
        if ( $in =~ /^$k/i ) {
            return $k;
        }
    }
    Lab::Exception::CorruptParameter->throw("Invalid keyword input '$in'\n");
}

# convert 'short form' keywords to long form

sub _bloat {
    my $in = shift;
    $in = shift if ref($in) eq 'HASH';    # dispose of $self->_bloat
    my $tr = shift;                       # hash of short=>long:

    $in =~ s/^\s+//;
    $in =~ s/\s+$//;
    return $in if $in eq '';

    foreach my $k ( keys( %{$tr} ) ) {
        if ( $in =~ /^${k}/i ) {
            return $tr->{$k};
        }
    }

    return uc($in);                       # nothing matched
}

# parse a GPIB number with suffix, units
# $result = _parseNRf($numberstring,$unit1[,$unit2,...])
# _parseNRf('maximum','foo) -> 'MAX'
# _parseNRf('-3.7e+3kJ','j') -> -3.7e6
# _parseNRf('2.3ksec','s','sec') -> 2300   ('s' and 'sec' alternate units)
# note special cases for suffixes: MHZ, MOHM, MA
# also handling 'dB' -> (number)dB(magnitudesuffix)(unit V|W|etc)
#
# if problem, string returned starts 'ERR: ..message...'
# see IEEE std 488-2 7.7.3

sub _parseNRf {
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


sub reset {
    my $self = shift;
    $self->write("*RST");
    $self->_debug();
    $self->_reset_cache();
}

our $_rst_state = {
    LOCKED  => 'NON',
    HEADER  => '1',
    VERBOSE => '1',

    data_encoding    => 'RIBINARY',
    data_destination => 'REFA',
    data_source      => 'CH1',
    data_start       => 1,
    data_stop        => 2500,
    data_width       => 1,

    display_format   => 'YT',
    display_style    => 'VECTORS',
    display_persist  => 0,
    display_contrast => 50,

    acquire_mode       => 'SAMPLE',
    acquire_numavg     => 16,
    acquire_stopafter  => 'RUNSTOP',
    autorange_settings => 'BOTH',

    chan_probe         => 10,
    chan_current_probe => 10,
    chan_scale         => 1.0,
    chan_position      => 0.0,
    chan_coupling      => 'DC',
    chan_bwlimit       => 0,
    chan_invert        => 0,
    chan_yunit         => 'V',

    cursor_type        => 'OFF',
    cursor_source      => 'CH1',
    cursor_vbars_units => 'SECONDS',
    cursor_x1          => -2.0e-3,
    cursor_x2          => 2.0e-3,
    cursor_y1          => 3.2,
    cursor_y2          => -3.2,

    hardcopy_format => 'JPEG',
    hardcopy_layout => 'PORTRAIT',
    hardcopy_port   => 'USB',

    horiz_view     => 'MAIN',
    horiz_scale    => 5.0E-4,
    horiz_position => 0.0E0,
    delay_scale    => 5.0E-5,
    delay_position => 0.0E0,

    meas_type_1   => 'NONE',
    meas_source_1 => 'CH1',
    meas_units_1  => undef,

    meas_type_2   => 'NONE',
    meas_source_2 => 'CH1',
    meas_units_2  => undef,

    meas_type_3   => 'NONE',
    meas_source_3 => 'CH1',
    meas_units_3  => undef,

    meas_type_4   => 'NONE',
    meas_source_4 => 'CH1',
    meas_units_4  => undef,

    meas_type_5   => 'NONE',
    meas_source_5 => 'CH1',
    meas_units_5  => undef,

    meas_type_imm   => 'PERIOD',
    meas_source_imm => 'CH1',
    meas_units_imm  => 'S',

    math_definition => 'CH1 - CH2',
    math_position   => 0.0E0,
    math_scale      => 2.0E0,
    fft_xposition   => 5.0E1,
    fft_xscale      => 1.0E0,
    fft_position    => 0.0E0,
    fft_scale       => 1.0E0,

    trig_mode    => 'AUTO',
    trig_type    => 'EDGE',
    trig_holdoff => 5.0E-7,
    trig_level   => 0.0E0,

    etrig_source  => 'CH1',
    trig_coupling => 'DC',
    trig_slope    => 'RISE',

    vtrig_source      => 'CH1',
    trig_vid_sync     => 'LINE',
    trig_vid_polarity => 'NORMAL',
    trig_vid_line     => 1,
    trig_vid_standard => 'NTSC',

    ptrig_source        => 'CH1',
    trig_pulse_polarity => 'POSITIVE',
    trig_pulse_width    => 1.0E-3,
    trig_pulse_when     => 'EQUAL',

};

sub _reset_cache {
    my $self = shift;

    for my $k ( keys( %{$_rst_state} ) ) {
        $self->{device_cache}->{$k} = $_rst_state->{$k};
        for ( my $ch = 1; $ch <= 4; $ch++ ) {
            $self->{chan_cache}->{"CH$ch"}->{select} = ( $ch == 1 ? 1 : 0 );
            next if "CH$ch" eq $self->{channel};
            $self->{chan_cache}->{"CH$ch"}->{$k} = $_rst_state->{$k};
        }
    }
    $self->{device_cache}->{select} = ( $self->{channel} eq 'CH1' ? 1 : 0 );
    foreach my $wfm (qw(MATH REFA REFB REFC REFD)) {
        $self->{chan_cache}->{$wfm}->{select} = 0;
    }
}

# print error queue; meant to be called at end of routine
# so uses 'caller' info to label the subroutine
sub _debug {
    return unless $DEBUG;
    my $self = shift;
    my ( $p, $f, $l, $subr ) = caller(1);
    while (1) {
        my ( $code, $msg ) = $self->get_error();
        last if $code == 0;
        print "$subr\t$code: $msg\n";
    }
}


sub get_error {
    my $self = shift;

    my $err = $self->query("*ESR?");
    if ( $err == 0 ) {
        return ( 0, "No events to report - queue empty" );
    }
    my $msg = $self->query("EVM?");

    if ( $msg =~ /^([\w:]+\s+)?(\d+),(.*)$/i ) {
        my $code = $2;
        $msg = $3;
        $msg =~ s/^\"//;
        $msg =~ s/\"$//;
        $msg =~ s/\"\"/"/g;
        return ( $code, $msg );
    }
    else {
        return ( -1, $msg );
    }

    #    (:EVMSG 110, "command head")
}


our $sbits = [qw(OPC RQC QYE DDE EXE CME URQ PON)];

sub get_status {
    my $self = shift;
    my $bit  = shift;
    my $s    = {};

    my $r = $self->query('*ESR?');
    $self->_debug();

    for ( my $j = 0; $j < 7; $j++ ) {
        $s->{ $sbits->[$j] } = ( $r >> $j ) & 0x01;
    }
    $s->{ERROR} = $s->{CME} | $s->{EXE} | $s->{DDE} | $s->{QYE};

    return $s->{ uc($bit) } if defined $bit;
    return $s;
}


sub get_datetime {
    my $self = shift;
    my $d = $self->query("DATE?");
    $d = $self->_parseReply($d);
    
    my $t = $self->query("TIM?");
    $t = $self->_parseReply($t);
    return "$d $t";
}


sub set_datetime {
    my $self = shift;
    my $unixtime = shift;
    $unixtime = time() unless defined $unixtime;
    
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime($unixtime);

    my $date = sprintf('%04d-%02d-%02d',$year+1900,$mon+1,$mday);
    my $time = sprintf('%02d:%02d:%02d',$hour,$min,$sec);

    $self->write("DATE \"$date\"");
    $self->write("TIME \"$time\"");

    return "$date $time";
}

    

sub wait_done {
    my $self = shift;
    my ( $time, $dt, $tail )
        = $self->_check_args( \@_, qw(timeout checkinterval) );

    my $tmax;

    $time = '10s' unless defined $time;

    if ( $time =~ /\s*(INF|MAX)/i ) {
        $tmax = -1;
    }
    else {
        $tmax = _parseNRf( $time, 's' );
        if ( $time =~ /(ERR|MIN|MAX)/ || $tmax <= 0 ) {
            Lab::Exception::CorruptParameter->throw(
                "Invalid time input '$time'\n");
            return;
        }
    }

    my $dtcheck;
    $dt = '500ms' unless defined $dt;
    $dtcheck = _parseNRf( $dt, 's' );
    if ( $dtcheck =~ /(ERR|MIN|MAX)/ || $dtcheck <= 0 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid time check interval input '$dt'\n");
        return;
    }

    my $n;
    if ( $tmax == -1 ) {
        $n = -1;
    }
    else {
        $n = $tmax / $dtcheck;

        $n = int( $n + 0.5 );
        $n = 1 if $n < 1;
        $n++;
    }

    while (1) {
        return 1 if $self->query('BUSY?') =~ /^(:BUSY )?\s*0/i;
        return 0 if $n-- == 0;
        sleep($dtcheck);
    }
}


sub test_busy {
    my $self = shift;
    return 1 if $self->query('BUSY?') =~ /^(:BUSY )?\s*1/i;
    return 0;
}


sub get_id {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    $tail->{read_mode} = $self->{config}->{default_read_mode}
        unless exists( $tail->{read_mode} ) && defined( $tail->{read_mode} );

    if ( $tail->{read_mode} ne 'cache'
        || !defined( $self->{device_cache}->{ID} ) ) {
        $self->{device_cache}->{ID} = $self->query('*IDN?');
        $self->_debug();
    }
    return $self->{device_cache}->{ID};
}


sub get_header {
    my $self = shift;

    my ($tail) = $self->_check_args( \@_ );

    $tail->{read_mode} = $self->{config}->{default_read_mode}
        unless exists( $tail->{read_mode} ) && defined( $tail->{read_mode} );

    if ( $tail->{read_mode} ne 'cache'
        || !defined( $self->{device_cache}->{HEADER} ) ) {
        my $r = $self->query('HEAD?');
        $self->_debug();

        # can't use the _parseReply here...
        if ( $r =~ /HEAD(er)?\s+([\w]+)/i ) {
            $r = $2;
        }
        if ( $r =~ /(1|ON)/i ) {
            $self->{device_cache}->{HEADER} = 1;
        }
        else {
            $self->{device_cache}->{HEADER} = 0;
        }
    }
    return $self->{device_cache}->{HEADER};
}


sub save {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'setup' );

    if ( $in !~ /^s*\d+\s*$/ || $in < 1 || $in > 10 || int($in) != $in ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid save setup number '$in'\n");
        return;
    }

    $self->write("*SAV $in");
    $self->_debug();
}


sub recall {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'setup' );

    if ( $in !~ /^\s*\d+\s*$/ || $in < 1 || $in > 10 || $in != int($in) ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid setup save location '$in'\n");
        return;
    }
    $self->write("*RCL $in");
    $self->_debug();
}


sub set_header {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'header' );
    my $h;

    if ( $in =~ /^\s*([1-9]|on|y|t)/i ) {
        $h = 1;
    }
    elsif ( $in =~ /^\s*(0|off|n|f)/i ) {
        $h = 0;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid boolean input '$in'\n");
        return;
    }
    return
        if defined( $self->{device_cache}->{HEADER} )
        && $self->{device_cache}->{HEADER} == $h;

    $self->write("HEAD $h");
    $self->{device_cache}->{HEADER} = $h;
    $self->_debug();
}


sub get_verbose {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    $tail->{read_mode} = $self->{config}->{default_read_mode}
        unless exists( $tail->{read_mode} ) && defined( $tail->{read_mode} );

    if ( $tail->{read_mode} ne 'cache'
        || !defined( $self->{device_cache}->{VERBOSE} ) ) {
        my $r = $self->query('VERB?');
        $self->_debug();

        # can't use the _parseReply here...
        if ( $r =~ /VERB(ose)?\s+([\w]+)/i ) {
            $r = $2;
        }
        if ( $r =~ /(1|ON)/i ) {
            $self->{device_cache}->{VERBOSE} = 1;
        }
        else {
            $self->{device_cache}->{VERBOSE} = 0;
        }
    }
    return $self->{device_cache}->{VERBOSE};
}


sub set_verbose {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'verbose' );
    my $v;

    if ( $in =~ /^\s*(1|on|y|t)/i ) {
        $v = 1;
    }
    elsif ( $in =~ /^\s*(0|off|n|f)/i ) {
        $v = 0;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid boolean input '$in'\n");
        return;
    }
    return
        if defined( $self->{device_cache}->{VERBOSE} )
        && $self->{device_cache}->{VERBOSE} == $v;
    $self->write("VERB $v");
    $self->{device_cache}->{VERBOSE} = $v;
    $self->_debug();
}


sub get_locked {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    $tail->{read_mode} = $self->{config}->{default_read_mode}
        unless exists( $tail->{read_mode} ) && defined( $tail->{read_mode} );

    if ( $tail->{read_mode} ne 'cache'
        || !defined( $self->{device_cache}->{LOCKED} ) ) {
        my $r = $self->query('LOC?');
        $self->_debug();

        # can't use the _parseReply here...
        if ( $r =~ /LOC(k)?\s+([\w]+)/i ) {
            $r = $2;
        }
        if ( $r =~ /(1|ON|ALL)/i ) {
            $self->{device_cache}->{LOCKED} = 1;
            $self->{config}->{no_cache}     = 0;
        }
        else {
            $self->{device_cache}->{LOCKED} = 0;
            $self->{config}->{no_cache}     = 1;
        }
    }
    return $self->{device_cache}->{LOCKED};
}


sub set_locked {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'locked' );

    my $lock;
    if ( $in =~ /^\s*(1|y|t|on|all)/i ) {
        $lock = 'ALL';
    }
    elsif ( $in =~ /^\s*(0|n|f|off|non)/i ) {
        $lock = 'NON';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid lock setting '$in'\n");
        return;
    }
    return
        if defined( $self->{device_cache}->{LOCKED} )
        && $self->{device_cache}->{LOCKED} eq $lock;

    $self->write("LOC $lock");
    $self->_debug();

    if ( $lock eq 'ALL' ) {    # locking clears cache
        $self->_ClearCache() if $self->{config}->{no_cache};
        $self->{config}->{no_cache}     = 0;
        $self->{device_cache}->{LOCKED} = 1;
    }
    else {
        $self->{config}->{no_cache}     = 1;
        $self->{device_cache}->{LOCKED} = 0;
    }
}

# clear cache of all but the "not front panel" (NFP) entries

sub _ClearCache {
    my $self = shift;
    my (%nfp);
    foreach my $k ( @{ $self->{NFP} } ) {
        $nfp{$k} = 1;
    }

    foreach my $ch (qw(CH1 CH2 CH3 CH4 MATH REFA REFB REFC REFD)) {
        foreach my $k ( keys( %{ $self->{chan_cache}->{$ch} } ) ) {
            next if exists( $nfp{$k} );
            $self->{chan_cache}->{$ch}->{$k} = undef;
        }
    }
}


# these give the mappings between SCPI codes and cache entries

our $_ccache = {    # per-channel caches
    'CH1:BANDWID'    => 'chan_bwlimit',
    'CH1:COUP'       => 'chan_coupling',
    'CH1:CURRENTPRO' => 'chan_current_probe',
    'CH1:INV'        => 'chan_invert',
    'CH1:POS'        => 'chan_position',
    'CH1:PRO'        => 'chan_probe',
    'CH1:SCA'        => 'chan_scale',
    'CH1:YUN'        => 'chan_yunit',
};

our $_lcache = {    # shared cache
    'ACQ:MODE'  => 'acquire_mode',
    'ACQ:NUMAV' => 'acquire_numavg',

    #'ACQ:STAT' => '          ',
    'ACQ:STOPA' => 'acquire_stopafter',

    'AUT:SETT' => 'autorange_settings',

    'CURS:FUNC'          => 'cursor_type',
    'CURS:HBA:POSITION1' => 'cursor_y1',
    'CURS:HBA:POSITION2' => 'cursor_y2',
    'CURS:SEL:SOU'       => 'cursor_source',
    'CURS:VBA:POSITION1' => 'cursor_x1',
    'CURS:VBA:POSITION2' => 'cursor_x2',
    'CURS:VBA:UNI'       => 'cursor_xunits',

    'DAT:DEST' => 'data_destination',
    'DAT:ENC'  => 'data_encoding',
    'DAT:SOU'  => 'data_source',
    'DAT:STAR' => 'data_start',
    'DAT:STOP' => 'data_stop',
    'DAT:WID'  => 'data_width',

    'DIS:CONTR' => 'display_contrast',
    'DIS:FORM'  => 'display_format',

    #'DIS:INV' => '          ',
    'DIS:PERS' => 'display_persist',
    'DIS:STY'  => 'display_style',

    #'HARDC:BUTT' => '          ',
    'HARDC:FORM' => 'hardcopy_format',

    #'HARDC:INKS' => '          ',
    'HARDC:LAY'        => 'hardcopy_layout',
    'HARDC:PORT'       => 'hardcopy_port',
    'HOR:DEL:POS'      => 'delay_position',
    'HOR:DEL:SCA'      => 'delay_scale',
    'HOR:MAI:POS'      => 'horiz_position',
    'HOR:MAI:SCA'      => 'horiz_scale',
    'HOR:VIEW'         => 'horiz_view',
    'MATH:DEFINE'      => 'math_definition',
    'MATH:FFT:HOR:POS' => 'fft_xposition',
    'MATH:FFT:HOR:SCA' => 'fft_xscale',
    'MATH:FFT:VER:POS' => 'fft_position',
    'MATH:FFT:VER:SCA' => 'fft_scale',
    'MATH:VER:POS'     => 'math_position',
    'MATH:VER:SCA'     => 'math_scale',

    'MEASU:IMM:SOU1'  => 'meas_source_imm',
    'MEASU:IMM:TYP'   => 'meas_type_imm',
    'MEASU:MEAS1:SOU' => 'meas_source_1',
    'MEASU:MEAS1:TYP' => 'meas_type_1',
    'MEASU:MEAS2:SOU' => 'meas_source_2',
    'MEASU:MEAS2:TYP' => 'meas_type_2',
    'MEASU:MEAS3:SOU' => 'meas_source_3',
    'MEASU:MEAS3:TYP' => 'meas_type_3',
    'MEASU:MEAS4:SOU' => 'meas_source_4',
    'MEASU:MEAS4:TYP' => 'meas_type_4',
    'MEASU:MEAS5:SOU' => 'meas_source_5',
    'MEASU:MEAS5:TYP' => 'meas_type_5',

    #    'PICT:DAT' => '          ',
    #    'PICT:IDPR' => '          ',
    #    'PICT:IMAG' => '          ',
    #    'PICT:PAP' => '          ',
    #    'PICT:PRIN' => '          ',

    #    'SAV:IMA:FIL' => '          ',

    'TRIG:MAI:EDGE:COUP'    => 'trig_coupling',
    'TRIG:MAI:EDGE:SLO'     => 'trig_slope',
    'TRIG:MAI:EDGE:SOU'     => 'etrig_source',
    'TRIG:MAI:HOLDO:VAL'    => 'trig_holdoff',
    'TRIG:MAI:LEV'          => 'trig_level',
    'TRIG:MAI:MOD'          => 'trig_mode',
    'TRIG:MAI:PUL:SOU'      => 'ptrig_source',
    'TRIG:MAI:PUL:WID:POL'  => 'trig_pulse_polarity',
    'TRIG:MAI:PUL:WID:WHEN' => 'trig_pulse_when',
    'TRIG:MAI:PUL:WID:WID'  => 'trig_pulse_width',
    'TRIG:MAI:TYP'          => 'trig_type',
    'TRIG:MAI:VID:LINE'     => 'trig_vid_line',
    'TRIG:MAI:VID:POL'      => 'trig_vid_polarity',
    'TRIG:MAI:VID:SOU'      => 'vtrig_source',
    'TRIG:MAI:VID:STAN'     => 'trig_vid_standard',
    'TRIG:MAI:VID:SYNC'     => 'trig_vid_sync',
};

sub get_setup {
    my $self = shift;

    if ( $self->query("*STB?") & 0x20 ) {
        $self->_debug();
        $self->write('*CLS');
    }

    my $v = $self->get_verbose();
    $self->set_verbose(1) if !$v;
    my $r = $self->query( "SET?", read_length => -1, timeout => 60 );
    my $post_status = $self->query("*STB?");

    # print Dumper($r),"\n";

    my $h = scpi_flat( scpi_parse($r), $self->{scpi_override} );

    #print Dumper($h),"\n";

    # special cases

    if ( exists( $h->{'TRIG:MAI:EDGE:SOU'} )
        && $h->{'TRIG:MAI:EDGE:SOU'} eq 'LINE' ) {

        if ( $post_status & 0x20 ) {
            my ( $ec, $em ) = $self->get_error();
            if (   ( $ec != 0 && $ec != 300 )
                || ( $ec == 300 && $em !~ /no\s*alternate/i ) ) {
                if ($DEBUG) {
                    my ( $p, $f, $l, $subr ) = caller(0);
                    print "$subr\t$ec: $em\n";
                }
            }
        }
    }

    $self->_debug();

    $self->set_verbose(0) if !$v;
    $h->{VERB} = $v;

    $self->{device_cache}->{HEADER}  = $h->{HEAD} if exists $h->{HEAD};
    $self->{device_cache}->{VERBOSE} = $h->{VERB} if exists $h->{VERB};
    if ( exists( $h->{LOC} ) ) {
        $self->{device_cache}->{LOCKED} = ( $h->{LOC} eq 'ALL' ? 1 : 0 );
    }

    if ( $self->{device_cache}->{LOCKED} ) {

        #per-channel values

        foreach my $wfm (qw(CH1 CH2 CH3 CH4 MATH REFA REFB REFC REFD)) {
            $self->{chan_cache}->{$wfm}->{select} = $h->{"SEL:$wfm"}
                if exists $h->{"SEL:$wfm"};

            next unless $wfm =~ /^CH/i;

            foreach my $k ( keys( %{$_ccache} ) ) {
                my $ck = $k;
                $ck =~ s/^CH1/$wfm/;
                next unless exists $h->{$ck};
                $self->{chan_cache}->{$wfm}->{ $_ccache->{$k} } = $h->{$ck};
            }
        }

        # shared cache values

        foreach my $k ( keys( %{$_lcache} ) ) {
            next unless exists $h->{$k};
            next if $_lcache->{$k} =~ /^\s*$/;
            $self->{device_cache}->{ $_lcache->{$k} } = $h->{$k};
        }
    }
    return $r;
}


sub set_setup {
    my $self = shift;
    my ( $setup, $args ) = $self->_check_args_strict( \@_, 'setup' );

    my $cmdlist
        = scpi_flat( scpi_parse_sequence($setup), $self->{scpi_override} );
    foreach my $hcmd ( @{$cmdlist} ) {
        foreach my $cmd ( keys( %{$hcmd} ) ) {
            my $v = $hcmd->{$cmd};
            $cmd .= ' ' . $v if defined($v) && $v ne '';
            $self->write( $cmd, $args );
            $self->_debug();
        }
    }
}


sub get_acquire_mode {
    my $self  = shift;
    my $amode = $self->query("ACQ:MODE?");
    $amode = $self->_parseReply( $amode, qw(SAM PEAK AVE) );
    $amode = _bloat(
        $amode,
        { SAM => 'SAMPLE', PEAK => 'PEAKDETECT', AVE => 'AVERAGE' }
    );
    $self->_debug();
    return $amode;
}


sub set_acquire_mode {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'mode' );

    my $m;
    if ( $in =~ /^\s*(SAM|NOR)/i ) {
        $m = 'SAM';
    }
    elsif ( $in =~ /^\s*(PE|PK)/i ) {
        $m = 'PEAK';
    }
    elsif ( $in =~ /^\s*AV/i ) {
        $m = 'AVE';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid aquire mode '$in'\n");
    }
    $self->write("ACQ:MODE $m");
    $self->_debug();
}


sub get_acquire_numacq {
    my $self = shift;
    my $ans  = $self->query("ACQ:NUMAC?");
    $self->_debug();
    return $self->_parseReply($ans);
}


sub get_acquire_numavg {
    my $self = shift;
    my $ans  = $self->query("ACQ:NUMAV?");
    $self->_debug();
    return $self->_parseReply($ans);
}


sub set_acquire_numavg {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'average' );

    #   $in =~ s/\D//g;
    #   $in += 0;

    if ( $in == 4 || $in == 16 || $in == 64 || $in == 128 ) {
        $self->write("ACQ:NUMAV $in");
        $self->_debug();
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid number to average '$in' [4,16,64,128]\n");
    }
}


sub get_acquire_state {
    my $self = shift;
    my $st   = $self->query("ACQ:STATE?");
    $self->_debug();

    $st = $self->_parseReply($st);
    return 'RUN' if $st =~ /(1|RUN)/i;
    return 'STOP';
}


# note: do not cache, since "single-shot ACQ" can change value asynchronously

sub set_acquire_state {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'state' );
    my $st;
    if ( $in =~ /^\s*(on|run|Y|t|[1-9])/i ) {
        $st = 1;
    }
    elsif ( $in =~ /^\s*(off|stop|n|f|0)/i ) {
        $st = 0;
    }
    else {
        Lab::Exception::CorruptParameter->throw("Invalid ACQ state '$in' \n");
        return;
    }
    $self->write("ACQ:STATE $st");
    $self->_debug();
}


sub get_acquire_stopafter {
    my $self = shift;
    my $ans  = $self->query("ACQ:STOPA?");
    $ans = $self->_parseReply( $ans, qw(RUNST SEQ) );
    $ans = _bloat( $ans, { RUNST => 'RUNSTOP', SEQ => 'SEQUENCE' } );
    $self->_debug();
    return $ans;
}


sub set_acquire_stopafter {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'mode' );

    my $m;
    if ( $in =~ /^\s*RU/i ) {
        $m = 'RUNST';
    }
    elsif ( $in =~ /^\s*(SE|SQ)/i ) {
        $m = 'SEQ';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid stopafter setting '$in' [4,16,64,128]\n");
    }
    $self->write("ACQ:STOPA $m");
    $self->_debug();
}


sub get_acquire {
    my $self   = shift;
    my ($tail) = $self->_check_args( \@_ );
    my $h      = {};

    $h->{mode}      = $self->get_acquire_mode($tail);
    $h->{numacq}    = $self->get_acquire_numacq($tail);
    $h->{numavg}    = $self->get_acquire_numavg($tail);
    $h->{state}     = $self->get_acquire_state($tail);
    $h->{stopafter} = $self->get_acquire_stopafter($tail);
    return $h;
}


sub set_acquire {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );
    $self->set_acquire_mode($tail)      if exists $tail->{mode};
    $self->set_acquire_stopafter($tail) if exists $tail->{stopafter};
    $self->set_acquire_numavg($tail)    if exists $tail->{average};
    $self->set_acquire_state($tail)     if exists $tail->{state};
}


sub get_autorange_state {
    my $self = shift;
    my $ars  = $self->query("AUTOR:STATE?");
    $self->_debug();
    return $self->_parseReply($ars);
}


sub set_autorange_state {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'state' );
    my $b;
    if ( $in =~ /^s*([1-9]|t|y|on)/i ) {
        $b = 1;
    }
    elsif ( $in =~ /^s*(0|f|n|off)/i ) {
        $b = 0;
    }
    else {
        Lab::Exception::CorruptParameter->throw("Invalid boolean '$in' \n");
        return;
    }

    $self->write("AUTOR:STATE $b");
    $self->_debug();
}


sub get_autorange_settings {
    my $self = shift;
    my $ars  = $self->query("AUTOR:SETT?");
    $ars = $self->_parseReply( $ars, qw(HOR VERT BOTH) );
    $ars = _bloat(
        $ars,
        { HOR => 'HORIZONTAL', VERT => 'VERTICAL', BOTH => 'BOTH' }
    );

    $self->_debug();
    return $ars;
}


sub set_autorange_settings {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'set' );
    my $ars;
    if ( $in =~ /^\s*(H|X)/i ) {
        $ars = 'HOR';
    }
    elsif ( $in =~ /^\s*(V|Y)/i ) {
        $ars = 'VERT';
    }
    elsif ( $in =~ /^\s*B/i ) {
        $ars = 'BOTH';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid autorange setting '$in' \n");
    }
    $self->write("AUTOR:SETT $ars");
    $self->_debug();
}


sub do_autorange {
    my $self = shift;
    $self->write("AUTOS EXEC");
    $self->_debug();
}


sub get_autorange_signal {
    my $self = shift;
    my $sig  = $self->query("AUTOS:SIGNAL?");
    $sig = $self->_parseReply(
        $sig,
        qw(LEVEL SINE SQUARE VIDPAL VIDNTSC OTHER NON)
    );
    $sig = 'NONE' if $sig eq 'NON';
    $self->_debug();
    return $sig;
}


sub get_autorange_view {
    my $self = shift;
    my $r    = $self->query("AUTOS:VIEW?");

    $r = $self->_parseReply(
        $r,
        qw(MULTICY SINGLECY FFT RISING FALLING FIELD ODD EVEN LINE LINEN DCLI DEF NONE)
    );
    $r = _bloat(
        $r, {
            MULTICY => 'MULTICYCLE',  SINGLECY => 'SINGLECYCLE',
            FFT     => 'FFT',         RISING   => 'RISINGEDGE',
            FALLING => 'FALLINGEDGE', FIELD    => 'FIELD', ODD => 'ODD',
            EVEN    => 'EVEN',        LINE     => 'LINE', LINEN => 'LINENUM',
            DCLI    => 'DCLINE',      DEF      => 'DEFAULT', NON => 'NONE'
        }
    );
    $self->_debug();
    return $r;
}


sub set_autorange_view {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'view' );
    my $kw;
    $in =~ s/^\s*//;

    if ( $in =~ /^MUL/i ) {
        $kw = 'MULTICY';
    }
    elsif ( $in =~ /^(SING|1)/i ) {
        $kw = 'SINGLECY';
    }
    elsif ( $in =~ /^FF/i ) {
        $kw = 'FFT';
    }
    elsif ( $in =~ /^(R|\+)/i ) {
        $kw = 'RISING';
    }
    elsif ( $in =~ /^(FA|\-)/i ) {
        $kw = 'FALLING';
    }
    elsif ( $in =~ /^FIE/i ) {
        $kw = 'FIELD';
    }
    elsif ( $in =~ /^OD/i ) {
        $kw = 'ODD';
    }
    elsif ( $in =~ /^EV/i ) {
        $kw = 'EVEN';
    }
    elsif ( $in =~ /^LINEN/i ) {
        $kw = 'LINEN';
    }
    elsif ( $in =~ /^LI/i ) {
        $kw = 'LINE';
    }
    elsif ( $in =~ /^DC/i ) {
        $kw = 'DCLI';
    }
    elsif ( $in =~ /^DE/i ) {
        $kw = 'DEF';
    }
    elsif ( $in =~ /^(NO|0|OF)/i ) {
        $kw = 'NONE';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid autorange view '$in' \n");
    }

    $self->write("AUTOS:VIEW $kw");

    my ( $c, $m ) = $self->get_error();
    return if $c == 0;
    carp("error in set_autorange_view: $c,'$m'");
}


sub get_autorange {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    my $h = {};
    $h->{state}    = $self->get_autorange_state($tail);
    $h->{settings} = $self->get_autorange_settings($tail);
    $h->{signal}   = $self->get_autorange_signal($tail);
    $h->{view}     = $self->get_autorange_view($tail);
    return $h;
}


sub get_channel {
    my $self = shift;
    return $self->{channel};
}


sub set_channel {
    my $self = shift;
    my ($ch) = $self->_check_args_strict( \@_, 'channel' );

    if ( $ch =~ /^\s*MAT/i ) {
        $ch = 'MATH';
    }
    elsif ( $ch =~ /^\s*(CH[1-4])\s*$/i ) {
        $ch = uc($1);
    }
    elsif ( $ch =~ /^\s*([1-4])\s*$/ ) {
        $ch = "CH${1}";
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid channel '$ch' should be CH1..4 or MATH \n");
        return;
    }
    return if $ch eq $self->{channel};    # already set to that channel

    # store the shared cache entries
    foreach my $k ( keys( %{ $self->{shared_cache} } ) ) {
        $self->{shared_cache}->{$k} = $self->{device_cache}->{$k};
    }

    # switch to the per-channel cache of selected channel
    $self->{device_cache} = $self->{chan_cache}->{$ch};

    # update from shared cache
    foreach my $k ( keys( %{ $self->{shared_cache} } ) ) {
        $self->{device_cache}->{$k} = $self->{shared_cache}->{$k};
    }

    $self->{channel} = $ch;
}


sub get_vertical_settings {
    my $self = shift;
    my ($ch) = $self->_check_args_strict( \@_ ,'channel');
    
    if ( $ch =~ /^\s*(CH[1-4])\s*$/i ) {
        $ch = uc($1);
    }
    elsif ( $ch =~ /^\s*([1-4])\s*$/ ) {
        $ch = "CH${1}";
    }
    elsif ( $ch =~ /^\s*MA/i) {
	$ch = 'MATH';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid channel '$ch' should be CH1..4 or MATH \n");
        return;
    }


    my $v = $self->get_verbose();
    $self->set_verbose(1) if !$v;
    my $hd = $self->get_header();
    $self->set_header(1) if !$hd;

    my $reply = $self->query("${ch}?");
    $self->set_verbose(0) if !$v;
    $self->set_header(0) if !$hd;
    return scpi_flat(scpi_parse($reply));
}
    



sub set_visible {
    my $self = shift;
    my ( $ch, $ivis ) = $self->_check_args( \@_, qw(channel visible) );

    $ch = $self->{channel} unless defined $ch;
    $ivis = 1 unless defined $ivis;

    if ( $ch =~ /^\s*(ch[1-4])\s*$/i ) {
        $ch = uc($1);
    }
    elsif ( $ch =~ /^\s*math\s*$/i ) {
        $ch = 'MATH';
    }
    elsif ( $ch =~ /^\s*(ref[a-d])\s*$/i ) {
        $ch = uc($1);
    }
    elsif ( $ch =~ /^\s*([1-4])\s*$/ ) {
        $ch = "CH$1";
    }
    elsif ( $ch =~ /^\s*([a-d])\s*$/i ) {
        $ch = "REF$1";
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid channel input '$ch'\n");
        return;
    }

    my $vis;
    if ( $ivis =~ /\s*(T|Y|ON|[1-9])/i ) {
        $vis = 1;
    }
    elsif ( $ivis =~ /\s*(F|N|OF|0)/i ) {
        $vis = 0;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid boolean input '$ivis'\n");
        return;
    }

    my $cache;
    if ( $self->{device_cache}->{LOCKED} ) {
        if ( $ch eq $self->{channel} ) {
            $cache = $self->{device_channel};
        }
        else {
            $cache = $self->{chan_cache}->{$ch};
        }
        return if defined( $cache->{select} ) && $vis == $cache->{select};
    }

    $self->write("SEL:$ch $vis");
    $self->_debug();
    $cache->{select} = $vis if defined $cache;
}


sub get_visible {
    my $self = shift;
    my ( $ch, $tail ) = $self->_check_args( \@_, qw(channel) );

    $tail->{read_mode} = $self->{config}->{default_read_mode}
        unless exists( $tail->{read_mode} ) && defined( $tail->{read_mode} );

    $ch = $self->{channel} unless defined $ch;

    if ( $ch =~ /^\s*(ch[1-4])\s*$/i ) {
        $ch = uc($1);
    }
    elsif ( $ch =~ /^\s*math\s*$/i ) {
        $ch = 'MATH';
    }
    elsif ( $ch =~ /^\s*(ref[a-d])\s*$/i ) {
        $ch = uc($1);
    }
    elsif ( $ch =~ /^\s*([1-4])\s*$/ ) {
        $ch = "CH$1";
    }
    elsif ( $ch =~ /^\s*([a-d])\s*$/i ) {
        $ch = "REF$1";
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid channel input '$ch'\n");
        return;
    }

    my $cache;
    if ( $self->{device_cache}->{LOCKED} ) {
        my $v;
        if ( $ch eq $self->{channel} ) {
            $cache = $self->{device_cache};
        }
        else {
            $cache = $self->{chan_cache}->{$ch};
        }
        $v = $cache->{select}
            if defined( $cache->{select} );
        return $v if defined($v) && $tail->{read_mode} eq 'cache';
    }
    my $r = $self->query("SEL:$ch?");
    $self->_debug();
    $r = $self->_parseReply($r);

    $cache->{select} = $r if defined $cache;
    return $r;
}


sub get_chan_bwlimit {
    my $self = shift;
    my $ch   = $self->{channel};

    return 0 if $ch eq 'MATH';

    my $r = $self->query("${ch}:BANDWID?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_chan_bwlimit {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'limit' );
    my $ch = $self->{channel};
    return if $ch eq 'MATH';

    my $b;
    if ( $in =~ /^\s*([1-9]|y|t|on)/i ) {
        $b = 'ON';
    }
    elsif ( $in =~ /^\s*(0|n|f|off)/i ) {
        $b = 'OFF';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid limit boolean, should be ON|OFF \n");
        return;
    }
    $self->write("${ch}:BANDWID $b");
    $self->_debug();
}


sub get_chan_coupling {
    my $self = shift;
    my $ch   = $self->{channel};

    return 'GND' if $ch eq 'MATH';
    my $r = $self->query("${ch}:COUP?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_chan_coupling {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'coupling' );
    my $ch = $self->{channel};

    return if $ch eq 'MATH';
    $in = _keyword( $in, qw(AC DC GND) );
    $self->write("${ch}:COUP $in");
    $self->_debug();
}


sub get_chan_current_probe {
    my $self = shift;
    my $ch   = $self->{channel};

    return 1 if $ch eq 'MATH';
    my $r = $self->query("${ch}:CURRENTPRO?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_chan_current_probe {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'factor' );
    my $ch = $self->{channel};

    return if $ch eq 'MATH';
    my $fact = _parseNRf( $in, 'X' );    # '10x', for example

    if ( $fact =~ /^ERR/i || $fact eq 'MIN' || $fact eq 'MAX' ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing probe factor '$in' \n");
        return;
    }
    $fact = int( $fact * 10 + 0.5 ) * 0.1;
    if (   $fact != 0.2
        && $fact != 1
        && $fact != 2
        && $fact != 5
        && $fact != 10
        && $fact != 50
        && $fact != 100
        && $fact != 1000 ) {
        Lab::Exception::CorruptParameter->throw("Invalid factor '$fact' \n");
        return;
    }
    $self->write("${ch}:CURRENTPRO $fact");
    $self->_debug();
}


sub get_chan_invert {
    my $self = shift;
    my $ch   = $self->{channel};

    return 0 if $ch eq 'MATH';

    my $r = $self->query("${ch}:INV?");
    $r = $self->_parseReply($r);
    $r = 1 if $r eq 'ON';
    $r = 0 if $r eq 'OFF';
    $self->_debug();
    return $r;
}


sub set_chan_invert {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'invert' );
    my $ch = $self->{channel};
    return if $ch eq 'MATH';

    if ( $in =~ /^\s*(on|[1-9]|t|y)/i ) {
        $in = 'ON';
    }
    elsif ( $in =~ /^\s*(off|0|f|n)/i ) {
        $in = 'OFF';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing boolean '$in' \n");
        return;
    }

    $self->write("${ch}:INV $in");
    $self->_debug();
}


sub get_chan_position {
    my $self = shift;
    my $ch   = $self->{channel};

    $ch = 'MATH:VER' if $ch eq 'MATH';
    my $r = $self->query("${ch}:POS?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_chan_position {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'position' );
    my $ch = $self->{channel};

    my $p = _parseNRf( $in, 'div' );

    if ( $p =~ /ERR/ || $p eq 'MIN' || $p eq 'MAX' ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing number '$in' \n");
        return;
    }

    $p = sprintf( '%.2e', $p );
    my $scale = $self->get_chan_scale();
    my $maxv  = 2;
    $maxv = 50 if $scale >= 0.5;

    if ( abs( $p * $scale ) > $maxv ) {
        Lab::Exception::CorruptParameter->throw(
            "Channel position '$p' out of range\n");
        return;
    }

    $ch = 'MATH:VER' if $ch eq 'MATH';
    $self->write("${ch}:POS $p");
    $self->_debug();
}


sub get_chan_probe {
    my $self = shift;
    my $ch   = $self->{channel};

    return 1 if $ch eq 'MATH';
    my $r = $self->query("${ch}:PRO?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_chan_probe {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'factor' );
    my $ch = $self->{channel};

    return if $ch eq 'MATH';
    my $fact = _parseNRf( $in, 'x' );

    if ( $fact =~ /ERR/ || $fact eq 'MIN' || $fact eq 'MAX' ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing probe attenuation '$in' \n");
        return;
    }

    $fact = int( $fact + 0.2 );
    if (   $fact != 1
        && $fact != 10
        && $fact != 20
        && $fact != 50
        && $fact != 100
        && $fact != 500
        && $fact != 1000 ) {
        Lab::Exception::CorruptParameter->throw("Invalid factor '$fact' \n");
        return;
    }
    $self->write("${ch}:PRO $fact");
    $self->_debug();
}


sub get_chan_scale {
    my $self = shift;
    my $ch   = $self->{channel};

    $ch = 'MATH:VER' if $ch eq 'MATH';
    my $r = $self->query("${ch}:SCA?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_chan_scale {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'scale' );
    my $ch = $self->{channel};

    my $gain = _parseNRf( $in, 'v/div', 'a/div', 'v', 'a' );

    if ( $gain =~ /ERR/ || $gain eq 'MIN' || $gain eq 'MAX' ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing probe attenuation '$in' \n");
        return;
    }

    if ( $ch ne 'MATH' ) {
        my $vmin = 2e-3;
        my $vmax = 5;
        my $probe;
        my $y = $self->get_chan_yunit();
        if ( $y eq 'V' ) {
            $probe = $self->get_chan_probe();
        }
        else {
            $probe = $self->get_chan_currentprobe();
        }
        $vmin *= $probe;
        $vmax *= $probe;
        $gain = sprintf( '%.3e', $gain );

        if ( $gain > $vmax || $gain < $vmin ) {
            Lab::Exception::CorruptParameter->throw(
                "Vertical scale '$in' out of range\n");
            return;
        }
    }
    else {
        if ( $gain <= 0 ) {
            Lab::Exception::CorruptParameter->throw(
                "Vertical scale '$in' out of range\n");
            return;
        }
    }

    $ch = 'MATH:VER' if $ch eq 'MATH';
    $self->write("${ch}:SCA $gain");
    $self->_debug();
}


sub get_chan_yunit {
    my $self = shift;
    my $ch   = $self->{channel};
    return 'V' if $ch eq 'MATH';

    my $r = $self->query("${ch}:YUN?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_chan_yunit {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'unit' );
    my $ch = $self->{channel};

    return if $ch eq 'MATH';
    my $y;
    if ( $in =~ /^\s*V/i ) {
        $y = 'V';
    }
    elsif ( $in =~ /^\s*A/i ) {
        $y = 'A';
    }
    else {
        Lab::Exception::CorruptParameter->throw("Invalid yunit '$in' \n");
        return;
    }

    $self->write("${ch}:YUN $y");
    $self->_debug();
}


sub get_chan_setup {
    my $self = shift;

    my ($tail) = $self->_check_args( \@_ );

    $self->set_channel($tail) if exists( $tail->{channel} );

    my $ch = $self->{channel};
    my $h  = {};
    $h->{channel}      = $ch;
    $h->{scale}        = $self->get_scale($tail);
    $h->{position}     = $self->get_position($tail);
    $h->{invert}       = $self->get_invert($tail);
    $h->{coupling}     = $self->get_coupling($tail);
    $h->{bandwidth}    = $self->get_bandwidth($tail);
    $h->{yunit}        = $self->get_yunit($tail);
    $h->{probe}        = $self->get_probe($tail);
    $h->{currentprobe} = $self->get_current_probe($tail);
    $h->{definition}   = $self->get_math_definition($tail) if $ch eq 'MATH';

    return $h;
}


sub set_chan_setup {
    my $self = shift;

    my ($tail) = $self->_check_args( \@_ );

    $self->set_channel($tail) if exits( $tail->{channel} );

    $self->set_chan_coupling($tail)
        if exists( $tail->{coupling} );
    $self->set_chan_invert($tail)
        if exists( $tail->{invert} );
    $self->set_chan_yunit($tail)
        if exists( $tail->{yunit} );
    $self->set_chan_probe($tail)
        if exists( $tail->{probe} );
    $self->set_chan_currentprobe($tail)
        if exists( $tail->{currentprobe} );
    $self->set_chan_scale($tail)
        if exists( $tail->{scale} );
    $self->set_chan_position($tail)
        if exists( $tail->{position} );
    $self->set_math_definition($tail)
        if exists( $tail->{math_definition} );

}


sub get_cursor_type {
    my $self = shift;
    my ($opt) = $self->_check_args( \@_, ['option'] );
    $opt = '' unless defined($opt);
    $opt = 'XY' if $opt =~ /\s*x/i;

    my $r = $self->query("CURS:FUNC?");
    $r = $self->_parseReply( $r, qw(OFF HBA VBA) );

    if ( $opt eq 'XY' ) {
        $r = _bloat( $r, { OFF => 'OFF', HBA => 'Y', VBA => 'X' } );
    }
    else {
        $r = _bloat( $r, { OFF => 'OFF', HBA => 'HBARS', VBA => 'VBARS' } );
    }
    $self->_debug();
    return $r;
}


sub set_cursor_type {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'type' );

    my $dform = $self->get_display_format();

    my $c;
    if ( $in =~ /^\s*(OFF|N|F|0)/i ) {
        $c = 'OFF';
    }
    elsif ( $in =~ /^\s*(H|y)/i ) {
        $c = 'HBA';
    }
    elsif ( $in =~ /^\s*(V|x)/i ) {
        $c = 'VBA';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid cursor selection '$in' \n");
        return;
    }
    if ( $dform eq 'XY' && $c ne 'OFF' ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid cursor selection '$in' for XY display\n");
        return;
    }

    $self->write("CURS:FUNC $c");
    $self->_debug();
}


sub get_cursor_xunits {
    my $self = shift;

    # trigger view error

    my $r = '';
    $r = $self->query("CURS:VBA:UNI?");
    $r = $self->_parseReply( $r, qw(SECO HER) );
    $r = _bloat( $r, { SECO => 'SECONDS', HER => 'HERTZ' } );

    $self->_debug();
    return $r;
}


sub get_cursor_yunits {
    my $self = shift;

    # trigger view error

    my $r = '';
    $r = $self->query("CURS:HBA:UNI?");
    $r = $self->_parseReply(
        $r, qw(VOL DIV DECIBELS UNKNOWN AMPS
            VOLTSSQUARED AMPSSQUARED VOLTSAMPS)
    );
    $r = _bloat( $r, { VOL => 'VOLTS', DIV => 'DIVISIONS' } );
    $self->_debug();
    return $r;
}


sub get_cursor_source {
    my $self = shift;
    my $r    = $self->query("CURS:SEL:SOU?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_cursor_source {
    my $self = shift;
    my ($ich) = $self->_check_args_strict( \@_, ['channel'] );

    my $ch = $ich;
    $ch =~ s/^\s+//;
    if ( $ich =~ /^([\d\.]+)/i ) {
        $ch = "CH$1";
    }

    if (   $ch !~ /^CH[1-4]$/i
        && $ch !~ /^MATH$/i
        && $ch !~ /^REF[a-d]$/i ) {
        Lab::Exception::CorruptParameter->throw("Invalid channel '$ch'\n");
        return;
    }
    $ch = uc($ch);

    $self->write("CURS:SEL:SOU $ch");
    $self->_debug();
}


sub set_cursor_xunits {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'unit' );

    my $u;
    if ( $in =~ /^\s*s/i ) {
        $u = 'SECO';
    }
    elsif ( $in =~ /^\s*her/i || $in =~ /^\s*Hz/i ) {
        $u = 'HER';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid cursor unit selection '$in' \n");
        return;
    }
    $self->write("CURS:VBA:UNI $u");
    $self->_debug();
}


sub get_cursor_dx {
    my $self = shift;

    # trigger view error

    my $r = $self->query("CURS:VBA:DELT?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub get_cursor_dy {
    my $self = shift;

    # trigger view error

    my $r = $self->query("CURS:HBA:DELT?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub get_cursor_x1 {
    my $self = shift;

    my $r = $self->query("CURS:VBA:POSITION1?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub get_cursor_x2 {
    my $self = shift;

    my $r = $self->query("CURS:VBA:POSITION2?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub get_cursor_y1 {
    my $self = shift;

    #   error if trigger view active
    my $r = $self->query("CURS:HBA:POSITION1?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub get_cursor_y2 {
    my $self = shift;

    # error trigger view
    my $r = $self->query("CURS:HBA:POSITION2?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_cursor_x1 {
    my $self = shift;
    my ($ipos) = $self->_check_args_strict( \@_, ['position'] );
    $self->_set_cursor( 'VBA', 1, $ipos );
}


sub set_cursor_x2 {
    my $self = shift;
    my ($ipos) = $self->_check_args_strict( \@_, ['position'] );
    $self->_set_cursor( 'VBA', 2, $ipos );
}


sub set_cursor_y1 {
    my $self = shift;
    my ($ipos) = $self->_check_args_strict( \@_, ['position'] );
    $self->_set_cursor( 'HBA', 1, $ipos );
}


sub set_cursor_y2 {
    my $self = shift;
    my ($ipos) = $self->_check_args_strict( \@_, ['position'] );
    $self->_set_cursor( 'HBA', 2, $ipos );
}

# setting cursors has a lot of 'common' code, so
# do it here
#      $self->_set_cursor(VBA|HBA,1|2,position);
#

sub _set_cursor {
    my $self = shift;
    my $t    = shift;
    my $c    = shift;
    my $ipos = shift;

    my $pos;

    if ( $t eq 'HBA' ) {
        my $u = $self->get_cursor_units();

        #	VOL, AMPS , DECIBELS, DIV, UNKNOWN, VOLTSSQUARE, ampssquared, voltsamps
        my $u2 = '';
        my $u3 = '';
        $u2 = 'V'   if $u eq 'VOL';
        $u2 = 'A'   if $u eq 'AMPS';
        $u2 = 'dB'  if $u eq 'DECIBELS';
        $u3 = 'dBV' if $u eq 'DECIBELS';
        $u2 = 'V.V' if $u eq 'VOLTSSQUARED';
        $u2 = 'A.A' if $u eq 'AMPSSQUARED';
        $u2 = 'W'   if $u eq 'VOLTSAMPS';
        $u3 = 'V.A' if $u eq 'VOLTSAMPS';

        $pos = _parseNRf( $ipos, $u, $u2, $u3 );
    }
    else {
        my $u = $self->get_cursor_units();

        #	SECO HER
        my $u2 = '';
        my $u3 = '';
        $u2 = 'seconds' if $u eq 'SECO';
        $u3 = 's'       if $u eq 'SECO';
        $u2 = 'hertz'   if $u eq 'HER';
        $u3 = 'hz'      if $u eq 'HER';
        $pos = _parseNRf( $ipos, $u, $u2, $u3 );
    }
    if ( $pos =~ /ERR/ || $pos eq 'MIN' || $pos eq 'MAX' ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing position '$ipos' \n");
        return;
    }
    $self->write("CURS:${t}:POSITION${c} $pos");
    $self->_debug();
}


sub get_cursor_v1 {
    my $self = shift;

    my $r = $self->query("CURS:VBA:HPOS1?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub get_cursor_v2 {
    my $self = shift;

    my $r = $self->query("CURS:VBA:HPOS2?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub get_cursor_dv {
    my $self = shift;
    my $r    = $self->query("CURS:VBA:VDELT?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub get_cursor {
    my $self   = shift;
    my ($tail) = $self->_check_args( \@_ );
    my $h      = {};

    # errors if trigger view active...
    $h->{type}   = $self->get_cursor_type($tail);
    $h->{xunits} = $self->get_cursor_xunits($tail);
    $h->{yunits} = $self->get_cursor_yunits($tail);
    $h->{source} = $self->get_cursor_source($tail);
    $h->{dx}     = $self->get_cursor_dx($tail);
    $h->{dy}     = $self->get_cursor_dy($tail);
    $h->{dv}     = $self->get_cursor_dv($tail);
    $h->{x1}     = $self->get_cursor_x1($tail);
    $h->{y1}     = $self->get_cursor_y1($tail);
    $h->{x2}     = $self->get_cursor_x2($tail);
    $h->{y2}     = $self->get_cursor_y2($tail);
    $h->{v1}     = $self->get_cursor_v1($tail);
    $h->{v2}     = $self->get_cursor_v2($tail);
    return $h;
}


sub set_cursor {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    $self->set_cursor_type($tail)   if exists( $tail->{type} );
    $self->set_cursor_yunits($tail) if exists( $tail->{yunits} );
    $self->set_cursor_source($tail) if exists( $tail->{source} );
    $self->set_cursor_x1($tail)     if exists( $tail->{x1} );
    $self->set_cursor_x2($tail)     if exists( $tail->{x2} );
    $self->set_cursor_y1($tail)     if exists( $tail->{y1} );
    $self->set_cursor_y2($tail)     if exists( $tail->{y2} );
}


sub get_display_contrast {
    my $self = shift;
    my $r    = $self->query("DIS:CONTR?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_display_contrast {
    my $self = shift;
    my ($cont) = $self->_check_args_strict( \@_, 'contrast' );
    $cont = int( $cont + 0.5 );
    if ( $cont < 1 || $cont > 100 ) {
        Lab::Exception::CorruptParameter->throw(
            "Contrast out of range 1..100 \n");
        return;
    }
    $self->write("DIS:CONTR $cont");
    $self->_debug();
}


sub get_display_format {
    my $self = shift;
    my $f    = $self->query("DIS:FORM?");
    $self->_debug();
    return $f;
}


sub set_display_format {
    my $self = shift;
    my ($f) = $self->_check_args_strict( \@_, 'format' );
    $f = _keyword( $f, qw(XY YT) );
    $self->write("DIS:FORM $f");
    $self->_debug();

    if ( $f eq 'XY' ) {
        $self->{device_cache}->{cursor_type} = 'OFF';
    }
}


sub get_display_persist {
    my $self = shift;
    my $r    = $self->query("DIS:PERS?");
    $r = $self->_parseReply($r);
    $r = 'OFF' if $r eq '0';
    $r = 'INF' if $r eq '99';
    $self->_debug();
    return $r;
}


sub set_display_persist {
    my $self = shift;
    my ($pers) = $self->_check_args_strict( \@_, 'persist' );
    my $p;

    if ( $pers =~ /^\s*(INF|MAX)/i ) {
        $p = 'INF';
    }
    elsif ( $pers =~ /^\s*(OFF|MIN|F|N|0)/i ) {
        $p = 'OFF';
    }
    else {
        $p = _parseNRf( $pers, 's' );
        if ( $p =~ /ERR/i || ( $p != 1 && $p != 2 && $p != 5 ) ) {
            Lab::Exception::CorruptParameter->throw(
                "Invalid persistance '$pers'\n");
            return;
        }
    }
    $self->write("DIS:PERS $p");
    $self->_debug();
}


sub get_display_style {
    my $self = shift;
    my $r    = $self->query("DIS:STY?");
    $r = $self->_parseReply( $r, qw(DOT VEC) );
    $r = _bloat( $r, { DOT => 'DOTS', VEC => 'VECTORS' } );
    $self->_debug();
    return $r;
}


sub set_display_style {
    my $self = shift;
    my ($st) = $self->_check_args_strict( \@_, 'style' );
    $st = _keyword( $st, qw(DOT VEC) );
    $self->write("DIS:STY $st");
    $self->_debug();
}


sub get_display {
    my $self   = shift;
    my ($tail) = $self->_check_args( \@_ );
    my $h      = {};
    $h->{contrast} = $self->get_display_contrast($tail);
    $h->{format}   = $self->get_display_format($tail);
    $h->{persist}  = $self->get_display_persist($tail);
    $h->{style}    = $self->get_display_style($tail);
    return $h;
}


sub set_display {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );
    $self->set_display_contrast($tail) if exists $tail->{contrast};
    $self->set_display_format($tail)   if exists $tail->{format};
    $self->set_display_persist($tail)  if exists $tail->{persist};
    $self->set_display_style($tail)    if exists $tail->{style};
}


sub get_cwd {
    my $self = shift;
    my $r    = $self->query("FILES:CWD?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_cwd {
    my $self = shift;
    my ($icwd) = $self->_check_args_strict( \@_, ['cwd'] );

    my $cwd = $icwd;
    $cwd =~ s/\//\\/g;
    $self->write("FILES:CWD $cwd");
    $self->_debug();
}


sub delete {
    my $self = shift;
    my ($file) = $self->_check_args_strict( \@_, ['file'] );

    $file =~ tr{/}{\\};

    $self->write("FILES:DELE \"$file\"");
    $self->_debug();
}


sub get_dir {
    my $self = shift;
    my $r    = $self->query("FILES:DIR?");
    $r = $self->_parseReply($r);
    $self->_debug();
    return _parseStrings($r);
}

sub _parseStrings {
    my $str = shift;
    my (@results) = ();
    return (@results) unless defined $str;
    $str =~ s/^\s+//;
    $str .= ' ,' if $str !~ /,\s*$/;
    my $x;

    while ( $str ne '' ) {
        last if $str =~ /^\s*,?\s*$/;
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


sub get_freespace {
    my $self = shift;
    my $r    = $self->query("FILES:FREES?");
    $self->_debug();
    return $self->parseReply($r);
}


sub mkdir {
    my $self = shift;
    my ($d) = $self->_check_args_strict( \@_, ['directory'] );

    $d =~ tr{/}{\\};

    $self->write("FILES:MKD \"$d\"");
    $self->_debug();
}


sub rename {
    my $self = shift;
    my ( $old, $new ) = $self->_check_args_strict( \@_, qw(old new) );

    $old =~ tr{/}{\\};
    $new =~ tr{/}{\\};

    $self->write("FILES:REN \"$old\",\"$new\"");
    $self->_debug();
}


sub rmdir {
    my $self = shift;
    my ($d) = $self->_check_args_strict( \@_, ['directory'] );

    $d =~ tr{/}{\\};
    $self->write("FILES:RMD \"$d\"");
    $self->_debug();
}


sub get_hardcopy_format {
    my $self = shift;

    my $r = $self->query("HARDC:FORM?");
    $r = $self->_parseReply(
        $r, qw( BMP BUBBLEJ DESKJ DPU3445
            DPU411 DPU412 EPSC60 EPSC80 EPSIMAGE EPSO INTERLEAF
            JPEG LASERJ PCX RLE THINK TIFF)
    );
    $self->_debug();
    return _bloat(
        $r, {
            BUBBLEJ => 'BUBBLEJET', DESKJ => 'DESKJET',
            EPSO    => 'EPSON',     THINK => 'THINKJET'
        }
    );
}


sub set_hardcopy_format {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['format'] );
    my $f;

    $in =~ s/^\s*//;
    if ( $in =~ /^BMP/i ) {
        $f = 'BMP';
    }
    elsif ( $in =~ /^(BUB|BJ)/i ) {
        $f = 'BUBBLEJ';
    }
    elsif ( $in =~ /^(DESKJ|DJ)/i ) {
        $f = 'DESKJ';
    }
    elsif ( $in =~ /^DPU3/i ) {
        $f = 'DPU3445';
    }
    elsif ( $in =~ /^DPU411/i ) {
        $f = 'DPU411';
    }
    elsif ( $in =~ /^DPU412/i ) {
        $f = 'DPU412';
    }
    elsif ( $in =~ /^(EPSC6|EPSON\s*(S(TYLUS)?)?\s*C6)/i ) {
        $f = 'EPSC60';
    }
    elsif ( $in =~ /^(EPSC8|EPSON\s*(S(TYLUS)?)?\s*C8)/i ) {
        $f = 'EPSC80';
    }
    elsif ( $in =~ /^epso/i ) {
        $f = 'EPSO';
    }
    elsif ( $in =~ /^(eps|post)/i ) {
        $f = 'EPSIMAGE';
    }
    elsif ( $in =~ /^INTER/i ) {
        $f = 'INTERLEAF';
    }
    elsif ( $in =~ /^JP/i ) {
        $f = 'JPEG';
    }
    elsif ( $in =~ /^(LASER|LJ)/i ) {
        $f = 'LASERJ';
    }
    elsif ( $in =~ /^PCX/i ) {
        $f = 'PCX';
    }
    elsif ( $in =~ /^RLE/i ) {
        $f = 'RLE';
    }
    elsif ( $in =~ /^THIN/i ) {
        $f = 'THINK';
    }
    elsif ( $in =~ /^TIF/i ) {
        $f = 'TIFF';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid hardcopy format '$in'\n");
        return;
    }

    $self->write("HARDC:FORM $f");
    $self->_debug();
}


sub get_hardcopy_layout {
    my $self = shift;
    my $r    = $self->query("HARDC:LAY?");
    $r = $self->_parseResponse( $r, qw(PORTR LAN) );
    $self->_debug();
    return _bloat( $r, { PORTR => 'PORTRAIT', LAN => 'LANDSCAPE' } );
}


sub set_hardcopy_layout {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['layout'] );
    my $lay;

    if ( $in =~ /^\s*(P|N)/i ) {
        $lay = 'PORTR';
    }
    elsif ( $in =~ /^\s*(L|R)/i ) {
        $lay = 'LAN';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid hardcopy layout '$in'\n");
        return;
    }
    $self->write("HARDC:LAY $lay");
    $self->_debug();
}


sub get_hardcopy_port {
    my $self = shift;
    my $r    = $self->query("HARDC:PORT?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_hardcopy_port {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['port'] );
    my $p = _keyword( $in, qw(USB CEN RS232 GPI) );
    if ( $p ne 'USB' ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid hardcopy port '$in'\n");
        return;
    }
    $self->write("HARDC:PORT $p");
    $self->_debug();
}


sub get_hardcopy {
    my $self = shift;

    my $h = {};
    $h->{format} = $self->get_hardcopy_format();
    $h->{layout} = $self->get_hardcopy_layout();
    $h->{port}   = $self->get_hardcopy_port();
    return $h;
}


sub set_hardcopy {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );
    $self->set_hardcopy_format($tail) if exists $tail->{format};
    $self->set_hardcopy_layout($tail) if exists $tail->{layout};
    $self->set_hardcopy_port($tail)   if exists $tail->{port};
}


sub get_image {
    my $self = shift;
    my ( $file, $force, $tail ) = $self->_check_args( \@_, qw(file force) );

    my $ovr = 0;
    if ( defined($force) ) {
        if ( $force =~ /^\s*(T|[1-9]|Y)/i ) {
            $ovr = 1;
        }
        elsif ( $force =~ /^s*(F|0|N)/i ) {
            $ovr = 0;
        }
        else {
            Lab::Exception::CorruptParameter->throw(
                "Invalid 'force overwrite' flag  '$force'\n");
            return;
        }
    }

    # do file check before image transfer
    if ( defined($file) ) {

        if ( -e $file && ( !$ovr || !-w $file ) ) {
            Lab::Exception::CorruptParameter->throw(
                "Output file $file exists, not writable, force overwrite not set\n"
            );
            return;
        }
    }

    $self->set_hardcopy($tail);
    my $head = $self->get_header();
    $self->set_header(0);

    # default 30s timeout, unlimited length, maybe no \n at end
    # note that we really need READ_BUFFER to be set correctly
    # for efficient image reading.
    my $args = {};
    $args->{timeout}     = 30;
    $args->{read_length} = -1;
    $args->{timeout}     = $tail->{timeout} if exists( $tail->{timeout} );
    
    $args->{brutal} = 1;    # read to the very end
    $args->{no_LF} = 1;

    my $r;
    $self->write("HARDC STAR");
    $r = $self->read($args);
    $self->set_header($head);

    carp("No image data read") unless defined($r);
    if ( defined($file) && defined($r) ) {
        open( IMG, ">$file" ) || croak("unable to open $file for writing");
        print IMG $r;
        close(IMG);
    }

    return $r;
}


sub get_horiz_view {
    my $self = shift;
    my $r    = $self->query("HOR:VIEW?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(MAI WINDOW ZONE) );
    return _bloat( $r, { MAI => 'MAIN' } );
}


sub set_horiz_view {
    my $self = shift;
    my ($v) = $self->_check_args_strict( \@_, ['view'] );
    $v = _keyword( $v, qw(MAI WIN ZON) );
    $v = _bloat( $v, { WIN => 'WINDOW', ZON => 'ZONE' } );
    $self->write("HOR:VIEW $v");
    $self->_debug();
}


sub get_horiz_position {
    my $self = shift;
    my $r    = $self->query("HOR:POS?");
    $self->_debug();

    return $self->_parseReply($r);
}


sub set_horiz_position {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['time'] );

    my $t = _parseNRf( $in, 's' );
    if ( $t eq 'MIN' || $t eq 'MAX' || $t =~ /ERR/ ) {
        Lab::Exception::CorruptParameter->throw("Invalid time input '$in'\n");
        return;
    }
    $t = sprintf( '%.3e', $t );

    $self->write("HOR:POS $t");
    $self->_debug();
}


sub get_delay_position {
    my $self = shift;
    my $r    = $self->query("HOR:DEL:POS?");
    $self->_debug();
    $r = $self->_parseReply($r);
    return $r;
}


sub set_delay_position {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['delaytime'] );
    my $t = _parseNRf( $in, 's' );
    if ( $t eq 'MIN' || $t eq 'MAX' || $t =~ /ERR/ ) {
        Lab::Exception::CorruptParameter->throw("Invalid time input '$in'\n");
        return;
    }
    $t = sprintf( '%.3e', $t );
    $self->write("HOR:DEL:POS $t");
    $self->_debug();
}


sub get_horiz_scale {
    my $self = shift;
    my $r    = $self->query("HOR:SCA?");
    $self->_debug();
    $r = $self->_parseReply($r);
    return $r;
}


sub set_horiz_scale {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['scale'] );

    my $s = _parseNRf( $in, 's', 's/div', 'Hz', 'Hz/div' );

    if ( $s eq 'MIN' || $s eq 'MAX' || $s =~ /ERR/ || $s <= 0 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid time scale input '$in'\n");
        return;
    }

    $s = sprintf( '%.2e', $s );
    my $ss = substr( $s, 0, 4 );
    if ( $ss ne '1.00' && $ss ne '2.50' && $ss ne '5.00' ) {
        carp("warning: $s will be rounded to nearest acceptable value");
    }

    $self->write("HOR:SCA $s");
    $self->_debug();
}


sub get_delay_scale {
    my $self = shift;
    my $r    = $self->query("HOR:DEL:SCA?");
    $self->_debug();
    $r = $self->_parseReply($r);
    return $r;
}


sub set_del_scale {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['delayscale'] );

    my $s = _parseNRf( $in, 's', 's/div', 'Hz', 'Hz/div' );

    if ( $s eq 'MIN' || $s eq 'MAX' || $s =~ /ERR/ || $s <= 0 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid time scale input '$in'\n");
        return;
    }

    $s = sprintf( '%.2e', $s );
    my $ss = substr( $s, 0, 4 );
    if ( $ss ne '1.00' && $ss ne '2.50' && $ss ne '5.00' ) {
        carp("warning: $s will be rounded to nearest acceptable value");
    }

    $self->write("HOR:DEL:SCA $s");
    $self->_debug();
}


sub get_recordlength {
    return 2500;
}


sub get_horizontal {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    my $h = {};

    $h->{view}         = $self->get_horiz_view($tail);
    $h->{time}         = $self->get_horiz_position($tail);
    $h->{delaytime}    = $self->get_delay_position($tail);
    $h->{scale}        = $self->get_horiz_scale($tail);
    $h->{delayscale}   = $self->get_delay_scale($tail);
    $h->{recordlength} = $self->get_recordlength($tail);

    return $h;
}


sub set_horizontal {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    $self->set_horiz_view($tail)     if exists $tail->{view};
    $self->set_horiz_position($tail) if exists $tail->{time};
    $self->set_horiz_scale($tail)    if exists $tail->{scale};
    $self->set_delay_position($tail) if exists $tail->{delaytime};
    $self->set_delay_scale($tail)    if exists $tail->{delayscale};
}


sub get_math_definition {
    my $self = shift;
    my $r    = $self->query("MATH:DEFINE?");
    $self->_debug();

    if ( $r =~ /^\"/ ) {
        $r =~ s/^\"//;
        $r =~ s/\"$//;
        $r =~ s/\"\"/"/g;
    }
    elsif ( $r =~ /^\'/ ) {
        $r =~ s/^\'//;
        $r =~ s/\'$//;
        $r =~ s/\'\'/'/g;
    }
    else {
        croak("quoted string error");
    }
    return $r;
}


sub set_math_definition {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['math'] );

    $in =~ s/\s+//g;
    $in = uc($in);

    if ( $in =~ /^FFT\(CH(\d)(,\w+)?\)/i ) {
        my $ch = $1;
        my $w  = '';
        $w = substr( $2, 1 ) if defined($2) && $2 ne '';
        $w = ',' . _keyword( $w, qw(HAN FLAT RECT) ) if $w ne '';
        $self->write("MATH:DEFINE \"FFT(CH${ch}${w})\"");
        $self->set_channel('MATH');
        $self->{device_channel}->{select}
            = $self->{chan_cache}->{MATH}->{select}
            = $self->{chan_cache}->{"CH${ch}"}->{select};
        $self->{chan_cache}->{"CH${ch}"}->{select} = 0;
    }
    else {
        my $c = _keyword(
            $in, qw(CH1+CH2 CH3+CH4 CH1–CH2 CH2–CH1
                CH3–CH4 CH4–CH3 CH1*CH2 CH3*CH4)
        );
        $self->write("MATH:DEFINE \"${c}\"");
    }
    $self->_debug();
}


sub get_math_position {
    my $self = shift;
    my $r    = $self->query("MATH:VER:POS?");
    $self->_debug();
    $r = $self->_parseReply($r);
    return _parseNRf($r);
}


sub set_math_position {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['position'] );

    my $y;
    $y = _parseNRf( $in, 'div', 'divs' );
    if ( $y =~ /ERR/ || $y eq 'MIN' || $y eq 'MAX' ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid MATH position input '$in'\n");
        return;
    }
    $self->write("MATH:VER:POS $y");
    $self->_debug();
}


sub get_fft_xposition {
    my $self = shift;
    my $r    = $self->query("MATH:FFT:HOR:POS?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_fft_xposition {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['fft_xposition'] );

    my $p = _parseNRf( $in, '%', 'pct', 'percent' );
    $p = 0   if $p eq 'MIN';
    $p = 100 if $p eq 'MAX';
    $p = sprintf( '%d', $p ) if $p !~ /ERR/;
    if ( $p =~ /ERR/ || $p < 0 || $p > 100 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid FFT position input '$in'\n");
        return;
    }
    $self->write("MATH:FFT:HOR:POS $p");
    $self->_debug();
}


sub get_fft_xscale {
    my $self = shift;
    my $r    = $self->query("MATH:FFT:HOR:SCA?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_fft_xscale {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['fft_xscale'] );
    my $z = _parseNRf( $in, 'x' );
    $z = 1  if $z eq 'MIN';
    $z = 10 if $z eq 'MAX';

    if ( $z =~ /ERR/ || $z <= 0 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid FFT xscale input '$in'\n");
        return;
    }

    my $zoom;
    if ( $z < 1.5 ) {
        $zoom = 1;
    }
    elsif ( $z < 3.5 ) {
        $zoom = 2;
    }
    elsif ( $z < 7.5 ) {
        $zoom = 5;
    }
    else {
        $zoom = 10;
    }

    carp("FFT scale rounded to valid value") if abs( $z - $zoom ) > 0.01;
    $self->write("MATH:FFT:HOR:SCA $zoom");
    $self->_debug();
}


sub get_fft_position {
    my $self = shift;
    my $r    = $self->query("MATH:FFT:VER:POS?");
    $self->_debug();
    return _parseReply($r);
}


sub set_fft_position {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['fft_position'] );
    my $p = _parseNRf( $in, 'div', 'divs' );

    if ( $p eq 'MIN' || $p eq 'MAX' || $p =~ /ERR/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid FFT yposition '$in'\n");
        return;
    }
    $self->write("MATH:FFT:VER:POS $p");
    $self->_debug();
}


sub get_fft_scale {
    my $self = shift;
    my $r    = $self->query("MATH:FFT:VER:SCA?");
    $self->_debug();
    return _parseReply($r);
}


sub set_fft_scale {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, ['fft_scale'] );
    my $z = _parseNRf( $in, 'x' );

    $z = 0.5 if $z eq 'MIN';
    $z = 10  if $z eq 'MAX';

    if ( $z =~ /ERR/ || $z <= 0 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid fft y scale input '$in'\n");
        return;
    }

    my $zoom;
    if ( $z < 0.75 ) {
        $zoom = 0.5;
    }
    elsif ( $z < 1.5 ) {
        $zoom = 1;
    }
    elsif ( $z < 3.5 ) {
        $zoom = 2;
    }
    elsif ( $z < 7.5 ) {
        $zoom = 5;
    }
    else {
        $zoom = 10;
    }

    carp("fft_scale adjusted to valid value") if abs( $z - $zoom ) > 0.01;
    $self->write("MATH:FFT:VER:POS $zoom");
    $self->_debug();
}


# do our own cache handling, doesn't fit the normal scheme

sub get_measurement_type {
    my $self = shift;
    my ( $in, $tail ) = $self->_check_args( \@_, ['measurement'] );
    $in = 'IMM' unless defined($in);

    my $n;
    if ( $in =~ /^\s*imm/i || $in =~ /^\s*$/ ) {
        $n = 'imm';
    }
    elsif ( $in =~ /^\s*(\d)\s*$/ ) {
        $n = $1;
        $n = undef if $n < 1 || $n > 5;
    }

    if ( !defined($n) ) {
        Lab::Exception::CorruptParameter->throw(
            "invalid measurement# '$in' \n");
        return;
    }

    $tail->{read_mode} = $self->{config}->{default_read_mode}
        unless exists( $tail->{read_mode} ) && defined( $tail->{read_mode} );
    $tail->{read_mode} = 'device' if $self->{config}->{no_cache};

    if ( $tail->{read_mode} eq 'cache'
        && defined( $self->{device_cache}->{"meas_type_$n"} ) ) {
        return $self->{device_cache}->{"meas_type_$n"};
    }

    my $nm;
    if ( $n eq 'imm' ) {
        $nm = 'IMM';
    }
    else {
        $nm = "MEAS$n";
    }

    my $r = $self->query("MEASU:${nm}:TYP?");
    $self->_debug();
    $r = _parseReply(
        $r,
        qw(FREQ MEAN PERI PHA PK2 CRM MINI MAXI RIS FALL PW NWI NONE)
    );

    $r = _bloat(
        $r, {
            FREQ => 'FREQUENCY', PERI => 'PERIOD', PHA  => 'PHASE',
            PK2  => 'PK2PK',     CRM  => 'CRMS',   MINI => 'MINIMUM',
            MAXI => 'MAXIMUM',   RIS  => 'RISE',   PWD  => 'PWIDTH',
            NWI  => 'NWIDTH'
        }
    );
    $self->{device_cache}->{"meas_type_$n"} = $r;
    return $r;
}


sub set_measurement_type {
    my $self = shift;
    my ( $in, $type, $tail )
        = $self->_check_args( \@_, qw(measurement measurement_type) );

    if ( !defined($in) || $in =~ /^\s*$/ ) {
        $in = 'IMM';
    }
    elsif ( !defined($type) ) {
        $type = $in;
        $in   = 'IMM';
    }

    my $n;
    my $nm;
    if ( $in =~ /^\s*imm/i ) {
        $n  = 'imm';
        $nm = 'IMM';
    }
    elsif ( $in =~ /^\s*(\d)\s*$/ ) {
        $n  = $1;
        $nm = "MEAS${n}";
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "invalid measurement# '$in' \n");
        return;
    }

    my $ty;
    if ( $n ne 'imm' && $type =~ /^\s*NONE/i ) {
        $ty = 'NONE';
    }
    else {
        $ty = _keyword(
            $type,
            qw(FREQ MEAN PERI PHA PK2 CRM MINI MAXI RIS FALL PW NWI)
        );
    }
    $self->write("MEASU:${nm}:TYP $ty");
    $self->_debug();
    $self->get_measurement_type( measurement => $n );
}


sub get_measurement_units {
    my $self = shift;
    my ( $in, $tail ) = $self->_check_args( \@_, ['measurement'] );

    my $n;
    my $nm;
    if ( !defined($in) || $in =~ /^\s*imm/i || $in =~ /^\s*$/ ) {
        $n  = 'imm';
        $nm = 'IMM';
    }
    elsif ( $in =~ /^\s*(\d)\s*$/ ) {
        $n  = $1;
        $nm = "MEAS${n}";
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "invalid measurement# '$in' \n");
        return;
    }

    $tail->{read_mode} = $self->{config}->{default_read_mode}
        unless exists( $tail->{read_mode} ) && defined( $tail->{read_mode} );
    $tail->{read_mode} = 'device' if $self->{config}->{no_cache};

    if ( $tail->{read_mode} eq 'cache'
        && defined( $self->{device_cache}->{"meas_units_${n}"} ) ) {
        return $self->{device_cache}->{"meas_units_${n}"};
    }

    my $r = $self->query("MEASU:${nm}:UNI?");
    $self->_debug();
    $r = $self->_parseReply($r);
    $self->{device_cache}->{"meas_units_${n}"} = $r;
    return $r;
}


sub get_measurement_source {
    my $self = shift;
    my ( $in, $tail ) = $self->_check_args( \@_, ['measurement'] );

    my $n;
    my $nm;
    if ( !defined($in) || $in =~ /^\s*imm/i || $in =~ /^\s*$/ ) {
        $n  = 'imm';
        $nm = 'IMM';
    }
    elsif ( $in =~ /^\s*(\d)\s*$/ ) {
        $n  = $1;
        $nm = "MEAS${n}";
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "invalid measurement# '$in' \n");
        return;
    }

    $tail->{read_mode} = $self->{config}->{default_read_mode}
        unless exists( $tail->{read_mode} ) && defined( $tail->{read_mode} );
    $tail->{read_mode} = 'device' if $self->{config}->{no_cache};

    if ( $tail->{read_mode} eq 'cache'
        && defined( $self->{device_cache}->{"meas_source_${n}"} ) ) {
        return $self->{device_cache}->{"meas_source_${n}"};
    }

    my $j = '';
    $j = 1 if $n eq 'imm';

    my $r = $self->query("MEASU:${nm}:SOU${j}?");
    $self->_debug();
    $r = $self->_parseReply($r);
    $self->{device_cache}->{"meas_source_${n}"} = $r;
    return $r;
}


sub set_measurement_source {
    my $self = shift;
    my ( $in, $inw )
        = $self->_check_args( \@_, qw(measurement measurement_source) );

    if ( !defined($inw) ) {
        $inw = $in;
        $in  = 'IMM';
    }

    my $n;
    my $nm;
    if ( !defined($in) || $in =~ /^\s*imm/i || $in =~ /^\s*$/ ) {
        $n  = 'imm';
        $nm = 'IMM';
    }
    elsif ( $in =~ /^\s*(\d)\s*$/ ) {
        $n  = $1;
        $nm = "MEAS${n}";
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "invalid measurement# '$in' \n");
        return;
    }

    my $j = '';
    $j = 1 if $n eq 'imm';

    my $wfm = _keyword( $inw, qw(CH1 CH2 CH3 CH4 MATH) );
    $self->write("MEASU:${nm}:SOU${j} $wfm");
    $self->_debug();
    $self->{device_cache}->{"meas_source_$n"} = $wfm;
}


sub get_measurement_value {
    my $self = shift;
    my ($in) = $self->_check_args( \@_, 'measurement' );

    my $n;
    my $nm;
    if ( !defined($in) || $in =~ /^\s*imm/i || $in =~ /^\s*$/ ) {
        $n  = 'imm';
        $nm = 'IMM';
    }
    elsif ( $in =~ /^\s*(\d)\s*$/ ) {
        $n  = $1;
        $nm = "MEAS${n}";
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "invalid measurement# '$in' \n");
        return;
    }

    if ( $n ne 'imm' ) {
        if ( $self->get_measurement_type( measurement => $n ) eq 'NONE' ) {
            Lab::Exception::CorruptParameter->throw(
                "Measurement $n type set to 'NONE'\n");
            return;
        }
    }

    my $wfm = $self->get_measurement_source( measurement => $n );
    if ( !$self->get_visible( source => $wfm ) ) {
        Lab::Exception::CorruptParameter->throw(
            "Meaurement only avail on visible traces\n");
        return;
    }

    my $r = $self->query("MEASU:${nm}:VAL?");
    $self->_debug();
    return _parseNRf($r);
}


sub trigger {
    my $self = shift;
    $self->write("TRIG FORC");
    $self->_debug();
}


sub get_trig_coupling {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:EDGE:COUP?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(AC DC HFR LFR NOISE) );
    return _bloat(
        $r,
        { HFR => 'HFREJ', LFR => 'LFREJ', NOISE => 'NOISEREJ' }
    );
}


sub set_trig_coupling {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'coupling' );

    my $c = _keyword( $in, qw(AC DC HFR LFR NOISE) );

    $self->write("TRIG:MAI:EDGE:COUP $c");
    $self->_debug();
}


sub get_trig_slope {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:EDGE:SLO?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(FALL RIS) );
    $r = 'RISE' if $r eq 'RIS';
    return $r;
}


sub set_trig_slope {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'slope' );

    my $sl;
    if ( $in =~ /^\s*(ri|up|pos|\+)/i ) {
        $sl = 'RIS';
    }
    elsif ( $in =~ /^\s*(fa|d|neg|\-)/i ) {
        $sl = 'FALL';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "invalid trigger slope '$in'\n");
        return;
    }

    $self->write("TRIG:MAI:EDGE:SLO $sl");
    $self->_debug();
}


sub get_trig_source {
    my $self = shift;
    my ( $in, $tail ) = $self->_check_args( \@_, 'type' );
    my $type;

    if ( defined($in) ) {
        $type = _keyword( $in, qw(EDGE PUL VID) );
    }
    else {
        $type = $self->get_trig_type();
    }

    my $t = lc( substr( $type, 0, 1 ) );

    $tail->{read_mode} = $self->{config}->{default_read_mode}
        unless exists( $tail->{read_mode} ) && defined( $tail->{read_mode} );
    $tail->{read_mode} = 'device' if $self->{config}->{no_cache};

    if ( $tail->{read_mode} eq 'cache' ) {
        return $self->{device_cache}->{"${t}trig_source"}
            if defined( $self->{device_cache}->{"${t}trig_source"} );
    }

    my $r = $self->query("TRIG:MAI:${type}:SOU?");
    $self->_debug();
    $r = $self->_parseReply($r);
    $self->{device_cache}->{"${t}trig_source"} = $r;
    return $r;
}


sub set_trig_source {
    my $self = shift;
    my ( $in, $tail ) = $self->_check_args_strict( \@_, 'source' );

    my $s;
    if ( $in =~ /^\s*(CH[1-4]|EXT5?)/i ) {
        $s = uc($1);
    }
    elsif ( $in =~ /^\s*(AC|LINE)/i ) {
        $s = 'LINE';
    }
    elsif ( $in =~ /^\s*([1-4])\s*$/ ) {
        $s = "CH$1";
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid trigger source '$in'\n");
        return;
    }

    my $type;
    $type = $tail->{type} if exists( $tail->{type} );
    $type = $self->get_trig_type()
        unless defined $type;
    $type = _keyword( $type, qw(EDGE PUL VID) );
    my $t = lc( substr( $type, 0, 1 ) );

    $self->write("TRIG:MAI:${type}:SOU $s");
    $self->_debug();
    $self->{device_cache}->{"${t}trig_source"}
        = _bloat( $type, { PUL => 'PULSE', VID => 'VIDEO' } );
}


sub get_trig_frequency {
    my $self = shift;

    my $type = $self->get_trig_type();
    if ( $type eq 'VIDEO' ) {
        Lab::Exception::CorruptParameter->throw(
            "Trigger frequency not availible for 'VIDEO' type trigger\n");
        return;
    }

    my $r = $self->query("TRIG:MAI:FREQ?");
    $r = $self->_parseReply($r);
    if ( $r > 1e37 ) {
        $r = 1;

        #clear out error
        $self->get_error();
    }
    $self->_debug();
    return $r;
}


sub get_trig_holdoff {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:HOLDO:VAL?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_trig_holdoff {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'holdoff' );
    my $t = _parseNRf( $in, 's', 'sec' );

    $t = '5E-07' if $t eq 'MIN';
    $t = 10      if $t eq 'MAX';

    if ( $t =~ /ERR/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Error parsing holdoff '$in'\n");
        return;
    }

    if ( $t < 5e-7 || $t > 10 ) {
        Lab::Exception::CorruptParameter->throw(
            "Holdoff '$in' out of range (500ns..10s)\n");
        return;
    }
    $self->write("TRIG:MAI:HOLDO:VAL $t");
    $self->_debug();
}


sub get_trig_level {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:LEV?");
    $self->_debug();
    return _parseReply($r);
}


sub set_trig_level {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'level' );
    return if $self->get_trig_source() eq 'AC LINE';

    my $v = _parseNRf( $in, 'v' );

    if ( $v eq 'MIN' || $v eq 'MAX' || $v =~ /ERR/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid trigger level '$in'\n");
        return;
    }
    $v = sprintf( '%.3e', $v );
    $self->write("TRIG:MAI:LEV $v");
    $self->_debug();
}


sub get_trig_mode {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:MOD?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(AUTO NORM) );
    $r = 'NORMAL' if $r eq 'NORM';
    return $r;
}


sub set_trig_mode {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'mode' );

    my $m = _keyword( $in, qw(AUTO NORM) );
    $self->write("TRIG:MAI:MOD $m");
    $self->_debug();
}


sub get_trig_type {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:TYP?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(EDGE PUL VID) );
    return _bloat( $r, { PUL => 'PULSE', VID => 'VIDEO' } );
}


sub set_trig_type {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'type' );

    my $t = _keyword( $in, qw(EDG PUL VID) );
    $t = 'EDGE' if $t eq 'EDG';
    $self->write("TRIG:MAI:TYP $t");
    $self->_debug();
}


sub get_trig_pulse_width {
    my $self = shift;

    my $r = $self->query("TRIG:MAI:PUL:WID:WID?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_trig_pulse_width {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'width' );

    my $w = _parseNRf( $in, 's', 'sec' );
    $w = 33e-9 if $w eq 'MIN';
    $w = 10    if $w eq 'MAX';
    if ( $w =~ /ERR/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid trigger width '$in'\n");
        return;
    }
    $w = sprintf( '%.3e', $w );
    $self->write("TRIG:MAI:PUL:WID:WID $w");
    $self->_debug();
}


sub get_trig_pulse_polarity {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:PUL:WID:POL?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(POS NEG) );
    return _bloat( $r, { POS => 'POSITIVE', NEG => 'NEGATIVE' } );
}


sub set_trig_pulse_polarity {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'pulse_polarity' );
    my $pol;

    if ( $in =~ /^\s*(P|\+)/i ) {
        $pol = 'POSITIV';
    }
    elsif ( $in =~ /^\s*(N|M|\-)/i ) {
        $pol = 'NEGA';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid trigger polarity '$in'\n");
        return;
    }
    $self->write("TRIG:MAI:PUL:WID:POL $pol");
    $self->_debug();
}


sub get_trig_pulse_when {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:PUL:WID:WHEN?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(EQ NOTE IN OUT) );
    return _bloat(
        $r, {
            EQ => 'EQUAL',  NOTE => 'NOTEQUAL',
            IN => 'INSIDE', OUT  => 'OUTSIDE'
        }
    );
}


sub set_trig_pulse_when {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'pulse_when' );

    my $w;
    if ( $in =~ /^\s*(EQ|=)/i ) {
        $w = 'EQ';
    }
    elsif ( $in =~ /^\s*(NO|NE|!=|<>)/i ) {
        $w = 'NOTE';
    }
    elsif ( $in =~ /^\s*(IN|LT|<)/i ) {
        $w = 'IN';
    }
    elsif ( $in =~ /^\s*(OU|GT|>)/i ) {
        $w = 'OUT';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid trigger 'when' parameter '$in'\n");
        return;
    }
    $self->write("TRIG:MAI:PUL:WID:WHEN $w");
    $self->_debug();
}


sub get_trig_vid_line {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:VID:LINE?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_trig_vid_line {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'vid_line' );

    $in = 1 if $in eq 'MIN';
    if ( $in eq 'MAX' ) {
        my $std = $self->get_trig_vid_standard();
        $in = 525;
        $in = 625 if $std eq 'PAL';
    }
    $in = int($in) if $in =~ /^\s*\d+/;

    if ( $in =~ /ERR/ || $in < 1 || $in > 625 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid video trigger line '$in'\n");
        return;
    }

    $self->write("TRIG:MAI:VID:LINE $in");
    $self->_debug();
}


sub get_trig_vid_polarity {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:VID:POL?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(NORM INV) );
    return _bloat( $r, { NORM => 'NORMAL', INV => 'INVERTED' } );
}


sub set_trig_vid_polarity {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'vid_polarity' );

    my $p;
    if ( $in =~ /^\s*(N|\-)/i ) {
        $p = 'NORM';
    }
    elsif ( $in =~ /^\s*(I|\+)/i ) {
        $p = 'INV';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid video trigger polarity '$in'\n");
        return;
    }
    $self->write("TRIG:MAI:VID:POL $p");
    $self->_debug();
}


sub get_trig_vid_standard {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:VID:STAND?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(NTS PAL) );
    $r = 'NTSC' if $r eq 'NTS';
    return $r;
}


sub set_trig_vid_standard {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'vid_standard' );

    my $s;
    if ( $in =~ /^\s*(NTS|US|JP)/i ) {
        $s = 'NTS';
    }
    elsif ( $in =~ /^\s*(PAL|EU|UK|AU|SEC)/i ) {
        $s = 'PAL';
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid video trigger standard '$in'\n");
        return;
    }
    $self->write("TRIG:MAI:VID:STAND $s");
    $self->_debug();
}


sub get_trig_vid_sync {
    my $self = shift;
    my $r    = $self->query("TRIG:MAI:VID:SYNC?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(FIELD LINE ODD EVEN LINEN) );
    $r = 'LINENUM' if $r eq 'LINEN';
    return $r;
}


sub set_trig_vid_sync {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'vid_sync' );

    my $s = _keyword( $in, qw(FIELD LINE ODD EVEN LINEN) );
    $self->write("TRIG:MAI:VID:SYNC $s");
    $self->_debug();
}


sub get_trig_state {
    my $self = shift;
    my $r    = $self->query("TRIG:STATE?");
    $self->_debug();
    $r = $self->_parseReply($r);
}


sub get_data_width {
    my $self = shift;
    my $r    = $self->query("DAT:WID?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_data_width {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'nbytes' );
    my $n;

    if ( $in =~ /^\s*1\s*$/ ) {
        $n = 1;
    }
    elsif ( $in =~ /^\s*2\s*$/ ) {
        $n = 2;
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid bytes/sample '$in' should be 1, 2\n");
        return;
    }
    $self->write("DAT:WID $n");
    $self->_debug();
}


sub get_data_encoding {
    my $self = shift;
    my $r    = $self->query("DAT:ENC?");
    $self->_debug();
    $r = $self->_parseReply( $r, qw(ASCI RIB RPB SRI SRP) );
    return _bloat(
        $r, {
            ASCI => 'ASCII',     RIB => 'RIBINARY', RPB => 'RPBINARY',
            SRI  => 'SRIBINARY', SRP => 'SRPBINARY'
        }
    );
}


sub set_data_encoding {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'encoding' );
    my $e = _keyword( $in, qw(ASC RI RP SRI SRP) );
    $e = _bloat( $e, { ASC => 'ASCI', RI => 'RIB', RP => 'RPB' } );
    $self->write("DAT:ENC $e");
    $self->_debug();
}


sub get_data_start {
    my $self = shift;
    my $r    = $self->query("DAT:STAR?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_data_start {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'start' );

    $in = 1        if $in =~ /^\s*MIN/i;
    $in = 2500 - 1 if $in =~ /^\s*MAX/i;

    if ( $in !~ /^\s*(\d+)\s*$/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid waveform start sample# '$in'; should be 1..2500\n");
        return;
    }
    my $i = $in;
    if ( $i < 1 || $i >= 2500 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid waveform start sample# '$in'; should be 1..2500\n");
        return;
    }

    $self->write("DAT:STAR $i");
    $self->_debug();
}


sub get_data_stop {
    my $self = shift;
    my $r    = $self->query("DAT:STOP?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_data_stop {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'stop' );

    $in = 2    if $in =~ /^\s*MIN/i;
    $in = 2500 if $in =~ /^\s*MAX/i;

    if ( $in !~ /^\s*(\d+)\s*$/ ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid waveform stop sample# '$in'; should be 1..2500\n");
        return;
    }
    my $i = $in;
    if ( $i < 2 || $i > 2500 ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid waveform stop sample# '$in'; should be 1..2500\n");
        return;
    }

    $self->write("DAT:STOP $i");
    $self->_debug();
}


sub get_data_destination {
    my $self = shift;
    my $r    = $self->query("DAT:DEST?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_data_destination {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'destination' );

    my $d;
    if ( $in =~ /^\s*(REF)?([A-D])\s*$/i ) {
        $d = "REF" . uc($2);
    }
    else {
        Lab::Exception::CorruptParameter->throw(
            "Invalid waveform destination '$in'; should be REFA..REFD\n");
        return;
    }
    $self->write("DAT:DEST $d");
    $self->_debug();
}


sub set_data_init {
    my $self = shift;
    $self->write("DAT INIT");
    $self->_debug();
}


sub get_data_source {
    my $self = shift;
    my $r    = $self->query("DAT:SOU?");
    $self->_debug();
    return $self->_parseReply($r);
}


sub set_data_source {
    my $self = shift;
    my ($in) = $self->_check_args_strict( \@_, 'source' );

    my $s;

    if ( $in =~ /^\s*(CH)?([1-4])\s*$/i ) {
        $s = "CH$2";
    }
    elsif ( $in =~ /^\s*MATH\s*$/i ) {
        $s = 'MATH';
    }
    elsif ( $in =~ /^\s*(REF)?([A-D])\s*$/i ) {
        $s = "REF" . uc($2);
    }
    else {
        Lab::Exception::CorruptParameter->throw("Invalid waveform '$in'");
        return;
    }
    $self->write("DAT:SOU $s");
    $self->_debug();
}


sub get_data {
    my $self   = shift;
    my ($tail) = $self->_check_args( \@_ );
    my $h      = {};

    $h->{width}       = $self->get_data_width($tail);
    $h->{stop}        = $self->get_data_stop($tail);
    $h->{start}       = $self->get_data_start($tail);
    $h->{encoding}    = $self->get_data_encoding($tail);
    $h->{source}      = $self->get_data_source($tail);
    $h->{destination} = $self->get_data_destination($tail);
    return $h;
}


sub set_data {
    my $self = shift;
    my ($tail) = $self->_check_args( \@_ );

    $self->set_data_width($tail)      if exists $tail->{width};
    $self->set_data_start($tail)      if exists $tail->{start};
    $self->set_data_stop($tail)       if exists $tail->{stop};
    $self->set_data_encoding($tail)   if exists $tail->{encoding};
    $self->set_data_source($tail)     if exists $tail->{source};
    $self->set_data_destinatin($tail) if exists $tail->{destination};
}


sub get_waveform {
    my $self = shift;
    my ( $in, $tail ) = $self->_check_args( \@_, 'waveform' );
    my $args = clone($tail);
    delete( $args->{destination} ) if exists $args->{destination};
    delete( $args->{source} )      if exists $args->{source};

    if ( !$self->get_visible($in) ) {
        Lab::Exception::CorruptParameter->throw("Waveform '$in' not visible");
        return;
    }

    $args->{source} = $in if defined $in;
    my $dstop;
    if ( $in =~ /^\s*MATH/i ) {
        $dstop = $self->get_data_stop();
        if ( $dstop > 1024 ) {
            $self->set_data_stop(1024);
        }
        else {
            $dstop = undef;
        }
    }

    $self->set_data($args);

    my $header = $self->get_header();
    $self->set_header(1);
    my $dath = $self->query("DAT?");
    $self->_debug();
    
    
    my $wfpre = $self->query( "WFMP?", read_length => 2000, timeout => 10 );
    $self->_debug();

    my $wf = $self->query("CURV?", read_length => -1, timeout => 60);
    $self->_debug();
    
    $self->set_header($header);

    #    $self->set_data_stop($dstop) if defined $dstop;

    my $hd = scpi_parse($dath);
    my $hp = scpi_parse($wfpre,$hd);
    my $h = scpi_flat( scpi_parse( $wf, $hp ), $self->{scpi_override} );

    my (@dat);
    if ( $h->{'DAT:ENC'} =~ /^ASC/i ) {
        @dat = split( /,/, $h->{CURV} );
    }
    else {
        if ( substr( $h->{CURV}, 0, 2 ) !~ /^#\d/ ) {
            croak("bad binary curve data");
        }
        my $nx = substr( $h->{CURV}, 1, 1 );
        my $n  = substr( $h->{CURV}, 2, $nx );
        my $w  = $h->{'WFMP:BYT_N'};
        my $f  = $h->{'WFMP:BN_F'};
        my $xsb = $h->{'WFMP:BYT_O'};

        my $form;
        if ( $w == 1 ) {
            if ( $f eq 'RP' ) {
                $form = 'C';
            }
            else {
                $form = 'c';
            }
        }
        else {
            if ( $f eq 'RP' ) {
                $form = 'S';
            }
            else {
                $form = 's';
            }
            if ( $xsb eq 'MSB' ) {
                $form .= '>';
            }
            else {
                $form .= '<';
            }
        }
        $form .= '*';
        @dat = unpack( $form, substr( $h->{CURV}, $nx + 2 ) );
    }

    $h->{t} = [];
    my $j    = 0;
    my $j0   = $h->{'DAT:STAR'};
    my $x0   = $h->{'WFMP:XZE'};
    my $dx   = $h->{'WFMP:XIN'};
    my $xoff = $h->{'WFMP:PT_O'};
    my $y0   = $h->{'WFMP:YZE'};
    my $yoff = $h->{'WFMP:YOF'};
    my $dy   = $h->{'WFMP:YMU'};

    $h->{'WFMP:XUN'} = _unquote( $h->{'WFMP:XUN'} );
    $h->{'WFMP:YUN'} = _unquote( $h->{'WFMP:YUN'} );
    $h->{'WFMP:WFI'} = _unquote( $h->{'WFMP:WFI'} );

    if ( $h->{'WFMP:PT_F'} eq 'Y' ) {
        $h->{v} = [];
        for ( $j = 0; $j <= $#dat; $j++ ) {
            $h->{t}->[ $j0 + $j ] = $x0 + $dx * ( $j - $xoff );
            $h->{v}->[ $j0 + $j ] = $y0 + $dy * ( $dat[$j] - $yoff );
        }
        $h->{'DAT:STOP'} = $j0 + $#dat;
    }
    else {    # envelope
        $h->{vmin} = [];
        $h->{vmax} = [];
        for ( $j = 0; $j <= $#dat; $j += 2 ) {
            $h->{t}->[ $j0 + $j / 2 ] = $x0 + $dx * ( $j + 1 - $xoff );
            $h->{vmin}->[ $j0 + $j / 2 ]
                = $y0 + $dy * ( $dat[$j] - $yoff );
            $h->{vmax}->[ $j0 + $j / 2 ]
                = $y0 + $dy * ( $dat[ $j + 1 ] - $yoff );
        }
        $h->{'DAT:STOP'} = $j0 + $#dat / 2;
    }

    return $h;
}

# remove scpi style quoting
sub _unquote {
    my $str = shift;
    return ''   unless defined($str);
    return $str unless $str =~ /^(\'|\")/;
    if ( $str =~ /^\'(.*)\'$/ ) {
        $str = $1;
        $str =~ s/\'\'/'/g;
    }
    elsif ( $str =~ /^\"(.*)\"$/ ) {
        $str = $1;
        $str =~ s/\"\"/"/g;
    }
    return $str;
}


sub create_waveform {
    my $self = shift;
    my ( $it0, $it1, $n, $vfunc, $tail )
        = $self->_check_args( \@_, qw(tstart tstop nbins vfunc) );

    $n = 2500 if !defined($n);
    $n = int($n);
    $n = 2500 if $n <= 0;

    my ( $t0, $t1 );

    if ( defined($it0) xor defined($it1) ) {
        Lab::Exception::CorruptParameter->throw(
            "Should define BOTH t0 and t1, or neither");
        return;
    }

    if ( defined($it0) ) {
        $t0 = _parseNRf( $it0, 's', 'sec' );
        if ( $t0 =~ /(MIN|MAX|ERR)/i ) {
            Lab::Exception::CorruptParameter->throw("Invalid time '$it0'");
            return;
        }
    }

    if ( defined($it1) ) {
        $t1 = _parseNRf( $it1, 's', 'sec' );
        if ( $t1 =~ /(MIN|MAX|ERR)/i ) {
            Lab::Exception::CorruptParameter->throw("Invalid time '$it1'");
            return;
        }
    }

    my $hwfd = {};
    $hwfd->{t} = [];
    my $t = $hwfd->{t};

    $hwfd->{'DAT:STAR'} = 1;
    $hwfd->{'DAT:STOP'} = $n;
    if ( defined($t0) ) {
        $hwfd->{'WFMP:XZE'} = sprintf( '%.4e', $t0 );
        my $dt = ( $t1 - $t0 );
        $dt = $dt / ( $n - 1 ) if $n > 1;
        $hwfd->{'WFMP:XIN'} = sprintf( '%.4e', $dt );

        for ( my $j = 1; $j <= $n; $j++ ) {
            $t->[$j] = $t0 + ( $j - 1 ) * $dt;
        }

    }
    if ( !defined($t0) ) {
        for ( my $j = 1; $j <= $n; $j++ ) {
            $t->[$j] = undef;
        }
    }

    $hwfd->{'WFMP:PT_F'} = 'Y';

    if ( defined($vfunc) ) {
        if ( ref($vfunc) ne 'CODE' ) {
            Lab::Exception::CorruptParameter->throw(
                "not a pointer to routine for filling voltages");
            return;
        }
        if ( !defined($t0) ) {
            Lab::Exception::CorruptParameter->throw(
                "cannot fill voltages without t0, t1 defined");
            return;
        }

        my ( $v0, $v1, $vmin, $vmax );

        for ( my $j = 1; $j <= $n; $j++ ) {
            ( $v0, $v1 ) = &{$vfunc}( $t->[$j] );    # call user function
            if ( defined($v1) ) {    # two values: doing envelope waveform
                if ( $v1 < $v0 ) {    # v1 > v0, swap if needed
                    my $vt = $v1;
                    $v1 = $v0;
                    $v0 = $vt;
                }
                $hwfd->{'WFMP:PT_F'} = 'ENV';
                $hwfd->{vmin} = [] unless exists $hwfd->{vmin};
                $hwfd->{vmax} = [] unless exists $hwfd->{vmax};
                $hwfd->{vmin}->[$j] = $v0;
                $hwfd->{vmax}->[$j] = $v1;
                if ( exists( $hwfd->{v} ) ) {
                    Lab::Exception::CorruptParameter->throw(
                        "Invalid mix of v; vmin,vmax");
                    return;
                }
                $n = 1250 if $n > 1250;    # envelope has fewer max bins
            }
            else {
                $hwfd->{v} = [] unless exists $hwfd->{v};
                $hwfd->{v}->[$j] = $v0;
                if ( exists( $hwfd->{vmin} ) ) {
                    Lab::Exception::CorruptParameter->throw(
                        "Invalid mix of v; vmin,vmax");
                    return;
                }
                $v1 = $v0;                 # need this for the max/min
            }

            $vmin = $v0 unless defined $vmin && $vmin < $v0;
            $vmax = $v1 unless defined $vmax && $vmax > $v1;
        }
    }
    return $hwfd;
}


sub put_waveform {
    my $self = shift;
    my ( $hwfm, $tail ) = $self->_check_args_strict( \@_, ['waveform'] );

    # extra 'data' call parameters should override info in waveform, but
    # tricky to get it right...ignore call parameters for now
    #    my $args = clone($tail);
    #    delete($args->{source}) if exists $args->{source};
    #    $self->set_data($args);

    my $ypos;
    my $ysca;

    if ( exists( $tail->{position} ) ) {
        $ypos = _parseNRf( $tail->{position}, 'div', 'division' );
        $ypos = 5  if $ypos eq 'MAX';
        $ypos = -5 if $ypos eq 'MIN';
        if ( $ypos eq 'ERR' || $ypos > 5 || $ypos < -5 ) {
            Lab::Exception::CorruptParameter->throw(
                "Invalid position '$tail->{position}'");
            return;
        }
    }
    if ( exists( $tail->{scale} ) ) {
        $ysca = _parseNRf( $tail->{scale}, 'V/div' );
        $ysca = 1e-3 if $ysca eq 'MIN';
        $ysca = 10   if $ysca eq 'MAX';
        if ( $ysca eq 'ERR' || $ysca < 1e-3 || $ysca > 10 ) {
            Lab::Exception::CorruptParameter->throw(
                "Invalid scale '$tail->{scale}'");
            return;
        }
    }

    my $fmt;
    $fmt = $tail->{encoding} if exists $tail->{encoding};
    $fmt = $hwfm->{'DAT:ENC'}
        if !defined($fmt) && exists( $hwfm->{'DAT:ENC'} );
    $fmt = $self->get_data_encoding() if !defined($fmt);
    $fmt = _keyword( $fmt, qw(ASC RI RP SRI SRP) );
    $fmt = _bloat( $fmt, { ASC => 'ASCI', RI => 'RIB', RP => 'RPB' } );
    $hwfm->{'DAT:ENC'} = $fmt;

    my $wd;
    $wd = $tail->{data_width} if exists $tail->{data_width};
    $wd = $hwfm->{'DAT:WID'} if !defined($wd) && exists $hwfm->{'DAT:WID'};
    $wd = $self->get_data_width() if !defined($wd);
    $wd = int( 0.5 + $wd );
    if ( $wd < 1 || $wd > 2 ) {
        Lab::Exception::CorruptParameter->throw("Invalid data width '$wd'");
        return;
    }
    $hwfm->{'DAT:WID'} = $wd;

    my ( $datamin, $datamax );
    if ( $wd == 1 ) {
        if ( $fmt =~ /RP/ ) {
            $datamin = 0x00;
            $datamax = 0xff;
        }
        else {
            $datamin = -128;
            $datamax = 127;
        }
    }
    else {
        if ( $fmt =~ /RP/ ) {
            $datamin = 0x0000;
            $datamax = 0xffff;
        }
        else {
            $datamin = -32768;
            $datamax = 32767;
        }
    }

    if ( defined($ypos) || defined($ysca) ) {
        my $ycenter = 0;    # okay for signed integer binary and ascii
        my $ymul;
        if ( $wd == 1 ) {
            $ycenter = 127 if $fmt =~ /^\s*S?RP/i;
            $ymul = 25;
        }
        else {
            $ycenter = 32767 if $fmt =~ /^\s*S?RP/i;
            $ymul = 6554;
        }

        if ( defined($ypos) ) {
            $hwfm->{'WFMP:YZE'} = 0;
            $hwfm->{'WFMP:YOF'} = int( $ycenter + $ypos * $ymul );
        }

        if ( defined($ysca) ) {
            $hwfm->{'WFMP:YMU'} = sprintf( '%.3e', $ysca / $ymul );
        }
    }

    my $rawdata;

    my ( $xmin, $xmax, $ymin, $ymax, $jmin, $jmax );
    my $ptf = 'Y';
    $ptf = $hwfm->{'WFMP:PT_F'} if exists $hwfm->{'WFMP:PT_F'};

    my $jlim = 2500;
    $jlim = 1250 if $ptf ne 'Y';    # envelope, fewer bins

    my ( $jstart, $jstop );

    if ( exists( $tail->{start} ) ) {
        $jstart = _parseNRf( $tail->{start} );
        $jstart = 1 if $jstart eq 'MIN';
        $jstart = $jlim - 1 if $jstart eq 'MAX';
        if ( $jstart eq 'ERR' || $jstart < 1 || $jstart >= $jlim ) {
            Lab::Exception::CorruptParameter->throw(
                "Invalid start point '$tail->{start}'");
            return;
        }
    }
    else {
        $jstart = $hwfm->{'DAT:STAR'} if exists $hwfm->{'DAT:STAR'};
        $jstart = 1 unless defined $jstart;
    }

    if ( exists( $tail->{stop} ) ) {
        $jstop = _parseNRf( $tail->{stop} );
        $jstop = 2 if $jstop eq 'MIN';
        $jstop = $jlim if $jstop eq 'MAX';
        if ( $jstop eq 'ERR' || $jstop < 2 || $jstop > $jlim ) {
            Lab::Exception::CorruptParameter->throw(
                "Invalid stop point '$tail->{stop}'");
            return;
        }
    }
    else {
        $jstop = $hwfm->{'DAT:STOP'} if exists $hwfm->{'DAT:STOP'};
        $jstop = $jlim unless defined $jstop;
    }

    for ( my $j = 1; $j <= $jlim; $j++ ) {
        last if defined($jmin) && !defined( $hwfm->{t}->[$j] );
        next unless defined( $hwfm->{t}->[$j] );
        $jmin = $j unless defined $jmin && $jmin < $j;
        $jmax = $j unless defined $jmax && $jmax > $j;
        my $x = $hwfm->{t}->[$j];
        $xmin = $x unless defined $xmin && $xmin < $x;
        $xmax = $x unless defined $xmax && $xmax > $x;

        if ( $ptf eq 'Y' ) {
            my $y = $hwfm->{v}->[$j] || 0;
            $ymin = $y unless defined $ymin && $ymin < $y;
            $ymax = $y unless defined $ymax && $ymax > $y;
        }
        else {
            my $y0 = $hwfm->{vmin}->[$j] || 0;
            my $y1 = $hwfm->{vmax}->[$j] || 0;
            $ymin = $y0 unless defined $ymin && $ymin < $y0;
            $ymax = $y1 unless defined $ymax && $ymax > $y1;
        }
    }

    $hwfm->{'WFMP:XZE'} = $xmin unless exists $hwfm->{'WFMP:XZE'};
    $hwfm->{'WFMP:XIN'} = ( $xmax - $xmin ) / ( $jmax - $jmin )
        unless exists $hwfm->{'WFMP:XIN'};

    $jstart = $jmin if $jmin > $jstart;
    $jstop  = $jmax if $jmax < $jstop;

    if ( $jstart >= $jstop ) {
        Lab::Exception::CorruptParameter->throw(
            "Invalid start ($jstart) >= stop ($jstop)");
        return;
    }

    $hwfm->{'DAT:STAR'} = $jstart;
    $hwfm->{'DAT:STOP'} = $jstop;

    # voltage = (binary - yoffset)*ymul + yzero
    # binary = (voltage-yzero)/ymul + yoffset

    $hwfm->{'WFMP:YOF'} = 0 unless exists $hwfm->{'WFMP:YOF'};
    my $yoff = $hwfm->{'WFMP:YOF'};
    $hwfm->{'WFMP:YZE'} = sprintf( '%.3e', $ymin - ( $ymax - $ymin ) / 200 )
        unless exists $hwfm->{'WFMP:YZE'};
    my $yzero = $hwfm->{'WFMP:YZE'};
    $hwfm->{'WFMP:YMU'} = sprintf( '%.3e', ( $ymax - $ymin ) / 200 )
        unless exists $hwfm->{'WFMP:YMU'};
    my $ymult = $hwfm->{'WFMP:YMU'};

    my ( @dat, $datapt );
    my $ds = 0;

    if ( $ptf eq 'Y' ) {
        for ( my $j = $jmin; $j <= $jmax; $j++ ) {
            $datapt
                = int( 0.5 + $yoff + ( $hwfm->{v}->[$j] - $yzero ) / $ymult );
            $datapt = $datamin if $datapt < $datamin;
            $datapt = $datamax if $datapt > $datamax;
            push( @dat, $datapt );
            $ds++;
        }
    }
    else {
        for ( my $j = $jmin; $j <= $jmax; $j += 2 ) {
            $datapt = int(
                0.5 + $yoff + ( $hwfm->{vmin}->[$j] - $yzero ) / $ymult );
            $datapt = $datamin if $datapt < $datamin;
            $datapt = $datamax if $datapt > $datamax;
            push( @dat, $datapt );

            $datapt = int(
                0.5 + $yoff + ( $hwfm->{vmax}->[$j] - $yzero ) / $ymult );
            $datapt = $datamin if $datapt < $datamin;
            $datapt = $datamax if $datapt > $datamax;
            push( @dat, $datapt );

            $ds += 2;
        }
    }

    if ( $fmt =~ /ASC/i ) {
        $rawdata = join( ',', @dat );
    }
    else {
        my $form;

        if ( $wd == 1 ) {
            if ( $fmt =~ /^\s*S?RP/i ) {
                $form = 'C';
            }
            else {
                $form = 'c';
            }
        }
        else {
            if ( $fmt =~ /^\s*S?RP/i ) {
                $form = 'S';
            }
            else {
                $form = 's';
            }
            if ( $fmt =~ /^\s*R/i ) {
                $form .= '>';
            }
            else {
                $form .= '<';
            }
            $ds = 2 * $ds;
        }
        $form .= '*';
        $ds = sprintf( '%d', $ds * $hwfm->{'DAT:WID'} );
        $rawdata = '#' . length($ds) . $ds;
        $rawdata .= pack( $form, @dat );
    }

    # since we now have the raw data, write all to scope

    # first, set the destination, if specified

    if ( exists( $tail->{destination} ) ) {
        $self->set_data_destination( $tail->{destination} );
    }

    # next the waveform prefix
    my $cmd = '';
    foreach my $k (qw(BYT_N XIN XZE YMU YZE YOF)) {
        if ( exists( $hwfm->{"WFMP:$k"} ) ) {
            $cmd .= "$k " . $hwfm->{"WFMP:$k"} . ";";
        }
    }
    $self->write( "WFMP:" . $cmd ) if $cmd ne '';
    $self->_debug();

    $cmd = '';
    foreach my $k (qw(STAR STOP ENC WID)) {
        if ( exists( $hwfm->{"DAT:$k"} ) ) {
            $cmd .= "$k " . $hwfm->{"DAT:$k"} . ";";
        }
    }
    $self->write( "DAT:" . $cmd ) if $cmd ne '';
    $self->_debug();

    # next the waveform data
    $cmd = 'CURV ' . $rawdata;
    $self->write($cmd);
    $self->_debug();
}


sub print_waveform {
    my $self = shift;
    my ( $in, $tail ) = $self->_check_args_strict( \@_, qw(waveform) );

    croak("must pass waveform as hashref")
        unless defined($in) && ref($in) eq 'HASH';
    my $out = *STDOUT;
    if ( exists( $tail->{output} ) ) {
        if ( ref( $tail->{output} ) =~ /(IO|GLOB)/ ) {
            $out = $tail->{output};
        }
        elsif ( ref( $tail->{output} ) eq '' ) {
            my $t;
            open( $t, ">$tail->{output}" );
            $out = $t;
        }
        else {
            carp("problem with output parameter");
        }
    }

    my $j = 0;
    foreach my $k ( sort( keys( %{$in} ) ) ) {
        next unless $k =~ /^(WFMP|DAT):/;
        print $out "$k: \t'", $in->{$k}, "'\n";
    }

    my $j0 = 1;
    my $j1 = 2500;
    $j0 = $in->{'DAT:STAR'} if exists $in->{'DAT:STAR'};

    if ( exists( $in->{v} ) ) {

        $j1 = $in->{'DAT:STOP'} if exists $in->{'DAT:STOP'};

        my $v = $in->{v};
        print $out "Voltages: \n";
        for ( my $j = $j0; $j <= $j1 - 5; $j += 5 ) {
            my $str = sprintf( '%04d: t=%+.3e ' . "\t", $j, $in->{t}->[$j] );
            for ( my $k = 0; $k < 5 && $j + $k <= $j1; $k++ ) {
                $str .= sprintf( '%+.3e ', $v->[ $j + $k ] ) . "\t";
            }
            print $out $str, "\n";
        }
    }
    elsif ( exists( $in->{vmin} ) ) {

        $j1 = 1250;
        $j1 = $in->{'DAT:STOP'} if exists $in->{'DAT:STOP'};

        my $vmin = $in->{vmin};
        my $vmax = $in->{vmax};
        print $out "Envelope:\n";
        my $str;
        for ( my $j = $j0; $j <= $j1 - 5; $j += 5 ) {
            $str = sprintf( '%04d: t=%+.3e MAX ' . "\t", $j, $in->{t}->[$j] );
            for ( my $k = 0; $k < 5 && $j + $k <= $j1; $k++ ) {
                $str .= sprintf( '%+.3e ', $vmax->[ $j + $k ] ) . "\t";
            }
            print $out $str, "\n";
            $str = sprintf( '%04d: t=%+.3e MIN ' . "\t", $j, $in->{t}->[$j] );
            for ( my $k = 0; $k < 5 && $j + $k <= $j1; $k++ ) {
                $str .= sprintf( '%+.3e ', $vmin->[ $j + $k ] ) . "\t";
            }
            print $out $str, "\n\n";
        }
    }

}

1;    # End of Lab::Instrument::TDS2024B

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::TDS2024B - Tektronix TDS2024B digital oscilloscope (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

=over 4

    use Lab::Instrument::TDS2024B;

    my $s = new Lab::Instrument::TDS2024B (
        usb_serial => 'C12345',
        # usb_vendor and usb_product set automatically        
    );
   
    $s->set_channel(3);
    $s->set_scale(scale=>'20mV/div');
    $s->set_display_persist(persist=>'5s');
    $s->set_acquire_average(32);
    $s->set_acquire_state(state=>'RUN');

=back

Many of the 'quantities' passed to the code can use scientific
notation, order of magnitude suffixes ('u', 'm', etc) and unit
suffixes. The routines can be called using positional parameters
(check the documentation for order), or with keyword parameters. 

There are a few 'big' routines that let you set many parameters
in one call, use keyword parameters for those. 

In general, keywords passed TO these routines are case-independent,
with only the first few characters being significant. So, in the
example above: state=>'Run', state=>'running', both work. In cases
where the keywords distinguish an "on/off" situation (RUN vs STOP 
for acquistion, for example) you can use a Boolean quantity, and
again, the Boolean values are flexible:

=over

TRUE = 't' or 'y' or 'on' or number!=0

FALSE = 'f' or 'n' or 'off' or number ==0

(only the first part of these is checked, case independent)

=back

The oscilloscope input 'channels' are CH1..CH4, but 
there are also MATH, REFA..REFD that can be displayed
or manipulated.  To perform operations on a channel, one
should first $s->set_channel($chan);  Channel can be
specified as 1..4 for the input channels, and it will
be translated to 'CH1..CH4'.

The state of the TDS2024B scope is cached only when the
front-panel is in a 'locked' state, so that it cannot be
changed by users fiddling with knobs.  

=head1 GENERAL/SYSTEM ROUTINES

=head2 new

my $s = new Lab::Instrument::TDS2024B(
         usb_serial => '...',
);

serial only needed if multiple TDS2024B scopes are attached, it
defaults to '*', which selects the first TDS2024B found.  See
Lab::Bus::USBtmc.pm documentation for more information.

=head2 reset

$s->reset()

Reset the oscilloscope (*RST)

=head2 get_error

($code,$message) = $s->get_error();

Fetch an error from the device error queue

=head2 get_status

$status = $s->get_status(['statusbit']);

Fetches the scope status, and returns either the requested
status bit (if a 'statusbit' is supplied) or a reference to
a hash of status information. Reading the status register
causes it to be cleared.  A status bit 'ERROR' is combined
from the other error bits.

Example: $s->get_status('OPC');

Example: $s->get_status()->{'DDE'};

Status bit names:

=over

B<PON>: Power on

B<URQ>: User Request (not used)

B<CME>: Command Error

B<EXE>: Execution Error

B<DDE>: Device Error

B<QYE>: Query Error

B<RQC>: Request Control (not used)

B<OPC>: Operation Complete

B<ERROR>: CME or EXE or DDE or QYE

=back

=head2 get_datetime

$datetime = $s->get_datetime();

fetches the date and time from the scope, returned
in form "YYYY-MM-DD HH:MM:SS"  (numeric month, 24hr time)

=head2 set_datetime

$s->set_datetime();           set to current date and time
$s->set_datetime($unixtime);  set to unix time $unixtime

Note that the TDS2024B has no notion of 'time zones', so
default is 'local time'. 

Returns the date and time in the same format as get_datetime.

=head2 wait_done

$s->wait_done([$time[,$deltaT]);

$s->wait_done(timeout => $time, checkinterval=>$deltaT);

Wait for "operation complete". If the $time optional argument
is given, it is the (max) number of seconds to wait for completion
before returning, otherwise a timeout of 10 seconds is used.
$time can be a simple number of seconds, or a text string with
magnitude and unit suffix. (Ex: $time = "200ms"). If $time="INF"
then this routine will run indefinitely until completion (or some
I/O error). 

If $deltaT is given, checks are performed in intervals of $deltaT
seconds (again, number or text), except when $deltaT is less than $time.
$deltaT defaults to 500ms. 

Returns 1 if completed, 0 if timed out. 

=head2 test_busy

$busy = $s->test_busy();

Returns 1 if busy (waiting for trigger, etc), 0 if not busy.

=head2 get_id

$s->get_id()

Fetch the *IDN? string from device

=head2 get_header

$header = $s->get_header();

Fetch whether headers are included
with query response; returns 0 or 1.

=head2 save

$s->save($n);

$s->save(setup=>$n);

Save the scope setup to a nonvolatile internal memory $n = 1..10

=head2 recall

$s->recall($n);

$s->recall(setup=>$n);

Recall scope setup from internal memory location $n = 1..10

=head2 set_header

$s->set_header($boolean);
$s->set_header(header=>$boolean);

Turns on or off headers in query replies; Boolean
values described above.

=head2 get_verbose

$verb = $s->get_verbose();

Fetch boolean indicating whether query responses
(headers, if enabled, and response keywords)
are returned in 'long form'

=head2 set_verbose

$s->set_verbose($bool);
$s->set_verbose(verbose=>$bool);

Sets the 'verbose' mode for replies, with
the longer form of command headers (if enabled) and
keyword values. Note that
when using the get_* routines, the replies are
processed before being returned as 'long' values, 
so this routine only affects the communication
between the scope and this code. 

=head2 get_locked

$locked = $s->get_locked()

Get whether user front-panel controls
are locked. Returns 1 (all controls locked)
or 0 (no controls locked). Caching for most
quantities is turned off when the controls
are unlocked. 

=head2 set_locked

$s->set_locked($bool);
$s->set_locked(locked=>$bool);

Lock or unlock front panel controls; 

NOTE: locking the front panel
enables the device_cache, and reinitializes cached values (other
than the special ones that are not alterable from the front
panel)

=head2 get_setup

$setup = get_setup();

Get a long GPIB string that has the scope setup information

Note that the scope I am testing with generates a 
"300, Device-specific error; no alternate chosen"
error when triggering on "AC LINE". Might be a firmware
bug, so filtering it out. 

=head2 set_setup

$s->set_setup($setup);

$s->set_setup(setup=>$setup);

Send configuration to scope. The '$setup' string is
of the form returned from get_setup(), but can be
any valid command string for the scope.  The setup
string is processed into separate commands, and
transmitted sequentially, to avoid communications
timeouts.

=head1 ACQUIRE ROUTINES

=head2 get_acquire_mode

$acqmode = $s->get_acquire_mode();

Fetches acquisition mode: SAMple,PEAKdetect,AVErage

=head2 set_acquire_mode

$s->set_acquire_mode($mode);
$s->set_acquire_mode(mode=>$mode);

Sets the acquire mode: SAMple, PEAKdetect or AVErage

=head2 get_acquire_numacq

$numacq = $s->get_acquire_numacq();

Fetch the number of acquisitions that have happened
since starting acquisition.

=head2 get_acquire_numavg

$numavg = $s->get_acquire_numavg();

Fetch the number of waveforms specified for averaging

=head2 set_acquire_numavg

$s->set_acquire_numavg($n);
$s->set_acquire_numavg(average=>$n);

Set the number of waveforms to average
valid values are 4, 16, 64 and 128

=head2 get_acquire_state

$state = $s->get_acquire_state()

Fetch the acquisition state: STOP (stopped) or RUN (running)
NOTE: to check if acq is complete: wait_done()

=head2 set_acquire_state

$s->set_acquire_state($state);
$s->set_acquire_state(state=>$state);

$state =  'RUN' (or boolean 'true') starts acquisition
          'STOP' (or boolean 'false')  stops acquisition

=head2 get_acquire_stopafter

$mode = $s->get_acquire_stopafter();

Fetch whether acquisition is in "RUNSop" mode (run until stopped)
or "SEQuence" mode 

=head2 set_acquire_stopafter

$s->set_acquire_stopafter($mode);
$s->set_acquire_stopafter(mode=>$mode);

Sets stopafter mode: RUNStop : run until stopped, 
or SEQuence: stop after some defined sequence (single trigger, pattern, etc)

=head2 get_acquire

%hashref = $s->get_acquire();

Get the "acquire" information in a hash; this is a combined
"get_acquire_*" with the keywords that can be use for set_acquire()

=head2 set_acquire

$s->set_acquire(state=>$state, # RUN|STOP  (or boolean)
                mode=>$mode,   # SAM|PEAK|AVE
                stopafter=>$stopa # STOPAfter|SEQ
                average=>$navg);
$s->set_acquire($hashref);       # from get_acquire
$s->set_acquire($state,$mode,$stopa,$navg);

Sets acquisition parameters

=head2 get_autorange_state

$arstate = $s->get_autorange_state()

Fetch the autorange state, boolean, indicating
whether the scope is autoranging

=head2 set_autorange_state

$s->set_autorange_state(state=>$bool);
$s->set_autorange_state($bool);

Set autoranging on or off.

=head2 get_autorange_settings

$arset  = $s->get_autorange_settings()

Fetch the autorange settings, returns
value (HORizontal|VERTical|BOTH)

=head2 set_autorange_settings

$s->set_autorange_settings(set=>$arset);

$s->set_autorange_settings($arset);

Set what is subject to autoranging: $arset = HORizontal, VERTical, BOTH

=head2 do_autorange

$s->do_autorange();

Causes scope to adjust horiz/vert, like pressing 'autoset' button
This command may take some time to complete.

=head2 get_autorange_signal

$sig = $s->get_autorange_signal()

returns the type of signal found by the most recent autoset, or NON
if the autoset menu is not displayed.

=head2 get_autorange_view

$view = $s->get_autoset_view();

Fetch the menu display; view can be one of (depending on scope options):
MULTICY SINGLECY FFT RISING FALLING FIELD ODD EVEN LINE LINEN DCLI DEF NONE

=head2 set_autorange_view

$s->set_autoset_view($view)

$s->set_autoset_view(view=>$view)

Set the menu display; view can be one of (depending on scope options):
MULTICY SINGLECY FFT RISING FALLING FIELD ODD EVEN LINE LINEN DCLI DEF NONE

=head2 get_autorange

%hashref = $s->get_autorange();

get autorange settings as a hash

=head1 CHANNEL ROUTINES

=head2 get_channel

$chan = $s->get_channel();

Get the current channel selected for operations 1..4

=head2 set_channel

$s->set_channel(channel=>$chan);
$s->set_channel($chan);

sets the channel number (1..4)  for operations
with the set_chan_XXX and get_chan_YYY methods
on oscilloscope channels

Channel can be specified as an integer 1..4, or Ch1, Ch2, etc.,
or 'MATH'.

=head2 get_vertical_settings

This is like get_chan_setup, but faster (one query
to scope) and output is kept in original form.

$settings = $s->get_vertical_settings($chan);
$settings = $s->get_vertical_settings(channel => $chan);

$chan = scope channel or MATH

Fetch the vertical settings for a channel into a
hash structure (example for CH1):
	$settings->{CH1:POS}	# position on display
        $settings->{CH1:INV}    # inverted?
        $settings->{CH1:SCAL}   # vertical scale
	$settings->{CH1:YUN}    # units for y-axis (volts, db, etc)
	$settings->{CH1:PRO}    # voltage probe attenuation
	$settings->{CH1:CURRENTPRO} # current probe attenuation
        $settings->{CH1:COUP}   # input coupling (AC, DC,..)
	$settings->{CH1:BANWID} # input bandwidth setting
	$settings->{MATH:DEFINE} # math definition, if $chan=MATH

=head2 set_visible

$s->set_visible([$chan,[$vis]]);

$s->set_visible(channel=>$chan [, visible=>$vis]);

Set/reset channel visiblity.

If no channel is given, the current channel (set by set_channel ) is used.
Otherwise $chan = CH1..4, REFA..D, MATH

If $vis is not specified, it defaults to "make channel visible". 

To make turn off display of a channel, use $vis=(boolean false).

=head2 get_visible

$vis = $s->get_visible($chan);

$vis = $s->get_visible(channel=>$chan);

Fetch boolean value for whether the channel (CH1..4, REFA..D, MATH) is
being displayed. If channel is not specified, the current channel
(from 'set_channel()') is used. 

=head2 get_chan_bwlimit

$bwlim = $s->get_chan_bwlimit()

Fetch whether the channel has bandwidth limited to 20MHz
(boolean)

=head2 set_chan_bwlimit

$s->set_chan_bwlimit(limit=>'on')

Turns on or off bandwith limiting (limit = boolean, true = 'limit')

=head2 get_chan_coupling

$coupling = $s->get_chan_coupling()

Fetch the channel coupling (AC/DC/GND).

=head2 set_chan_coupling

$s->set_coupling(coupling => $coupling); 

Set the coupling to AC|DC|GND for an input channel

=head2 get_chan_current_probe

$iprobe = $s->get_chan_current_probe();

Get the probe scale factor. This does not mean that a
current probe is in use, just what 'probe scale factor'
would be applied if current probe use is selected. 

=head2 set_chan_current_probe

$self->set_chan_current_probe(factor=>$x);

Set the current probe scale factor. Valid values
are 0.2, 1, 2, 5, 10, 50, 100, 1000

=head2 get_chan_invert

$inv = $s->get_chan_invert();

fetch whether the channel is 'inverted' -> boolean

=head2 set_chan_invert

$s->set_chan_invert(invert=>$inv);

sets a channel to 'invert' mode if $inv is true, $inv=boolean

=head2 get_chan_position

$p = $s->get_chan_position();

get the vertical position of "zero volts" for a channel
The value is the number of graticule divisions from the
center.

=head2 set_chan_position

$s->set_chan_position(position=> -24)

Sets the trace 'zero' position, in graticule divisions
from the center of the display.
Note that the limits depend on the vertical scale,
+/- 50V for >= 500mV/div, +/- 2V for < 500mV/div

=head2 get_chan_probe

$probe = $s->get_chan_probe();

Fetch the voltage probe attenuation. 

=head2 set_chan_probe

$self->set_chan_probe(factor=>X);

Set the voltage probe scale factor. Valid values
are 1, 10, 20, 50, 100, 500, 1000

=head2 get_chan_scale

$scale = $s->get_chan_scale();

Fetch the vertical scale for a channel, in V/div
(or A/div when used with a current probe)

=head2 set_chan_scale

$self->set_chan_scale(scale=>$scale);

Set the vertical scale for a channel, in V/div or
A/div.  X can be a number, or a string with suffixes and units
Ex: '2.0V/div' '100m'.  

=head2 get_chan_yunit

$scale = $s->get_chan_yunit();

Fetch the units for the vertical scale of a channel,
returns either "V" or "A" 

=head2 set_chan_yunit

$self->set_chan_yunit(unit=>X);

Set the vertical scale units to either 'V' or 'A'

=head2 get_chan_setup

$hashref = $s->get_chan_setup([channel=>$chan])

Fetches channel settings and returns them as a 
hashref:
=over 2
=item    channel => channel selected (otherwise default from set_channel)
=item    probe => probefactor,
=item    postion => screen vertical position, in divisions
=item    scale => screen vertical scale, V/div or A/div
=item    coupling =>  (AC|DC|GND)
=item    bandwidth => (ON|OFF)
=item    yunit => (V|A)
=item    invert => ON|OFF
=item    probe => probe attentuation (for yunit=V)
=item    currentprobe => current probe factor (for yunit=A)
=back

The hash is set up so that it can be passed to 
$s->set_channel($hashref) 

=head2 set_chan_setup

$s->set_channel([channel=>1],scale=>...)

Can pass the hash returned from "get_chan_setup" to 
set a an oscilloscope channel to the desired state.

TODO: check current/voltage probe selection,
adjust order of calls to avoid settings conflicts

=head1 CURSOR CONTROLS

The cursors can either be 'horizontal bars' (HBARS), attached to
a particular trace, measuring amplitude; or 'vertical bars' (VBARS)
that are measuring horizontally (time or frequency).  

Since these names can be confusing, you can also use 'X' to select VBARS and 
'Y' to select HBARS, since that gives a more natural indication of what
you are measuring. 

=head2 get_cursor_type

$cursor = $s->get_cursor_type([$opt]);

$cursor = $s->get_cursor_type([option=>$opt]);

Fetch cursor type: (OFF|HBARS|VBARS) default

cursor type returned as: (OFF|X|Y) if $opt = 'xy';

=head2 set_cursor_type

$s->set_cursor_type($type);

$s->set_cursor_type(type=>$type)

$type = OFF|HBAr|Y|VBAr|X  

=head2 get_cursor_xunits

$units = $s->get_cursor_xunits()

gets the x (horizontal) units for the cursors (VBAR type),
returns either SECONDS or HERTZ.

=head2 get_cursor_yunits

$self->get_cursor_yunits();

Fetch the units used for the cursor y positions (HBARS, or the 
waveform vertical position with VBARS).

The units returned can be: VOLTS, DIVISIONS, DECIBELS UNKNOWN AMPS 
VOLTSSQUARED AMPSSQUARED VOLTSAMPS.

=head2 get_cursor_source

$src = $s->get_cursor_source();

Fetch the source waveform being used with the cursors, determines
the units of the cursor for horizontal bar (HBAR, Y) cursors. 

=head2 set_cursor_source

$s->set_cursor_sourch($chan);

$s->set_cursor_source(channel => $chan);

=head2 set_cursor_xunits

$s->set_cursor_xunits($units);

$s->set_cursor_xunits(unit=>$units);

Set the units used for VBAR (x) cursor, for VBAR the possible
units are (SEConds|s) or (HERtz|Hz). HBAR cursor units
cannot be changed. 

=head2 get_cursor_dx

$delt = $s->get_cursor_dx();

Fetch the difference between x (VBAR) cursor positions.

=head2 get_cursor_dy

$delt = $s->get_cursor_dy();

Fetch the difference between y (HBAR) cursor positions.

=head2 get_cursor_x1

$pos = $s->get_cursor_x1();

Fetch the x position of cursor 1 (VBAR), typically in
units of seconds. 

=head2 get_cursor_x2

$pos = $s->get_cursor_x2();

Fetch the x position of cursor 2 (VBAR), typically in
units of seconds. 

=head2 get_cursor_y1

$pos = $s->get_cursor_y1();

Fetch the y position of cursor 1 (HBAR), typically in
units of volts, but possibly other units 

=head2 get_cursor_y2

$pos = $s->get_cursor_y2();

Fetch the y position of cursor 2 (HBAR), typically in
units of volts, but possibly other units. 

=head2 set_cursor_x1

$s->set_cursor_x1($location);

$s->set_cursor_x1(position => $location);

set cursor 1 x location (VBAR type cursor)

=head2 set_cursor_x2

$s->set_cursor_x2($location);

$s->set_cursor_x2(position => $location);

set cursor 2 x location (VBAR type cursor)

=head2 set_cursor_y1

$s->set_cursor_y1($location);

$s->set_cursor_y1(position => $location);

set cursor 1 y position (HBAR type)

=head2 set_cursor_y2

$s->set_cursor_y2($location);

$s->set_cursor_y2(position => $location);

set cursor 2 y position (HBAR type)

=head2 get_cursor_v1

$vcursor = $s->get_cursor_v1();

If using HBAR (y) cursors, get the vertical position of cursors;
if using VBAR (x) cursors, get the waveform voltage (or other vertical unit)
at the cursor1 position.

=head2 get_cursor_v2

$vcursor = $s->get_cursor_v2();

If using HBAR (y) cursors, get the vertical position of cursors;
if using VBAR (x) cursors, get the waveform voltage (or other vertical unit)
at the cursor2 position.

=head2 get_cursor_dv

$dv = $s->get_cursor_dv();

Get the vertical distance between the cursors (dy if HBAR cursors,
dv2-dv1 if VBAR cursors)

=head2 $hashref = $s->get_cursor()

Fetches cursor information and returns it in a hash,
in a form that can be used with set_cursor()

=head2 set_cursor

$s->set_cursor( type=>$type,
               x1 => $x1, x2 => $x2, ...);

sets cursor information. If used with a hash from get_cursor, the
entries that cannot be used to set the cursors are ignored

=head1 DISPLAY CONTROLS    

=head2 get_display_contrast

$cont = $s->get_display_contrast()

Fetches the display contrast:  1 .. 100

=head2 set_display_contrast

$s->set_display_contrast($cont)

(alternate set_display_contrast(contrast => number) )
Set the display contrast, percent 1..100

=head2 get_display_format

$form = $s->get_display_format()

Fetch the display format: YT or XY

=head2 set_display_format

$s->set_display_format($format);

$s->set_display_format(format => $format);

Where $format = XY or YT.

=head2 get_display_persist

$pers = $s->get_display_persist()

Fetch the display persistance, values 1,2,5,INF,OFF
Numbers are in seconds.

=head2 set_display_persist

$s->set_display_persist($pers);

$s->set_display_persist(persist=>$pers);

Sets display persistence. $pers = 1,2,5 seconds, INF, or OFF

=head2 get_display_style

$style = $s->get_display_style()

Fetch the display style = 'DOTS' or 'VECTORS'

=head2 set_display_style

$s->set_display_style($style)l\;

$s->set_display_style(style=>$style);

Sets the display style: $style is DOTs or VECtors

=head2 get_display

$hashref = $s->get_display();

Fetch display settings (contrast, format, etc) in a
hash, that can be used with "set_display".

=head2 set_display

$s->set_display(contrast=>$contrast, ...)

Set the display characteristics

=head1 FILESYSTEM ROUTINES

=head2 get_cwd

$s->get_cwd();

Gets the current working directory on any USB flash drive
plugged into the oscilloscope, or a null string ( '' ) if 
no drive is plugged in.

=head2 set_cwd

$s->set_cwd($cwd);

$s->set_cwd(cwd => $cwd);

Set the current working directory on the flash drive.
The flash drive is on the "A:" drive, and the cwd uses
"DOS" type syntax.  For compatibility, forward slashes
are translated to backslashes. 

It would be a good idea to check for errors after
this call.

=head2 delete

$self->delete($file);

$self->delete(file => $file);

Delete a file from the USB filesystem; use DOS format, and
note that the USB filesystem is on "A:\topdir\subdir..."

For ease of use, this routine translates forward slashes
to backslashes.  It would be a good idea to check for errors
after calling this routine. 

=head2 get_dir

@files = $s->get_dir();

Get a list of filenames in the current (USB flash drive)
directory. 

=head2 get_freespace

$bytes = $s->get_freespace();

Get the amount of freespace on the USB flash.

=head2 mkdir

$s->mkdir($dirname);

$s->mkdir(directory=>$dirname);

Create a directory on the flash drive, uses MSDOS
file syntax, only on the A: drive.

Forward slashes are translated to backslashes for compatibility.

It is a good idea to check for errors after calling this routine.

=head2 rename

$s->rename($old,$new);

$s->rename(old=>$old, new=>$new);

Rename $old filepath to $new filepath. Note that these are in
MSDOS file syntax, all on the "A:" drive. 

Forward slashes are translated to backslashes.

It is a good idea to check for errors after calling this routine.

=head2 rmdir

$s->rmdir($dir);

$s->rmdir(directory=>$rmdir);

Removes a directory from the USB flash drive. The directory
name is in MSDOS syntax; forward slashes are translated to 
backslashes. 

A directory must be empty before deletion; it is a good idea
to check for errors after calling this routien.

=head1 HARDCOPY ROUTINES

=head2 get_hardcopy_format

$format = $s->get_hardcopy_format();

Fetch the hardcopy format, returns one of:

=over 4

 BMP BUBBLEJET DESKJET DPU3445 DPU411 DPU412 EPSC60 EPSC80 

 EPSIMAGE EPSON INTERLEAF JPEG LASERJET PCX RLE THINK TIFF

=back

=head2 set_hardcopy_format

$s->set_hardcopy_format($format);

$s->set_hardcopy_format(format => $format);

Set the 'hardcopy' format, used for screen captures:

=over 4

 BMP BUBBLEJET DESKJET DPU3445 DPU411 DPU412 EPSC60 EPSC80 

 EPSIMAGE EPSON INTERLEAF JPEG LASERJET PCX RLE THINK TIFF

=back

=head2 get_hardcopy_layout

$layout = $s->get_hardcopy_layout();

Fetch the hardcopy layout: PORTRAIT or LANDSCAPE

=head2 set_hardcopy_layout

$s->set_hardcopy_layout($layout);

$s->set_hardcopy_layout(layout => $layout);

Set the hardcopy layout: LANdscpe or PORTRait.

=head2 get_hardcopy_port

$port = $s->get_hardcopy_port();

Fetch the port used for hardcopy printing; for the TDS2024B, this
should aways return 'USB'.

=head2 set_hardcopy_port

$s->set_hardcopy_port($port);

$s->set_hardcopy_port(port => $port);

Set the hardcopy port; for the TDS2024B, this should always be USB.
Included for compatibility with other scopes.

=head2 get_hardcopy

$hashref = get_hardcopy();

Fetch hardcopy parameters (format, layout, port; although
port is always 'USB') and return in a hashref.

=head2 set_hardcopy

$s->set_hardcopy(format=>$format, layout=>$layout, port=>$port);

Set hardcopy parameters; this can use a hashref returned from
get_hardcopy();

=head2 get_image

$img = $s->get_image();

$img = $s->get_image($filename[, $force]);

$img = $s->get_image(file=>$filename, force=>$force,
                 timeout=>$timeout, read_length=>$rlength,
                   [hardcopy options]);

Fetch a screen-capture image of the scope, using the the current
hardcopy options (format, layout).  If the filename is specified, write
to that filename (in addition to returning the image data); error
if the file already exists, unless $force is true. 

timeout (in seconds) and read_length (in bytes) are only passed with
the "hash" form of the call. 

=head1 HORIZONTAL CONTROL ROUTINES

=head2 get_horiz_view

$view = $s->get_horiz_view();

Fetch the horizontal view: MAIN, WINDOW, ZONE

WINDOW is a selection of the MAIN view; ZONE is
the same as MAIN, but with vertical bar cursors
to show the range displayed in WINDOW view.

=head2 set_horiz_view

$s->set_horiz_view($view);

$s->set_horiz_view(view=>$view);

Set the horizontal view to MAIn, WINDOW, or ZONE.

=head2 get_horiz_position

$pos = $s->get_horiz_position();

Fetch the horizontal position of the main view, in seconds; this
is the difference between the trigger point and the horizontal 
center of the screen. 

=head2 set_horiz_position

$s->set_horiz_position($t);

$s->set_horiz_position(time => $t);

Set the horizontal position, in seconds, for the main view.
Positive time values puts the trigger point to the left of the
center of the screen.

=head2 get_delay_position

$time = $s->get_delay_position();

Fetch the delay time for the WINDOW view. Time is relative to the
center of the screen.

=head2 set_delay_position

$s->set_delay_position($time);

$s->set_delay_position(delaytime=>$time);

Set the postion of the WINDOW view horizontally. $time is in
seconds, relative to the center of the screen.

=head2 get_horiz_scale

$secdiv = $s->get_horiz_scale();

Fetch the scale (in seconds/division) for the 'main' view.

=head2 set_horiz_scale

$s->set_horiz_scale($secdiv);

$s->set_horiz_scale(scale=>$secdiv);

Set the horizontal scale, main window, to $secdiv
seconds/division.

=head2 get_delay_scale

$secdiv = $s->get_delay_scale();

Fetch the scale (in seconds/division) for the 'window' view.

=head2 set_del_scale

$s->set_del_scale($secdiv);

$s->set_del_scale(delayscale=>$secdiv);

Set the horizontal scale, window view, to $secdiv
seconds/division.

=head2 get_recordlength

$samples = $s->get_recordlength();

Returns record length, in number of samples. For the TDS200B,
this is always 2500, so a constant is returned. 

=head2 get_horizontal

$hashref = $s->get_horizontal();

Fetch a hashref, with entries that describe the horizontal setup, and
can be passesd to set_horizontal

keys: view, time, delaytime, scale, delayscale, recordlength

=head2 set_horizontal

$s->set_horizontal(time=>..., scale=>...);

Set the horizontal characteristics. See get_horizontal()

=head1 MATH/FFT ROUTINES

=head2 get_math_definition

$string = $s->get_math_definition();

Fetch the definition used for the MATH waveform

=head2 set_math_definition

$s->set_math_definition($string);

$s->set_math_definition(math => $string);

Define the 'MATH' waveform; the input is sufficiently complex that
the user should check for errors after calling this routine.

Choices:

=over

    CH1+CH2

    CH3+CH4

    CH1-CH2

    CH2-CH1

    CH3-CH4

    CH4-CH3 

    CH1*CH2

    CH3*CH4

    FFT (CHx[, <window>])

=back

<window> is HANning, FLATtop, or RECTangular.

=head2 get_math_position

$y => $s->get_math_position();

Fetch the MATH trace vertical position, in divisions
from the center of the screen. 

=head2 set_math_position

$s->set_math_position($y);

$s->set_math_postition(position=>$y);

Set the MATH trace veritical position, in divisions from the center
of the screen.

=head2 get_fft_xposition

$pos = $s->get_fft_xposition();

Fetch FFT horizontal position, a percentage of the total FFT 
length, relative to the center of the screen.

=head2 set_fft_xposition

$s->set_fft_xposition($percent);

$s->set_fft_xposition(fft_xposition=>$percent);

Set the horizontal position of the FFT trace; the "percent"
of the trace is placed at the center of the screen.

=head2 get_fft_xscale

$scale = $s->get_fft_xscale();

Fetch the horizontal zoom factor for FFT display,
possible values are 1,2,5 and 10.

=head2 set_fft_xscale

$s->set_fft_xscale($zoom);

$s->set_fft_xscale(fft_xscale => $zoom);

Set the FFT horizontal scale zoom factor: 1,2,5, or 10.

=head2 get_fft_position

$divs = $s->get_fft_position();

Fetch the y position of the FFT display, in division from the
screen center.

=head2 set_fft_position

$s->set_fft_position($divs);

$s->set_fft_position(fft_position=>$divs);

Set the FFT trace y position, in screen divisions relative to the
screen center. 

=head2 get_fft_scale

$zoom = $s->get_fft_scale();

Fetch the FFT vertical zoom factor, returns one of 0.5, 1, 2, 5, 10

=head2 set_fft_scale

$s->set_fft_scale($zoom);

$s->set_fft_yscale(fft_scale => $zoom);

Set the fft vertical zoom factor, valid values are 
0.5, 1, 2, 5, 10

=head1 MEASUREMENT ROUTINES

The TDS2024B manual suggests using the 'IMMediate' measurements;
when measurements 1..5 are used, it results in an on-screen display
of the measurement results, because the on-screen display is update
(at most) every 500ms. It would be a good idea to check for errors
after calling get_measurement_value, because errors can result if
the waveform is out of range.  Also note that when the MATH trace
is in FFT mode, 'normal' measurement is not possible. 

The 'IMMediate' measurements cannot be accessed from the scope
front panel, so will be cached even if the scope is in an 'unlocked'
state. (see set_locked) 

=head2 get_measurement_type

$type = $s->get_measurement_type($n);

$type = $s->get_measurement_type(measurement=>$n);

Fetch the measurement type for measurement $n = 'IMMediate' or 1..5
$n defaults to 'IMMediate'

returns one of:
 FREQuency | MEAN | PERIod |
PHAse | PK2pk | CRMs | MINImum | MAXImum | RISe | FALL |
PWIdth | NWIdth | NONE 

=head2 set_measurement_type

$s->set_measurement_type($n,$type);

$s->set_measurement_type(measurement=>$n, type=>$type);

$s->set_measurement_type($type);     (defaults to $n = 'IMMediate')

Set the measurement type, for measurement $n= 'IMMediate', 1..5

The type is one of:  FREQuency | MEAN | PERIod |
PHAse | PK2pk | CRMs | MINImum | MAXImum | RISe | FALL | PWIdth | NWIdth 
or NONE (only for $n=1..5).

=head2 get_measurement_units

$units = $s->get_measurement_units($n);

$units = $s->get_measurement_units(measurement=>$n);

Fetch the measurement units for measurement $n (IMMediate, 1..5)
result:  V, A, S, Hz, VA, AA, VV

If $n is missing or undefined, uses IMMediate. 

=head2 get_measurement_source

$wfm = $s->get_measurement_source($n);

$wfm = $s->get_measurement_source(measurement=>$n);

Fetch the source waveform for measurements: CH1..CH4 or MATH
for measurement $n = IMMediate, 1..5

If $n is undefined or missing, IMMediate is used. 

=head2 set_measurement_source

$s->set_measurement_source($n,$wfm);

$s->set_measurement_source(measurement=>$n, measurement_source => $wfm);

Set the measurement source, CH1..CH4 or MATH for measurement 
$n = IMMediate, 1..5.  If $n is undefined or missing uses IMMediate. 

=head2 get_measurement_value

$val = $s->get_measurement_value($n);

$val = $s->get_measurement_value(measurement=>$n);

Fetch  measurement value, measurement $n = IMMediate, 1..5
If $n is missing or undefined, use IMMediate. 

=head1 TRIGGER ROUTINES

=head2 trigger

$s->trigger();

Force a trigger, equivalent to pushing the "FORCE TRIGGE" button on
front panel

=head2 get_trig_coupling

$coupling = $s->get_trig_coupling();

returns $coupling = AC|DC|HFREJ|LFREJ|NOISEREJ

(only applies to 'EDGE' trigger)

=head2 set_trig_coupling

$s->set_trig_coupling($coupling);

$s->set_trig_coupling(coupling=>$coupling);

Set trigger coupling, $coupling = AC|DC|HFRej|LFRej|NOISErej
Only applies to EDGE trigger

=head2 get_trig_slope

$sl = $s->get_trig_slope();

Fetch the trigger slope, FALL or RISE
only applies to EDGE trigger.

=head2 set_trig_slope

$s->set_trig_slope($sl);

$s->set_trig_slope(slope=>$sl);

Set the trigger slope: RISE|UP|POS|+  or FALL|DOWN|NEG|-

Only applies to EDGE trigger

=head2 get_trig_source

$ch = $s->get_trig_source([$trigtype]);

$ch = $s->get_trig_source([type=>$trigtype]);

Fetch the trigger source, returns one of CH1..4, EXT, EXT5,  LINE

(EXT5 is 'external source, attenuated by a factor of 5')

Trigger type is the "currently selected" trigger type, unless
specified with the type parameter.

=head2 set_trig_source

$s->set_trig_source($ch);

$s->set_trig_source(source=>$ch[, type=>$type]);

Set the trigger source to one of CH1..4, EXT, EXT5, LINE (or 'AC LINE') 
for the current trigger type, unless type=>$type is specified.

=head2 get_trig_frequency

$f = $s->get_trig_frequency();

Fetch the trigger frequency in Hz. This function is not for use when
in 'video' trigger type. If the frequcency is less than 10Hz, 1Hz
is returned.

=head2 get_trig_holdoff

$hold = $s->get_trig_holdoff();

Fetch the trigger holdoff, in seconds

=head2 set_trig_holdoff

$s->set_trig_holdoff($time);

$s->set_trig_holdoff(holdoff=>$time);

Set the trigger holdoff. If $time is a number it is
taken to be in seconds; text can be passed with the
usual order-of-magnitude and unit suffixes. 

holdoff can range from 500ns to 10s

=head2 get_trig_level

$lev = $s->get_trig_level();

Fetch the trigger level, in volts

=head2 set_trig_level

$s->set_trig_level($lev);

$s->set_trig_level(level => $lev);

Set the trigger level, in volts.  The usual magnitude/suffix 
rules apply. This routine has no effect when the trigger ssource 
is set to 'AC LINE'

=head2 get_trig_mode

$mode = $s->get_trig_mode();

Fetch the trigger mode: AUTO or NORMAL

=head2 set_trig_mode

$s->set_trig_mode($mode);

$s->set_trig_mode(mode=>$mode);

Set the trigger mode: AUTO or NORMAL

=head2 get_trig_type

$type = $s->get_trig_type();

Fetch the trigger type, returns EDGE or PULSE or VIDEO.

=head2 set_trig_type

$s->set_trig_type($type);

$s->set_trig_type(type=>$type);

Set trigger type to EDGE, PULse or VIDeo. 

=head2 get_trig_pulse_width

$wid = $s->get_trig_pulse_width();

Fetch trigger pulse width for PULSE trigger type

=head2 set_trig_pulse_width

$s->set_trig_pulse_width($wid);

$s->set_trig_pulse_width(width=>$wid);

Set the pulse width for PULSE type triggers, in seconds. Valid
range is from 33ns to 10s.

=head2 get_trig_pulse_polarity

$pol = $s->get_trig_pulse_polarity();

Fetch the polarity for the PULSE type trigger,
returns POSITIVE or NEGATIVE

=head2 set_trig_pulse_polarity

$s->set_trig_pulse_polarity($pol);

$s->set_trig_pulse_polarity(pulse_polarity=>$pol);

Set the polarity for PULSE type trigger.  

$pol can be (Postive|P|+) or (Negative|N|M|-)

=head2 get_trig_pulse_when

$when = $s->get_trig_pulse_when();

Fetch the "when" condition for pulse triggering, possible
values are 

=over 4

EQUAL: triggers on trailing edge of specified width)

NOTEQUAL: triggers on trailing edge of pulse shorter than specified
width, or if pulse continues longer than specified width.

INSIDE: triggers on the trailing edge of pulses that are less than
the specified width.

OUTSIDE: triggers when a pulse continues longer than the specified
width

=back

=head2 set_trig_pulse_when

$s->set_trig_pulse_when($when);

$s->set_trig_pulse_when(pulse_when=>$when);

Set the PULSE type trigger to trigger on the specified 
condition, relative to the pulse width.

=over 4

EQ|EQUAL|= : trigger on trailing edge of pulse equal to 'width'.

NOTE|NOTEQUAL|NE|!=|<>: trigger on trailing edge of pulse that is shorter than specified width, or when the pulse exceeds the specified width.

IN|INSIDE|LT|< : trigger on trailing edge when less than specified width

OUT|OUTSIDE|GT|> : trigger when pulse width exceeds specified width.

The pulse width for this trigger is set by set_trig_pulse_width();

=back

=head2 get_trig_vid_line

$line = $s->get_trig_vid_line();

Get the video line number for triggering when
SYNC is set to LINENUM.

=head2 set_trig_vid_line

$s->set_trig_vid_line($line);

$s->set_trig_vid_line(vid_line => $line);

Set the video line number for triggering with video
trigger, when SYNC is set to LINENUM.

=head2 get_trig_vid_polarity

$pol = $s->get_trig_vid_polarity();

Fetch the video trigger polarity: NORMAL or INVERTED

=head2 set_trig_vid_polarity

$s->set_trig_vid_polarity($pol);

$s->set_trig_vid_polarity(vid_polarity=>$pol);

Set the video trigger polarity: NORMal|-SYNC or INVerted|+SYNC

=head2 get_trig_vid_standard

$std = $s->get_trig_vid_standard();

Fetch the video standard used for video-type triggering;
returns NTSC or PAL (PAL = PAL or SECAM).

=head2 set_trig_vid_standard

$s->set_trig_vid_standard($std);

$s->set_trig_vid_standard(vid_standard=>$std);

Set the video standard used for video triggering. 
$std = NTSC, PAL, SECAM  (SECAM selects PAL triggering).

=head2 get_trig_vid_sync

$sync = $s->get_trig_vid_sync();

Fetcht the syncronization used for video trigger, possible
values are FIELD, LINE, ODD, EVEN and LINENUM.

=head2 set_trig_vid_sync

$s->set_trig_vid_sync($sync);

$s->set_trig_vid_sync(vid_sync => $sync);

Set the synchronization used for video triggering; possible values
are FIELD, LINE, ODD, EVEN, and LINENum.

=head2 get_trig_state

$state = $s->get_trig_state();

Fetch the trigger state (warning: this is not a good way to determine
if acquisition is completed).  Possible values are:

=over 4

ARMED: aquiring pretrigger information, triggers ignored

READY: ready to accept a trigger

TRIGGER: trigger has been accepted, scope is processing postrigger information.

AUTO: in auto mode, acquiring even without a trigger.

SAVE: acquisition stopped, or all channels off.

SCAN: scope is in scan mode 

=back

=head1 WAVEFORM ROUTINES

=head2 get_data_width

$nbytes = $s->get_data_width();

Fetch the number of bytes transferred per waveform sample, returns 1 or 2. 

Note that only the MSB is used, unless the waveform is averaged or a 
MATH waveform. 

=head2 set_data_width

$s->set_data_width($nbytes);

$s->set_data_width(nbytes=>$nbytes);

Set the number of bytes per waveform sample, either 1 or 2. 

Note that only the MSB is used for waveforms that are not the
result of averaging or MATH operations.

=head2 get_data_encoding

$enc = $s->get_data_encoding();

Fetch the encoding that is used to transfer waveform
data from the scope. 

returns one of 

=over 4

ASCII: numbers returned as ascii signed  integers, comma separated

RIBINARY: signed integer binary, MSB transferred first (if width=2)

RPBINARY: unsigned integer binary, MSB first

SRIBINARY: signed integer binary, LSB first

SRPBINARY: unsigned integer binary, LSB first

=back

RIBINARY is the fastest transfer mode, particularly with width=1,
as is used for simple waveform traces, with values ranging from
-128..127 with 0 corresponding to the center of the screen. 

(width = 2 data range -32768 .. 32767 with center = 0) 

For unsigned data, width=1, range is 0..255 with 127 at center,
width=2 range is 0..65535.

In all cases the "lower limit" is one division below the bottom of the
screen, and the "upper limit" is one division above the top of the screen.

=head2 set_data_encoding

$s->set_data_encoding($enc);

$s->set_data_encoding(encoding=>$enc);

Set the waveform transfer encoding, see get_waveform_encoding for
possible values and their meanings.

=head2 get_data_start

$i = $s->get_data_start();

Fetch the index of the first waveform sample 
for transfers $i = 1..2500

=head2 set_data_start

$s->set_data_start($i);

$s->set_data_start(start=>$i);

Set the index of the first waveform sample
for transfers, $i = 1..2500.

=head2 get_data_stop

$i = $s->get_data_stop();

Fetch the index of the last waveform sample 
for transfers $i = 1..2500

=head2 set_data_stop

$s->set_data_stop($i);

$s->set_data_stop(stop=>$i);

Set the index of the lat waveform sample
for transfers, $i = 1..2500.

=head2 get_data_destination

$dst = $s->get_data_destination();

Fetch the destination (REFA..REFD) for data transfered
TO the scope. 

=head2 set_data_destination

$s->set_data_destination($dst);

$s->set_data_destination(destination=>$dst);

Set the destination ($dst = REFA..REFD) for waveforms
transferred to the scope. 

=head2 set_data_init

$s->set_data_init();

initialize all data parameters (source, destination, encoding, etc)
to factory defaults

=head2 get_data_source

$src = $s->get_data_source();

Fetch the source of waveforms transferred FROM the scope.

Possible values are CH1..CH4, MATH, or REFA..REFD.

=head2 set_data_source

$s->set_data_source($src);

$s->set_data_source(source => $src);

Set the source of waveforms transferred from the scope. Possible
values are CH1..CH4, MATH, or REFA..REFD. 

=head2 get_data

  $h = $s->get_data();

return a hash reference with data transfer information
such as width, encoding, source, etc, suitable for use with
the  set_data($h) routine

=head2 set_data

$s->set_data(width=>$w, start=>$istart, ... );

set data transfer characteristics, call with a hash
or hashref similar to what one gets from get_data()

=head2 get_waveform

$hashref = $s->get_waveform();

$hashref = $s->get_waveform( waveform=>$wfm,
                             start=>$startbin, stop=>$stopbin,
                             ...data parameters...);

Fetch waveform from specified channel; if parameters are not
set, use the current setup from the scope (see get_data_source) 
The value of $wfm can be CH1..4, MATH, or REFA..D.

returns $hashref = { v=>[voltages], t=>[times], various x,y parameters };

Note that voltages and times are indexed starting at '1', or at the
'data_start' index  (see set_data_start())  
    $hashref->{v}->[1]  ...first voltage sample, default

    Alternately:
    $s->set_data_start(33);
    ...
    $hashref->{v}->[33]  ... first voltage sample

    The hashref contains keys DAT:STAR and DAT:STOP for start and stop
    sample numbers. 

If you are going to alter the data in $hashref->{v}->[], make
sure to delete($hashref->{rawdata}) before the waveform is transmitted
to the scope, this will case the rawdata to be regenerated from 
the $hashref->{v}->[] entries.

=head2 create_waveform

$hwfd = $s->create_waveform();

$hwfd = $s->create_waveform($t0,$t1[,$n[,\&vfunc]]);

$hwfd = $s->create_waveform(tstart=>$t0, tstop=>$t1[, nbins=$n][, vfunc=\&vfunc]);

returns a hashref with an array of time values (useful for creating
a waveform) starting at $t0 and ending at $t1 with $n bins. Please
note that the TDS2024B can use $n=2500 at most, although this routine
will work for larger values of $n.  If $n is not specified $n=2500 for 
a simple waveform, and $n=1250 for an 'envelope' waveform. 

$t0 and $t1 can be numbers, in seconds, or text with suffixes: $t1='33ms'

The bin numbers start with '1', matching the scope behavior: $hwfd->{t}->[1] = $t0 ... $hwfd->{t}->[$n] = $t1

If a "vfunc" is given, it is called with the time values:

    $v = vfunc($t);  # $t in seconds   

If vfunc returns an array of two voltages, it is taken as "min,max" values
for an 'ENVELOPE' style waveform:

   ($vmin,$vmax) = vfunc($t);

In either case, the result is 
analyzed to produce a 'rawdata' entry with 8 bit waveform data, 
filling in the parameters needed for
transmitting the waveform to the scope. 

If you do not provide a reference to a "vfunc" function, you will
have to create and fill in an array: $hwfd->{v}->[$n] = voltage($n)
If you do not specify the $t0 and $t1 times, then you will also
have to create and fill in the $hwfd->{t}->[$n] = time($n) array.

To make use of an "envelope" waveform, fill in $hwfd->{vmin}->[$n]
and $hwfd->{vmax}->[$n].

=head2 put_waveform

$s->put_waveform($hwfm);

$s->put_waveform(waveform=>$hwfm, 
    [destination=>$dst, position=>$ypos, scale=>$yscale] )

Store waveform to one of the REFA..REFD traces. If not set explicitly
in the call arguments, uses the location set in the scope (see 
get_data_destination).

The vertical position of the trace is set with $ypos = divisions from
the screen center, and the vertical scale with $yscale = V/div. 

If  $hwfm->{rawdata} exists, it will be transmitted to the scope
unchanged. Otherwise the $hwfm->{rawdata} entry will be regenerated
from the $hwfm->{v}->[]  (or $hwfm->{vmin|vmax}->[]) array(s).  

The error/consistency checking is certainly not complete, so 
doing something 'tricky' with the $hwfm hash may give unexpected
results.

=head2 print_waveform

$s->print_waveform($hwfm [,$IOhandle]);

$s->print_waveform(waveform=>$hwfm [,output=>$iohandle]);

print information from the waveform stored in a
hasref $hwfm, taken from get_waveform();

This is mostly for diagnostic purposes.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Charles Lane
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel
            2021       Charles Lane


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
