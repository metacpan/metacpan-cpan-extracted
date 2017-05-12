package JIRA::REST::Class::Issue::Transitions::Transition;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an individual state transition a JIRA issue can go through.

__PACKAGE__->mk_ro_accessors( qw/ issue to / );
__PACKAGE__->mk_data_ro_accessors( qw/ id name hasScreen fields / );
__PACKAGE__->mk_field_ro_accessors( qw/ summary / );

#pod =accessor B<issue>
#pod
#pod The L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object this is a
#pod transition for.
#pod
#pod =accessor B<to>
#pod
#pod The status this transition will move the issue to, represented as a
#pod L<JIRA::REST::Class::Issue::Status|JIRA::REST::Class::Issue::Status> object.
#pod
#pod =accessor B<id>
#pod
#pod The id of the transition.
#pod
#pod =accessor B<>
#pod
#pod The name of the transition.
#pod
#pod =accessor B<fields>
#pod
#pod The fields for the transition.
#pod
#pod =accessor B<summary>
#pod
#pod The summary for the transition.
#pod
#pod =accessor B<hasScreen>
#pod
#pod Heck if I know.
#pod
#pod =cut

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    $self->{to} = $self->make_object( 'status', { data => $self->data->{to} } );

    return;
}

#pod =method B<go>
#pod
#pod Perform the transition represented by this object on the issue.
#pod
#pod =cut

sub go {
    my ( $self, @args ) = @_;
    $self->issue->post(
        '/transitions',
        {
            transition => { id => $self->id },
            @args
        }
    );

    # reload the issue itself, since it's going to have a new status,
    # which will mean new transitions
    $self->issue->reload;

    # reload these new transitions
    $self->issue->transitions->init( $self->factory );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik hasScreen

=head1 NAME

JIRA::REST::Class::Issue::Transitions::Transition - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an individual state transition a JIRA issue can go through.

=head1 VERSION

version 0.10

=head1 METHODS

=head2 B<go>

Perform the transition represented by this object on the issue.

=head1 READ-ONLY ACCESSORS

=head2 B<issue>

The L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object this is a
transition for.

=head2 B<to>

The status this transition will move the issue to, represented as a
L<JIRA::REST::Class::Issue::Status|JIRA::REST::Class::Issue::Status> object.

=head2 B<id>

The id of the transition.

=head2 B<>

The name of the transition.

=head2 B<fields>

The fields for the transition.

=head2 B<summary>

The summary for the transition.

=head2 B<hasScreen>

Heck if I know.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue>

=item * L<JIRA::REST::Class::Issue::Status|JIRA::REST::Class::Issue::Status>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
