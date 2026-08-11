use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;

# Blob->content casts the raw pointer with "string($size)" rather than
# treating it as a NUL-terminated C string. Two consequences were never
# tested: an empty blob (pointer may be non-NULL but size 0 - the guard that
# returns '' instead of casting a zero-length string), and binary content with
# embedded NUL bytes, which is exactly what the size-based cast is for. A
# strlen-based implementation would pass the existing suite and truncate here.

my ( $repo, $tmp ) = TestRepo::new_repo();

subtest 'an empty blob has size 0 and empty content' => sub {
  my $oid = $repo->blob_create_frombuffer('');

  # git's empty blob has a fixed OID.
  is "$oid", 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391',
    'the empty blob hashes to the well-known empty-blob OID';

  my $blob = $repo->blob($oid);
  is $blob->size, 0, 'size is 0';
  is $blob->content, '', 'content is the empty string, not undef';
  is $blob->oid->hex, $oid->hex, 'oid round-trips';
};

subtest 'binary content survives embedded NUL bytes' => sub {
  my $bin = "head\0middle\ntail\0";
  my $oid = $repo->blob_create_frombuffer($bin);

  my $blob = $repo->blob($oid);
  is $blob->size, length($bin), 'size is the full byte count, not the length to the first NUL';
  is $blob->content, $bin, 'content round-trips byte for byte';
  is length( $blob->content ), length($bin), 'nothing was truncated at a NUL';
};

subtest 'text content round-trips and the oid is stable' => sub {
  my $text = "line one\nline two\n";
  my $oid  = $repo->blob_create_frombuffer($text);
  my $blob = $repo->blob($oid);

  is $blob->content, $text, 'content round-trips';
  is $blob->size, length($text), 'size matches';
  is $blob->oid->hex, $oid->hex, 'oid is the one create returned';
  is $blob->oid->hex, $oid->hex, 'oid is stable across calls (lazy build)';

  # Same bytes hash to the same object - blob_create_frombuffer is content
  # addressed, not append-only.
  is $repo->blob_create_frombuffer($text)->hex, $oid->hex,
    're-creating identical content yields the same OID';
};

subtest 'blob lookup of a non-blob OID fails typed' => sub {
  my $tb = $repo->tree_builder;
  $tb->insert(
    name => 'f', oid => $repo->blob_create_frombuffer("x\n"), mode => 0100644,
  );
  my $tree_oid = $tb->write;

  my $err = dies { $repo->blob($tree_oid) };
  isa_ok $err, ['Git::Native::Error'], 'blob() on a tree OID throws';
  ok !$err->isa('Git::Libgit2::Error'), 'the low-level error does not leak';
  ok $err->code < 0, 'with a negative libgit2 code';
};

done_testing;
