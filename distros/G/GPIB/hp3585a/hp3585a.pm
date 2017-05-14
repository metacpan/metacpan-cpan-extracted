package GPIB::hp3585a;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use GPIB;

require Exporter;

@ISA = qw(Exporter AutoLoader GPIB);
@EXPORT = qw( );
$VERSION = '0.30';

sub getCaption {
    my $g = shift;
    my $cap;
    my @r = ();

    $g->ibwrt("D7T4");
    return @r if ($g->ibsta & GPIB->ERR);

    $cap = $g->ibrd(173);
    return @r if ($g->ibsta & GPIB->ERR);

    # Clean up text for the modern world where we have
    # both upper and lower case
    $cap =~ s/\r//g;                    # get rid of CR
    @r = split /\n/, $cap;              # Break up into lines based on LF
    for (@r) {
        s/^ *//;     s/ *$//;           # Get rid of leading/training space
        s/KHZ/kHz/g; s/HZ/Hz/g;         # Make units look nice
        s/DBM/dBm/g; s/DB/dB/g;
        s/(\d) (\d)/$1$2/g;             # Get rid of commas in numbers
    }
    return @r;
}

sub getDisplay {
    my  $g = shift;
    my  $cap;
    my  @vals;

    $g->ibwrt("SATB0");         # Transfer A display to B
    return () if $g->ibsta & GPIB->ERR; 

    $g->ibwrt("BO");            # Send B display to host
    return () if $g->ibsta & GPIB->ERR; 

    $cap = $g->ibrd(2004);      # Must read exactly 2004 bytes
    return () if $g->ibsta & GPIB->ERR; 

    @vals = unpack 'n*', $cap;
    return @vals;
}

1;  # so that "use" statment succeeds in user program
__END__

=head1 NAME

GPIB::hp3585a - Perl-GPIB module for HP3585A Spectrum Analyser

=head1 SYNOPSIS

    use GPIB::hp3585a;

    $g = GPIB:hp3585a->new("name");
    @caption = $g->getCaption;
    @display = $g->getDisplay;

=head1 DESCRIPTION

Driver for HP8535A spectrum analyser.   getCaption() returns an array
of 8 strings containing the current text on the display of the 
instrument.   getDisplay() returns an array of 1002 values representing
the display points of the A trace of the instrument. The first
point is invalid (this is the way the instrument returns the data).
The values are in the range 0..1023.  The higher order bits contain
some extra information like whether there is a marker at the location.
See the HP3585A manual for more detailed information.  In general,
mask off everything but the lower 10-bits of each element to get a 
nice plot.

There's a lot more work to do on this module...

=head1 CONFIGURATION

A typical /etc/pgpib.conf entry is shown below.  The HP3585A 
defaults to primary address 11 unless you get out a screw
driver and open up the big beast.  Also note that a 1 second
timeout may not be enough for this device.  It seems to stall
any GPIB access while doing a configuration cycle.

This device does not assert EOI or send an EOS character at the
end of transmissions.  This means that you must know the 
exact number of bytes to read.  This is the reason the 
caption code reads precisely 174 bytes.  It's a pain, but 
reasonable seeing as this instrument was designed in the 70's.

    # name                  Board   PAD   SAD   TMO   EOT   EOS
    HP3585A     GPIB::ni    0       11    0     T1s   1     0

=head1 AUTHOR

Jeff Mock jeff@mock.com

=head1 SEE ALSO

GPIB(3), perl(1).

=cut
