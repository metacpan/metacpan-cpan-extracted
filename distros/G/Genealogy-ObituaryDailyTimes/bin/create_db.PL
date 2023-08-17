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
	}
}

my $force_flag;
if(defined($ARGV[0]) && ($ARGV[0] eq '-f')) {
	$force_flag++;
} elsif($ENV{'AUTOMATED_TESTING'}) {
	exit;
}

my $dir = 'lib/Genealogy/ObituaryDailyTimes/database';
my $filename = File::Spec->catdir($dir, 'obituaries.sql');
my %normalised;

if(!-d $dir) {
	mkdir $dir, 0755;
}

if(-r $filename) {
	# Don't bother building if the current file is less than a day old
	if(((-s $filename) > 0) && (-M $filename < 1) && !$force_flag) {
		exit;
	}
	unlink $filename;
}

my $cachedir = $ENV{'CACHEDIR'};
if($cachedir) {
	mkdir $cachedir, 0700 if(!-d $cachedir);
	$cachedir = File::Spec->catfile($cachedir, 'http-cache-transparent');
} else {
	$cachedir = File::Spec->catfile(File::HomeDir->my_home(), '.cache', 'http-cache-transparent');
}

HTTP::Cache::Transparent::init({
	BasePath => $cachedir,
	Verbose => 0,
	NoUpdate => 60 * 60 * 24 * 7 * 31,	# The archive never changes
	MaxAge => 30 * 24
}) || die "$0: $cachedir: $!";

print "This will take some time. It'd be best to go and make yourself a cup of tea.\n";

my $ua = LWP::UserAgent::WithCache->new(timeout => 10, keep_alive => 1);
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
my $page = 1;
while(mlarchives($ua, $page)) {
	$page++;
	flush($dbh) if(scalar(@queue) > 200_000);
};

print ' ' x 78, "\r";

flush($dbh);

my $issue = 9;
while(freelists($ua, 'v25no' . sprintf('%03d', $issue))) {
	$issue++;
}

flush($dbh);

$issue = 1;
while(freelists($ua, 'v26no' . sprintf('%03d', $issue))) {
	$issue++;
	if($issue == 52) {
		$issue++;	# https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v26no052 doesn't exist
	}
}

flush($dbh);

$issue = 1;
while(freelists($ua, 'v27no' . sprintf('%03d', $issue))) {
	$issue++;
}

flush($dbh);

$issue = 1;
while(freelists($ua, 'v28no' . sprintf('%03d', $issue))) {
	$issue++;
}

print "\n";

flush($dbh);

$dbh->commit();
$dbh->prepare('CREATE INDEX name_index ON obituaries(first, last)')->execute();
$dbh->do('pragma optimize');
$dbh->disconnect();

sub mlarchives($$) {
	my @lines;

	my $url = "https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=$page";

	$| = 1;
	printf "%-70s\r", $url;
	$| = 0;

	if($ENV{'MLARCHIVEDIR'}) {
		@lines = read_file(File::Spec->catfile($ENV{'MLARCHIVEDIR'}, "emails?listname=gen-obit&page=$page"));
	} elsif($ENV{'MLARCHIVE_DIR'}) {
		@lines = read_file(File::Spec->catfile($ENV{'MLARCHIVE_DIR'}, "emails?listname=gen-obit&page=$page"));
	} else {
		my $ua = shift;
		my $page = shift;

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

	# -1 => header, 0 => post-preamble, 1 => post
	my $stage = -1;

	my $last_line;
	my $rc;

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
					return 0;
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
			next;
		} elsif($stage == -1) {
			if($line =~ /^LAST NAME/) {
				# The ----- probably didn't start a line
				# e.g. https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=41
				$stage = 0;
			} elsif($line =~ /Re: \[GEN-OBIT\]/) {
				# It's a reply to a post, not an actual post
				# e.g. https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=46
				return 1;
			} elsif($line =~ /No Results/) {
				# Last page
				return 0;
			}
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
		queue($first, normalise_name($last), $maiden, $age, $place, $date, $newspaper, 'M', $page) if($last =~ /^[A-Z]/);
		# print "\"$last\",\"$first\",\"$maiden\",\"$age\",\"$place\",\"$date\",\"$newspaper\"\n" if($last =~ /^[A-Z]/);
		$rc = 1;
	}
	die "Couldn't parse $url" if(!defined($rc));
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

	die $source if(($source ne 'F') && ($source ne 'M'));

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
	my %seen;
	my @deduped;

	foreach my $item(@queue) {
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
		die $source if(($source ne 'F') && ($source ne 'M'));
		$query .= "'" . $columns{'newspaper'} . "','" . $columns{'source'} . "','" . $columns{'page'} . "')";
	}

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
	@queue = ();	# Make sure Perl really frees all memory
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
