package Device::ISDN::OCLM::Statistics;

=head1 NAME

Device::ISDN::OCLM::Statistics - OCLM statistics superclass

=head1 SYNOPSIS

 $fields = $info->supportedFields ();
 foreach my $field (@{$fields}) {
   ...
 }

=head1 DESCRIPTION

This is the superclass of various OCLM statistics classes.

=head1 METHODS

The following methods are provided:

=over 4

=item $copy = $info->clone ()

This method returns a clone of the subclass.

=item $fields = $lanmodem->suppoertedFields ()

This method returns a reference to a list of all the statistics fields
supported by the subclass.

=item $str = $lanmodem->toString ()

This method returns a textual representation of the subclass.

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
use Device::ISDN::OCLM::SystemStatistics;
use Device::ISDN::OCLM::ISDNStatistics;
use Device::ISDN::OCLM::CurrentStatistics;
use Device::ISDN::OCLM::LastStatistics;
use Device::ISDN::OCLM::SPStatistics;

use UNIVERSAL qw (isa);
use vars qw ($VERSION);

$VERSION = "0.40";

sub
new
{
  my ($class, $table, $fields, $map) = @_;

  my $vars = {
    '_fields' => $fields,
   };
  return undef if _parseRows ($vars, $table->content, $map);

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
supportedFields
{
  return shift->{'_fields'};
}

sub
toString
{
  my ($self) = @_;

  my $string = "";
  my $fields = $self->supportedFields;
  foreach my $field (@{$fields}) {
    my $value = $self->{$field};
    if (ref ($value)) {
      foreach my $i (1 .. $#{$value}) {
	my $subvalue = $value->[$i];
	$string .= $field . "[$i]: $subvalue\n" if defined ($subvalue);
      }
    } else {
      $string .= "$field: $value\n" if defined ($value);
    }
  }

  return $string;
}

sub
_parseRows
{
  my ($vars, $rows, $map) = @_;

  foreach my $row (@{$rows}) {
    if (isa ($row, 'HTML::Element')) {
#     die "Expected table row (" . $row->tag . ")" if ($row->tag ne 'tr');
      return -1 if ($row->tag ne 'tr');

      return -1 if _parseCols ($vars, $row->content, $map);
    }
  }

  undef;
}

sub
_parseCols
{
  my ($vars, $cols, $map) = @_;

  my $i = 0;
  my $col;

  while (defined ($col = $cols->[$i ++]) && !isa ($col, 'HTML::Element')) {}
# die "Expected table column" if !defined ($col) || !($col->tag =~ /^t[dh]$/i);
  return -1 if !defined ($col) || !($col->tag =~ /^t[dh]$/i);
  my $key = lc ($col->content->[0]);
  $key =~ s/^\s*(.*\S)\s*$/$1/;

  my $var = $map->{$key};
# die "Unknown key ($key)" if !defined ($var);
  return -1 if !defined ($var);
  return if ($var eq '');

  my $n = 1;
  if ($var =~ s/\#(\d)$//) {
    $n = $1;
    $vars->{$var} = [];
  } elsif ($var =~ s/\#N$//) {
    $n = 101; # hack
    $vars->{$var} = [];
  }

  foreach my $j (1 .. $n) {
    while (defined ($col = $cols->[$i ++]) && !isa ($col, 'HTML::Element')) {}
    last if !defined ($col) && ($n == 101);
#   die "Expected table column" if !defined ($col) || !($col->tag =~ /^t[dh]$/i);
    return -1 if !defined ($col) || !($col->tag =~ /^t[dh]$/i);
    my $text = Device::ISDN::OCLM::HTML->_toText ($col);
    
    if ($n > 1) {
      $vars->{$var}->[$j] = $text;
    } else {
      $vars->{$var} = $text;
    }
  }

  undef;
}

my @_informationClasses = qw (Device::ISDN::OCLM::SystemStatistics Device::ISDN::OCLM::ISDNStatistics Device::ISDN::OCLM::CurrentStatistics Device::ISDN::OCLM::LastStatistics Device::ISDN::OCLM::SPStatistics);

sub
_create
{
  my ($class, $index, $table) = @_;

  my $infoClass = $_informationClasses[$index - 1];
  my $info = $infoClass->new ($table);

  return $info
}

1;
