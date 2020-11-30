#!/usr/bin/env perl

# Create CSV from https://sites.rootsweb.com/~obituary/ and
#	https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit

use strict;
use warnings;
use DBI;
# use DBD::SQLite::Constants qw/:file_open/;	# For SQLITE_OPEN_READONLY
use File::HomeDir;
use File::Spec;
use HTML::Entities;
use HTTP::Cache::Transparent;
use LWP::ConnCache;
use LWP::UserAgent::WithCache;
use Lingua::EN::NameCase qw(nc);
use Try::Tiny;

sub freelists($$);
sub mlarchives($$);
sub queue($$$$$$$);
sub flush($);

BEGIN {
	$SIG{__WARN__} = sub {
		my $warning = shift;
		if($warning =~ /^Use of uninitialized value/) {
			die $warning;
		}
	}
}

exit if($ENV{'AUTOMATED_TESTING'});

my $dir = 'lib/Genealogy/ObituaryDailyTimes/database';
my $filename = File::Spec->catdir($dir, 'obituaries.sql');

if(!-d $dir) {
	mkdir $dir;
}

if(-r $filename) {
	# Don't bother downloading if the file is less than a day old
	exit if(-M $filename < 1);
}

my $dbh = DBI->connect("dbi:SQLite:dbname=$filename", undef, undef, { RaiseError => 1, AutoCommit => 0, synchronous => 0, locking_mode => 'EXCLUSIVE' });
if($dbh) {
	$dbh->do('CREATE TABLE obituaries(first VARCHAR, last VARCHAR NOT NULL, maiden VARCHAR, age INTEGER, place VARCHAR, newspaper VARCHAR NOT NULL, date DATE NOT NULL)');
	$dbh->do('PRAGMA cache_size = -65536');	# 64MB
	$dbh->do('PRAGMA journal_mode = OFF');
} else {
	die "obituaries.sql: $!";
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
	NoUpdate => 60 * 60 * 24,
	MaxAge => 30 * 24
}) || die "$0: $cachedir: $!";

print "This will take some time. It'd be best to go and make yourself a cup of tea.\n";

my $ua = LWP::UserAgent::WithCache->new(timeout => 10, keep_alive => 1);
$ua->env_proxy(1);
$ua->agent('Mozilla/5.0');
$ua->conn_cache()->total_capacity(undef);

# print '"last","first","maiden","age","place","newspapername","newspaperdate","tag"', "\n";

my $page = 1;
my @queue;
while(1) {
	last if(!mlarchives($ua, $page));
	$page++;
}

my $issue = 9;
while(1) {
	last if(!freelists($ua, 'v25no' . sprintf('%03d', $issue)));
	$issue++;
}

print "\n";

flush($dbh);
$dbh->commit();
$dbh->disconnect();

sub mlarchives($$) {
	my $ua = shift;
	my $page = shift;
	my $url = "https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=$page";

	$| = 1;
	printf "%-70s\r", $url;
	$| = 0;

	my $response = $ua->get($url);

	my $data;
	if($response->is_success) {
		$data = $response->decoded_content();
	} else {
		if($response->status_line() ne '404 Not Found') {
			warn "\n$url: ", $response->status_line();
		}
		return 0;
	}

	# mlarchive data is much easier to parse because it's nicely all on one line
	$data =~ s/\r//g;

	# -1 => header, 0 => post-preamble, 1 => post
	my $stage = -1;
	my @lines = split(/$/ms, $data);

	my $last_line;

	while(my $line = shift(@lines)) {
		# LAST NAME, First Name (MAIDEN); Age; Place of Death; Newspaper Name; Newspaper date; tagname

		next if((defined($last_line)) && ($line eq $last_line));
		$last_line = $line;

		$line =~ s/^\n//;
		# print "$stage: $line\n";
		if($line =~ /^------/) {
			if($stage == -1) {
				if($line =~ /No Results/) {
					# last page
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
		my $maiden;
		if($first) {
			if($first =~ /(.+)\s\((.+)\)$/) {
				$first = nc($1);
				$maiden = nc($2);
			} else {
				$first = nc($first);
			}
		}
		$last = nc($last);
		# $age //= '';

		# print "$line->>>>>>>>>>\n";
		queue($first, $last, $maiden, $age, $place, $date, $newspaper) if($last =~ /^[A-Z]/);
		# print "\"$last\",\"$first\",\"$maiden\",\"$age\",\"$place\",\"$date\",\"$newspaper\"\n" if($last =~ /^[A-Z]/);
	}
	return 1;
}

sub freelists($$) {
	my $ua = shift;
	my $issue = shift;
	my $url = "https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-$issue";

	$| = 1;
	printf "%-70s\r", $url;
	$| = 0;

	my $response = $ua->get($url);

	my $data;
	if($response->is_success) {
		$data = $response->decoded_content();
	} else {
		if($response->status_line() ne '404 Not Found') {
			warn "\n$url: ", $response->status_line();
		}
		return 0;
	}

	# print $data;
	# exit;

	$data =~ s/.*?^\-\-\-\-+<br>$//ms;
	$data =~ s/.*?^\-\-\-\-+<br>$//ms;
	# $data =~ s/(.*?)^\-\-\-\-+<br>$/$1/ms;

	my @lines = split(/<br>$/ms, $data);

	while(my $line = shift(@lines)) {
		# LAST NAME, First Name (MAIDEN); Age; Place of Death; Newspaper Name; Newspaper date; tagname

		$line =~ s/^\n//;
		last if($line =~ /^\-\-\-\-\-\-\-\-/);
		$line =~ s/&nbsp;/ /g;
		$line = decode_entities($line);
		$line =~ s/'/''/g;
		my ($name, $age, $place, $newspaper, $date, $tag) = split(/;\s?/, $line);
		if((!defined($tag)) || ($tag eq '')) {
			my $cont = shift(@lines);

			$cont =~ s/^\n//;
			last if($cont =~ /^\-\-\-\-\-\-\-\-/);
			$cont =~ s/&nbsp;/ /g;
			$cont =~ s/&gt;/>/g;
			$line =~ s/&quot;/"/g;
			$line .= $cont;
			($name, $age, $place, $newspaper, $date, $tag) = split(/;\s?/, $line);
		}
		# use Data::Dumper;
		# print __LINE__, ": $issue: ", Data::Dumper->new([split(/;\s?/, $line)])->Dump();
		next unless(defined($name));
		my ($last, $first) = split(',\s', $name);
		next unless(defined($last));

		# Parsing completely broken
		# e.g. https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-v25no010
		last unless(defined($newspaper));

		my $maiden;
		if($first) {
			if($first =~ /(.+)\s\((.+)\)$/) {
				$first = nc($1);
				$maiden = nc($2);
			} else {
				$first = nc($first);
			}
		} else {
			$first = '';
		}
		$last = nc($last);
		# $age //= '';

		# print "$line->>>>>>>>>>\n";
		# print "\"$last\",\"$first\",\"$maiden\",\"$age\",\"$place\",\"$date\",\"$newspaper\"\n" if($last =~ /^[A-Z]/);
		queue($first, $last, $maiden, $age, $place, $date, $newspaper) if($last =~ /^[A-Z]/);
	}
	return 1;
}

sub queue($$$$$$$)
{
	my ($first, $last, $maiden, $age, $place, $date, $newspaper) = @_;

	my %columns;
	$columns{'first'} = $first;
	$columns{'last'} = $last;
	if($maiden) {
		$columns{'maiden'} = $maiden;
	}
	if(defined($age) && ($age ne '')) {
		$columns{'age'} = $age;
	}
	$columns{'place'} = $place;
	if($date) {
		return unless($date =~ /^\d/);
		$columns{'date'} = $date;
	} else {
		return;	# If we don't know the date of publication, it's not easy to find
	}
	$columns{'newspaper'} = $newspaper;

	push @queue, \%columns;
}

sub flush($)
{
	my $dbh = shift;

	my $query;

	while(my $row = pop @queue) {
		if(!defined($query)) {
			$query = 'INSERT INTO obituaries(first, last, maiden, age, place, date, newspaper) VALUES (';
		} else {
			$query .= ',(';
		}
		my %columns = %{$row};

		if($columns{'first'}) {
			$query .= "'" . $columns{'first'} . "','" . $columns{'last'} . "',";
		} else {
			$query .= "NULL,'" . $columns{'last'} . "',";
		}
		if($columns{'maiden'} && ($columns{'maiden'} ne ' ')) {
			$query .= "'" . $columns{'maiden'} . "',";
		} else {
			$query .= 'NULL,';
		}
		if($columns{'age'}) {
			$query .= "'" . $columns{'age'} . "',";
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
		$query .= "'" . $columns{'newspaper'} . "')";
	}

	# $| = 1;
	# printf "%-70s\n", $query;
	# $| = 0;

	try {
		$dbh->do($query);
	} catch {
		my @call_details = caller(0);
		die "\nError in insert ($query) called from line ",
			$call_details[2], ': ', $dbh->errstr(), "\n";
	};
}
