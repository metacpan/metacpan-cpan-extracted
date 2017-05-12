#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp 0.19;
use File::Copy;
use Path::Class;

use Locale::POFileManager;

{
    my $dir = File::Temp->newdir;
    my $from_dir = dir('t/data/comments');
    my $tmpdir = dir($dir->dirname);
    for my $file ($from_dir->children) {
        copy($file->stringify, $dir->dirname);
    }

    my $manager = Locale::POFileManager->new(
        base_dir           => $dir->dirname,
        canonical_language => 'en',
    );
    $manager->add_stubs;

    is($tmpdir->file('en.po')->slurp, $from_dir->file('en.po')->slurp,
       "canonical file untouched");

    my $expected = $from_dir->file("de.po")->slurp;
    my $got = $tmpdir->file("de.po")->slurp;
    my $fixed = substr $got, 0, length($expected), '';
    is($fixed, $expected, "original part of the file wasn't touched");
    is(substr($got, 0, 1, ''), "\n", "spacing newline added properly");
    is_deeply([sort split /\n\n/, $got],
              [qq{msgid "quuux"}, qq{msgid "quux"}],
              "added the correct stubs");
}

done_testing;
