#!/usr/bin/perl
# A simple example script on how to use IMDB::JSON to lookup movie data
# against the internet movie database (www.imdb.com)

use IMDB::JSON;
use Data::Dumper;

my $IMDB = IMDB::JSON->new;

if($ARGV[0] =~ /^(tt\d+)$/){
	print Dumper($IMDB->byid($1));
} elsif($ARGV[0] && $ARGV[1] =~ /^\d{4}$/){
	print Dumper($IMDB->search($ARGV[0], $ARGV[1]));
} else {
	print qq{usage: $0 <imdb_id>
       $0 "Movie Title" "year"\n};
}

exit;

