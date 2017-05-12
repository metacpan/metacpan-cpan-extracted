#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

use DBI;
use Dwimmer::Feed::DB;
use Data::Dumper qw(Dumper);

my %TABLES = (
	config          => [qw(key value)],
	sources         => [qw(id title url feed comment twitter status)],
	entries         => [qw(id source_id link remote_id author issued title summary content tags)],
	delivery_queue  => [qw(channel entry)],
);


main(@ARGV);
exit;

sub usage {
	die "Usage: $0 NEW_DB   OLD_DB   NAME_OF_FEED\n";
}
sub main {
	my ($new,  $old, $name, $all) = @_;

	#  [1]     The last 1 is need to import the entries as well
	$all = 1;

	usage() if not $new or not -e $new;
	usage() if not $old or not -e $old;
	usage() if not $name;

	my $old_dbh = DBI->connect("dbi:SQLite:dbname=$old", "", "", {
		FetchHashKeyName => 'NAME_lc',
		RaiseError       => 1,
		PrintError       => 0,
		AutoCommit       => 1,
	});

	if (not $all) {
		shift @{ $TABLES{sources} }; # remove id
	}

	my $db = Dwimmer::Feed::DB->new( store => $new );
	$db->connect;
	$db->addsite( name => $name );
	my $site_id = $db->get_site_id($name);
	die if not $site_id;
	$db->dbh->begin_work;

	foreach my $table ('config', 'sources', 'entries', 'delivery_queue') {
		if (not $all) {
			next if $table eq 'entries';
			next if $table eq 'delivery_queue';
		}

		#print "\n";
		#say $table;
		my $select_sql = _get_select_sql($table);
		my $insert_sql = _get_insert_sql($table);

		my $sth = $old_dbh->prepare($select_sql);
		$sth->execute;
		while (my @row = $sth->fetchrow_array) {
			#if ($table ne 'entries') {
				push @row, $site_id;
			#}
			#say "@row";
			eval {
				$db->dbh->do($insert_sql, undef, @row);
			};
			if ($@) {
				say "died on: @row";
				die $@;
			}
		}
	}
	$db->dbh->commit;
}

sub _get_select_sql {
	my $table = shift;

	my $sql = 'SELECT ' . join(', ', @{ $TABLES{$table} }) . " FROM $table";
	#say $sql;

	return $sql;
}

sub _get_insert_sql {
	my $table = shift;

	my @cols = @{ $TABLES{$table} };
	#if ($table ne 'entries') {
		push @cols, 'site_id';
	#}
	my $sql = "INSERT INTO $table (" . join(', ', @cols) . ') VALUES (';
	$sql .=  join(',', split //, '?' x @cols) . ')';
	#say $sql;

	return $sql;
}


