package Langertha::Usage;
# ABSTRACT: Immutable value object for LLM token usage with cross-provider conversion
our $VERSION = '0.503';
use Moose;
use Scalar::Util qw( blessed looks_like_number );
use Hash::Util::FieldHash qw( fieldhash );

# The %{} overload (back-compat for `$response->usage->{...}`) hijacks every
# `$self->{attr}` deref on the object — including the ones Moose's generated
# accessors use internally. A naive overload therefore breaks the accessors
# (verified: infinite recursion / undef reads). The canonical Perl solution is
# to keep the attribute values in a field hash (keyed by object identity, not
# by the object's own hash) and route both the accessors and the overload
# through it. See "HASH OVERLOAD" below.
fieldhash my %DATA;

use overload
  '%{}' => sub { $_[0]->_as_hash },
  fallback => 1;

has input_tokens  => ( is => 'ro', isa => 'Int', default => 0 );
has output_tokens => ( is => 'ro', isa => 'Int', default => 0 );
has total_tokens  => ( is => 'ro', isa => 'Int', lazy => 1, builder => '_build_total_tokens' );

has cached_tokens      => ( is => 'ro', isa => 'Maybe[Int]', default => undef );
has cache_write_tokens => ( is => 'ro', isa => 'Maybe[Int]', default => undef );
has reasoning_tokens   => ( is => 'ro', isa => 'Maybe[Int]', default => undef );
has input_includes_cache => ( is => 'ro', isa => 'Maybe[Bool]', default => undef );
has cost_usd           => ( is => 'ro', isa => 'Maybe[Num]', default => undef );

has raw => (
  is => 'ro',
  isa => 'Maybe[HashRef]',
  default => undef,
);

# The generated accessors read $self->{attr}, which the %{} overload would
# route through _as_hash. Route them through the field hash instead.
around input_tokens  => sub { my ( $orig, $self ) = @_; $DATA{$self}{input_tokens} };
around output_tokens => sub { my ( $orig, $self ) = @_; $DATA{$self}{output_tokens} };
around total_tokens  => sub {
  my ( $orig, $self ) = @_;
  my $d = $DATA{$self} || {};
  return $d->{total_tokens} if defined $d->{total_tokens};
  return ( $d->{input_tokens} // 0 ) + ( $d->{output_tokens} // 0 );
};
around cached_tokens      => sub { my ( $orig, $self ) = @_; $DATA{$self}{cached_tokens} };
around cache_write_tokens => sub { my ( $orig, $self ) = @_; $DATA{$self}{cache_write_tokens} };
around reasoning_tokens   => sub { my ( $orig, $self ) = @_; $DATA{$self}{reasoning_tokens} };
around input_includes_cache => sub { my ( $orig, $self ) = @_; $DATA{$self}{input_includes_cache} };
around cost_usd           => sub { my ( $orig, $self ) = @_; $DATA{$self}{cost_usd} };
around raw => sub { my ( $orig, $self ) = @_; $DATA{$self}{raw} };

# The constructor's writes to $self->{attr} go through the overload and are
# lost, so the field hash is populated here from the raw constructor args.
sub BUILD {
  my ( $self, $args ) = @_;
  $DATA{$self} = {
    input_tokens       => $args->{input_tokens} // 0,
    output_tokens      => $args->{output_tokens} // 0,
    total_tokens       => $args->{total_tokens},
    cached_tokens      => $args->{cached_tokens},
    cache_write_tokens => $args->{cache_write_tokens},
    reasoning_tokens   => $args->{reasoning_tokens},
    input_includes_cache => $args->{input_includes_cache},
    cost_usd           => $args->{cost_usd},
    raw                => $args->{raw},
  };
}

# input_tokens without the cache reads and writes that are counted in it.
sub uncached_input_tokens {
  my ($self) = @_;
  my $input = $self->input_tokens;
  my $includes = $self->input_includes_cache;
  return $input if defined $includes && !$includes;
  my $rest = $input - ( $self->cached_tokens // 0 ) - ( $self->cache_write_tokens // 0 );
  return $rest < 0 ? 0 : $rest;
}

sub _build_total_tokens {
  my ($self) = @_;
  return $self->input_tokens + $self->output_tokens;
}

# Build a Usage from any of the wire-format hashrefs we know about.
sub from_hash {
  my ($class, $hash) = @_;
  return $class->new unless $hash && ref($hash) eq 'HASH';

  my $input  = $hash->{input_tokens};
  my $output = $hash->{output_tokens};
  my $total  = $hash->{total_tokens};

  $input  = $hash->{prompt_tokens}     if !defined $input  && defined $hash->{prompt_tokens};
  $input  = $hash->{prompt_eval_count} if !defined $input  && defined $hash->{prompt_eval_count};

  $output = $hash->{completion_tokens} if !defined $output && defined $hash->{completion_tokens};
  $output = $hash->{eval_count}        if !defined $output && defined $hash->{eval_count};

  # Gemini's usageMetadata spelling (the raw body, before the engine renames it).
  # Gemini counts thinking and the tool-use prompt beside the prompt and the
  # answer: totalTokenCount = promptTokenCount + toolUsePromptTokenCount +
  # candidatesTokenCount + thoughtsTokenCount. Thinking is billed as output, so
  # it is folded into output_tokens (what OpenAI's completion_tokens already
  # includes), the tool-use prompt into input_tokens. proto3 JSON omits zero
  # counts, so either half of a sum may be missing (k299).
  my $gemini_thoughts = $hash->{thoughtsTokenCount};
  if ( !defined $input && ( defined $hash->{promptTokenCount} || defined $hash->{toolUsePromptTokenCount} ) ) {
    $input = ( $hash->{promptTokenCount} // 0 ) + ( $hash->{toolUsePromptTokenCount} // 0 );
  }
  if ( !defined $output && ( defined $hash->{candidatesTokenCount} || defined $gemini_thoughts ) ) {
    $output = ( $hash->{candidatesTokenCount} // 0 ) + ( $gemini_thoughts // 0 );
  }
  $total  = $hash->{totalTokenCount}      if !defined $total  && defined $hash->{totalTokenCount};

  $input  = 0 + ($input  // 0);
  $output = 0 + ($output // 0);

  # Prompt-cache read/write counts each carry several wire spellings. OpenAI's
  # Chat wire nests both under prompt_tokens_details (cached_tokens /
  # cache_write_tokens); the Open-Responses envelope (OpenAI Responses, the
  # Perplexity Agent API) nests them under input_tokens_details, mixing the
  # OpenAI read key (cached_tokens) with the Anthropic-named counts
  # (cache_read_input_tokens / cache_creation_input_tokens); Anthropic reports
  # them flat; Gemini reports the read count as usageMetadata's
  # cachedContentTokenCount (Engine::Gemini renames it cached_content_token_count).
  # The OpenAI Chat nesting wins, then the Responses nesting, then the Anthropic
  # flat keys, then Gemini's, then the canonical flat cached_tokens that
  # Engine::AKI emits (karr #125 / #130 / #159 / k197). The read count and the
  # write count are distinct quantities — the write count is deliberately NOT
  # folded into cached_tokens. Values are read into lexicals first so a missing
  # key never autovivifies the caller's hash.
  my $ptd = $hash->{prompt_tokens_details};
  $ptd = undef unless ref($ptd) eq 'HASH';
  my $itd = $hash->{input_tokens_details};
  $itd = undef unless ref($itd) eq 'HASH';

  # Whether the cache counts are part of the input count depends on where they
  # were found, so it is recorded next to them (input_includes_cache, k263). A
  # count nested in a *_details block breaks the prompt/input total down
  # (OpenAI Chat, Open-Responses: the captures in t/data/ show input_tokens 8542
  # beside a 4394 write, 4071 beside a 4068 write); Gemini's
  # cachedContentTokenCount is part of promptTokenCount; AKI native's
  # num_cached_tokens is a subset of prompt_length. Anthropic's flat keys are
  # counted beside input_tokens, not in it.
  my ( $cached, $cached_in_input );
  if    ( $ptd && defined $ptd->{cached_tokens} )           { $cached = $ptd->{cached_tokens};                $cached_in_input = 1 }
  elsif ( $itd && defined $itd->{cached_tokens} )           { $cached = $itd->{cached_tokens};                $cached_in_input = 1 }
  elsif ( $itd && defined $itd->{cache_read_input_tokens} ) { $cached = $itd->{cache_read_input_tokens};      $cached_in_input = 1 }
  elsif ( defined $hash->{cache_read_input_tokens} )        { $cached = $hash->{cache_read_input_tokens};     $cached_in_input = 0 }
  elsif ( defined $hash->{cachedContentTokenCount} )        { $cached = $hash->{cachedContentTokenCount};     $cached_in_input = 1 }
  elsif ( defined $hash->{cached_content_token_count} )     { $cached = $hash->{cached_content_token_count};  $cached_in_input = 1 }
  elsif ( defined $hash->{cached_tokens} )                  { $cached = $hash->{cached_tokens};               $cached_in_input = 1 }

  my ( $cache_write, $write_in_input );
  if    ( $ptd && defined $ptd->{cache_write_tokens} )          { $cache_write = $ptd->{cache_write_tokens};           $write_in_input = 1 }
  elsif ( $itd && defined $itd->{cache_write_tokens} )          { $cache_write = $itd->{cache_write_tokens};           $write_in_input = 1 }
  elsif ( $itd && defined $itd->{cache_creation_input_tokens} ) { $cache_write = $itd->{cache_creation_input_tokens};  $write_in_input = 1 }
  elsif ( defined $hash->{cache_creation_input_tokens} )        { $cache_write = $hash->{cache_creation_input_tokens}; $write_in_input = 0 }
  elsif ( ref( $hash->{cache_creation} ) eq 'HASH' ) {
    # Anthropic's per-TTL split (ephemeral_5m / ephemeral_1h), which Moonshot's
    # /anthropic shim also reports; only read when the flat total is missing.
    my @tiers = grep { defined } map { $hash->{cache_creation}{"ephemeral_${_}_input_tokens"} } qw( 5m 1h );
    if (@tiers) { $cache_write = 0; $cache_write += $_ for @tiers; $write_in_input = 0 }
  }

  # One flag for both counts: every wire above nests both or flattens both. If
  # a hash ever mixes the two, "not included" wins — pricing a count on top of
  # input_tokens can overcharge, subtracting it can go below zero.
  my $includes = defined $cached_in_input ? $cached_in_input : $write_in_input;
  $includes = 0 if defined $write_in_input && !$write_in_input;

  # A canonical input_includes_cache key in the hash beats the inference from
  # the spelling. Role::AnthropicCompatible adds it for a shim that spells the
  # counts the Anthropic way but counts them inside input_tokens (AKIAnthropic,
  # ADR 0031 / k265). It only applies when a cache count was found.
  $includes = $hash->{input_includes_cache}
    if defined $includes && defined $hash->{input_includes_cache};

  # The reasoning share of output_tokens (already counted in it on every wire):
  # OpenAI Chat nests it under completion_tokens_details, Open-Responses under
  # output_tokens_details, Gemini reports thoughtsTokenCount (k299).
  my $ctd = $hash->{completion_tokens_details};
  my $otd = $hash->{output_tokens_details};
  my $reasoning;
  if    ( ref($ctd) eq 'HASH' && defined $ctd->{reasoning_tokens} ) { $reasoning = $ctd->{reasoning_tokens} }
  elsif ( ref($otd) eq 'HASH' && defined $otd->{reasoning_tokens} ) { $reasoning = $otd->{reasoning_tokens} }
  elsif ( defined $gemini_thoughts )                                { $reasoning = $gemini_thoughts }

  # What the provider says the request was billed, normalized to USD. xAI
  # reports it in the usage block as cost_in_usd_ticks (1 USD = 10^10 ticks;
  # chat/completions, Responses, images, video) and, on Responses, also as
  # cost_in_nano_usd (1 USD = 10^9); both may be null there. The finer ticks
  # win. The integers stay verbatim in raw (k354).
  # The Perplexity Agent API sends usage.cost as an object that names its unit
  # ({ currency => 'USD', total_cost => ..., input_cost => ... }, the captures
  # in t/data/perplexity_agent_*); it is read only when the currency is USD and
  # a total is there. A bare number under the generic name cost (OpenRouter's
  # credits) carries no unit, so it is not read here: the engine that knows the
  # unit copies it to the canonical cost_usd key, which is read first (k363).
  my $cost_usd;
  my $cost = $hash->{cost};
  if ( defined $hash->{cost_usd} && !ref $hash->{cost_usd} && looks_like_number( $hash->{cost_usd} ) ) {
    $cost_usd = 0 + $hash->{cost_usd};
  }
  elsif ( defined $hash->{cost_in_usd_ticks} ) { $cost_usd = $hash->{cost_in_usd_ticks} / 10_000_000_000 }
  elsif ( defined $hash->{cost_in_nano_usd} )  { $cost_usd = $hash->{cost_in_nano_usd}  / 1_000_000_000 }
  elsif ( ref($cost) eq 'HASH' && uc( $cost->{currency} // '' ) eq 'USD'
    && defined $cost->{total_cost} && !ref $cost->{total_cost} && looks_like_number( $cost->{total_cost} ) ) {
    $cost_usd = 0 + $cost->{total_cost};
  }

  my %args = ( input_tokens => $input, output_tokens => $output );
  $args{total_tokens}       = 0 + $total       if defined $total;
  $args{cached_tokens}      = 0 + $cached       if defined $cached;
  $args{cache_write_tokens} = 0 + $cache_write  if defined $cache_write;
  $args{reasoning_tokens}   = 0 + $reasoning    if defined $reasoning;
  $args{cost_usd}           = $cost_usd         if defined $cost_usd;
  $args{input_includes_cache} = $includes ? 1 : 0 if defined $includes;
  $args{raw} = $hash;
  return $class->new(%args);
}

# Build a Usage from any response shape: a Langertha::Response, a HashRef
# with a usage key, or undef.
sub from_response {
  my ($class, $response) = @_;
  return $class->new unless $response;

  if ( blessed($response) && $response->isa('Langertha::Response') ) {
    my $usage = $response->has_usage ? $response->usage : undef;
    return $usage if blessed($usage) && $usage->isa('Langertha::Usage');
    return $class->from_hash( $usage || {} );
  }
  if ( ref($response) eq 'HASH' ) {
    return $class->from_raw($response) // $class->from_hash( $response->{usage} || {} );
  }
  return $class->new;
}

# Build a Usage from a raw decoded provider response body; undef when the body
# reports no usage. Probes with lexicals so the caller's body never autovivifies.
sub from_raw {
  my ($class, $data) = @_;
  return undef unless ref($data) eq 'HASH';
  for my $key (qw( usage usageMetadata )) {
    return $class->from_hash( $data->{$key} ) if ref( $data->{$key} ) eq 'HASH';
  }
  my $envelope = $data->{response};
  if ( ref($envelope) eq 'HASH' && ref( $envelope->{usage} ) eq 'HASH' ) {
    return $class->from_hash( $envelope->{usage} );
  }
  # Ollama native: top-level counts. A zero count is "not reported", as in
  # Engine::Ollama's chat_response, so a body with only zeros has no usage.
  my %ollama = map { $data->{$_} ? ( $_ => $data->{$_} ) : () } qw( prompt_eval_count eval_count );
  return $class->from_hash( \%ollama ) if %ollama;
  # AKI native: top-level counts under their own names (Engine::AKI's
  # chat_response reads the same keys, by definedness).
  my %aki = map { defined $data->{$_} ? ( $_ => $data->{$_} ) : () }
    qw( prompt_length num_generated_tokens num_cached_tokens );
  if (%aki) {
    return $class->new(
      input_tokens  => 0 + ( $aki{prompt_length}        // 0 ),
      output_tokens => 0 + ( $aki{num_generated_tokens} // 0 ),
      exists $aki{num_cached_tokens}
        ? ( cached_tokens => 0 + $aki{num_cached_tokens}, input_includes_cache => 1 ) : (),
      raw           => \%aki,
    );
  }
  return undef;
}


# Immutable merge — returns a new Usage that is the sum of self + other.
# Cache and reasoning counts are summed (undef only when neither side reported one). When
# one side counts its cache inside input_tokens (flag 1, or undef with counts)
# and the other beside it (flag 0), the beside side's cache counts are added to
# its input_tokens first, so the sum is "inside" throughout and priced without
# loss (k265).
sub merge {
  my ($self, $other) = @_;
  return $self unless $other;
  my %cache;
  for my $count (qw( cached_tokens cache_write_tokens reasoning_tokens )) {
    my @seen = grep { defined } $self->$count, $other->$count;
    next unless @seen;
    $cache{$count} = 0;
    $cache{$count} += $_ for @seen;
  }
  my @reported = grep { defined $_->cached_tokens || defined $_->cache_write_tokens } $self, $other;
  my @beside = grep { defined $_->input_includes_cache && !$_->input_includes_cache } @reported;
  my $input  = $self->input_tokens + $other->input_tokens;
  my $includes;
  if ( @beside && @beside < @reported ) {
    $input += ( $_->cached_tokens // 0 ) + ( $_->cache_write_tokens // 0 ) for @beside;
    $includes = 1;
  }
  elsif (@beside) {
    $includes = 0;
  }
  elsif (@reported) {
    # All inside: 1 when every side said so, else undef (which reads as inside).
    $includes = ( grep { !defined $_->input_includes_cache } @reported ) ? undef : 1;
  }
  # A cost is only known for the sum when both sides report one: a partial
  # sum would read as the whole bill.
  my @costs = grep { defined } $self->cost_usd, $other->cost_usd;
  return ref($self)->new(
    input_tokens  => $input,
    output_tokens => $self->output_tokens + $other->output_tokens,
    %cache,
    @costs == 2 ? ( cost_usd => $costs[0] + $costs[1] ) : (),
    defined $includes ? ( input_includes_cache => $includes ) : (),
  );
}


# Canonical hash representation (input_tokens / output_tokens / total_tokens).
sub to_hash {
  my ($self) = @_;
  return {
    input_tokens  => $self->input_tokens,
    output_tokens => $self->output_tokens,
    total_tokens  => $self->total_tokens,
  };
}

# Backing for the %{} overload. When a provider hash was captured (raw), that
# hash is returned verbatim so existing `$response->usage->{...}` callers keep
# seeing the exact engine-normalized keys they always saw — including
# provider-specific extras (cache tokens, token details) and the deliberate
# absence of keys the engine normalized away. Without a raw hash (a Usage
# constructed directly), the canonical to_hash shape is returned.
sub _as_hash {
  my ($self) = @_;
  my $d = $DATA{$self} || {};
  return $d->{raw} if $d->{raw};
  return {
    input_tokens  => $d->{input_tokens} // 0,
    output_tokens => $d->{output_tokens} // 0,
    total_tokens  => $d->{total_tokens} // ( ( $d->{input_tokens} // 0 ) + ( $d->{output_tokens} // 0 ) ),
  };
}

# Make the object transparent to any JSON encoder configured with
# convert_blessed => 1 (the house default, see Langertha::Plugin::Langfuse).
# to_hash is the complete canonical representation, so this is a plain
# delegator — nothing is dropped.
sub TO_JSON { shift->to_hash }

sub to_openai_format {
  my ($self) = @_;
  return {
    prompt_tokens     => $self->input_tokens,
    completion_tokens => $self->output_tokens,
    total_tokens      => $self->total_tokens,
  };
}

sub to_anthropic_format {
  my ($self) = @_;
  return {
    input_tokens  => $self->input_tokens,
    output_tokens => $self->output_tokens,
  };
}

sub to_ollama_format {
  my ($self) = @_;
  return {
    prompt_eval_count => $self->input_tokens,
    eval_count        => $self->output_tokens,
  };
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Usage - Immutable value object for LLM token usage with cross-provider conversion

=head1 VERSION

version 0.503

=head2 from_raw

    my $data  = $engine->parse_response($http_response);
    my $usage = Langertha::Usage->from_raw($data)
      or return;   # the body reported no usage
    printf "%d in / %d out\n", $usage->input_tokens, $usage->output_tokens;

Class method. Builds a Usage from a B<raw decoded provider response body>, the
HashRef C<parse_response> returns — for callers that send their own requests
and never get a L<Langertha::Response>. It finds the usage block wherever the
provider puts it: C<usage> (OpenAI-compatible, Anthropic, Open-Responses),
C<usageMetadata> (Gemini), C<response.usage> (an Open-Responses event
envelope), the top-level C<prompt_eval_count> / C<eval_count> of Ollama's
native API, or the top-level C<prompt_length> / C<num_generated_tokens> /
C<num_cached_tokens> of AKI.IO's native API. The usage block and the Ollama
counts are then read by L</from_hash>, so every spelling it knows applies.

Returns C<undef> when the body reports no usage (or is not a HashRef), so a
caller can tell "not reported" from "zero tokens". As in
L<Langertha::Engine::Ollama>, an Ollama count of zero counts as not reported.

=head2 from_response

    my $usage = Langertha::Usage->from_response($response_or_body);

Class method. Builds a Usage from a L<Langertha::Response> (its C<usage>), or
from a raw body HashRef via L</from_raw>. Always returns a Usage: all-zero
when nothing is reported.

=head2 from_hash

    my $usage = Langertha::Usage->from_hash($usage_block);

Class method. Builds a Usage from a provider's usage block, accepting the
OpenAI (C<prompt_tokens> / C<completion_tokens>), Anthropic and Open-Responses
(C<input_tokens> / C<output_tokens>), Ollama (C<prompt_eval_count> /
C<eval_count>) and Gemini (C<promptTokenCount> / C<candidatesTokenCount> /
C<totalTokenCount>) spellings, in that order of preference, plus the cache
counts described under L</cached_tokens> and L</cache_write_tokens>, the
L</reasoning_tokens> share and the provider-reported L</cost_usd>.

Gemini counts thinking and the tool-use prompt beside the prompt and the
answer (C<totalTokenCount> is their sum), so from the Gemini spelling
C<output_tokens> is C<candidatesTokenCount> plus C<thoughtsTokenCount> and
C<input_tokens> is C<promptTokenCount> plus C<toolUsePromptTokenCount>.
Thinking is billed at the output rate; C<output_tokens> then means what
OpenAI's C<completion_tokens> means, reasoning included.

=head2 merge

    my $sum = $usage->merge($other);

Returns a new Usage holding the sum of both: C<input_tokens>, C<output_tokens>,
and L</cached_tokens> / L</cache_write_tokens> / L</reasoning_tokens> (a side that did not report a
count adds nothing; the sum stays C<undef> when neither did). L</input_includes_cache>
comes from the sides that reported a cache count. When both count it beside
C<input_tokens> (false) the sum is false. When one counts it inside (true, or
C<undef>) and the other beside, the beside side's cache counts are added to its
C<input_tokens> before summing and the sum is true, so pricing the merged Usage
costs the same as pricing both parts. When both count it inside, the sum is
true, or C<undef> if either side's flag was C<undef>. L</cost_usd> is summed
only when both sides report one; otherwise the sum's cost is C<undef>, since
a partial sum would read as the whole bill. L</raw> is not carried over.

=head1 HASH OVERLOAD — backward compatibility

C<Langertha::Usage> overloads C<%{}>, so a Usage object can keep being
dereferenced as a hash: C<< $response->usage->{prompt_tokens} >> keeps working.
This is the deliberate back-compat seam for the coercion of
L<Langertha::Response/usage> from a raw HashRef to a C<Langertha::Usage>
object (karr #43).

When the object was built from a provider hash (via L</from_hash>, which is
what L<Langertha::Response> does in C<BUILDARGS>), the overload returns that
hash B<verbatim> — stored in L</raw>. Callers therefore keep seeing exactly
the engine-normalized keys they always saw: provider-specific extras
(Anthropic cache tokens, OpenAI C<prompt_tokens_details> /
C<completion_tokens_details>) survive, and keys the engine normalized away
(Gemini camelCase, Ollama C<prompt_eval_count> / C<eval_count>) stay absent.
C<exists> checks behave exactly as they did on the raw hash.

These engine-normalized keys are legacy: the accessors above read every
spelling, so no engine needs to rename for Usage's sake any more. They are
kept for compatibility and are B<not> deprecated. For example
L<Langertha::Engine::Gemini> still serves C<prompt_tokens>,
C<completion_tokens>, C<total_tokens> and C<cached_content_token_count> here
in place of Gemini's camelCase C<usageMetadata> names.

For a Usage constructed directly (no raw hash), the overload returns the
canonical L</to_hash> shape (C<input_tokens> / C<output_tokens> /
C<total_tokens>). New code should prefer the accessors and the
C<to_*_format> methods over hash dereferencing.

=head2 Why the field hash

A naive C<%{}> overload on a Moose class is impossible: the overload hijacks
every C<< $self->{attr} >> deref on the object, including the ones Moose's
generated accessors use internally, so the accessors read through the overload
and recurse (verified: infinite recursion / undef reads). The canonical Perl
solution is to keep the attribute values in a C<Hash::Util::FieldHash> keyed
by object identity and route B<both> the accessors (via C<around> modifiers)
and the overload through it. The object's own hash is then never read, so the
overload only ever serves caller hash derefs.

=head2 cached_tokens

Number of prompt tokens served from the provider's prefix cache (the cache
B<read> count), when the provider reports it. L</from_hash> parses it from any
of its wire spellings: OpenAI's Chat wire nests it at
C<usage.prompt_tokens_details.cached_tokens> (also Mistral, and any
OpenAI-compatible server such as SGLang with C<return_cached_tokens_details>),
the Open-Responses envelope (OpenAI Responses, the Perplexity Agent API) nests
it at C<usage.input_tokens_details.cached_tokens> (or the Anthropic-named
C<cache_read_input_tokens> in the same block), and Anthropic reports it flat as
C<usage.cache_read_input_tokens>. The OpenAI Chat nesting wins, then the
Responses nesting, then the Anthropic flat key. Gemini reports it as
C<usageMetadata.cachedContentTokenCount> (C<cached_content_token_count> after
L<Langertha::Engine::Gemini> renames it), read after the Anthropic key. A flat
canonical C<cached_tokens> (what L<Langertha::Engine::AKI> puts in its usage
hash, from AKI.IO's native C<num_cached_tokens>) is read last. C<undef> when the
provider does not report a cache-read count.

Note: on OpenAI (GPT-5.6 and later) this count excludes hidden tokens and
rounds down to a multiple of 128, so cost arithmetic built on it is
approximate by construction.

=head2 cache_write_tokens

Number of prompt tokens written to the provider's prefix cache (the cache
B<creation> count), a distinct quantity from L</cached_tokens> and deliberately
not folded into it. L</from_hash> parses it from any of its wire spellings:
OpenAI's Chat wire nests it at C<usage.prompt_tokens_details.cache_write_tokens>,
the Open-Responses envelope (OpenAI Responses, the Perplexity Agent API) nests
it at C<usage.input_tokens_details.cache_creation_input_tokens>, and Anthropic
reports it flat as C<usage.cache_creation_input_tokens> (Anthropic further splits
that count across TTL tiers under C<usage.cache_creation>, which stays verbatim
in L</raw>). The OpenAI Chat nesting wins, then the Responses nesting, then the
Anthropic flat key; without the flat key the C<ephemeral_5m_input_tokens> /
C<ephemeral_1h_input_tokens> of C<usage.cache_creation> are summed. C<undef>
when the provider does not report a cache-write count.

=head2 input_includes_cache

Whether L</cached_tokens> and L</cache_write_tokens> are already counted in
C<input_tokens>. C<input_tokens> keeps the meaning the wire gives it, and
that meaning differs: OpenAI's C<prompt_tokens>, the Open-Responses
C<input_tokens>, Gemini's C<promptTokenCount> and AKI.IO's C<prompt_length>
include the cached tokens; Anthropic's C<input_tokens> counts only the tokens
after the last cache breakpoint, with C<cache_read_input_tokens> and
C<cache_creation_input_tokens> beside it. L</from_hash> and L</from_raw> set
this flag from where they found the cache counts: true for a count nested in
C<prompt_tokens_details> / C<input_tokens_details>, for Gemini's and for the
flat C<cached_tokens>; false for Anthropic's flat keys. C<undef> when no cache
count was reported, or when the object was built with C<new> and the flag was
not passed.

The Anthropic-compatible shims follow the Anthropic spelling, but not always
its meaning: AKI.IO's C</anthropic> endpoint reports the same numbers under
C<input_tokens> as its OpenAI face does under C<prompt_tokens> (cached reads
included). A canonical C<input_includes_cache> key in the usage hash therefore
beats the inference when a cache count was found;
L<Langertha::Role::AnthropicCompatible> adds it for an engine whose
C<_usage_input_includes_cache> hook answers (L<Langertha::Engine::AKIAnthropic>
answers true), so the key also shows in C<< $response->usage->{...} >>.

=head2 reasoning_tokens

How many of C<output_tokens> the model spent reasoning (thinking), when the
provider reports it. The count is already part of C<output_tokens> — never add
it again. L</from_hash> reads OpenAI Chat's
C<completion_tokens_details.reasoning_tokens>, then the Open-Responses
C<output_tokens_details.reasoning_tokens>, then Gemini's C<thoughtsTokenCount>
(which Gemini reports beside C<candidatesTokenCount>, so L</from_hash> adds it
into C<output_tokens>). C<undef> when the provider does not report one.

=head2 cost_usd

What the provider says the request was billed, in US dollars, when it reports
it: the actual charge after its discounts (prompt caching) and including its
server-side tool fees. xAI puts it in every usage block (chat completions,
Responses, image and video generation) as the integer C<cost_in_usd_ticks>
(1 USD = 10,000,000,000 ticks), and on Responses also as C<cost_in_nano_usd>
(1 USD = 1,000,000,000 nano-USD). L</from_hash> converts whichever is present,
C<cost_in_usd_ticks> first as the finer unit; the integers stay verbatim in
L</raw>, so C<< $usage->{cost_in_usd_ticks} >> still gives exact integer
accounting. A stream carries it only in its usage frame, which comes when the
request asks for it (C<stream_options =E<gt> { include_usage =E<gt> 1 }>).

The Perplexity Agent API sends C<usage.cost> as an object that names its
currency (C<currency>, C<total_cost>, and the parts such as C<input_cost> and
C<tool_calls_cost>); L</from_hash> reads C<total_cost> when C<currency> is
C<USD>, and nothing when the currency is another one or the total is missing.
OpenRouter sends C<usage.cost> as a bare number in its credits, which are US
dollars; a bare number names no unit, so L</from_hash> does not read it on its
own. L<Langertha::Engine::OpenRouter> adds it to the usage block as the
canonical C<cost_usd> key, which L</from_hash> reads first, so it arrives on
the engine's responses and stream chunks, but not through L</from_raw> on an
OpenRouter body. For a BYOK request C<cost> is still only what OpenRouter
charged your credits; what the key's own provider charged is in
C<cost_details.upstream_inference_cost>, which stays in L</raw> and is not
added.

C<undef> when the provider reports no cost, never C<0>: it is not an estimate,
and L<Langertha::Pricing> does not read it — that builds a L<Langertha::Cost>
from your own price rules.

=head2 uncached_input_tokens

    my $fresh = $usage->uncached_input_tokens;

The input tokens that were neither read from nor written to the prompt cache.
When L</input_includes_cache> is false this is C<input_tokens>; otherwise
(true or C<undef>) it is C<input_tokens> minus L</cached_tokens> minus
L</cache_write_tokens>, never below zero. An C<undef> flag is read as
"included" because that is what C<total_tokens> assumes of C<input_tokens>.
L<Langertha::Pricing/cost_for> prices this count at the input rate when a rule
has a cache rate.

=head2 raw

The provider-verbatim hash the object was built from, when it was built via
L</from_hash>. C<undef> for directly constructed objects. Read-only; the
canonical L</to_hash> and C<TO_JSON> deliberately do B<not> include it — it
exists solely to back the C<%{}> overload.

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
