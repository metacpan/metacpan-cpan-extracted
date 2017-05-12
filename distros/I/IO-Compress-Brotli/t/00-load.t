#!/usr/bin/perl
use v5.14;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('IO::Compress::Brotli');
    use_ok('IO::Uncompress::Brotli');
}
