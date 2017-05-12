#!/usr/bin/perl 
use strict;
use warnings;

use Test::More 'no_plan';
use File::Find 'find';

my @modules;

find(
    {   no_chdir => 1,
        wanted   => sub {
            return unless $File::Find::name =~ /\.pm$/;
            push @modules, $File::Find::name;
            }
    },
    'lib'
);
for (@modules) {
    s/^.*?KinoSearch1/KinoSearch1/;
    s/\.pm$//;
    s/[^a-zA-Z1-9]+/::/g;
    eval "use_ok('" . $_ . "');";
}

