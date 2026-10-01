package Kubernetes::Comb::Client::Sync;
# ABSTRACT: Synchronous Comb client on Kubernetes::REST, returning done Futures
our $VERSION = '0.001';

use Moo;
with 'Kubernetes::Comb::Role::Client';

use Future;
use Types::Standard qw( InstanceOf Str );
use Kubernetes::REST;
use Kubernetes::REST::Kubeconfig;
use Kubernetes::Comb::CRD;
use namespace::autoclean;


has kubeconfig => ( is => 'ro', isa => Str, predicate => 1 );


has context => ( is => 'ro', isa => Str, predicate => 1 );


has rest => ( is => 'lazy', isa => InstanceOf['Kubernetes::REST'] );

sub _build_rest {
  my ( $self ) = @_;
  my $api = Kubernetes::REST::Kubeconfig->new(
    ( $self->has_kubeconfig ? ( kubeconfig_path => $self->kubeconfig ) : () ),
    ( $self->has_context    ? ( context_name    => $self->context )    : () )
  )->api;
  return Kubernetes::REST->new(
    server      => $api->server,
    credentials => $api->credentials,
    with        => [ Kubernetes::Comb::CRD->new ]
  );
}


sub get           { shift->_call( get           => @_ ) }
sub list          { shift->_call( list          => @_ ) }
sub ensure        { shift->_call( ensure        => @_ ) }
sub delete        { shift->_call( delete        => @_ ) }
sub update        { shift->_call( update        => @_ ) }
sub patch         { shift->_call( patch         => @_ ) }
sub update_status { shift->_call( update_status => @_ ) }
sub patch_status  { shift->_call( patch_status  => @_ ) }
sub log           { shift->_call( log           => @_ ) }

sub _call {
  my ( $self, $method, @args ) = @_;
  return Future->call( sub { Future->done( scalar $self->rest->$method(@args) ) } );
}


sub server_url { shift->rest->server->endpoint }


has _for_context => ( is => 'ro', init_arg => undef, default => sub { {} } );

sub for_context {
  my ( $self, $context ) = @_;
  return $self->_for_context->{$context} //= ref($self)->new(
    ( $self->has_kubeconfig ? ( kubeconfig => $self->kubeconfig ) : () ),
    context => $context
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::Client::Sync - Synchronous Comb client on Kubernetes::REST, returning done Futures

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Kubernetes::Comb::Client::Sync;

  my $k8s = Kubernetes::Comb::Client::Sync->new;                    # current context
  my $k8s = Kubernetes::Comb::Client::Sync->new(context => 'dev');
  my $k8s = Kubernetes::Comb::Client::Sync->new(rest => $rest);     # your own client

  my $pods = $k8s->list('Pod', namespace => 'platform')->get->items;

=head1 DESCRIPTION

The default client of a Comb. Every method of L<Kubernetes::Comb::Role::Client>
runs the request right away through L<Kubernetes::REST> and returns an
already-done L<Future> -- or an already-failed one: whatever
L<Kubernetes::REST> croaks with becomes the failure, nothing is thrown. So
C<< ->get >> on a result never waits for an event loop.

=head2 kubeconfig

Path of the kubeconfig to read. Defaults to what L<Kubernetes::REST::Kubeconfig>
finds: C<$KUBECONFIG>, then F<~/.kube/config>, then the in-cluster service
account.

=head2 context

Kube context to use. Defaults to the kubeconfig's current context.

=head2 rest

The L<Kubernetes::REST> instance. Built on first use from L</kubeconfig> and
L</context>, with L<Kubernetes::Comb::CRD> registered so the Kind C<Comb>
resolves. A failure building it -- no kubeconfig, an unknown context --
fails the Future of the request that needed it. Pass your own to control
everything else.

=head2 get

=head2 list

=head2 ensure

=head2 delete

=head2 update

=head2 patch

=head2 update_status

=head2 patch_status

=head2 log

The request methods of L<Kubernetes::Comb::Role::Client>, each passing its
arguments to the L<Kubernetes::REST> method of the same name and returning an
already-done or already-failed L<Future>.

=head2 server_url

The API server URL of L</rest>.

=head2 for_context

  my $dev = $k8s->for_context('dev');

The client for another context of the same L</kubeconfig> (the default one
when none was given), made on first use and kept: asking again returns the
same one. Nothing is read until its first request.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::Role::Client>

=item * L<Kubernetes::Comb::Client::Async>

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
