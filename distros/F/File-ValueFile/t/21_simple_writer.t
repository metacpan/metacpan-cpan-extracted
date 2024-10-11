#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 3;

use_ok('File::ValueFile::Simple::Writer');

my $in;
my $writer;
my $storage = '';

open($in, '>', \$storage);

ok(defined($writer = File::ValueFile::Simple::Writer->new($in, format => 'e5da6a39-46d5-48a9-b174-5c26008e208e')), 'Created writer');
$writer->write('');
like($storage, qr/^!!ValueFile 54bf8af4-b1d7-44da-af48-5278d11e8f32 e5da6a39-46d5-48a9-b174-5c26008e208e[\r\n ]/, 'Wrote magic');

exit 0;
