use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Git::Native;

my ( $repo, $tmp ) = TestRepo::new_repo();

my $blob = $repo->blob_create_frombuffer("hi\n");
my $tb   = $repo->tree_builder;
$tb->insert( name => 'README', oid => $blob, mode => 0100644 );
my $tree   = $tb->write;
my $commit = $repo->commit_create(
  tree    => $tree,
  parents => [],
  message => 'initial',
);

# Lightweight tag - no message, just a ref under refs/tags/.
my $lite_oid = $repo->tag_create( 'v0.0.1-light', $commit );
isa_ok $lite_oid, 'Git::Native::Oid', 'lightweight tag returns Oid';
# Lightweight tags get a ref pointing at the commit itself.
ok $repo->reference_exists('refs/tags/v0.0.1-light'), 'lightweight tag ref exists';

# Annotated tag.
my $tag_oid = $repo->tag_create(
  'v1.0.0', $commit,
  message => "first release\n",
  tagger  => Git::Native::Signature->new( name => 'Tester', email => 't@example' ),
);
isa_ok $tag_oid, 'Git::Native::Oid', 'annotated tag returns Oid';
ok $repo->reference_exists('refs/tags/v1.0.0'), 'annotated tag ref exists';

# Look up annotated tag object.
my $tag = $repo->tag('v1.0.0');
isa_ok $tag, 'Git::Native::Tag', 'tag() returns annotated wrapper';
is $tag->name, 'v1.0.0', 'tag name';
like $tag->message, qr/first release/, 'tag message';
is $tag->target_id->hex, $commit->hex, 'tag points at commit';

# Lightweight tag - tag() returns undef (no annotated object).
my $lite = $repo->tag('v0.0.1-light');
is $lite, undef, 'lightweight tag has no annotated object';

# List tags.
my $names = $repo->tag_names;
is scalar(@$names), 2, 'two tag names';
my %seen = map { $_ => 1 } @$names;
ok $seen{'v0.0.1-light'}, 'lightweight in list';
ok $seen{'v1.0.0'},       'annotated in list';

# Pattern match.
my $v1 = $repo->tag_names( pattern => 'v1.*' );
is scalar(@$v1), 1, 'pattern filter';
is $v1->[0], 'v1.0.0', 'pattern result';

# Delete.
$repo->tag_delete('v0.0.1-light');
ok !$repo->reference_exists('refs/tags/v0.0.1-light'), 'deleted lightweight';

done_testing;
