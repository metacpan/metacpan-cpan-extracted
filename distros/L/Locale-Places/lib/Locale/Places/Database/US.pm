package Locale::Places::Database::US;

use strict;
use warnings;

# From http://download.geonames.org/export/dump/readme.txt
#	alternateNameId   : the id of this alternate name, int
#	geonameid         : geonameId referring to id in table 'geoname', int
#	isolanguage       : iso 639 language code 2- or 3-characters; 4-characters 'post' for postal codes and 'iata','icao' and faac for airport codes, fr_1793 for French Revolution names,  abbr for abbreviation, link to a website (mostly to wikipedia), wkdt for the wikidataid, varchar(7)
#	alternate name    : alternate name or name variant, varchar(400)
#	isPreferredName   : '1', if this alternate name is an official/preferred name
#	isShortName       : '1', if this is a short name like 'California' for 'State of California'
#	isColloquial      : '1', if this alternate name is a colloquial or slang term. Example: 'Big Apple' for 'New York'.
#	isHistoric        : '1', if this alternate name is historic and was used in the past. Example 'Bombay' for 'Mumbai'.
#	from		  : from period when the name was used
#	to		  : to period when the name was used

# US.csv is from http://download.geonames.org/export/dump/alternatenames/US.zip

use Database::Abstraction;

our @ISA = ('Database::Abstraction');

# If there's no SQLite file, fall back to the original CSV file, that's when the arguments to _open will be used
sub _open {
	my $self = shift;

	return $self->SUPER::_open(sep_char => "\t", column_names => ['code1','code2','type','data','ispreferredname','isshortname']);
}

1;
