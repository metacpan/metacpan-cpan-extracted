package Google::Checkout::Command::GCOCommand;

=head1 NAME

Google::Checkout::Command::GCOCommand 

=head1 SYNOPSIS

=head1 DESCRIPTION

You usually won't need to use this class directly.

=over 4

=item new ORDER_NUMBER => ..., NAME => ...

Constructor. Takes a Google order number and the name of the 
actual command that will eventually be sent to Google Checkout.
Again, you will not need to use this class directly most of the time.

=item get_name

Returns the name of the command.

=item set_name NAME

Sets the name of the command.

=item get_order_number

Returns the Google order number.

=item set_order_number ORDER_NUMBER

Sets the Google order number.

=item to_xml

Writes the command name as well as the Google order number that are
common to all the sub-command classes.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

=cut

use strict;
use warnings;

use Google::Checkout::General::Error;
use Google::Checkout::XML::Writer;
use Google::Checkout::XML::Constants;
our @ISA = qw/Google::Checkout::XML::Writer/;

sub new 
{
  my ($class, %args) = @_;

  delete $args{root};

  my $self = $class->SUPER::new(%args);

  $self->{name} = $args{name} || '';
  $self->{order_number} = $args{order_number};

  return bless $self => $class;
}

sub get_name 
{ 
  my ($self) = @_;

  return $self->{name}; 
}

sub set_name 
{
  my ($self, $name) = @_;

  $self->{name} = $name || '';
}

sub get_order_number 
{ 
  my ($self) = @_;

  return $self->{order_number};
}

sub set_order_number
{
  my ($self, $order_number) = @_;

  $self->{order_number} = $order_number if $order_number;
}

sub to_xml
{
  my ($self, %args) = @_;

  return Google::Checkout::General::Error(
    @{$Google::Checkout::General::Error::ERRORS{MISSING_ORDER_NUMBER}}) 
      unless $self->get_order_number;

  my $sstring = Google::Checkout::XML::Constants::XML_SCHEMA;

  my $xml_schema = '';
  if ($args{gco}->reader()) {
    $xml_schema = $args{gco}->reader()->get($sstring);
  } else {
    $xml_schema = $args{gco}->{__xml_schema};
  }

  $self->add_element(
           name => $self->get_name,
           attr => [xmlns => $xml_schema,
                    Google::Checkout::XML::Constants::ORDER_NUMBER, $self->get_order_number]);
}

1;
