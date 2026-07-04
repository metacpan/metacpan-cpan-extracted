#!perl
# Function-style imports: use File::Raw::Archive qw(import) installs
# file_archive_open / file_archive_create / file_archive_list /
# file_archive_extract / file_archive_extract_all / file_archive_each
# in the caller's package. These are the same XSUBs as the class
# methods minus the leading $class arg.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Importing :all should bring in all six file_archive_* names.
use File::Raw::Archive qw(import);

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/funcs.tar";

# All six functions are installed in this package.
ok( __PACKAGE__->can('file_archive_open'),        'file_archive_open installed');
ok( __PACKAGE__->can('file_archive_create'),      'file_archive_create installed');
ok( __PACKAGE__->can('file_archive_list'),        'file_archive_list installed');
ok( __PACKAGE__->can('file_archive_extract'),     'file_archive_extract installed');
ok( __PACKAGE__->can('file_archive_extract_all'), 'file_archive_extract_all installed');
ok( __PACKAGE__->can('file_archive_each'),        'file_archive_each installed');

# Build a tarball using file_archive_create / Writer methods.
my $w = file_archive_create($tar);
$w->add(name => 'one.txt',   content => 'first');
$w->add(name => 'two.txt',   content => 'second');
$w->add(name => 'three.txt', content => 'third');
$w->close;

ok(-s $tar > 0, 'archive produced via file_archive_create');

# file_archive_list returns AoH same as the class method.
my $rows = file_archive_list($tar);
isa_ok($rows, 'ARRAY', 'file_archive_list returns arrayref');
is(scalar @$rows, 3, '3 entries listed');
is($rows->[0]{name}, 'one.txt', 'first row name');
is($rows->[1]{size}, 6, 'second row size');

# file_archive_each invokes the callback per entry.
my @names;
file_archive_each($tar, sub { push @names, $_[0]->name });
is_deeply(\@names, ['one.txt', 'two.txt', 'three.txt'],
    'file_archive_each iterates all entries');

# file_archive_open + Reader methods.
my $r = file_archive_open($tar);
isa_ok($r, 'File::Raw::Archive::Reader', 'file_archive_open returns Reader');
my $first = $r->next;
is($first->name, 'one.txt', 'first entry via file_archive_open');
$r->close;

# file_archive_extract one named file.
my $out = "$dir/two-extracted.txt";
my $rc  = file_archive_extract($tar, 'two.txt', $out);
ok($rc, 'file_archive_extract found and wrote');
open my $fh, '<', $out or die $!;
my $content = do { local $/; <$fh> };
close $fh;
is($content, 'second', 'extracted content matches');

# file_archive_extract_all.
my $dest = "$dir/all";
file_archive_extract_all($tar, $dest);
ok(-d $dest, 'extract_all created dest');
ok(-f "$dest/one.txt",   'extract_all wrote one.txt');
ok(-f "$dest/two.txt",   'extract_all wrote two.txt');
ok(-f "$dest/three.txt", 'extract_all wrote three.txt');

done_testing;
