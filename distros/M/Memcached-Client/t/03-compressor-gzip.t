#!/usr/bin/perl

use Memcached::Client::Compressor::Gzip;
use Compress::Zlib qw{};
use Test::More tests => 10;

my $compressor;

isa_ok ($compressor = Memcached::Client::Compressor::Gzip->new,
        'Memcached::Client::Compressor::Gzip',
        'Create a new instance of the ::Gzip class');

is ($compressor->compress,
    undef,
    '->compress should return undef since we gave it nothing to compress');

is ($compressor->decompress,
    undef,
    '->decompress should return undef since we gave it nothing to decompress');

is_deeply ([$compressor->compress ('foo', 0)],
           ['foo', 0],
           '->compress should return the simple tuple since it is so short');

is_deeply ([$compressor->decompress ('foo', 0)],
           ['foo', 0],
           '->decompress should return the same structure since it was not compressed');

my $longstring = 'a' x 20000;

my $longgzip = Compress::Zlib::memGzip $longstring;

is_deeply ([$compressor->compress ($longstring, 0)],
           [$longstring, 0],
           '->compress a very long repetitive string with no threshold');

is_deeply ([$compressor->decompress ($longstring, 0)],
           [$longstring, 0],
           '->decompress a very long repetitive string with no threshold, compare');

is ($compressor->compress_threshold (10000), 0, 'Set the compress threshold');

is_deeply ([$compressor->compress ($longstring, 0)],
           [$longgzip, 2],
           '->compress a very long repetitive string');

is_deeply ([$compressor->decompress ($longgzip, 2)],
           [$longstring, 2],
           '->decompress a very long repetitive string, compare');
