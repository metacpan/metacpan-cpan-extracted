package Google::Checkout::Notification::RiskInformation;

=head1 NAME

Google::Checkout::Notification::RiskInformation

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::Notification::RiskInformation;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $xml = "/xml/risk_information_notification.xml";

  #--
  #-- $xml can either be a file or a complete XML doc string
  #--
  my $risk = Google::Checkout::Notification::RiskInformation->new(xml => $xml);
  die $risk if is_gco_error $risk;

  print $refund->get_avs_response, "\n",
        $refund->get_cvn_response, "\n",
        $refund->get_partial_cc_number, "\n";

=head1 DESCRIPTION

Sub-class of C<Google::Checkout::Notification::GCONotification>. 
This module can be used to extract various risk information when 
the rish information notification is received.

=over 4

=item new XML => ...

Constructor. Takes either a XML file or XML doc as data string. If
the XML is invalid (syntax error for example), C<Google::Checkout::General::Error> 
is returned.

=item type

Always return C<Google::Checkout::XML::Constants::RISK_INFORMATION_NOTIFICATION>.

=item eligible_for_protection

Returns 1 if user is eligible for protection. Returns 0 otherwise.

=item get_buyer_info WHICH_DATA

Returns buyer information. WHICH_DATA can be 
C<Google::Checkout::XML::Constants::BUYER_CONTACT_NAME>, 
C<Google::Checkout::XML::Constants::BUYER_COMPANY_NAME>,
C<Google::Checkout::XML::Constants::BUYER_EMAIL>, 
C<Google::Checkout::XML::Constants::BUYER_PHONE>,
C<Google::Checkout::XML::Constants::BUYER_FAX>, 
C<Google::Checkout::XML::Constants::BUYER_ADDRESS1>,
C<Google::Checkout::XML::Constants::BUYER_ADDRESS2>, 
C<Google::Checkout::XML::Constants::BUYER_CITY>,
C<Google::Checkout::XML::Constants::BUYER_REGION>, 
C<Google::Checkout::XML::Constants::BUYER_POSTAL_CODE>,
C<Google::Checkout::XML::Constants::BUYER_COUNTRY_CODE>.

=item get_avs_response

Returns the AVS code.

=item get_cvn_response

Returns the CVN code.

=item get_partial_cc_number

Returns the partial credit card number.

=item get_buyer_account_age

Returns the buyer's Google Checkout account age in days.

=item get_buyer_ip_address

Returns the buyer's IP address.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=head1 SEE ALSO

Google::Checkout::Notification::GCONotification

=cut

#--
#--   <risk-information-notification>
#--

use strict;
use warnings;

use Google::Checkout::General::Error;
use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_valid_buyer_info/;

use Google::Checkout::Notification::GCONotification;
our @ISA = qw/Google::Checkout::Notification::GCONotification/;

sub type
{
  return Google::Checkout::XML::Constants::RISK_INFORMATION_NOTIFICATION;
}

sub eligible_for_protection
{
  my ($self) = @_;

  my $sstring = Google::Checkout::XML::Constants::ELIGIBLE_FOR_PROTECTION;
 
  return $self->get_data->{Google::Checkout::XML::Constants::RISK_INFORMATION}->
                          {$sstring} eq 'true' ? 1 : 0; 
}

sub get_buyer_info
{
  my ($self, $info) = @_;

  return Google::Checkout::General::Error->new(
           $Google::Checkout::General::Error::ERRORS{INVALID_VALUE}->[0],
           $Google::Checkout::General::Error::ERRORS{INVALID_VALUE}->[1] . ": $info") 
    unless is_valid_buyer_info $info;

  return $self->get_data->{Google::Checkout::XML::Constants::RISK_INFORMATION}->
                          {Google::Checkout::XML::Constants::BILLING_ADDRESS}->
                          {$info} || '';
}

sub get_avs_response
{
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::RISK_INFORMATION}->
                          {Google::Checkout::XML::Constants::AVS_RESPONSE} || '';
}

sub get_cvn_response
{
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::RISK_INFORMATION}->
                          {Google::Checkout::XML::Constants::CVN_RESPONSE} || '';
}

sub get_partial_cc_number
{
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::RISK_INFORMATION}->
                          {Google::Checkout::XML::Constants::PARTIAL_CC_NUMBER} || '';
}

sub get_buyer_account_age
{ 
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::RISK_INFORMATION}->
                          {Google::Checkout::XML::Constants::BUYER_ACCOUNT_AGE} || -1;
}

sub get_buyer_ip_address
{
  my ($self) = @_;

  return $self->get_data->{Google::Checkout::XML::Constants::RISK_INFORMATION}->
                          {Google::Checkout::XML::Constants::IP_ADDRESS} || '';
}

1;
