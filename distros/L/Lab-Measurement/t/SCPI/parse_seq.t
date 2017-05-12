#!perl -T 
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 4;

BEGIN {
    # need these to make system() calls in testing while taint check on
    $ENV{PATH}     = '/usr/bin';
    $ENV{BASH_ENV} = '';
}

use_ok('Lab::SCPI') || print "Bail out!\n";

my $h
    = scpi_parse_sequence(
    ':WFMPRE:BYT_NR 1;BIT_NR 8;ENCDG ASCII;BN_FMT RI;BYT_OR MSB;WFID "Ch1, DC coupling, 100.0mV/div, 10.00us/div, 10000 points, Sample mode";NR_PT 10000;PT_FMT Y;XUNIT "s";XINCR 10.0000E-9;XZERO -49.7400E-6;PT_OFF 0;YUNIT "V";YMULT 4.0000E-3;YOFF -500.0000E-3;YZERO 0.0E+0;VSCALE 100.0000E-3;HSCALE 10.0000E-6;VPOS -20.0000E-3;VOFFSET 0.0E+0;HDELAY 260.0000E-9;:SET *RST;:ACQUIRE:STOPAFTER RUNSTOP;STATE 1;MODE SAMPLE;NUMENV INFINITE;NUMAVG 512;SAMPLINGMODE RT;:HEADER 1;:LOCK NONE;:VERBOSE 1;:MESSAGE:SHOW "";BOX 167,67,188,99;STATE 0;:ALIAS:STATE 0;:DISPLAY:COLOR:PALETTE NORMAL;:DISPLAY:STYLE:DOTSONLY 0;:DISPLAY:PERSISTENCE 0.0E+0;CLOCK 1;FORMAT YT;GRATICULE FULL;INTENSITY:WAVEFORM 35;GRATICULE 75;BACKLIGHT HIGH;:HARDCOPY:INKSAVER 1;LAYOUT PORTRAIT;PREVIEW 0;:SAVE:IMAGE:LAYOUT LANDSCAPE;FILEFORMAT PNG;:SAVE:WAVEFORM:FILEFORMAT SPREADSHEET;GATING NONE;:SAVE:ASSIGN:TYPE IMAGE;'
    );

my $href = [
    { 'WFMPRE' => { 'BYT_NR' => { '_VALUE' => '1' } } },
    { 'WFMPRE' => { 'BIT_NR' => { '_VALUE' => '8' } } },
    { 'WFMPRE' => { 'ENCDG'  => { '_VALUE' => 'ASCII' } } },
    { 'WFMPRE' => { 'BN_FMT' => { '_VALUE' => 'RI' } } },
    { 'WFMPRE' => { 'BYT_OR' => { '_VALUE' => 'MSB' } } },
    {
        'WFMPRE' => {
            'WFID' => {
                '_VALUE' =>
                    '"Ch1, DC coupling, 100.0mV/div, 10.00us/div, 10000 points, Sample mode"'
            }
        }
    },
    { 'WFMPRE'  => { 'NR_PT'        => { '_VALUE' => '10000' } } },
    { 'WFMPRE'  => { 'PT_FMT'       => { '_VALUE' => 'Y' } } },
    { 'WFMPRE'  => { 'XUNIT'        => { '_VALUE' => '"s"' } } },
    { 'WFMPRE'  => { 'XINCR'        => { '_VALUE' => '10.0000E-9' } } },
    { 'WFMPRE'  => { 'XZERO'        => { '_VALUE' => '-49.7400E-6' } } },
    { 'WFMPRE'  => { 'PT_OFF'       => { '_VALUE' => '0' } } },
    { 'WFMPRE'  => { 'YUNIT'        => { '_VALUE' => '"V"' } } },
    { 'WFMPRE'  => { 'YMULT'        => { '_VALUE' => '4.0000E-3' } } },
    { 'WFMPRE'  => { 'YOFF'         => { '_VALUE' => '-500.0000E-3' } } },
    { 'WFMPRE'  => { 'YZERO'        => { '_VALUE' => '0.0E+0' } } },
    { 'WFMPRE'  => { 'VSCALE'       => { '_VALUE' => '100.0000E-3' } } },
    { 'WFMPRE'  => { 'HSCALE'       => { '_VALUE' => '10.0000E-6' } } },
    { 'WFMPRE'  => { 'VPOS'         => { '_VALUE' => '-20.0000E-3' } } },
    { 'WFMPRE'  => { 'VOFFSET'      => { '_VALUE' => '0.0E+0' } } },
    { 'WFMPRE'  => { 'HDELAY'       => { '_VALUE' => '260.0000E-9' } } },
    { 'SET'     => { '_VALUE'       => '*RST' } },
    { 'ACQUIRE' => { 'STOPAFTER'    => { '_VALUE' => 'RUNSTOP' } } },
    { 'ACQUIRE' => { 'STATE'        => { '_VALUE' => '1' } } },
    { 'ACQUIRE' => { 'MODE'         => { '_VALUE' => 'SAMPLE' } } },
    { 'ACQUIRE' => { 'NUMENV'       => { '_VALUE' => 'INFINITE' } } },
    { 'ACQUIRE' => { 'NUMAVG'       => { '_VALUE' => '512' } } },
    { 'ACQUIRE' => { 'SAMPLINGMODE' => { '_VALUE' => 'RT' } } },
    { 'HEADER'  => { '_VALUE'       => '1' } },
    { 'LOCK'    => { '_VALUE'       => 'NONE' } },
    { 'VERBOSE' => { '_VALUE'       => '1' } },
    { 'MESSAGE' => { 'SHOW'         => { '_VALUE' => '""' } } },
    { 'MESSAGE' => { 'BOX'          => { '_VALUE' => '167,67,188,99' } } },
    { 'MESSAGE' => { 'STATE'        => { '_VALUE' => '0' } } },
    { 'ALIAS'   => { 'STATE'        => { '_VALUE' => '0' } } },
    { 'DISPLAY' => { 'COLOR' => { 'PALETTE' => { '_VALUE' => 'NORMAL' } } } },
    { 'DISPLAY' => { 'STYLE' => { 'DOTSONLY' => { '_VALUE' => '0' } } } },
    { 'DISPLAY' => { 'PERSISTENCE' => { '_VALUE' => '0.0E+0' } } },
    { 'DISPLAY' => { 'CLOCK'       => { '_VALUE' => '1' } } },
    { 'DISPLAY' => { 'FORMAT'      => { '_VALUE' => 'YT' } } },
    { 'DISPLAY' => { 'GRATICULE'   => { '_VALUE' => 'FULL' } } },
    {
        'DISPLAY' => { 'INTENSITY' => { 'WAVEFORM' => { '_VALUE' => '35' } } }
    },
    {
        'DISPLAY' =>
            { 'INTENSITY' => { 'GRATICULE' => { '_VALUE' => '75' } } }
    },
    {
        'DISPLAY' =>
            { 'INTENSITY' => { 'BACKLIGHT' => { '_VALUE' => 'HIGH' } } }
    },
    { 'HARDCOPY' => { 'INKSAVER' => { '_VALUE' => '1' } } },
    { 'HARDCOPY' => { 'LAYOUT'   => { '_VALUE' => 'PORTRAIT' } } },
    { 'HARDCOPY' => { 'PREVIEW'  => { '_VALUE' => '0' } } },
    { 'SAVE' => { 'IMAGE' => { 'LAYOUT' => { '_VALUE' => 'LANDSCAPE' } } } },
    { 'SAVE' => { 'IMAGE' => { 'FILEFORMAT' => { '_VALUE' => 'PNG' } } } },
    {
        'SAVE' => {
            'WAVEFORM' => { 'FILEFORMAT' => { '_VALUE' => 'SPREADSHEET' } }
        }
    },
    { 'SAVE' => { 'WAVEFORM' => { 'GATING' => { '_VALUE' => 'NONE' } } } },
    { 'SAVE' => { 'ASSIGN'   => { 'TYPE'   => { '_VALUE' => 'IMAGE' } } } }
];

is_deeply( $h, $href, 'parse_sequential dpo4104' );

my $dpo4104
    = ':ACQUIRE:STOPAFTER RUNSTOP;STATE 1;MODE SAMPLE;NUMENV INFINITE;NUMAVG 512;SAMPLINGMODE RT;:HEADER 1;:LOCK NONE;:VERBOSE 1;:MESSAGE:SHOW "";BOX 167,67,188,99;STATE 0;:ALIAS:STATE 0;:DISPLAY:COLOR:PALETTE NORMAL;:DISPLAY:STYLE:DOTSONLY 0;:DISPLAY:PERSISTENCE 0.0E+0;CLOCK 1;FORMAT YT;GRATICULE FULL;INTENSITY:WAVEFORM 35;GRATICULE 75;BACKLIGHT HIGH;';

$h = scpi_parse_sequence($dpo4104);

my $override = {    # only selected parts of the DPO4104B overrides
    ACQuire => {
        MAGnivu   => undef,
        MODe      => undef,
        NUMACq    => undef,
        NUMAVg    => undef,
        NUMEnv    => undef,
        STATE     => undef,
        STOPAfter => undef,
    },

    ALIas => {
        DELEte => undef,
        STATE  => undef,
    },

    DISplay => {
        DIGital => {
            HEIght => undef,
        },
        GRAticule => undef,
        INTENSITy => {
            BACKLight => undef,
            GRAticule => undef,
            WAVEform  => undef,
        },
        STYle => {
            DOTsonly => undef,
        },
        TRIGFrequency => undef,
    },

    LOCk => undef,
};

my $fseq = [];

foreach my $hx ( @{$h} ) {
    my $f = scpi_flat( $hx, $override );
    push( @{$fseq}, $f );
}

my $fref = [
    { 'ACQ:STOPA'          => 'RUNSTOP', },
    { 'ACQ:STATE'          => '1', },
    { 'ACQ:MOD'            => 'SAMPLE', },
    { 'ACQ:NUME'           => 'INFINITE', },
    { 'ACQ:NUMAV'          => '512', },
    { 'ACQ:SAMP'           => 'RT', },
    { 'HEAD'               => '1', },
    { 'LOC'                => 'NONE', },
    { 'VERB'               => '1', },
    { 'MESS:SHOW'          => '""', },
    { 'MESS:BOX'           => '167,67,188,99', },
    { 'MESS:STAT'          => '0', },
    { 'ALI:STATE'          => '0', },
    { 'DIS:COL:PAL'        => 'NORMAL', },
    { 'DIS:STY:DOT'        => '0', },
    { 'DIS:PERS'           => '0.0E+0', },
    { 'DIS:CLOC'           => '1', },
    { 'DIS:FORM'           => 'YT', },
    { 'DIS:GRA'            => 'FULL', },
    { 'DIS:INTENSIT:WAVE'  => '35', },
    { 'DIS:INTENSIT:GRA'   => '75', },
    { 'DIS:INTENSIT:BACKL' => 'HIGH', },
];

is_deeply( $fseq, $fref, "flatten test sequential parse" );

$h = scpi_parse_sequence('*IDN?;:CH1:STATE ON;AMP 1.0V;LIMIT?;:CH2:VOLTS?');
$href = [
    { '*IDN?' => undef },
    {
        'CH1' => {
            'STATE' => {
                '_VALUE' => 'ON',
            },
        }
    },
    {
        'CH1' => {
            'AMP' => { _VALUE => '1.0V' },
        },
    },
    {
        'CH1' => {
            'LIMIT?' => undef,
        },
    },
    {
        'CH2' => {
            'VOLTS?' => undef,
        },
    },
];

is_deeply( $h, $href, 'test queries' );

#print Dumper($h);
