use strict;
use warnings;
use Test::More;
use Path::Tiny qw( tempdir );
use File::Spec;
use MCP::Wiki::Document;

subtest 'Document basic operations' => sub {
    my $dir = tempdir;

    my $test_file = File::Spec->catfile($dir, 'test.md');
    Path::Tiny::path($test_file)->spew_utf8(<<'MARKDOWN');
# Introduction

This is the intro.

## Background

Some background.
MARKDOWN

    my $doc = MCP::Wiki::Document->new(
        file_path   => $test_file,
        wiki_root => "$dir",
    );

    ok($doc->content, 'has content');

    my @toc = $doc->get_toc;
    is(scalar(@toc), 2, 'two TOC entries');
    is($toc[0]->heading, 'Introduction');
    is($toc[1]->heading, 'Background');
};

subtest 'get_paragraph returns section content' => sub {
    my $dir = tempdir;

    my $test_file = File::Spec->catfile($dir, 'test.md');
    Path::Tiny::path($test_file)->spew_utf8(<<'MARKDOWN');
# Intro

Some intro content here.

## Section One

Section one content.
MARKDOWN

    my $doc = MCP::Wiki::Document->new(
        file_path   => $test_file,
        wiki_root => "$dir",
    );

    my $para = $doc->get_paragraph('Intro');
    ok($para, 'got paragraph');
    like($para->{content}, qr/intro/i, 'content contains intro');

    $para = $doc->get_paragraph('Intro#Section One');
    ok($para, 'got nested paragraph');
    like($para->{content}, qr/Section one/, 'content has section one');
};

subtest 'update_content_hash is consistent' => sub {
    my $dir = tempdir;

    my $test_file = File::Spec->catfile($dir, 'test.md');
    Path::Tiny::path($test_file)->spew_utf8("# Test\n\nContent.");

    my $doc = MCP::Wiki::Document->new(
        file_path   => $test_file,
        wiki_root => "$dir",
    );

    my $hash1 = $doc->update_content_hash;
    my $hash2 = $doc->update_content_hash;

    is($hash1, $hash2, 'same content produces same hash');
};

done_testing;