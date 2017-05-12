#!/usr/bin/perl -w
#########################################
#
# Dirbuster::Parser v0.1 
#
#########################################

use strict;
use Dirbuster::Parser;
use Getopt::Long;
use vars qw( $PROG );
( $PROG = $0 ) =~ s/^.*[\/\\]//;    # Truncate calling path from the prog name

my $dparser = new Dirbuster::Parser;
my $file;

sub usage {
    print "usage: $0 [file.xml]\n";
    exit;
}
if ( $ARGV[0] ) {
    $file = $ARGV[0];
}
else {
    usage;
}

my $parser = $dparser->parse_file("$file");

print "Directories:\n";
foreach my $h ( grep($_->type eq 'Dir', $parser->get_all_results() ) ) {
    print "Type: " . $h->type . "\n";
    print "Path: " . $h->path . "\n";
    print "Response Code: " . $h->response_code . "\n";
}
