package Langertha::Engine::LMStudioAnthropic;
# ABSTRACT: LM Studio via Anthropic-compatible API
our $VERSION = '0.400';
use Moose;

extends 'Langertha::Engine::AnthropicBase';


has '+url' => (
  lazy => 1,
  default => sub { 'http://localhost:1234' },
);

sub _build_api_key {
  return $ENV{LANGERTHA_LMSTUDIO_API_KEY} || 'lmstudio';
}


sub default_model { 'default' }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::LMStudioAnthropic - LM Studio via Anthropic-compatible API

=head1 VERSION

version 0.400

=head1 SYNOPSIS

    use Langertha::Engine::LMStudioAnthropic;

    my $lm_anthropic = Langertha::Engine::LMStudioAnthropic->new(
        url   => 'http://localhost:1234',
        model => 'qwen2.5-7b-instruct-1m',
    );

    print $lm_anthropic->simple_chat('Hello from Anthropic-compatible endpoint');

=head1 DESCRIPTION

Adapter for LM Studio's Anthropic-compatible local endpoint
(C<POST /v1/messages> on the LM Studio server URL, default
C<http://localhost:1234>).

LM Studio requires a non-empty C<x-api-key> header for this endpoint, but the
value is not validated against Anthropic. This class defaults to C<lmstudio>
when no API key is configured.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

API key sent as C<x-api-key> to the Anthropic-compatible endpoint.
LM Studio accepts arbitrary non-empty values. Defaults to C<lmstudio> when
no explicit C<api_key> and no C<LANGERTHA_LMSTUDIO_API_KEY> are set.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::LMStudio> - Native LM Studio API (C</api/v1/chat>)

=item * L<Langertha::Engine::AnthropicBase> - Base Anthropic-compatible engine

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
