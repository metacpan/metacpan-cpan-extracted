#!/opt/local/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::General::MerchantItem;
use Google::Checkout::General::ShoppingCart;
use Google::Checkout::XML::CheckoutXmlWriter;
use Google::Checkout::General::MerchantCheckoutFlow;
use Google::Checkout::General::ShippingRestrictions;
use Google::Checkout::General::AddressFilters;
use Google::Checkout::General::Pickup;
use Google::Checkout::General::FlatRateShipping;
use Google::Checkout::General::MerchantCalculatedShipping;
use Google::Checkout::General::TaxRule;
use Google::Checkout::General::TaxTable;
use Google::Checkout::General::TaxTableAreas;
use Google::Checkout::General::MerchantCalculations;
use Google::Checkout::General::ParameterizedUrl;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- The following example shows how to perform a CBG checkout 
#-- using various objects. The purpose of the code below is
#-- to demostrate the usage of all the objects but logic wise,
#-- it's probably not something a typical merchant will do
#--

my $config = $ARGV[0] || "../conf/GCOSystemGlobal.conf";

my $gco = Google::Checkout::General::GCO->new(config_path => $config);

#--
#-- Create some shipping restrictions. The followings says we 
#-- can ship to CA (the state) and all EU countries.
#-- We have a very handy constant EU_COUNTRIES for that.
#--
my $restriction = Google::Checkout::General::ShippingRestrictions->new(
                  allowed_state => ["CA"],
                  allowed_postal_area => [Google::Checkout::XML::Constants::EU_COUNTRIES]);

#--
#-- Create some address filters. The followings says we 
#-- can ship to CA (the state) and all EU countries but not MI and IL.
#-- In this case, since we want to further limit some of the EU countries
#-- in the postal code level, we have to spell out all the countries
#-- in an array of hashes.
#--
my $address_filters = Google::Checkout::General::AddressFilters->new(
                      allowed_state => ["CA"],
                      allowed_postal_area => [{country_code => 'AT', postal_code_pattern => '123*'},
                                              {country_code => 'BE'},
                                              {country_code => 'BG'},
                                              {country_code => 'CY'},
                                              {country_code => 'CZ'},
                                              {country_code => 'DK'},
                                              {country_code => 'EE'},
                                              {country_code => 'FI'},
                                              {country_code => 'FR'},
                                              {country_code => 'DE'},
                                              {country_code => 'GR'},
                                              {country_code => 'HU'},
                                              {country_code => 'IE'},
                                              {country_code => 'IT', postal_code_pattern => 'AB*'},
                                              {country_code => 'LV'},
                                              {country_code => 'LT'},
                                              {country_code => 'LU'},
                                              {country_code => 'MT'},
                                              {country_code => 'NL'},
                                              {country_code => 'PL'},
                                              {country_code => 'PT'},
                                              {country_code => 'RO'},
                                              {country_code => 'SK'},
                                              {country_code => 'SI'},
                                              {country_code => 'ES'},
                                              {country_code => 'SE'},
                                              {country_code => 'UK', postal_code_pattern => 'SW*'}],
                      excluded_state => ["MI", "IL"]);

#--
#-- Create a custom shipping method with the above 
#-- shipping restriction for a total of $45.99
#--
my $custom_shipping = Google::Checkout::General::MerchantCalculatedShipping->new(
                      price         => 45.99,
                      restriction   => $restriction,
                      address_filters => $address_filters,
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
#-- Create yet another tax rule that uses postal area
#--
my $tax_rule4 = Google::Checkout::General::TaxRule->new(
                shipping_tax => 1,
                rate => 0.025,
                area => Google::Checkout::General::TaxTableAreas->new(
                        postal => [{country_code => 'US', postal_code_pattern => '940*'}]));

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
                 rules => [$tax_rule2, $tax_rule4]);

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
#-- Create a parameterized URL object so we can track the order
#--
my $purl1 = Google::Checkout::General::ParameterizedUrl->new(
            url => 'http://www.yourcompany.com/tracking?parter=123&amp;partnerName=Company',
            url_params => {orderID => 'order-id', totalCost => 'order-total'});

#--
#-- Add a couple more params
#--
$purl1->set_url_param(taxes => 'tax-amount');
$purl1->set_url_param(shipping => 'shipping-amount');

#--
#-- Create another parameterized URL object
#--
my $purl2 = Google::Checkout::General::ParameterizedUrl->new(
            url => 'http://www.doubleclick.com/tracking?parter=123&amp;partnerName=Company',
            url_params => {orderID => 'order-id', totalCost => 'order-total'});

#--
#-- Add a couple more params
#--
$purl2->set_url_param(other => 'something');

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
                    shipping_method       => [$custom_shipping],
                    edit_cart_url         => "http://edit/cart/url",
                    continue_shopping_url => "http://continue/shopping/url",
                    buyer_phone           => 'true',
                    tax_table             => [$tax_table1,$tax_table2],
                    merchant_calculation  => $merchant_calculation,
                    parameterized_urls    => [$purl1, $purl2]);

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
#-- Now checkout out...
#--
my $response = ($gco->checkout_with_xml($cart))[0];

#--
#-- Check for error
#--
die $response if is_gco_error($response);

#--
#-- No error, the redirect URL is returned to us
#--
print $response,"\n";
