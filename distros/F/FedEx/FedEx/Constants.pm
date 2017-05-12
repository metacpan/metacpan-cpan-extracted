package Business::FedEx::Constants;
#Fedex/Constants.pm

use strict;
use warnings;

my @api = qw(WEBAPICLIENT
	     WEBAPIConnect
	     WEBAPIDisconnect
	     WEBAPITransaction
	     WEBAPISetLogFile
	     WEBAPISetLogMode
	     WEBAPISetTraceFile
	     WEBAPISetTraceMode
	     WEBAPISetReadTimeout
	     );

my @returns = qw(WEBAPI_OK
		 WEBAPI_COMM_ERROR
		 WEBAPI_TIMEOUT_ERROR
		 WEBAPI_SECURITY_ERROR
		 WEBAPI_NOT_REGISTERED_ERROR
		 WEBAPI_SERVICE_DOWN_ERROR
		 WEBAPI_BAD_SERVICE_ERROR
		 WEBAPI_DATA_LENGTH_ERROR
		 WEBAPI_NOT_INIT_ERROR
		 WEBAPI_NOT_CONNECT_ERROR
		 WEBAPI_BAD_AUTH_FILE
		 WEBAPI_NOT_SENDIND_ERROR
		 WEBAPI_BAD_PORT
		 WEBAPI_REOPEN_FAILURE
		 WEBAPI_NO_INI_FILE
		 WEBAPI_NO_ET_INI_FILE
		 WEBAPI_NO_HOST_ADDRESS
		 WEBAPI_ENCRYPT_ERROR
		 WEBAPI_CONF_ERROR
		 WEBAPI_RSPBUFF_ERROR
		 WEBAPI_LOCALSEC_ERROR
		 WEBAPI_REMOTSEC_ERROR
		 WEBAPI_PROXY_ERROR
		 WEBAPI_COMM_OPEN_ERROR
		 WEBAPI_INIT_ERROR
		 WEBAPI_INVALID_FILENAME
		 WEBAPI_FILE_OPEN_ERROR
		 WEBAPI_BUFFER_TOO_LARGE
		 WEBAPI_BUFFER_TOO_SMALL
		 WEBAPI_NOT_ACTIVATED
		 WEBAPI_PARSING_ERROR
		 WEBAPI_DECRYPT_ERROR
		 WEBAPI_UNK_MSG_TYPE
		 WEBAPI_DN_REVOKED
		 WEBAPI_LDAP_ERROR
		 WEBAPI_LDAP_ENTRY_NOT_FOUND
		 WEBAPI_VENDOR_PROD_NOT_ENABLED
		 lookup_errstr
		);

my @fedex_codes = qw(DEST_COMPANY
		     SHIP_DATE
		     DEST_ADDRESS1
		     DEST_ADDRESS2
		     PAYMENT_CODE
		     DRY_ICE_WEIGHT
		     WEIGHT_UNITS
		     REFERENCE_INFO
		     SERVICE
		     DEST_STATE
		     SHIPPER_STATE
		     COD_CASHIERS_CHECK
		     SIGNATURE_RELEASE_FLAG
		     DEST_ZIP_CODE
		     SHIPPER_CITY
		     PAYOR_ACCOUNT_NUMBER
		     SHIPPER_ADDRESS1
		     SHIPPER_ADDRESS2
		     SPECIAL_SERVICES
		     ACCOUNT_NUMBER
		     TRANSACTION_TYPE
		     DEST_CITY
		     METER_NUMBER
		     TRANSACTION_ID
		     SHIPPER_NAME
		     COD_AMOUNT
		     COD_FLAG
		     DEST_PHONE
		     SHIPPER_PHONE
		     WEIGHT
		     SHIPPER_COMPANY
		     SHIPPER_ZIP_CODE
		     DECLARED_VALUE
		     RECIPIENT_DEPARTMENT
		     GIF_LABEL
		     TRACKING_NUM
		     DEST_COUNTRY_CODE
		     ULT_DEST_COUNTRY_CODE
		     SHIPPER_COUNTRY_CODE
		     TRACKING_NUM
		     DEST_CONTACT_NAME
		     HAL_STATION_ADDRESS1
		     HAL_CITY
		     HAL_STATE
		     HAL_ZIP_CODE
		     PKG_HEIGHT
		     PKG_WIDTH
		     PKG_LENGTH
		     DIM_UNITS
		     FUTURE_DAY_SHIP
		     DUTIES_PAY_TYPE
		     DUTIES_ACCOUNT_NUM
		     PKG_DESCRIPTION
		     MANUFACTURE_COUNTRY_CODE		     
		     CURRENCY_TYPE
		     CARRIAGE_VALUE
		     UNIT_WEIGHT1
		     UNIT_VALUE1
		     QUANTITY1
		     UNIT_MEASURE1
		     LOCAL_SHIP_TIME
		     CUSTOMS_VALUE
		     EIN_NUM
		     COMMERCIAL_INVOICE_FLAG
		     HAL_PHONE
		    );
my @return_fe_codes = qw(FE0
			 FE1
			 FE3
			 FE21
			 FE28
			 FE29
			 FE30
			 FE33
			 FE34
			 FE35
			 FE36
			 FE37
			 FE60
			 FE65
			 FE188
			 FE194
			 FE195
			 FE409
			 FE411
			 FE431
			 FE526
			 FE99
			 FE1701
			 FE1704
			 FE1705
			 FE1706
			 FE1707
			 FE1709
			 FE1711
			 FE1710
			 FE1712
			 FE1713
			 FE1715
			 FE1718
			 FE1720
			 FE1721
			 FE1722
			 FE1723
			 FE1724
			 FE1725
			 FE1726
			 FE1727
			 FE1728
			 FE1729
			 FE1730
			 FE1731
			 FE1732
			 FE1733
			 FE1734
			 FE1735
		    );

my @log_modes = qw(WAPI_LOG_ERROR
		   WAPI_LOG_INFORM
		   WAPI_LOG_VERBOSE
		   WAPI_LOG_DEBUG
		  );

my @trace_modes = qw(WAPI_TRACE_OFF
		     WAPI_TRACE_ON
		    );

my @read_timeout = qw(WAPI_DEFAULT_TIMEOUT
		      );

my @all = (@api, @returns, @fedex_codes, @return_fe_codes, @log_modes, @trace_modes, @read_timeout);

our @ISA = qw(Business::FedEx);
our %EXPORT_TAGS = ( 'all'     => \@all,
		     'api'     => \@api,
		     'returns' => \@returns,
		     'fedex_codes' => \@fedex_codes,
		     'return_fe_codes' => \@fedex_codes,
		     'log_modes' => \@log_modes,
		     'trace_modes' => \@trace_modes,
		     'read_timeout' => \@read_timeout);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.01';

# returns the string equivalent of the error constant below
# please implement this somehow
sub lookup_errstr {
  return "ERROR--not implemented yet (need to type in error strings";
}

use constant WEBAPICLIENT => 'webapiclient';
use constant WEBAPIConnect => 'WEBAPIConnect';
use constant WEBAPIDisconnect => 'WEBAPIDisconnect';
use constant WEBAPITransaction => 'WEBAPITransaction';
use constant WEBAPISetLogFile => 'WEBAPISetLogFile';
use constant WEBAPISetLogMode => 'WEBAPISetLogMode';
use constant WEBAPISetTraceFile => 'WEBAPISetTraceFile';
use constant WEBAPISetTraceMode => 'WEBAPISetTraceMode';
use constant WEBAPISetReadTimeout => 'WEBAPISetReadTimeout';

#GENERIC
use constant WEBAPI_OK => 0 ;#Indicates successful WEBAPI function
use constant WEBAPI_COMM_ERROR => -1 ;# Generic communications error
use constant WEBAPI_TIMEOUT_ERROR => -2 ;# Generic timeout error
use constant WEBAPI_SECURITY_ERROR => -3 ;# Security violation error
use constant WEBAPI_NOT_REGISTERED_ERROR => -4 ;# Client is not registered error
use constant WEBAPI_SERVICE_DOWN_ERROR => -5 ;# FedEx Service is DOWN error
use constant WEBAPI_BAD_SERVICE_ERROR => -6 ;# FedEx Service is non-existent error
use constant WEBAPI_DATA_LENGTH_ERROR => -7 ;# Data len is too long or short error
use constant WEBAPI_NOT_INIT_ERROR => -8 ;# not inited yet, need to do

# a WEBAPIInit() 
use constant WEBAPI_NOT_CONNECT_ERROR => -9 ;#not connected yet, need to do
      
# a WEBAPIConnect() 
use constant WEBAPI_BAD_AUTH_FILE => -10 ;# Bad Authentication file       
use constant WEBAPI_NOT_SENDING_ERROR => -11 ;# not sending currently,need to     
      
#do WEBAPISend() 
use constant WEBAPI_BAD_PORT => -12 ;# Invalid Port Number          
use constant WEBAPI_REOPEN_FAILURE => -13 ;# failure to reopen the comm port   
use constant WEBAPI_NO_INI_FILE => -14 ;# no webapi.ini file found       
use constant WEBAPI_NO_ET_INI_FILE => -15 ;# no webapi.ini file found       
use constant WEBAPI_NO_HOST_ADDRESS => -16 ;# no FDXHOST variable in webapi.ini  
use constant WEBAPI_ENCRYPT_ERROR => -17 ;# Encryption package not working    
use constant WEBAPI_CONF_ERROR => -18 ;# Encryption package not working    
use constant WEBAPI_RSPBUFF_ERROR => -19 ;# Unable to locate response buffer   
use constant WEBAPI_LOCALSEC_ERROR => -20 ;# Local security init error      
use constant WEBAPI_REMOTSEC_ERROR => -21 ;# Remote security init error      
use constant WEBAPI_PROXY_ERROR => -22 ;# User name/Password Error       
use constant WEBAPI_COMM_OPEN_ERROR => -23 ;# cannot open the server port passed  
use constant WEBAPI_INIT_ERROR => -24 ;# Initialization in WEBAPIInit() failed,probably system resource error.                
use constant WEBAPI_INVALID_FILENAME => -25 ;# Filename is NULL or Zero length   
use constant WEBAPI_FILE_OPEN_ERROR => -26 ;# Unable to open log or trace file   
use constant WEBAPI_BUFFER_TOO_LARGE => -27 ;# Buffer passed to WEBAPISend() or WEBAPITransaction()is too large Max bytes allowed SHRT_MAX(32767)  
use constant WEBAPI_BUFFER_TOO_SMALL => -28 ;# Buffer passed to WEBAPIReceive() or WEBAPITransaction()is too small for message received. Max bytes allowed SHRT_MAX(32767)  
use constant WEBAPI_NOT_ACTIVATED => -29 ;#Software has been installed but has not been activated.         
use constant WEBAPI_PARSING_ERROR => -30 ;#Parsing Passport Buffer failed. It usually means that the data passed was not in Passport format.     
use constant WEBAPI_DECRYPT_ERROR => -31 ;#Decryption package not working       
use constant WEBAPI_UNK_MSG_TYPE => -32 ;#Unknown Client message type. This error will only occurr when passing an unknown message type to WEBAPISend().On the subsequent call to WEBAPIReceive() this error will be returned. Users should use WEBAPITransaction(). WEBAPI_UNK_ERROR_TYPE -33 #Unknown error code(this will go away WEBAPI_ADMIN_MSG -62 ;#Message must be sent to admin port
use constant WEBAPI_DN_REVOKED => -90 ;# This user certificate is revoked.
use constant WEBAPI_LDAP_ERROR => -91 ;# LDAP error on FedEx server side.   
use constant WEBAPI_LDAP_ENTRY_NOT_FOUND => -92 ;# LDAP entry not found on FedEx side. 
use constant WEBAPI_VENDOR_PROD_NOT_ENABLED => -93 ;# Vendor's software not enabled.    

#SOLO API Log Modes 
use constant WAPI_LOG_ERROR => 0;
use constant WAPI_LOG_INFORM => 1;
use constant WAPI_LOG_VERBOSE => 2;
use constant WAPI_LOG_DEBUG => 3;

#SOLO API Trace Modes 
use constant WAPI_TRACE_OFF => 0;
use constant WAPI_TRACE_ON => 1;

#SOLO API Default Read Timeout 
use constant WAPI_DEFAULT_TIMEOUT => 60;

#--/-FEDEX CODES-/------------------------------------------------#
use constant TRANSACTION_ID => 1;
use constant ACCOUNT_NUMBER => 10;
use constant WEIGHT => 21;
use constant WEIGHT_UNITS => 75;
use constant SERVICE => 22;
use constant SPECIAL_SERVICES => 39;
use constant SHIP_DATE => 24;
use constant DECLARED_VALUE => 26;
use constant COD_FLAG => 27;
use constant COD_AMOUNT => 53;
use constant COD_CASHIERS_CHECK => 54;
use constant SPECIAL_SERVICES => 39;
use constant DRY_ICE_WEIGHT => 43;
use constant METER_NUMBER => 498;

use constant SHIPPER_NAME => 32;
use constant SHIPPER_COMPANY => 4;
use constant SHIPPER_ADDRESS1 => 5;
use constant SHIPPER_ADDRESS2 => 6;
use constant SHIPPER_CITY => 7;
use constant SHIPPER_ZIP_CODE => 9;
use constant SHIPPER_STATE => 8;
use constant SHIPPER_COUNTRY_CODE => 117;
use constant SHIPPER_PHONE => 183;

use constant DEST_COMPANY => 12;
use constant DEST_ADDRESS1 => 13;
use constant DEST_ADDRESS2 => 14;
use constant DEST_CITY => 15;
use constant DEST_ZIP_CODE => 17;
use constant DEST_STATE => 16;
use constant DEST_COUNTRY_CODE => 50;
use constant ULT_DEST_COUNTRY_CODE => 74;
use constant DEST_PHONE => 18;
use constant RECIPIENT_DEPARTMENT => 1145;
use constant PAYOR_ACCOUNT_NUMBER => 20;
use constant PAYMENT_CODE => 23;
use constant REFERENCE_INFO => 25;
use constant SIGNATURE_RELEASE_FLAG => 51;
use constant GIF_LABEL => 187;
use constant TRACKING_NUM => 29;
use constant DEST_CONTACT_NAME => 12;
use constant HAL_STATION_ADDRESS1 => 44;
use constant HAL_CITY => 46;
use constant HAL_STATE => 47;
use constant HAL_ZIP_CODE => 48;
use constant HAL_PHONE =>49;
use constant PKG_HEIGHT => 57;
use constant PKG_WIDTH => 58;
use constant PKG_LENGTH => 59;
use constant DIM_UNITS => 1116;
use constant FUTURE_DAY_SHIP => 1119;
use constant DUTIES_PAY_TYPE => 70;
use constant DUTIES_ACCOUNT_NUM => 71;
use constant PKG_DESCRIPTION => 79;
use constant MANUFACTURE_COUNTRY_CODE => 80;

use constant CURRENCY_TYPE => 68;
use constant CARRIAGE_VALUE => 69;
use constant UNIT_WEIGHT1 => 77;
use constant UNIT_VALUE1 => 127;
use constant QUANTITY1 => 401;
use constant UNIT_MEASURE1 => 414;
use constant LOCAL_SHIP_TIME => 1115;
use constant CUSTOMS_VALUE => 26;
use constant EIN_NUM => 118;
use constant COMMERCIAL_INVOICE_FLAG => 113;

#--/-RETURN FEDEX CODES-/---------------------------------------#

use constant FE0 => 'transaction_type';
use constant FE1 => 'transaction_id';
use constant FE2 => 'error_code';
use constant FE3 => 'error_mesg';
use constant FE21 => 'weight';
use constant FE28 => 'cod_tracking_num';
use constant FE29 => 'tracking_num';
use constant FE30 => 'ursa_code';
use constant FE33 => 'service_area';
use constant FE34 => 'base_charge';
use constant FE35 => 'total_surcharge';
use constant FE36 => 'total_discount';
use constant FE37 => 'net_charge';
use constant FE60 => 'billed_weight';
use constant FE65 => 'astra_bar_code';
use constant FE188 => 'gif_label';
use constant FE194 => 'delivery_day';
use constant FE195 => 'routing_location_id';
use constant FE411 => 'cod_label';
use constant FE431 => 'dim_weight_used';
use constant FE526 => 'tracking_form_id';
use constant FE99 => 'transaction_term';
use constant FE1701 =>'tracking_status';
use constant FE1718 =>'package_type';
use constant FE1704 =>'service_type';
use constant FE1705 =>'delivery_description';
use constant FE1706 =>'signed_for';
use constant FE1707 =>'delivery_time';
use constant FE1709 =>'dispatch_exception';
use constant FE1710 =>'cartage_agent';
use constant FE1711 =>'status_exception';
use constant FE1712 =>'cod_ret_track_num';
use constant FE1713 =>'cod_flag';
use constant FE1715 =>'num_tracking_activities';
use constant FE1718 =>'pkg_type';
use constant FE1720 =>'delivery_date';
use constant FE1721 =>'track_1';
use constant FE1722 =>'track_2';
use constant FE1723 =>'track_3';
use constant FE1724 =>'track_4';
use constant FE1725 =>'track_5';
use constant FE1726 =>'track_6';
use constant FE1727 =>'track_7';
use constant FE1728 =>'track_8';
use constant FE1729 =>'track_9';
use constant FE1730 =>'track_10';
use constant FE1731 =>'track_11';
use constant FE1732 =>'track_12';
use constant FE1733 =>'track_13';
use constant FE1734 =>'track_14';
use constant FE1735 =>'track_15';

1;
__END__


=head1 NAME

Business::FedEx::Constants - Constants used by Business::FedEx::ShipRequest;

=head1 SYNOPSIS
 
Constants are used in the creation of a ShipRequest Object, and in a ShipRequest get_data() method.


=head1 API

=head1 DESCRIPTION

Two parts to this documentation:

1) SET FEDEX VALUES  -- used by ShipRequest->new() (for ship and rate...not track)

2) GET FEDEX VALUES  -- used by ShipRequest->get_data()


=head2 SET FEDEX VALUES:

              transaction_id=>'32826482',                #--/-REQUIRED - Any number you want - used for error tracking
	      account_number => '',                      #--/-REQUIRED - Your 9 digit FedEx Account number
	      weight => '',                              #--/-REQUIRED
	      weight_units =>'LBS',
	      service => '1',
	      special_services => '',
	      ship_date => '',
	      declared_value => '',
	      cod_flag => 'N',
	      cod_amount => '',
	      cod_cashiers_check => '',
	      special_services => 'NNNNNNNNNNNNN',
	      dry_ice_weight => '',
	      meter_number => '',                        #--/-REQUIRED - Your 7 digit FedEx meter number
	      gif_label => '400',
	      tracking_num => '',

	      shipper_name => '',                        #--/-REQUIRED - 
	      shipper_company => '',                      #--/-REQUIRED - 
	      shipper_address1 => '',                    #--/-REQUIRED - 
	      shipper_address2 => '',
	      shipper_city => '',                        #--/-REQUIRED - 
	      shipper_zip_code => '',                    #--/-REQUIRED - 
	      shipper_state => '',                       #--/-REQUIRED - 
	      shipper_phone => '',                       #--/-REQUIRED - 
	      
	      dest_company => '',                        #--/-REQUIRED - 
	      dest_address1 => '',                       #--/-REQUIRED - 
	      dest_address2 => '',
	      dest_city => '',                           #--/-REQUIRED - 
	      dest_zip_code => '',                       #--/-REQUIRED - 
	      dest_state => '',                          #--/-REQUIRED - 
	      dest_phone => '',                           #--/-REQUIRED - 
	      recipient_department => '',                
	      payor_account_number => '',                #--/-REQUIRED - 10 digit fedex account # of payor
	      payment_code => '1',                       #--/-REQUIRED - 
	      reference_info => '',
	      signature_release_flag => 'N',
	      #
	      hal_station_address1 => '',
	      hal_city => '',
	      hal_state => '',
	      hal_zip_code => '',
	      pkg_height => '',
	      pkg_width => '', 
	      pkg_length => '',
	      dim_units => '',
	      future_day_ship => '',
	      dest_country_code => 'US',
	      ult_dest_country_code => 'US',
	      shipper_country_code => 'US',
	      #INTERNATIONAL SHIPPING ONLY-------------------------------------------------                  
	      duties_pay_type => '',
	      duties_account_num => '',
	      pkg_description => '',
	      manufacture_country_code => '',
	      currency_type => '',
	      carriage_value => '',
	      unit_weight1 => '',
	      unit_value1 => '',
	      quantity1 => '',
	      unit_measure1 => '',
	      #local_ship_time => '',
	      customs_value => '',
	      ein_num => '',
	      commercial_invoice_flag => '',
	      hal_phone => '',







=head2 GET FEDEX VALUES:

You can get all the above values as well as the values listed below through Business::FedEx::ShipRequest->get_data('constant_name'):

 'transaction_type';
 'transaction_id';
 'error_code';
 'error_mesg';
 'weight';
 'cod_tracking_num';
 'tracking_num';
 'ursa_code';
 'service_area';
 'base_charge';
 'total_surcharge';
 'total_discount';
 'net_charge';
 'billed_weight';
 'astra_bar_code';
 'gif_label';
 'delivery_day';
 'routing_location_id';
 'cod_label';
 'dim_weight_used';
 'tracking_form_id';
 'transaction_term';
 'tracking_status';
 'package_type';
 'service_type';
 'delivery_description';
 'signed_for';
 'delivery_time';
 'dispatch_exception';
 'cartage_agent';
 'status_exception';
 'cod_ret_track_num';
 'cod_flag';
 'num_tracking_activities';
 'pkg_type';
 'delivery_date';
 'track_1';
 'track_2';
 'track_3';
 'track_4';
 'track_5';
 'track_6';
 'track_7';
 'track_8';
 'track_9';
 'track_10';
 'track_11';
 'track_12';
 'track_13';
 'track_14';
 'track_15';

Refer to the FedEx ShipAPI documentation.

=head2 EXPORT

None by default.

=head1 AUTHOR

Patrick Tully, ptully@avatartech.com

=head1 SEE ALSO

Business::FedEx

Business::FedEx::ShipRequest

Business::FedEx::ShipAPI

=cut
