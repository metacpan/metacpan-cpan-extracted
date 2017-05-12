#!/usr/bin/perl

use Business::FedEx::ShipRequest;

my $date = '20001005';  #yyyymmdd
my $fe = Business::FedEx::ShipRequest->new(
	      				transaction_id => '12345678',
	      				account_number => '123456789',
	      				weight => '10',
	      				weight_units =>'LBS',
	      				service => '1',
	      				special_services => '',
	      				ship_date => $date,
	      				declared_value => '',
	      				cod_flag => 'N',
	      				cod_amount => '',
	      				cod_cashiers_check => '',
	      				special_services => 'NNNNNNNNNNNNN',
	      				dry_ice_weight => '',
	      				meter_number => '1234567',

	      				shipper_name => 'name',
	      				shipper_company => 'company',
	      				shipper_address1 => '61 ship Street',
	      				shipper_address2 => '',
	      				shipper_city => 'city',
	      				shipper_zip_code => '54321',
	      				shipper_state => 'NY',
	      				shipper_phone => '123-987-1177',
	      
	      				dest_company => 'none',
	      				dest_address1 => '23 myway',
	      				dest_address2 => '',
	      				dest_city => 'boston',
	      				dest_zip_code => '02115',
	      				dest_state => 'MA',
	      				dest_phone => '617-111-2222',
	      				recipient_department => 'my dept',
	      				payor_account_number => '123456789',
	      				payment_code => '1',
	      				reference_info => '',
	      				signature_release_flag => 'N',
	      				dest_country_code => 'US');
	      

$fe->rate('yo', 'hey','http://10.2.0.2:9500/cgi-bin/fedex.pl');

$data = $fe->get_data('net_charge');

print "$data, Done\n";
