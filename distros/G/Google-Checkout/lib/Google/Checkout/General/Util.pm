package Google::Checkout::General::Util;

=head1 NAME

Google::Checkout::General::Util

=head1 SYNOPSIS

  use Google::Checkout::General::Util qw/is_gco_error 
                 compute_hmac_sha1 compute_base64
                 date_time_string make_xml_safe is_merchant_item
                 is_shipping_method is_tax_table format_tax_rate
                 get_valid_carrier is_valid_buyer_info
                 is_gift_certificate_object is_digital_content/;

=head1 DESCRIPTION

Library contains a group of useful utility functions

=over 4

=item is_gco_error OBJECT

Returns true if OBJECT is an object (or sub-class) of C<Google::Checkout::General::Error>.
Returns false otherwise. Many functions reteurns C<Google::Checkout::General::Error>
to indicate error conditions so it's important to use this function
to check for them.

=item is_merchant_item OBJECT

Returns true if OBJECT is an object (or sub-class) of C<Google::Checkout::General::MerchantItem>.
Returns false otherwise. This function is used internally.

=item is_shipping_method OBJECT

Returns true if OBJECT is an object (or sub-class) of C<Google::Checkout::General::Shipping>.
Returns false otherwise. This function is used internally.

=item is_tax_table OBJECT

Returns true if OBJECT is an object (or sub-class) of C<Google::Checkout::General::TaxTable>.
Returns false otherwise. This function is used internally.

=item compute_hmac_sha1 DATA, B64

Compute HMAC SHA1 for DATA. If B64 is true, also encode it
in Base64 before returning.

=item compute_base64 DATA

Compute Base64 for DATA.

=item date_time_string DATE_TIME_STRING

Given a valid date/time string, return it in ISO 8601 UTC format.
If string is not a valid date/time string, C<Google::Checkout::General::Error> is returned.

=item make_xml_safe XML_DATA

Make XML_DATE safe to be used in a XML document. '&' is turned
into '&#x26;', '>' is turned into '&#x3e;' and '<' is turned into
'&#x3c;'.

=item format_tax_rate RATE

Make sure tax rate is in the right format. If RATE is less than 1,
it's already in the right form so it's returned without any change.
If RATE is equal to or greater than 1, it's assumed to be in percent
format (for example, 25 means 25%) in which case it's turned into
RATE / 100 (25 / 100 = 0.25).

=item get_valid_carrier CARRIER

Returns a valid carrier if CARRIER is valid. Returns C<Google::Checkout::General::Error>
otherwise. This function is used internally.

=item is_valid_buyer_info BUYER_INFO

This function is used internally.

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=cut

use strict;
use warnings;

use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/is_gco_error compute_hmac_sha1 compute_base64
                    date_time_string make_xml_safe is_merchant_item
                    is_shipping_method is_tax_table format_tax_rate
                    get_valid_carrier is_valid_buyer_info
                    is_gift_certificate_object is_digital_content
                    is_parameterized_url/;

use UNIVERSAL qw/isa/;

use Date::Manip;
use MIME::Base64;
use Digest::HMAC_SHA1;
use Google::Checkout::XML::Constants;

#--
#-- A small hash to hold all possible valid buyer info
#--
my %valid_buyer_info = ( Google::Checkout::XML::Constants::BUYER_CONTACT_NAME , 1, 
                         Google::Checkout::XML::Constants::BUYER_COMPANY_NAME , 1,
                         Google::Checkout::XML::Constants::BUYER_EMAIL        , 1, 
                         Google::Checkout::XML::Constants::BUYER_PHONE        , 1,
                         Google::Checkout::XML::Constants::BUYER_FAX          , 1, 
                         Google::Checkout::XML::Constants::BUYER_ADDRESS1     , 1,
                         Google::Checkout::XML::Constants::BUYER_ADDRESS2     , 1, 
                         Google::Checkout::XML::Constants::BUYER_CITY         , 1,
                         Google::Checkout::XML::Constants::BUYER_CITY         , 1, 
                         Google::Checkout::XML::Constants::BUYER_REGION       , 1,
                         Google::Checkout::XML::Constants::BUYER_POSTAL_CODE  , 1, 
                         Google::Checkout::XML::Constants::BUYER_COUNTRY_CODE , 1);

sub is_gco_error       
{ 
  my ($obj) = @_;

  return is_object($obj, "Google::Checkout::General::Error"); 
}

sub is_merchant_item   
{ 
  my ($obj) = @_;

  return is_object($obj, "Google::Checkout::General::MerchantItem"); 
}

sub is_shipping_method 
{ 
  my ($obj) = @_;

  return is_object($obj, "Google::Checkout::General::Shipping");
}

sub is_tax_table 
{ 
  my ($obj) = @_;

  return is_object($obj, "Google::Checkout::General::TaxTable");
}

sub is_gift_certificate_object
{
  my ($obj) = @_;

  return is_object($obj, "Google::Checkout::General::GiftCertificate");
}

sub is_digital_content
{
  my ($obj) = @_;

  return is_object($obj, "Google::Checkout::General::DigitalContent");
}

sub is_parameterized_url
{
  my ($obj) = @_;

  return is_object($obj, "Google::Checkout::General::ParameterizedUrl");
}

sub is_object
{  
  my ($obj, $name) = @_;

  return isa $obj, $name;
}

#--
#-- Given data ($data) and key ($key), compute the HMAC SHA1
#-- value. If $b64 is true, apply Base64 at the same time
#--
sub compute_hmac_sha1
{
  #--
  #-- $b64 = Apply Base64 at the same time?
  #--
  my ($key, $data, $b64) = @_;

  my $hmac = Digest::HMAC_SHA1->new($key);
     $hmac->add($data);

  my $secure = $b64 ? $hmac->b64digest : $hmac->digest;

  #--
  #-- pad with = if not multiple of 4
  #--
  while (length($secure) % 4) 
  {
    $secure .= '=';
  }

  return $secure;
}

#--
#-- Given data ($data), compute the Base64 encoding
#--
sub compute_base64
{
  my ($data) = @_;

  return encode_base64($data, "");
}

#--
#-- Returns a ISO 8601 UTC date string
#--
sub date_time_string
{
  my ($date_time) = @_;

  my $date = ParseDateString($date_time);
  
  return Google::Checkout::General::Error->new(
           $Google::Checkout::General::Error::ERRORS{INVALID_DATE_STRING}->[0],
           $Google::Checkout::General::Error::ERRORS{INVALID_DATE_STRING}->[1] . ": $date_time") 
    if (!$date);

  #--
  #-- Return in ISO 8601 UTC format: YYYY-MM-DDThh:mm:ssZ
  #--
  return UnixDate($date, "%Y-%m-%dT%H:%M:%SZ");
}

#--
#-- GCO requires special characters to be in hex
#-- form but XML::Writer generate the entity form
#-- so I encode them here myself
#--
sub make_xml_safe
{
  my ($data) = @_;

  if ($data)
  {
    $data =~ s/&/&#x26;/g;
    $data =~ s/>/&#x3e;/g;
    $data =~ s/</&#x3c;/g;
  }

  return $data;
}

sub format_tax_rate
{
  my ($number) = @_;

  #--
  #-- Number might already in the right format such as 0.04
  #--
  return $number if $number < 1;

  return $number / 100;
}

sub get_valid_carrier
{
  my ($carrier) = @_;

  return $carrier if ($carrier eq Google::Checkout::XML::Constants::DHL   ||
                      $carrier eq Google::Checkout::XML::Constants::FedEx ||
                      $carrier eq Google::Checkout::XML::Constants::UPS   ||
                      $carrier eq Google::Checkout::XML::Constants::USPS  ||
                      $carrier eq Google::Checkout::XML::Constants::Other);

  return Google::Checkout::General::Error->new(
           $Google::Checkout::General::Error::ERRORS{INVALID_CARRIER}->[0],
           $Google::Checkout::General::Error::ERRORS{INVALID_CARRIER}->[1] . ": $carrier");
}

sub is_valid_buyer_info
{
  my ($info) = @_;

  return 0 unless defined $info;

  return exists $valid_buyer_info{$info} &&
                $valid_buyer_info{$info};
}

1;
