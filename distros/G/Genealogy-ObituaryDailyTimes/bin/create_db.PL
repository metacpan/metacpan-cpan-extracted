#!/usr/bin/env perl

# Create SQLite3 from https://sites.rootsweb.com/~obituary/ and
#	https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit
#
# -f:	force a build, otherwise it won't build on CPAN smokers or if the
#	database is less than a day old

# If mlarchives starts to fail to download, try looking at bin/ml_from_cache

use strict;
use warnings;
use DBI;
# use DBD::SQLite::Constants qw/:file_open/;	# For SQLITE_OPEN_READONLY
use File::HomeDir;
use File::Slurp;
use File::Spec;
use HTML::Entities;
use HTTP::Cache::Transparent;
use LWP::ConnCache;
use LWP::UserAgent::WithCache;
use Lingua::EN::NameCase qw(nc);
use Text::CSV;
use Try::Tiny;
use autodie qw(:all);

sub freelists($$);
sub mlarchives($$);
sub queue($$$$$$$$$);
sub flush($);
sub normalise_name($);

BEGIN {
	$SIG{__WARN__} = sub {
		my $warning = shift;
		if(($warning =~ /^Use of uninitialized value/) ||
		   ($warning =~ /isn't numeric in numeric eq /i)) {
			die $warning;
		}
		warn $warning;
	}
}

my %normalised;
my $force_flag;
my $dir = 'lib/Genealogy/ObituaryDailyTimes/data';

if(defined($ARGV[0]) && ($ARGV[0] eq '-f')) {
	$force_flag++;
} elsif($ENV{'AUTOMATED_TESTING'}) {
	exit;
}

if(!-d $dir) {
	mkdir $dir, 0755;
}

my $filename = File::Spec->catdir($dir, 'obituaries.sql');

if(-r $filename) {
	# Don't bother building if the current file is less than a day old
	if(((-s $filename) > 0) && (-M $filename < 1) && !$force_flag) {
		exit;
	}
	unlink $filename;
}

my $cache_dir = $ENV{'CACHE_DIR'} || $ENV{'CACHEDIR'};
if($cache_dir) {
	mkdir $cache_dir, 0700 if(!-d $cache_dir);
	$cache_dir = File::Spec->catfile($cache_dir, 'http-cache-transparent');
} else {
	$cache_dir = File::Spec->catfile(File::HomeDir->my_home(), '.cache', 'http-cache-transparent');
}

HTTP::Cache::Transparent::init({
	BasePath => $cache_dir,
	Verbose => 0,
	NoUpdate => 60 * 60 * 24 * 7 * 31,	# The archive never changes
	MaxAge => 30 * 24
}) || die "$0: $cache_dir: $!";

print "This will take some time. It'd be best to go and make yourself a cup of tea.\n";

my $ua = LWP::UserAgent::WithCache->new(timeout => 60, keep_alive => 1);
$ua->env_proxy(1);
$ua->agent('Mozilla/5.0');
$ua->conn_cache()->total_capacity(undef);
$Lingua::EN::NameCase::POSTNOMINAL = 0;

# print '"last","first","maiden","age","place","newspapername","newspaperdate","tag"', "\n";

my $dbh = DBI->connect("dbi:SQLite:dbname=$filename", undef, undef, { RaiseError => 1, AutoCommit => 0, synchronous => 0, locking_mode => 'EXCLUSIVE' });
die "$filename: $!" if(!defined($dbh));

$dbh->do('PRAGMA cache_size = -65536');	# 64MB
$dbh->do('PRAGMA journal_mode = OFF');
$dbh->do('CREATE TABLE obituaries(first VARCHAR NOT NULL, middle VARCHAR, last VARCHAR NOT NULL, maiden VARCHAR, age INTEGER, place VARCHAR, newspaper VARCHAR NOT NULL, date DATE NOT NULL, source CHAR NOT NULL, page VARCHAR NOT NULL)');

my @queue;

data();

if($ENV{'MLARCHIVE_DIR'} || $ENV{'MLARCHIVEDIR'}) {
	if(mlarchives($ua, 'other')) {
		flush($dbh)
	}
}

print ' ' x 78, "\r";

my $page = 1;
while(mlarchives($ua, $page)) {
	flush($dbh) if(scalar(@queue) > 10_000);
	$page++;
};

print ' ' x 78, "\r";

flush($dbh);

my $issue = 9;
while(freelists($ua, 'v25no' . sprintf('%03d', $issue))) {
	flush($dbh) if(scalar(@queue) > 10_000);
	$issue++;
}

flush($dbh);

$issue = 1;
while(freelists($ua, 'v26no' . sprintf('%03d', $issue))) {
	flush($dbh) if(scalar(@queue) > 10_000);
	$issue++;
	if($issue == 52) {
		$issue++;	# https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v26no052 doesn't exist
	}
}

flush($dbh);

$issue = 1;
while(freelists($ua, 'v27no' . sprintf('%03d', $issue))) {
	flush($dbh) if(scalar(@queue) > 10_000);
	$issue++;
}

flush($dbh);

$issue = 1;
while(freelists($ua, 'v28no' . sprintf('%03d', $issue))) {
	flush($dbh) if(scalar(@queue) > 10_000);
	$issue++;
}

flush($dbh);

$issue = 1;
# 2024
while(freelists($ua, 'v29no' . sprintf('%03d', $issue))) {
	flush($dbh) if(scalar(@queue) > 10_000);
	$issue++;
}

print "\n";

flush($dbh);

$dbh->commit();
$dbh->prepare('CREATE INDEX name_index ON obituaries(first, last)')->execute();
$dbh->prepare('CREATE INDEX name_age_index ON obituaries(first, last, age)')->execute();
$dbh->do('pragma optimize');
$dbh->disconnect();

# Import the data section
sub data
{
	local $| = 1;
	printf "%-70s\r", '<DATA>';

	my $parser = Text::CSV->new();
	while(<DATA>) {
		$parser->parse($_);
		my ($first, $middle, $last, $maiden, $age, $place, $date, $url) = $parser->fields();
		# printf "%-70s\r", $url;
		queue($first, normalise_name($last), $maiden, $age, $place, $date, $url, 'L', $url);
	}
}

sub mlarchives($$) {
	my @lines;
	my $ua = shift;
	my $page = shift;

	# my $url = "https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=$page";
	# Ancestry has removed the archives.
	# The first 17 pages are on Wayback machine, but the rest is lost
	my $url = "https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=$page";

	local $| = 1;
	printf "%-70s\r", $url if($page ne 'other');

	if($ENV{'MLARCHIVEDIR'}) {
		if($page eq 'other') {
			$url = File::Spec->catfile($ENV{'MLARCHIVEDIR'}, 'other');
			return 0 if(!-r $url);
			printf "%-70s\r", $url;
			@lines = read_file($url);
		} else {
			@lines = read_file(File::Spec->catfile($ENV{'MLARCHIVEDIR'}, "emails?listname=gen-obit&page=$page"));
		}
	} elsif($ENV{'MLARCHIVE_DIR'}) {
		if($page eq 'other') {
			$url = File::Spec->catfile($ENV{'MLARCHIVE_DIR'}, 'other');
			return 0 if(!-r $url);
			printf "%-70s\r", $url;
			@lines = read_file($url);
		} else {
			@lines = read_file(File::Spec->catfile($ENV{'MLARCHIVE_DIR'}, "emails?listname=gen-obit&page=$page"));
		}
	} else {
		my $response = $ua->get($url);

		my $data;
		if($response->is_success) {
			$data = $response->decoded_content();
		} else {
			if($response->status_line() ne '404 Not Found') {
				print STDERR "You may need to run bin/ml_from_cache\n";
				die "\n$url: ", $response->status_line();
			}
			return 0;
		}

		# mlarchive data is much easier to parse because it's nicely all on one line
		$data =~ s/\r//g;
		@lines = split(/$/ms, $data);
	}

	$| = 0;

	# -1 => header, 0 => post-preamble, 1 => post
	my $stage = -1;

	my $last_line;
	my $rc;
	# my $entries = 0;

	while(my $line = shift(@lines)) {
		# LAST NAME, First Name (MAIDEN); Age; Place of Death; Newspaper Name; Newspaper date; tagname

		next if((defined($last_line)) && ($line eq $last_line));
		$last_line = $line;

		$line =~ s/^\n//;
		# print "$stage: $line\n";
		if($line =~ /^------/) {
			if($stage == -1) {
				if($line =~ /No Results/) {
					# Last page
					return 0
				}
				if($line =~ /This page has not been archived here/) {
					# End of Wayback's archive
					die;	# Debugging
					return 0
				}
				# Introduction to a post about to start
				$stage = 0;
			} elsif($stage == 0) {
				# Post contents about to start
				$stage = 1;
			} else {
				# Introduction to a post about to start
				$stage = 0;
			}
			next
		} elsif($line =~ /^Obituary Results/) {
			# Contents about to start
			$stage = 1;
			next
		} elsif($stage == -1) {
			if($line =~ /^LAST NAME/) {
				# The ----- probably didn't start a line
				# e.g. https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=41
				$stage = 0
			} elsif($line =~ /Re: \[GEN-OBIT\]/) {
				# It's a reply to a post, not an actual post
				# e.g. https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=46
				return 1
			} elsif($line =~ /No Results/) {
				# Last page
				return 0
			} elsif($line =~ /This page has not been archived here/) {
				# End of Wayback's archive
				return 0
			}
			# if($line =~ /Obituary Daily Times (v\d.+)$/) {
				# print "$1\n" unless($1 =~ /strong>/);
			# }
		}
		next unless($stage == 1);

		if($line =~ /<\/p>.+/) {
			$stage = -1;
			next;
		}
		if($line =~ /^LAST NAME/) {
			# a whole entry is unparsable
			# e.g. https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=3
			next;
		}
		next if($line =~ /^\s/);
		$line =~ s/&nbsp;/ /g;
		$line = decode_entities($line);
		$line =~ s/'/''/g;
		my ($name, $age, $place, $newspaper, $date, $tag) = split(/;\s?/, $line);

		next if((!defined($tag)) || ($tag eq ''));

		# use Data::Dumper;
		# print __LINE__, ": $page: '$line' ", Data::Dumper->new([split(/;\s?/, $line)])->Dump();
		next unless(defined($name));
		my ($last, $first) = split(',\s', $name);
		next unless(defined($last));
		next unless(defined($first));

		my $maiden;
		if($first) {
			if($first =~ /(.+)\s\((.+)\)$/) {
				$first = normalise_name($1);
				$maiden = normalise_name($2);
			} else {
				$first = normalise_name($first);
			}
		}
		# $age //= '';

		# print "$line->>>>>>>>>>\n";
		if($last =~ /^[A-Z]/) {
			queue($first, normalise_name($last), $maiden, $age, $place, $date, $newspaper, 'M', $page);
			# $entries++;
		}
		# print "\"$last\",\"$first\",\"$maiden\",\"$age\",\"$place\",\"$date\",\"$newspaper\"\n" if($last =~ /^[A-Z]/);
		$rc = 1;
	}
	die "Couldn't parse $url" if(!defined($rc));
	# print "\n\t$entries\n";
	return 1;
}

sub freelists($$) {
	my $ua = shift;
	my $page = shift;
	my $url = "https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-$page";

	$| = 1;
	printf "%-70s\r", $url;
	$| = 0;

	my $response = $ua->get($url);

	my $data;
	if($response->is_success) {
		$data = $response->decoded_content();
	} else {
		if($response->status_line() ne '404 Not Found') {
			die "\n$url: ", $response->status_line();
		}
		return 0;
	}

	# print $data;
	# exit;

	# my @lines = split(/<br>|<br \/>/ms, $data);
	$data =~ s/<br>/\n/g;
	$data =~ s/<br ?\/>/\n/g;
	$data =~ s/\n\n+/\n/g;
	my @lines = split(/\n/ms, $data);

	my $rc;

	my $stage = 0;
	while(my $line = shift(@lines)) {
		# LAST NAME, First Name (MAIDEN); Age; Place of Death; Newspaper Name; Newspaper date; tagname
		# print "$stage: $line\n";
		$line =~ s/^\n//;
		next if($line eq '');
		if($line =~ /\-\-\-\-\-\-\-\-/) {
			$stage++;
			last if($stage >= 3);
			$line =~ s/^.*\-+//;
			next if($line eq '');
			next if($line eq '<br/>');
		}
		next if($stage != 2);
		$line =~ s/&nbsp;/ /g;
		$line =~ s/\x{a0}/ /g;
		$line = decode_entities($line);
		$line =~ s/'/''/g;
		my ($name, $age, $place, $newspaper, $date, $tag) = split(/;\s?/, $line);
		if((!defined($tag)) || ($tag eq '')) {
			# Handle when the information is split across more
			# than one line ("cont" means "continuation")
			my $cont = shift(@lines);

			# print __LINE__, ": continuation '$cont'\n";
			$cont =~ s/^\n//;
			last if($cont =~ /^\-\-\-\-\-\-\-\-/);
			$cont =~ s/&nbsp;/ /g;
			$cont =~ s/\x{a0}/ /g;
			$cont =~ s/&gt;/>/g;
			$line =~ s/&quot;/"/g;
			$line .= $cont;
			# print __LINE__, ": line '$line'\n";
			($name, $age, $place, $newspaper, $date, $tag) = split(/;\s?/, $line);
		}
		# print __LINE__, ": $line: ($stage): $name, $age, $place, $newspaper, $date, $tag\n";
		# use Data::Dumper;
		# print __LINE__, ": $page ", Data::Dumper->new([split(/;\s?/, $line)])->Dump();
		next unless(defined($name));
		my ($last, $first) = split(',\s', $name);
		next unless(defined($last));
		next unless(defined($first));

		# Parsing completely broken
		# e.g. https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v25no010
		# print __LINE__, "\n";
		last unless(defined($newspaper));
		# print __LINE__, "\n";

		my $maiden;
		if($first) {
			if($first =~ /(.+)\s\((.+)\)$/) {
				$first = normalise_name($1);
				$maiden = normalise_name($2);
			} else {
				$first = normalise_name($first);
			}
		}
		# $age //= '';

		# print "$line:\n",
			# "\t\"$last\",\"$first\",\"$age\",\"$place\",\"$date\",\"$newspaper\"\n" if($last =~ /^[A-Z]/);
			# "\t\"$last\",\"$first\",\"$maiden\",\"$age\",\"$place\",\"$date\",\"$newspaper\"\n" if(defined($maiden) && ($last =~ /^[A-Z]/));
		queue($first, normalise_name($last), $maiden, $age, $place, $date, $newspaper, 'F', $page) if($last =~ /^[A-Z]/);
		$rc = 1;
	}
	die "Couldn't parse $url (stage == $stage)" if(!defined($rc));
	return 1;
}

sub queue($$$$$$$$$)
{
	my ($first, $last, $maiden, $age, $place, $date, $newspaper, $source, $page) = @_;

	die $source if($source !~ /M|F|L/);

	# If we don't know the date of publication, it's not easy to find
	return unless(defined($date));

	return unless($date =~ /^\d/);

	my %columns = (
		first => $first,
		last => $last,
		date => $date,
		newspaper => $newspaper,
		place => $place,
		source => $source,
		page => $page,
	);

	if(defined($age) && ($age ne '')) {
		return if($age =~ /\D/);
		$age =~ s/\s+//g;
		$columns{'age'} = $age;
	}

	if($maiden) {
		$columns{'maiden'} = $maiden;
	}
	push @queue, \%columns;
}

sub flush($)
{
	my $dbh = shift;

	# Remove duplicates
	my @deduped;
	my %seen;

	while(my $item = pop @queue) {
		# my $first = $item->{'first'};
		# if(!defined($first)) {
			# $item->{'first'} = '';
		# }
		my $maiden = $item->{'maiden'};
		if(!defined($maiden)) {
			$item->{'maiden'} = '';
		}
		my $age = $item->{'age'};
		if(!defined($age)) {
			$item->{'age'} = '';
		}
		# use Data::Dumper;
		# print Data::Dumper->new([$item])->Dump();
		my $k = join('|', @$item{qw /first last maiden age place date newspaper source page/ });
		# if(!defined($first)) {
			# delete $item->{'first'};
		# }
		if(!defined($maiden)) {
			delete $item->{'maiden'};
		}
		if($item->{'age'} eq '') {
			delete $item->{'age'};
		}
		unless($seen{$k}) {
			push @deduped, $item;
			$seen{$k} = 1;
		} else {
			# print "$k\n";
		}
	}
	undef @queue;	# Make sure Perl really frees all memory
	undef %seen;

	my $query;

	while(my $row = pop @deduped) {
		if(!defined($query)) {
			$query = 'INSERT INTO obituaries(first, middle, last, maiden, age, place, date, newspaper, source, page) VALUES (';
		} else {
			$query .= ',(';
		}
		my %columns = %{$row};

		if($columns{'first'}) {
			if($columns{'first'} =~ /(.+)\s(.+)/) {
				# Has a middle name
				$query .= "'$1','$2',";
			} else {
				$query .= "'" . $columns{'first'} . "',NULL,";
			}
		} else {
			$query .= 'NULL,NULL,';
		}
		$query .= "'" . $columns{'last'} . "',";
		if($columns{'maiden'} && ($columns{'maiden'} ne ' ')) {
			$query .= "'" . $columns{'maiden'} . "',";
		} else {
			$query .= 'NULL,';
		}
		if($columns{'age'}) {
			$query .= $columns{'age'} . ',';
		} else {
			$query .= 'NULL,';
		}
		if($columns{'place'} && ($columns{'place'} ne '')) {
			$query .= "'" . $columns{'place'} . "',";
		} else {
			$query .= 'NULL,';
		}
		if($columns{'date'}) {
			$query .= "'" . $columns{'date'} . "',";
		} else {
			$query .= 'NULL,';
		}
		my $source = $columns{'source'};
		die $source if($source !~ /M|F|L/);
		$query .= "'" . $columns{'newspaper'} . "','" . $columns{'source'} . "','" . $columns{'page'} . "')";
	}

	undef @deduped;	# Make sure Perl really frees all memory
	# $| = 1;
	# printf "%-70s\n", $query;
	# $| = 0;

	try {
		$dbh->do($query);
	} catch {
		my @call_details = caller(0);
		die "\nError in insert ($query) called from line ",
			$call_details[2], ': ', $dbh->errstr();
	};
}

# Reduce the very large number of calls to Lingua::EN::NameCase
sub normalise_name($)
{
	my $name = shift;
	$name =~ s/\"//g;

	my $key = lc($name);

	if($normalised{$key}) {
		return $normalised{$key};
	}
	my $value = nc($name);
	$normalised{$key} = $value;
	return $value;
}

# "first","middle","last","maiden","age","place","date","url"
__DATA__
"David",,"Erickson",,92,"Stow, OH, USA","2024-01-22","https://www.beaconjournal.com/obituaries/pwoo0723808"
"Lowell","Alva","Frantz",,91,"Smithville, OH, USA","2024-02-18","https://www.the-daily-record.com/obituaries/pwoo0727773"
"McRae","David","Gordon",,74,"Little Falls, NY, USA","2024-02-23","https://www.legacy.com/us/obituaries/legacyremembers/david-mcrae-obituary?id=54446719"
"Joyce",,"Diver",,,"2024-02-16","https://funeral-notices.co.uk/notice/diver/5174279"
"Thomas","Andrew","Dlugosz",,72,"Wyandotte, MI, USA","2024-02-25","https://www.legacy.com/us/obituaries/name/thomas-dlugosz-obituary?id=54466889"
"Sheila",,"Kirkham",,,"2024-02-16","https://funeral-notices.co.uk/notice/kirkham/5174285"
"Irene",,"Caney",,,"2024-02-16","https://funeral-notices.co.uk/notice/caney/5174301"
"Irene",,"Caney",,,"2024-02-16","https://funeral-notices.co.uk/notice/caney/5174314"
"Mary",,"Clarke",,,"2024-02-16","https://funeral-notices.co.uk/notice/clarke/5174319"
"Ramesh",,"Chhabra",,,"2024-02-16","https://funeral-notices.co.uk/notice/chhabra/5174399"
"Phillip",,"Morris",,,"2024-02-16","https://funeral-notices.co.uk/notice/morris/5174455"
"Marjorie",,"Bray",96,,"2024-02-15","https://funeral-notices.co.uk/notice/bray/5174000"
"Dorothy",,"Daniels",,,"2024-02-15","https://funeral-notices.co.uk/notice/daniels/5174112"
"Malva",,"Ridge",88,,"2024-02-15","https://funeral-notices.co.uk/notice/ridge/5174115"
"Paul",,"Batchelor",60,,"2024-02-21","https://funeral-notices.co.uk/notice/batchelor/5175192"
"Pamela",,"Lambert",82,,"2024-02-24","https://funeral-notices.co.uk/notice/lambert/5175963"
"Rodney",,"Bishop",84,"Brownwood, TX, USA","2024-02-26","https://www.brownwoodnews.com/2024/02/26/rodney-dwain-bishop/"
