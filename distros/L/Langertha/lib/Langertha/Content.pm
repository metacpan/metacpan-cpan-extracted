package Langertha::Content;
# ABSTRACT: Base role for canonical multimodal content blocks with cross-provider serialization
our $VERSION = '0.500';
use Moose::Role;

requires qw( to_openai to_anthropic to_gemini );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Content - Base role for canonical multimodal content blocks with cross-provider serialization

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    package Langertha::Content::Image;
    use Moose;
    with 'Langertha::Content';

    sub to_openai    { ... }
    sub to_anthropic { ... }
    sub to_gemini    { ... }

=head1 DESCRIPTION

Marker role for canonical content blocks that can be embedded inside the
C<content> arrayref of a chat message and serialized to any provider wire
format by L<Langertha::Role::Chat>.

Implementations must provide C<to_openai>, C<to_anthropic>, and C<to_gemini>,
returning the HashRef block the respective provider expects inside its
message content / parts array.

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
