use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Git::Native;
use Git::Native::Branch;

my ( $repo, $tmp ) = TestRepo::new_repo();

# Need a commit to anchor a branch.
my $blob = $repo->blob_create_frombuffer("hi\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'README', oid => $blob, mode => 0100644 );
my $tree   = $tb->write;
my $commit = $repo->commit_create(
  tree    => $tree,
  parents => [],
  message => 'initial',
);

# Create branch 'feature' pointing at commit.
my $feat = $repo->branch_create( 'feature', $commit );
isa_ok $feat, 'Git::Native::Branch', 'branch_create returns Branch';
is $feat->name,    'feature',           'name';
is $feat->refname, 'refs/heads/feature','refname';
is $feat->target->hex, $commit->hex,    'branch target matches commit';
ok $feat->is_local, 'is_local';
ok !$feat->is_remote, 'not is_remote';

# Lookup roundtrip.
ok $repo->has_branch('feature'), 'has_branch yes';
ok !$repo->has_branch('nope'),   'has_branch no';

my $found = $repo->branch('feature');
is $found->name, 'feature', 'branch() lookup';

# List branches.
my $list = $repo->branches;
is scalar(@$list), 1, 'one branch';
is $list->[0]->name, 'feature', 'branch in list';

# Rename.
my $renamed = $feat->rename('trunk');
is $renamed->name, 'trunk', 'renamed';
ok $repo->has_branch('trunk'), 'new name exists';
ok !$repo->has_branch('feature'), 'old name gone';

# Delete.
$renamed->delete;
ok !$repo->has_branch('trunk'), 'deleted';

done_testing;
