use 5.006;    #our
use strict;
use warnings;

package Git::PurePerl::Walker::Role::HasRepo;

our $VERSION = '0.004001';

# ABSTRACT: An entity that has a repo

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role qw( with has );
use Git::PurePerl::Walker::Types qw( GPPW_Repository );













with qw( MooseX::Clone );









has '_repo' => ( isa => GPPW_Repository, is => 'rw', weak_ref => 1 );


























sub for_repository {
  my ( $self, $repo ) = @_;
  my $clone = $self->clone( _repo => $repo, );
  return $clone;
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::PurePerl::Walker::Role::HasRepo - An entity that has a repo

=head1 VERSION

version 0.004001

=head1 DESCRIPTION

This is a composition role consumed by other roles to provide them with a
private repo property.

This role also folds in L<< C<MooseX::B<Clone>>|MooseX::Clone >> and provides the 'for_repository'
method which sets the repo property.

	package Foo {
		use Moose;
		with 'Git::PurePerl::Walker::Role::HasRepo';
		__PACKAGE__->meta->make_immutable;
	}

	my $factory = Foo->new( %args );

	my $instance = $factory->for_repository( $Git_PurePerl_Repo );

=head1 METHODS

=head2 for_repository

Construct an entity for a given repository.

This internally calls L<< C<MooseX::B<Clone>>|MooseX::Clone >> on the current object, passing the _repo
field to its constructor, producing a separate, disconnected object to work
with.

The rationale behind this is simple: Its very likely users will want one set of
settings for a consuming class, but they'll want to use those same settings with
multiple repositories.

And as each repository will need to maintain its own state for traversal, they
have to normally manually construct an object for each repository, manually
disconnecting the constructor arguments.

This instead is simple:

	my $thing = Thing->new( %args );
	my ( @foos  ) = map { $thing->for_repository( $_ ) } @repos;

And now all C<@foos> can be mangled independently.

=head1 INHERITED METHODS

=head2 clone

L<< C<MooseX::B<Clone>-E<gt>I<clone( %params )>>|MooseX::Clone/clone-params >>

=head1 PRIVATE ATTRIBUTES

=head2 _repo

=head1 PRIVATE ATTRIBUTE GENERATED METHODS

=head2 _repo

=head1 CONSUMED ROLES

=head2 MooseX::Clone

L<< C<MooseX::B<Clone>>|MooseX::Clone >>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
