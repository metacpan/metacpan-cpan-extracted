#!/usr/bin/perl

use strict;
use HTML::Table::FromDatabase;

# $Id$
# Simple usage example for HTML::Table::FromDatabase

# Normal DBI stuff to perform a query...
my $dbh = DBI->connect('dbi:mysql:test');
$sth = $dbh->prepare('select * from mytable')
    or die "Failed to prepare query - " . $dbh->errstr;
$sth->execute() or die "Failed to execute query - " . $dbh->errstr;

# Now use HTML::Table::FromDatabase:
my $table = HTML::Table::FromDatabase->new( -sth => $sth, -border => 1 );
$table->print;

