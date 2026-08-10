use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Git::Native;
use Git::Native::Remote;

# Unit tests for Remote::_expand_push_refspecs. libgit2's git_remote_push
# does NOT expand wildcard refspecs (the CLI does), so Git::Native reimplements
# that expansion in pure Perl - exactly the kind of client-side git-semantics
# reimplementation that bit us with known_hosts (see t/43). t/20 only exercises
# ONE happy-path pattern end-to-end; here we pin the string/regex behaviour
# directly: passthrough, force-prefix, namespace remap, no-match, malformed.

my ( $repo, $tmp ) = TestRepo::new_repo();

# Anchor a commit and plant a handful of refs to expand against.
my $blob = $repo->blob_create_frombuffer("x\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'f', oid => $blob, mode => 0100644 );
my $tree   = $tb->write;
my $commit = $repo->commit_create( tree => $tree, parents => [], message => 'm' );
$repo->reference_create( 'refs/heads/main',       $commit, force => 1 );
$repo->reference_create( 'refs/karr/test/data',   $commit, force => 1 );
$repo->reference_create( 'refs/karr/extra/data',  $commit, force => 1 );

# A remote we never connect through - we only need its _owner repo.
my $remote = $repo->remote_anonymous('file:///nonexistent');

sub expand {
  my (@specs) = @_;
  return Git::Native::Remote::_expand_push_refspecs( $remote, [@specs] );
}

# 1. No wildcard -> passed through verbatim.
is_deeply expand('+refs/heads/main:refs/heads/main'),
  ['+refs/heads/main:refs/heads/main'],
  'non-wildcard refspec passes through unchanged';

# 2. Wildcard src+dst, same namespace -> one concrete refspec per matching ref,
#    force prefix preserved, sorted by ref name.
is_deeply expand('+refs/karr/*:refs/karr/*'),
  [
    '+refs/karr/extra/data:refs/karr/extra/data',
    '+refs/karr/test/data:refs/karr/test/data',
  ],
  'wildcard expands to one refspec per local ref, force prefix kept';

# 3. Wildcard with a DIFFERENT destination namespace -> the captured tail is
#    spliced into dst; missing force prefix stays missing.
is_deeply expand('refs/karr/*:refs/backup/*'),
  [
    'refs/karr/extra/data:refs/backup/extra/data',
    'refs/karr/test/data:refs/backup/test/data',
  ],
  'wildcard remaps src namespace onto a different dst namespace';

# 4. Wildcard matching nothing -> empty (no spurious refspec emitted).
is_deeply expand('+refs/nope/*:refs/nope/*'), [],
  'wildcard with no matching refs expands to nothing';

# 5. Malformed refspec (no colon) -> regex misses, passed through untouched
#    so libgit2 produces the error rather than us silently dropping it.
is_deeply expand('refs/heads/main'), ['refs/heads/main'],
  'colon-less refspec is left for libgit2 to reject';

# 6. Multiple input refspecs are expanded independently and concatenated.
is_deeply expand( 'refs/heads/*:refs/heads/*', '+refs/karr/*:refs/karr/*' ),
  [
    'refs/heads/main:refs/heads/main',
    '+refs/karr/extra/data:refs/karr/extra/data',
    '+refs/karr/test/data:refs/karr/test/data',
  ],
  'several refspecs expand independently and keep input order';

done_testing;
