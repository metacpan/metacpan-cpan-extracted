#!/usr/bin/perl

use v5.10.1;
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Require::AuthorTesting;
use File::Find;

BEGIN {
    my @files;
    find(sub { push @files, $File::Find::name if /\.pm$/}, 'lib');

    my @modules = map { s!^lib/|\.pm$!!g; s!/!::!g; $_ } @files;
    plan tests => scalar @modules;
    foreach my $module (@modules) {
        my $ok = eval "use $module; 1";
        ok $ok, "$module compiles", $@;
    }
};

done_testing;
