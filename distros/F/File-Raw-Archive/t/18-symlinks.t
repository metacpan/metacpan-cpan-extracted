#!perl
# Symlink entries: write a symlink, read it back, verify type and
# link_target, plus extract_all should materialise it as a real symlink
# on disk (skipped on filesystems that don't support symlinks).
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);

# Quick probe: does this filesystem support symlinks?
my $sym_supported = eval {
    symlink("$dir/x", "$dir/_probe") and unlink("$dir/_probe");
    1;
};
plan skip_all => 'symlink(2) not supported here' unless $sym_supported;

my $tar = "$dir/syms.tar";

my $w = File::Raw::Archive->create($tar);
$w->add(name => 'real.txt', content => 'I am real');
$w->add(name => 'alias',    link_target => 'real.txt');     # implicit symlink
$w->add(
    name        => 'long-link',
    link_target => 'a/longer/path/to/somewhere',
    type        => File::Raw::Archive::AE_SYMLINK(),
    mode        => 0777,
);
$w->close;

# Read back: types and targets match.
my $r = File::Raw::Archive->open($tar);
my $real = $r->next;
ok($real->is_file, 'real.txt is_file');

my $alias = $r->next;
isa_ok($alias, 'File::Raw::Archive::Entry', 'alias entry');
ok($alias->is_symlink, 'alias is_symlink');
is($alias->link_target, 'real.txt', 'alias link_target');

my $longlink = $r->next;
ok($longlink->is_symlink, 'long-link is_symlink');
is($longlink->link_target, 'a/longer/path/to/somewhere', 'long-link target');

$r->close;

# extract_all materialises symlinks on disk.
my $dest = "$dir/extracted";
File::Raw::Archive->extract_all($tar, $dest);

ok(-l "$dest/alias",     'alias extracted as symlink');
my $target = readlink("$dest/alias");
is($target, 'real.txt',  'alias readlink target');

ok(-l "$dest/long-link", 'long-link extracted as symlink');
is(readlink("$dest/long-link"),
   'a/longer/path/to/somewhere',
   'long-link readlink target');

done_testing;
