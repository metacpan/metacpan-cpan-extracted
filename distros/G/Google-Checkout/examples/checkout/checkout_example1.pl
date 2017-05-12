#!/usr/bin/perl -w 
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::General::MerchantItem;
use Google::Checkout::General::DigitalContent;
use Google::Checkout::General::ShoppingCart;
use Google::Checkout::XML::CheckoutXmlWriter;
use Google::Checkout::General::MerchantCheckoutFlow;
use Google::Checkout::General::ShippingRestrictions;
use Google::Checkout::General::Pickup;
use Google::Checkout::General::FlatRateShipping;
use Google::Checkout::General::MerchantCalculatedShipping;
use Google::Checkout::General::TaxRule;
use Google::Checkout::General::TaxTable;
use Google::Checkout::General::TaxTableAreas;
use Google::Checkout::General::MerchantCalculations;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- The following example shows how to perform a CBG checkout.
#-- The example here is simplified. For a more complicated example,
#-- please see gco_checkout_example2.pl.
#--

my $config = $ARGV[0] || "../conf/GCOSystemGlobal.conf";

#--
#-- Create a CBG object so we can interact with the CBG system
#--
my $gco = Google::Checkout::General::GCO->new(config_path => $config);

#--
#-- Create a shopping cart that will expire in 1 month
#--
my $cart = Google::Checkout::General::ShoppingCart->new(
           expiration    => "+1 month",
           private       => "Simple shopping cart");

#--
#-- Now we create a merchant item.
#--
my $item = Google::Checkout::General::MerchantItem->new(
           name     => "Fish",
           description => "A fish" ,
           price       => 12.34,
           quantity    => 12,
           private     => "gold");

#--
#-- Digital content
#--
my $digital = Google::Checkout::General::DigitalContent->new(
              name            => "Digital",
              description     => "Requires key to download",
              price           => 19.99,
              quantity        => 1,
              delivery_method => Google::Checkout::General::DigitalContent::KEY_URL_DELIVERY,
              key             => 1234,
              url             => 'http://download/url');

$cart->add_item($digital);

#--
#-- We add the item to the cart
#--
$cart->add_item($item);

#--
#-- Add another item to the cart
#--
$cart->add_item(Google::Checkout::General::MerchantItem->new(
                name     => "Coral",
                description => "A coral",
                price       => 99.99,
                quantity    => 1,
                private     => "green"));

#--
#-- Now checkout...
#--
my $response = $gco->checkout($cart);

#--
#-- Check for error
#--
die $response if is_gco_error($response);

#--
#-- No error, the redirect URL is returned to us
#--
print $response,"\n";
