use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Git::Native;
use Git::Native::Revwalker;

my ( $repo, $tmp ) = TestRepo::new_repo();

# Build a small chain: C1 -> C2 -> C3 on refs/heads/main.
my @oids;
my $parent;
for my $i ( 1 .. 3 ) {
  my $blob = $repo->blob_create_frombuffer("commit $i\n");
  my $tb   = $repo->tree_builder;
  $tb->insert( name => 'f', oid => $blob, mode => 0100644 );
  my $tree = $tb->write;
  my $oid  = $repo->commit_create(
    tree    => $tree,
    parents => $parent ? [$parent] : [],
    message => "commit $i",
  );
  push @oids, $oid;
  $parent = $oid;
}
$repo->reference_create( 'refs/heads/main', $oids[-1], force => 1 );

# Walk all commits from main.
my $w = $repo->revwalker;
$w->sorting( Git::Native::Revwalker::GIT_SORT_TOPOLOGICAL );
$w->push_ref('refs/heads/main');
my $all = $w->all;
is scalar(@$all), 3, 'walked 3 commits';

# Topological: newest first. First in walk == last commit we made.
is $all->[0]->hex, $oids[2]->hex, 'tip is C3';
is $all->[2]->hex, $oids[0]->hex, 'root is C1';

# Reset + reverse order.
$w->reset;
$w->sorting( Git::Native::Revwalker::GIT_SORT_TOPOLOGICAL
           | Git::Native::Revwalker::GIT_SORT_REVERSE );
$w->push_ref('refs/heads/main');
my $rev = $w->all;
is $rev->[0]->hex, $oids[0]->hex, 'reversed: root first';

# Hide: walking head while hiding C2 should yield only C3.
my $w2 = $repo->revwalker;
$w2->push_oid( $oids[2] );
$w2->hide_oid( $oids[1] );
my $partial = $w2->all;
is scalar(@$partial), 1, 'hide cuts off ancestors';
is $partial->[0]->hex, $oids[2]->hex, 'only tip remains';

done_testing;
