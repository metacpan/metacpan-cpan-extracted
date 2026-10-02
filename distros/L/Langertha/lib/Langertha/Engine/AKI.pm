package Langertha::Engine::AKI;
# ABSTRACT: AKI.IO native API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak carp );
use JSON::MaybeXS;

extends 'Langertha::Engine::Remote';

with map { 'Langertha::Role::'.$_ } qw(
  Models
  Temperature
  SystemPrompt
  Chat
  Tools
  HermesTools
);

sub _build_tool_wire_format { 'hermes' }

# The native /api/call body has no tools field, so Hermes (tools in the system
# prompt) is the only tool wire it can carry. Another tag would claim
# tools_native (HermesTools keys on the resolved tag, k251) and then drop the
# tools from the request -- fail loud instead. -- karr k254
sub BUILD {
  my ( $self ) = @_;
  my $fmt = $self->tool_wire_format;
  croak "".(ref $self)." cannot use tool_wire_format '$fmt': the native API only"
    ." speaks 'hermes'; use Langertha::Engine::AKIOpenAI (\$aki->openai) for native tools"
    unless $fmt eq 'hermes';
  return;
}


has api_key => (
  is => 'ro',
  lazy_build => 1,
);
sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_AKI_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_AKI_API_KEY or api_key set";
}


has '+url' => (
  lazy => 1,
  default => sub { 'https://aki.io' },
);

# AKI's native /api/endpoints listing carries `minimax_m3` (endpoint_details
# reports "MiniMax M3 428B", category chat) — AKI.IO's current-generation
# MiniMax and the chosen default now that llama3_8b_chat is marked end-of-life
# 2026-09-30. Verified live against the native endpoint listing on 2026-09-10.
# MiniMax is a per-account gated endpoint: a key without the entitlement is
# answered with "Client not authorized for endpoint minimax_m3!" (not a silent
# fallback), so check $response->model / the error when it matters. -- karr k132
sub default_model { 'minimax_m3' }


sub hermes_extract_content {
  my ( $self, $data ) = @_;
  return $data->{text};
}

has top_k => (
  is => 'ro',
  isa => 'Num',
  predicate => 'has_top_k',
);


has top_p => (
  is => 'ro',
  isa => 'Num',
  predicate => 'has_top_p',
);


has max_gen_tokens => (
  is => 'ro',
  isa => 'Int',
  predicate => 'has_max_gen_tokens',
);


# Dynamic model listing

sub list_models_request {
  my ($self) = @_;
  return $self->generate_http_request(
    GET => $self->url.'/api/endpoints?key='.$self->api_key,
    sub { $self->list_models_response(shift) },
  );
}

sub list_models_response {
  my ($self, $response) = @_;
  my $data = $self->parse_response($response);
  return $data->{endpoints};
}

sub list_models {
  my ($self, %opts) = @_;

  # Check cache unless force_refresh requested
  unless ($opts{force_refresh}) {
    my $cache = $self->_models_cache;
    if ($cache->{timestamp} && time - $cache->{timestamp} < $self->models_cache_ttl) {
      return $opts{full} ? $cache->{models} : $cache->{model_ids};
    }
  }

  # Fetch from API
  my $request = $self->list_models_request;
  my $response = $self->user_agent->request($request);
  my $endpoints = $request->response_call->($response);

  # Update cache
  $self->_models_cache({
    timestamp => time,
    models => $endpoints,
    model_ids => $endpoints,
  });

  return $endpoints;
}


sub endpoint_details_request {
  my ($self, $endpoint_name) = @_;
  return $self->generate_http_request(
    GET => $self->url.'/api/endpoints/'.$endpoint_name.'?key='.$self->api_key,
    sub { $self->endpoint_details_response(shift) },
  );
}

sub endpoint_details_response {
  my ($self, $response) = @_;
  return $self->parse_response($response);
}

sub endpoint_details {
  my ($self, $endpoint_name) = @_;
  my $request = $self->endpoint_details_request($endpoint_name);
  my $response = $self->user_agent->request($request);
  return $request->response_call->($response);
}


# Chat

sub chat_request {
  my ( $self, $messages, %extra ) = @_;

  # Canonical per-request controls (chat_f, karr #46) beat the engine
  # attributes on a per-key basis; the rest of %extra passes straight through.
  # AKI's native wire only honors temperature and max_gen_tokens; the other
  # canonical controls (response_format, seed, reasoning_effort, ...) have no
  # native placement here and are consumed without being emitted.
  my $controls = delete $extra{controls} // {};

  # The model is the endpoint; a per-request model names it there, never in
  # the body (karr k357).
  my $model = $self->_url_model( \%extra );
  return $self->generate_http_request(
    POST => $self->url.'/api/call/'.$model,
    sub { $self->chat_response(shift) },
    key => $self->api_key,
    chat_context => $self->encode_json_text($messages),
    exists $controls->{temperature}
      ? ( temperature => $controls->{temperature} )
      : ( $self->has_temperature ? ( temperature => $self->temperature ) : () ),
    $self->has_top_k ? ( top_k => $self->top_k ) : (),
    $self->has_top_p ? ( top_p => $self->top_p ) : (),
    exists $controls->{max_tokens}
      ? ( max_gen_tokens => $controls->{max_tokens} )
      : ( $self->has_max_gen_tokens ? ( max_gen_tokens => $self->max_gen_tokens ) : () ),
    wait_for_result => JSON->true,
    %extra,
  );
}


sub chat_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  croak "".(ref $self)." API error: ".($data->{error} || 'unknown')
    unless $data->{success};
  require Langertha::Response;
  # The native endpoint composes Role::HermesTools (tool_wire_format 'hermes'),
  # so tool calls ride as <tool_call> tags in the model text. Route them onto
  # Response.tool_calls (ADR 0003) via the tag-aware role helpers rather than
  # leaving them buried in content; strip the tags from content when a call is
  # present. -- karr k123
  my $tool_calls = $self->_raw_tool_calls($data);

  # Native usage: the AKI wire names its token counts differently from the
  # OpenAI/Anthropic shapes, so normalize to the keys Langertha::Usage->from_hash
  # understands. num_cached_tokens is the same quantity as cached_tokens; it rides
  # in the usage hash so Response->usage->cached_tokens carries it and
  # Response->cached_tokens is lifted off that Usage (karr k197). It counts
  # prefix-cache *reads* (a subset of prompt_length, vLLM 16-token blocks, often
  # non-zero even on a first call); native and /v1 report the same numbers for
  # identical messages (live-verified 2026-09-25). Trust $response->model for which
  # model answered. -- karr k126, k197
  my $usage = {
    defined $data->{prompt_length}        ? ( prompt_tokens     => $data->{prompt_length} )        : (),
    defined $data->{num_generated_tokens} ? ( completion_tokens => $data->{num_generated_tokens} ) : (),
    defined $data->{num_cached_tokens}    ? ( cached_tokens     => $data->{num_cached_tokens} )    : (),
  };
  undef $usage unless %$usage;

  # Timing: AKI reports durations already in SECONDS. Emit the engine-agnostic
  # total_seconds (ADR 0011) plus the native compute_seconds, and deliberately do
  # NOT emit a raw total_duration key -- Engine::Ollama uses that same key in
  # nanoseconds, so an AKI seconds value under it collides by a factor of 1e9.
  # -- karr k126
  my $timing = {
    defined $data->{total_duration}   ? ( total_seconds   => $data->{total_duration} )   : (),
    defined $data->{compute_duration} ? ( compute_seconds => $data->{compute_duration} ) : (),
  };
  undef $timing unless %$timing;

  return Langertha::Response->new(
    content       => ( @$tool_calls ? $self->_raw_text_content($data) : ( $data->{text} // '' ) ),
    raw           => $data,
    $data->{job_id}     ? ( id    => $data->{job_id} )     : (),
    $data->{model_name} ? ( model => $data->{model_name} ) : (),
    $usage              ? ( usage => $usage )              : (),
    $timing             ? ( timing => $timing )            : (),
    @$tool_calls        ? ( tool_calls => $tool_calls )    : (),
  );
}


sub openai {
  my ( $self, %args ) = @_;
  require Langertha::Engine::AKIOpenAI;
  unless (exists $args{model}) {
    carp "".(ref $self)."->openai: native model name cannot be mapped to /v1 model name automatically, using AKIOpenAI default model";
  }
  return Langertha::Engine::AKIOpenAI->new(
    api_key => $self->api_key,
    $self->has_system_prompt ? ( system_prompt => $self->system_prompt ) : (),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    %args,
  );
}


sub anthropic {
  my ( $self, %args ) = @_;
  require Langertha::Engine::AKIAnthropic;
  unless (exists $args{model}) {
    carp "".(ref $self)."->anthropic: native model name cannot be mapped to /anthropic model name automatically, using AKIAnthropic default model";
  }
  return Langertha::Engine::AKIAnthropic->new(
    api_key => $self->api_key,
    $self->has_system_prompt ? ( system_prompt => $self->system_prompt ) : (),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    %args,
  );
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::AKI - AKI.IO native API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::AKI;

    my $aki = Langertha::Engine::AKI->new(
        api_key => $ENV{AKI_API_KEY},
        model   => 'llama3_8b_chat',
    );

    print $aki->simple_chat('Hello from Perl!');

    # Get OpenAI-compatible API access
    my $aki_openai = $aki->openai;
    print $aki_openai->simple_chat('Hello via OpenAI format!');

    # Get Anthropic-compatible API access
    my $aki_anthropic = $aki->anthropic;
    print $aki_anthropic->simple_chat('Hello via Anthropic format!');

=head1 DESCRIPTION

Provides access to AKI.IO's native API for running LLM inference. AKI.IO is
a European AI model hub based in Germany; all inference runs on EU infrastructure,
fully GDPR-compliant with no data leaving the EU.

The native API sends the API key as a C<key> field in the JSON request body
(not as an HTTP header). Supports synchronous chat, temperature and sampling
controls, dynamic endpoint listing, MCP tool calling via
L<Langertha::Role::HermesTools>, OpenAI-compatible access via L</openai>,
and Anthropic-compatible access via L</anthropic>.

Streaming is not yet supported in the native API. For streaming, use the
OpenAI-compatible endpoint via C<< $aki->openai >>.

The native API has no C<tools>, C<tool_choice> or C<response_format> field:
tools ride the system prompt (Hermes format), which cannot force a tool, so a
C<tool_choice> other than C<auto> or C<none> is dropped with a warning. To
force a tool or get structured output, use L<Langertha::Engine::AKIOpenAI>
(C<< $aki->openai >>).

C<tool_wire_format> is fixed to C<hermes>: the constructor croaks on any other
value, since the native body has no field to carry native tools. Use
L<Langertha::Engine::AKIOpenAI> for OpenAI-format tools.

Get your API key at L<https://aki.io/> and set C<LANGERTHA_AKI_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

The AKI.IO API key. If not provided, reads from C<LANGERTHA_AKI_API_KEY>
environment variable. Sent as a C<key> field in the JSON request body
(not as an HTTP header). Required.

=head2 default_model

Returns C<minimax_m3>, AKI.IO's current-generation MiniMax M3 (428B) on the
native endpoint. This replaces C<llama3_8b_chat>, which AKI.IO marks
end-of-life 2026-09-30. MiniMax is a B<per-account gated> endpoint: a key
without the entitlement is answered with C<"Client not authorized for endpoint
minimax_m3!"> rather than a silent model substitution, so check
C<< $response->model >> if it matters which model replied.

=head2 top_k

    top_k => 40

Top-K sampling parameter. Controls the number of highest-probability tokens
to consider at each generation step.

=head2 top_p

    top_p => 0.9

Top-P (nucleus) sampling parameter. Controls the cumulative probability
threshold for token selection.

=head2 max_gen_tokens

    max_gen_tokens => 1000

Maximum number of tokens to generate in the response.

=head2 list_models

    my $endpoints = $aki->list_models;
    my $endpoints = $aki->list_models(force_refresh => 1);

Fetches available endpoint names from the AKI.IO C<GET /api/endpoints> API.
Returns an ArrayRef of endpoint names. Results are cached for C<models_cache_ttl>
seconds (default: 3600).

=head2 endpoint_details

    my $details = $aki->endpoint_details('llama3_8b_chat');
    # Returns hashref with name, title, description, workers, parameter_description, etc.

Fetches detailed information about a specific endpoint from the AKI.IO
C<GET /api/endpoints/{name}> API. Returns worker info, model metadata,
and parameter descriptions.

=head2 chat_request

    my $request = $aki->chat_request($messages, %extra);

Generates a native AKI.IO chat request. Posts to C</api/call/{model}> with
messages encoded as JSON in the C<chat_context> field. Includes C<key>,
C<temperature>, C<top_k>, C<top_p>, C<max_gen_tokens>, and
C<wait_for_result> parameters as configured. A C<model> in C<%extra> (a
per-request model from L<Langertha::Role::Chat/chat_f> or
L<Langertha::Chat/model>) replaces C<{model}> in the URL for this request and
is not sent in the body. Returns an HTTP request object.

=head2 chat_response

    my $response = $aki->chat_response($http_response);

Parses a native AKI.IO chat response. Dies with an API error message if
C<success> is false. Returns a L<Langertha::Response> with C<content>,
C<id> (from the wire C<job_id>), C<model>, C<usage> (from C<prompt_length> /
C<num_generated_tokens> / C<num_cached_tokens>), C<cached_tokens> (lifted off
C<usage>),
C<timing> (C<total_seconds> / C<compute_seconds>, both already in seconds),
C<tool_calls> (Hermes C<E<lt>tool_callE<gt>> tags), and C<raw>. The native
token counts differ from the OpenAI-compatible shim for the same prompt —
check C<< $response->model >> for which model answered.

=head2 openai

    my $oai = $aki->openai;
    my $oai = $aki->openai(model => 'llama3-chat-8b');

Returns a L<Langertha::Engine::AKIOpenAI> instance configured with the same
API key, system prompt, and temperature. Supports streaming and MCP tool
calling.

B<Note:> The native AKI model name is B<not> carried over automatically
because the C</v1> endpoint uses different model identifiers. If no C<model>
is passed, the AKIOpenAI default model is used and a warning is emitted.
Pass C<< model => '...' >> explicitly with a valid C</v1> model name to
suppress the warning.

=head2 anthropic

    my $anth = $aki->anthropic;
    my $anth = $aki->anthropic(model => 'gemma4-26b');

Returns a L<Langertha::Engine::AKIAnthropic> instance configured with the
same API key, system prompt, and temperature. URL defaults to
C<https://aki.io/anthropic> (set on L<Langertha::Engine::AKIAnthropic>
itself, so it is not carried over from the native engine's
C<https://aki.io> base).

B<Note:> The native AKI model name is B<not> carried over automatically
because the C</anthropic> endpoint uses different model identifiers. If no
C<model> is passed, the AKIAnthropic default model is used and a warning is
emitted. Pass C<< model => '...' >> explicitly with a valid C</anthropic>
model name to suppress the warning. AKI.IO also silently routes unknown
model IDs to MiniMax M2.5 — check C<< $response->model >> if it matters
which model replied.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::AKIOpenAI> - OpenAI-compatible AKI.IO access via L</openai>

=item * L<Langertha::Engine::AKIAnthropic> - Anthropic-compatible AKI.IO access via L</anthropic>

=item * L<https://aki.io/docs> - AKI.IO API documentation

=item * L<Langertha::Role::Chat> - Chat interface methods

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
