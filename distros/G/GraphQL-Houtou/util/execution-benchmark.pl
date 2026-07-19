use 5.014;
use strict;
use warnings;

use Benchmark qw(cmpthese);
use FindBin qw($Bin);
use File::Spec;
use Getopt::Long qw(GetOptions);

BEGIN {
  my $root = File::Spec->catdir($Bin, '..');
  my $upstream = File::Spec->catdir($root, '..', 'graphql-perl');

  unshift @INC,
    File::Spec->catdir($root, 'local', 'lib', 'perl5'),
    File::Spec->catdir($root, 'local', 'lib', 'perl5', 'darwin-2level'),
    File::Spec->catdir($root, 'lib'),
    File::Spec->catdir($root, 'blib', 'lib'),
    File::Spec->catdir($root, 'blib', 'arch'),
    File::Spec->catdir($upstream, 'lib');
}

use GraphQL::Execution qw(execute);
use GraphQL::Language::Parser qw(parse);

use GraphQL::Schema;
use GraphQL::Type::Interface;
use GraphQL::Type::Object;
use GraphQL::Type::Scalar ();
use GraphQL::Type::Union;

use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Promise::PromiseXS qw(
  maybe_get_promise_xs
);
use GraphQL::Houtou::Type::Interface ();
use GraphQL::Houtou::Type::Object ();
use GraphQL::Houtou::Type::Scalar ();
use GraphQL::Houtou::Type::Union ();

my $count = -3;
my @only;
my $include_async = 1;
my $promise_backend = 'promise_xs';

GetOptions(
  'count=s' => \$count,
  'case=s@' => \@only,
  'include-async!' => \$include_async,
  'promise-backend=s' => \$promise_backend,
) or die "Usage: $0 [--count Benchmark-count] [--case name] [--include-async|--no-include-async]\n";

my %only = map { $_ => 1 } @only;

sub upstream_promise_xs_code {
  require Promise::XS;
  return {
    resolve => sub { Promise::XS::resolved(@_) },
    reject => sub { Promise::XS::rejected(@_) },
    all => sub {
      my $all_promise = Promise::XS::all(@_);
      return $all_promise->then(sub {
        my @rows = @_;
        my @flattened = map {
          ref($_) eq 'ARRAY' && @{$_} == 1 ? $_->[0] : $_
        } @rows;
        return \@flattened;
      });
    },
    then => sub {
      my ($promise, $on_fulfilled, $on_rejected) = @_;
      return defined $on_rejected
        ? $promise->then($on_fulfilled, $on_rejected)
        : $promise->then($on_fulfilled);
    },
    is_promise => sub {
      my ($value) = @_;
      return !!($value && ref($value) && eval { $value->isa('Promise::XS::Promise') });
    },
  };
}

sub promise_backend {
  my ($backend_name) = @_;
  $backend_name ||= 'promise_xs';

  return {
    name => 'promise_xs',
    upstream_code => upstream_promise_xs_code(),
    resolve => sub {
      require Promise::XS;
      return Promise::XS::resolved(@_);
    },
    maybe_get => sub { maybe_get_promise_xs(@_) },
  } if $backend_name eq 'promise_xs';

  die "Unknown promise backend '$backend_name'\n";
}

sub build_upstream_schema {
  my ($include_async_case, $promise) = @_;

  my $User = GraphQL::Type::Object->new(
    name => 'User',
    fields => {
      id => { type => $GraphQL::Type::Scalar::ID->non_null },
      name => { type => $GraphQL::Type::Scalar::String->non_null },
    },
  );

  my $NamedEntity = GraphQL::Type::Interface->new(
    name => 'NamedEntity',
    resolve_type => sub { 'User' },
    fields => {
      name => { type => $GraphQL::Type::Scalar::String->non_null },
    },
  );

  my $SearchResult = GraphQL::Type::Union->new(
    name => 'SearchResult',
    resolve_type => sub { 'User' },
    types => [ $User ],
  );

  my %fields = (
    hello => {
      type => $GraphQL::Type::Scalar::String->non_null,
      resolve => sub { 'world' },
    },
    greet => {
      type => $GraphQL::Type::Scalar::String->non_null,
      args => {
        name => { type => $GraphQL::Type::Scalar::String->non_null },
      },
      resolve => sub {
        my ($root, $args) = @_;
        return "hello $args->{name}";
      },
    },
    user => {
      type => $User,
      args => {
        id => { type => $GraphQL::Type::Scalar::ID->non_null },
      },
      resolve => sub {
        my ($root, $args) = @_;
        return {
          id => $args->{id},
          name => "user:$args->{id}",
        };
      },
    },
    users => {
      type => $User->list->non_null,
      resolve => sub {
        return [
          { id => '21', name => 'user:21' },
          { id => '22', name => 'user:22' },
        ];
      },
    },
    searchResult => {
      type => $SearchResult,
      resolve => sub {
        return {
          id => '13',
          name => 'search:13',
        };
      },
    },
  );

  if ($include_async_case) {
    $fields{asyncHello} = {
      type => $GraphQL::Type::Scalar::String->non_null,
      resolve => sub {
        return $promise->{resolve}->('async-world');
      },
    };
    $fields{asyncList} = {
      type => $GraphQL::Type::Scalar::String->non_null->list->non_null,
      resolve => sub {
        return [
          $promise->{resolve}->('alpha'),
          $promise->{resolve}->('beta'),
        ];
      },
    };
    $fields{asyncUser} = {
      type => $User,
      resolve => sub {
        return $promise->{resolve}->({
          id => '41',
          name => 'async:41',
        });
      },
    };
    $fields{asyncSearchResult} = {
      type => $SearchResult,
      resolve => sub {
        return $promise->{resolve}->({
          id => '42',
          name => 'async:42',
        });
      },
    };
  }

  my $Query = GraphQL::Type::Object->new(
    name => 'Query',
    fields => \%fields,
  );

  return GraphQL::Schema->new(
    query => $Query,
    types => [ $User, $NamedEntity, $SearchResult ],
  );
}

sub build_houtou_schema {
  my ($include_async_case, $promise) = @_;

  my $User = GraphQL::Houtou::Type::Object->new(
    name => 'User',
    fields => {
      id => { type => $GraphQL::Houtou::Type::Scalar::ID->non_null },
      name => { type => $GraphQL::Houtou::Type::Scalar::String->non_null },
    },
  );

  my $NamedEntity = GraphQL::Houtou::Type::Interface->new(
    name => 'NamedEntity',
    resolve_type => sub { 'User' },
    fields => {
      name => { type => $GraphQL::Houtou::Type::Scalar::String->non_null },
    },
  );

  my $SearchResult = GraphQL::Houtou::Type::Union->new(
    name => 'SearchResult',
    resolve_type => sub { 'User' },
    types => [ $User ],
  );

  my %fields = (
    hello => {
      type => $GraphQL::Houtou::Type::Scalar::String->non_null,
      resolver_mode => 'native',
      resolve => sub { 'world' },
    },
    greet => {
      type => $GraphQL::Houtou::Type::Scalar::String->non_null,
      args => {
        name => { type => $GraphQL::Houtou::Type::Scalar::String->non_null },
      },
      resolver_mode => 'native',
      resolve => sub {
        my ($root, $args) = @_;
        return "hello $args->{name}";
      },
    },
    user => {
      type => $User,
      args => {
        id => { type => $GraphQL::Houtou::Type::Scalar::ID->non_null },
      },
      resolver_mode => 'native',
      resolve => sub {
        my ($root, $args) = @_;
        return {
          id => $args->{id},
          name => "user:$args->{id}",
        };
      },
    },
    users => {
      type => $User->list->non_null,
      resolver_mode => 'native',
      resolve => sub {
        return [
          { id => '21', name => 'user:21' },
          { id => '22', name => 'user:22' },
        ];
      },
    },
    searchResult => {
      type => $SearchResult,
      resolver_mode => 'native',
      resolve => sub {
        return {
          id => '13',
          name => 'search:13',
        };
      },
    },
  );

  if ($include_async_case) {
    $fields{asyncHello} = {
      type => $GraphQL::Houtou::Type::Scalar::String->non_null,
      resolver_mode => 'native',
      resolve => sub {
        return $promise->{resolve}->('async-world');
      },
    };
    $fields{asyncList} = {
      type => $GraphQL::Houtou::Type::Scalar::String->non_null->list->non_null,
      resolver_mode => 'native',
      resolve => sub {
        return [
          $promise->{resolve}->('alpha'),
          $promise->{resolve}->('beta'),
        ];
      },
    };
    $fields{asyncUser} = {
      type => $User,
      resolver_mode => 'native',
      resolve => sub {
        return $promise->{resolve}->({
          id => '41',
          name => 'async:41',
        });
      },
    };
    $fields{asyncSearchResult} = {
      type => $SearchResult,
      resolver_mode => 'native',
      resolve => sub {
        return $promise->{resolve}->({
          id => '42',
          name => 'async:42',
        });
      },
    };
  }

  my $Query = GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => \%fields,
  );

  return GraphQL::Houtou::Schema->new(
    query => $Query,
    types => [ $User, $NamedEntity, $SearchResult ],
  );
}

sub benchmark_case {
  my ($name, $spec, $up_schema, $houtou_schema) = @_;
  return if @only && !$only{$name};

  my $query = $spec->{query};
  my $vars = $spec->{vars};
  my $op = $spec->{op};
  # Real web traffic sends different variable values on every request; a
  # generator case measures that instead of the 100%-cache-hit shape the
  # fixed-vars cases produce.
  my $vars_generator = $spec->{vars_generator};
  my $json_codec = $spec->{json} ? do { require JSON::MaybeXS; JSON::MaybeXS->new->utf8 } : undef;
  my $promise = $spec->{promise} ? promise_backend($promise_backend) : undef;
  my $upstream_promise_code = $promise ? $promise->{upstream_code} : undef;
  my $up_ast = parse($query);
  my $runtime = $houtou_schema->build_runtime;
  my $program = $runtime->compile_program($query);
  my $native_runtime = !$promise ? $houtou_schema->build_native_runtime : undef;
  my $native_bundle = ($native_runtime && !$vars_generator)
    ? $native_runtime->compile_bundle(
        $program,
        (defined($vars) ? (variables => $vars) : ()),
      )
    : undef;

  my $expected;
  $expected = _normalize_result(($promise ? $promise->{maybe_get} : \&maybe_get_promise_xs)->(
    $promise
      ? $runtime->execute_program(
        $program,
        (defined($vars) ? (variables => $vars) : ()),
      )
      : execute(
        $up_schema,
        $up_ast,
        undef,
        undef,
        $vars,
        $op,
        undef,
        $upstream_promise_code,
      )
  ));

  my $call_vars = $vars_generator
    ? sub { $vars_generator->() }
    : sub { $vars };

  my @checks;
  if (!$promise) {
    push @checks,
      [ 'upstream_ast', sub {
        return maybe_get_promise_xs(
          execute($up_schema, $up_ast, undef, undef, $call_vars->(), $op, undef, $upstream_promise_code)
        );
      } ],
      [ 'upstream_string', sub {
        return maybe_get_promise_xs(
          execute($up_schema, $query, undef, undef, $call_vars->(), $op, undef, $upstream_promise_code)
        );
      } ];
  }

  push @checks, [ 'houtou_runtime_program', sub {
    my $request_vars = $call_vars->();
    return ($promise ? $promise->{maybe_get} : \&maybe_get_promise_xs)->(
      $runtime->execute_program(
        $program,
        (defined($request_vars) ? (variables => $request_vars) : ()),
      )
    );
  } ];

  if ($native_bundle) {
    push @checks, [ 'houtou_runtime_native_bundle', sub {
      return maybe_get_promise_xs(
        $native_runtime->execute_bundle($native_bundle)
      );
    } ];
  }

  for my $check (@checks) {
    my ($label, $code) = @$check;
    my $got = _normalize_result($code->());
    die "Sanity check failed for $name/$label\n" if !$got;
    if ($vars_generator) {
      # Values differ per generated variable set; assert shape only.
      die "Sanity check failed for $name/$label (errors present)\n"
        if !defined $got->{data} || @{ $got->{errors} || [] };
      next;
    }
    require Data::Dumper;
    die "Result mismatch for $name/$label\nExpected: " . Data::Dumper::Dumper($expected) . "Got: " . Data::Dumper::Dumper($got)
      if _dump($got) ne _dump($expected);
  }

  if ($json_codec) {
    @checks = map {
      my ($label, $code) = @$_;
      [ $label, sub { return $json_codec->encode($code->()) } ];
    } @checks;
    if ($native_bundle) {
      push @checks, [ 'houtou_bundle_to_json', sub {
        return $native_runtime->execute_bundle_to_json($native_bundle);
      } ];
    }
    push @checks, [ 'houtou_document_to_json', sub {
      return $native_runtime ? $native_runtime->execute_document_to_json($query) : undef;
    } ] if $native_runtime;
  }

  print "\n=== $name ===\n";
  print "Query: $query\n";
  print "Mode: " . ($spec->{promise} ? "promise-backed execute ($promise_backend)" : "sync execute")
    . ($vars_generator ? ' (fresh variables per request)' : '')
    . ($json_codec ? ' (+ JSON encode)' : '')
    . "\n";
  cmpthese($count, { map { $_->[0] => $_->[1] } @checks });
}

# L3 checkpoint case: the native async lane with promises that are already
# resolved when execution sees them (the DataLoader steady state after a
# flush). The sync fast lane on the same query shape is the reference cost;
# the gap between the two is what L3 works on. 20-item object list with 3
# fields, variables carried so the sync runtime takes the fast lane.
sub benchmark_async_preresolved {
  require Promise::XS;
  require JSON::MaybeXS;

  my $query = 'query q($n: Int) { items(n: $n) { id name qty } }';
  my $vars = { n => 20 };
  # Rows are rebuilt per request (like DB rows in production) rather than
  # shared between the runtimes: serializing a shared SV marks it POK, and
  # the async lanes' native tree serializes dualvars string-first (no
  # GraphQL type info there yet - plan P3), which would fail the sanity
  # comparison on "1" vs 1 rather than on a real lane difference. qty is a
  # fresh IV for the same reason ($i itself goes POK via interpolation).
  my $make_rows = sub {
    return [ map { my $i = $_; { id => "i$i", name => "item-$i", qty => 0 + $i } } 1 .. 20 ];
  };

  my $item_fields = {
    id => { type => $GraphQL::Houtou::Type::Scalar::ID },
    name => { type => $GraphQL::Houtou::Type::Scalar::String },
    qty => { type => $GraphQL::Houtou::Type::Scalar::Int },
  };
  my $make_schema = sub {
    my ($resolve) = @_;
    my $Item = GraphQL::Houtou::Type::Object->new(name => 'Item', fields => $item_fields);
    return GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          items => {
            type => $Item->list,
            args => { n => { type => $GraphQL::Houtou::Type::Scalar::Int } },
            resolve => $resolve,
          },
        },
      ),
    );
  };

  my $sync_rt = $make_schema->(sub { $make_rows->() })->build_native_runtime;
  my $async_rt = $make_schema->(sub { Promise::XS::resolved($make_rows->()) })
    ->build_native_runtime(async => 1);
  my $async_items_rt = $make_schema->(
    sub { [ map { Promise::XS::resolved($_) } @{ $make_rows->() } ] }
  )->build_native_runtime(async => 1);

  my %modes = (
    houtou_sync_sv => sub {
      return $sync_rt->execute_document($query, variables => $vars);
    },
    houtou_async_sv => sub {
      return maybe_get_promise_xs(
        $async_rt->execute_document($query, variables => $vars));
    },
    houtou_async_items_sv => sub {
      return maybe_get_promise_xs(
        $async_items_rt->execute_document($query, variables => $vars));
    },
    houtou_sync_json => sub {
      return $sync_rt->execute_document_to_json($query, variables => $vars);
    },
    houtou_async_json => sub {
      return $async_rt->execute_document_to_json($query, variables => $vars);
    },
  );

  my $json = JSON::MaybeXS->new->utf8;
  my $expected = _normalize_result($modes{houtou_sync_sv}->());
  for my $mode (sort keys %modes) {
    my $got = $modes{$mode}->();
    $got = _normalize_result(ref $got ? $got : $json->decode($got));
    # JSON-lane key order follows completion order; compare decoded trees.
    die "Result mismatch for async_preresolved/$mode\n"
      if _dump($got) ne _dump($expected);
  }

  print "\n=== async_preresolved ===\n";
  print "Query: $query\n";
  print "Mode: native runtime, pre-resolved Promise::XS vs sync fast lane\n";
  cmpthese($count, \%modes);
}

sub _dump {
  require Data::Dumper;
  local $Data::Dumper::Sortkeys = 1;
  return Data::Dumper::Dumper($_[0]);
}

sub _normalize_result {
  my ($value) = @_;
  return $value if ref($value) ne 'HASH';
  my %copy = %{$value};
  $copy{errors} ||= [];
  return \%copy;
}

my $promise = promise_backend($promise_backend);
my $up_schema = build_upstream_schema($include_async, $promise);
my $houtou_schema = build_houtou_schema($include_async, $promise);

my @cases = (
  {
    name => 'simple_scalar',
    query => '{ hello greet(name: "houtou") }',
  },
  {
    name => 'nested_variable_object',
    query => 'query q($id: ID!) { user(id: $id) { id name } }',
    vars => { id => '42' },
    op => 'q',
  },
  {
    name => 'list_of_objects',
    query => '{ users { id name } }',
  },
  {
    name => 'abstract_with_fragment',
    query => '{ searchResult { __typename ... on User { id name } } }',
  },
  {
    name => 'varying_variables',
    query => 'query q($id: ID!) { user(id: $id) { id name } }',
    vars => { id => '42' },
    vars_generator => do { my $n = 0; sub { return { id => 'v' . (++$n) } } },
    op => 'q',
  },
  {
    name => 'list_of_objects_json',
    query => '{ users { id name } }',
    json => 1,
  },
);

push @cases, {
  name => 'async_scalar',
  query => '{ asyncHello }',
  promise => 1,
} if $include_async;

push @cases, {
  name => 'async_list',
  query => '{ asyncList }',
  promise => 1,
} if $include_async;

push @cases, {
  name => 'async_object',
  query => '{ asyncUser { id name } }',
  promise => 1,
} if $include_async;

push @cases, {
  name => 'async_abstract',
  query => '{ asyncSearchResult { __typename ... on User { id name } } }',
  promise => 1,
} if $include_async;

print "Benchmark count: $count\n";
print "Using built GraphQL::Houtou from blib and upstream GraphQL from sibling checkout.\n";

for my $case (@cases) {
  benchmark_case($case->{name}, $case, $up_schema, $houtou_schema);
}

benchmark_async_preresolved()
  if $include_async && (!@only || $only{async_preresolved});
