use strict;
use warnings;

package Gentoo::Perl::Distmap::Record;
BEGIN {
  $Gentoo::Perl::Distmap::Record::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Perl::Distmap::Record::VERSION = '0.2.0';
}

# ABSTRACT: A Single C<Distmap> Record

use Moose;

with 'Gentoo::Perl::Distmap::Role::Serialize';


has 'category'   => ( isa => Str =>, is => ro =>, required => 1 );
has 'package'    => ( isa => Str =>, is => ro =>, required => 1 );
has 'repository' => ( isa => Str =>, is => ro =>, required => 1 );
has 'versions_gentoo' => (
  isa     => 'ArrayRef[Str]',
  is      => ro =>,
  lazy    => 1,
  default => sub { [] },
  traits  => ['Array'],
  handles => {
    add_version  => 'push',
    has_versions => 'count',
  },
);


sub description {
  my ($self) = @_;
  return sprintf '%s/%s::%s', $self->category, $self->package, $self->repository;
}


sub describe_version {
  my ( $self, $version ) = @_;
  return sprintf '=%s/%s-%s::%s', $self->category, $self->package, $version, $self->repository;
}


sub enumerate_packages {
  my ($self) = @_;
  return map { $self->describe_version($_) } $self->versions_gentoo;
}


sub to_rec {
  my ($self) = @_;
  return {
    category        => $self->category,
    package         => $self->package,
    repository      => $self->repository,
    versions_gentoo => $self->versions_gentoo,
  };
}


sub from_rec {
  my ( $class, $rec ) = @_;
  if ( ref $rec ne 'HASH' ) {
    require Carp;
    Carp::confess('Can only convert from hash records');
  }
  my $rec_clone    = { %{$rec} };
  my $construction = {};
  for my $key (qw( category package repository versions_gentoo )) {
    next unless exists $rec_clone->{$key};
    $construction->{$key} = delete $rec_clone->{$key};
  }
  if ( keys %{$rec_clone} ) {
    require Carp;
    Carp::cluck( 'Unknown keys : ' . join q{,}, keys %{$rec_clone} );
  }
  return $class->new( %{$construction} );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Gentoo::Perl::Distmap::Record - A Single C<Distmap> Record

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    record: {
        category:
        package:
        repository:
        versions_gentoo: [

        ]
    }

    my $record = Gentoo::Perl::Distmap::Record->new(
        category => 'dev-perl',
        package  => 'Moo',
        repository => 'perl-experimental',
    );

    $record->description # dev-perl/Moo::perl-experimental

    $record->has_versions() # undef

    $record->describe_version( '1.1') #     '=dev-perl/Moo-1.1::perl-experimental'

    $record->add_version('1.1');

    my ( @packages ) = $record->enumerate_packages();

    @packages = (
        '=dev-perl/Moo-1.1::perl-experimental'
    )

=head1 ATTRIBUTES

=head2 category

=head2 package

=head2 repository

=head2 versions_gentoo

=head1 METHODS

=head2 description

A pretty description of this object

    say $object->description
    # dev-perl/Foo::gentoo

=head2 describe_version

Like L</description> but for a specified version

    say $object->describe_version('1.1');
    # =dev-perl/Foo-1.1::gentoo

=head2 enumerate_packages

Returns package declarations for all versions

	my @packages = $instance->enumerate_packages();

    # =dev-perl/Foo-1.1::gentoo
    # =dev-perl/Foo-1.2::gentoo

=head2 to_rec

	my $datastructure = $instance->to_rec

=head1 CLASS METHODS

=head2 from_rec

	my $instance = G:P:D:Record->from_rec( $datastructure );

=head1 ATTRIBUTE METHODS

=head2 category -> category

=head2 package -> package

=head2 repository -> repository

=head2 versions_gentoo -> versions_gentoo

=head2 add_version -> versions_gentoo.push

	$instance->add_version('1.1');

=head2 has_versions -> versions_gentoo.count

	if( $instance->has_versions ){

	}

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
