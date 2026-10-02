package Langertha::Engine::Perplexity;
# ABSTRACT: Perplexity Agent API (search-augmented)
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::Remote';

# Lean Agent-API engine (ADR 0016): parent = Remote for auth + HTTP + JSON only,
# NOT OpenAIBase — the Agent API is the Open-Responses envelope, not
# /chat/completions, so composing the OpenAI dialect (and its embeddings /
# whisper / model-list baggage, plus the inherited-but-wrong capability flags
# k138 catalogued) would be dishonest. The envelope lives in
# Role::ResponsesCompatible, composed here exactly as AnthropicBase composes
# Role::AnthropicCompatible. Role::ReasoningEffort::_build_reasoning_wire_format
# and Role::Tools::_build_tool_wire_format default to 'openai';
# ResponsesCompatible (composed last) supplies 'responses' for both (ADR 0015
# -excludes canon). Role::Tools: the Agent API takes client-executed
# type:function tools (karr k213); its built-in tools are not modelled here.
with 'Langertha::Role::Models',
     'Langertha::Role::Temperature',
     'Langertha::Role::ReasoningEffort' => { -excludes => ['_build_reasoning_wire_format'] },
     'Langertha::Role::Tools'           => { -excludes => ['_build_tool_wire_format'] },
     'Langertha::Role::ResponseSize',
     'Langertha::Role::SystemPrompt',
     'Langertha::Role::ResponseFormat',
     'Langertha::Role::Streaming',
     # Role::Chat::content_format defaults to 'openai'; ResponsesCompatible supplies 'responses'.
     'Langertha::Role::Chat' => { -excludes => ['content_format'] },
     'Langertha::Role::StaticModels',
     'Langertha::Role::ImageInput',
     'Langertha::Role::ResponsesCompatible';


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.perplexity.ai' },
);

has api_key => (
  is => 'ro',
  lazy_build => 1,
);
sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_PERPLEXITY_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_PERPLEXITY_API_KEY or api_key set";
}


sub update_request {
  my ( $self, $request ) = @_;
  my $key = $self->api_key;
  $request->header('Authorization', 'Bearer '.$key) if defined $key;
}


sub default_model { 'sonar' }

# The four user-facing model ids, unchanged from the Sonar lineup. They are
# selectors only: _responses_model_kwargs maps each onto a preset for the wire.
sub _build_static_models {[
  { id => 'sonar' },
  { id => 'sonar-pro' },
  { id => 'sonar-reasoning-pro' },
  { id => 'sonar-deep-research' },
]}

# Doc-recommended model -> preset mapping (migrate-from-sonar guide 2026-09-10;
# live-confirmed k147, 2026-09-14). A preset is a routing label, not a model id:
# fast, low and medium all resolved to openai/gpt-5.6-luna on the wire, so the
# base model behind a preset is Perplexity's to change -- which is why the engine
# reports whatever $response->model returns rather than mapping it back (by
# 2026-09-29, k232, fast already resolved to openai/gpt-6-luna). high
# (sonar-deep-research) was not exercised (cost). reasoning.effort on the
# fast/low presets is ACCEPTED (HTTP 200, echoed as reasoning:{effort}) but
# spends no reasoning tokens there -- honored-as-accepted, a no-op on the
# non-reasoning presets, never a 400.
my %MODEL_TO_PRESET = (
  'sonar'               => 'fast',
  'sonar-pro'           => 'low',
  'sonar-reasoning-pro' => 'medium',
  'sonar-deep-research' => 'high',
);

# Exactly one of model / models / preset is required. Emit the preset for a
# known sonar id (presets bundle web_search + citations); pass anything else
# straight through as `model` so a caller can target an explicit Agent
# model/preset by name.
sub _responses_model_kwargs {
  my ( $self ) = @_;
  my $model = $self->chat_model // $self->default_model;
  if ( my $preset = $MODEL_TO_PRESET{$model} ) {
    return ( preset => $preset );
  }
  return ( model => $model );
}

# Structured output stays in the Chat-Completions shape at the TOP level of the
# body ({type:json_schema,json_schema:{name,schema,strict?}}) — NOT under
# text.format the way OpenAI's Responses engine wants it.
# Live-confirmed (k147): the top-level response_format=json_schema slot is
# honored, `strict` is enforced (the reply is exactly the schema, no extra
# keys), structured JSON is returned, and search still runs alongside it. The
# response_format.type enum is {json_schema,text} (see the json_object
# correction below).
sub _responses_format_kwargs {
  my ( $self, $rf ) = @_;
  return ( response_format => $rf );
}

# Agent API input items are typed {type:"message",role,content}. Live-confirmed
# (k147): a bare {role,content} item (no type) is ALSO accepted (HTTP 200), so
# type:message is a safe superset rather than a hard requirement — stamp it
# anyway, the explicit form the docs show.
sub _normalize_input_item {
  my ( $self, $msg ) = @_;
  return { type => 'message', %$msg };
}

# The Agent API is not an OpenAPI-spec engine here: POST the built body straight
# to /v1/agent (Remote's generate_http_request), rather than resolving an
# operation id against a spec the way OpenAIResponses does.
# Live-confirmed (k147): creation is POST /v1/agent (HTTP 200). The reply is an
# object:"response" with a resp_ id, store:true and background:false — the
# Open-Responses store shape — so retrieval would follow /v1/responses/{id},
# not /v1/agent/{id}. Retrieve/background is not implemented here and was not
# exercised (stateful; no cheap probe).
sub _responses_dispatch {
  my ( $self, $response_call, @request_args ) = @_;
  return $self->generate_http_request(
    POST => $self->url.'/v1/agent',
    $response_call,
    @request_args,
  );
}

# Citations. The classic Sonar top-level citations[] is gone; the Agent API
# carries sources in an output[] item of type search_results, each result a
# {id,url,title,snippet,date,last_updated,source} hash. Lift them onto
# Response.citations.
# Live-confirmed (k147): inline markers are [1] (NOT [web:1]); the message
# output_text part carries an annotations[] that came back empty, so the
# search_results block is the authoritative source list, exactly as assumed
# here. A structured (json_schema) reply still emits the search_results block.
sub _responses_extra_fields {
  my ( $self, $data ) = @_;
  my @citations;
  for my $item ( @{ $data->{output} // [] } ) {
    next unless ref($item) eq 'HASH';
    next unless ( $item->{type} // '' ) eq 'search_results';
    push @citations, @{ $item->{results} // [] };
  }
  return @citations ? ( citations => \@citations ) : ();
}

# Agent API echo filter (karr k213, ADR 0020 k213 Update). The Agent input is
# a closed oneOf of message | function_call | function_call_output, and a
# message part is only input_text / input_image (OpenAPI for POST /v1/agent,
# fetched 2026-09-25). Live-confirmed (k232, 2026-09-29): the echo this builds
# -- the call verbatim with its fc_ id and status, a preamble flattened to
# string content, search_results left out -- is accepted (HTTP 200); captures in
# t/data/perplexity_agent_*. The Responses echo replays every
# output[] item, which on a preset turn includes search_results /
# fetch_url_results / *_results / mcp_* items and an assistant message of
# output_text parts -- all off-schema as input. Keep the calls (thought_signature
# included, as Perplexity's own sample replays them), flatten an assistant
# message to its text, drop everything else.
sub _responses_echo_item {
  my ( $self, $item ) = @_;
  my $type = $item->{type} // '';
  return $item if $type eq 'function_call' || $type eq 'function_call_output';
  return () unless $type eq 'message';
  my $content = $item->{content};
  my $text = ref $content eq 'ARRAY'
    ? join( '', map { $_->{text} // '' }
        grep { ref $_ eq 'HASH' && ( $_->{type} // '' ) eq 'output_text' } @$content )
    : ( $content // '' );
  return () unless length $text;
  return { type => 'message', role => ( $item->{role} // 'assistant' ), content => $text };
}

# The Agent API's response_format enum is {json_schema,text} — no json_object
# (live-confirmed k147: a json_object body -> HTTP 400 "validation failed:
# response_format.type must be one of json_schema, text"), so clear the flag
# Role::ResponseFormat advertises by default. The Agent request schema has no
# tool_choice and no parallel_tool_calls field (karr k213, docs only), so clear
# every tool_choice_* flag and parallel_tool_use that Role::Tools brings: the
# envelope then never sends either field, and with tool_choice_named off chat_f
# still reroutes a forced tool through json_schema (Perplexity stays the ADR
# 0005 direction-1 exemplar). Everything else is honest by composition: no
# Role::PromptCache (prompt_cache / prompt_cache_key stay off — caching is
# automatic), no Role::ServerTools, Role::ReasoningEffort composed so
# reasoning_effort is on (wire reasoning.effort via the responses format).
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete $caps->{$_} for qw(
    response_format_json_object
    tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
    parallel_tool_use
  );
  return $caps;
};

# image_input (k266, ADR 0019 k266 Update): the Agent API takes input_image
# parts (k267), but a sonar id is a preset whose base model is Perplexity's to
# change, so only an explicit third-party id from an all-vision family claims
# (llm-advisor, docs only, 2026-09-25). Open-weight gpt-oss is text-only.
sub model_capability_corrections {
  return (
    qr/\A/                              => { image_input => 0 },
    qr{\A(?:openai|anthropic|google)/}  => { image_input => 1 },
    qr{\Aopenai/gpt-oss}                => { image_input => 0 },
  );
}

# Tool-result PDFs (karr k361): the Agent API's FunctionCallOutputInput.output
# is "a JSON string or an array of input_text and input_image content parts",
# and no input schema lists input_file (docs.perplexity.ai/api-reference/
# agent-post, fetched 2026-09-30), so a PDF stays the k336 placeholder while
# OpenAIResponses sends it as input_file. Spelled out (the Role::Tools default
# is 0 too) because this is where the shared Responses envelope diverges.
sub _tool_result_pdf_on_wire { 0 }

# Rate limit (karr k356, ADR 0022): the Agent API sends x-ratelimit-limit /
# -remaining / -reset / -used with no -requests / -tokens suffix, and the Remote
# fallback reads only Retry-After. Read here, not in a shared parser: on
# Perplexity -reset is an epoch-seconds instant (the k232 captures put it one
# second after their own Date header), while other senders of the same names use
# other kinds (OpenRouter an epoch-ms, the IETF RateLimit draft delta-seconds),
# and ADR 0022 declines guessing the kind by magnitude. used=1 after one request
# makes it the requests bucket. -used stays in raw; retry_after is derived from
# raw as on every engine.
around _parse_rate_limit_headers => sub {
  my ( $orig, $self, $http_response ) = @_;
  require Langertha::RateLimit;
  require Langertha::Moment;
  my %raw = Langertha::RateLimit::_collect_headers($http_response);
  my ( $limit, $remaining, $reset ) = @raw{ map { "x-ratelimit-$_" } qw( limit remaining reset ) };
  return $self->$orig($http_response) unless defined $limit || defined $remaining || defined $reset;
  my $reset_at = Langertha::Moment->from_wire($reset);
  return Langertha::RateLimit->new(
    received => Langertha::Moment->now_utc,
    ( defined $limit     ? ( requests_limit     => $limit + 0 )     : () ),
    ( defined $remaining ? ( requests_remaining => $remaining + 0 ) : () ),
    ( defined $reset     ? ( requests_reset     => $reset )         : () ),
    ( defined $reset_at  ? ( requests_reset_at  => $reset_at )      : () ),
    raw => \%raw,
  );
};

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Perplexity - Perplexity Agent API (search-augmented)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::Perplexity;

    my $perplexity = Langertha::Engine::Perplexity->new(
        api_key => $ENV{PERPLEXITY_API_KEY},
        model   => 'sonar-pro',
    );

    my $response = $perplexity->simple_chat('What are the latest Perl releases?');
    print $response;              # the answer text
    print $response->citations;   # ArrayRef of search sources

    # Streaming
    $perplexity->simple_chat_stream(sub {
        print shift->content;
    }, 'Summarize recent Perl news');

    # Async with Future::AsyncAwait
    use Future::AsyncAwait;
    my $response = await $perplexity->simple_chat_f('What is new in Perl?');

=head1 DESCRIPTION

Provides access to Perplexity's B<Agent API> (C<POST /v1/agent>), the successor
to the retired Sonar Chat Completions surface (Sonar Chat Completions reached
end of life 2026-09-27). The Agent API speaks the Open-Responses wire envelope
(C<input> / C<instructions> / typed C<output[]> / C<input_tokens> usage), not
C</chat/completions>, so this engine composes
L<Langertha::Role::ResponsesCompatible> (shared with
L<Langertha::Engine::OpenAIResponses>) over a bare
L<Langertha::Engine::Remote> for Bearer auth and HTTP.

Perplexity models are search-augmented LLMs with real-time web access;
responses carry L<Langertha::Response/citations> alongside the generated text.

=head2 Models and presets

The four user-facing model ids are kept as the selector; each maps to an Agent
API B<preset>, which is what actually reaches the wire. Presets bundle the
web_search tool and inline citations automatically — a bare model call on the
Agent API no longer searches (web search became opt-in), so the preset path is
what preserves Perplexity's search+citations identity.

    sonar                 -> preset "fast"
    sonar-pro             -> preset "low"
    sonar-reasoning-pro   -> preset "medium"
    sonar-deep-research   -> preset "high"

C<$response-E<gt>model> reports the real model the chosen preset ran — a preset
is a routing label, not a fixed model (in mid-September 2026 C<fast>, C<low> and
C<medium> all resolved to C<openai/gpt-5.6-luna> on the wire; by 2026-09-29
C<fast> resolved to C<openai/gpt-6-luna>), so read the model off the response
rather than inferring it from the preset.

=head2 Capabilities

Client function tools work: pass C<tools> to C<chat_f>, or set
C<mcp_servers> and use C<chat_with_tools_f>. They go out as flat
C<< { type => 'function', name, description, parameters } >> tools, the
model's C<function_call> items land on L<Langertha::Response/tool_calls>, and
the tool loop answers them with C<function_call_output> items. Perplexity never
runs a function tool itself. A preset still runs its own C<web_search>
alongside your tools (presets merge tools). The echo of a tool turn keeps only
what the Agent input accepts: the function calls and the assistant's text; the
search results and other built-in tool items are left out. The call turn, its
echo (the call with its C<id> and C<status>, then the C<function_call_output>)
and a streamed call turn were checked against the live API (2026-09-29). For a
turn with search results and an assistant preamble (a constructed turn: the
model did not produce one live), only this is live-confirmed: the filtered echo
is accepted with HTTP 200. That the Agent input rejects the unfiltered items
comes from Perplexity's documentation.

There is no C<tool_choice> and no C<parallel_tool_calls> on the Agent API, so
every C<tool_choice_*> capability and C<parallel_tool_use> are off and neither
field is ever sent (a forced choice that cannot be sent carps). C<tool_choice
=E<gt> 'none'> is honored by leaving the request's tools out (with a carp); a
choice Langertha cannot read is dropped with a carp. A request without tools
may still carry earlier C<function_call> and C<function_call_output> items; the
Agent API accepts them (checked live, 2026-09-29). Perplexity's
built-in tools (C<web_search>, C<fetch_url>, C<sandbox>, ...) are not modelled
yet; a native hash of one in C<tools> is sent as given.

No C<json_object> mode: the only structured C<response_format> the Agent API
accepts is C<json_schema> (the C<type> enum is C<json_schema>/C<text>; a
C<json_object> body is rejected with HTTP 400). A forced named tool still
works as structured output — C<chat_f> rewrites it into a top-level
C<response_format=json_schema> plus a synthetic L<Langertha::ToolCall> (ADR
0005 rewrite direction 1; Perplexity remains its exemplar), and C<strict> is
enforced on the returned JSON. C<reasoning_effort> B<is> accepted (wire
C<reasoning.effort>), though the non-reasoning presets (C<fast>/C<low>) echo it
back without spending reasoning tokens. Prompt caching is automatic (no
request-side key).

Limitations: embeddings and transcription are not supported.

Get your API key at L<https://www.perplexity.ai/settings/api> and set
C<LANGERTHA_PERPLEXITY_API_KEY>.

=head2 api_key

Perplexity API key, sent as C<Authorization: Bearer>. Defaults to
C<LANGERTHA_PERPLEXITY_API_KEY>.

=head2 update_request

Adds the C<Authorization: Bearer {api_key}> header. Auth is unchanged from the
Sonar surface — only the endpoint and body shape moved to the Agent API.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::ResponsesCompatible> - the Open-Responses wire envelope this composes

=item * L<Langertha::Engine::OpenAIResponses> - the other Responses-envelope consumer

=item * L<https://docs.perplexity.ai/docs/agent-api/migrate-from-sonar/overview> - Sonar -> Agent API migration guide

=item * L<https://status.perplexity.com/> - Perplexity service status

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
