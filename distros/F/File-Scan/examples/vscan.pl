#!/usr/bin/perl

use File::Scan;
use File::Find::Rule;
use MIME::Parser;
use strict;

# Make sure we have an output directory...

	mkdir('/tmp/radioactive') unless ( -d '/tmp/radioactive' );
	mkdir("/tmp/radioactive/$$") unless ( -d "/tmp/radioactive/$$" );
	`rm -Rf /tmp/radioactive/$$/*`;

# Read in the message

	my $parser = new MIME::Parser;
	$parser->output_under("/tmp/radioactive/$$");
	$parser->parse( \*STDIN ) or die "Failed to parse message!";

# Grab all files...

	my @files = File::Find::Rule->file()->in( "/tmp/radioactive/$$/" );

	for my $filename (@files) {

		my $nice_filename = $filename;
		$nice_filename =~ s!.+/!!;

		print "Scanning $nice_filename...\n";

		my $scanner = File::Scan->new();
		my $vname = $scanner->scan( $filename );

		print "\tFOUND: $vname\n" if $vname;

	}

# Cleanup

	END { `rm -Rf /tmp/radioactive/$$`  }
