package Device::ISDN::OCLM::ISDNStatistics;

=head1 NAME

Device::ISDN::OCLM::ISDNStatistics - OCLM ISDN statistics

=head1 SYNOPSIS

 $status = $lanmodem->getISDNStatistics ();
 ...
 $info = $lanmodem->isdnStatistics ();
 $tei = $info->tei ();

=head1 DESCRIPTION

This class encapsulates 3com OCLM ISDN statistics, including line status, etc.

This class is a subclass of B<Device::ISDN::OCLM::Statistics>.

=head1 CONSTRUCTORS

Extract instances of this class from B<Device::ISDN::OCLM::LanModem>.

=head1 METHODS

The following methods are provided:

=over 4

=item $copy = $info->clone ()

This method returns a clone of this object.

=item $l1 = $info->layer1 ()

This method returns the layer 1 status.

=item $l2 = $info->layer2 ()

This method returns the layer 2 status.

=item $tei = $info->tei ()

This method returns the line TEI.

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
  'layer1',
  'layer2',
  'tei',
];

my $map = {
  'layer 1 (physical) status' => 'layer1',
  'layer 2 status' => 'layer2',
  'tei' => 'tei',
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
layer1
{
  return shift->{'layer1'};
}

sub
layer2
{
  return shift->{'layer2'};
}

sub
tei
{
  return shift->{'tei'};
}
