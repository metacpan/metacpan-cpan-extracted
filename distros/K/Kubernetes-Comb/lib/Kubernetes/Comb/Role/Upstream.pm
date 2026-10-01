package Kubernetes::Comb::Role::Upstream;
# ABSTRACT: What a Comb borrows its service from instead of running it
our $VERSION = '0.001';

use Moo::Role;

requires qw( status endpoints );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::Role::Upstream - What a Comb borrows its service from instead of running it

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  package MyApp::Upstream::Catalog;
  use Moo;
  with 'Kubernetes::Comb::Role::Upstream';

  has url => ( is => 'ro', required => 1 );

  sub status {
    my ( $self, $comb ) = @_;
    return Future->done( { reachable => 1, phase => 'Running', via => [ 'vendor' ] } );
  }

  sub endpoints {
    my ( $self, $comb ) = @_;
    return Future->done( [
      Kubernetes::Comb::Endpoint->new( name => 'api', port => 443, cluster => 'catalog.example.com:443' )
    ] );
  }

  # in a Comb class, or returned by the upstream coderef of the controlling code
  sub upstream { '+MyApp::Upstream::Catalog' => ( url => 'https://catalog.example.com' ) }

=head1 DESCRIPTION

An upstream is where a Comb borrows its service from instead of running it
itself. L<Kubernetes::Comb/reconcile> accepts as upstream any object doing
this role, and builds one from the short forms (C<< K8s => (...) >>,
C<< '+Full::Class' => (...) >>) and from C<spec.upstream> of the custom
resource -- the arguments go to C<new>, so an upstream class takes the keys
the custom resource names as its constructor arguments.

The Comb is not a constructor argument: every method gets it as its first
argument, so the upstream can take the Comb's namespace, name and client from
it.

=head2 status

  my $seen = $upstream->status($comb)->get;

Future of a hashref:

=over

=item reachable

Whether the upstream can be used at all. False makes the Comb C<Blocked>,
with C<message> as the reason. An upstream reports unreachability this way,
not by failing: a failed Future makes the Comb C<Error>.

=item phase

The phase the upstream reports for itself; the Comb is C<Running> only while
it is C<Running>.

=item via

Optional arrayref of the layers the service is borrowed through, nearest
first -- for a chain C<[ 'dev', 'prod' ]>.

=item context

Optional kube context of the upstream, recorded in C<status.upstream>.

=item message

Optional, human-readable: why it is unreachable, or what else there is to
know.

=back

=head2 endpoints

  my $endpoints = $upstream->endpoints($comb)->get;

Future of an arrayref of L<Kubernetes::Comb::Endpoint>: what the upstream
offers under which name. The upstream decides which address is reachable:
C<cluster> is the address to use from inside the Comb's cluster (the one the
bridge points at), C<external> the one from outside. Without C<cluster> the
Comb uses C<external> from inside too.

=head2 replicate_into

  $upstream->replicate_into($comb)->get;

Optional. Called with the Comb on every L<Kubernetes::Comb/reconcile> step
that borrows from the upstream, before the bridge is deployed, to replicate
data into it. May return a Future; a failure makes the Comb C<Error>.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb>

=item * L<Kubernetes::Comb::Upstream::K8s>

=item * L<Kubernetes::Comb::Upstream::Static>

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
