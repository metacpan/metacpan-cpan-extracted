#!/usr/bin/env perl

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

use	constant	MAX_INSERT_COUNT => 50;	# Maximum number of CSV rows to insert in a single statement

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
my %supported_countries = (
	'au' => 1,
	'ca' => 1,
	'us' => 1,
);

my %postcodes = ();
my $current_state;
my %global_md5s;
my %state_md5s;
my %queued_commits;

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
		my $ua = LWP::UserAgent::Throttled->new(keep_alive => 1);
		$ua->throttle({ 'api.zippopotam.us' => 1 });
		$ua->env_proxy(1);

		# $dbh->prepare("CREATE TABLE openaddresses(md5 CHAR(32) UNIQUE PRIMARY KEY NOT NULL, lat INTEGER, lon INTEGER, number CHAR, street CHAR, city CHAR, county CHAR, state CHAR NOT NULL, country CHAR(2) NOT NULL)")->execute();
		$dbh->prepare("CREATE TABLE openaddresses(md5 CHAR(32), lat INTEGER, lon INTEGER, number CHAR, street CHAR, city CHAR, county CHAR, state CHAR NOT NULL, country CHAR(2) NOT NULL)")->execute();

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
				my $digest = Digest::MD5::md5_base64($state, 'US');
				my $query = "INSERT INTO openaddresses('MD5','LAT','LON','STATE','COUNTRY'" .
					') VALUES (' .
					"'$digest'," .
					$row->{'Latitude'} . ',' .
					$row->{'Longitude'} . ',' .
					"'$state','US')";
				$dbh->prepare($query)->execute();
				# print "$query\n";
				$state_fips{$row->{'State FIPS'}} = $state;
				$global_md5s{$digest} = 1;
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
				my $digest = Digest::MD5::md5_base64($county, $state, 'US');
				$county =~ s/'/''/g;	# O'Brien County, IA
				my $query = "INSERT INTO openaddresses('MD5','LAT','LON','COUNTY','STATE','COUNTRY'" .
					') VALUES (' .
					"'$digest'," .
					"'" . $row->{'Latitude'} . "'," .
					"'" . $row->{'Longitude'} . "'," .
					"'$county','$state','US')";
				# print "$query\n";
				$dbh->prepare($query)->execute();
				$global_md5s{$digest} = 1;
			}
		}

		foreach my $csv_file (create_tree($oa)) {
			# next unless($csv_file =~ /statewide/);
			# next unless($csv_file =~ /us\/ne\/dawes/);
			# next unless($csv_file =~ /us\/ca\/sonoma/);
			# next unless($csv_file =~ /us\/md\/statewide/);

			# Handle https://github.com/openaddresses/openaddresses/issues/3928
			# TODO: It would be better to merge airdrie.csv and city_of_airdrie.csv
			next if($csv_file =~ /ca\/ab\/airdrie.csv/);

			my $f = $csv_file;
			$f =~ s/^$oa\///;
			$| = 1;
			printf "%-70s\r", $f;
			$| = 0;
			print "\n";
			my @components = split(/\//, $f);
			if(my $country = $components[0]) {
				next unless($supported_countries{lc($country)});

				my $query;
				my $state;
				my $file;
				if($components[1] =~ /\.csv$/) {
					$file = $components[1];
				} else {
					$state = uc($components[1]);
					$file = $components[2];
				}

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
				my $head = $csv->getline($fin);
				$csv->column_names($head);

				my $inserts = 0;

				while(my $row = $csv->getline_hr($fin)) {
					my $city = $row->{'CITY'};
					my $county;
					if(($file !~ /^statewide/) && ($file !~ /^province/)) {
						if($file =~ /^city_of_(.+).csv$/) {
							$city = $1;
						} elsif($file =~ /^town_of_(.+).csv$/) {
							$city = $1;
						} elsif($file =~ /^(.+)_borough.csv$/) {
							$city = $1;
						} elsif(!defined($city)) {
							$city = $file;
							$city =~ s/\.csv$//;
						} else {
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
								next;
							}
							my $place = @{$rc->{'places'}}[0];
							if(!$place) {
								# print "\n", Data::Dumper->new([\$row])->Dump();
								next;
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
								insert($dbh, \%columns);
								$inserts++;
							}
						}
						if(!defined($city)) {
							next if(!$zip);
							next if($zip !~ /^\d{5}/);
							# print "\n", Data::Dumper->new([\$row])->Dump();
							$dbh->disconnect();
							die $csv_file;
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
						} elsif($street =~ /(.+)\s+CIRCLE$/) {
							$street = "$1 CIR";
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
					if(($city && ($city !~ /^\s+$/)) || $county) {
						# Counties and states alone have already been read in
						my %columns = (
							'COUNTRY' => uc($country),
							'CITY' => $city,
							'STATE' => $state,
							'COUNTY' => $county,
							'STREET' => $street
						);
						if($street) {
							$row->{'STREET'} =~ s/\s\s+/ /g;
						}
						foreach my $c('LAT', 'LON', 'NUMBER') {
							$columns{$c} = delete $row->{$c};
						}
						insert($dbh, \%columns);
						$inserts++;
						if(delete($columns{'COUNTY'})) {
							insert($dbh, \%columns);
							$inserts++;
						}
						if(delete($columns{'NUMBER'})) {
							# Match somewhere in the street when number isn't known
							insert($dbh, \%columns);
							$inserts++;
							if($city && delete($columns{'STREET'})) {
								# Match somewhere in the city when street isn't known
								insert($dbh, \%columns);
								$inserts++;
							}
						}
					}
					if($inserts >= MAX_INSERT_COUNT) {
						flush_queue($dbh);
						$inserts = 0;
					}
				}
			}
		}
		flush_queue($dbh);
		$| = 1;
		printf "%-70s\r", 'creating index';
		$| = 0;
		$dbh->prepare('CREATE UNIQUE INDEX md5_index ON openaddresses(MD5)')->execute();
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
		if(-d $file) {
			push(@list, create_tree($file, @list));
		} elsif(($file =~ /\.csv$/) && (-f $file)) {
			push(@list, $file);
		}
	}
	return @list;
}

sub insert {
	my ($dbh, $columns) = @_;

	foreach my $column(keys %{$columns}) {
		if(!defined($columns->{$column})) {
			delete $columns->{$column};
		} elsif($columns->{$column} =~ /^\s+$/) {
			delete $columns->{$column};
		}
	}

	# print Data::Dumper->new([$columns])->Dump() if($columns->{'CITY'} && (uc($columns->{'CITY'}) eq 'INDIANAPOLIS'));

	my $lat = $columns->{'LAT'};
	my $lon = $columns->{'LON'};

	die unless(defined($lat) && defined($lon));

	# my $digest = Digest::MD5::md5_base64(map { Encode::encode_utf8($columns->{$_}) } sort keys %{$columns});
	my $digest;
	# print Data::Dumper->new([$columns])->Dump();
	foreach my $column('NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
		$digest .= $columns->{$column} if($columns->{$column});
	}
	# print "$digest\n";
	$digest = Digest::MD5::md5_base64(Encode::encode_utf8($digest));
	# print "$digest\n";

	if(my $state = $columns->{'STATE'}) {
		# print "Looking for digest $digest\n";
		$state = uc($state);
		if((!defined($current_state)) || ($state ne $current_state)) {
			$current_state = $state;
			%state_md5s = ( $digest => 1 );
			# print "new state $state\n";
			flush_queue($dbh);	# Shouldn't be needed
		} else {
			if($state_md5s{$digest} || $global_md5s{$digest}) {
				# print "Ignore ", join(',', values(%{$columns})), "\n";
				return;
			}
			$state_md5s{$digest} = 1;
		}
	} else {
		die;
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

	# All of the place's values are combined into one large INSERT INTO
	$queued_commits{$digest} = $columns;

	if($columns->{'STREET'} && ($columns->{'STREET'} =~ /^[A-Z]\s\w+\s\w+$/)) {
		# Handle https://rt.cpan.org/Public/Bug/Display.html?id=124919
		my $s = $columns->{'STREET'};	# Should use a 'local' variable I guess

		$columns->{'STREET'} =~ s/\s+//g;
		$digest = '';
		foreach my $column('NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY') {
			$digest .= $columns->{$column} if($columns->{$column});
		}
		$digest = Digest::MD5::md5_base64(Encode::encode_utf8($digest));
		if($columns->{'STATE'} && ($state_md5s{$digest} || $global_md5s{$digest})) {
			# print "Ignore ", join(',', values(%{$columns})), "\n";
			return;
		}
		$state_md5s{$digest} = 1;
		$queued_commits{$digest} = $columns;

		$columns->{'STREET'} = $s;
	}
}

# All of the place's values are combined into one INSERT INTO
# Be aware of https://github.com/openaddresses/openaddresses/issues/3928
sub flush_queue
{
	my $dbh = shift;

	# print "flush\n";

	my @columns = ('LAT','LON','NUMBER','STREET','CITY','COUNTY','STATE','COUNTRY');

	my $query;
	foreach my $md5(keys %queued_commits) {
		if(!defined($query)) {
			$query = 'INSERT INTO openaddresses(';
			foreach my $column(@columns) {
				$query .= "$column,";
			}
			$query .= 'MD5) VALUES (';
		} else {
			$query .= ',(';
		}

		my $row = $queued_commits{$md5};
		foreach my $column(@columns) {
			if($row->{$column}) {
				$row->{$column} =~ s/'/''/g;
				if(($column eq 'LAT') || ($column eq 'LON')) {
					$query .= $row->{$column} . ',';
				} else {
					$query .= "'" . $row->{$column} . "',";
				}
			} else {
				$query .= 'NULL,';
			}
		}
		$query .= "'$md5')";
	}

	if($query) {
		# print "$query\n";
		$dbh->prepare($query)->execute();
		%queued_commits = ();
	}
}
