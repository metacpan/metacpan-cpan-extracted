package Langertha::Role::ContextSize;
# ABSTRACT: Role for an engine where you can specify the context size (in tokens)
our $VERSION = '0.400';
use Moose::Role;

has context_size => (
  isa => 'Int',
  is => 'ro',
  predicate => 'has_context_size',
);


sub get_context_size {
  my ( $self ) = @_;
  return $self->context_size if $self->has_context_size;
  return $self->default_context_size if $self->can('default_context_size');
  return;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ContextSize - Role for an engine where you can specify the context size (in tokens)

=head1 VERSION

version 0.400

=head2 context_size

The maximum context size in tokens to use for requests. Optional. When not set,
the engine uses its own C<default_context_size> if available, or omits the
parameter from the request.

=head2 get_context_size

    my $size = $engine->get_context_size;

Returns the effective context size: the explicit C<context_size> if set,
otherwise the engine's C<default_context_size>, otherwise C<undef>.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::ResponseSize> - Limit response token count

=item * L<Langertha::Engine::Ollama> - Engine that composes this role

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
