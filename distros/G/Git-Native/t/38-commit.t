use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Git::Native;
use Git::Native::Signature;

my ( $repo, $tmp ) = TestRepo::new_repo();

# Deterministic timestamp so time/time_offset are checkable.
my $when   = 1_600_000_000;   # 2020-09-13T12:26:40Z
my $offset = 120;             # +02:00
my $sig    = Git::Native::Signature->new(
  name   => 'Tester',
  email  => 'tester@example.invalid',
  when   => $when,
  offset => $offset,
);

my $blob = $repo->blob_create_frombuffer("hi\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'README', oid => $blob, mode => 0100644 );
my $tree = $tb->write;
my $oid  = $repo->commit_create(
  tree      => $tree,
  parents   => [],
  message   => "summary line\n\nbody paragraph here\n",
  author    => $sig,
  committer => $sig,
);

my $commit = $repo->commit($oid);
is $commit->summary, 'summary line', 'summary is the first paragraph';
like $commit->message, qr/body paragraph here/, 'message keeps the body';
is $commit->time, $when, 'time is the committer epoch';
is $commit->time_offset, $offset, 'time_offset in minutes east of UTC';

done_testing;
