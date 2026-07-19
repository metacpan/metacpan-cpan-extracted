use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use File::Spec;

BEGIN {
  my $root = File::Spec->catdir($Bin, '..');
  for my $path (
    File::Spec->catdir($root, 'lib'),
    File::Spec->catdir($root, 'local', 'lib', 'perl5'),
    File::Spec->catdir($root, 'local', 'lib', 'perl5', 'darwin-2level'),
  ) {
    unshift @INC, $path if -d $path;
  }
}

use GraphQL::Houtou qw(execute build_native_runtime parse);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);
use GraphQL::Houtou::Validation::DepthLimit qw(check_query_depth);

# ------------------------------------------------------------------
# Schema: Author -> Book -> Author (cyclic type refs) for depth tests
# ------------------------------------------------------------------
my ($AuthorType, $BookType);
$BookType = GraphQL::Houtou::Type::Object->new(
  name   => 'Book',
  fields => sub { {
    title  => { type => $String, resolve => sub { 'GraphQL in Practice' } },
    author => { type => $AuthorType, resolve => sub { {} } },
  } },
);
$AuthorType = GraphQL::Houtou::Type::Object->new(
  name   => 'Author',
  fields => sub { {
    name => { type => $String, resolve => sub { 'Alice' } },
    book => { type => $BookType, resolve => sub { {} } },
  } },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name   => 'Query',
    fields => {
      author => { type => $AuthorType, resolve => sub { {} } },
    },
  ),
);

# ------------------------------------------------------------------
# Helper: build a query of exactly $depth field-nesting depth.
#   depth 2 = { author { name } }
#   depth 3 = { author { book { title } } }
#   depth N = N fields total (N-1 non-leaf + 1 leaf), alternating Author/Book types
# ------------------------------------------------------------------
sub _query_of_depth {
  my ($depth) = @_;
  return '{ author { name } }' if $depth <= 2;

  # Build N-1 non-leaf fields starting with 'author' (from the query root)
  my @non_leaf = ('author');
  for my $i (2 .. $depth - 1) {
    push @non_leaf, ($i % 2 == 0 ? 'book' : 'author');
  }
  # leaf depends on the type of the last non-leaf field
  my $leaf  = ($non_leaf[-1] eq 'author') ? 'name' : 'title';
  my $inner = $leaf;
  for my $field (reverse @non_leaf) {
    $inner = "$field { $inner }";
  }
  return "{ $inner }";
}

# ------------------------------------------------------------------
subtest 'default depth limit is 15' => sub {
  use GraphQL::Houtou::Validation::DepthLimit;
  is GraphQL::Houtou::Validation::DepthLimit::DEFAULT_MAX_DEPTH(), 15,
    'DEFAULT_MAX_DEPTH constant is 15';
};

subtest 'check_query_depth: depth within limit passes' => sub {
  my $ast    = parse('{ author { name } }');
  my @errors = check_query_depth($ast, max_depth => 3);
  is scalar @errors, 0, 'depth 2 passes max_depth=3';
};

subtest 'check_query_depth: depth exactly at limit passes' => sub {
  my $query  = _query_of_depth(5);
  my $ast    = parse($query);
  my @errors = check_query_depth($ast, max_depth => 5);
  is scalar @errors, 0, 'depth 5 passes max_depth=5';
};

subtest 'check_query_depth: depth exceeds limit returns error' => sub {
  my $query  = _query_of_depth(6);
  my $ast    = parse($query);
  my @errors = check_query_depth($ast, max_depth => 5);
  is scalar @errors, 1, 'depth 6 fails max_depth=5';
  like $errors[0]{message}, qr/depth 6 exceeds maximum allowed depth of 5/i,
    'error message contains depth and limit';
};

subtest 'check_query_depth: max_depth=undef disables check' => sub {
  my $query  = _query_of_depth(20);
  my $ast    = parse($query);
  my @errors = check_query_depth($ast, max_depth => undef);
  is scalar @errors, 0, 'max_depth=undef disables depth check';
};

subtest 'check_query_depth: fragments do not add depth' => sub {
  my $ast = parse(<<'GQL');
fragment AuthorFields on Author { name }
{ author { ...AuthorFields } }
GQL
  my @errors = check_query_depth($ast, max_depth => 2);
  is scalar @errors, 0, 'fragment spread counted at depth of spread site';
};

subtest 'check_query_depth: inline fragments do not add depth' => sub {
  my $ast = parse('{ author { ... on Author { name } } }');
  my @errors = check_query_depth($ast, max_depth => 2);
  is scalar @errors, 0, 'inline fragment does not add extra depth';
};

subtest 'execute: deep query rejected with default limit' => sub {
  # depth 16 — exceeds the default of 15
  my $query  = _query_of_depth(16);
  my $result = $schema->execute($query);
  ok $result->{errors} && @{ $result->{errors} }, 'depth 16 returns errors';
  like $result->{errors}[0]{message}, qr/depth/i, 'error mentions depth';
  ok !defined $result->{data} || !%{ $result->{data} || {} },
    'data is undef or empty on depth error';
};

subtest 'execute: query within default limit succeeds' => sub {
  my $result = $schema->execute('{ author { name } }');
  ok !exists $result->{errors}, 'no errors for shallow query';
  is $result->{data}{author}{name}, 'Alice', 'correct result';
};

subtest 'execute: per-call max_depth override (stricter)' => sub {
  my $result = $schema->execute('{ author { book { title } } }', max_depth => 2);
  ok $result->{errors} && @{ $result->{errors} }, 'depth 3 fails max_depth=2';
};

subtest 'execute: per-call max_depth override (permissive)' => sub {
  my $query  = _query_of_depth(15);
  my $result = $schema->execute($query, max_depth => 15);
  ok !exists $result->{errors}, 'depth 15 passes when max_depth=15';
};

subtest 'execute: max_depth=undef disables limit' => sub {
  my $query  = _query_of_depth(20);
  my $result = $schema->execute($query, max_depth => undef);
  ok !exists $result->{errors}, 'max_depth=undef disables limit';
};

subtest 'build_native_runtime: schema-level max_depth' => sub {
  my $strict = build_native_runtime($schema, max_depth => 2);
  my $ok     = $strict->execute_document('{ author { name } }');
  ok !exists $ok->{errors}, 'depth 2 passes strict runtime';

  my $deep   = $strict->execute_document('{ author { book { title } } }');
  ok $deep->{errors} && @{ $deep->{errors} },
    'depth 3 rejected by strict runtime (max_depth=2)';
};

subtest 'build_native_runtime: per-call max_depth overrides schema-level' => sub {
  my $strict = build_native_runtime($schema, max_depth => 2);
  my $result = $strict->execute_document(
    '{ author { book { title } } }', max_depth => 5,
  );
  ok !exists $result->{errors}, 'per-call max_depth=5 overrides schema-level 2';
};

subtest 'cached program skips redundant depth check' => sub {
  my $runtime = build_native_runtime($schema, max_depth => 10);
  my $query   = '{ author { name } }';

  my $first  = $runtime->execute_document($query);
  my $second = $runtime->execute_document($query);

  ok !exists $first->{errors}, 'first call succeeds';
  ok !exists $second->{errors}, 'second call (cached) succeeds';
  is_deeply $first->{data}, $second->{data}, 'results are identical';
};

done_testing;
