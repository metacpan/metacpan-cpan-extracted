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
    = scpi_parse(
    ':WFMPRE:BYT_NR 1;BIT_NR 8;ENCDG ASCII;BN_FMT RI;BYT_OR MSB;WFID "Ch1, DC coupling, 100.0mV/div, 10.00us/div, 10000 points, Sample mode";NR_PT 10000;PT_FMT Y;XUNIT "s";XINCR 10.0000E-9;XZERO -49.7400E-6;PT_OFF 0;YUNIT "V";YMULT 4.0000E-3;YOFF -500.0000E-3;YZERO 0.0E+0;VSCALE 100.0000E-3;HSCALE 10.0000E-6;VPOS -20.0000E-3;VOFFSET 0.0E+0;HDELAY 260.0000E-9;:SET *RST;:ACQUIRE:STOPAFTER RUNSTOP;STATE 1;MODE SAMPLE;NUMENV INFINITE;NUMAVG 512;SAMPLINGMODE RT;:HEADER 1;:LOCK NONE;:VERBOSE 1;:MESSAGE:SHOW "";BOX 167,67,188,99;STATE 0;:ALIAS:STATE 0;:DISPLAY:COLOR:PALETTE NORMAL;:DISPLAY:STYLE:DOTSONLY 0;:DISPLAY:PERSISTENCE 0.0E+0;CLOCK 1;FORMAT YT;GRATICULE FULL;INTENSITY:WAVEFORM 35;GRATICULE 75;BACKLIGHT HIGH;:HARDCOPY:INKSAVER 1;LAYOUT PORTRAIT;PREVIEW 0;:SAVE:IMAGE:LAYOUT LANDSCAPE;FILEFORMAT PNG;:SAVE:WAVEFORM:FILEFORMAT SPREADSHEET;GATING NONE;:SAVE:ASSIGN:TYPE IMAGE;'
    );

my $href = {
    'SET'     => { '_VALUE' => '*RST' },
    'VERBOSE' => { '_VALUE' => '1' },
    'LOCK'    => { '_VALUE' => 'NONE' },
    'SAVE'    => {
        'ASSIGN'   => { 'TYPE' => { '_VALUE' => 'IMAGE' } },
        'WAVEFORM' => {
            'FILEFORMAT' => { '_VALUE' => 'SPREADSHEET' },
            'GATING'     => { '_VALUE' => 'NONE' }
        },
        'IMAGE' => {
            'LAYOUT'     => { '_VALUE' => 'LANDSCAPE' },
            'FILEFORMAT' => { '_VALUE' => 'PNG' }
        }
    },
    'MESSAGE' => {
        'SHOW'  => { '_VALUE' => '""' },
        'BOX'   => { '_VALUE' => '167,67,188,99' },
        'STATE' => { '_VALUE' => '0' }
    },
    'HEADER' => { '_VALUE' => '1' },
    'WFMPRE' => {
        'PT_OFF'  => { '_VALUE' => '0' },
        'YUNIT'   => { '_VALUE' => '"V"' },
        'VOFFSET' => { '_VALUE' => '0.0E+0' },
        'HDELAY'  => { '_VALUE' => '260.0000E-9' },
        'BN_FMT'  => { '_VALUE' => 'RI' },
        'XZERO'   => { '_VALUE' => '-49.7400E-6' },
        'ENCDG'   => { '_VALUE' => 'ASCII' },
        'XINCR'   => { '_VALUE' => '10.0000E-9' },
        'WFID'    => {
            '_VALUE' =>
                '"Ch1, DC coupling, 100.0mV/div, 10.00us/div, 10000 points, Sample mode"'
        },
        'XUNIT'  => { '_VALUE' => '"s"' },
        'BYT_OR' => { '_VALUE' => 'MSB' },
        'YZERO'  => { '_VALUE' => '0.0E+0' },
        'YMULT'  => { '_VALUE' => '4.0000E-3' },
        'BIT_NR' => { '_VALUE' => '8' },
        'HSCALE' => { '_VALUE' => '10.0000E-6' },
        'YOFF'   => { '_VALUE' => '-500.0000E-3' },
        'VSCALE' => { '_VALUE' => '100.0000E-3' },
        'NR_PT'  => { '_VALUE' => '10000' },
        'BYT_NR' => { '_VALUE' => '1' },
        'PT_FMT' => { '_VALUE' => 'Y' },
        'VPOS'   => { '_VALUE' => '-20.0000E-3' }
    },
    'HARDCOPY' => {
        'PREVIEW'  => { '_VALUE' => '0' },
        'LAYOUT'   => { '_VALUE' => 'PORTRAIT' },
        'INKSAVER' => { '_VALUE' => '1' }
    },
    'ALIAS'   => { 'STATE' => { '_VALUE' => '0' } },
    'DISPLAY' => {
        'COLOR'     => { 'PALETTE' => { '_VALUE' => 'NORMAL' } },
        'INTENSITY' => {
            'WAVEFORM'  => { '_VALUE' => '35' },
            'BACKLIGHT' => { '_VALUE' => 'HIGH' },
            'GRATICULE' => { '_VALUE' => '75' }
        },
        'STYLE'       => { 'DOTSONLY' => { '_VALUE' => '0' } },
        'GRATICULE'   => { '_VALUE'   => 'FULL' },
        'FORMAT'      => { '_VALUE'   => 'YT' },
        'PERSISTENCE' => { '_VALUE'   => '0.0E+0' },
        'CLOCK'       => { '_VALUE'   => '1' }
    },
    'ACQUIRE' => {
        'NUMENV'       => { '_VALUE' => 'INFINITE' },
        'STATE'        => { '_VALUE' => '1' },
        'STOPAFTER'    => { '_VALUE' => 'RUNSTOP' },
        'MODE'         => { '_VALUE' => 'SAMPLE' },
        'SAMPLINGMODE' => { '_VALUE' => 'RT' },
        'NUMAVG'       => { '_VALUE' => '512' }
    }
};

is_deeply( $h, $href, 'parse dpo4104' );

# try some special cases

$h    = scpi_parse(":FOO:BAR? a , zab, 22;BLEM #12ab ; *zip? 1.00 E -08 V; ");
$href = {
    FOO => {
        'BAR?' => {
            _VALUE => 'a,zab,22',
        },
        'BLEM' => { _VALUE => '#12ab' },
    },
    '*zip?' => { _VALUE => '1.00 E -08 V' }
};

is_deeply( $h, $href, 'parse odd cases' );

my $sp = '';
foreach my $c ( 0 .. 9, 11 .. 32 ) {
    $sp .= chr($c);
}

$h = scpi_parse(":FOO${sp}abcd${sp};");

$href = { FOO => { _VALUE => 'abcd' } };

is_deeply( $h, $href, 'full ieee488 whitespace range' );

