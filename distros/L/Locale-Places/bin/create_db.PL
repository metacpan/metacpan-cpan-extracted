#!/usr/bin/env perl

# Create SQLite3 from http://download.geonames.org/export/dump/GB.zip

# -f:	force a build, otherwise it won't build on CPAN smokers or if the
#	database already exists

use strict;
use warnings;
use Config;
use DBI;
use File::Copy;
use File::Spec;
use Try::Tiny;
use autodie qw(:all);

# Constants
use	constant	AIO_READAHEAD_SIZE => 1048576;	# 1MB

sub doit($$);

BEGIN {
	$SIG{__WARN__} = sub {
		my $warning = shift;
		if(($warning =~ /^Use of uninitialized value/) ||
		   ($warning =~ /Wide/) ||
		   ($warning =~ /masks earlier declaration in same scope/) ||
		   ($warning =~ /: attempt to add consecutive punctuation/) ||
		   ($warning =~ /^Odd number of elements in hash assignment/) ||
		   ($warning =~ /isn't numeric in numeric eq /i)) {
			die $warning;
		}
	}
}

my $dir = 'lib/Locale/Places/data';

my $force_flag;
if(defined($ARGV[0]) && ($ARGV[0] eq '-f')) {
	$force_flag++;
} elsif($ENV{'AUTOMATED_TESTING'}) {
	exit(0);
}

if($Config{'osname'} ne 'MSWin32') {
	require IO::AIO;
	IO::AIO->import();

	require File::Open::NoCache::ReadOnly;
	File::Open::NoCache::ReadOnly->import();
}

# Process countries
foreach my $country ('GB', 'US') {
	process_country($country);
}

sub process_country {
	my $country = shift;

	my $csv = File::Spec->catfile($dir, "$country.csv");
	my $sqlite = File::Spec->catfile($dir, "$country.sql");

	# Skip processing if SQLite file is valid and up to date
	if(should_skip_build($sqlite, $csv)) {
		return;
	}

	print "Building $sqlite\n";

	# Open CSV file
	my $fin = open_csv($csv, $Config{'osname'});

	# Connect to SQLite database
	my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlite", undef, undef, {
		RaiseError => 1,
		AutoCommit => 0,
		synchronous => 0,
		locking_mode => 'EXCLUSIVE',
	}) or die "$sqlite: $!";

	# Initialize database
	initialize_database($dbh, lc($country));

	# Process and insert data
	my $queue = doit($dbh, $fin);
	flush($dbh, lc($country), $queue);

	# Finalize database
	finalize_database($dbh, $sqlite);

	# close $fin;
}

sub should_skip_build {
	my ($sqlite, $csv) = @_;

	return 0 if($force_flag);	# -f option has been given
	return 0 unless -r $sqlite;	# SQLite file does not exist
	return 0 unless -s $sqlite;	# SQLite file is empty
	return 1 if -M $sqlite < 1;	# SQLite file is less than a day old
	return 1 if -M $sqlite < -M $csv;	# SQLite file is newer than CSV

	unlink $sqlite;	# Remove outdated SQLite file
	return 0;
}

sub open_csv {
	my ($csv, $osname) = @_;

	if($osname eq 'MSWin32') {
		open my $fin, '<', $csv or die "Failed to open $csv: $!";
		return $fin;
	}

	my $file = File::Open::NoCache::ReadOnly->new($csv) or die "Failed to open $csv: $!";
	aio_readahead($file->fd(), 0, AIO_READAHEAD_SIZE);
	return $file->fd();
}

sub initialize_database {
	my ($dbh, $table) = @_;

	$dbh->do("DROP TABLE IF EXISTS $table");
	$dbh->do(qq{
		CREATE TABLE $table (
			code1 INTEGER,
			code2 INTEGER,
			type VARCHAR(4),
			data VARCHAR NOT NULL,
			ispreferredname BIT,
			isshortname BIT
		)
	});
	$dbh->do('PRAGMA cache_size = -65536');	# 64MB
	$dbh->do('PRAGMA journal_mode = OFF');
}

sub finalize_database {
	my ($dbh, $sqlite) = @_;

	$dbh->commit();
	$dbh->disconnect();
	File::Copy::copy($sqlite, File::Spec->catfile('blib', $sqlite));
}

sub doit($$) {
	my ($dbh, $fin) = @_;

	my %queue;

	while(my $line = <$fin>) {
		chomp $line;

		my ($code1, $code2, $type, $data, $ispreferredname, $isshortname) = split(/\t/, $line);
		die "Can't parse the line '$line'" unless(defined($type));
		# next if($type eq 'link');
		# next if($type eq 'wkdt');
		# next if($type eq 'post');
		next if(length($type) != 2);

		# print __LINE__, ": $code1=>$data=>$ispreferredname\n";

		$queue{$code1} = {
			code1 => $code1,
			code2 => $code2,
			type => $type,
			data => $data,
		};
		if(length($ispreferredname)) {
			$queue{$code1}->{'ispreferredname'} = $ispreferredname;
		}
		if(length($isshortname)) {
			$queue{$code1}->{'isshortname'} = $isshortname;
		}
	}
	if(scalar(keys(%queue)) == 0) {
		die 'No entries found in the file';
	}
	print scalar(keys %queue), " entries to be added\n";
	return \%queue;
}

sub flush($$$)
{
	my ($dbh, $table, $queue) = @_;

	my $query;

	while(my ($key, $value) = each (%{$queue})) {
		delete $queue->{$key};
		if(!defined($query)) {
			$query = "INSERT INTO $table(code1, code2, type, data, ispreferredname, isshortname) VALUES (";
		} else {
			$query .= ',(';
		}

		$value->{'code1'} =~ s/'/''/g;
		$value->{'code2'} =~ s/'/''/g;
		$query .= $value->{'code1'} . ",'" . $value->{'code2'} . "',";

		if($value->{'type'} && ($value->{'type'} ne '')) {
			$query .= "'" . $value->{'type'} . "',";
		} else {
			$query .= 'NULL,';
		}
		$value->{'data'} =~ s/'/''/g;
		$query .= "'" . $value->{'data'} . "',";

		if(defined($value->{'ispreferredname'})) {
			my $ispreferredname = $value->{'ispreferredname'} ? 1 : 0;
			$query .= "$ispreferredname,";
		} else {
			$query .= 'NULL,';
		}

		if(defined($value->{'isshortname'})) {
			my $isshortname = $value->{'isshortname'} ? 1 : 0;
			$query .= "$isshortname)";
		} else {
			$query .= 'NULL)';
		}

		# use Data::Dumper;
		# print Data::Dumper->new([$value])->Dump() if($ispreferredname);
	}

	try {
		$dbh->do($query);
	} catch {
		my @call_details = caller(0);
		die "Error in insert ($query) called from line ",
		# die "Error in insert called from line ",
			$call_details[2], ': ', $dbh->errstr();
	};
}
