#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 2 + 2*4;
use File::Spec;

use_ok('File::Information');

my $instance = File::Information->new;
isa_ok($instance, 'File::Information');

foreach my $name (File::Spec->curdir, File::Spec->rootdir) {
    my $link = $instance->for_link($name);
    my $inode;

    isa_ok($link, 'File::Information::Link');

    $inode = $link->inode;
    isa_ok($inode, 'File::Information::Inode');

    ok(defined($link->get('readonly', default => undef)),  'Asking link for readonly');
    ok(defined($inode->get('readonly', default => undef)), 'Asking inode for readonly');
}

exit 0;

