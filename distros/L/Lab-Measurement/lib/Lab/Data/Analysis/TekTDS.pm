package Lab::Data::Analysis::TekTDS;
#ABSTRACT: Analysis routine for Tektronix TDS1000/TDS2000/etc. scopes
$Lab::Data::Analysis::TekTDS::VERSION = '3.881';
use v5.20;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Lab::SCPI;
use Lab::Instrument::TDS2024B;
use Lab::Data::Analysis;
use Clone qw(clone);

our @ISA = ("Lab::Data::Analysis");

our $DEBUG = 0;

# default config values, copied to $self->{CONFIG} initially

our $DEFAULT_CONFIG = {};


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless $self, $class;

    my ( $stream, $tail )
        = Lab::Data::Analysis::_check_args( \@_, qw(stream) );

    $self->{STREAM} = $stream;    # hash of stream fileheader info

    return $self;
}


sub Analyze {
    my $self  = shift;
    my $event = shift;

    # handle analysis options
    my $option = shift;
    $option = {} unless defined $option && ref($option) eq 'HASH';
    $option->{dropraw}       = 0 unless exists $option->{dropraw};
    $option->{interpolate}   = 1 unless exists $option->{interpolate};
    $option->{print_summary} = 0 unless exists $option->{print_summary};

    my $stream = $self->{STREAM}->{NUMBER};

    my $a = {};
    $a->{MODULE}      = 'TekTDS';
    $a->{RAW}         = {};
    $a->{RAW}->{CHAN} = {};
    $a->{CHAN}        = {};
    $a->{COMMENT}     = [];
    $a->{RUN}         = $event->{RUN};
    $a->{EVENT}       = $event->{EVENT};
    $a->{STREAM}      = $stream;
    $a->{OPTIONS}     = clone($option);

    # event->{ANALYZE}->{stream#}->{TekTDS}->{analysis stuff}?

    foreach my $c ( @{ $event->{STREAM}->{$stream}->{COMMENT} } ) {
        push( @{ $a->{COMMENT} }, $c );
    }

    my $ch;
    my $seq = [];
    foreach my $g ( @{ $event->{STREAM}->{$stream}->{GPIB} } ) {
        my $str = substr( $g, 1 );
        next if $str =~ /^\d+/;
        $seq = scpi_parse_sequence( $str, $seq );
    }
    print "seq = ", Dumper($seq), "\n", if $DEBUG;

    my $fseq = scpi_flat(
        $seq,
        $Lab::Instrument::TDS2024B::fields{scpi_override}
    );
    print "fseq = ", Dumper($fseq), "\n" if $DEBUG;

    for ( my $j = 0; exists( $fseq->[$j] ); $j++ ) {
        if ( exists( $fseq->[$j]->{'DAT:SOU'} ) ) {
            $ch = $fseq->[$j]->{'DAT:SOU'};
            $a->{RAW}->{CHAN}->{$ch} = {}
                unless exists $a->{RAW}->{CHAN}->{$ch};
            $a->{CHAN}->{$ch} = {} unless exists $a->{CHAN}->{$ch};
            $a->{CHAN}->{$ch}->{CHAN} = $ch;
            $a->{RAW}->{CHAN}->{$ch}->{CHAN} = $ch;
        }

        foreach my $k ( keys( %{ $fseq->[$j] } ) ) {
            print "\$fseq->[$j]->{$k} = '", $fseq->[$j]->{$k}, "'\n"
                if $DEBUG;
            if ( $k =~ /^(DAT|WFMP|CURV)/ ) {
                $a->{RAW}->{CHAN}->{$ch}->{$k} = $fseq->[$j]->{$k};
            }
        }

    }
    print Dumper($a) if $DEBUG > 2;
    $self->_PrintSummary( $a, $option ) if $option->{print_summary};

    foreach $ch ( keys( %{ $a->{RAW}->{CHAN} } ) ) {
        my $id   = $a->{RAW}->{CHAN}->{$ch}->{'WFMP:WFI'};
        my $x0   = $a->{RAW}->{CHAN}->{$ch}->{'WFMP:XZE'};
        my $y0   = $a->{RAW}->{CHAN}->{$ch}->{'WFMP:YZE'};
        my $dx   = $a->{RAW}->{CHAN}->{$ch}->{'WFMP:XIN'};
        my $xoff = $a->{RAW}->{CHAN}->{$ch}->{'WFMP:PT_O'};
        my $xun  = $a->{RAW}->{CHAN}->{$ch}->{'WFMP:XUN'};
        my $dy   = $a->{RAW}->{CHAN}->{$ch}->{'WFMP:YMU'};
        my $yoff = $a->{RAW}->{CHAN}->{$ch}->{'WFMP:YOF'};
        my $yun  = $a->{RAW}->{CHAN}->{$ch}->{'WFMP:YUN'};
        my $j0   = $a->{RAW}->{CHAN}->{$ch}->{'DAT:STAR'};
        my $j1   = $a->{RAW}->{CHAN}->{$ch}->{'DAT:STOP'};
        my $enc  = $a->{RAW}->{CHAN}->{$ch}->{'DAT:ENC'};
        my $wd   = $a->{RAW}->{CHAN}->{$ch}->{'DAT:WID'};
        my $d    = $a->{RAW}->{CHAN}->{$ch}->{'CURV'};

        $id =~ s/^\"(.*)\"/$1/;
        $a->{CHAN}->{$ch}->{ID} = $id;
        $xun =~ s/^\"(.*)\"/$1/;
        $yun =~ s/^\"(.*)\"/$1/;
        $a->{CHAN}->{$ch}->{Xunit} = $xun;
        $a->{CHAN}->{$ch}->{Yunit} = $yun;
        $a->{CHAN}->{$ch}->{DX}    = $dx;
        $a->{CHAN}->{$ch}->{X}     = [];

        my (@dat) = _extractWaveform( $enc, $wd, $d );
        my ( $ymin, $ymax );
        if ( $a->{RAW}->{CHAN}->{$ch}->{'WFMP:PT_F'} eq 'Y' ) {
            $a->{CHAN}->{$ch}->{Y}     = [];
            $a->{CHAN}->{$ch}->{START} = $j0;
            $a->{CHAN}->{$ch}->{STOP}  = $j1;
            for ( my $j = 0; $j <= $#dat; $j++ ) {
                $a->{CHAN}->{$ch}->{X}->[ $j + $j0 ]
                    = $x0 + $dx * ( $j - $xoff );
                my $y = $y0 + $dy * ( $dat[$j] - $yoff );
                $a->{CHAN}->{$ch}->{Y}->[ $j + $j0 ] = $y;
                $ymin = $y unless defined $ymin && $y > $ymin;
                $ymax = $y unless defined $ymax && $y < $ymax;
            }
        }
        else {    #envelope
            $a->{CHAN}->{$ch}->{Y0}    = [];
            $a->{CHAN}->{$ch}->{Y1}    = [];
            $a->{CHAN}->{$ch}->{START} = $j0;
            $a->{CHAN}->{$ch}->{STOP}  = $j0 + $#dat / 2;
            for ( my $j = 0; $j <= $#dat; $j += 2 ) {
                $a->{CHAN}->{$ch}->{X}->[ $j / 2 + $j0 ]
                    = $x0 + $dx * ( $j - $xoff );
                my $y = $y0 + $dy * ( $dat[$j] - $yoff );
                $a->{CHAN}->{$ch}->{Y0}->[ $j / 2 + $j0 ] = $y;
                $ymin = $y unless defined $ymin && $y > $ymin;
                $ymax = $y unless defined $ymax && $y < $ymax;

                $y = $y0 + $dy * ( $dat[ $j + 1 ] - $yoff );
                $a->{CHAN}->{$ch}->{Y1}->[ $j / 2 + $j0 ] = $y;
                $ymin = $y unless defined $ymin && $y > $ymin;
                $ymax = $y unless defined $ymax && $y < $ymax;
            }
        }
        $a->{CHAN}->{$ch}->{YMIN} = $ymin;
        $a->{CHAN}->{$ch}->{YMAX} = $ymax;

        $a->{CHAN}->{$ch}->{XMIN} = $a->{CHAN}->{$ch}->{X}->[$j0];
        $a->{CHAN}->{$ch}->{XMAX} = $a->{CHAN}->{$ch}->{X}->[$j1];

        #
        # creates an anonymous sub that interpolates into the waveform
        #
        if ( $option->{interpolate} ) {
            $a->{CHAN}->{$ch}->{Yfunc} = sub {
                use feature 'state';
                state $hchan;
                $hchan = $a->{CHAN}->{$ch} unless defined $hchan;
                return ( _interpolate( $hchan, @_ ) );
            };
            $a->{CHAN}->{$ch}->{Yfunc}->(0);    # initialize state var
        }
    }
    delete( $a->{RAW} ) if $option->{dropraw};
    $event->{ANALYZE} = {} unless exists $event->{ANALYZE};

    $event->{ANALYZE}->{$stream} = {}
        unless exists $event->{ANALYZE}->{$stream};

    $event->{ANALYZE}->{$stream}->{TekTDS} = $a;

    #    push(@{$event->{ANALYZED}},$a);
    return $event;
}

sub _interpolate {
    my $h = shift;    # hash pointer to {CHAN}->{$ch}
    if ( ref($h) ne 'HASH' ) {
        carp("bad hash pointer for wfd interpolation");
        return undef;
    }
    my $x = shift;

    return undef if $x < $h->{XMIN} || $x > $h->{XMAX};

    my $nx  = ( $x - $h->{XMIN} ) / $h->{DX};
    my $nx0 = int($nx);
    my ( $y0, $y1, $ry0, $ry1 );
    if ( exists( $h->{Y} ) ) {
        $y0 = $h->{Y}->[$nx0];
        $y1 = $h->{Y}->[ $nx0 + 1 ];
        return $y0 + ( $y1 - $y0 ) * ( $nx - $nx0 );
    }
    else {
        $y0  = $h->{Y0}->[$nx0];
        $y1  = $h->{Y0}->[ $nx0 + 1 ];
        $ry0 = ( $y1 - $y0 ) * ( $nx - $nx0 );

        $y0  = $h->{Y1}->[$nx0];
        $y1  = $h->{Y1}->[ $nx0 + 1 ];
        $ry1 = ( $y1 - $y0 ) * ( $nx - $nx0 );
        return ( $ry0, $ry1 );
    }
}

sub _PrintSummary {
    my $self = shift;
    my $a    = shift;
    my $opt  = shift;

    print "TekTDS Analysis Summary: Run ", $a->{RUN},
        " Event ", $a->{EVENT}, " Stream ", $a->{STREAM}, "\n";

    print "\nAnalysis Options:\n";
    foreach my $k ( sort( keys( %{ $a->{OPTIONS} } ) ) ) {
        print "\t $k = ", $a->{OPTIONS}->{$k}, "\n";
    }

    print "\nDAQ inline comments:\n";
    foreach my $c ( @{ $a->{COMMENT} } ) {
        print "\t \"$c\"\n";
    }

    print "\nChannels:";
    foreach my $ch ( sort( keys( %{ $a->{RAW}->{CHAN} } ) ) ) {
        print " $ch";
    }
    print "\n";

    foreach my $ch ( sort( keys( %{ $a->{RAW}->{CHAN} } ) ) ) {
        print "Channel $ch info: \n";

        foreach my $k ( sort( keys( %{ $a->{RAW}->{CHAN}->{$ch} } ) ) ) {
            next if $k =~ /\?$/;
            next if $k eq 'CURV';
            my $key = sprintf( "%-18s", $k );
            print "\t$key : ", $a->{RAW}->{CHAN}->{$ch}->{$k}, "\n";
        }
        print "\n";
    }

}

sub _extractWaveform {
    my $enc = shift;
    my $wd  = shift;
    my $dat = shift;

    my (@result);

    $enc =~ s/^\s*//;

    if ( $enc =~ /^ASC/i ) {
        @result = split( /,/, $dat );
    }
    else {
        if ( substr( $dat, 0, 2 ) !~ /^#\d/ ) {
            croak("bad binary curve data");
        }
        my $nx = substr( $dat, 1, 1 );
        my $n  = substr( $dat, 2, $nx );
        my $form;
        if ( $wd == 1 ) {
            if ( $enc =~ /^RPB/i ) {
                $form = 'C';
            }
            else {
                $form = 'c';
            }
        }
        else {
            if ( $enc =~ /RPB/i ) {
                $form = 'S';    # unsigned
            }
            else {
                $form = 's';    # RIB signed
            }
            if ( $enc =~ /^S/i ) {    # LSB first
                $form .= '<';
            }
            else {
                $form .= '>';         # MSB first
            }
        }
        $form .= '*';
        @result = unpack( $form, substr( $dat, $nx + 2 ) );
    }
    return (@result);
}

1;                                    # End of Lab::Data::Analysis::TekTDS

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Data::Analysis::TekTDS - Analysis routine for Tektronix TDS1000/TDS2000/etc. scopes

=head1 VERSION

version 3.881

=head1 SUBROUTINES/METHODS

=head2 new

my $a = Lab::Data::Analysis::TekTDS->new(stream=>$stream);

create a new TekTDS analysis object; for use by Lab::Data::Analysis
code

=head2 Analyze

my $event = $a->Analyze($event[, optionshash]);

Do TekTDS analysis on an event (passed by hashref); the
results of the analysis are stored in the hashref, and the
hashref is returned.

If there is an error, "undef" is returned.

The analysis results can be found in 

$event->{CHAN}->{$channel}->{

	    CHAN => channel name,

	    X => [ ... x values ... typically times ],

	    Yunit => unit for Y scale,

	    Xunit => unit for X scale,

	    ID => ID string describing waveform,

            START => $jstart        ... $X->[$jstart] is first sample
 
            STOP => $jstop          ... $X->[$jstop] is last sample

            two options:

           Y => [ ... y values... typically voltages ],

            or 

           YMIN => [ ... min y values ...], YMAX=> [... max y values..],

The YMIN,YMAX arrays are returned for 'envelope' type waveforms.

To get the usual time/voltage pairs:

      for ($j = $ev->{CHAN}->{CH1}->{START};
 
        $j <= $ev->{CHAN}->{CH1}->{STOP}; $j++) {

        $t = $ev->{CHAN}->{CH1}->X->[$j];

        $v = $ev->{CHAN}->{CH1}->Y->[$j];

      }

Analysis options:

    dropraw => [def: 0]    ... drop the raw analysis intermediate results
    interpolate => [def: 1] ... create a Yfunc interpolation function
    print_summary => [def: 0] ..print a summary of waveform info

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Charles Lane
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
