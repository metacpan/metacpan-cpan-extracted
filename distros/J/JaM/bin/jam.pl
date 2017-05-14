#!/usr/local/bin/perl

# $Id: jam.pl,v 1.33 2002/03/08 10:55:15 joern Exp $

package JaM;

$VERSION = "1.0.10";

use strict;

BEGIN {
	# find root directory of this JaM installation
	
	# 1. evtl. resolve symbolic link
	my $file = $0;
	while ( -l $file ) {
		my $new_file = readlink $file;
		if ( $new_file =~ m!^/! ) {
			$file = $new_file;
		} else {
			$file =~ s!/[^/]+$!!;
			$file = "$file/$new_file";
		}
	}
		
	# 2. derive root directory from program path
	my $dir = $file;
	$dir =~ s!/?bin/jam.pl$!!;
	
	# 3. change to root dir, so paths are reached relative
	#    without more configuration stuff
	chdir $dir if $dir;

	# 4. add lib directory to module search path
	unshift @INC, "lib";
	
}

use JaM::GUI;
use JaM::Database;
use JaM::GUI::Init;
use DBI;

main: {
	# connect to database
	my $dbh = JaM::Database->connect;

	# connection error?
	JaM::GUI::Init->db_configuration if not $dbh;

	# check database schema version
	JaM::GUI::Init->check_schema_version ( dbh => $dbh );

	# set debugging level
	my $debug = shift @ARGV;
	JaM::GUI->debug_level ($debug);

	# create GUI object
	my $gui = JaM::GUI->new (
		dbh => $dbh,
	);
	
	# start GUI
	$gui->start;

	# disconnect from database
	END { $dbh->disconnect if $dbh }
}

