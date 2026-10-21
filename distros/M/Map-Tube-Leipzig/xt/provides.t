#!/usr/bin/env perl

use 5.10.0;
use strict;
use warnings;
use Test::More;
use CPAN::Meta;

plan skip_all => 'these tests are for authors only!'
    unless ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING});

my $meta_file;
for my $candidate (qw( META.json META.yml MYMETA.json MYMETA.yml )) {
    if (-f $candidate) {
        $meta_file = $candidate;
        last;
    }
}

plan skip_all => 'No META or MYMETA file found. Run "perl Makefile.PL" first.'
    unless $meta_file;

my $meta = CPAN::Meta->load_file($meta_file);
my $provides = $meta->provides;

plan skip_all => 'No "provides" section found in metadata'
    unless $provides && keys %$provides;

subtest "Validate 'provides' file paths using $meta_file" => sub {
    for my $module (sort keys %$provides) {
        my $file = $provides->{$module}{file};
        ok($file, "Module $module defines a file path");

        # This will fail and explicitly show the incorrect path error
        ok(-f $file, "Incorrect file path for $module: '$file'");
    }
};

done_testing();
