#!/usr/bin/env perl

# Import data from openaddresses.io and whosonfirst.org into an SQLite database.
# Set OPENADDR_HOME and WHOSONFIRST_HOME to the directories where the data has been downloaded
# Download the OPENADDR_HOME data from http://results.openaddresses.io.
# Download the WHOSONFIRST_HOME data using https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-sqlite-download

# TODO: perhaps use a layered approach to the database schema

use 5.010;
use strict;
use warnings;
use autodie qw(:all);
use File::Copy;
use DBI;
use Data::Dumper;
use JSON;
use LWP::UserAgent::Throttled;
use Locale::US;
use Digest::MD5;
use Encode;
use Geo::StreetAddress::US;
use File::Basename;
use File::Spec;
use DBD::SQLite::Constants qw/:file_open/;	# For SQLITE_OPEN_READONLY
use Text::CSV;
use CHI;
use CHI::Driver::RawMemory;
use Try::Tiny;

use	constant	MAX_INSERT_COUNT => 250;	# Maximum number of CSV rows to insert in a single statement

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

my %known_places = (	# Places I've checked with my GPS
	'us/md/statewide.csv' => [
		{
			# NCBI
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
			# Bold bite
			'LAT' => 38.98939358,
			'LON' => -77.09819543,
			'STREET' => 'NORFOLK AVE',
			'CITY' => 'BETHESDA',
			'COUNTY' => 'MONTGOMERY',
			'STATE' => 'MD',
			'COUNTRY' => 'US',
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
		}
	],
	'us/dc/statewide.csv' => [
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

if(my $oa = $ENV{'OPENADDR_HOME'}) {
	# Import openaddresses.io data into an SQLite database
	# TODO: download and unzip the files from results.openaddresses.io
	# TODO: only Australian, US and Canadian data is supported at the moment

	my $sqlite_file = "$oa/openaddresses.sql";
	if(!-r $sqlite_file) {
		my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlite_file", undef, undef, { RaiseError => 1, AutoCommit => 0, synchronous => 0, locking_mode => 'EXCLUSIVE' });
		$dbh->do('PRAGMA cache_size = 65536');
		$dbh->do('PRAGMA journal_mode = OFF');
		if(!-d $oa) {
			mkdir $oa;
		}
		$dbh->do('CREATE TABLE cities(sequence INTEGER, city VARCHAR, county VARCHAR, state VARCHAR NOT NULL, country CHAR(2) NOT NULL)');
		$dbh->do('CREATE TABLE openaddresses(md5 CHAR(16), lat DECIMAL, lon DECIMAL, name VARCHAR, number VARCHAR, street VARCHAR, city INTEGER, FOREIGN KEY (city) REFERENCES cities(sequence))');
		# $dbh->do('CREATE TABLE openaddresses(md5 CHAR(16) PRIMARY KEY, lat DECIMAL, lon DECIMAL, name VARCHAR, number VARCHAR, street VARCHAR, city INTEGER, FOREIGN KEY (city) REFERENCES cities(sequence))');
		# $dbh->prepare('CREATE TABLE node(md5 CHAR(16), parent CHAR(16)')->execute();
		# $dbh->prepare('CREATE TABLE leaf(md5 CHAR(16), lat DECIMAL, lon DECIMAL')->execute();

		print "This will take some time.\nBest to do it last thing at night and go to sleep, it should be ready in the morning.\n";

		my $filename = 'lib/Geo/Coder/Free/OpenAddresses/databases/states.txt';
		if(-r $filename) {
			# Import US states and counties from https://github.com/openaddresses/openaddresses/tree/master/us-data
			$| = 1;
			printf "%-70s\r", $filename;
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

			open(my $fin, '<', $filename);
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
				$inserts += insert($dbh, 1, \%columns);
				if($inserts >= MAX_INSERT_COUNT) {
					flush_queue($dbh);
					$inserts = 0;
				}
			}

			close($fin);

			# Import the counties
			$filename = 'lib/Geo/Coder/Free/OpenAddresses/databases/counties.txt';
			$| = 1;
			printf "%-70s\r", $filename;
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

			open($fin, '<', $filename);
			$csv->column_names($csv->getline($fin));

			while(my $row = $csv->getline_hr($fin)) {
				# print Data::Dumper->new([\$row])->Dump();
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
				$inserts += insert($dbh, 1, \%columns);
				if($inserts >= MAX_INSERT_COUNT) {
					flush_queue($dbh);
					$inserts = 0;
				}
			}
			flush_queue($dbh);
		}

		my $current_state;
		my $current_country;
		my %whosonfirst;
		my $wof_global_dbh;
		my $wof_global_file;
		if(my $whosonfirst = $ENV{WHOSONFIRST_HOME}) {
			$| = 1;
			printf "%-70s\r", "Traversing $whosonfirst";
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

		if($wof_global_dbh) {
			$wof_global_dbh->do('PRAGMA cache_size = 65536');
			my $file = basename($wof_global_file);
			# Import from the global file
			$| = 1;
			printf "%-70s\r", $file;
			$| = 0;
			print "\n";

			my $inserts = 0;
			my $sth = $wof_global_dbh->prepare('SELECT body FROM geojson');
			$sth->execute() || die $wof_global_file;

			my $j = JSON->new()->utf8();
			# while(my $data = $sth->fetchrow_hashref()) {
				# if($data->{'body'}) {
					# $data = $data->{'body'};
				# }
			my $rowcache = $sth->fetchall_arrayref(undef, 10_000);
			while(my $aref = shift(@{$rowcache})) {
				if(scalar(@{$rowcache}) == 0) {
					$rowcache = $sth->fetchall_arrayref(undef, 10_000);
				}
				next if(!defined($aref));
				my $data = @{$aref}[0];
				next if(!defined($data));
				$data = $j->decode($data);
				my $properties = $data->{'properties'};
				next if(scalar(@{$properties->{'wof:superseded_by'}}));
				my $placetype = $properties->{'wof:placetype'};
				next if($placetype eq 'country');
				my $country = $properties->{'wof:country'};
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
				my $state;
				# print $placetype, "\n";
				if($placetype eq 'region') {
					if(($country eq 'US') || ($country eq 'CA') || ($country eq 'AU')) {
						$state = $properties->{'wof:abbreviation'} || $properties->{'wof:name'};
					} else {
						$state = $properties->{'wof:name'};
					}
				} else {
					$state = $properties->{'sg:province'};
				}
				if(!defined($state)) {
					my @hierarchy = @{$properties->{'wof:hierarchy'}};
					if(scalar(@hierarchy) && (my $region = $hierarchy[0]->{'region_id'})) {
						next if($region < 0);
						$state = get_wof($wof_global_dbh, $region);
					} else {
						next;
					}
					# FIXME: the information will be in there somewhere
					# if(!defined($state)) {
						# die Data::Dumper->new([$properties])->Dump();
					# }
					next unless($state);
				}
				my $city;
				if(($placetype eq 'locality') || ($placetype eq 'neighbourhood')) {
					$city = $properties->{'wof:name'};
					die if(!defined($city));
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
				# print Data::Dumper->new([$properties])->Dump();
				# if($city) {
					# print "$country, $state, $city\n";
				# } else {
					# print "$country, $state\n";
				# }
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
				my $number = $properties->{'addr:number'};
				if($number) {
					$number = uc($number);
				}
				my $row = {
					'LAT' => $properties->{'geom:latitude'},
					'LON' => $properties->{'geom:longitude'},
					# 'NAME' => uc($properties->{'wof:name'}),
					'NUMBER' => $number,
					'STREET' => $street,
					'CITY' => uc($city),
					'STATE' => uc($state),
					'COUNTRY' => uc($country),
					'POSTCODE' => $postcode,
				};
				$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh, global => 1);
				if($inserts >= MAX_INSERT_COUNT) {
					flush_queue($dbh);
					$inserts = 0;
				}
			}
		}

		# $dbh->commit();
		# $dbh->disconnect();
		# $wof_global_dbh->disconnect();
		# exit(0);

		# Find all of the .csv files in $OPENADDR_HOME
		foreach my $csv_file (uniq(create_tree($oa))) {
			# next unless($csv_file =~ /us\/md\/statewide/);
			# next unless($csv_file =~ /us\/ne\/dawes/);
			# next unless($csv_file =~ /us\/mo\//);

			# Handle https://github.com/openaddresses/openaddresses/issues/3928
			# TODO: It would be better to merge airdrie.csv and city_of_airdrie.csv
			next if($csv_file =~ /ca\/ab\/airdrie.csv/);

			my $f = $csv_file;
			$f =~ s/^$oa\///;
			my @components = split(/\//, $f);
			if(my $country = $components[0]) {
				next unless($openaddresses_supported_countries{lc($country)});

				my $query;
				my $state;
				my $file;
				if($components[1] =~ /\.csv$/) {
					$file = $components[1];
				} else {
					$state = uc($components[1]);
					$file = $components[2];
				}

				# Clear the deduping hash when we can, to avoid it becoming too large
				if($country eq 'us') {
					if((!defined($current_state)) || ($state ne $current_state)) {
						# print "New state, clear state_md5s; state = $state, country = $country\n";
						%state_md5s = ( );
						$current_country = $country;
						$current_state = $state;
					}
				} elsif((!defined($current_country)) || ($country ne $current_country)) {
					# print "New country, clear state_md5s\n";
					%state_md5s = ( );
					$current_country = $country;
				}

				my $inserts = 0;

				# Import this state's hand curated data
				if(my $k = $known_places{$f}) {
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
					if($state && ($country eq 'us')) {
						next unless($wof_file =~ /\/whosonfirst\-data\-venue\-([a-z]{2})\-([a-z]+)\-latest/);
						next if((lc($1) ne $country) || (uc($2) ne $state));
					} else {
						next unless($wof_file =~ /\/whosonfirst\-data\-venue\-([a-z]{2})\-latest/);
						my $c = lc($1);
						next if($c ne $country);
					}
				# if(my $whosonfirst = $ENV{WHOSONFIRST_HOME}) {
					# my $wof_file;
					# if($state && ($country eq 'us')) {
						# $wof_file = "$whosonfirst/whosonfirst-data-venue-us-" . lc($state) . '-latest.db';
					# } else {
						# $wof_file = "$whosonfirst/whosonfirst-data-venue-" . lc($country) . '-latest.db';
					# }
					my $file = basename($wof_file);
					$| = 1;
					printf "%-70s\r", $file;
					$| = 0;
					print "\n";
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
						next if($properties->{'wof:country'} ne uc($country));
						my $city = $properties->{'sg:city'};
						# Don't trust sg:city to be correct
						my @hierarchy = @{$properties->{'wof:hierarchy'}};
						if(scalar(@hierarchy) && (my $locality = $hierarchy[0]->{'locality_id'})) {
							if(my $w = get_wof($wof_global_dbh, $locality)) {
								$city = $w;
							}
						}
						if($country ne 'us') {
							# For the US, the state name comes from the WOF filename
							# For the rest of the world there is one WOF file per country
							$state = $properties->{'sg:region'} || $properties->{'sg:province'};
						}
						# if($city) {
							# print "$country, $state, $city\n";
						# } else {
							# print "$country, $state\n";
						# }
						if(!defined($city)) {
							my $address = $properties->{'addr:full'};
							next if(!defined($address));
							if($country eq 'us') {
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
						my $number = $properties->{'addr:number'};
						if($number) {
							$number = uc($number);
						}
						my $row = {
							'LAT' => $properties->{'geom:latitude'},
							'LON' => $properties->{'geom:longitude'},
							'NAME' => uc($properties->{'wof:name'}),
							'NUMBER' => $number,
							'STREET' => $street,
							'CITY' => uc($city),
							'STATE' => $state,
							'COUNTRY' => uc($country),
							'POSTCODE' => $postcode,
						};
						$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh);
						if($inserts >= MAX_INSERT_COUNT) {
							flush_queue($dbh);
							$inserts = 0;
						}
					}
					$wof_dbh->disconnect();
					delete $whosonfirst{$wof_file};
					# last;
				}

				$| = 1;
				printf "%-70s\r", $f;
				$| = 0;
				print "\n";

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

				open(my $fin, '<', $csv_file);
				$csv->column_names($csv->getline($fin));

				while(my $row = $csv->getline_hr($fin)) {
					$inserts += import(country => $country, state => $state, row => $row, file => $file, ua => $ua, dbh => $dbh);
					if($inserts >= MAX_INSERT_COUNT) {
						flush_queue($dbh);
						$inserts = 0;
					}
				}
			}
		}

		%state_md5s = ();

		foreach my $country(@whosonfirst_only_countries) {
			# TODO: import known_places for this country

			# Import this country's Who's on First data
			my $inserts = 0;
			foreach my $wof_file (keys %whosonfirst) {
				next unless($wof_file =~ /\/whosonfirst\-data\-venue\-([a-z]{2})\-latest/);
				my $c = lc($1);
				next if($c ne $country);
				my $file = basename($wof_file);
				$| = 1;
				printf "%-70s\r", $file;
				$| = 0;
				print "\n";
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
					next if($properties->{'wof:country'} ne uc($country));
					my $street = $properties->{'addr:street'};
					next if(!defined($street));
					# https://github.com/whosonfirst-data/whosonfirst-data/issues/1193
					$street =~ s/;.+$//;
					my $city = $properties->{'sg:city'};
					# Don't trust sg:city to be correct
					my @hierarchy = @{$properties->{'wof:hierarchy'}};
					if(scalar(@hierarchy) && (my $locality = $hierarchy[0]->{'locality_id'})) {
						if(my $w = get_wof($wof_global_dbh, $locality)) {
							$city = $w;
						}
					}
					my $state = $properties->{'sg:region'} || $properties->{'sg:province'};
					my $postcode = $properties->{'addr:postcode'};
					$country = uc($country);
					if(defined($city)) {
						$city = uc($city);
					}
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
					if(!defined($city)) {
						if(defined($postcode) && ($postcode =~ /^W1 /)) {
							$city = 'LONDON';
						} else {
							# warn Data::Dumper->new([$data])->Dump();
							next;
						}
					}
					my $row = {
						'LAT' => $properties->{'geom:latitude'},
						'LON' => $properties->{'geom:longitude'},
						'NAME' => uc($properties->{'wof:name'}),
						'NUMBER' => uc($properties->{'addr:housenumber'}),
						'STREET' => uc($street),
						'CITY' => $city,
						'STATE' => $state,
						'COUNTRY' => $country,
						'POSTCODE' => $postcode,
					};
					$inserts += import(row => $row, file => $file, ua => $ua, dbh => $dbh);
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
		$| = 0;
		foreach my $key(keys %cities) {
			my ($city, $county, $state, $country) = split(/,/, $key);
			my $sequence = $cities{$key};

			$city =~ s/'/''/g;
			my $query = "INSERT INTO cities('SEQUENCE','CITY','COUNTY','STATE','COUNTRY'" .
				') VALUES (' .
				"'$sequence'," .
				(($city eq 0) ? "NULL," : "'$city',") .
				(($county eq 0) ? "NULL," : "'$county',") .
				"'$state'," .
				"'$country')";

			# print "$query\n";
			$dbh->do($query);
		}

		$| = 1;
		printf "%-70s\r", 'creating indicies';
		$| = 0;

		# Reclaim memory
		%state_md5s = ();
		%global_md5s = ();
		%cities = ();

		$dbh->prepare('CREATE UNIQUE INDEX sequence_index ON cities(sequence)')->execute();
		$dbh->prepare('CREATE UNIQUE INDEX md5_index ON openaddresses(md5)')->execute();
		# $dbh->prepare('CREATE UNIQUE INDEX node_index ON level(md5)')->execute();
		# $dbh->prepare('CREATE UNIQUE INDEX leaf_index ON leaf(md5)')->execute();

		$| = 1;
		printf "%-70s\r", 'committing';
		$| = 0;
		$dbh->commit();
		$dbh->disconnect();
		print ' ' x 70, "\r";
	}

	# TODO: Import the Maxmind databases
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

	my $city = $row->{'CITY'};
	my $county = $row->{'COUNTY'};
	if(($file !~ /^statewide/) && ($file !~ /^province/) && ($file !~ /^countrywide/)) {
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
		} elsif($file !~ /^WHOSONFIRST\-DATA/i) {
			$county = $file;
			$county =~ s/\.csv$//;
		}
	}
	if(!defined($city)) {
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
					'COUNTRY' => uc($country),
					'STATE' => $state,
					'COUNTY' => $county,
					'CITY' => $city,
					'LAT' => $place->{'latitude'},
					'LON' => $place->{'longitude'},
				);
				# print "$zip => $query\n";
				$inserts += insert($dbh, $global, \%columns);
			}
		}
		if(!defined($city)) {
			return 0 if(!$zip);
			return 0 if($zip !~ /^\d{5}/);
			# print "\n", Data::Dumper->new([\$row])->Dump();
			$dbh->disconnect();
			die $file;
		}
	}
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
	my $street = $row->{'STREET'};
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
		} elsif($street =~ /(.+)\s+CREEK$/) {
			$street = "$1 CRK";
		}
		$street =~ s/^0+//;	# Turn 04th St into 4th St
	}
	if($file =~ /^(.+)[_\-]county.csv$/) {
		$county = $1;
	} elsif(!defined($county)) {
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
	if(!defined($state)) {
		$state = $row->{'REGION'};
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
	if(($city && ($city !~ /^\s+$/)) || $county) {
		# Counties and states alone have already been read in
		$country = uc($country);
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
			$columns{$c} = delete $row->{$c};
		}
		if(($country eq 'GB') && ($city eq 'LONDON') && defined($state) && ($state eq 'LONDON')) {
			delete $columns{'CITY'};
		}
		$inserts += insert($dbh, $global, \%columns);
		if(delete($columns{'COUNTY'})) {
			$inserts += insert($dbh, $global, \%columns);
		}
		my $name = $columns{'NAME'};
		if($name) {
			# TODO: more of these
			# foreach my $classifier($properties->{'sg:classifier'}) {
			#	Check if $name ends with uc($classifier->{category})
			if($name =~ /^(.+)\s+RESTAURANT/i) {
				$columns{'NAME'} = $1;
				$inserts += insert($dbh, $global, \%columns);
				# print "$1\n";
			}
			if(delete($columns{'NAME'})) {
				$inserts += insert($dbh, $global, \%columns);
			}
		}
		if(delete($columns{'NUMBER'})) {
			if($name) {
				# For when a name is known but not a street number
				$columns{'NAME'} = $name;
				$inserts += insert($dbh, $global, \%columns);
				if($name =~ /^(.+)\s+RESTAURANT/i) {
					$columns{'NAME'} = $1;
					$inserts += insert($dbh, $global, \%columns);
					# print "$1\n";
				}
				delete($columns{'NAME'});
			}
			# Match somewhere in the street when number isn't known
			$inserts += insert($dbh, $global, \%columns);
			if(delete($columns{'STREET'})) {
				if($name) {
					# For when a name is known but not a street
					$columns{'NAME'} = $name;
					$inserts += insert($dbh, $global, \%columns);
					if($name =~ /^(.+)\s+RESTAURANT/i) {
						$columns{'NAME'} = $1;
						$inserts += insert($dbh, $global, \%columns);
						# print "$1\n";
					}
					delete($columns{'NAME'});
				}
				# Match somewhere in the city when street isn't known
				$inserts += insert($dbh, $global, \%columns);
			}
		} elsif($name && delete($columns{'STREET'})) {
			# For when a name is known but not a street
			$columns{'NAME'} = $name;
			$inserts += insert($dbh, $global, \%columns);
			if($name =~ /^(.+)\s+RESTAURANT/i) {
				$columns{'NAME'} = $1;
				$inserts += insert($dbh, $global, \%columns);
				# print "$1\n";
			}
		}
	}
	return $inserts;
}

# Insert data into the database, returns the number of new rows
sub insert {
	my ($dbh, $global, $c) = @_;

	my $columns = { %{$c} };	# Take a copy of the hash because we're going to play with it

	foreach my $column(keys %{$columns}) {
		if(!defined($columns->{$column})) {
			delete $columns->{$column};
		} elsif($columns->{$column} =~ /^\s+$/) {
			delete $columns->{$column};
		}
	}

	# print Data::Dumper->new([$columns])->Dump() if($columns->{'CITY'} && (uc($columns->{'CITY'}) eq 'INDIANAPOLIS'));
	# print Data::Dumper->new([$columns])->Dump() if($columns->{'NAME'} && (uc($columns->{'NAME'}) eq 'EL PAPI STREET TACOS'));
	# my @call_details = caller(0);
	# print "line " . $call_details[2], "\n";
	# print Data::Dumper->new([$columns])->Dump();

	my $lat = $columns->{'LAT'};
	my $lon = $columns->{'LON'};

	die Data::Dumper->new([$columns])->Dump() unless(defined($lat) && defined($lon));
	# die "$lat/$lon" unless($columns->{'STATE'});

	# Remove duplicate, leading and trailing spaces from entries.  Some openaddresses files are littered with them
	foreach my $column(keys %{$columns}) {
		$columns->{$column} =~ s/\s+$//g;
		$columns->{$column} =~ s/^\s+//g;
		$columns->{$column} =~ s/\s\s+/ /g;
	}

	# my $digest = Digest::MD5::md5_base64(map { Encode::encode_utf8($columns->{$_}) } sort keys %{$columns});
	my $digest;
	# print Data::Dumper->new([$columns])->Dump();
	foreach my $column('NAME','NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
		$digest .= $columns->{$column} if($columns->{$column});
	}
	# print "$digest\n";
	$digest = hash($global, Encode::encode_utf8($digest));

	if(!defined($digest)) {
		# print "Ignore ", join(',', values(%{$columns})), "\n";
		return 0;
	}

	# print "$digest\n";

	# my $q = "SELECT * FROM openaddresses WHERE MD5 = '$digest'";
	# my $sth = $dbh->prepare($q);
	# $sth->execute();
	# while(my $href = $sth->fetchrow_hashref()) {
		# my @call_details = caller(0);
		# print "line " . $call_details[2], "\n";
		# print Data::Dumper->new([$columns])->Dump();
		# print Data::Dumper->new([$href])->Dump();
	# }

	$queued_commits{$digest} = $columns;
	my $key = city_key($columns->{'CITY'}, $columns->{'COUNTY'}, $columns->{'STATE'}, $columns->{'COUNTRY'});
	if(!$cities{$key}) {
		$city_sequence++;
		# print "adding '$key' to cities list\n";
		$cities{$key} = $city_sequence;
	}

	# Some postal address parsers have problems with "N FOO ST", so also store "NFOOST"
	if($columns->{'STREET'} && ($columns->{'STREET'} =~ /^[A-Z]\s\w+\s\w+$/)) {
		# Handle https://rt.cpan.org/Public/Bug/Display.html?id=124919
		$columns->{'STREET'} =~ s/\s+//g;
		$digest = '';

		foreach my $column('NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
			$digest .= $columns->{$column} if($columns->{$column});
		}
		if($digest = hash($global, Encode::encode_utf8($digest))) {
			$queued_commits{$digest} = $columns;
			return 2;
		# } else {
			# print "Ignore ", join(',', values(%{$columns})), "\n";
		}
	}
	return 1;
}

# All of the place's values are combined into one INSERT INTO
# Be aware of https://github.com/openaddresses/openaddresses/issues/3928
sub flush_queue
{
	my $dbh = shift;

	# print "flush\n";

	# my @columns = ('LAT','LON','NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY');
	my @columns = ('LAT','LON','NAME','NUMBER','STREET');

	my $query;

	keys %queued_commits;
	# print scalar(keys %queued_commits), "\n";
	while(my($md5, $row) = each %queued_commits) {
		my $country = $row->{'COUNTRY'};
		my $state = $row->{'STATE'};
		if($max_state_lengths{$country} && $state && (length($state) > $max_state_lengths{$country})) {
			print STDERR 'Invalid state length: ', Data::Dumper->new([$row])->Dump();
			next;
		}
		if(length($country) != 2) {
			print STDERR "Invalid country length:\n", Data::Dumper->new([$row])->Dump();
			next;
		}

		if(!defined($query)) {
			$query = 'INSERT INTO openaddresses(';
			foreach my $column(@columns) {
				$query .= "$column,";
			}
			$query .= 'CITY,MD5) VALUES (';
		} else {
			$query .= ',(';
		}

		# print join(',', @columns), ": $md5\n";
		# print "$md5: ", Data::Dumper->new([$row])->Dump();

		my $key = city_key($row->{'CITY'}, $row->{'COUNTY'}, $state, $country);

		foreach my $column(@columns) {
			if($row->{$column}) {
				if(($column eq 'LAT') || ($column eq 'LON') || ($column eq 'CITY')) {
					$query .= $row->{$column} . ',';
				} else {
					$row->{$column} =~ s/'/''/g;
					$query .= "'" . $row->{$column} . "',";
				}
			} else {
				$query .= 'NULL,';
			}
		}
		die $key unless $cities{$key};
		$query .= $cities{$key} . ",'$md5')";
	}

	if($query) {
		# print "$query\n";
		# $| = 1;
		# print '.';
		# $| = 0;
		try {
			$dbh->do($query);
		} catch {
			print Data::Dumper->new([\%queued_commits])->Dump();
			die $_;
		};
		%queued_commits = ();
	}
}

sub hash
{
	my $global = shift;

	# my $digest = Digest::MD5::md5_base64(@_);
	my $digest = substr Digest::MD5::md5_base64(@_), 0, 16;
	return if($global_md5s{$digest} || $state_md5s{$digest});

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

sub get_wof {
	my ($dbh, $id) = @_;

	state $cache;

	if(defined($cache)) {
		if(my $name = $cache->get($id)) {
			# print "get_wof: cached $name\n";
			return $name;
		}
	} else {
		$cache = CHI->new(driver => 'RawMemory', global => 0, max_size => 1_000);
	}

	# print "get_wof: not cached $id\n";

	my $query = "SELECT body FROM geojson where id = $id LIMIT 1";
	my $sth = $dbh->prepare($query);
	$sth->execute() || die($query);
	my $data = $sth->fetchrow_arrayref();
	return if(!defined($data));
	# print Data::Dumper->new([@{$data}])->Dump();
	# print $data, "\n", 'x' x 70, "\n";
	$data = JSON->new()->utf8()->decode(@{$data});
	my $properties = $data->{'properties'};
	return if(scalar(@{$properties->{'wof:superseded_by'}}));
	# if($properties->{'wof:name'}) {
		if($properties->{'wof:placetype'} eq 'region') {
			my $country = $properties->{'wof:country'};
			if(($country eq 'US') || ($country eq 'CA') || ($country eq 'AU')) {
				return $cache->set($id, $properties->{'wof:abbreviation'} || $properties->{'wof:name'}, '1 minute');
			}
		}
		return $cache->set($id, $properties->{'wof:name'}, '1 minute');
	# }
}
