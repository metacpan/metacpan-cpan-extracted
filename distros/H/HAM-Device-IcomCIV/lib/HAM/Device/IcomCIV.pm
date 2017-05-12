#####################################################################
# HAM::Device::IcomCIV -- OO Module for Icom CI-V radios
#
# Copyright (c) 2007 Ekkehard (Ekki) Plicht. All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#####################################################################

=pod

=head1 NAME

HAM::Device::IcomCIV - Class for basic remote control of Icom CI-V Radios

=head1 MODULE VERSION

Version 0.02 02. Dec. 2007

=head1 SYNOPSIS

  use HAM::Device::IcomCIV;

  # initiate first radio
  my $rig1 = HAM::Device::IcomCIV->new( undef, '/dev/ttyS1', 1, 19200, 'IC-R8500', 0x4A, 0xE0, 1 );

  my ($lower, $upper) = $rig1->get_bandedges;

  my $freq = $rig1->frequency;
  $rig1->frequency(6075000);

  my $mode = $rig1->mode;
  my ($mode, filter) = $rig1->mode;
  $rig1->mode('AM');
  $rig1->mode('AM', 'NARROW');

  ...
  # initiate second radio on same bus (same serial port)
  $my $serio = $rig1->get_serioobject;

  $my $rig2 = HAM::Device::IcomCIV->new( $serio, undef, undef, undef, 'IC-R75', undef, 0xE0, 1 );

=head1 SUPPORTED CI-V FUNCTIONS

 * Read/Set Frequency
 * Read/Set Mode
 * Read Band Edges
 * Switch to VFO (last selected or A or B or Main or Sub)
 * Switch to Memory
 * Select Memory channel
 * Clear Memory channel
 * Transfer Memory to VFO
 * Write VFO contents to selected memory

If you are looking for support of more elaborate CI-V functions see descendants of HAM::Device::IcomCIV, like HAM::Device::IcomICR8500, HAM::Device::IcomICR75 etc. These classes implement functions specific to the radio. If these classes do not implement what you want, derive your own class from HAM::Device::IcomCIV.

=head1 DESCRIPTION

This module is an OO approach to use Icom radios attached to a serial port.

HAM::Device::IcomCIV is not an abstract class, but one you can use directly. It allows
for the most basic form of remote control of practically any Icom radio equipped
with a CI-V port, namely set & get of the displayed frequency, set & get the mode and filter, read the band edges, switch to VFO or Memory (if radio has a VFO), select a memory channel, write VFO data to memory and clear a memory.

It supports multiple radios on the same serial port, differentiated by their
CI-V adress. Note: If you have two or more identical models on the same bus, they must use different CI-V adresses.

This class can be used in a procedural manner or with an event callback mechanism (or both at the same time). When used without callbacks you just use the provided methods for setting or getting radio settings (Frequency, Mode etc.). If you use the callback mechanism you will receive a callback to your sub (set with set_callback) which tells you what happened, i.e. which data was received (see event and status constants).

=head1 EXPORT

Nothing by default.

=head2 STATUS CONSTANTS (exported on demand)

    stGOOD      all ok, command succeeded
    stFAIL      command to radio failed
    stNOIM      command not implemented in this class (not recognized)
    stWAIT      wait, status update in progress
    stINIT      occurs only after new() and if no command has been issued yet

=head2 EVENT CONSTANTS (exported on demand)

    evSTAT      Status GOOD/NOGOOD received
    evFREQ      A new frequency has been received
    evMODE      A new mode/filter has been received
    evUNKN      Unknown command response received
    evNOEV      Fake, no event has happened so far
    evEDGE      Band Edges have been received

=head1 USES

    HAM::Device::IcomCIVSerialIO
    Carp;

=cut

package HAM::Device::IcomCIV;

use 5.008008;
use strict;
use warnings;
use Carp;
use HAM::Device::IcomCIVSerialIO;


our $VERSION = '0.02';

############################################################
# Constants, to be exported on demand

use constant stGOOD => 1;   # 0xFB received
use constant stFAIL => 2;   # 0xFA received
use constant stWAIT => 3;   # Wait, status about to change
use constant stINIT => 4;   # After init of object, nothing happened yet

############################################################
# Events, to be exported on demand

use constant evSTAT => 1;   # status (GOOD/NOGOOD) received
use constant evFREQ => 2;   # Frequency received
use constant evMODE => 3;   # Mode/Filter received
use constant evUNKN => 4;   # Unknown command response received
use constant evNOEV => 5;   # No Event has happened, only after init
use constant evEDGE => 6;   # Band Edges received

############################################################

require Exporter;

our @ISA = qw( Exporter );

our @EXPORT = qw ( );

our %EXPORT_TAGS = (
    Constants => [ qw (
        stGOOD
        stFAIL
        stNOIM
        stWAIT
        stINIT
    )],
    Events => [ qw (
        evSTAT
        evFREQ
        evMODE
        evUNKN
        evNOEV
        evEDGE
    )]
);

our @EXPORT_OK = ( );

Exporter::export_ok_tags( 'Constants', 'Events');

$EXPORT_TAGS{ALL} = \@EXPORT_OK;

############################################################
############################################################

=pod

=head1 METHODS

=head2 new( SerialIOobject, SerialDevice, Baudrate, UseLock, RadioModel, RadioAdr, OwnAdr, DebugLevel )

Creates a new IcomCIV object. Returns the object reference.

=over 4

=item SerialIOobject

Is a ref to an instance of HAM::Device::IcomCIVSerialIO. If undef a new SerialIO object will be created with the following two parameters. If defined no new SerialIO object will be created but this one will be used instead. This allows to share one SerialIO object between several instances of IcomCIV (see method get_serioobject() ).

Either SerialIOobject or SerialDevice must be set, otherwise new will die.

=item SerialDevice

Must be present at least once (if you have multiple radios on one serial bus).
Can be undef for subsequent calls for the creation of a 2nd, 3rd etc. radio
which use the same serial port as the first. Default is /dev/ttyS1. If undef the previous parameter mus tbe set.

=item Baudrate

If SerialDevice is given, this value should be given as well. If SerialDevice is undef this value is ignored. If SerialDevice is present and this valus is undef, defaults to 19200.

=item UseLock

Boolean if serial port should use locking or not

=item RadioModel

Must be exactly one of the model names defined in this module, case does
not matter. If model is not known the creation of the object will fail. See below for a list of recognized models.

=item RadioAdr

The CI-V bus adress of that radio. Can be undef, in that case the default adress
of the specified model is used.

=item OwnAdr

The CI-V bus adress of the controller (this computer), usually 0xE0 is used. Can be undef, if so 0xEO is used.

=item DebugLevel

Numeric value, 0 disables debugging, increasing values yield more debug output
to STDERR. Default 0.

=back

=cut

sub new {
    my $class = shift;
    my $self = {};
    $self->{SEROBJ}     = shift || undef;
    $self->{SERDEV}     = shift || '/dev/ttyS1';
    $self->{BAUDRATE}   = shift || 19200;
    $self->{USELOCK}    = shift || undef;
    $self->{MODEL}      = shift || 'Undefined';
    $self->{CIV_ADRESS} = shift || get_civ_adress( $self->{MODEL} );
    $self->{OWN_ADRESS} = shift || 0xE0;
    $self->{DEBUG}      = shift || 0;
    $self->{FREQ}       = -1;
    $self->{MODE}       = 'undefined';
    $self->{FILTER}     = 'undefined';
    $self->{STATUS}     = stINIT;
    $self->{EVENT}      = evNOEV;
    $self->{CBACK}      = undef;
    $self->{IN_CHECK_RX} = undef;

    croak "Model '$self->{MODEL}' is not recognized! See IcomCIV::Support for supported models." unless ( get_civ_adress( $self->{MODEL} ) );

    bless ($self, $class);

    # Set up new SerialIO object if not given
    $self->{SEROBJ} = HAM::Device::IcomCIVSerialIO->new (
        $self->{SERDEV},
        $self->{BAUDRATE},
        $self->{USELOCK},
        $self->{DEBUG}
        ) unless (defined $self->{SEROBJ});

    # Tell SerialIO object for which adress I am responsible
    $self->{SEROBJ}->set_callback( $self->{CIV_ADRESS}, $self );

    return $self;
};



=pod

=head2 set_callback ( ref_to_sub )

With this method the callback subroutine is set for later calls. After each received message from the CI-V protocol this sub is called with the following parameters:

=over 4

=item event

Is one of

    evSTAT      Status GOOD/NOGOOD received
    evFREQ      A new frequency has been received
    evMODE      A new mode/filter has been received
    evUNKN      Unknown command response received
    evNOEV      Fake, no event has happened so far
    evEDGE      Band Edges have been received

=item state

Is one of

    stGOOD      all ok, command succeeded
    stFAIL      command to radio failed
    stNOIM      command not implemented in this class (not recognized)
    stWAIT      wait, status update in progress
    stINIT      occurs only after new() and if no command has been issued yet

=item data1, data2

=back

Contents of data1 and data2 depends on the specific event:

    Event   data1           data2
    ------------------------------
    evFREQ  frequency       undef
    evMODE  mode            filter
    evEDGE  loedge          hiedge
    evSTAT  undef           undef
    evUNKN  commandbyte     undef

The callback function should handle the received data (e.g. display it) and return without much delay. Currently there is no protection that the callback is not called again and again before returning. I.e. your callback function should be re-entrant.

=cut

sub set_callback {
    my $self = shift;
    $self->{CBACK} = shift;
};

=pod

=head2 get_serioobject()

Returns the HAM::Device::IcomCIVSerialIO object which was initiated in an earlier instance of HAM::Device::IcomCIV. For use in a subsequent instance of this module for another radio on the same bus.

=cut

sub get_serioobject {
    my $self = shift;
    return $self->{SEROBJ};
};

=pod

=head2 process_buffer( buffer )

This is the central routine which is called whenever a CI-V telegram has been received. It receives a byte buffer, filled with the entire CI-V telegram, including leading 0xFE 0xFE, but excluding the trailing 0xFD.

This basic class IcomCIV::Radio implements decoding of command responses which are supported by most Icom radios. That is:

    get freq          0x00 or 0x03 received
    get mode/filter   0x01 or 0x04 received
    get Band edges    0x02 received
    GOOD              0xFB received
    NOGOOD            0xFA received

All other responses are not recognized by this class and should be handled by a descendant for an individual model. See HAM::Device::IcomICR8500 or HAM::Device::IcomICR75 for examples of descendant classes.

At the end of process_buffer the upper layer (application) is called by it's callback (if set).

=cut

sub process_buffer {
    my $self = shift;

    #break datagram into bytes
    my @bytes = unpack("C*", $_[0]);
    my ($data1, $data2);

         if ( ($bytes[4] eq 0x00) or ($bytes[4] eq 0x03) ) {
        $self->{FREQ}   = bcd2int(@bytes[5,6,7,8,9]);
        $self->{STATUS} = stGOOD;
        $self->{EVENT}  = evFREQ;
        $data1 = $self->{FREQ};
    } elsif ( ($bytes[4] eq 0x01) or ($bytes[4] eq 0x04) ) {
        ( $self->{MODE}, $self->{FILTER} )
            = ( icom2mode($bytes[5], $self->{MODEL}), icom2filter(@bytes[5,6]));
        $self->{STATUS} = stGOOD;
        $self->{EVENT}  = evMODE;
        $data1 = $self->{MODE};
        $data2 = $self->{FILTER};
    } elsif ( $bytes[4] eq 0x02 ) {
        $self->{LOEDGE} = bcd2int(@bytes[5,6,7,8,9]);
        $self->{HIEDGE} = bcd2int(@bytes[11,12,13,14,15]);
        $self->{STATUS} = stGOOD;
        $self->{EVENT}  = evEDGE;
        $data1 = $self->{LOEDGE};
        $data2 = $self->{HIEDGE};
    } elsif ( $bytes[4] eq 0xFA ) {
        $self->{STATUS} = stFAIL;
        $self->{EVENT}  = evSTAT;
    } elsif ( $bytes[4] eq 0xFB ) {
        $self->{STATUS} = stGOOD;
        $self->{EVENT}  = evSTAT;
    } else {
        $self->{STATUS} = stFAIL;
        $self->{EVENT}  = evUNKN;
    };

    # call callback function of upper layer
    if ( $self->{CBACK} ) {
        &{ $self->{CBACK} }( $self->{EVENT}, $self->{STATUS}, $data1, $data2 );
    };
};

=pod

=head2 frequency( [integer] )

Sets (when issued with parameter) or gets (without parameter) the frequency of a radio. Frequency is integer in Hz.

Setting the frequency uses the command 0x05 which yields a GOOD/NOGOOD response from the radio, so expect a status event after setting the frequency (if you use the event callback).

Alternatively there exists the method B<set_frequency> which uses command 0x00, which does not yield a response from the radio. So you will not receive a status event or any feedback if your command was successful or not, but it's slightly faster.

Getting a frequency interrogates the radio and waits (blocks) until the radio returns the frequency (integer, in Hz). A later version will implement a timeout.

If events are used (if callback is set) you will also receive a evFREQ event. Before sending the query command to the radio the status is set to stWAIT, it will change to stGOOD if a frequency was received.

=cut

sub frequency {
    my $self = shift;
    $self->{STATUS} = stWAIT;
    if (@_) {
        my $str = chr(0x05) . int2bcd( shift, 5 );
        $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
    } else {
        my $str = chr(0x03);
        $self->{EVENT} = evNOEV;
        my $res = $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
        while ( $self->{EVENT} != evFREQ ) {
            # wait without timeout
        };
        return $self->{FREQ};
    };
};

sub set_frequency {
# use command 0x00 to set freq without response from radio.
    my $self = shift;
    if (@_) {
        my $str = chr(0x00) . int2bcd( shift, 5 );
        $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
    };
};

=pod

=head2 mode( Modestring [, Filterstring] )

Sets (when issued with parameter) or gets (without parameter) the current mode and filter of the radio (USB. LSB, AM etc.). Optional parameter is filter, so mode and filter can be set with one call.

Setting the mode uses the command 0x06 which yields a GOOD/NOGOOD response from the radio, so expect a status event after setting the mode (if you use the event callback).

Alternatively there exists the method B<set_mode> which uses command 0x01, which does not yield a response from the radio. So you will not receive a status event or any feedback if your command was successful or not.

Getting a mode interrogates the radio and waits (blocks) until a response is received. A later version will implement a timeout.
In scalar context only mode is returned, in list context mode and filter is returned. Returned strings are human readable like USB, LSB, AM etc., and NORMAL, NARROW or WIDE for filter. See IcomCIV::Support for all possible modes and filters.

If events are used (if callback is set) you will also receive a evMODE event. Before sending the query command to the radio the status is set to stWAIT, it will change to stGOOD if a mode/filter was received.

=cut

sub mode {
    my $self = shift;
    $self->{STATUS} = stWAIT;
    if (@_) {
        $self->{MODE} = shift;
        my $str = chr(0x06) . mode2icom( $self->{MODE} );
        if (@_) {
            $self->{FILTER} = shift;
            $str .= filter2icom( $self->{MODE}, $self->{FILTER} )
        };
        $self->{SEROBJ}->send_civ($self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str);
    } else {
        my $str = chr(0x04);
        $self->{EVENT} = evNOEV;
        $self->{SEROBJ}->send_civ($self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str);
        while ( $self->{EVENT} != evMODE ) {
            # wait blocking
        };
    };
    wantarray ? return ( $self->{MODE}, $self->{FILTER} ) : return $self->{MODE};
};

sub set_mode {
# Use command 0x01 to set mode without response
    my $self = shift;
    if (@_) {
        $self->{MODE} = shift;
        my $str = chr(0x01) . mode2icom( shift );
        if (@_) {
            $self->{FILTER} = shift;
            $str .= filter2icom( $self->{MODE}, $self->{FILTER} )
        };
        $self->{SEROBJ}->send_civ($self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str);
    };
};

=pod

=head2 status( )

Returns the current status, one of:
    stGOOD      all ok, command succeeded
    stFAIL      command to radio failed
    stNOIM      command not implemented in this class (not recognized)
    stWAIT      wait, status update in progress
    stINIT      occurs only after new() and if no command has been issued yet

=cut

sub status {
    my $self = shift;
    return $self->{STATUS};
};

=pod

=head2 get_bandedges( )

Returns the lower and upper frequency limit the radio does support. Frequencies are integer in Hz.

=cut

sub get_bandedges {
    my $self = shift;
    my $str = chr(0x02);
    $self->{EVENT} = evNOEV;
    $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
    while ( $self->{EVENT} != evEDGE ) {
        # wait blocking
    };
    return ( $self->{LOEDGE}, $self->{HIEDGE} );
};

=pod

=head2 select_vfo( [A|B|MAIN|SUB] )

Selects the VFO mode. If no parameter is given the previously selected VFO (A or B, Main or Sub) is selected. With parameter 'A', 'B', 'Main' or 'Sub' the respective VFO is selected. Works only with radio which have a VFO (not all do).

If successful status is set to stGOOD and a evSTAT event happens.

=cut

sub select_vfo {
    my $self = shift;
    my $str = chr(0x07);
    if (@_) {
           if ( uc($_[0]) eq 'A')    { $str .= chr(0x00) }
        elsif ( uc($_[0]) eq 'B')    { $str .= chr(0x01) }
        elsif ( uc($_[0]) eq 'MAIN') { $str .= chr(0xD0) }
        elsif ( uc($_[0]) eq 'SUB')  { $str .= chr(0xD1) };
    };
    $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
};

=pod

=head2 equal_vfo( )

Equalizes VFO A and VFO B. If successful status is set to stGOOD and a evSTAT event happens. Works only with radios which have a VFO (not all do).

=cut

sub equal_vfo {
    my $self = shift;
    my $str = chr(0x07) . chr(0xA0);
    $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
};

=head2 exchange_vfo( )

Swaps VFO A and VFO B. If successful status is set to stGOOD and a evSTAT event happens. Works only with radios which have a VFO (not all do).

=cut

sub exchange_vfo {
    my $self = shift;
    my $str = chr(0x07) . chr(0xB0);
    $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
};

=pod

=head2 equal_mainsub( )

Swaps VFOs MAIN and SUB. If successful status is set to stGOOD and a evSTAT event happens. Works only with radios which have a Main/Sub VFO (not all do).

=cut

sub equal_mainsub {
    my $self = shift;
    my $str = chr(0x07) . chr(0xB1);
    $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
};

=pod

=head2 select_mem( [number] )

Selects memory mode, previously used memory channel if no parameter is given. Or selects memory channel number if parameter is provided.

If successful status is set to stGOOD and a evSTAT event happens.

=cut

sub select_mem {
    my $self = shift;
    my $str = chr(0x08);
    if (@_) {
        my $n = reverse int2bcd( shift,2 );
        $str .= $n;
    };
    $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
};

=pod

=head2 write_mem( )

Writes the currently displayed frequency and mode to the currently selected VFO. If the selected memory is not empty the previous contents is overwritten.

If successful status is set to stGOOD and a evSTAT event happens.

=cut

sub write_mem {
    my $self = shift;
    my $str = chr(0x09);
    $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
};

=pod

=head2 xfer_mem( )

Transfers the contents (Frequency, Mode) of currently selected memory channel to the VFO. Please note that this command behaves differently, depending whether the radio is currently in Memory or VFO mode. Check the authors website for more details.

If successful status is set to stGOOD and a evSTAT event happens.

=cut

sub xfer_mem {
    my $self = shift;
    my $str = chr(0x0A);
    $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
};

=pod

=head2 clear_mem( )

Erases the currently selected memory channel. With most radios this works only if the radio is currently in memory mode and fails (status stFAIL) when in VFO Mode.

If successful status is set to stGOOD and a evSTAT event happens.

=cut

sub clear_mem {
    my $self = shift;
    my $str = chr(0x0B);
    $self->{SEROBJ}->send_civ( $self->{CIV_ADRESS}, $self->{OWN_ADRESS}, $str );
};

##########################################################################
# Support functions
# all called as class functions, i.e. without self

=pod

=head1 CLASS FUNCTIONS

These functions are used internally.

=head2 int2bcd( frequency, want_nr_of_bytes )

Converts an integer number to a BCD string as used with the CI-V protocol. Length of BCD string is want_nr_of_bytes.

Frequency as integer, BCD string is LSB first. If frequency results in a longer BCD string than requested by want_nr_of_bytes it is cut off.

=cut

sub int2bcd(@) {
    my ($int, $nrb) = @_;
    my $v = '0000000000' . sprintf('%u',$int);
    my $r = '';
    my $i;
    for ($i=-1; $i>=-5; $i--) {
        $r .= chr(hex('0x'.substr($v,$i*2,2)) );
    }
    return substr($r, 0, $nrb);
};


=pod

=head2 bcd2int( List_of_BCD_bytes )

Converts a list of BCD bytes to an integer number. List of BCD bytes must be LSB first, as used with the Icom CI-V protocol. Returns the resulting frequency as integer.

=cut

sub bcd2int(@) {
    my $f = 0;
    my $i = 0;
    foreach my $b (@_) {
        $f += ( ($b & 0x0F) + ((($b & 0xF0) >>4 ) * 10)) * 100**$i;
        $i++;
    };
    return $f;
};


=pod

=head2 icom2mode( mode, model )

Converts mode byte as used by the Icom CI-V protocol to a readable string. Returns the mode string.

Valid modes are (depending on radio):

    LSB, USB,
    AM, S-AM,
    CW, CW-R,
    RTTY, RTTY-R,
    FM, WFM,
    PSK, PSK-R

=cut

#################################################
# Valid for normal mode command, not for modes in a memory
my %icommodes = (
    0x00 => 'LSB',
    0x01 => 'USB',
    0x02 => 'AM',
    0x03 => 'CW',
    0x04 => 'RTTY',
    0x05 => 'FM',
    0x06 => 'WFM',
    0x07 => 'CW-R',
    0x08 => 'RTTY-R',
    0x11 => 'S-AM',
    0x12 => 'PSK',
    0x13 => 'PSK-R',
);
my %revicommodes = (
    'LSB'    => 0x00,
    'USB'    => 0x01,
    'AM'     => 0x02,
    'CW'     => 0x03,
    'RTTY'   => 0x04,
    'FM'     => 0x05,
    'WFM'    => 0x06,
    'CW-R'   => 0x07,
    'RTTY-R' => 0x08,
    'S-AM'   => 0x11,
    'PSK'    => 0x12,
    'PSK-R'  => 0x13,
    'SSB'    => 0x05,
);

sub icom2mode {
    my $mode = shift;
    my $model = shift;

    if (($mode==0x05) and ($model eq 'IC-R7000')) {
        return 'SSB';
    }
    else {
        return $icommodes{$mode};
    };
};

=pod

=head2 mode2icom( mode_string )

Reverse of above, converts mode string to Icom byte. Returns one mode byte as chr. If mode is not recognized the invalid modebyte '0x99' is returned. If you do not check the return value and send this to the radio, it will respond with a stFAIL status.

Valid modes: see icom2mode

=cut

sub mode2icom($) {
    my $mode = shift;
    return (exists($revicommodes{uc($mode)})) ? chr($revicommodes{uc($mode)}) : chr(0x99);
};



=pod

=head2 icom2filter( mode, filter )

Converts two bytes from the Icom CI-V protocol to Filter width

Returned filters are:

    NORMAL
    NARROW
    WIDE

=cut

my %icomfilters = (
    0x01 => 'WIDE',
    0x02 => 'NORMAL',
    0x03 => 'NARROW',
);
my %revicomfilters = (
    'WIDE'   => 0x01,
    'NORMAL' => 0x02,
    'NARROW' => 0x03,
);

sub icom2filter(@) {
    my ($m, $f) = @_;
    if (($m ne 0x02) and ($m ne 0x11)) {
        $f++; #when mode not AM shift filterbytes to match table
    };
    return $icomfilters{ $f };
};



=pod

=head2 filter2icom( mode_string, filter_string )

Converts mode and filter string to Icom filter byte. Requires mode byte as well, because possible filters depend on mode. Returns filter byte as chr. Please note that an invalid filter is not mapped to an invalid code but to 'Normal'.

Valid mode strings: depending on radio, also see icom2mode
Valid filter strings:

    NORMAL
    NARROW
    WIDE

=cut

sub filter2icom(@) {
    my ($m, $f) = @_;
    $m = uc($m);
    $f = uc($f);
    if (($m eq 'AM') or ($m eq 'S-AM')) {
        if    ($f eq 'WIDE')   {return chr(0x01)}
        elsif ($f eq 'NORMAL') {return chr(0x02)}
        elsif ($f eq 'NARROW') {return chr(0x03)}
        else                   {return chr(0x02)} #default normal
    }
    else { #non-am
        if    ($f eq 'NORMAL') {return chr(0x01)}
        elsif ($f eq 'NARROW') {return chr(0x02)}
        else                   {return chr(0x01)}; #default normal
    };
};

=pod

=head2 get_civ_adress( model )

Returns the default CI-V bus adress for a model if found (as integer), otherwise undef.

Valid models are:

    IC-1271       IC-707   IC-7400      IC-7800    IC-R9000
    IC-1275       IC-718   IC-746PRO    IC-820     IC-R9500
    IC-271        IC-725   IC-751A      IC-821     IC-X3
    IC-275        IC-726   IC-756       IC-910
    IC-375        IC-725   IC-756PRO    IC-970
    IC-471        IC-726   IC-756PRO2   IC-R10
    IC-475        IC-728   IC-756PRO3   IC-R20
    IC-575        IC-729   IC-761       IC-R71
    IC-7000       IC-735   IC-765       IC-R72
    IC-703        IC-736   IC-7700      IC-R75
    IC-706        IC-737   IC-775       IC-R7000
    IC-706 MK2    IC-738   IC-78        IC-R7100
    IC-706 MK2G   IC-746   IC-781       IC-R8500

=cut


my %icommodels = (
    'IC-1271'     => 0x24,
    'IC-1275'     => 0x18,
    'IC-271'      => 0x20,
    'IC-275'      => 0x10,
    'IC-375'      => 0x12,
    'IC-471'      => 0x22,
    'IC-475'      => 0x14,
    'IC-575'      => 0x16,
    'IC-7000'     => 0x70,
    'IC-703'      => 0x68,
    'IC-706'      => 0x48,
    'IC-706 MK2'  => 0x4e,
    'IC-706 MK2G' => 0x58,
    'IC-707'      => 0x3e,
    'IC-718'      => 0x5E,
    'IC-725'      => 0x28,
    'IC-726'      => 0x30,
    'IC-728'      => 0x38,
    'IC-729'      => 0x3A,
    'IC-735'      => 0x04,
    'IC-736'      => 0x40,
    'IC-737'      => 0x3C,
    'IC-738'      => 0x44,
    'IC-746'      => 0x56,
    'IC-7400'     => 0x66,
    'IC-746PRO'   => 0x66,
    'IC-751A'     => 0x1c,
    'IC-756'      => 0x50,
    'IC-756PRO'   => 0x5C,
    'IC-756PRO2'  => 0x64,
    'IC-756PRO3'  => 0x6e,
    'IC-761'      => 0x1e,
    'IC-765'      => 0x2c,
    'IC-7700'     => 0x76, # assumed
    'IC-775'      => 0x46,
    'IC-78'       => 0x62,
    'IC-781'      => 0x26,
    'IC-7800'     => 0x6a,
    'IC-820'      => 0x42,
    'IC-821'      => 0x4c,
    'IC-910'      => 0x60,
    'IC-970'      => 0x2e,
    'IC-R10'      => 0x52,
    'IC-R20'      => 0x6c,
    'IC-R71'      => 0x1a,
    'IC-R72'      => 0x32,
    'IC-R75'      => 0x5a,
    'IC-R7000'    => 0x08,
    'IC-R7100'    => 0x34,
    'IC-R8500'    => 0x4a,
    'IC-R9000'    => 0x2a,
    'IC-R9500'    => 0x72,
    'IC-X3'       => 0x74, # assumed
);

sub get_civ_adress {
    my $model = uc( shift );
    if ( exists $icommodels{ $model } ) {
        return $icommodels{ $model } ;
    } else {
        return undef;
    };
};


=pod

=head1 SEE ALSO

    HAM::Device::IcomCIVSerialIO
    HAM::Device::IcomICR8500
    HAM::Device::IcomICR75
    and probably other IcomCIV modules

    Icom CI-V Protocol Specification by Icom
    Documentation of the CI-V protocol in any recent Icom radio manual
    Documentation of the CI-V protocol at the authors website
    http://www.df4or.de

If you are looking for a library which supports more radios than just Icoms, look for 'grig' or 'hamlib'.

=head1 AUTHOR

Ekkehard (Ekki) Plicht, DF4OR, E<lt>ekki@plicht.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Ekkehard (Ekki) Plicht. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
__END__
