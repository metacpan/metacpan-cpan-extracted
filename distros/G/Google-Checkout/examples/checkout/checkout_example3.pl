#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::General::MerchantItem;
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
#-- This example is the same as example 2 except it doesn't actuall
#-- perform a checkout. Instead, it prints out the XML, signature, 
#-- etc. This gives the user a chance to manually inspect the XML
#-- generated. Great for debug! 
#--

my $config = $ARGV[0] || "../conf/GCOSystemGlobal.conf";

my $gco = Google::Checkout::General::GCO->new(config_path => $config);

#--
#-- Create some shipping restrictions. The followings says we 
#-- can ship to CA (the state).
#--
my $restriction = Google::Checkout::General::ShippingRestrictions->new(
                  allowed_state => ["CA"]);

#--
#-- Create a custom shipping method with the above 
#-- shipping restriction for a total of $45.99
#--
my $custom_shipping = Google::Checkout::General::MerchantCalculatedShipping->new(
                      price         => 45.99,
                      restriction   => $restriction,
                      shipping_name => "custom shipping");

#--
#-- Create 2 more shipping methods: One for pickup 
#-- and the other flat rate shipping for $19.99. Notice 
#-- that it's common for the pickup method to not 
#-- include a price tag. It will be defaulted to 0 if 
#-- it's not supplied
#--
my $pickup_shipping    = Google::Checkout::General::Pickup->new(shipping_name => "Pickup");
my $flat_rate_shipping = Google::Checkout::General::FlatRateShipping->new(
                         shipping_name => "Flat rate UPS", 
                         price         => 19.99);

#--
#-- Now are are creating a tax rule. We set shipping 
#-- tax to the full 50 US states.
#--
my $tax_rule1 = Google::Checkout::General::TaxRule->new(
                shipping_tax => 1,
                rate => 0.025,
                area => Google::Checkout::General::TaxTableAreas->new(
                        country => [Google::Checkout::XML::Constants::FULL_50_STATES]));

#--
#-- We create another tax rule but we tell Checkout that shipping isn't taxable
#--
my $tax_rule2 = Google::Checkout::General::TaxRule->new(
                shipping_tax => 0,
                rate => 8.87,
                area => [Google::Checkout::General::TaxTableAreas->new(state => ['NY'])]);

#--
#-- Create yet another tax rule similar to the first one
#--
my $tax_rule3 = Google::Checkout::General::TaxRule->new(
                shipping_tax => 1,
                rate => 0.025,
                area => Google::Checkout::General::TaxTableAreas->new(
                        country => [Google::Checkout::XML::Constants::FULL_50_STATES]));

#--
#-- Now we have 3 tax rules created, we need to create 
#-- a tax table to hold them. Notice that we only add 
#-- rule1 and rule3 to the table but discarded rule2. Also 
#-- notice that default is set to 1. This tell Checkout that 
#-- this is the default tax table
#--
my $tax_table1 = Google::Checkout::General::TaxTable->new(
                 default => 1, 
                 rules => [$tax_rule1, $tax_rule3]);

#--
#-- We create another tax table with the name 'item'. 
#-- This is not a default table but we can reference 
#-- it using it's name
#--
my $tax_table2 = Google::Checkout::General::TaxTable->new(
                 default => 0,
                 name => "taxtable",
                 standalone => 1,
                 rules => [$tax_rule2]);

#--
#-- A merchant calculations object tells Checkout that we want to calculate
#-- the shipping expense using a custom algorithm. The URL specify
#-- the address that Checkout should call when it needs to find out the 
#-- shipping expense. We also specify that users can apply coupons and
#-- gift certificates to the shipping cost
#--
my $merchant_calculation = Google::Checkout::General::MerchantCalculations->new(
                             url => "http://callback/url",
                             coupons => 1,
                             certificates => 1);

#--
#-- Now it's time to create the checkout flow. 
#-- This particular checkout flow only supports the flat rate 
#-- shipping method (you can add more). Edit cart and continue 
#-- shopping URL specify 2 addresses: one for editing the cart 
#-- and another for when the user click the continue shopping link.
#-- The 2 tax tables (created above) is added and we tell Checkout what 
#-- we are interested in calculating our own shipping expense with 
#-- our own calculation. The buyer's phone number is also added
#--
my $checkout_flow = Google::Checkout::General::MerchantCheckoutFlow->new(
                    shipping_method       => [$flat_rate_shipping],
                    edit_cart_url         => "http://edit/cart/url",
                    continue_shopping_url => "http://continue/shopping/url",
                    buyer_phone           => "1-111-111-1111",
                    tax_table             => [$tax_table1,$tax_table2],
                    merchant_calculation  => $merchant_calculation,
		    analytics_data        => "SW5zZXJ0IDxhbmFseXRpY3MtZGF0YT4gdmFsdWUgaGVyZS4=",
                    platform_id           => 123456789);

#--
#-- Once the merchant checkout flow is created, we can create the shopping
#-- cart. The cart includes the checkout flow created above, it will expire
#-- in 1 month and we include a private message in the cart
#--
my $cart = Google::Checkout::General::ShoppingCart->new(
           expiration    => "+1 month",
           private       => "Any private data you want",
           checkout_flow => $checkout_flow);

#--
#-- Now we create a merchant item.
#--
my $item = Google::Checkout::General::MerchantItem->new(
           name               => "Fish",
           description        => "A fish" ,
           price              => 12.34,
           quantity           => 12,
           private            => "gold",
           tax_table_selector => $tax_table2->get_name());

#--
#-- We can the item to the cart
#--
$cart->add_item($item);

#--
#-- Add another item to the cart
#--
$cart->add_item(Google::Checkout::General::MerchantItem->new(
                name               => "Coral",
                description        => "A coral",
                price              => 99.99,
                quantity           => 1,
                private            => "green",
                tax_table_selector => $tax_table2->get_name()));

#--
#-- Get the signature and XML cart
#--
my $data = $gco->get_xml_and_signature($cart);

#--
#-- Print the XML and signature
#--
print "URL:       ",$gco->get_checkout_url,"\n",
      "Raw XML:   $data->{raw_xml}\n",
      "Key:       $data->{raw_key}\n",
      "Signature: $data->{signature}\n",
      "XML cart:  $data->{xml}\n";
