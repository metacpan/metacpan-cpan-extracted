use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;

# t/36-reference.t walks the happy path over a branch and an alias. What was
# never exercised: `name` itself, `target` on a symbolic ref (must be undef,
# not a crash), is_remote / is_tag on refs that really are remote / tag refs,
# set_target fed a hex string instead of an Oid, set_target refused on a
# symbolic ref, and `delete` plus the state it leaves behind.

my ( $repo, $tmp ) = TestRepo::new_repo();

my $blob = $repo->blob_create_frombuffer("hi\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'README', oid => $blob, mode => 0100644 );
my $tree = $tb->write;
my $c1   = $repo->commit_create( tree => $tree, parents => [], message => 'one' );
my $c2   = $repo->commit_create( tree => $tree, parents => [$c1], message => 'two' );

$repo->reference_create( 'refs/heads/main',         $c1, force => 1 );
$repo->reference_create( 'refs/remotes/origin/main', $c1, force => 1 );
$repo->reference_create( 'refs/tags/v0',            $c1, force => 1 );
my $alias = $repo->reference_symbolic_create( 'refs/heads/alias', 'refs/heads/main' );

subtest 'the three ref kinds are told apart' => sub {
  # Each predicate has to be true for its own namespace AND false for the
  # other two - a single positive assertion would pass on `sub { 1 }`.
  my %kind = (
    'refs/heads/main'          => [ 1, 0, 0 ],
    'refs/remotes/origin/main' => [ 0, 1, 0 ],
    'refs/tags/v0'             => [ 0, 0, 1 ],
  );
  for my $name ( sort keys %kind ) {
    my ( $branch, $remote, $tag ) = @{ $kind{$name} };
    my $ref = $repo->reference($name);
    is $ref->name,      $name,   "$name: name is the full refname";
    is $ref->is_branch, $branch, "$name: is_branch";
    is $ref->is_remote, $remote, "$name: is_remote";
    is $ref->is_tag,    $tag,    "$name: is_tag";
  }

  is $repo->reference('refs/remotes/origin/main')->shorthand, 'origin/main',
    'a remote-tracking ref shortens to remote/branch';
  is $repo->reference('refs/tags/v0')->shorthand, 'v0',
    'a tag ref shortens to the tag name';
};

subtest 'symbolic refs carry no OID target' => sub {
  ok $alias->is_symbolic, 'the alias is symbolic';
  is $alias->target, undef,
    'target on a symbolic ref is undef (libgit2 hands back a NULL git_oid*)';
  is $alias->symbolic_target, 'refs/heads/main', 'symbolic_target is the refname';

  # resolve follows the chain; on a direct ref it is a no-op that still hands
  # back a usable Reference.
  is $alias->resolve->target->hex, $c1->hex, 'resolve on a symbolic ref reaches the OID';
  my $direct = $repo->reference('refs/heads/main');
  is $direct->resolve->name, 'refs/heads/main',
    'resolve on a direct ref returns the same ref';
  is $direct->resolve->target->hex, $c1->hex, 'resolve on a direct ref keeps the OID';
};

subtest 'set_target accepts a hex string' => sub {
  # Every OID-taking method promises Oid-or-hex; the hex branch of set_target
  # had no caller in the suite.
  my $ref   = $repo->reference('refs/heads/main');
  my $moved = $ref->set_target( $c2->hex );
  is $moved->target->hex, $c2->hex, 'set_target took a 40-char hex string';
  is $repo->reference('refs/heads/main')->target->hex, $c2->hex,
    'and persisted it';

  # Put it back so the rest of the file starts from a known state.
  $repo->reference('refs/heads/main')->set_target($c1);
};

subtest 'set_target is refused on a symbolic ref' => sub {
  # The wrapper documents symbolic_set_target as the mutator for symbolic
  # refs; libgit2 enforces it and the failure must arrive typed.
  my $err = dies { $alias->set_target($c2) };
  isa_ok $err, ['Git::Native::Error'],
    'set_target on a symbolic ref throws Git::Native::Error';
  ok !$err->isa('Git::Libgit2::Error'), 'the low-level error does not leak';
  ok $err->code < 0, 'the libgit2 return code is negative';
  like $err->message, qr/symbolic/i, 'the message names the actual problem';

  # The alias is unchanged - a refused mutation must not half-apply.
  is $repo->reference('refs/heads/alias')->symbolic_target, 'refs/heads/main',
    'the symbolic ref still points where it did';
};

subtest 'symbolic_set_target without a message' => sub {
  $repo->reference_create( 'refs/heads/other', $c2, force => 1 );
  my $repointed = $alias->symbolic_set_target('refs/heads/other');
  is $repointed->symbolic_target, 'refs/heads/other',
    'symbolic_set_target repoints without needing a reflog message';
  is $repo->reference('refs/heads/alias')->resolve->target->hex, $c2->hex,
    'the repointed alias resolves to the new branch tip';
};

subtest 'delete removes the ref' => sub {
  my $ref = $repo->reference('refs/tags/v0');
  my $ret = $ref->delete;
  ref_is $ret, $ref, 'delete returns the same object for chaining';

  is $repo->reference_exists('refs/tags/v0'), 0, 'the ref is gone';

  # Looking it up afterwards is the typed not-found error, not undef.
  my $err = dies { $repo->reference('refs/tags/v0') };
  isa_ok $err, ['Git::Native::Error'], 'looking up a deleted ref throws';
  is $err->is_not_found, 1, 'and it is the not-found kind';

  ok !grep( { $_ eq 'refs/tags/v0' } @{ $repo->reference_names } ),
    'the deleted ref is out of reference_names too';
};

done_testing;
