use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Native::Branch;

# t/31-branch.t covers local branches on the happy path. Untested until now:
# the remote-tracking side (is_local / is_remote only ever saw a local
# branch), rename onto a name that already exists (the one real failure mode
# of git_branch_move) and the force flag that overrides it, branch_create's
# hex-string target, and the type filter on branches().

my ( $repo, $tmp ) = TestRepo::new_repo();

my $blob = $repo->blob_create_frombuffer("hi\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'README', oid => $blob, mode => 0100644 );
my $tree = $tb->write;
my $c1   = $repo->commit_create( tree => $tree, parents => [], message => 'one' );
my $c2   = $repo->commit_create( tree => $tree, parents => [$c1], message => 'two' );

subtest 'branch_create accepts a hex target' => sub {
  # branch_create documents Oid-or-hex; only the Oid branch had a caller.
  my $b = $repo->branch_create( 'from-hex', $c1->hex );
  is $b->target->hex, $c1->hex, 'the branch points at the commit named by hex';
  is $b->refname, 'refs/heads/from-hex', 'refname';
};

subtest 'remote-tracking branches report is_remote, not is_local' => sub {
  # A remote-tracking branch is just a ref under refs/remotes/*; the wrapper
  # distinguishes them by the `type` it was looked up with.
  $repo->reference_create( 'refs/remotes/origin/main', $c1, force => 1 );

  my $remote = $repo->branch(
    'origin/main', type => Git::Native::Branch::GIT_BRANCH_REMOTE,
  );
  is $remote->name,      'origin/main',              'name drops refs/remotes/';
  is $remote->refname,   'refs/remotes/origin/main', 'refname is the full ref';
  is $remote->is_remote, 1, 'is_remote';
  is $remote->is_local,  0, 'not is_local';
  is $remote->is_head,   0, 'a remote-tracking branch is never HEAD';
  is $remote->target->hex, $c1->hex, 'target';

  # ... and looking the same name up as a LOCAL branch must fail, rather than
  # quietly returning the remote-tracking ref.
  my $err = dies {
    $repo->branch( 'origin/main', type => Git::Native::Branch::GIT_BRANCH_LOCAL )
  };
  isa_ok $err, ['Git::Native::Error'],
    'looking up a remote branch as local throws';
  is $err->is_not_found, 1, 'and it is the not-found kind';
  is $repo->has_branch('origin/main'), 0,
    'has_branch defaults to local and says no';
  is $repo->has_branch(
       'origin/main', type => Git::Native::Branch::GIT_BRANCH_REMOTE ), 1,
    'has_branch with the remote type says yes';
};

subtest 'branches() filters by type' => sub {
  my $all    = $repo->branches;
  my $local  = $repo->branches( type => Git::Native::Branch::GIT_BRANCH_LOCAL );
  my $remote = $repo->branches( type => Git::Native::Branch::GIT_BRANCH_REMOTE );

  my @local_names  = sort map { $_->name } @$local;
  my @remote_names = sort map { $_->name } @$remote;

  is \@local_names,  ['from-hex'],    'the local listing has only local branches';
  is \@remote_names, ['origin/main'], 'the remote listing has only remote branches';
  is scalar(@$all), scalar(@$local) + scalar(@$remote),
    'the default listing is local + remote';

  # The type each Branch reports must match the list it came from, otherwise
  # is_local / is_remote on a listed branch would lie.
  is [ map { $_->is_local } @$local ],   [ (1) x scalar(@$local) ],
    'branches from the local listing report is_local';
  is [ map { $_->is_remote } @$remote ], [ (1) x scalar(@$remote) ],
    'branches from the remote listing report is_remote';
};

subtest 'rename onto an existing branch is refused unless forced' => sub {
  my $src = $repo->branch_create( 'src', $c1 );
  $repo->branch_create( 'dst', $c2 );

  my $err = dies { $src->rename('dst') };
  isa_ok $err, ['Git::Native::Error'], 'rename onto an existing name throws';
  is $err->is_exists, 1, 'and it is the already-exists kind';

  # Nothing moved: both branches are exactly where they were.
  is $repo->has_branch('src'), 1, 'the source branch still exists';
  is $repo->branch('dst')->target->hex, $c2->hex,
    'the destination branch still points at its own commit';

  # force => 1 takes the other side of the flag and overwrites the target.
  my $moved = $repo->branch('src')->rename( 'dst', force => 1 );
  is $moved->name, 'dst', 'forced rename lands on the taken name';
  is $moved->target->hex, $c1->hex, 'and the destination now carries the source commit';
  is $repo->has_branch('src'), 0, 'the old name is gone';
};

subtest 'delete leaves nothing behind' => sub {
  my $b = $repo->branch_create( 'doomed', $c1 );
  my $ret = $b->delete;
  ref_is $ret, $b, 'delete returns the same object';
  is $repo->has_branch('doomed'), 0, 'the branch is gone';
  is $repo->reference_exists('refs/heads/doomed'), 0,
    'and so is the underlying ref';
};

done_testing;
