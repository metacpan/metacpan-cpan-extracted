#!/usr/bin/perl
use strict;    # Thu May  5 20:11:02 2011
use warnings;

our $VERSION = '0.02';

use Benchmark qw/ :hireswallclock timeit cmpthese timethese timestr/;

use Geo::IP;
use Geo::IP::Record;

our @ips;

sub rand_ip {
    join '.', map { int( rand(256) ) } 1 .. 4;
}

push @ips, rand_ip() for 1 .. 1e5;

my $p = '/usr/local/share/GeoIP';

my $gi   = Geo::IP->open( "$p/GeoIP.dat",     GEOIP_STANDARD )     or die;
my $gim  = Geo::IP->open( "$p/GeoIP.dat",     GEOIP_MEMORY_CACHE ) or die;
my $gic  = Geo::IP->open( "$p/GeoIPCity.dat", GEOIP_STANDARD )     or die;
my $gicm = Geo::IP->open( "$p/GeoIPCity.dat", GEOIP_MEMORY_CACHE ) or die;
my $gi6  = Geo::IP->open( "$p/GeoIPv6.dat",   GEOIP_STANDARD )     or die;
my $gim6 = Geo::IP->open( "$p/GeoIPv6.dat",   GEOIP_MEMORY_CACHE ) or die;
my $gii  = Geo::IP->open( "$p/GeoIPISP.dat",  GEOIP_STANDARD )     or die;
my $giim = Geo::IP->open( "$p/GeoIPISP.dat",  GEOIP_MEMORY_CACHE ) or die;

my $cnt;
timethese(
    -10,
    {
        country_v6_std => sub {
            $gi6->country_code_by_addr_v6( '::' . $ips[ ++$cnt % 1e5 ] );
        },
        country_v6_mem => sub {
            $gim6->country_code_by_addr_v6( '::' . $ips[ ++$cnt % 1e5 ] );
        },
        country_std => sub {
            $gi->country_code_by_addr( $ips[ ++$cnt % 1e5 ] );
        },
        country_mem => sub {
            $gim->country_code_by_addr( $ips[ ++$cnt % 1e5 ] );
        },
        city_std => sub {
            $gic->record_by_addr( $ips[ ++$cnt % 1e5 ] );
        },
        city_mem => sub {
            $gicm->record_by_addr( $ips[ ++$cnt % 1e5 ] );
        },
        isp_std => sub {
            $gii->name_by_addr( $ips[ ++$cnt % 1e5 ] );
        },
        isp_mem => sub {
            $giim->name_by_addr( $ips[ ++$cnt % 1e5 ] );
        },
    }
);

