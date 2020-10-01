#!/usr/bin/env perl

use strict;
use warnings;

use DBI;

# ---------------

if (! $ENV{DBI_DSN})
{
	print "Exiting because \$DBI_DSN is not set. \n";

	exit 0;
}

my($table)             = shift || die "Usage $0 name_of_table\n";;
my($attr)              = {};
$$attr{sqlite_unicode} = 1 if ($ENV{DBI_DSN} =~ /SQLite/i);
my($dbh)               = DBI -> connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, $attr);

$dbh -> do('PRAGMA foreign_keys = ON') if ($ENV{DBI_DSN} =~ /SQLite/i);

my($row_ara) = $dbh -> selectall_arrayref("pragma foreign_key_list($table)");
my(@name)    = (qw/COUNT KEY_SEQ FKTABLE_NAME PKCOLUMN_NAME FKCOLUMN_NAME UPDATE_RULE DELETE_RULE NONE/);

print "Table: $table. Foreign keys: \n";

for my $row (@$row_ara)
{
	for my $field_count (0 .. $#$row)
	{
		print "$name[$field_count] => $$row[$field_count]. \n";
	}

	print "\n";
}

