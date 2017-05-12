package Device::ISDN::OCLM::ManualStatistics;

=head1 NAME

Device::ISDN::OCLM::ManualStatistics - OCLM manual call statistics

=head1 SYNOPSIS

 $status = $lanmodem->getManualStatistics ();
 ...
 $info = $lanmodem->manualStatistics ();
 $sp = $info->serviceProvider (1);

=head1 DESCRIPTION

This class encapsulates 3com OCLM manual call statistics, including
known service providers and whether or not they are currently connected.

=head1 CONSTRUCTORS

Extract instances of this class from B<Device::ISDN::OCLM::LanModem>.

=head1 METHODS

The following methods are provided:

=over 4

=item $copy = $info->clone ()

This method returns a clone of this object.

=item $sp = $info->serviceProvider ($index)

This method returns the name of the service provider at the specified
index (1-offset) or undef. Beware of I<TempSvcProvider> as this is not
a normal service provider.

=item $st = $info->callStatus ($index)

This method returns the call status of the service provider at the specified
index (1-offset) or undef. Typically this will be I<Down> or I<Up (1B)> or
something like that.

=item $cm = $info->command ($index)

This method returns the command hyperlink of the service provider at the
specified index (1-offset) or undef. Typically this will be I<CALL1.HTM>
or I<DISC1.htm> or something like that.

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

use HTML::Element;

use Device::ISDN::OCLM::HTML;

use UNIVERSAL qw (isa);
use vars qw ($VERSION);

$VERSION = "0.40";

sub
new
{
  my ($class, $table) = @_;

  my $vars = {
    'serviceProvider' => [],
    'callStatus' => [],
    'command' => [],
    'commandHREF' => [],
   };
  return undef if _parseRows ($vars, $table->content);

  my $self = bless ($vars, $class);

  $self;
}

sub 
clone
{
  my ($self) = @_;

  my $copy = bless { %$self }, ref $self;

  $copy;
}

sub
serviceProvider
{
  return shift->{'serviceProvider'}->[shift];
}

sub
callStatus
{
  return shift->{'callStatus'}->[shift];
}

sub
command
{
  return shift->{'command'}->[shift];
}

sub
commandHREF
{
  return shift->{'commandHREF'}->[shift];
}

sub
connectIndex
{
  my ($self, $index) = @_;

  my $status = $self->{'commandHREF'}->[$index];
  return -1 if !($status =~ s/CALL(\d)\.HTM//i);

  $1;
}

sub
disconnectIndex
{
  my ($self, $index) = @_;

  my $status = $self->{'commandHREF'}->[$index];
  return -1 if !($status =~ s/DISC(\d)\.HTM//i);

  $1;
}

sub
abortIndex
{
  my ($self, $index) = @_;

  my $status = $self->{'commandHREF'}->[$index];
  return -1 if !($status =~ s/ABORT(\d)\.HTM//i);

  $1;
}

sub
toString
{
  my ($self) = @_;

  my $string = "";
  my $providers = $self->{'serviceProvider'};
  my $stati = $self->{'callStatus'};
  foreach my $i (1 .. $#{$providers}) {
    my $provider = $providers->[$i];
    my $status = $stati->[$i];
    $string .= "$provider: $status\n";
  }

  return $string;
}

sub
_parseRows
{
  my ($vars, $rows) = @_;

  my $index = 0;
  foreach my $row (@{$rows}) {
    if (isa ($row, 'HTML::Element')) {
#     die "Expected table row (" . $row->tag . ")" if ($row->tag ne 'tr');
      return -1 if ($row->tag ne 'tr');
      
      if ($index > 0) {
	return -1 if _parseCols ($vars, $row->content, $index);
      }
      ++ $index;
    }
  }

  undef;
}

sub
_parseCols
{
  my ($vars, $cols, $index) = @_;

  my $i = 0;
  my $col;

  while (defined ($col = $cols->[$i ++]) && !isa ($col, 'HTML::Element')) {}
# die "Expected table column" if !defined ($col) || (($col->tag ne 'td'));
  return -1 if !defined ($col) || (($col->tag ne 'td'));
  my $provider = $col->content->[0];
  $vars->{'serviceProvider'}->[$index] = $provider;

  while (defined ($col = $cols->[$i ++]) && !isa ($col, 'HTML::Element')) {}
# die "Expected table column" if !defined ($col) || (($col->tag ne 'td'));
  return -1 if !defined ($col) || (($col->tag ne 'td'));
  my $status = Device::ISDN::OCLM::HTML->_toText ($col);
  $vars->{'callStatus'}->[$index] = $status;

  while (defined ($col = $cols->[$i ++]) && !isa ($col, 'HTML::Element')) {}
# die "Expected table column" if !defined ($col) || (($col->tag ne 'td'));
  return -1 if !defined ($col) || (($col->tag ne 'td'));
  my $command = Device::ISDN::OCLM::HTML->_toText ($col);
  $vars->{'command'}->[$index] = $command;
  my $hrefs = $col->extract_links (qw (a));
  my $href = $hrefs->[0]->[0];
  $vars->{'commandHREF'}->[$index] = $href;

  undef;
}

1;
