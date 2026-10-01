package TestComb::Configurable;
# A Comb class for the reconcile tests: what it renders, offers and misses,
# and whether it is optional, come from the instance. Plain POD: t/lib is
# not woven.

use Moo;
extends 'Kubernetes::Comb';

=head1 SYNOPSIS

  my $comb = TestComb::Configurable->new(
    name      => 'nats',                          # else from the crd
    namespace => 'platform',
    k8s       => $fake,
    parts     => [ deployment('nats') ],          # or sub { ... } for manifests
    missing   => [ 'secret nats-auth' ],          # or sub { ... } for check
    offers    => [ { name => 'client', port => 4222 } ],
    needs     => [ 'db' ],                        # else depends_on from the crd
    optional  => 1
  );

=cut

has _name  => ( is => 'ro', init_arg => 'name',  predicate => 1 );
has _needs => ( is => 'ro', init_arg => 'needs', predicate => 1 );

has parts   => ( is => 'rw', default => sub { [] } );
has missing => ( is => 'rw', default => sub { [] } );
has offers  => ( is => 'rw', default => sub { [] } );

has _optional => ( is => 'ro', init_arg => 'optional', default => 0 );

sub name {
  my ( $self ) = @_;
  return $self->_has_name ? $self->_name : $self->SUPER::name;
}

sub depends_on {
  my ( $self ) = @_;
  return $self->_has_needs ? @{ $self->_needs } : $self->SUPER::depends_on;
}

sub manifests { shift->_given('parts') }
sub check     { shift->_given('missing') }
sub endpoints { @{ shift->offers } }

sub optional {
  my ( $self ) = @_;
  return ref $self ? $self->_optional : 0;
}

sub _given {
  my ( $self, $attr ) = @_;
  my $given = $self->$attr;
  return ref $given eq 'CODE' ? $given->($self) : @$given;
}

1;
