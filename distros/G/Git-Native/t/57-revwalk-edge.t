use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Native::Revwalker;

# t/30-revwalk.t drives push_*/hide_ref/sorting over a linear chain. Left
# untested: hide_head, hide_glob, simplify_first_parent (all three subs were
# never called), the hex-string form of push_oid / hide_oid, and what a walker
# with nothing pushed does. The last one matters most: `next` must return
# undef on GIT_ITEROVER rather than throwing, and `all` must terminate.

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

# A little history with a merge, so first-parent simplification has something
# to simplify:
#     a1 -- a2 --\
#                 merge      (first parent: a2, second parent: b1)
#     b1 --------/
my $a1    = commit_on('a1');
my $a2    = commit_on( 'a2', $a1 );
my $b1    = commit_on('b1');
my $merge = commit_on( 'merge', $a2, $b1 );

$repo->reference_create( 'refs/heads/main', $merge, force => 1 );
$repo->set_head('refs/heads/main');

subtest 'a walker with nothing pushed is empty, not an error' => sub {
  my $w = $repo->revwalker;
  is $w->next, undef, 'next on an unseeded walker is undef (GIT_ITEROVER, not a throw)';
  is $repo->revwalker->all, [], 'all on an unseeded walker is an empty arrayref';
};

subtest 'next returns undef exactly once the walk is drained' => sub {
  my $w = $repo->revwalker;
  $w->push_oid($a1);   # a root commit: exactly one commit in the walk
  my $first = $w->next;
  is $first->hex, $a1->hex, 'the single commit comes out';
  is $w->next, undef, 'the walk is then exhausted';
  is $w->next, undef, 'and stays exhausted on a further call';
};

subtest 'push_oid / hide_oid accept hex strings' => sub {
  # Documented as "Oid or hex string"; only the Oid form had a caller.
  my $w = $repo->revwalker;
  $w->push_oid( $merge->hex );
  $w->hide_oid( $a2->hex );
  my $got = $w->all;
  my %seen = map { $_->hex => 1 } @$got;
  is scalar(@$got), 2, 'hiding a2 by hex string cuts the a-side ancestry';
  ok $seen{ $merge->hex }, 'the tip is still walked';
  ok $seen{ $b1->hex },    'the other parent is still walked';
  ok !$seen{ $a2->hex },   'the hidden commit is excluded';
  ok !$seen{ $a1->hex },   'and so is its ancestor';
};

subtest 'hide_head empties a walk seeded from HEAD' => sub {
  my $w = $repo->revwalker;
  $w->push_head;
  is scalar( @{ $repo->revwalker->push_head->all } ), 4,
    'HEAD alone walks the whole history';

  $w->hide_head;
  is $w->all, [], 'hiding HEAD after pushing it leaves nothing to walk';
};

subtest 'hide_glob excludes every matching ref' => sub {
  my $w = $repo->revwalker;
  $w->push_head;
  $w->hide_glob('refs/heads/*');
  is $w->all, [], 'hiding refs/heads/* removes the only branch tip';

  # A glob that matches nothing must not change the walk.
  my $w2 = $repo->revwalker;
  $w2->push_head;
  $w2->hide_glob('refs/nothing/*');
  is scalar( @{ $w2->all } ), 4, 'a glob matching no ref hides nothing';
};

subtest 'simplify_first_parent follows only the first parent of a merge' => sub {
  my $full = $repo->revwalker;
  $full->push_head;
  is scalar( @{ $full->all } ), 4, 'the full walk sees both sides of the merge';

  my $w = $repo->revwalker;
  $w->push_head;
  $w->simplify_first_parent;
  my $got = $w->all;
  is [ map { $_->hex } @$got ], [ $merge->hex, $a2->hex, $a1->hex ],
    'first-parent walk is merge -> a2 -> a1, dropping the second parent';
};

subtest 'the mutators chain' => sub {
  # Every push_/hide_/sorting/reset returns $self so calls can be chained;
  # nothing in the suite depended on it, so nothing would have caught a
  # method that stopped doing it.
  my $w = $repo->revwalker;
  ref_is $w->push_head,  $w, 'push_head returns the walker';
  ref_is $w->reset,      $w, 'reset returns the walker';
  ref_is $w->sorting( Git::Native::Revwalker::GIT_SORT_TOPOLOGICAL ), $w,
    'sorting returns the walker';
  ref_is $w->push_ref('refs/heads/main'), $w, 'push_ref returns the walker';
  ref_is $w->simplify_first_parent, $w, 'simplify_first_parent returns the walker';

  # reset really does clear the pushed tips: after reset the walk is empty
  # until something is pushed again.
  my $w2 = $repo->revwalker;
  $w2->push_head;
  $w2->reset;
  is $w2->all, [], 'reset drops previously pushed tips';
};

done_testing;
