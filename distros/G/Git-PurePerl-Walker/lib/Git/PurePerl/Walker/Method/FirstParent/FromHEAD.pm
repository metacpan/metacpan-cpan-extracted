use 5.006;    # our
use strict;
use warnings;

package Git::PurePerl::Walker::Method::FirstParent::FromHEAD;

our $VERSION = '0.004001';

# ABSTRACT: Start at the HEAD of the current repo.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( extends has );







extends 'Git::PurePerl::Walker::Method::FirstParent';






































has '+start' => (
  init_arg   => undef,
  lazy_build => 1,
  required   => 0,
);





has '+_repo' => ( predicate => '_has_repo', );





sub _build_start {
  my $self = shift;
  if ( not $self->_has_repo ) {
    require Carp;
    Carp::confess('No repo defined while trying to find a starting commit');
  }
  return $self->_repo->head_sha1;
}























































no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::PurePerl::Walker::Method::FirstParent::FromHEAD - Start at the HEAD of the current repo.

=head1 VERSION

version 0.004001

=head1 INHERITED METHODS

=head2 for_repository

L<<
C<Git::PurePerl::B<Walker::Role::HasRepo>-E<gt>I<for_repository( $repo )>>
|Git::PurePerl::Walker::Role::HasRepo/for_repository
>>

=head2 clone

L<<
C<MooseX::B<Clone>-E<gt>I<clone( %params )>>
|MooseX::Clone/clone-params
>>

=head2 _repo

L<< C<Git::PurePerl::B<Walker::Role::HasRepo>-E<gt>I<_repo( $repo )>>|Git::PurePerl::Walker::Role::HasRepo/_repo >>

=head2 start

L<< C<Git::PurePerl::B<Walker::Method::FirstParent>-E<gt>I<start( $commit )>>|Git::PurePerl::Walker::Method::FirstParent/start >>

=head2 _commit

L<<
C<Git::PurePerl::B<Walker::Method::FirstParent>-E<gt>I<_commit( $commit_object )>>
|Git::PurePerl::Walker::Method::FirstParent/_commit
>>

=head2 _build_commit

L<<
C<Git::PurePerl::B<Walker::Method::FirstParent>-E<gt>I<_build_commit()>>
|Git::PurePerl::Walker::Method::FirstParent/_build_commit
>>

=head2 current

L<<
C<Git::PurePerl::B<Walker::Method::FirstParent>-E<gt>I<current()>>
|Git::PurePerl::Walker::Method::FirstParent/current
>>

=head2 has_next

L<<
C<Git::PurePerl::B<Walker::Method::FirstParent>-E<gt>I<has_next()>>
|Git::PurePerl::Walker::Method::FirstParent/has_next
>>

=head2 next

L<<
C<Git::PurePerl::B<Walker::Method::FirstParent>-E<gt>I<next()>>
|Git::PurePerl::Walker::Method::FirstParent/next
>>

=head2 peek_next

L<<
C<Git::PurePerl::B<Walker::Method::FirstParent>-E<gt>I<peek_next()>>
|Git::PurePerl::Walker::Method::FirstParent/peek_next
>>

=head2 reset

L<<
C<Git::PurePerl::B<Walker::Method::FirstParent>-E<gt>I<reset()>>
|Git::PurePerl::Walker::Method::FirstParent/reset
>>

=head1 PRIVATE METHODS

=head2 _build_start

=head1 PRIVATE ATTRIBUTE GENERATED METHODS

=head2 _has_repo

=head1 EXTENDS

=head2 Git::PurePerl::Walker::Method::FirstParent

L<< C<Git::PurePerl::B<Walker::Method::FirstParent>>|Git::PurePerl::Walker::Method::FirstParent >>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
