#!perl
# Filenames with non-ASCII bytes, embedded spaces, deep nesting, dot-
# leading components, etc. Tar's `name` field is bytes-of-unspecified-
# encoding; we treat them as opaque byte strings (no transcoding) and
# round-trip them bit-exact.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/special.tar";

my @names = (
    'file with spaces.txt',
    'sub/with-dashes/and_underscores.csv',
    'a/b/c/d/e/f/g/h/deeply.nested.txt',
    '.hidden',
    'sub/.hidden-in-dir',
    'unicode-utf8/' . "\xe2\x98\x83.txt",                  # snowman
    'mixed/' . "\xc3\xa9" . 'galit' . "\xc3\xa9.csv",      # é
    'numeric/0123456789.bin',
    'punct/[brackets](parens){braces}.txt',
);

my $w = File::Raw::Archive->create($tar);
for my $n (@names) {
    $w->add(name => $n, content => "data-of-$n");
}
$w->close;

# All names round-trip via list().
my $rows = File::Raw::Archive->list($tar);
my @got = map { $_->{name} } @$rows;
is_deeply(\@got, \@names, 'all special paths round-trip via list()');

# Per-entry slurp content matches what we wrote.
my $r = File::Raw::Archive->open($tar);
while (my $e = $r->next) {
    my $expected = "data-of-" . $e->name;
    is($e->slurp, $expected, "content matches for: " . $e->name);
}
$r->close;

# extract_all materialises each name as a real file.
my $dest = "$dir/out";
File::Raw::Archive->extract_all($tar, $dest);
for my $n (@names) {
    ok(-e "$dest/$n", "extracted: $n");
}

# Deep path is fully created.
ok(-d "$dest/a/b/c/d/e/f/g/h", 'deep nested directories created');

done_testing;
