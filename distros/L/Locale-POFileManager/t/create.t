#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp 0.19;
use File::Copy;
use Path::Class;

use Locale::POFileManager;

sub header_is {
    my ($got, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @got      = split /\n/, $got, -1;
    my @expected = split /\n/, $expected, -1;
    is_deeply([@got[0..1],      sort @got[2..$#got]],
              [@expected[0..1], sort @expected[2..$#expected]],
              "got the right header");
}

{
    my $dir = File::Temp->newdir;
    my $from_dir = dir('t/data/create');
    my $tmpdir = dir($dir->dirname);
    for my $file ($from_dir->children) {
        copy($file->stringify, $dir->dirname);
    }
    my $expected_header = $tmpdir->file('en.po')->slurp;
    $expected_header =~ s/\n\n.*/\n\n/s;

    my $manager = Locale::POFileManager->new(
        base_dir           => $dir->dirname,
        canonical_language => 'en',
    );
    is_deeply([sort map { $_->basename } $tmpdir->children],
              [qw(en.po)],
              "correct initial directory contents");

    $manager->add_language('ru');
    $manager->add_language('hi');

    is_deeply([sort map { $_->basename } $tmpdir->children],
              [qw(en.po hi.po ru.po)],
              "correct directory contents after creation");

    for my $lang (qw(ru hi)) {
        header_is(scalar($tmpdir->file("$lang.po")->slurp), $expected_header);
    }

    $manager->language_file('ru')->add_entry(
        msgid  => 'baz',
        msgstr => 'Zab',
    );
    is_deeply([sort $manager->language_file('ru')->msgids],
              ['', qw(baz)],
              "created new entry successfully");
    is($manager->language_file('ru')->msgstr('baz'), 'Zab',
       "correct entry created");

    is_deeply([sort $manager->language_file('hi')->msgids],
              [''],
              "other language file untouched");

    $manager->add_stubs;

    for my $lang (qw(ru hi)) {
        is_deeply([sort $manager->language_file($lang)->msgids],
                  ['', qw(bar baz foo)],
                  "stubs for $lang created properly");
    }

    my %langs = (
        en => [qq{msgid "foo"\nmsgstr "foo"\n\n}
             . qq{msgid "bar"\nmsgstr "bar"\n\n}
             . qq{msgid "baz"\nmsgstr "baz"\n},
               qq{}],
        hi => [qq{},
               qq{msgid "foo"\n\n}
             . qq{msgid "bar"\n\n}
             . qq{msgid "baz"\n\n}],
        ru => [qq{msgid "baz"\nmsgstr "Zab"\n\n},
               qq{msgid "foo"\n\n}
             . qq{msgid "bar"\n\n}],
    );

    for my $lang (keys %langs) {
        my $contents = $manager->language_file($lang)->file->slurp;
        my ($header, $data) = ($contents =~ /^(.*?\n\n)(.*)$/s);
        header_is($header, $expected_header);
        my $fixed = substr($data, 0, length($langs{$lang}->[0]), '');
        is($fixed, $langs{$lang}->[0], "existing data untouched");
        is_deeply([sort split /\n\n/, $data],
                  [sort split /\n\n/, $langs{$lang}->[1]],
                  "correct new msgids added");
    }
}

done_testing;
