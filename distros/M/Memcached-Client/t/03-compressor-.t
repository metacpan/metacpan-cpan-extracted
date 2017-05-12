#!/usr/bin/perl

use Memcached::Client::Compressor;
use Test::More tests => 7;

ok (my $compressor = Memcached::Client::Compressor->new, 'Create a new instance of the abstract base class');
is (eval {$compressor->compress}, undef, 'Watch ->compress fail');
ok ($@, 'Make sure it did fail');
is (eval {$compressor->decompress}, undef, 'Watch ->decompress fail');
ok ($@, 'Make sure it did fail');
is ($compressor->compress_threshold (10000), 0, 'Check default compress_threshold');
is ($compressor->compress_threshold, 10000, 'Check recently set compress_threshold');

