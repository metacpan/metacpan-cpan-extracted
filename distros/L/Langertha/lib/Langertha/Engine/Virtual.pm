package Langertha::Engine::Virtual;
# ABSTRACT: Rule-driven engine that answers without network, key or model
our $VERSION = '0.504';
use Moose;
use Carp qw( croak );
use Encode ();
use HTTP::Response;
use HTTP::Status ();
use LWP::UserAgent;
use Module::Runtime qw( use_module );
use Path::Tiny;
use Scalar::Util qw( looks_like_number weaken );
use YAML::PP;
use Langertha::Request::SyncHTTP;
use Langertha::Virtual::Rules ();

extends 'Langertha::Engine::Remote';

# Chat, streaming and the tool loop run through the real OpenAI-dialect request
# builders and parsers (OpenAICompatible + OpenAPI + Streaming); only the
# transport is replaced by the in-process rule evaluation below. No
# Temperature, ResponseFormat, ...: the engine claims only what it serves.
with map { 'Langertha::Role::'.$_ } qw(
  OpenAICompatible
  OpenAPI
  Models
  ResponseSize
  SystemPrompt
  Streaming
  Chat
  Tools
  StreamUsage
);


has '+url' => (
  default => 'http://virtual.invalid/v1',
);


sub default_model { 'virtual' }


sub api_key_env { undef }


sub _build_openapi_operations {
  return use_module('Langertha::Spec::OpenAI')->data;
}

has rules => (
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);


has fallback => (
  is        => 'ro',
  predicate => 'has_fallback',
);


has script => (
  is        => 'ro',
  isa       => 'ArrayRef',
  predicate => 'has_script',
);


has rules_file => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_rules_file',
);


has default_usage => (
  is        => 'ro',
  isa       => 'HashRef|CodeRef',
  predicate => 'has_default_usage',
);


has stream_chunk_size => (
  is      => 'ro',
  isa     => 'Int',
  default => 8,
);


has requests => (
  is       => 'ro',
  isa      => 'ArrayRef',
  init_arg => undef,
  default  => sub { [] },
);


has calls => (
  is       => 'ro',
  isa      => 'ArrayRef',
  init_arg => undef,
  default  => sub { [] },
);


has results => (
  is       => 'ro',
  isa      => 'ArrayRef',
  init_arg => undef,
  default  => sub { [] },
);


has _script_position => (
  is       => 'rw',
  isa      => 'Int',
  init_arg => undef,
  default  => 0,
);

my %RULES_FILE_KEYS = map { $_ => 1 } qw( rules after fallback script );
my %REACTION_KEYS   = map { $_ => 1 } qw( answer text tool_calls error usage );
my %PRESETS         = (
  echo  => '_preset_echo',
  files => '_preset_files',
);

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  return $args unless defined $args->{rules_file};
  my $file = $args->{rules_file} = "$args->{rules_file}";
  my $loaded = $class->_load_rules_file($file);
  for my $key ( sort keys %$loaded ) {
    croak $class.": $key is given to the constructor and in rules_file $file" if exists $args->{$key};
    $args->{$key} = $loaded->{$key};
  }
  return $args;
};

sub BUILD {
  my ( $self ) = @_;
  my $class = ref $self;
  my @rules = @{ $self->rules };
  croak $class.': rules must be a list of TRIGGER => REACTION pairs (odd number of elements)' if @rules % 2;
  croak $class.': rules and script cannot be combined' if @rules && $self->has_script;
  croak $class.': stream_chunk_size must be at least 1' if $self->stream_chunk_size < 1;
  my $number = 0;
  while ( my ( $trigger, $reaction ) = splice @rules, 0, 2 ) {
    $number++;
    $self->_check_trigger( $trigger, "rule $number" );
    $self->_check_reaction( $reaction, "rule $number" );
  }
  if ( $self->has_script ) {
    my $position = 0;
    $self->_check_reaction( $_, 'script entry '.++$position ) for @{ $self->script };
  }
  $self->_check_reaction( $self->fallback, 'fallback' ) if $self->has_fallback;
  return;
}

sub _check_trigger {
  my ( $self, $trigger, $where ) = @_;
  my $class = ref $self;
  croak $class.": the trigger of $where is undef" unless defined $trigger;
  return if !ref $trigger || ref $trigger eq 'Regexp' || ref $trigger eq 'CODE';
  return if ref $trigger eq 'HASH' && keys %$trigger == 1 && ref $trigger->{after} eq 'HASH';
  croak $class.": the trigger of $where must be a string, a Regexp, a sub or after(...)";
}

sub _check_reaction {
  my ( $self, $reaction, $where ) = @_;
  return if ref $reaction eq 'CODE';
  $self->_normalize_reaction( $reaction, $where );
  return;
}

# A reaction as data: { answer => Maybe[Str], tool_calls => [ [ $name, \%arguments ], ... ] },
# plus usage => \%usage when it gives one.
sub _normalize_reaction {
  my ( $self, $reaction, $where ) = @_;
  my $class = ref $self;
  return { answer => $reaction, tool_calls => [] } if defined $reaction && !ref $reaction;
  croak $class.": $where must be a text, a HashRef or a sub, not ".( defined $reaction ? ref $reaction : 'undef' )
    unless ref $reaction eq 'HASH';
  my @unknown = grep { !$REACTION_KEYS{$_} } sort keys %$reaction;
  croak $class.": $where has unknown keys: @unknown (known: answer, text, tool_calls, usage, error)" if @unknown;
  croak $class.": $where has both answer and text" if exists $reaction->{answer} && exists $reaction->{text};
  if ( exists $reaction->{error} ) {
    my $error = $reaction->{error};
    croak $class.": the error of $where must be { status => ..., message => ... }"
      unless ref $error eq 'HASH' && defined $error->{status} && $error->{status} =~ /\A[45]\d\d\z/
        && defined $error->{message} && !ref $error->{message};
    croak $class.": $where has an error together with an answer, tool calls or usage"
      if grep { exists $reaction->{$_} } qw( answer text tool_calls usage );
    return { error => { status => 0 + $error->{status}, message => $error->{message} } };
  }
  croak $class.": the usage of $where must be a HashRef"
    if exists $reaction->{usage} && ref $reaction->{usage} ne 'HASH';
  my $answer = exists $reaction->{answer} ? $reaction->{answer} : $reaction->{text};
  croak $class.": the answer of $where must be a text" if ref $answer;
  my $calls = $reaction->{tool_calls} // [];
  croak $class.": the tool_calls of $where must be an ArrayRef" unless ref $calls eq 'ARRAY';
  my @tool_calls;
  for my $call (@$calls) {
    croak $class.": each tool call of $where must be [ \$name, \\%arguments ]"
      unless ref $call eq 'ARRAY' && @$call >= 1 && @$call <= 2
        && defined $call->[0] && !ref $call->[0] && length $call->[0]
        && ( !defined $call->[1] || ref $call->[1] eq 'HASH' );
    push @tool_calls, [ $call->[0], $call->[1] // {} ];
  }
  croak $class.": $where has neither an answer nor tool calls" unless defined $answer || @tool_calls;
  return { answer => $answer, tool_calls => \@tool_calls,
    exists $reaction->{usage} ? ( usage => $reaction->{usage} ) : () };
}

sub _load_rules_file {
  my ( $class, $file ) = @_;
  my $data = YAML::PP->new( boolean => 'JSON::PP' )->load_string( path($file)->slurp_utf8 );
  croak $class.": rules_file $file must hold a mapping" unless ref $data eq 'HASH';
  my @unknown = grep { !$RULES_FILE_KEYS{$_} } sort keys %$data;
  croak $class.": rules_file $file has unknown keys: @unknown (known: after, fallback, rules, script)" if @unknown;
  my %args;
  for my $key (qw( rules after )) {
    next unless exists $data->{$key};
    my $map = $data->{$key};
    croak $class.": $key in rules_file $file must be a mapping" unless ref $map eq 'HASH';
    push @{ $args{rules} }, map {
      ( $key eq 'after' ? Langertha::Virtual::Rules::after($_) : $_ ) => $map->{$_}
    } sort keys %$map;
  }
  $args{fallback} = $data->{fallback} if exists $data->{fallback};
  $args{script}   = $data->{script}   if exists $data->{script};
  return \%args;
}

sub preset {
  my ( $class, $name, @args ) = @_;
  my $method = defined $name ? $PRESETS{$name} : undef;
  croak $class.'->preset: unknown preset '.( $name // 'undef' ).' (known: '.join( ', ', sort keys %PRESETS ).')'
    unless $method;
  return $class->new( $class->$method, @args );
}


sub _preset_echo {
  return (
    fallback => sub {
      my ( $request ) = @_;
      return Langertha::Virtual::Rules::answer( $request->{last_user_text} // '' );
    },
  );
}

sub _preset_files {
  return (
    rules => [
      qr/\ARead the file (\S+)\z/ => sub {
        my ( $request, $path ) = @_;
        return Langertha::Virtual::Rules::tool( read_file => { path => $path } );
      },
      qr/\AWrite the file (\S+): (.*)\z/s => sub {
        my ( $request, $path, $content ) = @_;
        return Langertha::Virtual::Rules::tool( write_file => { path => $path, content => $content } );
      },
      qr/\ARun the command (.+)\z/s => sub {
        my ( $request, $command ) = @_;
        return Langertha::Virtual::Rules::tool( bash => { command => $command } );
      },
      Langertha::Virtual::Rules::after() => sub {
        my ( $request ) = @_;
        return Langertha::Virtual::Rules::answer(
          join "\n", map { $_->{content} // '' } @{ $request->{tool_results} } );
      },
    ],
    fallback => Langertha::Virtual::Rules::answer(
      "I know these prompts:\nRead the file PATH\nWrite the file PATH: CONTENT\nRun the command COMMAND" ),
  );
}

sub list_models {
  my ( $self, %opts ) = @_;
  my @models = ( { id => $self->model } );
  return $opts{full} ? \@models : [ map { $_->{id} } @models ];
}


# The transport. Every request the sync user agent sends is answered by the
# request_send handler before LWP picks a protocol, and the _f calls run over
# the same agent through the sync shim, so nothing ever reaches the network.
sub _build_user_agent {
  my ( $self ) = @_;
  my $ua = LWP::UserAgent->new( agent => $self->user_agent_agent );
  my $engine = $self;
  weaken $engine;
  $ua->add_handler( request_send => sub {
    my ( $request ) = @_;
    return $engine->_virtual_response($request);
  } );
  return $ua;
}

sub _build__async_http {
  my ( $self ) = @_;
  return Langertha::Request::SyncHTTP->new( user_agent => $self->user_agent );
}

around format_tool_results => sub {
  my ( $orig, $self, $data, $results ) = @_;
  push @{ $self->results }, @{ $results // [] };
  return $self->$orig( $data, $results );
};

# A request the engine cannot answer comes back as an error status, so the
# caller fails with core's own "<class> request failed: <status> - <reason>"
# on every path (sync, _f, the tool loops), as with a real server.
sub _virtual_response {
  my ( $self, $request ) = @_;
  my $reply = $self->virtual_reply( $request->method, $request->uri->path, $request->content );
  if ( $reply->{code} == 200 ) {
    my $body = $self->json->decode( $request->content );
    return $self->_virtual_stream_response( $request, $body, $reply->{content} ) if $body->{stream};
  }
  return $self->_virtual_http_response( $request, @{$reply}{qw( code message content )} );
}

# A stream request's reply as the server-sent events an OpenAI server sends.
sub _virtual_stream_response {
  my ( $self, $request, $body, $completion ) = @_;
  my $chunks = $self->virtual_stream_chunks( $completion,
    include_usage => ref $body->{stream_options} eq 'HASH' && $body->{stream_options}{include_usage} ? 1 : 0 );
  my $events = join( '', map { 'data: '.$self->json->encode($_)."\n\n" } @$chunks )."data: [DONE]\n\n";
  my $response = HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'text/event-stream', 'Cache-Control' => 'no-cache' ], $events );
  $response->request($request);
  return $response;
}

sub virtual_reply {
  my ( $self, $method, $path, $content ) = @_;
  unless ( uc($method) eq 'POST' && $path =~ m{/chat/completions\z} ) {
    return { code => 404, message => 'Not Found',
      content => "answers only chat completions, not $method $path" };
  }
  my $view = $self->_request_view( $self->json->decode($content) );
  push @{ $self->requests }, $view;
  my ( $reaction, $usage, $error );
  eval {
    $reaction = $self->_reaction_for($view);
    $usage    = $self->_usage_for( $view, $reaction ) if $reaction && !$reaction->{error};
    1;
  } or $error = $@ || 'unknown error';
  if ( defined $error ) {
    $error =~ s/\s+\z//;
    return { code => 500, message => 'Reaction Failed', content => $error };
  }
  return { code => 500, message => 'No Reaction', content => $self->_no_reaction_message($view) }
    unless $reaction;
  if ( my $failure = $reaction->{error} ) {
    return { code => $failure->{status}, message => HTTP::Status::status_message( $failure->{status} ) // 'Error',
      content => $failure->{message} };
  }
  return { code => 200, message => 'OK', content => $self->_completion( $view, $reaction, $usage ) };
}


sub virtual_stream_chunks {
  my ( $self, $completion, %opts ) = @_;
  my $choice  = $completion->{choices}[0];
  my $message = $choice->{message};
  my %base = (
    id      => $completion->{id},
    object  => 'chat.completion.chunk',
    created => $completion->{created},
    model   => $completion->{model},
  );
  my @deltas = map { { content => $_ } } $self->_stream_pieces( $message->{content} );
  my $tool_calls = $message->{tool_calls} // [];
  for my $index ( 0 .. $#$tool_calls ) {
    my $call = $tool_calls->[$index];
    push @deltas, { tool_calls => [ {
      index    => $index,
      id       => $call->{id},
      type     => $call->{type},
      function => { name => $call->{function}{name}, arguments => '' },
    } ] };
    push @deltas, map { { tool_calls => [ { index => $index, function => { arguments => $_ } } ] } }
      $self->_stream_pieces( $call->{function}{arguments} );
  }
  push @deltas, { content => '' } unless @deltas;
  $deltas[0] = { role => 'assistant', %{ $deltas[0] } };
  my @chunks = map { { %base, choices => [ { index => 0, delta => $_ } ] } } @deltas;
  push @chunks, { %base, choices => [ { index => 0, delta => {}, finish_reason => $choice->{finish_reason} } ] };
  push @chunks, { %base, choices => [], usage => $completion->{usage} }
    if $opts{include_usage} && $completion->{usage};
  return \@chunks;
}


# The text in pieces of stream_chunk_size characters; none for an empty text.
sub _stream_pieces {
  my ( $self, $text ) = @_;
  return () unless defined $text && length $text;
  my $size = $self->stream_chunk_size;
  return $text =~ /(.{1,$size})/gs;
}

# The reply's usage block (see USAGE): the reaction's, else default_usage's,
# else none. total_tokens is added when the wire would carry it.
sub _usage_for {
  my ( $self, $view, $reaction ) = @_;
  my $usage = $reaction->{usage};
  if ( !$usage && $self->has_default_usage ) {
    $usage = $self->default_usage;
    if ( ref $usage eq 'CODE' ) {
      my %data = ( answer => $reaction->{answer}, tool_calls => $reaction->{tool_calls} );
      $usage = $usage->( $view, \%data );
      return unless defined $usage;
      croak ref($self).': default_usage returned '.( ref $usage || 'a non-reference' ).', not a HashRef or undef'
        unless ref $usage eq 'HASH';
    }
  }
  return unless $usage;
  my %usage = %$usage;
  $usage{total_tokens} = $usage{prompt_tokens} + $usage{completion_tokens}
    if !defined $usage{total_tokens}
      && looks_like_number( $usage{prompt_tokens} ) && looks_like_number( $usage{completion_tokens} );
  return \%usage;
}

# $content is a completion body (JSON) or an error text (text/plain).
sub _virtual_http_response {
  my ( $self, $request, $code, $message, $content ) = @_;
  my $response = ref $content
    ? HTTP::Response->new( $code, $message, [ 'Content-Type' => 'application/json' ], $self->json->encode($content) )
    : HTTP::Response->new( $code, $message, [ 'Content-Type' => 'text/plain; charset=utf-8' ], Encode::encode( 'UTF-8', $content ) );
  $response->request($request);
  return $response;
}

# What the rules see of a request (documented under "The request").
sub _request_view {
  my ( $self, $body ) = @_;
  my @messages = @{ $body->{messages} // [] };
  my $last_role = @messages ? $messages[-1]{role} // '' : '';
  my ($last_user) = grep { ( $_->{role} // '' ) eq 'user' } reverse @messages;
  my %tool_names = map { ( $_->{id} // '' ) => $_->{function}{name} }
    map { @{ $_->{tool_calls} // [] } }
    grep { ( $_->{role} // '' ) eq 'assistant' } @messages;
  my @results;
  my $index = $#messages;
  while ( $index >= 0 && ( $messages[$index]{role} // '' ) eq 'tool' ) {
    unshift @results, $messages[ $index-- ];
  }
  return {
    number         => scalar @{ $self->requests } + 1,
    model          => $body->{model},
    messages       => \@messages,
    text           => $last_role eq 'user' ? $self->_message_text( $messages[-1] ) : undef,
    last_user_text => $last_user ? $self->_message_text($last_user) : undef,
    tool_results   => [ map { {
      id      => $_->{tool_call_id},
      name    => $tool_names{ $_->{tool_call_id} // '' },
      content => $self->_message_text($_),
    } } @results ],
    tools          => $body->{tools} // [],
    body           => $body,
  };
}

sub _message_text {
  my ( $self, $message ) = @_;
  my $content = $message->{content};
  return $content // '' unless ref $content eq 'ARRAY';
  return join "\n", map { ref $_ ? $_->{text} // () : $_ // () }
    grep { !ref $_ || ( ref $_ eq 'HASH' && ( $_->{type} // '' ) eq 'text' ) } @$content;
}

sub _reaction_for {
  my ( $self, $view ) = @_;
  if ( $self->has_script ) {
    my $position = $self->_script_position;
    if ( $position < @{ $self->script } ) {
      $self->_script_position( $position + 1 );
      return $self->_resolve_reaction( $self->script->[$position], $view, [], 'script entry '.( $position + 1 ) );
    }
  }
  else {
    my @rules  = @{ $self->rules };
    my $number = 0;
    while ( my ( $trigger, $reaction ) = splice @rules, 0, 2 ) {
      $number++;
      my $captures = $self->_match_trigger( $trigger, $view ) or next;
      return $self->_resolve_reaction( $reaction, $view, $captures, "rule $number" );
    }
  }
  return $self->_resolve_reaction( $self->fallback, $view, [], 'fallback' ) if $self->has_fallback;
  return;
}

sub _no_reaction_message {
  my ( $self, $view ) = @_;
  my $what = $self->has_script ? 'the script has run out' : 'no rule matches';
  my $last = defined $view->{text} ? "the user message '$view->{text}'"
    : @{ $view->{tool_results} } ? 'the tool result of '
      .join( ', ', map { $_->{name} // 'an unknown call' } @{ $view->{tool_results} } )
    : 'a conversation that does not end in a user message or a tool result';
  return $what.' and no fallback is set (request '.$view->{number}.", last message: $last)";
}

# Captures (an ArrayRef, empty for none) when the trigger matches, else undef.
sub _match_trigger {
  my ( $self, $trigger, $view ) = @_;
  return $self->_match_after( $trigger->{after}, $view ) if ref $trigger eq 'HASH';
  return $trigger->($view) ? [] : undef if ref $trigger eq 'CODE';
  return undef unless defined $view->{text};
  return $self->_match_value( $trigger, $view->{text} );
}

sub _match_after {
  my ( $self, $match, $view ) = @_;
  for my $result ( @{ $view->{tool_results} } ) {
    my $tool = $self->_match_value( $match->{tool}, $result->{name} ) or next;
    my $text = $self->_match_value( $match->{result}, $result->{content} ) or next;
    return [ @$tool, @$text ];
  }
  return undef;
}

# A string matcher compares exactly, a Regexp matches; undef matches anything.
sub _match_value {
  my ( $self, $matcher, $value ) = @_;
  return [] unless defined $matcher;
  return undef unless defined $value;
  return $value eq $matcher ? [] : undef unless ref $matcher;
  my @captures = $value =~ $matcher or return undef;
  return $#+ ? \@captures : [];
}

sub _resolve_reaction {
  my ( $self, $reaction, $view, $captures, $where ) = @_;
  if ( ref $reaction eq 'CODE' ) {
    $reaction = $reaction->( $view, @$captures );
    croak ref($self).": the sub of $where returned a sub, not a reaction" if ref $reaction eq 'CODE';
    $where = "the reply of the sub of $where";
  }
  return $self->_normalize_reaction( $reaction, $where );
}

# The reaction as an OpenAI chat completion body.
sub _completion {
  my ( $self, $view, $reaction, $usage ) = @_;
  my @tool_calls = map {
    my ( $name, $arguments ) = @$_;
    push @{ $self->calls }, [ $name, $arguments ];
    {
      id       => 'call_virtual_'.scalar @{ $self->calls },
      type     => 'function',
      function => { name => $name, arguments => $self->encode_json_text($arguments) },
    };
  } @{ $reaction->{tool_calls} };
  return {
    id      => 'virtual-'.$view->{number},
    object  => 'chat.completion',
    created => time,
    model   => $view->{model} // $self->chat_model,
    choices => [ {
      index         => 0,
      message       => {
        role    => 'assistant',
        content => $reaction->{answer},
        @tool_calls ? ( tool_calls => \@tool_calls ) : (),
      },
      finish_reason => @tool_calls ? 'tool_calls' : 'stop',
    } ],
    $usage ? ( usage => $usage ) : (),
  };
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Virtual - Rule-driven engine that answers without network, key or model

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    use Langertha::Engine::Virtual;
    use Langertha::Virtual::Rules qw( answer tool after );

    my $engine = Langertha::Engine::Virtual->new(
      rules => [
        'Hello'               => answer('Hi there!'),
        qr/\AAdd (\d+) and (\d+)\z/ => sub {
          my ( $request, $first, $second ) = @_;
          return tool( add => { a => $first, b => $second } );
        },
        after('add')          => sub {
          my ( $request ) = @_;
          return answer( 'The sum is '.$request->{tool_results}[0]{content} );
        },
      ],
      fallback => answer('I only know a few prompts.'),
    );

    print $engine->simple_chat('Hello');            # Hi there!

    # The MCP tool loop runs as with any engine
    my $tooled = Langertha::Engine::Virtual->new(
      rules       => $engine->rules,
      fallback    => $engine->fallback,
      mcp_servers => [ $mcp ],
    );
    my $text = await $tooled->chat_with_tools_f('Add 7 and 15');   # The sum is 22

    # One reply per request, in order
    my $scripted = Langertha::Engine::Virtual->new(
      script => [ tool( read_file => { path => 'a.txt' } ), answer('Done.') ],
    );

    # Ready-made rule sets
    my $echo  = Langertha::Engine::Virtual->preset('echo');
    my $files = Langertha::Engine::Virtual->preset( files => mcp_servers => [ $mcp ] );

    # Rules from a YAML file
    my $from_file = Langertha::Engine::Virtual->new( rules_file => 't/data/rules.yml' );

    # Token usage, and streaming in pieces of four characters
    my $counted = Langertha::Engine::Virtual->new(
      rules => [ 'Hello' => answer( 'Hi there!', usage => { prompt_tokens => 3, completion_tokens => 2 } ) ],
      stream_chunk_size => 4,
    );
    $counted->simple_chat('Hello')->usage->total_tokens;   # 5
    my ( $content, $chunks ) = await $counted->chat_stream_realtime_f(
      messages       => [ { role => 'user', content => 'Hello' } ],
      chunk_callback => sub { print $_[0]->content },        # Hi t, here, !
    );
    $counted->aggregate_usage($chunks)->{total_tokens};      # 5, from the last chunk

    # What happened
    $engine->requests;   # every request the engine answered, as seen by the rules
    $engine->calls;      # every tool call it emitted: [ $name, \%arguments ]
    $engine->results;    # every tool result the tool loop handed back

=head1 DESCRIPTION

An engine that needs no network, no API key and no model: it answers each
request by L</RULES> you give it (or by a L</script>), so a test, a demo or a
manual run gets exactly the replies it asks for. Everything above the
transport is the real thing: requests are built by
L<Langertha::Role::OpenAICompatible>, replies are parsed into
L<Langertha::Response> by the same code that reads OpenAI, and
L<Langertha::Role::Tools/chat_with_tools_f> (or another tool loop, such as
langertha-raider's) runs the tools of its L<Langertha::Role::Tools/mcp_servers>
for real. Only the HTTP round trip is replaced: the request never leaves the
process; the engine reads it, picks a reaction and answers it as an OpenAI
chat completion. That holds for the chat traffic only: if
C<LANGFUSE_PUBLIC_KEY> and C<LANGFUSE_SECRET_KEY> are set in the environment,
an explicit C<langfuse_flush> can still send traces over the network. Pass
C<< langfuse_enabled => 0 >> to keep a test or demo fully offline. Synchronous (C<simple_chat>) and C<_f> calls both work; the
C<_f> calls run synchronously (their futures are already complete), and
L<Langertha::Role::AsyncHTTP/async_loop> is C<undef>. The in-process
transport is the engine's own C<user_agent> (and the C<_async_http> built
over it); passing either to the constructor replaces it.

The engine supports chat, tool calling and streaming (C<chat>,
C<tools_native>, the C<tool_choice_*> flags, C<parallel_tool_use>,
C<response_size>, C<system_prompt>, C<streaming>, C<stream_usage>; see
L</STREAMING>). There is
no embedding, no transcription and no image generation. Request parameters it
has no use for (C<tool_choice>, a C<response_format>, C<max_tokens>, ...) are
accepted and visible in L</requests>, but do not change the reaction. A reply
carries token usage only when a reaction or L</default_usage> gives it (see
L</USAGE>).

L<Langertha::Engine::Mock> is the same engine under the name C<Mock>.

=head1 RULES

C<rules> is a list of C<< TRIGGER => REACTION >> pairs, checked in order for
every request; the first pair whose trigger matches gives the reaction. When
none matches, L</fallback> answers. Without a fallback the request fails
like a request to a server that answers with an error, here
C<< 500 No Reaction >>: C<simple_chat> croaks and the C<_f> calls fail with
C<< <class> request failed: 500 No Reaction - no rule matches and no fallback
is set (request N, last message: ...) >>, so a missing rule is never a silent
answer. A C<sub> reaction that dies, or returns something that is not a
reaction, fails the request the same way with C<500 Reaction Failed> and the
error.

=head2 Triggers

String and C<Regexp> triggers are matched against the text of the B<last
message, if it is a user message>. The text of a message whose content is a
list of parts is its text parts joined with a newline.

=over

=item * a B<string> matches when it is exactly equal to that text - no
trimming, no case folding.

=item * a B<Regexp> matches as C<=~> does. Its captures are passed to a
C<sub> reaction after the request.

=item * a B<sub> is a predicate: it is called with the request (see L</The
request>) and matches when it returns true. It is checked for every request,
whatever the last message is.

=item * an L<after|Langertha::Virtual::Rules/after> trigger matches when the
last message is a tool result: C<after('read_file')> for a C<read_file>
result, C<after()> for any tool, C<< after( tool => qr/.../, result => qr/.../ ) >>
to match the tool name and the result text. With several results at the end
of the conversation (parallel calls) the first one that matches counts.
Captures of its C<Regexp>s are passed to a C<sub> reaction, the tool name's
first.

=back

So a string or C<Regexp> rule fires on the user's prompt but not again when
the tool loop comes back with the result of the call it asked for; that turn
is answered by an C<after> rule, a predicate or the fallback.

=head2 Reactions

=over

=item * C<< answer($text) >> (C<< { answer => $text } >>): reply with this text.

=item * C<< tool( $name => \%arguments ) >>
(C<< { tool_calls => [ [ $name, \%arguments ] ] } >>): call this tool.

=item * C<< tools( [ [ $name => \%arguments ], ... ] ) >>: call several tools
in one turn.

=item * C<< error( $status, $message ) >> (C<< { error => { status => 429, message => '...' } } >>):
fail the request like a server that answers with this HTTP status (400 to
599) and message, so the caller's error path runs: C<simple_chat> croaks and
the C<_f> calls fail with C<< <class> request failed: 429 Too Many Requests -
... >>. It cannot be combined with an answer or tool calls. A C<sub> may
return it. Served over HTTP by L<Langertha::Virtual::Server> it is the
response with that status and an OpenAI-style error body.

=item * a plain string: the same as C<answer> of it.

=item * a HashRef with C<answer> (or its alias C<text>) and C<tool_calls>
together: a reply that carries text and calls.

=item * any of these HashRefs (not C<error>) with C<usage>, a HashRef: the
reply's token usage (see L</USAGE>). The helpers take it as an option:
C<< answer( $text, usage => \%usage ) >>, C<< tool( $name => \%arguments, usage => \%usage ) >>,
C<< tools( \@calls, usage => \%usage ) >>.

=item * a B<sub>: called with the request and the captures of the trigger,
C<< $sub->( $request, @captures ) >>; it returns one of the above (not
another sub).

=back

The helpers live in L<Langertha::Virtual::Rules>. Rules and reactions are
checked when the engine is built: a malformed one croaks there, not on the
first request. Every emitted tool call gets a unique id
(C<call_virtual_1>, C<call_virtual_2>, ...) and the reply's C<finish_reason>
is C<tool_calls>; a reply without calls finishes with C<stop>.

=head2 The request

Sub triggers and sub reactions get the request as a HashRef:

=over

=item * C<text> - the text of the last message when it is a user message, else C<undef>

=item * C<last_user_text> - the text of the most recent user message anywhere in the conversation

=item * C<tool_results> - the tool results at the end of the conversation, in order, each C<< { id, name, content } >> (C<content> is the result's text, C<name> the tool name of the call it answers)

=item * C<messages> - the conversation as sent (OpenAI chat format)

=item * C<tools> - the tool definitions sent with the request (OpenAI format), or C<[]>

=item * C<model> - the model the request named

=item * C<number> - the request's number, from 1

=item * C<body> - the whole decoded request body

=back

=head2 Script mode

With C<script> instead of C<rules>, the engine answers the first request with
the first reaction, the second with the second, and so on, whatever they
contain. Entries are reactions as above; a sub entry gets the request. When
the script runs out, L</fallback> answers, or the request fails with
C<500 No Reaction> (C<the script has run out ...>). C<script> and C<rules>
cannot be combined.

=head2 Rules files

L</rules_file> loads the rules from YAML, which cannot hold subs or
C<Regexp>s:

    rules:                     # trigger text => reaction, matched exactly
      Write a note.:
        tool_calls:
          - [ write_file, { path: notes/a.txt, content: "hello\n" } ]
      Hello: { answer: Hi there! }
    after:                     # tool name => reaction
      write_file: { answer: Fertig. }
    fallback: { answer: done }

or, for script mode, C<script:> with a list of reactions:

    script:
      - tool_calls:
          - [ read_file, { path: app.txt } ]
      - text: Done.

A reaction is C<< { answer: ... } >> (or C<< { text: ... } >>),
C<< { tool_calls: [ [ name, { arguments } ], ... ] } >> or both, each
optionally with C<< usage: { prompt_tokens: ..., completion_tokens: ... } >>,
or a plain string. The keys C<rules>, C<after>, C<fallback> and C<script> are the only
ones allowed; anything else croaks. C<after> rules come after the C<rules>
ones. A key the file sets cannot also be passed to the constructor.

The keys of C<rules> and C<after> are read by YAML before they are texts: a
trigger that YAML takes for a boolean, null or number (C<true>, C<null>, C<~>,
C<1.0>, C<0x10>) must be quoted, else the rule never matches the prompt. The
entries of each map are taken in alphabetical order of their keys, not file
order, so C<after> rules too: when several match one tool result, the first in
that order wins.

=head1 USAGE

By default a reply carries no C<usage> block, so
L<Langertha::Response/has_usage> is false, as with a server that reports none.
A reaction's C<usage> gives the reply one; without it, L</default_usage> does,
when set. The block is OpenAI's wire usage (C<prompt_tokens>,
C<completion_tokens>, C<total_tokens>, and any further keys such as
C<prompt_tokens_details>, passed on unchanged); C<total_tokens> is added as
the sum of the other two when it is missing and both are given. It arrives
where a provider's would: on the chat completion, read by the OpenAI-dialect
parser into L<Langertha::Response/usage> (a L<Langertha::Usage>), and on a
stream only when the request asks for it with
C<< stream_options => { include_usage => 1 } >>, as a last chunk with an
empty C<choices> list (see L</STREAMING>). The engine's own stream request
asks for it (it claims C<stream_usage>, see L<Langertha::Role::StreamUsage>);
pass C<< stream_options => { include_usage => 0 } >> to leave it out. L<Langertha::Virtual::Server>
serves the same block over HTTP.

    my $engine = Langertha::Engine::Virtual->new(
      rules => [ 'Hello' => answer( 'Hi', usage => { prompt_tokens => 3, completion_tokens => 1 } ) ],
    );
    $engine->simple_chat('Hello')->usage->total_tokens;   # 4

=head1 STREAMING

The engine streams like an OpenAI-dialect server: a request built by
C<chat_stream_request> (L<Langertha::Role::Chat/chat_stream_realtime_f>,
C<simple_chat_stream>, C<simple_chat_stream_iterator>, ...) is answered with
C<text/event-stream> C<chat.completion.chunk> events, parsed by the same
C<parse_stream_chunk> that reads OpenAI. The reaction is chosen as for any
request, then cut into events (L</virtual_stream_chunks>): the text in pieces
of L</stream_chunk_size> characters, each tool call as an opening fragment
(C<index>, C<id>, C<type>, C<function.name>, empty C<arguments>) followed by
its arguments in pieces of the same size, then an event with the
C<finish_reason>, and with C<include_usage> the usage event. The stream gives
the same text and the same L<Langertha::ToolCall>s as the non-streaming reply.
An C<error> reaction, or a request no rule answers, fails the stream like an
error status from a server.

The in-process transport hands the whole event stream over at once: the chunk
callback runs once per event, but all of them after the reply is complete, so
time to first token is not meaningful here.

=head1 PRESETS

L</preset> builds an engine with a ready-made rule set. These are the
prompts that trigger them, exactly as written:

=head2 echo

Answers every request with the text of the most recent user message,
unchanged. Every prompt triggers it.

=head2 files

Drives the file tools of an MCP server such as langertha-raider's stock
C<files> and C<bash> tools (C<read_file>, C<write_file>, C<bash>). C<PATH>
is one word without spaces; C<CONTENT> and C<COMMAND> run to the end of the
prompt, newlines included. The words around them must match exactly:

=over

=item * C<Read the file PATH> - calls C<read_file> with C<< { path => PATH } >>

=item * C<Write the file PATH: CONTENT> - calls C<write_file> with
C<< { path => PATH, content => CONTENT } >>

=item * C<Run the command COMMAND> - calls C<bash> with C<< { command => COMMAND } >>

=back

After any tool result it answers with the result's text (several results
joined with a newline). Any other prompt is answered with a short list of
these prompts.

=head1 ATTRIBUTES AND METHODS

Besides the chat and tool-calling API every engine has
(L<Langertha::Role::Chat>, L<Langertha::Role::Tools>), the engine has the
following. L</requests>, L</calls> and L</results> keep what the engine saw
and did, in order, for a test to check; they are for reading.

=head2 url

The URL the requests are addressed to. Defaults to
C<http://virtual.invalid/v1>; nothing is ever sent there (the C<.invalid>
top-level domain cannot resolve).

=head2 default_model

C<virtual>. Any C<model> may be passed; it is sent in the request and comes
back as L<Langertha::Response/model>.

=head2 api_key_env

C<undef>: the engine reads no API key.

=head2 rules

    rules => [ 'Hello' => answer('Hi'), qr/\ABye/ => 'Bye!', after('ls') => answer('ok') ]

The rules, as C<< TRIGGER => REACTION >> pairs (see L</RULES>). Defaults to
C<[]>.

=head2 fallback

    fallback => answer('I do not know.')

The reaction for a request no rule matches, or that comes after the end of
the L</script>. Without one, such a request fails with C<500 No Reaction>.

=head2 script

    script => [ tool( ls => {} ), answer('Done.') ]

Script mode (see L</Script mode>): one reaction per request, in order. Cannot
be combined with L</rules>.

=head2 rules_file

    rules_file => 't/data/virtual_rules.yml'

A YAML file with C<rules>, C<after>, C<fallback> and/or C<script> (see
L</Rules files>), read when the engine is built.

=head2 default_usage

    default_usage => { prompt_tokens => 10, completion_tokens => 5 }
    default_usage => sub {
      my ( $request, $reaction ) = @_;
      return { prompt_tokens => length $request->{last_user_text},
               completion_tokens => length( $reaction->{answer} // '' ) };
    }

The usage of every reply whose reaction gives none (see L</USAGE>): a HashRef,
or a sub called with the request (see L</The request>) and the reaction as
data (C<< { answer => $text_or_undef, tool_calls => [ [ $name, \%arguments ], ... ] } >>)
that returns the usage HashRef, or C<undef> for none. A sub that dies or
returns anything else fails the request with C<500 Reaction Failed>. Not set
by default: replies then carry no usage.

=head2 stream_chunk_size

    stream_chunk_size => 1   # one character per event

The number of characters per event when a reply is streamed (see
L</STREAMING>), for the text and for each tool call's arguments. Default
C<8>; at least C<1>.

=head2 requests

Every chat request the engine received, in order, including the ones that
failed (no rule matched, a reaction died), as the HashRef the rules saw (see
L</The request>).

=head2 calls

Every tool call the engine emitted, in order, as C<[ $name, \%arguments ]>.

=head2 results

Every tool result a tool loop handed back through
L<Langertha::Role::Tools/format_tool_results>, in order, as the loop passed
it: C<< { tool_call => ..., result => \%mcp_result } >>, where C<result> is
the MCP C<call_tool> result (C<content>, C<isError>, ...).

=head2 preset

    my $engine = Langertha::Engine::Virtual->preset('echo');
    my $engine = Langertha::Engine::Virtual->preset( files => mcp_servers => [ $mcp ] );

Class method. Builds an engine with the named rule set (see L</PRESETS>);
further arguments go to the constructor and replace the preset's own
C<rules> or C<fallback> when they name them. Combined with C<rules_file>,
C<preset> croaks, because the preset's C<rules> and the file's collide. Croaks
on an unknown name.

=head2 list_models

    my $ids = $engine->list_models;   # [ 'virtual' ]

The configured L<Langertha::Role::Models/model>, without a request.

=head2 virtual_reply

    my $reply = $engine->virtual_reply( POST => '/v1/chat/completions', $json_text );
    # { code => 200, message => 'OK', content => \%completion }

The engine's answer to one HTTP request, as data: the status C<code> and
C<message>, and the C<content>, which is the chat completion (a HashRef) on
success and an error text otherwise. The in-process transport and
L<Langertha::Virtual::Server> both answer through it; it records the request
like any other. A path other than C<.../chat/completions> or a method other
than C<POST> is a C<404>. The body must be the JSON of a chat request. The
completion is the same for a request with C<< "stream": true >>; the
transports cut it into events with L</virtual_stream_chunks>. It carries
C<usage> when the reaction or L</default_usage> gives one (see L</USAGE>).

=head2 virtual_stream_chunks

    my $chunks = $engine->virtual_stream_chunks( $completion, include_usage => 1 );

Cuts a chat completion (the C<content> of a successful L</virtual_reply>) into
the C<chat.completion.chunk> events an OpenAI server streams, as an ArrayRef
of HashRefs, without the closing C<[DONE]>: the text in pieces of
L</stream_chunk_size> characters (the first event carries
C<< role => 'assistant' >>), each tool call as an opening fragment with
C<index>, C<id>, C<type>, its C<function.name> and empty C<arguments>, then
its arguments in pieces, then an event with an empty C<delta> and the
C<finish_reason>. With C<include_usage> and a completion that carries
C<usage>, a last event with an empty C<choices> list carries it, as
C<< stream_options => { include_usage => 1 } >> asks of OpenAI. The
in-process transport and L<Langertha::Virtual::Server> both stream through
it.

=head1 SEE ALSO

=over

=item * L<Langertha::Virtual::Rules> - C<answer>, C<tool>, C<tools> and C<after>

=item * L<Langertha::Engine::Mock> - The same engine under the name C<Mock>

=item * L<Langertha::Role::Tools> - The MCP tool loop the engine runs in

=item * L<Langertha::Role::OpenAICompatible> - The request builder and parser it reuses

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
