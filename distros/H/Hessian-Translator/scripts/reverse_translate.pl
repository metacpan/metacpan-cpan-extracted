#!/usr/bin/perl

use strict;
use warnings;
use version; our $VERSION = qv('0.0.1');
use Math::BigInt try => 'GMP';
use DateTime;
use DateTime::Format::Epoch::Unix;
use Time::TAI64 qw/:tai64n/;

binmode( STDOUT, "utf8" );

use Math::Int64 qw/int64 net_to_int64 int64_to_net/;

# Hex string sequence on Specification website
my @date_array_from_spec = qw/x00 x00 x00 xd0 x4b x92 x84 xb8/;
my @unhexed_values = map { hex $_ } @date_array_from_spec;
my $bytes_input = "\x00\x00\x00\xd0\x4b\x92\x84\xb8";
print "Byte input = $bytes_input\n";

my @unpacked_input = unpack 'CCCCCCCC', $bytes_input;
print "Unpacked input = @unpacked_input\n";

# don't know what this is

my $int       = Math::BigInt->new(0);
my $shift_val = 0;
foreach my $bit_pos ( reverse @unpacked_input) {
    my $to_shift = Math::BigInt->new($bit_pos);
    if ( $bit_pos) {
        
        print "To shift is: ".$to_shift." shifted by ".$shift_val."\t" if $bit_pos;

        $to_shift->blsft($shift_val);
        print "by: $to_shift\n";
    }

    $int->bxor($to_shift);
    $shift_val += 8;
}
$int->bdiv(1000);
print "Integer is: ".$int."\n";
print "Integer as hex: ".$int->as_hex()."\n";


my $formatter = DateTime::Format::Epoch::Unix->new();
my $dt = $formatter->parse_datetime("".$int);
my $dt2 = DateTime->from_epoch(epoch => "".$int);
$dt->set_time_zone('UTC');
print "Date: " . $dt . "\n";
print "Date: ".$dt2."\n";
my $original_string = pack( 'nnnnnnnn', @unhexed_values );
print "Original string: " . $original_string . "\n";

my @unpacked_again = unpack 'LLLL', $original_string;
print "Unpacked array: @unpacked_again\n";

