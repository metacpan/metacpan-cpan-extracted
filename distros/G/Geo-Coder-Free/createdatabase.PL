#!/usr/bin/env perl

# Import data from openaddresses.io and whosonfirst.org into an SQLite database.
# Set OPENADDR_HOME and WHOSONFIRST_HOME to the directories where the data has been downloaded
# Download the OPENADDR_HOME data from http://results.openaddresses.io.
# Download the WHOSONFIRST_HOME data using https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-sqlite-download
# You can look up a WOF place by https://spelunker.whosonfirst.org/id/$locality_id

# TODO: perhaps use a layered approach to the database schema

use 5.010;
use strict;
use warnings;
# use autodie qw(:all);
use autodie;	# Don't want system() to die, we catch failures
use File::Copy;
use File::Open::NoCache::ReadOnly;
use DBI;
use Data::Dumper;
use JSON;
use LWP::UserAgent::Throttled;
use Locale::US;
use Digest::MD5;
use Encode;
use Geo::StreetAddress::US;
use CHI;
use CHI::Driver::RawMemory;
use File::Basename;
use File::Spec;
use DBD::SQLite::Constants qw/:file_open/;	# For SQLITE_OPEN_READONLY
use IO::AIO;
use Lingua::EN::AddressParse;
use Locale::SubCountry;
use Text::CSV;
use Try::Tiny;

use	constant	DEBUG_OFF => 0;
use	constant	DEBUG_INVALID_LENGTH => 1;
use	constant	DEBUG_L_EN_A => 2;
use	constant	DEBUG_NEW_LOCATION => 4;
use	constant	DEBUG_DETERMINE_LOCATION => 8;
use	constant	DEBUG_GET_WOF => 0x10;
use	constant	DEBUG_BREAKUP => 0x20;
use	constant	DEBUG_DATA_VALIDATE => 0x40;
use	constant	DEBUG_ALL => 0xFF;
use	constant	DEBUG => DEBUG_OFF;

use	constant	MAX_INSERT_COUNT => 250;	# Maximum number of CSV rows to insert in a single statement
# use	constant	MAX_INSERT_COUNT => 1;	# Maximum number of CSV rows to insert in a single statement

my %zipcodes = (
	'04350' => { city => 'Litchfield', county => 'Kennebec' },
	'04410' => { city => 'Bradford', county => 'Penobscot' },
	'04490' => { city => 'Topsfield', county => 'Washington' },
	'04653' => { city => 'Bass Harbor', county => 'Hancock' },
	'04654' => { city => 'Machias', county => 'Washington' },
	'04664' => { city => 'Sullivan', county => 'Hancock' },
	'04674' => { city => 'Seal Cove', county => 'Hancock' },
	'04677' => { city => 'Sorrento', county => 'Hancock' },
	'04679' => { city => 'Southwest Harbor', county => 'Hancock' },
	'04681' => { city => 'Stonington', county => 'Hancock' },
	'04685' => { city => 'Swans Island', county => 'Hancock' },
	'04787' => { city => 'Westfield', county => 'Aroostook' },
	'04984' => { city => 'Temple', county => 'Franklin' },
	'32346' => { city => 'Panacea', county => 'Wakulla' },
	'46204' => { city => 'Indianapolis', county => 'Marion' },
	'46206' => { city => 'Indianapolis', county => 'Marion' },
	'46222' => { city => 'Indianapolis', county => 'Marion' },
	'46231' => { city => 'Indianapolis', county => 'Marion' },
	'46282' => { city => 'Indianapolis', county => 'Marion' },
	'46259' => { city => 'Indianapolis', county => 'Marion' },
	'47001' => { city => 'Aurora', county => 'Dearborn' },
	'47864' => { city => 'New Lebanon', county => 'Sullivan' },
	'59276' => { city => 'Whitetail', county => 'Daniels' },
	'59645' => { city => 'White Sulphur Springs', county => 'Meagher' },
	'80011' => { city => 'Aurora', county => 'Arapahoe' },
	'80015' => { city => 'Aurora', county => 'Arapahoe' },
	'80016' => { city => 'Aurora', county => 'Arapahoe' },
	'80018' => { city => 'Aurora', county => 'Arapahoe' },
	'80131' => { city => 'Louviers', county => 'Douglas' },
	'80118' => { city => 'Larkspur', county => 'Douglas' },
	'80202' => { city => 'Denver', county => 'Adams' },
	'80218' => { city => 'Denver', county => 'Adams' },
	'80221' => { city => 'Denver', county => 'Adams' },
	'80222' => { city => 'Denver', county => 'Adams' },
	'80230' => { city => 'Denver', county => 'Adams' },
	'80233' => { city => 'Denver', county => 'Adams' },
	'80234' => { city => 'Denver', county => 'Adams' },
	'80236' => { city => 'Denver', county => 'Adams' },
	'80241' => { city => 'Denver', county => 'Adams' },
	'80293' => { city => 'Denver', county => 'Adams' },
	'80294' => { city => 'Denver', county => 'Adams' },
	'81501' => { city => 'Grand Junction', county => 'Mesa' },
	'81507' => { city => 'Grand Junction', county => 'Mesa' },
	'81432' => { city => 'Ridgway', county => 'Ouray' },
	'80513' => { city => 'Berthoud', county => 'Larimer' },
	'80516' => { city => 'Erie', county => 'Weld' },
	'80550' => { city => 'Windsor', county => 'Weld' },
	'80610' => { city => 'Auld', county => 'Weld' },
	'80615' => { city => 'Eaton', county => 'Weld' },
	'80631' => { city => 'Greeley', county => 'Weld' },
	'80634' => { city => 'Greeley', county => 'Weld' },
	'80642' => { city => 'Hudson', county => 'Weld' },
	'80645' => { city => 'La Salle', county => 'Weld' },
	'80650' => { city => 'Pierce', county => 'Weld' },
);

my %openaddresses_supported_countries = (
	'au' => 1,
	'ca' => 1,
	'us' => 1,
);
my @whosonfirst_only_countries = (
	'gb'
);

my %max_state_lengths = (
	'AU' => 3,
	'CA' => 2,
	'US' => 2
);

# TODO: Use Geo::Coder::Free::Local, until then keep the data in sync
my %known_places = (	# Places I've checked with my GPS
	'us/md/statewide.csv' => [
		{
			'NAME' => 'NCBI',
			'LAT' => 38.99516556,
			'LON' => -77.09943963,
			'STREET' => 'MEDLARS DR',
			'CITY' => 'BETHESDA',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20894,
		}, {
			'LAT' => 38.99698114,
			'LON' => -77.10031119,
			'STREET' => 'CENTER DR',
			'CITY' => 'BETHESDA',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
		}, {
			# 'NAME' => 'BOLD BITE',
			'LAT' => 38.98939358,
			'LON' => -77.09819543,
			'STREET' => 'NORFOLK AVE',
			'CITY' => 'BETHESDA',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
		}, {
			'LAT' => 39.028326,
			'LON' => -77.136774,
			'NAME' => 'THE ATRIUM AT ROCK SPRING PARK',
			'NUMBER' => 6555,
			'STREET' => 'ROCKLEDGE DR',
			'CITY' => 'BETHESDA',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20852,
		}, {
			'NAME' => 'ALBERT EINSTEIN HIGH SCHOOL',
			'LAT' => 39.03869019,
			'LON' => -77.0682871,
			'NUMBER' => 11135,
			'STREET' => 'NEWPORT MILL RD',
			'CITY' => 'KENSINGTON',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20895
		}, {
			'NAME' => 'POST OFFICE',
			'LAT' => 39.02554455,
			'LON' => -77.07178215,
			'NUMBER' => 10325,
			'STREET' => 'KENSINGTON PKWY',
			'CITY' => 'KENSINGTON',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20895
		}, {
			'NAME' => 'NEWPORT MILL MIDDLE SCHOOL',
			'LAT' => 39.0416107,
			'LON' => -77.06884708,
			'NUMBER' => 11311,
			'STREET' => 'NEWPORT MILL RD',
			'CITY' => 'KENSINGTON',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20895
		}, {
			'NAME' => 'SAFEWAY',
			'LAT' => 39.02822438,
			'LON' => -77.0755196,
			'NUMBER' => 10541,
			'STREET' => 'HOWARD AVE',
			'CITY' => 'KENSINGTON',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20895
		}, {
			'NAME' => 'HAIR CUTTERY',
			'LAT' => 39.03323865,
			'LON' => -77.07368044,
			'NUMBER' => 3731,
			'STREET' => 'CONNECTICUT AVE',
			'CITY' => 'KENSINGTON',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
		}, {
			'NAME' => 'STROSNIDERS',
			'LAT' => 39.02781493,
			'LON' => -77.07740792,
			'NUMBER' => 10504,
			'STREET' => 'CONNECTICUT AVE',
			'CITY' => 'KENSINGTON',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
		}, {
			'NAME' => 'FOREST GLEN MEDICAL CENTER',
			'LAT' => 39.016042,
			'LON' => -77.042148,
			'NUMBER' => 9801,
			'STREET' => 'GEORGIA AVE',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20902,
		}, {
			'LAT' => 38.993369,
			'LON' => -77.009501,
			'NAME' => 'LA CASITA PUPESERIA AND MARKET',
			'NUMBER' => 8214,
			'STREET' => 'PINEY BRANCH ROAD',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910,
		}, {
			'NAME' => 'SNIDERS',
			'LAT' => 39.0088797,
			'LON' => -77.04162824,
			'NUMBER' => 1936,
			'STREET' => 'SEMINARY RD',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910,
		}, {
			'LAT' => 39.008961,
			'LON' => -77.043030,
			'NUMBER' => 1954,
			'STREET' => 'SEMINARY RD',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910,
		}, {
			'LAT' => 39.008845,
			'LON' => -77.043317,
			'NUMBER' => 1956,
			'STREET' => 'SEMINARY RD',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910,
		}, {
			'LAT' => 39.008810,
			'LON' => -77.048953,
			'NUMBER' => 9315,
			'STREET' => 'WARREN ST',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910,
		}, {
			'LAT' => 39.036439,
			'LON' => -77.025502,
			'NAME' => 'ARCOLA HEALTH AND REHABILITATION CENTER',
			'NUMBER' => 901,
			'STREET' => 'ARCOLA AVE',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910,
		}, {
			'LAT' => 39.010436,
			'LON' => -77.048550,
			'NUMBER' => 9411,
			'STREET' => 'WARREN ST',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910,
		}, {
			'NAME' => 'SILVER DINER',
			'LAT' => 39.05798753,
			'LON' => -77.12165374,
			'NUMBER' => 12276,
			'STREET' => 'ROCKVILLE PIKE',
			'CITY' => 'ROCKVILLE',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20852
		}, {
			# LF
			'LAT' => 39.07669788,
			'LON' => -77.12306436,
			'NUMBER' => 1605,
			'STREET' => 'VIERS MILL ROAD',
			'CITY' => 'ROCKVILLE',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20851
		}, {
			'LAT' => 39.075583,
			'LON' => -77.123833,
			'NUMBER' => 1406,
			'STREET' => 'LANGBROOK PLACE',
			'CITY' => 'ROCKVILLE',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20851
		}, {
			'LAT' => 39.0147541,
			'LON' => -77.05466857,
			'NAME' => 'BP',
			'NUMBER' => 2601,
			'STREET' => 'FOREST GLEN ROAD',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910
		}, {
			'LAT' => 39.06412645,
			'LON' => -77.11252263,
			'NAME' => 'OMEGA STUDIOS',
			'NUMBER' => 12412,	# Suite 14A
			'CITY' => 'ROCKVILLE',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20852
		}, {
			'LAT' => 39.190009,
			'LON' => -76.841152,
			'NUMBER' => 7001,
			'ROAD' => 'CRADLEROCK FARM COURT',
			'CITY' => 'COLUMBIA',
			'COUNTY' => 'HOWARD',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 21045,
		}
	], 'us/me/statewide.csv' => [
		{
			'LAT' => 44.35378018,
			'LON' => -68.57383976,
			'NUMBER' => 86,
			'STREET' => 'ALLEN POINT LANE',
			'CITY' => 'BLUE HILLS',
			'COUNTY' => 'HANCOCK',
			'STATE' => 'ME',
			'COUNTRY' => 'US',
			'POSTCODE' => 04614
                }, {
                        'LAT' => 44.406700,
                        'LON' => -68.597114,
                        'NAME' => 'BANGOR AIRPORT',
                        'STREET' => 'GODFREY BOULEVARD',
                        'CITY' => 'BANGOR',
                        'COUNTY' => 'PENOBSCOT',
                        'STATE' => 'ME',
                        'COUNTRY' => 'US',
                        'POSTCODE' => 04401
		}, {
			'LAT' => 44.40670019,
			'LON' => -68.59711438,
			'NAME' => 'TRADEWINDS',
			'NUMBER' => 15,
			'STREET' => 'SOUTH STREET',
			'CITY' => 'BLUE HILLS',
			'COUNTY' => 'HANCOCK',
			'STATE' => 'ME',
			'COUNTRY' => 'US',
			'POSTCODE' => 04614
		}, {
			'LAT' => 44.40662476,
			'LON' => -68.59610059,
			'NAME' => 'RITE AID',
			'NUMBER' => 17,
			'STREET' => 'SOUTH STREET',
			'CITY' => 'BLUE HILLS',
			'COUNTY' => 'HANCOCK',
			'STATE' => 'ME',
			'COUNTRY' => 'US',
			'POSTCODE' => 04614
		}
	], 'us/dc/statewide.csv' => [
		{
			'LAT' => 38.955403,
			'LON' => -76.996241,
			'NUMBER' => 5350,
			'STREET' => 'CHILLUM PLACE NE',
			'CITY' => 'WASHINGTON',
			'STATE' => 'DC',
			'COUNTRY' => 'US',
			'POSTCODE' => 20011
		}
	], 'us/in/statewide.csv' => [
		{
			'LAT' => 41.074247,
			'LON' => -85.138531,
			'ROAD' => 'DOUGLAS AVE',
			'CITY' => 'FORT WAYNE',
			'COUNTY' => 'ALLEN',
			'STATE' => 'IN',
			'COUNTRY' => 'US',
			'POSTCODE' => 46802,
		}
	], 'us/oh/statewide.csv' => [
		{
			'LAT' => 39.997959,
			'LON' => -82.881320,
			'NAME' => 'JOHN GLENN AIRPORT',
			'NUMBER' => 4600,
			'ROAD' => 'INTERNATIONAL GATEWAY',
			'CITY' => 'COLUMBUS',
			'COUNTY' => 'FRANKLIN',
			'STATE' => 'OH',
			'COUNTRY' => 'US',
			'POSTCODE' => 43219,
		}, {
			'LAT' => 41.379695,
			'LON' => -82.222877,
			'NAME' => 'MIDDLE RIDGE PLAZA',
			'CITY' => 'AMHERST',
			'COUNTY' => 'LOHRAIN',
			'STATE' => 'OH',
			'COUNTRY' => 'US',
			'POSTCODE' => 44001
		}, {
			'LAT' => 40.097097,
			'LON' => -83.123745,
			'NAME' => 'RESIDENCE INN BY MARRIOTT',
			'NUMBER' => '6364',
			'STREET' => 'FRANTZ RD',
			'CITY' => 'DUBLIN',
			'STATE' => 'OH',
			'COUNTRY' => 'US',
			'POSTCODE' => 43017
		}, {
			'LAT' => 41.291654,
			'LON' => -81.675815,
			'NAME' => 'TOWPATH TRAVEL PLAZA',
			'CITY' => 'BROADVIEW HEIGHTS',
			'COUNTY' => 'CUYAHOGA',
			'STATE' => 'OH',
			'COUNTRY' => 'US',
			'POSTCODE' => 44147
		}
	], 'us/pa/statewide.csv' => [
		{
			'LAT' => 40.206267,
			'LON' => -79.565682,
			'NAME' => 'NEW STANTON SERVICE PLAZA',
			'CITY' => 'HEMPFIELD',
			'STATE' => 'PA',
			'COUNTRY' => 'US',
			'POSTCODE' => 15639
		}, {
			'LAT' => 39.999154,
			'LON' => -79.046526,
			'NAME' => 'SOUTH SOMERSET SERVICE PLAZA',
			'CITY' => 'SOMERSET',
			'COUNTY' => 'SOMERSET',
			'STATE' => 'PA',
			'COUNTRY' => 'US',
			'POSTCODE' => 15501
		}
	], 'us/va/statewide.csv' => [
		{
			'LAT' => 44.40662476,
			'LON' => -68.59610059,
			'NAME' => 'THE PURE PASTY COMPANY',
			'NUMBER' => '128C',
			'STREET' => 'MAPLE AVE W',
			'CITY' => 'VIENNA',
			'COUNTY' => 'FAIRFAX',
			'STATE' => 'VA',
			'COUNTRY' => 'US',
			'POSTCODE' => 22180
		}, {
			'LAT' => 38.915635,
			'LON' => -77.225730,
			'NAME' => 'THE CAPITAL GRILLE RESTAURANT',
			'NUMBER' => 1861,
			'STEET' => 'INTERNATIONAL DR',
			'CITY' => 'MCLEAN',
			'COUNTY' => 'FAIRFAX',
			'STATE' => 'VA',
			'COUNTRY' => 'US',
			'POSTCODE' => 22102
		}
	], 'other' => [
		{
			'LAT' => 51.926793,
			'LON' => 0.70408,
			'NAME' => 'ST ANDREWS CHURCH',
			'STREET' => 'CHURCH HILL',
			'CITY' => 'EARLS COLNE',
			'STATE' => 'ESSEX',
			'COUNTRY' => 'GB'
		}, {
                        'LAT' => 51.358967,
                        'LON' => 1.391367,
                        'NAME' => 'WESTWOOD CROSS',
                        'NUMBER' => 23,
                        'STREET' => 'MARGATE ROAD',
                        'CITY' => 'BROADSTAIRS',
                        'STATE' => 'KENT',
                        'COUNTRY' => 'GB',
		}, {
			'LAT' => 51.37875,
			'LON' => 1.1955,
			'NAME' => 'RECULVER ABBEY',
			'STREET' => 'RECULVER',
			'CITY' => 'HERNE BAY',
			'STATE' => 'KENT',
			'COUNTRY' => 'GB',
		}, {
                        'LAT' => 51.357510,
                        'LON' => 1.388894,
                        'NAME' => 'TOBY CARVERY',
                        'STREET' => 'NEW HAINE ROAD',
                        'CITY' => 'RAMSGATE',
                        'STATE' => 'KENT',
                        'COUNTRY' => 'GB',
                }, {
                        'LAT' => 51.334522,
                        'LON' => 1.314417,
                        'NAME' => 'NEW INN',
                        'NUMBER' => 2,
                        'STREET' => 'TOTHILL ST',
                        # 'CITY' => 'MINSTER, THANET',
                        'CITY' => 'RAMSGATE',
                        'STATE' => 'KENT',
                        'COUNTRY' => 'GB',
		}, {
			'LAT' => 51.34320725,
			'LON' => 1.31680853,
			'NAME' => 'HOLIDAY INN EXPRESS',
			'STREET' => 'TOTHILL ST',
			# 'CITY' => 'MINSTER, THANET',
			'CITY' => 'RAMSGATE',
			'STATE' => 'KENT',
			'COUNTRY' => 'GB',
		}, {
			'LAT' => 51.334522,
			'LON' => 1.314417,
			'NAME' => 'NEW INN',
			'NUMBER' => 2,
			'STREET' => 'TOTHILL ST',
			# 'CITY' => 'MINSTER, THANET',
			'CITY' => 'RAMSGATE',
			'STATE' => 'KENT',
			'COUNTRY' => 'GB',
		}, {
			'LAT' => 51.33995174,
			'LON' => 1.31570211,
			'NUMBER' => 106,
			'STREET' => 'TOTHILL ST',
			# 'CITY' => 'MINSTER, THANET',
			'CITY' => 'RAMSGATE',
			'STATE' => 'KENT',
			'COUNTRY' => 'GB',
		}, {
			'LAT' => 51.34015944,
			'LON' => 1.31580976,
			'NUMBER' => 114,
			'STREET' => 'TOTHILL ST',
			# 'CITY' => 'MINSTER, THANET',
			'CITY' => 'RAMSGATE',
			'STATE' => 'KENT',
			'COUNTRY' => 'GB',
		}, {
			'LAT' => 51.34203083,
			'LON' => 1.31609075,
			'NAME' => 'MINSTER CEMETERY',
			'NUMBER' => 116,
			'STREET' => 'TOTHILL ST',
			# 'CITY' => 'MINSTER, THANET',
			'CITY' => 'RAMSGATE',
			'STATE' => 'KENT',
			'COUNTRY' => 'GB',
		}, {
			'LAT' => 51.33090893,
			'LON' => 1.31559716,
			'NAME' => 'ST MARY THE VIRGIN CHURCH',
			'STREET' => 'CHURCH ST',
			# 'CITY' => 'MINSTER, THANET',
			'CITY' => 'RAMSGATE',
			'STATE' => 'KENT',
			'COUNTRY' => 'GB',
		}, {
			'LAT' => 51.34772374,
			'LON' => 1.39532565,
			'NUMBER' => 20,
			'STREET' => 'MELBOURNE AVE',
			'CITY' => 'RAMSGATE',
			'STATE' => 'KENT',
			'COUNTRY' => 'GB',
		}, {
			'LAT' => 51.32711,
			'LON' => 1.406806,
			'STREET' => 'WESTCLIFF PROMENADE',
			'CITY' => 'RAMSGATE',
			'STATE' => 'KENT',
			'COUNTRY' => 'GB',
		}, {
			'LAT' => 51.5082675,
			'LON' => -0.0754225,
			'NAME' => 'TOWER OF LONDON',
			'NUMBER' => 35,
			'STREET' => 'TOWER HILL',
			'CITY' => 'LONDON',
			'STATE' => 'LONDON',
			'COUNTRY' => 'GB',
			# 'POSTCODE' => 20894,
		}
	]
);

my %postcodes = ();
my $current_state;
my %global_md5s;
my %state_md5s;
my %queued_commits;
my $city_sequence;
my %cities;
my %unknown_zips;
my %state_parent_md5s;

if(!-r 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql') {
	(system('bash bin/createdatabase') == 0)
		or warn "Can't create the SQLite database - expect poor performance";

	if(-r 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql') {
		if(-r 'blib/lib/Geo/Coder/Free/MaxMind/databases/cities.sql') {
			unlink('blib/lib/Geo/Coder/Free/MaxMind/databases/cities.sql');
		}
		copy('lib/Geo/Coder/Free/MaxMind/databases/cities.sql', 'blib/lib/Geo/Coder/Free/MaxMind/databases/cities.sql')
			or die "Can't copy SQLite file to blib: $!";
	}
}

exit(0) if($ENV{'AUTOMATED_TESTING'});

if(!(-r 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.txt')) {
	print "Consider downloading http://download.geonames.org/export/dump/allCountries.zip to lib/Geo/Coder/Free/GeoNames/databases/allCountries.txt\n";
}

$Data::Dumper::Sortkeys = 1;

if(my $oa = $ENV{'OPENADDR_HOME'}) {
	# Import openaddresses.io data into an SQLite database
	# TODO: download and unzip the files from results.openaddresses.io
	# TODO: only Australian, US and Canadian data is supported at the moment

	my $sqlite_file = "$oa/openaddresses.sql";
	exit(0) if(-r $sqlite_file);

	my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlite_file", undef, undef, { RaiseError => 1, AutoCommit => 0, synchronous => 0, locking_mode => 'EXCLUSIVE' });
	$dbh->do('PRAGMA cache_size = 65536');
	$dbh->do('PRAGMA journal_mode = OFF');
	if(!-d $oa) {
		mkdir $oa;
	}
	# $dbh->do('CREATE TABLE cities(sequence INTEGER, city VARCHAR, county VARCHAR, state VARCHAR NOT NULL, country CHAR(2) NOT NULL)');
	# $dbh->do('CREATE TABLE openaddresses(md5 CHAR(16), lat DECIMAL, lon DECIMAL, name VARCHAR, number VARCHAR, street VARCHAR, city INTEGER, FOREIGN KEY (city) REFERENCES cities(sequence))');
	if((DEBUG&DEBUG_ALL) && (MAX_INSERT_COUNT != 1)) {
		warn "MAX_INSERT_COUNT not set to 1 in DEBUG mode";
	}

	if(MAX_INSERT_COUNT == 1) {
		$dbh->do('CREATE TABLE openaddresses(md5 CHAR(16) PRIMARY KEY, lat DECIMAL, lon DECIMAL)');
	} else {
		$dbh->do('CREATE TABLE openaddresses(md5 CHAR(16), lat DECIMAL, lon DECIMAL)');
	}
	# $dbh->do('CREATE TABLE openaddresses(md5 CHAR(16) PRIMARY KEY, lat DECIMAL, lon DECIMAL, name VARCHAR, number VARCHAR, street VARCHAR, city INTEGER, FOREIGN KEY (city) REFERENCES cities(sequence))');
	# $dbh->prepare('CREATE TABLE tree(lat DECIMAL, lon DECIMAL, md5 CHAR(16) NOT NULL, parent CHAR(16))')->execute();

	print "This will take some time.\nBest to do it last thing at night and go to sleep, it should be ready in the morning.\n";

	my $filename = 'lib/Geo/Coder/Free/OpenAddresses/databases/states.txt';
	if(-r $filename) {
		# Import US states and counties from https://github.com/openaddresses/openaddresses/tree/master/us-data
		$| = 1;
		printf "%-70s\r", $filename;
		print "\n" if(DEBUG);
		$| = 0;
		my %state_fips;


		my $csv = Text::CSV->new({
			sep_char => "\t",
			allow_loose_quotes => 1,
			blank_is_undef => 1,
			empty_is_undef => 1,
			binary => 1,
			# Workaround for https://github.com/openaddresses/openaddresses/issues/3905
			# escape_char => '\\',	# Put back once issue 3905 has been fixed
		});

		my $inserts = 0;

		my $fh = File::Open::NoCache::ReadOnly->new($filename);

		my $fin = $fh->fd();

		# open(my $fin, '<', $filename);

		$csv->column_names($csv->getline($fin));

		while(my $row = $csv->getline_hr($fin)) {
			# print Data::Dumper->new([\$row])->Dump();
			my $state;
			unless($state = Locale::US->new()->{state2code}{uc($row->{'Name'})}) {
				die $row->{'Name'};
			}
			$state_fips{$row->{'State FIPS'}} = $state;
			my %columns = (
				'COUNTRY' => 'US',
				'STATE' => $state,
				'LAT' => $row->{'Latitude'},
				'LON' => $row->{'Longitude'},
			);
			# print "$zip => $query\n";
			$inserts += insert($dbh, 1, %columns);
			if($inserts >= MAX_INSERT_COUNT) {
				flush_queue($dbh);
				$inserts = 0;
			}
		}

		# close($fin);

		# Import the counties
		$filename = 'lib/Geo/Coder/Free/OpenAddresses/databases/counties.txt';
		$| = 1;
		printf "%-70s\r", $filename;
		print "\n" if(DEBUG);
		$| = 0;

		$csv = Text::CSV->new({
			sep_char => "\t",
			allow_loose_quotes => 1,
			blank_is_undef => 1,
			empty_is_undef => 1,
			binary => 1,
			# Workaround for https://github.com/openaddresses/openaddresses/issues/3905
			# escape_char => '\\',	# Put back once issue 3905 has been fixed
		});

		$fh = File::Open::NoCache::ReadOnly->new($filename);

		$fin = $fh->fd();

		# open($fin, '<', $filename);

		$csv->column_names($csv->getline($fin));

		while(my $row = $csv->getline_hr($fin)) {
			# print __LINE__, ': ', Data::Dumper->new([\$row])->Dump();
			my $state = $state_fips{$row->{'State FIPS'}};
			die $row->{'Name'} unless(defined($state));
			my $county = uc($row->{'Name'});
			$county =~ s/\s+COUNTY$//;
			$county =~ s/'/''/g;	# O'Brien County, IA
			my %columns = (
				'COUNTRY' => 'US',
				'STATE' => $state,
				'COUNTY' => $county,
				'LAT' => $row->{'Latitude'},
				'LON' => $row->{'Longitude'},
			);
			# print "$zip => $query\n";
			$inserts += insert($dbh, 1, %columns);
			if($inserts >= MAX_INSERT_COUNT) {
				flush_queue($dbh);
				$inserts = 0;
			}
		}
		# close($fin);
	}

	my $current_state;
	my $current_country;
	my %whosonfirst;
	my $wof_global_dbh;
	my $wof_global_file;
	if(my $whosonfirst = $ENV{WHOSONFIRST_HOME}) {
		$| = 1;
		printf "%-70s\r", "Traversing $whosonfirst";
		print "\n" if(DEBUG);
		$| = 0;
		foreach my $file(<"$whosonfirst/*.db">) {
			$whosonfirst{$file} = 1;
		}
		$wof_global_file = "$whosonfirst/whosonfirst-data-latest.db";
		if(-r $wof_global_file) {
			$wof_global_dbh = DBI->connect("dbi:SQLite:dbname=$wof_global_file", undef, undef, {
				sqlite_open_flags => SQLITE_OPEN_READONLY,
			});
		}

	}

	my $ua = LWP::UserAgent::Throttled->new(keep_alive => 1);
	$ua->throttle({ 'api.zippopotam.us' => 1 });
	$ua->env_proxy(1);

	# Import the Maxmind databases
	if((-r 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.txt') &&
	   open(my $fin, '<', 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.txt') &&
	   open(my $fin1, '<', 'lib/Geo/Coder/Free/MaxMind/databases/admin1.db') &&
	   (my $admin2 = File::Open::NoCache::ReadOnly->new('lib/Geo/Coder/Free/MaxMind/databases/admin2.db'))) {
	   # open(my $fin2, '<', 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db')) {
		aio_readahead($fin, 0, 10240);
		aio_readahead($fin1, 0, 10240);
		my $fin2 = $admin2->fd();
		aio_readahead($fin2, 0, 10240);

		$| = 1;
		printf "%-70s\r", 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.txt';
		$| = 0;
		print "\n" if(MAX_INSERT_COUNT == 1);

		# $csv->column_names(['key', 'name', 'asciiname', 'lat', 'long', 'skip1', 'skip2', 'country', 'state', 'county', 'skip3', 'skip4', 'skip5', 'skip6', 'skip7', 'skip8']);

		my $csv = Text::CSV->new({
			sep_char => "\t",
			allow_loose_quotes => 1,
			blank_is_undef => 1,
			empty_is_undef => 1,
			binary => 1,
			# Workaround for https://github.com/openaddresses/openaddresses/issues/3905
			# escape_char => '\\',	# Put back once issue 3905 has been fixed
		});

		$csv->column_names(['concatenated_codes', 'name', 'asciiname', 'geonameId']);

		my %admin1;

		while(my $row = $csv->getline_hr($fin1)) {
			$admin1{$row->{'concatenated_codes'}} = $row->{'asciiname'};
		}
		close($fin1);

		my %admin2;

		while(my $row = $csv->getline_hr($fin2)) {
			$admin2{$row->{'concatenated_codes'}} = $row->{'asciiname'};
		}

		# close($fin2);

		my $inserts = 0;

		while(my $line = <$fin>) {
			my @fields = split(/\t/, $line);

			my $country = lc($fields[8]);
			if(!$openaddresses_supported_countries{$country}) {
				my $found = 0;
				foreach my $c(@whosonfirst_only_countries) {
					if($country eq $c) {
						$found = 1;
						last;
					}
				}
				next if(!$found);
			}
			my $city;
			if($fields[7] ne 'ADM1') {
				# Not State/County/Province
				$city = uc($fields[2]);
			}

			my $latitude = $fields[4];
			my $longitude = $fields[5];
			my %columns;
			if($country eq 'gb') {
				my $state = $admin2{uc($country) . '.' . uc($fields[10]) . '.' . uc($fields[11])};
				next if(!defined($state));

				%columns = (
					'CITY' => $city,
					'STATE' => uc($state),
					'COUNTRY' => 'GB',
					'LAT' => $latitude,
					'LON' => $longitude,
				);
			} else {
				my $state = $admin1{uc($country) . '.' . uc($fields[10])};
				next if(!defined($state));
				$state = uc($state);
				if($state eq 'YUKON') {
					$state = 'YT';
				} elsif($state eq 'WASHINGTON, D.C.') {
					$state = 'DC';
				} elsif(my $sc = Locale::SubCountry->new($country)) {
					if(my $code = $sc->code($state)) {
						$code = uc($code);
						$state = $code if($code ne 'UNKNOWN');
						# die "$state:\n", Data::Dumper->new([\@fields])->Dump();
					} else {
						die $state;
					}
				} else {
					die "Locale::SubCountry failed on $country";
				}
				if(defined($city) && ($city =~ /(.+)\s+county$/i)) {
					%columns = (
						'COUNTY' => uc($1),
						'STATE' => uc($state),
						'COUNTRY' => uc($country),
						'LAT' => $latitude,
						'LON' => $longitude,
					);
				} else {
					%columns = (
						'CITY' => $city,
						'STATE' => uc($state),
						'COUNTRY' => uc($country),
						'LAT' => $latitude,
						'LON' => $longitude,
					);
				}
			}
			# print Data::Dumper->new([\%columns])->Dump() if(!defined($city));
			$inserts += import(row => \%columns, file => "$country/countrywide.csv", ua => $ua, dbh => $dbh, global => 1);
			if($inserts >= MAX_INSERT_COUNT) {
				flush_queue($dbh);
				$inserts = 0;
			}
		}
		close($fin);
	}
	flush_queue($dbh);

	# print "Debug exit\n" if(DEBUG&DEBUG_ALL);
	# $dbh->commit();
	# $dbh->disconnect();
	# $wof_global_dbh->disconnect();
	# exit(0);

	my %address_parsers;

	if($wof_global_dbh) {
		$wof_global_dbh->do('PRAGMA cache_size = 65536');
		my $file = basename($wof_global_file);
		# Import from the global file
		$| = 1;
		printf "%-70s\r", $file;
		$| = 0;
		print "\n" if(MAX_INSERT_COUNT == 1);

		my $inserts = 0;
		my $sth = $wof_global_dbh->prepare('SELECT body FROM geojson');
		$sth->execute() || die $wof_global_file;

		my $j = JSON->new()->utf8();
		# while(my $data = $sth->fetchrow_hashref()) {
			# if($data->{'body'}) {
				# $data = $data->{'body'};
			# }
		my $rowcache = $sth->fetchall_arrayref(undef, 10_000);
		my $region_id;
		my $region_name;
		while(my $aref = shift(@{$rowcache})) {
			if(scalar(@{$rowcache}) == 0) {
				$rowcache = $sth->fetchall_arrayref(undef, 10_000);
			}
			next if(!defined($aref));
			my $data = @{$aref}[0];
			next if(!defined($data));
			$data = $j->decode($data);
			my $properties = $data->{'properties'};
			# print "processing ", $properties->{'wof:id'}, "\n";
			next if(scalar(@{$properties->{'wof:superseded_by'}}));
			next if(exists($properties->{'mz:is_current'}) && ($properties->{'mz:is_current'} == 0));
			next if(exists($properties->{'src:geom'}) && ($properties->{'src:geom'} eq 'missing'));	# https://github.com/whosonfirst-data/whosonfirst-data/issues/1346
			my $placetype = $properties->{'wof:placetype'};
			next if($placetype eq 'country');
			next if($placetype eq 'marketarea');
			my $country = uc($properties->{'wof:country'});
			next if(!defined($country));
			if(!$openaddresses_supported_countries{lc($country)}) {
				my $found = 0;
				foreach my $c(@whosonfirst_only_countries) {
					if(lc($country) eq $c) {
						$found = 1;
						last;
					}
				}
				next if(!$found);
			}
			# print $placetype, "\n";
			my $state;
			if($placetype eq 'region') {
				# print "\t$country\n";
				if(($country eq 'US') || ($country eq 'CA') || ($country eq 'AU')) {
					$state = $properties->{'wof:abbreviation'} || $properties->{'wof:shortcode'} || $properties->{'wof:name'};
				} else {
					$state = $properties->{'wof:name'};
				}
				# print "\t$state\n";
			} else {
				$state = $properties->{'sg:province'};
				if((!defined($state)) && ($country eq 'US') && (my $rc = $properties->{'qs:gn_nameadm1'})) {
					if($rc =~ /^\[A-Z]{2}$/) {
						die $rc;
					}
				}
			}
			# if((!defined($state)) && ($placetype eq 'borough') && (my $region = $properties->{'wof:region_id'})) {
				# # FIXME:  This is probably a dup of the next if clause
				# $state = get_wof($wof_global_dbh, $region);
			# }
			if((!defined($state)) && (my $a1 = ($properties->{'as:a1'} || $properties->{'qs:a1'} || $properties->{'qs:name_adm1'} || $properties->{'woe:name_adm1'}))) {
				if(($a1 eq 'England') || ($a1 eq 'Scotland') || ($a1 eq 'Wales') || ($a1 eq 'Northern Ireland')) {
					$a1 = $properties->{'qs:name_adm2'};
				}
				if(($country eq 'US') || ($country eq 'CA') || ($country eq 'AU')) {
					if(my $sc = Locale::SubCountry->new($country)) {
						if($a1 =~ /^(.+)[\s_]COUNTY/i) {
							$a1 = $1;
						}
						$a1 =~ s/^\W+//;
						# die Data::Dumper->new([$properties])->Dump();
						if(my $code = $sc->code($a1)) {
							$code = uc($code);
							$state = $code if($code ne 'UNKNOWN');
						}
					} else {
						die "Locale::SubCountry failed on $country";
					}
				} else {
					$state = $a1;
				}
				if($state) {
					$state =~ s/^\W+//;
					if($state =~ /^CITY\[_\s]OF/i) {
						$state = undef;
					} else {
						die Data::Dumper->new([$properties])->Dump() if($state eq 'England');
						print "Gained $state from looking at the record\n" if(DEBUG&DEBUG_DETERMINE_LOCATION);
					}
				}
			}

			if(!defined($state)) {
				my @hierarchy = @{$properties->{'wof:hierarchy'}};
				if(scalar(@hierarchy) && (my $region = $hierarchy[0]->{'region_id'})) {
					if(defined($region_id) && ($region == $region_id)) {
						$state = $region_name;
						# print "Saved state = $state\n" if(DEBUG&DEBUG_ALL);
					} else {
						next if($region < 0);
						print "Getting state from hierachy:\n\t", Data::Dumper->new([$properties])->Dump() if(DEBUG&DEBUG_DETERMINE_LOCATION);
						$state = get_wof($wof_global_dbh, $region);
						if($state) {
							print "\tGot $state\n" if(DEBUG&DEBUG_DETERMINE_LOCATION);
							# Remember the region's name, since consecutive entries in the file are often the same,
							# this is save a number of calls to get_wof()
							$region_id = $region;
							$region_name = $state;
						} else {
							print "\tCouldn't work out the state\n" if(DEBUG&DEBUG_DETERMINE_LOCATION);
						}
					}
				} else {
					# print "\tcan't determine the state\n",
						# Data::Dumper->new([$properties])->Dump();
					# print "\tcan't determine the state\n";
					next;
				}
				# FIXME: the information will be in there somewhere
				# if(!defined($state)) {
					# die Data::Dumper->new([$properties])->Dump();
				# }
				next unless($state);
			}
			if($max_state_lengths{$country} && (length($state) > $max_state_lengths{$country})) {
				if(my $sc = Locale::SubCountry->new($country)) {
					if(my $code = $sc->code($state)) {
						$code = uc($code);
						$state = $code if($code ne 'UNKNOWN');
						# die Data::Dumper->new([$properties])->Dump();
					}
				} else {
					die "Locale::SubCountry failed on $country";
				}
			}
			my $city;
			if(($placetype eq 'locality') || ($placetype eq 'neighbourhood') || ($placetype eq 'borough')) {
				$city = $properties->{'wof:name'};
				if(($placetype eq 'borough') && (my $parent = $properties->{'wof:parent_id'})) {
					if(my $parent = get_wof($wof_global_dbh, $parent)) {
						$city = "$city, $parent";
					# } else {
						# Most likely the parent is in a different database
						# die "Can't determine the parent for $city in ", $properties->{'wof:id'}, "->$parent";
					}
				}
				die "Can't determine the city" if(!defined($city));
			} else {
				$city = $properties->{'sg:city'};
				# Don't trust sg:city to be correct
				my @hierarchy = @{$properties->{'wof:hierarchy'}};
				if(scalar(@hierarchy) && (my $locality = $hierarchy[0]->{'locality_id'})) {
					if(my $w = get_wof($wof_global_dbh, $locality)) {
						$city = $w;
					}
				}
			}
			if($placetype eq 'county') {
				# TODO
				# print "\tcounty: ", $properties->{'wof:name'}, ", $state, $country\n";
					# Data::Dumper->new([$properties])->Dump();
				my $row = {
					'LAT' => $properties->{'geom:latitude'},
					'LON' => $properties->{'geom:longitude'},
					'COUNTY' => uc($properties->{'wof:name'}),
					'STATE' => $state,
					'COUNTRY' => $country,
				};
				$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, global => 1);
				next;
			}
			if($city) {
				# print "\t$country, $state, $city\n";
			} else {
				# print "\t$country, $state\n";
			}
			if(!defined($city)) {
				my $address = $properties->{'addr:full'};
				next if(!defined($address));
				if(my $href = (Geo::StreetAddress::US->parse_location($address) || Geo::StreetAddress::US->parse_address($address))) {
					if($href->{city}) {
						$city = $href->{city};
					}
				}
			}
			next if(!defined($city));
			my $postcode = $properties->{'addr:postcode'};
			if($postcode) {
				$postcode = uc($postcode);
			}
			my $street = $properties->{'addr:street'};
			if($street) {
				$street = uc($street);
			}
			my $number = $properties->{'addr:number'} || $properties->{'addr:housenumber'};
			if($number) {
				$number = uc($number);
			}
			$state = uc($state);
			# print "\tqueuing ", $properties->{'wof:id'}, ': ', $properties->{'wof:name'}, ", $city, $state, $country\n";
			if(my $name = $properties->{'wof:name'}) {
				if($name ne $city) {
					my $row = {
						'LAT' => $properties->{'geom:latitude'} || $properties->{'lbl:latitude'},
						'LON' => $properties->{'geom:longitude'} || $properties->{'lbl:longitude'},
						'NAME' => uc($name),
						'NUMBER' => $number,
						'STREET' => $street,
						'CITY' => uc($city),
						'STATE' => $state,
						'COUNTRY' => $country,
						'POSTCODE' => $postcode,
					};
					unless($row->{'LAT'} && $row->{'LON'}) {
						print 'Empty LAT/LON in WOF entry ',
							$properties->{'wof:id'},
							" in $file ",
							Data::Dumper->new([$properties])->Dump()
							if(DEBUG&DEBUG_DATA_VALIDATE);
						next;
					}
					$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, global => 1);
				}
			}
			my $row = {
				'LAT' => $properties->{'geom:latitude'},
				'LON' => $properties->{'geom:longitude'},
				# 'NAME' => uc($properties->{'wof:name'}),
				'NUMBER' => $number,
				'STREET' => $street,
				'CITY' => uc($city),
				'STATE' => $state,
				'COUNTRY' => $country,
				'POSTCODE' => $postcode,
			};
			$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, global => 1);
			if(my $addr_full = $properties->{'addr:full'}) {
				my $ap;
				if($country =~ /^ENGLAND/) {
					$address_parsers{'GB'} ||= Lingua::EN::AddressParse->new(country => 'GB', auto_clean => 1, force_case => 1, force_post_code => 0);
					$ap = $address_parsers{'GB'};
				} else {
					$address_parsers{$country} ||= Lingua::EN::AddressParse->new(country => $country, auto_clean => 1, force_case => 1, force_post_code => 0);
					$ap = $address_parsers{$country};
				}
				if($ap) {
					if(my $error = $ap->parse($addr_full)) {
						# print STDERR 'Address parse failed: ', $ap->report(), "\n";
					} else {
						my %c = $ap->components();
						if(my $type = $c{'street_type'}) {
							$c{'street_name'} .= " $type";
						}
						$row = {
							'LAT' => $properties->{'geom:latitude'},
							'LON' => $properties->{'geom:longitude'},
							'NUMBER' => $c{'property_identifier'},
							'STREET' => uc($c{'street_name'}),
							'CITY' => uc($c{'suburb'}),
							'STATE' => $state,
							'COUNTRY' => $country,
							'POSTCODE' => uc($c{'post_code'}),
						};
						# print(Data::Dumper->new([$row])->Dump()) if(DEBUG&DEBUG_ALL);
						$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, global => 1);
					}
				}
			}
			if($inserts >= MAX_INSERT_COUNT) {
				flush_queue($dbh);
				$inserts = 0;
			}
		}
	}

	# print "Debug exit\n" if(DEBUG&DEBUG_ALL);
	# $dbh->commit();
	# $dbh->disconnect();
	# $wof_global_dbh->disconnect();
	# exit(0);

	# Find all of the .csv files in $OPENADDR_HOME
	foreach my $csv_file (uniq(create_tree($oa))) {
		# next unless($csv_file =~ /us\/md\/statewide/);
		# next unless($csv_file =~ /us\/ne\/dawes/);
		# next unless($csv_file =~ /us\/in\//);

		# Handle https://github.com/openaddresses/openaddresses/issues/3928
		# TODO: It would be better to merge airdrie.csv and city_of_airdrie.csv
		next if($csv_file =~ /ca\/ab\/airdrie.csv/);

		my $f = $csv_file;
		$f =~ s/^$oa\///;
		my @components = split(/\//, $f);
		if(my $country = uc($components[0])) {
			my $query;
			my $state;
			my $file;
			my $region_id;
			my $region_name;

			next unless($openaddresses_supported_countries{lc($country)});

			if($components[1] =~ /\.csv$/) {
				$file = $components[1];
			} else {
				$state = uc($components[1]);
				$file = $components[2];
			}

			# Clear the deduping hash when we can, to avoid it becoming too large
			if($country eq 'US') {
				if((!defined($current_state)) || ($state ne $current_state)) {
					print "New state, clear state_md5s; state = $state, country = $country\n" if(DEBUG&DEBUG_NEW_LOCATION);
					flush_queue($dbh);	# Check for hanging dups in current state
					%state_md5s = ();
					%state_parent_md5s = ();
					$current_country = $country;
					$current_state = $state;
				}
			} elsif((!defined($current_country)) || ($country ne $current_country)) {
				# print "New country, clear state_md5s\n";
				flush_queue($dbh);	# Check for hanging dups in current country
				%state_md5s = ();
				%state_parent_md5s = ();
				$current_country = $country;
			}

			my $inserts = 0;

			# Import this state's hand curated data
			if(my $k = $known_places{$f}) {
				# print "Known place:\n\t", Data::Dumper->new([\$k])->Dump();
				foreach my $row(@{$k}) {
					$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, global => 1);
					if($inserts >= MAX_INSERT_COUNT) {
						flush_queue($dbh);
						$inserts = 0;
					}
				}
			}

			# Import this state's Who's on First data
			# This strange loop is there to avoid importing a file more than once
			foreach my $wof_file (keys %whosonfirst) {
				if($state && ($country eq 'US')) {
					next unless($wof_file =~ /\/whosonfirst\-data\-venue\-([a-z]{2})\-([a-z]+)\-latest/);
					next if((uc($1) ne $country) || (uc($2) ne $state));
				} else {
					next unless($wof_file =~ /\/whosonfirst\-data\-venue\-([a-z]{2})\-latest/);
					next if(uc($1) ne $country);
				}
			# if(my $whosonfirst = $ENV{WHOSONFIRST_HOME}) {
				# my $wof_file;
				# if($state && ($country eq 'US')) {
					# $wof_file = "$whosonfirst/whosonfirst-data-venue-us-" . lc($state) . '-latest.db';
				# } else {
					# $wof_file = "$whosonfirst/whosonfirst-data-venue-" . lc($country) . '-latest.db';
				# }
				my $file = basename($wof_file);
				$| = 1;
				printf "%-70s\r", $file;
				$| = 0;
				print "\n" if(MAX_INSERT_COUNT == 1);
				print __LINE__, ": state = $state\n" if(DEBUG&DEBUG_NEW_LOCATION);
				my $wof_dbh = DBI->connect("dbi:SQLite:dbname=$wof_file", undef, undef, {
					sqlite_open_flags => SQLITE_OPEN_READONLY,
				});
				$wof_dbh->do('PRAGMA synchronous = OFF');
				$wof_dbh->do('PRAGMA cache_size = 65536');

				my $sth = $wof_dbh->prepare('SELECT body FROM geojson');
				$sth->execute() || die $wof_file;

				my $j = JSON->new()->utf8();
				# while(my $data = $sth->fetchrow_hashref()) {
					# if($data->{'body'}) {
						# $data = $data->{'body'};
					# }
					# next if(!defined($data));
				my $rowcache = $sth->fetchall_arrayref(undef, 10_000);
				while(my $aref = shift(@{$rowcache})) {
					if(scalar(@{$rowcache}) == 0) {
						$rowcache = $sth->fetchall_arrayref(undef, 10_000);
					}
					next if(!defined($aref));
					my $data = @{$aref}[0];
					$data = $j->decode($data);
					my $properties = $data->{'properties'};
					next if(scalar(@{$properties->{'wof:superseded_by'}}));
					next if(exists($properties->{'mz:is_current'}) && ($properties->{'mz:is_current'} == 0));
					next if($properties->{'wof:country'} ne $country);
					my $city = $properties->{'sg:city'};
					# Don't trust sg:city to be correct
					my @hierarchy = @{$properties->{'wof:hierarchy'}};
					if(scalar(@hierarchy) && (my $locality = $hierarchy[0]->{'locality_id'})) {
						if(my $w = get_wof($wof_global_dbh, $locality)) {
							$city = $w;
						}
					}
					if($country eq 'US') {
						die "$country, $state" if($state ne uc($components[1]));
					} else {
						# For the US, the state name comes from the WOF filename
						# For the rest of the world there is one WOF file per country
						$state = $properties->{'sg:region'} || $properties->{'sg:province'};
					}
					# TODO: If DEBUG_DATA_VALIDATE is set, always check the
					#	state in the hierachy is correct
					if(!defined($state)) {
						if($country eq 'US') {
							die 'States in the US should be obtained from the file name';
						}
						my @hierarchy = @{$properties->{'wof:hierarchy'}};
						if(scalar(@hierarchy) && (my $region = $hierarchy[0]->{'region_id'})) {
							if(defined($region_id) && ($region == $region_id)) {
								$state = $region_name;
								# print "Saved state = $state\n" if(DEBUG&DEBUG_ALL);
							} else {
								next if($region < 0);
								print "Getting state from hierachy:\n\t", Data::Dumper->new([$properties])->Dump() if(DEBUG&DEBUG_DETERMINE_LOCATION);
								my $state = get_wof($wof_global_dbh, $region);
								# Remember the region's name, since consecutive entries in the file are often the same,
								# this is save a number of calls to get_wof()
								$region_id = $region;
								$region_name = $state;
							}
						} else {
							# print "\tcan't determine the state\n",
								# Data::Dumper->new([$properties])->Dump();
							# print "\tcan't determine the state\n";
							next;
						}
						# FIXME: the information will be in there somewhere
						# if(!defined($state)) {
							# die Data::Dumper->new([$properties])->Dump();
						# }
						next unless($state);
					}
					if($country eq 'US') {
						die $properties->{'wof:id'}, "; $country: $state/", $components[1] if($state ne uc($components[1]));
					}
					# if($city) {
						# print "$country, $state, $city\n";
					# } else {
						# print "$country, $state\n";
					# }
					if(!defined($city)) {
						my $address = $properties->{'addr:full'};
						next if(!defined($address));
						if($country eq 'US') {
							if(my $href = (Geo::StreetAddress::US->parse_location($address) || Geo::StreetAddress::US->parse_address($address))) {
								if($href->{city}) {
									$city = $href->{city};
								}
							}
						}
					}
					next if(!defined($city));
					my $postcode = $properties->{'addr:postcode'};
					if($postcode) {
						$postcode = uc($postcode);
					}
					my $street = $properties->{'addr:street'};
					if($street) {
						$street = uc($street);
					}
					my $number = $properties->{'addr:number'} || $properties->{'addr:housenumber'};
					if($number) {
						$number = uc($number);
					}
					my $name = $properties->{'wof:name'};
					if($name) {
						$name = uc($name);
					}
					my $row = {
						'LINE' => __LINE__,
						'LAT' => $properties->{'geom:latitude'},
						'LON' => $properties->{'geom:longitude'},
						'NAME' => $name,
						'NUMBER' => $number,
						'STREET' => $street,
						'CITY' => uc($city),
						'STATE' => $state,
						'COUNTRY' => $country,
						'POSTCODE' => $postcode,
					};
					die Data::Dumper->new([$properties])->Dump() if(!defined($state));
					$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh);
					if(my $addr_full = $properties->{'addr:full'}) {
						if($inserts >= MAX_INSERT_COUNT) {
							flush_queue($dbh);
							$inserts = 0;
						}
						my $ap;
						if($country =~ /^ENGLAND/) {
							$address_parsers{'GB'} ||= Lingua::EN::AddressParse->new(country => 'GB', auto_clean => 1, force_case => 1, force_post_code => 0);
							$ap = $address_parsers{'GB'};
						} else {
							$address_parsers{$country} ||= Lingua::EN::AddressParse->new(country => $country, auto_clean => 1, force_case => 1, force_post_code => 0);
							$ap = $address_parsers{$country};
						}
						if($ap) {
							if($country eq 'us') {
								die if($state ne uc($components[1]));
							}
							if(my $error = $ap->parse($addr_full)) {
								# print STDERR 'Address parse failed: ', $ap->report(), "\n";
							} else {
								my %c = $ap->components();
								my $post_code = $c{'post_code'};
								if($post_code) {
									$post_code = uc($post_code);
								}
								if($c{'street_name'} && (my $type = $c{'street_type'})) {
									$c{'street_name'} .= " $type";
								}
								if($number && ($c{'property_identifier'} ne $number)) {
									print "diff number\n" if(DEBUG&DEBUG_L_EN_A);
								}
								if(defined($street) && (uc($c{'street_name'}) ne $street)) {
									print "diff street ($street/$c{street_name})\n" if(DEBUG&DEBUG_L_EN_A);
								}
								if(uc($c{'suburb'}) ne uc($city)) {
									print "diff city ($city/$c{suburb})\n" if(DEBUG&DEBUG_L_EN_A);
								}
								if(defined($postcode) && ($post_code && ($post_code ne $postcode))) {
									print "diff postcode\n" if(DEBUG&DEBUG_L_EN_A);
								}
								if(($number && ($c{'property_identifier'} ne $number)) ||
								   ($street && (uc($c{'street_name'}) ne $street)) ||
								   (uc($c{'suburb'}) ne uc($city)) ||
								   ($postcode && ($post_code && ($post_code ne $postcode)))) {
									print 'After ', Data::Dumper->new([$row])->Dump() if(DEBUG&DEBUG_L_EN_A);
									$row = {
										'LAT' => $properties->{'geom:latitude'},
										'LON' => $properties->{'geom:longitude'},
										'NAME' => $name,
										'NUMBER' => $c{'property_identifier'},
										'STREET' => uc($c{'street_name'}),
										'CITY' => uc($c{'suburb'}),
										'STATE' => $state,
										'COUNTRY' => $country,
										'POSTCODE' => $post_code,
									};
									print "\tAdding from L:EN:A($addr_full):\n\t", Data::Dumper->new([$row])->Dump() if(DEBUG&DEBUG_L_EN_A);
									$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh);
								}
							}
						}
					}
					if($inserts >= MAX_INSERT_COUNT) {
						flush_queue($dbh);
						$inserts = 0;
					}
				}
				$wof_dbh->disconnect();
				delete $whosonfirst{$wof_file};
				flush_queue($dbh);	# Check for hanging dups in current state
				$inserts = 0;
			}

			my $fh = File::Open::NoCache::ReadOnly->new($csv_file)
				or die($csv_file);

			my $fin = $fh->fd();

			# open(my $fin, '<', $csv_file);
			aio_readahead($fin, 0, 10240);

			$| = 1;
			printf "%-70s\r", $f;
			$| = 0;
			print "\n" if(MAX_INSERT_COUNT == 1);

			# Import this state's OpenAddresses data
			my $csv = Text::CSV->new({
				# sep_char => $sep_char,
				allow_loose_quotes => 1,
				blank_is_undef => 1,
				empty_is_undef => 1,
				binary => 1,
				# Workaround for https://github.com/openaddresses/openaddresses/issues/3905
				# escape_char => '\\',	# Put back once issue 3905 has been fixed
			});

			$csv->column_names($csv->getline($fin));

			while(my $row = $csv->getline_hr($fin)) {
				$inserts += import(country => $country, state => $state, row => $row, file => $csv_file, ua => $ua, dbh => $dbh);
				if($inserts >= MAX_INSERT_COUNT) {
					flush_queue($dbh);
					$inserts = 0;
				}
			}

			# close($fin);

			flush_queue($dbh);	# Check for hanging dups in current state
			$inserts = 0;
		}
	}

	# print "Debug exit\n" if(DEBUG&DEBUG_ALL);
	# $dbh->commit();
	# $dbh->disconnect();
	# $wof_global_dbh->disconnect();
	# exit(0);

	flush_queue($dbh);	# Check for hanging dups in last state
	%state_md5s = ();
	%state_parent_md5s = ();

	foreach my $country(@whosonfirst_only_countries) {
		# Import this country's hand curated data
		my $inserts = 0;
		if(my $k = $known_places{'other'}) {
			# print "Known place:\n\t", Data::Dumper->new([\$k])->Dump();
			foreach my $row(@{$k}) {
				$inserts += import(row => $row, file => "$country/countrywide.csv", ua => $ua, dbh => $dbh);
			}
		}

		if($inserts >= MAX_INSERT_COUNT) {
			flush_queue($dbh);
			$inserts = 0;
		}

		# Import this country's Who's on First data
		foreach my $wof_file (keys %whosonfirst) {
			next unless($wof_file =~ /\/whosonfirst\-data\-venue\-([a-z]{2})\-latest/);
			next if(lc($1) ne $country);
			my $file = basename($wof_file);
			$| = 1;
			printf "%-70s\r", $file;
			$| = 0;
			print "\n" if(MAX_INSERT_COUNT == 1);
			my $wof_dbh = DBI->connect("dbi:SQLite:dbname=$wof_file", undef, undef, {
				sqlite_open_flags => SQLITE_OPEN_READONLY,
			});
			$wof_dbh->do('PRAGMA synchronous = OFF');
			$wof_dbh->do('PRAGMA cache_size = 65536');

			my $sth = $wof_dbh->prepare('SELECT body FROM geojson');
			$sth->execute() || die $wof_file;

			my $j = JSON->new()->utf8();
			# while(my $data = $sth->fetchrow_hashref()) {
				# # print Data::Dumper->new([$data])->Dump();
				# if($data->{'body'}) {
					# $data = $data->{'body'};
				# }
				# next if(!defined($data));
			my $rowcache = $sth->fetchall_arrayref(undef, 10_000);
			while(my $aref = shift(@{$rowcache})) {
				if(scalar(@{$rowcache}) == 0) {
					$rowcache = $sth->fetchall_arrayref(undef, 10_000);
				}
				next if(!defined($aref));
				my $data = @{$aref}[0];
				$data = $j->decode($data);

				my $properties = $data->{'properties'};
				next if(scalar(@{$properties->{'wof:superseded_by'}}));
				next if(exists($properties->{'mz:is_current'}) && ($properties->{'mz:is_current'} == 0));
				next if($properties->{'wof:country'} ne $country);
				my $street = $properties->{'addr:street'};
				# next if(!defined($street));
				# https://github.com/whosonfirst-data/whosonfirst-data/issues/1193
				if($street) {
					$street =~ s/;.+$//;
					$street = uc($street);
				}
				my $city = $properties->{'sg:city'};
				# Don't trust sg:city to be correct
				my @hierarchy = @{$properties->{'wof:hierarchy'}};
				if(scalar(@hierarchy) && (my $locality = $hierarchy[0]->{'locality_id'})) {
					# print 'Check locality_id at ', __LINE__, "\n\t", Data::Dumper->new([$properties])->Dump() if(DEBUG&DEBUG_ALL);
					if(my $w = get_wof($wof_global_dbh, $locality)) {
						$city = $w;
					}
				}
				my $state = $properties->{'sg:region'} || $properties->{'sg:province'};
				my $postcode = $properties->{'addr:postcode'};
				if(defined($postcode)) {
					$postcode = uc($postcode);
				}
				if(defined($state)) {
					$state = uc($state);
				}
				if((!defined($state)) && ($country eq 'GB')) {
					if($postcode =~ /^BA1 /) {
					# if($properties->{'wof:hierarchy'}[0]->{'region_id'} == 85683823) {
						$state = 'SOMERSET';
					}
				}
				if(defined($city)) {
					$city = uc($city);
				} elsif(defined($postcode) && ($postcode =~ /^W1 /)) {
					$city = 'LONDON';
				} else {
					print STDERR "City not defined:\n\t",
						Data::Dumper->new([$data])->Dump();
					next;
				}
				if(!defined($state)) {
					my $placetype = $properties->{'wof:placetype'};
					if(($placetype eq 'venue') && scalar(@hierarchy) && (my $region = $hierarchy[0]->{'region_id'})) {
						$state = get_wof($wof_global_dbh, $region);
					}
				}
				$city =~ s/^CITY OF //g;
				# Note that if import says that if city == state, set city to undef
				if(($country eq 'GB') && ($city eq 'LONDON')) {
					# if(defined($state) && ($state ne 'GREATER LONDON')) {
						# warn Data::Dumper->new([$data])->Dump();
					# }
					$state = 'LONDON';
				} elsif(defined($state)) {
					if($state =~ /$city CITY/) {
						$state = $city;
					} elsif($state =~ /CITY OF $city/) {
						$state = $city;
					}
				}
				# print $properties->{'wof:id'}, ': ', $properties->{'wof:name'}, ", $city, $state, $country\n";
				my $row = {
					'LAT' => $properties->{'geom:latitude'},
					'LON' => $properties->{'geom:longitude'},
					'NAME' => uc($properties->{'wof:name'}),
					'STREET' => $street,
					'CITY' => $city,
					'STATE' => $state,
					'COUNTRY' => $country,
					'POSTCODE' => $postcode,
				};
				if(my $number = $properties->{'addr:housenumber'}) {
					$row->{'NUMBER'} = uc($number);
				}
				$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh);
				if(my $addr_full = $properties->{'addr:full'}) {
					my $ap;
					if($country =~ /^ENGLAND/i) {
						$address_parsers{'GB'} ||= Lingua::EN::AddressParse->new(country => 'GB', auto_clean => 1, force_case => 1, force_post_code => 0);
						$ap = $address_parsers{'GB'};
					} else {
						$address_parsers{$country} ||= Lingua::EN::AddressParse->new(country => $country, auto_clean => 1, force_case => 1, force_post_code => 0);
						$ap = $address_parsers{$country};
					}
					if($ap) {
						if(my $error = $ap->parse($addr_full)) {
							# print STDERR 'Address parse failed: ', $ap->report(), "\n";
						} else {
							my %c = $ap->components();
							my $post_code = $c{'post_code'};
							if($post_code) {
								$post_code = uc($post_code);
							}
							if(my $type = $c{'street_type'}) {
								$c{'street_name'} .= " $type";
							}
							$row = {
								'LAT' => $properties->{'geom:latitude'},
								'LON' => $properties->{'geom:longitude'},
								'NUMBER' => $c{'property_identifier'},
								'STREET' => uc($c{'street_name'}),
								'CITY' => uc($c{'suburb'}),
								'STATE' => $state,
								'COUNTRY' => $country,
								'POSTCODE' => $post_code,
							};
							print(Data::Dumper->new([$row])->Dump()) if(DEBUG&DEBUG_ALL);
							$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh);
						}
					}
				}
				if($inserts >= MAX_INSERT_COUNT) {
					flush_queue($dbh);
					$inserts = 0;
				}
			}
			$wof_dbh->disconnect();
		}
	}

	flush_queue($dbh);
	%whosonfirst = ();

	$| = 1;
	printf "%-70s\r", 'creating cities';
	print "\n" if(DEBUG);
	$| = 0;
	foreach my $key(keys %cities) {
		my ($city, $county, $state, $country) = split(/,/, $key);
		my $sequence = $cities{$key};

		$city =~ s/'/''/g;
		# my $query = "INSERT INTO cities('SEQUENCE','CITY','COUNTY','STATE','COUNTRY'" .
			# ') VALUES (' .
			# "'$sequence'," .
			# (($city eq 0) ? "NULL," : "'$city',") .
			# (($county eq 0) ? "NULL," : "'$county',") .
			# "'$state'," .
			# "'$country')";

		# # print "$query\n";
		# $dbh->do($query);
	}

	$| = 1;
	printf "%-70s\r", 'creating indicies';
	print "\n" if(DEBUG);
	$| = 0;

	# Reclaim memory
	%state_md5s = ();
	%state_parent_md5s = ();
	%global_md5s = ();
	%cities = ();

	if(MAX_INSERT_COUNT > 1) {
		# $dbh->prepare('CREATE UNIQUE INDEX sequence_index ON cities(sequence)')->execute();
		$dbh->prepare('CREATE UNIQUE INDEX md5_index ON openaddresses(md5)')->execute();
		# $dbh->prepare('CREATE UNIQUE INDEX tree_index ON tree(md5,parent)')->execute();
		# $dbh->prepare('CREATE UNIQUE INDEX node_index ON level(md5)')->execute();
		# $dbh->prepare('CREATE UNIQUE INDEX leaf_index ON leaf(md5)')->execute();
	}

	$| = 1;
	printf "%-70s\r", 'committing';
	print "\n" if(DEBUG);
	$| = 0;
	$dbh->commit();
	$dbh->disconnect();
	print ' ' x 70, "\r" if(!DEBUG);
}

# Return a list of all .csv files under the given directory
sub create_tree {
	my $where = shift;
	my @list = shift || ();

	foreach my $file(<"$where/*">) {
		next if($file =~ /summary$/);
		my $supported_country = 0;
		foreach my $c(keys %openaddresses_supported_countries) {
			if($file =~ /$c/) {
				$supported_country = 1;
				last;
			}
		}
		next unless($supported_country);
		# if(($file =~ /\.csv$/) || ($file =~ /\.geojson$/)) {
		if($file =~ /\.csv$/) {
			push(@list, $file);
			# print "$file\n";
		} elsif(-d $file) {
			push(@list, create_tree($file, @list));
		}
	}
	return @list;
}

# Import a row into the database
sub import {
	my %param;
	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(ref($_[0])) {
		die 'import: bad args';
	} elsif(@_ % 2 == 0) {
		%param = @_;
	} else {
		die 'import: no args';
	}

	my $r = $param{'row'} || die 'import: no row';
	my $row = { %{$r} };	# Take a copy of the hash because we're going to play with it
	my $country = $param{'country'} || $row->{'COUNTRY'} || die 'import: no country';
	my $state = $param{'state'} || $row->{'STATE'};	# Will come from $row->{'REGION'}
	my $file = $param{'file'} || die 'import: no file';
	my $ua = $param{'ua'} || die 'import: no ua';
	my $dbh = $param{'dbh'} || die 'import: no dbh';
	my $global = $param{'global'} || 0;
	my $inserts = 0;

	if($state) {
		$state = uc($state);
	}

	my $city = $row->{'CITY'};
	my $county = $row->{'COUNTY'};
	if(($file !~ /^statewide/) && ($file !~ /^province/) && ($file !~ /countrywide/)) {
		if($file =~ /^city_of_(.+).csv$/) {
			$city = $1;
		} elsif($file =~ /^town_of_(.+).csv$/) {
			$city = $1;
		} elsif($file =~ /^(.+)_borough.csv$/) {
			$city = $1;
		} elsif($file =~ /^(.+)-region.csv$/) {
			$city = $1;
		} elsif($file =~ /^township_of_(.+).csv$/) {
			$city = $1;
		} elsif($file =~ /^(.+)_district.csv$/) {
			$city = $1;
		} elsif(!defined($city)) {
			$city = $file;
			$city =~ s/\.csv$//;
		} elsif(($file !~ /^WHOSONFIRST\-DATA/i) && ($file !~ /countrywide/)) {
			$county = $file;
			$county =~ s/\.csv$//;
		}
	}
	if(!defined($city)) {
		# print "$state:\n", Data::Dumper->new([\$row])->Dump();
		my $zip = $row->{'POSTCODE'};
		if((!defined($city)) && defined($zip) && (my $info = $zipcodes{$zip})) {
			$city = $info->{'city'};
			$county = $info->{'county'};
		}
		if((!defined($city)) && defined($zip) && ($zip =~ /^(\d{5})/)) {
			$zip = $1;
			if(exists($unknown_zips{"$country/$zip"})) {
				return 0;
			}
			my $res = $ua->get("https://api.zippopotam.us/$country/$zip");
			if(!$res->is_success()) {
				warn "$country/$zip: ", $res->status_line();
				$unknown_zips{"$country/$zip"} = 1;
				return 0;
			}
			my $rc = JSON->new()->utf8()->decode($res->content());
			if(!defined($rc)) {
				# print "\n", Data::Dumper->new([\$row])->Dump();
				return 0;
			}
			my $place = @{$rc->{'places'}}[0];
			if(!$place) {
				# print "\n", Data::Dumper->new([\$row])->Dump();
				return 0;
			}
			$city = uc($place->{'place name'});
			$zipcodes{$zip} = { 'city' => $city };
			# print "$zip => $city\n";
			if($city) {
				# Counties and states alone have already been read in
				my %columns = (
					'COUNTRY' => $country,
					'STATE' => $state,
					'COUNTY' => $county,
					'CITY' => $city,
					'LAT' => $place->{'latitude'},
					'LON' => $place->{'longitude'},
				);
				# print "$zip => $query\n";
				$inserts = insert($dbh, $global, %columns);
			}
		}
		if((!defined($city)) && !defined($state)) {
			# die Data::Dumper->new([\$row])->Dump();
			return 0 if(!$zip);
			return 0 if($zip !~ /^\d{5}/);
			$dbh->disconnect();
			die $file;
		}
	}
	if((!defined($row->{'LAT'})) || !defined($row->{'LON'})) {
		my @call_details = caller(0);
		print 'Empty LAT/LON in ',
			($state ? "$state/" : ''),
			"$file from line $call_details[2]: ",
			Data::Dumper->new([$row])->Dump()
			if(DEBUG&DEBUG_DATA_VALIDATE);
		return 0;
	}
	return 0 if(($row->{'LAT'} == 0) && ($row->{'LON'} == 0));
	my $street = $row->{'STREET'};
	if($street && $city && ($city =~ /(.+),\s*(.+)/)) {
		# For example the city could be "North Side, Chicago", which comes from the case when a borough record
		# has been added.  Let's allow searches on the borough or the city alone
		my $borough = $1;
		my $city_name = $2;
		print "Break up $city\n\tstreet = $street\n\tborough = $borough\n\tcity_name = $city_name\n" if(DEBUG&DEBUG_BREAKUP);
		if($borough ne $street) {
			my %columns = ( %{$param{'row'}}, 'COUNTRY' => $country, 'STATE' => $state, 'COUNTY' => $county, 'CITY' => $borough );
			print "\t", Data::Dumper->new([\%columns])->Dump() if(DEBUG&DEBUG_BREAKUP);
			$inserts += insert($dbh, $global, %columns);
			$columns{'CITY'} = $city_name;
			print "\t", Data::Dumper->new([\%columns])->Dump() if(DEBUG&DEBUG_BREAKUP);
			$inserts += insert($dbh, $global, %columns);
			print "\tDone\n" if(DEBUG&DEBUG_BREAKUP);
		}
	}
	if($city) {
		$city =~ s/\.csv$//;
		$city =~ s/[_,\-\.]/ /g;
		$city = uc($city);
		$city =~ s/\s+BORO$//;
		$city =~ s/\s+TWP$//;
		$city =~ s/^TOWN\s+OF\s+//;
		$city =~ s/^CITY\s+OF\s+//i;
		$city =~ s/^THE\s+CITY\s+OF\s+//i;
		$city =~ s/^TOWNSHIP\s+OF\s+//;
		$city =~ s/\s\s+/ /g;
		$city =~ s/\s+$//g;
		$city =~ s/^\s+//g;
	}
	if($street) {
		$street = uc($street);
		if($street =~ /(.+)\s+STREET$/) {
			$street = "$1 ST";
		} elsif($street =~ /(.+)\s+ROAD$/) {
			$street = "$1 RD";
		} elsif($street =~ /(.+)\s+AVENUE$/) {
			$street = "$1 AVE";
		} elsif($street =~ /(.+)\s+AVENUE\s+(.+)/) {
			$street = "$1 AVE $2";
		} elsif($street =~ /(.+)\s+COURT$/) {
			$street = "$1 CT";
		} elsif($street =~ /(.+)\s+CENTER$/) {
			$street = "$1 CTR";
		} elsif($street =~ /(.+)\s+DRIVE$/) {
			$street = "$1 DR";
		} elsif($street =~ /(.+)\s+CIRCLE$/) {
			$street = "$1 CIR";
		} elsif($street =~ /(.+)\s+PARKWAY$/) {
			$street = "$1 PKWY";
		} elsif($street =~ /(.+)\s+SPRING$/) {
			$street = "$1 SPG";
		} elsif($street =~ /(.+)\s+RIDGE$/) {
			$street = "$1 RDG";
		} elsif($street =~ /(.+)\s+LANE$/) {
			$street = "$1 LN";
		} elsif($street =~ /(.+)\s+PLACE$/) {
			$street = "$1 PL";
		} elsif($street =~ /(.+)\s+GARDENS$/) {
			$street = "$1 GRDNS";
		} elsif($street =~ /(.+)\s+HIGHWAY$/) {
			$street = "$1 HWY";
		} elsif($street =~ /(.+)\s+CREEK$/) {
			$street = "$1 CRK";
		}
		$street =~ s/^0+//;	# Turn 04th St into 4th St
	}
	if($file =~ /^(.+)[_\-]county.csv$/) {
		$county = $1;
	} elsif((!defined($county)) && defined($city)) {
		if($city =~ /(.+)\s+COUNTY$/i) {
			$county = $1;
			$city = undef;
		}
	}
	if((!defined($county)) && $row->{'DISTRICT'} && ($row->{'DISTRICT'} ne $state)) {
		if($row->{'DISTRICT'} !~ /^\d+$/) {
			$county = $row->{'DISTRICT'};
		}
	}
	if($county) {
		if($city) {
			if($city =~ /\s+COUNTY$/i) {
				my $tmp = $city;
				$city = $county;
				$county = $tmp;
			}
			if(($city eq $county) ||
			   ($city eq "$county COUNTY") ||
			   ($county eq "$city COUNTY")) {
				$city = undef;
			}
		}
		$county = uc($county);
		$county =~ s/_/ /g;
		$county =~ s/\s+COUNTY$//;
		$county =~ s/\s\s+/ /g;
		$county =~ s/\s+$//g;
		$county =~ s/^\s+//g;
	}
	if(defined($state)) {
		if($state eq 'IN') {
			if(defined($city) && ($city eq 'FW')) {
				$city = 'FORT WAYNE';
				$county = 'ALLEN';
			} elsif(defined($county) && ($county eq 'LAPORTE')) {
				$county = 'LA PORTE';
			}
		} elsif($state eq 'MO') {
			if(defined($city) && ($city eq 'SAINT LOUIS')) {
				$city = 'ST. LOUIS';
				$county = undef;
			}
		}
	}
	if(($city && ($city !~ /^\s+$/)) || $county || $state) {
		my %columns = (
			'COUNTRY' => $country,
			'CITY' => $city,
			'STATE' => $state,
			'COUNTY' => $county,
			'STREET' => $street
		);
		if($street) {
			$row->{'STREET'} =~ s/\s\s+/ /g;
		}
		foreach my $c('LAT', 'LON', 'NAME', 'NUMBER') {
			$columns{$c} = $row->{$c};
		}
		if((!defined($city)) ||
		   ($country eq 'GB') && ($city eq 'LONDON') && defined($state) && ($state eq 'LONDON')) {
			delete $columns{'CITY'};
		}
		foreach my $column(keys %columns) {
			delete $columns{$column} if(!defined($columns{$column}));
		}
		if((!defined($city)) && defined($street) && defined($row->{'REGION'}) && !defined($county)) {
			$county = uc($row->{'REGION'});
			if(!defined($street)) {
				print "County and street with no city:\n", Data::Dumper->new([$row])->Dump() if($county && (DEBUG&DEBUG_DATA_VALIDATE));
				return $inserts;
			}
		}
		# print Data::Dumper->new([\%columns])->Dump() if(!defined($city) && !defined($county));
		$inserts += insert($dbh, $global, %columns);
		if(delete($columns{'COUNTY'})) {
			return $inserts if(!defined($city));
			$inserts += insert($dbh, $global, %columns);
		}
		my $name = $columns{'NAME'};
		if($name) {
			# TODO: more of these
			# foreach my $classifier($properties->{'sg:classifier'}) {
			#	Check if $name ends with uc($classifier->{category})
			if($name =~ /^(.+)\s+RESTAURANT/i) {
				$columns{'NAME'} = $1;
				$inserts += insert($dbh, $global, %columns);
				# print "RESTAURANT: $1\n";
			}
			if(delete($columns{'NAME'})) {
				$inserts += insert($dbh, $global, %columns);
			}
		}
		if(delete($columns{'NUMBER'})) {
			if($name) {
				# For when a name is known but not a street number
				$columns{'NAME'} = $name;
				$inserts += insert($dbh, $global, %columns);
				if($name =~ /^(.+)\s+RESTAURANT/i) {
					$columns{'NAME'} = $1;
					$inserts += insert($dbh, $global, %columns);
					# print "RESTAURANT: $1\n";
				}
				delete($columns{'NAME'});
			}
			# Match somewhere in the street when number isn't known
			$inserts += insert($dbh, $global, %columns);
			if(delete($columns{'STREET'})) {
				if($name) {
					# For when a name is known but not a street
					$columns{'NAME'} = $name;
					$inserts += insert($dbh, $global, %columns);
					if($name =~ /^(.+)\s+RESTAURANT/i) {
						$columns{'NAME'} = $1;
						$inserts += insert($dbh, $global, %columns);
						# print "RESTAURANT: $1\n";
					}
					delete($columns{'NAME'});
				}
				# Match somewhere in the city when street isn't known
				$inserts += insert($dbh, $global, %columns);
			}
		} elsif($name && delete($columns{'STREET'})) {
			# For when a name is known but not a street
			$columns{'NAME'} = $name;
			$inserts += insert($dbh, $global, %columns);
			if($name =~ /^(.+)\s+RESTAURANT/i) {
				$columns{'NAME'} = $1;
				$inserts += insert($dbh, $global, %columns);
				# print "RESTAURANT: $1\n";
			}
		}
	}
	return $inserts;
}

# Insert data into the database, returns the number of new rows
sub insert {
	my ($dbh, $global, %columns) = @_;

	foreach my $column(keys %columns) {
		if(!defined($columns{$column})) {
			delete $columns{$column};
		} elsif($columns{$column} =~ /^\s+$/) {
			delete $columns{$column};
		}
	}

	# print Data::Dumper->new([$columns])->Dump() if($columns{'CITY'} && (uc($columns{'CITY'}) eq 'INDIANAPOLIS'));
	# print Data::Dumper->new([$columns])->Dump() if($columns{'NAME'} && (uc($columns{'NAME'}) eq 'EL PAPI STREET TACOS'));
	# {
		# my @call_details = caller(0);
		# print "line " . $call_details[2], "\n";
		# print Data::Dumper->new([\%columns])->Dump();
	# }

	my $lat = $columns{'LAT'};
	my $lon = $columns{'LON'};

	die Data::Dumper->new([\%columns])->Dump() unless(defined($lat) && defined($lon));
	# die "$lat/$lon" unless($columns{'STATE'});

	# Remove duplicate, leading and trailing spaces from entries.  Some openaddresses files are littered with them
	foreach my $column(keys %columns) {
		$columns{$column} =~ s/\s+$//g;
		$columns{$column} =~ s/^\s+//g;
		$columns{$column} =~ s/\s\s+/ /g;
	}

	# my $digest = Digest::MD5::md5_base64(map { Encode::encode_utf8($columns{$_}) } sort keys %{$columns});
	my $digest;
	# print Data::Dumper->new([$columns])->Dump();
	foreach my $column('NAME','NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
		$digest .= $columns{$column} if($columns{$column});
	}
	# print "$digest\n";
	$digest = create_md5($global, Encode::encode_utf8($digest));

	if(!defined($digest)) {
		# print "Ignore ", join(',', values(%columns)), "\n";
		return 0;
	}

	# if(!defined($columns{'CITY'}) && !defined($columns{'COUNTY'})) {
		# my @call_details = caller(0);
		# print $call_details[2], '->', __LINE__, ": $digest:\n", Data::Dumper->new([\%columns])->Dump() if($columns{'COUNTRY'} eq 'US');
	# }
	# print "$digest\n";

	# $dbh->prepare("SELECT * FROM openaddresses WHERE MD5 = '$digest'");
	# $sth->execute();
	# while(my $href = $sth->fetchrow_hashref()) {
		# my @call_details = caller(0);
		# print "line " . $call_details[2], "\n";
		# print Data::Dumper->new([\%columns])->Dump();
		# print Data::Dumper->new([$href])->Dump();
	# }

	my @call_details = caller(0);
	$columns{'LINE'} = $call_details[2] if(DEBUG);
	$queued_commits{$digest} = \%columns;
	if(DEBUG&DEBUG_ALL) {
		flush_queue($dbh);
	}
	if(!defined($columns{'COUNTRY'})) {
		print "insert: no country. Called from line " . $call_details[2], "\n";
		die Data::Dumper->new([\%columns])->Dump();
	}
	my $key = city_key($columns{'CITY'}, $columns{'COUNTY'}, $columns{'STATE'}, $columns{'COUNTRY'});
	if(!$cities{$key}) {
		$city_sequence++;
		# print "adding '$key' to cities list\n";
		$cities{$key} = $city_sequence;
	}

	# Some postal address parsers have problems with "N FOO ST", so also store "NFOOST"
	if($columns{'STREET'} && ($columns{'STREET'} =~ /^[A-Z]\s\w+\s\w+$/)) {
		my %columns2 = %columns;
		# Handle https://rt.cpan.org/Public/Bug/Display.html?id=124919
		$columns2{'STREET'} =~ s/\s+//g;
		$columns2{'LINE'} = $call_details[2] if(DEBUG);
		$digest = undef;

		foreach my $column('NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
			$digest .= $columns2{$column} if($columns2{$column});
		}
		if($digest = create_md5($global, Encode::encode_utf8($digest))) {
			$queued_commits{$digest} = \%columns2;
			if(DEBUG&DEBUG_ALL) {
				flush_queue($dbh);
			}
			return 2;
		# } else {
			# print "Ignore ", join(',', values(%columns2)), "\n";
		}
	}
	return 1;
}

# All of the place's values are combined into one INSERT INTO
# Be aware of https://github.com/openaddresses/openaddresses/issues/3928
sub flush_queue
{
	my $dbh = shift;

	# print "flush\n" if(DEBUG&DEBUG_ALL);

	# my @columns = ('LAT','LON','NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY');
	my @columns = ('LAT','LON','NAME','NUMBER','STREET');

	my $query;

	keys %queued_commits;
	# print scalar(keys %queued_commits), "\n";
	# while(my($md5, $row) = each %queued_commits) {
	foreach my $md5(keys %queued_commits) {
		my $row = $queued_commits{$md5};
		# if($md5 eq 'D8GO4pMZCAYej/OR') {
			# my @call_details = caller(0);
			# print "flush_queue: Flomation called from line ", $call_details[2], "\n\t",
				# Data::Dumper->new([\%queued_commits])->Dump();
		# }
		die if(ref($row) ne 'HASH');
		my $country = $row->{'COUNTRY'};
		if(!defined($country)) {
			my @call_details = caller(0);
			print "flush_queue: called from line ", $call_details[2], "\n";
			die Data::Dumper->new([$row])->Dump();
		}
		my $state = $row->{'STATE'};
		if($max_state_lengths{$country} && $state && (length($state) > $max_state_lengths{$country})) {
			print STDERR 'Invalid state length: ', Data::Dumper->new([$row])->Dump() if(DEBUG&DEBUG_INVALID_LENGTH);
			next;
		}
		if(length($country) != 2) {
			print STDERR "Invalid country length:\n", Data::Dumper->new([$row])->Dump() if(DEBUG&DEBUG_INVALID_LENGTH);
			next;
		}

		# die Data::Dumper->new([$row])->Dump() unless ($row->{'LAT'} && $row->{'LON'});
		unless ($row->{'LAT'} && $row->{'LON'}) {
			my @call_details = caller(0);
			print "flush_queue: ignoring blank entry called from line ", $call_details[2], "\n\t",
				Data::Dumper->new([$row])->Dump() if(DEBUG&DEBUG_DATA_VALIDATE);
			next;
		}

		if(!defined($query)) {
			$query = 'INSERT INTO openaddresses(LAT, LON, MD5) VALUES (';
		} else {
			$query .= ',(';
		}

		# print join(',', @columns), ": $md5\n";
		# print "$md5: ", Data::Dumper->new([$row])->Dump();

		my $key = city_key($row->{'CITY'}, $row->{'COUNTY'}, $state, $country);
		$query .= $row->{'LAT'} . ',' . $row->{'LON'} . ",'$md5')";

		# foreach my $column(@columns) {
			# if($row->{$column}) {
				# if(($column eq 'LAT') || ($column eq 'LON') || ($column eq 'CITY')) {
					# $query .= $row->{$column} . ',';
				# } else {
					# $row->{$column} =~ s/'/''/g;
					# $query .= "'" . $row->{$column} . "',";
				# }
			# } else {
				# $query .= 'NULL,';
			# }
		# }
		# die $key unless $cities{$key};
		# $query .= $cities{$key} . ",'$md5')";
	}

	my $tree_query;
	# while(my($md5, $row) = each %queued_commits) {
	if(0) {
		my $row;
		my $digest = $row->{'COUNTRY'};
		my $parent_md5;

		my $md5 = $state_parent_md5s{$digest};
		if(!defined($md5)) {
			$md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
			$state_parent_md5s{$md5} = $digest;
			if(!defined($tree_query)) {
				$tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
			} else {
				$tree_query .= ',(';
			}
			$tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
				",'$md5',NULL)";
		}

		$digest = undef;
		foreach my $column('STATE','COUNTRY') {
			$digest .= $row->{$column} if($row->{$column});
		}
		$parent_md5 = $md5;
		$md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
		if(!defined($state_parent_md5s{$md5})) {
			$state_parent_md5s{$md5} = $digest;
			if(!defined($tree_query)) {
				$tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
			} else {
				$tree_query .= ',(';
			}
			$tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
				",'$md5','$parent_md5')";
		}

		if($row->{'COUNTY'}) {
			$digest = undef;
			foreach my $column('COUNTY','STATE','COUNTRY') {
				$digest .= $row->{$column} if($row->{$column});
			}
			$parent_md5 = $md5;
			$md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
			if(!defined($state_parent_md5s{$md5})) {
				$state_parent_md5s{$md5} = $digest;
				if(!defined($tree_query)) {
					$tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
				} else {
					$tree_query .= ',(';
				}
				$tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
					",'$md5','$parent_md5')";
			}
		}
		if($row->{'CITY'}) {
			$digest = undef;
			foreach my $column('CITY','COUNTY','STATE','COUNTRY') {
				$digest .= $row->{$column} if($row->{$column});
			}
			$parent_md5 = $md5;
			$md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
			if(!defined($state_parent_md5s{$md5})) {
				$state_parent_md5s{$md5} = $digest;
				if(!defined($tree_query)) {
					$tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
				} else {
					$tree_query .= ',(';
				}
				$tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
					",'$md5','$parent_md5')";
			}
		}
		if($row->{'STREET'}) {
			$digest = undef;
			foreach my $column('STREET','CITY','COUNTY','STATE','COUNTRY') {
				$digest .= $row->{$column} if($row->{$column});
			}
			$parent_md5 = $md5;
			$md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
			if(!defined($state_parent_md5s{$md5})) {
				$state_parent_md5s{$md5} = $digest;
				if(!defined($tree_query)) {
					$tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
				} else {
					$tree_query .= ',(';
				}
				$tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
					",'$md5','$parent_md5')";
			}
		}
		if($row->{'NUMBER'}) {
			$digest = undef;
			foreach my $column('NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
				$digest .= $row->{$column} if($row->{$column});
			}
			$parent_md5 = $md5;
			$md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
			if(!defined($state_parent_md5s{$md5})) {
				$state_parent_md5s{$md5} = $digest;
				if(!defined($tree_query)) {
					$tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
				} else {
					$tree_query .= ',(';
				}
				$tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
					",'$md5','$parent_md5')";
			}
		}

		# TODO: add NAME field
	}

	if($query) {
		# print "$query\n";
		# $| = 1;
		# print '.';
		# $| = 0;
		try {
			$dbh->do($query);
		} catch {
			my @call_details = caller(1);
			print "Error in flush_queue ($query) called from line ", $call_details[2], "\n\t",
				Data::Dumper->new([\%queued_commits])->Dump();
			die $_;
		};
	}
	# if($tree_query) {
	if(0) {
		# print "$tree_query\n";
		# $| = 1;
		# print '.';
		# $| = 0;
		try {
			$dbh->do($tree_query);
		} catch {
			print Data::Dumper->new([\%queued_commits])->Dump();
			die $_;
		};
	}
	%queued_commits = ();
}

sub create_md5
{
	my $global = shift;

	# my $digest = Digest::MD5::md5_base64(@_);
	my $digest = substr Digest::MD5::md5_base64(@_), 0, 16;
	return if($global_md5s{$digest} || $state_md5s{$digest} || $queued_commits{$digest});

	# print join(',', @_), ": $digest\n";
	if($global) {
		$global_md5s{$digest} = 1;
	}
	$state_md5s{$digest} = 1;
	return $digest;
}

sub uniq {
	my %seen;
	grep !$seen{$_}++, @_;
}

# State must be the abbreviated form
sub city_key {
	my ($city, $county, $state, $country) = @_;

	if(!defined($city)) {
		$city = '0';
	}
	if(!defined($county)) {
		$county = '0';
	}
	if(!defined($state)) {
		return "$city,$county,0,$country";
	}
	return "$city,$county,$state,$country";
}

# Given a Whosonfirst ID, return the matching geojson. Cache lookups
sub get_wof {
	my ($dbh, $id) = @_;

	state %l1_cache;
	state $l2_cache;

	if($l1_cache{$id}) {
		# my @call_details = caller(0);
		# print "get_wof: stored $l1_cache{$id} at line " . $call_details[2], "\n" if(DEBUG&DEBUG_ALL);
		return $l1_cache{$id};
	}
	if(scalar(keys %l1_cache) >= 50) {
		%l1_cache = ();
	}

	if(defined($l2_cache)) {
		if(my $name = $l2_cache->get($id)) {
			my @call_details = caller(0);
			print "get_wof: cached $name at line " . $call_details[2], "\n" if(DEBUG&DEBUG_GET_WOF);
			$l1_cache{$id} = $name;
			return $name;
		}
	} else {
		$l2_cache = CHI->new(driver => 'RawMemory', global => 0, max_size => 1_000);
	}

	# print "get_wof: not cached $id\n";

	my $query = "SELECT body FROM geojson where id = $id LIMIT 1";
	my $sth = $dbh->prepare($query);
	$sth->execute() || die($query);
	my $data = $sth->fetchrow_arrayref();
	return if(!defined($data));
	# print Data::Dumper->new([@{$data}])->Dump();
	# print "\n", 'x' x 70, "\n";
	$data = JSON->new()->utf8()->decode(@{$data});
	my $properties = $data->{'properties'};
	return if(scalar(@{$properties->{'wof:superseded_by'}}));
	return if(exists($properties->{'mz:is_current'}) && ($properties->{'mz:is_current'} == 0));
	# if($properties->{'wof:name'}) {
		if($properties->{'wof:placetype'} eq 'region') {
			my $country = uc($properties->{'wof:country'});
			if(($country eq 'US') || ($country eq 'CA') || ($country eq 'AU')) {
				return $l1_cache{$id} = $l2_cache->set($id, $properties->{'wof:abbreviation'} || $properties->{'wof:shortcode'} || $properties->{'wof:name'}, '1 minute');
			}
		}
		return $l1_cache{$id} = $l2_cache->set($id, $properties->{'wof:name'}, '1 minute');
	# }
}
