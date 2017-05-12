#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(:all);
our $VERSION = '0.01';

my @ips = map {
    join '.',
        map { int( rand(256) ) } 1 .. 4
} ( 1 .. 5_000 );

use MaxMind::DB::Reader;
use MaxMind::DB::Reader::XS;
use Data::Dumper;
use Data::Compare;

my $file = '/usr/local/share/GeoIP2/city-v6.db';

my $reader = MaxMind::DB::Reader->new( file => $file ) or die;
my $reader_xs = MaxMind::DB::Reader::XS->new( file => $file ) or die;

for my $ip (@ips) {

    # reader dies unfortunately for private IP's
    my $r = eval { $reader->record_for_address($ip) };
    my $rxs = $reader_xs->record_for_address($ip);

    unless ( Compare( $r, $rxs ) ) {

        print "reader and reader_xs results differ for $ip\n";
        print Dumper($r);
        print Dumper($rxs);

        #    exit;

    }
}
