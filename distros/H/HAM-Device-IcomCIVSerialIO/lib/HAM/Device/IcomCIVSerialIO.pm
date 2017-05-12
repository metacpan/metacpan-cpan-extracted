##########################################################################
# HAM::Device::IcomCIVSerialIO -- Low Level IO Module for Icom CI-V radios
#
# Copyright (c) 2007 Ekkehard (Ekki) Plicht. All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
##########################################################################

=pod

=head1 NAME

HAM::Device::IcomCIVSerialIO - Low Level Serial IO for Icom CI-V Radios

=head1 MODULE VERSION

Version 0.02 02. Dec. 2007

=head1 SYNOPSIS

  use HAM::Device::IcomCIVSerialIO;

  $ser = HAM::Device::IcomCIVSerialIO->new( '/dev/ttyS2', 19200, undef, debuglevel );
  $ser->set_callback ( $thiscivadress, $myradio );
  ...
  $ser->send_civ( $thiscivadress, $own_adress, $command );
  ...
  $ser->clear_callback( $thiscivadress );
  $ser->stop_serial();

=head1 DESCRIPTION

This module is the basic part of a bundle of modules that supports remote control of Icom radios equipped with the CI-V interface. It is used mainly by HAM::Device::IcomCIV and it's descendants.
To use it you need to open the serial port, send commands to the radio with   send_civ() and receive callbacks (set with set_callback() to process received CI-V data.

Note:

This module is considered private, it will change it's interface and functionality in the future, when it will support multiple serial ports at the same time. Do not use it directly, use HAM::Device::IcomCIV or one of it's desceandants instead.

=head2 EXPORTS

Nothing by default.

=head2 USES

  Device::SerialPort
  Time::HiRes
  Carp
  $SIG{ALRM}

=cut

package HAM::Device::IcomCIVSerialIO;

use 5.008008;
use strict;
use warnings;
use Device::SerialPort;
use Time::HiRes qw( ualarm );
use bytes;
use Carp;

our $VERSION = '0.02';

require Exporter;

our @ISA = qw( Exporter );

###########################################################################
# Class Data

my (%callbacks, $in_check_rx, $ser);
$SIG{ALRM} = \&check_rx;        # Poll the receive buffer

###########################################################################
###########################################################################

=head1 METHODS

=head2 new( device, baudrate, uselock, debug )

Opens the serial device with baudrate, and returns handle of serial port. Dies on various reasons (lock not possible, open not possible etc.).

This function also starts the ualarm() timer which polls regularly the incoming data. If data is received it is passed to the callback function.

=over 4

=item *

I<device> Is any valid devicename for a serial port, e.g. '/dev/ttyS1'.

=item *

I<baudrate> Is any valid baudrate supported by the attached Icom radio, e.g. 9600, 19200 etc. For performance reasons you should use 9600 and above.

=item *

I<uselock> If defined will try to lock the serial device with a lockfile in /var/lock.
No locking if undefined.

Note:
When using different distributions I found that Device::SerialPort sometimes uses 'sleep', at other times 'nanosleep' in the locking function. This leads to unexpected delays when using locking (2 seconds). If you experience this, don't use locking or patch your Device::SerialPort module.

=item *

I<debug> Debug flag, if >0 results in some diagnostic messages printed to STDERR.

=back

The new method clears the callback table! Set your callback[s] right after you have initiated a new serial device.

=cut

sub new {
    my $class = shift;
    my $self = {};
    $self->{DEVICE}  = shift;
    $self->{BAUD}    = shift;
    $self->{USELOCK} = shift;
    $self->{DEBUG}   = shift;

    %callbacks = ();    # initial clear callback table

    my $lockdevice = '';
    if ( $self->{USELOCK} ) {
    	my @items = split "/", $self->{DEVICE};
		$lockdevice = splice (@items,-1);
		defined($lockdevice) || croak 'failed extracting serial device\n';
		$lockdevice = '/var/lock/LCK..' . $lockdevice;
	};

	$self->{SERDEV} = Device::SerialPort->new (
        $self->{DEVICE},
        0,
        $lockdevice
        )                                    || croak "Can't lock and open $self->{DEVICE}: $!";

	$self->{SERDEV}->baudrate($self->{BAUD}) || croak 'failed setting baudrate';
	$self->{SERDEV}->parity('none')          || croak 'failed setting parity to none';
	$self->{SERDEV}->databits(8)			 || croak 'failed setting databits to 8';
	$self->{SERDEV}->stopbits(1)			 || croak 'failed setting stopbits to 1';
	$self->{SERDEV}->handshake('none')		 || croak 'failed setting handshake to none';
	$self->{SERDEV}->datatype('raw')		 || croak 'failed setting datatype raw';
	$self->{SERDEV}->write_settings 		 || croak 'failed write settings';
	$self->{SERDEV}->error_msg(1);			 # use built-in error messages
	$self->{SERDEV}->user_msg(1);			 # ?
	$self->{SERDEV}->read_const_time(100);	 # important for nice behaviour, otherwise hogs cpu
   	$self->{SERDEV}->read_char_time(100);	 # dto.

    $self->{SERDEV}->are_match( "\xFD" );    # end of CI-V data telegram

    bless ( $self, $class );

    $ser = $self->{SERDEV};

    # Finally set up alarm for polling
    ualarm(100);

    return $self;
};

=pod

=head2 stop_serial( )

Closes the serial port. Returns nothing.

=cut

sub stop_serial {
    my $self = shift;
	undef $self->{SERDEV};
};

sub DESTROY {
    my $self = shift;
    undef $self->{SERDEV};
}

=pod

=head2 send_civ( to_adr, fm_adr, command )

Assembles the data (to_adr, fm_adr, command) with header and tail of the CI-V
frame and sends this out over the serial line. Returns true if all data was
sent ok, otherwise false.

=over 4

=item *

I<to_adr> Is the Icom CI-V bus adress of the radio to which this command is directed.
Must be Integer, will be converted to a char.

=item *

I<fm_adr> Is the senders adress, usually 0xE0 for the controlling computer. Must be integer, will be converted to a char.

=item *

I<command> Is the data to be sent (a string of bytes), everything after the adresses and up to, but not including the final 0xFD.

=back

=cut


sub send_civ {
    my $self = shift;
    my ($to, $fm, $cmd) = @_;

    # Incoming data is probably flagged as UTF-8,
    # which leads to uf8ness of concatenated string,
    # which leads to 0xFE etc. being coded as \x{C3BE} (or so)
    # So I remove utf8ness
    utf8::downgrade($cmd);
    my $tele = chr(0xFE) . chr(0xFE) . chr($to) . chr($fm) . $cmd . chr(0xFD);

    if ( $self->{DEBUG} ) {
        my $th = s2hex($tele);
        warn "Tx: $th\n";
    };

	return ( length($cmd) +5 == $self->{SERDEV}->write($tele) ) ? 1 : 0;
};

###
# Called by SIGALARM every 100 msec.
# Class Function!
sub check_rx {
    # protect against re-entry if callback takes very long
    return if ($in_check_rx);
    $in_check_rx = 1;

    my $rxdata = $ser->lookfor;
    if ($rxdata) {
        my $th = s2hex($rxdata);
        warn "Rx: $th\n";


        # If from-adress is in callbacks, it's
        # a) not my own echo
        # b) a valid adress which I am responsible for
        # TODO Improvement: transfer ref to rxdata array, not array itself
        if ( exists $callbacks{ substr( $rxdata, 3, 1 ) } ) {
            $callbacks{ substr( $rxdata, 3, 1 ) }->process_buffer($rxdata);
        };
    };
    ualarm ( 100 ); # restart alarm
    $in_check_rx = 0;
};

=pod

=head2 set_callback( civadress, object )

Sets the callback object reference which is used for callback routine 'process_buffer', to be called whenever a complete CI-V telegram has been received by the serial routine. It's the responsibilty of this called routine to decode and act on the received telegram.

This method must be called with the appropiate data for each upper level instance of IcomCIV, otherwise it won't work!

=over 4

=item *

I<civadress> The CI-V bus adress for which this callback adress feels responsible, as integer, not char. Callbacks are multiplexed to different IcomCIV instances, depending on CI-V adress. This enables an application to have several instances of IcomCIV and handle each separately.

Currently this does not allow for duplicate CI-V bus adresses on the same serial port. So if you have two or more identical devices with identical adresses, you have to change them to make then unique to each radio. This is likely to change in the future, using a unique identifier for each radio (and will break the API).

=item *

I<object> The blessed reference of a an instance of a IcomCIV object (or descendant thereof). The actual method which is called is named 'process_buffer' and receives one parameter (besides the usual $self), and that is the entire CI-V telegram from the leading 0xFE 0xFE up to and including the final 0xFD.

=back

=cut

sub set_callback {
    my $self = shift;
    my ($civ, $obj) = @_;
    $callbacks{ chr($civ) } = $obj;
};

=pod

=head2 clear_callback ( civadress )

Deletes this CI-V bus adress from the callback table. Returns true on success, false if adress was not in table.

=over 4

=item *

I<civadress> The CI-V bus adress for which this callback adress feels responsible, as integer, not char.print "Serdev: $self->{SERDEV}\n";

=back

=cut

sub clear_callback {
    my $self = shift;
    my $adr = chr(shift);
    if ( exists $callbacks{$adr}) {
        delete $callbacks{$adr};
        return 1;
    } else {
        return 0;
    };
}

# For debugging only
sub s2hex {
    # in: scalar
    # out: string with each byte of input in 2-digit hex. space separated
    #my $self = shift;
    my ($c, $result, $tmp);
    $tmp = shift;
    my @bytes = unpack("C*", $tmp);
    $result="";
    foreach $c (@bytes) {
        $result = $result . sprintf ("%02lX ", $c);
    };
    return $result;
}



=pod

=head1 SEE ALSO

    HAM::Device::IcomCIV
    HAM::Device::IcomICR8500
    HAM::Device::IcomICR75
    and other IcomCIV modules

    Icom CI-V Protocol Specification by Icom
    Documentation of the CI-V protocol in any recent Icom radio manual
    Documentation of the CI-V protocol at the authors website:
    http://www.df4or.de

If you are looking for a library which supports more radios than just Icoms, look for 'grig' or 'hamlib'.

=head1 Portability

Due to the use of %SIG and Time::Hires this module is probably not very portable. The author has developed and used it only on various Linux platforms. If you have any feedback on the use of this module on other platforms, please let the author know. Thanks.

=head1 AUTHOR

Ekkehard (Ekki) Plicht, DF4OR, E<lt>ekki@plicht.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Ekkehard (Ekki) Plicht. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
__END__
