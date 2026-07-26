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
use GraphQL::Houtou::Type::List ();
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

sub benchmark_async_preresolved_leaf {
  require Promise::XS;
  require GraphQL::Houtou::DataLoader;

  my $query = 'query q($name: String) { greeting(name: $name) }';
  my $vars = { name => 'Houtou' };
  my $make_schema = sub {
    my ($resolve) = @_;
    return GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          greeting => {
            type => $GraphQL::Houtou::Type::Scalar::String,
            args => {
              name => { type => $GraphQL::Houtou::Type::Scalar::String },
            },
            resolve => $resolve,
          },
        },
      ),
    );
  };
  my $sync_rt = $make_schema->(
    sub { my ($source, $args) = @_; return "hello $args->{name}" }
  )->build_native_runtime;
  my $async_rt = $make_schema->(
    sub {
      my ($source, $args) = @_;
      return Promise::XS::resolved("hello $args->{name}");
    }
  )->build_native_runtime(async => 1);
  # Ticket-ready: a DataLoader ticket already fulfilled (primed) by the time
  # the resolver returns it - fast_lane_guard_promise_sv unwraps it in place
  # without ever entering the suspension channel. The loader is built and
  # primed once, outside the timed closure, so this isolates the XS-level
  # unwrap cost from Perl-level DataLoader construction cost (which is a
  # separate, already-benchmarked concern in util/dataloader-benchmark.pl).
  my $ticket_ready_loader = GraphQL::Houtou::DataLoader->new(
    batch => sub { my ($keys) = @_; return [map { "hello $_" } @$keys] },
  );
  $ticket_ready_loader->prime($vars->{name}, "hello $vars->{name}");
  my $ticket_ready_rt = $make_schema->(
    sub {
      my ($source, $args) = @_;
      return $ticket_ready_loader->load($args->{name});
    }
  )->build_native_runtime(async => 1);
  # Ticket-pending: a genuinely pending DataLoader ticket, driven to
  # completion via on_stall - exercises the direct
  # gql_runtime_vm_subscribe_dataloader_ticket suspend/resume path instead
  # of the Promise::XS then() bridge.
  my $pending_loader;
  my $ticket_pending_rt = $make_schema->(
    sub {
      my ($source, $args) = @_;
      return $pending_loader->load($args->{name});
    }
  )->build_native_runtime(async => 1);
  my %modes = (
    houtou_sync_leaf_sv => sub {
      return $sync_rt->execute_document($query, variables => $vars);
    },
    houtou_async_leaf_sv => sub {
      return maybe_get_promise_xs(
        $async_rt->execute_document($query, variables => $vars)
      );
    },
    houtou_async_leaf_ticket_ready_sv => sub {
      return maybe_get_promise_xs(
        $ticket_ready_rt->execute_document($query, variables => $vars)
      );
    },
    houtou_async_leaf_ticket_pending_sv => sub {
      $pending_loader = GraphQL::Houtou::DataLoader->new(
        batch => sub { my ($keys) = @_; return [map { "hello $_" } @$keys] },
      );
      return maybe_get_promise_xs(
        $ticket_pending_rt->execute_document(
          $query,
          variables => $vars,
          on_stall => GraphQL::Houtou::DataLoader->on_stall_for($pending_loader),
        )
      );
    },
  );
  my $expected = _normalize_result($modes{houtou_sync_leaf_sv}->());
  for my $mode (sort keys %modes) {
    my $got = _normalize_result($modes{$mode}->());
    die "Result mismatch for async_preresolved_leaf/$mode\n"
      if _dump($got) ne _dump($expected);
  }

  print "\n=== async_preresolved_leaf ===\n";
  print "Query: $query\n";
  print "Mode: native runtime, pre-resolved Promise::XS/Ticket leaf vs sync leaf\n";
  cmpthese($count, \%modes);
}

sub benchmark_async_multi_leaf {
  require Promise::XS;
  require GraphQL::Houtou::DataLoader;

  # Phase 3: root has N nullable scalar sibling leaves; one of them
  # (the last) is DataLoader-Ticket-backed and genuinely pending, the rest
  # resolve synchronously. Before Phase 3 this shape always fell back to
  # the generic async executor (op_count > 1); this benchmark exercises the
  # new lazily-promoted block_frame_t continuation added for it.
  for my $width (2, 5, 10) {
    my @field_names = map { "f$_" } 1 .. $width;
    my $query = 'query q(' . join(', ', map { "\$v$_: String" } 1 .. $width) . ') { '
      . join(' ', map { "f$_(id: \$v$_)" } 1 .. $width) . ' }';
    my $vars = { map { ("v$_" => "id$_") } 1 .. $width };

    my $build_fields = sub {
      my ($last_resolve) = @_;
      my %fields;
      for my $i (1 .. $width - 1) {
        $fields{"f$i"} = {
          type => $GraphQL::Houtou::Type::Scalar::String,
          args => { id => { type => $GraphQL::Houtou::Type::Scalar::String } },
          resolve => sub { my (undef, $args) = @_; return "sync:$args->{id}" },
        };
      }
      $fields{"f$width"} = {
        type => $GraphQL::Houtou::Type::Scalar::String,
        args => { id => { type => $GraphQL::Houtou::Type::Scalar::String } },
        resolve => $last_resolve,
      };
      return \%fields;
    };

    my $sync_rt = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => $build_fields->(
          sub { my (undef, $args) = @_; return "sync:$args->{id}" }
        ),
      ),
    )->build_native_runtime;

    my $pending_loader;
    my $async_rt = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => $build_fields->(
          sub { my (undef, $args) = @_; return $pending_loader->load($args->{id}) }
        ),
      ),
    )->build_native_runtime(async => 1);

    my %modes = (
      "houtou_sync_multi${width}_sv" => sub {
        return $sync_rt->execute_document($query, variables => $vars);
      },
      "houtou_async_multi${width}_sv" => sub {
        $pending_loader = GraphQL::Houtou::DataLoader->new(
          batch => sub { my ($keys) = @_; return [ map { "batched:$_" } @$keys ] },
        );
        return maybe_get_promise_xs(
          $async_rt->execute_document(
            $query,
            variables => $vars,
            on_stall => GraphQL::Houtou::DataLoader->on_stall_for($pending_loader),
          )
        );
      },
    );

    my $sync_result = _normalize_result($modes{"houtou_sync_multi${width}_sv"}->());
    my $async_result = _normalize_result($modes{"houtou_async_multi${width}_sv"}->());
    # The last field differs (sync:idN vs batched:idN by design); compare
    # everything else and the last field's shape only.
    for my $i (1 .. $width - 1) {
      die "Result mismatch for async_multi_leaf/width=$width field f$i\n"
        if ($sync_result->{data}{"f$i"} // '') ne "sync:id$i";
    }
    die "Result mismatch for async_multi_leaf/width=$width last field\n"
      unless ($async_result->{data}{"f$width"} // '') eq "batched:id$width";

    print "\n=== async_multi_leaf (width=$width) ===\n";
    print "Query: $width sibling leaves, 1 DataLoader-Ticket-pending\n";
    cmpthese($count, \%modes);
  }
}

sub benchmark_async_leaf_list {
  require GraphQL::Houtou::DataLoader;

  # Phase 4: root has a single plain-leaf list field (no child block, no
  # abstract dispatch); every item is DataLoader-Ticket-backed and settles
  # in one shared batch. Before Phase 4 a LIST op was unconditionally
  # ineligible for the fast root continuation, so this shape always fell
  # back to the generic async executor; this benchmark exercises the new
  # item-level list_pending continuation added for it.
  for my $width (2, 5, 10) {
    my $query = 'query q($ids: [String]) { names(ids: $ids) }';
    my $vars = { ids => [ map { "id$_" } 1 .. $width ] };

    my $build_schema = sub {
      my ($resolve) = @_;
      return GraphQL::Houtou::Schema->new(
        query => GraphQL::Houtou::Type::Object->new(
          name => 'Query',
          fields => {
            names => {
              type => GraphQL::Houtou::Type::List->new(
                of => $GraphQL::Houtou::Type::Scalar::String
              ),
              args => {
                ids => {
                  type => GraphQL::Houtou::Type::List->new(
                    of => $GraphQL::Houtou::Type::Scalar::String
                  ),
                },
              },
              resolve => $resolve,
            },
          },
        ),
      );
    };

    my $sync_rt = $build_schema->(
      sub { my (undef, $args) = @_; return [ map { "sync:$_" } @{ $args->{ids} } ] }
    )->build_native_runtime;

    my $pending_loader;
    my $async_rt = $build_schema->(
      sub {
        my (undef, $args, $ctx) = @_;
        return [ map { $pending_loader->load($_) } @{ $args->{ids} } ];
      }
    )->build_native_runtime(async => 1);

    my %modes = (
      "houtou_sync_leaf_list${width}_sv" => sub {
        return $sync_rt->execute_document($query, variables => $vars);
      },
      "houtou_async_leaf_list${width}_sv" => sub {
        $pending_loader = GraphQL::Houtou::DataLoader->new(
          batch => sub { my ($keys) = @_; return [ map { "batched:$_" } @$keys ] },
        );
        return maybe_get_promise_xs(
          $async_rt->execute_document(
            $query,
            variables => $vars,
            on_stall => GraphQL::Houtou::DataLoader->on_stall_for($pending_loader),
          )
        );
      },
    );

    my $async_result = _normalize_result($modes{"houtou_async_leaf_list${width}_sv"}->());
    for my $i (1 .. $width) {
      die "Result mismatch for async_leaf_list/width=$width item $i\n"
        unless ($async_result->{data}{names}[$i - 1] // '') eq "batched:id$i";
    }

    print "\n=== async_leaf_list (width=$width) ===\n";
    print "Query: single root list field, $width DataLoader-Ticket-pending items\n";
    cmpthese($count, \%modes);
  }
}

sub benchmark_async_object_list_item_field {
  require GraphQL::Houtou::DataLoader;

  # Phase 5: root has a single list field whose items are objects; each
  # item's own child block has one sync field and one DataLoader-Ticket-
  # pending field, settling in one shared batch. Before Phase 5 a LIST op
  # with child_block_index >= 0 was unconditionally ineligible for the
  # fast root continuation, so this shape always fell back to the generic
  # async executor; this benchmark exercises the new per-item child-block
  # wrapper (gql_runtime_vm_execute_list_item_child_block_fast_sv) added
  # for it - the 2-level-deep suspension case (list -> item -> item's own
  # field) that benchmark_async_preresolved's Item type never exercises
  # (its fields are always plain sync leaves).
  for my $width (2, 5, 10) {
    my $query = 'query q($ids: [String]) { rows(ids: $ids) { id name } }';
    my $vars = { ids => [ map { "id$_" } 1 .. $width ] };

    my $build_schema = sub {
      my ($name_resolve) = @_;
      my $Row = GraphQL::Houtou::Type::Object->new(
        name => 'Row',
        fields => {
          id => { type => $GraphQL::Houtou::Type::Scalar::String },
          name => { type => $GraphQL::Houtou::Type::Scalar::String, resolve => $name_resolve },
        },
      );
      return GraphQL::Houtou::Schema->new(
        query => GraphQL::Houtou::Type::Object->new(
          name => 'Query',
          fields => {
            rows => {
              type => GraphQL::Houtou::Type::List->new(of => $Row),
              args => {
                ids => {
                  type => GraphQL::Houtou::Type::List->new(
                    of => $GraphQL::Houtou::Type::Scalar::String
                  ),
                },
              },
              resolve => sub {
                my (undef, $args) = @_;
                return [ map { { id => $_ } } @{ $args->{ids} } ];
              },
            },
          },
        ),
      );
    };

    my $sync_rt = $build_schema->(
      sub { return "sync:$_[0]{id}" }
    )->build_native_runtime;

    my $pending_loader;
    my $async_rt = $build_schema->(
      sub { my ($source, undef, $ctx) = @_; return $pending_loader->load($source->{id}) }
    )->build_native_runtime(async => 1);

    my %modes = (
      "houtou_sync_object_list${width}_sv" => sub {
        return $sync_rt->execute_document($query, variables => $vars);
      },
      "houtou_async_object_list${width}_sv" => sub {
        $pending_loader = GraphQL::Houtou::DataLoader->new(
          batch => sub { my ($keys) = @_; return [ map { "batched:$_" } @$keys ] },
        );
        return maybe_get_promise_xs(
          $async_rt->execute_document(
            $query,
            variables => $vars,
            on_stall => GraphQL::Houtou::DataLoader->on_stall_for($pending_loader),
          )
        );
      },
    );

    my $async_result = _normalize_result($modes{"houtou_async_object_list${width}_sv"}->());
    for my $i (1 .. $width) {
      die "Result mismatch for async_object_list_item_field/width=$width item $i\n"
        unless ($async_result->{data}{rows}[$i - 1]{name} // '') eq "batched:id$i";
    }

    print "\n=== async_object_list_item_field (width=$width) ===\n";
    print "Query: single root object-list field, $width items each with one sync + one DataLoader-Ticket-pending field\n";
    cmpthese($count, \%modes);
  }
}

sub benchmark_async_nested_object_list_item_field {
  require GraphQL::Houtou::DataLoader;

  # Phase 6: root has a single list field whose items are objects, and
  # each item's own "author" field is ITSELF another object whose own
  # child block has one sync field and one DataLoader-Ticket-pending
  # field. Before Phase 6 any object/abstract field nested inside a list
  # item's own child block forced the whole list field back to the
  # generic async executor; this benchmark exercises the new recursive
  # per-item/per-nested-field wrapper
  # (gql_runtime_vm_execute_safe_child_block_fast_sv, reused one level
  # deeper) added for it.
  for my $width (2, 5, 10) {
    my $query = 'query q($ids: [String]) { posts(ids: $ids) { title author { name } } }';
    my $vars = { ids => [ map { "id$_" } 1 .. $width ] };

    my $build_schema = sub {
      my ($author_name_resolve) = @_;
      my $Author = GraphQL::Houtou::Type::Object->new(
        name => 'Author',
        fields => {
          name => { type => $GraphQL::Houtou::Type::Scalar::String, resolve => $author_name_resolve },
        },
      );
      my $Post = GraphQL::Houtou::Type::Object->new(
        name => 'Post',
        fields => {
          title => { type => $GraphQL::Houtou::Type::Scalar::String, resolve => sub { "t:$_[0]{id}" } },
          author => { type => $Author, resolve => sub { { id => $_[0]{id} } } },
        },
      );
      return GraphQL::Houtou::Schema->new(
        query => GraphQL::Houtou::Type::Object->new(
          name => 'Query',
          fields => {
            posts => {
              type => GraphQL::Houtou::Type::List->new(of => $Post),
              args => {
                ids => {
                  type => GraphQL::Houtou::Type::List->new(
                    of => $GraphQL::Houtou::Type::Scalar::String
                  ),
                },
              },
              resolve => sub {
                my (undef, $args) = @_;
                return [ map { { id => $_ } } @{ $args->{ids} } ];
              },
            },
          },
        ),
      );
    };

    my $sync_rt = $build_schema->(
      sub { return "sync:$_[0]{id}" }
    )->build_native_runtime;

    my $pending_loader;
    my $async_rt = $build_schema->(
      sub { my ($source, undef, $ctx) = @_; return $pending_loader->load($source->{id}) }
    )->build_native_runtime(async => 1);

    my %modes = (
      "houtou_sync_nested_object_list${width}_sv" => sub {
        return $sync_rt->execute_document($query, variables => $vars);
      },
      "houtou_async_nested_object_list${width}_sv" => sub {
        $pending_loader = GraphQL::Houtou::DataLoader->new(
          batch => sub { my ($keys) = @_; return [ map { "batched:$_" } @$keys ] },
        );
        return maybe_get_promise_xs(
          $async_rt->execute_document(
            $query,
            variables => $vars,
            on_stall => GraphQL::Houtou::DataLoader->on_stall_for($pending_loader),
          )
        );
      },
    );

    my $async_result = _normalize_result($modes{"houtou_async_nested_object_list${width}_sv"}->());
    for my $i (1 .. $width) {
      die "Result mismatch for async_nested_object_list_item_field/width=$width item $i\n"
        unless ($async_result->{data}{posts}[$i - 1]{author}{name} // '') eq "batched:id$i";
    }

    print "\n=== async_nested_object_list_item_field (width=$width) ===\n";
    print "Query: single root object-list field, $width items each with a nested object field whose own sub-field is DataLoader-Ticket-pending\n";
    cmpthese($count, \%modes);
  }
}

sub benchmark_async_single_root_object_field {
  require GraphQL::Houtou::DataLoader;

  # Phase 7: root has a single (non-list) object field, whose own "team"
  # field is itself another object with one sync field and one
  # DataLoader-Ticket-pending field. Before Phase 7 any root op with
  # complete_code OBJECT/ABSTRACT forced the whole request back to the
  # generic async executor; this benchmark exercises the eligibility guard
  # widening that reuses Phase 5/6's per-field/per-nested-field wrapper
  # (gql_runtime_vm_execute_safe_child_block_fast_sv) from the root itself.
  my $query = 'query q($id: String) { user(id: $id) { name team { name } } }';
  my $vars = { id => 'u1' };

  my $build_schema = sub {
    my ($team_name_resolve) = @_;
    my $Team = GraphQL::Houtou::Type::Object->new(
      name => 'Team',
      fields => {
        name => { type => $GraphQL::Houtou::Type::Scalar::String, resolve => $team_name_resolve },
      },
    );
    my $User = GraphQL::Houtou::Type::Object->new(
      name => 'User',
      fields => {
        name => { type => $GraphQL::Houtou::Type::Scalar::String, resolve => sub { "n:$_[0]{id}" } },
        team => { type => $Team, resolve => sub { { id => $_[0]{id} } } },
      },
    );
    return GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          user => {
            type => $User,
            args => { id => { type => $GraphQL::Houtou::Type::Scalar::String } },
            resolve => sub { my (undef, $args) = @_; return { id => $args->{id} } },
          },
        },
      ),
    );
  };

  my $sync_rt = $build_schema->(
    sub { return "sync:$_[0]{id}" }
  )->build_native_runtime;

  # Same shape, but built async => 1 with a plain synchronous resolver: this
  # is the case Phase 7's eligibility widening targets - the fixed cost of
  # the previously-unconditional generic-executor fallback for this shape,
  # not the genuinely-suspending case below.
  my $async_all_sync_rt = $build_schema->(
    sub { return "sync:$_[0]{id}" }
  )->build_native_runtime(async => 1);

  my $pending_loader;
  my $async_rt = $build_schema->(
    sub { my ($source, undef, $ctx) = @_; return $pending_loader->load($source->{id}) }
  )->build_native_runtime(async => 1);

  my %modes = (
    'houtou_sync_single_root_object_field_sv' => sub {
      return $sync_rt->execute_document($query, variables => $vars);
    },
    'houtou_async_all_sync_single_root_object_field_sv' => sub {
      return $async_all_sync_rt->execute_document($query, variables => $vars);
    },
    'houtou_async_single_root_object_field_sv' => sub {
      $pending_loader = GraphQL::Houtou::DataLoader->new(
        batch => sub { my ($keys) = @_; return [ map { "batched:$_" } @$keys ] },
      );
      return maybe_get_promise_xs(
        $async_rt->execute_document(
          $query,
          variables => $vars,
          on_stall => GraphQL::Houtou::DataLoader->on_stall_for($pending_loader),
        )
      );
    },
  );

  my $async_result = _normalize_result($modes{'houtou_async_single_root_object_field_sv'}->());
  die "Result mismatch for single_root_object_field\n"
    unless ($async_result->{data}{user}{team}{name} // '') eq 'batched:u1';

  print "\n=== async_single_root_object_field ===\n";
  print "Query: single root object field, whose nested team field is DataLoader-Ticket-pending\n";
  cmpthese($count, \%modes);
}

sub benchmark_async_fallback_runtime_directive {
  require GraphQL::Houtou::DataLoader;

  # Item 1 (Phase 9): a runtime-directive sibling forces the whole request
  # off the fast lane and onto the generic executor - the shape
  # gql_runtime_vm_drive_promise_with_on_stall_sv now drives from C instead
  # of handing the generic executor's own Promise::XS response back to
  # Perl's _settle_result. Unlike benchmark_async_single_root_object_field
  # (which measures the fast lane skipping the response Promise::XS
  # entirely), the generic executor here still builds a real Promise::XS
  # internally - only the outer then()/while-loop round trip moves into C -
  # so this measures a smaller saving.
  my $query = 'query q($skipIt: Boolean!, $id: String) { '
    . 'plain @skip(if: $skipIt) user(id: $id) { name team { name } } }';
  my $vars = { skipIt => 1, id => 'u1' };

  my $build_schema = sub {
    my ($team_name_resolve) = @_;
    my $Team = GraphQL::Houtou::Type::Object->new(
      name => 'FallbackTeam',
      fields => {
        name => { type => $GraphQL::Houtou::Type::Scalar::String, resolve => $team_name_resolve },
      },
    );
    my $User = GraphQL::Houtou::Type::Object->new(
      name => 'FallbackUser',
      fields => {
        name => { type => $GraphQL::Houtou::Type::Scalar::String, resolve => sub { "n:$_[0]{id}" } },
        team => { type => $Team, resolve => sub { { id => $_[0]{id} } } },
      },
    );
    return GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name => 'Query',
        fields => {
          plain => { type => $GraphQL::Houtou::Type::Scalar::String, resolve => sub { 'plain-val' } },
          user => {
            type => $User,
            args => { id => { type => $GraphQL::Houtou::Type::Scalar::String } },
            resolve => sub { my (undef, $args) = @_; return { id => $args->{id} } },
          },
        },
      ),
    );
  };

  my $sync_rt = $build_schema->(
    sub { return "sync:$_[0]{id}" }
  )->build_native_runtime;

  my $pending_loader;
  my $async_rt = $build_schema->(
    sub { my ($source, undef, $ctx) = @_; return $pending_loader->load($source->{id}) }
  )->build_native_runtime(async => 1);

  my %modes = (
    'houtou_sync_fallback_runtime_directive_sv' => sub {
      return $sync_rt->execute_document($query, variables => $vars);
    },
    'houtou_async_fallback_runtime_directive_sv' => sub {
      $pending_loader = GraphQL::Houtou::DataLoader->new(
        batch => sub { my ($keys) = @_; return [ map { "batched:$_" } @$keys ] },
      );
      return maybe_get_promise_xs(
        $async_rt->execute_document(
          $query,
          variables => $vars,
          on_stall => GraphQL::Houtou::DataLoader->on_stall_for($pending_loader),
        )
      );
    },
  );

  my $async_result = _normalize_result($modes{'houtou_async_fallback_runtime_directive_sv'}->());
  die "Result mismatch for fallback_runtime_directive\n"
    unless ($async_result->{data}{user}{team}{name} // '') eq 'batched:u1';

  print "\n=== async_fallback_runtime_directive ===\n";
  print "Query: a runtime-directive sibling forces the generic-executor fallback,\n";
  print "  whose nested team field is DataLoader-Ticket-pending\n";
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
    name => 'dynamic_directive_guards',
    query => 'query q($show: Boolean!) { '
      . join(' ', map { "greet$_: greet(name: \"houtou\") \@include(if: \$show)" } 1 .. 10)
      . ' }',
    vars => { show => 1 },
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
benchmark_async_preresolved_leaf()
  if $include_async && (!@only || $only{async_preresolved_leaf});
benchmark_async_multi_leaf()
  if $include_async && (!@only || $only{async_multi_leaf});
benchmark_async_leaf_list()
  if $include_async && (!@only || $only{async_leaf_list});
benchmark_async_object_list_item_field()
  if $include_async && (!@only || $only{async_object_list_item_field});
benchmark_async_nested_object_list_item_field()
  if $include_async && (!@only || $only{async_nested_object_list_item_field});
benchmark_async_single_root_object_field()
  if $include_async && (!@only || $only{async_single_root_object_field});
benchmark_async_fallback_runtime_directive()
  if $include_async && (!@only || $only{async_fallback_runtime_directive});
