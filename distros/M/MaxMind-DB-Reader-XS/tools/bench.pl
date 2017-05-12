#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(:all);
use Sys::Hostname;
our $VERSION = '0.01';

my @ips = map {
    join '.',
        map { int( rand(256) ) } 1 .. 4
} ( 1 .. 5_000 );
my $max_ips = $#ips;

use MaxMind::DB::Reader;
use MaxMind::DB::Reader::XS;

my $file = '/usr/local/share/GeoIP2/GeoIP2-City.mmdb';

my $reader = MaxMind::DB::Reader->new( file => $file ) or die;
my $reader_xs = MaxMind::DB::Reader::XS->new( file => $file ) or die;

my $fast_reader_xs = MaxMind::DB::Reader::XS->open( $file, 2 ) or die;

#use Data::Dumper;
#print Dumper( $fast_reader_xs->lookup_by_ip('24.24.24.24') );

my ( $reader_idx, $reader_xs_idx, $fast_reader_xs_idx ) = ( 0, 0, 0 );

print scalar(localtime), ' ', hostname, "\n";
print "MaxMind::DB::Reader     ", $MaxMind::DB::Reader::VERSION,     "\n";
print "MaxMind::DB::Reader::XS ", $MaxMind::DB::Reader::XS::VERSION, "\n";
print "libmaxminddb            ", MaxMind::DB::Reader::XS->lib_version, "\n";

cmpthese(
    -5,
    {
        'reader' => sub {
            eval {
                $reader->record_for_address(
                    $ips[ $reader_idx++ % $max_ips ] );
            };
        },
        'reader_xs' => sub {
            eval {
                $reader_xs->record_for_address(
                    $ips[ $reader_xs_idx++ % $max_ips ] );
            };
        },
        'fast_reader_xs' => sub {
            eval {
                $fast_reader_xs->lookup_by_ip(
                    $ips[ $fast_reader_xs_idx++ % $max_ips ] );
            };
        },
    }
);

__END__

perl -Mblib ./benchmark/bench.pl

          s/iter    reader reader_xs
reader      42.1        --     -100%
reader_xs  0.104    40379%        --
