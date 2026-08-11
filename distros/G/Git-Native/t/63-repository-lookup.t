use Test2::V0;
use lib 't/lib';
use TestRepo;
use Path::Tiny;
use Git::Native;
use Git::Native::Signature;

# Repository lookup / creation edges that no test reached: remote() and
# has_remote() had never been called (t/20 only ever uses remote_create and
# remote_anonymous), reference_create was never fed a hex string and its
# force flag never had a conflict to resolve, reference_symbolic_create's
# force flag was never exercised, tag_names was never called on a repo with
# no tags (the count == 0 path), and tag() was never given a full refname.

my ( $repo, $tmp ) = TestRepo::new_repo();

my $blob = $repo->blob_create_frombuffer("hi\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'README', oid => $blob, mode => 0100644 );
my $tree = $tb->write;
my $c1   = $repo->commit_create( tree => $tree, parents => [], message => 'one' );
my $c2   = $repo->commit_create( tree => $tree, parents => [$c1], message => 'two' );

my $tagger = Git::Native::Signature->new(
  name => 'Tester', email => 'tester@example.invalid',
);

subtest 'tag_names on a repo with no tags' => sub {
  # The strarray walker only runs when count > 0; the empty case has to come
  # back as an empty arrayref rather than dereferencing a NULL strings ptr.
  is $repo->tag_names, [], 'no tags yet -> empty arrayref';
  is $repo->tag_names( pattern => 'v*' ), [],
    'a pattern with no matches -> empty arrayref';
};

subtest 'remote / has_remote' => sub {
  is $repo->has_remote('origin'), 0, 'has_remote is 0 before the remote exists';

  my $err = dies { $repo->remote('origin') };
  isa_ok $err, ['Git::Native::Error'], 'remote() on an unknown name throws';
  is $err->is_not_found, 1, 'and it is the not-found kind';

  my $url = 'file://' . Path::Tiny->tempdir;
  $repo->remote_create( 'origin', $url );

  is $repo->has_remote('origin'), 1, 'has_remote is 1 once it exists';

  my $looked_up = $repo->remote('origin');
  isa_ok $looked_up, ['Git::Native::Remote'], 'remote() returns a Remote';
  is $looked_up->name, 'origin', 'name round-trips through the lookup';
  is $looked_up->url,  $url,     'url round-trips through the lookup';

  # Creating the same remote twice is a conflict, not a silent overwrite.
  my $dup = dies { $repo->remote_create( 'origin', $url ) };
  isa_ok $dup, ['Git::Native::Error'], 'remote_create on an existing name throws';
  is $dup->is_exists, 1, 'and it is the already-exists kind';

  # An anonymous remote is not registered, so it stays invisible to lookups.
  my $anon = $repo->remote_anonymous($url);
  is $anon->name, undef, 'an anonymous remote has no name';
  is $repo->has_remote('anon'), 0, 'and does not show up under one';
};

subtest 'reference_create: hex target, conflict, force' => sub {
  my $ref = $repo->reference_create( 'refs/heads/hexed', $c1->hex );
  is $ref->target->hex, $c1->hex, 'reference_create accepts a hex string target';

  my $err = dies { $repo->reference_create( 'refs/heads/hexed', $c2 ) };
  isa_ok $err, ['Git::Native::Error'], 'creating an existing ref without force throws';
  is $err->is_exists, 1, 'and it is the already-exists kind';
  is $repo->reference('refs/heads/hexed')->target->hex, $c1->hex,
    'the refused create left the ref where it was';

  my $forced = $repo->reference_create(
    'refs/heads/hexed', $c2, force => 1, message => 'forced move',
  );
  is $forced->target->hex, $c2->hex, 'force => 1 overwrites the existing ref';
  is $repo->reference('refs/heads/hexed')->target->hex, $c2->hex,
    'and the overwrite persisted';
};

subtest 'reference_symbolic_create: conflict and force' => sub {
  $repo->reference_create( 'refs/heads/first',  $c1, force => 1 );
  $repo->reference_create( 'refs/heads/second', $c2, force => 1 );

  my $sym = $repo->reference_symbolic_create( 'refs/heads/ptr', 'refs/heads/first' );
  is $sym->symbolic_target, 'refs/heads/first', 'symbolic ref created';

  my $err = dies {
    $repo->reference_symbolic_create( 'refs/heads/ptr', 'refs/heads/second' )
  };
  isa_ok $err, ['Git::Native::Error'],
    'creating an existing symbolic ref without force throws';
  is $err->is_exists, 1, 'and it is the already-exists kind';
  is $repo->reference('refs/heads/ptr')->symbolic_target, 'refs/heads/first',
    'the refused create left the symbolic ref alone';

  my $forced = $repo->reference_symbolic_create(
    'refs/heads/ptr', 'refs/heads/second', force => 1, message => 'repoint',
  );
  is $forced->symbolic_target, 'refs/heads/second', 'force => 1 repoints it';
  is $repo->reference('refs/heads/ptr')->resolve->target->hex, $c2->hex,
    'and it resolves to the new target';
};

subtest 'reference_delete is idempotent' => sub {
  # git_reference_remove reports success for a ref that is not there - same as
  # `git update-ref -d` on a missing ref. Pinned here because it is the
  # opposite of reference() / tag(), which DO throw not-found, and because a
  # caller writing cleanup code needs to know which of the two it gets.
  my $ret = $repo->reference_delete('refs/heads/never-existed');
  ref_is $ret, $repo, 'deleting a ref that is not there returns the repository';
  is $repo->reference_exists('refs/heads/never-existed'), 0, 'and it is still absent';

  # A ref that does exist really is removed.
  $repo->reference_create( 'refs/heads/doomed', $c1, force => 1 );
  is $repo->reference_exists('refs/heads/doomed'), 1, 'the ref exists first';
  $repo->reference_delete('refs/heads/doomed');
  is $repo->reference_exists('refs/heads/doomed'), 0, 'and is gone afterwards';
};

subtest 'tag: full refname, conflict, force' => sub {
  $repo->tag_create( 'v1.0.0', $c1, message => "release one\n", tagger => $tagger );

  # tag() takes either the short name or the full refname.
  my $by_short = $repo->tag('v1.0.0');
  my $by_full  = $repo->tag('refs/tags/v1.0.0');
  isa_ok $by_full, ['Git::Native::Tag'], 'tag() accepts a full refname';
  is $by_full->name, $by_short->name, 'both spellings find the same tag';
  is $by_full->target_id->hex, $c1->hex, 'the tag points at its commit';

  my $err = dies { $repo->tag('does-not-exist') };
  isa_ok $err, ['Git::Native::Error'], 'tag() on a missing tag throws';
  is $err->is_not_found, 1, 'and it is the not-found kind';

  # Re-tagging an existing name needs force, for both annotated ...
  my $dup = dies {
    $repo->tag_create( 'v1.0.0', $c2, message => "again\n", tagger => $tagger )
  };
  isa_ok $dup, ['Git::Native::Error'], 'annotated tag_create on a taken name throws';
  is $dup->is_exists, 1, 'and it is the already-exists kind';
  is $repo->tag('v1.0.0')->target_id->hex, $c1->hex,
    'the refused tag_create left the tag alone';

  $repo->tag_create(
    'v1.0.0', $c2, message => "again\n", tagger => $tagger, force => 1,
  );
  is $repo->tag('v1.0.0')->target_id->hex, $c2->hex,
    'force => 1 moves the annotated tag';

  # ... and lightweight.
  $repo->tag_create( 'light', $c1 );
  my $dup_light = dies { $repo->tag_create( 'light', $c2 ) };
  isa_ok $dup_light, ['Git::Native::Error'],
    'lightweight tag_create on a taken name throws';
  is $dup_light->is_exists, 1, 'and it is the already-exists kind';

  $repo->tag_create( 'light', $c2, force => 1 );
  is $repo->reference('refs/tags/light')->target->hex, $c2->hex,
    'force => 1 moves the lightweight tag';

  # And now tag_names has something to report, which also proves the empty
  # result earlier was a real empty and not a broken walker.
  is [ sort @{ $repo->tag_names } ], [ 'light', 'v1.0.0' ],
    'tag_names lists both tags';
};

done_testing;
