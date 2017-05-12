package GPIB::hp59306a;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require GPIB;

@ISA = qw(Exporter AutoLoader GPIB);
@EXPORT = qw( );
$VERSION = '0.30';

sub new {
    my $g = GPIB::new(@_);  
    my $i;

    for (1 .. 6) {
        $g->setRelay($_, 0);
    }
    $$g{state} = [0,0,0,0,0,0];

    return $g;
}

sub devicePresent {
    my $g = shift;

    # ibln() doesn't seem to see this device with one call, so
    # I call ibln() up to 10 times looking for a single postive
    # response.
    my $pad = $g->ibask(GPIB->IbaPAD);
    my $sad = $g->ibask(GPIB->IbaSAD);
    my $active = 0;
    for(1 .. 10) {
        if ($g->ibln($pad, $sad)) {
            $active = 1;
            last;
        }
    }

    if ($active) {
        for (1 .. 6) {
            $g->setRelay($_, 0);
        }
    }
    $$g{state} = [0,0,0,0,0,0];
    return $active;
}

sub setRelay {
    my ($g, $relay, $value) = @_;

    if ($value) {
        $g->ibwrt("A$relay");
        $$g{state}[$relay-1] = 1;
    } else {
        $g->ibwrt("B$relay");
        $$g{state}[$relay-1] = 0;
    }
}

sub getState {
    my $g = shift;

    return @{$$g{state}};
}

1;
__END__

=head1 NAME

GPIB::hp59306a - Perl-GPIB module for HP59306A relay actuator 

=head1 SYNOPSIS

    use GPIB::hp59306a;

    $g = GPIB::hp59306a->new("name");
    print "Device found on bus\n" if $g->devicePresent;
    $g->setRelay(6, 1);  # Turn relay 6 on
    $g->setRelay(5, 0);  # Turn relay 5 off
    @st = $g->getState;  # Get array of length 6 of relay state

=head1 DESCRIPTION

HP59306A device driver.  The HP59306A is a simple GPIB device with
six relays that can be turned on and off under program control.  This
device is pretty old (1978 or so) and doesn't have a 
microprocessor.  It accepts simple commands to set the relays but
has no mechanism to read back the state of the relays. The relays
are numbers 1 through 6 and that numbering scheme extends to this
module. The relays all turn off when there is no active controller 
on the GPIB bus.  This is usually case when a GPIB program terminates.

The device driver keeps track of the state of the relays internally.
This works fine, but it is an open loop technique since you cannot
read the state of the relays back from the unit.  Don't use the
$g->getState method to launch Cruise missles and such.

new() and devicePresent() both turn all of the relays off.
It seems that the device has a little deficiancy where it needs
to ignore a few commands form the host before it starts working 
correctly.  Both of these methods send a few commands to turn all of 
the relays off, this insures that that the first command to active a relay 
will succeed.

I bought one of these boxes for $50 on ebay to control my 
Christmas lights.

hp59306a is a subclass of GPIB.

=head1 AUTHOR

Jeff Mock, jeff@mock.com

=head1 SEE ALSO

GPIB(3), perl(1).

=cut

