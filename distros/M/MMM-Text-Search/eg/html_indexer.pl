#!/usr/bin/perl
#$Id: html_indexer.pl,v 1.2 1999/04/25 18:05:26 maxim Exp $
use strict;
use MMM::Text::Search;
# index all txt and html files in the specified directory hierarchy
# '.search.db' and '.search.db-*' files are created

my $dir = $ARGV[0];

if (! -d $dir ) {
	die "Usage: $0 directory \n";
}
if (! -w $dir ) {
	die "Directory '$dir' is not writable.\n";
}
my $dbname = '.search.db';
my $dbpath = $dir."/".$dbname;


my $search = new MMM::Text::Search {	IndexDB  => $dbpath,
					FileMask => '(?i)\.(.?htm.?|txt)',
					Dirs	 => [ $dir ],
					Verbose	 => 1 			};


$search->makeindex;





				
	

