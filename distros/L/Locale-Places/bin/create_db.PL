#!/usr/bin/env perl

# Create SQLite3 from http://download.geonames.org/export/dump/alternatenames/GB.zip

use strict;
use warnings;
use Config;
use DBI;
use File::Copy;
use File::Spec;
use Try::Tiny;
use autodie qw(:all);

use	constant	AIO_READAHEAD_SIZE => 1048576;	# 1MB

sub doit($$);

BEGIN {
	$SIG{__WARN__} = sub {
		my $warning = shift;
		if($warning =~ /^Use of uninitialized value/) {
			die $warning;
		}
	}
}

exit if($ENV{'AUTOMATED_TESTING'});

if($Config{'osname'} ne 'MSWin32') {
	require IO::AIO;
	IO::AIO->import();

	require File::Open::NoCache::ReadOnly;
	File::Open::NoCache::ReadOnly->import();
}

my $dir = 'lib/Locale/Places/databases';
my $csv = File::Spec->catdir($dir, 'GB.csv');
my $sqlite = File::Spec->catdir($dir, 'GB.sql');

if(-r $sqlite) {
	if((-s $sqlite) > 0) {
		# Don't bother downloading if the file is less than a day old
		exit if(-M $sqlite < 1);
	}
	unlink $sqlite;
}

my $fin;
if($Config{'osname'} eq 'MSWin32') {
	open($fin, '<', $csv);
} else {
	$csv = File::Open::NoCache::ReadOnly->new($csv);
	$fin = $csv->fd();
	aio_readahead($fin, 0, AIO_READAHEAD_SIZE);
}

if(my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlite", undef, undef, { RaiseError => 1, AutoCommit => 0, synchronous => 0, locking_mode => 'EXCLUSIVE' })) {
	$dbh->do('CREATE TABLE gb(code1 INTEGER, code2 INTEGER, type VARCHAR(4), data VARCHAR NOT NULL, ispreferredname BIT)');
	# keys
	# if($place = $self->{'gb'}->fetchrow_hashref({ type => $from, data => $place })) {
		# if(my $line = $self->{'gb'}->fetchrow_hashref({ type => $to, code2 => $place->{'code2'} })) {
	$dbh->do('PRAGMA cache_size = -65536');	# 64MB
	$dbh->do('PRAGMA journal_mode = OFF');

	my $queue = doit($dbh, $fin);

	$csv = undef;

	flush($dbh, $queue);
	$dbh->commit();
	$dbh->disconnect();

	File::Copy::copy($sqlite, File::Spec->catfile('blib', $sqlite));
} else {
	die "$sqlite: $!";
}

sub doit($$) {
	my ($dbh, $fin) = @_;

	my %queue;

	while(my $line = <$fin>) {
		chomp $line;

		my ($code1, $code2, $type, $data, $ispreferredname) = split(/\t/, $line);
		next if($type eq 'link');
		next if($type eq 'wkdt');

		# print __LINE__, ": $code1=>$data=>$ispreferredname\n";

		$queue{$code1} = {
			code1 => $code1,
			code2 => $code2,
			type => $type,
			data => $data,
			ispreferredname => $ispreferredname
		};
	}
	return \%queue;
}

sub flush($)
{
	my ($dbh, $queue) = @_;

	my $query;

	while(my ($key, $value) = each (%{$queue})) {
		if(!defined($query)) {
			$query = 'INSERT INTO gb(code1, code2, type, data, ispreferredname) VALUES (';
		} else {
			$query .= ',(';
		}
		# use Data::Dumper;
		# print Data::Dumper->new([$value])->Dump();

		$query .= $value->{'code1'} . ',' . $value->{'code2'} . ',';

		if($value->{'type'} && ($value->{'type'} ne '')) {
			$query .= "'" . $value->{'type'} . "',";
		} else {
			$query .= 'NULL,';
		}
		$value->{'data'} =~ s/'/''/g;
		my $ispreferredname = $value->{'ispreferredname'} ? 1 : 0;
		$query .= "'" . $value->{'data'} . "',$ispreferredname)";
		# use Data::Dumper;
		# print Data::Dumper->new([$value])->Dump() if($ispreferredname);
	}

	try {
		$dbh->do($query);
	} catch {
		my @call_details = caller(0);
		die "Error in insert ($query) called from line ",
			$call_details[2], ': ', $dbh->errstr();
	};
}
