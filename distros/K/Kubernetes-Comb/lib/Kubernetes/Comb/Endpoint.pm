package Kubernetes::Comb::Endpoint;
# ABSTRACT: Value object for an endpoint a Comb offers
our $VERSION = '0.001';

use Moo;
use Carp qw( croak );
use Types::Standard qw( Int Str );
use Kubernetes::Comb::CRD::CombEndpoint;
use namespace::autoclean;


has name => ( is => 'ro', isa => Str, required => 1 );


has protocol => ( is => 'ro', isa => Str, default => 'tcp' );


has port => ( is => 'ro', isa => Int, required => 1 );


has cluster => ( is => 'ro', isa => Str, predicate => 1 );


has external => ( is => 'ro', isa => Str, predicate => 1 );


sub BUILD {
  my ( $self ) = @_;
  my $problem = $self->name_problem( $self->name );
  croak ref($self).': '.$problem if defined $problem;
}

sub name_problem {
  my ( $self, $name ) = @_;
  return if defined $name && length $name <= 63 && $name =~ /\A[a-z0-9](?:[-a-z0-9]*[a-z0-9])?\z/;
  return "the name '".( $name // '' )."' is not a DNS-1123 label (lowercase letters, digits and -, "
    .'alphanumeric at both ends, at most 63 characters), as the name of a Service port must be';
}


sub crd_endpoint_class { 'Kubernetes::Comb::CRD::CombEndpoint' }


sub from_crd {
  my ( $class, $entry ) = @_;
  return $class->new(
    map { defined $entry->$_ ? ( $_ => $entry->$_ ) : () }
      qw( name protocol port cluster external )
  );
}


sub to_crd {
  my ( $self ) = @_;
  return $self->crd_endpoint_class->new(
    name     => $self->name,
    protocol => $self->protocol,
    port     => $self->port,
    ( $self->has_cluster  ? ( cluster  => $self->cluster )  : () ),
    ( $self->has_external ? ( external => $self->external ) : () )
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::Endpoint - Value object for an endpoint a Comb offers

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $ep = Kubernetes::Comb::Endpoint->new(
    name     => 'client',
    port     => 4222,
    cluster  => 'nats.platform.svc:4222',
    external => 'nats.example.com:4222'
  );
  $ep->protocol;   # tcp

  my $status_entry = $ep->to_crd;                           # CombEndpoint
  my $again = Kubernetes::Comb::Endpoint->from_crd($status_entry);

=head1 DESCRIPTION

What a Comb offers under one name: protocol and port as the class declares
them, and the addresses it is reached at once resolved -- C<cluster> from
inside the cluster, C<external> from outside. With an active upstream both
point at the upstream. Immutable; a changed address is a new object.

=head2 name

Required. The name the Comb class declares the endpoint under, e.g. C<client>.
It names the port of the Service the bridge makes, so it must be a DNS-1123
label (see L</name_problem>); construction dies on one that is not.

=head2 protocol

Defaults to C<tcp>.

=head2 port

Required. The port the endpoint is offered on.

=head2 cluster

Optional. Address inside the cluster as C<host:port>; C<has_cluster> tells
whether there is one.

=head2 external

Optional. Address from outside the cluster as C<host:port>; C<has_external>
tells whether there is one.

=head2 name_problem

  my $problem = Kubernetes::Comb::Endpoint->name_problem($name);

Why C<$name> cannot be the name of an endpoint, or nothing when it can: it
must be a DNS-1123 label -- lowercase letters, digits and C<->,
alphanumeric at both ends, at most 63 characters -- because the bridge uses
it as the name of a Service port. Works as class and as instance method.

=head2 crd_endpoint_class

The status-entry class L</to_crd> builds, L<Kubernetes::Comb::CRD::CombEndpoint>.
Override it in a subclass to build another.

=head2 from_crd

  my $ep = Kubernetes::Comb::Endpoint->from_crd($combendpoint);

Builds an endpoint from a L<Kubernetes::Comb::CRD::CombEndpoint>, as found in
C<status.endpoints> of a Comb custom resource. A missing C<protocol> becomes
C<tcp>. Dies when C<name> or C<port> is missing.

=head2 to_crd

  $status->endpoints([ map { $_->to_crd } @endpoints ]);

Returns the endpoint as a L<Kubernetes::Comb::CRD::CombEndpoint> for
C<status.endpoints>.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::CRD::CombEndpoint>

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
