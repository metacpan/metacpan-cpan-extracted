#!/usr/bin/perl -w

# Example of an EekBoek application.

# Author          : Johan Vromans
# Created On      : Sun Apr 13 17:25:07 2008
# Last Modified By: Johan Vromans
# Last Modified On: Wed Jan 23 13:31:52 2013
# Update Count    : 97
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# EekBoek modules.

use EekBoek;		# optional (but we'll use $PACKAGE)
use EB;			# common

################ Presets ################

binmode( STDOUT, ':encoding(utf-8)' );

################ The Process ################

#### W A R N I N G #### W A R N I N G #### W A R N I N G #####
#
# Querying the database may give unexpected results except for
# trivial things like names of customers, grootboekrekeningen.
#
################ ################ ################ ###########

# Initialise.
# The app name passed will be used for the config files,
# e.g., Foo -> /etc/foo.conf, ~/.foo/foo.conf, ./.foo.conf
# By using $EekBoek::PACKAGE we'll use the standard EekBoek
# config files.
my $eb = EB->app_init( { app => $EekBoek::PACKAGE,
			 config => "eekboek.conf",	# local
		       } );

# Connect to the data base.
# Returns the database handle.
# NOTE: This is not a DBI object!
my $dbh = $eb->connect_db;

# SQL query.
my $sql =
  "SELECT acc_id, acc_desc, acc_balres".
  " FROM Accounts".
  " ORDER BY acc_id";

# Parse SQL and execute.
my $sth = $dbh->sql_exec($sql);

# Bind result columns.
$sth->bind_columns(\my($acc_id, $acc_desc, $acc_balans));

# Fetch results.
while ( $sth->fetch ) {
    # Print balansrekeningen.
    printf("%5d %s\n", $acc_id, $acc_desc) if $acc_balans;
}
