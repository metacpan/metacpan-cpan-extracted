#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Cwd;
use File::Copy;
use lib '../lib';
use EBook::Generator;

my $generator = EBook::Generator->new();

foreach my $url (@ARGV) {
	my $filename = $generator->processSource($url, "pdf",
			'local-tex-tree-path' => getcwd().'/../texmf',
		);
	unless (defined $filename) {
		print "FAIL $url\n";
		next;
	}

	# copy file into special directory inside webroot
	my $ebook_filename = $filename;
		 $ebook_filename =~ s/^.*\///g;
		 $ebook_filename = getcwd().'/ebooks/'.$ebook_filename;		 
	copy($filename, $ebook_filename);
	unlink($filename);
	
	$ebook_filename =~ s/^.*\///g;
	$ebook_filename = '/ebooks/'.$ebook_filename;
	
	print "\nCreated $ebook_filename\n";
}
