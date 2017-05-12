package Google::Checkout::Notification::Factory;

=head1 NAME

Google::Checkout::Notification::Factory

=head1 DESCRIPTION

Given a notification XML, return the corresponding notification
object that's capable of handing the notification.

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=cut

use strict;
use warnings;

use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/get_notification_object/;

use Google::Checkout::General::Error;
use Google::Checkout::XML::Constants;
use Google::Checkout::General::MerchantCalculationCallback;
use Google::Checkout::Notification::ChargeAmount;
use Google::Checkout::Notification::ChargebackAmount;
use Google::Checkout::Notification::NewOrder;
use Google::Checkout::Notification::OrderStateChange;
use Google::Checkout::Notification::RefundAmount;
use Google::Checkout::Notification::RiskInformation;
use Google::Checkout::General::Util qw/is_gco_error/;

sub get_notification_object
{
  my %args = @_;

  #--
  #-- no XML is an error
  #--
  return Google::Checkout::General::Error->new(-1, "No XML") unless $args{xml};

  #--
  #-- get the root element of the XML. no 'real' XML
  #-- parse and verification. i want this to be quick
  #--
  my $root_element = _get_root_element(\%args);

  return Google::Checkout::General::Error->new(-1, "Invalid XML") if is_gco_error($root_element);

  return _map_xml_to_notification_object($root_element, \%args);
}

sub _get_root_element
{
  my ($args) = @_;

  my $xml = '';

  #--
  #-- XML can either be in a file or in memory.
  #-- we are going to make the assumption that
  #-- if $args->{xml} starts with '<', it's not
  #-- in a file. otherwise, we load it from file
  #--
  if ($args->{xml} !~ /^</)
  {
    open(XML, $args->{xml}) || 
      return Google::Checkout::General::Error->new(-1, "Unable to open $args->{xml}: $!");

    #--
    #-- got a couple of lines. that's all we need 
    #-- to determine the type of the notification
    #--
    while (<XML>)
    {
      $xml .= $_;

      last if $. > 2;
    }

    close(XML);
  }
  else
  {
    $xml = $args->{xml};
  }

  if ($xml =~ /^<.+?<(\S+)/ms)
  { 
    return $1;
  }
  else 
  {
    return '';
  }
}

sub _map_xml_to_notification_object
{
  my ($root_element, $args) = @_;

  if ($root_element eq Google::Checkout::XML::Constants::CHARGE_AMOUNT_NOTIFICATION)
  {
    return Google::Checkout::Notification::ChargeAmount->new(xml => $args->{xml});
  } 
  elsif ($root_element eq Google::Checkout::XML::Constants::CHARGE_BACK_NOTIFICATION) 
  {
    return Google::Checkout::Notification::ChargebackAmount->new(xml => $args->{xml});
  }
  elsif ($root_element eq Google::Checkout::XML::Constants::MERCHANT_CALCULATION_CALLBACK)
  {
    return Google::Checkout::General::MerchantCalculationCallback->new(xml => $args->{xml});
  }
  elsif ($root_element eq Google::Checkout::XML::Constants::NEW_ORDER_NOTIFICATION)
  {
    return Google::Checkout::Notification::NewOrder->new(xml => $args->{xml});
  }
  elsif ($root_element eq Google::Checkout::XML::Constants::ORDER_STATE_CHANGE_NOTIFICATION)
  {
    return Google::Checkout::Notification::OrderStateChange->new(xml => $args->{xml});
  }
  elsif ($root_element eq Google::Checkout::XML::Constants::REFUND_AMOUNT_NOTIFICATION)
  {
    return Google::Checkout::Notification::RefundAmount->new(xml => $args->{xml});
  } 
  elsif ($root_element eq Google::Checkout::XML::Constants::RISK_INFORMATION_NOTIFICATION)
  {
    return Google::Checkout::Notification::RiskInformation->new(xml => $args->{xml});
  }
  else
  {
    return Google::Checkout::General::Error->new(-1, "Unknown notification: $root_element");
  }
}

1;
