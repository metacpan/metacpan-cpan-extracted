#!/usr/bin/perl

use strict;
use warnings;

require Geo::IPfree;

##################################
# CONVERT IPSCOUNTRY.DAT TO TXT  #
##################################

my $in_fname  = $ARGV[ 0 ] || './ipscountry.dat';
my $out_fname = $ARGV[ 1 ] || './ips-ascii.txt';

if ( !@ARGV || $ARGV[ 0 ] =~ m{^-[h?]}i ) {
    print qq`This tool will convert a Geo::IPfree dat file to ASCII.

    USAGE: perl $0 ./ipscountry.dat ./ips-ascii.txt
`;

    exit;
}

print "Reading ${in_fname} ...\n";

open( my $in_fh, $in_fname ) or die "unable to open '${in_fname}': $!";

my $buffer = '';
sysread( $in_fh, $buffer, 1, length( $buffer ) ) while $buffer !~ m{##start##$}s;

my @IPS;
while ( sysread( $in_fh, $buffer, 7 ) ) {
    my $country = substr( $buffer, 0, 2 );
    my $iprange = substr( $buffer, 2 );

    my $range   = Geo::IPfree::baseX2dec( $iprange );
    my $ip      = Geo::IPfree::nb2ip( $range );
    my $ip_prev = Geo::IPfree::nb2ip( $range - 1 );

    push( @IPS, $country, $ip, $ip_prev );
}

close( $in_fh );

print "Saving ${out_fname} ...\n";

my @OUT;

for ( my $i = 0; $i <= $#IPS; $i += 3 ) {
    my $ct     = $IPS[ $i ];
    my $ip     = $IPS[ $i + 1 ];
    my $ipprev = $IPS[ $i - 1 ];

    if ( $ip ne '1.0.0.0.0' && $ct =~ /[\w-]{2}/ ) {
        push( @OUT, "$ct: $ip $ipprev" );
    }
}

open( my $out_fh, '>', $out_fname ) or die "unable to open '${out_fname}': $!";
print $out_fh join( "\n", reverse @OUT );
close( $out_fh );

print "Done.\n";
