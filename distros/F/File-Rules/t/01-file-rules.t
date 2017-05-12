#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 13;

use_ok('File::Rules');

my @rules = (
    'filename is ignored.txt',
    'pathname contains skip',
    'dirname regex /skip/',
);

for my $str (@rules) {
    ok( my $filerules = File::Rules->new($str), "new rule: $str" );
    ok( $filerules->match('t/dirs/skip-me/ignored.txt'),
        "ignored.txt file matches '$str'" );
}

@rules = (
    'directory contains ignored.txt',
    'pathname contains skip',
    'dirname is skip-me',
);

for my $str (@rules) {
    ok( my $filerules = File::Rules->new($str), "new rule: $str" );
    ok( $filerules->match('t/dirs/skip-me'), "skip-me dir matches '$str'" );
}
