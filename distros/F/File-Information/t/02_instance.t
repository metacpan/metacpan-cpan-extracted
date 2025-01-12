#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 4;

use_ok('File::Information');

my $instance = File::Information->new;
isa_ok($instance, 'File::Information');
my @digest_info = $instance->digest_info;
ok(scalar(@digest_info), 'Found digests');
my @lifecycles = $instance->lifecycles;
ok(scalar(@lifecycles), 'Found lifecycles');

exit 0;
