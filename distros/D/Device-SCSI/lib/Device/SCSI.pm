package Device::SCSI;
BEGIN {
  $Device::SCSI::DIST = 'Device-SCSI';
}
BEGIN {
  $Device::SCSI::VERSION = '1.004';
}
# ABSTRACT: Perl module to control SCSI devices
use 5.009004;                   # due to Module::Load
use warnings;
use strict;

use Carp;

use Module::Load;

# This kludge attempts to load a module with the same name as the OS type.
# (e.g. SCSI::linux) and then makes this a subclass of that, so we get its
# methods

BEGIN {
    my $impl = "Device::SCSI::$^O";
    load $impl;
    our @ISA = $impl;
}


sub new {
    my($pkg, $handle)=@_;

    my $self=bless {}, $pkg;
    if (defined $handle) {
        return unless $self->open($handle);
    }
    return $self;
}

sub DESTROY {
    my $self=shift;

    $self->close();
}


sub inquiry {
    my $self=shift;

    # FIXME: this ignores the sense data
    my($data, undef)=$self->execute(pack("C x3 C x1", 0x12, 96), 96); # INQUIRE
    my %enq;
    @enq{qw( DEVICE VENDOR PRODUCT REVISION )}=unpack("C x7 A8 A16 A4", $data);
    return \%enq;
}


1;

__END__
=pod

=head1 NAME

Device::SCSI - Perl module to control SCSI devices

=head1 VERSION

version 1.004

=head1 SYNOPSIS

  use Device::SCSI;

  my @devices = Device::SCSI->enumerate;

  my $device = Device::SCSI->new($devices[0]);
  my %inquiry = %{ $device->inquiry };
  my ($result, $sense) = $device->execute($command, $wanted, $data);
  $device->close;

=head1 DESCRIPTION

This Perl library uses Perl5 objects to make it easy to perform low-level
SCSI I/O from Perl, avoiding all the black magic and fighting with C. The
object-oriented interface allows for the application to use more than one
SCSI device simultaneously (although this is more likely to be used by the
application to cache the devices it needs in a hash.)

As well as the general purpose execute() method, there are also a number of
other helper methods that can aid in querying the device and debugging. Note
that the goats and black candles usually required to solve SCSI problems
will need to be provided by yourself.

=for test_synopsis my($command, $wanted, $data);

=head1 IMPLEMENTATION

Not surprisingly, SCSI varies sufficiently from OS to OS that each one needs
to be dealt with separately. This package provides the OS-neutral
processing. The OS-specific code is provided in a module under
"Device::SCSI::" that has the same name as $^O does on your architecture.
The Linux driver is called Device::SCSI::linux, for example.

The generic class is actually made a subclass of the OS-specific class, not
the other way round as one might have expected. In other words, it takes the
opportunity to select its parent after it has started.

=head1 METHODS

=head2 new

 $device = Device::SCSI->new;

 $device = Device::SCSI->new($unit_name);

Creates a new SCSI object. If $unit_name is given, it will try to open it.
On failure, it returns undef, otherwise the object.

=head2 enumerate

 my @units = Device::SCSI->enumerate;

Returns a list of all the unit names that can be given to new() and open().
There is no guarantee that all these devices will be available (indeed, this
is unlikely to be the case) and you should iterate over this list, open()ing
and inquiry()ing devices until you find the one you want.

=head2 open

 $device->open($device_name);

Attempts to open a SCSI device, and returns $device if it can, or undef if
it can't. Reasons for not being able to open a device include it not
actually existing on your system, or you don't have sufficient permissions
to use F</dev/sg?> devices. (Many systems require you to be root to use
these.)

=head2 close

$device->close;

Closes the SCSI device after use. The device will also be closed if the
handle goes out of scope.

=head2 execute

 # Reading from the device only
 my ($result, $sense) = $device->execute($command, $wanted);

 # Writing (and possibly reading) from the device
 my ($result, $sense) = $device->execute($command, $wanted, $data);

This method sends a raw SCSI command to the device in question. $command
should be a 10 or a 12 character string containing the SCSI command. You
will often use pack() to create this. $wanted indicates how many bytes of
data you expect to receive from the device. If you are sending data to the
device, you also need to provide that data in $data.

The data (if any) returned from the device will be in $result, and the sense
data will appear the array ref $sense. If there is any serious error, for
example if the device cannot be contacted (and the kernel has not paniced
from such hardware failure) then an exception may be thrown.

=head2 inquiry

 %inquiry = %{ $device->inquiry };

This method provides a simple way to query the device via SCSI INQUIRY
command to identify it. A hash ref will be returned with the following keys:

=head3 DEVICE

A number identifying the type of device, for example 1 for a tape drive, or
5 for a CD-ROM.

=head3 VENDOR

The vendor name, "HP", or "SONY" for example.

=head3 PRODUCT

The device product name, e.g. "HP35470A", "CD-ROM CDU-8003A".

=head3 REVISION

The firmware revision of the device, e.g. "1109" or "1.9a".

=head1 WARNINGS

Playing directly with SCSI devices can be hazardous and lead to loss of
data. Since such things can normally only be done as the superuser (or by
the superuser changing the permissions on F</dev/sg?> to allow mere mortals
access) the usual caveats about working as root on raw devices applies. The
author cannot be held responsible for loss of data or other damages.

=head1 SEE ALSO

The Linux SCSI-Programming-HOWTO (In F</usr/doc/HOWTO/> on Debian Linux,
similar places for other distributions) details the gory details of the
generic SCSI interface that this talks to. Perl advocates will easily notice
how much shorter this Perl is compared to the C versions detailed in that
document.

To do anything more than a bit of hacking, you'll need the SCSI standards
documents. Drafts are apparently available via anonymous FTP from:

  ftp://ftp.cs.tulane.edupub/scsi
  ftp://ftp.symbios.com/pub/standards
  ftp://ftp.cs.uni-sb.de/pub/misc/doc/scsi

There's a Usenet group dedicated to SCSI:

  news:comp.periphs.scsi - Discussion of SCSI-based peripheral devices.

=head1 BUGS

This is some of my very early Perl, dating back to 2000, so the code quality
is not great. It does however work, despite the lack of a test suite to
prove it.

=head1 AUTHOR

Peter Corlett <abuse@cabal.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Peter Corlett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

