package JIRA::REST::Class::Iterator;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA query as an object.  Allows the user to iterate over the results and retrieve them one by one.  Wraps L<JIRA::REST|JIRA::REST>'s L<set_search_iterator|JIRA::REST/"set_search_iterator PARAMS"> and L<next_issue|JIRA::REST/next_issue> methods to make them a bit more object-like.

use Readonly 2.04;

Readonly my @ACCESSORS => qw( total fetched iterator_args
                              restart_if_lt_total seen_cache );

__PACKAGE__->mk_accessors( @ACCESSORS );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    my $args = $self->iterator_args;

    # if we weren't passed a maxResults, use the default for the class object
    unless ( exists $args->{maxResults} ) {
        $args->{maxResults} = $self->jira->maxResults;
    }

    if ( exists $args->{restart_if_lt_total} ) {
        $self->restart_if_lt_total( $args->{restart_if_lt_total} );
        delete $args->{restart_if_lt_total};
    }

    $self->seen_cache( {} );
    $self->fetched( 0 );
    $self->set_search_iterator;  # fetch the first bunch of issues
    return;
}

#pod =method B<issue_count>
#pod
#pod A count of the number of issues matched by the query.
#pod
#pod =cut

sub issue_count { return shift->total }

#pod =method B<next>
#pod
#pod The next issue returned by the query, as a
#pod L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object.  If there are
#pod no more issues matched by the query, this method returns an undefined value.
#pod
#pod If the L</restart_if_lt_total> method is set to true and the number of
#pod issues fetched is less than the total number of issues matched by the query
#pod (see the L</issue_count> method), this method will rerun the query and keep
#pod returning issues. This is particularly useful if you are transforming a
#pod number of issues through an iterator, and the transformation causes the
#pod issues to no longer match the query.
#pod
#pod =cut

sub next { ## no critic (ProhibitBuiltinHomonyms)
    my $self = shift;

    my $issue = $self->_get_next_unseen_issue;

    if (  !$issue
        && $self->fetched < $self->total
        && $self->restart_if_lt_total ) {

        # ok, we didn't get as many results as we were promised,
        # so let's try the search again
        $self->set_search_iterator;
        $issue = $self->_get_next_unseen_issue;
    }

    if ( $issue ) {
        $self->fetched( $self->fetched + 1 );
        return $self->factory->make_object( 'issue', { data => $issue } );
    }

    return;
}

#pod =internal_method B<_get_next_unseen_issue>
#pod
#pod Method to consolidate code that fetches issues without duplication
#pod
#pod =cut

sub _get_next_unseen_issue {
    my $self  = shift;
    my $issue = $self->JIRA_REST->next_issue;

    # loop if we got an issue but we've seen it already
    while ( $issue && $self->seen_cache->{ $issue->{id} }++ ) {
        $issue = $self->JIRA_REST->next_issue;
    }

    return $issue;
}

#pod =method B<restart_if_lt_total>
#pod
#pod This getter/setter method tells the iterator whether to restart the search
#pod if the number of issues found is less than the issue count returned by the
#pod initial search.
#pod
#pod =cut

#pod =internal_method B<set_search_iterator>
#pod
#pod Method that is used to restart a query that has run out of results prematurely.
#pod
#pod =cut

sub set_search_iterator {
    my $self = shift;
    my $args = shift || $self->iterator_args;

    $self->JIRA_REST->set_search_iterator( $args );

    # fetch results using code borrowed from JIRA::REST
    my $iter = $self->JIRA_REST->{iter};
    $iter->{params}{startAt} = $iter->{offset};
    $iter->{results}
        = $self->JIRA_REST->POST( '/search', undef, $iter->{params} );

    # since there seems to be a problem with getting all the results in one
    # search, let's track how many we get so we can re-search if necessary
    $self->{total}   = $self->JIRA_REST->{iter}->{results}->{total};
    $self->{fetched} = 0;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik

=head1 NAME

JIRA::REST::Class::Iterator - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA query as an object.  Allows the user to iterate over the results and retrieve them one by one.  Wraps L<JIRA::REST|JIRA::REST>'s L<set_search_iterator|JIRA::REST/"set_search_iterator PARAMS"> and L<next_issue|JIRA::REST/next_issue> methods to make them a bit more object-like.

=head1 VERSION

version 0.10

=head1 METHODS

=head2 B<issue_count>

A count of the number of issues matched by the query.

=head2 B<next>

The next issue returned by the query, as a
L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object.  If there are
no more issues matched by the query, this method returns an undefined value.

If the L</restart_if_lt_total> method is set to true and the number of
issues fetched is less than the total number of issues matched by the query
(see the L</issue_count> method), this method will rerun the query and keep
returning issues. This is particularly useful if you are transforming a
number of issues through an iterator, and the transformation causes the
issues to no longer match the query.

=head2 B<restart_if_lt_total>

This getter/setter method tells the iterator whether to restart the search
if the number of issues found is less than the issue count returned by the
initial search.

=head1 INTERNAL METHODS

=head2 B<_get_next_unseen_issue>

Method to consolidate code that fetches issues without duplication

=head2 B<set_search_iterator>

Method that is used to restart a query that has run out of results prematurely.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
