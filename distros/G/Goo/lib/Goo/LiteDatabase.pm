#!/usr/bin/perl

package Goo::LiteDatabase;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2004
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::LiteDatabase.pm
# Description:  Drive an SQLite database
#
# Date          Change
# ----------------------------------------------------------------------------
# 18/12/2004    Version 1
# 19/08/2005    Added method: createDatabase
# 18/10/2005    Added method: getPrimaryKey
# 18/10/2005    Created test file: GooDatabaseTest.tpm
# 18/10/2005    Added method: getTableColumns
#
##############################################################################

use strict;

use DBI;
use Data::Dumper;
use Goo::Environment;
use Goo::TrailManager;

# global database handle - set by BEGIN block
our $dbh;

$dbh->{PrintError} = 0;    # enable error checking via warn
$dbh->{RaiseError} = 0;    # enable error checking via die


###############################################################################
#
# get_connection - open a connection to the default database
#
###############################################################################

sub get_connection {

	my ($database_location) = @_;

	# store the handle in an our variable (see above)
	$dbh = DBI->connect("dbi:SQLite:dbname=$database_location", '', '')
    			    or handle_error('SQLite connect failed ', caller());

}


###############################################################################
#
# do_sql - execute some sql
#
###############################################################################

sub do_sql {

    my ($querystring, $testing) = @_;

    execute_sql($querystring, $testing);

}


###############################################################################
#
# do_query - execute sql and return the result all in one
#
###############################################################################

sub do_query {

    my ($querystring) = @_;

    my $query = execute_sql($querystring);

    return get_result_hash($query);

}


###############################################################################
#
# generate_numeric_sqlin_clause - return an sql 'in' clause with numeric values
#
###############################################################################

sub generate_numeric_sqlin_clause {

    my (@values) = @_;

    my $inclause = join(",", @values);

    return "(" . $inclause . ")";

}


###############################################################################
#
# generate_string_sqlin_clause - return an sql 'in' clause with string values
#
###############################################################################

sub generate_string_sqlin_clause {

    my (@values) = @_;

    my $inclause = join("','", @values);

    return "('" . $inclause . "')";

}


###############################################################################
#
# get_number_of_rows - return the number of rows for this statement handle
#
###############################################################################

sub get_number_of_rows {

    my ($sth) = @_;
    return $sth->rows();

}


###############################################################################
#
# get_next_row - alias for get_result_hash
#
###############################################################################

sub get_next_row {

    my ($sth) = @_;

    return $sth->fetchrow_hashref();
}


###############################################################################
#
# get_result_hash - return a hash for this result
#
###############################################################################

sub get_result_hash {

    my ($sth) = @_;

    return $sth->fetchrow_hashref();
}


###############################################################################
#
# bind_param - bind a parameter to a value
#
###############################################################################

sub bind_param {

    my ($sth, $param, $value) = @_;

    $sth->bind_param($param, $value) ||
        handle_error("failed to bind parameter: $param = $value in $sth->{statement}", caller());

}


###############################################################################
#
# prepare_sql(String s) - take a string and prepare the SQL
#
###############################################################################

sub prepare_sql {

    my ($querytext, $testmode) = @_;

    if ($testmode) { print $querytext; }

    my $sth = $dbh->prepare($querytext) ||
        handle_error("failed to prepare $querytext", caller());

    return $sth;

}


###############################################################################
#
# show_sql - display sql statement useful for debugging
#
###############################################################################

sub show_sql {

    my ($querytext) = @_;

    print $querytext. "\n";

}


###############################################################################
#
# execute_sql - take a string and execute the sql return a hash of column headings and values
#
###############################################################################

sub execute_sql {

    my ($querytext, $testmode) = @_;

    print "$querytext\n" if ($testmode);

    my $sth = prepare_sql($querytext) ||
        handle_error("error preparing $querytext", caller());

    # execute the query - if it fails pass to the error handler
    $sth->execute() || handle_error("error executing $querytext", caller());

    return $sth;

}


###############################################################################
#
# execute - execute prepared statement
#
###############################################################################

sub execute {

    my ($sth) = @_;

    # execute the query - if it fails pass to the errorHandler
    $sth->execute() ||
        handle_error("error executing $sth->{statement}", caller());

    return $sth;

}


###############################################################################
#
# get_max - return the maximum value of a database column
#
###############################################################################

sub get_max {

    my ($column, $table) = @_;

    my $row = do_query( <<EOSQL);

    	select max($column) as $column
    	from   $table

EOSQL

    return $row->{$column};

}


###############################################################################
#
# get_last_max - return the latest increment for this database handle
#
###############################################################################

sub get_last_max {

    my $row = do_query( <<EOSQL);

    	select last_insert_id() as lastmaxid

EOSQL

    return $row->{lastmaxid};

}


###############################################################################
#
# count_rows_in_table - check if a value exists in a given column and table
#
###############################################################################

sub count_rows_in_table {

    my ($table, $column, $value) = @_;

    my $query = prepare_sql( <<EOSQL);

    	select count(*) as rowcount
    	from   $table
    	where  $column = ?

EOSQL

    bind_param($query, 1, $value);
    execute($query);

    my $row = get_result_hash($query);
    return $row->{rowcount};

}


###############################################################################
#
# exists_in_table - check if a value exists in a given column and table
#
###############################################################################

sub exists_in_table {

    my ($table, $column, $value) = @_;

    return count_rows_in_table($table, $column, $value) > 0;

}


###############################################################################
#
# get_row - return a row based on a key
#
###############################################################################

sub get_row {

    my ($table, $column, $value) = @_;

    my $query = prepare_sql( <<EOSQL);

   	select	*
   	from	$table
   	where	$column = ?

EOSQL

    bind_param($query, 1, $value);
    execute($query);
    return get_result_hash($query);

}


###############################################################################
#
# get_count - return a simple row in the table
#
###############################################################################

sub get_count {

    my ($table) = @_;

    my $row = do_query("select count(*) as 'count' from $table");

    return $row->{count};

}


###############################################################################
#
# delete_row - delete a row based on a key
#
###############################################################################

sub delete_row {

    my ($table, $column, $value) = @_;

    my $query = prepare_sql( <<EOSQL);

   	delete
   	from	$table
   	where	$column = ?

EOSQL

    bind_param($query, 1, $value);
    execute($query);

}


###############################################################################
#
# quote - quote a value for insertion into the database
#
###############################################################################

sub quote {

    my ($value) = @_;

    return $dbh->quote($value);

}


###############################################################################
#
# handle_error - handle any error thrown by the dbi subsystem
#
###############################################################################

sub handle_error {

    my ($message, $calledby) = @_;

    die("[$calledby] $message \n[DB says: $DBI::err $DBI::errstr $DBI::state]");

}


###############################################################################
#
# get_primary_key - return the primary key for a table
#
###############################################################################

sub get_primary_key {

    my ($table) = @_;

    my @keys = $dbh->primary_key(undef, undef, $table);

    # assume one column primary keys
    return pop(@keys);

}


###############################################################################
#
# get_table_columns - return a list of column names for the table
#
###############################################################################

sub get_table_columns {

    my ($table) = @_;

    my $query = execute_sql("select * from $table");

    my $row = get_result_hash($query);

    return sort { $a cmp $b } keys %$row;

}


1;


__END__

=head1 NAME

Goo::LiteDatabase - Drive an SQLite database

=head1 SYNOPSIS

use Goo::LiteDatabase;

=head1 DESCRIPTION

Interface to an SQLite database.

=head1 METHODS

=over

=item get_connection

open a connection to the default database

=item do_sql

execute some SQL

=item do_query

execute SQL and return the result all in one

=item generate_numeric_sqlin_clause

return an SQL 'in' clause with numeric values

=item generate_string_sqlin_clause

return an SQL 'in' clause with string values

=item get_number_of_rows

return the number of rows for this statement handle

=item get_next_row

alias for get_result_hash

=item get_result_hash

return a hash for this result

=item bind_param

bind a parameter to a value

=item show_sql

display SQL statement useful for debugging

=item execute_sql

take a string and execute the SQL return a hash of column headings and values

=item prepare_sql

take a string and prepare the SQL for later execution

=item execute

execute prepared statement

=item get_max

return the maximum value of a database column

=item get_last_max

return the latest increment for this database handle

=item count_rows_in_table

check if a value exists in a given column and table

=item exists_in_table

check if a value exists in a given column and table

=item get_row

return a row based on a key

=item get_count

return a simple row in the table

=item delete_row

delete a row based on a key

=item quote

quote a value for insertion into the database

=item handle_error

handle any error thrown by the dbi subsystem

=item get_primary_key

return the primary key for a table

=item get_table_columns

return a list of column names for the table

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

