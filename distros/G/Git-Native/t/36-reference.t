use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Git::Native;

my ( $repo, $tmp ) = TestRepo::new_repo();

# Anchor: one commit, a main branch pointing at it.
my $blob = $repo->blob_create_frombuffer("hi\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'README', oid => $blob, mode => 0100644 );
my $tree = $tb->write;
my $c1   = $repo->commit_create( tree => $tree, parents => [], message => 'one' );
$repo->reference_create( 'refs/heads/main', $c1, force => 1 );

# ---- direct ref accessors / predicates ----
my $main = $repo->reference('refs/heads/main');
ok !$main->is_symbolic, 'main is a direct ref';
ok $main->is_branch,    'is_branch';
ok !$main->is_remote,   'not is_remote';
ok !$main->is_tag,      'not is_tag';
is $main->shorthand,    'main', 'shorthand strips refs/heads/';
is $main->target->hex,  $c1->hex, 'direct target';
is $main->symbolic_target, undef, 'direct ref has no symbolic_target';

# ---- symbolic ref: create, inspect, resolve ----
my $alias = $repo->reference_symbolic_create( 'refs/heads/alias', 'refs/heads/main' );
ok $alias->is_symbolic,            'alias is symbolic';
is $alias->symbolic_target, 'refs/heads/main', 'symbolic_target';
is $alias->resolve->target->hex, $c1->hex, 'resolve follows alias -> main -> oid';

# ---- set_target: advance main to a child commit ----
my $c2 = $repo->commit_create( tree => $tree, parents => [$c1], message => 'two' );
my $moved = $main->set_target( $c2, message => 'advance main' );
isa_ok $moved, 'Git::Native::Reference', 'set_target returns a Reference';
is $moved->target->hex, $c2->hex, 'set_target moved main in-memory';
is $repo->reference('refs/heads/main')->target->hex, $c2->hex,
  'set_target persisted on disk';

# ---- symbolic_set_target: repoint alias ----
my $repointed = $alias->symbolic_set_target( 'refs/heads/main', message => 'x' );
is $repointed->symbolic_target, 'refs/heads/main', 'symbolic_set_target';

done_testing;
