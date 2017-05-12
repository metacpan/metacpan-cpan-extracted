use strictures 1;
use Test::More;

use File::Tree::Snapshot;
use File::Path qw( rmtree );
use FindBin;

my $tree_path = "$FindBin::Bin/test-tree";

my $tree = File::Tree::Snapshot->new(
    storage_path    => $tree_path,
);

ok not($tree->exists), 'tree doesnt exist yet';
ok $tree->create, 'tree creation successful';
ok $tree->exists, 'tree does now exit';
ok(-e "$tree_path/.gitignore", 'created .gitignore');

do {
  ok(my $fh = $tree->open('>', 'foo/bar.txt', mkpath => 1), 'open file');
  print $fh "baz";
  close $fh;
};

my ($file) = $tree->find_files('txt', 'foo');
ok -e $file, 'written file exists';

ok $tree->commit, 'commit';
ok $tree->reset, 'reset';
ok -e $file, 'file still exists';

do {
  ok(my $fh = $tree->open('>', 'foo/bar.txt', mkpath => 1), 'open file again');
  print $fh "qux";
  close $fh;
};

do {
  ok(my $fh = $tree->open('>', 'foo/baz.txt', mkpath => 1), 'open other file');
  print $fh "qux";
  close $fh;
};

ok $tree->reset, 'reset before commit';
ok -e $tree->file('foo/bar.txt'), 'original file still exists';
ok not(-e $tree->file('foo/baz.txt')), 'new file no longer exists';

do {
  my $fh = $tree->open('<', 'foo/bar.txt');
  my $body = do { local $/; <$fh> };
  is $body, 'baz', 'reset to original content';
};

rmtree $tree_path;

done_testing;
