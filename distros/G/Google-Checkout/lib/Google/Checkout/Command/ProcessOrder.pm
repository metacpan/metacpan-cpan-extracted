package Google::Checkout::Command::ProcessOrder;

=head1 NAME

Google::Checkout::Command::ProcessOrder

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Command::ProcessOrder;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $gco = Google::Checkout::General::GCO->new;

  my $process_order = Google::Checkout::Command::ProcessOrder->new(
                      order_number => 156310171628413);
  my $response = $gco->command($process_order);
  die $response if is_gco_error($response);
  print $response,"\n\n";

=head1 DESCRIPTION

A sub-class of C<Google::Checkout::Command::GCOCommand>. 
This module is used to send a process order command to Google Checkout.

=over 4

=item new ORDER_NUMBER => ...

Constructor. Takes a Google Checkout order number.

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

#--
#--  <process-order> 
#--

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
           name => Google::Checkout::XML::Constants::PROCESS_ORDER) => $class;
}

sub to_xml
{
  my ($self, @args) = @_;

  my $code = $self->SUPER::to_xml(@args);

  return is_gco_error($code) ? $code : $self->done;
}

1;
