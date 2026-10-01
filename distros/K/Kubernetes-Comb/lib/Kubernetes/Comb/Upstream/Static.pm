package Kubernetes::Comb::Upstream::Static;
# ABSTRACT: An upstream with fixed endpoints and no cluster behind it
our $VERSION = '0.001';

use Moo;
with 'Kubernetes::Comb::Role::Upstream';

use Carp qw( croak );
use Future;
use Scalar::Util qw( blessed );
use Types::Standard qw( ArrayRef Bool InstanceOf Str );
use Kubernetes::Comb::Endpoint;
use namespace::autoclean;


has _given => (
  is       => 'ro',
  isa      => ArrayRef,
  init_arg => 'endpoints',
  default  => sub { [] }
);

has _offered => (
  is       => 'lazy',
  isa      => ArrayRef[ InstanceOf['Kubernetes::Comb::Endpoint'] ],
  init_arg => undef
);

sub _build__offered {
  my ( $self ) = @_;
  return [ map {
    blessed $_ && $_->isa('Kubernetes::Comb::Endpoint') ? $_
      : ref $_ eq 'HASH' ? $self->endpoint_class->new(%$_)
      : croak ref($self).': an endpoint is a hashref or a Kubernetes::Comb::Endpoint, got '
        .( ref $_ || 'a plain scalar' );
  } @{ $self->_given } ];
}


has phase => ( is => 'ro', isa => Str, default => 'Running' );


has via => ( is => 'ro', isa => ArrayRef[Str], default => sub { [] } );


has reachable => ( is => 'ro', isa => Bool, coerce => 1, default => 1 );


has message => ( is => 'ro', isa => Str, predicate => 1 );


sub BUILD { $_[0]->_offered }

sub endpoint_class { 'Kubernetes::Comb::Endpoint' }


sub status {
  my ( $self, $comb ) = @_;
  return Future->done( {
    reachable => $self->reachable ? 1 : 0,
    phase     => $self->phase,
    via       => [ @{ $self->via } ],
    ( $self->has_message ? ( message => $self->message ) : () )
  } );
}


sub endpoints {
  my ( $self, $comb ) = @_;
  return Future->done( [ @{ $self->_offered } ] );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::Upstream::Static - An upstream with fixed endpoints and no cluster behind it

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # a vendor service, from the controlling code or a class upstream method
  upstream => sub {
    Static => (
      endpoints => [ { name => 'api', port => 443, cluster => 'geoip.vendor.example:443' } ],
      via       => [ 'vendor' ]
    );
  }

  # the same in the custom resource
  upstream:
    class: Kubernetes::Comb::Upstream::Static
    endpoints:
      - { name: api, port: 443, cluster: geoip.vendor.example:443 }
    via: [ vendor ]

=head1 DESCRIPTION

An upstream whose endpoints are given, with nothing to ask: a vendor service,
a process or a Docker container running next to the cluster, or the upper
layers of a chain in a test. Its L</status> is whatever it was built with.

=head2 endpoints

Constructor argument: arrayref of what the upstream offers, each a
L<Kubernetes::Comb::Endpoint> or a hashref of its attributes (C<name>,
C<port>, C<protocol>, C<cluster>, C<external>). C<cluster> is the address to
use from inside the Comb's cluster; without it the Comb uses C<external>.
Default: none. Construction dies on an endpoint that is not one.

=head2 phase

The phase L</status> reports, default C<Running>.

=head2 via

Arrayref of the layers L</status> reports, default none.

=head2 reachable

Whether L</status> reports the upstream reachable, default true.

=head2 message

Optional message L</status> reports.

=head2 endpoint_class

The class hashrefs in L</endpoints> become, L<Kubernetes::Comb::Endpoint>.

=head2 status

Future of C<< { reachable, phase, via, message } >> as built.

=head2 endpoints

Future of the arrayref of the L</endpoints> as L<Kubernetes::Comb::Endpoint>.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::Role::Upstream>

=item * L<Kubernetes::Comb::Upstream::K8s>

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
