#!/usr/local/bin/perl

# $Id: jam_dropmail.pl,v 1.2 2001/08/13 20:37:01 joern Exp $

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
	$dir =~ s!/?bin/jam_dropmail.pl$!!;
	
	# 3. change to root dir, so paths are reached relative
	#    without more configuration stuff
	chdir $dir if $dir;

	# 4. add lib directory to module search path
	unshift @INC, "lib";
	
}

use DBI;
use JaM::Drop;
use JaM::Database;

main: {
	my $fh = \*STDIN;

	my $dbh = JaM::Database->connect;

	if ( not $dbh ) {
		print "Please start jam.pl first, for proper database setup!\n";
		exit 1;
	}
	
	$JaM::Drop::VERBOSE = 1;
	my $mailer = JaM::Drop->new (
		fh  => $fh,
		dbh => $dbh,
	);
	
	$mailer->drop_mails;
	
	END { $dbh->disconnect if $dbh }
}
