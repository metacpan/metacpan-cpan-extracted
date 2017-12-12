#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 0.99;

use Time::Piece;
use Path::Tiny 0.018;

use_ok 'File::Rotate::Simple';

my $dir  = Path::Tiny->tempdir;
my $base = 'test.log';
my $file = path($dir, $base);

$file->touch;
path($dir, $base . '.' . $_)->touch for (1..3);

File::Rotate::Simple->rotate(
    file => $file->stringify,
    if_missing => 1,
    );

ok !-e $file, 'file missing';
ok -e path($dir, $base . '.' . $_), "file $_ rotated" for (1..4);

File::Rotate::Simple->rotate(
    file => $file->stringify,
    if_missing => 1,
    );

ok !-e $file, 'file missing';
ok !-e path($dir, $base . '.' . $_), "file $_ missing" for (1);
ok -e path($dir, $base . '.' . $_), "file $_ rotated" for (2..5);

File::Rotate::Simple->rotate(
    file => $file->stringify,
    max  => 5,
    if_missing => 1,
    );

ok !-e $file, 'file missing';
ok !-e path($dir, $base . '.' . $_), "file $_ missing" for (1..2, 6);
ok -e path($dir, $base . '.' . $_), "file $_ rotated" for (3..5);


path($dir, $base . '.' . $_)->touch for (1..2,6);
path($dir, $base . '.' . $_)->touch( time - 86401 ) for (5);


File::Rotate::Simple->rotate(
    file => $file->stringify,
    age  => 1,
    if_missing => 1,
    );

ok !-e $file, 'file missing';
ok !-e path($dir, $base . '.' . $_), "file $_ missing" for (1, 6);
ok -e path($dir, $base . '.' . $_), "file $_ rotated" for (3..5, 7);

done_testing;
