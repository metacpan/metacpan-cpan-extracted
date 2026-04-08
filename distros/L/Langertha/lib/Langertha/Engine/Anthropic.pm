package Langertha::Engine::Anthropic;
# ABSTRACT: Anthropic API
our $VERSION = '0.400';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::AnthropicBase';


has '+url' => (
  lazy => 1,
  default => sub { 'https://api.anthropic.com' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_ANTHROPIC_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_ANTHROPIC_API_KEY or api_key set";
}

sub default_model { 'claude-sonnet-4-6' }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Anthropic - Anthropic API

=head1 VERSION

version 0.400

=head1 SYNOPSIS

    use Langertha::Engine::Anthropic;

    my $claude = Langertha::Engine::Anthropic->new(
        api_key => $ENV{ANTHROPIC_API_KEY},
        model   => 'claude-sonnet-4-6',
    );

    print $claude->simple_chat('Generate Perl Moose classes for GeoJSON');

=head1 DESCRIPTION

Concrete Anthropic engine for Claude models. Inherits shared
Anthropic-compatible behavior from L<Langertha::Engine::AnthropicBase> and
provides Anthropic cloud defaults (URL, API key env var, default model).

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::AnthropicBase> - Shared Anthropic-compatible implementation

=item * L<Langertha::Engine::MiniMax> - Anthropic-compatible MiniMax engine

=item * L<Langertha::Engine::LMStudioAnthropic> - Anthropic-compatible LM Studio engine

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
