package JIRA::REST::Class::Issue::Changelog;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the changelog of a JIRA issue as an object.

__PACKAGE__->mk_contextual_ro_accessors( qw/ changes / );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    $self->{data} = $self->issue->get( '?expand=changelog' );
    my $changes = $self->{changes} = [];

    foreach my $change ( @{ $self->data->{changelog}->{histories} } ) {
        push @$changes,
            $self->issue->make_object( 'change', { data => $change } );
    }

    return;
}

#pod =method B<changes>
#pod
#pod Returns a list of individual changes, as
#pod L<JIRA::REST::Class::Issue::Changelog::Change|JIRA::REST::Class::Issue::Changelog::Change> objects.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik

=head1 NAME

JIRA::REST::Class::Issue::Changelog - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the changelog of a JIRA issue as an object.

=head1 VERSION

version 0.10

=head1 METHODS

=head2 B<changes>

Returns a list of individual changes, as
L<JIRA::REST::Class::Issue::Changelog::Change|JIRA::REST::Class::Issue::Changelog::Change> objects.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Issue::Changelog::Change|JIRA::REST::Class::Issue::Changelog::Change>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
