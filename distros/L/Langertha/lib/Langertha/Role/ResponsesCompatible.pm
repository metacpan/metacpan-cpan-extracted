package Langertha::Role::ResponsesCompatible;
# ABSTRACT: Role for the Open-Responses wire envelope (input/instructions/output[])
our $VERSION = '0.503';
use Moose::Role;
use Carp qw( croak carp );
use JSON::MaybeXS;
use Langertha::Tool;
use Langertha::ToolCall;
use Langertha::ToolChoice;
use Langertha::Response;
use Langertha::ServerTool;
use Langertha::ServerToolCall;
use Langertha::Usage;
use Scalar::Util qw( blessed );


# The Responses envelope carries flat tools and nested reasoning:{effort}.
# These override the openai defaults inherited from Role::Tools /
# Role::ReasoningEffort; on a lean consumer (parent = Remote) they are supplied
# with -excludes on those roles (ADR 0015), the same way AnthropicBase wires
# Role::AnthropicCompatible.
sub _build_tool_wire_format { 'responses' }
sub _build_reasoning_wire_format { 'responses' }

# Content parts in input[] are typed input_text / input_image (output_text on an
# assistant turn); the chat-style text / image_url parts are a 400 (karr k267).
# Role::Chat::content_format defaults to 'openai'; a consumer composing both in
# one `with` excludes it from Role::Chat (Perplexity).
sub content_format { 'responses' }

# Default endpoint is the OpenAI Responses operation; Perplexity's Agent engine
# overrides _responses_dispatch to POST /v1/agent directly.
sub chat_operation_id { 'createResponse' }

# OpenAI reasoning models 400 on a non-default temperature whenever reasoning is
# active -- only the wire default (1) is accepted (karr k155). Identical gate to
# Role::OpenAICompatible::_temperature_kwargs, on the Responses wire: the
# supports('temperature') check + control-beats-attribute resolution mirror
# AnthropicCompatible::_temperature_kwargs, and the EFFORT-AWARE drop delegates to
# the per-model, resolved-effort predicate on the engine
# (Engine::OpenAI::_temperature_rejected_by_reasoning, inherited by
# OpenAIResponses via the 'responses' reasoning wire). Perplexity, the other
# Responses consumer, never defines that predicate, so the can() guard leaves its
# temperature untouched. temperature=1 passes through silently.
#
# A model that does not take temperature at all (supports('temperature') false)
# never gets the field, not even 1; a caller-set non-default value is dropped
# with the same carp as the OpenAI and Anthropic wire roles, 1 quietly (ADR 0025
# k214 Update; parity since karr k220).
sub _temperature_kwargs {
    my ( $self, $controls ) = @_;
    my $temp = exists $controls->{temperature} ? $controls->{temperature}
             : $self->has_temperature          ? $self->temperature
             :                                    undef;
    return () unless defined $temp;
    # An engine attribute is the same on every request: warn once per engine
    # instance (karr k247); a per-request control warns every time.
    my $once = exists $controls->{temperature} ? undef
      : 'temperature=' . $temp . ' model=' . ( $self->can('chat_model') ? $self->chat_model // '' : '' );
    unless ( $self->supports('temperature') ) {
        $self->_langertha_carp( "".( ref $self ).": dropping temperature=$temp -- model '"
          . ( $self->chat_model // '' )
          . "' does not take a temperature (rejected or fixed server-side); "
          . "unset temperature to silence this",
          defined $once ? "$once unsupported" : undef )
          if $temp != 1;
        return ();
    }
    if ( $temp != 1
      && $self->can('_temperature_rejected_by_reasoning')
      && $self->_temperature_rejected_by_reasoning($controls) ) {
        $self->_langertha_carp( "".( ref $self ).": dropping temperature=$temp -- this reasoning "
          . "model rejects a non-default temperature while reasoning is active "
          . "(only the wire default 1 is accepted); pass reasoning_effort => "
          . "'none' to keep it",
          defined $once ? "$once reasoning" : undef );
        return ();
    }
    return ( temperature => $temp );
}

# True for an item the Responses wire takes as-is (spec k206 section 3.4,
# karr k210, ADR 0001): a flat {type=>'function', name, ...}, a Responses
# server-side tool, or any other typed item Langertha does not recognise
# (custom, namespace, hosted shell, future server types -- values open, the
# provider judges). Everything else goes to format_tools: a function-tool form
# is formatted there, and a known client-executed built-in (local_shell,
# computer, apply_patch, local shell, client tool_search, ...), another wire's
# built-in, or an untyped nameless hash croaks there.
sub _is_native_responses_tool {
    my ($item) = @_;
    return 0 unless ref $item eq 'HASH' && length( $item->{type} // '' );
    my $category = Langertha::Tool->classify( $item, 'responses' );
    return 1 if $category eq 'server' || $category eq 'unknown';
    return ( $category eq 'function' && $item->{type} eq 'function'
        && ref $item->{function} ne 'HASH' ) ? 1 : 0;
}

# Shapes the `tools` kwarg in place, for both request builders. The engine's
# default server_tools (Role::ServerTools) are appended to the request's own
# tools, then every item is decided on its own, so a mixed list keeps every
# tool in both orders (karr k210):
#   - a server-side tool (a Langertha::ServerTool, or a hash ServerTool
#     recognises for 'responses') goes out as its native hash after the
#     engine's _server_tool_wire_check hook -- only on an engine that
#     supports('server_tools'); a ServerTool object croaks anywhere else
#     (k206, ADR 0030);
#   - a native Responses item goes out verbatim (see _is_native_responses_tool);
#   - every other function-tool form (MCP inputSchema, canonical input_schema,
#     OpenAI chat's nested function, a Langertha::Tool) is formatted to the
#     flat shape, and anything that is neither croaks in Langertha::Tool.
# Guarded by can(): a consumer that composes no Role::Tools has no
# format_tools, and its tools go out as given.
sub _responses_tools_kwarg {
    my ( $self, $extra ) = @_;
    my @server = $self->can('server_tools') ? $self->_responses_default_server_tools($extra->{tools}) : ();
    $extra->{tools} = [ ( ref $extra->{tools} eq 'ARRAY' ? @{ $extra->{tools} } : () ), @server ]
        if @server;
    return unless exists $extra->{tools} && ref $extra->{tools} eq 'ARRAY';
    my $server_ok = $self->supports('server_tools');
    $extra->{tools} = [ map {
        my $item = $_;
        croak "".( ref $self ).": '" . $item->type . "' is a Langertha::ServerTool, "
          . "and this engine does not supports('server_tools')"
            if !$server_ok && blessed $item && $item->isa('Langertha::ServerTool');
        my $st = $server_ok ? Langertha::ServerTool->from_hash( responses => $item ) : undef;
        $st                                ? $self->_responses_server_tool_spec($st)
      : !$self->can('format_tools')        ? $item
      : _is_native_responses_tool($item)   ? $item
      :                                      @{ $self->format_tools([$item]) };
    } @{ $extra->{tools} } ];
    return;
}

# Shapes the `tool_choice` kwarg in place, for both request builders; runs
# after _responses_tools_kwarg, since it may withhold the shaped tools.
# Normalized to the Responses (flat function) format, pinned to the literal
# 'responses' rather than $self->tool_wire_format: the envelope is always
# Responses-shaped (mirrors OpenAICompatible pinning 'openai'). A choice whose
# kind the engine does not support (tool_choice_auto / _any / _none / _named)
# is not sent: Perplexity's Agent API has no tool_choice field at all (karr
# k213). The decision is Role::Chat::_gate_tool_choice, this role's k233 rule
# generalized to every envelope in k239: dropping 'auto' is silent, any other
# drop carps; an unsendable 'none' also withholds every tool of the request --
# function tools, native built-ins and server-tool defaults alike, since they
# are all on the tools list by now -- so the caller's "call no tool" holds
# without the field. A value ToolChoice cannot read (a provider-native choice)
# passes through as given where the wire has a tool_choice field, and is
# dropped with a carp where it has none.
sub _responses_tool_choice_kwarg {
    my ( $self, $extra ) = @_;
    my $tc = $self->_gate_tool_choice($extra) or return;
    $extra->{tool_choice} = $tc->to('responses');
    return;
}

# parallel_tool_use -> parallel_tool_calls, in place, for both request builders
# (the streaming one too, karr k240): only when tools are present, and only
# where the wire has the field (Perplexity's Agent API does not, k213); a value
# the caller set that this drops carps (k241). See
# Role::Chat::_parallel_tool_calls_kwarg.
sub _responses_parallel_tool_calls_kwarg {
    my ( $self, $extra, $controls ) = @_;
    return $self->_parallel_tool_calls_kwarg( $extra, $controls );
}

# The engine's server_tools defaults, as ServerTool objects, minus every one
# the request already carries (k206 review I1/M6). Unlike a request's own
# tools (values open, the provider judges), a default must be a server tool:
# a bare string, a function tool or an unlisted type croaks here instead of
# being dropped by format_tools or sent on every request. The request wins:
# a default is skipped when a request tool is a server tool of the same kind
# -- same type, and for mcp the same server_label.
sub _server_tool_kind {
    my ($st) = @_;
    my $spec = $st->spec;
    return $st->type eq 'mcp' ? 'mcp:' . ( $spec->{server_label} // '' ) : $st->type;
}

sub _responses_default_server_tools {
    my ( $self, $request_tools ) = @_;
    my %requested = map {
        my $st = Langertha::ServerTool->from_hash( responses => $_ );
        $st ? ( _server_tool_kind($st) => 1 ) : ();
    } ( ref $request_tools eq 'ARRAY' ? @$request_tools : () );
    my @defaults;
    for my $entry ( @{ $self->server_tools } ) {
        my $st = Langertha::ServerTool->from_hash( responses => $entry );
        unless ($st) {
            my $label = !ref $entry          ? "'" . ( $entry // 'undef' ) . "'"
                      : ref $entry eq 'HASH' ? '{' . join( ',', map { "$_=" . ( ref $entry->{$_} ? '...' : $entry->{$_} // '' ) } sort keys %$entry ) . '}'
                      :                        ref $entry;
            croak "".( ref $self ).": server_tools entry $label is not a server tool of the "
              . "responses wire; pass a Langertha::ServerTool (unlisted => 1 for a type "
              . "Langertha does not list yet) or a provider-native server tool hash";
        }
        push @defaults, $st unless $requested{ _server_tool_kind($st) };
    }
    return @defaults;
}

sub _responses_server_tool_spec {
    my ( $self, $st ) = @_;
    $st->to('responses');    # croaks for a server tool of another wire
    return $self->_server_tool_wire_check($st);
}

# max_output_tokens only where the wire takes it: a per-request max_tokens
# control beats the engine's response_size. Gated on supports('response_size')
# so an engine or a model whose wire rejects the field (a layer-2/3
# correction, ADR 0002/0019) never sends it (spec k206 section 4, Q2 ruling).
sub _responses_max_tokens_kwargs {
    my ( $self, $controls ) = @_;
    return () unless $self->supports('response_size');
    return ( max_output_tokens => $controls->{max_tokens} ) if exists $controls->{max_tokens};
    return $self->get_response_size ? ( max_output_tokens => $self->get_response_size ) : ();
}

sub chat_request {
    my ( $self, $messages, %extra ) = @_;

    # Canonical per-request controls (chat_f, karr #46) beat the engine
    # attributes on a per-key basis; the rest of %extra passes straight through.
    my $controls = delete $extra{controls} // {};

    $self->_responses_tools_kwarg(\%extra);
    $self->_responses_tool_choice_kwarg(\%extra);
    $self->_responses_parallel_tool_calls_kwarg(\%extra, $controls);

    # Build input array: strip system messages (they go to instructions).
    my @input;
    for my $msg (@$messages) {
        next if ( $msg->{role} // '' ) eq 'system';
        push @input, $self->_normalize_input_item($msg);
    }

    # Structured output. Per-request control beats the engine attribute; the
    # wire slot is chosen by the consumer via _responses_format_kwargs.
    my $response_format =
        exists $controls->{response_format} ? $controls->{response_format}
      : ( $self->can('has_response_format') && $self->has_response_format )
                                            ? $self->response_format
      :                                       undef;

    my @request_args = (
        $self->_responses_model_kwargs,
        $self->has_system_prompt ? ( instructions => $self->system_prompt ) : (),
        scalar(@input) ? ( input => \@input ) : (),
        $self->_responses_max_tokens_kwargs($controls),
        defined $response_format
            ? $self->_responses_format_kwargs($response_format)
            : (),
        $self->_temperature_kwargs($controls),
        exists $controls->{seed} ? ( seed => $controls->{seed} ) : (),
        ( $self->can('reasoning_kwargs_for') ? $self->reasoning_kwargs_for(%$controls) : () ),
        stream => JSON->false,
        %extra,
    );

    return $self->_responses_dispatch(
        sub { $self->chat_response(shift) },
        @request_args,
    );
}


# --- Divergence hooks (OpenAI-Responses defaults) ------------------------

sub _responses_model_kwargs {
    my ( $self ) = @_;
    return defined $self->chat_model ? ( model => $self->chat_model ) : ();
}


sub _responses_format_kwargs {
    my ( $self, $rf ) = @_;
    return ( text => { format => $self->_responses_text_format($rf) } );
}


sub _responses_dispatch {
    my ( $self, $response_call, @request_args ) = @_;
    return $self->generate_request(
        $self->chat_operation_id,
        $response_call,
        @request_args,
    );
}


sub _normalize_input_item {
    my ( $self, $msg ) = @_;
    # Pass through for the OpenAI Responses wire; consumers that require a typed
    # {type:message,...} item (Perplexity) override this.
    return $msg;
}


sub _responses_extra_fields {
    my ( $self, $data ) = @_;
    return ();
}


sub _responses_echo_item {
    my ( $self, $item ) = @_;
    return $item;
}


# Translate an OpenAI Chat-Completions response_format hash into the value the
# Responses API wants under text.format. On the Chat wire the schema is nested
# (`{ type => 'json_schema', json_schema => { name, schema, strict } }`); the
# Responses wire pulls that inner object up one level (flat json_schema). A
# json_object stays a bare type; anything unrecognized (or already flat) passes
# through unchanged so we never mangle a shape we do not model.
sub _responses_text_format {
    my ( $self, $rf ) = @_;
    return $rf unless ref $rf eq 'HASH';
    my $type = $rf->{type} // '';
    if ( $type eq 'json_schema' && ref $rf->{json_schema} eq 'HASH' ) {
        return { %{ $rf->{json_schema} }, type => 'json_schema' };
    }
    if ( $type eq 'json_object' ) {
        return { type => 'json_object' };
    }
    return $rf;
}

# --- Response parsing ----------------------------------------------------

sub chat_response {
    my ( $self, $response ) = @_;
    my $data = $self->parse_response($response);

    # A 200 body with an `error` object and no output (a failed response) is
    # no answer; it parsed to an empty Response. Croak like the k301
    # OpenAI-compatible parser. -- karr k311
    if ( ref $data eq 'HASH' && defined $data->{error}
        && !( ref $data->{output} eq 'ARRAY' && @{ $data->{output} } ) ) {
        croak "".( ref $self )." response carried an error: ".$self->_body_error_text( $data->{error} );
    }

    my %out = $self->_responses_walk_output($data);
    my %extra = $self->_responses_extra_fields($data);
    my $citations = $self->_responses_merge_citations( delete $extra{citations}, $out{citations} );

    # Normalize usage to chat-style keys (Langertha::Usage / Goldmine read
    # prompt_tokens/completion_tokens off the %{} overload), while carrying the
    # Responses-native detail blocks through verbatim: input_tokens_details holds
    # the automatic prompt-cache read/write counts, and Langertha::Usage->from_hash
    # parses them onto cached_tokens / cache_write_tokens the same way it does the
    # chat wire (karr #159). The per-call cost block rides along under usage.cost.
    # The chat-spelled aliases stay so the overload keeps returning
    # prompt_tokens/completion_tokens for existing callers (t/60, t/91).
    my $usage = $data->{usage} // {};
    my $normalized_usage = {
        prompt_tokens     => $usage->{input_tokens},
        completion_tokens => $usage->{output_tokens},
        total_tokens      => $usage->{total_tokens},
        ( ref $usage->{input_tokens_details} eq 'HASH'
            ? ( input_tokens_details => $usage->{input_tokens_details} ) : () ),
        ( ref $usage->{cost} eq 'HASH'
            ? ( cost => $usage->{cost} ) : () ),
    };
    # Read output_tokens_details into a lexical and ref-check before deref: the
    # chained rvalue $usage->{output_tokens_details}{reasoning_tokens} would
    # autovivify output_tokens_details => {} into $data->{usage} (the same ref as
    # raw => $data) when the provider omits the block, polluting the trace. -- k168
    my $otd = $usage->{output_tokens_details};
    if ( ref($otd) eq 'HASH' && $otd->{reasoning_tokens} ) {
        $normalized_usage->{completion_tokens_details}
            = { reasoning_tokens => $otd->{reasoning_tokens} };
    }

    return Langertha::Response->new(
        content       => $out{content},
        raw           => $data,
        $data->{id}      ? ( id => $data->{id} )      : (),
        $data->{model}   ? ( model => $data->{model} ) : (),
        defined $out{finish_reason} ? ( finish_reason => $out{finish_reason} ) : (),
        usage         => $normalized_usage,
        # created_at is the Responses envelope's epoch stamp; Response.BUILDARGS
        # runs it through Langertha::Moment->from_wire (ADR 0017), which drops it
        # if unreadable rather than failing the whole reply.
        defined $data->{created_at} ? ( created => $data->{created_at} ) : (),
        $out{tool_calls} ? ( tool_calls => $out{tool_calls} ) : (),
        $out{server_tool_calls} ? ( server_tool_calls => $out{server_tool_calls} ) : (),
        defined $out{thinking} ? ( thinking => $out{thinking} ) : (),
        defined $out{refusal} ? ( refusal => $out{refusal} ) : (),
        $citations ? ( citations => $citations ) : (),
        %extra,
    );
}


# The one output[] walker (karr k212). chat_response reads a whole response
# with it, and parse_stream_chunk reads the response object that the terminal
# response.completed / response.incomplete event carries, so a streamed and a
# non-streamed reply of the same response can never disagree about its tool
# calls, thinking or finish_reason (karr k222). Returns a hash: content (concatenated
# output_text, '' when none), and -- only when present -- thinking, refusal,
# finish_reason, and tool_calls (ArrayRef of Langertha::ToolCall).
sub _responses_walk_output {
    my ( $self, $data ) = @_;

    my ( $text, @tc_data, $finish_reason, $thinking, @citations, $refusal );

    for my $item ( @{ $data->{output} // [] } ) {
        next unless ref($item) eq 'HASH';
        # A client-actionable item Langertha does not map croaks (k206).
        Langertha::Tool->_croak_on_client_item($item);
        my $type = $item->{type} // '';

        if ( $type eq 'reasoning' ) {
            # Ref-check each level before deref: the chained rvalue
            # $item->{summary}[0]{text} autovivified summary => [{}] into the
            # item (the same ref as raw => $data) when a reasoning item carries
            # no summary -- OpenAI's summary => [], xAI's encrypted-only
            # reasoning with the field omitted. -- k211, the k168 bug class
            my $first = ref $item->{summary} eq 'ARRAY' ? $item->{summary}[0] : undef;
            my $summary = ref $first eq 'HASH' ? ( $first->{text} // '' ) : '';
            $thinking //= $summary if length $summary;
        }
        elsif ( $type eq 'message' ) {
            $finish_reason = ( $item->{status} // '' ) eq 'completed' ? 'stop' : ( $item->{status} // '' );

            for my $block ( @{ $item->{content} // [] } ) {
                my $block_type = $block->{type} // '';
                if ( $block_type eq 'output_text' ) {
                    $text .= ( $block->{text} // '' );
                    push @citations, _url_citations( $block->{annotations} );
                }
                elsif ( $block_type eq 'function_call' ) {
                    push @tc_data, $block;
                }
                elsif ( $block_type eq 'refusal' ) {
                    # A declined request answers a refusal part instead of
                    # output_text (ADR 0004: Response.refusal). -- k301
                    $refusal .= $block->{refusal}
                        if defined $block->{refusal} && !ref $block->{refusal};
                }
            }
        }
        elsif ( $type eq 'function_call' ) {
            # Real Responses API emits function_call as a top-level output[]
            # item carrying name/arguments/call_id directly on the item.
            push @tc_data, $item;
        }
    }

    # A response that carries tool calls reports finish_reason 'tool_calls',
    # matching the OpenAI Chat-Completions convention -- regardless of where the
    # calls sit in output[] (a top-level function_call, or one nested in a
    # message) and regardless of a coexisting assistant text message. A completed
    # message sets finish_reason 'stop' in the loop above; a tool call present
    # alongside it must win, so resolve it here rather than let output[] ordering
    # decide (a message preamble may precede or follow the call). A genuinely
    # non-completed message status (e.g. truncation) is left intact. -- k171
    #
    # A reply that hit max_output_tokens before any message item says so only
    # on the envelope: status incomplete, incomplete_details.reason
    # max_output_tokens (max_tokens in the reference's response.incomplete
    # example; both are read). With no message item to carry a status --
    # nothing but function calls in output[], or an empty output[] because
    # reasoning consumed the whole budget -- that is finish_reason 'length'. The
    # tool loops then treat a call whose arguments were cut off as truncated,
    # and chat_f reports the token-limit cut on a reply with no content -- karr
    # k349, k350, k345. A truncated *message* keeps its own status (set above).
    if ( !defined $finish_reason && _cut_by_token_limit($data) ) {
        $finish_reason = 'length';
    }
    if ( @tc_data && ( !defined $finish_reason || $finish_reason eq 'stop' ) ) {
        $finish_reason = 'tool_calls';
    }

    my @server_calls = Langertha::ServerToolCall->extract( responses => $data );

    return (
        content => $text // '',
        defined $thinking      ? ( thinking      => $thinking )      : (),
        defined $refusal       ? ( refusal       => $refusal )       : (),
        defined $finish_reason ? ( finish_reason => $finish_reason ) : (),
        @tc_data ? ( tool_calls => [ grep { defined } map { $self->_parse_function_call($_) } @tc_data ] ) : (),
        @server_calls ? ( server_tool_calls => \@server_calls ) : (),
        @citations ? ( citations => \@citations ) : (),
    );
}

# True when a Responses envelope reports it stopped on its output token limit.
sub _cut_by_token_limit {
    my ($data) = @_;
    return 0 unless ref $data eq 'HASH' && ( $data->{status} // '' ) eq 'incomplete';
    my $details = $data->{incomplete_details};
    my $reason  = ref $details eq 'HASH' ? ( $details->{reason} // '' ) : '';
    return $reason eq 'max_output_tokens' || $reason eq 'max_tokens';
}

# The url_citation annotations of one output_text block, normalized to
# { url, title?, start_index?, end_index? } (spec k206 section 3.6); other
# annotation types (file_citation, ...) are left on raw. The url is kept
# verbatim -- OpenAI appends ?utm_source=openai -- and only the dedup key in
# _responses_merge_citations ignores it.
sub _url_citations {
    my ($annotations) = @_;
    return () unless ref $annotations eq 'ARRAY';
    my @out;
    for my $ann (@$annotations) {
        next unless ref $ann eq 'HASH' && ( $ann->{type} // '' ) eq 'url_citation';
        next unless defined $ann->{url} && !ref $ann->{url} && length $ann->{url};
        push @out, { map { defined $ann->{$_} && !ref $ann->{$_} ? ( $_ => $ann->{$_} ) : () }
            qw( url title start_index end_index ) };
    }
    return @out;
}

# The dedup key of a citation url: the url without utm_* query parameters.
# OpenAI's url_citation carries ?utm_source=openai while its search sources
# list the same page with and without it, so the tracking parameter must not
# make one page two citations. Every other query parameter still counts --
# ?page=2 is another page. The stored url is never rewritten.
sub _citation_key {
    my ($url) = @_;
    my ( $base, $query, $fragment ) = $url =~ /\A([^?#]*)(?:\?([^#]*))?(#.*)?\z/s;
    return $url unless defined $base;
    my @keep = grep { length && !/\Autm_[^=]*(?:=|\z)/i } split /&/, ( $query // '' );
    return $base . ( @keep ? '?' . join( '&', @keep ) : '' ) . ( $fragment // '' );
}

sub _responses_merge_citations {
    my ( $self, $hook, $annotations ) = @_;
    # No annotations: the hook's list goes out exactly as it came, so a
    # consumer whose payload has none (Perplexity) is unchanged.
    return ( ref $hook eq 'ARRAY' && @$hook ? $hook : undef )
        unless ref $annotations eq 'ARRAY' && @$annotations;
    my ( @out, %at );
    for my $entry ( ( ref $hook eq 'ARRAY' ? @$hook : () ), @$annotations ) {
        my $url = ref $entry eq 'HASH' ? $entry->{url} : undef;
        my $key = defined $url && !ref $url ? _citation_key($url) : undef;
        if ( defined $key && exists $at{$key} ) {
            my $seen = $out[ $at{$key} ];
            exists $seen->{$_} or $seen->{$_} = $entry->{$_} for keys %$entry;
            next;
        }
        push @out, ref $entry eq 'HASH' ? { %$entry } : $entry;
        $at{$key} = $#out if defined $key;
    }
    return \@out;
}


# One function_call block through the value-object door: arguments that do not
# decode (a string cut off by max_output_tokens) become {} with
# arguments_undecodable set, where decoding them here died with a raw JSON
# error -- karr k349, the k324 flag. A block without a name is no call.
sub _parse_function_call {
    my ( $self, $block ) = @_;
    return Langertha::ToolCall->from_responses($block);
}

# --- Streaming (typed SSE) -----------------------------------------------

sub stream_format { 'sse' }


sub chat_stream_request {
    my ( $self, $messages, %extra ) = @_;

    my $controls = delete $extra{controls} // {};

    $self->_responses_tools_kwarg(\%extra);
    $self->_responses_tool_choice_kwarg(\%extra);
    $self->_responses_parallel_tool_calls_kwarg(\%extra, $controls);

    my @input;
    for my $msg (@$messages) {
        next if ( $msg->{role} // '' ) eq 'system';
        push @input, $self->_normalize_input_item($msg);
    }

    my $response_format =
        exists $controls->{response_format} ? $controls->{response_format}
      : ( $self->can('has_response_format') && $self->has_response_format )
                                            ? $self->response_format
      :                                       undef;

    my @request_args = (
        $self->_responses_model_kwargs,
        $self->has_system_prompt ? ( instructions => $self->system_prompt ) : (),
        scalar(@input) ? ( input => \@input ) : (),
        $self->_responses_max_tokens_kwargs($controls),
        defined $response_format
            ? $self->_responses_format_kwargs($response_format)
            : (),
        $self->_temperature_kwargs($controls),
        exists $controls->{seed} ? ( seed => $controls->{seed} ) : (),
        ( $self->can('reasoning_kwargs_for') ? $self->reasoning_kwargs_for(%$controls) : () ),
        stream => JSON->true,
        %extra,
    );

    return $self->_responses_dispatch( sub {}, @request_args );
}


sub parse_stream_chunk {
    my ( $self, $data, $event ) = @_;

    require Langertha::Stream::Chunk;

    # The Responses/Agent stream is typed: each data payload carries a `type`
    # naming the event (the `event:` SSE line, when present, mirrors it). Text
    # arrives as response.output_text.delta with the increment in `delta`; the
    # terminal response.completed carries usage. `data: [DONE]` is consumed by
    # Role::Streaming before this is called.
    #
    # Live-confirmed against Perplexity's Agent stream (k147): the frame sequence
    # is response.created -> response.in_progress -> response.output_item.added
    # -> response.output_text.delta (text in `delta`) -> response.output_text.done
    # -> response.output_item.done -> response.completed. Usage rides on
    # response.completed under response.usage (no separate trailing frame), and
    # the resolved model is under response.model there too -- the earlier frames
    # may carry the preset label (e.g. "medium") instead, which is why model is
    # read from response.completed and not response.created.
    my $type = ref($data) eq 'HASH' ? ( $data->{type} // ( $event // '' ) ) : '';

    if ( $type eq 'response.output_text.delta' ) {
        return Langertha::Stream::Chunk->new(
            content  => ( $data->{delta} // '' ),
            raw      => $data,
            is_final => 0,
        );
    }

    # A failed run ends the stream with response.failed (the error under
    # response.error) instead of response.completed; a transport-level problem
    # arrives as a top-level `error` event (code/message on the event itself).
    # Both are terminal and carry no reply, so fail the stream loudly with the
    # provider's own message -- the LMStudio parser's pattern: the croak fails
    # the request future in chat_stream_realtime_f on every backend (ADR 0027),
    # where returning undef would end the stream as an empty, silent success.
    # -- karr k212
    if ( $type eq 'response.failed' || $type eq 'error' ) {
        my $err = $type eq 'error' ? $data : ( ref $data->{response} eq 'HASH' ? $data->{response}{error} : undef );
        $err = $err->{error} if ref $err eq 'HASH' && ref $err->{error} eq 'HASH';
        my $message = ref $err eq 'HASH' && defined $err->{message} ? $err->{message}
                    : "$type without an error message";
        my $code = ref $err eq 'HASH' && defined $err->{code} && !ref $err->{code} ? " ($err->{code})" : '';
        croak "".( ref $self )." stream failed$code: $message";
    }

    if ( $type eq 'response.completed' || $type eq 'response.incomplete' ) {
        my $resp  = $data->{response} // {};
        my $usage = $resp->{usage};
        # The terminal event carries the whole response object, so its output[]
        # goes through the same walker chat_response uses: the function calls
        # land on this final chunk as finished Langertha::ToolCall objects, where
        # aggregate_tool_calls collects them (karr k212). The incremental
        # function-call events (output_item.added/.done, function_call_arguments
        # .delta/.done) are deliberately not assembled -- the terminal output[]
        # is complete and authoritative, and reading only it means a call can
        # never arrive twice. Text is not taken from it: that already streamed as
        # output_text.delta. Thinking is, because no reasoning delta event is
        # read (drop it here if one ever is). finish_reason is the walker's, as
        # on chat_response: tool_calls, stop for a completed message, or the
        # message status (incomplete) -- on text-only streams too (karr k222).
        my %out = $self->_responses_walk_output($resp);
        # A search-augmented reply carries its sources as a search_results item
        # in the terminal response.output[] array — the same block
        # _responses_extra_fields lifts on the non-streaming path. Reuse that
        # divergence hook (the base envelope returns none) so a streamed reply
        # surfaces citations too, on the final chunk (karr #158).
        my %extra = $self->_responses_extra_fields($resp);
        my $citations = $self->_responses_merge_citations( $extra{citations}, $out{citations} );
        # Surface the prefix-cache read count and (Perplexity) cost off the
        # terminal usage, symmetric to the non-streaming chat_response (k159).
        # cached_tokens is parsed by Langertha::Usage->from_hash -- the same value
        # object and spelling precedence the non-streaming path relies on, so both
        # paths read every Agent/Responses cache spelling identically (from_hash
        # reads into lexicals, so a missing block never autovivifies into
        # raw => $data). The dedicated Stream::Chunk cached_tokens Int carries the
        # read count; the input_tokens_details and cost blocks ride verbatim in
        # the usage hash (cost has no Chunk attribute), mirroring the non-streaming
        # normalized usage. -- k160
        my $cached = ref($usage) eq 'HASH'
            ? Langertha::Usage->from_hash($usage)->cached_tokens : undef;
        return Langertha::Stream::Chunk->new(
            content  => '',
            raw      => $data,
            is_final => 1,
            $resp->{model} ? ( model => $resp->{model} ) : (),
            $usage ? ( usage => {
                prompt_tokens     => $usage->{input_tokens},
                completion_tokens => $usage->{output_tokens},
                total_tokens      => $usage->{total_tokens},
                ( ref $usage->{input_tokens_details} eq 'HASH'
                    ? ( input_tokens_details => $usage->{input_tokens_details} ) : () ),
                ( ref $usage->{cost} eq 'HASH'
                    ? ( cost => $usage->{cost} ) : () ),
            } ) : (),
            defined $cached ? ( cached_tokens => $cached ) : (),
            $citations ? ( citations => $citations ) : (),
            $out{tool_calls} ? ( tool_calls => $out{tool_calls} ) : (),
            defined $out{finish_reason} ? ( finish_reason => $out{finish_reason} ) : (),
            defined $out{thinking} ? ( thinking => $out{thinking} ) : (),
            defined $out{refusal} ? ( refusal => $out{refusal} ) : (),
        );
    }

    # Every other typed event (response.created, response.output_item.added,
    # reasoning / search deltas, ...) carries no assistant text -> skip.
    return undef;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ResponsesCompatible - Role for the Open-Responses wire envelope (input/instructions/output[])

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Not used directly - composed by engines speaking the Responses envelope.

    package My::Engine;
    use Moose;

    extends 'Langertha::Engine::Remote';

    with map { 'Langertha::Role::'.$_ } qw(
        Models Temperature ReasoningEffort ResponseSize SystemPrompt
        ResponseFormat Streaming Chat ResponsesCompatible
    );

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

The Open-Responses wire envelope, parallel to
L<Langertha::Role::OpenAICompatible> and L<Langertha::Role::AnthropicCompatible>.
This is the request/response/stream shape that OpenAI's C</v1/responses> API and
Perplexity's C</v1/agent> Agent API share:

=over 4

=item * C<input> instead of C<messages> (typed items, system messages lifted out)

=item * C<instructions> for the system prompt (top-level, not in C<input>)

=item * C<output[]> array discriminated by C<type> (C<message>, C<reasoning>,
C<function_call>) instead of C<choices[]>

=item * C<input_tokens>/C<output_tokens> instead of
C<prompt_tokens>/C<completion_tokens>

=item * flat tool objects C<{ type, name, description, parameters }> and the
C<responses> C<tool_wire_format> / C<reasoning_wire_format>

=back

The role owns the body builder, the C<output[]> response walker, the usage
normalization, and the typed-SSE stream parser. It does B<not> own
authentication (each consumer supplies its own C<api_key> / C<update_request>,
so this role never clobbers an inherited key builder) nor the capability
corrections (an engine that opts out of streaming, or narrows the
C<response_format> enum, does so on itself).

=head2 Divergence hooks

Two consumers speak this envelope from different parents and diverge on a
handful of slots; each is an overridable method with the OpenAI-Responses
default baked in:

=over 4

=item * L</_responses_model_kwargs> - C<model> vs C<preset> (or C<models>)
selection.

=item * L</_responses_format_kwargs> - structured output slot: OpenAI's
C<text.format> (flat json_schema) vs the Chat-Completions-shaped top-level
C<response_format>.

=item * L</_responses_dispatch> - how the built body reaches the wire: an
OpenAPI operation (C<createResponse> -> C</v1/responses>) vs a direct
C<POST> to a provider path.

=item * L</_normalize_input_item> - per-item shaping of the C<input> array.

=item * L</_responses_extra_fields> - extra L<Langertha::Response> constructor
args pulled from the raw payload (e.g. Perplexity citations).

=item * L</_responses_echo_item> - which of the reply's C<output[]> items the
tool loop echoes back as input, and in which shape (Perplexity keeps only what
its Agent input schema accepts).

=back

=head2 chat_request

    my $request = $engine->chat_request($messages, %extra);

Builds an Open-Responses request body (C<input> / C<instructions> / model or
preset / optional structured-output slot / C<reasoning> / C<max_output_tokens>
/ C<temperature>) and hands it to L</_responses_dispatch>. Returns an HTTP
request object.

=head2 _responses_model_kwargs

Returns the model-selection kwargs for the body. Default emits
C<< model => chat_model >>. Overridden by consumers that select a C<preset>
or C<models[]> instead (Perplexity maps its user-facing model ids to presets).

=head2 _responses_format_kwargs

Returns the structured-output kwargs for the body from a Chat-Completions-shaped
C<response_format> hash. Default is OpenAI's C<< text => { format => ... } >>
(flat json_schema, see L</_responses_text_format>). Overridden by consumers
whose wire keeps the top-level Chat-Completions C<response_format> shape
(Perplexity).

=head2 _responses_dispatch

Turns the built body into an HTTP request. Default resolves the endpoint from
the OpenAPI spec via L</chat_operation_id> (C<createResponse> ->
C</v1/responses>). Overridden by consumers on a non-OpenAPI parent to
C<POST> a fixed provider path directly (Perplexity -> C</v1/agent>).

=head2 _normalize_input_item

Shapes one C<input> array item from a normalized chat message. Default passes
the C<{ role, content }> hash through unchanged. Overridden by consumers that
require an explicit item C<type>.

=head2 _responses_extra_fields

Returns extra L<Langertha::Response> constructor args pulled from the raw
response payload. Default empty. Overridden by consumers that surface
provider-specific fields (Perplexity lifts C<search_results> into
L<Langertha::Response/citations>).

=head2 _responses_echo_item

    my @items = $engine->_responses_echo_item($output_item);

Shapes one C<output[]> item of the previous reply for the tool-loop echo
(L<Langertha::Role::Tools/format_tool_results>, C<responses> wire), after a
function call nested in a message has been hoisted. Returns the item(s) to send
back as input, or an empty list to drop it. Default passes every item through
unchanged: OpenAI's C</v1/responses> takes its own output items as input.
Overridden by consumers whose input schema is narrower: Perplexity keeps
C<function_call> items, turns an assistant message into
C<< { type => 'message', role => 'assistant', content => $text } >>, and drops
every other item (C<search_results>, C<*_results>, C<mcp_*>).

=head2 chat_response

    my $response = $engine->chat_response($http_response);

Walks the C<output[]> array (C<message> / C<reasoning> / top-level
C<function_call>), normalizes usage, maps C<created_at> to
L<Langertha::Response/created>, and returns a L<Langertha::Response>. Extra
provider fields come from L</_responses_extra_fields>.

Server-side call items (C<web_search_call>, C<file_search_call>, C<mcp_call>,
...) land on L<Langertha::Response/server_tool_calls>, never on
L<Langertha::Response/tool_calls>. The C<url_citation> annotations of the
answer are merged with any C<citations> from L</_responses_extra_fields> onto
L<Langertha::Response/citations> (hook entries first, one entry per page; see
L</_responses_merge_citations>). An output item the client must answer and
Langertha cannot (C<mcp_approval_request>, C<computer_call>,
C<custom_tool_call>, C<local_shell_call>, C<apply_patch_call>, a client
C<tool_search_call>) croaks.

C<finish_reason> is C<tool_calls> when the reply carries function calls,
C<stop> for a completed message, and the message status (C<incomplete>) for a
truncated one. A reply with no message item whose envelope reports C<status>
C<incomplete> with C<incomplete_details.reason> C<max_output_tokens> (or
C<max_tokens>) has C<finish_reason> C<length> -- whether it holds only function
calls or an empty C<output> because reasoning consumed the whole budget. A
function call's C<arguments> that do not decode leave it with C<{}> and
L<Langertha::ToolCall/arguments_undecodable> set.

A C<refusal> content part of a message becomes L<Langertha::Response/refusal>
(on a stream, the final chunk's C<refusal>).

A body with an C<error> object and an empty or missing C<output> is not an
answer and croaks
C<"E<lt>engineE<gt> response carried an error: E<lt>messageE<gt> (E<lt>codeE<gt>)">.

=head2 _responses_merge_citations

    my $citations = $engine->_responses_merge_citations( $hook_citations, $annotation_citations );

Merges the C<citations> a consumer's L</_responses_extra_fields> returned with
the C<url_citation> annotations the walker collected. Hook entries come first,
then annotations, in wire order. One page is listed once: the dedup key is the
C<url> without C<utm_*> query parameters (OpenAI's C<?utm_source=openai>), the
first entry wins, and a later duplicate only fills in fields the first one
lacks. The stored C<url> is never rewritten. Without annotations the hook's
list is returned unchanged. Returns C<undef> when there is nothing.

=head2 stream_format

    my $format = $engine->stream_format;

Returns C<'sse'>. The Responses/Agent stream is a typed SSE stream. A consumer
that does not stream (OpenAI's Responses engine) overrides this to C<undef> and
clears the C<streaming> capability.

=head2 chat_stream_request

    my $request = $engine->chat_stream_request($messages, %extra);

Builds a streaming (C<stream => true>) Open-Responses request. Returns an HTTP
request object for streaming execution.

=head2 parse_stream_chunk

    my $chunk = $engine->parse_stream_chunk($data, $event);

Parses one typed-SSE data payload from a Responses/Agent stream. Returns a
L<Langertha::Stream::Chunk> for C<response.output_text.delta> (text) and the
terminal C<response.completed> / C<response.incomplete> (final chunk: usage, the
prefix-cache read count from C<usage.input_tokens_details.cached_tokens> lifted
onto L<Langertha::Stream::Chunk/cached_tokens>, any C<usage.cost> carried
through the usage hash, and — via L</_responses_extra_fields> — any
search-augmented C<citations> lifted from the completed C<output[]>), C<undef>
for every other typed event.

The final chunk's C<output[]> is read by the same walker as L</chat_response>:
the reply's function calls land on it as L<Langertha::Stream::Chunk/tool_calls>
(collect them with L<Langertha::Role::Chat/aggregate_tool_calls>), a reasoning
summary lands on its C<thinking>, and its C<finish_reason> is the one
L</chat_response> reports for the same response: C<tool_calls> when the reply
carries function calls, C<stop> for a completed message, the message status
(C<incomplete>) for a truncated one, and C<length> for a reply of only
function calls that stopped on C<max_output_tokens>. The incremental function-call events are not assembled, so a call
is delivered exactly once. A C<response.failed> or C<error> event croaks with
the provider's error code and message, which fails the stream.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::OpenAIResponses> - OpenAI C</v1/responses> consumer

=item * L<Langertha::Engine::Perplexity> - Perplexity C</v1/agent> Agent API consumer

=item * L<Langertha::Role::OpenAICompatible> - the parallel Chat-Completions envelope

=item * L<Langertha::Role::AnthropicCompatible> - the parallel Anthropic envelope

=item * L<Langertha::ToolCall> - tool-call extraction (C<responses> format)

=item * L<Langertha::Reasoning/to_responses> - C<reasoning:{effort}> serialization

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
