package JIRA::REST::Class::Issue::Changelog::Change;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an individual change to a JIRA issue as an object.

__PACKAGE__->mk_ro_accessors( qw/ author created / );
__PACKAGE__->mk_data_ro_accessors( qw/ id / );
__PACKAGE__->mk_contextual_ro_accessors( qw/ items / );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    # make user object
    $self->populate_scalar_data( 'author', 'user', 'author' );

    # make date object
    $self->populate_date_data( 'created', 'created' );

    # make list of changed items
    $self->populate_list_data( 'items', 'changeitem', 'items' );

    return;
}

1;

#pod =accessor B<author>
#pod
#pod Returns the author of a JIRA issue's change as a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =accessor B<created>
#pod
#pod Returns the creation time of a JIRA issue's change as a L<DateTime|DateTime>
#pod object.
#pod
#pod =accessor B<id>
#pod
#pod Returns the id of a JIRA issue's change.
#pod
#pod =accessor B<items>
#pod
#pod Returns the list of items modified by a JIRA issue's change as a list of
#pod L<JIRA::REST::Class::Issue::Changelog::Change::Item|JIRA::REST::Class::Issue::Changelog::Change::Item>
#pod objects.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik

=head1 NAME

JIRA::REST::Class::Issue::Changelog::Change - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an individual change to a JIRA issue as an object.

=head1 VERSION

version 0.10

=head1 READ-ONLY ACCESSORS

=head2 B<author>

Returns the author of a JIRA issue's change as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<created>

Returns the creation time of a JIRA issue's change as a L<DateTime|DateTime>
object.

=head2 B<id>

Returns the id of a JIRA issue's change.

=head2 B<items>

Returns the list of items modified by a JIRA issue's change as a list of
L<JIRA::REST::Class::Issue::Changelog::Change::Item|JIRA::REST::Class::Issue::Changelog::Change::Item>
objects.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Issue::Changelog::Change::Item|JIRA::REST::Class::Issue::Changelog::Change::Item>

=item * L<JIRA::REST::Class::User|JIRA::REST::Class::User>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
