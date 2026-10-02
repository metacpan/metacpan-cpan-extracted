package Langertha::RateLimit;
# ABSTRACT: Rate limit information from API response headers
our $VERSION = '0.503';
use Moose;
use Langertha::Moment;


has requests_limit => (
  is => 'ro',
  isa => 'Maybe[Num]',
  default => undef,
);


has requests_remaining => (
  is => 'ro',
  isa => 'Maybe[Num]',
  default => undef,
);


has requests_reset => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => undef,
);


has tokens_limit => (
  is => 'ro',
  isa => 'Maybe[Num]',
  default => undef,
);


has tokens_remaining => (
  is => 'ro',
  isa => 'Maybe[Num]',
  default => undef,
);


has tokens_reset => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => undef,
);


has received => (
  is => 'ro',
  isa => 'Langertha::Moment',
  default => sub { Langertha::Moment->now_utc },
);


has requests_reset_at => (
  is => 'ro',
  isa => 'Maybe[Langertha::Moment]',
  lazy => 1,
  builder => '_build_requests_reset_at',
  predicate => 'has_requests_reset_at',
);


has requests_reset_after => (
  is => 'ro',
  isa => 'Maybe[Num]',
  lazy => 1,
  builder => '_build_requests_reset_after',
  predicate => 'has_requests_reset_after',
);


has tokens_reset_at => (
  is => 'ro',
  isa => 'Maybe[Langertha::Moment]',
  lazy => 1,
  builder => '_build_tokens_reset_at',
  predicate => 'has_tokens_reset_at',
);


has tokens_reset_after => (
  is => 'ro',
  isa => 'Maybe[Num]',
  lazy => 1,
  builder => '_build_tokens_reset_after',
  predicate => 'has_tokens_reset_after',
);


has retry_after => (
  is => 'ro',
  isa => 'Maybe[Num]',
  lazy => 1,
  builder => '_build_retry_after',
  predicate => 'has_retry_after',
);


has raw => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);


# Lazy derivation of the missing half of a reset bucket. A bucket is populated
# with exactly the shape the wire spoke (a duration on the OpenAI family, an
# instant on Anthropic); the other half is derived here against `received`,
# only on demand, and only when the wire actually spoke one of the two. When
# neither was sent both stay undef — the expected path for the many providers
# that send no reset header. The sibling *predicate* is the guard that keeps a
# never-spoken bucket from triggering the other builder (no mutual recursion),
# and the `defined` guards keep it correct regardless of access order.
sub _reset_at_from {
  my ( $self, $after ) = @_;
  return undef unless defined $after;
  my $whole = int $after;
  my $nanos = int( ( $after - $whole ) * 1_000_000_000 + 0.5 );
  return $self->received->plus_seconds($whole)->plus_nanoseconds($nanos);
}

sub _reset_after_from {
  my ( $self, $at ) = @_;
  return undef unless defined $at;
  return $self->received->delta_nanoseconds($at) / 1_000_000_000;
}

sub _build_requests_reset_at {
  my ( $self ) = @_;
  return undef unless $self->has_requests_reset_after;
  return $self->_reset_at_from( $self->requests_reset_after );
}

sub _build_requests_reset_after {
  my ( $self ) = @_;
  return undef unless $self->has_requests_reset_at;
  return $self->_reset_after_from( $self->requests_reset_at );
}

sub _build_tokens_reset_at {
  my ( $self ) = @_;
  return undef unless $self->has_tokens_reset_after;
  return $self->_reset_at_from( $self->tokens_reset_after );
}

sub _build_tokens_reset_after {
  my ( $self ) = @_;
  return undef unless $self->has_tokens_reset_at;
  return $self->_reset_after_from( $self->tokens_reset_at );
}

sub _build_retry_after {
  my ( $self ) = @_;
  return _resolve_retry_after( $self->raw, $self->received );
}

# retry-after-ms (Azure OpenAI; openai-python reads it first) is the more
# precise answer and wins; Retry-After otherwise (karr k312).
sub _resolve_retry_after {
  my ( $raw, $received ) = @_;
  my $ms = $raw->{'retry-after-ms'};
  if ( defined $ms ) {
    ( my $trimmed = $ms ) =~ s/\A\s+|\s+\z//g;
    return $trimmed / 1000 if $trimmed =~ /\A[0-9]+(?:\.[0-9]+)?\z/;
  }
  return _parse_retry_after( $raw->{'retry-after'}, $received );
}


sub _parse_retry_after {
  my ( $value, $received ) = @_;
  return undef unless defined $value;
  ( my $trimmed = $value ) =~ s/\A\s+|\s+\z//g;
  return $trimmed + 0 if $trimmed =~ /\A[0-9]+(?:\.[0-9]+)?\z/;
  require HTTP::Date;
  my $epoch = HTTP::Date::str2time($trimmed);
  return undef unless defined $epoch;
  $received //= Langertha::Moment->now_utc;
  my $wait = $epoch - ( $received->epoch + $received->nanosecond / 1_000_000_000 );
  return $wait > 0 ? $wait : 0;
}


# Go time.Duration.String() unit table, in seconds. Go emits compound
# ("2m59.56s", "6m0s", "1h2m3s"), sub-second ("250ms", "35ms"), and fractional
# ("7.66s") forms; the micro unit is written "µs" (U+00B5) but "us" is accepted.
my %go_duration_seconds = (
  ns => 1e-9,
  us => 1e-6,
  ms => 1e-3,
  s  => 1,
  m  => 60,
  h  => 3600,
);

sub _parse_go_duration {
  my ( $string ) = @_;
  return undef unless defined $string;
  # Whole-string shape check: one or more <number><unit> segments, nothing
  # else. A bare number, an RFC 3339 stamp, or an epoch is rejected outright —
  # this parser never guesses at a shape that is not a Go duration.
  return undef
    unless $string =~ /\A-?(?:[0-9]+(?:\.[0-9]+)?(?:ns|us|\x{b5}s|\x{3bc}s|ms|s|m|h))+\z/;
  my $sign = $string =~ /\A-/ ? -1 : 1;
  my $total = 0;
  while ( $string =~ /([0-9]+(?:\.[0-9]+)?)(ns|us|\x{b5}s|\x{3bc}s|ms|s|m|h)/g ) {
    my ( $num, $unit ) = ( $1, $2 );
    $unit = 'us' if $unit eq "\x{b5}s" or $unit eq "\x{3bc}s";
    $total += $num * $go_duration_seconds{$unit};
  }
  return $sign * $total;
}


sub _collect_headers {
  my ( $http_response ) = @_;
  my %raw;
  my $headers = $http_response->headers;
  for my $name ( $headers->header_field_names ) {
    next
      unless $name =~ /\A(?:x-ratelimit-|anthropic-ratelimit-|anthropic-priority-|anthropic-fast-|ratelimitbysize-)/i
      or lc($name) =~ /\Aretry-after(?:-ms)?\z/;
    my $val = $http_response->header($name);
    $raw{ lc $name } = $val if defined $val;
  }
  return %raw;
}


sub to_hash {
  my ( $self ) = @_;
  # The *_reset_at Moments are numified to a plain epoch number, exactly as
  # Langertha::Response emits `created` (0+ overload) — to_hash returns plain
  # scalars, not value objects. `received` is the derivation anchor, not a
  # rate-limit field, and is reachable via its accessor; it stays out of the
  # serialized view so it does not appear in every trace of a rate-limited
  # response.
  return {
    ( defined $self->requests_limit        ? ( requests_limit        => $self->requests_limit )               : () ),
    ( defined $self->requests_remaining    ? ( requests_remaining    => $self->requests_remaining )           : () ),
    ( defined $self->requests_reset        ? ( requests_reset        => $self->requests_reset )               : () ),
    ( defined $self->requests_reset_at     ? ( requests_reset_at     => 0 + $self->requests_reset_at )        : () ),
    ( defined $self->requests_reset_after  ? ( requests_reset_after  => $self->requests_reset_after )         : () ),
    ( defined $self->tokens_limit          ? ( tokens_limit          => $self->tokens_limit )                 : () ),
    ( defined $self->tokens_remaining      ? ( tokens_remaining      => $self->tokens_remaining )             : () ),
    ( defined $self->tokens_reset          ? ( tokens_reset          => $self->tokens_reset )                 : () ),
    ( defined $self->tokens_reset_at       ? ( tokens_reset_at       => 0 + $self->tokens_reset_at )          : () ),
    ( defined $self->tokens_reset_after    ? ( tokens_reset_after    => $self->tokens_reset_after )           : () ),
    ( defined $self->retry_after           ? ( retry_after           => $self->retry_after )                  : () ),
    raw => $self->raw,
  };
}


sub TO_JSON {
  my ( $self ) = @_;
  my $hash = $self->to_hash;
  delete $hash->{raw};
  return $hash;
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::RateLimit - Rate limit information from API response headers

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $response = $engine->simple_chat('Hello');

    if ($response->has_rate_limit) {
        my $rl = $response->rate_limit;
        say "Requests remaining: ", $rl->requests_remaining // 'unknown';
        say "Tokens remaining: ", $rl->tokens_remaining // 'unknown';
        say "Reset in: ", $rl->requests_reset // 'unknown', " seconds";
    }

    # Access raw provider-specific headers
    my $raw = $response->rate_limit->raw;

    # Also available on the engine (always reflects latest response)
    if ($engine->has_rate_limit) {
        say "Engine requests remaining: ", $engine->rate_limit->requests_remaining;
    }

=head1 DESCRIPTION

Normalized rate limit data extracted from HTTP response headers. Different
providers use different header naming conventions; this class provides a
unified interface.

B<Supported providers:>

=over 4

=item * OpenAI, Groq, Cerebras, OpenRouter, Replicate, HuggingFace (C<x-ratelimit-*>)

=item * Anthropic (C<anthropic-ratelimit-*>)

=back

Engines that do not return rate limit headers (DeepSeek, Ollama, vLLM,
LlamaCpp, etc.) will not have a rate_limit set.

B<Reset timing.> Providers spell the reset of a bucket in incompatible ways: the
OpenAI family sends a duration (a Go C<time.Duration> string), Anthropic sends
an instant (RFC 3339), and many send nothing. Rather than leave a single
untyped field holding whichever shape arrived, each bucket exposes both a
typed instant — L</requests_reset_at> / L</tokens_reset_at>
(L<Langertha::Moment>, I<when>) — and a typed duration —
L</requests_reset_after> / L</tokens_reset_after> (seconds, I<in how long>).
The parser fills whichever half the wire actually spoke; the other is derived
lazily against L</received>. Both stay C<undef> for a bucket no header
described. The verbatim header strings remain available, untyped, as
L</requests_reset> / L</tokens_reset>.

=head2 requests_limit

Maximum number of requests allowed in the current window.

=head2 requests_remaining

Number of requests remaining in the current window.

=head2 requests_reset

The B<verbatim> C<*-reset-requests> / C<requests-reset> header string, exactly
as the provider sent it. Its shape is provider-dependent and untyped: OpenAI
and the OpenAI-compatible family send a Go C<time.Duration> string (C<"6m0s">,
C<"2m59.56s">, C<"250ms">), Anthropic sends an RFC 3339 instant, and most
providers send nothing. A consumer cannot tell which kind it holds without
knowing the provider.

Kept for back-compatibility. Prefer the typed pair L</requests_reset_at> (WHEN,
a L<Langertha::Moment>) and L</requests_reset_after> (IN HOW LONG, seconds),
which normalize this string and derive the missing half against L</received>.

=head2 tokens_limit

Maximum number of tokens allowed in the current window.

=head2 tokens_remaining

Number of tokens remaining in the current window.

=head2 tokens_reset

The B<verbatim> C<*-reset-tokens> / C<tokens-reset> header string, exactly as
the provider sent it — same untyped, provider-dependent shape as
L</requests_reset>.

Kept for back-compatibility. Prefer the typed pair L</tokens_reset_at> and
L</tokens_reset_after>.

=head2 received

L<Langertha::Moment> stamped when the response headers were parsed. It is the
reference instant against which the two halves of each reset bucket are
reconciled: a provider that sent only a duration (OpenAI family) gets its
C<*_reset_at> from C<< received + *_reset_after >>, and one that sent only an
instant (Anthropic) gets its C<*_reset_after> from C<< *_reset_at - received >>.
Defaults to L<Time::Moment/now_utc> at construction; the header readers
stamp it at parse time.

=head2 requests_reset_at

Maybe[L<Langertha::Moment>] — the instant the request limit resets (I<when>).
Set directly from an RFC 3339 reset header (Anthropic); otherwise derived
lazily from L</received> plus L</requests_reset_after> when the provider sent
only a duration (OpenAI family). C<undef> when the provider sent no request
reset header at all — absence is the expected path for the many providers that
send none, not an error, and no default is invented.

=head2 requests_reset_after

Maybe[Num] — seconds until the request limit resets (I<in how long>); may be
fractional. Set directly from a Go C<time.Duration> reset header (OpenAI
family); otherwise derived lazily from L</requests_reset_at> minus L</received>
when the provider sent only an instant (Anthropic). C<undef> when the provider
sent no request reset header at all.

=head2 tokens_reset_at

Maybe[L<Langertha::Moment>] — the instant the token limit resets (I<when>).
The token-bucket mirror of L</requests_reset_at>.

=head2 tokens_reset_after

Maybe[Num] — seconds until the token limit resets (I<in how long>); may be
fractional. The token-bucket mirror of L</requests_reset_after>.

=head2 retry_after

Maybe[Num] — seconds the provider asks the client to wait before retrying,
read from L</raw>. A numeric C<retry-after-ms> (Azure OpenAI and some
proxies send it next to C<retry-after>) wins, divided by 1000. Otherwise
C<retry-after> is read, a duration whichever form the wire uses:
delta-seconds (C<8>; a fractional C<1.5> is accepted too) is taken as is, an
HTTP-date is measured from L</received> (a date already past gives C<0>, never
a negative wait). C<undef> when the response sent neither header, or none in a
readable form (the verbatim values stay in L</raw>).
Providers send it mostly on a C<429> or C<503>, which is why the engine records
the rate limit of an error response before it croaks (see
L<Langertha::Engine::Remote/rate_limit>).

=head2 raw

HashRef of all rate-limit-related headers as returned by the provider, keyed
by lower-cased header name. The header readers collect every response header
matching C<< /^(x-ratelimit-|anthropic-ratelimit-|anthropic-priority-|anthropic-fast-|ratelimitbysize-)/i >>
plus C<retry-after> — a strict superset of the fields the normalized attributes
cover, so provider-specific extras survive here even when they carry a window
in the name (Groq's per-day request bucket, Cerebras's C<x-ratelimit-reset-requests-day>)
or a shape the normalizer does not model (Anthropic's C<anthropic-priority-*> /
C<anthropic-fast-*>, Mistral's C<-minute>-suffixed names). Useful for accessing
provider-specific fields not covered by the normalized attributes.

=head2 _resolve_retry_after

    my $seconds = Langertha::RateLimit::_resolve_retry_after(\%raw, $received);

The seconds to wait from a L</raw>-shaped hash: C<retry-after-ms> divided by
1000 when it holds a number, else C<retry-after> via L</_parse_retry_after>.
Backs L</retry_after> and the retry note in the error messages of
L<Langertha::Role::HTTP>, so both say the same number.

=head2 _parse_retry_after

    my $seconds = Langertha::RateLimit::_parse_retry_after('8');   # 8
    my $seconds = Langertha::RateLimit::_parse_retry_after($http_date, $received);

Reads a C<Retry-After> value as the seconds to wait: delta-seconds directly, an
HTTP-date (via L<HTTP::Date>) as its distance from C<$received> (a
L<Langertha::Moment>, default now), clamped at C<0>. Returns C<undef> for
anything else. The C<retry-after> half of L</_resolve_retry_after>.

=head2 _parse_go_duration

    my $seconds = Langertha::RateLimit::_parse_go_duration('2m59.56s');   # 179.56

Parses a Go C<time.Duration.String()> string into fractional seconds. Handles
compound (C<"6m0s">, C<"1h2m3s">), sub-second (C<"250ms">, C<"35ms">) and
fractional (C<"7.66s">) forms. Returns C<undef> — never guesses — for anything
that is not that exact shape (a bare number, an RFC 3339 instant, an epoch).
Used by L<Langertha::Role::OpenAICompatible> to populate L</requests_reset_after>
/ L</tokens_reset_after> from the C<x-ratelimit-reset-*> headers.

=head2 _collect_headers

    my %raw = Langertha::RateLimit::_collect_headers($http_response);

Collects every rate-limit-related response header into a hash keyed by
lower-cased name — the single source of truth for the L</raw> superset. Matches
the C<x-ratelimit-> / C<anthropic-ratelimit-> / C<anthropic-priority-> /
C<anthropic-fast-> / C<ratelimitbysize-> prefixes plus C<retry-after> and
C<retry-after-ms>. The
wire-envelope roles call this, then normalize the known subset out of the
result.

=head2 to_hash

    my $hash = $rate_limit->to_hash;

Returns a flat HashRef of all defined rate limit fields plus the raw headers.
The typed reset halves appear here whenever they were sent or can be derived:
L</requests_reset_at> / L</tokens_reset_at> as a plain epoch number (their
C<0+> overload, matching L<Langertha::Response/created>) and
L</requests_reset_after> / L</tokens_reset_after> as seconds, and
L</retry_after> in seconds when the provider sent one. A bucket the provider
never spoke is omitted rather than defaulted. L</received> is not
included; read it from the accessor when the derivation anchor is needed.

=head2 TO_JSON

    my $json = JSON::MaybeXS->new(convert_blessed => 1)->encode({ rate_limit => $rl });

Serialization hook for JSON encoders configured with C<convert_blessed>.
Returns L</to_hash> B<without> the C<raw> key.

C<TO_JSON> fires implicitly, from wherever the surrounding structure happens
to be encoded — a trace, a log line, a queue message. The caller did not ask
for this object and cannot see what it contributed, so the implicit path
carries only the normalized, provider-agnostic fields. C<raw> holds the
provider's own rate-limit response headers; shipping those into third-party
sinks by accident is not something a caller should have to opt out of.

A caller who wants the raw headers asks for them explicitly — via L</to_hash>
or L</raw>. That is the only difference between the two methods, and the
reason they deliberately do not return the same thing.

=head1 SEE ALSO

=over

=item * L<Langertha::Response> - Response objects carry rate limit data

=item * L<Langertha::Role::HTTP> - Extracts rate limit headers during response parsing

=item * L<Langertha::Engine::Remote> - Stores the latest rate limit on the engine

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
