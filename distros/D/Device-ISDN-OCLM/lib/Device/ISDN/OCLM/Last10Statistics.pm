package Device::ISDN::OCLM::Last10Statistics;

=head1 NAME

Device::ISDN::OCLM::Last10Statistics - OCLM Last10 call statistics

=head1 SYNOPSIS

 $status = $lanmodem->getLast10Statistics ();
 ...
 $info = $lanmodem->Last10Statistics ();
 $sp = $info->serviceProvider (1);

=head1 DESCRIPTION

This class encapsulates 3com OCLM last 10 call statistics, including
known service providers and whether or not they are currently connected.

=head1 CONSTRUCTORS

Extract instances of this class from B<Device::ISDN::OCLM::LanModem>.

=head1 METHODS

The following methods are provided:

=over 4

=item $copy = $info->clone ()

This method returns a clone of this object.

=item $typ = $info->callType ($index)

This method returns the call type of the specified call (1-offset) or undef.

=item $sp = $info->serviceProvider ($index)

This method returns the name of the service provider of the specified
call (1-offset) or undef.

=item $dur = $info->duration ($index)

This method returns the duration of the specified call (1-offset) or
undef.

=item $reason = $info->initiationReason ($index)

This method returns the initiation reason of the specified call (1-offset)
or undef.

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
    'callType' => [],
    'serviceProvider' => [],
    'duration' => [],
    'initiationReason' => [],
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
callType
{
  return shift->{'callType'}->[shift];
}

sub
serviceProvider
{
  return shift->{'serviceProvider'}->[shift];
}

sub
duration
{
  return shift->{'duration'}->[shift];
}

sub
initiationReason
{
  return shift->{'initiationReason'}->[shift];
}

# TODO: Better
sub
toString
{
  my ($self) = @_;

  my $string = "";
  my $types = $self->{'callType'};
  my $providers = $self->{'serviceProvider'};
  my $durations = $self->{'duration'};
  my $reasons = $self->{'initiationReason'};
  foreach my $i (1 .. $#{$providers}) {
    my $type = $types->[$i];
    my $provider = $providers->[$i];
    my $duration = $durations->[$i];
    my $reason = $reasons->[$i];
    $string .= "callType[$i]: $type\n" if defined ($type);
    $string .= "serviceProvider[$i]: $provider\n" if defined ($provider);
    $string .= "duration[$i]: $duration\n" if defined ($duration);
    $string .= "initiationReason[$i]: $reason\n" if defined ($reason);
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
  my $type = $col->is_empty ? undef : $col->content->[0];
  $vars->{'callType'}->[$index] = $type;

  while (defined ($col = $cols->[$i ++]) && !isa ($col, 'HTML::Element')) {}
# die "Expected table column" if !defined ($col) || (($col->tag ne 'td'));
  return -1 if !defined ($col) || (($col->tag ne 'td'));
  my $provider = $col->is_empty ? undef : $col->content->[0];
  $vars->{'serviceProvider'}->[$index] = $provider;

  while (defined ($col = $cols->[$i ++]) && !isa ($col, 'HTML::Element')) {}
# die "Expected table column" if !defined ($col) || (($col->tag ne 'td'));
  return -1 if !defined ($col) || (($col->tag ne 'td'));
  my $duration = $col->is_empty ? undef : $col->content->[0];
  $vars->{'duration'}->[$index] = $duration;

  while (defined ($col = $cols->[$i ++]) && !isa ($col, 'HTML::Element')) {}
# die "Expected table column" if !defined ($col) || (($col->tag ne 'td'));
  return -1 if !defined ($col) || (($col->tag ne 'td'));
  my $reason = Device::ISDN::OCLM::HTML->_toText ($col);
  $vars->{'initiationReason'}->[$index] = $reason;

  undef;
}

1;
