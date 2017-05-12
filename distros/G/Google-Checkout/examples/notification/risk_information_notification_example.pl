#!/usr/bin/perl -w
use strict;

use Google::Checkout::General::GCO;
use Google::Checkout::Notification::RiskInformation;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/is_gco_error/;

#--
#-- User normally receive the XML from Checkout
#--
my $xml = $ARGV[0] || "xml/risk_information_notification.xml";

my $risk_information = Google::Checkout::Notification::RiskInformation->new(xml => $xml);
die $risk_information if is_gco_error $risk_information;

my $contact  = Google::Checkout::XML::Constants::BUYER_CONTACT_NAME;
my $company  = Google::Checkout::XML::Constants::BUYER_COMPANY_NAME;
my $email    = Google::Checkout::XML::Constants::BUYER_EMAIL;
my $phone    = Google::Checkout::XML::Constants::BUYER_PHONE;
my $fax      = Google::Checkout::XML::Constants::BUYER_FAX;
my $address1 = Google::Checkout::XML::Constants::BUYER_ADDRESS1;
my $address2 = Google::Checkout::XML::Constants::BUYER_ADDRESS2;
my $city     = Google::Checkout::XML::Constants::BUYER_CITY;
my $region   = Google::Checkout::XML::Constants::BUYER_REGION;
my $zip_code = Google::Checkout::XML::Constants::BUYER_POSTAL_CODE;
my $country  = Google::Checkout::XML::Constants::BUYER_COUNTRY_CODE;

print <<__RISK_INFORMATION__;
#-------------------------#
#    Risk information     #
#-------------------------#
Eligible for protection: @{[$risk_information->eligible_for_protection]}
AVS code:                @{[$risk_information->get_avs_response]}
CVN code:                @{[$risk_information->get_cvn_response]}
Partial CC number:       @{[$risk_information->get_partial_cc_number]}
Buyer account age:       @{[$risk_information->get_buyer_account_age]}
Buyer IP address:        @{[$risk_information->get_buyer_ip_address]}

Billing info:
Contact:  @{[$risk_information->get_buyer_info($contact)]}
Company:  @{[$risk_information->get_buyer_info($company)]}
Email:    @{[$risk_information->get_buyer_info($email)]}
Phone:    @{[$risk_information->get_buyer_info($phone)]}
Fax:      @{[$risk_information->get_buyer_info($fax)]}
Address1: @{[$risk_information->get_buyer_info($address1)]}
Address2: @{[$risk_information->get_buyer_info($address2)]}
City:     @{[$risk_information->get_buyer_info($city)]}
Region:   @{[$risk_information->get_buyer_info($region)]}
Zip code: @{[$risk_information->get_buyer_info($zip_code)]}
Country:  @{[$risk_information->get_buyer_info($country)]}


__RISK_INFORMATION__
