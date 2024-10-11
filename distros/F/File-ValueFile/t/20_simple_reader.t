#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 3;

use_ok('File::ValueFile::Simple::Reader');

my $in;
my $reader;

open($in, '<', \"!!ValueFile 54bf8af4-b1d7-44da-af48-5278d11e8f32 e5da6a39-46d5-48a9-b174-5c26008e208e\r\n");

ok(defined($reader = File::ValueFile::Simple::Reader->new($in)), 'Created reader');
$reader->read_to_cb(sub {});
is($reader->format->ise, 'e5da6a39-46d5-48a9-b174-5c26008e208e', 'Detected format');

exit 0;
