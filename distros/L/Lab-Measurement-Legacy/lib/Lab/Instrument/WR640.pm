package Lab::Instrument::WR640;
#ABSTRACT: LeCroy WaveRunner 640 digital oscilloscope
$Lab::Instrument::WR640::VERSION = '3.899';
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
    supported_connections => ['VICP'],

    #default settings for connections

    connection_settings => {
        connection_type => 'VICP',
        remote_address  => 'nulrs640',
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
        ID      => undef,
        HEADER  => undef,
        VERBOSE => undef,
        LOCKED  => undef,

    },

    channel => undef,

    # almost all of the WR640 command suite is non-SCPI
    scpi_override => {

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

    $self->{config}->{no_cache}          = 1;
    $self->{config}->{default_read_mode} = '';
    $DEBUG = $self->{config}->{debug} if exists $self->{config}->{debug};

    # initialize channel caches
    foreach my $ch (qw(C1 C2 C3 C4)) {
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

    $self->{device_cache} = $self->{chan_cache}->{C1};
    $self->{channel}      = "C1";
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

    my $err = $self->query("CHL? CLR");
    $err =~ s/^(CHL\s*)?\"(.*)\"/$2/is;
    my (@lines) = split( /\n/, $err );
    my (@elines) = ();

    foreach my $x (@lines) {
        $x =~ s/^\s*(.*)\s*$/$1/;
        next if $x =~ /^connection\s/i;
        next if $x =~ /^disconnect/i;
        push( @elines, $x );
    }
    return (@elines);

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


sub recall {
    my $self = shift;
    my ( $mem, $tail ) = $self->_check_args( \@_, 'n' );

    my $n;
    if ( $mem =~ /^\s*([0-6])\s/ ) {
        $n = $1;
    }
    else {
        carp("recall memory n=$mem invalid, should be 0..6");
        return;
    }
    $self->write("*RCL $n");
}

sub get_setup {
    my $self = shift;
    my (@a) = ();

    foreach my $ch (qw(C1 C2 C3 C4 EX EX10 ETM10 LINE)) {
        if ( $ch =~ /C\d/ ) {
            foreach my $q (qw(ATTN CPL OFST OFCT TRA TRCP VDIV)) {
                push( @a, $self->query( $ch . ':' . $q . '?' ) );
            }
        }
        if ( $ch ne 'LINE' ) {
            push( @a, $self->query( $ch . ":TRLV?" ) );
        }
        push( @a, $self->query( $ch . ":TRSL?" ) );
    }

    for ( my $j = 1; $j <= 8; $j++ ) {
        my $ch = "F$j";
        foreach my $q (qw(TRA VMAG VPOS)) {
            push( @a, $self->query( $ch . ":" . $q . "?" ) );
        }
    }

    foreach my $ch (qw(M1 M2 M3 M4)) {
        push( @a, $self->query( $ch . ":VPOS?" ) );
    }

    foreach my $q (
        qw(ALST BWL COUT CMR COMB CFMT CHDR CORD CRMS
        ILVD RCLK SCLK SEQ TDIV TRDL TRMD TRPA
        TRSE WFSU)
        ) {
        push( @a, $self->query( $q . '?' ) );
    }

    return (@a);
}

sub get_visible {
    my $self = shift;
    my $ch   = shift;

    my $r = $self->query("$ch:TRA?");
    $r =~ s/^.*:TRA(ce)?\s+//i;
    $r = uc($r);
    return 1 if $r eq 'ON';
    return 0;
}

sub get_waveform {
    my $self = shift;
    my $ch   = shift;
    return $self->query("$ch:WF?");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::WR640 - LeCroy WaveRunner 640 digital oscilloscope (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

=over 4

    use Lab::Instrument::WR640;

    my $s = new Lab::Instrument::WR640 (
        address => '192.168.1.1',
    );

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

=head2 test_busy

$busy = $s->test_busy();

Returns 1 if busy (waiting for trigger, etc), 0 if not busy.

=head2 get_id

$s->get_id()

Fetch the *IDN? string from device

=head2 recall

$s->recall($n);

$s->recall(n => $n);

Recall setup 0..6

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Charles Lane
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
