use 5.006;    # our
use strict;
use warnings;

package Git::PurePerl::Walker::Method::FirstParent;

our $VERSION = '0.004001';

# ABSTRACT: Walk down a tree following the first parent.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has );







with qw( Git::PurePerl::Walker::Role::Method );

































has '_commit' => ( isa => 'Maybe[ Object ]', is => 'rw', lazy_build => 1 );
has 'start'   => ( isa => 'Str',             is => 'rw', required   => 1 );





sub _build__commit {
  my ($self) = @_;
  return $self->_repo->get_object( $self->start );
}







sub current {
  my ($self) = @_;
  return $self->_commit;
}







sub has_next {
  my ($self) = @_;
  if ( not $self->_commit ) {
    return;
  }
  if ( not $self->_commit->parent ) {
    return;
  }
  return 1;
}







## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub next {
  my ($self) = @_;
  my $commit;
  $self->_commit( $commit = $self->peek_next );
  return $commit;
}
## use critic







sub peek_next {
  my $commit = (shift)->_commit->parent;
  return $commit;
}







## no critic ( Subroutines::ProhibitBuiltinHomonyms )
sub reset {
  my ($self) = @_;
  $self->_commit( $self->_repo->get_object( $self->start ) );
  return $self;
}
## use critic

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::PurePerl::Walker::Method::FirstParent - Walk down a tree following the first parent.

=head1 VERSION

version 0.004001

=head1 CONSTRUCTOR ARGUMENTS

=head2 start

=head1 ATTRIBUTES

=head2 start

=head1 ATTRIBUTE GENERATED METHODS

=head2 start

=head1 INHERITED METHODS

=head2 for_repository

L<< C<Git::PurePerl::B<Walker::Role::HasRepo>-E<gt>I<for_repository( $repo )>>|Git::PurePerl::Walker::Role::HasRepo/for_repository >>

=head2 clone

L<< C<MooseX::B<Clone>-E<gt>I<clone( %params )>>|MooseX::Clone/clone-params >>

=head2 _repo

L<< C<Git::PurePerl::B<Walker::Role::HasRepo>-E<gt>I<_repo( $repo )>>|Git::PurePerl::Walker::Role::HasRepo/_repo >>

=head1 PRIVATE CONSTRUCTOR ARGUMENTS

=head2 _commit

=head1 PRIVATE ATTRIBUTES

=head2 _commit

=head1 PRIVATE METHODS

=head2 _build_commit

=head1 PRIVATE ATTRIBUTE GENERATED METHODS

=head2 _commit

=head1 CONSUMED ROLES

=head2 Git::PurePerl::Walker::Role::Method

L<< C<Git::PurePerl::B<Walker::Role::Method>>|Git::PurePerl::Walker::Role::Method >>

=head1 ROLE SATISFYING METHODS

=head2 current

L<< C<Git::PurePerl::B<Walker::Role::Method>-E<gt>I<current()>>|Git::PurePerl::Walker::Role::Method/current >>

=head2 has_next

L<< C<Git::PurePerl::B<Walker::Role::Method>-E<gt>I<has_next()>>|Git::PurePerl::Walker::Role::Method/has_next >>

=head2 next

L<< C<Git::PurePerl::B<Walker::Role::Method>-E<gt>I<next()>>|Git::PurePerl::Walker::Role::Method/next >>

=head2 peek_next

L<< C<Git::PurePerl::B<Walker::Role::Method>-E<gt>I<peek_next()>>|Git::PurePerl::Walker::Role::Method/peek_next >>

=head2 reset

L<< C<Git::PurePerl::B<Walker::Role::Method>-E<gt>I<reset()>>|Git::PurePerl::Walker::Role::Method/reset >>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
