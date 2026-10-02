package Langertha::Content;
# ABSTRACT: Base role for canonical multimodal content blocks with cross-provider serialization
our $VERSION = '0.503';
use Moose::Role;

use Carp qw( croak );

requires qw( to_openai to_anthropic to_gemini );

# Serializers added after the role was public (karr k267) get croaking
# defaults instead of joining `requires`, so an outside content class still
# composes; it only fails when it is actually sent on such a wire.
sub _no_serializer {
  my ( $self, $fmt ) = @_;
  croak( ( ref $self || $self )." cannot be sent on the $fmt wire; implement to_$fmt" );
}

sub to_responses { $_[0]->_no_serializer('responses') }
sub to_ollama    { $_[0]->_no_serializer('ollama') }
sub to_lmstudio  { $_[0]->_no_serializer('lmstudio') }



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Content - Base role for canonical multimodal content blocks with cross-provider serialization

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    package Langertha::Content::Image;
    use Moose;
    with 'Langertha::Content';

    sub to_openai    { ... }
    sub to_anthropic { ... }
    sub to_gemini    { ... }
    sub to_responses { ... }
    sub to_ollama    { ... }
    sub to_lmstudio  { ... }

=head1 DESCRIPTION

Marker role for canonical content blocks that can be embedded inside the
C<content> arrayref of a chat message and serialized to any provider wire
format by L<Langertha::Role::Chat>.

Implementations must provide C<to_openai>, C<to_anthropic> and C<to_gemini>,
and may provide C<to_responses>, C<to_ollama> and C<to_lmstudio> (one per
L<Langertha::Role::Chat/content_format>). Each returns what its wire expects
for the block: a HashRef for the message content / parts / input array, or
(C<to_ollama>) the raw base64 string for the message C<images> array. The
role's defaults for the last three croak with
C<< "<class> cannot be sent on the <fmt> wire; implement to_<fmt>" >>.

=head2 to_responses

=head2 to_ollama

=head2 to_lmstudio

Default serializers for the C<responses>, C<ollama> and C<lmstudio>
L<Langertha::Role::Chat/content_format>s. They croak; a content class that
can be sent on those wires overrides them (L<Langertha::Content::Image> does).

=head1 SEE ALSO

=over

=item * L<Langertha::Content::Image> - Image (URL / base64 / local file) content block

=item * L<Langertha::ToolChoice> - Sibling value object for tool_choice normalization

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
