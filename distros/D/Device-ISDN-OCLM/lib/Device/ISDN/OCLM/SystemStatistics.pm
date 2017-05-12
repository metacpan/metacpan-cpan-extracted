package Device::ISDN::OCLM::SystemStatistics;

=head1 NAME

Device::ISDN::OCLM::SystemStatistics - OCLM system statistics

=head1 SYNOPSIS

 $status = $lanmodem->getSystemStatistics ();
 ...
 $info = $lanmodem->systemStatistics ();
 $upTime = $info->upTime ();

=head1 DESCRIPTION

This class encapsulates 3com OCLM system statistics, including serial
number, firmware version, etc.

This class is a subclass of B<Device::ISDN::OCLM::Statistics>.

=head1 CONSTRUCTORS

Extract instances of this class from B<Device::ISDN::OCLM::LanModem>.

=head1 METHODS

The following methods are provided:

=over 4

=item $copy = $info->clone ()

This method returns a clone of this object.

=item $id = $info->productID ()

This method returns the device product ID.

=item $sn = $info->serialNumber ()

This method returns the device serial number.

=item $addr = $info->ethernetAddress ()

This method returns the device ethernet address. Note that this is the NIC
address, not the IP address.

=item $sv = $info->systemVersion ()

This method returns the device system software version.

=item $bv = $info->bootVersion ()

This method returns the device boot software version.

=item $ut = $info->upTime ()

This method returns the device up-time.

=item $dat = $info->date ()

This method returns the device date.

=item $tim = $info->upTime ()

This method returns the device time.

=item $str = $info->toString ()

This method returns a textual representation of this object.

=back

=head1 COPYRIGHT

Copyright 1999-2000 Merlin Hughes.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Merlin Hughes E<lt>merlin@merlin.org>

=cut

use strict;

use Device::ISDN::OCLM::Statistics;

use UNIVERSAL qw (isa);
use vars qw (@ISA $VERSION);

$VERSION = '0.40';
@ISA = qw (Device::ISDN::OCLM::Statistics);

my $fields = [
  'productID',
  'serialNumber',
  'ethernetAddress',
  'systemVersion',
  'bootVersion',
  'upTime',
  'date',
  'time'
];

my $map = {
  'product id' => 'productID',
  'serial number' => 'serialNumber',
  'ethernet address' => 'ethernetAddress',
  'system software version number' => 'systemVersion',
  'boot software version number' => 'bootVersion',
  'the lan modem has been up for' => 'upTime',
  'date (day/month/year)' => 'date',
  'time (hour:minute:second)' => 'time'
};

sub
new
{
  my ($class, $table) = @_;

  my $self = Device::ISDN::OCLM::Statistics->new ($table, $fields, $map);
  $self = bless ($self, $class);

  $self;
}

sub
productID
{
  return shift->{'productID'};
}

sub
serialNumber
{
  return shift->{'serialNumber'};
}

sub
ethernetAddress
{
  return shift->{'ethernetAddress'};
}

sub
systemVersion
{
  return shift->{'systemVersion'};
}

sub
bootVersion
{
  return shift->{'bootVersion'};
}

sub
upTime
{
  return shift->{'upTime'};
}

sub
date
{
  return shift->{'date'};
}

sub
time
{
  return shift->{'time'};
}
