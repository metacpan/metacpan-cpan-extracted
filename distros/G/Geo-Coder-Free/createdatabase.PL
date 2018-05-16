#!/usr/bin/env perl

# Import data from openaddresses.io and whosonfirst.org into an SQLite database.
# Set OPENADDR_HOME and WHOSONFIRST_HOME to the directories where the data has been downloaded
# Download the OPENADDR_HOME data from http://results.openaddresses.io.
# Download the WHOSONFIRST_HOME data using https://github.com/nigelhorne/NJH-Snippets/blob/master/bin/wof-sqlite-download

# TODO: perhaps use a layered approach to the database schema

use strict;
use warnings;
use autodie qw(:all);
use File::Copy;
use DBI;
use Text::xSV::Slurp;
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

use	constant	MAX_INSERT_COUNT => 100;	# Maximum number of CSV rows to insert in a single statement

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
my %known_places = (	# Places I've checked with my GPS
	'us/md/statewide.csv' =>
		[
			{
				# NCBI
				'LAT' => 38.99516556,
				'LON' => -77.09943963,
				'STREET' => 'MEDLARS DR',
				'CITY' => 'BETHESDA',
				'COUNTY' => 'MONTGOMERY',
				'POSTCODE' => 20894,
			}, {
				'LAT' => 38.99698114,
				'LON' => -77.10031119,
				'STREET' => 'CENTER DR',
				'CITY' => 'BETHESDA',
				'COUNTY' => 'MONTGOMERY',
			}, {
				# Bold bite
				'LAT' => 38.98939358,
				'LON' => -77.09819543,
				'STREET' => 'NORFOLK AVE',
				'CITY' => 'BETHESDA',
				'COUNTY' => 'MONTGOMERY',
			}, {
				'NAME' => 'ALBERT EINSTEIN HIGH SCHOOL',
				'LAT' => 39.03869019,
				'LON' => -77.0682871,
				'NUMBER' => 11135,
				'STREET' => 'NEWPORT MILL RD',
				'CITY' => 'KENSINGTON',
				'COUNTY' => 'MONTGOMERY',
				'POSTCODE' => 20895
			}, {
				'NAME' => 'POST OFFICE',
				'LAT' => 39.02554455,
				'LON' => -77.07178215,
				'NUMBER' => 10325,
				'STREET' => 'KENSINGTON PKWY',
				'CITY' => 'KENSINGTON',
				'COUNTY' => 'MONTGOMERY',
				'POSTCODE' => 20895
			}, {
				'NAME' => 'NEWPORT MILL MIDDLE SCHOOL',
				'LAT' => 39.0416107,
				'LON' => -77.06884708,
				'NUMBER' => 11311,
				'STREET' => 'NEWPORT MILL RD',
				'CITY' => 'KENSINGTON',
				'COUNTY' => 'MONTGOMERY',
				'POSTCODE' => 20895
			}, {
				'NAME' => 'SAFEWAY',
				'LAT' => 39.02822438,
				'LON' => -77.0755196,
				'NUMBER' => 10541,
				'STREET' => 'HOWARD AVE',
				'CITY' => 'KENSINGTON',
				'COUNTY' => 'MONTGOMERY',
				'POSTCODE' => 20895
			}, {
				'NAME' => 'STROSNIDERS',
				'LAT' => 39.02781493,
				'LON' => -77.07740792,
				'NUMBER' => 10504,
				'STREET' => 'CONNECTICUT AVE',
				'CITY' => 'KENSINGTON',
				'COUNTY' => 'MONTGOMERY',
			}, {
				'NAME' => 'SNIDERS',
				'LAT' => 39.0088797,
				'LON' => -77.04162824,
				'NUMBER' => 1936,
				'STREET' => 'SEMINARY RD',
				'CITY' => 'SILVER SPRING',
				'COUNTY' => 'MONTGOMERY',
				'POSTCODE' => 20910,
			}, {
				'NAME' => 'SILVER DINER',
				'LAT' => 39.05798753,
				'LON' => -77.12165374,
				'NUMBER' => 12276,
				'STREET' => 'ROCKVILLE PIKE',
				'CITY' => 'ROCKVILLE',
				'COUNTY' => 'MONTGOMERY',
				'POSTCODE' => 20852
			}, {
				# LF
				'LAT' => 39.07669788,
				'LON' => -77.12306436,
				'NUMBER' => 1605,
				'STREET' => 'VIERS MILL ROAD',
				'CITY' => 'ROCKVILLE',
				'COUNTY' => 'MONTGOMERY',
				'POSTCODE' => 20851
			}, {
				'LAT' => 39.0147541,
				'LON' => -77.05466857,
				'NAME' => 'BP',
				'NUMBER' => 2601,
				'STREET' => 'FOREST GLEN ROAD',
				'CITY' => 'SILVER SPRING',
				'COUNTY' => 'MONTGOMERY',
				'POSTCODE' => 20910
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
		$dbh->prepare("CREATE TABLE cities(sequence INTEGER, city VARCHAR, county VARCHAR, state VARCHAR(3) NOT NULL, country CHAR(2) NOT NULL)")->execute();
		$dbh->prepare("CREATE TABLE openaddresses(md5 CHAR(16), lat INTEGER, lon INTEGER, name VARCHAR, number VARCHAR, street VARCHAR, city INTEGER, FOREIGN KEY (city) REFERENCES cities(sequence))")->execute();

		print "This will take some time.\nBest to do it last thing at night and go to sleep, it should be ready in the morning.\n";

		my $filename = 'lib/Geo/Coder/Free/OpenAddresses/databases/states.txt';
		if(-r $filename) {
			# Import counties and states from https://github.com/openaddresses/openaddresses/tree/master/us-data
			$| = 1;
			printf "%-70s\r", $filename;
			$| = 0;
			my %state_fips;

			my @data = @{xsv_slurp(
				shape => 'aoh',
				text_csv => {
					sep_char => "\t",
					allow_loose_quotes => 1,
					blank_is_undef => 1,
					empty_is_undef => 1,
					binary => 1,
				},
				file => $filename
			)};
			foreach my $row(@data) {
				# print Data::Dumper->new([\$row])->Dump();
				my $state;
				unless($state = Locale::US->new()->{state2code}{uc($row->{'Name'})}) {
					die $row->{'Name'};
				}
				my $digest = hash(1, $state, 'US');
				my $key = city_key(undef, undef, $state, 'US');
				if(!$cities{$key}) {
					$city_sequence++;
					$cities{$key} = $city_sequence;
				}
				my $query = "INSERT INTO openaddresses('MD5','LAT','LON','CITY'" .
					') VALUES (' .
					"'$digest'," .
					$row->{'Latitude'} . ',' .
					$row->{'Longitude'} . ',' .
					$cities{$key} . ')';
				$dbh->prepare($query)->execute();
				# print "$query\n";
				$state_fips{$row->{'State FIPS'}} = $state;
			}

			$filename = 'lib/Geo/Coder/Free/OpenAddresses/databases/counties.txt';
			$| = 1;
			printf "%-70s\r", $filename;
			$| = 0;

			@data = @{xsv_slurp(
				shape => 'aoh',
				text_csv => {
					sep_char => "\t",
					allow_loose_quotes => 1,
					blank_is_undef => 1,
					empty_is_undef => 1,
					binary => 1,
				},
				file => $filename
			)};
			foreach my $row(@data) {
				# print Data::Dumper->new([\$row])->Dump();
				my $state = $state_fips{$row->{'State FIPS'}};
				die $row->{'Name'} unless(defined($state));
				my $county = uc($row->{'Name'});
				$county =~ s/\s+COUNTY$//;
				my $digest = hash(1, $county, $state, 'US');
				$county =~ s/'/''/g;	# O'Brien County, IA
				my $key = city_key(undef, $county, $state, 'US');
				if(!$cities{$key}) {
					$city_sequence++;
					$cities{$key} = $city_sequence;
				}
				my $query = "INSERT INTO openaddresses('MD5','LAT','LON','CITY'" .
					') VALUES (' .
					"'$digest'," .
					"'" . $row->{'Latitude'} . "'," .
					"'" . $row->{'Longitude'} . "'," .
					$cities{$key} . ')';
				# print "$query\n";
				$dbh->prepare($query)->execute();
			}
		}

		my $current_state;
		my $current_country;
		my %whosonfirst;
		if(my $whosonfirst = $ENV{WHOSONFIRST_HOME}) {
			$| = 1;
			printf "%-70s\r", "Traversing $whosonfirst";
			$| = 0;
			foreach my $file(<"$whosonfirst/*.db">) {
				$whosonfirst{$file} = 1;
			}
		}
		my $ua = LWP::UserAgent::Throttled->new(keep_alive => 1);
		$ua->throttle({ 'api.zippopotam.us' => 1 });
		$ua->env_proxy(1);

		foreach my $csv_file (uniq(create_tree($oa))) {
			# next unless($csv_file =~ /statewide/);
			# next unless($csv_file =~ /us\/ne\/dawes/);
			# next unless($csv_file =~ /us\/ca\/sonoma/);
			# next unless($csv_file =~ /us\/md\/statewide/);

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
				if(($country eq 'us') || ($country eq 'ca')) {
					if((!defined($current_state)) || ($state ne $current_state)) {
						# print "New state, clear state_md5s\n";
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
						$inserts += import(country => $country, state => $state, row => $row, file => $file, ua => $ua, dbh => $dbh, global => 1);
						if($inserts >= MAX_INSERT_COUNT) {
							flush_queue($dbh);
							$inserts = 0;
						}
					}
				}

				# Import this state's Who's on First data
				foreach my $wof_file (keys %whosonfirst) {
					if($state && ($country eq 'us')) {
						next unless($wof_file =~ /\/whosonfirst\-data\-venue\-([a-z]{2})\-([a-z]+)\-latest/);
						my $c = lc($1);
						my $s = uc($2);
						next if(($c ne $country) || ($s ne $state));
					} else {
						next unless($wof_file =~ /\/whosonfirst\-data\-venue\-([a-z]{2})\-latest/);
						my $c = lc($1);
						next if($c ne $country);
					}
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

					my $sth = $wof_dbh->prepare('SELECT * FROM geojson');
					$sth->execute() || die $wof_file;

					while(my $data = $sth->fetchrow_hashref()) {
						if($data->{'body'}) {
							$data = $data->{'body'};
						}
						next if(!defined($data));
						$data = JSON->new()->utf8()->decode($data);
						next if($data->{'properties'}->{'wof:superseded_by'});
						next if($data->{'properties'}->{'wof:country'} ne uc($country));
						my $city = $data->{'properties'}->{'sg:city'};
						if(!defined($city)) {
							my $address = $data->{'properties'}->{'addr:full'};
							next if(!defined($address));
							if(my $href = (Geo::StreetAddress::US->parse_location($address) || Geo::StreetAddress::US->parse_address($address))) {
								if($href->{city}) {
									$city = $href->{city};
								}
							}
						}
						next if(!defined($city));
						my $postcode = $data->{'properties'}->{'addr:postcode'};
						if($postcode) {
							$postcode = uc($postcode);
						}
						my $street = $data->{'properties'}->{'addr:street'};
						if($street) {
							$street = uc($street);
						}
						my $number = $data->{'properties'}->{'addr:number'};
						if($number) {
							$number = uc($number);
						}
						my $row = {
							'LAT' => $data->{'properties'}->{'geom:latitude'},
							'LON' => $data->{'properties'}->{'geom:longitude'},
							'NAME' => uc($data->{'properties'}->{'wof:name'}),
							'NUMBER' => $number,
							'STREET' => $street,
							'CITY' => uc($city),
							'STATE' => $state,
							'COUNTRY' => uc($country),
							'POSTCODE' => $postcode,
						};
						$inserts += import(country => $country, state => $state, row => $row, file => $file, ua => $ua, dbh => $dbh);
						if($inserts >= MAX_INSERT_COUNT) {
							flush_queue($dbh);
							$inserts = 0;
						}
					}
					$wof_dbh->disconnect();
					delete $whosonfirst{$wof_file};
					last;
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

		%state_md5s = ( );

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

				my $sth = $wof_dbh->prepare('SELECT * FROM geojson');
				$sth->execute() || die $wof_file;

				while(my $data = $sth->fetchrow_hashref()) {
					# print Data::Dumper->new([$data])->Dump();
					if($data->{'body'}) {
						$data = $data->{'body'};
					}
					next if(!defined($data));
					$data = JSON->new()->utf8()->decode($data);

					next if(scalar(@{$data->{'properties'}->{'wof:superseded_by'}}));
					next if($data->{'properties'}->{'wof:country'} ne uc($country));
					my $street = $data->{'properties'}->{'addr:street'};
					next if(!defined($street));
					# https://github.com/whosonfirst-data/whosonfirst-data/issues/1193
					$street =~ s/;.+$//;
					my $city = $data->{'properties'}->{'sg:city'};
					my $state = $data->{'properties'}->{'sg:region'} || $data->{'properties'}->{'sg:province'};
					my $postcode = $data->{'properties'}->{'addr:postcode'};
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
						# if($data->{'properties'}->{'wof:hierachy'}[0]->{'region_id'} == 85683823) {
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
						'LAT' => $data->{'properties'}->{'geom:latitude'},
						'LON' => $data->{'properties'}->{'geom:longitude'},
						'NAME' => uc($data->{'properties'}->{'wof:name'}),
						'NUMBER' => uc($data->{'properties'}->{'addr:housenumber'}),
						'STREET' => uc($street),
						'CITY' => $city,
						'STATE' => $state,
						'COUNTRY' => $country,
						'POSTCODE' => $postcode,
					};
					$inserts += import(country => $country, state => $state, row => $row, file => $file, ua => $ua, dbh => $dbh);
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
			$dbh->prepare($query)->execute();
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

		$| = 1;
		printf "%-70s\r", 'committing';
		$| = 0;
		$dbh->commit();
		$dbh->disconnect();
		print ' ' x 70, "\r";
	}

	# TODO:  Import the Maxmind databases
}

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

	my $country = $param{'country'} || die 'import: no country';
	my $state = $param{'state'};	# Will come from $row->{'REGION'}
	my $row = $param{'row'} || die 'import: no row';
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
		} elsif($file !~ /^wof\-.+latest\.csv$/i) {
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
			my $res = $ua->get("http://api.zippopotam.us/$country/$zip");
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
			my %columns = (
				'COUNTRY' => uc($country),
				'STATE' => $state,
				'CITY' => $city,
				'LAT' => $place->{'latitude'},
				'LON' => $place->{'longitude'},
			);
			if($city) {
				# Counties and states alone have already been read in
				$columns{'COUNTY'} = $county;
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
	$city =~ s/_/ /g;
	$city =~ s/\-/ /g;
	$city =~ s/\./ /g;
	$city = uc($city);
	$city =~ s/\s+BORO$//;
	$city =~ s/\s+TWP$//;
	$city =~ s/^TOWN\s+OF\s+//;
	$city =~ s/^CITY\s+OF\s+//;
	$city =~ s/^TOWNSHIP\s+OF\s+//;
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
		} elsif($street =~ /(.+)\s+CT$/) {
			$street = "$1 COURT";
		} elsif($street =~ /(.+)\s+DRIVE$/) {
			$street = "$1 DR";
		} elsif($street =~ /(.+)\s+CIRCLE$/) {
			$street = "$1 CIR";
		} elsif($street =~ /(.+)\s+PARKWAY$/) {
			$street = "$1 PKWY";
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
		$county = uc($county);
		$county =~ s/_/ /g;
		$county =~ s/\s+COUNTY$//;
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
		if(delete($columns{'NAME'})) {
			$inserts += insert($dbh, $global, \%columns);
		}
		if(delete($columns{'NUMBER'})) {
			# Match somewhere in the street when number isn't known
			$inserts += insert($dbh, $global, \%columns);
			if(delete($columns{'STREET'})) {
				# Match somewhere in the city when street isn't known
				$inserts += insert($dbh, $global, \%columns);
			}
		}
	}
	return $inserts;
}

# Insert data into the database, returns the number of new rows
sub insert {
	my ($dbh, $global, $columns) = @_;

	$columns = { %{$columns} };	# Take a copy of the hash because we're going to play with it

	foreach my $column(keys %{$columns}) {
		if(!defined($columns->{$column})) {
			delete $columns->{$column};
		} elsif($columns->{$column} =~ /^\s+$/) {
			delete $columns->{$column};
		}
	}

	# print Data::Dumper->new([$columns])->Dump() if($columns->{'CITY'} && (uc($columns->{'CITY'}) eq 'INDIANAPOLIS'));
	# print Data::Dumper->new([$columns])->Dump() if($columns->{'NAME'} && (uc($columns->{'NAME'}) eq 'EL PAPI STREET TACOS'));
	# print Data::Dumper->new([$columns])->Dump();

	my $lat = $columns->{'LAT'};
	my $lon = $columns->{'LON'};

	die unless(defined($lat) && defined($lon));
	# die "$lat/$lon" unless($columns->{'STATE'});

	# my $digest = Digest::MD5::md5_base64(map { Encode::encode_utf8($columns->{$_}) } sort keys %{$columns});
	my $digest;
	# print Data::Dumper->new([$columns])->Dump();
	foreach my $column('NAME','NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
		$digest .= $columns->{$column} if($columns->{$column});
	}
	# print "$digest\n";
	$digest = hash($global, Encode::encode_utf8($digest));
	# print "$digest\n";

	if(!defined($digest)) {
		# print "Ignore ", join(',', values(%{$columns})), "\n";
		return 0;
	}

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

	if($columns->{'STREET'} && ($columns->{'STREET'} =~ /^[A-Z]\s\w+\s\w+$/)) {
		# Handle https://rt.cpan.org/Public/Bug/Display.html?id=124919
		my $s = $columns->{'STREET'};	# Should use a 'local' variable, I guess

		$columns->{'STREET'} =~ s/\s+//g;
		$digest = '';

		foreach my $column('NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
			$digest .= $columns->{$column} if($columns->{$column});
		}
		if($digest = hash($global, Encode::encode_utf8($digest))) {
			$queued_commits{$digest} = $columns;
		# } else {
			# print "Ignore ", join(',', values(%{$columns})), "\n";
		}
		return 2;
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

	foreach my $md5(keys %queued_commits) {
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

		my $row = $queued_commits{$md5};
		my $key = city_key($row->{'CITY'}, $row->{'COUNTY'}, $row->{'STATE'}, $row->{'COUNTRY'});
		foreach my $column(@columns) {
			if($row->{$column}) {
				$row->{$column} =~ s/'/''/g;
				if(($column eq 'LAT') || ($column eq 'LON') || ($column eq 'CITY')) {
					$query .= $row->{$column} . ',';
				} else {
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
		$dbh->prepare($query)->execute();
		%queued_commits = ();
	}
}

sub hash
{
	my $global = shift;

	my $digest = substr Digest::MD5::md5_base64(@_), 0, 16;
	# my $digest = Digest::MD5::md5_base64(@_);
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
		$state = '0';
	}
	return "$city,$county,$state,$country";
}
