#!perl -T 
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 2;

BEGIN {
    # need these to make system() calls in testing while taint check on
    $ENV{PATH}     = '/usr/bin';
    $ENV{BASH_ENV} = '';

}

use_ok('Lab::SCPI') || print "Bail out!\n";

my $dpo4104
    = ':ACQUIRE:STOPAFTER RUNSTOP;STATE 1;MODE SAMPLE;NUMENV INFINITE;NUMAVG 512;SAMPLINGMODE RT;:HEADER 1;:LOCK NONE;:VERBOSE 1;:MESSAGE:SHOW "";BOX 167,67,188,99;STATE 0;:ALIAS:STATE 0;:DISPLAY:COLOR:PALETTE NORMAL;:DISPLAY:STYLE:DOTSONLY 0;:DISPLAY:PERSISTENCE 0.0E+0;CLOCK 1;FORMAT YT;GRATICULE FULL;INTENSITY:WAVEFORM 35;GRATICULE 75;BACKLIGHT HIGH;';

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

my $h = scpi_parse($dpo4104);
my $f = scpi_flat( $h, $override );

#print "not ok\n";
#print Dumper($f),"\n";

my $fok = {
    'ACQ:STATE'          => '1',
    'VERB'               => '1',
    'ACQ:NUMAV'          => '512',
    'ACQ:NUME'           => 'INFINITE',
    'DIS:CLOC'           => '1',
    'MESS:BOX'           => '167,67,188,99',
    'DIS:COL:PAL'        => 'NORMAL',
    'DIS:INTENSIT:GRA'   => '75',
    'DIS:INTENSIT:BACKL' => 'HIGH',
    'ACQ:MOD'            => 'SAMPLE',
    'LOC'                => 'NONE',
    'ALI:STATE'          => '0',
    'DIS:GRA'            => 'FULL',
    'DIS:PERS'           => '0.0E+0',
    'ACQ:STOPA'          => 'RUNSTOP',
    'ACQ:SAMP'           => 'RT',
    'MESS:SHOW'          => '""',
    'DIS:STY:DOT'        => '0',
    'MESS:STAT'          => '0',
    'DIS:INTENSIT:WAVE'  => '35',
    'DIS:FORM'           => 'YT',
    'HEAD'               => '1',
};

is_deeply( $f, $fok, "flatten test" );
