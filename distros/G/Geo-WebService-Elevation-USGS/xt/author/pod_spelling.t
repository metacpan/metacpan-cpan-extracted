package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	Test::Spelling->import();
    };
    $@ and do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
}

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
CONUS
CUBITS
Dataset
Dru
GEOID
Geoid
GIS
GPS
IDs
InvalidCastException
merchantability
Milbert
NAD
namespace
NAVD
NED
Ph
Survey's
USGS
WGS
WSDL
Wyant
geo
getAllElevations
getElevation
targetNamespace
conterminous
geoid
gory
url
wildcard
