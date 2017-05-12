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
    my $manager = Locale::POFileManager->new(
        base_dir           => 't/data/basic',
        canonical_language => 'en',
    );

    my %missing = $manager->find_missing;
    %missing = map { $_ => [ sort @{ $missing{$_} } ] } keys %missing;
    is_deeply(\%missing,
              {ru => [qw(bar baz)], hi => [qw(bar)], en => [], de => []},
              "got the correct missing messages");
}

{
    my $dir = File::Temp->newdir;
    my $from_dir = dir('t/data/basic');
    for my $file ($from_dir->children) {
        copy($file->stringify, $dir->dirname);
    }
    my $manager = Locale::POFileManager->new(
        base_dir           => $dir->dirname,
        canonical_language => 'en',
    );
    $manager->add_stubs;
    is_deeply({$manager->find_missing},
              {ru => [], hi => [], en => [], de => []},
              "got the correct missing messages");

    my $expected_header = <<'HEADER';
msgid ""
msgstr ""
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=utf-8\n"
"Content-Transfer-Encoding: 8bit\n"

HEADER

    my %langs = (
        en => qr{
            \A
            msgid\ "foo"\n
            msgstr\ "foo"\n
            \n
            msgid\ "bar"\n
            msgstr\ "bar"\n
            \n
            msgid\ "baz"\n
            msgstr\ "baz"\n
            \z
        }x,
        ru => qr{
            \A
            msgid\ "foo"\n
            msgstr\ "foo"\n
            \n
            (?:
                msgid\ "bar"\n
                \n
                msgid\ "baz"\n
            |
                msgid\ "baz"\n
                \n
                msgid\ "bar"\n
            )
            \n
            \z
        }x,
        hi => qr{
            \A
            msgid\ "foo"\n
            msgstr\ "foo"\n
            \n
            msgid\ "baz"\n
            msgstr\ "baz"\n
            \n
            msgid\ "bar"\n
            \n
            \z
        }x,
        de => qr{
            \A
            msgid\ "foo"\n
            msgstr\ "foo"\n
            \n
            msgid\ "bar"\n
            msgstr\ "bar"\n
            \n
            msgid\ "baz"\n
            msgstr\ "baz"\n
            \n
            \z
        }x,
    );

    for my $file ($manager->files) {
        my $contents = $file->file->slurp;
        my ($header, $data) = ($contents =~ /^(.*?\n\n)(.*)$/s);
        header_is($header, $expected_header);
        like($data, $langs{$file->language},
           "got the right stubs for " . $file->language);
    }
}

done_testing;
