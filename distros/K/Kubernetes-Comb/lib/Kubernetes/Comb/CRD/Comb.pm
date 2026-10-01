package Kubernetes::Comb::CRD::Comb;
# ABSTRACT: The Comb custom resource
our $VERSION = '0.001';

use IO::K8s::APIObject
  api_version     => 'comb.internal/v1',
  resource_plural => 'combs';
with 'IO::K8s::Role::Namespaced';

use Carp qw( croak );
use Kubernetes::Comb::CRD::CombSpec;
use Kubernetes::Comb::CRD::CombStatus;


k8s spec => '+Kubernetes::Comb::CRD::CombSpec';


k8s status => '+Kubernetes::Comb::CRD::CombStatus';


around to_crd => sub {
  my ( $orig, $self, %args ) = @_;
  my @unknown = sort grep { !/\A(?:group|kind|plural)\z/ } keys %args;
  croak __PACKAGE__.'->to_crd: unknown argument(s) '.join( ', ', @unknown )
    .' (known: group, kind, plural)' if @unknown;
  for my $arg (qw( group kind plural )) {
    croak __PACKAGE__.'->to_crd: '.$arg.' must be a non-empty string'
      if exists $args{$arg} && !( defined $args{$arg} && length $args{$arg} );
  }

  my $crd   = $self->$orig;
  my $spec  = $crd->spec;
  my $names = $spec->names;
  $spec->group( $args{group} ) if exists $args{group};
  if ( exists $args{kind} ) {
    $names->kind( $args{kind} );
    $names->singular( lc $args{kind} );
    $names->listKind( $args{kind}.'List' );
  }
  $names->plural( $args{plural} ) if exists $args{plural};
  $crd->metadata->name( $names->plural.'.'.$spec->group );
  $_->subresources({ status => {} }) for @{ $spec->versions };
  return $crd;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::CRD::Comb - The Comb custom resource

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Kubernetes::Comb::CRD::Comb;

  my $cr = Kubernetes::Comb::CRD::Comb->new(
    metadata => { name => 'nats', namespace => 'platform' },
    spec     => { class => 'MyApp::Comb::NATS', dependsOn => [ 'db' ] }
  );
  print $cr->to_yaml;

  # the CustomResourceDefinition, as an IO::K8s object
  my $crd = Kubernetes::Comb::CRD::Comb->to_crd;
  $rest->ensure_crd('Kubernetes::Comb::CRD::Comb');   # Kubernetes::REST

  # another API group: a three-line subclass, passed as crd_class
  package MyApp::CRD::Comb;
  use Moo; extends 'Kubernetes::Comb::CRD::Comb';
  sub api_version { 'comb.example.com/v1' }

=head1 DESCRIPTION

The C<Comb> custom resource: default group C<comb.internal/v1> (C<.internal>
is reserved for private use and never collides with a real domain), kind
C<Comb>, plural C<combs>, namespaced, with the status subresource. Whoever
manages Combs watches these and builds a live Comb instance from each; the
instance writes its own status back.

L<IO::K8s> fixes C<api_version> when the class is loaded, so another API group
is a subclass, not a runtime switch: the subclass overrides C<api_version>,
and everything else -- C<kind> and C<resource_plural>, the schema, L</to_crd>
-- follows it. Keep C<Comb> as the last segment of the subclass's package
name: IO::K8s derives C<kind> from it. Pass the subclass wherever a
C<crd_class> is taken, for example to L<Kubernetes::Comb::CRD> and to the
Comb itself.

=head2 spec

L<Kubernetes::Comb::CRD::CombSpec>; a hashref is inflated.

=head2 status

L<Kubernetes::Comb::CRD::CombStatus>; a hashref is inflated. Written through
the status subresource only.

=head2 to_crd

  my $crd = Kubernetes::Comb::CRD::Comb->to_crd;
  my $crd = Kubernetes::Comb::CRD::Comb->to_crd(
    group  => 'comb.example.com',
    kind   => 'Comb',
    plural => 'combs'
  );

Returns the C<CustomResourceDefinition> as an L<IO::K8s> object, with the
C<openAPIV3Schema> generated from these classes and the status subresource
enabled. C<group>, C<kind> and C<plural> default to what the class says;
each may be overridden. An overridden value only describes the definition --
a CR class that talks to that group, kind or plural is still a subclass (see
L</DESCRIPTION>), so pass the overrides only to publish a definition for such
a subclass without loading it. Croaks on unknown arguments and on an empty
value.

This extends L<IO::K8s::Role::APIObject/to_crd>, so
L<Kubernetes::REST/ensure_crd> installs the same definition, status
subresource included.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::CRD> -- resource map provider for this class

=item * L<Kubernetes::Comb::CRD::CombSpec>

=item * L<Kubernetes::Comb::CRD::CombStatus>

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
