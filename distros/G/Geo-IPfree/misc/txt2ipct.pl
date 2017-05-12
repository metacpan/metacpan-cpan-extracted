#!/usr/bin/perl

use strict;
use warnings;

require Geo::IPfree;
use IO::Handle;

##################################
# CONVERT TXT TO IPSCOUNTRY.DAT  #
##################################

my $in_fname  = $ARGV[ 0 ] || './ips-ascii.txt';
my $out_fname = $ARGV[ 1 ] || './ipscountry.dat';

my $HEADERS_BLKS = 256;

if ( !@ARGV || $ARGV[ 0 ] =~ m{^-[h?]}i ) {
    print qq`This tool will convert the ASCII database (from ipct2txt)
to Geo::IPfree dat file.

    USAGE: perl $0 ./ips-ascii.txt ./ipscountry.dat
`;

    exit;
}

print "Reading ${in_fname} ...\n";

open( my $in_fh, $in_fname ) or die "unable to open '${in_fname}': $!";

my @DB;
while ( my $line = <$in_fh> ) {
    my ( $country, $ip ) = $line =~ m{^([\w-]{2}):\s+(\d+\.\d+\.\d+\.\d+)}gs;

    my $range   = Geo::IPfree::ip2nb( $ip );
    my $iprange = Geo::IPfree::dec2baseX( $range );

    unshift( @DB, "${country}${iprange}" );
}
close( $in_fh );

my %headers;
my $c   = 0;
my $pos = 0;
my $blk_sz = int( @DB / $HEADERS_BLKS );

print "BLK size: $blk_sz\n";

foreach my $DB_i ( @DB ) {
    if ( $c == 0 ) {
        my $iprange = substr( $DB_i, 2 );
        my $range = Geo::IPfree::baseX2dec( $iprange );
        $headers{ $range } = $pos;
    }
    $c++;

    if ( $c >= $blk_sz ) { $c = 0; }
    $pos += 7;
}

print "Saving ${out_fname} ...\n";

open( my $out_fh, '>', $out_fname ) or die "unable to open '${out_fname}': $!";
$out_fh->autoflush( 1 );

my $date = get_date();

print $out_fh
    qq`###############################################################
## IPs COUNTRY DATABASE ($date)                ##
###############################################################
## This is the database used in the Perl module Geo::IPfree. ##
##                                                           ##
## FORMAT:                                                   ##
##                                                           ##
##   the DB has a list of IP ranges & countrys, for          ##
##   example, from 200.128.0.0 to 200.103.255.255 the IPs    ##
##   are from BR. To make a fast access to the DB the        ##
##   format try to use less bytes per input (block). The     ##
##   file was in ASCII and in blocks of 7 bytes: XXnnnnn     ##
##                                                           ##
##     XX    -> the country code (BR,US...)                  ##
##     nnnnn -> the IP range using a base of 85 digits       ##
##              (not in dec or hex to get space).            ##
##                                                           ##
##  To convert this file back to plain text, see the         ##
##  ipct2txt.pl script shipped with Geo-IPfree.              ##
##                                                           ##
## Check CPAN for updates...                                 ##
###############################################################
`;

my $header = join( '#', map { "$_=$headers{$_}" } sort { $b <=> $a } keys %headers );
print $out_fh "\n##headers##" . length( $header ) . "##${header}";
print $out_fh "\n\n##start##";
print $out_fh $_ for @DB;
close( $out_fh );

print "Done.\n";

sub get_date {
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime( time );

    return sprintf( '%d-%02d-%02d %02d:%02d:%02d', $year + 1900, $mon + 1, $mday, $hour, $min, $sec );
}
