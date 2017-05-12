package Device::ISDN::OCLM::SPStatistics;

=head1 NAME

Device::ISDN::OCLM::SPStatistics - OCLM service provider statistics

=head1 SYNOPSIS

 $status = $lanmodem->getSPStatistics ();
 ...
 $info = $lanmodem->spStatistics ();
 $sp = $info->providerName (1);

=head1 DESCRIPTION

This class encapsulates 3com OCLM service provider statistics, including
total call time, failures, etc.

This class is a subclass of B<Device::ISDN::OCLM::Statistics>.

=head1 CONSTRUCTORS

Extract instances of this class from B<Device::ISDN::OCLM::LanModem>.

=head1 METHODS

The following methods are provided: For most calls, a provider index must
be specified; this should probably range from 1 through 5.

=over 4

=item $copy = $info->clone ()

This method returns a clone of this object.

=item $type = $info->providerName ($index)

This method returns the name of the specified provider or undef.

=item $dir = $info->successes ($index)

This method returns the number of successful connections to the
specified provider or undef.

=item $dir = $info->failures ($index)

This method returns the number of failed connections to the
specified provider or undef.

=item $dir = $info->octetsReceived ($index)

This method returns the number of octets received from the
specified provider or undef.

=item $dir = $info->octetsTransmitted ($index)

This method returns the number of octets transmitted to the
specified provider or undef.

=item $dir = $info->connectTime ($index)

This method returns the total connect time with the
specified provider or undef.

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
  'providerName',
  'successes',
  'failures',
  'octetsReceived',
  'octetsTransmitted',
  'connectTime',
];

my $nbsp = "\xa0";

my $map = {
  $nbsp => 'providerName#N',
  'number of successful connections' => 'successes#N',
  'number of failed connections' => 'failures#N',
  'total number of octets received' => 'octetsReceived#N',
  'total number of octets transmitted' => 'octetsTransmitted#N',
  'total connection time (seconds)' => 'connectTime#N',
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
providerName
{
  return shift->{'providerName'}->[shift];
}

sub
successes
{
  return shift->{'successes'}->[shift];
}

sub
failures
{
  return shift->{'failures'}->[shift];
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
connectTime
{
  return shift->{'connectTime'}->[shift];
}
