package JIRA::REST::Class::Issue::Comment;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a comment on a JIRA issue as an object.

use Readonly 2.04;

# fields that will be turned into JIRA::REST::Class::User objects
Readonly my @USERS => qw( author updateAuthor );

# fields that will be turned into DateTime objects
Readonly my @DATES => qw( created updated );

__PACKAGE__->mk_ro_accessors( @USERS, @DATES );

__PACKAGE__->mk_data_ro_accessors( qw/ body id self visibility / );

__PACKAGE__->mk_contextual_ro_accessors();

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    # make user objects
    foreach my $field ( @USERS ) {
        $self->populate_scalar_data( $field, 'user', $field );
    }

    # make date objects
    foreach my $field ( @DATES ) {
        $self->{$field} = $self->make_date( $self->data->{$field} );
    }

    return;
}

#pod =method B<delete>
#pod
#pod Deletes the comment from the issue. Returns nothing.
#pod
#pod =cut

sub delete { ## no critic (ProhibitBuiltinHomonyms)
    my $self = shift;
    $self->issue->delete( '/comment/' . $self->id );

    # now that we've deleted this comment, the
    # lazy accessor will need to be reloaded
    undef $self->issue->{comments};

    return;
}

1;

#pod =accessor B<author>
#pod
#pod The author of the comment as a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =accessor B<updateAuthor>
#pod
#pod The updateAuthor of the comment as a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =accessor B<created>
#pod
#pod The created date for the comment as a L<DateTime|DateTime> object.
#pod
#pod =accessor B<updated>
#pod
#pod The updated date for the comment as a L<DateTime|DateTime> object.
#pod
#pod =accessor B<body>
#pod
#pod The body of the comment as a string.
#pod
#pod =accessor B<id>
#pod
#pod The ID of the comment.
#pod
#pod =accessor B<self>
#pod
#pod The full URL for the JIRA REST API call for the comment.
#pod
#pod =accessor B<visibility>
#pod
#pod A hash reference representing the visibility of the comment.
#pod
#pod =for stopwords iconUrl updateAuthor
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik iconUrl updateAuthor

=head1 NAME

JIRA::REST::Class::Issue::Comment - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a comment on a JIRA issue as an object.

=head1 VERSION

version 0.10

=head1 METHODS

=head2 B<delete>

Deletes the comment from the issue. Returns nothing.

=head1 READ-ONLY ACCESSORS

=head2 B<author>

The author of the comment as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<updateAuthor>

The updateAuthor of the comment as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<created>

The created date for the comment as a L<DateTime|DateTime> object.

=head2 B<updated>

The updated date for the comment as a L<DateTime|DateTime> object.

=head2 B<body>

The body of the comment as a string.

=head2 B<id>

The ID of the comment.

=head2 B<self>

The full URL for the JIRA REST API call for the comment.

=head2 B<visibility>

A hash reference representing the visibility of the comment.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::User|JIRA::REST::Class::User>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
