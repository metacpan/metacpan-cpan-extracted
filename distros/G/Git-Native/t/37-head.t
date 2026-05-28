use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Path::Tiny;
use Git::Native;

my ( $repo, $tmp ) = TestRepo::new_repo();

# ---- fresh repo: HEAD is unborn, head() is undef ----
ok $repo->head_unborn,    'fresh repo: HEAD unborn';
ok !$repo->head_detached, 'fresh repo: HEAD not detached';
is $repo->head, undef,    'head() is undef while unborn';

# ---- commit + set_head -> HEAD resolves ----
my $blob = $repo->blob_create_frombuffer("hi\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'README', oid => $blob, mode => 0100644 );
my $tree = $tb->write;
my $c1   = $repo->commit_create( tree => $tree, parents => [], message => 'one' );
$repo->reference_create( 'refs/heads/main', $c1, force => 1 );
$repo->set_head('refs/heads/main');

ok !$repo->head_unborn, 'HEAD born after set_head + existing branch';
my $h = $repo->head;
isa_ok $h, 'Git::Native::Reference', 'head() returns a Reference';
is $h->shorthand,   'main',    'head resolves to main';
is $h->target->hex, $c1->hex,  'head target is the commit';

# ---- init(initial_branch => ...) pins HEAD even before any commit ----
my $dir = Path::Tiny->tempdir;
my $r2  = Git::Native->init( "$dir", initial_branch => 'main' );
is $r2->reference('HEAD')->symbolic_target, 'refs/heads/main',
  'init(initial_branch) points HEAD at refs/heads/main';
ok $r2->head_unborn, 'main is unborn until first commit';

done_testing;
