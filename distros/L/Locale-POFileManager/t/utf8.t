#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp 0.19;
use File::Copy;
use Path::Class;

use Locale::POFileManager;

{
    my $dir = File::Temp->newdir;
    my $from_dir = dir('t/data/utf8');
    my $tmpdir = dir($dir->dirname);
    for my $file ($from_dir->children) {
        copy($file->stringify, $dir->dirname);
    }

    {
        my $manager = Locale::POFileManager->new(
            base_dir           => $dir->dirname,
            canonical_language => 'hi',
        );

        is($manager->language_file('hi')->msgstr('नमस्ते'),
           'नमस्ते',
           "got the right hindi translation");
        is($manager->language_file('en')->msgstr('नमस्ते'),
           'Hello',
           "got the right english translation");
        ok(!$manager->language_file('en')->has_msgid('मेरा नाम'),
           "no translation for this one");

        $manager->add_stubs;

        ok($manager->language_file('en')->has_msgid('मेरा नाम'),
           "correct stub added");
    }

    {
        my $manager = Locale::POFileManager->new(
            base_dir           => $dir->dirname,
            canonical_language => 'hi',
        );

        ok($manager->language_file('en')->has_msgid('मेरा नाम'),
           "correct stub loaded");
    }
}

done_testing;
