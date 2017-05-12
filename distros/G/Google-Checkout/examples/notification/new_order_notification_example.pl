#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Notification::NewOrder;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- User normally receive the XML from Checkout
#--
my $xml = $ARGV[0] || "xml/new_order_notification.xml";

my $new_order = Google::Checkout::Notification::NewOrder->new(xml => $xml);
die $new_order if is_gco_error $new_order;

#--
#-- First got all the items
#--
my $items = $new_order->get_items();

for my $item (@$items)
{
  #--
  #-- $private is a array reference
  #--
  my $private = $item->get_private;

  print <<__ONE_ITEM__;
Item:
ID:           @{[$item->get_merchant_item_id]}
Name:         @{[$item->get_name]}
Description:  @{[$item->get_description]}
Price:        @{[$item->get_price]}
Quantity:     @{[$item->get_quantity]}
Private data: @$private
Tax table:    @{[$item->get_tax_table_selector]}

__ONE_ITEM__

}

my $serial_number = $new_order->get_serial_number;
my $order_number  = $new_order->get_order_number;
my $time_stamp    = $new_order->get_timestamp;
my $ful_state     = $new_order->get_fulfillment_state;
my $fin_state     = $new_order->get_financial_state;
my $email_allowed = $new_order->marketing_email_allowed;
my $calculation_s = $new_order->merchant_calculation_successful;
my $total_tax     = $new_order->get_total_tax;
my $adjust_total  = $new_order->get_adjustment_total;
my $gc_cal_amount = $new_order->get_gift_certificate_calculated_amount;
my $gc_app_amount = $new_order->get_gift_certificate_applied_amount;
my $gc_cer_code   = $new_order->get_gift_certificate_code;
my $gc_cer_pin    = $new_order->get_gift_certificate_pin;
my $gc_message    = $new_order->get_gift_certificate_message;
my $cu_cal_amount = $new_order->get_coupon_calculated_amount;
my $cu_app_amount = $new_order->get_coupon_applied_amount;
my $cu_code       = $new_order->get_coupon_code;
my $cu_message    = $new_order->get_coupon_message;
my $shipping_name = $new_order->get_shipping_name || '';
my $shipping_cost = $new_order->get_shipping_cost;
my $cart_expire   = $new_order->get_cart_expiration;
my $merchant_data = $new_order->get_merchant_private_data;
my $shipping_meth = $new_order->get_shipping_method;

print <<__NEW_ORDER__;
#------------------#
#    New order     #
#------------------#
Serial number:                      $serial_number
Order number:                       $order_number
Timestamp:                          $time_stamp
Fulfillment state:                  $ful_state
Financial state:                    $fin_state
Email allowed:                      $email_allowed
Merchant calculation successful:    $calculation_s
Total tax:                          $total_tax
Adjustment total:                   $adjust_total
Gift certificate calculated amount: $gc_cal_amount
Gift certificate applied amount:    $gc_app_amount
Gift certificate code:              $gc_cer_code
Guft certificate PIN:               $gc_cer_pin
Gift certificate message:           $gc_message
Coupon calculated amount:           $cu_cal_amount
Coupon applied amount:              $cu_app_amount
Coupon code:                        $cu_code
Coupon message:                     $cu_message
Name of shipping method:            $shipping_name
Shipping cost:                      $shipping_cost
Cart expiration:                    $cart_expire
Merchant private data:              $merchant_data
Shipping method:                    $shipping_meth

Shipping info:
Contact:  @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_CONTACT_NAME)]}
Company:  @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_COMPANY_NAME)]}
Email:    @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_EMAIL)]}
Phone:    @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_PHONE)]}
Fax:      @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_FAX)]}
Address1: @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_ADDRESS1)]}
Address2: @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_ADDRESS2)]}
City:     @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_CITY)]}
Region:   @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_REGION)]}
Zip code: @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_POSTAL_CODE)]}
Country:  @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_SHIPPING,
                                        Google::Checkout::XML::Constants::BUYER_COUNTRY_CODE)]}

Billing info:
Contact:  @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_CONTACT_NAME)]}
Company:  @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_COMPANY_NAME)]}
Email:    @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_EMAIL)]}
Phone:    @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_PHONE)]}
Fax:      @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_FAX)]}
Address1: @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_ADDRESS1)]}
Address2: @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_ADDRESS2)]}
City:     @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_CITY)]}
Region:   @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_REGION)]}
Zip code: @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_POSTAL_CODE)]}
Country:  @{[$new_order->get_buyer_info(Google::Checkout::XML::Constants::GET_BILLING,
                                        Google::Checkout::XML::Constants::BUYER_COUNTRY_CODE)]}


__NEW_ORDER__
