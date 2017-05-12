package Device::ISDN::OCLM::LastStatistics;

=head1 NAME

Device::ISDN::OCLM::LastStatistics - OCLM last call statistics

=head1 SYNOPSIS

 $status = $lanmodem->getLastStatistics ();
 ...
 $info = $lanmodem->lastStatistics ();
 $reason = $info->downReason (1);

=head1 DESCRIPTION

This class encapsulates 3com OCLM last call statistics, including
call time, destination, etc.

This class is a subclass of B<Device::ISDN::OCLM::Statistics>.

=head1 CONSTRUCTORS

Extract instances of this class from B<Device::ISDN::OCLM::LanModem>.

=head1 METHODS

The following methods are provided: For most calls, a call number must
be specified; this will be either 1 or 2.

=over 4

=item $copy = $info->clone ()

This method returns a clone of this object.

=item $type = $info->callType ($index)

This method returns the call type of the specified call or undef.

=item $dir = $info->callDirection ($index)

This method returns the call direction of the specified call or undef.

=item $sp = $info->spName ($index)

This method returns the service provider name or dial-in user of the
specified call or undef.

=item $opt = $info->callOptions ($index)

This method returns the call options of the specified call or undef.

=item $st = $info->startTime ($index)

This method returns the start time of the specified call or undef.

=item $ut = $info->upTime ($index)

This method returns the up time of the specified call or undef.

=item $oct = $info->octetsReceived ($index)

This method returns the octets received on the specified call or undef.

=item $oct = $info->octetsTransmitted ($index)

This method returns the octets transmitted on the specified call or undef.

=item $num = $info->callingNumber ($index)

This method returns the calling number of the specified call or undef.

=item $num = $info->calledNumber ($index)

This method returns the called number of the specified call or undef.

=item $reason = $info->upReason ($index)

This method returns the reason for the specified call going up or undef.

=item $reason = $info->downReason ($index)

This method returns the reason for the specified call going down or undef.

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
  'callType',
  'callDirection',
  'spName',
  'spUser',
  'callOptions',
  'startTime',
  'upTime',
  'octetsReceived',
  'octetsTransmitted',
  'callingNumber',
  'calledNumber',
  'upReason',
  'downReason',
];

my $nbsp = "\xa0";

# NB that uptime can now be a funky string

my $map = {
  $nbsp => '',
  'call type' => 'callType#2',
  'call direction' => 'callDirection#2',
  'service provider name' => 'spName#2',
  'service provider/dial-in user' => 'spName#2',
  'data call options' => 'callOptions#2',
  'call start time' => 'startTime#2',
  'the call was up for (seconds)' => 'upTime#2',
  'the call was up for' => 'upTime#2',
  'number of octets received' => 'octetsReceived#2',
  'number of octets transmitted' => 'octetsTransmitted#2',
  'calling telephone or port number' => 'callingNumber#2',
  'called telephone number' => 'calledNumber#2',
  'reason for call coming up' => 'upReason#2',
  'reason for call going down' => 'downReason#2',
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
callType
{
  return shift->{'callType'}->[shift];
}

sub
callDirection
{
  return shift->{'callDirection'}->[shift];
}

sub
spName
{
  return shift->{'spName'}->[shift];
}

sub
callOptions
{
  return shift->{'callOptions'}->[shift];
}

sub
startTime
{
  return shift->{'startTime'}->[shift];
}

sub
upTime
{
  return shift->{'upTime'}->[shift];
}

sub
octetsReceived
{
  return shift->{'octetsReceived'}->[shift];
}

sub
octetsTransmitted
{
  return shift->{'octetsTransmitted'}->[shift];
}

sub
callingNumber
{
  return shift->{'callingNumber'}->[shift];
}

sub
calledNumber
{
  return shift->{'calledNumber'}->[shift];
}

sub
upReason
{
  return shift->{'upReason'}->[shift];
}

sub
downReason
{
  return shift->{'downReason'}->[shift];
}
