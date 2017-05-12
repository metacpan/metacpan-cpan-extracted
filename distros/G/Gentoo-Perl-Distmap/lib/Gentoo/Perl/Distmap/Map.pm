use strict;
use warnings;

package Gentoo::Perl::Distmap::Map;
BEGIN {
  $Gentoo::Perl::Distmap::Map::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Perl::Distmap::Map::VERSION = '0.2.0';
}

# ABSTRACT: A collection of C<CPAN> distributions mapped to C<Gentoo> ones.

use Moose;

with 'Gentoo::Perl::Distmap::Role::Serialize';


has store => (
  isa     => HashRef =>,
  is      => ro      =>,
  lazy    => 1,
  default => sub     { {} },
  traits  => ['Hash'],
  handles => {
    store_keys => 'keys',
  },
);


sub all_mapped_dists { return ( my (@items) = sort $_[0]->store_keys ) }


sub all_mapped_dists_data {
  return map { $_[0]->store->{$_} } $_[0]->all_mapped_dists;
}


sub mapped_dists {
  my ($self) = @_;
  return grep { $self->store->{$_}->has_versions } $self->all_mapped_dists;
}


sub mapped_dists_data {
  my ($self) = @_;
  return map { $self->store->{$_} } $self->mapped_dists();
}


sub multi_repository_dists {
  my ($self) = @_;
  return grep { $self->store->{$_}->is_multi_repository } $self->all_mapped_dists;
}


sub multi_repository_dists_data {
  my ($self) = @_;
  return map { $self->store->{$_} } $self->multi_repository_dists;
}


sub dists_in_repository {
  my ( $self, $repository ) = @_;
  return grep { $self->store->{$_}->in_repository($repository) } $self->all_mapped_dists;
}


sub dists_in_repository_data {
  my ( $self, $repository ) = @_;
  return map { $self->store->{$_} } $self->dists_in_repository($repository);
}


sub add_version {
  my ( $self, %config ) = @_;
  my %cloned;
  for my $need (qw( distribution category package version repository )) {
    if ( exists $config{$need} ) {
      $cloned{$need} = delete $config{$need};
      next;
    }
    require Carp;
    Carp::confess("Need parameter $need in config");
  }
  if ( keys %config ) {
    require Carp;
    Carp::confess( 'Surplus keys in config: ' . join q[,], keys %config );
  }

  if ( not exists $self->store->{ $cloned{distribution} } ) {
    require Gentoo::Perl::Distmap::RecordSet;
    $self->store->{ $cloned{distribution} } = Gentoo::Perl::Distmap::RecordSet->new();
  }
  my $distro = delete $cloned{distribution};
  $self->store->{$distro}->add_version(%cloned);
  return $self->store->{$distro};
}


sub to_rec {
  my ($self) = @_;
  my $out;
  for my $dist ( keys %{ $self->store } ) {
    $out->{$dist} = $self->store->{$dist}->to_rec;
  }
  return $out;
}


sub from_rec {
  my ( $class, $rec ) = @_;
  if ( ref $rec ne 'HASH' ) {
    require Carp;
    Carp::confess('Can only convert from hash records');
  }
  my $rec_clone = { %{$rec} };
  my $in;
  require Gentoo::Perl::Distmap::RecordSet;
  for my $dist ( keys %{$rec_clone} ) {
    $in->{$dist} = Gentoo::Perl::Distmap::RecordSet->from_rec( $rec_clone->{$dist} );
  }
  return $class->new( store => $in, );
}
__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Gentoo::Perl::Distmap::Map - A collection of C<CPAN> distributions mapped to C<Gentoo> ones.

=head1 VERSION

version 0.2.0

=head1 ATTRIBUTES

=head2 store

=head1 METHODS

=head2 all_mapped_dists

	my @names = $instance->all_mapped_dists();

=head2 all_mapped_dists_data

  my @data = $instance->all_mapped_dists_data()

=head2 mapped_dists

	my @names = $instance->mapped_dists();

=head2 mapped_dists_data

  my @data = $instance->mapped_dists_data()

=head2 multi_repository_dists

	my @names = $instance->multi_repository_dists();

=head2 multi_repository_dists_data

  my @data = $instance->multi_repository_dists_data()

=head2 dists_in_repository

	my @names = $instance->dists_in_repository('gentoo');

=head2 dists_in_repository_data

  my @data = $instance->dists_in_repository_data('gentoo');

=head2 add_version

	$instance->add_version(
		distribution => 'Perl-Dist-Name'
		category     => 'gentoo-category-name',
		package      => 'gentoo-package-name',
		version      => 'gentoo-version',
		repository   => 'gentoo-repository-name',
	);

=head2 to_rec

	my $datastructure = $instance->to_rec

=head1 CLASS METHODS

=head2 from_rec

	my $instance = G:P:D:Map->from_rec( $datastructure );

=head1 ATTRIBUTE METHODS

=head2 store -> store

=head2 store_keys -> store.keys

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
