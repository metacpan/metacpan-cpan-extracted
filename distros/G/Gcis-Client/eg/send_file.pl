#!/usr/bin/env perl

use Gcis::Client;
use v5.14;

# Sample usage :
# 
# ./send_file.pl http://localhost:3000 /report/files/nca1/nca1.pdf /tmp/nca1.pdf
#
# Notes :
#     If a report has two files, they are assumed to be low and high resolution PDFs.
#     Be sure to include the filename in the path (second argument above).
#

my ($url,$path,$filename) = @ARGV;

die "usage : $0 <url> <path> <filename>" unless $filename;

-e $filename or die "$filename does not exist";

my $g = Gcis::Client->new->connect(url => $url);

$g->put_file($path, $filename) or die $g->error;

say $g->tx->res->body;



