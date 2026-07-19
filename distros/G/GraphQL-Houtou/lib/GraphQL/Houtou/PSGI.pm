package GraphQL::Houtou::PSGI;

use 5.014;
use strict;
use warnings;

use JSON::MaybeXS ();
use Scalar::Util qw(blessed);

use GraphQL::Houtou ();

our $VERSION = $GraphQL::Houtou::VERSION;

my $JSON = JSON::MaybeXS->new->utf8;

sub new {
  my ($class, %args) = @_;

  my $allow_introspection = exists $args{allow_introspection}
    ? delete $args{allow_introspection} : undef;

  my $runtime = delete $args{runtime};
  if (!$runtime) {
    my $schema = delete $args{schema}
      or die "GraphQL::Houtou::PSGI->new requires a schema or a runtime\n";
    my %runtime_opts;
    $runtime_opts{program_cache_max} = delete $args{program_cache_max}
      if exists $args{program_cache_max};
    $runtime_opts{async} = delete $args{async} if exists $args{async};
    $runtime_opts{allow_introspection} = $allow_introspection
      if defined $allow_introspection;
    $runtime = $schema->build_native_runtime(%runtime_opts);
  }

  # Request body cap: an unauthenticated client
  # must not be able to exhaust memory with a giant body. 1 MiB is far
  # above any real GraphQL request. Pass max_body_size => 0 to disable.
  my $max_body_size = exists $args{max_body_size}
    ? delete $args{max_body_size}
    : 1024 * 1024;

  my $self = bless {
    runtime => $runtime,
    graphiql => delete $args{graphiql},
    graphiql_path => delete $args{graphiql_path},
    context => delete $args{context},
    root_value => delete $args{root_value},
    on_stall => delete $args{on_stall},
    max_depth => delete $args{max_depth},
    max_nodes => delete $args{max_nodes},
    max_cost => delete $args{max_cost},
    default_list_size => delete $args{default_list_size},
    allow_introspection => $allow_introspection,
    max_body_size => $max_body_size,
  }, $class;

  if (my @unknown = sort keys %args) {
    die "Unknown GraphQL::Houtou::PSGI options: @unknown\n";
  }
  return $self;
}

sub to_app {
  my ($self) = @_;
  return sub { $self->call($_[0]) };
}

sub call {
  my ($self, $env) = @_;
  my $method = $env->{REQUEST_METHOD} || '';

  if ($method eq 'POST') {
    return $self->_handle_post($env);
  }
  if ($method eq 'GET' && $self->{graphiql} && _accepts_html($env)) {
    return _graphiql_response($self);
  }
  return _error_response($env, 405, 'GraphQL over HTTP requests must use POST',
    [ Allow => $self->{graphiql} ? 'GET, POST' : 'POST' ]);
}

sub _handle_post {
  my ($self, $env) = @_;

  my $content_type = lc($env->{CONTENT_TYPE} || '');
  $content_type =~ s/\s*;.*//s;
  if ($content_type ne 'application/json') {
    return _error_response($env, 415, 'Content-Type must be application/json');
  }

  my $max_body = $self->{max_body_size};
  if ($max_body && ($env->{CONTENT_LENGTH} || 0) > $max_body) {
    return _error_response($env, 413, 'Request body is too large');
  }

  my ($body, $too_large) = _read_body($env, $max_body);
  return _error_response($env, 413, 'Request body is too large') if $too_large;
  my $payload = do {
    local $@;
    my $decoded = eval { $JSON->decode($body) };
    $@ ? undef : $decoded;
  };
  if (ref $payload ne 'HASH') {
    return _error_response($env, 400, 'Request body must be a JSON object');
  }

  my $query = $payload->{query};
  if (!defined $query || ref $query || $query !~ /\S/) {
    return _error_response($env, 400, 'The "query" field is required');
  }
  my $variables = $payload->{variables};
  if (defined $variables && ref $variables ne 'HASH') {
    return _error_response($env, 400, 'The "variables" field must be a JSON object');
  }
  my $operation_name = $payload->{operationName};
  if (defined $operation_name && (ref $operation_name || $operation_name !~ /\S/)) {
    return _error_response($env, 400, 'The "operationName" field must be a non-empty string');
  }

  my ($context, $on_stall) = $self->_request_context($env);

  my %exec_opts;
  $exec_opts{operation_name} = $operation_name if defined $operation_name;
  $exec_opts{variables} = $variables if defined $variables;
  $exec_opts{context} = $context if defined $context;
  $exec_opts{root_value} = $self->{root_value} if defined $self->{root_value};
  $exec_opts{on_stall} = $on_stall if defined $on_stall;
  $exec_opts{max_depth} = $self->{max_depth} if defined $self->{max_depth};
  $exec_opts{max_nodes} = $self->{max_nodes} if defined $self->{max_nodes};
  $exec_opts{max_cost} = $self->{max_cost} if defined $self->{max_cost};
  $exec_opts{default_list_size} = $self->{default_list_size}
    if defined $self->{default_list_size};
  $exec_opts{allow_introspection} = $self->{allow_introspection}
    if defined $self->{allow_introspection};

  my ($json, $error) = do {
    local $@;
    my $out = eval { $self->{runtime}->execute_document_to_json($query, %exec_opts) };
    $@ ? (undef, $@) : ($out, undef);
  };
  if (defined $error) {
    # Request errors (syntax, validation, input coercion) come back as an
    # errors-only envelope, not an exception, so a die here is a server
    # problem - async misconfiguration, scheduler deadlock, an internal
    # bug. GraphQL over HTTP calls for a 5xx, and the details belong in
    # logs, not the response.
    warn "GraphQL::Houtou::PSGI: execution failed: $error";
    return _error_response($env, 500, 'Internal server error');
  }

  # An errors-only envelope means the request itself was invalid (no field
  # ever executed): GraphQL over HTTP maps that to a 400. Request errors
  # always serialize as {"errors":...} with no data key, so the prefix
  # check avoids decoding the response we just encoded.
  my $status = index($json, '{"errors":') == 0 ? 400 : 200;

  return [
    $status,
    [ 'Content-Type' => _response_content_type($env), 'Content-Length' => length $json ],
    [ $json ],
  ];
}

sub _request_context {
  my ($self, $env) = @_;
  my $context = $self->{context};
  if (ref $context eq 'CODE') {
    # The builder runs once per request and may return the context alone or
    # a (context, on_stall) pair - the natural shape when per-request
    # DataLoaders live inside the context.
    my ($built, $on_stall) = $context->($env);
    return ($built, $on_stall // $self->{on_stall});
  }
  return ($context, $self->{on_stall});
}

# Reads the request body, enforcing $max_body against the bytes actually
# read (not just the client-supplied CONTENT_LENGTH, which can lie).
# Returns ($body, $too_large).
sub _read_body {
  my ($env, $max_body) = @_;
  my $input = $env->{'psgi.input'} or return ('', 0);
  my $length = $env->{CONTENT_LENGTH} || 0;
  my $body = '';
  while ($length > 0) {
    my $read = $input->read($body, $length, length $body);
    last if !$read;
    $length -= $read;
    return ($body, 1) if $max_body && length($body) > $max_body;
  }
  return ($body, 0);
}

sub _accepts_html {
  my ($env) = @_;
  return (($env->{HTTP_ACCEPT} || '') =~ m{text/html}) ? 1 : 0;
}

sub _response_content_type {
  my ($env) = @_;
  my $accept = $env->{HTTP_ACCEPT} || '';
  return $accept =~ m{application/graphql-response\+json}
    ? 'application/graphql-response+json; charset=utf-8'
    : 'application/json; charset=utf-8';
}

sub _error_response {
  my ($env, $status, $message, $extra_headers) = @_;
  my $json = $JSON->encode({ errors => [ { message => $message } ] });
  return [
    $status,
    [
      'Content-Type' => _response_content_type($env),
      'Content-Length' => length $json,
      @{ $extra_headers || [] },
    ],
    [ $json ],
  ];
}

sub _graphiql_response {
  my ($self) = @_;
  my $endpoint = $self->{graphiql_path} // '';
  my $html = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>GraphiQL - GraphQL::Houtou</title>
  <style>html, body, #graphiql { height: 100%; margin: 0; }</style>
  <link rel="stylesheet" href="https://esm.sh/graphiql\@5.2.4/dist/style.css" />
</head>
<body>
  <div id="graphiql">Loading GraphiQL...</div>
  <script type="importmap">
  {
    "imports": {
      "react": "https://esm.sh/react\@19.2.7",
      "react/": "https://esm.sh/react\@19.2.7/",
      "react-dom": "https://esm.sh/react-dom\@19.2.7",
      "react-dom/": "https://esm.sh/react-dom\@19.2.7/",
      "graphiql": "https://esm.sh/graphiql\@5.2.4?standalone&external=react,react-dom,\@graphiql/react,graphql",
      "graphiql/": "https://esm.sh/graphiql\@5.2.4/",
      "\@graphiql/react": "https://esm.sh/\@graphiql/react\@0.37.7?standalone&external=react,react-dom,graphql,\@graphiql/toolkit,\@emotion/is-prop-valid",
      "\@graphiql/toolkit": "https://esm.sh/\@graphiql/toolkit\@0.12.1?standalone&external=graphql",
      "graphql": "https://esm.sh/graphql\@17.0.2",
      "\@emotion/is-prop-valid": "data:text/javascript,"
    }
  }
  </script>
  <script type="module">
    import React from 'react';
    import ReactDOM from 'react-dom/client';
    import { GraphiQL } from 'graphiql';
    import { createGraphiQLFetcher } from '\@graphiql/toolkit';
    import 'graphiql/setup-workers/esm.sh';
    const fetcher = createGraphiQLFetcher({ url: '$endpoint' || window.location.pathname });
    ReactDOM.createRoot(document.getElementById('graphiql')).render(
      React.createElement(GraphiQL, { fetcher })
    );
  </script>
</body>
</html>
HTML
  return [
    200,
    [ 'Content-Type' => 'text/html; charset=utf-8', 'Content-Length' => length $html ],
    [ $html ],
  ];
}

1;
__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::PSGI - GraphQL over HTTP endpoint as a plain PSGI app

=head1 SYNOPSIS

  # app.psgi
  use GraphQL::Houtou::PSGI;
  use GraphQL::Houtou::DataLoader;

  GraphQL::Houtou::PSGI->new(
    schema => $schema,
    graphiql => 1,
    context => sub {
      my ($env) = @_;
      my $users = GraphQL::Houtou::DataLoader->new(batch => \&batch_users);
      my $context = { users => $users, env => $env };
      return ($context, GraphQL::Houtou::DataLoader->on_stall_for($users));
    },
  )->to_app;

=head1 DESCRIPTION

A GraphQL over HTTP endpoint built directly on the PSGI interface - no
Plack modules are required at runtime. Responses are rendered by the
direct-JSON execution lane (C<execute_document_to_json>), so the Perl
response envelope is never materialized: sync schemas take the streaming
fast lane and batching (DataLoader) schemas take the async lane with the
JSON tail.

=head1 OPTIONS

=over 4

=item schema / runtime

Either a L<GraphQL::Houtou::Schema> (a native runtime is built once at
construction) or a prebuilt L<GraphQL::Houtou::Runtime::NativeRuntime>.

=item context

A hashref passed to resolvers as-is, or a coderef called once per request
with the PSGI C<$env>. The coderef may return the context alone or a
C<($context, $on_stall)> pair - the natural shape when per-request
DataLoaders live inside the context (see SYNOPSIS).

=item on_stall

A static stall-flush hook (see L<GraphQL::Houtou/Batching resolvers>).
A per-request hook returned by the C<context> builder takes precedence.

=item graphiql

Serve the GraphiQL IDE (loaded from the esm.sh CDN) on C<GET> requests
whose C<Accept> includes C<text/html>. C<graphiql_path> overrides the
endpoint URL the IDE posts to (defaults to the page's own path).

=item async

Passed to C<build_native_runtime> when the app is constructed from a
C<schema>. Declare it when resolvers return promises (DataLoader or other
Promise::XS sources) so every request starts on the async-capable lane
(see "Declaring an async schema" in L<GraphQL::Houtou>). Requests that
carry an C<on_stall> hook run on the async lane either way, so pure
DataLoader apps work without it - C<async> matters when promises can
appear without a stall-flush hook.

=item root_value, max_depth, max_nodes, max_cost, default_list_size, program_cache_max

Passed through to the runtime. C<max_depth> caps query nesting;
C<max_nodes> caps the total field selections an operation resolves
(alias-flooding defense). C<max_cost> caps weighted field cost;
C<default_list_size> is the multiplier for list fields without an explicit
C<list_size> (defaults to 10). Limits reject over-limit queries with an
errors-only 400 response.

=item allow_introspection

Defaults to true. Set to C<0> on public endpoints to reject C<__schema> and
C<__type> with an C<INTROSPECTION_DISABLED> request error. C<__typename>
remains available. When C<schema> is supplied the option is also applied to
the runtime built by the adapter; with a prebuilt C<runtime> it is applied to
each document request. GraphiQL relies on schema introspection, so do not
combine C<graphiql =E<gt> 1> with a disabled policy unless trusted requests
override it outside this adapter.

=item max_body_size

Maximum request body in bytes (default C<1048576>, i.e. 1 MiB). Bodies
whose C<Content-Length> exceeds this, or that read past it, are rejected
with a C<413> before parsing. Pass C<0> to disable the cap.

=back

=head1 PROTOCOL

POST with C<Content-Type: application/json> and a
C<{"query": ..., "variables": ..., "operationName": ...}> body. The
response is C<application/graphql-response+json> when the client accepts
it, C<application/json> otherwise. Requests that fail before execution
(malformed body, parse or validation errors, unknown operationName)
return 400 with an errors-only envelope; field-level errors execute to a
200 response with the C<errors> array populated, as GraphQL over HTTP
specifies. GET execution is not implemented; GET serves GraphiQL when
enabled and 405 otherwise.

Requests naming an C<operationName> are cached like any other: the
program cache keys on the C<(query, operationName)> pair, so clients that
always send C<operationName> (Apollo Client and friends) stay on the
compiled hot path.

=cut
