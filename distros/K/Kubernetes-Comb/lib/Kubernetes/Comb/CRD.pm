package Kubernetes::Comb::CRD;
# ABSTRACT: IO::K8s resource map provider for the Comb custom resource
our $VERSION = '0.001';

use Moo;
with 'IO::K8s::Role::ResourceMap';

use Module::Runtime qw( use_module );
use Types::Standard qw( Str );
use Kubernetes::Comb::CRD::Comb;
use namespace::autoclean;


has crd_class => (
  is      => 'ro',
  isa     => Str,
  default => 'Kubernetes::Comb::CRD::Comb'
);


sub resource_map {
  my ( $self ) = @_;
  my $class = $self->crd_class;
  use_module($class) unless $class->can('kind');
  return {
    $class->kind                         => '+'.$class,
    $class->api_version.'/'.$class->kind => '+'.$class
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::CRD - IO::K8s resource map provider for the Comb custom resource

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Kubernetes::REST;
  use Kubernetes::Comb::CRD;

  my $rest = Kubernetes::REST->new(
    server      => ...,
    credentials => ...,
    with        => [ 'Kubernetes::Comb::CRD' ]
  );
  my $combs = $rest->list('Comb', namespace => 'platform');

  # a CR class in another API group
  my $k8s = IO::K8s->new(
    with => [ Kubernetes::Comb::CRD->new(crd_class => 'MyApp::CRD::Comb') ]
  );

=head1 DESCRIPTION

Registers the Comb custom resource with L<IO::K8s>, so a client resolves the
Kind C<Comb> -- and its qualified name, C<comb.internal/v1/Comb> by default --
to the CR class and inflates Comb objects. Takes the place of the provider
classes IO::K8s ships for its bundled CRDs (C<IO::K8s::Cilium>, ...).

=head2 crd_class

The CR class to register. Defaults to L<Kubernetes::Comb::CRD::Comb>; a
subclass for another API group goes here. Loaded on first use unless it is
already.

=head2 resource_map

Returns the map L<IO::K8s::Role::ResourceMap> asks for: the Kind and the
qualified C<apiVersion/Kind> of L</crd_class>, both pointing at the class. The
qualified entry is there for clients that take a plain C<resource_map> instead
of providers, like L<Net::Async::Kubernetes>.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::CRD::Comb>

=item * L<IO::K8s/with>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-kubernetes-comb/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
