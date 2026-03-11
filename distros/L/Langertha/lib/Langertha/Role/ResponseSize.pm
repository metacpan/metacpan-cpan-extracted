package Langertha::Role::ResponseSize;
# ABSTRACT: Role for an engine where you can specify the response size (in tokens)
our $VERSION = '0.307';
use Moose::Role;

has response_size => (
  isa => 'Int',
  is => 'ro',
  predicate => 'has_response_size',
);


sub get_response_size {
  my ( $self ) = @_;
  return $self->response_size if $self->has_response_size;
  return $self->default_response_size if $self->can('default_response_size');
  return;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ResponseSize - Role for an engine where you can specify the response size (in tokens)

=head1 VERSION

version 0.307

=head2 response_size

Maximum number of tokens to generate in the response. Optional. When not set,
the engine uses its own C<default_response_size> if available, or omits the
parameter from the request.

=head2 get_response_size

    my $size = $engine->get_response_size;

Returns the effective response size: the explicit C<response_size> if set,
otherwise the engine's C<default_response_size>, otherwise C<undef>.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::ContextSize> - Limit total context tokens

=item * L<Langertha::Role::Temperature> - Sampling temperature

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
