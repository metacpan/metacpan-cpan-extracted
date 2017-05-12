#!/usr/local/bin/perl

use warnings;
use strict;
use File::Basename;

my $me = basename( $0 );
my @tests = grep { -x $_ && !/$me$/ } <test-*.pl>;
my $x = 0;

my $OLD_STDOUT;
my $OLD_STDERR;
open( $OLD_STDOUT, '>&STDOUT');
open( $OLD_STDERR, '>&STDOUT');

select $OLD_STDOUT;
$|=1;
select $OLD_STDERR;
$|=1;
select STDOUT;

close( STDERR );
close( STDOUT );

while( $x++ < ( int($ARGV[0]) ? int($ARGV[0]) : 1 ) ) {
    foreach my $stress ( 0, 1 ) {
        foreach (@tests) {
            if ( $stress ) {
                next unless /stress/;
            } else {
                next if /stress/;
            }
            print $OLD_STDOUT "Run $x: Starting $_...";
            system("./$_");
            if ( $? ) {
                if ( $? == 2 ) {
                    print $OLD_STDERR "Caught SIGINT, exiting\n";
                } else {
                    print $OLD_STDERR "Failed to run $_, exit code " . ( ( $? >> 8 ) & 0xFF ) . "\n";
                }
                exit 1;
            }
            print $OLD_STDOUT " successful!\n";
        }
    }
}
$x--;
print $OLD_STDERR "$x runs successful!\n";
