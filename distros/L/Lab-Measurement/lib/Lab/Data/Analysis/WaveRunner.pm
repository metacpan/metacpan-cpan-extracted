package Lab::Data::Analysis::WaveRunner;
#ABSTRACT: Analysis routine for LeCroy WaveRunner/etc. scopes
$Lab::Data::Analysis::WaveRunner::VERSION = '3.881';
use v5.20;

use strict;
use warnings;
use English;
use Carp;
use Data::Dumper;
use Lab::Data::Analysis;
use Clone qw(clone);

our @ISA = ("Lab::Data::Analysis");

our $DEBUG = 0;

# default config values, copied to $self->{CONFIG} initially

our $DEFAULT_CONFIG = {};

# template => [  [name, { hash}], ... ]

our $DEFAULT_TEMPLATE = [
    [
        'WAVEDESC:BLOCK',
        [
            {
                'TYPE'   => 'string',
                'NAME'   => 'DESCRIPTOR_NAME',
                'OFFSET' => '0'
            },
            {
                'OFFSET' => '16',
                'NAME'   => 'TEMPLATE_NAME',
                'TYPE'   => 'string'
            },
            {
                'ENUM' => {
                    '0' => 'byte',
                    '1' => 'word'
                },
                'NAME'   => 'COMM_TYPE',
                'TYPE'   => 'enum',
                'OFFSET' => '32'
            },
            {
                'TYPE' => 'enum',
                'NAME' => 'COMM_ORDER',
                'ENUM' => {
                    '0' => 'HIFIRST',
                    '1' => 'LOFIRST'
                },
                'OFFSET' => '34'
            },
            {
                'OFFSET' => '36',
                'TYPE'   => 'long',
                'NAME'   => 'WAVE_DESCRIPTOR'
            },
            {
                'OFFSET' => '40',
                'NAME'   => 'USER_TEXT',
                'TYPE'   => 'long'
            },
            {
                'NAME'   => 'RES_DESC1',
                'TYPE'   => 'long',
                'OFFSET' => '44'
            },
            {
                'OFFSET' => '48',
                'TYPE'   => 'long',
                'NAME'   => 'TRIGTIME_ARRAY'
            },
            {
                'NAME'   => 'RIS_TIME_ARRAY',
                'TYPE'   => 'long',
                'OFFSET' => '52'
            },
            {
                'OFFSET' => '56',
                'NAME'   => 'RES_ARRAY1',
                'TYPE'   => 'long'
            },
            {
                'TYPE'   => 'long',
                'NAME'   => 'WAVE_ARRAY_1',
                'OFFSET' => '60'
            },
            {
                'NAME'   => 'WAVE_ARRAY_2',
                'TYPE'   => 'long',
                'OFFSET' => '64'
            },
            {
                'NAME'   => 'RES_ARRAY2',
                'TYPE'   => 'long',
                'OFFSET' => '68'
            },
            {
                'NAME'   => 'RES_ARRAY3',
                'TYPE'   => 'long',
                'OFFSET' => '72'
            },
            {
                'NAME'   => 'INSTRUMENT_NAME',
                'TYPE'   => 'string',
                'OFFSET' => '76'
            },
            {
                'OFFSET' => '92',
                'TYPE'   => 'long',
                'NAME'   => 'INSTRUMENT_NUMBER'
            },
            {
                'OFFSET' => '96',
                'TYPE'   => 'string',
                'NAME'   => 'TRACE_LABEL'
            },
            {
                'OFFSET' => '112',
                'TYPE'   => 'word',
                'NAME'   => 'RESERVED1'
            },
            {
                'NAME'   => 'RESERVED2',
                'TYPE'   => 'word',
                'OFFSET' => '114'
            },
            {
                'OFFSET' => '116',
                'TYPE'   => 'long',
                'NAME'   => 'WAVE_ARRAY_COUNT'
            },
            {
                'TYPE'   => 'long',
                'NAME'   => 'PNTS_PER_SCREEN',
                'OFFSET' => '120'
            },
            {
                'OFFSET' => '124',
                'NAME'   => 'FIRST_VALID_PNT',
                'TYPE'   => 'long'
            },
            {
                'OFFSET' => '128',
                'NAME'   => 'LAST_VALID_PNT',
                'TYPE'   => 'long'
            },
            {
                'NAME'   => 'FIRST_POINT',
                'TYPE'   => 'long',
                'OFFSET' => '132'
            },
            {
                'OFFSET' => '136',
                'TYPE'   => 'long',
                'NAME'   => 'SPARSING_FACTOR'
            },
            {
                'OFFSET' => '140',
                'TYPE'   => 'long',
                'NAME'   => 'SEGMENT_INDEX'
            },
            {
                'NAME'   => 'SUBARRAY_COUNT',
                'TYPE'   => 'long',
                'OFFSET' => '144'
            },
            {
                'TYPE'   => 'long',
                'NAME'   => 'SWEEPS_PER_ACQ',
                'OFFSET' => '148'
            },
            {
                'TYPE'   => 'word',
                'NAME'   => 'POINTS_PER_PAIR',
                'OFFSET' => '152'
            },
            {
                'OFFSET' => '154',
                'NAME'   => 'PAIR_OFFSET',
                'TYPE'   => 'word'
            },
            {
                'TYPE'   => 'float',
                'NAME'   => 'VERTICAL_GAIN',
                'OFFSET' => '156'
            },
            {
                'OFFSET' => '160',
                'TYPE'   => 'float',
                'NAME'   => 'VERTICAL_OFFSET'
            },
            {
                'NAME'   => 'MAX_VALUE',
                'TYPE'   => 'float',
                'OFFSET' => '164'
            },
            {
                'OFFSET' => '168',
                'TYPE'   => 'float',
                'NAME'   => 'MIN_VALUE'
            },
            {
                'NAME'   => 'NOMINAL_BITS',
                'TYPE'   => 'word',
                'OFFSET' => '172'
            },
            {
                'NAME'   => 'NOM_SUBARRAY_COUNT',
                'TYPE'   => 'word',
                'OFFSET' => '174'
            },
            {
                'OFFSET' => '176',
                'TYPE'   => 'float',
                'NAME'   => 'HORIZ_INTERVAL'
            },
            {
                'NAME'   => 'HORIZ_OFFSET',
                'TYPE'   => 'double',
                'OFFSET' => '180'
            },
            {
                'NAME'   => 'PIXEL_OFFSET',
                'TYPE'   => 'double',
                'OFFSET' => '188'
            },
            {
                'TYPE'   => 'unit_definition',
                'NAME'   => 'VERTUNIT',
                'OFFSET' => '196'
            },
            {
                'OFFSET' => '244',
                'TYPE'   => 'unit_definition',
                'NAME'   => 'HORUNIT'
            },
            {
                'OFFSET' => '292',
                'NAME'   => 'HORIZ_UNCERTAINTY',
                'TYPE'   => 'float'
            },
            {
                'OFFSET' => '296',
                'NAME'   => 'TRIGGER_TIME',
                'TYPE'   => 'time_stamp'
            },
            {
                'TYPE'   => 'float',
                'NAME'   => 'ACQ_DURATION',
                'OFFSET' => '312'
            },
            {
                'OFFSET' => '316',
                'TYPE'   => 'enum',
                'ENUM'   => {
                    '8' => 'centered_RIS',
                    '1' => 'interleaved',
                    '2' => 'histogram',
                    '7' => 'sequence_obsolete',
                    '4' => 'filter_coefficient',
                    '0' => 'single_sweep',
                    '5' => 'complex',
                    '9' => 'peak_detect',
                    '3' => 'graph',
                    '6' => 'extrema'
                },
                'NAME' => 'RECORD_TYPE'
            },
            {
                'TYPE' => 'enum',
                'NAME' => 'PROCESSING_DONE',
                'ENUM' => {
                    '0' => 'no_processing',
                    '5' => 'no_result',
                    '2' => 'interpolated',
                    '4' => 'autoscaled',
                    '7' => 'cumulative',
                    '3' => 'sparsed',
                    '6' => 'rolling',
                    '1' => 'fir_filter'
                },
                'OFFSET' => '318'
            },
            {
                'OFFSET' => '320',
                'TYPE'   => 'word',
                'NAME'   => 'RESERVED5'
            },
            {
                'TYPE'   => 'word',
                'NAME'   => 'RIS_SWEEPS',
                'OFFSET' => '322'
            },
            {
                'TYPE' => 'enum',
                'ENUM' => {
                    '44'  => '500_s/div',
                    '42'  => '100_s/div',
                    '32'  => '50_ms/div',
                    '10'  => '2_ns/div',
                    '29'  => '5_ms/div',
                    '23'  => '50_us/div',
                    '38'  => '5_s/div',
                    '18'  => '1_us/div',
                    '0'   => '1_ps/div',
                    '4'   => '20_ps/div',
                    '17'  => '500_ns/div',
                    '20'  => '5_us/div',
                    '2'   => '5_ps/div',
                    '14'  => '50_ns/div',
                    '12'  => '10_ns/div',
                    '36'  => '1_s/div',
                    '22'  => '20_us/div',
                    '9'   => '1_ns/div',
                    '26'  => '500_us/div',
                    '37'  => '2_s/div',
                    '24'  => '100_us/div',
                    '31'  => '20_ms/div',
                    '1'   => '2_ps/div',
                    '25'  => '200_us/div',
                    '47'  => '5_ks/div',
                    '5'   => '50_ps/div',
                    '27'  => '1_ms/div',
                    '6'   => '100_ps/div',
                    '40'  => '20_s/div',
                    '3'   => '10_ps/div',
                    '39'  => '10_s/div',
                    '35'  => '500_ms/div',
                    '28'  => '2_ms/div',
                    '46'  => '2_ks/div',
                    '8'   => '500_ps/div',
                    '15'  => '100_ns/div',
                    '7'   => '200_ps/div',
                    '33'  => '100_ms/div',
                    '11'  => '5_ns/div',
                    '41'  => '50_s/div',
                    '100' => 'EXTERNAL',
                    '34'  => '200_ms/div',
                    '16'  => '200_ns/div',
                    '19'  => '2_us/div',
                    '21'  => '10_us/div',
                    '13'  => '20_ns/div',
                    '43'  => '200_s/div',
                    '45'  => '1_ks/div',
                    '30'  => '10_ms/div'
                },
                'NAME'   => 'TIMEBASE',
                'OFFSET' => '324'
            },
            {
                'ENUM' => {
                    '1' => 'ground',
                    '3' => 'ground',
                    '0' => 'DC_50_Ohms',
                    '2' => 'DC_1MOhm',
                    '4' => 'AC_1MOhm'
                },
                'NAME'   => 'VERT_COUPLING',
                'TYPE'   => 'enum',
                'OFFSET' => '326'
            },
            {
                'OFFSET' => '328',
                'TYPE'   => 'float',
                'NAME'   => 'PROBE_ATT'
            },
            {
                'OFFSET' => '332',
                'ENUM'   => {
                    '15' => '100_mV/div',
                    '8'  => '500_uV/div',
                    '23' => '50_V/div',
                    '10' => '2_mV/div',
                    '26' => '500_V/div',
                    '9'  => '1_mV/div',
                    '22' => '20_V/div',
                    '11' => '5_mV/div',
                    '12' => '10_mV/div',
                    '2'  => '5_uV/div',
                    '20' => '5_V/div',
                    '14' => '50_mV/div',
                    '7'  => '200_uV/div',
                    '17' => '500_mV/div',
                    '4'  => '20_uV/div',
                    '0'  => '1_uV/div',
                    '18' => '1_V/div',
                    '13' => '20_mV/div',
                    '25' => '200_V/div',
                    '1'  => '2_uV/div',
                    '21' => '10_V/div',
                    '19' => '2_V/div',
                    '16' => '200_mV/div',
                    '24' => '100_V/div',
                    '3'  => '10_uV/div',
                    '6'  => '100_uV/div',
                    '27' => '1_kV/div',
                    '5'  => '50_uV/div'
                },
                'NAME' => 'FIXED_VERT_GAIN',
                'TYPE' => 'enum'
            },
            {
                'OFFSET' => '334',
                'ENUM'   => {
                    '0' => 'off',
                    '1' => 'on'
                },
                'NAME' => 'BANDWIDTH_LIMIT',
                'TYPE' => 'enum'
            },
            {
                'NAME'   => 'VERTICAL_VERNIER',
                'TYPE'   => 'float',
                'OFFSET' => '336'
            },
            {
                'OFFSET' => '340',
                'NAME'   => 'ACQ_VERT_OFFSET',
                'TYPE'   => 'float'
            },
            {
                'TYPE' => 'enum',
                'ENUM' => {
                    '2' => 'CHANNEL_3',
                    '0' => 'CHANNEL_1',
                    '9' => 'UNKNOWN',
                    '1' => 'CHANNEL_2',
                    '3' => 'CHANNEL_4'
                },
                'NAME'   => 'WAVE_SOURCE',
                'OFFSET' => '344'
            }
        ]
    ],
    [
        'USERTEXT:BLOCK',
        [
            {
                'OFFSET' => '0',
                'NAME'   => 'TEXT',
                'TYPE'   => 'text'
            }
        ]
    ],
    [
        'TRIGTIME:ARRAY',
        [
            {
                'OFFSET' => '0',
                'TYPE'   => 'double',
                'NAME'   => 'TRIGGER_TIME'
            },
            {
                'NAME'   => 'TRIGGER_OFFSET',
                'TYPE'   => 'double',
                'OFFSET' => '8'
            }
        ]
    ],
    [
        'RISTIME:ARRAY',
        [
            {
                'OFFSET' => '0',
                'TYPE'   => 'double',
                'NAME'   => 'RIS_OFFSET'
            }
        ]
    ],
    [
        'DATA_ARRAY_1:ARRAY',
        [
            {
                'NAME'   => 'MEASUREMENT',
                'TYPE'   => 'data',
                'OFFSET' => '0'
            }
        ]
    ],
    [
        'DATA_ARRAY_2:ARRAY',
        [
            {
                'OFFSET' => '0',
                'NAME'   => 'MEASUREMENT',
                'TYPE'   => 'data'
            }
        ]
    ],
    [
        'SIMPLE:ARRAY',
        [
            {
                'TYPE'   => 'data',
                'NAME'   => 'MEASUREMENT',
                'OFFSET' => '0'
            }
        ]
    ],
    [
        'DUAL:ARRAY',
        [
            {
                'TYPE'   => 'data',
                'NAME'   => 'MEASUREMENT_1',
                'OFFSET' => '0'
            },
            {
                'NAME'   => 'MEASUREMENT_2',
                'TYPE'   => 'data',
                'OFFSET' => '0'
            }
        ]
    ]
];


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless $self, $class;

    my ( $stream, $tail )
        = Lab::Data::Analysis::_check_args( \@_, qw(stream) );

    $self->{STREAM} = $stream;    # hash of stream fileheader info
    $self->{TEMPLATE}      = clone($DEFAULT_TEMPLATE);
    $self->{PARSED_HEADER} = 0;
    $self->{BYTEORDER} = '>';     # MSB, gets fixed when waveform read

    return $self;
}


sub Analyze {
    my $self  = shift;
    my $event = shift;

    # handle analysis options
    my $option = shift;
    $option = {} unless defined $option && ref($option) eq 'HASH';
    $option->{dropraw}     = 0 unless exists $option->{dropraw};
    $option->{interpolate} = 1 unless exists $option->{interpolate};
    $option->{use_default_template} = 0
        unless exists $option->{use_default_template};
    $option->{print_summary} = 0 unless exists $option->{print_summary};

    if ( !$option->{use_default_template} ) {
        $self->_ParseHeader( $event, $option ) unless $self->{PARSED_HEADER};
    }

    my $stream = $self->{STREAM}->{NUMBER};

    my $a = {};
    $a->{MODULE}      = 'WaveRunner';
    $a->{RAW}         = {};
    $a->{RAW}->{CHAN} = {};
    $a->{EVENT}       = $event->{EVENT};
    $a->{RUN}         = $event->{RUN};
    $a->{CHAN}        = {};
    $a->{COMMENT}     = [];
    $a->{STREAM}      = $stream;
    $a->{OPTIONS}     = clone($option);

    foreach my $c ( @{ $event->{STREAM}->{$stream}->{COMMENT} } ) {
        push( @{ $a->{COMMENT} }, $c );
    }

    my $ch;
    my $seq = [];
    foreach my $g ( @{ $event->{STREAM}->{$stream}->{GPIB} } ) {
        next unless substr( $g, 0, 1 ) eq '<';    # from scope
        my $str = substr( $g, 1 );
        next unless $str =~ /^\s*:?(\w+):(WF|WAVEFORM)\s*(\w+),/i;
        $ch = uc($1);
        my $parts = uc($3);
        $g = $POSTMATCH;
        $a->{RAW}->{CHAN}->{$ch} = $self->_ParseWaveform( $g, $option );
        $a->{RAW}->{CHAN}->{$ch}->{PARTS} = $parts;
        $a->{CHAN}->{$ch}
            = $self->_AnalyzeWaveform( $a->{RAW}->{CHAN}->{$ch}, $option );
    }

    print Dumper($a) if $DEBUG > 2;
    $self->_PrintSummary( $a, $option ) if $option->{print_summary};

    $event->{ANALYZE} = {} unless exists $event->{ANALYZE};
    $event->{ANALYZE}->{$stream} = {}
        unless exists $event->{ANALYZE}->{$stream};

    delete( $a->{RAW} ) if $option->{dropraw};
    $event->{ANALYZE}->{$stream}->{WaveRunner} = $a;

    return $event;
}

sub _AnalyzeWaveform {
    my $self = shift;
    my $raw  = shift;
    my $opt  = shift;

    my $a = {};

    my $id = $raw->{WAVEDESC}->{INSTRUMENT_NAME};
    $id .= ', ' . $raw->{WAVEDESC}->{WAVE_SOURCE};
    $id .= ': ' . $raw->{WAVEDESC}->{VERT_COUPLING};
    $id .= ', 1:' . $raw->{WAVEDESC}->{PROBE_ATT};
    $id .= ' ' . $raw->{WAVEDESC}->{TIMEBASE};
    $id .= ' ' . $raw->{WAVEDESC}->{RECORD_TYPE};
    $id .= ' ' . $raw->{WAVEDESC}->{FIXED_VERT_GAIN};
    $id .= ' [' . $raw->{WAVEDESC}->{TRACE_LABEL} . ']'
        if $raw->{WAVEDESC}->{TRACE_LABEL} ne '';
    $a->{ID} = $id;

    $a->{VERTUNIT} = $raw->{WAVEDESC}->{VERTUNIT};
    $a->{HORUNIT}  = $raw->{WAVEDESC}->{HORUNIT};
    $a->{TIME}     = $raw->{WAVEDESC}->{TRIGGER_TIME};

    my $vgain = $raw->{WAVEDESC}->{VERTICAL_GAIN};
    my $voff  = $raw->{WAVEDESC}->{VERTICAL_OFFSET};
    my $hint  = $raw->{WAVEDESC}->{HORIZ_INTERVAL};
    my $hoff  = $raw->{WAVEDESC}->{HORIZ_OFFSET};
    my $j0    = $raw->{WAVEDESC}->{FIRST_VALID_PNT};
    my $j1    = $raw->{WAVEDESC}->{LAST_VALID_PNT};

    $a->{Y} = [];
    $a->{X} = [];
    my ( $ymax, $ymin );

    $a->{START} = $j0;
    $a->{STOP}  = $j1;
    for ( my $j = $j0; $j <= $j1; $j++ ) {
        my $d = $raw->{WAVE_ARRAY_1}->{MEASUREMENT}->[$j];
        my $y = $d * $vgain - $voff;
        $ymax = $y unless defined($ymax) && $ymax > $y;
        $ymin = $y unless defined($ymin) && $ymin < $y;

        my $x = $j * $hint + $hoff;
        $a->{Y}->[$j] = $y;
        $a->{X}->[$j] = $x;
    }
    $a->{YMAX} = $ymax;
    $a->{YMIN} = $ymin;
    $a->{XMIN} = $j0 * $hint + $hoff;
    $a->{XMAX} = $j1 * $hint + $hoff;

    return $a;
}

sub _PrintSummary {
    my $self = shift;
    my $a    = shift;
    my $opt  = shift;

    print "WaveRunner Analysis Summary: Run ", $a->{RUN}, " Event ",
        $a->{EVENT}, " Stream ", $a->{STREAM}, "\n";

    print "\nAnalysis options:\n";
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
        print "Channel $ch summary: \n";
        print "\tWaveform parts transmitted: ",
            $a->{RAW}->{CHAN}->{$ch}->{PARTS}, "\n";

        foreach my $k (
            sort( keys( %{ $a->{RAW}->{CHAN}->{$ch}->{WAVEDESC} } ) ) ) {
            my $key = sprintf( "%-18s", $k );
            print "\t$key : ", $a->{RAW}->{CHAN}->{$ch}->{WAVEDESC}->{$k},
                "\n";
        }
        print "\n";
    }

}

sub _trimNul {
    my $s = shift;
    $s =~ s/\0+$//;
    return $s;
}

sub _ParseWaveform {
    my $self = shift;
    my $w    = shift;
    my $opt  = shift;    # hash of analysis options

    if ( !defined( $self->{TEMPLATE} ) ) {
        carp("no waveform template defined!");
        return undef;
    }

    # make in index by template part name
    if (   !exists( $self->{TEMPLATE_PART} )
        || !defined( $self->{TEMPLATE_PART} ) ) {
        $self->{TEMPLATE_PART} = {};

        my $j = 0;
        foreach my $part ( @{ $self->{TEMPLATE} } ) {
            $self->{TEMPLATE_PART}->{ $self->{TEMPLATE}->[$j]->[0] } = $j;
            $j++;
        }
    }

    my $a = {};

    if ( substr( $w, 0, 1 ) ne '#' ) {
        carp("no leading # in waveform data");
        return undef;
    }
    my $nd = substr( $w, 1, 1 );
    if ( $nd !~ /[1-9]/ ) {
        carp("no num digits digit in waveform data");
        return undef;
    }
    my $n = substr( $w, 2, $nd );
    if ( $n !~ /^\d+$/ ) {
        carp("invalid digits in waveform data count");
        return undef;
    }
    $w = substr( $w, 2 + $nd, $n );    # w is the binary string of wf data

    # need to find the byte order

    if ( !exists( $self->{TEMPLATE_PART}->{'WAVEDESC:BLOCK'} ) ) {
        carp("waveform templates needs WAVEDESC:BLOCK!");
        return undef;
    }
    if ( $self->{TEMPLATE_PART}->{'WAVEDESC:BLOCK'} != 0 ) {
        carp("WAVEDESC:BLOCK must come first in waveform data");
        return undef;
    }

    my $wdesc = $self->{TEMPLATE}->[0]->[1];
    foreach my $f ( @{$wdesc} ) {
        next unless $f->{NAME} eq 'COMM_ORDER';
        my $bord = unpack( 'S', substr( $w, $f->{OFFSET}, 2 ) );
        if ( $bord == 0 ) {
            $self->{BYTEORDER} = '>';
        }
        else {
            $self->{BYTEORDER} = '<';
        }
        last;
    }
    $self->{COMM_TYPE} = 'byte';    # temp

    # now decode the WAVEDESC block
    $a->{WAVEDESC} = {};
    my $p = 0;                      # offset into overall data block
    foreach my $f ( @{$wdesc} ) {
        $f = $self->_fetchwf( $w, $f, $p );
        $a->{WAVEDESC}->{ $f->{NAME} } = $f->{VALUE};
    }
    $p += $a->{WAVEDESC}->{WAVE_DESCRIPTOR};
    $self->{COMM_TYPE} = $a->{WAVEDESC}->{COMM_TYPE};    # need for 'data'

    # usertext block
    $a->{USER_TEXT} = '';
    my $seglen = $a->{WAVEDESC}->{USER_TEXT};
    if ( $seglen > 0 ) {
        $a->{USER_TEXT} = _trimNul( substr( $w, $p, $seglen ) );
        $p += $seglen;
    }

    # arrays

    my $tname = {
        TRIGTIME_ARRAY => 'TRIGTIME:ARRAY',
        RIS_TIME_ARRAY => 'RISTIME:ARRAY',
        RES_ARRAY1     => 'SIMPLE:ARRAY',
        WAVE_ARRAY_1   => 'DATA_ARRAY_1:ARRAY',
        WAVE_ARRAY_2   => 'DATA_ARRAY_2:ARRAY',
        RES_ARRAY2     => 'SIMPLE:ARRAY',
        RES_ARRAY3     => 'SIMPLE:ARRAY',
    };

    foreach my $aname (
        qw(TRIGTIME_ARRAY RIS_TIME_ARRAY RES_ARRAY1
        WAVE_ARRAY_1 WAVE_ARRAY_2 RES_ARRAY2 RES_ARRAY3)
        ) {
        if ( !exists( $a->{WAVEDESC}->{$aname} ) ) {
            carp("Array $aname length not found");
            next;
        }

        my $template = $tname->{$aname};

        if ( !exists( $self->{TEMPLATE_PART}->{$template} ) ) {
            carp("No template found for $template");
            next;
        }
        my $jtemp = $self->{TEMPLATE_PART}->{$template};
        $wdesc = $self->{TEMPLATE}->[$jtemp]->[1];

        # each piece of the ARRAY thing gets its own array
        # maybe not the best way to do it, but what is?

        # $a->{TRIGTIME_ARRAY}->{TRIGGER_TIME} = []
        # $a->{TRIGTIME_ARRAY}->{TRIGGER_OFFSET} = []
        # $a->{WAVE_ARRAY_1}->{MEASUREMENT} = []
        # etc

        $seglen = $a->{WAVEDESC}->{$aname};

        # fill from data block, unless a "reserved" array
        if ( $aname =~ /^RES_/ ) {
            $p += $seglen;
        }
        else {

            # create the arrays
            $a->{$aname} = {};
            foreach my $f ( @{$wdesc} ) {
                $a->{$aname}->{ $f->{NAME} } = [];
            }

            while ( $seglen > 0 ) {
                my $len = 0;
                foreach my $f ( @{$wdesc} ) {
                    $f->{TYPE} = $self->{COMM_TYPE} if $f->{TYPE} eq 'data';

                    # array of ONE type can be unpacked all at once.
                    if ( $#{$wdesc} == 0 ) {
                        my $fmt;
                        my $px = $p + $f->{OFFSET};
                        $fmt = "x[$px]c[" . $seglen . "]"
                            if $f->{TYPE} eq 'byte';
                        $fmt
                            = "x[$px]s["
                            . ( $seglen >> 1 ) . "]"
                            . $self->{BYTEORDER}
                            if $f->{TYPE} eq 'word';
                        $fmt
                            = "x[$px]l["
                            . ( $seglen >> 2 ) . "]"
                            . $self->{BYTEORDER}
                            if $f->{TYPE} eq 'long';
                        if ( defined($fmt) ) {
                            $a->{$aname}->{ $f->{NAME} }
                                = [ unpack( $fmt, $w ) ];
                            $len += $seglen;
                            next;
                        }
                    }

                    my $d = $self->_fetchwf( $w, $f, $p );
                    $len += $d->{LENGTH};
                    push( @{ $a->{$aname}->{ $f->{NAME} } }, $d->{VALUE} );

                }
                $p += $len;
                $seglen -= $len;
            }
        }
    }

    return $a;
}

sub _fetchwf {
    my $self   = shift;
    my $wdata  = shift;
    my $desc   = shift;
    my $offset = shift || 0;

    my $a = clone($desc);

    my $ord = $self->{BYTEORDER};       # '<'   LSB   '>'  MSB
    my $p   = $a->{OFFSET} + $offset;
    my $len = 1;

    if ( $a->{TYPE} eq 'data' ) {
        $a->{TYPE} = $self->{COMM_TYPE};
    }

    if ( $a->{TYPE} eq 'string' ) {
        $len = 16;
        $a->{VALUE} = _trimNul( substr( $wdata, $p, $len ) );
    }
    elsif ( $a->{TYPE} eq 'byte' ) {
        $len = 1;
        $a->{VALUE} = unpack( 'c', substr( $wdata, $p, $len ) );
    }
    elsif ( $a->{TYPE} eq 'word' ) {
        $len = 2;
        $a->{VALUE} = unpack( 's' . $ord, substr( $wdata, $p, $len ) );
    }
    elsif ( $a->{TYPE} eq 'long' ) {
        $len = 4;
        $a->{VALUE} = unpack( 'l' . $ord, substr( $wdata, $p, $len ) );
    }
    elsif ( $a->{TYPE} eq 'float' ) {
        $len = 4;
        $a->{VALUE}
            = _float( unpack( 'L' . $ord, substr( $wdata, $p, $len ) ) );
    }
    elsif ( $a->{TYPE} eq 'double' ) {

        #	printf("Double bytes: %02x %02x %02x %02x %02x %02x %02x %02x\n",
        #	       unpack('c*',substr($wdata,$p,8)));
        $len = 8;
        my (@long) = unpack( '(LL)' . $ord, substr( $wdata, $p, $len ) );
        @long = reverse(@long) if $ord eq '<';

        #	print "ord: $ord\n";
        #	printf("Double in: MSB 0x%08x LSB %08x\n",@long);
        $a->{VALUE} = _double(@long);
    }
    elsif ( $a->{TYPE} eq 'time_stamp' ) {
        $len = 16;
        my ( $s1, $s2, $m, $h, $d, $mo, $y, $un )
            = unpack( '(LLccccss)' . $ord, substr( $wdata, $p, $len ) );
        ( $s1, $s2 ) = reverse( $s1, $s2 ) if $ord eq '<';
        my $sec = _double( $s1, $s2 );
        my $sstr = sprintf( '%.12f', $sec );
        $sstr = '0' . $sstr if $sec < 10;
        $a->{VALUE} = sprintf(
            '%04d-%02d-%02d %02d:%02d:%s',
            $y, $mo, $d, $h, $m, $sstr
        );
    }
    elsif ( $a->{TYPE} eq 'unit_definition' ) {
        $len = 48;
        $a->{VALUE} = _trimNul( substr( $wdata, $p, $len ) );
    }
    elsif ( $a->{TYPE} eq 'enum' ) {
        $len = 2;
        my $ne = sprintf(
            '%d',
            unpack( 'S' . $ord, substr( $wdata, $p, $len ) )
        );
        $a->{VALUE} = $a->{ENUM}->{$ne};
    }
    elsif ( $a->{TYPE} eq 'text' ) {
        $len = length($wdata);
        $a->{VALUE} = _trimNul( substr( $wdata, $p ) );
    }
    else {
        carp( "unknown waveform field type: " . $a->{TYPE} );
        return undef;
    }
    $a->{LENGTH} = $len;
    return $a;
}

# IEEE754 single precision  (binary32): assumes MSB data ('>')
sub _float {
    my $str = shift;
    my $s   = ( $str >> 31 ) & 0x0001;
    my $e   = ( $str >> 23 ) & 0x00FF;
    my $f   = $str & 0x007FFFFF;
    my $w   = ( 2**( $e - 127 ) ) * ( 1 + ( $f / 0x00800000 ) );
    $w = -$w if $s;
    return $w;
}

sub double_from_hex { unpack 'd', scalar reverse pack 'H*', $_[0] }

use constant POS_INF => double_from_hex '7FF0000000000000';
use constant NEG_INF => double_from_hex 'FFF0000000000000';
use constant NaN     => double_from_hex '7FF8000000000000';

sub _double    # assumes MSB data input
{
    #    my ($bytes) = @_;
    #    my ($bottom, $top) = unpack ("LL", $bytes);
    my ( $top, $bottom ) = @_;

    # Reference:
    # http://en.wikipedia.org/wiki/Double_precision_floating-point_format

    # Eight zero bytes represents 0.0.
    if ( $bottom == 0 ) {
        if ( $top == 0 ) {
            return 0;
        }
        elsif ( $top == 0x80000000 ) {
            return -0;
        }
        elsif ( $top == 0x7ff00000 ) {
            return POS_INF;
        }
        elsif ( $top == 0xfff00000 ) {
            return NEG_INF;
        }
    }
    elsif ( $top == 0x7ff00000 ) {
        return NaN;
    }
    my $sign = $top >> 31;

    #    print "sgn $sign\n";
    my $exponent = ( ( $top >> 20 ) & 0x7FF ) - 1023;

    #    print "e  = $exponent\n";
    my $e = ( $top >> 20 ) & 0x7FF;
    my $t = $top & 0xFFFFF;

    #    printf ("--> !%011b%020b \n--> %032b\n", $e, $t, $top);
    my $mantissa = ( $bottom + ( $t * ( 2**32 ) ) ) / 2**52 + 1;

    #    print "mant: $mantissa\n";
    my $double = (-1)**$sign * 2**$exponent * $mantissa;

    #    print "double result: $double\n";
    return $double;
}

# IEEE754 double precision (binary64)
#sub _Xdouble {
#    my $str = shift;
#    my $s = ($str >> 63) & 0x1;
#    my $e = ($str >> 52) & 0x7FF;
#    my $f = $str & 0x000FFFFFFFFFFFFF  ;
#    my $w = (2**($e-1023))*(1+$f/0x0010000000000000);
#    $w = -$w if $s;
#    return $w;
#}

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

sub _ParseTemplate {
    my $self  = shift;
    my $input = shift;

    my $f;
    my (@blox) = ();
    my $inenum = 0;
    my $x;
    my $scopish;

    #    my $ln = 0;

    foreach ( split( /\n/, $input ) ) {

        #	$ln++;
        chomp;
        next if /^\s*$/;

        if ( !defined($scopish) && /^(TMPL|TEMPLATE)\s+\"/i ) {
            $scopish = 1;
            next;
        }

        if ( defined($scopish) && $scopish && /^\"/ ) {
            last;
        }

        if ( !defined($scopish) && /^(\/|0|;)/ ) {
            $scopish = 0;
        }

        s/;.*$//;
        next if /^\s*$/;
        next if /^\s*\/00/;
        next if /^\s*00/i;
        next if /^\s+\d[\d\s]+/;    # funky 8 111 333 string

        if ($inenum) {
            if (/^\s*endenum(\s|$)/i) {
                $inenum = 0;
            }
            elsif (/^\s*_(\d+)\s+(.+)(\s|$)/i) {
                $x->{ENUM}->{$1} = $2;
            }
            else {
                carp("Error parsing enum entry: $_");
            }
            next;
        }

        if (/^\s*(\w+)\s*:\s*(\w+)/i) {
            my $entry = [ "$1:$2", [] ];
            $f = $entry->[1];
            push( @blox, $entry );

        }
        elsif (/^\s*\<\s*(\d+)\s*\>\s+(\w+):\s*(\w+)/i) {
            $x = {
                OFFSET => $1,
                NAME   => $2,
                TYPE   => $3,
            };

            if ( lc( $x->{TYPE} ) eq 'enum' ) {
                $x->{ENUM} = {};
                $inenum = 1;
            }
            push( @{$f}, $x );
        }
        else {
            carp("error parsing line: $_");
        }
    }

    print Dumper( \@blox ), "\n" if $DEBUG;
    return [@blox];
}

sub _ParseHeader {
    my $self   = shift;
    my $ev     = shift;
    my $opt    = shift;
    my $stream = $self->{STREAM}->{NUMBER};

    if ( defined( $ev->{RUNHEADER} ) ) {
        foreach my $g ( @{ $ev->{RUNHEADER}->{STREAM}->{$stream}->{GPIB} } ) {
            next unless $g =~ /^\s*\<(TMPL|TEMPLATE)/i;
            $self->{TEMPLATE}
                = $self->_ParseTemplate( substr( $g, 1 ), $opt );
        }
    }

    $self->{PARSED_HEADER} = 1;
}

1;    # End of Lab::Data::Analysis::TekTDS

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Data::Analysis::WaveRunner - Analysis routine for LeCroy WaveRunner/etc. scopes

=head1 VERSION

version 3.881

=head1 SUBROUTINES/METHODS

=head2 new

my $a = Lab::Data::Analysis::WaveRunner->new(stream=>$stream);

create a new WaveRunner analysis object; for use by Lab::Data::Analysis
code

=head2 Analyze

my $event = $a->Analyze($event[, optionshash]);

Do  analysis on an event (passed by hashref); the
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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Charles Lane
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
