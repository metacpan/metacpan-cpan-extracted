package Langertha::Engine::Remote;
# ABSTRACT: Base class for all remote engines
our $VERSION = '0.401';
use Moose;

use Langertha::RateLimit;

with map { 'Langertha::Role::'.$_ } qw(
  JSON
  HTTP
  PluginHost
);


has '+url' => (
  required => 1,
);

has _last_rate_limit => (
  is => 'rw',
  isa => 'Maybe[Langertha::RateLimit]',
  predicate => '_has_last_rate_limit',
  clearer => '_clear_last_rate_limit',
  init_arg => undef,
);

sub rate_limit {
  my ( $self ) = @_;
  return $self->_last_rate_limit;
}


sub has_rate_limit {
  my ( $self ) = @_;
  return defined $self->_last_rate_limit;
}


sub _update_rate_limit {
  my ( $self, $http_response ) = @_;
  my $rl = $self->_parse_rate_limit_headers($http_response);
  if ($rl) {
    $self->_last_rate_limit($rl);
  }
}

sub _parse_rate_limit_headers {
  return undef;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Remote - Base class for all remote engines

=head1 VERSION

version 0.401

=head1 SYNOPSIS

    package My::Engine;
    use Moose;

    extends 'Langertha::Engine::Remote';

    has '+url' => ( default => 'https://api.example.com' );

    sub default_model { 'my-model' }

=head1 DESCRIPTION

Root base class for all HTTP-based LLM engines in Langertha. Composes
L<Langertha::Role::JSON>, L<Langertha::Role::HTTP>, and
L<Langertha::Role::PluginHost>, and makes the C<url> attribute required.

All engines in the distribution extend this class, either directly
(L<Langertha::Engine::Anthropic>, L<Langertha::Engine::Gemini>,
L<Langertha::Engine::Ollama>, L<Langertha::Engine::AKI>) or via the
OpenAI-compatible intermediate class L<Langertha::Engine::OpenAIBase>.

=head2 rate_limit

    my $rl = $engine->rate_limit;

Returns the L<Langertha::RateLimit> from the most recent API response,
or C<undef> if no rate limit headers were present.

=head2 has_rate_limit

    if ($engine->has_rate_limit) { ... }

Returns true if the engine has rate limit data from the most recent response.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::OpenAIBase> - Intermediate base for all OpenAI-compatible engines

=item * L<Langertha::Engine::Anthropic> - Anthropic Claude (extends this directly)

=item * L<Langertha::Engine::Gemini> - Google Gemini (extends this directly)

=item * L<Langertha::Engine::Ollama> - Ollama native API (extends this directly)

=item * L<Langertha::Engine::AKI> - AKI EU engine (extends this directly)

=item * L<Langertha::Role::HTTP> - HTTP transport with C<url>, C<user_agent>, request builders

=item * L<Langertha::Role::JSON> - Shared JSON encoder/decoder

=item * L<Langertha::Role::PluginHost> - Plugin system with lifecycle events

=item * L<Langertha::RateLimit> - Rate limit data stored per-engine

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
