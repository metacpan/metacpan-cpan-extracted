#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.010000;

use Benchmark qw(:all);
use lib 'lib';
use File::Zglob;
use File::Glob qw(bsd_glob);
use File::Find::Rule;

my $t = timethese(-1, {
    glob => sub {
        glob('*/*.t')
    },
    zglob => sub {
        zglob('*/*.t')
    },
    bsd_glob => sub {
        bsd_glob('*/*.t')
    },
    rule => sub {
        File::Find::Rule->file->name('*.t')->in('.')
    },
});
cmpthese($t);

