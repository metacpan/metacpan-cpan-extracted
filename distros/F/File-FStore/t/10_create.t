#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More;
use File::Temp;
use File::Spec;

use_ok('File::FStore');

my $tempdir = File::Temp->newdir;
my $path = File::Spec->catdir($tempdir->dirname, 'store');

# Only create
my $store = eval { File::FStore->create(path => $path) };
isa_ok($store, 'File::FStore');
$store->close;


# Open:
$store = eval { File::FStore->new(path => $path) };
isa_ok($store, 'File::FStore');
$store->close;

done_testing();

exit 0;
