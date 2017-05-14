#!/usr/local/bin/perl

# $Id: jam_nsmail_import.pl,v 1.3 2001/08/13 20:37:01 joern Exp $

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
	$dir =~ s!/?bin/jam_nsmail_import.pl$!!;
	
	# 3. change to root dir, so paths are reached relative
	#    without more configuration stuff
	chdir $dir if $dir;

	# 4. add lib directory to module search path
	unshift @INC, "lib";
	
}

use DBI;
use JaM::Import::Netscape;
use JaM::Database;
use JaM::Folder;

$| = 1;

main: {
	my $dbh = JaM::Database->connect;

	my ($with_mails, $abort_file) = @ARGV;

	if ( not $dbh ) {
		print "Please start jam.pl first, for proper database setup!\n";
		exit 1;
	}
	
	my $nsmail = JaM::Import::Netscape->new (
		dbh => $dbh,
		abort_file => $abort_file
	);

	exit if -f $abort_file;

	$nsmail->folder_progress_callback (
		sub {
			my ($path) = @_;
			print "Create Folder: $path\n";
		}
	);

	print "Importing folder structure...\n\n";

	$nsmail->create_folders;

	exit if -f $abort_file;

	if ( $with_mails ) {
		my $last_folder_id;
		my $path;
		$nsmail->mail_progress_callback (
			sub {
				my ($folder_id, $nr) = @_;
				if ( $folder_id != $last_folder_id ) {
					$path = JaM::Folder->by_id($folder_id)->path;
					$last_folder_id = $folder_id;
				}
				$nr ||= '-';
				print "$path: $nr\n"
			}
		);

		print "Importing mails...\n\n";
		$nsmail->import_folders;
	}

	END {
		print "END\n";
		$dbh->disconnect if $dbh;
	}
}

1;
