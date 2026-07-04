#!perl
# Every Entry accessor and type predicate, exercising the ALIAS-driven
# XSUB dispatch.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/accessors.tar";

my $w = File::Raw::Archive->create($tar);
$w->add(
    name     => 'a-file.txt',
    content  => 'hello',
    mode     => 0640,
    mtime    => 1700000000,
    mtime_ns => 123456789,
    uid      => 501,
    gid      => 20,
);
$w->add(name => 'sub-dir/');                        # AE_DIR
$w->add(name => 'a-link', link_target => 'a-file.txt');  # AE_SYMLINK
$w->close;

my $r = File::Raw::Archive->open($tar);

# File entry: every metadata field.
my $file = $r->next;
isa_ok($file, 'File::Raw::Archive::Entry', 'file entry blessed');
is($file->name,        'a-file.txt',  'name');
is($file->size,        5,             'size');
is($file->mode,        0640,          'mode');
is($file->mtime,       1700000000,    'mtime');
is($file->mtime_ns,    123456789,     'mtime_ns');
is($file->uid,         501,           'uid');
is($file->gid,         20,            'gid');
is($file->type,        File::Raw::Archive::AE_FILE(), 'type=AE_FILE');
is($file->link_target, undef,         'link_target undef for files');
is($file->is_sparse,   0,             'is_sparse 0');

# Type predicates on a file
ok( $file->is_file,    'is_file true on file');
ok(!$file->is_dir,     'is_dir false on file');
ok(!$file->is_symlink, 'is_symlink false on file');
ok(!$file->is_link,    'is_link false on file');

$file->slurp;  # consume payload before next()

# Directory entry.
my $dirent = $r->next;
is($dirent->name, 'sub-dir/',                         'dir name');
is($dirent->type, File::Raw::Archive::AE_DIR(),       'dir type');
ok( $dirent->is_dir,     'is_dir true on dir');
ok(!$dirent->is_file,    'is_file false on dir');
ok(!$dirent->is_symlink, 'is_symlink false on dir');
ok(!$dirent->is_link,    'is_link false on dir');

# Symlink entry.
my $sym = $r->next;
is($sym->name,        'a-link',                            'symlink name');
is($sym->type,        File::Raw::Archive::AE_SYMLINK(),    'symlink type');
is($sym->link_target, 'a-file.txt',                        'link_target on symlink');
ok( $sym->is_symlink, 'is_symlink true on symlink');
ok( $sym->is_link,    'is_link true on symlink');
ok(!$sym->is_file,    'is_file false on symlink');
ok(!$sym->is_dir,     'is_dir false on symlink');

# xattrs accessor returns undef when entry has none.
is($sym->xattrs, undef, 'xattrs undef when no xattrs set');

$r->close;

done_testing;
