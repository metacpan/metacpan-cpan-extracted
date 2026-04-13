package Langertha::RateLimit;
# ABSTRACT: Rate limit information from API response headers
our $VERSION = '0.401';
use Moose;


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


has raw => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);


sub to_hash {
  my ( $self ) = @_;
  return {
    ( defined $self->requests_limit     ? ( requests_limit     => $self->requests_limit )     : () ),
    ( defined $self->requests_remaining ? ( requests_remaining => $self->requests_remaining ) : () ),
    ( defined $self->requests_reset     ? ( requests_reset     => $self->requests_reset )     : () ),
    ( defined $self->tokens_limit       ? ( tokens_limit       => $self->tokens_limit )       : () ),
    ( defined $self->tokens_remaining   ? ( tokens_remaining   => $self->tokens_remaining )   : () ),
    ( defined $self->tokens_reset       ? ( tokens_reset       => $self->tokens_reset )       : () ),
    raw => $self->raw,
  };
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::RateLimit - Rate limit information from API response headers

=head1 VERSION

version 0.401

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

=head2 requests_limit

Maximum number of requests allowed in the current window.

=head2 requests_remaining

Number of requests remaining in the current window.

=head2 requests_reset

Time until the request limit resets. Format varies by provider (seconds,
RFC 3339 timestamp, or epoch).

=head2 tokens_limit

Maximum number of tokens allowed in the current window.

=head2 tokens_remaining

Number of tokens remaining in the current window.

=head2 tokens_reset

Time until the token limit resets. Format varies by provider.

=head2 raw

HashRef of all rate-limit-related headers as returned by the provider.
Useful for accessing provider-specific fields not covered by the
normalized attributes (e.g. Anthropic's C<input-tokens-limit>).

=head2 to_hash

    my $hash = $rate_limit->to_hash;

Returns a flat HashRef of all defined rate limit fields plus the raw headers.

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

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
