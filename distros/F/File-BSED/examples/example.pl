#!/usr/local/bin/perl
# 
# - Small example for File::BSED -
#
# Please see `perldoc File::BSED` for more information.
# The source to bin/plbsed is also a good example.
#
# $Id: example.pl,v 1.1 2007/07/16 18:10:32 ask Exp $
# $Source: /opt/CVS/File-BSED/examples/example.pl,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/07/16 18:10:32 $
use strict;
use warnings;
use File::BSED qw(
    binary_file_matches
    binary_search_replace
    string_to_hexstring
);

my $infile  = '/bin/ls';
my $outfile = 'ls.out';


# Search & replace bytes.
my $match = binary_search_replace({
    search  => "0xff",
    replace => "0xcc",
    infile  => $infile,
    outfile => $outfile,
});

die "Error: ", File::BSED::errtostr()
    if $match == -1;
print "Replaced 0xff to 0xcc in $infile to $outfile $match time(s).\n";

# Search for the string "recursive"
my $recursive_in_hex = string_to_hexstring("recursive");
my $match2 = binary_file_matches($recursive_in_hex, $infile);
die "Error: ", File::BSED::errtostr()
    if $match2 == -1;
print "The file $infile matches the string 'recursive' $match2 time(s).\n";
print "recursive in hex is: $recursive_in_hex\n";

# Remove outfile after we're done.
unlink $outfile;



