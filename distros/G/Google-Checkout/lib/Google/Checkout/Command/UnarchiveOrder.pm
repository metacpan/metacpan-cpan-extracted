package Google::Checkout::Command::UnarchiveOrder;

=head1 NAME

Google::Checkout::Command::UnarchiveOrder

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Command::UnarchiveOrder;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $gco = Google::Checkout::General::GCO->new;

  my $unarchive = Google::Checkout::Command::UnarchiveOrder->new(
                  order_number => 156310171628413);
  my $response = $gco->command($unarchive);
  die $response if is_gco_error($response);
  print $response,"\n\n";

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::Command::GCOCommand>. 
This module is used to unarchive an order.

=over 4

=item new ORDER_NUMBER => ...

Constructor. Takes a Google order number.

=item to_xml

Return the XML that will be sent to Google Checkout. Note that 
this function should not be used directly. Instead, it's called 
indirectly by the C<Google::Checkout::General::GCO> object internally.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::Command::GCOCommand

=cut

use strict;
use warnings;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

use Google::Checkout::Command::GCOCommand;
our @ISA = qw/Google::Checkout::Command::GCOCommand/;

sub new
{
  my ($class, @args) = @_;

  return bless $class->SUPER::new(
           @args, 
           name => Google::Checkout::XML::Constants::UNARCHIVE_ORDER) => $class;
}

sub to_xml
{
  my ($self, @args) = @_;

  my $code = $self->SUPER::to_xml(@args);

  return is_gco_error($code) ? $code : $self->done;
}

1;
