package Lab::Bus::USBtmc;
#ABSTRACT: USBtmc (Test & Measurement) Linux kernel driver bus
$Lab::Bus::USBtmc::VERSION = '3.682';
# "sys/ioctl.ph" throws a warning about FORTIFY_SOURCE, but
# this alternate is (perhaps?) not present on all systems,
# so do a workaround
if ( !defined( eval('require "linux/ioctl.ph";') ) ) {
    require "sys/ioctl.ph";
}

# Created using h2ph
eval 'sub USBTMC_IOC_NR () {91;}' unless defined(&USBTMC_IOC_NR);
eval 'sub USBTMC_IOCTL_INDICATOR_PULSE () { &_IO( &USBTMC_IOC_NR, 1);}'
    unless defined(&USBTMC_IOCTL_INDICATOR_PULSE);
eval 'sub USBTMC_IOCTL_CLEAR () { &_IO( &USBTMC_IOC_NR, 2);}'
    unless defined(&USBTMC_IOCTL_CLEAR);
eval 'sub USBTMC_IOCTL_ABORT_BULK_OUT () { &_IO( &USBTMC_IOC_NR, 3);}'
    unless defined(&USBTMC_IOCTL_ABORT_BULK_OUT);
eval 'sub USBTMC_IOCTL_ABORT_BULK_IN () { &_IO( &USBTMC_IOC_NR, 4);}'
    unless defined(&USBTMC_IOCTL_ABORT_BULK_IN);
eval 'sub USBTMC_IOCTL_CLEAR_OUT_HALT () { &_IO( &USBTMC_IOC_NR, 6);}'
    unless defined(&USBTMC_IOCTL_CLEAR_OUT_HALT);
eval 'sub USBTMC_IOCTL_CLEAR_IN_HALT () { &_IO( &USBTMC_IOC_NR, 7);}'
    unless defined(&USBTMC_IOCTL_CLEAR_IN_HALT);

# please note: with the usbtmc kernel module on Linux
# kernel 4.7.4 (and some prior versions) the module has a
# built-in unchangable timeout of 5 seconds. So the only
# way to deal with timeouts is "try the read N times, and see
# if there is a response".  It also makes no sense to "sleep between
# the write and read" of a query, since one might as well do
# the read and get a (potentially) faster result.

# So:
# wait_query is ignored
# brutal only has the effect of not throwing errors on read timeouts
# timeout is rounded to 5 second interval, to give the number of reads
# that are tried

use strict;
use Scalar::Util qw(weaken);
use Carp;
use Lab::Bus;
use Data::Dumper;

our @ISA = ("Lab::Bus");

our %fields = (
    type        => 'USBtmc',
    brutal      => 0,          # ignore read timeout
    read_length => 1000,       # bytes
    wait_query  => 10e-6,      # ignored
    timeout     => 10,         # sec,
);

our $DRIVER_TIMEOUT = 5;       # sec, built into module

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # search for twin in %Lab::Bus::BusList. If there's none, place $self there and weaken it.
    if ( $class eq __PACKAGE__ )
    {        # careful - do only if this is not a parent class constructor
        if ( $twin = $self->_search_twin() ) {
            undef $self;
            return $twin;    # ...and that's it.
        }
        else {
            $Lab::Bus::BusList{ $self->type() }->{'default'} = $self;
            weaken( $Lab::Bus::BusList{ $self->type() }->{'default'} );
        }
    }

    return $self;
}

sub connection_new {         # { tmc_address => primary address }
    my $self = shift;
    my $args = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $fn;
    my $usb_vendor;
    my $usb_product;
    my $usb_serial = '*';

    if ( defined $args->{'tmc_address'}
        && $args->{'tmc_address'} =~ /^[0-9]*$/ ) {
        $fn = "/dev/usbtmc" . $args->{'tmc_address'};
    }
    else {
        # want the vendor/product as strings, hex values
        if (
            defined $args->{'visa_name'}
            && ( $args->{'visa_name'}
                =~ /USB::0x([0-9A-Fa-f]{4})::0x([0-9A-Fa-f]{4})::[^:]*::INSTR/
            )
            ) {
            $usb_vendor  = $1;
            $usb_product = $2;
            $usb_serial  = $3;
        }
        else {
            $usb_vendor = $args->{'usb_vendor'};
            if ( $usb_vendor =~ /^\s*0x([\da-f]{4})/i ) {
                $usb_vendor = $1;
            }
            else {
                $usb_vendor = sprintf( '%04x', $usb_vendor );
            }
            $usb_product = $args->{'usb_product'};
            if ( $usb_product =~ /^\s*0x([\da-f]{4})/i ) {
                $usb_product = $1;
            }
            else {
                $usb_product = sprintf( '%04x', $usb_product );
            }
            $usb_serial = $args->{'usb_serial'};
        }
    }

    if ( !defined $fn && ( !defined $usb_vendor || !defined $usb_product ) ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No valid USB TMC address given to "
                . __PACKAGE__
                . "::connection_new()\n", );
    }

    # try to find device
    # options: lsusb, /proc/bus/usb/ /sys/kernel/debug/usb/devices
    # select matching serial; if usb_serial = '*' select first match.

    if ( !defined($fn) ) {
        my $got = 0;

        if (
            open( LSUSB_HANDLE,
                "/usr/bin/lsusb -d ${usb_vendor}:${usb_product} -v 2>/dev/null |"
            )
            ) {
            # sometimes lsusb doesn't have serial, not sure why
            while (<LSUSB_HANDLE>) {
                if ( !$got && /^\s*iSerial\s+\d+\s+([^\s]+)?/i ) {
                    $got = 1 if $usb_serial eq '*';
                    $self->{config}->{usb_serial} = $1;
                    next;
                }
                if ( $got && /^\s*iInterface\s+(\d+)\s/i ) {
                    $fn = "/dev/usbtmc$1";
                    last;
                }
            }
            close(LSUSB_HANDLE);
        }

        if (   !$got
            && -x "usb-devices"
            && open( LSUSB_HANDLE, "usb-devices |" ) ) {
            my $okdev = 0;
            while (<LSUSB_HANDLE>) {
                $okdev = 0 if /^\s*$/;
                $okdev = 1
                    if /Vendor=${usb_vendor}\s+ProdID=${usb_product}\s/i;
                next unless $okdev;
                if (/SerialNumber=([^\s]+)/i) {
                    $got = 1 if $usb_serial eq '*' || $usb_serial eq $1;
                    $self->{config}->{usb_serial} = $1;
                    next;
                }
                next unless $got;
                if (/\If#=\s*(\d+)/i) {
                    $fn = "/dev/usbtmc$1";
                    last;
                }
            }
            close(LSUSB_HANDLE);
        }

        # modern /sys/ stuff, but maybe not user readable, or
        # obsolete usbfs stuff, same format
        if (
            !$got
            && (   open( LSUSB_HANDLE, "</sys/kernel/debug/usb/devices" )
                || open( LSUSB_HANDLE, "</proc/bus/usb/devices" ) )
            ) {
            my $okdev = 0;
            while (<LSUSB_HANDLE>) {
                $okdev = 0 if /^\s*$/;
                $okdev = 1
                    if /Vendor=${usb_vendor}\s+ProdID=${usb_product}\s/i;
                next unless $okdev;
                if (/SerialNumber=([^\s]+)/i) {
                    $got = 1 if $usb_serial eq '*' || $usb_serial eq $1;
                    $self->{config}->{usb_serial} = $1;
                    next;
                }
                next unless $got;
                if (/\If#=\s*(\d+)/i) {
                    $fn = "/dev/usbtmc$1";
                    last;
                }
            }
            close(LSUSB_HANDLE);
        }

    }

    if ( !defined $fn ) {
        Lab::Exception::CorruptParameter->throw(
            error => sprintf(
                      "Could not find specified device 0x%s/0x%s/%s in "
                    . __PACKAGE__
                    . "::connection_new()\n",
                $usb_vendor, $usb_product, $usb_serial
            ),
        );
    }

    my $connection_handle = undef;
    my $tmc_handle        = undef;

    open( $tmc_handle, "+<", $fn )
        || Lab::Exception::CorruptParameter->throw(
        error => $! . ": '$fn'\n" );
    binmode($tmc_handle);
    $tmc_handle->autoflush;

    $connection_handle
        = { valid => 1, type => "USBtmc", tmc_handle => $tmc_handle };
    return $connection_handle;
}

# if read returns 'undef', that's an EOF/error/Timeout, see $!
# return a zero length string if brutal=1 and timeout
sub connection_read
{    # @_ = ( $connection_handle, $args = { read_length, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();
    my $timeout     = $args->{'timeout'}     || $self->{'timeout'};

    my $result = undef;

    my $tmc_handle = $connection_handle->{'tmc_handle'};
    my $iss;
    my $tries = 0;

    while (1) {
        $iss = sysread( $tmc_handle, $result, $read_length );
        if ( !defined($iss) ) {
            if ( $! =~ /timed?\s*out/i ) {
                $tries++;
                next if $timeout <= 0;
                next if $timeout >= $tries * $DRIVER_TIMEOUT;
                if ( !$brutal ) {
                    Lab::Exception::Timeout->throw(
                        error => "USBtmc read time out\n",
                    );
                }

                return '';
            }
            else {
                Lab::Exception::DriverError->throw(
                    error => "USBtmc read error $!\n",
                );
            }
        }
        last;
    }

    # strip spaces and null byte
    $result =~ s/[\n\r\x00]*$//;
    return $result;
}

# write then read
sub connection_query
{ # @_ = ( $connection_handle, $args = { command, read_length, wait_status, wait_query, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    #    my $wait_query = $args->{'wait_query'} || $self->wait_query();
    # just use regular 'timeout' for the wait time
    my $result = undef;

    $self->connection_write($args);
    $result = $self->connection_read($args);
    return $result;
}

sub connection_write
{    # @_ = ( $connection_handle, $args = { command, wait_status }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command = $args->{'command'} || undef;

    if ( !defined $command ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No command given to "
                . __PACKAGE__
                . "::connection_write().\n", );
    }

    # use syswrite, since 'print' and 'sysread' should not be mixed
    my $iss = syswrite( $connection_handle->{'tmc_handle'}, $command );

    if ( !defined($iss) ) {
        Lab::Exception::DriverError->throw(
            error => "USBtmc write error $!\n",
        );
        return 0;
    }

    return 1;
}

sub connection_settermchar {    # @_ = ( $connection_handle, $termchar

    # 	my $self = shift;
    # 	my $connection_handle=shift;
    # 	my $termchar =shift; # string termination character as string
    #

    # useless for USBtmc, return success

    return 1;
}

sub connection_enabletermchar {    # @_ = ( $connection_handle, 0/1 off/on

    # 	my $self = shift;
    # 	my $connection_handle=shift;
    # 	my $arg=shift;
    #
    # useless for USBtmc, return success

    return 1;
}

sub serial_poll {
    my $self              = shift;
    my $connection_handle = shift;
    my $sbyte             = undef;

    # useless for USBtmc return undef
    return $sbyte;
}

sub connection_clear {
    my $self              = shift;
    my $connection_handle = shift;

    close( $connection_handle->{'tmc_handle'} );
}

sub connection_device_clear {
    my $self              = shift;
    my $connection_handle = shift;

    my $unused = 0;

    ioctl(
        $connection_handle->{'tmc_handle'},
        USBTMC_IOCTL_ABORT_BULK_OUT(), $unused
    );
    ioctl(
        $connection_handle->{'tmc_handle'},
        USBTMC_IOCTL_ABORT_BULK_IN(), $unused
    );
    ioctl(
        $connection_handle->{'tmc_handle'},
        USBTMC_IOCTL_CLEAR_OUT_HALT(), $unused
    );
    ioctl(
        $connection_handle->{'tmc_handle'},
        USBTMC_IOCTL_CLEAR_IN_HALT(), $unused
    );
    ioctl(
        $connection_handle->{'tmc_handle'}, USBTMC_IOCTL_CLEAR(),
        $unused
    );
}

sub timeout {
    my $self              = shift;
    my $connection_handle = shift;
    my $timo              = shift;

    my $t;

    if ( $timo !~ /^\s*(\+|\-)?(\d+\.\d*|\d+|\d*\.\d+)\s*$/ ) {
        Lab::Exception::CorruptParameter->throw(
            error => "Bad timeout value '$timo'\n" );
        return;
    }

    $timo = $timo + 0;

    if ( $timo <= 0 ) {
        $t = -1;    # infinite
    }
    else {
        $t = ( int( $timo / $DRIVER_TIMEOUT ) + 1 ) * $DRIVER_TIMEOUT;
    }
    $self->{timeout} = $t;
}

sub ParseIbstatus
{    # Ibstatus http://linux-gpib.sourceforge.net/doc_html/r634.html
    carp("ParseIbstatus not supported");
}

sub VerboseIbstatus {
    my $self     = shift;
    my $ibstatus = shift;

    carp("VerboseIbstatus not supported");
}

#
# search and return an instance of the same type in %Lab::Bus::BusList
#
sub _search_twin {
    my $self = shift;

    if ( !$self->ignore_twins() ) {
        for my $conn ( values %{ $Lab::Bus::BusList{ $self->type() } } ) {
            return $conn;    # if $conn->gpib_board() == $self->gpib_board();
        }
    }
    return undef;
}

1;


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Bus::USBtmc - USBtmc (Test & Measurement) Linux kernel driver bus

=head1 VERSION

version 3.682

=head1 SYNOPSIS

This is the USB TMC (Test & Measurement Class) bus class.

  my $tmc = new Lab::Bus::USBtmc({ });

or implicit through instrument and connection creation:

  my $instrument = new Lab::Instrument::HP34401A({
    connection_type => 'USBtmc',
    tmc_address=>1,
  }

=head1 DESCRIPTION

Driver for the interface provided by the usbtmc linux kernel module.

Obviously, this will work for Linux systems only. 
On Windows, please use L<Lab::Bus::VISA>. The interfaces are (errr, will be) identical.

Note: you don't need to explicitly handle bus objects. The Instruments will create them themselves, and existing bus will
be automagically reused.

=head1 CONSTRUCTOR

=head2 new

 my $bus = Lab::Bus::USBtmc({
  });

Return blessed $self, with @_ accessible through $self->config().

=head1 Thrown Exceptions

Lab::Bus::USBtmc throws

  Lab::Exception::TMCOpenFileError
  
  Lab::Exception::CorruptParameter

  Lab::Exception::DriverError

  Lab::Exception::Timeout

=head1 METHODS

=head2 connection_new

  $tmc->connection_new({ tmc_address => $addr });

Creates a new connection ("instrument handle") for this bus. The argument is a hash, whose contents 
depend on the bus type.

For TMC there are several ways to indicate which device is to be used 

if more than one is given, it is the first one that is used:
tmc_address => $addr         selects /dev/usbtmc$addr 
visa_name=> 'USB::0xVVVV::0xPPPP::SSSSSS::INSTR';
    where VVVV is the hex usb vendor number, PPPP is the hex usb product number, and SSSSSS is the serial
    number string.  If SSSSSS is '*', then the first device found that matches vendor and product will be
    used.
usb_vendor=>'0xVVVV' or 0xVVVV    vendor number
usb_product=>'0xPPPP' or 0xPPPP   product number
usb_serial=>'SSSSSS'  or '*'      serial number, or wildcard.

The usb_serial defaults to '*' if not specified. 

The handle is usually stored in an instrument object and given to connection_read, connection_write etc.
to identify and handle the calling instrument:

  $InstrumentHandle = $tmc->connection_new({ usb_vendor => 0x0699, usb_product => 0x1234 });
  $result = $tmc->connection_read($self->InstrumentHandle(), { options });

Please note that, because of obscure Linux device configuration issues,
it is sometimes difficult to extract the USBtmc device serial number
without 'root' privileges. This code tries several techniques, including
invoking 'lsusb', looking in /proc/bus/usb, and looking in 
/sys/kernel/debug/usb/devices. There is no guarantee that those hacking
on the Linux kernel won't change these in future. 

Also the current (as of kernel 4.7.4, and many earlier versions) default
kernel modules for usbtmc has a 'built in' read timeout hardcoded to 
5 seconds. The read/timeout code here works with this. 

Some years ago, when the USBtmc module was first being added to standard
distributions, it was "edited to conform with kernel module style guidelines"
which resulted in a completely nonfunctional driver.  Alternate (older)
versions from device manufacturers DID work, and had greater functionality.
If you are using one of those modules, check to see if the timeout logic
here requires modification.  

Unfortunately, it's not so easy for a little perl module to tell what
variety of kernel module is being used, so that will be up to the user. 

See C<Lab::Instrument::Read()>.

=head2 connection_write

  $tmc->connection_write( $InstrumentHandle, { Cmd => $Command } );

Sends $Command to the instrument specified by the handle.

=head2 connection_read

  $tmc->connection_read( $InstrumentHandle, { ReadLength => $readlength } );

Reads back a maximum of $readlength bytes. 

Setting C<Brutal> to a true value will result in timeouts being ignored, and the gathered data returned without error.

IF there is a timeout (i.e., no data) then connection_read returns a zero
length string.

=head2 timeout

  $tmc->timeout( $connection_handle, $timeout );

Sets the timeout in seconds for tmc operations on the device/connection specified by $connection_handle.  $timeout <= 0 means "no timeout, indefinate wait".

The timeout is quantized in units of the kernel module timeout (currently
5 sec in kernel 4.7.4), so the timeout just results in determining the
number of reads that are attempted before a timeout error is thrown. 

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $tmc_serial = $instrument->config(usb_serial);

Without arguments, returns a reference to the complete $self->config aka @_ of the constructor.

 $config = $bus->config();
 $tmc_serial = $bus->config()->{'usb_serial'};

=head1 CAVEATS/BUGS

Lots, I'm sure.

=head1 SEE ALSO

=over 4

=item

L<Lab::Bus>

=item

and many more...

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2012       Hermann Kraus
            2016       Charles Lane, Simon Reinhardt
            2017       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
