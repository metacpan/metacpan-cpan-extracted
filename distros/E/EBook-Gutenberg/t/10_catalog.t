#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use EBook::Gutenberg::Catalog;

# Only methods related to processing catalog files are tested. This does not
# test anything related to fetching catalogs remotely.

my $CATPATH = File::Spec->catfile(qw/t data pg_catalog.csv/);

# Only testing first 5 books
my @BOOK_TESTS = (
    {
        'Text#'       => q{1},
        'Type'        => q{Text},
        'Issued'      => q{1971-12-01},
        'Title'       => q{The Declaration of Independence of the United States of America},
        'Language'    => q{en},
        'Authors'     => q{Jefferson, Thomas, 1743-1826},
        'Subjects'    => q{United States -- History -- Revolution, 1775-1783 -- Sources; United States. Declaration of Independence},
        'LoCC'        => q{E201; JK},
        'Bookshelves' => q{Politics; American Revolutionary War; United States Law; Browsing: History - American; Browsing: History - Warfare; Browsing: Politics},
    },
    {
        'Text#'       => q{2},
        'Type'        => q{Text},
        'Issued'      => q{1972-12-01},
        'Title'       => q{The United States Bill of Rights The Ten Original Amendments to the Constitution of the United States},
        'Language'    => q{en},
        'Authors'     => q{United States},
        'Subjects'    => q{Civil rights -- United States -- Sources; United States. Constitution. 1st-10th Amendments},
        'LoCC'        => q{JK; KF},
        'Bookshelves' => q{Politics; American Revolutionary War; United States Law; Browsing: History - American; Browsing: Law & Criminology; Browsing: Politics},
    },
    {
        'Text#'       => q{3},
        'Type'        => q{Text},
        'Issued'      => q{1973-11-01},
        'Title'       => q{John F. Kennedy's Inaugural Address},
        'Language'    => q{en},
        'Authors'     => q{Kennedy, John F. (John Fitzgerald), 1917-1963},
        'Subjects'    => q{United States -- Foreign relations -- 1961-1963; Presidents -- United States -- Inaugural addresses},
        'LoCC'        => q{E838},
        'Bookshelves' => q{Browsing: History - American; Browsing: Politics},
    },
    {
        'Text#'       => q{4},
        'Type'        => q{Text},
        'Issued'      => q{1973-11-01},
        'Title'       => q{Lincoln's Gettysburg Address Given November 19, 1863 on the battlefield near Gettysburg, Pennsylvania, USA},
        'Language'    => q{en},
        'Authors'     => q{Lincoln, Abraham, 1809-1865},
        'Subjects'    => q{Consecration of cemeteries -- Pennsylvania -- Gettysburg; Soldiers' National Cemetery (Gettysburg, Pa.); Lincoln, Abraham, 1809-1865. Gettysburg address},
        'LoCC'        => q{E456},
        'Bookshelves' => q{US Civil War; Browsing: History - American; Browsing: Politics},
    },
    {
        'Text#'       => q{5},
        'Type'        => q{Text},
        'Issued'      => q{1975-12-01},
        'Title'       => q{The United States Constitution},
        'Language'    => q{en},
        'Authors'     => q{United States},
        'Subjects'    => q{United States -- Politics and government -- 1783-1789 -- Sources; United States. Constitution},
        'LoCC'        => q{JK; KF},
        'Bookshelves' => q{United States; Politics; American Revolutionary War; United States Law; Browsing: History - American; Browsing: Law & Criminology; Browsing: Politics},
    },
);

my $cat = EBook::Gutenberg::Catalog->new($CATPATH);
isa_ok($cat, 'EBook::Gutenberg::Catalog');

like($cat->path, qr/\Q$CATPATH\E$/, "path ok");

$cat->set_path($CATPATH);
like($cat->path, qr/\Q$CATPATH\E$/, "set_path ok");

for my $i (1 .. 20) {
    my $ref = $cat->book($i);
    is(ref $ref, 'HASH', "book($i) is hash ref");
    for my $k ('Text#', qw(
        Type Issued Title Language Authors Subjects LoCC Bookshelves
    )) {
        ok(exists $ref->{ $k }, "book($i) has $k");
    }
}

for my $i (0 .. 4) {
    my $ref = $cat->book($i + 1);
    is_deeply($ref, $BOOK_TESTS[$i], "book #$i ok");
}

my $books;

$books = $cat->books({ 'Text#' => sub { $_ % 2 == 0 } });
is(scalar @$books, 10, "'Text#' filter ok");

$books = $cat->books({ 'Type' => sub { $_ eq 'Text' } });
is(scalar @$books, 20, "'Type' filter ok");

$books = $cat->books({ 'Issued' => sub { $_ =~ /^1973/ } });
is(scalar @$books, 2, "'Issued' filter ok");

$books = $cat->books({ 'Title' => sub { $_ =~ /United States/ } });
is(scalar @$books, 3, "'Title' filter ok");

$books = $cat->books({ 'Language' => sub { $_ eq 'en' } });
is(scalar @$books, 20, "'Language' filter ok");

$books = $cat->books({ 'Authors' => sub { $_ =~ /Lincoln, Abraham/ } });
is(scalar @$books, 3, "'Authors' filter ok");

$books = $cat->books({ 'Subjects' => sub { $_ =~ /United States/ } });
is(scalar @$books, 8, "'Subjects' filter ok");

$books = $cat->books({ 'LoCC' => sub { $_ =~ /JK/ } });
is(scalar @$books, 4, "'LoCC' filter ok");

$books = $cat->books({ 'Bookshelves' => sub { $_ =~ /Browsing/ } });
is(scalar @$books, 20, "'Bookshelves' filter ok");

done_testing;

# vim: expandtab shiftwidth=4
