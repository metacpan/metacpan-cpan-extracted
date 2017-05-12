#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::General::MerchantCalculationCallback;
use Google::Checkout::General::MerchantCalculationResults;
use Google::Checkout::General::MerchantCalculationResult;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

my $gco = Google::Checkout::General::GCO->new;

my $callback = Google::Checkout::General::MerchantCalculationCallback->new(
               xml => $ARGV[0] || "xml/merchant_calculation_callback.xml");
die $callback if is_gco_error $callback;

#--
#-- Get all the items from the callback xml
#--
my $items = $callback->get_items();

for my $item (@$items)
{
  #--
  #-- $private is a array reference
  #--
  my $private = $item->get_private;

  print <<__ONE_ITEM__;
Item:

Name:         @{[$item->get_name]}
ID:           @{[$item->get_merchant_item_id]}
Description:  @{[$item->get_description]}
Price:        @{[$item->get_price]}
Quantity:     @{[$item->get_quantity]}
Private:      @$private
Tax table:    @{[$item->get_tax_table_selector || '']}
__ONE_ITEM__

}

print <<__CALLBACK__;
#--------------------------------------#
#    Merchant calculation callback     #
#--------------------------------------#
Cart expiration:       @{[$callback->get_cart_expiration]}
Merchant private data: @{[$callback->get_merchant_private_data]}
Buyer ID:              @{[$callback->get_buyer_id]}
Buyer language:        @{[$callback->get_buyer_language]}   
Should tax:            @{[$callback->should_tax]}
Shipping methods:      @{$callback->get_shipping_methods}
Merchant code strings: @{$callback->get_merchant_code_strings}

__CALLBACK__

#--
#-- Show anonymous addresses
#--
my $addresses = $callback->get_addresses;

for my $address (@$addresses)
{
  print <<__ADDRESS__;
Address:      $address->{id}
Country code: $address->{country_code}
City:         $address->{city}
Postal code:  $address->{postal_code}
Region:       $address->{region}

__ADDRESS__
}

#--
#-- After we have shown the data that Checkout post to us, we need
#-- to do some calculation to figure out what the shipping cost
#-- should be. Normally, the business partner performs some custom
#-- calculation but here I am just going to hard code some values
#--

#--
#-- Get a list of coupons and gift certificates. It's up to
#-- the business partner to determin whether the code is a
#-- coupon or a gift certificate. We get back an array reference
#--
my $coupons_certificates = $callback->get_merchant_code_strings;

my (@coupons, @certificates);

for (@$coupons_certificates)
{
  #--
  #-- If the code has the string 'coupon' in it, assume it's a coupon code.
  #-- Partner might use a completely different rule to determine this
  #--
  if (/coupon/i)
  {
    push @coupons, $_;
  }
  else
  {
    push @certificates, $_;
  }
}

#--
#-- Print out each gift certification code and PINs
#--
my $gcs = $callback->get_merchant_code_strings_with_pin;
for my $i (@$gcs) {
  print "Gift certificate code: $i->{code}, PIN: $i->{pin}\n";
}

#--
#-- Create a merchant calculation result object. 
#-- All the coupon and certificate stuff are optional 
#--
my $mcr1 = Google::Checkout::General::MerchantCalculationResult->new(
             shipping_name                 => "SuperShip",
             address_id                    => $addresses->[0]->{id},
             total_tax                     => 45.34,
             shipping_rate                 => 0.045,
             shippable                     => 1,
             valid_coupon                  => 1,
             valid_certificate             => 1,
             coupon_calculated_amount      => 13.45,
             certificate_calculated_amount => 45.56,
             coupon_code                   => $coupons[0],
             certificate_code              => $certificates[0],
             coupon_message                => "coupon is valid",
             certificate_message           => "certificate is valid");

my $mcr2 = Google::Checkout::General::MerchantCalculationResult->new(
             shipping_name => "UPS",
             address_id    => $addresses->[1]->{id});

#--
#-- This sends the merchant calculation back to GCO. 
#-- Partner will likely run this in some sort of CGI 
#-- enviroment since it outputs a text/xml header as well
#--
$gco->send_merchant_calculation([$mcr1, $mcr2]);

print "\n\n";