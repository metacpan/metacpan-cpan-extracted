package GraphQL::Houtou::Runtime::NativeRuntime;

use 5.014;
use strict;
use warnings;

use Scalar::Util qw(blessed refaddr);

use GraphQL::Houtou::Runtime::InputCoercion ();
use GraphQL::Houtou::Runtime::DirectiveRuntime ();
use GraphQL::Houtou::Runtime::OperationCompiler ();
use GraphQL::Houtou::Runtime::VMCompiler ();
use GraphQL::Houtou::Schema ();
use JSON::MaybeXS qw(decode_json encode_json is_bool);

use GraphQL::Houtou::Validation::DepthLimit ();
use GraphQL::Houtou::Validation::NodeLimit ();

use constant DEFAULT_MAX_DEPTH => GraphQL::Houtou::Validation::DepthLimit::DEFAULT_MAX_DEPTH();
use constant DEFAULT_MAX_NODES => GraphQL::Houtou::Validation::NodeLimit::DEFAULT_MAX_NODES();
use constant DEFAULT_MAX_COST => 10_000;
use constant DEFAULT_LIST_SIZE => 10;

sub new {
  my ($class, %args) = @_;
  die "runtime_schema is required\n" if !$args{runtime_schema};
  my $cache_max = exists $args{program_cache_max} ? $args{program_cache_max} : 1000;
  my $max_depth = exists $args{max_depth} ? $args{max_depth} : DEFAULT_MAX_DEPTH;
  my $max_nodes = exists $args{max_nodes} ? $args{max_nodes} : DEFAULT_MAX_NODES;
  my $max_cost = exists $args{max_cost} ? $args{max_cost} : DEFAULT_MAX_COST;
  my $default_list_size = exists $args{default_list_size}
    ? $args{default_list_size} : DEFAULT_LIST_SIZE;
  return bless {
    runtime_schema => $args{runtime_schema},
    native_runtime_struct => $args{native_runtime_struct},
    native_runtime_compact_struct => $args{native_runtime_compact_struct},
    native_runtime_handle => $args{native_runtime_handle},
    _program_cache => {},
    _program_cache_order => [],
    _limit_signatures => {},
    _program_cache_max => $cache_max,
    _specialized_program_cache => {},
    _specialized_program_cache_order => [],
    _specialized_program_cache_max => $cache_max,
    _max_depth => $max_depth,
    _max_nodes => $max_nodes,
    _max_cost => $max_cost,
    _default_list_size => $default_list_size,
    _validate => exists $args{validate} ? ($args{validate} ? 1 : 0) : 1,
    _allow_introspection => exists $args{allow_introspection}
      ? ($args{allow_introspection} ? 1 : 0) : 1,
    _async => $args{async} ? 1 : 0,
  }, $class;
}

sub runtime_schema { return $_[0]{runtime_schema} }

sub _native_runtime_struct {
  my ($self) = @_;
  $self->{native_runtime_struct} ||= $self->runtime_schema->to_native_exec_struct;
  return $self->{native_runtime_struct};
}

sub _native_runtime_compact_struct {
  my ($self) = @_;
  $self->{native_runtime_compact_struct} ||= $self->runtime_schema->to_native_compact_struct;
  return $self->{native_runtime_compact_struct};
}

sub _native_runtime_handle {
  my ($self) = @_;
  GraphQL::Houtou::_bootstrap_xs();
  $self->{native_runtime_handle} ||= GraphQL::Houtou::XS::VM::load_native_runtime_xs(
    $self->_native_runtime_struct,
  );
  return $self->{native_runtime_handle};
}

sub compile_program {
  my ($self, $document, %opts) = @_;
  my $operation_name = delete $opts{operation_name};
  if (!ref($document) && $self->{_program_cache_max}) {
    my $key = _document_cache_key($document, $operation_name);
    my $cached = $self->{_program_cache}{$key};
    return $cached if $cached;
    my $source = defined $operation_name
      ? _select_operation_ast(GraphQL::Houtou::parse($document), $operation_name)
      : $document;
    my $program = $self->runtime_schema->compile_program($source, %opts);
    $self->_store_program_cache($key, $program);
    return $program;
  }
  my $source = defined $operation_name
    ? _select_operation_ast(
        ref($document) ? $document : GraphQL::Houtou::parse($document),
        $operation_name,
      )
    : $document;
  return $self->runtime_schema->compile_program($source, %opts);
}

# NUL is not a valid GraphQL source character, so joining on it cannot
# collide with a plain document key.
sub _document_cache_key {
  my ($document, $operation_name) = @_;
  return defined $operation_name ? $document . "\0" . $operation_name : $document;
}

# The operation compiler executes the first operation in a document, so a
# request naming an operationName compiles a filtered AST: the named
# operation plus every fragment. Dies are GraphQL request errors (the
# document, not the server, is at fault) and become errors-only envelopes.
sub _select_operation_ast {
  my ($ast, $operation_name) = @_;
  die "GraphQL document must parse to a list of definitions\n"
    if ref($ast) ne 'ARRAY';
  my ($selected) = grep {
    ($_->{kind} || '') eq 'operation' && ($_->{name} || '') eq $operation_name
  } @$ast;
  die qq{Operation "$operation_name" was not found in the document\n}
    if !$selected;
  return [ $selected, grep { ($_->{kind} || '') eq 'fragment' } @$ast ];
}

sub _store_program_cache {
  my ($self, $key, $program) = @_;
  my $cache = $self->{_program_cache};
  my $order = $self->{_program_cache_order};
  if (scalar(@$order) >= $self->{_program_cache_max}) {
    my $evicted = shift @$order;
    delete $cache->{$evicted};
    delete $self->{_validated_documents}{$evicted};
    delete $self->{_limit_signatures}{$evicted};
  }
  $cache->{$key} = $program;
  push @$order, $key;
}

sub program_cache_size { scalar keys %{ $_[0]{_program_cache} } }

sub clear_program_cache {
  my ($self) = @_;
  $self->{_program_cache} = {};
  $self->{_program_cache_order} = [];
  $self->{_specialized_program_cache} = {};
  $self->{_specialized_program_cache_order} = [];
  $self->{_validated_documents} = {};
  $self->{_limit_signatures} = {};
}

sub _limit_signature {
  return join "\0", map { defined $_ ? $_ : 'off' } @_;
}

sub _introspection_errors {
  my ($ast) = @_;
  my @pending = ref($ast) eq 'ARRAY' ? @$ast : ($ast);
  for (my $cursor = 0; $cursor < @pending; $cursor++) {
    my $node = $pending[$cursor];
    next if ref($node) ne 'HASH';
    if (($node->{kind} || q()) eq 'field'
        && (($node->{name} || q()) eq '__schema'
            || ($node->{name} || q()) eq '__type')) {
      my $field_name = $node->{name};
      return [ {
        message => qq{Introspection field "$field_name" is disabled},
        (defined $node->{location} ? (locations => [ $node->{location} ]) : ()),
        extensions => { code => 'INTROSPECTION_DISABLED' },
      } ];
    }
    push @pending, @{ $node->{selections} || [] };
  }
  return [];
}

sub compile_bundle_for_document {
  my ($self, $document, %opts) = @_;
  my $descriptor = $self->compile_bundle_descriptor_for_document($document, %opts);
  return $self->load_bundle_descriptor($descriptor);
}

sub specialize_program {
  my ($self, $program, %opts) = @_;
  my $candidate = $self->specialize_program_for_native(
    $program,
    %opts,
  );
  my $struct = _require_native_program($candidate);
  GraphQL::Houtou::_bootstrap_xs();
  die "Program cannot be specialized into the native VM path.\n"
    if !GraphQL::Houtou::XS::VM::program_native_eligible_xs($struct, 0);
  return $candidate;
}

sub specialize_program_for_native {
  my ($self, $program, %opts) = @_;
  return $program if !$program;

  my $native_program = _require_native_program($program);
  my $variables = GraphQL::Houtou::Runtime::InputCoercion::prepare_variables(
    $self->runtime_schema,
    $native_program,
    $opts{variables} || {},
  );
  GraphQL::Houtou::_bootstrap_xs();
  return $self->_specialize_program_descriptor(
    $native_program,
    $variables,
  );
}

sub _specialize_program_descriptor {
  my ($self, $native_program, $variables) = @_;
  my $specialized = GraphQL::Houtou::XS::VM::specialize_native_program_xs(
    $self->_native_runtime_handle,
    $native_program,
    $variables,
  );
  my $descriptor = ref($specialized) && eval { $specialized->isa('GraphQL::Houtou::Runtime::NativeProgram') }
    ? GraphQL::Houtou::XS::VM::native_program_descriptor_xs($specialized)
    : $specialized;
  _specialize_runtime_directives_payloads($descriptor, $variables);
  return GraphQL::Houtou::XS::VM::load_native_program_xs($descriptor);
}

sub compile_bundle {
  my ($self, $program, %opts) = @_;
  my $candidate = $self->specialize_program($program, %opts);
  return $self->_load_bundle_parts(_require_native_program($candidate));
}

sub compile_bundle_descriptor {
  my ($self, $program, %opts) = @_;
  my $candidate = $self->specialize_program($program, %opts);
  GraphQL::Houtou::_bootstrap_xs();
  return {
    runtime => $self->_native_runtime_compact_struct,
    program => GraphQL::Houtou::XS::VM::native_program_descriptor_xs($candidate),
  };
}

sub compile_program_descriptor {
  my ($self, $program, %opts) = @_;
  my $candidate = $self->specialize_program($program, %opts);
  GraphQL::Houtou::_bootstrap_xs();
  return GraphQL::Houtou::XS::VM::native_program_descriptor_xs($candidate);
}

sub compile_program_descriptor_for_document {
  my ($self, $document, %opts) = @_;
  my $program = $self->compile_program($document, %opts);
  return $self->compile_program_descriptor($program, %opts);
}

sub compile_bundle_descriptor_for_document {
  my ($self, $document, %opts) = @_;
  my $program = $self->compile_program($document, %opts);
  return $self->compile_bundle_descriptor($program, %opts);
}

sub _load_bundle_parts {
  my ($self, $program) = @_;
  GraphQL::Houtou::_bootstrap_xs();
  return GraphQL::Houtou::XS::VM::load_native_bundle_from_handles_xs(
    $self->_native_runtime_handle,
    $program,
  );
}

sub _require_native_program {
  my ($program) = @_;
  return $program
    if ref($program) && eval { $program->isa('GraphQL::Houtou::Runtime::NativeProgram') };
  die "Active runtime paths expect a GraphQL::Houtou::Runtime::NativeProgram.\n";
}

sub load_bundle_descriptor {
  my ($self, $descriptor) = @_;
  GraphQL::Houtou::Runtime::OperationCompiler::assert_supported_operation_descriptor(
    ref($descriptor) eq 'HASH' ? $descriptor->{program} : undef,
  );
  GraphQL::Houtou::_bootstrap_xs();
  return GraphQL::Houtou::XS::VM::load_native_bundle_xs($descriptor);
}

sub inflate_bundle_descriptor {
  my ($self, $descriptor) = @_;
  GraphQL::Houtou::Runtime::OperationCompiler::assert_supported_operation_descriptor(
    ref($descriptor) eq 'HASH' ? $descriptor->{program} : undef,
  );
  return GraphQL::Houtou::Runtime::VMCompiler->inflate_native_bundle(
    $self->runtime_schema,
    $descriptor,
  );
}

sub dump_bundle_descriptor {
  my ($self, $program, $path, %opts) = @_;
  my $descriptor = $self->compile_bundle_descriptor($program, %opts);
  open my $fh, '>', $path or die "Cannot open $path for write: $!";
  print {$fh} encode_json($descriptor);
  close $fh;
  return $descriptor;
}

sub dump_bundle_descriptor_for_document {
  my ($self, $document, $path, %opts) = @_;
  my $descriptor = $self->compile_bundle_descriptor_for_document($document, %opts);
  open my $fh, '>', $path or die "Cannot open $path for write: $!";
  print {$fh} encode_json($descriptor);
  close $fh;
  return $descriptor;
}

sub load_bundle_descriptor_file {
  my ($self, $path) = @_;
  open my $fh, '<', $path or die "Cannot open $path for read: $!";
  local $/;
  my $json = <$fh>;
  close $fh;
  my $descriptor = decode_json($json);
  return $self->load_bundle_descriptor($descriptor);
}

sub execute_program {
  my ($self, $program, %opts) = @_;
  my $native_program = _require_native_program($program);
  my $runtime_handle = $self->_native_runtime_handle;
  my $on_stall = delete $opts{on_stall};
  my $has_root_value = exists $opts{root_value};
  my $has_context_value = exists $opts{context};
  my $has_variables = exists $opts{variables};
  my $root_value = $has_root_value ? $opts{root_value} : undef;
  my $context_value = $has_context_value ? $opts{context} : undef;
  my $variables = $has_variables ? $opts{variables} : undef;
  my $strict_sync = delete $opts{strict_sync} ? 1 : 0;

  die "promise_code is no longer supported; Promise::XS is detected automatically.\n"
    if exists $opts{promise_code};

  if ($on_stall && !$strict_sync) {
    require GraphQL::Houtou::Promise::PromiseXS;
    # Batching resolvers return promises, so the request must run on the
    # async-capable lane regardless of variables, and the returned promise
    # is driven to completion here: Promise::XS resolutions run their
    # callbacks synchronously, so each flush advances the XS scheduler
    # until the next stall.
    my $result = GraphQL::Houtou::XS::VM::execute_native_program_auto_xs(
      $runtime_handle,
      $native_program,
      $root_value,
      $context_value,
      $variables,
    );
    return _settle_result($result, $on_stall);
  }
  # Runtimes built with async => 1 declare that resolvers return promises
  # (the DataLoader deployment shape); every request starts on the
  # async-capable lane, exactly like the no-variables path. A strict
  # synchronous request still wins.
  if ($self->{_async} && !$strict_sync) {
    require GraphQL::Houtou::Promise::PromiseXS;
    return GraphQL::Houtou::XS::VM::execute_native_program_auto_xs(
      $runtime_handle,
      $native_program,
      $root_value,
      $context_value,
      $variables,
    );
  }
  if ($strict_sync || $has_variables) {
    my $prepared_variables = GraphQL::Houtou::Runtime::InputCoercion::prepare_variables(
      $self->runtime_schema,
      $native_program,
      $variables || {},
    );
    # Programs without runtime directives or variable-dependent directive
    # guards are variable-invariant: the fast lanes evaluate dynamic
    # arguments against the prepared variables at request time, so no
    # per-request clone/specialize (or variables-keyed cache) is needed.
    if (!GraphQL::Houtou::XS::VM::native_program_needs_variable_specialization_xs($native_program)) {
      return $self->execute_compact_program($native_program, %opts, variables => $prepared_variables);
    }
    my $specialized = $self->_cached_specialized_program(
      $native_program,
      $prepared_variables,
    );
    return $self->execute_compact_program($specialized, %opts, variables => $prepared_variables);
  }
  if (!$has_root_value && !$has_context_value && !$has_variables) {
    return GraphQL::Houtou::XS::VM::execute_native_program_auto_simple_xs(
      $runtime_handle,
      $native_program,
    );
  }
  return GraphQL::Houtou::XS::VM::execute_native_program_auto_xs(
    $runtime_handle,
    $native_program,
    $root_value,
    $context_value,
    $variables,
  );
}

sub execute_compact_program {
  my ($self, $program, %opts) = @_;
  my $native_program = _require_native_program($program);
  return GraphQL::Houtou::XS::VM::execute_native_program_handle_xs(
    $self->_native_runtime_handle,
    $native_program,
    $opts{root_value},
    $opts{context},
    $opts{variables},
  );
}

# Drive a possibly-pending async result to completion using the caller's
# on_stall callback. This is the core batching contract: execution runs
# until every field either completed or is waiting on a promise ("stall"),
# then on_stall is invoked and must make progress (return a true dispatch
# count) by resolving promises - typically by flushing data loaders. Each
# resolution runs its continuations synchronously, advancing the scheduler
# to the next stall. No progress while promises remain pending is reported
# as a deadlock.
sub _settle_result {
  my ($result, $on_stall) = @_;
  return $result
    if !(blessed($result) && $result->isa('Promise::XS::Promise'));

  my ($settled, $value) = (0, undef);
  $result->then(
    sub { ($settled, $value) = (1, $_[0]) },
    sub { ($settled, $value) = (-1, $_[0]) },
  );
  while (!$settled) {
    my $progressed = $on_stall->();
    if (!$settled && !$progressed) {
      # The request is being abandoned while promises are pending; cancel
      # it so the pending machinery (a reference cycle while armed) is
      # torn down instead of leaking with the abandoned frames.
      GraphQL::Houtou::XS::VM::cancel_pending_response_xs($result);
      die "GraphQL execution stalled: promises are pending but on_stall made no progress"
        . " (a resolver returned a promise that no registered loader will resolve)\n";
    }
  }
  if ($settled < 0) {
    die $value if ref $value || ($value // '') ne '';
    die "GraphQL execution failed with an unknown async rejection\n";
  }
  return $value;
}

sub execute_bundle_descriptor {
  my ($self, $descriptor, %opts) = @_;
  my $bundle = $self->load_bundle_descriptor($descriptor);
  return $self->execute_bundle($bundle, %opts);
}

# Request-stage checks shared by execute_document and its JSON sibling:
# depth limit and full query validation. The depth check is skipped for
# documents already in the program cache; validation is skipped only for
# documents this runtime has actually validated before (a cache entry
# stored under validate => 0 proves nothing). Returns an arrayref of
# request errors, or undef when execution may proceed. Request errors
# produce an errors-only envelope (no "data" key), per the spec's
# request-error contract.
sub _document_request_errors {
  my ($self, $document, $max_depth, $max_nodes, $max_cost,
      $default_list_size, $validate, $operation_name, $allow_introspection) = @_;
  return undef if !defined $max_depth && !defined $max_nodes
    && !defined $max_cost && !$validate && $allow_introspection;

  my $is_string = !ref($document);
  my $cache_key = $is_string
    ? _document_cache_key($document, $operation_name)
    : undef;
  my $already_validated = $is_string && $self->{_validated_documents}{$cache_key};
  my $already_limited = $is_string && $self->{_limit_signatures}{$cache_key}
    && $self->{_limit_signatures}{$cache_key} eq _limit_signature(
      $max_depth, $max_nodes, $max_cost, $default_list_size,
      $allow_introspection,
    );
  # Depth and node caps bound the untrusted document; skip them once the
  # program is cached (a cached document already passed them once).
  my $need_limits = (defined $max_depth || defined $max_nodes || defined $max_cost)
    && !$already_limited;
  my $need_validate = $validate && !$already_validated;
  my $need_introspection_check = !$allow_introspection && !$already_limited;
  return undef if !$need_limits && !$need_validate && !$need_introspection_check;

  my $ast = $is_string ? GraphQL::Houtou::parse($document) : $document;
  $ast = _select_operation_ast($ast, $operation_name) if defined $operation_name;
  if ($need_introspection_check) {
    my $errors = _introspection_errors($ast);
    return $errors if @$errors;
  }
  if ($need_limits && defined $max_depth) {
    my @errors = GraphQL::Houtou::Validation::DepthLimit::check_query_depth(
      $ast, max_depth => $max_depth,
    );
    return \@errors if @errors;
  }
  if ($need_limits && defined $max_nodes) {
    my @errors = GraphQL::Houtou::Validation::NodeLimit::check_query_nodes(
      $ast, max_nodes => $max_nodes,
    );
    return \@errors if @errors;
  }
  if ($need_limits && defined $max_cost) {
    my $schema = $self->runtime_schema->can('schema')
      ? $self->runtime_schema->schema : undef;
    if ($schema) {
      require GraphQL::Houtou::Validation;
      my $errors = GraphQL::Houtou::Validation::check_query_cost(
        $schema, $ast,
        max_cost => $max_cost,
        default_list_size => $default_list_size,
        (defined $operation_name ? (operation_name => $operation_name) : ()),
      );
      return $errors if $errors && @$errors;
    }
  }
  if ($need_validate) {
    # Validation needs the schema's type objects; a runtime inflated from
    # a descriptor (persisted deployments) has none, and its documents
    # were validated when the descriptor was built.
    my $schema = $self->runtime_schema->can('schema') ? $self->runtime_schema->schema : undef;
    if ($schema) {
      require GraphQL::Houtou::Validation;
      my $errors = GraphQL::Houtou::Validation::validate($schema, $ast);
      return $errors if $errors && @$errors;
      # Only remember validated documents that the program cache can also
      # hold, so the set stays bounded by the cache's eviction.
      $self->{_validated_documents}{$cache_key} = 1
        if $is_string && $self->{_program_cache_max};
    }
  }
  return undef;
}

# Convert a caught exception into GraphQL error entries for an errors-only
# envelope. Houtou error objects keep their locations/extensions; the
# parser's graphql-perl-style message is reduced to a spec-style syntax
# error line (the parse() API keeps raising the full legacy format).
sub _request_error_entries {
  my ($error) = @_;
  if (blessed($error) && $error->isa('GraphQL::Houtou::Error')) {
    my $entry = $error->to_json;
    if (($entry->{message} // '') =~ /\AError parsing Pegex document:\s*\n\s*msg:\s*(.+?)\s*\n/) {
      $entry->{message} = "Syntax Error: $1";
    }
    return [ $entry ];
  }
  my $message = "$error";
  $message =~ s/\s+\z//;
  return [ { message => $message } ];
}

# True for exceptions that represent GraphQL request errors (client-caused:
# syntax, validation, input coercion). Anything else - configuration or
# internal errors - must keep propagating as an exception.
sub _is_request_error {
  my ($error) = @_;
  return blessed($error) && $error->isa('GraphQL::Houtou::Error');
}

sub execute_document {
  my ($self, $document, %opts) = @_;
  my $max_depth = exists $opts{max_depth} ? delete $opts{max_depth} : $self->{_max_depth};
  my $max_nodes = exists $opts{max_nodes} ? delete $opts{max_nodes} : $self->{_max_nodes};
  my $max_cost = exists $opts{max_cost} ? delete $opts{max_cost} : $self->{_max_cost};
  my $default_list_size = exists $opts{default_list_size}
    ? delete $opts{default_list_size} : $self->{_default_list_size};
  my $validate = exists $opts{validate} ? delete $opts{validate} : $self->{_validate};
  my $allow_introspection = exists $opts{allow_introspection}
    ? (delete $opts{allow_introspection} ? 1 : 0)
    : $self->{_allow_introspection};
  my $operation_name = delete $opts{operation_name};

  # Hot path: a cached program whose document this runtime already
  # validated skips the request stage entirely (depth was checked before
  # it entered the cache, validation is recorded per document). Requests
  # naming an operationName cache under a (document, operationName) key.
  my $cache_key = !ref($document)
    ? _document_cache_key($document, $operation_name)
    : undef;
  my $cached = defined $cache_key && $self->{_program_cache_max}
    ? $self->{_program_cache}{$cache_key}
    : undef;
  my $limit_signature = _limit_signature(
    $max_depth, $max_nodes, $max_cost, $default_list_size,
    $allow_introspection,
  );
  my $limits_ok = $cached && $self->{_limit_signatures}{$cache_key}
    && $self->{_limit_signatures}{$cache_key} eq $limit_signature;
  if ($cached && $limits_ok
      && (!$validate || $self->{_validated_documents}{$cache_key})) {
    my $result = eval { $self->execute_program($cached, %opts) };
    if (my $error = $@) {
      die $error if !_is_request_error($error);
      return { errors => _request_error_entries($error) };
    }
    return $result;
  }

  # Cold path. The taxonomy: parse/validation/compile failures are
  # document-caused and always envelope; execution failures envelope only
  # when they are GraphQL request errors (variable coercion raises
  # GraphQL::Houtou::Error) - async misconfiguration, scheduler deadlock,
  # and internal bugs keep propagating.
  my $executing = 0;
  my ($result, $request_errors);
  my $ok = eval {
    $request_errors = $self->_document_request_errors(
      $document, $max_depth, $max_nodes, $max_cost,
      $default_list_size, $validate, $operation_name, $allow_introspection);
    if (!$request_errors) {
      my $program = $self->compile_program($document, %opts,
        (defined $operation_name ? (operation_name => $operation_name) : ()));
      $self->{_limit_signatures}{$cache_key} = $limit_signature
        if defined $cache_key && $self->{_program_cache}{$cache_key};
      $executing = 1;
      $result = $self->execute_program($program, %opts);
    }
    1;
  };
  if (!$ok) {
    my $error = $@;
    die $error if $executing && !_is_request_error($error);
    return { errors => _request_error_entries($error) };
  }
  return { errors => $request_errors } if $request_errors;
  return $result;
}

sub execute_bundle {
  my ($self, $bundle, %opts) = @_;
  return GraphQL::Houtou::XS::VM::execute_native_bundle_xs(
    $self->_native_runtime_handle,
    $bundle,
    $opts{root_value},
    $opts{context},
    $opts{variables},
  );
}

# Direct-JSON siblings of the sync native lane: the response is rendered as
# UTF-8 JSON bytes in XS without materializing the Perl envelope. Without
# on_stall the lane is sync-only and resolvers returning Promise::XS
# promises croak; with on_stall the request runs on the async lane and the
# response frame serializes its native value tree straight to JSON when it
# resolves (see execute_program_to_json).

sub execute_bundle_to_json {
  my ($self, $bundle, %opts) = @_;
  return GraphQL::Houtou::XS::VM::execute_native_bundle_to_json_xs(
    $self->_native_runtime_handle,
    $bundle,
    $opts{root_value},
    $opts{context},
    $opts{variables},
  );
}

sub execute_program_to_json {
  my ($self, $program, %opts) = @_;
  my $native_program = _require_native_program($program);
  my $on_stall = delete $opts{on_stall};
  my $strict_sync = delete $opts{strict_sync} ? 1 : 0;
  if ($on_stall && !$strict_sync) {
    # Batching resolvers return promises, so run on the async lane; the
    # response frame renders JSON directly from its native value tree at
    # resolve time (query field order preserved). The auto lane prepares
    # program variables itself.
    require GraphQL::Houtou::Promise::PromiseXS;
    my $result = GraphQL::Houtou::XS::VM::execute_native_program_auto_to_json_xs(
      $self->_native_runtime_handle,
      $native_program,
      $opts{root_value},
      $opts{context},
      $opts{variables},
    );
    return _settle_result($result, $on_stall);
  }
  if ($self->{_async} && !$strict_sync) {
    return $self->_auto_json_or_die($native_program, %opts);
  }
  my $prepared_variables = GraphQL::Houtou::Runtime::InputCoercion::prepare_variables(
    $self->runtime_schema,
    $native_program,
    $opts{variables} || {},
  );
  my $effective_program = $native_program;
  if (GraphQL::Houtou::XS::VM::native_program_needs_variable_specialization_xs($native_program)) {
    $effective_program = $self->_cached_specialized_program(
      $native_program,
      $prepared_variables,
    );
  }
  return GraphQL::Houtou::XS::VM::execute_native_program_to_json_xs(
    $self->_native_runtime_handle,
    $effective_program,
    $opts{root_value},
    $opts{context},
    $prepared_variables,
  );
}

# Async JSON lane without an on_stall hook: promises that resolve during
# execution (pre-resolved chains) complete synchronously and yield JSON; a
# genuine stall has nothing to flush it, so fail with a pointer to on_stall
# rather than handing a promise to a caller that expected bytes.
sub _auto_json_or_die {
  my ($self, $native_program, %opts) = @_;
  require GraphQL::Houtou::Promise::PromiseXS;
  my $result = GraphQL::Houtou::XS::VM::execute_native_program_auto_to_json_xs(
    $self->_native_runtime_handle,
    $native_program,
    $opts{root_value},
    $opts{context},
    $opts{variables},
  );
  if (blessed($result) && $result->isa('Promise::XS::Promise')) {
    # Pre-resolved promise chains settle during execution, so the response
    # promise may already hold the JSON; only a genuine stall is an error.
    my $settled = eval {
      GraphQL::Houtou::Promise::PromiseXS::maybe_get_promise_xs($result);
    };
    if (my $err = $@) {
      # A rejected response promise carries a real request error; only the
      # still-pending case earns the on_stall hint. The pending request is
      # abandoned here, so cancel it (see _settle_result).
      die $err if $err !~ /did not resolve synchronously/;
      GraphQL::Houtou::XS::VM::cancel_pending_response_xs($result);
      die "resolvers returned pending promises; pass on_stall (see GraphQL::Houtou::DataLoader)"
        . " so execute_document_to_json can drive them to completion\n";
    }
    return $settled;
  }
  return $result;
}

sub _request_errors_json {
  my ($errors) = @_;
  require JSON::MaybeXS;
  return JSON::MaybeXS->new->utf8->canonical->encode({ errors => $errors });
}

sub execute_document_to_json {
  my ($self, $document, %opts) = @_;
  my $max_depth = exists $opts{max_depth} ? delete $opts{max_depth} : $self->{_max_depth};
  my $max_nodes = exists $opts{max_nodes} ? delete $opts{max_nodes} : $self->{_max_nodes};
  my $max_cost = exists $opts{max_cost} ? delete $opts{max_cost} : $self->{_max_cost};
  my $default_list_size = exists $opts{default_list_size}
    ? delete $opts{default_list_size} : $self->{_default_list_size};
  my $validate = exists $opts{validate} ? delete $opts{validate} : $self->{_validate};
  my $allow_introspection = exists $opts{allow_introspection}
    ? (delete $opts{allow_introspection} ? 1 : 0)
    : $self->{_allow_introspection};
  my $operation_name = delete $opts{operation_name};

  # Same hot/cold structure and error taxonomy as execute_document.
  my $cache_key = !ref($document)
    ? _document_cache_key($document, $operation_name)
    : undef;
  my $cached = defined $cache_key && $self->{_program_cache_max}
    ? $self->{_program_cache}{$cache_key}
    : undef;
  my $limit_signature = _limit_signature(
    $max_depth, $max_nodes, $max_cost, $default_list_size,
    $allow_introspection,
  );
  my $limits_ok = $cached && $self->{_limit_signatures}{$cache_key}
    && $self->{_limit_signatures}{$cache_key} eq $limit_signature;
  if ($cached && $limits_ok
      && (!$validate || $self->{_validated_documents}{$cache_key})) {
    my $result = eval { $self->execute_program_to_json($cached, %opts) };
    if (my $error = $@) {
      die $error if !_is_request_error($error);
      return _request_errors_json(_request_error_entries($error));
    }
    return $result;
  }

  my $executing = 0;
  my ($result, $request_errors);
  my $ok = eval {
    $request_errors = $self->_document_request_errors(
      $document, $max_depth, $max_nodes, $max_cost,
      $default_list_size, $validate, $operation_name, $allow_introspection);
    if (!$request_errors) {
      my $program = $self->compile_program($document, %opts,
        (defined $operation_name ? (operation_name => $operation_name) : ()));
      $self->{_limit_signatures}{$cache_key} = $limit_signature
        if defined $cache_key && $self->{_program_cache}{$cache_key};
      $executing = 1;
      $result = $self->execute_program_to_json($program, %opts);
    }
    1;
  };
  if (!$ok) {
    my $error = $@;
    die $error if $executing && !_is_request_error($error);
    return _request_errors_json(_request_error_entries($error));
  }
  return _request_errors_json($request_errors) if $request_errors;
  return $result;
}

sub _cached_specialized_program {
  my ($self, $native_program, $variables) = @_;
  return $native_program if !$variables || !keys %$variables;

  my $variables_key = _specialized_variables_cache_key($variables);
  if (length($variables_key) > 2048) {
    # Unbounded variable payloads would otherwise become unbounded cache
    # keys; specialize without caching instead.
    return $self->_specialize_program_descriptor($native_program, $variables);
  }
  my $key = join q(|), refaddr($native_program), $variables_key;

  if (my $cached = $self->{_specialized_program_cache}{$key}) {
    return $cached;
  }

  my $specialized = $self->_specialize_program_descriptor($native_program, $variables);
  my $cache = $self->{_specialized_program_cache};
  my $order = $self->{_specialized_program_cache_order};
  if (scalar(@$order) >= $self->{_specialized_program_cache_max}) {
    my $evicted = shift @$order;
    delete $cache->{$evicted};
  }
  $cache->{$key} = $specialized;
  push @$order, $key;
  return $specialized;
}

sub _specialized_variables_cache_key {
  my ($value) = @_;
  my $ref = ref($value);
  return 'u' if !defined $value;
  return $value ? 'b1' : 'b0' if is_bool($value);
  return 's:' . $value if !$ref;
  if ($ref eq 'ARRAY') {
    return 'a:[' . join(',', map { _specialized_variables_cache_key($_) } @$value) . ']';
  }
  if ($ref eq 'HASH') {
    return 'h:{' . join(',', map {
      my $k = $_;
      $k . '=>' . _specialized_variables_cache_key($value->{$k})
    } sort keys %$value) . '}';
  }
  return $ref . ':' . "$value";
}

sub _specialize_runtime_directives_payloads {
  my ($descriptor, $variables) = @_;
  return $descriptor if !$descriptor;

  if (ref($descriptor) eq 'HASH') {
    my $blocks = $descriptor->{blocks_compact} || $descriptor->{blocks} || [];
    for my $block (@$blocks) {
      my $ops = ref($block) eq 'ARRAY' ? ($block->[4] || []) : ($block->{ops} || []);
      for my $op (@$ops) {
        _specialize_runtime_directives_op($op, $variables);
      }
    }
  }

  return $descriptor;
}

sub _specialize_runtime_directives_op {
  my ($op, $variables) = @_;
  return if !$op;

  if (ref($op) eq 'ARRAY') {
    my $mode_code = $op->[18] || 0;
    return if !$mode_code || !$op->[20];
    my $payload = GraphQL::Houtou::Runtime::DirectiveRuntime::materialize_runtime_directives(
      $op->[19],
      $variables,
    );
    $op->[18] = 1;
    $op->[19] = $payload;
    $op->[20] = @$payload ? 1 : 0;
    return;
  }

  return if ref($op) ne 'HASH';
  my $mode_code = $op->{runtime_directives_mode_code} || 0;
  return if !$mode_code || !$op->{has_runtime_directives};

  my $payload = GraphQL::Houtou::Runtime::DirectiveRuntime::materialize_runtime_directives(
    $op->{runtime_directives_payload},
    $variables,
  );
  $op->{runtime_directives_mode_code} = 1;
  $op->{runtime_directives_payload} = $payload;
  $op->{has_runtime_directives} = @$payload ? 1 : 0;
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Runtime::NativeRuntime - request-time execution API on the XS VM

=head1 SYNOPSIS

    my $runtime = $schema->build_native_runtime(async => 1);

    # dynamic queries (program compiled + cached per query string)
    my $result = $runtime->execute_document($query, variables => \%vars);
    my $bytes  = $runtime->execute_document_to_json($query, variables => \%vars);

    # persisted artifacts
    my $program = $runtime->compile_program($query);
    my $result  = $runtime->execute_program($program, variables => \%vars);
    my $result  = $runtime->execute_bundle($bundle);
    my $bytes   = $runtime->execute_bundle_to_json($bundle);

=head1 DESCRIPTION

The reusable execution engine built from a schema by
C<build_native_runtime>. Build it once at startup; every method here is
request-time API. Queries compile into native programs (cached per query
string, FIFO, C<program_cache_max>, default 1000) and execute on the XS
VM. See L<GraphQL::Houtou/API Selection Guide> for choosing between
documents, programs, and bundles.

=head1 EXECUTION METHODS

=head2 execute_document($query, %opts) / execute_document_to_json($query, %opts)

Compile (or fetch from the program cache) and execute. The C<_to_json>
form renders UTF-8 JSON bytes directly from the XS lane without building
the Perl envelope. Options:

=over 4

=item * C<variables> - hashref of GraphQL variable values

=item * C<operation_name> - selects the named operation from a
multi-operation document (the compiler otherwise executes the first one).
Programs cache under a C<(document, operation_name)> key, so repeated
requests naming an operation stay on the hot path. An unknown name is a
request error (errors-only envelope).

=item * C<context> / C<root_value> - passed to resolvers

=item * C<allow_introspection> - defaults to true. Set false on the runtime
or per request to reject C<__schema> and C<__type> with the
C<INTROSPECTION_DISABLED> request-error code. C<__typename> remains available.
The policy check is cached with the compiled document and cannot be bypassed
with C<validate =E<gt> 0>.

=item * C<on_stall> - stall-flush hook; the request runs on the
async-capable lane and is driven to completion synchronously (see
L<GraphQL::Houtou/Batching resolvers (DataLoader / the on_stall hook)>)

=item * C<strict_sync> - set true to force the strict sync fast lane even on
an C<async> runtime; promise resolvers croak there. Omit it for normal
automatic lane selection. Execution always uses the XS native runtime.

=back

=head2 execute_program($program, %opts) / execute_program_to_json($program, %opts)

Execute a program compiled with C<compile_program($query)>. Same options
as above; this is the persisted-query path for variable-bearing queries.
Programs and bundles are trusted prevalidated artifacts, so the
C<allow_introspection> document policy is enforced while accepting dynamic
documents, not while executing these direct artifact APIs.

=head2 execute_bundle($bundle, %opts) / execute_bundle_to_json($bundle, %opts) / execute_bundle_descriptor($descriptor, %opts)

Execute a fixed-query native bundle (no GraphQL variables; argument
values are baked in at compile time). Descriptors are the serialisable
form for crossing process boundaries.

=head1 LANE SELECTION

Requests choose an execution lane automatically: C<on_stall> or a runtime
built with C<async =E<gt> 1> starts on the async-capable lane (promises
suspend and resume); otherwise requests run the synchronous fast lane and
promise-returning resolvers fail with an error naming both fixes.

=head1 OTHER METHODS

C<compile_program>, C<compile_bundle>, descriptor dump/load pairs
(C<dump_bundle_descriptor> / C<load_bundle_descriptor> and friends),
C<program_cache_size>, C<clear_program_cache>, C<runtime_schema>.

=head1 SEE ALSO

L<GraphQL::Houtou>, L<GraphQL::Houtou::Schema>, L<GraphQL::Houtou::DataLoader>

=cut
