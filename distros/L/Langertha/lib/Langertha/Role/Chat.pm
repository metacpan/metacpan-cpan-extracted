package Langertha::Role::Chat;
# ABSTRACT: Role for APIs with normal chat functionality
our $VERSION = '0.503';
use Moose::Role;
use Future;
use Future::AsyncAwait;
use Carp qw( carp croak );
use JSON::MaybeXS;
use Log::Any qw( $log );
use Scalar::Util qw( blessed refaddr );
use Time::HiRes qw( gettimeofday tv_interval );
use Langertha::ToolChoice;
use Langertha::Tool;
use Langertha::ServerTool;
use Langertha::Role::Capabilities;

requires qw(
  chat_request
  chat_response
);


# Defaults to the OpenAI dialect; AnthropicBase (via AnthropicCompatible),
# ResponsesCompatible, Engine::Gemini, Engine::Ollama and Engine::LMStudio
# override it. The POD =method above documents the same override points from
# the engine-user perspective.
sub content_format { 'openai' }

# Internal wire truth, deliberately not a capability flag (karr k267): true on
# engines whose endpoint rejects remote image URLs (base64 / data: URLs only).
# URL-sourced Content::Image blocks are then inlined -- fetched, as to_gemini
# always does -- before serialization, and a failed fetch croaks before any
# request is sent.
sub _content_inline_images_only { 0 }


with 'Langertha::Role::Capabilities';


has chat_model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy_build => 1,
);
sub _build_chat_model {
  my ( $self ) = @_;
  croak "".(ref $self)." can't handle models!" unless $self->does('Langertha::Role::Models');
  return $self->default_chat_model if $self->can('default_chat_model');
  return $self->model;
}


# Adds a key/value pair into an existing timing hashref (or new one).
# Used to layer client-measured ttft_seconds / total_seconds onto a
# Response that may already carry provider-native stages (e.g. Ollama's
# *_seconds). Never overwrites an existing key — first-write-wins so a
# provider-supplied duration (e.g. Ollama's total_seconds) trumps the
# client measurement.
sub _merge_timing_field {
  my ( $existing, $key, $value ) = @_;
  my $t = $existing ? { %$existing } : {};
  $t->{$key} = $value unless exists $t->{$key};
  return $t;
}

sub chat {
  my ( $self, @messages ) = @_;
  return $self->chat_request($self->chat_messages(@messages));
}


sub chat_messages {
  my ( $self, @messages ) = @_;
  $self->_warn_control_message_args(@messages);
  my @out = $self->_system_messages;
  for my $m (@messages) {
    my $msg = ref $m ? $m : { role => 'user', content => $m };
    push @out, $self->_normalize_content_blocks($msg);
  }
  return \@out;
}

# The leading system messages this engine prepends to a conversation. An
# explicit $system_prompt replaces the engine's own system_prompt; engine
# prefixes (NousResearch's reasoning prompt) wrap this method and still apply.
# Shared by chat_messages and Langertha::Chat (karr k277).
sub _system_messages {
  my ( $self, @override ) = @_;
  my $prompt = @override ? $override[0]
    : $self->has_system_prompt ? $self->system_prompt : undef;
  return defined $prompt ? ( { role => 'system', content => $prompt } ) : ();
}

sub _normalize_content_blocks {
  my ( $self, $msg ) = @_;
  my $content = $msg->{content};
  return $msg unless ref $content eq 'ARRAY';

  my $needs_convert = 0;
  for my $b (@$content) {
    if ( blessed($b) && $b->does('Langertha::Content') ) {
      $needs_convert = 1;
      last;
    }
  }
  my $fmt    = $self->content_format;
  # Gemini has no string-or-array content field: every array becomes parts,
  # Content object or not (karr k269). Ollama native content is a string: a
  # text-part array is joined, never sent as an array (karr k331).
  return $msg unless $needs_convert || $fmt eq 'gemini' || $fmt eq 'ollama';

  my $method = "to_$fmt";
  my $role   = $msg->{role} // 'user';
  # Only the URL-capable formats take the inline switch; gemini / ollama /
  # lmstudio always inline.
  my @opt = ( $self->_content_inline_images_only
      && ( $fmt eq 'openai' || $fmt eq 'responses' ) ) ? ( inline => 1 ) : ();

  # Ollama native /api/chat: content is a string, images a sibling base64 array.
  if ( $fmt eq 'ollama' ) {
    my ( @text, @images );
    for my $part (@$content) {
      if ( blessed($part) && $part->does('Langertha::Content') ) {
        push @images, $self->_content_block( $part, $method );
      }
      elsif ( !ref $part ) {
        push @text, $part;
      }
      elsif ( ref $part eq 'HASH' && ( $part->{type} // '' ) eq 'text' && defined $part->{text} ) {
        push @text, $part->{text};
      }
      elsif ( my $img = $self->_image_url_part_image($part) ) {
        push @images, $self->_content_block( $img, $method );
      }
      else {
        croak ref($self).": Ollama native /api/chat takes a string message content; "
          . "a content part may be a string, a { type => 'text' } or { type => 'image_url' } hash "
          . "or a Langertha::Content object";
      }
    }
    return { %$msg, content => join( "\n", @text ),
      ( @images || $msg->{images} )
        ? ( images => [ @{ $msg->{images} // [] }, @images ] ) : () };
  }

  my $text_type = $fmt ne 'responses' ? 'text'
                : $role eq 'assistant' ? 'output_text'
                :                        'input_text';

  my @blocks = map {
    if ( blessed($_) && $_->does('Langertha::Content') ) {
      $self->_content_block( $_, $method, @opt );
    }
    elsif ( !ref $_ ) {
      $fmt eq 'gemini'
        ? { text => $_ }
        : { type => $text_type, text => $_ };
    }
    elsif ( $fmt eq 'gemini' ) {
      $self->_gemini_part( $_, $method );
    }
    else {
      $_;
    }
  } @$content;

  if ( $fmt eq 'gemini' ) {
    return { role => ( $role eq 'assistant' ? 'model' : $role ), parts => \@blocks };
  }
  return { %$msg, content => \@blocks };
}

# One hash part of a Gemini message. A part without `type` is already native
# (text, inline_data / inlineData, fileData / file_data, functionCall, ...) and
# passes through; the OpenAI-style text and image_url parts are translated, an
# image through Content::Image so it gets the same inline_data a Content object
# gets. Any other typed part has no Gemini counterpart and croaks (karr k269).
sub _gemini_part {
  my ( $self, $part, $method ) = @_;
  return $part unless ref $part eq 'HASH' && defined $part->{type};
  my $type = $part->{type};
  return { text => $part->{text} } if $type eq 'text' && defined $part->{text};
  if ( my $img = $self->_image_url_part_image($part) ) {
    return $self->_content_block( $img, $method );
  }
  croak ref($self).": a Gemini message content part may be a string, a native Gemini part, "
    . "a { type => 'text' } or { type => 'image_url' } hash or a Langertha::Content object; "
    . "got type '$type'";
}

# The Langertha::Content::Image for an OpenAI-style { type => 'image_url' }
# hash part (a data URL becomes base64), or undef for any other part. Shared by
# the wires without an image_url part of their own (gemini, ollama).
sub _image_url_part_image {
  my ( $self, $part ) = @_;
  return undef unless ref $part eq 'HASH' && ( $part->{type} // '' ) eq 'image_url';
  my $url = ref $part->{image_url} eq 'HASH' ? $part->{image_url}{url} : $part->{image_url};
  return undef unless defined $url && length $url;
  require Langertha::Content::Image;
  return $url =~ m{\Adata:([^;,]+);base64,(.*)\z}s
    ? Langertha::Content::Image->from_base64( $2, media_type => $1 )
    : Langertha::Content::Image->from_url($url);
}

# Serializes one Langertha::Content block. A URL-only image that has to be
# inlined (fetched) and cannot be says so in the engine's name before any
# request is built (karr k267).
sub _content_block {
  my ( $self, $block, $method, @opt ) = @_;
  my %opt = @opt;
  # The serializers fetch through ensure_base64 without arguments (30s); fetch
  # first with the engine's timeout instead (karr k279).
  my $prefetch = $block->isa('Langertha::Content::Image')
    && $block->has_url && !$block->has_base64
    && ( $opt{inline} || $method =~ /\Ato_(?:gemini|ollama|lmstudio)\z/ );
  my $out;
  return $out if eval {
    $block->ensure_base64( timeout => $self->inline_image_fetch_timeout,
      $self->_inline_image_fetch_limits ) if $prefetch;
    $out = $block->$method(@opt);
    1;
  };
  my $err = $@;
  croak $self->_inline_image_error($err)
    if $block->can('has_url') && $block->has_url && !$block->has_base64;
  die $err;
}

sub _inline_image_error {
  my ( $self, $err ) = @_;
  $err =~ s/ at \S+ line \d+.*//s;
  $err =~ s/\s+\z//;
  return ref($self).": this endpoint takes only inline images (base64 or a data: URL) "
    . "and the image URL could not be inlined ($err); pass the image as base64 "
    . "or from a local file instead";
}

has inline_image_fetch_timeout => (
  isa => 'Int',
  is => 'ro',
  default => 30,
);


has inline_image_max_bytes => (
  isa => 'Int',
  is => 'ro',
  default => 20_971_520,
);


has inline_image_url_filter => (
  isa => 'Maybe[CodeRef]',
  is => 'ro',
);


# The ensure_base64(_f) options for the two attributes above (karr k337).
sub _inline_image_fetch_limits {
  my ($self) = @_;
  return ( max_bytes => $self->inline_image_max_bytes,
    url_filter => $self->inline_image_url_filter );
}

# The _f paths fetch every URL image this engine has to inline through its
# async backend (_async_http: injected client, Net::Async::HTTP or the sync
# LWP shim, ADR 0027) before the request is built, all at once, so the build
# finds base64 on the object and does no blocking LWP GET inside the event
# loop (karr k274). Returns @messages, with Gemini's image_url hash parts
# swapped for the fetched Content::Image they would have become in
# _gemini_part. A failed fetch fails with the error _content_block croaks.
# Each fetch races inline_image_fetch_timeout on the backend's loop (karr
# k276): Net::Async::HTTP has no timeout of its own, so a host that accepts
# and never answers would stall the call forever. wait_any cancels the loser:
# the fetch (Net::Async::HTTP closes its connection) or the timer.
async sub _prefetch_inline_images_f {
  my ( $self, @messages ) = @_;
  my $fmt = $self->content_format;
  return @messages unless $fmt eq 'gemini' || $fmt eq 'ollama' || $fmt eq 'lmstudio'
    || ( $self->_content_inline_images_only && ( $fmt eq 'openai' || $fmt eq 'responses' ) );

  my ( @out, @fetch, %seen, %by_url );
  for my $msg (@messages) {
    unless ( ref $msg eq 'HASH' && ref $msg->{content} eq 'ARRAY' ) {
      push @out, $msg;
      next;
    }
    my $swapped;
    my @content;
    for my $part ( @{ $msg->{content} } ) {
      my $out = $part;
      if ( blessed($part) && $part->isa('Langertha::Content::Image') ) {
        push @fetch, $part
          if $part->has_url && !$part->has_base64 && !$seen{ refaddr $part }++;
      }
      elsif ( $fmt eq 'gemini' && ref $part eq 'HASH' && ( $part->{type} // '' ) eq 'image_url' ) {
        my $url = ref $part->{image_url} eq 'HASH' ? $part->{image_url}{url} : $part->{image_url};
        if ( defined $url && length $url && $url !~ m{\Adata:[^;,]+;base64,}s ) {
          require Langertha::Content::Image;
          $out = $by_url{$url} //= do {
            my $img = Langertha::Content::Image->from_url($url);
            push @fetch, $img;
            $img;
          };
          $swapped = 1;
        }
      }
      push @content, $out;
    }
    push @out, $swapped ? { %$msg, content => \@content } : $msg;
  }
  return @messages unless @fetch;

  my $http = $self->_async_http;
  my $loop = $self->async_loop;
  my $secs = $self->inline_image_fetch_timeout;
  await Future->needs_all( map {
    my $url   = $_->url;
    my $fetch = $_->ensure_base64_f( $http, $self->_inline_image_fetch_limits );
    $fetch = Future->wait_any( $fetch, $loop->delay_future( after => $secs )
      ->then_fail("ensure_base64: failed to fetch $url: timed out after ${secs}s\n") )
      if $loop && $secs;
    $fetch->else( sub {
      Future->fail( $self->_inline_image_error( $_[0] ) . "\n" );
    } );
  } @fetch );
  return @out;
}


sub simple_chat {
  my ( $self, @messages ) = @_;
  $log->debugf("[%s] simple_chat with %d message(s), model=%s",
    ref $self, scalar @messages, $self->chat_model // 'default');
  my $t0 = [gettimeofday];
  my $request = $self->chat(@messages);
  my $response = $self->user_agent->request($request);
  my $elapsed = tv_interval($t0);
  my $result = $request->response_call->($response);
  if (ref $result && $result->isa('Langertha::Response')) {
    $result = $result->clone_with(
      timing => _merge_timing_field($result->timing, total_seconds => $elapsed),
    );
    if ($self->can('has_rate_limit') && $self->has_rate_limit) {
      $result = $result->clone_with(rate_limit => $self->rate_limit);
    }
  }
  return $result;
}


sub chat_stream {
  my ( $self, @messages ) = @_;
  croak "".(ref $self)." does not support streaming"
    unless $self->can('chat_stream_request');
  return $self->chat_stream_request($self->chat_messages(@messages));
}


sub simple_chat_stream {
  my ( $self, $callback, @messages ) = @_;
  croak "simple_chat_stream requires a callback as first argument"
    unless ref $callback eq 'CODE';
  $log->debugf("[%s] simple_chat_stream (%s format)", ref $self, $self->stream_format);
  my $request = $self->chat_stream(@messages);
  my ( $chunks, $timing ) = $self->execute_streaming_request($request, $callback);
  $log->debugf("[%s] Stream completed: %d chunks (%.3fs)",
    ref $self, scalar @$chunks, $timing->{total_seconds} // 0);
  my $content  = join('', map { $_->content } @$chunks);
  my $thinking = $self->aggregate_thinking($chunks);
  return wantarray ? ( $content, $thinking ) : $content;
}


sub simple_chat_stream_iterator {
  my ( $self, @messages ) = @_;
  require Langertha::Stream;
  my $request = $self->chat_stream(@messages);
  my ( $chunks, $timing ) = $self->execute_streaming_request($request);
  $log->debugf("[%s] Stream completed: %d chunks (%.3fs)",
    ref $self, scalar @$chunks, $timing->{total_seconds} // 0);
  return Langertha::Stream->new(chunks => $chunks);
}


# Future-based async methods. The _async_http backend (and its _async_loop)
# come from Langertha::Role::AsyncHTTP (composed below): injected client >
# Net::Async::HTTP > synchronous LWP fallback.

async sub simple_chat_f {
  my ( $self, @messages ) = @_;
  $log->debugf("[%s] simple_chat_f with %d message(s)", ref $self, scalar @messages);
  return await $self->chat_f( messages => \@messages );
}

# Canonical per-request controls (karr #46). chat_f normalizes these like
# messages/tools instead of spreading them as raw target-wire kwargs: each
# engine's chat_request consumes the `controls` hash and places them via the
# same value objects the engine attributes use (Langertha::Reasoning,
# Langertha::PromptCache) or the engine's own placement logic (Ollama options,
# Gemini generationConfig). Unknown keys still pass straight through.
my %CANONICAL_CONTROLS = map { $_ => 1 } qw(
  temperature
  max_tokens
  response_format
  seed
  parallel_tool_use
  reasoning_effort
  thinking_budget
  thinking_display
  prompt_cache
  prompt_cache_ttl
  prompt_cache_key
  prefix_cache_salt
  cache_prompt
  n_cache_reuse
  id_slot
  priority
  return_cached_tokens_details
  extra_key
);

sub _extract_controls {
  my ( $self, $opts ) = @_;
  my %controls;
  for my $key ( keys %CANONICAL_CONTROLS ) {
    $controls{$key} = delete $opts->{$key} if exists $opts->{$key};
  }
  return \%controls;
}


# karr #122: simple_chat / simple_chat_f / chat funnel their positional
# @messages through chat_messages, which turns every non-ref scalar into a
# { role => 'user' } turn. A caller who mistakes those methods for chat_f and
# appends a control as a kwarg tail -- simple_chat($prompt, reasoning_effort =>
# 'high') -- silently sends the control name and its value as extra user
# messages, with no error and no effect (the project hit this twice in its own
# docs). This is a diagnostic only: warn once (never die) when a plain-scalar
# message exactly matches a canonical control name; behaviour is otherwise
# unchanged (the strings still become messages as before). A control name has
# no legitimate use as a whole user turn, so this has no false positives in
# practice. The broader unknown-constructor-arg finding (karr #101) is out of
# scope here.
sub _warn_control_message_args {
  my ( $self, @messages ) = @_;
  my %seen;
  my @hits =
    grep { !$seen{$_}++ }
    grep { defined $_ && !ref $_ && $CANONICAL_CONTROLS{$_} } @messages;
  return unless @hits;
  carp sprintf(
    "%s: message argument(s) %s match a chat_f control name and are being "
      . "sent as plain user message text. Per-request controls such as "
      . "reasoning_effort, temperature and response_format are named "
      . "arguments to chat_f (or engine constructor attributes), not "
      . "simple_chat/chat message arguments.",
    ref $self,
    join( ', ', map { "'$_'" } @hits ),
  );
  return;
}

# Drop warnings (karr k247, ADR 0025): a request builder that leaves a value
# off the wire says so, but the carp fires in a private helper several
# Langertha frames below the caller's chat_f / chat / simple_chat_f call, and
# Carp skips only one frame. For the duration of this one warning every
# Langertha, Moose, Class::MOP, Eval::Closure and Future package on the stack
# is marked Carp-internal, so the message names the first frame outside that
# plumbing: the user's own call site (the rule of Role::AsyncHTTP's
# _caller_location). croak keeps Carp's normal location. Under an event loop
# the stack may hold no user frame; Carp then reports what it finds, it never
# dies.
#
# $once is set when the dropped value comes from an engine attribute: that
# value is the same on every request (and every chat_with_tools_f iteration),
# so it warns once per engine instance per key. A per-request value warns
# every time. The seen-set lives on the instance, never in a global.
has _warned_drops => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => undef,
  lazy     => 1,
  default  => sub { {} },
);

my $LANGERTHA_INTERNAL = qr/\A(?:Langertha|Moose|Class::MOP|Eval::Closure|Future)(?:::|\z)/;

sub _langertha_carp {
  my ( $self, $message, $once ) = @_;
  return if defined $once && $self->_warned_drops->{$once}++;
  my %internal;
  for ( my $level = 0; my ($package) = caller $level; $level++ ) {
    $internal{$package} = 1 if $package =~ $LANGERTHA_INTERNAL;
  }
  local @Carp::Internal{ keys %internal } = (1) x keys %internal;
  carp $message;
  return;
}

# karr #148 / #184: a couple of OpenAI-compatible serving stacks reject a
# request that combines tools and a structured-output response_format with an
# opaque HTTP 400 and no body. No boolean capability flag can express a mutual
# exclusion between two capabilities in one request (ADR 0021). The constraint
# is a property of the serving STACK, not of the model: Groq and Cerebras
# enforce it across every model they serve, while AKI serves gpt-oss-120b with
# tools + a json_schema response_format at HTTP 200 (live 2026-09-19) — so each
# affected engine declares its own all-models rule and there is no shared base
# rule to over-fire on the unaffected stacks.
#
# The seam mirrors ADR 0019's model_capability_corrections: an ORDERED list of
# ( $matcher => $rule ) pairs keyed on chat_model. $matcher is an exact
# model-id string (matched with eq) or a qr// regex (matched against
# chat_model). $rule is a CODEREF — the concrete seam, deliberately NOT a
# declarative constraint DSL (karr #148) — invoked as $self->$rule(%request)
# with has_tools / tool_choice_forced / response_format / streaming; it croaks
# when the request hits the combination the stack rejects. The default is an
# empty list, so engines that constrain nothing pay nothing; an engine whose
# serving stack rejects the combination declares an all-models rule by
# overriding model_capability_exclusions (Groq, Cerebras, SGLang).
sub model_capability_exclusions { return () }

# Consulted by chat_f (streaming => 0) and chat_stream_realtime_f
# (streaming => 1) after the effective post-rewrite request is built (ADR 0021),
# so an ADR 0005 rewrite that already collapsed the body to a single path
# pre-empts it. Walks the per-model exclusion table for the selected chat_model
# and lets each matching rule convert a known provider 400 into a clear local
# croak. A no-op when the table is empty or no matcher hits.
sub _check_capability_exclusions {
  my ( $self, %request ) = @_;
  $self->$_(%request) for $self->_matched_capability_exclusions;
  return;
}

# The rules of model_capability_exclusions whose matcher hits chat_model, in
# table order. Shared by _check_capability_exclusions and the per-request model
# override warning (karr k352), which compares the matched set for two models.
sub _matched_capability_exclusions {
  my ( $self ) = @_;
  my @rules = $self->model_capability_exclusions;
  return unless @rules;
  # chat_model is the model that actually carries tools / response_format on the
  # wire; guard for the rare consumer that has no model surface at all.
  # An empty or undef chat_model is matched as '', the same as
  # model_capability_corrections (karr k223), so an all-models qr// rule
  # (Groq, Cerebras) still holds for model => ''.
  return unless $self->can('chat_model');
  my $model = $self->chat_model // '';
  my @matched;
  while ( @rules >= 2 ) {
    my ( $matcher, $rule ) = splice @rules, 0, 2;
    my $hit = ref $matcher eq 'Regexp' ? ( $model =~ $matcher )
            :                            ( $model eq $matcher );
    push @matched, $rule if $hit;
  }
  return @matched;
}


# True when the request asks for tools — either a tools array or a
# forced named tool_choice. Used to feed the capability-exclusion hook.
sub _chat_tools_requested {
  my ( $self, $opts ) = @_;
  # An empty tools => [] sends zero tools on the wire, so it must NOT trip the
  # capability-exclusion guard (which would croak on Cerebras/Groq for a request
  # that combines tools with a structured-output response_format). Only a
  # non-empty tools array counts as "tools requested" here.
  return 1 if ref $opts->{tools} eq 'ARRAY' && @{ $opts->{tools} };
  return 0 unless exists $opts->{tool_choice};
  my $tc = Langertha::ToolChoice->from_hash( $opts->{tool_choice} );
  return ( $tc && $tc->type eq 'tool' ) ? 1 : 0;
}

# True when the request forces a tool call: tool_choice any (wire 'required')
# or a named tool (karr k245). Read from the caller's tool_choice before any
# tool_choice gate runs, so an exclusion rule sees what was asked; after the
# ADR 0005 rewrite (which deletes tool_choice) it is 0. Feeds the
# capability-exclusion hook as tool_choice_forced.
sub _chat_tool_choice_forced {
  my ( $self, $opts ) = @_;
  return 0 unless defined $opts->{tool_choice};
  my $tc = Langertha::ToolChoice->from_hash( $opts->{tool_choice} );
  return ( $tc && ( $tc->type eq 'any' || $tc->type eq 'tool' ) ) ? 1 : 0;
}

# The response_format the request builders will put on the wire (karr k249):
# the per-request value when the caller passed the key, else the engine
# attribute (Role::ResponseFormat) -- the same precedence as
# OpenAICompatible's chat_request / chat_stream_request, AnthropicCompatible's
# _take_response_format and ResponsesCompatible. Feeds the capability-exclusion
# hook, so a rule also fires for an engine-level response_format. Always a
# scalar (undef when neither is set): it is called in a hash-list position.
sub _chat_effective_response_format {
  my ( $self, $opts ) = @_;
  my $rf = exists $opts->{response_format} ? $opts->{response_format}
    : ( $self->can('has_response_format') && $self->has_response_format ) ? $self->response_format
    : undef;
  return $rf;
}

# The ADR 0005 forced-tool rewrite sets a per-request response_format, which
# replaces any other one (karr k250). A structured response_format the caller
# passed in the same request is a conflicting intent: croak. One that only
# comes from the engine attribute yields to the request's forced tool: carp.
# A `text` response_format asks for no structure, so it is no conflict.
sub _chat_rewrite_replaces_response_format {
  my ( $self, $opts, $name ) = @_;
  my $rf = $self->_chat_effective_response_format($opts);
  return unless defined $rf;
  my $type = ref $rf eq 'HASH' ? $rf->{type} : $rf;
  return if defined $type && !ref $type && $type eq 'text';
  croak "".(ref $self).": chat_f got both a forced tool_choice '$name' and a "
    . "response_format; this engine carries a forced tool as a response_format "
    . "(no native named tool_choice), so the two conflict -- pick one"
    if exists $opts->{response_format};
  $self->_langertha_carp( "".(ref $self).": the forced tool_choice '$name' is sent as a "
    . "response_format (no native named tool_choice); the engine's "
    . "response_format is replaced for this request",
    "response_format replaced by tool_choice $name" );
  return;
}

# karr k352 (split from k238): a `model` passed to chat_f or
# chat_stream_realtime_f is no canonical control; it rides %extra into the
# request builder and replaces the body's model field. Every model-scoped wire
# decision still reads chat_model: the layer-3 capability corrections and the
# learned facts (ADR 0019 / 0032, and a model-aware layer 2 such as Gemini's),
# the exclusion rules (ADR 0024), the reasoning profile (ADR 0023), the
# reasoning temperature gate (ADR 0025), the per-model tool_wire_format (ADR
# 0033) and the per-model body shape (completion-length key, response-size
# default, native structured output). Langertha does not re-scope a request to
# its override (that is a second engine); it warns when the override would get
# a different decision, naming which.
#
# Quiet unless something flips: an override equal to chat_model costs nothing,
# and only the decisions THIS request consults are compared. A capability flag
# named here is compared only when one of its request features is in play;
# image_input never (it reports what the model sees and gates nothing, ADR
# 0019 k266 Update); any other flag always, so a new model-scoped flag errs
# toward a warning, not toward silence.
my %CAP_CONSULTED_BY = (
  tools_native                => ['tools'],
  tools_hermes                => ['tools'],
  server_tools                => ['tools'],
  tool_choice_auto            => ['tool_choice'],
  tool_choice_any             => ['tool_choice'],
  tool_choice_none            => ['tool_choice'],
  tool_choice_named           => ['tool_choice'],
  response_format_json_object => ['response_format'],
  # the ADR 0005 forced-tool rewrite consults it too
  response_format_json_schema => [ 'response_format', 'tool_choice' ],
  temperature                 => ['temperature'],
  reasoning_effort            => ['reasoning'],
  thinking_budget             => ['reasoning'],
  parallel_tool_use           => ['parallel_tool_use'],
  streaming                   => ['streaming'],
  # Gemini's per-generation flag: consulted only with a bound cachedContent
  cached_content              => ['cached_content'],
  image_input                 => [],
);

# The request features that decide which model-scoped decisions a request
# consults: from the per-request options, else the engine attribute.
sub _chat_request_features {
  my ( $self, $opts, $streaming ) = @_;
  my $attr_set = sub {
    my $predicate = 'has_' . $_[0];
    return $self->can($predicate) && $self->$predicate;
  };
  my %features;
  $features{tools} = 1 if ref $opts->{tools} eq 'ARRAY' && @{ $opts->{tools} };
  $features{tool_choice} = 1 if defined $opts->{tool_choice};
  $features{response_format} = 1 if defined $self->_chat_effective_response_format($opts);
  $features{temperature} = 1 if exists $opts->{temperature} || $attr_set->('temperature');
  $features{reasoning} = 1
    if grep { exists $opts->{$_} || $attr_set->($_) } qw( reasoning_effort thinking_budget thinking_display );
  $features{parallel_tool_use} = 1 if exists $opts->{parallel_tool_use} || $attr_set->('parallel_tool_use');
  $features{max_tokens} = 1 if exists $opts->{max_tokens};
  $features{streaming} = 1 if $streaming;
  $features{cached_content} = 1 if $attr_set->('cached_content');
  return \%features;
}

# The model-scoped decisions this engine takes for a request with $features,
# as label => value. Read-only: no warning, no request. An engine with a
# model-scoped decision of its own adds it with an `around` (NousResearch's
# reasoning prompt).
sub _model_scoped_wire_decisions {
  my ( $self, $features, $opts ) = @_;
  my %decision;
  my $caps = $self->engine_capabilities;
  for my $cap ( grep { $caps->{$_} } keys %$caps ) {
    my $by = $CAP_CONSULTED_BY{$cap};
    next if $by && !grep { $features->{$_} } @$by;
    $decision{"supports('$cap')"} = 1;
  }
  my $tools = $features->{tools} || $features->{tool_choice};
  $decision{tool_wire_format} = $self->tool_wire_format
    if $tools && $self->can('tool_wire_format');
  $decision{model_capability_exclusions} = join ',', map { refaddr $_ } $self->_matched_capability_exclusions
    if $tools || $features->{response_format};
  if ( $features->{reasoning} ) {
    require Langertha::Reasoning::Profile;
    $decision{'reasoning profile'} =
      refaddr( Langertha::Reasoning::Profile->for_model( $self->_capability_model ) );
  }
  $decision{'temperature gate'} = $self->_temperature_rejected_by_reasoning($opts) ? 1 : 0
    if $features->{temperature} && $self->can('_temperature_rejected_by_reasoning');
  my $size = $self->can('get_response_size') ? $self->get_response_size : undef;
  $decision{'response_size default'} = $size // ''
    if !$features->{max_tokens} && $self->can('get_response_size');
  $decision{'completion-length key'} = $self->_max_tokens_key
    if ( $features->{max_tokens} || $size ) && $self->can('_max_tokens_key');
  $decision{'native structured output'} = $self->_native_structured_output_for_model ? 1 : 0
    if $features->{response_format} && $self->can('_native_structured_output_for_model');
  return %decision;
}

# Warns when the request's model override flips a decision (see above). The
# decisions for the override are read off an in-memory clone whose chat_model
# is the override, as Manifest::Builder probes a model (a builder-made
# tool_wire_format is resolved again, a constructor one kept, karr k251). A
# per-request value, so it warns on every request (karr k247). Diagnostic
# only: if the decisions cannot be computed, the request goes on unwarned and
# its own path reports the error.
sub _warn_model_override {
  my ( $self, $method, $opts, $streaming ) = @_;
  my $override = $opts->{model};
  return unless defined $override && !ref $override && length $override;
  return unless $self->can('chat_model');
  my $configured = $self->_capability_model // '';
  return if $override eq $configured;
  my @flipped;
  {
    local $@;
    eval {
      my $features = $self->_chat_request_features( $opts, $streaming );
      my $probe = $self->meta->clone_object( $self, chat_model => $override );
      $probe->_reset_derived_tool_wire_format if $probe->can('_reset_derived_tool_wire_format');
      my %mine   = $self->_model_scoped_wire_decisions( $features, $opts );
      my %theirs = $probe->_model_scoped_wire_decisions( $features, $opts );
      my %labels = ( %mine, %theirs );
      @flipped = grep { ( $mine{$_} // '' ) ne ( $theirs{$_} // '' ) } sort keys %labels;
      1;
    } or return;
  }
  return unless @flipped;
  $self->_langertha_carp( "".(ref $self).": $method got a per-request model '$override' "
    . "that differs from chat_model '$configured'; model-scoped wire decisions follow "
    . "chat_model, and these differ for '$override': " . join( ', ', @flipped )
    . " -- use an engine whose chat_model is '$override'" );
  return;
}

# The model a request goes to on a wire that names it in the URL (Gemini's
# models/{model}:generateContent, AKI native's /api/call/{model}): the
# per-request override when there is one (the same test as
# _warn_model_override), else chat_model. The `model` key is taken out of
# %extra either way: there it would only ride the body as an unknown field
# while the URL still named chat_model (karr k357).
sub _url_model {
  my ( $self, $extra ) = @_;
  my $override = delete $extra->{model};
  return $override if defined $override && !ref $override && length $override;
  return $self->chat_model;
}

async sub chat_f {
  my ( $self, %opts ) = @_;

  my $messages = delete $opts{messages} // [];
  my @messages = ref $messages eq 'ARRAY' ? @$messages : ($messages);

  # Before any decision is taken for chat_model (karr k352).
  $self->_warn_model_override( 'chat_f', \%opts, 0 );

  # A Langertha::ServerTool needs a wire that takes server-side tools (k206).
  Langertha::ServerTool->check_engine( $self, $opts{tools} );

  # Auto-fallback: forced named tool on an engine that cannot do
  # native named-tool-forcing but supports json_schema response_format.
  # Rewrite tools+tool_choice into a response_format and remember the
  # tool name so we can synthesize a tool_calls entry afterwards.
  my $synth_tool_name;
  if ( exists $opts{tool_choice}
    && exists $opts{tools}
    && !$self->supports('tool_choice_named')
    && $self->supports('response_format_json_schema')
  ) {
    my $tc = Langertha::ToolChoice->from_hash( $opts{tool_choice} );
    if ( $tc && $tc->type eq 'tool' && defined $tc->name && length $tc->name ) {
      my $name = $tc->name;
      my ($tool) =
        grep { defined $_ && $_->name eq $name }
        map  { Langertha::Tool->from_hash($_) }
        @{ $opts{tools} };
      if ($tool) {
        $self->_chat_rewrite_replaces_response_format( \%opts, $name );
        delete $opts{tools};
        delete $opts{tool_choice};
        $opts{response_format} = {
          type        => 'json_schema',
          json_schema => {
            %{ $tool->to_json_schema },
            strict => JSON->true,
          },
        };
        $synth_tool_name = $name;
        $log->debugf("[%s] forced-tool fallback: tool '%s' rerouted via response_format",
          ref $self, $name);
      }
    }
  }

  # Provider mutual-exclusion guard (karr #148). Consulted after the
  # forced-tool fallback (which may have set response_format) so it sees the
  # effective request; walks the per-model exclusion table for the selected
  # chat_model and croaks on a combination the model rejects with an opaque 400.
  $self->_check_capability_exclusions(
    has_tools          => $self->_chat_tools_requested(\%opts),
    tool_choice_forced => $self->_chat_tool_choice_forced(\%opts),
    response_format    => $self->_chat_effective_response_format(\%opts),
    streaming          => 0,
  );

  # Extract the canonical controls (after the forced-tool fallback, which may
  # have set response_format) and hand them to chat_request under `controls`.
  my $controls = $self->_extract_controls(\%opts);

  @messages = await $self->_prefetch_inline_images_f(@messages);
  my ( $conversation, $hermes_prompted ) =
    $self->_hermes_prompt_tools( \%opts, $self->chat_messages(@messages) );
  $opts{tools} = $self->_wire_tools( $opts{tools} ) if ref $opts{tools} eq 'ARRAY';

  $conversation = $self->_hermes_prompt_schema( $controls, $conversation );

  my $t0 = [gettimeofday];
  my $request = $self->chat_request( $conversation,
    ( %$controls ? ( controls => $controls ) : () ),
    %opts );

  my $response = await $self->_async_do_request_f( request => $request );

  # A failed response records its rate limit before the die (a success does it
  # in parse_response), so a caller can back off from a 429 (karr k300).
  unless ($response->is_success) {
    $self->_update_rate_limit($response) if $self->can('_update_rate_limit');
    # The sync croak's text, body included (karr k312).
    die $self->_request_failed_message( $response, 'request' );
  }

  my $elapsed = tv_interval($t0);
  my $result = $request->response_call->($response);

  if ( blessed($result) && $result->isa('Langertha::Response') ) {
    $result = $result->clone_with(
      timing => _merge_timing_field( $result->timing, total_seconds => $elapsed ),
    );
  }

  # One chat_with_tools_f turn on hermes (k231): the <tool_call> blocks the
  # model wrote go onto Response.tool_calls (ADR 0003), out of content. An
  # engine whose chat_response already lifted them (AKI native) is left alone.
  if ( $hermes_prompted && blessed($result) && $result->isa('Langertha::Response')
       && !( $result->has_tool_calls && @{ $result->tool_calls } ) ) {
    my ( $clean, $calls ) = $self->_hermes_split_text( $result->content );
    if (@$calls) {
      # The reply ended to call tools: report that over the wire's stop, as the
      # OpenAI dialect does for native calls (k248); ->raw keeps the wire value.
      my $reason = $result->finish_reason;
      $result = $result->clone_with( content => $clean, tool_calls => $calls,
        ( !length( $reason // '' ) || $reason eq 'stop' ) ? ( finish_reason => 'tool_calls' ) : () );
    }
  }

  if ( $synth_tool_name && blessed($result) && $result->isa('Langertha::Response') ) {
    my $args = $self->decode_loose_json( $result->content );
    # A tool's arguments are a JSON object. Only synthesize the ToolCall when the
    # model actually returned one — a non-object result (e.g. a bare JSON array)
    # would otherwise be coerced to empty {} in Response BUILDARGS and the
    # synthetic call would falsely claim success with no arguments. Leaving
    # tool_calls unset lets the caller see the gap (the raw content is still on
    # Response.content) instead of a hollow success.
    if ( ref $args eq 'HASH' ) {
      $result = $result->clone_with(
        tool_calls => [{
          name      => $synth_tool_name,
          arguments => $args,
          synthetic => 1,
        }],
      );
    }
    else {
      $log->debugf(
        "[%s] forced-tool fallback: '%s' response was not a JSON object; no synthetic tool_call attached",
        ref $self, $synth_tool_name);
    }
  }

  if ( $self->can('has_rate_limit') && $self->has_rate_limit
       && ref $result && $result->isa('Langertha::Response') ) {
    $result = $result->clone_with( rate_limit => $self->rate_limit );
  }
  return $result;
}



sub simple_chat_stream_f {
  my ($self, @messages) = @_;
  return $self->simple_chat_stream_realtime_f(undef, @messages);
}


async sub simple_chat_stream_realtime_f {
  my ($self, $chunk_callback, @messages) = @_;

  return await $self->chat_stream_realtime_f(
    messages       => \@messages,
    chunk_callback => $chunk_callback,
  );
}

async sub chat_stream_realtime_f {
  my ( $self, %opts ) = @_;

  my $chunk_callback = delete $opts{chunk_callback};
  my $messages = delete $opts{messages} // [];
  my @messages = ref $messages eq 'ARRAY' ? @$messages : ($messages);

  croak "".(ref $self)." does not support streaming"
    unless $self->can('chat_stream_request');

  # Before any decision is taken for chat_model (karr k352).
  $self->_warn_model_override( 'chat_stream_realtime_f', \%opts, 1 );

  # A Langertha::ServerTool needs a wire that takes server-side tools (k206).
  Langertha::ServerTool->check_engine( $self, $opts{tools} );

  # Provider mutual-exclusion guard (karr #148) — streaming path. Same per-model
  # seam as chat_f; the streaming flag lets a rule refuse a combination that is
  # rejected only when streaming (e.g. Groq structured outputs, which do not
  # support streaming at all).
  $self->_check_capability_exclusions(
    has_tools          => $self->_chat_tools_requested(\%opts),
    tool_choice_forced => $self->_chat_tool_choice_forced(\%opts),
    response_format    => $self->_chat_effective_response_format(\%opts),
    streaming          => 1,
  );

  # Same canonical-control extraction as chat_f (karr #46).
  my $controls = $self->_extract_controls(\%opts);

  @messages = await $self->_prefetch_inline_images_f(@messages);
  my ( $conversation, $hermes_prompted ) =
    $self->_hermes_prompt_tools( \%opts, $self->chat_messages(@messages) );
  $conversation = $self->_hermes_prompt_schema( $controls, $conversation );
  $opts{tools} = $self->_wire_tools( $opts{tools} ) if ref $opts{tools} eq 'ARRAY';

  my $request = $self->chat_stream_request( $conversation,
    ( %$controls ? ( controls => $controls ) : () ),
    %opts );
  my @all_chunks;
  my $buffer = '';
  my %stream_state;   # this stream's parse state (tool-call fragments, karr k221)
  my $format = $self->stream_format;
  my $response_status;
  my $error_content;   # the body of a non-2xx response
  my $t0           = [gettimeofday];
  my $ttft_seconds;

  # Every parsed chunk goes out through here. When the tools rode the hermes
  # prompt, the <tool_call> blocks are withheld from the text and their calls
  # land on the final chunk, as chat_f lifts them from its reply (karr k253).
  my %hermes_state;
  # $flush (no chunk) asks the lift for what a stream without a final chunk
  # still owes.
  my $deliver = sub {
    my ( $chunk, $flush ) = @_;
    $ttft_seconds = tv_interval($t0) unless defined $ttft_seconds || $flush;
    if ($hermes_prompted) {
      $chunk = $self->_hermes_stream_chunk( \%hermes_state, $chunk, $flush );
      return unless $chunk;
    }
    $ttft_seconds //= tv_interval($t0);
    push @all_chunks, $chunk;
    $chunk_callback->($chunk) if $chunk_callback;
  };

  # A die in the chunk-sub (a malformed stream line, or the caller's
  # chunk_callback) must fail this request's future on every backend, and must
  # not unwind into the backend: Net::Async::HTTP runs the chunk-sub inside
  # the loop's read handler, where a die escapes the loop and leaves this
  # request pending (karr k194, ADR 0027).
  my ( $request_f, $stream_error );
  $request_f = $self->_async_do_request_f(
    request => $request,
    on_header => sub {
      my ($response) = @_;
      $response_status = $response;

      # A non-2xx body is the provider's error, not a stream: keep it for the
      # error text (the sync croak shows it, karr k312) instead of parsing it.
      # Net::Async::HTTP hands the header response without the body.
      unless ( $response->is_success ) {
        $error_content = '';
        return sub { $error_content .= $_[0] if defined $_[0] };
      }

      # Return a callback that handles each body chunk
      return sub {
        my ($data) = @_;
        return if $stream_error;       # already failed; drop the rest
        return unless defined $data;   # undef signals end of body

        my $ok = eval {
          $buffer .= $data;
          my $chunks = $self->_process_stream_buffer(\$buffer, $format, 0, \%stream_state);
          $deliver->($_) for @$chunks;
          1;
        };
        return if $ok;
        $stream_error = [ $@ || "streaming callback died\n", http => $response, $request ];

        # A synchronous backend (Langertha::Request::SyncHTTP) runs the
        # chunk-sub before do_request returns: die again so it stops reading
        # and fails its own future with the original exception.
        die $stream_error->[0] unless $request_f;

        # An event-loop backend must not be stopped from in here. Cancelling
        # a Net::Async::HTTP request closes its connection, and doing that
        # inside its read handler leaves the rest of an already-read burst
        # in the buffer of a connection with no request left, which
        # Net::Async::HTTP then dies on ("Spurious on_read"). Cancel on the
        # next loop iteration instead, once this read is fully processed; if
        # the response completes within this read there is nothing to cancel.
        # A future without an IO::Async-style loop (an injected client with
        # no loop, or one from another event system) is drained.
        my $loop = $request_f->can('loop') && $request_f->loop;
        $loop->later(sub { $request_f->cancel unless $request_f->is_ready })
          if $loop && $loop->can('later');
        return;
      };
    },
  );

  # Wait for the transfer to end however it ends: done, failed, or cancelled
  # above. A cancel from our own caller still stops the transfer.
  my $transfer_f = $request_f->new;
  $request_f->on_ready(sub { $transfer_f->done unless $transfer_f->is_ready });
  $transfer_f->on_cancel(sub { $request_f->cancel unless $request_f->is_ready });
  await $transfer_f;
  # The headers arrived, so their rate limit is this response's, whatever
  # happens to the body or the status next (karr k300). Taken here, not in
  # on_header, which may run inside the event loop's read handler.
  $self->_update_rate_limit($response_status)
    if $response_status && $self->can('_update_rate_limit');
  # The exception that stopped the stream wins over any transport failure
  # seen afterwards (from the cancel, a drain, or the connection itself).
  await Future->fail(@$stream_error) if $stream_error;
  await $request_f if $request_f->is_failed;

  unless ($response_status->is_success) {
    my $failed = $response_status->clone;
    $failed->content($error_content) if defined $error_content;
    die $self->_request_failed_message( $failed, 'streaming request' );
  }

  # Process remaining buffer
  if ($buffer ne '') {
    my $chunks = $self->_process_stream_buffer(\$buffer, $format, 1, \%stream_state);
    $deliver->($_) for @$chunks;
  }
  # A hermes stream that ended without a final chunk still owes its held text
  # (a partial or unclosed tag is text) and the calls of its closed blocks.
  $deliver->( undef, 1 ) if $hermes_prompted;
  # The stream ended: let the dialect report what it could not finish (a
  # tool call that never saw its finish_reason, karr k221).
  $self->_finish_stream_state(\%stream_state) if $self->can('_finish_stream_state');

  my $content      = join('', map { $_->content } @all_chunks);
  my $thinking     = $self->aggregate_thinking(\@all_chunks);
  my $total_seconds = tv_interval($t0);
  return ($content, \@all_chunks, {
    ttft_seconds  => $ttft_seconds,
    total_seconds => $total_seconds,
  }, $thinking);
}

# Decides a caller's tool_choice against supports('tool_choice_*'), in place,
# for every request builder whose wire field may be missing (karr k239, the
# k233 Responses rule generalized; ADR 0002: field emission follows the
# claimed capability). Returns the Langertha::ToolChoice to serialize when the
# engine supports its kind; the builder calls ->to($fmt) itself, since only it
# knows its envelope. Otherwise the field is deleted: undef or 'auto' (the
# wire default) silently; 'none' withholds the request's tools too, so "call
# no tool" holds without the field, with a carp when there were tools to
# withhold (none without tools is silent, as on the hermes wire, k246); a
# forced choice (any /
# named) with a carp, the model then decides. chat_f's ADR 0005 rewrite runs
# first and has already taken a forced named tool it could reroute. A value
# ToolChoice cannot read (a provider-native choice) stays as given where the
# wire has a tool_choice field at all, and is dropped with a carp where not.
sub _gate_tool_choice {
  my ( $self, $extra ) = @_;
  return unless exists $extra->{tool_choice};
  my $has_field = grep { $self->supports("tool_choice_$_") } qw( auto any none named );
  unless ( defined $extra->{tool_choice} ) {
    delete $extra->{tool_choice} unless $has_field;
    return;
  }
  my $tc = Langertha::ToolChoice->from_hash( $extra->{tool_choice} );
  unless ($tc) {
    return if $has_field;
    delete $extra->{tool_choice};
    $self->_langertha_carp( "".( ref $self ).": dropping tool_choice -- this engine has no tool_choice "
      . "field and the value is not one Langertha can read; the model decides whether to call a tool" );
    return;
  }
  my $cap = $tc->type eq 'tool' ? 'tool_choice_named' : 'tool_choice_' . $tc->type;
  return $tc if $self->supports($cap);
  delete $extra->{tool_choice};
  if ( $tc->type eq 'none' ) {
    my $tools = delete $extra->{tools};
    $self->_langertha_carp( "".( ref $self ).": dropping tool_choice 'none' -- this engine does not "
      . "support('tool_choice_none'); the request's tools are withheld instead" )
        if ref $tools eq 'ARRAY' && @$tools;
    return;
  }
  $self->_langertha_carp( "".( ref $self ).": dropping tool_choice '"
    . ( $tc->type eq 'tool' ? 'tool ' . ( $tc->name // '' ) : $tc->type )
    . "' -- this engine does not support('$cap'); the model decides whether to call a tool" )
      unless $tc->type eq 'auto';
  return;
}

# parallel_tool_use -> parallel_tool_calls, in place, for the Chat Completions
# and Responses builders alike (streaming too, karr k240); Ollama native and
# Gemini call it only for the drop carp (flag cleared, k241). Only when tools are
# present. A per-request control beats the engine attribute; an explicit
# parallel_tool_calls kwarg is the caller's wire intent and wins over both.
# Emitted only where the engine supports('parallel_tool_use') (karr k241, ADR
# 0002); a value the caller set that the gate drops carps (ADR 0025
# drop+carp), nothing set stays silent.
sub _parallel_tool_calls_kwarg {
  my ( $self, $extra, $controls ) = @_;
  return unless exists $extra->{tools} && !exists $extra->{parallel_tool_calls};
  my ( $ptu, $from_attr );
  if ( exists $controls->{parallel_tool_use} ) {
    $ptu = $controls->{parallel_tool_use};
  }
  elsif ( $self->can('has_parallel_tool_use') && $self->has_parallel_tool_use ) {
    $ptu       = $self->parallel_tool_use;
    $from_attr = 1;
  }
  return unless defined $ptu;
  unless ( $self->supports('parallel_tool_use') ) {
    $self->_langertha_carp( "".( ref $self ).": dropping parallel_tool_use -- this engine does not "
      . "support('parallel_tool_use'); the provider decides how many tool calls a turn has",
      $from_attr ? "parallel_tool_use=$ptu" : undef );
    return;
  }
  $extra->{parallel_tool_calls} = $ptu ? JSON->true : JSON->false;
  return;
}

# The one path that puts a caller's tools list on the wire, for chat_f and
# chat_stream_realtime_f alike (karr k221, k227; ADR 0001). A tools list is
# often built by hand: Langertha::Tool / ServerTool objects next to hashes of
# any shape. The JSON encoder would put an object on the wire in its canonical
# to_hash shape, which only the Anthropic wire reads, so the value objects
# shape the list for this engine's tool_wire_format, item by item and in the
# caller's order (Langertha::Tool->request_list): objects serialize, hashes
# already in the wire's shape pass through verbatim (extras and built-ins
# included), other function-tool hashes convert. Order is caller intent, and
# an Anthropic cache_control breakpoint caches the prefix of the list.
# Left alone: an engine without Role::Tools, and the Responses envelope,
# which already decides per item itself and needs the ServerTool objects for
# its engine hook and default-tool dedup (_responses_tools_kwarg, k210/k206).
# The hermes wire never gets here: _hermes_prompt_tools took the list off.
sub _wire_tools {
  my ( $self, $tools ) = @_;
  return $tools unless $self->can('tool_wire_format');
  my $fmt = $self->tool_wire_format;
  return $tools if $fmt eq 'responses';
  return Langertha::Tool->request_list( $fmt, $tools );
}

# The hermes wire has no tools or tool_choice body key: the tools ride the
# system prompt (Role::HermesTools). A chat_f / chat_stream_realtime_f turn is
# built as one chat_with_tools_f turn (karr k231, ADR 0001): the list goes
# through the same format_tools and prompt builder, and neither key reaches
# the body. tool_choice none withholds the tools (no prompt, so no reply
# lift either; the Responses rule of k233). The prompt cannot force a tool,
# so any other choice but auto (or undef, no choice) is ignored with a carp.
# Returns the conversation to send and whether the tool prompt was put in
# front of it.
sub _hermes_prompt_tools {
  my ( $self, $opts, $conversation ) = @_;
  return ( $conversation, 0 )
    unless $self->can('tool_wire_format') && $self->tool_wire_format eq 'hermes';
  my $tools  = delete $opts->{tools};
  my $given  = delete $opts->{tool_choice};
  my $choice = defined $given ? Langertha::ToolChoice->from_hash($given) : undef;
  my $type   = $choice ? $choice->type : '';
  if ( $type eq 'none' ) {
    $self->_langertha_carp( "".(ref $self).": tool_choice none on the hermes tool wire: "
      . "the tools were withheld from the system prompt" )
      if ref $tools eq 'ARRAY' && @$tools;
    return ( $conversation, 0 );
  }
  $self->_langertha_carp( "".(ref $self).": tool_choice is ignored on the hermes tool wire "
    . "(tools ride the system prompt, which cannot force a tool)" )
    if defined $given && $type ne 'auto';
  return ( $conversation, 0 ) unless ref $tools eq 'ARRAY' && @$tools;
  return ( $self->_hermes_tool_messages( $conversation, $self->format_tools($tools) ), 1 );
}

# On the hermes wire a json_schema response_format -- the caller's, the
# engine's, or the ADR 0005 rewrite's -- also rides a leading system message
# (karr k234), so a backend that ignores response_format still sees the
# schema. Only on an engine whose wire takes response_format (NousResearch).
sub _hermes_prompt_schema {
  my ( $self, $controls, $conversation ) = @_;
  return $conversation
    unless $self->can('tool_wire_format') && $self->tool_wire_format eq 'hermes'
      && $self->supports('response_format_json_schema');
  my $format = exists $controls->{response_format} ? $controls->{response_format}
    : ( $self->can('has_response_format') && $self->has_response_format ) ? $self->response_format
    : undef;
  return $self->_hermes_schema_messages( $conversation, $format );
}

sub aggregate_tool_calls {
  my ( $self, $chunks ) = @_;
  return [] unless ref($chunks) eq 'ARRAY';
  my @tcs;
  for my $c (@$chunks) {
    next unless eval { $c->has_tool_calls };
    push @tcs, @{ $c->tool_calls };
  }
  return \@tcs;
}


sub aggregate_thinking {
  my ( $self, $chunks ) = @_;
  return undef unless ref($chunks) eq 'ARRAY';
  my $thinking = '';
  my $seen = 0;
  for my $c (@$chunks) {
    my $t = eval { $c->has_thinking ? $c->thinking : undef };
    next unless defined $t;
    $thinking .= $t;
    $seen = 1;
  }
  return $seen ? $thinking : undef;
}


# Every dialect reports cumulative usage, but not always on the final chunk:
# the OpenAI include_usage frame arrives after it (karr k298). The last chunk
# that carries usage has the stream's totals.
sub aggregate_usage {
  my ( $self, $chunks ) = @_;
  return undef unless ref($chunks) eq 'ARRAY';
  my $usage;
  for my $c (@$chunks) {
    my $u = eval { $c->has_usage ? $c->usage : undef };
    $usage = $u if ref $u eq 'HASH';
  }
  return $usage;
}




sub _process_stream_buffer {
  my ($self, $buffer_ref, $format, $final, $state) = @_;

  my @chunks;

  if ($format eq 'sse') {
    # On the final flush ($final, passed after the stream body ends) the last
    # event can arrive without its terminating blank line — the connection just
    # closed. Append one so the loop below consumes the remainder instead of
    # dropping it (its finish_reason / usage would be lost, and the sync
    # process_stream_data path — which splits the whole body at once — keeps it).
    # Event separators and line breaks are matched CRLF-tolerantly (\r?\n) to
    # match that sync path (split /\r?\n/).
    $$buffer_ref .= "\n\n" if $final && $$buffer_ref ne '';
    while ($$buffer_ref =~ s/^(.*?)\r?\n\r?\n//s) {
      my $block = $1;
      for my $line (split /\r?\n/, $block) {
        next if $line eq '' || $line =~ /^:/;
        if ($line =~ /^data:\s*(.*)$/) {
          my $json_data = $1;
          next if $json_data eq '[DONE]' || $json_data eq '';
          my $parsed = $self->json->decode($json_data);
          my $chunk = $self->parse_stream_chunk($parsed, undef, $state);
          push @chunks, $chunk if $chunk;
        }
      }
    }
  } elsif ($format eq 'ndjson') {
    $$buffer_ref .= "\n" if $final && $$buffer_ref ne '';
    while ($$buffer_ref =~ s/^(.*?)\r?\n//s) {
      my $line = $1;
      next if $line eq '';
      my $parsed = $self->json->decode($line);
      my $chunk = $self->parse_stream_chunk($parsed, undef, $state);
      push @chunks, $chunk if $chunk;
    }
  }

  # A final flush without a caller-owned state ends the stream on the
  # engine-wide fallback: close it here, so nothing left unfinished there can
  # reach the next stream. A caller that passes its own state (as
  # chat_stream_realtime_f does) closes it itself.
  $self->_finish_stream_state
    if $final && !$state && $self->can('_finish_stream_state');

  return \@chunks;
}

with 'Langertha::Role::ThinkTag', 'Langertha::Role::Langfuse', 'Langertha::Role::AsyncHTTP';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Chat - Role for APIs with normal chat functionality

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Synchronous chat
    my $response = $engine->simple_chat('Hello, how are you?');

    # Streaming with callback
    $engine->simple_chat_stream(sub {
        my ($chunk) = @_;
        print $chunk->content;
    }, 'Tell me a story');

    # Streaming with iterator
    my $stream = $engine->simple_chat_stream_iterator('Tell me a story');
    while (my $chunk = $stream->next) {
        print $chunk->content;
    }

    # Async with Future (traditional style)
    my $future = $engine->simple_chat_f('Hello');
    my $response = $future->get;

    # Async with Future::AsyncAwait (recommended)
    use Future::AsyncAwait;

    async sub chat_example {
        my ($engine) = @_;
        my $response = await $engine->simple_chat_f('Hello');
        say $response;
    }

    # Async streaming with real-time callback
    async sub stream_example {
        my ($engine) = @_;
        my ($content, $chunks) = await $engine->simple_chat_stream_realtime_f(
            sub { print shift->content },
            'Tell me a story'
        );
        say "\nTotal chunks: ", scalar @$chunks;
    }

=head1 DESCRIPTION

This role provides chat functionality for LLM engines. It includes both
synchronous and asynchronous (L<Future>-based) methods for chat and streaming.

The Future-based C<_f> methods are implemented using L<Future::AsyncAwait>. The
HTTP backend is selected by L<Langertha::Role::AsyncHTTP>: an injected
C<_async_http> client wins, else L<Net::Async::HTTP> if it can be loaded, else a
synchronous L<LWP::UserAgent> fallback (L<Langertha::Request::SyncHTTP>). These
async modules are loaded lazily only on the async path, so synchronous-only
usage — and the sync fallback — does not require them.

When the sync fallback is used the C<_f> methods still return a L<Future> and
keep working, but they run B<synchronously and sequentially> (blocking, no
concurrency): the future is already complete when returned, so several C<_f>
calls awaited "in parallel" run one after another. Install L<Net::Async::HTTP>
+ L<IO::Async> (or inject your own C<_async_http> client) for real concurrency.

=head2 chat_model

The model name used for chat requests. Lazily defaults to C<default_chat_model>
if the engine provides it, otherwise falls back to the general C<model>
attribute from L<Langertha::Role::Models>.

=head2 chat

    my $request = $engine->chat(@messages);

Builds and returns a chat HTTP request object. Messages may be plain strings
(treated as C<user> role) or HashRefs with C<role> and C<content> keys. A
system prompt from L<Langertha::Role::SystemPrompt> is prepended automatically.

=head2 inline_image_fetch_timeout

Seconds each URL image fetch may take on an engine that has to inline images
(see L</content_format>) before the call fails with the engine-named
inline-image error. Defaults to C<30>.

On the C<_f> paths it is enforced on the event loop of the async backend
(L<Langertha::Role::AsyncHTTP/async_loop>; the error says C<timed out after
30s>), and C<0> disables it; on the synchronous LWP fallback, or with an
injected client without a C<loop>, the client's own timeout applies instead
(for the fallback, the C<user_agent>'s). When the synchronous methods build the
request, it is the LWP timeout of L<Langertha::Content::Image/ensure_base64>
(the error then carries LWP's C<read timeout> status), and C<0> leaves LWP's
own default of 180 seconds, because LWP cannot run without a timeout.

=head2 inline_image_max_bytes

The most bytes a URL image fetch may download on an engine that has to inline
images (see L</content_format>). Defaults to C<20971520> (20 MiB), about the
largest inline image providers take; C<0> removes the cap. Enforced on every
backend: a C<Content-Length> over the cap stops the fetch before the body, and
a body that grows past it stops the download (L<Net::Async::HTTP> closes the
connection, LWP stops reading). The call then fails with the engine-named
inline-image error carrying

    Langertha::Content::Image image at <url> exceeds inline_image_max_bytes (<n>)

on the synchronous and the C<_f> paths alike.
See L<Langertha::Content::Image/ensure_base64>.

=head2 inline_image_url_filter

    inline_image_url_filter => Langertha::Content::Image->deny_private_hosts,
    inline_image_url_filter => sub { my ($uri) = @_; $uri->host eq 'img.example.com' },

Optional code reference that decides which image URLs an engine that has to
inline images may fetch, against server-side request forgery when image URLs
come from untrusted input (a gateway forwarding its clients' messages). It gets
a L<URI> object and returns true to allow the fetch. It runs on the image URL
before any request and on every redirect hop before that hop is requested; a
refusal fails the call with the engine-named inline-image error. Unset by
default: every C<http> and C<https> URL is fetched.
L<Langertha::Content::Image/deny_private_hosts> returns a filter that refuses
loopback, link-local, private, carrier-grade NAT and cloud metadata addresses;
read its DNS-rebinding caveat. Only the fetches Langertha makes are filtered:
engines that pass an image URL through to the provider (OpenAI, Anthropic)
leave the fetch to the provider.

=head2 chat_messages

    my $messages = $engine->chat_messages(@messages);

Normalises C<@messages> into the canonical ArrayRef-of-HashRef format expected
by C<chat_request>. Plain strings become C<{ role =E<gt> 'user', content =E<gt>
$string }>. If the engine has a C<system_prompt> set it is prepended as a
C<system> message.

=head2 simple_chat

    my $response = $engine->simple_chat(@messages);
    my $response = $engine->simple_chat('Hello, how are you?');

Sends a synchronous chat request and returns the response text. Blocks until
the request completes.

=head2 chat_stream

    my $request = $engine->chat_stream(@messages);

Builds and returns a streaming chat HTTP request object. Croaks if the engine
does not implement C<chat_stream_request>. Use L</simple_chat_stream> or
L</simple_chat_stream_iterator> to execute the request.

=head2 simple_chat_stream

    my $content = $engine->simple_chat_stream($callback, @messages);

    $engine->simple_chat_stream(sub {
        my ($chunk) = @_;
        print $chunk->content;
    }, 'Tell me a story');

Sends a synchronous streaming chat request. Calls C<$callback> with each
L<Langertha::Stream::Chunk> as it arrives (each chunk may carry incremental
C<thinking>, see L<Langertha::Stream::Chunk/thinking>). In scalar context
returns the complete concatenated content string; in list context returns
C<($content, $thinking)> where C<$thinking> is the aggregated chain-of-thought
(C<undef> when the engine surfaced none), as L</aggregate_thinking> assembles
it. Blocks until the stream completes. C<total_seconds> is logged; for a full
breakdown read L</execute_streaming_request>.

=head2 simple_chat_stream_iterator

    my $stream = $engine->simple_chat_stream_iterator(@messages);
    while (my $chunk = $stream->next) {
        print $chunk->content;
    }

Returns a L<Langertha::Stream> iterator. The full response is fetched
synchronously and buffered; iteration yields each L<Langertha::Stream::Chunk>
in order.

=head2 _extract_controls

    my $controls = $engine->_extract_controls(\%opts);

Removes the canonical per-request controls (karr #46) from C<%opts> and returns
them as a HashRef. The engine's C<chat_request> receives the hash under the
C<controls> key and places each control on its wire; unknown keys stay in
C<%opts> and pass straight through as before.

=head2 model_capability_exclusions

    sub model_capability_exclusions {
      return (
        qr/some-family/  => \&_exclude_some_combination,  # a model family (regex)
        'exact-model-id' => \&_exclude_some_combination,  # an exact model id
      );
    }

The per-model capability-exclusion seam (karr #148), consulted at the
C<chat_f> / C<chat_stream_realtime_f> layer above the boolean registry. A
boolean capability flag asserts I<the wire accepts field X>; this seam
expresses a I<mutual exclusion between two fields in one request> — combining
C<tools> with a structured-output C<response_format> — which a flag cannot spell
(L<ADR 0021|docs/adr/0021-pairwise-capability-exclusions-as-per-engine-guard.md>).

Returns an B<ordered> list of C<< ( $matcher => $rule ) >> pairs, keyed on
C<chat_model> exactly as L<Langertha::Role::Capabilities/model_capability_corrections>
is. C<$matcher> is an exact model-id string (matched with C<eq>) or a C<qr//>
regex (matched against C<chat_model>) — model ids come in families and, through
aggregators, carry a C<provider/> prefix, so a regex catches the routed backend
id too. C<$rule> is a B<coderef> (the concrete seam — deliberately not a
constraint DSL) invoked as C<< $self->$rule(%request) >> with C<has_tools>,
C<tool_choice_forced> (true for a C<tool_choice> of C<any>/C<required> or a
named tool, as the caller passed it), C<response_format> (the one that goes on
the wire: the per-request value, else the engine's C<response_format>
attribute) and C<streaming>; it C<croak>s when the request hits the combination
the model rejects.

Where the rule lives depends on what the constraint belongs to. Groq and
Cerebras reject C<tools> alongside a structured-output C<response_format> across
every model they serve — a property of the serving stack — so each declares an
all-models (C<qr//>) rule by overriding this method. SGLang does the same for a
forced C<tool_choice> combined with a C<response_format>. A constraint that belonged
to one model would instead be keyed on that model id or family regex, leaving a
sibling model on the same engine unaffected. The default is an empty list, so an
engine that constrains nothing pays nothing.

=head2 simple_chat_f

    # Traditional Future style
    my $response = $engine->simple_chat_f(@messages)->get;

    # With async/await (recommended)
    use Future::AsyncAwait;
    async sub my_chat {
        my $response = await $engine->simple_chat_f(@messages);
        return $response;
    }

Async version of L</simple_chat>. Returns a L<Future> that resolves to the
response text. The HTTP backend comes from L<Langertha::Role::AsyncHTTP>:
L<Net::Async::HTTP> when installed (loaded lazily on first call), otherwise a
synchronous L<LWP::UserAgent> fallback under which the call blocks and several
C<_f> calls run one after another rather than concurrently.

For requests that need named arguments (tools, tool_choice,
response_format, etc.) use L</chat_f>; C<simple_chat_f> delegates to it.

=head2 chat_f

    my $response = await $engine->chat_f(
      messages       => [ ... ],
      tools          => [ $tool, ... ],
      tool_choice    => { type => 'tool', name => 'extract' },
      response_format => { ... },
      temperature    => 0.7,
      max_tokens     => 512,
      # any other engine-specific extras pass straight through
    );

Async I<single-turn> chat with named arguments. Returns a L<Future>
resolving to a L<Langertha::Response>. The caller is responsible for
acting on any C<tool_calls> the engine emits — C<chat_f> does not
loop. For the multi-turn MCP tool-calling loop use
L<Langertha::Role::Tools/chat_with_tools_f> instead.

C<tools> in C<chat_f> can mix L<Langertha::Tool> objects,
L<Langertha::ServerTool> objects and HashRefs of any provider shape (OpenAI,
Anthropic, MCP, Gemini, provider built-ins). Before the request is built,
each item is put into the engine's C<tool_wire_format> in place, keeping
the caller's order (L<Langertha::Tool/request_list>, the same path
L</chat_stream_realtime_f> takes): an object goes through its C<to>; a
hash already in the wire's shape goes out verbatim, extras such as
C<function.strict> and C<cache_control> included; a function-tool hash in
another shape (for example an MCP tool with C<inputSchema>) is converted;
built-ins and unknown typed items go out verbatim for the provider to
judge. On Gemini all function declarations share one
C<functionDeclarations> entry. The Responses envelope decides per item
itself (L<Langertha::Role::ResponsesCompatible>). A
C<Langertha::ServerTool> croaks on an engine that does not
C<supports('server_tools')>.

On a C<hermes> engine (L<Langertha::Role::HermesTools>) a C<chat_f> call is
one turn of L<Langertha::Role::Tools/chat_with_tools_f>: the tools go into a
leading system message built from C<hermes_tool_prompt>, in MCP shape, and
the body carries no C<tools> key. Only function tools can go into the
prompt: a built-in or other non-function item croaks there instead of going
out verbatim. C<tool_choice> is never sent there: C<none> withholds the
tools (no tool prompt; a warning says so), and any value other than
C<auto> is ignored with a warning, as the prompt cannot force a tool
(on L<Langertha::Engine::NousResearch> a forced named tool takes the
C<json_schema> rewrite described below instead). On NousResearch, tools
together with a C<json_schema> C<response_format> send both the schema prompt
and the tool prompt.
C<E<lt>tool_callE<gt>> blocks in the reply land on
L<Langertha::Response/tool_calls> and are removed from C<content>; a block
that carries no call (no valid JSON object with a C<name>) stays in
C<content> as the model wrote it. When calls were lifted and the reply's
C<finish_reason> was C<stop> or absent, it reads C<tool_calls>
(L<Langertha::Response/raw> keeps the provider's value); any other value, such
as C<length>, stays.

A C<tool_choice> goes on the wire only as the engine's C<tool_choice_*>
capabilities allow. Where the engine does not
C<supports('tool_choice_E<lt>kindE<gt>')> for the choice's kind, C<auto> is
dropped silently, C<none> withholds the request's tools instead (with a
warning when there were tools to withhold), and a forced choice is dropped
with a warning, the model then decides; a forced
named tool that the C<json_schema> rewrite below can take is rewritten
instead. Likewise C<parallel_tool_use> reaches the wire only where the engine
C<supports('parallel_tool_use')>; a value you set elsewhere is dropped with a
warning.

These drop warnings (and the C<temperature> drops of
L<Langertha::Role::Temperature>) name the line of your own call to C<chat_f>,
C<simple_chat_f>, C<chat_request> and the like, not a line inside Langertha;
code running inside an event-loop callback gets whatever location Carp finds.
A value that comes from an engine attribute is the same on every request, so
its drop warns once per engine instance; a value passed with the request warns
on every request.

A C<model> passed to C<chat_f> is no control: it replaces the model field of
the request body, or, on engines that carry the model in the URL
(L<Langertha::Engine::Gemini>, L<Langertha::Engine::AKI>), the model named in
the URL, but every model-scoped decision is still taken for the engine's C<chat_model> — the
capability picture L<Langertha::Role::Capabilities/supports> answers, the
C<model_capability_exclusions> rules, the reasoning profile, the temperature
gate for reasoning models, a per-model C<tool_wire_format> and reasoning
prompt (L<Langertha::Engine::NousResearch>) and per-model body details such as the
completion-length key and the default response size. When the override
differs from C<chat_model> and one of those decisions that the request uses
would come out differently for it, C<chat_f> warns and names the decisions;
the request is sent unchanged. For a different model, use an engine whose
C<chat_model> is that model.

The canonical per-request controls (karr #46) are normalized like
C<messages>/C<tools> instead of being spread as raw target-wire kwargs:
C<temperature>, C<max_tokens>, C<response_format>, C<seed>,
C<parallel_tool_use>, C<reasoning_effort>, C<thinking_budget>,
C<prompt_cache>, C<prompt_cache_ttl> and C<prompt_cache_key>. Each engine's
C<chat_request> places them on its own wire (Ollama C<options>, Gemini
C<generationConfig>, Anthropic C<output_config>+C<thinking>, ...) via the same
value objects the engine attributes use, so the same call is correct across
engine families. A per-request control beats the configured engine attribute
on a per-key basis. Any other key still passes straight through to the wire as
before.

When the caller asks for a forced named tool on an engine that cannot
do native named-tool-forcing but supports C<json_schema>
response_format (for example L<Langertha::Engine::Perplexity> and
L<Langertha::Engine::NousResearch>), the
request is automatically rewritten to use the JSON Schema path and the
response is loose-parsed; the resulting L<Langertha::Response> exposes
the parsed arguments via L<Langertha::Response/tool_call_args> with
C<synthetic =E<gt> 1> on the synthesized tool_call entry.

The rewrite takes the request's C<response_format>. Passing a forced named
tool and a C<response_format> other than C<text> in the same C<chat_f> call
therefore croaks: the two ask for different output, so pick one. When the
C<response_format> only comes from the engine attribute, the forced tool wins
for that request and a warning says so. A C<text> response_format is replaced
silently.

On a C<hermes> engine that takes C<response_format>
(L<Langertha::Engine::NousResearch>), every C<json_schema> response format
(the rewritten one, one passed to C<chat_f> or
L</chat_stream_realtime_f>, or the engine's own) also goes into a leading
system message built from L<Langertha::Role::HermesTools/hermes_schema_prompt>,
for a backend that ignores C<response_format>.

=head2 simple_chat_stream_f

    my ($content, $chunks) = $engine->simple_chat_stream_f(@messages)->get;

Async streaming without a real-time callback. Convenience wrapper around
L</simple_chat_stream_realtime_f> with C<undef> as the callback. Returns a
L<Future> that resolves to C<($content, \@chunks, \%timing, $thinking)> — the
same tuple as L</chat_stream_realtime_f>; the trailing elements are additive.

=head2 aggregate_tool_calls

    my $tool_calls = $engine->aggregate_tool_calls( $chunks );

Walks an ArrayRef of L<Langertha::Stream::Chunk> objects and returns
the flat list of L<Langertha::ToolCall> objects collected from any
chunks that carry C<tool_calls>, in stream order. Returns an empty ArrayRef if
none of the chunks emitted tool calls.

This is the streaming counterpart to L<Langertha::Response/tool_calls>: for a
streamed response it returns the same calls, as equal L<Langertha::ToolCall>
objects, that the non-streaming reply of that response carries. Each dialect's
C<parse_stream_chunk> assembles its fragments (Chat-Completions
C<delta.tool_calls> per C<index>, Anthropic C<input_json_delta> per content
block) in per-stream state and puts every finished call on exactly one chunk,
so this helper only collects and never sees a call twice. See
L<Langertha::Stream::Chunk/tool_calls> for the chunk each dialect uses.

=head2 aggregate_thinking

    my $thinking = $engine->aggregate_thinking( $chunks );

Walks an ArrayRef of L<Langertha::Stream::Chunk> objects and concatenates the
C<thinking> text of every chunk that carries one, in stream order — the way
L</chat_stream_realtime_f> concatenates C<content>. Returns C<undef> when no
chunk carried thinking, so the streamed result mirrors
L<Langertha::Response/thinking> (also C<undef> when the engine surfaced none).

This is the streaming counterpart to the native C<thinking> that
L<Langertha::Response> exposes on the non-streaming path. Each dialect stream
parser fills C<Stream::Chunk-E<gt>thinking> from its own delta spelling (see
L<Langertha::Stream::Chunk/thinking>); this helper just reassembles the
fragments.

=head2 aggregate_usage

    my $usage = $engine->aggregate_usage( $chunks );
    my $counts = Langertha::Usage->from_hash($usage) if $usage;

Walks an ArrayRef of L<Langertha::Stream::Chunk> objects and returns the
C<usage> HashRef of the last chunk that carries one, or C<undef> when none
did. Streamed usage is cumulative, so that is the whole stream's usage. Use it
rather than reading the C<is_final> chunk: an OpenAI-compatible stream
requested with C<stream_options =E<gt> { include_usage =E<gt> 1 }> reports
its usage on a content-less chunk after the final one.

=head2 simple_chat_stream_realtime_f

    # With async/await (recommended)
    use Future::AsyncAwait;
    async sub my_stream {
        my ($content, $chunks) = await $engine->simple_chat_stream_realtime_f(
            sub { print shift->content },
            @messages
        );
        return $content;
    }

    # Traditional Future style
    my $future = $engine->simple_chat_stream_realtime_f($callback, @messages);
    my ($content, $chunks) = $future->get;

Async streaming with real-time callback. C<$callback> is called with each
L<Langertha::Stream::Chunk> as it arrives from the server (each chunk may carry
incremental C<thinking>). Returns a L<Future> that resolves to
C<($content, \@chunks, \%timing, $thinking)>, the same tuple as
L</chat_stream_realtime_f>; the trailing elements are additive, so callers
destructuring only C<($content, \@chunks)> keep working.

This is the recommended method for real-time streaming in async applications.
Pass C<undef> as the callback (or use L</simple_chat_stream_f>) if you only
need the final result.

This is a thin wrapper around L</chat_stream_realtime_f>; existing callers
keep working unchanged. For requests that need named arguments (tools,
tool_choice, response_format, temperature, max_tokens, etc.) use
L</chat_stream_realtime_f> directly.

=head2 chat_stream_realtime_f

    my ($content, $chunks) = await $engine->chat_stream_realtime_f(
        messages       => [ ... ],
        chunk_callback => sub { print shift->content },
        temperature    => 0.7,
        max_tokens     => 512,
        # any other engine-specific extras pass straight through
    );

Async I<single-turn> streaming chat with named arguments. C<messages> is
required (ArrayRef or a single message); C<chunk_callback> is called with each
L<Langertha::Stream::Chunk> as it arrives from the server. The canonical
per-request controls (karr #46) — C<temperature>, C<max_tokens>,
C<response_format>, C<seed>, C<parallel_tool_use>, C<reasoning_effort>,
C<thinking_budget>, C<prompt_cache>, C<prompt_cache_ttl>, C<prompt_cache_key> —
are extracted and handed to L</chat_stream_request> under C<controls>, exactly
as in L</chat_f>. C<tools> is shaped for the engine's C<tool_wire_format> item
by item, exactly as in L</chat_f> (L<Langertha::Tool/request_list>):
L<Langertha::Tool> objects are serialized, hashes already in the wire's shape
(built-ins and extras included) pass through verbatim, other function-tool
hashes (MCP C<inputSchema>, canonical C<input_schema>) are converted, and on
Gemini all declarations are merged into one C<functionDeclarations> entry.
C<tool_choice> is decided against the C<tool_choice_*> capabilities as in
L</chat_f> (without the C<json_schema> rewrite); any engine-specific extras
pass through. Tool calls the
model streams are collected with L</aggregate_tool_calls>. On a C<hermes>
engine the tools ride the system prompt and C<tool_choice> is handled as in
L</chat_f>. The text inside the C<E<lt>tool_callE<gt>> blocks the model writes
(L<Langertha::Role::HermesTools/hermes_call_tag>) is not streamed, even when a
tag is split across chunks, and chunks that carried only such text are not
delivered; the calls land as L<Langertha::ToolCall> objects on the final chunk,
as L</chat_f> puts them on L<Langertha::Response/tool_calls>, and that chunk's
C<finish_reason> reads C<tool_calls> where L</chat_f>'s would (over C<stop> or
none). A block that carries no call is streamed as text where it stood, as
L</chat_f> keeps it in C<content>, and a call tag inside C<E<lt>thinkE<gt>>
text is no call. Markup that is unclosed when the stream ends is streamed as
text and gives no call. A stream that ends without a final chunk gets a
closing chunk for the text still held back and any calls. A per-request
C<model> warns as in L</chat_f> when it would flip a model-scoped decision.

Returns a L<Future> that resolves to C<($content, \@chunks, \%timing,
$thinking)> where C<$content> is the full concatenated text, C<\@chunks> the
collected L<Langertha::Stream::Chunk> objects, C<\%timing> carries
C<ttft_seconds> and C<total_seconds>, and C<$thinking> is the aggregated
chain-of-thought (C<undef> when the engine surfaced none), assembled from the
per-chunk C<thinking> deltas by L</aggregate_thinking> so it matches the native
L<Langertha::Response/thinking> of the non-streaming L</chat_f> on the same
engine and prompt. The trailing element is additive: callers destructuring only
the first three keep working.

If C<chunk_callback> dies, or a stream line cannot be parsed, the returned
future B<fails> with that exception on every HTTP backend, and no further
chunk reaches C<chunk_callback>. How the rest of the transfer ends depends on
the backend (L<Langertha::Role::AsyncHTTP>):

=over

=item * L<Net::Async::HTTP>: the exception never escapes the event loop. The
request is cancelled on the next loop iteration (unless the response already
ended within the same read), and the engine goes on serving requests. Like any
cancelled L<Net::Async::HTTP> request this closes its connection; the client
Langertha builds does not pipeline, so requests queued behind it on the same
engine wait for a connection of their own and are unaffected.

=item * the synchronous L<Langertha::Request::SyncHTTP> fallback: LWP stops
reading at once.

=item * an injected client whose futures have no C<loop> (or one without
C<later>, from another event system): the rest of the body is read and
discarded, and the future fails when the response ends. If the transfer then
fails at the transport level, the future still fails with the original
exception.

=back

Cancelling the returned future cancels the HTTP request.

This is the streaming counterpart to L</chat_f>. Unlike L</chat_f> it does
not apply the forced-tool fallback (rewriting a named C<tool_choice> into a
C<response_format> on engines without C<tool_choice_named>); synthesizing a
C<tool_calls> entry from the accumulated stream text is a separate follow-up
concern.

C<response_format> is honored on the streaming path only where the engine
has a native wire form (Gemini C<responseJsonSchema>, Ollama C<format>,
OpenAI-compatible C<response_format>). Anthropic-family engines have no
native form and their synthesized-tool rewrite has no streaming lift, so
they consume the key and croak — use L</chat_f> for structured output there.

=head2 content_format

    my $fmt = $engine->content_format;
    # 'openai' | 'anthropic' | 'gemini' | 'responses' | 'ollama' | 'lmstudio'

Wire format for multimodal content blocks. Controls how
L<Langertha::Content> objects embedded in a message's C<content> arrayref
are serialized during L</chat_messages>. Defaults to C<'openai'>; overridden
by L<Langertha::Engine::AnthropicBase>, L<Langertha::Engine::Gemini>,
L<Langertha::Role::ResponsesCompatible> (C<responses>: C<input_text> /
C<input_image> parts, C<output_text> on assistant turns),
L<Langertha::Engine::Ollama> (C<ollama>: text joined into a string content,
images lifted into the message C<images> array) and
L<Langertha::Engine::LMStudio> (C<lmstudio>).

A message whose content is a plain string is passed through unchanged on
every format; so is an arrayref without any L<Langertha::Content> object,
except on C<gemini> (always turned into parts) and C<ollama> (text parts
always joined into a string, C<image_url> parts lifted into C<images>).

=head2 engine_capabilities

    my $caps = $engine->engine_capabilities;
    if ( $caps->{tool_choice_named} ) { ... }

Returns a HashRef of capability flags so callers can avoid passing
parameters the engine cannot honour.

The base implementation reports only what L<Langertha::Role::Chat>
itself provides (C<chat>). Every other capability-bearing role
(L<Langertha::Role::Tools>, L<Langertha::Role::ResponseFormat>,
L<Langertha::Role::Streaming>, L<Langertha::Role::Embedding>,
L<Langertha::Role::Transcription>, L<Langertha::Role::ImageGeneration>,
L<Langertha::Role::HermesTools>, L<Langertha::Role::Temperature>,
L<Langertha::Role::Seed>, L<Langertha::Role::ContextSize>,
L<Langertha::Role::ResponseSize>, L<Langertha::Role::SystemPrompt>,
L<Langertha::Role::ParallelToolUse>) hangs its own contribution into
this method via C<around engine_capabilities>. Engines override (also
via C<around>) when the wire reality differs from the role inventory
— for example to clear C<tool_choice_named> on providers that only
accept string forms.

Common keys produced by the bundled roles:

=over

=item * C<chat> — C<simple_chat>/C<simple_chat_f> work

=item * C<streaming> — C<chat_stream_request> is wired up

=item * C<tools_native> — engine accepts a C<tools> array on the wire

=item * C<tools_hermes> — tools are injected via Hermes-style XML
prompt rather than (or in addition to) the native API

=item * C<tool_choice_auto> / C<tool_choice_any> / C<tool_choice_none> —
which string-form C<tool_choice> values are accepted

=item * C<tool_choice_named> — C<{type =E<gt> 'tool', name =E<gt> '...'}>
forcing works (possibly translated internally — Gemini routes named
tools through C<allowed_function_names>, for example)

=item * C<response_format_json_object> — C<{type =E<gt> 'json_object'}>

=item * C<response_format_json_schema> — JSON Schema structured output

=item * C<embedding>, C<transcription>, C<image_generation> — auxiliary
capabilities matching the corresponding roles

=item * C<temperature>, C<seed>, C<context_size>, C<response_size>,
C<system_prompt>, C<parallel_tool_use> — generation-parameter knobs
the engine will honour

=back

Callers should treat the hash as advisory — a missing key means
"unknown / unsupported", a true value means "the engine claims it
will honour this".

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Langfuse> - Observability integration (composed by this role)

=item * L<Langertha::Role::SystemPrompt> - System prompt injection

=item * L<Langertha::Role::Streaming> - Stream parsing (SSE / NDJSON)

=item * L<Langertha::Role::Tools> - Tool calling on top of chat

=item * L<Langertha::Role::Models> - Model selection

=item * L<Langertha::Stream> - Stream iterator

=item * L<Langertha::Stream::Chunk> - Individual stream chunk

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
