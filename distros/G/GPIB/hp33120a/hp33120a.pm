package GPIB::hp33120a;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require GPIB;

@ISA = qw(Exporter AutoLoader GPIB);
@EXPORT = qw();

@EXPORT_OK = qw(SIN SQUARE TRIANGLE RAMP NOISE DC USER);

$VERSION = '0.30';

sub SIN         { "SIN" }
sub SQUARE      { "SQU" }
sub TRIANGLE    { "TRIANGLE" }
sub RAMP        { "RAMP" }
sub NOISE       { "NOISE" }
sub DC          { "DC" }
sub USER        { "USER" }

sub set {
    my $g = shift;
    my $shape = shift;
    my ($freq, $amplitude, $offset);
    my $cmd;

    $freq = shift if @_;
    $amplitude = shift if @_;
    $offset = shift if @_;

    
    $cmd = "APPLY:$shape";
    $cmd .= " " . $freq if defined($freq);
    $cmd .= ", " . $amplitude if defined($amplitude);
    $cmd .= ", " . $offset if defined($offset);

    # Set instrument to sensible state
    return if $g->ibwrt($cmd) & GPIB->ERR;
    return if $g->ibwrt("SOURCE:AM:STATE OFF") & GPIB->ERR;
    return if $g->ibwrt("SOURCE:FM:STATE OFF") & GPIB->ERR;
    return if $g->ibwrt("SOURCE:BM:STATE OFF") & GPIB->ERR;
    return if $g->ibwrt("SOURCE:FSKEY:STATE OFF") & GPIB->ERR;
    return if $g->ibwrt("SOURCE:SWEEP:STATE OFF") & GPIB->ERR;
    return if $g->ibwrt("TRIG:SOURCE IMM") & GPIB->ERR;
}

    
# Returns 4 element list with basic operating parameters
# ($waveshape, $freq, $amplitude, $offset)
sub get {
    my $g = shift;                          # Get object reference
    $_ = $g->query("APPLY?");               # Fetch string from device
    return () if $g->ibsta & GPIB->ERR;     # bag on error
    s/[\r\n]//g;                   # Get rid of any CR/LF
    s/"//g;                        # Get rid of "'s
    s/,/ /g;                       # Change commas to spaces
    split;                         # Split into array delimited by spaces
    return @_;                     # return array
}
    
sub display {
    my $g = shift;
    my $title;

    if (@_ > 0) {
        $title = shift;
        $g->ibwrt("DISP ON");
        return $g->ibwrt("DISP:TEXT \"$title\"");
    } else {
        $title = $g->query("DISP:TEXT?");
        $title =~ s/[\r\n]//g;
        $title =~ s/"//g;
        return $title;
    }
}
        
sub shape {
    my $g = shift;
    my $shape;

    if (@_ > 0) {
        $shape = shift;
        return $g->ibwrt("FUNC:SHAPE $shape");
    } else {
        $shape = $g->query("FUNC:SHAPE?");
        $shape =~ s/[\n\r]//g;
        return $shape;
    }
}

sub freq {
    my $g = shift;
    my $freq;

    if (@_ > 0) {
        $freq = shift;
        return $g->ibwrt("FREQ $freq");
    } else {
        $freq = $g->query("FREQ?");
        $freq =~ s/[\n\r]//g;
        return $freq;
    }
}

sub amplitude {
    my $g = shift;
    my $amp;

    if (@_ > 0) {
        $amp = shift;
        return $g->ibwrt("VOLT $amp");
    } else {
        $amp = $g->query("VOLT?");
        $amp =~ s/[\n\r]//g;
        return $amp;
    }
}

sub offset {
    my $g = shift;
    my $off;

    if (@_ > 0) {
        $off = shift;
        return $g->ibwrt("VOLT:OFFS $off");
    } else {
        $off = $g->query("VOLT:OFFS?");
        $off =~ s/[\n\r]//g;
        return $off;
    }
}

sub arb {
    my $g = shift;
    my $a = shift;

    my $pk;

    $pk = pack 'n*', @$a;
    $g->ibwrt("FORM:BORD NORM");
    $pk = "DATA:DAC VOLATILE, #5" . sprintf("%05d", length($pk)) . $pk;
    $g->ibwrt($pk);
}

sub am {
    my ($g, $depth, $func, $freq) = @_;

    return if $g->ibwrt("AM:DEPTH $depth") & GPIB->ERR;
    return if $g->ibwrt("AM:INT:FUNC $func") & GPIB->ERR;
    return if $g->ibwrt("AM:INT:FREQ $freq") & GPIB->ERR;
    return if $g->ibwrt("AM:STATE ON") & GPIB->ERR;
}
    
sub fm {
    my ($g, $deviation, $func, $freq) = @_;

    return if $g->ibwrt("FM:DEV $deviation") & GPIB->ERR;
    return if $g->ibwrt("FM:INT:FUNC $func") & GPIB->ERR;
    return if $g->ibwrt("FM:INT:FREQ $freq") & GPIB->ERR;
    return if $g->ibwrt("FM:STATE ON") & GPIB->ERR;
}
    
sub bm {
    my ($g, $cycles, $phase, $freq) = @_;

    return if $g->ibwrt("BM:NCYC $cycles") & GPIB->ERR;
    return if $g->ibwrt("BM:PHASE $phase") & GPIB->ERR;
    return if $g->ibwrt("BM:INT:RATE $freq") & GPIB->ERR;
    return if $g->ibwrt("BM:STATE ON") & GPIB->ERR;
}
    
sub fsk {
    my ($g, $freq2, $rate) = @_;

    return if $g->ibwrt("FSK:FREQ $freq2") & GPIB->ERR;
    return if $g->ibwrt("FSK:INT:RATE $rate") & GPIB->ERR;
    return if $g->ibwrt("FSK:STATE ON") & GPIB->ERR;
}
    
sub sweep {
    my ($g, $stype, $f1, $f2, $time) = @_;

    return if $g->ibwrt("SWE:SPAC $stype") & GPIB->ERR;
    return if $g->ibwrt("FREQ:START $f1") & GPIB->ERR;
    return if $g->ibwrt("FREQ:STOP $f2") & GPIB->ERR;
    return if $g->ibwrt("SWE:TIME $time") & GPIB->ERR;
    return if $g->ibwrt("SWE:STAT ON") & GPIB->ERR;
}

1;
__END__

=head1 NAME

GPIB::hp33120a - Perl-GPIB module for HP33120A 15MHz function generator

=head1 SYNOPSIS

    use GPIB::hp33120a qw(SIN SQUARE TRIANGLE RAMP NOISE DC USER);

    $g = GPIB::hp33120a->new("Name");

    $g->set($shape, $freq, $amplitude, $offset);
    ($shape, $freq, $amp, $offs) = $g->get;

    $g->shape($shape);      # Set individual parameters
    $g->freq(1000000.0);
    $g->amplitude(1.0);
    $g->offset(0.1);

    $shape = $g->shape;     # Get individial parameters
    $freq = $g->freq;
    $amp = $g->amplitude;
    $off = $g->offset;

    @a = (1..1000);
    $g->arb(\@a);           # Set Arb data

    $g->display("TEST");    # Set display
    $text = $g->display;

    $g->am($depth, $shape, $freq)        # AM
    $g->fm($deviation, $shape, $freq)    # FM
    $g->bm($cycles, $phase, $freq)       # Burst modulation
    $g->fsk($freq2, $rate)               # frequency shift keying
    $g->sweep("LIN", $f1, $f2, $time)    # "LIN" or "LOG" sweep

=head1 DESCRIPTION

GPIB::hp33120a is a module for controlling an HP33120A 15MHz arbitrary
function generator.  This module is a sub-class of the GPIB module
so all of the GPIB methods are also available through the reference.

Basic parameters can be set at once with $g->set() passing a list
with waveform, frequency, amplitude, and offset.  Basic parameters
get also be set and retrieved individually as shown above.

The arbitrary function waveform is set with a call to $g->arb passing
a reference to an array of numbers in the range -2047..2047.  The
length of the waveform is the length of the array.  See the HP33120A
manual for special considerations in calculating an arbitrary waveform.
Also see test.pl for an example generating an arbitray waveform.

$g->display($text) sets the display.  The display is fairly limited 
so it's proably a good idea to stick to upper case characters.

$g->am(), $g->fm, $g->bm, $g->fsk, and $g->sweep set various fancy 
modulation and sweep modes described in the HP33120A manual.

This module has been tested with the GPIB::ni, GPIB::hpserial, and
GPIB::rmt modules on Linux and NT4.0.

=head1 AUTHOR

Jeff Mock, jeff@mock.com

=head1 SEE ALSO

GPIB(3), perl(1).

=cut
