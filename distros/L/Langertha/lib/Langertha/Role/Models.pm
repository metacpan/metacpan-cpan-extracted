package Langertha::Role::Models;
# ABSTRACT: Role for APIs with several models
our $VERSION = '0.404';
use Moose::Role;

requires qw(
  default_model
);

has models => (
  is => 'rw',
  isa => 'ArrayRef[Str]',
  lazy_build => 1,
);
sub _build_models {
  my ( $self ) = @_;
  return $self->list_models() if $self->can('list_models');
  return [ $self->model ];
}


has model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  lazy_build => 1,
);
sub _build_model {
  my ( $self ) = @_;
  return $self->default_model;
}


# Cache configuration
has models_cache_ttl => (
  is => 'ro',
  isa => 'Int',
  default => sub { 3600 }, # 1 hour default
);


has _models_cache => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { {} },
  traits => ['Hash'],
  handles => {
    _clear_models_cache => 'clear',
  },
);

# Public method to clear the cache
sub clear_models_cache {
  my ($self) = @_;
  $self->_clear_models_cache;
  return;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Models - Role for APIs with several models

=head1 VERSION

version 0.404

=head2 models

ArrayRef of available model name strings. Lazily populated by calling
C<list_models> if the engine supports it, otherwise contains only the
currently selected C<model>.

=head2 model

The model name to use for requests. Defaults to the engine's C<default_model>.
Engines that require this role must implement C<default_model>.

=head2 models_cache_ttl

Time-to-live in seconds for the models list cache. Defaults to C<3600> (one hour).

=head2 clear_models_cache

    $engine->clear_models_cache;

Clears the internal models list cache, forcing a fresh fetch on the next
access to C<models>.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::OpenAPI> - Typically composed alongside this role

=item * L<Langertha::Role::Chat> - Uses C<model> via C<chat_model>

=item * L<Langertha::Role::Embedding> - Uses C<model> via C<embedding_model>

=item * L<Langertha::Role::Transcription> - Uses C<model> via C<transcription_model>

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
