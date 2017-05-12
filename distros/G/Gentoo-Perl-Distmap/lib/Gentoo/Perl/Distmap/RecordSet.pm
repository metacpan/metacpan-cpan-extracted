use strict;
use warnings;

package Gentoo::Perl::Distmap::RecordSet;
BEGIN {
  $Gentoo::Perl::Distmap::RecordSet::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Perl::Distmap::RecordSet::VERSION = '0.2.0';
}

# ABSTRACT: A collection of Record objects representing versions in >1 repositories.

use Moose;

with 'Gentoo::Perl::Distmap::Role::Serialize';


has 'records' => (
  isa     => ArrayRef =>,
  is      => ro       =>,
  lazy    => 1,
  traits  => ['Array'],
  default => sub      { [] },
  handles => {
    all_records  => 'elements',
    grep_records => 'grep',
  },
);


sub records_with_versions {
  return $_[0]->grep_records( sub { $_->has_versions } );
}


sub has_versions {
  my $self = shift;
  return scalar $self->records_with_versions;
}


sub is_multi_repository {
  my $self = shift;
  my %seen;
  for my $record ( $self->records_with_versions ) {
    $seen{ $record->repository }++;
  }
  return 1 if scalar keys %seen > 1;
  return;
}


sub in_repository {
  my ( $self, $repository ) = @_;
  return grep { $_->repository eq $repository } $self->records_with_versions;
}


sub find_or_create_record {
  my ( $self, %config ) = @_;
  my %cloned;
  for my $need (qw( category package repository )) {
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
  my (@found) = $self->grep_records(
    sub {
      return unless $_->category eq $cloned{category};
      return unless $_->package eq $cloned{package};
      return unless $_->repository eq $cloned{repository};
      1;
    }
  );
  return $found[0] if scalar @found == 1;
  if ( scalar @found > 1 ) {
    require Carp;
    Carp::confess( sprintf 'Bug: >1 result for ==category(%s) ==package(%s) ==repository(%s) ',
      $cloned{category}, $cloned{package}, $cloned{repository} );
  }
  require Gentoo::Perl::Distmap::Record;
  ## no critic( ProhibitAmbiguousNames )
  my $record = Gentoo::Perl::Distmap::Record->new(
    category   => $cloned{category},
    package    => $cloned{package},
    repository => $cloned{repository},
  );
  push @{ $self->records }, $record;
  return $record;

}


sub add_version {
  my ( $self, %config ) = @_;
  my %cloned;
  for my $need (qw( category package version repository )) {
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
  ## no critic( ProhibitAmbiguousNames )
  my $record = $self->find_or_create_record(
    category   => $cloned{category},
    package    => $cloned{package},
    repository => $cloned{repository},
  );
  if ( scalar grep { $_ eq $cloned{version} } @{ $record->versions_gentoo } ) {
    require Carp;
    Carp::carp( "Tried to insert version $cloned{version} muliple times for "
        . " package $cloned{package} category $cloned{category} repository $cloned{repository}" );
    return;
  }
  $record->add_version( $cloned{version} );
  return;

}


sub to_rec {
  my ($self) = @_;
  return [ map { $_->to_rec } @{ $self->records } ];
}


sub from_rec {
  my ( $class, $rec ) = @_;
  if ( ref $rec ne 'ARRAY' ) {
    require Carp;
    Carp::confess('Can only convert from ARRAY records');
  }
  my $rec_clone = [ @{$rec} ];
  require Gentoo::Perl::Distmap::Record;
  return $class->new( records => [ map { Gentoo::Perl::Distmap::Record->from_rec($_) } @{$rec_clone} ] );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Gentoo::Perl::Distmap::RecordSet - A collection of Record objects representing versions in >1 repositories.

=head1 VERSION

version 0.2.0

=head1 ATTRIBUTES

=head2 records

=head1 METHODS

=head2 records_with_versions

=head2 has_versions

	if( $instance->has_versions() ) {

	}

=head2 is_multi_repository

	if ( $instance->is_multi_repository() ){

	}

=head2 in_repository

	if ( my @records = $instance->in_repository('gentoo') ) {
		/* records from gentoo only */
	}

=head2 find_or_create_record

    my $record = $recordset->find_or_create_record(
        category   => foo  =>,
        package    => bar  =>,
        repository => quux =>,
    );

=head2 add_version

	$instance->add_version(
		category   => 'gentoo-category',
		package    => 'gentoo-package',
		version    => 'gentoo-version',
		repository => 'gentoo-repository',
	);

=head2 to_rec

	my $datastructure = $instance->to_rec

=head1 CLASS METHODS

=head2 from_rec

	my $instance = G:P:D:RecordSet->from_rec( $datastructure );

=head1 ATTRIBUTE METHODS

=head2 records -> records

=head2 all_records -> records.elements

=head2 grep_reords -> records.grep

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
