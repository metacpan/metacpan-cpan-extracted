package Google::Checkout::General::GCO;

=head1 NAME

Google::Checkout::General::GCO

=head1 VERSION

Version 1.1.1

=cut 

=head1 SYNOPSIS

  use Google::Checkout::General::GCO;
  use Google::Checkout::General::MerchantItem;
  use Google::Checkout::Command::CancelOrder;
  use Google::Checkout::General::Util qw/is_gco_error/;

  my $gco = Google::Checkout::General::GCO->new(
            config_path => 'conf/GCOSystemGlobal.conf');

  #--
  #-- Or you can pass in the merchant id, key and Checkout URL like this
  #--
  $gco = Google::Checkout::General::GCO->new(
         merchant_id  => 1234,
         merchant_key => 'abcd',
         gco_server   => 'https://sandbox.google.com/...');

  my $cart = Google::Checkout::General::ShoppingCart->new(
             expiration    => "+1 month",
             private       => "Merchant private data",
             checkout_flow => $checkout_flow);

  my $item1 = Google::Checkout::General::MerchantItem->new(
              name        => "Fish",
              description => "A fish",
              price       => 12.34,
              quantity    => 12,
              private     => "gold");

  $cart->add_item($item1);

  #--
  #-- Checkout a cart
  #--
  my $response = $gco->checkout($cart);
    or
  my ($response,$requestXML) = $gco->checkout_with_xml($cart);

  die $response if is_gco_error $response;

  #--
  #-- print the redirect URL
  #--
  print $response,"\n";

  #--
  #-- Send a cancel order command
  #--
  my $cancel = Google::Checkout::Command::CancelOrder->new(
               order_number => 156310171628413,
               amount       => 5,
               reason       => "Cancel order");

  $response = $gco->command($cancel);

  die $response if is_gco_error $response;

  print $response,"\n";

=head1 DESCRIPTION

This is the main module for interacting with the Google
Checkout system. It allows a user to checkout, send
various commands and process notifications.

=over 4

=item new CONFIG_PATH => ..., MERCHANT_ID => ..., MERCHANT_KEY => ..., GCO_SERVER => ...

Constructor. Loads the configuration file from CONFIG_PATH. If no configuration
file is specified, merchant id, key and Checkout server URL must be specified.

=item reader

Returns the configuration reader used to parse
and load the configuration file.

=item get_checkout_url

Returns the Google Checkout URL defined in the
configuration file.

=item get_checkout_diagnose_url

Returns the diagnose Google Checkout URL
defined in the configuration file.

=item get_request_url

Returns the URL where requests will be sent to.

=item get_request_diagnose_url

Same as C<get_request_url> except this function
returns the diagnose version of it.

=item b64_signature XML_CART

Given a shopping cart (in XML), returns the
HMAC-SHA1 / Base64 signature of it.

=item b64_xml_cart XML_CART

Given a shopping cart (in XML), encode and 
return it in Base64.

=item get_xml_and_signature CART

Given a C<Google::Checkout::General::ShoppingCart> object CART, return the
Base64 encoding signature and XML cart. The return
value is a hash reference where 'xml' is the XML
cart (Base64 encoded) and 'signature' is the Base64 
encoding signature.

=item checkout CART, DIAGNOSE

Sends the shopping cart (C<Google::Checkout::General::ShoppingCart> object) to 
Google Checkout. If DIAGNOSE is true, the cart will be sent
as a diagnose request.

=item checkout_with_xml CART, DIAGNOSE

Sends the shopping cart (C<Google::Checkout::General::ShoppingCart> object) to 
Google Checkout. If DIAGNOSE is true, the cart will be sent
as a diagnose request.  This method returns both the result and the xml request that was sent to Google Checkout.

=item raw_checkout XML, DIAGNOSE

Treat XML as a shopping cart and attempt to checkout it. If
DIAGNOSE is true, the XML will be sent as a diagnose request.
This method is actually used by C<checkout>.

=item command COMMAND, DIAGNOSE

Sends a command to Google Checkout. COMMAND should be one of
C<Google::Checkout::Command::GCOCommand>'s sub-class. If DIAGNOSE 
is true, the command will be sent as a diagnose request.

=item send_notification_response

After you receive a notification, you are expected to send
back a response knowledging the notification is properly handled.
This method can be used to ensure a valid response is send back
to Google Checkout. Since we are communicating over HTTP, this
function will return a 200 header first.

=item send_merchant_calculation CALCULATIONS

This function is similar to C<send_notification_response> except
it's used to send back a response after a merchant calculation
callback. CALCULATIONS should be an array reference of 
C<Google::Checkout::General::MerchantCalculationResult>. 

=item send HASH

A generic function to send request to Google Checkout. Please note
that it's not recommanded that you use this function directly. C<checkout>,
C<command>, C<send_notification_response>, etc should be all you need
to interact with the Google Checkout system.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=cut

#--
#-- Class to interact with the GCO system
#--

use strict;
use warnings;

use CGI;
use Google::Checkout::General::Error;
use LWP 5.64;
use XML::Simple;
use Crypt::SSLeay;
use Google::Checkout::General::ConfigReader;
use HTTP::Request;
use HTTP::Headers;
use Google::Checkout::XML::Constants;
use Google::Checkout::XML::CommandXmlWriter;
use Google::Checkout::XML::CheckoutXmlWriter;
use Google::Checkout::General::MerchantCalculationResults;
use Google::Checkout::XML::NotificationResponseXmlWriter;
use Google::Checkout::General::Util qw/is_gco_error compute_hmac_sha1 compute_base64/;

#--
#-- Version. This is the version number of the whole sample
#-- code. Thus, everytime we make a bug fix or release a new
#-- version of any code, this number if increased.
#--
#-- NOTE: Please do NOT change this number! This is in fact
#--       a special variable that Perl tracks. It allows us
#--       to ask for a specify version of the sample code. 
#--       For example, if we add a feature to the sample code
#--       which is only available to the newest version of GCO,
#--       the user can say "use GCO 2.0;' which will reject this
#--       version of the library. 
#--
our $VERSION = "1.1.1";

sub new 
{
  my ($class, %args) = @_;

  my $self = {_reader => undef};

  if ($args{config_path}) {

    #--
    #-- have a configuration? if so, use it
    #--
    $self->{_reader} = Google::Checkout::General::ConfigReader->new(
                       {config_path => $args{config_path}});

  } elsif ($args{merchant_id} && $args{merchant_key} && $args{gco_server}) {

    #--
    #-- config is passed in
    #--
    $self->{__merchant_id}     = $args{merchant_id};
    $self->{__merchant_key}    = $args{merchant_key};
    $self->{__base_gco_server} = $args{gco_server};

    #--
    #-- if user supply the following, use them. otherwise, use default
    #--
    $self->{__xml_schema}         = $args{xml_schema} || 'http://checkout.google.com/schema/2';
    $self->{__currency_supported} = $args{currency_supported} || 'USD';
    $self->{__xml_version}        = $args{xml_version} || '1.0';
    $self->{__xml_encoding}       = $args{xml_encoding} || 'UTF-8';

  } else {

    #--
    #-- try a default configuration
    #--

    $self->{_reader} = Google::Checkout::General::ConfigReader->new;
  }

  return bless $self => $class;
}

sub reader 
{ 
  my ($self) = @_;

  return $self->{_reader}; 
}

sub get_checkout_url          
{ 
  my ($self) = @_;

  return $self->_get_url('merchantCheckout');

  #--
  #-- TODO: the following will go away on July 2007
  #--
  return $self->_get_url("checkout");    
}

sub get_checkout_diagnose_url 
{ 
  my ($self) = @_;

  return $self->_get_url('merchantCheckout');

  #--
  #-- TODO: the following will go away on July 2007
  #--
  return $self->_get_url("checkout", 1); 
}

sub get_request_url          
{ 
  my ($self) = @_;

  return $self->_get_url("request");    
}

sub get_request_diagnose_url 
{ 
  my ($self) = @_;

  return $self->_get_url("request", 1); 
}

#--
#-- Return the HMAC-SHA1 / Base64 signature
#--
sub b64_signature
{
  my ($self, $cart) = @_; #-- $cart = Shopping cart in XML
 
  my $id = '';
  if ($self->reader()) {
    $id = $self->reader()->get(Google::Checkout::XML::Constants::MERCHANT_KEY);
  } else {
    $id = $self->{__merchant_key} || Google::Checkout::General::Error(-1, "Missing merchant key");
  }
 
  return is_gco_error($id) ? $id : compute_hmac_sha1($id, $cart, 1);
}

#--
#-- Return Base64 cart XML
#--
sub b64_xml_cart
{
  my ($self, $cart) = @_; #-- $cart = Shopping cart in XML

  return compute_base64($cart);
}

#--
#-- Return the cart XML as well as base64 encoded signature
#--
sub get_xml_and_signature
{
  my ($self, $cart) = @_;

  my $xml = Google::Checkout::XML::CheckoutXmlWriter->new(gco => $self, cart => $cart)->done;

  my $signature = $self->b64_signature($xml);

  my $merchant_key = '';
  if ($self->reader()) {
    $merchant_key = $self->reader()->get(Google::Checkout::XML::Constants::MERCHANT_KEY);
  } else {
    $merchant_key = $self->{__merchant_key};
  }

  return {xml => compute_base64($xml), signature => $signature,
          raw_xml => $xml, 
          raw_key => $merchant_key};
}

#--
#-- Sends a shopping cart to GCO for checkout
#--
sub checkout_with_xml
{
  my ($self, $cart, $diagnose) = @_;

  my $xml = Google::Checkout::XML::CheckoutXmlWriter->new(gco => $self, cart => $cart)->done;

  return (($self->raw_checkout($xml, $diagnose)),$xml);
}

#--
#-- Same as above, but it doesn't return the XML for backwards compatibility
#--
sub checkout
{
  my ($self, $cart, $diagnose) = @_;

  my ($result,$xml) = $self->checkout_with_xml($cart, $diagnose);

  return $result
}

#--
#-- This is exactly the same as $gci->checkout except
#-- that the user is expected to pass in a XML file.
#-- The XML file will be passed to GCO directly
#--
sub raw_checkout
{
  my ($self, $xml, $diagnose) = @_;

  my $url = $diagnose ? $self->get_checkout_diagnose_url :
                        $self->get_checkout_url();

  my $response = $self->send(url  => $url,
                             cart => $xml);

  return $response if is_gco_error($response);

  return $diagnose ? 
           '' :  #-- Normally GCO returns a 200 OK only           
           $self->_extract_redirect_url($response);
}

#--
#-- Sends a command to GCO
#--
sub command
{
  my ($self, $command, $diagnose) = @_;

  my $url = $diagnose ? $self->get_request_diagnose_url : 
                        $self->get_request_url();

  my $response = $self->send(url  => $url,
                             cart => $command->to_xml(gco => $self));

  return $response;
}

#--
#-- Returns a 200 to GCO after receiving a notification. 
#-- The header will be text/xml and the body will always 
#-- be a valid notification response
#--
sub send_notification_response
{
  my ($self) = @_;

  #--
  #-- Send back xml header
  #--
  print CGI->header(-type => "text/xml", -charset => "utf-8");
  
  #--
  #-- Now send the response
  #--
  print Google::Checkout::XML::NotificationResponseXmlWriter->new(gco => $self)->done;
}

#--
#-- Returns a merchant calculation resutls back to GCO
#--
sub send_merchant_calculation
{
  #--
  #-- $results = Array reference of MerchantCalculationResult
  #--
  my ($self, $results) = @_;

  #--
  #-- Send back xml header
  #--
  print CGI->header(-type => "text/xml", -charset => "utf-8");

  print Google::Checkout::General::MerchantCalculationResults->new(
          gco => $self,
          merchant_calculation_result => $results)->done;
}

#--
#-- Send request to GCO using HTTP Basic Authentication. Note
#-- that users do not have to use this function directly. It's
#-- safer to use either the 'checkout' or the 'command' API instead
#--
sub send
{
  my ($self, %args) = @_;

  my $id = '';
  my $key = '';

  if ($self->reader()) {
    $id  = $self->reader()->get(Google::Checkout::XML::Constants::MERCHANT_ID);
    $key = $self->reader()->get(Google::Checkout::XML::Constants::MERCHANT_KEY);
  } else {
    $id = $self->{__merchant_id} || Google::Checkout::General::Error(-1, "Missing merchant ID");
    $key = $self->{__merchant_key} || Google::Checkout::General::Error(-1, "Missing merchant key");
  }

  return $id  if is_gco_error($id);
  return $key if is_gco_error($key);

  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{INVALID_MERCHANT_ID}})  
      unless $id;

  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{INVALID_MERCHANT_KEY}}) 
      unless $key;

  #--
  #-- URL and shopping cart (in XML format) is required
  #--
  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{MISSING_URL}})  
      unless $args{url};

  return Google::Checkout::General::Error->new(
    @{$Google::Checkout::General::Error::ERRORS{MISSING_CART}}) 
      unless $args{cart};

  return $self->raw_send(signature => compute_base64("$id:$key"),
                         url       => $args{url},
                         cart      => $args{cart});
}

sub raw_send
{
  my ($self, %args) = @_;

  my $agent = LWP::UserAgent->new;

  my $header  = HTTP::Headers->new;
     $header->header('Authorization' => "Basic " . $args{signature});
     $header->header('Content-Type'  => "application/xml; charset=UTF-8");
     $header->header('Accept'        => "application/xml");

  my $request = HTTP::Request->new(POST => $args{url}, $header, $args{cart});
  my $response = $agent->request($request);

  unless ($response->is_success) {
    return Google::Checkout::General::Error->new(
             $response->code,
             $response->status_line . $response->content);
  }

  return $response->content;
}

#-- PRIVATE --#

#--
#-- Returns either the checkout or request URL 
#--
sub _get_url
{
  my ($self, $type, $diagnose) = @_;

  my $url = Google::Checkout::General::Error->new(-1, 'Missing URL');
  my $mid = Google::Checkout::General::Error->new(-1, 'Missing merchant ID');

  if ($self->reader()) {
    $url = $self->reader()->get(Google::Checkout::XML::Constants::BASE_GCO_SERVER);
    $mid = $self->reader()->get(Google::Checkout::XML::Constants::MERCHANT_ID);
  } else {
    $url = $self->{__base_gco_server} || Google::Checkout::General::Error->new(-1, 'Missing URL');
    $mid = $self->{__merchant_id} || Google::Checkout::General::Error->new(-1, 'Missing merchant ID');
  }

  return $url if is_gco_error($url);
  return $mid if is_gco_error($mid);

  if ($self->reader()) {
    $url =~ s#/+$##;
    $url .= '/' . $mid . '/' . $type;
  }

  $url .= '/diagnose' if $diagnose;

  return $url;
}

#--
#-- Extract the redirect URL after posting
#-- to the GCO server of a checkout request.
#-- Returns Google::Checkout::General::Error if the XML file isn't 
#-- not a valid "success" XML file
#--
sub _extract_redirect_url
{
  my ($self, $xml) = @_;

  my $parser = XMLin($xml);

  my $url = $parser->{Google::Checkout::XML::Constants::REDIRECT_URL}; 

  return $url if $url;

  return Google::Checkout::General::Error->new(
           $Google::Checkout::General::Error::ERRORS{INVALID_XML}->[0],
           $Google::Checkout::General::Error::ERRORS{INVALID_XML}->[1] . ": $xml");
}

sub _has_error
{
  my ($self, $xml) = @_;

  my $parser = XMLin($xml);

  my $error = $parser->{Google::Checkout::XML::Constants::ERROR_MESSAGE};

  return $error ? 1 : 0;
}

1;
