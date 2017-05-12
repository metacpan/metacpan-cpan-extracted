package JIRA::REST::Class::Issue::Worklog;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the worklog of a JIRA issue as an object.

__PACKAGE__->mk_contextual_ro_accessors( qw/ items / );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    $self->{data} = $self->issue->get( '/worklog' );
    my $items = $self->{items} = [];

    foreach my $item ( @{ $self->data->{worklogs} } ) {
        push @$items,
            $self->issue->make_object( 'workitem', { data => $item } );
    }

    return;
}

#pod =method B<items>
#pod
#pod Returns a list of individual work items, as
#pod L<JIRA::REST::Class::Issue::Worklog::Item|JIRA::REST::Class::Issue::Worklog::Item>
#pod objects.
#pod
#pod =for stopwords worklog
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik worklog

=head1 NAME

JIRA::REST::Class::Issue::Worklog - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the worklog of a JIRA issue as an object.

=head1 VERSION

version 0.10

=head1 METHODS

=head2 B<items>

Returns a list of individual work items, as
L<JIRA::REST::Class::Issue::Worklog::Item|JIRA::REST::Class::Issue::Worklog::Item>
objects.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Issue::Worklog::Item|JIRA::REST::Class::Issue::Worklog::Item>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
