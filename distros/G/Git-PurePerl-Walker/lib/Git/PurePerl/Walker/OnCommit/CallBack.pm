use 5.006;    # our
use strict;
use warnings;

package Git::PurePerl::Walker::OnCommit::CallBack;

our $VERSION = '0.004001';

# ABSTRACT: Execute a sub() for each commit

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has );
use MooseX::Types::Moose qw( CodeRef );
use namespace::autoclean;







with qw( Git::PurePerl::Walker::Role::OnCommit );





























has callback => (
  handles  => { do_callback => 'execute', },
  is       => 'rw',
  isa      => CodeRef,
  required => 1,
  traits   => [qw( Code )],
);







sub handle {
  my ( $self, $commit ) = @_;
  $self->do_callback($commit);
  return $self;
}







## no critic ( Subroutines::ProhibitBuiltinHomonyms )
sub reset {
  return shift;
}
## use critic

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::PurePerl::Walker::OnCommit::CallBack - Execute a sub() for each commit

=head1 VERSION

version 0.004001

=head1 CONSTRUCTOR ARGUMENTS

=head2 callback

=head1 ATTRIBUTES

=head2 callback

=head1 ATTRIBUTE GENERATED METHODS

=head2 callback

=head2 do_callback

=head1 INHERITED METHODS

=head2 for_repository

L<< C<Git::PurePerl::B<Walker::Role::HasRepo>-E<gt>I<for_repository( $repo )>>|Git::PurePerl::Walker::Role::HasRepo/for_repository >>

=head2 clone

L<< C<MooseX::B<Clone>-E<gt>I<clone( %params )>>|MooseX::Clone/clone-params >>

=head2 _repo

L<< C<Git::PurePerl::B<Walker::Role::HasRepo>-E<gt>I<_repo( $repo )>>|Git::PurePerl::Walker::Role::HasRepo/_repo >>

=head1 CONSUMED ROLES

=head2 Git::PurePerl::Walker::Role::OnCommit

L<< C<Git::PurePerl::B<Walker::Role::OnCommit>>|Git::PurePerl::Walker::Role::OnCommit >>

=head1 ROLE SATISFYING METHODS

=head2 handle

L<< C<Git::PurePerl::B<Walker::Role::OnCommit>-E<gt>I<handle( $commit )>>|Git::PurePerl::Walker::Role::OnCommit/handle >>

=head2 reset

L<< C<Git::PurePerl::B<Walker::Role::OnCommit>-E<gt>I<reset()>>|Git::PurePerl::Walker::Role::OnCommit/reset >>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
