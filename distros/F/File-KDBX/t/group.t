#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Group;
use File::KDBX;
use Test::More;

subtest 'Path' => sub {
    my $kdbx = File::KDBX->new;
    my $group_a = $kdbx->add_group(name => 'Group A');
    my $group_b = $group_a->add_group(name => 'Group B');
    is $kdbx->root->path, 'Root', 'Root group has path';
    is $group_a->path, 'Group A', 'Layer 1 group has path';
    is $group_b->path, 'Group A.Group B', 'Layer 2 group has path';
};

done_testing;
