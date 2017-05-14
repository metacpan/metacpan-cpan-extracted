package GPIB::hpe3631a;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require GPIB;

@ISA = qw(Exporter AutoLoader GPIB);
@EXPORT = qw();

@EXPORT_OK = qw(
    P6V P25V N25V
);

$VERSION = '0.30';

sub P6V { "P6V" }
sub P25V { "P25V" }
sub N25V { "N25V" }

sub set {
    my ($g, $output, $voltage, $current) = @_;
    $g->ibwrt("APPL $output, $voltage, $current");
}

sub get {
    my ($g, $output) = @_;
    my $response;

    $response = $g->query("APPLY? $output");
    return () if ($g->ibsta & GPIB->ERR);

    # Extract 0.000,0.000 numbers from response
    $response =~ /(-*\d+\.\d+),(-*\d+\.\d+)/;
    return ($1,$2);
}

sub measure {
    my ($g, $output) = @_;
    my $vresp;
    my $cresp;

    $vresp = $g->query("MEASURE:VOLT? $output");
    return () if ($g->ibsta & GPIB->ERR);
    $cresp = $g->query("MEASURE:CURR? $output");
    return () if ($g->ibsta & GPIB->ERR);

    $vresp =~ s/[\r\n]//g;
    $cresp =~ s/[\r\n]//g;

    return ($vresp,$cresp);
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

sub output {
    my $g = shift;

    if (@_ > 0) {
        my $state = shift;
        if ($state) {
            return $g->ibwrt("OUTPUT ON");
        } else {
            return $g->ibwrt("OUTPUT OFF");
        }
    } else {
        return 0 + $g->query("OUTPUT?");
    }
}
    
sub track {
    my $g = shift;

    if (@_ > 0) {
        my $state = shift;
        if ($state) {
            return $g->ibwrt("OUTPUT:TRACK ON");
        } else {
            return $g->ibwrt("OUTPUT:TRACK OFF");
        }
    } else {
        return 0 + $g->query("OUTPUT:TRACK?");
    }
}
    
1;
__END__

=head1 NAME

GPIB::hpe3631a - Perl-GPIB module HPE3631A power supply

=head1 SYNOPSIS

  use GPIB::hpe3631a;

  $g->GPIB::hpe3631a->new("name");
  $g->output(1);       # Outputs on
  $g->output(0);       # Outputs off
  $v = $g->output;     # Read output state 

  $g->track(1);        # P25V and N25V track voltage 
  $g->track(0);        # stop tracking
  $v = $g->track;      # Get tracking state

  $t = $g->display;
  $g->display("String");

  ($voltage, $current) = $g->measure(P6V)  # P6V, P25V, or N25V
  ($voltage, $current) = $g->get(P6V)      # P6V, P25V, or N25V
  $g->set(P6V, $voltage, $current)         # P6V, P25V, or N25V

=head1 DESCRIPTION

GPIB::hpe3631a privides control for the HPE3631E bench power supply.
This module works with both GPIB and serial interface modules
as defined by the /etc/pgpib.conf configuration.

$g->display with no parameter returns the contents of the display.
$g->display("string") sets the display to the specified string.  
Note the the device can only display a limited set of characters,
probably best to stick with upper case captions.

$g->measure(P6V) returns a two element list representing the 
voltage and current at the specified output.

$g->get(P6V) returns a two element list of the voltage and current
limits for te specified output.

$g->set(P6V, $v, $c) sets the current limits for the specified output.

=head1 CONFIGURATION

A typical /etc/pgpib.conf configuration for a GPIB interface  
is shown below. The HPE3631A uses primary address 5 by default:

  # name    interface   Board   PAD   SAD  TMO   EOT   EOS
  HPE3631A  GPIB::ni    0       5     0    T1s   1     0

A typical /etc/pgpib.conf configuration for a serial interface 
is shown below.  The HPE3631A uses 9600 baud by default.  The flag
value of 0x0001 says to use RTS/CTS hardware flow control.   This
is pretty much required.  The device seems to overflow easily unless
hardware flow control is used.  Note that the HPE3631A uses 
DTR/DSR flow control and Linux only supports RTS/CTS flow control
so you are pretty much stuck building a custom serial cable.

  # name    interface      port        speed   TMO     EOS     FLAG
  HPE3631AS GPIB::hpserial /dev/ttyS1  9600    T3s     0x0a    0x0001

=head1 AUTHOR

Jeff Mock, jeff@mock.com

=head1 SEE ALSO

perl(1), GPIB(3).

=cut


