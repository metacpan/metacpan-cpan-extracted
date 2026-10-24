package Langertha::Skeid::OpenAPI;
our $VERSION = '0.004';
# ABSTRACT: OpenAPI 3.1 description built from the proxy's route table
use strict;
use warnings;
use Carp qw(croak);


# --- component schemas ------------------------------------------------------------------------

my %SCHEMA = (
  Error => {
    type       => 'object',
    properties => {
      error => {
        type       => 'object',
        properties => {
          message => { type => 'string' },
          type    => { type => 'string' },
          code    => { type => [ 'string', 'null' ] },
        },
        required => ['message'],
      },
    },
    description => 'The error object of the face the route belongs to. The OpenAI shape is shown; '
      . 'the Anthropic and Ollama routes answer in their own client dialects.',
  },
  Object => { type => 'object', additionalProperties => \1 },
  ModelList => {
    type       => 'object',
    properties => {
      object => { type => 'string', const => 'list' },
      data   => {
        type  => 'array',
        items => {
          type       => 'object',
          properties => {
            id       => { type => 'string' },
            object   => { type => 'string', const => 'model' },
            created  => { type => 'integer' },
            owned_by => { type => 'string' },
          },
          required => [ 'id', 'object' ],
        },
      },
    },
    required => [ 'object', 'data' ],
  },
  ChatCompletionRequest => {
    type       => 'object',
    properties => {
      model    => { type => 'string', description => 'A node model or an alias name.' },
      messages => {
        type  => 'array',
        items => {
          type       => 'object',
          properties => { role => { type => 'string' }, content => {} },
          required   => ['role'],
        },
      },
      stream      => { type => 'boolean' },
      temperature => { type => 'number' },
      max_tokens  => { type => 'integer' },
      tools       => { type => 'array', items => { type => 'object' } },
      tool_choice => {},
    },
    required => [ 'model', 'messages' ],
  },
  EmbeddingsRequest => {
    type       => 'object',
    properties => {
      model => { type => 'string' },
      input => { oneOf => [ { type => 'string' }, { type => 'array', items => { type => 'string' } } ] },
    },
    required => [ 'model', 'input' ],
  },
  RerankRequest => {
    type       => 'object',
    properties => {
      model     => { type => 'string' },
      query     => { type => 'string' },
      documents => { type => 'array', minItems => 1, items => {} },
      top_n     => { type => 'integer' },
    },
    required => [ 'model', 'query', 'documents' ],
  },
  AudioRequest => {
    type       => 'object',
    properties => {
      file  => { type => 'string', contentMediaType => 'application/octet-stream' },
      model => { type => 'string' },
      stream => { type => 'boolean' },
    },
    required => [ 'file', 'model' ],
  },
  DocumentsFileRequest => {
    type       => 'object',
    description => 'docling-serve\'s form: the files plus its option fields, relayed as sent.',
    properties => {
      files => { type => 'array', items => { type => 'string', contentMediaType => 'application/octet-stream' } },
    },
    required => ['files'],
  },
  DocumentsSourceRequest => {
    type       => 'object',
    description => 'docling-serve\'s source body: inline files (base64) and options, relayed as sent.',
    properties => {
      file_sources => {
        type  => 'array',
        items => {
          type       => 'object',
          properties => { base64_string => { type => 'string' }, filename => { type => 'string' } },
          required   => [ 'base64_string', 'filename' ],
        },
      },
      options => { type => 'object' },
    },
    required => ['file_sources'],
  },
  AnthropicMessagesRequest => {
    type       => 'object',
    properties => {
      model      => { type => 'string' },
      max_tokens => { type => 'integer' },
      system     => { oneOf => [ { type => 'string' }, { type => 'array', items => { type => 'object' } } ] },
      messages   => { type => 'array', items => { type => 'object' } },
      stream     => { type => 'boolean' },
    },
    required => [ 'model', 'max_tokens', 'messages' ],
  },
  OllamaChatRequest => {
    type       => 'object',
    properties => {
      model    => { type => 'string' },
      messages => { type => 'array', items => { type => 'object' } },
      stream   => { type => 'boolean', description => 'Streams unless false.' },
    },
    required => [ 'model', 'messages' ],
  },
  OllamaGenerateRequest => {
    type       => 'object',
    properties => {
      model  => { type => 'string' },
      prompt => { type => 'string' },
      system => { type => 'string' },
      stream => { type => 'boolean', description => 'Streams unless false.' },
    },
    required => [ 'model', 'prompt' ],
  },
  NodeList => {
    type       => 'object',
    properties => { nodes => { type => 'array', items => { type => 'object' } } },
  },
);

# One example body per request schema; $model is the first name GET /v1/models lists.
my %EXAMPLE = (
  ChatCompletionRequest    => sub { +{ model => $_[0], messages => [ { role => 'user', content => 'Hello' } ] } },
  EmbeddingsRequest        => sub { +{ model => $_[0], input => 'The quick brown fox' } },
  RerankRequest            => sub { +{ model => $_[0], query => 'What is Skeid?', documents => [ 'A routing proxy.', 'A fruit.' ] } },
  DocumentsSourceRequest   => sub { +{ options => { to_formats => ['md'] },
    file_sources => [ { base64_string => 'JVBERi0xLjQK', filename => 'document.pdf' } ] } },
  AnthropicMessagesRequest => sub { +{ model => $_[0], max_tokens => 256, messages => [ { role => 'user', content => 'Hello' } ] } },
  OllamaChatRequest        => sub { +{ model => $_[0], stream => \0, messages => [ { role => 'user', content => 'Hello' } ] } },
  OllamaGenerateRequest    => sub { +{ model => $_[0], stream => \0, prompt => 'Hello' } },
);

# --- path templates ---------------------------------------------------------------------------


sub path_template {
  my ($self, $pattern) = @_;
  (my $t = $pattern) =~ s/[:#*]([A-Za-z_][A-Za-z0-9_]*)/{$1}/g;
  return $t;
}

sub path_params {
  my ($self, $pattern) = @_;
  return $pattern =~ /[:#*]([A-Za-z_][A-Za-z0-9_]*)/g;
}


sub document {
  my ($self, %arg) = @_;
  my $kind    = $arg{kind} // 'client';
  croak "unknown document kind '$kind'" unless $kind eq 'client' || $kind eq 'admin';
  my $entries = $arg{entries} || [];
  my $models  = $arg{models}  || [];
  my $model   = @$models ? $models->[0] : 'my-model';
  my $scheme  = $kind eq 'admin' ? 'admin_key' : 'client_auth';

  my (%paths, %used, %tags);
  for my $e (@$entries) {
    for my $pattern (@{$e->{paths}}) {
      my $template = $self->path_template($pattern);
      my @params   = $self->path_params($pattern);
      for my $method (@{$e->{methods}}) {
        my $op = {
          operationId => $e->{id} . (@{$e->{methods}} > 1 ? '_' . lc($method) : '')
            . (@{$e->{paths}} > 1 ? '_' . ($pattern =~ /\*/ ? 'path' : 'root') : ''),
          summary     => $e->{summary},
          tags        => [ $e->{tag} ],
        };
        $op->{description} = $e->{description} if defined $e->{description};
        $tags{$e->{tag}} = 1;

        my @parameters = map { +{ name => $_, in => 'path', required => 1, schema => { type => 'string' } } } @params;
        # A route that takes its input in the query (the realtime WebSocket, skeid k95).
        push @parameters, map {
          +{ name => $_->{name}, in => 'query', required => ($_->{required} ? \1 : \0),
             (defined $_->{description} ? (description => $_->{description}) : ()),
             schema => { type => 'string' } }
        } @{ $e->{query} || [] };
        $op->{parameters} = \@parameters if @parameters;

        if (defined $e->{request}) {
          croak "unknown request schema '$e->{request}'" unless $SCHEMA{$e->{request}};
          $used{$e->{request}} = 1;
          my $media = ($e->{request_type} // 'json') eq 'multipart' ? 'multipart/form-data' : 'application/json';
          my $content = { schema => { '$ref' => '#/components/schemas/' . $e->{request} } };
          $content->{example} = $EXAMPLE{$e->{request}}->($model) if $EXAMPLE{$e->{request}};
          $op->{requestBody} = { required => \1, content => { $media => $content } };
        }

        my $ok_schema = $e->{response} // 'Object';
        croak "unknown response schema '$ok_schema'" unless $SCHEMA{$ok_schema};
        $used{$ok_schema} = 1;
        $used{Error} = 1;
        my %ok = ( description => $e->{response_description} // 'The answer.' );
        if ($e->{stream}) {
          $ok{description} .= ' With "stream": true, a text/event-stream.';
          $ok{content} = {
            'application/json'  => { schema => { '$ref' => '#/components/schemas/' . $ok_schema } },
            'text/event-stream' => { schema => { type => 'string' } },
          };
        }
        else {
          $ok{content} = { 'application/json' => { schema => { '$ref' => '#/components/schemas/' . $ok_schema } } };
        }
        # An upgrade is not a document: the success is 101, and there is no body to describe.
        %ok = ( description => 'Switching protocols: the connection is a WebSocket from here on.' )
          if $e->{websocket};
        $op->{responses} = {
          ($e->{websocket} ? ('101' => \%ok) : ('200' => \%ok)),
          default => {
            description => 'An error: 4xx for a request the caller got wrong, 5xx for the proxy or its node.',
            content     => { 'application/json' => { schema => { '$ref' => '#/components/schemas/Error' } } },
          },
        };

        if ($e->{public}) {
          $op->{security} = [];
        }
        elsif ($kind eq 'client' && !$arg{client_auth}) {
          # No client_auth section: a key is not required, only used for policy and metering.
          $op->{security} = [ {}, { $scheme => [] } ];
        }
        else {
          $op->{security} = [ { $scheme => [] } ];
        }

        $paths{$template}{lc $method} = $op;
      }
    }
  }

  my $title = $kind eq 'admin' ? 'Skeid admin API' : 'Skeid';
  my %doc = (
    openapi => '3.1.0',
    info    => {
      title   => $title,
      version => $arg{version} // '0',
      description => $kind eq 'admin'
        ? 'The control-plane routes under /skeid. Every one needs the admin API key.'
        : 'An LLM routing proxy. One API key, several client formats (OpenAI, Anthropic, Ollama), '
          . 'models behind it chosen by Skeid. Describes the routes this deployment serves.',
    },
    tags  => [ map { +{ name => $_ } } sort keys %tags ],
    paths => \%paths,
    components => {
      schemas         => { map { $_ => $SCHEMA{$_} } sort keys %used },
      securitySchemes => {
        $scheme => {
          type         => 'http',
          scheme       => 'bearer',
          description  => $kind eq 'admin'
            ? 'The admin API key (admin_api_key).'
            : 'A Skeid customer key, as "Authorization: Bearer <key>". The Anthropic face also '
              . 'accepts it as an x-api-key header. With a client_auth section in the config only '
              . 'listed keys are let in (401 otherwise).',
        },
      },
    },
  );
  return \%doc;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::OpenAPI - OpenAPI 3.1 description built from the proxy's route table

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  my $doc = Langertha::Skeid::OpenAPI->document(
    entries     => \@enabled_route_table_entries,
    kind        => 'client',          # or 'admin'
    models      => ['qwen3-32b'],     # what GET /v1/models lists for this caller
    client_auth => 1,
    version     => $Langertha::Skeid::Proxy::VERSION,
  );

=head1 DESCRIPTION

Turns entries of L<Langertha::Skeid::Proxy/route_table> into an OpenAPI 3.1 document. Which
entries are in the document -- the enabled ones -- is the proxy's decision; this module
only describes what it is given, so the document cannot name a route the app does not
register (the route table is also what registers them).

Nothing in a document comes from a request body, a key or the config's secrets: it holds paths,
fixed descriptions and one model name per example, from the same list C<GET /v1/models>
answers.

=head2 path_template

  Langertha::Skeid::OpenAPI->path_template('/mcp/#mcp_server/*mcp_path');
  # '/mcp/{mcp_server}/{mcp_path}'

A Mojolicious route pattern as an OpenAPI path template.

=head2 path_params

The placeholder names of a route pattern, in order.

=head2 document

The document, as a hashref ready for C<encode_json>. Arguments: C<entries> (route table
entries, already filtered), C<kind> (C<client> or C<admin>), C<models>, C<client_auth> (true
when the config requires a key on the client routes), C<version>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
