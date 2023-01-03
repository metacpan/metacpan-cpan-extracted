#MIT License
#
#Copyright (c) 2023 IP2Location.com
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

package Geo::IP2Location;

use strict;
use vars qw(@ISA $VERSION @EXPORT);
use Math::BigInt;
use bigint;

$VERSION = '8.70';
require Exporter;
@ISA = qw(Exporter);

use constant UNKNOWN => "UNKNOWN IP ADDRESS";
use constant IPV6_ADDRESS_IN_IPV4_BIN => "IPV6 ADDRESS MISSING IN IPV4 BIN";
use constant NO_IP => "MISSING IP ADDRESS";
use constant INVALID_IPV6_ADDRESS => "INVALID IPV6 ADDRESS";
use constant INVALID_IPV4_ADDRESS => "INVALID IPV4 ADDRESS";
use constant INVALID_IP_ADDRESS => "INVALID IP ADDRESS";
use constant INVALID_BIN_DATABASE => "Incorrect IP2Location BIN file format. Please make sure that you are using the latest IP2Location BIN file.";
use constant NOT_SUPPORTED => "This parameter is unavailable in selected .BIN data file. Please upgrade data file.";
use constant MAX_IPV4_RANGE => 4294967295;
use constant MAX_IPV6_RANGE => 340282366920938463463374607431768211455;
use constant IP_COUNTRY => 1;
use constant IP_COUNTRY_ISP => 2;
use constant IP_COUNTRY_REGION_CITY => 3;
use constant IP_COUNTRY_REGION_CITY_ISP => 4;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE => 5;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ISP => 6;
use constant IP_COUNTRY_REGION_CITY_ISP_DOMAIN => 7;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ISP_DOMAIN => 8;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE => 9;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_ISP_DOMAIN => 10;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE => 11;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_ISP_DOMAIN => 12;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_TIMEZONE_NETSPEED => 13;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_ISP_DOMAIN_NETSPEED => 14;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_AREACODE => 15;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_ISP_DOMAIN_NETSPEED_AREACODE => 16;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_TIMEZONE_NETSPEED_WEATHER => 17;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_ISP_DOMAIN_NETSPEED_AREACODE_WEATHER => 18;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ISP_DOMAIN_MOBILE => 19;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_ISP_DOMAIN_NETSPEED_AREACODE_WEATHER_MOBILE => 20;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_AREACODE_ELEVATION => 21;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_ISP_DOMAIN_NETSPEED_AREACODE_WEATHER_MOBILE_ELEVATION => 22;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ISP_DOMAIN_MOBILE_USAGETYPE => 23;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_ISP_DOMAIN_NETSPEED_AREACODE_WEATHER_MOBILE_ELEVATION_USAGETYPE => 24;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_ISP_DOMAIN_NETSPEED_AREACODE_WEATHER_MOBILE_ELEVATION_USAGETYPE_ADDRESSTYPE_CATEGORY => 25;
use constant IP_COUNTRY_REGION_CITY_LATITUDE_LONGITUDE_ZIPCODE_TIMEZONE_ISP_DOMAIN_NETSPEED_AREACODE_WEATHER_MOBILE_ELEVATION_USAGETYPE_ADDRESSTYPE_CATEGORY_DISTRICT_ASN => 26;

use constant COUNTRYSHORT => 1;
use constant COUNTRYLONG => 2;
use constant REGION => 3;
use constant CITY => 4;
use constant ISP => 5;
use constant LATITUDE => 6;
use constant LONGITUDE => 7;
use constant DOMAIN => 8;
use constant ZIPCODE => 9;
use constant TIMEZONE => 10;
use constant NETSPEED => 11;
use constant IDDCODE => 12;
use constant AREACODE => 13;
use constant WEATHERSTATIONCODE => 14;
use constant WEATHERSTATIONNAME => 15;
use constant MCC => 16;
use constant MNC => 17;
use constant MOBILEBRAND => 18;
use constant ELEVATION => 19;
use constant USAGETYPE => 20;
use constant ADDRESSTYPE => 21;
use constant CATEGORY => 22;
use constant DISTRICT => 23;
use constant ASN => 24;
use constant AS => 25;

use constant ALL => 100;
use constant IPV4 => 0;
use constant IPV6 => 1;

my @COUNTRY_POSITION =             (0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2, 2, 2);
my @REGION_POSITION =              (0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, 3, 3);
my @CITY_POSITION =                (0,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4, 4, 4);
my @LATITUDE_POSITION =            (0,  0,  0,  0,  0,  5,  5,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5, 5, 5);
my @LONGITUDE_POSITION =           (0,  0,  0,  0,  0,  6,  6,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6, 6, 6);
my @ZIPCODE_POSITION =             (0,  0,  0,  0,  0,  0,  0,  0,  0,  7,  7,  7,  7,  0,  7,  7,  7,  0,  7,  0,  7,  7,  7,  0,  7, 7, 7);
my @TIMEZONE_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  7,  8,  8,  8,  7,  8,  0,  8,  8,  8,  0,  8, 8, 8);
my @ISP_POSITION =                 (0,  0,  3,  0,  5,  0,  7,  5,  7,  0,  8,  0,  9,  0,  9,  0,  9,  0,  9,  7,  9,  0,  9,  7,  9, 9, 9);
my @DOMAIN_POSITION =              (0,  0,  0,  0,  0,  0,  0,  6,  8,  0,  9,  0, 10,  0, 10,  0, 10,  0, 10,  8, 10,  0, 10,  8, 10, 10, 10);
my @NETSPEED_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8, 11,  0, 11,  8, 11,  0, 11,  0, 11,  0, 11, 11, 11);
my @IDDCODE_POSITION =             (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9, 12,  0, 12,  0, 12,  9, 12,  0, 12, 12, 12);
my @AREACODE_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 10, 13,  0, 13,  0, 13, 10, 13,  0, 13, 13, 13);
my @WEATHERSTATIONCODE_POSITION =  (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9, 14,  0, 14,  0, 14,  0, 14, 14, 14);
my @WEATHERSTATIONNAME_POSITION =  (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 10, 15,  0, 15,  0, 15,  0, 15, 15, 15);
my @MCC_POSITION =                 (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9, 16,  0, 16,  9, 16, 16, 16);
my @MNC_POSITION =                 (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 10, 17,  0, 17, 10, 17, 17, 17);
my @MOBILEBRAND_POSITION =         (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 11, 18,  0, 18, 11, 18, 18, 18);
my @ELEVATION_POSITION =           (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 11, 19,  0, 19, 19, 19);
my @USAGETYPE_POSITION =           (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 12, 20, 20, 20);
my @ADDRESSTYPE_POSITION =         (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 21, 21);
my @CATEGORY_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 22, 22);
my @DISTRICT_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 23);
my @ASN_POSITION =                 (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 24);
my @AS_POSITION =                  (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25);
my @COLUMN_SIZE =                  (0,  2,  3,  4,  5,  6,  7,  6,  8,  7,  9,  8, 10,  8, 11, 10, 13, 10, 15, 11, 18, 11, 19, 12, 20, 22, 25);

my @IPV6_COUNTRY_POSITION =             (0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2, 2, 2);
my @IPV6_REGION_POSITION =              (0,  0,  0,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, 3, 3);
my @IPV6_CITY_POSITION =                (0,  0,  0,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4, 4, 4);
my @IPV6_LATITUDE_POSITION =            (0,  0,  0,  0,  0,  5,  5,  0,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5, 5, 5);
my @IPV6_LONGITUDE_POSITION =           (0,  0,  0,  0,  0,  6,  6,  0,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6, 6, 6);
my @IPV6_ZIPCODE_POSITION =             (0,  0,  0,  0,  0,  0,  0,  0,  0,  7,  7,  7,  7,  0,  7,  7,  7,  0,  7,  0,  7,  7,  7,  0,  7, 7, 7);
my @IPV6_TIMEZONE_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8,  8,  7,  8,  8,  8,  7,  8,  0,  8,  8,  8,  0,  8, 8, 8);
my @IPV6_ISP_POSITION =                 (0,  0,  3,  0,  5,  0,  7,  5,  7,  0,  8,  0,  9,  0,  9,  0,  9,  0,  9,  7,  9,  0,  9,  7,  9, 9, 9);
my @IPV6_DOMAIN_POSITION =              (0,  0,  0,  0,  0,  0,  0,  6,  8,  0,  9,  0, 10,  0, 10,  0, 10,  0, 10,  8, 10,  0, 10,  8, 10, 10, 10);
my @IPV6_NETSPEED_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  8, 11,  0, 11,  8, 11,  0, 11,  0, 11,  0, 11, 11, 11);
my @IPV6_IDDCODE_POSITION =             (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9, 12,  0, 12,  0, 12,  9, 12,  0, 12, 12, 12);
my @IPV6_AREACODE_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 10, 13,  0, 13,  0, 13, 10, 13,  0, 13, 13, 13);
my @IPV6_WEATHERSTATIONCODE_POSITION =  (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9, 14,  0, 14,  0, 14,  0, 14, 14, 14);
my @IPV6_WEATHERSTATIONNAME_POSITION =  (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 10, 15,  0, 15,  0, 15,  0, 15, 15, 15);
my @IPV6_MCC_POSITION =                 (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  9, 16,  0, 16,  9, 16, 16, 16);
my @IPV6_MNC_POSITION =                 (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 10, 17,  0, 17, 10, 17, 17, 17);
my @IPV6_MOBILEBRAND_POSITION =         (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 11, 18,  0, 18, 11, 18, 18, 18);
my @IPV6_ELEVATION_POSITION =           (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 11, 19,  0, 19, 19, 19);
my @IPV6_USAGETYPE_POSITION =           (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 12, 20, 20, 20);
my @IPV6_ADDRESSTYPE_POSITION =         (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 21, 21);
my @IPV6_CATEGORY_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 22, 22);
my @IPV6_DISTRICT_POSITION =            (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 23);
my @IPV6_ASN_POSITION =                 (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 24);
my @IPV6_AS_POSITION =                  (0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 25);
my @IPV6_COLUMN_SIZE =                  (0,  2,  3,  4,  5,  6,  7,  6,  8,  7,  9,  8, 10,  8, 11, 10, 13, 10, 15, 11, 18, 11, 19, 12, 20, 22, 25);

my $IPv6_re = qr/:(?::[0-9a-fA-F]{1,4}){0,5}(?:(?::[0-9a-fA-F]{1,4}){1,2}|:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})))|[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}:(?:[0-9a-fA-F]{1,4}|:)|(?::(?:[0-9a-fA-F]{1,4})?|(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))))|:(?:(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|[0-9a-fA-F]{1,4}(?::[0-9a-fA-F]{1,4})?|))|(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|:[0-9a-fA-F]{1,4}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){0,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,2}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,3}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))|(?:(?::[0-9a-fA-F]{1,4}){0,4}(?::(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))|(?::[0-9a-fA-F]{1,4}){1,2})|:))/;
my $IPv4_re = qr/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;

my $getLastErrorMessage = "";

sub open {
  unless( (@_ > 1) && ($_[1]) ) {
  	$getLastErrorMessage = "Geo::IP2Location::open() requires a database path name.";
  	die "Geo::IP2Location::open() requires a database path name";
  } 
  my ($class, $db_file) = @_;
  my $handle;
  my $obj;
  unless (CORE::open $handle, "$db_file") {
  	$getLastErrorMessage = "Geo::IP2Location::open() error in opening $db_file" . ".";
  	die "Geo::IP2Location::open() error in opening $db_file";
  }
	binmode($handle);
	$obj = bless {filehandle => $handle}, $class;
	$obj->initialize();
	if ($obj->{"productcode"} == 1) {
	} else {
		if (($obj->{"databaseyear"} <= 20) && ($obj->{"productcode"} == 0)) {
		} else {
			$obj->close();
			undef $obj;
			$getLastErrorMessage = INVALID_BIN_DATABASE;
			die INVALID_BIN_DATABASE;
		}
	}
	return $obj;
}

sub close {
  my ($class) = @_;
  if (CORE::close($class->{filehandle})) {
  	return 0;
  } else {
  	return 1;
  }
}

sub initialize {
	my ($obj) = @_;
	my @header = $obj->read512($obj->{filehandle}, 1);
	$obj->{"databasetype"} = unpack("C", $header[0]);
	$obj->{"databasecolumn"} = unpack("C", $header[1]);
	$obj->{"databaseyear"} = unpack("C", $header[2]);
	$obj->{"databasemonth"} = unpack("C", $header[3]);
	$obj->{"databaseday"} = unpack("C", $header[4]);
	$obj->{"ipv4databasecount"} = unpack("V", join('', @header[5..8]));
	$obj->{"ipv4databaseaddr"} = unpack("V", join('', @header[9..12]));
	$obj->{"ipv6databasecount"} = unpack("V", join('', @header[13..16]));
	$obj->{"ipv6databaseaddr"} = unpack("V", join('', @header[17..20]));
	$obj->{"ipv4indexbaseaddr"} = unpack("V", join('', @header[21..24]));
	$obj->{"ipv6indexbaseaddr"} = unpack("V", join('', @header[25..28]));
	$obj->{"productcode"} = unpack("C", $header[29]);
	$obj->{"licensecode"} = unpack("C", $header[30]);
	$obj->{"databasesize"} = unpack("V", join('', @header[31..34]));
	return $obj;
}

sub get_last_error_message	{
	my $class = shift(@_);
	return ($getLastErrorMessage);
}

sub get_module_version {
	my $obj = shift(@_);
	return $VERSION;
}

sub get_database_version {
	my $obj = shift(@_);
	return $obj->{"databaseyear"} . "." . $obj->{"databasemonth"} . "." . $obj->{"databaseday"};
}

sub get_country_short {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, COUNTRYSHORT);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, COUNTRYSHORT);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_country_long {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, COUNTRYLONG);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, COUNTRYLONG);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_region {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, REGION);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, REGION);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub get_city {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, CITY);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, CITY);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_isp {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, ISP);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, ISP);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub get_latitude {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, LATITUDE);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, LATITUDE);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_zipcode {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, ZIPCODE);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, ZIPCODE);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_longitude {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, LONGITUDE);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, LONGITUDE);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}	
}

sub get_domain {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, DOMAIN);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, DOMAIN);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_timezone {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, TIMEZONE);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, TIMEZONE);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_netspeed {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, NETSPEED);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, NETSPEED);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_iddcode {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, IDDCODE);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, IDDCODE);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_areacode {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, AREACODE);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, AREACODE);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_weatherstationcode {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, WEATHERSTATIONCODE);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, WEATHERSTATIONCODE);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_weatherstationname {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, WEATHERSTATIONNAME);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, WEATHERSTATIONNAME);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_mcc {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, MCC);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, MCC);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_mnc {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, MNC);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, MNC);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_mobilebrand {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, MOBILEBRAND);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, MOBILEBRAND);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_elevation {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, ELEVATION);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, ELEVATION);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_usagetype {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, USAGETYPE);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, USAGETYPE);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_addresstype {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, ADDRESSTYPE);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, ADDRESSTYPE);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_category {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, CATEGORY);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, CATEGORY);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_district {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, DISTRICT);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, DISTRICT);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_asn {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, ASN);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, ASN);	
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_as {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, AS);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, AS);
		} else {
			return INVALID_IP_ADDRESS;
		}
	}
}

sub get_all {
	my $obj = shift(@_);
	my $ipaddr = shift(@_);
	my ($ipv, $ipnum) = $obj->validate_ip($ipaddr);
	if ($ipv == 4) {
		return $obj->get_ipv4_record($ipnum, ALL);
	} else {
		if ($ipv == 6) {
			return $obj->get_ipv6_record($ipnum, ALL);	
		} else {
			return (INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS, INVALID_IP_ADDRESS);
		}
	}
}

sub get_ipv6_record {
	my $obj = shift(@_);
	my $ipnum = shift(@_);
	my $mode = shift(@_);
	my $dbtype = $obj->{"databasetype"};

	if ($ipnum eq "") {
		if ($mode == ALL) {
			return (NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP);
		} else {
			return NO_IP;
		}
	}

	if (($mode == COUNTRYSHORT) && ($IPV6_COUNTRY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == COUNTRYLONG) && ($IPV6_COUNTRY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == REGION) && ($IPV6_REGION_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == CITY) && ($IPV6_CITY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ISP) && ($IPV6_ISP_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == LATITUDE) && ($IPV6_LATITUDE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == LONGITUDE) && ($IPV6_LONGITUDE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == DOMAIN) && ($IPV6_DOMAIN_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ZIPCODE) && ($IPV6_ZIPCODE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == TIMEZONE) && ($IPV6_TIMEZONE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == NETSPEED) && ($IPV6_NETSPEED_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == IDDCODE) && ($IPV6_IDDCODE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == AREACODE) && ($IPV6_AREACODE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == WEATHERSTATIONCODE) && ($IPV6_WEATHERSTATIONCODE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == WEATHERSTATIONNAME) && ($IPV6_WEATHERSTATIONNAME_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == MCC) && ($IPV6_MCC_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == MNC) && ($IPV6_MNC_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == MOBILEBRAND) && ($IPV6_MOBILEBRAND_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ELEVATION) && ($IPV6_ELEVATION_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == USAGETYPE) && ($IPV6_USAGETYPE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ADDRESSTYPE) && ($IPV6_ADDRESSTYPE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == CATEGORY) && ($IPV6_CATEGORY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == DISTRICT) && ($IPV6_DISTRICT_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ASN) && ($IPV6_ASN_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == AS) && ($IPV6_AS_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}

	my $realipno = $ipnum;
	my $handle = $obj->{"filehandle"};
	my $baseaddr = $obj->{"ipv6databaseaddr"};
	my $dbcount = $obj->{"ipv6databasecount"};
	my $dbcolumn = $obj->{"databasecolumn"};
	my $indexbaseaddr = $obj->{"ipv6indexbaseaddr"};

	if ($dbcount == 0) {
		if ($mode == ALL) {
			return (IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN, IPV6_ADDRESS_IN_IPV4_BIN);
		} else {
			return IPV6_ADDRESS_IN_IPV4_BIN;
		}
	}

	my $ipnum1_2 = new Math::BigInt($ipnum);
	my $remainder = 0;
	($ipnum1_2, $remainder) = $ipnum1_2->bdiv(2**112);
	my $indexaddr = $indexbaseaddr + ($ipnum1_2 << 3);

	my $low = 0;
	my $high = $dbcount;
	if ($indexbaseaddr > 0) {
		($low, $high) = $obj->read32x2($handle, $indexaddr);
	}

	my $mid = 0;
	my $ipfrom = 0;
	my $ipto = 0;
	my $ipno = 0;

	$ipno = $realipno;
	if ($realipno == "340282366920938463463374607431768211455") {
		$ipno = $ipno->bsub(1);
	}

	my $raw_positions_row;
	
	while ($low <= $high) {
		$mid = int(($low + $high)/2);
		($ipfrom, $ipto, $raw_positions_row) = $obj->readRow128($handle, $baseaddr + $mid * (($dbcolumn * 4) + 12), $dbcolumn);
		
		if (($ipno >= $ipfrom) && ($ipno < $ipto)) {
			my $row_pointer = $baseaddr + $mid * (($dbcolumn * 4) + 12);
			
			if ($mode == ALL) {
				my $country_short = NOT_SUPPORTED;
				my $country_long = NOT_SUPPORTED;
				my $region = NOT_SUPPORTED;
				my $city = NOT_SUPPORTED;
				my $isp = NOT_SUPPORTED;
				my $latitude = NOT_SUPPORTED;
				my $longitude = NOT_SUPPORTED;
				my $domain = NOT_SUPPORTED;
				my $zipcode = NOT_SUPPORTED;
				my $timezone = NOT_SUPPORTED;
				my $netspeed = NOT_SUPPORTED;
				my $iddcode = NOT_SUPPORTED;
				my $areacode = NOT_SUPPORTED;
				my $weatherstationcode = NOT_SUPPORTED;
				my $weatherstationname = NOT_SUPPORTED;
				my $mcc = NOT_SUPPORTED;
				my $mnc = NOT_SUPPORTED;
				my $mobilebrand = NOT_SUPPORTED;
				my $elevation = NOT_SUPPORTED;
				my $usagetype = NOT_SUPPORTED;
				my $addresstype = NOT_SUPPORTED;
				my $category = NOT_SUPPORTED;
				my $district = NOT_SUPPORTED;
				my $asn = NOT_SUPPORTED;
				my $as = NOT_SUPPORTED;
				
				if ($IPV6_COUNTRY_POSITION[$dbtype] != 0) {
					$country_short = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_COUNTRY_POSITION[$dbtype]+2), 4)));
					$country_long = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_COUNTRY_POSITION[$dbtype]+2), 4)) + 3);
				}
				if ($IPV6_REGION_POSITION[$dbtype] != 0) {
					$region = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_REGION_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_CITY_POSITION[$dbtype] != 0) {
					$city = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_CITY_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_ISP_POSITION[$dbtype] != 0) {
					$isp = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_ISP_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_LATITUDE_POSITION[$dbtype] != 0) {
					$latitude = $obj->readFloat(substr($raw_positions_row, 4 * ($IPV6_LATITUDE_POSITION[$dbtype]+2)));
					$latitude = sprintf("%.6f", $latitude);
				}
				if ($IPV6_LONGITUDE_POSITION[$dbtype] != 0) {
					$longitude = $obj->readFloat(substr($raw_positions_row, 4 * ($IPV6_LONGITUDE_POSITION[$dbtype]+2)));
					$longitude = sprintf("%.6f", $longitude);
				}
				if ($IPV6_DOMAIN_POSITION[$dbtype] != 0) {
					$domain = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_DOMAIN_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_ZIPCODE_POSITION[$dbtype] != 0) {
					$zipcode = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_ZIPCODE_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_TIMEZONE_POSITION[$dbtype] != 0) {
					$timezone = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_TIMEZONE_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_NETSPEED_POSITION[$dbtype] != 0) {
					$netspeed = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_NETSPEED_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_IDDCODE_POSITION[$dbtype] != 0) {
					$iddcode = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_IDDCODE_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_AREACODE_POSITION[$dbtype] != 0) {
					$areacode = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_AREACODE_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_WEATHERSTATIONCODE_POSITION[$dbtype] != 0) {
					$weatherstationcode = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_WEATHERSTATIONCODE_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_WEATHERSTATIONNAME_POSITION[$dbtype] != 0) {
					$weatherstationname = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_WEATHERSTATIONNAME_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_MCC_POSITION[$dbtype] != 0) {
					$mcc = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_MCC_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_MNC_POSITION[$dbtype] != 0) {
					$mnc = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_MNC_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_MOBILEBRAND_POSITION[$dbtype] != 0) {
					$mobilebrand = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_MOBILEBRAND_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_ELEVATION_POSITION[$dbtype] != 0) {
					$elevation = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_ELEVATION_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_USAGETYPE_POSITION[$dbtype] != 0) {
					$usagetype = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_USAGETYPE_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_ADDRESSTYPE_POSITION[$dbtype] != 0) {
					$addresstype = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_ADDRESSTYPE_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_CATEGORY_POSITION[$dbtype] != 0) {
					$category = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_CATEGORY_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_DISTRICT_POSITION[$dbtype] != 0) {
					$district = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_DISTRICT_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_ASN_POSITION[$dbtype] != 0) {
					$asn = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_ASN_POSITION[$dbtype]+2), 4)));
				}
				if ($IPV6_AS_POSITION[$dbtype] != 0) {
					$as = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_AS_POSITION[$dbtype]+2), 4)));
				}

				return ($country_short, $country_long, $region, $city, $latitude, $longitude, $zipcode, $timezone, $isp, $domain, $netspeed, $iddcode, $areacode, $weatherstationcode, $weatherstationname, $mcc, $mnc, $mobilebrand, $elevation, $usagetype, $addresstype, $category, $district, $asn, $as);
			}
			if ($mode == COUNTRYSHORT) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_COUNTRY_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == COUNTRYLONG) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_COUNTRY_POSITION[$dbtype]+2), 4)) + 3);
			}
			if ($mode == REGION) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_REGION_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == CITY) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_CITY_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == ISP) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_ISP_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == LATITUDE) {
				my $lat = $obj->readFloat(substr($raw_positions_row, 4 * ($IPV6_LATITUDE_POSITION[$dbtype]+2)));
				$lat = sprintf("%.6f", $lat);				
				return $lat;
			}
			if ($mode == LONGITUDE) {
				my $lon = $obj->readFloat(substr($raw_positions_row, 4 * ($IPV6_LONGITUDE_POSITION[$dbtype]+2)));
				$lon = sprintf("%.6f", $lon);				
				return $lon;
			}
			if ($mode == DOMAIN) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_DOMAIN_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == ZIPCODE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_ZIPCODE_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == TIMEZONE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_TIMEZONE_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == NETSPEED) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_NETSPEED_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == IDDCODE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_IDDCODE_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == AREACODE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_AREACODE_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == WEATHERSTATIONCODE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_WEATHERSTATIONCODE_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == WEATHERSTATIONNAME) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_WEATHERSTATIONNAME_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == MCC) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_MCC_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == MNC) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_MNC_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == MOBILEBRAND) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_MOBILEBRAND_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == ELEVATION) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_ELEVATION_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == USAGETYPE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_USAGETYPE_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == ADDRESSTYPE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_ADDRESSTYPE_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == CATEGORY) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_CATEGORY_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == DISTRICT) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_DISTRICT_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == ASN) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_ASN_POSITION[$dbtype]+2), 4)));
			}
			if ($mode == AS) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IPV6_AS_POSITION[$dbtype]+2), 4)));
			}
		} else {
			if ($ipno < $ipfrom) {
				$high = $mid - 1;
			} else {
				$low = $mid + 1;
			}
		}
	}
	if ($mode == ALL) {
		return (UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN);
	} else {
		return UNKNOWN;
	}
}

sub get_ipv4_record {
	my $obj = shift(@_);
	my $ipnum = shift(@_);
	my $mode = shift(@_);
	my $dbtype= $obj->{"databasetype"};
	
	if ($ipnum eq "") {
		if ($mode == ALL) {
			return (NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP, NO_IP);
		} else {
			return NO_IP;
		}
	}
	
	if (($mode == COUNTRYSHORT) && ($COUNTRY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == COUNTRYLONG) && ($COUNTRY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == REGION) && ($REGION_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == CITY) && ($CITY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ISP) && ($ISP_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == LATITUDE) && ($LATITUDE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == LONGITUDE) && ($LONGITUDE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == DOMAIN) && ($DOMAIN_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ZIPCODE) && ($ZIPCODE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == TIMEZONE) && ($TIMEZONE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == NETSPEED) && ($NETSPEED_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == IDDCODE) && ($IDDCODE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == AREACODE) && ($AREACODE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == WEATHERSTATIONCODE) && ($WEATHERSTATIONCODE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == WEATHERSTATIONNAME) && ($WEATHERSTATIONNAME_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == MCC) && ($MCC_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == MNC) && ($MNC_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == MOBILEBRAND) && ($MOBILEBRAND_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ELEVATION) && ($ELEVATION_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == USAGETYPE) && ($USAGETYPE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ADDRESSTYPE) && ($ADDRESSTYPE_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == CATEGORY) && ($CATEGORY_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == DISTRICT) && ($DISTRICT_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == ASN) && ($ASN_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	if (($mode == AS) && ($AS_POSITION[$dbtype] == 0)) {
		return NOT_SUPPORTED;
	}
	
	my $realipno = $ipnum;
	my $handle = $obj->{"filehandle"};
	my $baseaddr = $obj->{"ipv4databaseaddr"};
	my $dbcount = $obj->{"ipv4databasecount"};
	my $dbcolumn = $obj->{"databasecolumn"};
	my $indexbaseaddr = $obj->{"ipv4indexbaseaddr"};

	my $ipnum1_2 = int($ipnum >> 16);
	my $indexaddr = $indexbaseaddr + ($ipnum1_2 << 3);

	my $low = 0;
	my $high = $dbcount;
	if ($indexbaseaddr > 0) {
		($low, $high) = $obj->read32x2($handle, $indexaddr);
	}
	my $mid = 0;
	my $ipfrom = 0;
	my $ipto = 0;
	my $ipno = 0;

	if ($realipno == MAX_IPV4_RANGE) {
		$ipno = $realipno - 1;
	} else {
		$ipno = $realipno;
	}

	my $raw_positions_row;

	while ($low <= $high) {
		$mid = int(($low + $high) >> 1);

		($ipfrom, $ipto, $raw_positions_row) = $obj->readRow32($handle, $baseaddr + $mid * $dbcolumn * 4, $dbcolumn);

		if (($ipno >= $ipfrom) && ($ipno < $ipto)) {
			if ($mode == ALL) {
				my $country_short = NOT_SUPPORTED;
				my $country_long = NOT_SUPPORTED;
				my $region = NOT_SUPPORTED;
				my $city = NOT_SUPPORTED;
				my $isp = NOT_SUPPORTED;
				my $latitude = NOT_SUPPORTED;
				my $longitude = NOT_SUPPORTED;
				my $domain = NOT_SUPPORTED;
				my $zipcode = NOT_SUPPORTED;
				my $timezone = NOT_SUPPORTED;
				my $netspeed = NOT_SUPPORTED;
				my $iddcode = NOT_SUPPORTED;
				my $areacode = NOT_SUPPORTED;
				my $weatherstationcode = NOT_SUPPORTED;
				my $weatherstationname = NOT_SUPPORTED;
				my $mcc = NOT_SUPPORTED;
				my $mnc = NOT_SUPPORTED;
				my $mobilebrand = NOT_SUPPORTED;
				my $elevation = NOT_SUPPORTED;
				my $usagetype = NOT_SUPPORTED;
				my $addresstype = NOT_SUPPORTED;
				my $category = NOT_SUPPORTED;
				my $district = NOT_SUPPORTED;
				my $asn = NOT_SUPPORTED;
				my $as = NOT_SUPPORTED;
				
				if ($COUNTRY_POSITION[$dbtype] != 0) {
					$country_short = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($COUNTRY_POSITION[$dbtype]-1), 4)));
					$country_long = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($COUNTRY_POSITION[$dbtype]-1), 4)) + 3);
				}

				if ($REGION_POSITION[$dbtype] != 0) {
					$region = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($REGION_POSITION[$dbtype]-1), 4)));
				}
				if ($CITY_POSITION[$dbtype] != 0) {
					$city = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($CITY_POSITION[$dbtype]-1), 4)));
				}
				if ($ISP_POSITION[$dbtype] != 0) {
					$isp = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($ISP_POSITION[$dbtype]-1), 4)));
				}
				if ($LATITUDE_POSITION[$dbtype] != 0) {
					$latitude = $obj->readFloat(substr($raw_positions_row, 4 * ($LATITUDE_POSITION[$dbtype]-1), 4));
					$latitude = sprintf("%.6f", $latitude);
				}
				if ($LONGITUDE_POSITION[$dbtype] != 0) {
					$longitude = $obj->readFloat(substr($raw_positions_row, 4 * ($LONGITUDE_POSITION[$dbtype]-1), 4));
					$longitude = sprintf("%.6f", $longitude);
				}
				if ($DOMAIN_POSITION[$dbtype] != 0) {
					$domain = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($DOMAIN_POSITION[$dbtype]-1), 4)));
				}
				if ($ZIPCODE_POSITION[$dbtype] != 0) {
					$zipcode = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($ZIPCODE_POSITION[$dbtype]-1), 4)));
				}
				if ($TIMEZONE_POSITION[$dbtype] != 0) {
					$timezone = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($TIMEZONE_POSITION[$dbtype]-1), 4)));
				}
				if ($NETSPEED_POSITION[$dbtype] != 0) {
					$netspeed = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($NETSPEED_POSITION[$dbtype]-1), 4)));
				}
				if ($IDDCODE_POSITION[$dbtype] != 0) {
					$iddcode = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IDDCODE_POSITION[$dbtype]-1), 4)));
				}
				if ($AREACODE_POSITION[$dbtype] != 0) {
					$areacode = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($AREACODE_POSITION[$dbtype]-1), 4)));
				}
				if ($WEATHERSTATIONCODE_POSITION[$dbtype] != 0) {
					$weatherstationcode = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($WEATHERSTATIONCODE_POSITION[$dbtype]-1), 4)));
				}
				if ($WEATHERSTATIONNAME_POSITION[$dbtype] != 0) {
					$weatherstationname = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($WEATHERSTATIONNAME_POSITION[$dbtype]-1), 4)));
				}
				if ($MCC_POSITION[$dbtype] != 0) {
					$mcc = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($MCC_POSITION[$dbtype]-1), 4)));
				}
				if ($MNC_POSITION[$dbtype] != 0) {
					$mnc = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($MNC_POSITION[$dbtype]-1), 4)));
				}
				if ($MOBILEBRAND_POSITION[$dbtype] != 0) {
					$mobilebrand = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($MOBILEBRAND_POSITION[$dbtype]-1), 4)));
				}
				if ($ELEVATION_POSITION[$dbtype] != 0) {
					$elevation = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($ELEVATION_POSITION[$dbtype]-1), 4)));
				}
				if ($USAGETYPE_POSITION[$dbtype] != 0) {
					$usagetype = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($USAGETYPE_POSITION[$dbtype]-1), 4)));
				}
				if ($ADDRESSTYPE_POSITION[$dbtype] != 0) {
					$addresstype = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($ADDRESSTYPE_POSITION[$dbtype]-1), 4)));
				}
				if ($CATEGORY_POSITION[$dbtype] != 0) {
					$category = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($CATEGORY_POSITION[$dbtype]-1), 4)));
				}
				if ($DISTRICT_POSITION[$dbtype] != 0) {
					$district = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($DISTRICT_POSITION[$dbtype]-1), 4)));
				}
				if ($ASN_POSITION[$dbtype] != 0) {
					$asn = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($ASN_POSITION[$dbtype]-1), 4)));
				}
				if ($AS_POSITION[$dbtype] != 0) {
					$as = $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($AS_POSITION[$dbtype]-1), 4)));
				}

				return ($country_short, $country_long, $region, $city, $latitude, $longitude, $zipcode, $timezone, $isp, $domain, $netspeed, $iddcode, $areacode, $weatherstationcode, $weatherstationname, $mcc, $mnc, $mobilebrand, $elevation, $usagetype, $addresstype, $category, $district, $asn, $as);
			}
			if ($mode == COUNTRYSHORT) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($COUNTRY_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == COUNTRYLONG) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($COUNTRY_POSITION[$dbtype]-1), 4)) + 3);
			}
			if ($mode == REGION) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($REGION_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == CITY) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($CITY_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == ISP) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($ISP_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == LATITUDE) {
				my $lat = $obj->readFloat(substr($raw_positions_row, 4 * ($LATITUDE_POSITION[$dbtype]-1), 4));
				$lat = sprintf("%.6f", $lat);
				return $lat;
			}
			if ($mode == LONGITUDE) {
				my $lon = $obj->readFloat(substr($raw_positions_row, 4 * ($LONGITUDE_POSITION[$dbtype]-1), 4));
				$lon = sprintf("%.6f", $lon);
				return $lon;
			}
			if ($mode == DOMAIN) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($DOMAIN_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == ZIPCODE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($ZIPCODE_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == TIMEZONE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($TIMEZONE_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == NETSPEED) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($NETSPEED_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == IDDCODE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($IDDCODE_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == AREACODE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($AREACODE_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == WEATHERSTATIONCODE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($WEATHERSTATIONCODE_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == WEATHERSTATIONNAME) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($WEATHERSTATIONNAME_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == MCC) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($MCC_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == MNC) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($MNC_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == MOBILEBRAND) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($MOBILEBRAND_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == ELEVATION) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($ELEVATION_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == USAGETYPE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($USAGETYPE_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == ADDRESSTYPE) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($ADDRESSTYPE_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == CATEGORY) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($CATEGORY_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == DISTRICT) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($DISTRICT_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == ASN) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($ASN_POSITION[$dbtype]-1), 4)));
			}
			if ($mode == AS) {
				return $obj->readStr($handle, unpack("V", substr($raw_positions_row, 4 * ($AS_POSITION[$dbtype]-1), 4)));
			}
		} else {
			if ($ipno < $ipfrom) {
				$high = $mid - 1;
			} else {
				$low = $mid + 1;
			}
		}
	}
	if ($mode == ALL) {
		return (UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN);
	} else {
		return UNKNOWN;
	}
}

sub readRow32 {
	my ($obj, $handle, $position, $column) = @_;
	my $data = "";
	my $data_length = $column * 4 + 4;
	seek($handle, $position-1, 0);
	read($handle, $data, $data_length);
	my $ipfrom = substr($data, 0, 4);
	my $ipfrom_next = substr($data, $data_length - 4, 4);
	my $result_row = substr($data, 0, $data_length - 4);
	return (unpack("V", $ipfrom), unpack("V", $ipfrom_next), $result_row);
}

sub readRow128 {
	my ($obj, $handle, $position, $column) = @_;
	my $data = "";
	my $data_length = $column * 4 + 12 + 16;
	seek($handle, $position-1, 0);
	read($handle, $data, $data_length);
	my $ipfrom = substr($data, 0, 16);
	my $ipfrom_next = substr($data, $data_length - 16, 16);
	my $result_row = substr($data, 0, $data_length - 16);
	return (&bytesInt($ipfrom), &bytesInt($ipfrom_next), $result_row);
}

sub read512 {
	my ($obj, $handle, $position) = @_;
	my $data = "";
	seek($handle, $position-1, 0);
	read($handle, $data, 64);
	my @data_array = split('', $data);
	while ($#data_array < 63) {
		$data_array[$#data_array+1] = 0x00;
	}
	return @data_array;
}

sub read32x2 {
	my ($obj, $handle, $position) = @_;
	my $data = "";
	seek($handle, $position-1, 0);
	read($handle, $data, 8);
	my $data_1 = substr($data, 0, 4);
	my $data_2 = substr($data, 4, 4);
	return (unpack("V", $data_1), unpack("V", $data_2));
}

sub read128 {
	my ($obj, $handle, $position) = @_;
	my $data = "";
	seek($handle, $position-1, 0);
	read($handle, $data, 16);
	return &bytesInt($data);
}

sub read32 {
	my ($obj, $handle, $position) = @_;
	my $data = "";
	seek($handle, $position-1, 0);
	read($handle, $data, 4);
	return unpack("V", $data);
}

sub read8 {
	my ($obj, $handle, $position) = @_;
	my $data = "";
	seek($handle, $position-1, 0);
	read($handle, $data, 1);
	return unpack("C", $data);
}

sub readStr {
	my ($obj, $handle, $position) = @_;
	my $data = "";
	seek($handle, $position, 0);
	read($handle, $data, 257);
	my $char_count = unpack("C", substr($data, 0, 1));
	my $string = substr($data, 1, $char_count);
	return $string;
}

sub readFloat {
	my ($obj, $data) = @_;
	my $is_little_endian = unpack("h*", pack("s", 1));
	if ($is_little_endian =~ m/^1/) {
		# "LITTLE ENDIAN - x86\n";
		return unpack("f", $data);
	} else {
		# "BIG ENDIAN - MAC\n";
		return unpack("f", reverse($data));
	}
}

sub bytesInt {
	my $binip = shift(@_);
	my @array = split(//, $binip);
	return 0 if ($#array != 15);
	my $ip96_127 = unpack("V", $array[0] . $array[1] . $array[2] . $array[3]);
	my $ip64_95 = unpack("V", $array[4] . $array[5] . $array[6] . $array[7]);
	my $ip32_63 = unpack("V", $array[8] . $array[9] . $array[10] . $array[11]);
	my $ip1_31 = unpack("V", $array[12] . $array[13] . $array[14] . $array[15]);

	my $big1 = Math::BigInt->new("$ip96_127");
	my $big2 = Math::BigInt->new("$ip64_95")->blsft(32);
	my $big3 = Math::BigInt->new("$ip32_63")->blsft(64);
	my $big4 = Math::BigInt->new("$ip1_31")->blsft(96);
	$big1 = $big1->badd($big2)->badd($big3)->badd($big4);
	
	return $big1->bstr();
}

sub validate_ip {
	my $obj = shift(@_);
	my $ip = shift(@_);
	my $ipv = -1;
	my $ipnum = -1;
	#name server lookup if domain name
	$ip = $obj->name2ip($ip);
	
	if ($obj->ip_is_ipv4($ip)) {
		#ipv4 address
		$ipv = 4;
		$ipnum = $obj->ip2no($ip);
	} else {
		#expand ipv6 address
		$ip = $obj->expand_ipv6_address($ip);
		if ($obj->ip_is_ipv6($ip)) {
			#ipv6 address
			$ipv = 6;
			$ipnum = $obj->hex2int($ip);
			
			#reformat ipv4 address in ipv6 
			if (($ipnum >= 281470681743360) && ($ipnum <= 281474976710655)) {
				$ipv = 4;
				$ipnum = $ipnum - 281470681743360;
			}

			#reformat 6to4 address to ipv4 address 2002:: to 2002:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
			if (($ipnum >= 42545680458834377588178886921629466624) && ($ipnum <= 42550872755692912415807417417958686719)) {
				$ipv = 4;
				#bitshift right 80 bits
				$ipnum->brsft(80);
				#bitwise modulus to get the last 32 bit
				$ipnum->bmod(4294967296); 
			}

			#reformat Teredo address to ipv4 address 2001:0000:: to 2001:0000:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:
			if (($ipnum >= 42540488161975842760550356425300246528) && ($ipnum <= 42540488241204005274814694018844196863)) {
				$ipv = 4;
				$ipnum = Math::BigInt->new($ipnum);
				#bitwise not to invert binary
				$ipnum->bnot();
				#bitwise modulus to get the last 32 bit
				$ipnum->bmod(4294967296);
			}

		} else {
			#not IPv4 and IPv6
		}
	}
	return ($ipv, $ipnum);
}

sub expand_ipv6_address {
	my $obj = shift(@_);
	my $ip = shift(@_);
	$ip =~ s/\:\:/\:Z\:/;
	my @ip = split(/\:/, $ip);
	my $num = scalar(@ip);

	my $l = 8;
	if ($ip[$#ip] =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
		my $a = sprintf("%x", ($1*256 + $2));
		my $b = sprintf("%x", ($3*256 + $4));
		$ip[$#ip] = $a;
		$ip[$#ip+1] = $b;
		$l--;
	}

	if ($#ip == 8) {
		shift(@ip);
		$l++;
	}

	foreach (0..(scalar(@ip)-1)) {
		next if (length($ip[$_]) > 3);
		$ip[$_] = ('0'x(4-length($ip[$_]))).$ip[$_];
	}
 	
	foreach (0..(scalar(@ip)-1)) {
		next unless ($ip[$_] eq '000Z');
		my @empty = map { $_ = '0'x4 } (0..7);
		$ip[$_] = join(':', @empty[0..$l-$num]);
		last;
	}

	return (uc(join ':', @ip));
}

sub hex2int {
	my $obj = shift(@_);
	my $hexip = shift(@_);

	$hexip =~ s/\://g;

	unless (length($hexip) == 32) {
		return 0;
	};

	my $binip = unpack('B128', pack('H32', $hexip));
	my ($n, $dec) = (Math::BigInt->new(1), Math::BigInt->new(0));

	foreach (reverse (split('', $binip))) {
		$_ && ($dec += $n);
		$n *= 2;
	}

	$dec =~ s/^\+//;
	return $dec;
}

sub ip2no {
	my $obj = shift(@_);
	my $ip = shift(@_);
	my @block = split(/\./, $ip);
	my $no = 0;
	$no = $block[3];
	$no = $no + $block[2] * 256;
	$no = $no + $block[1] * 256 * 256;
	$no = $no + $block[0] * 256 * 256 * 256;
	return $no;
}

sub name2ip {
  my $obj = shift(@_);
  my $host = shift(@_);
  my $ip_address = "";
  if (($host =~ m/^$IPv4_re$/) || ($host =~ m/^$IPv6_re$/) || ($host =~ m/^\:\:$/)) {
    $ip_address = $host;
  } else {
  	# TO_DO: Can we return IPv6 address too?
  	my @hostname = gethostbyname($host);
  	if ($#hostname < 4) {
  		$ip_address = $host;
  	} else {
  		$ip_address = join('.', unpack('C4', $hostname[4]));
  	}
  }
  return $ip_address;
}

sub ip_is_ipv4 {
	my $obj = shift(@_);
	my $ip = shift(@_);
	if ($ip =~ m/^$IPv4_re$/) {
		my @octet = split(/\./, $ip);
		foreach my $i (0 .. $#octet) {
			return 0 if (($octet[$i] > 255) || ($octet[$i] < 0));
		}
		return 1;
	} else {
		return 0;
	}
}

sub ip_is_ipv6 {
	my $obj = shift(@_);
	my $ip = shift(@_);
	if (($ip =~ m/^$IPv6_re$/) || ($ip =~ m/^$IPv4_re$/) || ($ip =~ m/^\:\:$/)) {
		return 1;
	} else {
		return 0;
	}
}

1;
__END__

=head1 NAME

Geo::IP2Location - Lookup of country, region, city, latitude, longitude, ZIP code, time zone, ISP, domain name, connection type, IDD code, area code, weather station code and station, MCC, MNC, mobile carrier brand name, elevation, usage type, IP address type, advertising category, district, AS number and AS name by using IP address. It supports both IPv4 and IPv6 addressing. Please visit L<IP2Location Database|https://www.ip2location.com> for more information.

=head1 SYNOPSIS

	use Geo::IP2Location;

	eval {

		my $obj = Geo::IP2Location->open("IP-COUNTRY-REGION-CITY-LATITUDE-LONGITUDE-ZIPCODE-TIMEZONE-ISP-DOMAIN-NETSPEED-AREACODE-WEATHER-MOBILE-ELEVATION-USAGETYPE-ADDRESSTYPE-CATEGORY-DISTRICT-ASN.BIN");

		if (!defined($obj)) {
			print STDERR Geo::IP2Location::get_last_error_message();
		}

		my $dbversion = $obj->get_database_version();
		my $moduleversion = $obj->get_module_version();
		my $countryshort = $obj->get_country_short("2001:1000:0000:0000:0000:0000:0000:0000");
		my $countrylong = $obj->get_country_long("20.11.187.239");
		my $region = $obj->get_region("20.11.187.239");
		my $city = $obj->get_city("20.11.187.239");
		my $latitude = $obj->get_latitude("20.11.187.239");
		my $longitude = $obj->get_longitude("20.11.187.239");
		my $isp = $obj->get_isp("20.11.187.239");
		my $domain = $obj->get_domain("20.11.187.239");
		my $zipcode = $obj->get_zipcode("20.11.187.239");
		my $timezone = $obj->get_timezone("20.11.187.239");
		my $netspeed = $obj->get_netspeed("20.11.187.239");
		my $iddcode = $obj->get_iddcode("20.11.187.239");
		my $areacode = $obj->get_areacode("20.11.187.239");
		my $weatherstationcode = $obj->get_weatherstationcode("20.11.187.239");
		my $weatherstationname = $obj->get_weatherstationname("20.11.187.239");
		my $mcc = $obj->get_mcc("20.11.187.239");
		my $mnc = $obj->get_mnc("20.11.187.239");
		my $brand = $obj->get_mobilebrand("20.11.187.239");
		my $elevation = $obj->get_elevation("20.11.187.239");
		my $usagetype = $obj->get_usagetype("20.11.187.239");
		my $addresstype = $obj->get_addresstype("20.11.187.239");
		my $category = $obj->get_category("20.11.187.239");
		my $district = $obj->get_district("20.11.187.239");
		my $asn = $obj->get_asn("20.11.187.239");
		my $as = $obj->get_as("20.11.187.239");

		($cos, $col, $reg, $cit, $lat, $lon, $zip, $tmz, $isp, $dom, $ns, $idd, $area, $wcode, $wname, $mcc, $mnc, $brand, $elevation, $usagetype, $addresstype, $category, $district, $asn, $as) = $obj->get_all("20.11.187.239");
		($cos, $col, $reg, $cit, $lat, $lon, $zip, $tmz, $isp, $dom, $ns, $idd, $area, $wcode, $wname, $mcc, $mnc, $brand, $elevation, $usagetype, $addresstype, $category, $district, $asn, $as) = $obj->get_all("2001:1000:0000:0000:0000:0000:0000:0000");

		$obj->close();

	} or do {

		print STDERR Geo::IP2Location::get_last_error_message();

	};

=head1 DESCRIPTION

This Perl module provides fast lookup of country, region, city, latitude, longitude, ZIP code, time zone, ISP, domain name, connection type, IDD code, area code, weather station code and station, MCC, MNC, mobile carrier brand, elevation, usage type, IP address type, IAB advertising category, district, AS number and AS name from IP address using IP2Location database. This module uses a file based BIN database available at L<IP2Location Product Page|https://www.ip2location.com/database/ip2location> upon subscription. You can visit L<Libraries|https://www.ip2location.com/development-libraries> to download BIN sample files. This database consists of IP address as keys and other information as values. It supports all IP addresses in IPv4 and IPv6.

This module can be used in many types of project such as:

 1) auto-select the geographically closest mirror server
 2) analyze web server logs to determine the countries of visitors
 3) credit card fraud detection
 4) software export controls
 5) display native language and currency
 6) prevent password sharing and abuse of service
 7) geotargeting in advertisement

=head1 IP2LOCATION DATABASES

The complete IPv4 and IPv6 database are available at:

L<IP2Location Product Page|https://www.ip2location.com/database/ip2location>

The database will be updated in monthly basis for greater accuracy.

Free IP2Location LITE database is also available at:

L<IP2Location LITE Page|https://lite.ip2location.com/>

=head1 CLASS METHODS

=over 4

=item $obj = Geo::IP2Location->open($database_file);

Constructs a new Geo::IP2Location object with the database located at $database_file.

=back

=head1 OBJECT METHODS

=over 4

=item $countryshort = $obj->get_country_short( $ip );

Returns the ISO 3166 country code of IP address or domain name. Returns "-" for unassigned or private IP address.

=item $countrylong = $obj->get_country_long( $ip );

Returns the full country name of IP address or domain name. Returns "-" for unassigned or private IP address.

=item $region = $obj->get_region( $ip );

Returns the region of IP address or domain name.

=item $city = $obj->get_city( $ip );

Returns the city of IP address or domain name.

=item $latitude = $obj->get_latitude( $ip );

Returns the latitude of IP address or domain name.

=item $longitude = $obj->get_longitude( $ip );

Returns the longitude of IP address or domain name.

=item $isp = $obj->get_isp( $ip );

Returns the ISP name of IP address or domain name.

=item $domain = $obj->get_domain( $ip );

Returns the domain name of IP address or domain name.

=item $zip = $obj->get_zipcode( $ip );

Returns the ZIP code of IP address or domain name.

=item $tz = $obj->get_timezone( $ip );

Returns the time zone of IP address or domain name.

=item $ns = $obj->get_netspeed( $ip );

Returns the connection type (DIAL, DSL or COMP) of IP address or domain name.

=item $idd = $obj->get_iddcode( $ip );

Returns the country IDD calling code of IP address or domain name.

=item $area = $obj->get_areacode( $ip );

Returns the phone area code code of IP address or domain name.

=item $wcode = $obj->get_weatherstationcode( $ip );

Returns the nearest weather station code of IP address or domain name.

=item $wname = $obj->get_weatherstationname( $ip );

Returns the nearest weather station name of IP address or domain name.

=item $mcc = $obj->get_mcc( $ip );

Returns the mobile carrier code (MCC) of IP address or domain name.

=item $mnc = $obj->get_mnc( $ip );

Returns the mobile network code (MNC) of IP address or domain name.

=item $brand = $obj->get_mobilebrand( $ip );

Returns the mobile carrier brand of IP address or domain name.

=item $elevation = $obj->get_elevation( $ip );

Returns the elevation of IP address or domain name.

=item $usagetype = $obj->get_usagetype( $ip );

Returns the usage type of IP address or domain name.

=item $addresstype = $obj->get_addresstype( $ip );

Returns the IP address type (A-Anycast, B-Broadcast, M-Multicast & U-Unicast) of IP address or domain name.

=item $category = $obj->get_category( $ip );

Returns the IAB content taxonomy category of IP address or domain name.

=item $district = $obj->get_district( $ip );

Returns the district of IP address or domain name.

=item $asn = $obj->get_asn( $ip );

Returns the AS number of IP address or domain name.

=item $as = $obj->get_as( $ip );

Returns the AS name of IP address or domain name.

=item ($cos, $col, $reg, $cit, $lat, $lon, $zip, $tmz, $isp, $dom, $ns, $idd, $area, $wcode, $wname, $mcc, $mnc, $brand, $elevation, $usagetype, $addresstype, $category, $district, $asn, $as) = $obj->get_all( $ip );

Returns an array of country, region, city, latitude, longitude, ZIP code, time zone, ISP, domain name, connection type, IDD code, area code, weather station code and station, MCC, MNC, mobile carrier brand, elevation, usage type, address type, IAB advertising category, district, AS number and AS name of IP address.

=item $dbversion = $obj->get_database_version();

Returns the version number of database.

=item $moduleversion = $obj->get_module_version();

Returns the version number of Perl module.

=item $error = Geo::IP2Location::get_last_error_message();

Returns the last error message.

=back

=head1 SEE ALSO

L<IP2Location Product Page|https://www.ip2location.com>

=head1 VERSION

8.70

=head1 AUTHOR

Copyright (c) 2023 IP2Location.com

All rights reserved. This package is free software. It is licensed under the MIT. See the LICENSE file for full license information.

=cut
