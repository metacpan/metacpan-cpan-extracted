package Langertha::Engine::MiniMaxAnthropic;
# ABSTRACT: MiniMax API via Anthropic-compatible endpoint (legacy)
our $VERSION = '0.402';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::AnthropicBase';

with 'Langertha::Role::StaticModels';


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.minimax.io/anthropic/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_MINIMAX_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_MINIMAX_API_KEY or api_key set";
}

sub default_model { 'MiniMax-M2.7' }

sub default_response_size { 4096 }

sub _build_static_models {[
  { id => 'MiniMax-M2.7' },
  { id => 'MiniMax-M2.5' },
  { id => 'MiniMax-M2.5-highspeed' },
  { id => 'MiniMax-M2.1' },
  { id => 'MiniMax-M2.1-highspeed' },
  { id => 'MiniMax-M2' },
]}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::MiniMaxAnthropic - MiniMax API via Anthropic-compatible endpoint (legacy)

=head1 VERSION

version 0.402

=head1 SYNOPSIS

    use Langertha::Engine::MiniMaxAnthropic;

    my $minimax = Langertha::Engine::MiniMaxAnthropic->new(
        api_key => $ENV{MINIMAX_API_KEY},
        model   => 'MiniMax-M2.7',
    );

    print $minimax->simple_chat('Hello from Perl!');

=head1 DESCRIPTION

Provides access to L<MiniMax|https://www.minimax.io/> models via their
Anthropic-compatible endpoint at C<https://api.minimax.io/anthropic/v1>.

B<Historical note:> Until version 0.402 this was the default behavior of
L<Langertha::Engine::MiniMax>. MiniMax's C</anthropic> endpoint is a shim
over their native OpenAI-compatible API — it does not always re-parse
stringified tool-call arguments, which causes intermittent tool-calling
failures where the Anthropic SDK sees a wrapper object whose key rotates
between C<result>, C<arguments>, and the tool name. For new code prefer
L<Langertha::Engine::MiniMax>, which talks to MiniMax's native OpenAI
endpoint and avoids the shim. This class is retained for anyone who needs
the Anthropic wire format specifically.

See L<Langertha::Engine::MiniMax> for the available models list.

Get your API key at L<https://platform.minimax.io/> and set
C<LANGERTHA_MINIMAX_API_KEY> in your environment.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::MiniMax> - Recommended MiniMax engine (OpenAI-compatible endpoint)

=item * L<https://platform.minimax.io/docs/api-reference/text-anthropic-api> - MiniMax Anthropic API docs

=item * L<Langertha::Engine::AnthropicBase> - Anthropic-compatible base class

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
