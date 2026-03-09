package Langertha::Role::StaticModels;
# ABSTRACT: Role for engines with a hardcoded model list
our $VERSION = '0.305';
use Moose::Role;


has static_models => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  lazy_build => 1,
);


sub list_models {
  my ($self, %opts) = @_;
  my $models = $self->static_models;
  return $opts{full} ? $models : [map { $_->{id} } @$models];
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::StaticModels - Role for engines with a hardcoded model list

=head1 VERSION

version 0.305

=head1 SYNOPSIS

    package My::Engine;
    use Moose;

    extends 'Langertha::Engine::OpenAIBase';

    with 'Langertha::Role::StaticModels';

    sub _build_static_models {[
      { id => 'model-a' },
      { id => 'model-b' },
    ]}

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Provides a C<list_models> implementation that returns a hardcoded model
list without making any HTTP requests. Useful for engines whose API does
not offer a C</models> endpoint (e.g. MiniMax).

The consuming class must implement C<_build_static_models> returning an
ArrayRef of HashRefs, each with at least an C<id> key.

=head2 static_models

ArrayRef of model HashRefs (each with at least an C<id> key). Built by
C<_build_static_models> which the consuming engine must implement.

=head2 list_models

    my $ids  = $engine->list_models;
    my $full = $engine->list_models(full => 1);

Returns the static model list. By default returns an ArrayRef of model
ID strings. Pass C<full =E<gt> 1> for the full model HashRefs.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::Models> - Model selection and caching

=item * L<Langertha::Engine::MiniMax> - Uses this role

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
