use 5.006;    # our
use strict;
use warnings;

package Git::PurePerl::Walker::OnCommit::List;

our $VERSION = '0.004001';

# ABSTRACT: Execute an ordered list of OnCommit events.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has around );
use MooseX::Types::Moose qw( ArrayRef );
use Git::PurePerl::Walker::Types qw( GPPW_OnCommit );
use namespace::autoclean;







with qw( Git::PurePerl::Walker::Role::OnCommit );





























has 'events' => (
  isa => ArrayRef [GPPW_OnCommit],
  is => 'rw',
  handles => {
    all_events => 'elements',
    add_event  => 'push',
  },
  traits  => [qw( Array )],
  default => sub { [] },
);







sub handle {
  my ( $self, $commit ) = @_;
  for my $child ( $self->all_events ) {
    $child->handle($commit);
  }
  return $self;
}







## no critic ( Subroutines::ProhibitBuiltinHomonyms )
sub reset {
  my ( $self, ) = @_;
  for my $child ( $self->events ) {
    $child->reset();
  }
  return $self;
}
## use critic

around add_event => sub {
  my ( $orig, $self, @args ) = @_;
  if ( not $self->_repo ) {
    return $orig->( $self, @args );
  }
  my (@new) = map { $_->for_repository( $self->_repo ) } @args;
  return $orig->( $self, @new );

};
around for_repository => sub {
  my ( $orig, $self, @args ) = @_;
  my $new = $self->$orig(@args);
  $new->events( [ map { $_->for_repository( $args[0] ) } $self->all_events ] );
  return $new;
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::PurePerl::Walker::OnCommit::List - Execute an ordered list of OnCommit events.

=head1 VERSION

version 0.004001

=head1 CONSTRUCTOR ARGUMENTS

=head2 events

=head1 ATTRIBUTES

=head2 events

=head1 ATTRIBUTE GENERATED METHODS

=head2 all_events

=head2 add_event

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
