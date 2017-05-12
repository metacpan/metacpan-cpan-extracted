package JIRA::REST::Class::Issue::Transitions;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the state transitions a JIRA issue can go through.  Currently assumes a state diagram consisting of Open/In Progress/Resolved/Reopened/In QA/Verified/Closed.

use Carp;

__PACKAGE__->mk_contextual_ro_accessors( qw/ transitions / );

#pod =method B<transitions>
#pod
#pod Returns an array of
#pod L<JIRA::REST::Class::Issue::Transitions::Transition|JIRA::REST::Class::Issue::Transitions::Transition>
#pod objects representing the transitions the issue can currently go through.
#pod
#pod =accessor B<issue>
#pod
#pod The L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object this is a
#pod transition for.
#pod
#pod =cut

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );
    $self->_refresh_transitions;
    return;
}

sub _refresh_transitions {
    my $self = shift;

    $self->{data}
        = $self->issue->get( '/transitions?expand=transitions.fields' );

    $self->{transitions} = [  #
        map {                 #
            $self->issue->make_object( 'transition', { data => $_ } )
        } @{ $self->data->{transitions} }
    ];

    return;
}

#pod =method B<find_transition_named>
#pod
#pod Returns the transition object for the named transition provided.
#pod
#pod =cut

sub find_transition_named {
    my $self = shift;
    my $name = shift or confess 'no name specified';

    $self->_refresh_transitions;

    foreach my $transition ( $self->transitions ) {
        next unless $transition->name eq $name;
        return $transition;
    }

    croak sprintf "Unable to find transition '%s'\n"
        . "issue status: %s\n"
        . "transitions:  %s\n",
        $name,
        $self->issue->status->name,
        $self->dump( [ $self->transitions ] );
}

#pod =method B<block>
#pod
#pod Blocks the issue.
#pod
#pod =cut

sub block { return shift->find_transition_named( 'Block Issue' )->go( @_ ) }

#pod =method B<close>
#pod
#pod Closes the issue.
#pod
#pod =cut

## no critic (ProhibitBuiltinHomonyms ProhibitAmbiguousNames)
sub close { return shift->find_transition_named( 'Close Issue' )->go( @_ ) }
## use critic

#pod =method B<verify>
#pod
#pod Verifies the issue.
#pod
#pod =cut

sub verify { return shift->find_transition_named( 'Verify Issue' )->go( @_ ) }

#pod =method B<resolve>
#pod
#pod Resolves the issue.
#pod
#pod =cut

sub resolve { return shift->find_transition_named( 'Resolve Issue' )->go( @_ ) }

#pod =method B<reopen>
#pod
#pod Reopens the issue.
#pod
#pod =cut

sub reopen { return shift->find_transition_named( 'Reopen Issue' )->go( @_ ) }

#pod =method B<start_progress>
#pod
#pod Starts progress on the issue.
#pod
#pod =cut

sub start_progress {
    return shift->find_transition_named( 'Start Progress' )->go( @_ );
}

#pod =method B<stop_progress>
#pod
#pod Stops progress on the issue.
#pod
#pod =cut

sub stop_progress {
    return shift->find_transition_named( 'Stop Progress' )->go( @_ );
}

#pod =method B<start_qa>
#pod
#pod Starts QA on the issue.
#pod
#pod =cut

sub start_qa { return shift->find_transition_named( 'Start QA' )->go( @_ ) }

#pod =method B<transition_walk>
#pod
#pod This method takes three unnamed parameters:
#pod   + The name of the end target issue status
#pod   + A hashref mapping possible current states to intermediate states
#pod     that will progress the issue towards the end target issue status
#pod   + A callback subroutine reference that will be called after each
#pod     transition with the name of the current issue state and the name
#pod     of the state it is transitioning to (defaults to an empty subroutine
#pod     reference).
#pod
#pod =cut

my %state_to_transition = (
    'Open'        => 'Stop Progress',
    'In Progress' => 'Start Progress',
    'Resolved'    => 'Resolve Issue',
    'In QA'       => 'Start QA',
    'Verified'    => 'Verify Issue',
    'Closed'      => 'Close Issue',
    'Reopened'    => 'Reopen Issue',
    'Blocked'     => 'Block Issue',
);

sub transition_walk {
    my $self     = shift;
    my $target   = shift;
    my $map      = shift;
    my $callback = shift // sub { };
    my $name     = $self->issue->status->name;

    my $orig_assignee = $self->issue->assignee // q{};

    until ( $name eq $target ) {
        if ( exists $map->{$name} ) {
            my $to = $map->{$name};
            unless ( exists $state_to_transition{$to} ) {
                die "Unknown target state '$to'!\n";
            }
            my $trans
                = $self->find_transition_named( $state_to_transition{$to} );
            $callback->( $name, $to );
            $trans->go;
        }
        else {
            die "Don't know how to transition from '$name' to '$target'!\n";
        }

        # get the new status name
        $name = $self->issue->status->name;
    }

    # put the owner back to who it's supposed
    # to be if it changed during our walk
    my $current_assignee = $self->issue->assignee // q{};
    if ( $current_assignee ne $orig_assignee ) {
        $self->issue->set_assignee( $orig_assignee );
    }

    return;
}

1;

#pod =head1 SEE ALSO
#pod
#pod =head2 JIRA REST API Reference L<Do transition|https://docs.atlassian.com/jira/REST/latest/#api/2/issue-doTransition>
#pod
#pod The fields that can be set on transition, in either the fields parameter or the
#pod update parameter can be determined using the
#pod C</rest/api/2/issue/{issueIdOrKey}/transitions?expand=transitions.fields>
#pod resource. If a field is not configured to appear on the transition screen, then
#pod it will not be in the transition metadata, and a field validation error will
#pod occur if it is submitted.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik

=head1 NAME

JIRA::REST::Class::Issue::Transitions - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the state transitions a JIRA issue can go through.  Currently assumes a state diagram consisting of Open/In Progress/Resolved/Reopened/In QA/Verified/Closed.

=head1 VERSION

version 0.10

=head1 METHODS

=head2 B<transitions>

Returns an array of
L<JIRA::REST::Class::Issue::Transitions::Transition|JIRA::REST::Class::Issue::Transitions::Transition>
objects representing the transitions the issue can currently go through.

=head2 B<find_transition_named>

Returns the transition object for the named transition provided.

=head2 B<block>

Blocks the issue.

=head2 B<close>

Closes the issue.

=head2 B<verify>

Verifies the issue.

=head2 B<resolve>

Resolves the issue.

=head2 B<reopen>

Reopens the issue.

=head2 B<start_progress>

Starts progress on the issue.

=head2 B<stop_progress>

Stops progress on the issue.

=head2 B<start_qa>

Starts QA on the issue.

=head2 B<transition_walk>

This method takes three unnamed parameters:
  + The name of the end target issue status
  + A hashref mapping possible current states to intermediate states
    that will progress the issue towards the end target issue status
  + A callback subroutine reference that will be called after each
    transition with the name of the current issue state and the name
    of the state it is transitioning to (defaults to an empty subroutine
    reference).

=head1 READ-ONLY ACCESSORS

=head2 B<issue>

The L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object this is a
transition for.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue>

=item * L<JIRA::REST::Class::Issue::Transitions::Transition|JIRA::REST::Class::Issue::Transitions::Transition>

=back

=head1 SEE ALSO

=head2 JIRA REST API Reference L<Do transition|https://docs.atlassian.com/jira/REST/latest/#api/2/issue-doTransition>

The fields that can be set on transition, in either the fields parameter or the
update parameter can be determined using the
C</rest/api/2/issue/{issueIdOrKey}/transitions?expand=transitions.fields>
resource. If a field is not configured to appear on the transition screen, then
it will not be in the transition metadata, and a field validation error will
occur if it is submitted.

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
