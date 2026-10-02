package Langertha::Response;
# ABSTRACT: LLM response with metadata
our $VERSION = '0.503';
use Moose;
use Langertha::Moment;
use Langertha::ServerToolCall;
use Langertha::ToolCall;
use Langertha::Usage;

use overload
  '""' => sub { $_[0]->content },
  # An object that exists is true. Without this, `fallback => 1` derives bool
  # from the '""' overload, and a Response whose content is the empty string --
  # a tool-call-only reply -- would be false. See "Boolean context" (karr #100).
  'bool' => sub { 1 },
  fallback => 1;


has content => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);


has raw => (
  is => 'ro',
  isa => 'HashRef',
  predicate => 'has_raw',
);


has id => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_id',
);


has model => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_model',
);


has finish_reason => (
  is => 'ro',
  isa => 'Maybe[Str]',
  predicate => 'has_finish_reason',
);


has usage => (
  is => 'ro',
  isa => 'Maybe[Langertha::Usage]',
  predicate => 'has_usage',
);


has timing => (
  is => 'ro',
  isa => 'Maybe[HashRef]',
  predicate => 'has_timing',
);


sub has_ttft {
  my ($self) = @_;
  my $t = $self->timing or return 0;
  return exists $t->{ttft_seconds} && defined $t->{ttft_seconds} ? 1 : 0;
}

sub ttft_seconds {
  my ($self) = @_;
  my $t = $self->timing or return undef;
  return $t->{ttft_seconds};
}

sub has_total {
  my ($self) = @_;
  my $t = $self->timing or return 0;
  return exists $t->{total_seconds} && defined $t->{total_seconds} ? 1 : 0;
}

sub total_seconds {
  my ($self) = @_;
  my $t = $self->timing or return undef;
  return $t->{total_seconds};
}



has created => (
  is => 'ro',
  isa => 'Maybe[Langertha::Moment]',
  predicate => 'has_created',
);


has cached_tokens => (
  is => 'ro',
  isa => 'Maybe[Int]',
  predicate => 'has_cached_tokens',
);


has thinking => (
  is => 'ro',
  isa => 'Maybe[Str]',
  predicate => 'has_thinking',
);

has refusal => (
  is => 'ro',
  isa => 'Maybe[Str]',
  predicate => 'has_refusal',
);

has rate_limit => (
  is => 'ro',
  isa => 'Maybe[Langertha::RateLimit]',
  predicate => 'has_rate_limit',
);

has tool_calls => (
  is        => 'ro',
  isa       => 'Maybe[ArrayRef[Langertha::ToolCall]]',
  predicate => 'has_tool_calls',
);

has server_tool_calls => (
  is        => 'ro',
  isa       => 'Maybe[ArrayRef[Langertha::ServerToolCall]]',
  predicate => 'has_server_tool_calls',
);

has probes => (
  is        => 'ro',
  isa       => 'Maybe[HashRef]',
  predicate => 'has_probes',
);

has citations => (
  is        => 'ro',
  isa       => 'Maybe[ArrayRef]',
  predicate => 'has_citations',
);

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $params = $class->$orig(@args);

  # Coerce the usage block to a Langertha::Usage object first (karr #43): the
  # value object owns inbound wire-spelling parsing (ADR 0001 / 0018 home 1),
  # including the prompt-cache read/write counts and the two wire spellings each
  # carries. Response no longer hand-parses any usage spelling itself.
  if ( defined $params->{usage} ) {
    $params->{usage} = ( ref( $params->{usage} ) && eval { $params->{usage}->isa('Langertha::Usage') } )
      ? $params->{usage}
      : Langertha::Usage->from_hash( $params->{usage} );
  }

  # Response keeps its public cached_tokens attribute (karr #61) but no longer
  # carries the provider wire spellings — those moved onto Langertha::Usage
  # (karr #130). Surface the prefix-cache read-back by lifting the PARSED count
  # off the Usage object, so ANY Response assembled from provider usage —
  # including one built from a streamed final chunk's usage — exposes it. Only
  # when defined (cached_tokens => 0 is a real count). An explicit cached_tokens
  # parameter always wins.
  if ( !exists $params->{cached_tokens}
       && ref( $params->{usage} )
       && eval { $params->{usage}->isa('Langertha::Usage') }
       && defined $params->{usage}->cached_tokens ) {
    $params->{cached_tokens} = $params->{usage}->cached_tokens;
  }

  # Accept legacy ArrayRef[HashRef] input by upgrading to ToolCall objects.
  if ( ref( $params->{tool_calls} ) eq 'ARRAY' ) {
    $params->{tool_calls} = [
      map {
        ref($_) && eval { $_->isa('Langertha::ToolCall') }
          ? $_
          : Langertha::ToolCall->new(
              name      => ( $_->{name} // '' ),
              arguments => ( ref( $_->{arguments} ) eq 'HASH' ? $_->{arguments} : {} ),
              id        => ( $_->{id} // '' ),
              synthetic => ( $_->{synthetic} ? 1 : 0 ),
              # Carry the k345 undecodable flag through the legacy-hash upgrade
              # (the hermes lift reduces a ToolCall to this shape) so the tool
              # loop still answers a bad call an error result -- karr k350.
              ( $_->{arguments_undecodable}
                ? ( arguments_undecodable => 1,
                    ( defined $_->{arguments_error} ? ( arguments_error => $_->{arguments_error} ) : () ) )
                : () ),
            );
      } @{ $params->{tool_calls} }
    ];
  }

  # created arrives in two shapes and must survive a third: an epoch integer
  # on the OpenAI-compatible wire, an RFC3339 string with nanoseconds from
  # Ollama, and anything at all from a shim nobody has met yet. Normalizing
  # here rather than in each engine means a producer only has to hand over
  # what the provider sent (ADR 0001's inbound half: the value object owns the
  # parse, the engine carries no per-shape code).
  #
  # from_wire never dies, and an unreadable value deletes the key rather than
  # setting it to undef -- created is metadata, and a timestamp the parser
  # cannot read must not fail the constructor for a response that is otherwise
  # perfectly good (GitHub #3, karr #92 / #117).
  if ( exists $params->{created} ) {
    my $moment = Langertha::Moment->from_wire( $params->{created} );
    if ( defined $moment ) {
      $params->{created} = $moment;
    }
    else {
      delete $params->{created};
    }
  }

  return $params;
};



sub tool_call {
  my ( $self, $name ) = @_;
  my $tcs = $self->tool_calls or return undef;
  return undef unless @$tcs;
  return $tcs->[0] unless defined $name;
  for my $tc (@$tcs) {
    return $tc if $tc->name eq $name;
  }
  return undef;
}


sub tool_call_args {
  my ( $self, $name ) = @_;
  my $tc = $self->tool_call($name) or return undef;
  return $tc->arguments;
}





sub clone_with {
  my ( $self, %overrides ) = @_;
  my %args = ( content => $self->content );
  for my $attr ( $self->meta->get_all_attributes ) {
    next unless $attr->has_predicate;
    next unless $attr->get_read_method;
    next if $attr->is_required;
    my $name = $attr->name;
    next if $name eq 'content';
    next if exists $overrides{$name};
    $args{$name} = $self->$name if $self->${\"has_$name"};
  }
  return ( ref $self )->new( %args, %overrides );
}



sub to_hash {
  my ($self) = @_;
  return {
    content => $self->content,
    ( $self->has_id            ? ( id            => $self->id )            : () ),
    ( $self->has_model         ? ( model         => $self->model )         : () ),
    ( $self->has_finish_reason ? ( finish_reason => $self->finish_reason ) : () ),
    ( $self->has_usage         ? ( usage         => $self->usage )         : () ),
    ( $self->has_timing        ? ( timing        => $self->timing )        : () ),
    # Numified on purpose: created is a Langertha::Moment, and the bounded
    # Response hash (karr #50) is the interop surface that has emitted an
    # epoch number for this key since the attribute existed. The sub-seconds
    # the object carries stay reachable on the object and under raw; they are
    # not in this hash, and were never in it.
    ( $self->has_created       ? ( created       => 0 + $self->created )   : () ),
    ( $self->has_cached_tokens ? ( cached_tokens => $self->cached_tokens ) : () ),
    ( $self->has_thinking      ? ( thinking      => $self->thinking )      : () ),
    ( $self->has_refusal       ? ( refusal       => $self->refusal )       : () ),
    ( $self->has_rate_limit    ? ( rate_limit    => $self->rate_limit )    : () ),
    ( $self->has_tool_calls    ? ( tool_calls    => $self->tool_calls )    : () ),
  };
}

sub TO_JSON { shift->to_hash }

sub prompt_tokens {
  my ( $self ) = @_;
  my $u = $self->usage or return undef;
  return $u->input_tokens;
}


sub completion_tokens {
  my ( $self ) = @_;
  my $u = $self->usage or return undef;
  return $u->output_tokens;
}


sub total_tokens {
  my ( $self ) = @_;
  my $u = $self->usage or return undef;
  return $u->total_tokens;
}


sub requests_remaining {
  my ( $self ) = @_;
  my $rl = $self->rate_limit or return undef;
  return $rl->requests_remaining;
}


sub tokens_remaining {
  my ( $self ) = @_;
  my $rl = $self->rate_limit or return undef;
  return $rl->tokens_remaining;
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Response - LLM response with metadata

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $response = $engine->simple_chat('Hello');

    # Stringifies to content (backward compatible)
    print $response;
    print "Response: $response\n";

    # Access metadata
    say $response->model;
    say $response->id;
    say $response->finish_reason;

    # Token usage
    say "Prompt tokens: ", $response->prompt_tokens;
    say "Completion tokens: ", $response->completion_tokens;
    say "Total tokens: ", $response->total_tokens;

    # Full raw response
    use Data::Dumper;
    print Dumper($response->raw);

=head1 DESCRIPTION

Wraps LLM response text content together with all available metadata
from the API response. Uses C<overload> for string context so existing
code treating responses as plain strings continues to work.

=head2 Boolean context — a Response is always true

C<Langertha::Response> overloads C<bool> to a constant true: the object exists,
so it is true, whatever L</content> happens to hold. This is not cosmetic. With
only the C<""> overload and C<fallback =E<gt> 1>, Perl derives boolean context
from stringification, so a Response whose content is the empty string was
B<false> — and that is exactly the shape of a tool-call-only reply (an
Anthropic turn that is pure C<tool_use>, an Ollama reply with empty
C<message.content> plus a C<tool_calls> array), as well as of a model that
legitimately answers C<"0">. Callers writing

    my $resp = $engine->simple_chat(@messages);
    if ($resp) { ... }             # entered now; silently skipped before
    $resp or die "no response";    # no longer dies on a perfectly good Response

used to drop precisely the responses that carry L</tool_calls>. Decided in
karr #100.

Asking whether the B<content> is empty is a different question, and keeps its
own spelling:

    if ( length "$resp" )         { ... }   # the model produced text
    if ( $resp->has_tool_calls )  { ... }   # the model emitted tool calls

The C<""> overload is unchanged — C<"$response"> is still L</content>, and
C<eq>, C<ne> and concatenation keep routing through it. The change also makes
this class agree with the rest of the distribution: L<Langertha::ToolCall>,
L<Langertha::Usage> and L<Langertha::Stream::Chunk> are already
true-because-they-exist. L<Langertha::Result> got the same treatment for the
same reason.

=head2 TO_JSON — the canonical, bounded representation

C<Langertha::Response> carries a C<TO_JSON> (delegating to L</to_hash>) so
that every L<JSON::MaybeXS> backend encodes a bare Response identically when
C<convert_blessed> is enabled. Decided in karr #50, after karr #43 fixed the
permanent shape of the class (L</usage> is now a L<Langertha::Usage> object
with its own C<TO_JSON>).

The shape is deliberately bounded: L</content> plus the metadata fields that
are present (L</id>, L</model>, L</finish_reason>, L</usage>, L</timing>,
L</created>, L</thinking>, L</refusal>, L</rate_limit>, L</tool_calls>).
L</raw> and L</probes> are B<not> included — L</raw> is the entire provider payload
(duplicating every other field, including the echoed prompt) and L</probes>
can hold megabytes of tensor data. A C<TO_JSON> that kept them would blow up
every trace it touched; one that dropped them keeps the object's JSON form
useful without silently discarding the fields a consumer is likely to want.

The string overload is unchanged: C<"$response"> still returns
L</content>, and the C<TO_JSON> does not replace it.

=for stopwords Cpanel

B<Backend uniformity is the point.> Before this method existed, what an
encoder with C<convert_blessed> did with a bare Response depended on the
L<JSON::MaybeXS> backend: L<Cpanel::JSON::XS> fell back to the C<"">
overload and emitted the content string, while L<JSON::XS> and L<JSON::PP>
threw. Consumers on Cpanel silently got C<{"response":"hello"}>, consumers
on JSON::XS/JSON::PP got an exception — the same application behaved
differently on two machines. With C<TO_JSON> all three emit the canonical
hash. The Cpanel behavior was never a contract (it is gone now); callers
that want the content string should stringify explicitly.

=head2 content

The text content of the response. Required.

=head2 raw

The full parsed API response as a HashRef.

=head2 id

Provider-specific response ID.

=head2 model

The actual model used for the response.

=head2 finish_reason

Why the response ended: C<stop>, C<end_turn>, C<length>, C<tool_calls>, etc.
Provider-specific values are preserved as-is.

=head2 usage

Token usage as a L<Langertha::Usage> object. For backward compatibility
C<BUILDARGS> upgrades a plain HashRef (the raw provider usage block) into a
C<Langertha::Usage> automatically; new code can construct the object
directly. The object overloads C<%{}>, so existing callers that dereference
C<< $response->usage->{prompt_tokens} >> keep working — the overload returns
the provider-verbatim hash (see L<Langertha::Usage/"HASH OVERLOAD">).

=head2 timing

Timing information as a HashRef. Holds client-measured
C<ttft_seconds> and C<total_seconds> (Float, seconds) on every engine,
plus provider-native stage durations that engines may populate
engine-specifically — e.g. Ollama's C<total_seconds>, C<load_seconds>,
C<prompt_eval_seconds>, C<eval_seconds> (all Float, seconds), with its
original C<*_duration> keys in nanoseconds preserved for backward
compatibility. See L</ttft_seconds> and L</total_seconds> for the
standard accessors.

=for stopwords first-write-wins

B<Merge policy: first-write-wins.> When both a provider-supplied duration
(e.g. Ollama's C<total_seconds> derived from C<total_duration>) and a
client-measured duration (Langertha::Role::Chat wrapper) are available
for the same key, the provider value wins. See
L<Langertha::Role::Chat/_merge_timing_field> and ADR 0011 in
F<docs/adr/0011-response-timing-seam.md> for the rationale — server-side
duration excludes network jitter and is the better signal for
model-latency observability. Callers that need the client wall-clock
(RTT, queue, TLS handshake, network back) should read
C<$response-E<gt>timing> directly: client-measured deltas are not
written under C<ttft_seconds> / C<total_seconds> when the provider
already populated those keys, but L<Langertha::Role::Chat> does not
delete other timing entries on conflict.

=head2 ttft_seconds

    my $ttft = $response->ttft_seconds;     # Float, undef when unmeasured
    if ($response->has_ttft) { ... }

Returns time-to-first-token in seconds (Float), measured client-side
between request send and the first streamed chunk. C<undef> for sync
(non-streaming) calls and for engines that did not record the metric.
Use C<has_ttft> to test availability without warnings.

=head2 total_seconds

    my $total = $response->total_seconds;   # Float, undef when unmeasured
    if ($response->has_total) { ... }

Returns end-to-end request time in seconds (Float). On engines that
populate the field from a provider-native metric (currently Ollama,
from C<total_duration>), this is the B<server-reported> duration —
time the model actually spent generating, excluding network jitter.
On engines where only the client wrapper measured, it is the
B<wall-clock> duration from before C<user_agent-E<gt>request> (sync) or
C<do_request> (async) to after the response body was fully consumed.

=for stopwords RTT

The two are not interchangeable: server-time answers "how fast is the
model", wall-clock answers "how long did my call take end-to-end".
Callers that need the wall-clock RTT should read C<$response-E<gt>timing>
directly (the client wrapper writes its measurement under a sibling key
when the provider has not claimed C<total_seconds>; when both are
present the provider value wins — see L</timing>).

C<undef> when the engine did not record the metric. Use C<has_total>
to test availability without warnings.

=head2 created

The instant the provider says the response was created, as a
L<Langertha::Moment> — a L<Time::Moment> subclass, so the full civil time is
there: sub-seconds, UTC offset, and every L<Time::Moment> accessor.

B<In numeric context it is the Unix timestamp it always was.> The C<0+>
overload yields whole seconds since the epoch, so C<0 + $response-E<gt>created>,
C<< $response->created > $cutoff >> and C<< int($response->created) >> keep
returning exactly what they returned when this attribute was a C<Maybe[Int]>.
In string context it is the full ISO-8601 stamp instead — which is where the
sub-seconds are, and which is B<not> what the old C<Int> stringified to. See
L</"Comparing and printing created"> below.

Engine-agnostic by contract, and normalized here rather than per engine:
C<BUILDARGS> runs every incoming value through
L<Langertha::Moment/from_wire>, which takes the OpenAI-compatible wire's epoch
integer and Ollama's RFC3339 C<created_at> string alike. A value it cannot
read — including the C<0001-01-01T00:00:00Z> zero-value sentinel Go-based
servers emit — B<drops the field> instead of failing the constructor:
C<has_created> is then false and the response is built regardless. A timestamp
is metadata and must never take a whole reply down with it (GitHub issue #3,
karr #92 / #117).

The provider's native form always stays available verbatim under L</raw>
(C<raw.created> on the OpenAI-compatible wire, C<raw.created_at> on Ollama).

=head2 Comparing and printing created

Numeric context, arithmetic and comparison are unchanged from the old C<Int>:

    0 + $response->created                 # 1700000000
    $response->created == 1700000000       # true
    $response->created > $cutoff           # true/false, as before
    sprintf '%d', $response->created       # 1700000000
    sort { $a->created <=> $b->created } @responses

Three idioms do B<not> survive the change to an object:

=over

=item * B<String context is the stamp, not the digits.>
C<"$response-E<gt>created"> now interpolates C<2023-11-14T22:13:20Z>, so
C<eq> against the epoch digits is false and a hash keyed by C<created> re-keys
itself. Write C<0 + $response-E<gt>created> where the number is what is
wanted. This is the point of the change, not a side effect — the string form
is where the sub-seconds are.

=item * B<C<ref> and C<blessed> are no longer empty.> Code branching on
whether the field is a reference takes the other path now.

=item * B<A JSON encoder without C<convert_blessed> dies on it> — the same
way it already dies on L</usage>, L</tool_calls> and L</rate_limit>, which
have been objects for longer. With C<convert_blessed> enabled it encodes as
the epoch number, because L<Langertha::Moment> carries a C<TO_JSON> that says
so. L</to_hash> and C<TO_JSON> on the Response itself are unaffected: they
emit a plain number either way.

=back

One smaller change: C<created> is now true in boolean context even when the
stamp is the epoch zero, where the old C<Int> C<0> was false. L</has_created>
is the predicate for "did the provider report a stamp", and it is unaffected.

=head2 cached_tokens

Number of prompt tokens served from the prefix cache (the cache B<read>
count), when the provider reports it. This is the engine-agnostic back-compat
accessor: C<BUILDARGS> lifts it off the L<Langertha::Usage> object's
L<Langertha::Usage/cached_tokens>, which parses it from either wire spelling —
C<usage.prompt_tokens_details.cached_tokens> on the OpenAI-compatible wire
(SGLang with C<return_cached_tokens_details> enabled, and other servers that
emit the detail block) or C<usage.cache_read_input_tokens> on Anthropic. An
explicit C<cached_tokens> constructor parameter always wins. C<undef> when the
provider does not report a cache-read count.

The cache B<write> count has no Response accessor — read it from the usage
object as C<< $response->usage->cache_write_tokens >>
(L<Langertha::Usage/cache_write_tokens>).

=head2 tool_calls

ArrayRef of L<Langertha::ToolCall> objects extracted from the
response, when the engine produced any. Single source of truth for
"what tool calls did the model emit" — both native provider tool
calling and synthesized fallbacks (forced-name via response_format)
land here in the same shape.

For backward compatibility C<BUILDARGS> upgrades plain HashRefs
(C<{ name =E<gt> ..., arguments =E<gt> ..., id =E<gt> ..., synthetic =E<gt> ... }>)
into L<Langertha::ToolCall> objects automatically; new code should
construct the objects directly.

=head2 tool_call

    my $tc = $response->tool_call;          # first tool call
    my $tc = $response->tool_call($name);   # named lookup

Returns the L<Langertha::ToolCall> for the first tool call (or the
first matching C<$name>), or C<undef> when no tool calls were
produced.

=head2 tool_call_args

    my $args = $response->tool_call_args;            # first tool call
    my $args = $response->tool_call_args($name);     # named lookup

Returns the C<arguments> HashRef of the first tool call, or of the
first tool call matching C<$name>. Returns C<undef> when no tool
calls were produced.

=head2 server_tool_calls

ArrayRef of L<Langertha::ServerToolCall> records: the tool calls the
B<provider> ran itself during this request (a C<web_search_call>, an
C<mcp_call>, ...), in wire order, when there were any. They are deliberately
B<not> on L</tool_calls>, which lists only calls the client must execute, so
C<chat_with_tools_f> and C<chat_f> callers never try to run a web search
themselves (ADR 0003 Update k206, ADR 0030). Each record carries the item
verbatim in C<data>. Set by the Responses wire
(L<Langertha::Engine::OpenAIResponses>); C<undef> elsewhere. Survives
L</clone_with>. Not part of L</to_hash> / C<TO_JSON> (the bounded shape, like
L</citations>); read the attribute.

=head2 rate_limit

Optional L<Langertha::RateLimit> object with rate limit information from the
API response headers. Only present when the provider returns rate limit headers.

=head2 thinking

Chain-of-thought reasoning content. Populated automatically from native API
fields (DeepSeek C<reasoning_content>, Anthropic C<thinking> blocks, Gemini
C<thought> parts) or from C<E<lt>thinkE<gt>> tag filtering when
L<Langertha::Role::ThinkTag/think_tag_filter> is enabled.

=head2 refusal

The model's refusal text, when the provider reports a refusal in a field of
its own instead of as content: the OpenAI-compatible C<message.refusal> (a
structured-output request the model declined; C<content> is then empty) and a
Responses API C<refusal> content part. L</content> stays what the model
answered, usually C<''>, so check C<has_refusal> before treating an empty
reply as empty. A refusal that arrives as a stop reason (Anthropic
C<stop_reason> C<refusal>) is in L</finish_reason> instead. Survives
L</clone_with>.

=head2 citations

Search-augmented source citations, when the provider reports them. An ArrayRef
of source HashRefs (each typically carrying C<url>, C<title>, and where
available C<snippet>/C<date>). Populated by search-augmented engines that lift
them out of the raw payload — L<Langertha::Engine::Perplexity> extracts the
Agent API's C<search_results> block here (the classic Sonar top-level
C<citations[]> is gone), and the Responses wire adds the answer's
C<url_citation> annotations as C<< { url, title, start_index, end_index } >>
(the url verbatim, including OpenAI's C<?utm_source=openai>). One page is
listed once: entries are deduplicated by url, compared without C<utm_*>
query parameters, keeping the first entry and filling in only fields it
lacks. C<undef> for every engine that does not report
citations. Survives L</clone_with> so it is preserved through C<E<lt>thinkE<gt>>
tag filtering.

=head2 probes

Provider-specific probe data returned by L<Langertha::Engine::VLLMHook> when a
vLLM-Hook server captures attention or hidden-state tensors for a request. A
HashRef keyed by probe cache name (e.g. C<qk_cache>, C<hs_cache>) — each cache
holding serialized tensors as nested JSON lists, plus an optional C<config>
block of scalar metadata. C<undef> for every other engine. Survives
L</clone_with> so it is preserved through C<E<lt>thinkE<gt>> tag filtering.

=head2 clone_with

    my $new = $response->clone_with(content => $filtered, thinking => $thought);

Returns a new Response with the same attributes as the original, except for
the overrides provided. Used by L<Langertha::Role::ThinkTag> to produce a
filtered response while preserving metadata.

Every read-only attribute with a C<has_*> predicate is automatically carried
forward — the implementation iterates the Moose metaclass rather than
maintaining a hand-rolled list, so new attributes added to
L<Langertha::Response> are picked up without further changes here. Required
attributes (currently just C<content>) are handled explicitly above the
loop. Attributes whose names appear in C<%overrides> are skipped during the
copy so the override value is what reaches C<new>.

=head2 to_hash

    my $hash = $response->to_hash;

Returns the canonical, bounded HashRef representation of the response:
C<content> plus every metadata field that is present (L</id>, L</model>,
L</finish_reason>, L</usage>, L</timing>, L</created>, L</cached_tokens>,
L</thinking>, L</refusal>, L</rate_limit>, L</tool_calls>). L</raw> and
L</probes> are deliberately excluded — see L</"TO_JSON — the canonical, bounded
representation">.

L</created> is emitted as a plain epoch number (via its C<0+> overload), not
as the L<Langertha::Moment> object — the hash is a bounded interop shape and
that key has been a number since it existed.

=head2 prompt_tokens

Returns the number of prompt/input tokens. Reads the normalized
C<input_tokens> attribute of the L<Langertha::Usage> object (which
L<Langertha::Usage/from_hash> maps from C<prompt_tokens>,
C<input_tokens>, or C<prompt_eval_count>).

=head2 completion_tokens

Returns the number of completion/output tokens. Reads the normalized
C<output_tokens> attribute of the L<Langertha::Usage> object (which
L<Langertha::Usage/from_hash> maps from C<completion_tokens>,
C<output_tokens>, or C<eval_count>).

=head2 total_tokens

Returns the total token count. Reads the C<total_tokens> attribute of the
L<Langertha::Usage> object — the provider-supplied value when present,
otherwise the sum of prompt and completion tokens (lazy builder).

=head2 requests_remaining

Returns the number of requests remaining from rate limit headers, or C<undef>.

=head2 tokens_remaining

Returns the number of tokens remaining from rate limit headers, or C<undef>.

=head1 SEE ALSO

=over

=item * L<Langertha::RateLimit> - Rate limit data from response headers

=item * L<Langertha::Stream::Chunk> - Single chunk from a streaming response

=item * L<Langertha::Role::Chat> - Chat role that produces response objects

=item * L<Langertha::Role::OpenAICompatible> - Parses responses into this class

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
