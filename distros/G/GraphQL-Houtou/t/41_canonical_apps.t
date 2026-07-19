use strict;
use warnings;
use Test::More;

# Three more canonical GraphQL application shapes, as implemented in every
# mainstream executor's examples: Relay-style cursor pagination
# (connections/edges/pageInfo), a TODO app driven by mutations with input
# objects, and a search field returning a union - the last one both on the
# sync lane and with items arriving through a DataLoader.

BEGIN {
  eval { require Promise::XS; 1 }
    or plan skip_all => 'Promise::XS not available';
}

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Union;
use GraphQL::Houtou::Type::InputObject;
use GraphQL::Houtou::Type::List;
use GraphQL::Houtou::Type::Scalar qw($String $Int $Boolean $ID);
use GraphQL::Houtou::DataLoader;
use MIME::Base64 qw(encode_base64 decode_base64);

# ==========================================================================
# 1. Relay-style cursor pagination
# ==========================================================================
subtest 'relay connection pagination' => sub {
  my @USERS = map { { id => "u$_", name => "user-$_" } } 1 .. 7;
  my $cursor_for = sub { encode_base64("cursor:$_[0]", '') };
  my $offset_for = sub {
    my ($cursor) = @_;
    return -1 if !defined $cursor;
    my ($n) = decode_base64($cursor) =~ /^cursor:(\d+)$/;
    return $n // -1;
  };

  my $User = GraphQL::Houtou::Type::Object->new(
    name => 'PageUser',
    fields => { id => { type => $ID }, name => { type => $String } },
  );
  my $Edge = GraphQL::Houtou::Type::Object->new(
    name => 'UserEdge',
    fields => {
      cursor => { type => $String->non_null },
      node => { type => $User },
    },
  );
  my $PageInfo = GraphQL::Houtou::Type::Object->new(
    name => 'PageInfo',
    fields => {
      hasNextPage => { type => $Boolean->non_null },
      hasPreviousPage => { type => $Boolean->non_null },
      startCursor => { type => $String },
      endCursor => { type => $String },
    },
  );
  my $Connection = GraphQL::Houtou::Type::Object->new(
    name => 'UserConnection',
    fields => {
      edges => { type => GraphQL::Houtou::Type::List->new(of => $Edge) },
      pageInfo => { type => $PageInfo->non_null },
    },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        users => {
          type => $Connection,
          args => {
            first => { type => $Int },
            after => { type => $String },
          },
          resolve => sub {
            my (undef, $args) = @_;
            my $start = $offset_for->($args->{after}) + 1;
            my $first = $args->{first} // scalar @USERS;
            my @slice_idx = grep { $_ < @USERS } $start .. $start + $first - 1;
            return {
              edges => [ map { { cursor => $cursor_for->($_), node => $USERS[$_] } } @slice_idx ],
              pageInfo => {
                hasNextPage => (@slice_idx && $slice_idx[-1] < $#USERS) ? 1 : 0,
                hasPreviousPage => $start > 0 ? 1 : 0,
                startCursor => @slice_idx ? $cursor_for->($slice_idx[0]) : undef,
                endCursor => @slice_idx ? $cursor_for->($slice_idx[-1]) : undef,
              },
            };
          },
        },
      },
    ),
  );
  my $runtime = build_native_runtime($schema);
  my $query = q~
    query Page($first: Int, $after: String) {
      users(first: $first, after: $after) {
        edges { cursor node { id name } }
        pageInfo { hasNextPage hasPreviousPage endCursor }
      }
    }
  ~;

  my $page1 = $runtime->execute_document($query, variables => { first => 3 });
  ok !exists $page1->{errors}, 'page 1: no errors';
  is_deeply [ map { $_->{node}{id} } @{ $page1->{data}{users}{edges} } ],
    [qw(u1 u2 u3)], 'page 1 nodes';
  ok $page1->{data}{users}{pageInfo}{hasNextPage}, 'page 1 has next';
  ok !$page1->{data}{users}{pageInfo}{hasPreviousPage}, 'page 1 has no previous';

  my $page2 = $runtime->execute_document($query, variables => {
    first => 3, after => $page1->{data}{users}{pageInfo}{endCursor},
  });
  is_deeply [ map { $_->{node}{id} } @{ $page2->{data}{users}{edges} } ],
    [qw(u4 u5 u6)], 'page 2 follows the cursor';

  my $page3 = $runtime->execute_document($query, variables => {
    first => 3, after => $page2->{data}{users}{pageInfo}{endCursor},
  });
  is_deeply [ map { $_->{node}{id} } @{ $page3->{data}{users}{edges} } ],
    [qw(u7)], 'final partial page';
  ok !$page3->{data}{users}{pageInfo}{hasNextPage}, 'final page has no next';
};

# ==========================================================================
# 2. TODO app: mutations with input objects, serial execution, defaults
# ==========================================================================
subtest 'todo app mutations' => sub {
  my (%TODOS, $next_id);
  my $reset = sub { %TODOS = (); $next_id = 1 };

  my $Todo = GraphQL::Houtou::Type::Object->new(
    name => 'Todo',
    fields => {
      id => { type => $ID->non_null },
      title => { type => $String->non_null },
      done => { type => $Boolean->non_null },
    },
  );
  my $TodoInput = GraphQL::Houtou::Type::InputObject->new(
    name => 'TodoInput',
    fields => {
      title => { type => $String->non_null },
      done => { type => $Boolean, default_value => 0 },
    },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        todos => {
          type => GraphQL::Houtou::Type::List->new(of => $Todo),
          resolve => sub { [ map { $TODOS{$_} } sort keys %TODOS ] },
        },
      },
    ),
    mutation => GraphQL::Houtou::Type::Object->new(
      name => 'Mutation',
      fields => {
        addTodo => {
          type => $Todo,
          args => { input => { type => $TodoInput->non_null } },
          resolve => sub {
            my (undef, $args) = @_;
            my $id = 't' . $next_id++;
            return $TODOS{$id} = {
              id => $id,
              title => $args->{input}{title},
              done => $args->{input}{done} ? 1 : 0,
            };
          },
        },
        toggleTodo => {
          type => $Todo,
          args => { id => { type => $ID->non_null } },
          resolve => sub {
            my (undef, $args) = @_;
            my $todo = $TODOS{ $args->{id} } or die "no such todo: $args->{id}\n";
            $todo->{done} = $todo->{done} ? 0 : 1;
            return $todo;
          },
        },
        deleteTodo => {
          type => $Boolean->non_null,
          args => { id => { type => $ID->non_null } },
          resolve => sub {
            my (undef, $args) = @_;
            return delete $TODOS{ $args->{id} } ? 1 : 0;
          },
        },
      },
    ),
  );
  my $runtime = build_native_runtime($schema);

  $reset->();
  my $added = $runtime->execute_document(q~
    mutation Seed {
      milk: addTodo(input: { title: "buy milk" }) { id title done }
      taxes: addTodo(input: { title: "file taxes", done: true }) { id done }
    }
  ~);
  is_deeply $added, {
    data => {
      milk => { id => 't1', title => 'buy milk', done => 0 },
      taxes => { id => 't2', done => 1 },
    },
  }, 'literal input objects with a defaulted field';

  my $via_vars = $runtime->execute_document(
    'mutation Add($input: TodoInput!) { addTodo(input: $input) { id title done } }',
    variables => { input => { title => 'walk dog' } },
  );
  is_deeply $via_vars->{data}{addTodo},
    { id => 't3', title => 'walk dog', done => 0 },
    'input object through variables applies the default';

  # serial semantics: the toggle sees the state left by the toggle before it
  my $toggled = $runtime->execute_document(q~
    mutation Flip {
      a: toggleTodo(id: "t1") { done }
      b: toggleTodo(id: "t1") { done }
      c: deleteTodo(id: "t3")
    }
  ~);
  is_deeply $toggled, {
    data => { a => { done => 1 }, b => { done => 0 }, c => 1 },
  }, 'mutations run serially against shared state';

  my $err = $runtime->execute_document('mutation { toggleTodo(id: "nope") { done } }');
  ok !defined $err->{data}{toggleTodo}, 'failed mutation field is null';
  like $err->{errors}[0]{message}, qr/no such todo/, 'mutation error surfaces';

  is_deeply [ map { $_->{id} } @{ $runtime->execute_document('{ todos { id } }')->{data}{todos} } ],
    [qw(t1 t2)], 'query reflects the mutations';
};

# ==========================================================================
# 3. Union search results (sync and via DataLoader)
# ==========================================================================
subtest 'union search results' => sub {
  my %DB = (
    p1 => { kind => 'product', id => 'p1', name => 'Keyboard', price => 90 },
    c1 => { kind => 'category', id => 'c1', name => 'Electronics', productCount => 12 },
    p2 => { kind => 'product', id => 'p2', name => 'Desk Mat', price => 25 },
  );
  my @MATCHES = qw(p1 c1 p2);

  my $build = sub {
    my ($search_resolver) = @_;
    my $Product = GraphQL::Houtou::Type::Object->new(
      name => 'Product',
      runtime_tag => 'product',
      fields => {
        id => { type => $ID },
        name => { type => $String },
        price => { type => $Int },
      },
    );
    my $Category = GraphQL::Houtou::Type::Object->new(
      name => 'Category',
      runtime_tag => 'category',
      fields => {
        id => { type => $ID },
        name => { type => $String },
        productCount => { type => $Int },
      },
    );
    my $SearchResult = GraphQL::Houtou::Type::Union->new(
      name => 'SearchResult',
      types => [ $Product, $Category ],
      tag_resolver => sub { $_[0]{kind} },
    );
    return GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          search => {
            type => GraphQL::Houtou::Type::List->new(of => $SearchResult),
            args => { term => { type => $String } },
            resolve => $search_resolver,
          },
        },
      ),
      types => [ $SearchResult, $Product, $Category ],
    );
  };

  my $query = q~
    {
      search(term: "desk") {
        __typename
        ... on Product { id name price }
        ... on Category { id name productCount }
      }
    }
  ~;
  my $expected = {
    data => {
      search => [
        { __typename => 'Product', id => 'p1', name => 'Keyboard', price => 90 },
        { __typename => 'Category', id => 'c1', name => 'Electronics', productCount => 12 },
        { __typename => 'Product', id => 'p2', name => 'Desk Mat', price => 25 },
      ],
    },
  };

  my $sync_runtime = build_native_runtime(
    $build->(sub { [ map { $DB{$_} } @MATCHES ] })
  );
  is_deeply $sync_runtime->execute_document($query), $expected,
    'sync union list with per-member fragments';

  # the same shape with each item loaded through a DataLoader
  my @batches;
  my $loader = GraphQL::Houtou::DataLoader->new(batch => sub {
    push @batches, [ @{ $_[0] } ];
    return [ map { $DB{$_} } @{ $_[0] } ];
  });
  my $async_runtime = build_native_runtime(
    $build->(sub {
      my (undef, undef, $context) = @_;
      return [ map { $context->{loader}->load($_) } @MATCHES ];
    }),
    async => 1,
  );
  my $async_result = $async_runtime->execute_document($query,
    context => { loader => $loader },
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
  );
  is_deeply $async_result, $expected, 'per-item promises of union members';
  is_deeply \@batches, [ [ qw(p1 c1 p2) ] ], 'one batch for all union items';
};

# ==========================================================================
# 4. Dependency-wave batching beats level-order BFS
#    (regression pin for breadth-wide DataLoader batching)
# ==========================================================================
subtest 'loads at different tree depths share one batch' => sub {
  my %USERS = (
    u1 => { id => 'u1', name => 'alice', boss_id => 'u2' },
    u2 => { id => 'u2', name => 'bob' },
  );
  my @batches;
  my $users = GraphQL::Houtou::DataLoader->new(batch => sub {
    push @batches, [ @{ $_[0] } ];
    return [ map { $USERS{$_} } @{ $_[0] } ];
  });

  my $User;
  $User = GraphQL::Houtou::Type::Object->new(
    name => 'WaveUser',
    fields => sub { {
      name => { type => $String },
      boss => {
        type => $User,
        resolve => sub { $_[0]{boss_id} ? $users->load($_[0]{boss_id}) : undef },
      },
    } },
  );
  my $Wrap2 = GraphQL::Houtou::Type::Object->new(
    name => 'WaveWrap2',
    fields => { user => { type => $User, resolve => sub { $users->load('u1') } } },
  );
  my $Wrap1 = GraphQL::Houtou::Type::Object->new(
    name => 'WaveWrap1',
    fields => { inner => { type => $Wrap2, resolve => sub { {} } } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        shallowUser => { type => $User, resolve => sub { $users->load('u2') } },
        deep => { type => $Wrap1, resolve => sub { {} } },
      },
    ),
  );
  my $result = build_native_runtime($schema, async => 1)->execute_document(
    '{ shallowUser { name } deep { inner { user { name boss { name } } } } }',
    on_stall => GraphQL::Houtou::DataLoader->on_stall_for($users),
  );
  is_deeply $result, {
    data => {
      shallowUser => { name => 'bob' },
      deep => { inner => { user => { name => 'alice', boss => { name => 'bob' } } } },
    },
  }, 'asymmetric-depth query resolves';
  # Loads at tree depths 1 and 3 have the same dependency depth: they must
  # land in ONE batch (level-order BFS would need two), and boss hits the
  # per-request cache instead of a second batch.
  is_deeply \@batches, [ [ qw(u2 u1) ] ],
    'one batch across tree depths, cache absorbs the repeat key';
};

done_testing;
