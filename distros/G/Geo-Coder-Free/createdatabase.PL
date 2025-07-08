#!/usr/bin/env perl

# Import geo-coding data into an SQLite database.

# Software copyright 2020-2024 Nigel Horne.

# Except for the "known_places" database, all the databases are copyrighted by third parties.
#	I've tried my best to acknowledge that, but if I haven't please let me know.

# The program code is released under the following licence: GPL2 for personal use on a single computer.
# All other users (including Commercial, Charity, Educational, Government)
# must apply in writing for a licence for use from Nigel Horne at <njh at nigelhorne.com>.

# -f:	force a build, otherwise it won't build on CPAN smokers or if the
#	database already exists

# Set OSM_HOME, OPENADDR_HOME, DR5HN_HOME and WHOSONFIRST_HOME to the directories where the data will be downloaded

# see bin/download_databases which will download the databases and call this script

# Download the OPENADDR_HOME data from http://results.openaddresses.io.
#	cd $OPENADDR_HOME
#	wget --quiet https://data.openaddresses.io/openaddr-collected-global.zip
#	wget --quiet https://data.openaddresses.io/openaddr-collected-global-sa.zip
# or
#	wget -nc --quiet https://s3.amazonaws.com/data.openaddresses.io/openaddr-collected-global.zip
#	wget -nc --quiet https://s3.amazonaws.com/data.openaddresses.io/openaddr-collected-global-sa.zip
#	unzip openaddr-collected-global.zip
#	unzip openaddr-collected-global-sa.zip
# Remove all the data you're not going to use, I only keep au, ca, us
#	echo ?? | sed 's/ /\n/g' | egrep -v '(au|ca|us)' | xargs rm -rf
#	rm -rf summary

# Download the WHOSONFIRST_HOME data from repositories such as
#	https://github.com/whosonfirst-data/whosonfirst-data-venue-us.git
#	I use whosonfirst-data-[venue|admin]-[au|gb|us|ca].git
#	I use whosonfirst-data-[venue]-us-??.git

# Download the DR5HN database:
#	cd $DR5HN_HOME && git clone https://github.com/dr5hn/countries-states-cities-database.git

# Openstreetmap.org data
#	cd $OSM_HOME && /usr/bin/wget https://download.geofabrik.de/europe-latest.osm.bz2
# Note that this can take a day to load in just AU, CA, GB, US

# You can look up a WOF place at https://spelunker.whosonfirst.org/id/$locality_id
#
# Try:
#	sqlite3 whosonfirst-data-latest.db
#	select body from geojson where body like '%north shields%';
# It'll be slow, but it shows the sort of thing this is about,
#	You'll see an id: field (e.g. 1108937103), then look at
#	https://spelunker.whosonfirst.org/id/1108937103

# TODO: perhaps use a layered approach to the database schema
# TODO: import https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/countries%2Bstates%2Bcities.json
# TODO: as the database is a simple key/value pair, perhaps CDB will be better

use 5.010;
use strict;
use warnings;
# use autodie qw(:all);
use autodie;	# Don't want system() to die, we catch failures
use Cwd;
use Data::Dumper;
# use BerkeleyDB;
use DB_File;
use DBD::SQLite::Constants qw/:file_open/;	# For SQLITE_OPEN_READONLY
use DBI;
use File::Copy;
use File::Slurp;
use Geo::Coder::Abbreviations;
use Geo::Hash;
use JSON::MaybeXS;
use LWP::ConnCache;
use LWP::UserAgent::Throttled;
use Locale::AU;	# TODO: use Locale::Geocode
use Locale::CA;
use Locale::Country;
use Locale::US;
use Digest::MD5;
use Encode;
use Geo::StreetAddress::US;
use CHI;
use CHI::Driver::RawMemory;
use File::Basename;
use File::Find;
use File::Spec;
use Lingua::EN::AddressParse;
use Locale::SubCountry;
use Text::CSV;
use Try::Tiny;
use Devel::Size;

# ONE or ALL - import from one database or all of them
# ALL uses HUGE amounts of RAM
use	constant	BUILDMODE => 'ALL';

use	constant	AIO_READAHEAD_SIZE => 1048576;	# 1MB

use	constant	DEBUG_OFF => 0;
use	constant	DEBUG_INVALID_LENGTH => 1;
use	constant	DEBUG_L_EN_A => 2;
use	constant	DEBUG_NEW_LOCATION => 4;
use	constant	DEBUG_DETERMINE_LOCATION => 8;
use	constant	DEBUG_GET_WOF => 0x10;
use	constant	DEBUG_BREAKUP => 0x20;
use	constant	DEBUG_DATA_VALIDATE => 0x40;
use	constant	DEBUG_FLUSH => 0x80;
use	constant	DEBUG_SIZE => 0x100;
use	constant	DEBUG_MD5 => 0x200;
use	constant	DEBUG_INSERT => 0x400;
use	constant	DEBUG_KNOWN_PLACES => 0x800;	# Only import the known_places hash
use	constant	DEBUG_OSM => 0x1000;	# Test - and only import, the OSM_HOME data
use	constant	DEBUG_WOF => 0x2000;	# Test - and only import, the WHOSONFIRST_HOME data
use	constant	DEBUG_DR5HN => 0x4000;
use	constant	DEBUG_ALL => 0xFFFF;	# Test - and only import, the DR5HN data
use	constant	DEBUG => DEBUG_OFF;

use	constant	MAX_INSERT_COUNT => 250;	# Maximum number of CSV rows to insert in a single statement
# use	constant	MAX_INSERT_COUNT => 1;	# Maximum number of CSV rows to insert in a single statement

binmode(STDOUT, "encoding(UTF-8)");
binmode(STDERR, "encoding(UTF-8)");

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

my %openaddresses_countries = (
	'au' => 1,
	'ca' => 1,
	'us' => 1,
);
my @whosonfirst_only_countries = (
	'gb'
);
my %osm_countries = (
	us => 1,
	canada => 1,
	gb => 1,
	australia => 1
);

my %max_state_lengths = (
	'AU' => 3,
	'CA' => 2,
	'US' => 2
);

# TODO: Use Geo::Coder::Free::Local, until then keep the data in sync
# Ensure you use abbreviations, e.e. RD not ROAD
my %known_places = (	# Places I've checked with my GPS
	'us/ks/statewide.csv' => [
		{
			'LAT' => 39.005175,
			'LON' => -95.706681,
			'NUMBER' => 3516,
			'STREET' => 'SW MACVICAR AVE',
			'CITY' => 'TOPEKA',
			'COUNTY' => 'SHAWNEE',
			'STATE' => 'KS',
			'COUNTRY' => 'US',
			'POSTCODE' => 66611,
		},
	], 'us/md/statewide.csv' => [
		{
			'LAT' => 39.467270,
			'LON' => -76.823947,
			'NAME' => 'ALL SAINTS EPISCOPAL CHURCH',
			'NUMBER' => 203,
			'STREET' => 'E CHATSWORTH RD',
			'CITY' => 'REISTERSTOWN',
			'COUNTY' => 'BALTIMORE',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 21136
		}, {
			'LAT' => 39.6852333333333,
			'LON' => -76.6071166666667,
			'NUMBER' => 7,
			'STREET' => 'JORDAN MILL COURT',
			'CITY' => 'WHITE HALL',
			'COUNTY' => 'BALTIMORE',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 21161
		}, {
			'LAT' => 39.633018,
			'LON' => -76.272558,
			'NAME' => 'BALLPARK RESTAURANT',
			'NUMBER' => 3418,
			'STREET' => 'CONOWINGO RD',
			'CITY' => 'DUBLIN',
			'COUNTY' => 'HARFORD',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 21154
		}, {
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
			'LAT' => 38.9890861111111,
			'LON' => -77.0975722222222,
			'NAME' => 'ROCK BOTTOM RESTAURANT & BREWERY',
			'STREET' => 'NORFOLK AVE',
			'CITY' => 'BETHESDA',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20814
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
			'LAT' => 39.2244603797302,
			'LON' => -77.449615439877,
			'STREET' => 'MOUTH OF MONOCACY RD',
			'CITY' => 'DICKERSON',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20842,
		}, {
			'NAME' => 'PATAPSCO VALLEY STATE PARK',
			'LAT' => 39.29491,
			'LON' => -76.78051,
			'NUMBER' => 8020,
			'STREET' => 'BALTIMORE NATIONAL PK',
			'CITY' => 'ELLICOTT CITY',
			'COUNTY' => 'HOWARD',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 21043,
		}, {
			'LAT' => 39.683529,
			'LON' => -77.349405,
			'STREET' => 'ANNANDALE RD',
			'CITY' => 'EMMITSBURG',
			'COUNTY' => 'FREDERICK',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 21727
		}, {
			'NAME' => 'UTICA DISTRICT PARK',
			'LAT' => 39.5167883333333,
			'LON' => -77.4015166666667,
			'CITY' => 'FREDERICK',
			'COUNTY' => 'FREDERICK',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 21701,
		}, {
			'LAT' => 39.342986,
			'LON' => -77.239770,
			'NUMBER' => 3923,
			'STREET' => 'SUGARLOAF CT',
			'CITY' => 'MONROVIA',
			'COUNTY' => 'FREDERICK',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 21770
		}, {
			'LAT' => 39.028404,
			'LON' => -77.073227,
			'NUMBER' => 10540,
			'STREET' => 'METROPOLITAN AVE',
			'CITY' => 'KENSINGTON',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20895
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
			'LAT' => 39.100869,
			'LON' => -76.812162,
			'NUMBER' => 8616,
			'STREET' => 'SAVANNAH RIVER RD',
			'CITY' => 'LAUREL',
			'COUNTY' => 'ANNE ARUNDEL',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20724
		}, {
			'LAT' => 39.110711,
			'LON' => -76.434062,
			'NAME' => 'DOWNS PARK',
			'STREET' => 'CHESAPEAKE BAY DRIVE',
			'CITY' => 'PASADENA',
			'COUNTY' => 'ANNE ARUNDEL',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 21122
		}, {
			'LAT' => 39.102637,
			'LON' => -76.456384,
			'NUMBER' => 1559,
			'STREET' => 'GUERDON CT',
			'CITY' => 'PASADENA',
			'COUNTY' => 'ANNE ARUNDEL',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 21122
		}, {
			'LAT' => 39.017633,
			'LON' => -77.049551,
			'NUMBER' => 9904,
			'STREET' => 'GARDINER AVE',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20902,
		}, {
			'LAT' => 39.010801,
			'LON' => -77.041771,
			'NAME' => 'CVS',
			'NUMBER' => 9520,
			'STREET' => 'GEORGIA AVE',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910
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
			'LAT' => 39.019575,
			'LON' => -77.047453,
			'NUMBER' => 10009,
			'STREET' => 'GREELEY AVE',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20902
		}, {
			'NAME' => 'ADVENTIST HOSPITAL',
			'LAT' => 39.049570,
			'LON' => -76.956882,
			'NUMBER' => 11886,
			'STREET' => 'HEALING WAY',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20904,
		}, {
			'LAT' => 39.019385,
			'LON' => -77.049779,
			'NUMBER' => 2322,
			'STREET' => 'HILDAROSE DR',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20902,
		}, {
			'NAME' => 'LA CASITA PUPESERIA AND MARKET',
			'LAT' => 38.993369,
			'LON' => -77.009501,
			'NUMBER' => 8214,
			'STREET' => 'PINEY BRANCH RD',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910,
		}, {
			'LAT' => 38.991667,
			'LON' => -77.030473,
			'NAME' => 'NOAA LIBRARY',
			'NUMBER' => 1315,
			'STREET' => 'EAST-WEST HIGHWAY',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910
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
			'LAT' => 39.010447,
			'LON' => -77.048548,
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
			'STREET' => 'ROCKVILLE PK',
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
			'STREET' => 'VIERS MILL RD',
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
			'LAT' => 39.015394,
			'LON' => -77.048357,
			'NUMBER' => 2225,
			'STREET' => 'FOREST GLEN RD',
			'CITY' => 'SILVER SPRING',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20910
		}, {
			'LAT' => 39.0147541,
			'LON' => -77.05466857,
			'NAME' => 'BP',
			'NUMBER' => 2601,
			'STREET' => 'FOREST GLEN RD',
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
			'LAT' => 39.033075,
			'LON' => -76.923859,
			'NUMBER' => 10424,
			'STREET' => '43RD AVE',
			'CITY' => 'BELTSVILLE',
			'COUNTY' => 'PRINCE GEORGE',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20705
		}, {
			'LAT' => 38.996764,
			'LON' => -76.849323,
			'NAME' => 'NASA',
			'STREET' => 'TIROS RD',
			'CITY' => 'GREENBELT',
			'COUNTY' => 'PRINCE GEORGE',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
			'POSTCODE' => 20771
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
		}, {
			'LAT' => 38.904022,
			'LON' => -77.023113,
			'NAME' => 'WALTER E. WASHINGTON CONVENTION CENTER',
			'NUMBER' => 801,
			'STREET' => 'MT VERNON PL NW',
			'CITY' => 'WASHINGTON',
			'STATE' => 'DC',
			'COUNTRY' => 'US',
			'POSTCODE' => 20001
		}
	], 'us/id/statewide.csv' => [
		{
			'LAT' => 47.693615,
			'LON' => -116.915357,
			'NUMBER' => 880,
			'STREET' => 'SOUTH GREENSFERRY RD',
			'CITY' => "COUER D'ALENE",
			'COUNTY' => 'KOOTENAI',
			'STATE' => 'ID',
			'POSTCODE' => 83814
		}, {
			'LAT' => 47.69556,
			'LON' => -116.91564,
			'NUMBER' => 898,
			'STREET' => 'SOUTH GREENSFERRY RD',
			'CITY' => "COUER D'ALENE",
			'COUNTY' => 'KOOTENAI',
			'STATE' => 'ID',
			'POSTCODE' => 83814
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
			'LAT' => 40.154989,
			'LON' =>  -76.304266,
			'CITY' => 'LITITZ',
			'COUNTY' => 'LANCASTER',
			'STATE' => 'PA',
			'COUNTRY' => 'US',
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
			'LAT' => 38.75422,
			'LON' =>  -77.1058666666667,
			'NAME' => 'HUNTLEY MEADOWS PARK',
			'NUMBER' => 3701,
			'STREET' => 'LOCKHEED BLVD',
			'CITY' => 'ALEXANDRIA',
			'STATE' => 'VA',
			'COUNTRY' => 'US',
			'POSTCODE' => 22306
		}, {
			'LAT' => 39.142146,
			'LON' => -77.866468,
			'NAME' => 'SHENANDOAH COOL SPRINGS BATTLEFIELD',
			'CITY' => 'BLUEMONT',
			'COUNTY' => 'CLARKE',
			'STATE' => 'VA',
			'COUNTRY' => 'US',
		}, {
			'LAT' => 38.873934,
			'LON' => -77.461939,
			'NUMBER' => 14900,
			'STEET' => 'CONFERENCE CENTER DR',
			'CITY' => 'CHANTILLY',
			'COUNTY' => 'FAIRFAX',
			'STATE' => 'VA',
			'COUNTRY' => 'US',
			'POSTCODE' => 20151
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
		}, {
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
			'LAT' => 39.099655,
			'LON' => -77.836975,
			'NAME' => 'DIRT FARM BREWERY',
			'NUMBER' => 18701,
			'STREET' => 'FOGGY BOTTOM RD',
			'CITY' => 'BLUEMONT',
			'COUNTY' => 'LOUDON',
			'STATE' => 'VA',
			'COUNTRY' => 'US',
			'POSTCODE' => 20135
		}, {
			'LAT' => 39.124843,
			'LON' => -77.535445,
			'NUMBER' => 818,
			'STREET' => 'FERNDALE TERRACE NE',
			'CITY' => 'LEESBURG',
			'COUNTY' => 'LOUDOUN',
			'STATE' => 'VA',
			'COUNTRY' => 'US',
			'POSTCODE' => 20176
		}, {
			'LAT' => 39.04071,
			'LON' => -77.61682,
			'STREET' => 'OATLANDS PLANTATION LN',
			'CITY' => 'OATLANDS',
			'COUNTY' => 'LOUDOUN',
			'STATE' => 'VA',
			'COUNTRY' => 'US',
			'POSTCODE' => 20175
		}, {
			'LAT' => 39.136193,
			'LON' => -77.693198,
			'STREET' => 'PURCELLVILLE GATEWAY DR',
			'CITY' => 'PURCELLVILLE',
			'COUNTY' => 'LOUDOUN',
			'STATE' => 'VA',
			'COUNTRY' => 'US',
			'POSTCODE' => 20132
		}, {
			'LAT' => 38.25075,
			'LON' => -76.9602533333333,
			'CITY' => 'COLONIAL BEACH',
			'COUNTY' => 'WESTMORELAND',
			'STATE' => 'VA',
			'COUNTRY' => 'US',
			'POSTCODE' => 22443
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
			'STREET' => 'MARGATE RD',
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
			'STREET' => 'NEW HAINE RD',
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
			'LAT' => 51.340826,
			'LON' => 1.406519,
			'NAME' => 'RAMSGATE STATION',
			'STREET' => 'STATION APPROACH RD',
			'CITY' => 'RAMSGATE',
			'STATE' => 'KENT',
			'COUNTRY' => 'GB'
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

BEGIN {
	$SIG{__WARN__} = sub {
		my $warning = shift;
		if(($warning =~ /^Use of uninitialized value/) ||
		   ($warning =~ /Wide/) ||
		   ($warning =~ /masks earlier declaration in same scope/) ||
		   ($warning =~ /isn't numeric in numeric eq /i)) {
			die $warning;
		}
		warn $warning;
	};
}

my $force_flag;
if(defined($ARGV[0]) && ($ARGV[0] eq '-f')) {
	$force_flag++;
} elsif($ENV{'AUTOMATED_TESTING'}) {
	exit(0);
}

if(($^O ne 'solaris') && ($^O ne 'haiku') && ($^O ne 'MSWin32')) {
	eval {
		require File::Open::NoCache::ReadOnly;
		require IO::AIO;

		File::Open::NoCache::ReadOnly->import();
		IO::AIO->import()
	};
	if($@) {
		die $@;
	}
}
my %queued_commits;
# my $city_sequence;
# my %cities;
my %unknown_zips;
# my %state_parent_md5s;

# This hash becomes HUGE - TODO: find another way to do this
# One alternative would be to create a PRIMARY key to begin with,
# but that really slows down the INSERT/REPLACE
my %global_md5s;
my %state_md5s;
my %state_parent_md5s;

my $cities_sql = 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql';

if(!-r $cities_sql) {
	(system('bash bin/create_sqlite') == 0)
		or warn "Can't create the SQLite database (perhaps you don't have sqlite3 installed) - expect poor performance";

	if(-r $cities_sql) {
		if(-r "blib/$cities_sql") {
			unlink("blib/$cities_sql");
		}
		copy($cities_sql, "blib/$cities_sql")
			or die "Can't copy SQLite file to blib: $!";
	}
}

if(!(-r 'downloads/allCountries.txt')) {
	print "Consider downloading http://download.geonames.org/export/dump/allCountries.zip to downloads/allCountries.txt\n";
}

my $oa = $ENV{'OPENADDR_HOME'};

exit(0) if((!defined($oa)) || (length($oa) == 0));

if(!-d $oa) {
	mkdir $oa;
}

$Data::Dumper::Sortkeys = 1;

# Import openaddresses.io data into a database
# TODO: download and unzip the files from results.openaddresses.io
# TODO: only Australian, US and Canadian data is supported at the moment

# TODO Make the database choice configurable
# my $sqlite_file = "$oa/openaddresses.sql";
my $sqlite_file;
my $db_file = "$oa/openaddresses.db";
# my $db_file;

if($sqlite_file && $db_file) {
	die 'Choose only one database driver';
}

if($force_flag) {
	unlink $sqlite_file if($sqlite_file && (-r $sqlite_file));
	unlink $db_file if($db_file && (-r $db_file));
} else {
	exit(0) if($sqlite_file && (-r $sqlite_file));	# Database has already been built
	exit(0) if($db_file && (-r $db_file));
}

my %db_tie;
my $dbh;
my $redis;
my $mongodb;
my $berkeley_db;

if($ENV{'REDIS_SERVER'}) {
	# Warning:  Redis stores the database in RAM which makes it
	#	slow and unrealistic for most scenarios as it will
	#	use all the memory on your machine
	require Redis;
	Redis->import();

	$redis = Redis->new(
		reconnect => 1200,
		every => 5_000_000,
		name => 'openaddresses'
	);
	$redis->select(1);
	$redis->flushdb();

	# So the database is not contantly re-written
	open(my $fout, '>', $sqlite_file);
	close($fout);
} elsif(my $e = $ENV{'MONGODB_SERVER'}) {
	# TODO
	# I'm hoping this will require less RAM than SQLite which just chews
	#	it up
	require MongoDB;
	MongoDB->import();

	my $db_name = 'Geo::Coder::Free';
	my ($server, $port) = split (/:/, $e);

	$mongodb = MongoDB::MongoClient->new(host => $server, port => $port)->get_database($db_name)->get_collection('data');

	# So the database is not contantly re-written
	open(my $fout, '>', $sqlite_file);
	close($fout);
} elsif($e = $ENV{'MARIADB_SERVER'}) {
	# MariaDB/MySQL
	require DBD::MariaDB;
	DBD::MariaDB->import();

	# FIXME: ask for user name and password
	my ($user, $password) = split(/:/, $ENV{'MARIADB_USER'});
	$dbh = DBI->connect("dbi:MariaDB:host=$e;database=geo_coder_free",
		$user,
		$password,
		{ RaiseError => 1, AutoCommit => 0 }
	);
	$| = 1;
	print "Removing old data\r";
	print "\n" if(DEBUG);
	$| = 0;
	$dbh->do('DROP DATABASE IF EXISTS geo_coder_free');
	$dbh->do('CREATE DATABASE geo_coder_free');
	$dbh->do('USE geo_coder_free');

	# So the database is not contantly re-written
	open(my $fout, '>', $sqlite_file);
	close($fout);
	truncate $sqlite_file, 0;
} elsif(defined($db_file)) {
	# if($berkeley_db = DB_File::HASHINFO->new()) {
		# $berkeley_db->{'cachesize'} = 64 * 1024 * 1024;
		# tie %db_tie, 'DB_File', "$oa/openaddresses.db", 0, 0644, $berkeley_db;
	# }
	# my $berkeley_db = BerkeleyDB::Hash->new(
			# -Filename => $db_file,
			# -Flags => DB_CREATE)
		# or die "Cannot open file $db_file: $! $BerkeleyDB::Error";
	# $DB_HASH->{'cachesize'} = 64 * 1024 * 1024;

	print "Building Berkeley database $db_file\n" if(DEBUG);

	$berkeley_db = DB_File::HASHINFO->new();
	$berkeley_db->{'cachesize'} = 65536;
	$berkeley_db = tie %db_tie, 'DB_File', $db_file, O_RDWR|O_CREAT, 0644, $berkeley_db
		or die "Cannot open file $db_file: $!";

	# See the DB_File example "Key is a C int"
	# $berkeley_db->filter_fetch_key(sub { $_ = unpack('i', $_) } );
	# $berkeley_db->filter_store_key(sub { $_ = pack('i', $_) } );
} elsif(defined($sqlite_file)) {
	# SQLite
	if($dbh = DBI->connect("dbi:SQLite:dbname=$sqlite_file", undef, undef, { RaiseError => 1, AutoCommit => 0, synchronous => 0, locking_mode => 'EXCLUSIVE' })) {
		$dbh->do('PRAGMA synchonuous = OFF');
		$dbh->do('PRAGMA cache_size = 262144');	# 256MB
		$dbh->do('PRAGMA journal_mode = OFF');
	} else {
		die "$sqlite_file: $!";
	}
} else {
	die 'Which database driver?';
}

if((DEBUG&DEBUG_ALL) && (MAX_INSERT_COUNT != 1)) {
	warn 'MAX_INSERT_COUNT not set to 1 in DEBUG mode';
}

if($dbh) {
	# $dbh->do('CREATE TABLE cities(sequence INTEGER, city VARCHAR, county VARCHAR, state VARCHAR NOT NULL, country CHAR(2) NOT NULL)');
	# $dbh->do('CREATE TABLE openaddresses(md5 CHAR(16), lat DECIMAL, lon DECIMAL, name VARCHAR, number VARCHAR, street VARCHAR, city INTEGER, FOREIGN KEY (city) REFERENCES cities(sequence))');
	if(MAX_INSERT_COUNT == 1) {
		# $dbh->do('CREATE TABLE openaddresses(md5 CHAR(16) PRIMARY KEY, lat DECIMAL, lon DECIMAL)');
		$dbh->do('CREATE TABLE openaddresses(md5 CHAR(16) PRIMARY KEY, geohash VARCHAR(10))');
	} else {
		# Add the keys later for performance
		# $dbh->do('CREATE TABLE openaddresses(md5 CHAR(16), lat DECIMAL, lon DECIMAL)');
		$dbh->do('CREATE TABLE openaddresses(md5 CHAR(16), geohash VARCHAR(10))');
	}
	# $dbh->do('CREATE TABLE openaddresses(md5 CHAR(16) PRIMARY KEY, lat DECIMAL, lon DECIMAL, name VARCHAR, number VARCHAR, street VARCHAR, city INTEGER, FOREIGN KEY (city) REFERENCES cities(sequence))');
	# $dbh->prepare('CREATE TABLE tree(lat DECIMAL, lon DECIMAL, md5 CHAR(16) NOT NULL, parent CHAR(16))')->execute();
}

print "This will take some time.\nBest to do it last thing at night and go to sleep, it should be ready in the morning.\n";

my $au = Locale::AU->new();
my $ca = Locale::CA->new();
my $us = Locale::US->new();
my $abbr = Geo::Coder::Abbreviations->new();
# my %digests_added;

my $filename = 'lib/Geo/Coder/Free/OpenAddresses/databases/states.txt';
if(((!(DEBUG&(DEBUG_KNOWN_PLACES|DEBUG_WOF|DEBUG_OSM))) && (-r $filename)) || $force_flag) {
	# Import US states and counties from https://github.com/openaddresses/openaddresses/tree/master/us-data
	$| = 1;
	printf "%-70s\r", $filename;
	print "\n" if(DEBUG);
	$| = 0;
	my $fh = File::Open::NoCache::ReadOnly->new($filename);

	my $fin = $fh->fd();

	aio_readahead($fin, 0, AIO_READAHEAD_SIZE) if($^O ne 'solaris');

	# open(my $fin, '<', $filename);

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

	$csv->column_names($csv->getline($fin));

	while(my $row = $csv->getline_hr($fin)) {
		# print Data::Dumper->new([\$row])->Dump();
		my $state;
		unless($state = $us->{state2code}{uc($row->{'Name'})}) {
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
		$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, 1, %columns);
		if($inserts >= MAX_INSERT_COUNT) {
			flush_queue($dbh, $redis, $mongodb, $berkeley_db);
			$inserts = 0;
		}
	}

	$fh->close();

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
		$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, 1, %columns);
		if($inserts >= MAX_INSERT_COUNT) {
			flush_queue($dbh, $redis, $mongodb, $berkeley_db);
			$inserts = 0;
		}
	}
	$fh->close();
}

my $current_state;
my $current_country;
# my %whosonfirst;

my $ua = LWP::UserAgent::Throttled->new(keep_alive => 1);
$ua->conn_cache(LWP::ConnCache->new());
$ua->throttle({ 'api.zippopotam.us' => 1 });
$ua->env_proxy(1);

$filename = 'downloads/allCountries.txt';

# Import the Maxmind databases
if(($force_flag || ((!(DEBUG&DEBUG_KNOWN_PLACES)) && (-r $filename))) &&
   # open(my $fin, '<', 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.txt') &&
   # open(my $fin1, '<', 'lib/Geo/Coder/Free/MaxMind/databases/admin1.db') &&
   # open(my $fin2, '<', 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db')) {
   (my $all_countries = File::Open::NoCache::ReadOnly->new($filename)) &&
   (!(DEBUG&(DEBUG_OSM|DEBUG_WOF|DEBUG_GET_WOF|DEBUG_DR5HN))) &&
   (my $admin1 = File::Open::NoCache::ReadOnly->new('lib/Geo/Coder/Free/MaxMind/databases/admin1.db')) &&
   (my $admin2 = File::Open::NoCache::ReadOnly->new('lib/Geo/Coder/Free/MaxMind/databases/admin2.db'))) {
	my $fin = $all_countries->fd();
	aio_readahead($fin, 0, AIO_READAHEAD_SIZE) if($^O ne 'solaris');
	my $fin1 = $admin1->fd();
	aio_readahead($fin1, 0, AIO_READAHEAD_SIZE) if($^O ne 'solaris');
	my $fin2 = $admin2->fd();
	aio_readahead($fin2, 0, AIO_READAHEAD_SIZE) if($^O ne 'solaris');

	$| = 1;
	printf "%-70s\r", $filename;
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

	$admin1->close();

	my %admin2;

	while(my $row = $csv->getline_hr($fin2)) {
		$admin2{$row->{'concatenated_codes'}} = $row->{'asciiname'};
	}

	$admin2->close();

	my $inserts = 0;
	my $offset = AIO_READAHEAD_SIZE;

	# TODO: Double check this is adding what I think it should be adding
	#	I may be able to extract more as the 'city' name often contains venues
	# DEBUG_INSERT helps
	while(my $line = <$fin>) {
		my @fields = split(/\t/, $line);

		my $country = lc($fields[8]);
		if(!$openaddresses_countries{$country}) {
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
			# Fix entries like 'Kansas City/NW/Airport' in allCountries.txt
			$city = uc($fields[2]);
			$city =~ s/\/.+$//;
			die "$filename: $line: $city" if(defined($city) && ($city =~ /\/..\//));
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
			if($columns{'STATE'} eq 'GREATER LONDON') {
				$columns{'STATE'} = 'LONDON';
			}
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
		die $columns{'CITY'} if(defined($columns{'CITY'}) && ($columns{'CITY'} =~ /\/..\//));
		$inserts += import(row => \%columns, file => "$country/countrywide.csv", ua => $ua, dbh => $dbh, redis => $redis, mongodb => $mongodb, berkeley_db => $berkeley_db, global => 1);
		if($inserts >= MAX_INSERT_COUNT) {
			flush_queue($dbh, $redis, $mongodb, $berkeley_db);
			aio_readahead($fin, $offset, AIO_READAHEAD_SIZE) if($^O ne 'solaris');
			$offset += AIO_READAHEAD_SIZE;
			$inserts = 0;
		}
	}
	$all_countries->close();
}
# undef %digests_added;

flush_queue($dbh, $redis, $mongodb, $berkeley_db);

# print "Debug exit\n" if(DEBUG&DEBUG_ALL);
# $dbh->disconnect();
# exit(0);

my $inserts = 0;

# Find all of the .csv files in $OPENADDR_HOME
foreach my $csv_file (create_tree($oa, 1)) {
	# next unless($csv_file =~ /us\/md\/statewide/);
	# next unless($csv_file =~ /us\/ne\/dawes/);
	# next unless($csv_file =~ /us\/in\//);

	next if((DEBUG&(DEBUG_OSM|DEBUG_WOF|DEBUG_GET_WOF)) && !$force_flag);

	# Handle https://github.com/openaddresses/openaddresses/issues/3928
	# TODO: It would be better to merge airdrie.csv and city_of_airdrie.csv
	next if($csv_file =~ /ca\/ab\/airdrie.csv/);

	my $f = $csv_file;
	# print __LINE__, ": >>>>>>>>>>>>>>: $f\n";
	$f =~ s/^$oa\///;
	my @components = split(/\//, $f);
	# print __LINE__, ": $f: ", Data::Dumper->new([\@components])->Dump(), "\n";
	if(my $country = uc($components[0])) {
		my $state;
		my $file;

		next unless($openaddresses_countries{lc($country)});

		if($components[1] =~ /\.csv$/) {
			$file = $components[1];
		} else {
			$state = uc($components[1]);
			$file = $components[2];
			if($state eq 'GREATER LONDON') {
				$state = 'LONDON';
			}
		}

		# Clear the deduping hash when we can, to avoid it becoming too large
		if($country eq 'US') {
			if((!defined($current_state)) || ($state ne $current_state)) {
				print "New state: state = $state, country = $country\n" if(DEBUG&DEBUG_NEW_LOCATION);
				# undef %digests_added;
				flush_queue($dbh, $redis, $mongodb, $berkeley_db);	# Check for hanging dups in current state
				%state_md5s = ();
				%state_parent_md5s = ();
				$current_country = $country;
				$current_state = $state;
			}
		} elsif((!defined($current_country)) || ($country ne $current_country)) {
			print "New country\n" if(DEBUG&DEBUG_NEW_LOCATION);
			# undef %digests_added;
			flush_queue($dbh, $redis, $mongodb, $berkeley_db);	# Check for hanging dups in current country
			%state_md5s = ();
			%state_parent_md5s = ();
			$current_country = $country;
		}

		# The readahead code can start doing its thing now
		my $fh = File::Open::NoCache::ReadOnly->new($csv_file)
			or die($csv_file);

		my $fin = $fh->fd();

		aio_readahead($fin, 0, AIO_READAHEAD_SIZE) if($^O ne 'solaris');

		# Import this state's hand curated data
		if(my $k = $known_places{$f}) {
			print __LINE__, ": known place ($f):\n\t", Data::Dumper->new([$k])->Dump() if(DEBUG&DEBUG_KNOWN_PLACES);
			foreach my $row(@{$k}) {
				$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, berkeley_db => $berkeley_db, redis => $redis, mongodb => $mongodb, global => 1);
				if(defined($row->{'STREET'}) && ($row->{'STREET'} =~ /MEDLARS DR/i) && (DEBUG&DEBUG_KNOWN_PLACES)) {
					# 'CITY' => 'BETHESDA',
					# 'COUNTRY' => 'US',
					# 'COUNTY' => 'MONTGOMERY',
					# 'LAT' => '38.99516556',
					# 'LON' => '-77.09943963',
					# 'NAME' => 'NCBI',
					# 'POSTCODE' => 20894,
					# 'STATE' => 'MD',
					# 'STREET' => 'MEDLARS DR'
					# global NCBIMEDLARS DRBETHESDAMONTGOMERYMDUS => RFa5+GhoBmCb91M8
					# global NCBIMEDLARS DRBETHESDAMDUS => tMt972yoDCKkdE5u
					# global MEDLARS DRBETHESDAMDUS => KZCIB0nblX/Etlnx
					# global NCBIBETHESDAMDUS => aQ1pIla9rwruGeg0
					print __LINE__, ': ', Data::Dumper->new([$row])->Dump();
				}
			}
			if($inserts >= MAX_INSERT_COUNT) {
				flush_queue($dbh, $redis, $mongodb, $berkeley_db);
				$inserts = 0;
			}
		}

		next if(DEBUG&DEBUG_KNOWN_PLACES);

		my $offset = AIO_READAHEAD_SIZE;

		$| = 1;
		printf "%-70s\r", $f;
		$| = 0;
		print "\n" if(MAX_INSERT_COUNT == 1);

		print STDERR __LINE__, " >>>>: $f: ", Devel::Size::total_size(\%queued_commits), "\n" if(DEBUG&DEBUG_SIZE);
		print STDERR __LINE__, " >>>>: $f: ", Devel::Size::total_size(\%state_md5s), "\n" if(DEBUG&DEBUG_SIZE);
		print STDERR __LINE__, " >>>>: $f: ", Devel::Size::total_size(\%global_md5s), "\n" if(DEBUG&DEBUG_SIZE);
		# print STDERR __LINE__, " >>>>: $f: ", Devel::Size::total_size(\%global_md5s), "\n";

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
			$row->{'COUNTRY'} //= $country;
			if(($country eq 'CA') || ($country eq 'US')) {
				$row->{'STATE'} //= $state;
			}
			delete $row->{'HASH'};
			delete $row->{'ID'};
			foreach my $column(keys %{$row}) {
				delete $row->{$column} if(!defined($row->{$column}));
			}
			$inserts += import(row => $row, file => $csv_file, ua => $ua, dbh => $dbh, berkeley_db => $berkeley_db, redis => $redis, mongodb => $mongodb);
			if($inserts >= MAX_INSERT_COUNT) {
				aio_readahead($fin, $offset, AIO_READAHEAD_SIZE) if($^O ne 'solaris');
				flush_queue($dbh, $redis, $mongodb, $berkeley_db);
				$inserts = 0;
				$offset += AIO_READAHEAD_SIZE;
			}
		}

		$fh->close();

		flush_queue($dbh, $redis, $mongodb, $berkeley_db);	# Check for hanging dups in current state
		$inserts = 0;
	}
}

if(BUILDMODE eq 'ONE') {
	undef $ENV{'DR5HN_HOME'};
	undef $ENV{'OSM_HOME'};
	undef $ENV{'WHOSONFIRST_HOME'};
	undef $oa;
}

if($dbh) {
	$dbh->commit();
}

# print "Debug exit\n" if(DEBUG&DEBUG_ALL);
# $dbh->disconnect();
# $wof_global_dbh->disconnect();
# exit(0);

flush_queue($dbh, $redis, $mongodb, $berkeley_db);	# Check for hanging dups in last state
# undef %digests_added;
undef %state_md5s;
undef %state_parent_md5s;

my %l1_cache;
my $l2_cache;

print STDERR __LINE__, ': >>>>', Devel::Size::total_size(\%queued_commits), "\n" if(DEBUG&DEBUG_SIZE);

# my $wof_global_dbh;
if(my $whosonfirst = $ENV{'WHOSONFIRST_HOME'}) {
	my %address_parsers;
	my $j = JSON::MaybeXS->new()->utf8();
	my $string = '';

	# Find all of the .geojson files in $WHOSONFIRST_HOME
	foreach my $geojson_file (create_tree_from_git($whosonfirst, 0)) {
		# Print progress, but not for every file as there are a lot
		my $s = $geojson_file;
		$s =~ s/\/data\/.+$//;
		if($s ne $string) {
			# undef %digests_added;
			$| = 1;
			printf "%-70s\r", $s;
			print "\n" if(DEBUG);
			$| = 0;
			$string = $s;
			print STDERR __LINE__, " >>>>: $s: ", Devel::Size::total_size(\%queued_commits), "\n" if(DEBUG&DEBUG_SIZE);
			print STDERR __LINE__, " >>>>: $s: ", Devel::Size::total_size(\%global_md5s), "\n" if(DEBUG&DEBUG_SIZE);
			# print STDERR __LINE__, " >>>>: $s: ", Devel::Size::total_size(\%global_md5s), "\n";
			print STDERR __LINE__, " >>>>: $s: ", Devel::Size::total_size(\%unknown_zips), "\n" if(DEBUG&DEBUG_SIZE);
			# print STDERR __LINE__, " >>>>: $s: ", Devel::Size::total_size(\%digests_added), "\n";
		}

		# Don't combine these statements - it creates CPANEL usage errors
		# which I need to investigate
		my $data = File::Slurp::read_file($geojson_file);
		my $properties;
		eval {
			$properties = $j->decode($data)->{'properties'};
		};
		if($@ || !defined($properties)) {
			warn "$geojson_file: $@";
			next;
		}
		# print 'processing ', $properties->{'wof:id'}, "\n";

		next if(exists($properties->{'wof:superseded_by'}) && scalar(@{$properties->{'wof:superseded_by'}}));
		# https://github.com/whosonfirst-data/whosonfirst-data/issues/1844
		# "mz:is_current":-1 means "not sure" versus 1 meaning known to be current when record last updated and 0 no longer current.
		# Most records have -1.
		next if(exists($properties->{'mz:is_current'}) && ($properties->{'mz:is_current'} <= 0));
		next if(exists($properties->{'src:geom'}) && ($properties->{'src:geom'} eq 'missing'));	# https://github.com/whosonfirst-data/whosonfirst-data/issues/1346
		my $placetype = $properties->{'wof:placetype'};
		next if(!defined($placetype));
		next if($placetype eq 'country');
		next if($placetype eq 'marketarea');
		my $country = $properties->{'wof:country'};
		next if(!defined($country));
		if(!$openaddresses_countries{lc($country)}) {
			my $found = 0;
			foreach my $c(@whosonfirst_only_countries) {
				if(lc($country) eq $c) {
					$found = 1;
					last;
				}
			}
			next if(!$found);
		}
		$country = uc($country);
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
			# $state = get_wof($wof_global_dbh, $region, $geojson_file);
		# }
		if((!defined($state)) && (my $a1 = ($properties->{'as:a1'} || $properties->{'qs:a1'} || $properties->{'qs:name_adm1'} || $properties->{'qs_pg:name_adm1'} || $properties->{'woe:name_adm1'}))) {
			if(($a1 eq 'England') || ($a1 eq 'Scotland') || ($a1 eq 'Wales') || ($a1 eq 'Northern Ireland')) {
				$a1 = $properties->{'qs:name_adm2'};
			} elsif(($country eq 'US') || ($country eq 'CA') || ($country eq 'AU')) {
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
			my $region_id;
			my $region_name;
			my @hierarchy = @{$properties->{'wof:hierarchy'}};
			if(scalar(@hierarchy) && (my $region = $hierarchy[0]->{'region_id'})) {
				if(defined($region_id) && ($region == $region_id)) {
					$state = $region_name;
					print "Saved state = $state\n" if(DEBUG&DEBUG_DETERMINE_LOCATION);
				} else {
					next if($region < 0);
					print "Getting state from hierarchy:\n\t", Data::Dumper->new([$properties])->Dump() if(DEBUG&DEBUG_DETERMINE_LOCATION);
					$state = get_wof($properties, $region, $geojson_file);
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
				if($parent = get_wof($properties, $parent, $geojson_file)) {
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
				if(my $w = get_wof($properties, $locality, $geojson_file)) {
					$city = $w;
				}
			}
		}
		my $file = basename($geojson_file);

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
			$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, berkeley_db => $berkeley_db, redis => $redis, mongodb => $mongodb, global => 1);
			if($inserts >= MAX_INSERT_COUNT) {
				flush_queue($dbh, $redis, $mongodb, $berkeley_db);
				$inserts = 0;
			}
			next;
		}
		if($city) {
			# print "\t$country, $state, $city\n";
		} else {
			# print "\t$country, $state\n";
			my $address = $properties->{'addr:full'};
			next if(!defined($address));
			if(my $href = (Geo::StreetAddress::US->parse_location($address) || Geo::StreetAddress::US->parse_address($address))) {
				if($href->{city}) {
					$city = $href->{city};
				}
			}
			next if(!defined($city));
		}
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
				$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, berkeley_db => $berkeley_db, redis => $redis, mongodb => $mongodb, global => 1);
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
		$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, berkeley_db => $berkeley_db, redis => $redis, mongodb => $mongodb, global => 1);
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
				if($ap->parse($addr_full)) {
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
					$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, berkeley_db => $berkeley_db, redis => $redis, mongodb => $mongodb, global => 1);
				}
			}
		}
		if($inserts >= MAX_INSERT_COUNT) {
			flush_queue($dbh, $redis, $mongodb, $berkeley_db);
			$inserts = 0;
		}
	}

	%l1_cache = ();
	$l2_cache->clear();
	undef %l1_cache;
	undef $l2_cache;

	if(BUILDMODE eq 'ONE') {
		undef $ENV{'DR5HN_HOME'};
		undef $ENV{'OSM_HOME'};
		undef $ENV{'WHOSONFIRST_HOME'};
		undef $oa;
	}
}

if($dbh) {
	$dbh->commit();
}

if(!(DEBUG&(DEBUG_OSM|DEBUG_WOF|DEBUG_GET_WOF))) {
	foreach my $country(@whosonfirst_only_countries) {
		# Import this country's hand curated data

		$| = 1;
		printf "%-70s\r", "Known place $country";
		print "\n" if(DEBUG);
		$| = 0;

		if(my $k = $known_places{'other'}) {
			# print "Known place:\n\t", Data::Dumper->new([\$k])->Dump();
			foreach my $row(@{$k}) {
				$inserts += import(row => $row, file => "$country/countrywide.csv", ua => $ua, dbh => $dbh, redis => $redis, mongodb => $mongodb, berkeley_db => $berkeley_db);
			}
		}

		if($inserts >= MAX_INSERT_COUNT) {
			flush_queue($dbh, $redis, $mongodb, $berkeley_db);
			$inserts = 0;
		}
	}
	flush_queue($dbh, $redis, $mongodb, $berkeley_db);
}

# %whosonfirst = ();

if((!(DEBUG&DEBUG_WOF)) && (my $osm = $ENV{'OSM_HOME'})) {
	# Openstreetmap
	# There are a range of differing formats -
	#	the format doesn't seem to be normalized and fields are inconsistent,
	#	so try hard to extract the data

	require XML::LibXML::Reader;
	XML::LibXML::Reader->import();

	my @files = ('north-america-latest.osm.bz2', 'europe-latest.osm.bz2', 'australia-oceania-latest.osm.bz2');

	foreach my $file(@files) {
		my $filename = File::Spec->catfile($osm, $file);

		$| = 1;
		printf "%-70s\r", $filename;
		$| = 0;
		print "\n" if(MAX_INSERT_COUNT == 1);
		# undef %digests_added;

		# TODO: check for the presence of bzcat
		open(my $pin, '-|', "bzcat $filename");
		my $reader = XML::LibXML::Reader->new(FD => $pin)
			or die "cannot read $filename";

		my $in_node;
		my $key;
		my $name;
		my $is_in;
		my $lat;
		my $lon;
		my $place;
		my $country;

		while($reader->read()) {
			# These constants are not exported by default :-(
			# print $reader->document->toString(1);
			if($reader->nodeType() == 1) {
				my $node = $reader->name();
				if($node eq 'node') {
					if($reader->hasAttributes()) {
						$lat = $reader->getAttribute('lat');
						$lon = $reader->getAttribute('lon');
						$in_node = 1;
						$name = undef;
						$is_in = undef;
					}
				} elsif($in_node && ($node eq 'tag') && $reader->hasAttributes()) {
					my $key = $reader->getAttribute('k');
					# print "key = $key\n";
					if($key eq 'name:en') {
						$name = $reader->getAttribute('v');
						# print "name:en: $name\n";
					} elsif(($key eq 'name') && !defined($name)) {
						$name = $reader->getAttribute('v');
						# print "name: $name\n";
					} elsif($key eq 'is_in') {
						$is_in = $reader->getAttribute('v');
						# print "is_in: $is_in\n";
						if(Locale::Country::country2code($country)) {
							$country = $is_in;
						}
					} elsif($key eq 'is_in:country') {
						$country = $reader->getAttribute('v');
						# print "is_in:country $country\n";
						# if(defined($is_in) && ($is_in !~ /\Q$country\E$/)) {
							# $is_in .= ", $country";
						# } elsif(!defined($is_in)) {
							# $is_in = $country;
						# }
					} elsif($key eq 'is_in:province') {	# Canada
						my $province = $reader->getAttribute('v');
						# print "is_in:province $province\n";
						if(defined($is_in)) {
							$is_in = "$province, $is_in";
						} else {
							# $is_in = "$province, Canada";
							$is_in = $province;
							$country = 'Canada';
						}
					} elsif($key eq 'wikipedia') {
						my $v = $reader->getAttribute('v');
						# print "wikipedia $v\n";
						if($v =~ /^en:(.+)/) {
							$place = $1;
						}
					} elsif($key eq 'gns:cc1') {
						# "Experimental import of Canadian places and POIs from GNS Dataset"
						#	Does not contain is_in:country or is_in:province records
						$country = $reader->getAttribute('v');
						if($country eq 'CA') {
							$country = 'Canada';
						} else {
							die "Unknown country '$country'";
						}
					} elsif($key eq 'place') {
						$place = $reader->getAttribute('v');
						# print "place $place\n";
					}
				}
			} elsif($reader->nodeType() == 15) {
				if(defined($name) && defined($is_in) && defined($lat) && defined($lon) && defined($place)) {

					print __LINE__, ": name = $name, place = $place, is_in = $is_in\n" if(DEBUG&DEBUG_OSM);
					# Don't add county to this list
					undef $place if($place =~ /town|locality|neighbourhood|hamlet|allotments|suburb|city|village|farm|island|islet|municipality|isolated[_\s]dwelling|State\sRoute\s|square|farm/);

					if((!defined($place)) && (!defined($name)) && ($is_in !~ /,/)) {
						print __LINE__, ": nothing at $lat, $lon\n";
						$name = undef;
						$lat = undef;
						$lon = undef;
						$is_in = undef;
						undef $country;
						$key = undef;
						$in_node = 0;
						next;
					}

					if(my $row = extract_osm_home($file, $name, $place, $is_in)) {
						$country = $row->{'COUNTRY'};
						my $state = $row->{'STATE'};
						if(DEBUG&DEBUG_DATA_VALIDATE) {
							die __LINE__, ': ', $row->{'CITY'} if(defined($row->{'CITY'}) && ($row->{'CITY'} =~ /,/));
							die 'no state' if(!defined($state));
							die __LINE__, ': ', $state if((($country eq 'US') || ($country eq 'Canada')) && ($state !~ /[A-Z]{2}/));
							foreach my $v(keys %{$row}) {
								die __LINE__, ": $v" if(!defined($row->{$v}));
							}
							die if(defined($row->{'CITY'}) && defined($row->{'NAME'}) && ($row->{'CITY'} eq $row->{'NAME'}));
							die if(defined($row->{'NUMBER'}) && !defined($row->{'ROAD'}));
							die if(defined($row->{'NUMBER'}) && !defined($row->{'CITY'}));
							die if(defined($row->{'ROAD'}) && !defined($row->{'CITY'}));
							die $row->{'COUNTRY'} if(!defined($osm_countries{lc($row->{'COUNTRY'})}));
						}
						$row->{'LAT'} = $lat;
						$row->{'LON'} = $lon;
						print __LINE__, ': ', Data::Dumper->new([$row])->Dump() if(DEBUG&DEBUG_OSM);
						$inserts += import(country => $country, state => $state, row => $row, file => $filename, ua => $ua, dbh => $dbh, berkeley_db => $berkeley_db, redis => $redis, mongodb => $mongodb);
						if($inserts >= MAX_INSERT_COUNT) {
							flush_queue($dbh, $redis, $mongodb, $berkeley_db);
							$inserts = 0;
						}
						next;
					}
					if(DEBUG&DEBUG_OSM) {
						print __LINE__, " Not parsed: is_in = $is_in, name = $name\n";
						print "\tplace = $place\n" if(defined($place));
					}
					next;

					my $preamble;
					my $city = $name;
					my $state;
					my $county;
					my $add_record = 1;

					if($is_in =~ /, US/) {
						if($is_in =~ /(.+), (.+), US/) {
							$preamble = $1;
							$state = $2;
						} elsif($is_in =~ /^(.+), US/) {
							$state = $1;
						}
						if($is_in =~ /^([a-z\s]+?)\sCounty, (.+)/i) {
							$county = $1;
							$is_in = $2;
						}
						if((!defined($state)) && ($is_in =~ /^(.+?), (.+)/)) {
							if(my $code = $us->{state2code}{uc($1)}) {
								$state = $code;
								$is_in = $2;
							}
						}
						if(defined($city) && defined($county)) {
							$is_in = "$state, US";
						}
print __LINE__, ": is_in = '$is_in', state = $state, city = $city\n";
						$country = 'US';
					} elsif($is_in =~ /, Canada/) {
						print __LINE__, ": decode Canadian place '$is_in'\n";
						if($is_in =~ /(.+), (.+), Canada/) {
							if($name) {
								$city = $1;
								$preamble = undef;
								print "\tname=$name, city=$city\n";
								if(my $code = $ca->{province2code}{uc($city)}) {
									$is_in = $city;
									$state = $code;
									$city = $name;
									undef $name;
								}
								if($city =~ /(.+?), (.+)/) {
									if(my $code = $ca->{province2code}{uc($2)}) {
										$state = $code;
										$city = $1;
									} elsif($code = $ca->{province2code}{uc($1)}) {
										$state = $code;
										$city = $2;
										if($city eq 'Alta.') {
											$city = $name;
											undef $name;
											print __LINE__, ": is_in = $is_in; (city/state/country) $city/$state/Canada";
											$is_in = "$state, Canada";
										}
									}
								}
							} else {
								$preamble = $1;
								print "\tname is not defined\n";
							}
							$state = $2;
						} elsif($is_in =~ /^(.+), Canada/) {
							$state = $1;
						}
						print "\tstate = $state\n";
						$country = 'Canada';
					} elsif(($is_in eq 'Canada') && defined($place) && ($place =~ /\Q$name\E, (.+)/)) {
						if(my $code = $ca->{province2code}{uc($1)}) {
							$state = $code;
							$place = $name;
							undef $name;
print __LINE__, ": $state\n";
						}
						$country = 'Canada';
					} elsif($is_in eq 'US') {
						$country = 'US';
					} elsif($is_in eq 'Canada') {
						$country = 'Canada';
					} elsif($is_in =~ /^Australia, (.+)/) {
						# Some Australian data starts with country, rather than ending with it
						print __LINE__, ": parse Australian is_in '$is_in'\n";
						$country = 'Australia';
						$is_in = $1;
						if($is_in =~ /(.+?), (.+)/) {
							if($au->{code2state}{uc($1)}) {
								$state = uc($1);
								$is_in = $2;
								if($is_in !~ /(.+?), (.+)/) {
									$name = $1;
									$city = $2;
								} else {
									$city = $is_in;
								}
							}
						}
						if($is_in =~ /(.+?), (.+)/) {
							if(my $code = $au->{state2code}{uc($1)}) {
								$state = $code;
								$is_in = $2;
								if($is_in !~ /(.+?), (.+)/) {
									$city = $is_in;
								}
								print __LINE__, ": city = $city, state = $state\n";
							}
						}
					} elsif($is_in =~ /(.+), Australia$/) {
						print __LINE__, ": parse Australian is_in '$is_in'\n";
						$country = 'Australia';
						$is_in = $1;
						if($is_in =~ /(.+?), (.+)/) {
							if($au->{code2state}{uc($2)}) {
								$state = uc($2);
								$is_in = $1;
								if($is_in !~ /(.+?), (.+)/) {
									$name = $2;
									$city = $1;
								} else {
									$city = $is_in;
								}
							}
						}
						if($is_in =~ /(.+?), (.+)/) {
							if(my $code = $au->{state2code}{uc($2)}) {
								$state = $code;
								$is_in = $1;
								if($is_in !~ /(.+?), (.+)/) {
									$city = $is_in;
								}
								print __LINE__, ": city = $city, state = $state\n";
							}
						}
					} elsif(defined($country) && ($country eq 'Australia')) {
						if(($is_in !~ /,/) && (my $code = $au->{state2code}{uc($is_in)})) {
							$state = $code;
							undef $name if($name eq $city);
						} elsif(!defined($state)) {
							print __LINE__, "Can't determine Australian state from $is_in\n";
							$add_record = 0;
						}
					}
					if($state && (length($state) > 2)) {
						print __LINE__, ": state = $state\n";
						if(my $code = $us->{state2code}{uc($state)}) {
							if($preamble) {
								$is_in = "$preamble, $code, US";
							} else {
								$is_in = "$code, US";
							}
							$state = $code;
							$country = 'US';
						} elsif($code = $ca->{province2code}{uc($state)}) {
							if($preamble) {
								$is_in = "$preamble, $code, Canada";
							} else {
								$is_in = "$code, Canada";
							}
							$state = $code;
							$country = 'Canada';
						} elsif($au->{code2state}{$state}) {
							$country = 'Australia';
							print __LINE__, ": Australian state = $state\n";
							if($city =~ /(.+?),\s(.+)/) {
								if(my $code = $au->{'state2code'}{uc($1)}) {
									$state = $code;
									$city = $2;
									if($city =~ /(.+?),\s(.+)/) {
										$city = $1;
										$name = $2 unless(defined($name));
									}
									$is_in = "$state, Australia";
								}
							} else {
								$is_in = "$state, Australia";
							}
							print "\tcity = $city\n" if(defined($city));
							undef $name if($name eq $city);
							print "\tname = $name\n" if(defined($name));
						} else {
							# warn "$is_in: unknown state $state" if(DEBUG&DEBUG_DATA_VALIDATE);
							print "$is_in: unknown state $state\n";
							$add_record = 0;
						}
						if($city eq $state) {
							if($name) {
								$city = $name;
								undef $name;
							} else {
								undef $city;
							}
						}
print __LINE__, ": add_record = $add_record, is_in = '$is_in', (city/state/country = $city/$state/$country)\n";
					} elsif(my $code = $us->{state2code}{uc($is_in)}) {
						$is_in = "$code, US";
						$state = $code;
						$country = 'US';
					} elsif($code = $ca->{province2code}{uc($is_in)}) {
						$is_in = "$code, Canada";
						$state = $code;
						$country = 'Canada';
					} elsif($code = $au->{state2code}{uc($is_in)}) {
						$is_in = "$code, Australia";
						$state = $code if(!defined($state));
						$country = 'Australia';
print __LINE__, ": add_record = $add_record (city/state/country = $city/$state/$country)\n";
					} else {
						if($is_in =~ /(.+), (.+), Canada/) {
							$preamble = $1;
							$state = $2;
							$country = 'Canada';
						} elsif($is_in =~ /^(.+),\s?Canada/) {
							$state = $1;
							$country = 'Canada';
						} elsif($is_in =~ /^Canada,\s?(.+?),/) {
							$state = $1;
							$country = 'Canada';
							print __LINE__, ": is_in = $is_in (state = $state)\n";
						}
						if($state && (length($state) > 2)) {
							if($state =~ /Qu.bec/i) {
								$state = 'Quebec';
							}
							if(my $code = $ca->{province2code}{uc($state)}) {

								$is_in = "$city, $code, Canada";
								if($preamble) {
									$is_in = "$code, $code, Canada";
									$name = $preamble;
									$is_in = 'Canada';
								}
								$state = $code;
								$country = 'Canada';
							} else {
								die "$is_in: unknown Canadian province $state";
							}
						}
					}
					print __LINE__, ": is_in = $is_in (add_record = $add_record, city = $city)\n";
					if($add_record) {
						if($is_in !~ /,/) {
							if((!defined($country)) && ($is_in ne 'GB')) {
								if(Locale::Country::country2code($is_in)) {
									$country = $is_in;
								} else {
									print __LINE__, ": is_in = $is_in (couldn't find country for $city)\n";
									$add_record = 0 if(!defined($country));
								}
							}
						} elsif($is_in =~ /(.+), (.+)$/) {
							$country = $2;
							if($country eq 'GB') {
								# TODO: complete this code
								#	It's tricky because the county system in the
								#	UK is much less well defined compared to US states
								$state = $1;
								print __LINE__, ": is_in = $is_in ($city, $state, $country)\n";
								if($state =~ /\Q$city\E, London/) {
									$state = 'London';
								}
							} elsif(!Locale::Country::country2code($country)) {
								if(my $province = $ca->{'province2code'}{uc($country)}) {
									$country = 'Canada';
									$state = $province;
								} elsif(my $s = $us->{'state2code'}{uc($country)}) {
									$state = $s;
									$country = 'US';
								} elsif($us->{'code2state'}{uc($country)}) {
									$state = uc($country);
									$country = 'US';
								} elsif($s = $au->{'state2code'}{uc($country)}) {
									$state = $s;
									$country = 'Australia';
								} else {
									print __LINE__, ": is_in = $is_in (couldn't find country for $country)\n";
									$add_record = 0;
								}
							}
						}
						print __LINE__, ": is_in = $is_in (add_record = $add_record)\n";
						if(!defined($country)) {
							my $full_name;

							print __LINE__, ": is_in = $is_in\n";
							if(($full_name = $us->{'code2state'}{$is_in})) {
								# Watch, because WA could be Western Australia or Washington, US
								if($file =~ /north-america/) {
									$country = 'US';
								} elsif($file =~ /australia/ && ($full_name = $au->{'code2state'}{$is_in})) {
									$country = 'Australia';
								}
								$state = $is_in;
							} elsif($full_name = $au->{'code2state'}{$is_in}) {
								$country = 'Australia';
								$state = $is_in;
							}
							if(defined($place) && defined($full_name) && ($place =~ /(.+),\s\Q$full_name\E/)) {
								$city = $1;
								undef $name;
								undef $place;
							}
							if(defined($city) && defined($full_name) && ($city =~ /(.+),\s\Q$full_name\E/)) {
								$city = $1;
							}
							$add_record = 1;
							print __LINE__, ": $city, $state, $country\n" if(defined($full_name));
						}
						if(!defined($country)) {
							print __LINE__, ": country not defined ($is_in)\n";
							$add_record = 0;
						} elsif($country !~ /Australia|Canada|US|GB/) {
							# FIXME: use %openaddresses_countries
							if(my $code = $au->{'state2code'}{uc($country)}) {
								if($is_in =~ /(.+?), \Q$country\E$/) {
									$city = $is_in;
									$add_record = 1;
								}
								$state = $code;
								$country = 'Australia';
							} else {
								print __LINE__, ": unsupported country $country\n";
								$add_record = 0;
							}
						} elsif($is_in =~ /,.+,/) {
							# Just towns for now
							if($state) {
								print "state = $state\n";
							}
							if($city) {
								print "city = $city\n";
							}
							die "is_in = $is_in, country = $country" unless($city && $state && $country);
							print __LINE__, ": is_in = $is_in ($city, $state, $country)\n";
						}
						print __LINE__, ": is_in = $is_in (add_record = $add_record)\n";
						$add_record = 0 if(!defined($state));
						if($add_record) {
							print "$city, $is_in: $lat, $lon\n" if(DEBUG&DEBUG_ALL);
							my $row = {
								'CITY' => $city,
								'STATE' => $state,
								'COUNTRY' => $country,
								'LAT' => $lat,
								'LON' => $lon,
							};
							if($name && ($name ne $city)) {
								$row->{'NAME'} = $name;
							}
							if($county) {
								$row->{'COUNTY'} = $county;
							}
							print __LINE__, ': ', Data::Dumper->new([$row])->Dump();
							$inserts += import(country => $country, state => $state, row => $row, file => $filename, ua => $ua, dbh => $dbh, berkeley_db => $berkeley_db, redis => $redis, mongodb => $mongodb);
							if($inserts >= MAX_INSERT_COUNT) {
								flush_queue($dbh, $redis, $mongodb, $berkeley_db);
								$inserts = 0;
							}
						} elsif($country) {
							print __LINE__, ": did not add record is_in = $is_in, country = $country\n";
						} else {
							print __LINE__, ": did not add record is_in = $is_in, country = undef\n";
						}
					}
					$name = undef;
					$lat = undef;
					$lon = undef;
					$is_in = undef;
					undef $country;
					$key = undef;
					$in_node = 0;
				}
			} elsif($reader->nodeType() == 14) {
				if(($reader->name() eq 'node') && $reader->hasAttributes()) {
					$lat = $reader->getAttribute('lat');
					$lon = $reader->getAttribute('lon');
				}
			} else {
				warn 'Unknown reader type ', $reader->nodeType(), ' in ', $reader->document->toString(1), "\n"
			}
		}
		close $pin;
	}

	flush_queue($dbh, $redis, $mongodb, $berkeley_db);	# Check for hanging dups in current state
	$inserts = 0;
} elsif(($force_flag || !(DEBUG&DEBUG_WOF)) && (my $dr5hn = $ENV{'DR5HN_HOME'})) {
	# my @files = (
		# 'cities',
		# 'countries+states+cities',
		# 'states+cities',
		# 'countries+cities',
		# 'countries+states',
		# 'states',
		# 'countries',
		# 'regions',
		# 'subregions'

	my $filename = File::Spec->catfile($dr5hn, 'json', 'countries+states+cities.json');

	$| = 1;
	printf "%-70s\r", $filename;
	print "\n" if(DEBUG);
	$| = 0;

	my $j = JSON::MaybeXS->new()->utf8();

	my $data = File::Slurp::read_file($filename);
	$data = $j->decode($data);

	foreach my $country(@{$data}) {
		# undef %digests_added;
		if(($country->{'iso3'} eq 'USA') || ($country->{'iso3'} eq 'CAN') || ($country->{'iso3'} eq 'AUS')) {
			if($country->{'name'} eq 'United States') {
				$country->{'name'} = 'US';
			}
			foreach my $state(@{$country->{'states'}}) {
				foreach my $city(@{$state->{'cities'}}) {
					my $row = {
						'COUNTRY' => $country->{'name'},
						'STATE' => $state->{'state_code'},
						'CITY' => $city->{'name'},
						'LAT' => $city->{'latitude'},
						'LON' => $city->{'longitude'},
					};
					if(($city->{'name'} =~ /County$/) && ($country->{'name'} eq 'US')) {
						$row->{'COUNTY'} = $city->{'name'};
					} else {
						$row->{'CITY'} = $city->{'name'};
					}
					$inserts += import(row => $row, file => $filename, ua => $ua, dbh => $dbh, redis => $redis, mongodb => $mongodb, berkeley_db => $berkeley_db);
					# print Data::Dumper->new([$row])->Dump();
					if($inserts >= MAX_INSERT_COUNT) {
						flush_queue($dbh, $redis, $mongodb, $berkeley_db);
						$inserts = 0;
					}
				}
			}
		# } elsif($country->{'iso3'} eq 'GBR') {
			# TODO
		};
	}

	flush_queue($dbh, $redis, $mongodb, $berkeley_db);
	$inserts = 0;

	if(BUILDMODE eq 'ONE') {
		undef $ENV{'DR5HN_HOME'};
		undef $ENV{'OSM_HOME'};
		undef $ENV{'WHOSONFIRST_HOME'};
		undef $oa;
	}
}


# undef %digests_added;
# $| = 1;
# printf "%-70s\r", 'creating cities';
# print "\n" if(DEBUG);
# $| = 0;
# foreach my $key(keys %cities) {
	# my ($city, $county, $state, $country) = split(/,/, $key);
	# my $sequence = $cities{$key};

	# $city =~ s/'/''/g;
	# my $query = "INSERT INTO cities('SEQUENCE','CITY','COUNTY','STATE','COUNTRY'" .
		# ') VALUES (' .
		# "'$sequence'," .
		# (($city eq 0) ? "NULL," : "'$city',") .
		# (($county eq 0) ? "NULL," : "'$county',") .
		# "'$state'," .
		# "'$country')";

	# # print "$query\n";
	# $dbh->do($query);
# }

# Reclaim memory
undef %global_md5s;
# %cities = ();
%state_md5s = ();
%state_parent_md5s = ();
undef %state_md5s;
undef %state_parent_md5s;

if((MAX_INSERT_COUNT > 1) && $dbh) {
	local $| = 1;
	printf "%-70s\r", 'creating indicies';
	print "\n" if(DEBUG);
	$| = 0;

	# SQLite - add the keys
	# GRANT INDEX ON geo_coder_free.openaddresses TO 'njh'@'localhost';
	$dbh->prepare('CREATE UNIQUE INDEX md5_index ON openaddresses(md5)')->execute();
	# $dbh->prepare('CREATE UNIQUE INDEX sequence_index ON cities(sequence)')->execute();
	# $dbh->prepare('CREATE UNIQUE INDEX tree_index ON tree(md5,parent)')->execute();
	# $dbh->prepare('CREATE UNIQUE INDEX node_index ON level(md5)')->execute();
	# $dbh->prepare('CREATE UNIQUE INDEX leaf_index ON leaf(md5)')->execute();
}

$| = 1;
printf "%-70s\r", 'Committing';
print "\n" if(DEBUG);
$| = 0;
if($dbh) {
	$dbh->commit();
	$dbh->do('pragma optimize');
	$dbh->disconnect();
}
if($berkeley_db) {
	undef $berkeley_db;
	untie %db_tie;
}
if($redis) {
	print "waiting for redis\n" if(DEBUG&DEBUG_FLUSH);
	$redis->wait_all_responses();	# Pipelining mode
	$redis->bgsave();
	$redis->shutdown();
}
print ' ' x 70, "\r" if(!DEBUG);

# Return a list of all .csv or .geojson files under the given directory
sub create_tree {
	my $where = shift or return;
	my $csv = shift;
	my @files;
	my $fin;

	if($csv) {
		open($fin, '-|', "find $where -name *.csv");
	} else {
		open($fin, '-|', "find $where -name *.geojson");
	}

	$| = 1;
	printf "%-70s\r", $where;
	print "\n" if(DEBUG);
	$| = 0;

	while(my $line = <$fin>) {
		# print $line;
		chomp $line;
		push @files, $line;
	}
	close $fin;

	return @files;
}

# Return a list of all .csv or .geojson files from all the Git repositories
# in the current directory
sub create_tree_from_git {
	my $where = shift;
	my $csv = shift;
	my @files;
	my $olddir = getcwd();

	$| = 1;
	printf "%-70s\r", $where;
	print "\n" if(DEBUG);
	$| = 0;

	foreach my $dir(<"$where/*/.git">) {
		my($d1, $d2) = fileparse($dir);	# File::BaseName
		chdir $d2;
		# Some call the main branch master, some call it main
		# So use HEAD
		# open(my $fin, '-|', 'git ls-tree -r master --name-only');
		open(my $fin, '-|', 'git ls-tree -r HEAD --name-only');
		print "Getting file list in $d2\n" if(DEBUG&DEBUG_ALL);
		while(my $line = <$fin>) {
			chomp $line;
			my $file = File::Spec->catfile($d2, $line);
			if($csv && ($line =~ /\.csv$/)) {
				push(@files, $file);
			} elsif($line =~ /\.geojson$/) {
				push(@files, $file);
			}
		}
		close $fin;
	}
	chdir $olddir;

	return @files;
}

# Import a location into the database
# Parses the data and prepares a set of columns to be queued for insertion
# global stores in the global_md5 as well, useful when going through something state by state
# If NUMBER and/or NAME is given, also add without that field
sub import
{
	my %param;
	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(ref($_[0])) {
		die 'import: bad args';
	} elsif(scalar(@_) % 2 == 0) {
		%param = @_;
	} else {
		die 'import: no args';
	}

	my $row = $param{'row'} || die 'import: no row';
	$row = { %{$row} };	# Take a copy of the hash because we're going to play with it
	my $country = $param{'country'} || $row->{'COUNTRY'};
	if(!defined($country)) {
		print STDERR "\nMissing parameter for import():\n",
			Data::Dumper->new([\$row])->Dump(),
			"\n";
		my $i = 0;
		while(my @call_details = caller($i++)) {
			print STDERR "\tCalled at line ", $call_details[2], "\n";
		}
		die 'country not defined';
	}
	my $state = $param{'state'} || $row->{'STATE'};	# Will come from $row->{'REGION'}
	my $file = $param{'file'} || die 'import: no file';
	my $ua = $param{'ua'} || die 'import: no ua';
	my $dbh = $param{'dbh'};
	my $redis = $param{'redis'};
	my $berkeley_db = $param{'berkeley_db'};
	my $global = $param{'global'} || 0;
	if((!$dbh) && (!$berkeley_db) && (!$mongodb) && (!$redis)) {
		print STDERR "\nMissing parameter for import():\n",
			Data::Dumper->new([\$row])->Dump(),
			"\n";
		my $i = 0;
		while(my @call_details = caller($i++)) {
			print STDERR "\tCalled at line ", $call_details[2], "\n";
		}
		die 'import neither dbh, berkeley_db, redis nor mongodb defined';
	}
	my $inserts = 0;

	if($state) {
		# Two characters in US/Canada, three in Australia
		$state = uc($state);
	}

	my $city = $row->{'CITY'};
	my $county = $row->{'COUNTY'};
	if(defined($county) && ($county =~ /geojson/i)) {
		print STDERR "\nError in county name:\n";
		my $i = 0;
		while(my @call_details = caller($i++)) {
			print STDERR "\tCalled at line ", $call_details[2], "\n";
		}
		die "$county is not a valid county name";
	}

	if(($file !~ /statewide/) && ($file !~ /^province/) && ($file !~ /countrywide/)) {
		if($file =~ /^city[_\s]of[_\s](.+).csv$/) {
			$city = $1;
			if(defined($city) && (($city =~ /\Q$oa\E/i) || ($city =~ /\/..\//))) {
				print __LINE__, ': ', Data::Dumper->new([\$row])->Dump();
				my $i = 0;
				while(my @call_details = caller($i++)) {
					print STDERR "\tCalled at line ", $call_details[2], "\n";
				}
				die "$file: $city ($country/$state)";
			}
		} elsif($file =~ /^town[_\s]of[_\s](.+).csv$/) {
			$city = $1;
		} elsif($file =~ /^(.+)[_\s]borough.csv$/) {
			# See $oa/us/ak/kenai_peninsula_borough.csv
			$city = $1 if((!defined($city)) || ($city eq 'REMOTE'));
			$city =~ s/\Q$oa\E\/?//i;
			$city =~ s/\.csv$//;
			$city =~ s/^.+\///;
			$city =~ s/(.+)[_\s]borough.csv$/$1/;
			$city =~ tr/_/ /;
		} elsif($file =~ /^(.+)-region.csv$/) {
			$city = $1 if(!defined($city));
		} elsif($file =~ /^township[_\s]of[_\s](.+).csv$/) {
			$city = $1;
		} elsif($file =~ /^(.+)[_\s]district.csv$/) {
			$city = $1 if(!defined($city));
			$city =~ s/\Q$oa\E\/?//i;
			$city =~ s/\.csv$//;
			$city =~ s/^.+\///;
			$city =~ s/(.+)[_\s]district.csv$/$1/;
			$city =~ tr/_/ /;
			die "BUG: $file: couldn't extract city name" if(length($city) == 0);
		} elsif((!defined($city)) && ($file !~ /countries\+states\+cities/i)) {
			$city = $file;
			$city =~ s/\Q$oa\E\/?//i;
			$city =~ s/\.csv$//;
			$city =~ s/^.+\///;	# Remove leading ca/nt in ca/nt/city_of_yellow_knife
			$city =~ s/^city[_\s]of[_\s](.+).csv$/$1/;
			$city =~ tr/_/ /;
			die "BUG: $file: couldn't extract city name" if(length($city) == 0);
		} elsif((!defined($county)) &&
			($file !~ /^WHOSONFIRST\-DATA/i)
			&& ($file !~ /countrywide/)
			&& ($file !~ /countries\+states\+cities/i)	# $DR5HN
			&& ($file !~ /^\d+\.GEOJSON$/i)) {
			$county = $file;
			$county =~ s/\.csv$//;
			$county =~ s/\Q$oa\E\/?//i;
			$county =~ s/^.+\///;
			$county =~ tr/_/ /;
		}
	}
	if(!defined($city)) {
		# print "$state:\n", Data::Dumper->new([\$row])->Dump();
		my $zip = $row->{'POSTCODE'};
		if((!defined($city)) && defined($zip) && (my $info = $zipcodes{$zip})) {
			$city = $info->{'city'};
			$county = $info->{'county'};
		}
		# die $county if(defined($county) && ($county =~ /\Q$oa\E/i));
		# die $city if(defined($city) && ($city =~ /\Q$oa\E/i));
		# die $city if(defined($city) && ($city =~ /\/..\//));
		if((!defined($city)) && defined($zip) && ($zip =~ /^(\d{5})/)) {
			$zip = $1;
			if(exists($unknown_zips{"$country/$zip"})) {
				return 0;
			}
			my $res = $ua->get("https://api.zippopotam.us/$country/$zip");
			if(!$res->is_success()) {
				warn "$file: https://api.zippopotam.us/$country/$zip: ", $res->status_line();
				$unknown_zips{"$country/$zip"} = 1;
				return 0;
			}
			my $rc = JSON::MaybeXS->new()->utf8()->decode($res->content());
			if(!defined($rc)) {
				# print "\n", Data::Dumper->new([\$row])->Dump();
				return 0;
			}
			my $place = $rc->{'places'}->[0];
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
				$inserts = insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
			}
		}
		if((!defined($city)) && !defined($state)) {
			# die Data::Dumper->new([\$row])->Dump();
			return $inserts if(!$zip);
			return $inserts if($zip !~ /^\d{5}/);
			$dbh->disconnect() if($dbh);
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
		return $inserts;	# Could have added one above
	}
	return $inserts if(($row->{'LAT'} == 0) && ($row->{'LON'} == 0));
	my $street = $row->{'STREET'};
	if($street) {
		$street =~ s/\s\s+/ /g;

		if($city && ($city =~ /(.+),\s*(.+)/)) {
			# For example the city could be "North Side, Chicago", which comes from the case when a borough record
			# has been added.  Let's allow searches on the borough or the city alone
			my $borough = $1;
			my $city_name = $2;
			print "Break up $city\n\tstreet = $street\n\tborough = $borough\n\tcity_name = $city_name\n" if(DEBUG&DEBUG_BREAKUP);
			if($borough ne $street) {
				my %columns = ( %{$param{'row'}}, 'COUNTRY' => $country, 'STATE' => $state, 'COUNTY' => $county, 'CITY' => $borough );
				print "\t", Data::Dumper->new([\%columns])->Dump() if(DEBUG&DEBUG_BREAKUP);
				$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
				$columns{'CITY'} = $city_name;
				print "\t", Data::Dumper->new([\%columns])->Dump() if(DEBUG&DEBUG_BREAKUP);
				$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
				print "\tDone\n" if(DEBUG&DEBUG_BREAKUP);
			}
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
		$city =~ s/^BOROUGH\s+OF\s+//;
		$city =~ s/^URBAN\s+//;
		$city =~ s/\(HISTORICAL\)//;
		$city =~ s/\s\s+/ /g;
		$city =~ s/\s+$//g;
		$city =~ s/^\s+//g;
	}
	if($street) {
		$street = uc($street);
		if($street =~ /(.+)\s+(.+)\s+(.+)/) {
			my $a;
			if((lc($2) ne 'cross') && ($a = $abbr->abbreviate($2))) {
				$street = "$1 $a $3";
			} elsif($a = $abbr->abbreviate($3)) {
				$street = "$1 $2 $a";
			}
		} elsif($street =~ /(.+)\s(.+)$/) {
			if(my $a = $abbr->abbreviate($2)) {
				$street = "$1 $a";
			}
		}
		$street =~ s/^0+//;	# Turn 04th St into 4th St
	}
	if(!defined($county)) {
		if($file =~ /^(.+)[_\-]county.csv$/) {
			$county = $1;
			$county =~ s/\Q$oa\E\/?//i;
			$county =~ s/^.+\///;
			$county =~ tr/_/ /;
		} elsif(defined($city) && ($city =~ /(.+)\s+COUNTY$/i)) {
			$county = $1;
			$city = undef;
		}
	}
	if((!defined($county)) && $row->{'DISTRICT'}) {
		if(!defined($state)) {
			print STDERR "\nMissing parameter for import():\n",
				Data::Dumper->new([\$row])->Dump(),
				"\n";
			my $i = 0;
			while(my @call_details = caller($i++)) {
				print STDERR "\tCalled at line ", $call_details[2], "\n";
			}
			die 'state not defined';
		}
		if(($row->{'DISTRICT'} ne $state) && ($row->{'DISTRICT'} !~ /^\d+$/)) {
			$county = $row->{'DISTRICT'};
		}
	}
	if(defined($city) && (!defined($county)) && ($city =~ /\s+County$/)) {
		$county = $city;
		undef $city;
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
	# die $county if(defined($county) && ($county =~ /\Q$oa\E/i));
	# if(defined($city) && (($city =~ /\Q$oa\E/i) || ($city =~ /\/..\//))) {
		# print __LINE__, ": $file: ", Data::Dumper->new([\$row])->Dump();
		# my $i = 0;
		# while(my @call_details = caller($i++)) {
			# print STDERR "\tCalled at line ", $call_details[2], "\n";
		# }
		# die "$file: $city ($country/$state)";
	# }
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
		if(!defined($state)) {
			if(($country eq 'AU') && ($file =~ /\/au\/(...)\/.+.csv$/)) {
				$state = uc($1);
			} elsif(my $region = $row->{'REGION'}) {
				delete $row->{'REGION'};
				$state = uc($region);
			}

			if(!defined($state)) {
				print __LINE__, ': ', Data::Dumper->new([$row])->Dump();
				my $i = 0;
				while(my @call_details = caller($i++)) {
					print STDERR "\tCalled at line ", $call_details[2], "\n";
				}
				die "$file: $country";
			}
		}

		if(defined($city) && (length($state) == 2) && ($city =~ /(.+)\s\Q$state\E/)) {
			$city = $1;
		}

		my %columns = (
			'COUNTRY' => $country,
			'CITY' => $city,
			'STATE' => $state,
		);

		$columns{'COUNTY'} = $county if(defined($county));
		$columns{'STREET'} = $street if(defined($street));

		foreach my $c('LAT', 'LON', 'NAME', 'NUMBER') {
			# Use 'defined" because LON can be 0 in London
			$columns{$c} = $row->{$c} if(defined($row->{$c}));
		}

		die __LINE__, ': ', Data::Dumper->new([$row])->Dump() if((DEBUG&DEBUG_DATA_VALIDATE) && $columns{'NUMBER'} && ($columns{'NUMBER'} !~ /^\d/));
		# Can't compare '== 0' because of house numbers such as '43A'
		delete($columns{'NUMBER'}) if(defined($columns{'NUMBER'}) && ($columns{'NUMBER'} eq '0'));

		# print __LINE__, ': ', Data::Dumper->new([\%columns])->Dump();
		if((!defined($city)) ||
		   ($country eq 'GB') && ($city eq 'LONDON') && defined($state) && ($state eq 'LONDON')) {
			delete $columns{'CITY'};
		}
		foreach my $column(keys %columns) {
			delete $columns{$column} if(!defined($columns{$column}));
		}
		if((!defined($city)) && defined($street) && defined($row->{'REGION'}) && !defined($county)) {
			$county = uc(delete $row->{'REGION'});
			if(!defined($street)) {
				print "County and street with no city:\n", Data::Dumper->new([$row])->Dump() if($county && (DEBUG&DEBUG_DATA_VALIDATE));
				return $inserts;
			}
		}

		print __LINE__, ": $file\n" if(DEBUG&DEBUG_OSM);

		$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
		if(delete($columns{'COUNTY'})) {
			return $inserts if(!defined($city));
			$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
		}
		my $name = $columns{'NAME'};
		if($name) {
			# TODO: more of these
			# foreach my $classifier($properties->{'sg:classifier'}) {
			#	Check if $name ends with uc($classifier->{category})
			if($name =~ /^(.+)\s+RESTAURANT/i) {
				$columns{'NAME'} = $1;
				$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
				# print "RESTAURANT: $1\n";
			}
			delete $columns{'NAME'};
			$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
		}
		if(delete($columns{'NUMBER'})) {
			if($name) {
				# For when a name is known but not a street number
				$columns{'NAME'} = $name;
				$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
				if($name =~ /^(.+)\s+RESTAURANT/i) {
					$columns{'NAME'} = $1;
					$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
					# print "RESTAURANT: $1\n";
				}
				delete($columns{'NAME'});
			}

			# Match somewhere in the street when number isn't known
			$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
			if(delete($columns{'STREET'})) {
				if($name) {
					# For when a name is known but not a street
					$columns{'NAME'} = $name;
					$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
					if($name =~ /^(.+)\s+RESTAURANT/i) {
						$columns{'NAME'} = $1;
						$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
						# print "RESTAURANT: $1\n";
					}
					delete($columns{'NAME'});
				}
				# Match somewhere in the city when street isn't known
				$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
			}
		} elsif($name && delete($columns{'STREET'})) {
			# For when a name is known but not a street
			$columns{'NAME'} = $name;
			$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
			if($name =~ /^(.+)\s+RESTAURANT/i) {
				$columns{'NAME'} = $1;
				$inserts += insert($dbh, $redis, $mongodb, $berkeley_db, $global, %columns);
				# print "RESTAURANT: $1\n";
			}
		}
	}
	return $inserts;
}

# Queue one row to be added to the database
# Returns the number of items added to the queued_commits array
sub insert
{
	my ($dbh, $redis, $mongodb, $berkeley_db, $global, %columns) = @_;

	if((!$dbh) && (!$mongodb) && (!$berkeley_db) && (!$redis)) {
		die 'insert neither dbh, berkeley_db, redis nor mongodb defined';
	}
	die 'nothing to insert' if(scalar(keys %columns) == 0);

	foreach my $column(keys %columns) {
		if(!defined($columns{$column})) {
			delete $columns{$column};
		} elsif($columns{$column} =~ /^\s+$/) {
			delete $columns{$column};
		}
	}
	if(defined($columns{'COUNTY'}) && ($columns{'COUNTY'} =~ /geojson/i)) {
		print STDERR "\nError in county name:\n";
		my $i = 0;
		while(my @call_details = caller($i++)) {
			print STDERR "\tCalled at line ", $call_details[2], "\n";
		}
		die $columns{'COUNTY'}, ' is not a valid county name';
	}

	# print Data::Dumper->new([$columns])->Dump() if($columns{'CITY'} && (uc($columns{'CITY'}) eq 'INDIANAPOLIS'));
	# print Data::Dumper->new([$columns])->Dump() if($columns{'NAME'} && (uc($columns{'NAME'}) eq 'EL PAPI STREET TACOS'));
	if(defined($columns{'COUNTY'}) && defined($columns{'CITY'}) && ($columns{'COUNTY'} =~ /CITY OF \Q$columns{'CITY'}\E/i)) {
		# /home/njh/misc/openaddr/ca/on/city_of_markham.csv:
		# {
		#	'CITY' => 'MARKHAM',
		#	'COUNTRY' => 'CA',
		#	'COUNTY' => 'CITY OF MARKHAM',
		#	'LAT' => '43.8514452',
		#	'LON' => '-79.3525134',
		#	'NUMBER' => '2',
		#	'STATE' => 'ON',
		#	'STREET' => 'MONTGOMERY CT'
		# };
		delete $columns{'COUNTY'};
	}
	if(DEBUG&DEBUG_INSERT) {
		print __LINE__, ': ', Data::Dumper->new([\%columns])->Dump();
		my $i = 0;
		while(my @call_details = caller($i++)) {
			print STDERR "\tcalled at line ", $call_details[2], "\n";
		}
	}

	my $lat = $columns{'LAT'};
	my $lon = $columns{'LON'};

	die __LINE__, ': ', Data::Dumper->new([\%columns])->Dump() unless(defined($lat) && defined($lon));
	# die "$lat/$lon" unless($columns{'STATE'});

	# Remove duplicate, leading and trailing spaces from entries.  Some openaddresses files are littered with them
	foreach my $column(keys %columns) {
		if(exists($columns{$column})) {
			$columns{$column} =~ s/\s+$//g;
			$columns{$column} =~ s/^\s+//g;
			$columns{$column} =~ s/\s\s+/ /g;
		} else {
			my $i = 0;
			while(my @call_details = caller($i++)) {
				print STDERR "\tCalled at line ", $call_details[2], "\n";
			}
			die Data::Dumper->new([\%columns])->Dump();
			delete $columns{$column};
		}
	}

	# my $digest = Digest::MD5::md5_base64(map { Encode::encode_utf8($columns{$_}) } sort keys %{$columns});
	my $digest;
	# print __LINE__, ': ', Data::Dumper->new([\%columns])->Dump();
	foreach my $column('NAME','NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
		$digest .= $columns{$column} if(exists($columns{$column}));
	}
	# print "$digest\n";
	$digest = create_md5($global, Encode::encode_utf8($digest));

	if(!defined($digest)) {
		# Already known
		print 'Ignore duplicate: ', join(',', values(%columns)), "\n" if(DEBUG&DEBUG_INSERT);
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
		# print "line ", $call_details[2], "\n";
		# print Data::Dumper->new([\%columns])->Dump();
		# print Data::Dumper->new([$href])->Dump();
	# }

	my @call_details = caller(0);
	$columns{'LINE'} = $call_details[2] if(DEBUG);
	$queued_commits{$digest} = \%columns;
	if(DEBUG&DEBUG_INSERT) {
		flush_queue($dbh, $redis, $mongodb, $berkeley_db);
	}
	if(!defined($columns{'COUNTRY'})) {
		print "insert: no country. Called from line ", $call_details[2], "\n";
		die Data::Dumper->new([\%columns])->Dump();
	}

	# my $key = city_key($columns{'CITY'}, $columns{'COUNTY'}, $columns{'STATE'}, $columns{'COUNTRY'});
	# if(!$cities{$key}) {
		# $city_sequence++;
		# # print "adding '$key' to cities list\n";
		# $cities{$key} = $city_sequence;
	# }

	# Some postal address parsers have problems with "N FOO ST", so also store "NFOOST"
	if($columns{'STREET'} && ($columns{'STREET'} =~ /^[A-Z]\s\w+\s\w+$/)) {
		my %columns2 = %columns;
		# Handle https://rt.cpan.org/Public/Bug/Display.html?id=124919
		$columns2{'STREET'} =~ s/\s+//g;
		$columns2{'LINE'} = $call_details[2] if(DEBUG);
		$digest = undef;

		print __LINE__, ': ', Data::Dumper->new([\%columns2])->Dump() if(DEBUG&DEBUG_INSERT);
		foreach my $column('NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
			$digest .= $columns2{$column} if(exists($columns2{$column}));
		}
		if($digest = create_md5($global, Encode::encode_utf8($digest))) {
			$queued_commits{$digest} = \%columns2;
			if(DEBUG&DEBUG_ALL) {
				flush_queue($dbh, $redis, $mongodb, $berkeley_db);
			}
			return 2;
		# } else {
			# print 'Ignore ', join(',', values(%columns2)), "\n";
		}
	}
	return 1;
}

# All of the place's values are combined into one INSERT INTO
# Be aware of https://github.com/openaddresses/openaddresses/issues/3928
sub flush_queue
{
	my ($dbh, $redis, $mongodb, $berkeley_db) = @_;

	print 'flush ', scalar(keys %queued_commits), " records\n" if(DEBUG&DEBUG_FLUSH);

	# my @columns = ('LAT','LON','NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY');
	# my @columns = ('LAT','LON','NAME','NUMBER','STREET');

	my $query;
	my $geo_hash = Geo::Hash->new();

	while(my($md5, $row) = each(%queued_commits)) {
	# foreach my $md5(keys %queued_commits) {
		# my $row = $queued_commits{$md5};
		# if($md5 eq 'D8GO4pMZCAYej/OR') {
			# my @call_details = caller(0);
			# print "flush_queue: Flomation called from line ", $call_details[2], "\n\t",
				# Data::Dumper->new([\%queued_commits])->Dump();
		# }
		# if($md5 == 17736627262094380841) {
			# my @call_details = caller(0);
			# print "flush_queue: 177366... called from line ", $call_details[2], "\n\t",
				# Data::Dumper->new([\%queued_commits])->Dump();
		# }
		die if(ref($row) ne 'HASH');
		my $country = $row->{'COUNTRY'};
		if(!defined($country)) {
			my @call_details = caller(0);
			print STDERR 'flush_queue: called from line ', $call_details[2], "\n";
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
			print 'flush_queue: ignoring blank entry called from line ', $call_details[2], "\n\t",
				Data::Dumper->new([$row])->Dump() if(DEBUG&DEBUG_DATA_VALIDATE);
			next;
		}

		# print join(',', @columns), ": $md5\n";
		# print "$md5: ", Data::Dumper->new([$row])->Dump();

		if($mongodb) {
			$mongodb->insert_one({ md5 => $row });
		}
		# die Data::Dumper->new([$row])->Dump() if(exists($db_tie{$md5}));
		if($berkeley_db) {
			# $berkeley_db->put($md5, $geo_hash->encode($row->{'LAT'}, $row->{'LON'}, 10));
			$db_tie{$md5} = $geo_hash->encode($row->{'LAT'}, $row->{'LON'}, 10);
		}
		if($dbh) {
			if(!defined($query)) {
				# Don't do this - it saves on global_md5s memory but is so slow
				# Without this code, you don't need DELETE privileges
				# if($ENV{'MARIADB_SERVER'}) {
					# # This is why you need DELETE privileges
					# # Don't use INSERT IGNORE because it ignores *all* errors
					# # GRANT DELETE ON geo_coder_free.openaddresses TO 'njh'@'localhost';
					# $query = 'REPLACE INTO openaddresses(LAT, LON, MD5) VALUES (';
				# } else {
					# $query = 'INSERT INTO openaddresses(LAT, LON, MD5) VALUES (';
					$query = 'INSERT INTO openaddresses(geohash, md5) VALUES (';
				# }
			} else {
				$query .= ',(';
			}

			$md5 =~ s/'/''/g;
			# $query .= $row->{'LAT'} . ',' . $row->{'LON'} . ",'$md5')";
			$query .= "'" . $geo_hash->encode($row->{'LAT'}, $row->{'LON'}, 10) . "','$md5')";
		}

		# my $key = city_key($row->{'CITY'}, $row->{'COUNTY'}, $state, $country);
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
	# if(0) {
		# my $row;
		# my $digest = $row->{'COUNTRY'};
		# my $parent_md5;
#
		# my $md5 = $state_parent_md5s{$digest};
		# if(!defined($md5)) {
			# $md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
			# $state_parent_md5s{$md5} = $digest;
			# if(!defined($tree_query)) {
				# $tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
			# } else {
				# $tree_query .= ',(';
			# }
			# $tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
				# ",'$md5',NULL)";
		# }
#
		# $digest = undef;
		# foreach my $column('STATE','COUNTRY') {
			# $digest .= $row->{$column} if($row->{$column});
		# }
		# $parent_md5 = $md5;
		# $md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
		# if(!defined($state_parent_md5s{$md5})) {
			# $state_parent_md5s{$md5} = $digest;
			# if(!defined($tree_query)) {
				# $tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
			# } else {
				# $tree_query .= ',(';
			# }
			# $tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
				# ",'$md5','$parent_md5')";
		# }
#
		# if($row->{'COUNTY'}) {
			# $digest = undef;
			# foreach my $column('COUNTY','STATE','COUNTRY') {
				# $digest .= $row->{$column} if($row->{$column});
			# }
			# $parent_md5 = $md5;
			# $md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
			# if(!defined($state_parent_md5s{$md5})) {
				# $state_parent_md5s{$md5} = $digest;
				# if(!defined($tree_query)) {
					# $tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
				# } else {
					# $tree_query .= ',(';
				# }
				# $tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
					# ",'$md5','$parent_md5')";
			# }
		# }
		# if($row->{'CITY'}) {
			# $digest = undef;
			# foreach my $column('CITY','COUNTY','STATE','COUNTRY') {
				# $digest .= $row->{$column} if($row->{$column});
			# }
			# $parent_md5 = $md5;
			# $md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
			# if(!defined($state_parent_md5s{$md5})) {
				# $state_parent_md5s{$md5} = $digest;
				# if(!defined($tree_query)) {
					# $tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
				# } else {
					# $tree_query .= ',(';
				# }
				# $tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
					# ",'$md5','$parent_md5')";
			# }
		# }
		# if($row->{'STREET'}) {
			# $digest = undef;
			# foreach my $column('STREET','CITY','COUNTY','STATE','COUNTRY') {
				# $digest .= $row->{$column} if($row->{$column});
			# }
			# $parent_md5 = $md5;
			# $md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
			# if(!defined($state_parent_md5s{$md5})) {
				# $state_parent_md5s{$md5} = $digest;
				# if(!defined($tree_query)) {
					# $tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
				# } else {
					# $tree_query .= ',(';
				# }
				# $tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
					# ",'$md5','$parent_md5')";
			# }
		# }
		# if($row->{'NUMBER'}) {
			# $digest = undef;
			# foreach my $column('NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
				# $digest .= $row->{$column} if($row->{$column});
			# }
			# $parent_md5 = $md5;
			# $md5 = substr(Digest::MD5::md5_base64(Encode::encode_utf8($digest)), 0, 16);
			# if(!defined($state_parent_md5s{$md5})) {
				# $state_parent_md5s{$md5} = $digest;
				# if(!defined($tree_query)) {
					# $tree_query = 'INSERT INTO tree(lat,lon,md5,parent) VALUES ('
				# } else {
					# $tree_query .= ',(';
				# }
				# $tree_query .= $row->{'LAT'} . ',' .  $row->{'LON'} .
					# ",'$md5','$parent_md5')";
			# }
		# }

		# # TODO: add NAME field
	# }

	if($query) {
		# print "$query\n";
		# $| = 1;
		# print '.';
		# $| = 0;
		if($dbh) {
			try {
				$dbh->do($query);
			} catch {
				my $err = $_;
				print STDERR "Error in flush_queue ($query)\n",
					Data::Dumper->new([\%queued_commits])->Dump(),
					"\n";
				my $i = 0;
				while(my @call_details = caller($i++)) {
					print STDERR "\tCalled at line ", $call_details[2], "\n";
				}
				die $err;
			};
		}
		if($redis) {
			print "writing to redis\n" if(DEBUG&DEBUG_FLUSH);
			my %data = map {
				my $row = $queued_commits{$_};
				# Use the key as a 64-bit number
				# to save some memory
				pack('i', $_) => $row->{'LAT'} . ',' . $row->{'LON'}
			} keys %queued_commits;

			# The sub {} means that we use pipelining mode
			$redis->mset(%data, sub {});
		}
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

# Create an MD5 of the information to be added.
# Returns undef if we already know it
sub create_md5
{
	my($global, $digest) = @_;

	# if($digests_added{$digest}) {
		# print "ignoring duplicate $digest\n" if(DEBUG&DEBUG_MD5);
		# return;
	# }
	# $digests_added{$digest} = 1;

	my $rc;
	$digest =~ tr/ž/z/;	# Remove wide characters
	$digest =~ s/\N{U+017E}/z/g;
	$digest =~ s/\xc5\xbe/z/g;
	if(length($digest) <= 16) {
		$rc = $digest;
	} else {
		$rc = substr Digest::MD5::md5_base64($digest), 0, 16;
	}
	# FIXME: prefixing the rc with the NUMBER field could reduce the changes of clashes, perhaps
	if($queued_commits{$rc} || $global_md5s{$rc} || $state_md5s{$rc}) {
		warn "Potential clash $digest => $rc" if(DEBUG&DEBUG_MD5);
		return undef;
	}

	if(defined($dbh)) {
		# Avoid duplicates on SQL databases since the PRIMARY KEY is added later
		# FIXME: The $global flag is a failed experiment to reduce usage
		#	remove it
		if($global || (BUILDMODE eq 'ALL')) {
			if(DEBUG&DEBUG_MD5) {
				print "global $digest => $rc\n";
				$global_md5s{$rc} = $digest;
			} else {
				$global_md5s{$rc} = 1;
			}
		} else {
			if(DEBUG&DEBUG_MD5) {
				print "state $digest => $rc\n";
				$state_md5s{$rc} = $digest;
			} else {
				$state_md5s{$rc} = 1;
			}
		}
	}
	return $rc;
}

# # State must be the abbreviated form
# sub city_key {
	# my ($city, $county, $state, $country) = @_;
#
	# if(!defined($city)) {
		# $city = '0';
	# }
	# if(!defined($county)) {
		# $county = '0';
	# }
	# if(!defined($state)) {
		# return "$city,$county,0,$country";
	# }
	# return "$city,$county,$state,$country";
# }

# Given a Whosonfirst ID, return the matching geojson. Cache lookups
sub get_wof {
	my ($properties, $id, $geojson_file) = @_;

	return if($id < 0);
	if($l1_cache{$id}) {
		# my @call_details = caller(0);
		# print "get_wof: stored $l1_cache{$id} at line ", $call_details[2], "\n" if(DEBUG&DEBUG_GET_WOF);
		return $l1_cache{$id};
	}
	if(scalar(keys %l1_cache) >= 100) {
		# TODO: LRU
		print "get_wof: emptying l1_cache\n" if(DEBUG&DEBUG_GET_WOF);
		%l1_cache = ();
	}

	if(defined($l2_cache)) {
		if(my $name = $l2_cache->get($id)) {
			my @call_details = caller(0);
			print "get_wof: cached $name at line ", $call_details[2], "\n" if(DEBUG&DEBUG_GET_WOF);
			$l1_cache{$id} = $name;
			return $name;
		}
	} else {
		# On machines that are paging heavily because of the large memory usage,
		# discarding can take more than 10 seconds, so up the timeout to a minute
		$l2_cache = CHI->new(driver => 'RawMemory', global => 0, max_size => 1_000, discard_timeout => 60);
	}

	print "get_wof: not cached $id\n" if(DEBUG&DEBUG_GET_WOF);
	my $filename;
	# Unfortunately whosonfirst doesn't tell you the repo of the region_id, just
	# its name, so you need to search all repos to find it
	# https://github.com/whosonfirst-data/whosonfirst-data/issues/1844
	my $repo;
	if($properties->{'wof:repo'}) {
		# Die while I debug the fix
		$repo = $properties->{'wof:repo'};
	} else {
		$repo = '*';
	}
	print "Repo = $repo\n" if(DEBUG&DEBUG_GET_WOF);
	if($id =~ /(\d{3})(\d{3})(\d{3})(\d+)/) {
		$filename = $ENV{'WHOSONFIRST_HOME'} . "/$repo/data/$1/$2/$3/$4/$id.geojson";
		if(($repo ne '*') && (!-e $filename)) {
			print "Forcing glob to a different repo\n" if(DEBUG&DEBUG_GET_WOF);
			$repo = '*';
			$filename = $ENV{'WHOSONFIRST_HOME'} . "/*/data/$1/$2/$3/$4/$id.geojson";
		}
	} elsif($id =~ /(\d{3})(\d{3})(\d+)/) {
		$filename = $ENV{'WHOSONFIRST_HOME'} . "/$repo/data/$1/$2/$3/$id.geojson";
		if(($repo ne '*') && (!-e $filename)) {
			print "Forcing glob to a different repo\n" if(DEBUG&DEBUG_GET_WOF);
			$repo = '*';
			$filename = $ENV{'WHOSONFIRST_HOME'} . "/*/data/$1/$2/$3/$id.geojson";
		}
	} else {
		die "Can't parse $id";
	}

	if($repo eq '*') {
		# Do a glob expansion on the string, useful if it's something like
		#	$ENV{'WHOSONFIRST_HOME'} . "/*/data/286/455/973/286455973.geojson"
		print "Glob expand $filename\n" if(DEBUG&DEBUG_GET_WOF);

		# Because of the layout of WOF (lots of small directories), this can be slow on EXT4, it would be nice to find a better way
		# my @filelist = <"$filename">;
		# $filename = $filelist[0];

		# File::Find
		find({	
			wanted => sub {
				return unless $_ =~ qr/$id.geojson$/;
				$filename = $File::Find::name;
				$File::Find::prune = 1;	# stop descending further
			},
			no_chdir => 1,
		}, $ENV{'WHOSONFIRST_HOME'});
		print "Found: $filename\n" if(DEBUG & DEBUG_GET_WOF);
	}
	if((!$filename) || (! -r $filename)) {
		# Probably shouldn't die here
		if(DEBUG&DEBUG_GET_WOF) {
			print STDERR __LINE__, ":\n";
			if($filename) {
				print STDERR "\t$filename: $!\n"
			}
			my @call_details = caller(0);
			print STDERR "\tcalled from line ",
				$call_details[2], "\n\t";
			die "$geojson_file: can't find $id file for ", $properties->{'wof:name'};
		}
		if($filename) {
			print STDERR "$geojson_file: can't find $id file for ", $properties->{'wof:name'}, ": $filename: $!\n";
		} else {
			print STDERR "$geojson_file: can't find $id file for ", $properties->{'wof:name'}, "\n";
		}
		return
	}
	print "get_wof: look at $filename\n" if(DEBUG&DEBUG_GET_WOF);

	my $data = File::Slurp::read_file($filename);
	$properties = JSON::MaybeXS->new()->utf8()->decode($data)->{'properties'};
	return if(scalar(@{$properties->{'wof:superseded_by'}}));
	return if(exists($properties->{'mz:is_current'}) && ($properties->{'mz:is_current'} <= 0));
	# if($properties->{'wof:name'}) {
		if($properties->{'wof:placetype'} eq 'region') {
			my $country = uc($properties->{'wof:country'});
			if(($country eq 'US') || ($country eq 'CA') || ($country eq 'AU')) {
				print "\t", $properties->{'wof:abbreviation'} // $properties->{'wof:shortcode'} // $properties->{'wof:name'}, "\n" if(DEBUG&DEBUG_GET_WOF);
				return $l1_cache{$id} = $l2_cache->set($id, $properties->{'wof:abbreviation'} // $properties->{'wof:shortcode'} // $properties->{'wof:name'}, '1 minute');
			}
		}
		print "\tname: ", $properties->{'wof:name'}, "\n" if(DEBUG&DEBUG_GET_WOF);
		return $l1_cache{$id} = $l2_cache->set($id, $properties->{'wof:name'}, '1 minute');
	# }
}

# Do our best to parse and extract data from OpenStreetMaps
sub extract_osm_home
{
	die scalar(@_) if(scalar(@_) != 4);

	my($file, $name, $place, $is_in) = @_;

	$is_in =~ s/[;,](\w)/, $1/g;
	$is_in =~ s/;\s?/, /g;
	$is_in =~ s/,\sUnited Kingdom/, GB/;
	$is_in =~ s/, UK,.+$/, GB/;
	$is_in =~ s/^UK, UK$/GB/;
	$is_in =~ s/GB, GB$/GB/;
	$is_in =~ s/, UK$/, GB/;
	$is_in =~ s/^UK,\s?(United Kingdom|England|Scotland|Wales|Cymru),\s?/GB, /;
	$is_in =~ s/^UK,\s?GB,\s?/GB, /;
	$is_in =~ s/(England|Scotland|Wales|Cymru), GB/GB/;
	$is_in =~ s/,\s?(England|Scotland|Wales|Cymru)$/, GB/;
	$is_in =~ s/^(England|Scotland|Wales|Cymru),\s?/GB, /;
	$is_in =~ s/Yorkshire, UK/Yorkshire, GB/;
	$is_in =~ s/\.UK$/, GB/;
	$is_in =~ s/, Europe$//;
	$is_in =~ s/United States of America.*|United States$|USA$/US/;
	$is_in =~ s/(\w)? USA$/$1, US/;
	$is_in =~ s/(.+),\sOntario Canada$/$1, Ontario, Canada/;	# name/place/is_in = Brookville/undef/Halton, Ontario Canada

	undef $place if(defined($name) && defined($place) && ($name eq $place));
	if(defined($place)) {
		$place =~ s/\x{2013}/-/g;
	}

	my $state;

	if(defined($name) && ($name !~ /,/) && (!defined($place)) && ($state = us_state2code(uc($is_in)))) {
		if(country($file, $is_in) eq 'US') {
			# name/place/is_in = Danville/undef/Pennsylvania
			return {
				CITY => $name,
				STATE => $state,
				COUNTRY => 'US'
			}
		}
		return
	}

	my $row;
	my @is_in_fields = split(/[,;]\s?/, $is_in);
	my @place_fields = split(/[,;]\s?/, $place) if(defined($place));
	if((scalar(@place_fields) == 3) && ($place_fields[1] !~ /\s/) && ($place_fields[2] =~ /^and\s/)) {
		# A list, such as
		# name/place/is_in = Cedar Avenue/Crown Family School of Social Work, Policy, and Practice/Québec, Canada
		@place_fields = ($place);
	}

	if(DEBUG&DEBUG_OSM) {
		if($name) {
			print $name;
		}
		if($place) {
			print "/$place/$is_in";
		} else {
			print "/undef/$is_in";
		}
		print "\n";
	}

	if((scalar(@is_in_fields) > 1) && ($is_in_fields[1] eq 'US') && ($state = $us->{'state2code'}{uc($is_in_fields[0])})) {
		if($place_fields[1] eq $is_in_fields[0]) {
			# name/place/is_in = Bemidji/Bemidji, Minnesota/Minnesota, USA
			return {
				CITY => $name,
				STATE => $state,
				COUNTRY => 'US',
			}
		}
		die;
	} elsif((scalar(@is_in_fields) > 1) && ($is_in_fields[1] eq 'US') && ($state = $us->{'state2code'}{uc($is_in_fields[0])})) {
		die;
	} elsif(defined($name) && defined($place) && ($place eq "$name, $is_in") && ($state = us_state2code($is_in))) {
		# name/place/is_in = Marysville/Marysville, Pennsylvania/Pennsylvania
		my $country = 'US' if($file =~ /north-america/);	# WA can be in US or Australia
		die if(!defined($country));
		return {
			CITY => $name,
			STATE => $state,
			COUNTRY => $country
		}
	}
	my @name_fields = split(/[,;]\s?/, $name) if(defined($name));
	if(scalar(@is_in_fields) == 5) {
		if($is_in_fields[4] eq 'US') {
			if($state = us_state2code($is_in_fields[1])) {
				$row = {
					STATE => $state,
					COUNTRY => 'US'
				};
				if(scalar(@name_fields) == 1) {
					# name/place/is_in = Normal/Normal, Illinois/Mc Lean County, Illinois, Ill., IL, USA
					$row->{'CITY'} = $name
				} elsif($name) {
					# name/place/is_in = St Marys Cement, McInnis Plant/Sonoma State Observatory/Brazoria,Texas,Tex.,TX,USA
					$row->{'CITY'} = $name_fields[1]
				} else {
					$row->{'CITY'} = $place_fields[0]
				}
				if($is_in_fields[0] =~ /(.+) County$/) {
					$row->{'COUNTY'} = $1
				}
				return $row
			}
			if($state = us_state2code($is_in_fields[3])) {
				# name/place/is_in = Forest Park/Forest Park (Columbus, Ohio)/Nortland, Columbus, Franklin, Ohio, USA
				$row = {
					CITY => $is_in_fields[1],
					STATE => $state,
					COUNTRY => 'US'
				};
				$row->{'NAME'} = $name if(defined($name));
				return $row
			}
		} elsif($is_in_fields[0] eq 'Australia') {
			# name/place/is_in = Nelson Hotel/Bondi Junction railway station/Australia, NSW, New South Wales, Sydney, Bondi Junction
			$row = {
				CITY => $is_in_fields[3],
				STATE => au_state2code($is_in_fields[1]),
				COUNTRY => 'Australia'
			};
			$row->{'NAME'} = $name if(defined($name));
			return $row
		}
	}

	if((scalar(@is_in_fields) == 2) && (scalar(@place_fields) == 2) && ($state = us_state2code($is_in_fields[0])) && ($state eq $is_in_fields[1]) && ($place_fields[1] eq $is_in_fields[0])) {
		# name/place/is_in = Mifflinville/Mifflinville, Pennsylvania/Pennsylvania,PA
		my $country = 'US' if($file =~ /north-america/);	# WA can be in US or Australia
		die if(!defined($country));
		return {
			CITY => $name,
			STATE => $state,
			COUNTRY => $country
		}
	}
	if((scalar(@is_in_fields) == 2) && defined($name) && (!defined($place)) && us_state2code($is_in_fields[0]) && (us_state2code($is_in_fields[0]) eq $is_in_fields[1])) {
		# name/place/is_in = Catawissa/undef/Pennsylvania,PA
		my $country = 'US' if($file =~ /north-america/);	# WA can be in US or Australia
		die if(!defined($country));
		return {
			CITY => $name,
			STATE => $is_in_fields[1],
			COUNTRY => $country
		}
	}
	if((scalar(@is_in_fields) == 2) && defined($name) && (scalar(@place_fields) == 3) && ($state = us_state2code($is_in_fields[1]))) {
		# name/place/is_in = Enterprise/Enterprise, Lake County, California/Lake, California
		my $country = 'US' if($file =~ /north-america/);	# WA can be in US or Australia
		die if(!defined($country));
		$row = {
			CITY => $name,
			STATE => $state,
			COUNTRY => $country,
		};
		if($place_fields[1] =~ /(.+) County$/) {
			$row->{'COUNTY'} = $1;
		}
		return $row;
	}
	if((scalar(@place_fields) == 2) && defined($name) && ($name eq $place_fields[0]) && ($us->{'code2state'}{$is_in}) && (country($file, $is_in) eq 'US')) {
		# name/place/is_in = Epping/Epping, New Hampshire/NH
		return {
			CITY => $name,
			STATE => $is_in,
			COUNTRY => 'US'
		}
	}
	if(defined($name) && (scalar(@is_in_fields) == 2) && (!defined($place)) && ($state = us_state2code($is_in_fields[1])) && (country($file, $is_in_fields[1]) eq 'US')) {
		$row = {
			STATE => $state,
			COUNTRY => 'US'
		};
		if($is_in_fields[0] =~ /(.+)\sCounty$/) {
			$row->{'COUNTY'} = $1;
		}
		if(scalar(@name_fields) == 1) {
			# name/place/is_in = Perryville/undef/Maricopa County; Arizona
			$row->{'CITY'} = $name
		} else {
			# name/place/is_in = Palisades del Rey, California/Palisades del Rey, California/Maricopa, AZ
			$row->{'NAME'} = $name_fields[0];
			$row->{'CITY'} = $name_fields[1]
		}
		return $row
	}
	if((scalar(@place_fields) == 3) && defined($name) && ($state = us_state2code($is_in)) && (country($file, $is_in) eq 'US')) {
		# name/place/is_in = Waterville/Cummings Township, Lycoming County, Pennsylvania#Waterville/Pennsylvania
		$row = {
			CITY => $name,
			STATE => $state,
			COUNTRY => 'US'
		};
		if($place_fields[1] =~ /(.+) County$/) {
			$row->{'COUNTY'} = $1
		}
		return $row
	}
	if((scalar(@place_fields) == 2) && (scalar(@is_in_fields) == 2) && ($state = us_state2code($is_in_fields[1])) && (country($file, $is_in_fields[1]) eq 'US')) {
		# name/place/is_in = West Athens/West Athens, California/Los Angeles, California
		$row = {
			CITY => $is_in_fields[0] || $name,
			STATE => $state,
			COUNTRY => 'US'
		};
		if(defined($name)) {
			if(($name =~ /\sRoad$/) || ($name =~ /\sLn$/) || ($name =~ /\sAvenue/) || ($name =~/\sStreet$/) || ($name =~ /\sRd$/) || ($name =~ /\sCt$/) || ($name =~ /\sRoad\s/ || ($name =~ /\sWay$/))) {
				$row->{'ROAD'} = $name
			} else {
				$row->{'NAME'} = $name
			}
		}
		return $row
	}
	if((scalar(@is_in_fields) == 4) && (scalar(@place_fields) == 2) && ($is_in_fields[3] eq 'US') && $us->{'code2state'}{$is_in_fields[2]}) {
		# name/place/is_in = Archbold/Archbold, Ohio/Fulton County, Ohio, OH, USA
		$row = {
			CITY => $place_fields[0],
			STATE => $is_in_fields[2],
			COUNTRY => 'US'
		};
		if($is_in_fields[0] =~ /(.+)\sCounty$/) {
			$row->{'COUNTY'} = $1;
		}
		return $row
	}
	if(defined($name) && ($name !~ /,/) && (!defined($place)) && ($is_in eq 'Washington DC')) {
		# name/place/is_in = Bellevue/undef/Washington DC
		# is_in will have been split into 2 by the space
		my $country = 'US' if($file =~ /north-america/);	# WA can be in US or Australia
		die if(!defined($country));
		return {
			CITY => $name,
			STATE => 'DC',
			COUNTRY => $country
		}
	}
	if(defined($name) && ($name !~ /,/) && defined($place) && ($is_in eq 'Washington DC')) {
		# name/place/is_in = Congress Heights/Congress Heights/Washington DC
		# is_in will have been split into 2 by the space
		my $country = 'US' if($file =~ /north-america/);	# WA can be in US or Australia
		die if(!defined($country));
		return {
			CITY => $name,
			STATE => 'DC',
			COUNTRY => $country
		}
	}
	if(defined($name) && ($name !~ /,/) && defined($place) && ($place =~ /^\Q$name\E\s.+Washington.*/) && ($is_in eq 'Washington DC')) {
		# name/place/is_in = Petworth/Petworth (Washington, D.C.)/Washington DC
		# is_in will have been split into 2 by the space
		my $country = 'US' if($file =~ /north-america/);	# WA can be in US or Australia
		die if(!defined($country));
		return {
			CITY => $name,
			STATE => 'DC',
			COUNTRY => $country
		}
	}
	if(defined($name) && defined($place) && ($place eq 'county') && (scalar(@is_in_fields) == 4) && ($is_in_fields[3] eq 'US') && (us_state2code($is_in_fields[0]) eq $is_in_fields[2])) {
		# name/place/is_in = Bartholomew/county/Indiana,Ind.,IN,USA
		return {
			COUNTY => $name,
			STATE => $is_in_fields[2],
			COUNTRY => 'US'
		}
	}
	if(defined($name) && (scalar(@place_fields) == 2) && (scalar(@is_in_fields) == 1) && ($state = us_state2code($place_fields[1])) && ($is_in =~ /(.+)\sCounty$/)) {
		# name/place/is_in = Hard Rock/Hardrock, Arizona/Navajo County
		$row = {
			CITY => $name,
			COUNTY => $1,
			STATE => $state,
			COUNTRY => 'US'
		};
		my $country = 'US' if($file =~ /north-america/);	# WA can be in US or Australia
		die if(!defined($country));
		$row->{'COUNTRY'} = $country;
		return $row
	}
	if(defined($name) && defined($place) && ($is_in eq 'US') && ($state = us_state2code($name))) {
		# name/place/is_in = Massachusetts/Massachusetts/USA
		return {
			STATE => $state,
			COUNTRY => 'US'
		}
	}
	if(defined($name) && defined($place) && (scalar(@is_in_fields) == 2) && ($state = us_state2code($is_in_fields[1])) && (country($file, $state) eq 'US')) {
		$row = {
			CITY => $is_in_fields[0],
			STATE => $state,
			COUNTRY => 'US'
		};
		if(($name =~ /\sRoad$/) || ($name =~ /\sLn$/) || ($name =~ /\sAvenue/) || ($name =~/\sStreet$/) || ($name =~ /\sRd$/) || ($name =~ /\sCt$/) || ($name =~ /\sRoad\s/) || ($name =~ /\sWay$/)) {
			# name/place/is_in = Ten Bear Road/Wheatland Ferry/Champaign, IL
			$row->{'ROAD'} = $name;
			$row->{'NAME'} = $place if($place ne $is_in_fields[0])
		} else {
			# name/place/is_in = Monroe County Airport/Monroe County Airport (Indiana)/Bloomington, Indiana
			$row->{'NAME'} = $name
		}
		return $row
	}
	if(defined($name) && (scalar(@is_in_fields) == 3) && ($is_in_fields[2] eq 'US') && ($state = us_state2code($is_in_fields[1]))) {
		if(scalar(@place_fields) == 1) {
			# name/place/is_in = Bird Springs Overlook/Monument Valley/Navajo County; Arizona; United States of America
			$row = {
				NAME => $name,
				CITY => $place,
				STATE => $state,
				COUNTRY => 'US'
			};
			if($is_in_fields[0] =~ /(.+)\sCounty$/) {
				$row->{'COUNTY'} = $1;
			}
			return $row
		}
		# name/place/is_in = El Presidio/undef/Tucson, Arizona, USA
		return {
			NAME => $name,
			CITY => $is_in_fields[0],
			STATE => $state,
			COUNTRY => 'US'
		}
	}
	if(defined($name) && (scalar(@is_in_fields) == 4)) {
		if($file =~ /north-america/) {
			# WA can be in US or Australia
			if(($name ne $is_in_fields[0]) && ($state = us_state2code($is_in_fields[1]))) {
				# name/place/is_in = Greenbrae Marina/undef/Marin,California,Calif.,CA
				return {
					NAME => $name,
					CITY => $is_in_fields[0],
					STATE => $state,
					COUNTRY => 'US'
				}
			}
			if(($state = us_state2code($is_in_fields[2])) && ($is_in_fields[3] eq 'US')) {
				# name/place/is_in = Burke Village/undef/Burke, Fairfax County, Virginia, United States of America
				$row = {
					NAME => $name,
					CITY => $is_in_fields[0],
					STATE => $state,
					COUNTRY => 'US'
				};
				if($is_in_fields[1] =~ /(.+)\sCounty$/) {
					$row->{'COUNTY'} = $1;
				}
				return $row
			}
		} elsif($is_in_fields[3] eq 'GB') {
			return {
				NAME => $name,
				CITY => $is_in_fields[1],
				STATE => $is_in_fields[2],
				COUNTRY => 'GB'
			}
		} elsif(($file =~ /australia/) && ($is_in_fields[0] eq 'Australia')) {
			if(($state = au_state2code($is_in_fields[2])) && ($is_in_fields[1] eq $state)) {
				# name/place/is_in = Hotel Avonleigh/New South Wales/Australia, NSW, New South Wales, Katoomba
				return {
					NAME => $name,
					CITY => $is_in_fields[3],
					STATE => $state,
					COUNTRY => 'Australia'
				}
			}
			if(($state = au_state2code($is_in_fields[1])) && ($is_in_fields[2] eq $state)) {
				# name/place/is_in = Harristown/undef/Australia, Queensland, QLD, Toowoomba
				return {
					NAME => $name,
					CITY => $is_in_fields[3],
					STATE => $state,
					COUNTRY => 'Australia'
				}
			}
		}
	}
	if(defined($name) && (scalar(@is_in_fields) == 6) && ($state = us_state2code($is_in_fields[2])) && ($is_in_fields[5] eq 'US')) {
		# name/place/is_in = Paloma del Sol/undef/Temecula;Riverside;California;Calif;CA;USA
		return {
			NAME => $name,
			CITY => $is_in_fields[0],
			STATE => $state,
			COUNTRY => 'US'
		}
	}
	if(defined($name) && ($name !~ /,/) && ($is_in =~ /[,;]\sCanada/) && (scalar(@is_in_fields) > 1)) {
		if(scalar(@is_in_fields) == 3) {
			if($is_in_fields[1] =~ /Qu.bec/i) {
				$is_in_fields[1] = 'Quebec';
				$state = 'QC';
			} elsif($is_in_fields[0] =~ /Qu.bec/i) {
				$is_in_fields[0] = 'Quebec';
				$state = 'QC';
			} else {
				$state = ca_province2code($is_in_fields[0]) || ca_province2code($is_in_fields[1]);
			}
			if(defined($place) && ($place =~ /, \Q$is_in_fields[0]\E$/)) {
				# name/place/is_in = The Bridle Path/Bridle Path, Toronto/Toronto, Ontario, Canada
				return {
					NAME => $name,
					CITY => $is_in_fields[0],
					STATE => $state,
					COUNTRY => 'Canada'
				}
			}
			if(defined($state) && ($is_in_fields[0] =~ /(.+) County$/)) {
				# name/place/is_in = name = 76, place = Trinity-St. Paul's United Church, is_in = Northern Sunrise County,Alberta,Canada
				return {
					COUNTY => $1,
					STATE => $state,
					COUNTRY => 'Canada'
				}
			}
			if(defined($state)) {
				# name/place/is_in = Redwood Meadows/undef/AB; Alberta; Canada
				# name/place/is_in = Tofino/undef/British Columbia, BC, Canada
				return {
					CITY => $name,
					STATE => $state,
					COUNTRY => 'Canada'
				}
			}
			# name/place/is_in = Saint-Étienne-de-Lauzon/undef/Lévis, Québec, Canada
			$row = {
				CITY => $is_in_fields[0],
				STATE => $state,
				COUNTRY => 'Canada'
			};
			die __LINE__, ': ', Data::Dumper->new([$row])->Dump() if(DEBUG&DEBUG_OSM);
		} elsif(scalar(@is_in_fields) == 4) {
			my $code;
			my %provinces = (
				'ALTA.' => 'ALBERTA'
			);
			if(my $p = $provinces{uc($is_in_fields[1])}) {
				$is_in_fields[1] = $p;
			}
			if($is_in_fields[2] =~ /Qu.bec/i) {
				$is_in_fields[2] = 'Quebec';
			}
			if(($state = ca_province2code($is_in_fields[0])) &&
			   ($code = ca_province2code($is_in_fields[1]))) {
				if(($state eq $is_in_fields[2]) && ($code eq $state)) {
					if(defined($place) && ($place eq 'county')) {
						# name/place/is_in = Youngstown/county/Alberta,Alta.,AB,Canada
						return {
							'COUNTY' => $name,
							'STATE' => $state,
							'COUNTRY' => 'Canada'
						}
					}
					# name/place/is_in = Boyle/undef/Alberta,Alta.,AB,Canada
					return {
						'CITY' => $name,
						'STATE' => $state,
						'COUNTRY' => 'Canada'
					}
				}
			} elsif($state = ca_province2code($is_in_fields[2])) {
				# name/place/is_in = Tyndall Park/undef/Point Douglas; Winnipeg;Manitoba;Canada
				$row = {
					'CITY' => $is_in_fields[1],
					'STATE' => $state,
					'COUNTRY' => 'Canada',
				};
				$row->{'NAME'} = $name if(defined($name));
			} elsif(($state = ca_province2code($is_in_fields[1])) && ($state eq $is_in_fields[2])) {
				# name/place/is_in = Thickwood/undef/Fort McMurray, Alberta, AB, Canada
				$row = {
					'CITY' => $is_in_fields[0],
					'STATE' => $state,
					'COUNTRY' => 'Canada',
				};
				$row->{'NAME'} = $name if(defined($name));
			} elsif(ca_province2code($is_in_fields[0]) && (ca_province2code($is_in_fields[0]) eq $is_in_fields[2])) {
				$state = $is_in_fields[2];
				die if(!$ca->{'code2province'}{$state});
				# name/place/is_in = Queens/undef/New Brunswick,N.B.,NB,Canada
				$row = {
					STATE => $state,
					COUNTRY => 'Canada',
				};
				if($place eq 'county') {
					$row->{'COUNTY'} = $name;
				} else {
					$row->{'CITY'} = $name;
				}
			} elsif(ca_province2code($is_in_fields[1]) eq $is_in_fields[2]) {
				$state = $is_in_fields[2];
				# name/place/is_in = Thickwood/undef/Fort McMurray, Alberta, AB, Canada
				$row = {
					'CITY' => $is_in_fields[0],
					'STATE' => $state,
					'COUNTRY' => 'Canada',
				};
				$row->{'NAME'} = $name if(defined($name));
			} elsif(($state = ca_province2code($is_in_fields[1])) && ($is_in_fields[2] eq 'Canada')) {
				# name/place/is_in = Elmwood/undef/Winnipeg; Manitoba; Canada; CA,
				$row = {
					'CITY' => $is_in_fields[0],
					'STATE' => $state,
					'COUNTRY' => 'Canada',
				};
				$row->{'NAME'} = $name if(defined($name));
			}
			return $row;
		} elsif(scalar(@is_in_fields) == 2) {
			if($is_in_fields[0] =~ /Qu.bec/i) {
				$is_in_fields[0] = 'Quebec';
			}
			if($state = ca_province2code($is_in_fields[0])) {
				if((scalar(@place_fields) == 2) && ($place_fields[1] eq 'D.C.')) {
					# name/place/is_in = Embassy of China/Embassy of China in Washington, D.C./Manitoba, Canada
					print __LINE__, ": $name is in both D.C. and Canada\n" if(DEBUG&DEBUG_OSM);
					return;
				}
				if((scalar(@place_fields) == 3) && ($place_fields[2] eq 'D.C.')) {
					# name/place/is_in = Embassy of Jordan/Embassy of Jordan, Washington, D.C./Manitoba, Canada
					print __LINE__, ": $name is in both D.C. and Canada\n" if(DEBUG&DEBUG_OSM);
					return;
				}
				print __LINE__, ": $is_in ($state)\n" if(DEBUG&DEBUG_OSM);
				if(!defined($place)) {
					# name/place/is_in = Whitecap/undef/Saskatchewan, Canada
					return {
						CITY => $name,
						STATE => $state,
						COUNTRY => 'Canada'
					}
				}
				if((scalar(@place_fields) == 1) && defined($name) && ($place !~ /,/)) {
					$row = {
						CITY => $place,
						STATE => $state,
						COUNTRY => 'Canada'
					};
					if(($name =~ /\sRoad$/) || ($name =~ /\sLn$/) || ($name =~ /\sAvenue/) || ($name =~/\sStreet$/) || ($name =~ /\sRd$/) || ($name =~ /\sCt$/)) {
						# name/place/is_in = Carpenter Rd/U.S. Route 82 in Texas/Québec,Canada
						$row->{'ROAD'} = $name
					} else {
						$row->{'NAME'} = $name
					}
				}
				if($place =~ /\Q$name\E/) {
					# name/place/is_in = East St. Paul/Rural Municipality of East St. Paul/Manitoba, Canada
					return {
						CITY => $name,
						STATE => $state,
						COUNTRY => 'Canada'
					}
				}
				if(scalar(@place_fields) == 2) {
					# name/place/is_in = Dundurn Millitary Base/Chatham, Ontario/Saskatchewan, Canada
					$row = {
						CITY => $place_fields[1],
						STATE => $state,
						COUNTRY => 'Canada'
					};
					$row->{'NAME'} = $name if(defined($name));
					return $row
				}
			}
		}
		if((scalar(@is_in_fields) == 7) && ($state = ca_province2code($is_in_fields[5]))) {
			# name/place/is_in = Gilwood Road/400 Lake Shore Drive/High Prairie,Alberta,Canada;Big Lakes, M.D. of,Alberta,Canada
			$row = {
				CITY => $is_in_fields[0],
				STATE => $state,
				COUNTRY => 'Canada',
			};
			if(defined($place) && ($place =~ /^(\d+?)\s(.+)/)) {
				$row->{'NUMBER'} = $1;
				$row->{'ROAD'} = $2;
			}
			$row->{'NAME'} = $name if(defined($name));
			return $row;
		}
		if((scalar(@is_in_fields) == 8) && ($is_in_fields[6] eq 'Canada')) {
			# name/place/in_in = Pembina Strip/undef/Fort Garry South; Winnipeg; River Heights—Fort Garry; Fort Garry; Winnipeg; Manitoba; Canada; CA
			return {
				CITY => $name,
				STATE => ca_province2code($is_in_fields[5]),
				COUNTRY => 'Canada'
			}
		}
		if(scalar(@is_in_fields) >= 5) {
			if(($is_in_fields[0] eq $is_in_fields[4]) && ca_province2code($is_in_fields[4])) {
				# name/place/is_in = Weston/undef/Manitoba, St. James–Brooklands; Assiniboia; Winnipeg; Manitoba; Canada
				shift @is_in_fields;
			} elsif(($is_in_fields[0] eq $is_in_fields[3]) && ca_province2code($is_in_fields[4])) {
				# name/place/is_in = Roblin Park/undef/Winnipeg;Charleswood–Tuxedo;Assiniboia;Winnipeg;Manitoba;Canada,
				shift @is_in_fields;
			}
			foreach my $i (3..4) {
				if(defined($is_in_fields[$i]) && ($state = ca_province2code($is_in_fields[$i]))) {
					# name/place/is_in = Garden City/undef/Old Kildonan; Lord Selkirk–West Kildonan; Winnipeg;Manitoba;Canada
					return {
						NAME => $name || $is_in_fields[1],
						CITY => $is_in_fields[2],
						STATE => $state,
						COUNTRY => 'Canada',
					}
				}
			}
			if(($state = ca_province2code($is_in_fields[2])) && ($is_in_fields[3] eq 'Canada')) {
				# name/place/is_in = East Kildonan/undef/East Kildonan–Transcona; Winnipeg; Manitoba; Canada; CA
				return {
					NAME => $name || $is_in_fields[0],
					CITY => $is_in_fields[1],
					STATE => $state,
					COUNTRY => 'Canada',
				}
			}
			if((scalar(@is_in_fields) == 10) && (scalar(@place_fields) == 1) && defined($name) && ($name !~ /,/) && ($state = ca_province2code($is_in_fields[8]))) {
				# name/place/is_in = Transpeninsular Highway, place = Blake Island, is_in = Leduc County,Alberta,Canada; Wetaskiwin No. 10, County of,Alberta,Canada; Leduc County,Alberta,Canada
				$row = {
					NAME => $place,
					STATE => $state,
					COUNTRY => 'Canada'
				};
				if($is_in_fields[0] =~ /(.+)\sCounty$/) {
					$row->{'COUNTY'} = $1;
				}
				return $row
			}
		}
		if(defined($row)) {
			return $row
		}
		# name/place/is_in = Carpenter Rd/U.S. Route 82 in Texas/Québec, Canada
		# name/place/is_in = Chaudière Bridge/Tenth Avenue (Manhattan)/Québec, Canada
		if(DEBUG&DEBUG_OSM) {
			if(defined($place)) {
				print "$file: Can't parse name = $name, place = $place, is_in = $is_in\n";
			} else {
				print "$file: Can't parse name = $name, place = undef, is_in = $is_in\n";
			}
		}
	} elsif((scalar(@is_in_fields) == 3) && ($is_in_fields[0] eq 'Canada')) {
		# name/place/is_in = Hébertville/undef/Canada,Québec,Saguenay Lac-St-Jean
		if($is_in_fields[1] =~ /Qu.bec/i) {
			$is_in_fields[1] = 'Quebec'
		}
		if($state = ca_province2code($is_in_fields[1])) {
			return {
				CITY => $name || $is_in_fields[2],
				STATE => $state,
				COUNTRY => 'Canada'
			}
		}
		die __LINE__, ': ', Data::Dumper->new([$row])->Dump();
	} elsif(defined($name) && ($name !~ /,/) && defined($place) && ($place =~ /,/) && $ca->{'code2province'}{$is_in}) {
		my @place_fields = split(/[,;]\s/, $place);
		if(scalar(@place_fields) == 2) {
			my @is_in_fields = split(/[,;]\s/, $is_in);
			if(ca_province2code($place_fields[1]) eq $is_in) {
				# name/place/is_in = Hague/Hague, Saskatchewan/SK
				die "$name, $place_fields[1]" if ($name ne $place_fields[0]);
				return {
					CITY => $name,
					STATE => $is_in,
					COUNTRY => 'Canada'
				};
			}
		}
	}
	if(defined($place) && $ca->{'code2province'}{$is_in}) {
		# name/place/is_in = Rosthern/Rosthern/SK
		return {
			CITY => $place,
			STATE => $is_in,
			COUNTRY => 'Canada'
		}
	}
	if(defined($name) && ($state = ca_province2code($is_in))) {
		# name/place/is_in = Kimberley/undef/British Columbia
		return {
			CITY => $name,
			STATE => $state,
			COUNTRY => 'Canada'
		}
	}
	if(defined($name) && (scalar(@is_in_fields) == 2) && ($state = ca_province2code($is_in_fields[1]))) {
		if(($name =~ /\sStreet/) || ($name =~ /\sRoad$/)) {
			# name/place/is_in = 212th Street W/Hastings Rail Bridge/Nobleford,Alberta
			return {
				ROAD => $name,
				CITY => $is_in_fields[0],
				STATE => $state,
				COUNTRY => 'Canada'
			}
		}
		if(scalar(@name_fields) == 2) {
			$row = {
				NAME => $name_fields[0],
				STATE => $state,
				COUNTRY => 'Canada'
			};
			if($is_in_fields[0] =~ /(.+)\sCounty$/) {
				$row->{'COUNTY'} = $1;
				if(defined($place)) {
					# name/place/is_in = Community College of Denver, Clear Creek/Douglass Park/Strathcona County,Alberta
					$row->{'CITY'} = $place if(scalar(@place_fields) == 1)
				} else {
					$row->{'CITY'} = $name_fields[1];
				}
			} elsif($is_in_fields[0] =~ /\sRoad$/) {
				# name/place/is_in = North Fork East Road;North Fork Klondike River Bridge/Big River (Saskatchewan)/Red Deer County,Alberta
				$row->{'NAME'} = $place if(defined($place));
				$row->{'ROAD'} = $is_in_fields[0];
				$row->{'CITY'} = $is_in_fields[1];
			} else {
				$row->{'CITY'} = $is_in_fields[0]
			}
			return $row
		}
		if(scalar(@name_fields) == 1) {
			$row = {
				CITY => $name,
				STATE => $state,
				COUNTRY => 'Canada'
			};
			if($is_in_fields[0] =~ /(.+)\sCounty$/) {
				$row->{'COUNTY'} = $1;
			}
			if(defined($place) && (($place =~ /\sHospital$/) || ($place =~ /sAirport$/))) {
				$row->{'NAME'} = $place;
				if($is_in_fields[0] !~ /(.+)\sCounty$/) {
					# name/place/is_in = Arborcrest Cemetery/New York Community Hospital/Castlegar,British Columbia
					$row->{'CITY'} = $is_in_fields[0];
					return
				}
			}
			# name/place/is_in = Inwood/undef/Armstrong, Manitoba
			$row->{'CITY'} = $name;
			return $row
		}
	}
	if((scalar(@is_in_fields) == 2) && ($is_in_fields[1] eq 'GB') && defined($name) && (scalar(@name_fields) == 1) && !defined($place)) {
		$row = {
			CITY => $name,
			STATE => $is_in_fields[0],
			COUNTRY => 'GB'
		};
	}
	if(defined($name) && (scalar(@is_in_fields) == 3) && ($name ne $is_in_fields[1]) && ($state = ca_province2code($is_in_fields[2]))) {
		# name/place/is_in = Cabbagetown/undef/Old Toronto, Toronto, Ontario
		return {
			NAME => $name,
			CITY => $is_in_fields[1],
			STATE => $state,
			COUNTRY => 'Canada'
		}
	}
	if(defined($name) && (scalar(@name_fields) == 1) && (scalar(@is_in_fields) == 3) && ($is_in_fields[0] eq 'Australia') && ($state = au_state2code($is_in_fields[2])) && ($state eq $is_in_fields[1])) {
		# name/place/is_in = Fingal/undef/Australia, NSW, New South Wales
		return {
			CITY => $name,
			STATE => $state,
			COUNTRY => 'Australia'
		}
	}
	if(defined($name) && (scalar(@is_in_fields) == 3) && ($is_in_fields[2] eq 'GB') && defined($place)) {
		# name/place/is_in = Whetstone/Whetstone, London/Barnet, London, GB
		return {
			CITY => $place_fields[0],
			STATE => $is_in_fields[1],
			COUNTRY => 'GB'
		}
	}
	if(defined($name) && (scalar(@name_fields) == 1) && (scalar(@is_in_fields) == 3) && ($is_in_fields[2] eq 'GB') && !defined($place)) {
		return {
			CITY => $name,
			STATE => $is_in_fields[1],
			COUNTRY => 'GB'
		}
	}
	if((scalar(@name_fields) == 1) && (scalar(@is_in_fields) == 2) && ($is_in_fields[1] eq 'GB') && ($name !~ /\sStreet$/)) {
		# name/place/is_in = Mere/Mere, Wiltshire/Wiltshire, GB
		# name/place/is_in = Shedfield/undef/Hampshire, GB
		return {
			CITY => $name,
			STATE => $is_in_fields[0],
			COUNTRY => 'GB'
		}
	}
	if(defined($name) && (scalar(@name_fields) == 1) && (scalar(@is_in_fields) == 4) && ($is_in_fields[0] eq 'GB')) {
		$row = {
			CITY => $name,
			COUNTRY => 'GB'
		};
		if($is_in_fields[1] eq 'Yorkshire') {
			# name/place/is_in = Leeds/Leeds/GB, Yorkshire,West Yorkshire, Airedale
			$row->{'STATE'} = $is_in_fields[2];
		} else {
			$row->{'STATE'} = $is_in_fields[1];
		}
		return $row
	}

	if(defined($name) && (scalar(@name_fields) == 1) && defined($place) && (scalar(@place_fields) == 2) && (scalar(@is_in_fields) == 1)) {
		if($is_in eq 'GB') {
			# name/place/is_in = Biggar/Biggar, South Lanarkshire/Scotland, UK
			return {
				CITY => $name,
				STATE => $place_fields[1],
				COUNTRY => 'GB'
			}
		}
		if(($state = au_state2code($is_in)) && (country($file, $state) eq 'Australia')) {
			if($is_in eq $place_fields[1]) {
				# name/place/is_in = Kalamunda/Kalamunda, Western Australia/Western Australia
				return {
					CITY => $name,
					STATE => $state,
					COUNTRY => 'Australia'
				}
			}
		}
	}
	if(defined($name) && (scalar(@name_fields) == 1) && (!defined($place)) && (scalar(@is_in_fields) == 1) && ($state = au_state2code($is_in)) && (country($file, $state) eq 'Australia')) {
		# name/place/is_in = Stratham/undef/Western Australia
		return {
			CITY => $name,
			STATE => $state,
			COUNTRY => 'Australia'
		}
	}
	if(defined($name) && (scalar(@name_fields) == 1) && defined($place) && (scalar(@place_fields) == 2) && (scalar(@is_in_fields) == 2) && ($is_in_fields[0] eq 'GB')) {
		# name/place/is_in = Whitwell/Whitwell, Isle of Wight/England, Isle of Wight
		return {
			CITY => $name,
			STATE => $place_fields[1],
			COUNTRY => 'GB'
		}
	}
	if(defined($name) && (scalar(@name_fields) == 1) && defined($place) && (scalar(@place_fields) == 1) && (scalar(@is_in_fields) == 2) && ($is_in_fields[0] eq 'GB')) {
		# name/place/is_in = Waldringfield/Newbourne/England, Suffolk
		return {
			CITY => $name,
			STATE => $is_in_fields[1],
			COUNTRY => 'GB'
		}
	}
	if(defined($name) && (scalar(@name_fields) == 1) && (!defined($place))) {
		if($is_in_fields[0] eq 'GB') {
			if(scalar(@is_in_fields) == 2) {
				# name/place/is_in = Niton/Niton/England, Isle of Wight
				return {
					CITY => $name,
					STATE => $is_in_fields[1],
					COUNTRY => 'GB'
				}
			}
			if(scalar(@is_in_fields) == 3) {
				# name/place/is_in = Newcastle upon Tyne/Newcastle upon Tyne/UK, England, Northumberland, Tyne & Wear
				return {
					CITY => $name,
					STATE => $is_in_fields[2],
					COUNTRY => 'GB'
				}
			}
		} elsif((scalar(@is_in_fields) == 3) && ($state = au_state2code($is_in_fields[1]))) {
			if($is_in_fields[2] eq 'Australia') {
				# name/place/is_in = Doncaster Hotel/undef/Doncaster,Victoria,Australia
				return {
					NAME => $name,
					CITY => $is_in_fields[0],
					STATE => $state,
					COUNTRY => 'Australia'
				}
			}
			if(($is_in_fields[0] eq 'Australia') && defined(au_state2code($is_in_fields[2])) && (au_state2code($is_in_fields[2]) eq $state)) {
				# name/place/is_in = Glen Aplin/undef/Australia, Qld, Queensland
				return {
					CITY => $name,
					STATE => $state,
					COUNTRY => 'Australia'
				}
			}
		} elsif((scalar(@is_in_fields) == 2) && ($is_in_fields[1] eq 'Australia') && ($state = au_state2code($is_in_fields[0]))) {
			# name/place/is_in: Dudauman/undef/New South Wales, Australia
			return {
				CITY => $name,
				STATE => $state,
				COUNTRY => 'Australia'
			}
		}
	}
	if((scalar(@place_fields) == 2) && ($state = ca_province2code($place_fields[1]))) {
		# name/place/is_in = Aldergrove/Aldergrove, British Columbia/Township of Langley
		return {
			CITY => $place_fields[0],
			STATE => $state,
			COUNTRY => 'Canada'
		}
	}
	if((DEBUG&DEBUG_OSM) && !defined($row)) {
		if(defined($place)) {
			print "$file: Can't parse name = $name, place = $place, is_in = $is_in\n";
		} else {
			print "$file: Can't parse name = $name, place = undef, is_in = $is_in\n";
		}
	}
	return $row;
}

# Procedural interface to Locale::US
sub us_state2code
{
	my $state = uc(shift);
	my $rc;

	if($rc = $us->{'state2code'}{$state}) {
		return $rc;
	}
	if($us->{'code2state'}{$state}) {
		return $state;
	}
	# my @call_details = caller(0);
	# print STDERR __LINE__, ": Unknown state '$state'\n",
		# "\tcalled from line ", $call_details[2], "\n";
	return;	# undef
}

# Procedural interface to Locale::CA
sub ca_province2code
{
	if(!defined($_[0])) {
		my @call_details = caller(0);
		die "ca_province2code, argument not given\n",
			"\tcalled from line ", $call_details[2];
	}
	my $province = uc(shift);
	my $rc;

	if($rc = $ca->{'province2code'}{$province}) {
		return $rc;
	}
	if($ca->{'code2province'}{$province}) {
		return $province;
	}
	# my @call_details = caller(0);
	# print STDERR __LINE__, ": Unknown province '$province'\n",
		# "\tcalled from line ", $call_details[2], "\n";
	return;	# undef
}

# Procedural interface to Locale::AU
sub au_state2code
{
	my $state = uc(shift);
	my $rc;

	if($rc = $au->{'state2code'}{$state}) {
		return $rc;
	}
	if($au->{'code2state'}{$state}) {
		return $state;
	}
	# my @call_details = caller(0);
	# print STDERR __LINE__, ": Unknown state '$state'\n",
		# "\tcalled from line ", $call_details[2], "\n";
	return;	# undef
}

# Given a state and Openstreetmap.org filename, determine the country
# WA can be in US or Australia
# Georgia can be a country or US state
# DE can be a US state or country
# VI is in Italy, I think
sub country
{
	my($file, $state) = @_;

	# Ensure the file argument is provided
	die if(!defined($file));

	# Check for file patterns and return corresponding country
	return 'US' if $file =~ /north-america/;
	return 'Australia' if $file =~ /australia/;

	# Ensure the state argument is provided if needed
	die 'State argument is missing' if(!defined($state));

	# Handle European cases with specific state codes
	if($file =~ /europe/) {
		my %valid_states = map { $_ => 1 } ('Georgia', 'GA', 'DE', 'VI');
		return $state if $valid_states{$state} || $valid_states{uc($state)};
	}

	# Default case: Raise error with both file and state information
	die "$file/$state";
}
