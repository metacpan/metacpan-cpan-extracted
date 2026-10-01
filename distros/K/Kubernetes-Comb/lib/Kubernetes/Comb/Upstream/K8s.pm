package Kubernetes::Comb::Upstream::K8s;
# ABSTRACT: Borrow a Comb's service from its peer Comb in another kube context
our $VERSION = '0.001';

use Moo;
with 'Kubernetes::Comb::Role::Upstream';

use Future;
use Types::Standard qw( Str );
use Kubernetes::Comb::Endpoint;
use namespace::autoclean;


has context => ( is => 'ro', isa => Str, required => 1 );


has namespace => ( is => 'ro', isa => Str, predicate => 1 );


has name => ( is => 'ro', isa => Str, predicate => 1 );


sub endpoint_class { 'Kubernetes::Comb::Endpoint' }


sub status {
  my ( $self, $comb ) = @_;
  return $self->_observe($comb)->then( sub {
    my ( $seen ) = @_;
    my %status = ( context => $self->context, via => [ $self->context ] );
    return Future->done( { %status, reachable => 0, message => $seen->{error} } )
      if defined $seen->{error};
    my $recorded = $seen->{peer}->status;
    my @unreachable = map { $_->name }
      grep { !defined $self->_address_of( $_, $seen->{same} ) } $self->_published($recorded);
    my $upstream = $recorded ? $recorded->upstream : undef;
    return Future->done( {
      %status,
      reachable => 1,
      ( $recorded && defined $recorded->phase ? ( phase => $recorded->phase ) : () ),
      via       => [ $self->context, $upstream ? @{ $upstream->via // [] } : () ],
      ( @unreachable ? ( message => 'no address reachable from here for endpoint(s) '
        .join( ', ', @unreachable ).': '.( $seen->{same}
          ? $seen->{where}.' publishes none'
          : 'context '.$self->context.' is another API server, and '.$seen->{where}
            .' publishes no external address' ) ) : () )
    } );
  } );
}


sub endpoints {
  my ( $self, $comb ) = @_;
  return $self->_observe($comb)->then( sub {
    my ( $seen ) = @_;
    return Future->fail( $seen->{error} ) if defined $seen->{error};
    return Future->done( [ map {
      my $address = $self->_address_of( $_, $seen->{same} );
      defined $address
        ? $self->endpoint_class->new(
            name    => $_->name,
            port    => $_->port,
            ( defined $_->protocol ? ( protocol => $_->protocol ) : () ),
            cluster => $address,
            ( defined $_->external ? ( external => $_->external ) : () )
          )
        : ();
    } $self->_published( $seen->{peer}->status ) ] );
  } );
}


sub _published {
  my ( $self, $recorded ) = @_;
  return $recorded ? @{ $recorded->endpoints // [] } : ();
}

sub _address_of {
  my ( $self, $endpoint, $same ) = @_;
  return $same ? $endpoint->cluster // $endpoint->external : $endpoint->external;
}

# Future of { peer, same, where } or { error }; never fails.
sub _observe {
  my ( $self, $comb ) = @_;
  my $where;
  return Future->call( sub {
    my $namespace = $self->has_namespace ? $self->namespace : $comb->namespace;
    my $name      = $self->has_name      ? $self->name      : $comb->name;
    $where = 'Comb '.$namespace.'/'.$name.' in context '.$self->context;
    my $client = $comb->k8s->for_context( $self->context );
    my $same = $client->server_url eq $comb->k8s->server_url ? 1 : 0;
    return Future->done( { error => $where.' is this Comb itself' } )
      if $same && $namespace eq $comb->namespace && $name eq $comb->name;
    return $client->get( '+'.$comb->crd_class, $name, namespace => $namespace )->then( sub {
      Future->done( { peer => $_[0], same => $same, where => $where } );
    } );
  } )->else( sub {
    my $error = defined $_[0] ? ( ''.$_[0] ) =~ s/\s+\z//r : 'unknown error';
    Future->done( { error => 'reading '.( $where // 'the peer Comb' ).' failed: '.$error } );
  } );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::Upstream::K8s - Borrow a Comb's service from its peer Comb in another kube context

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # the controlling code: every Comb borrows from its peer in dev
  my $comb = Kubernetes::Comb->from_crd($cr,
    upstream => sub { K8s => ( context => 'dev' ) }
  );

  # the same in the custom resource
  upstream:
    class: Kubernetes::Comb::Upstream::K8s
    context: dev
    namespace: platform     # default: the Comb's own
    name: nats              # default: the Comb's own

=head1 DESCRIPTION

The layering upstream: the service comes from the peer Comb -- the same
Comb, one layer up -- in another kube context. It reads the peer's C<Comb>
custom resource and nothing else, so C<get> on C<combs> in that namespace is
all the access it needs. The custom resource only names the context; the
credentials are those of the local kubeconfig.

The client for the context comes from the Comb's own
(L<Kubernetes::Comb::Role::Client/for_context>), synchronous or asynchronous
alike. The peer is read as the Comb's L<Kubernetes::Comb/crd_class>.

What cannot be read -- a context that is missing or broken, a custom
resource that is not there or not accessible -- is no error: L</status>
reports it unreachable, and the Comb goes C<Blocked> with the reason.

Because every Comb publishes its already resolved endpoints in
C<status.endpoints>, the peer's addresses are the right ones however many
layers are behind it, and L</status> reports them in C<via>.

=head2 context

Required. The kube context the peer lives in, from the kubeconfig the Comb's
own client uses.

=head2 namespace

Namespace of the peer. Default: the Comb's own.

=head2 name

Name of the peer. Default: the Comb's own.

=head2 endpoint_class

The class L</endpoints> builds, L<Kubernetes::Comb::Endpoint>.

=head2 status

  my $seen = $upstream->status($comb)->get;

Future of C<< { reachable, phase, via, context, message } >>: C<phase> is the
peer's, C<via> this L</context> followed by the peer's own C<via>. Never
fails: whatever keeps the peer from being read makes it unreachable, with
the reason in C<message>. So does a peer that is the Comb itself. A
C<message> also names the peer's endpoints that have no address reachable
from here.

=head2 endpoints

  my $endpoints = $upstream->endpoints($comb)->get;

Future of the arrayref of the peer's published endpoints that have an
address reachable from here, as L<Kubernetes::Comb::Endpoint>. When both
contexts point at the same API server (L<Kubernetes::Comb::Role::Client/server_url>)
C<cluster> is the peer's C<cluster> address, else its C<external> one;
C<external> stays the peer's. Fails with the reason when the peer cannot be
read.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::Role::Upstream>

=item * L<Kubernetes::Comb::Upstream::Static>

=item * L<Kubernetes::Comb/reconcile>

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
