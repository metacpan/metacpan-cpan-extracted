use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;

# commit_create supports N parents via `pack 'J*'`, but an inline comment
# claims "For MVP, support 0..1 parent" and t/10 / t/38 only ever build 0- or
# 1-parent commits. A real merge commit (2 parents) pins down what actually
# works and keeps parent_count / parent_oids honest.

my ( $repo, $tmp ) = TestRepo::new_repo();

sub commit_on {
  my ( $msg, @parents ) = @_;
  my $blob = $repo->blob_create_frombuffer("$msg\n");
  my $tb   = $repo->tree_builder;
  $tb->insert( name => 'f', oid => $blob, mode => 0100644 );
  return $repo->commit_create(
    tree => $tb->write, parents => [@parents], message => $msg,
  );
}

# Two independent roots, then a commit that merges both.
my $a = commit_on('branch-a');
my $b = commit_on('branch-b');
my $merge = commit_on( 'merge a+b', $a, $b );

my $c = $repo->commit($merge);
is $c->parent_count, 2, 'merge commit has two parents';

# parent_oids preserves the order parents were passed in.
my @poids = map { $_->hex } @{ $c->parent_oids };
is \@poids, [ $a->hex, $b->hex ], 'parent_oids are [a, b] in order';

# Sanity: the two parents really are distinct commits.
isnt $a->hex, $b->hex, 'the two parents are different commits';

done_testing;
