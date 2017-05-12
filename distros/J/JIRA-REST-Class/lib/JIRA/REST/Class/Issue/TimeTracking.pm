package JIRA::REST::Class::Issue::TimeTracking;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the time tracking for a JIRA issue as an object.

use Contextual::Return;

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    my $data = $self->issue->get( q{}, { fields => 'timetracking' } );
    $self->{data} = $data->{fields}->{timetracking};

    return;
}

#pod =accessor B<originalEstimate>
#pod
#pod Returns the original estimate as a number of seconds in numeric context, and as a w/d/h/m/s string in a string context.
#pod
#pod =cut

sub originalEstimate {
    my $self = shift;
    #<<<
    return
        NUM { $self->data->{originalEstimateSeconds} }
        STR { $self->data->{originalEstimate} }
    ;
    #>>>
}

#pod =accessor B<remainingEstimate>
#pod
#pod Returns the remaining estimate as a number of seconds in numeric context, and as a w/d/h/m/s string in a string context.
#pod
#pod =cut

sub remainingEstimate {
    my $self = shift;
    #<<<
    return
        NUM { $self->data->{remainingEstimateSeconds} }
        STR { $self->data->{remainingEstimate} }
    ;
    #>>>
}

#pod =accessor B<timeSpent>
#pod
#pod Returns the time spent as a number of seconds in numeric context, and as a w/d/h/m/s string in a string context.
#pod
#pod =cut

sub timeSpent {
    my $self = shift;
    #<<<
    return
        NUM { $self->data->{timeSpentSeconds} }
        STR { $self->data->{timeSpent} }
    ;
    #>>>
}

#pod =method B<set_originalEstimate>
#pod
#pod Sets the original estimate to the amount of time given.  Accepts any time format that JIRA uses.
#pod
#pod =cut

sub set_originalEstimate {
    my $self = shift;
    my $est  = shift;
    return $self->update( { originalEstimate => $est } );
}

#pod =method B<set_remainingEstimate>
#pod
#pod Sets the remaining estimate to the amount of time given.  Accepts any time format that JIRA uses.
#pod
#pod =cut

sub set_remainingEstimate {
    my $self = shift;
    my $est  = shift;
    return $self->update( { remainingEstimate => $est } );
}

#pod =method B<update>
#pod
#pod Accepts a hashref of timetracking fields to update. The acceptable fields are determined by JIRA, but I think they're originalEstimate and remainingEstimate.
#pod
#pod =cut

sub update {
    my $self   = shift;
    my $update = shift;

    foreach my $key ( qw/ originalEstimate remainingEstimate / ) {

        # if we're updating the key, don't change it
        next if exists $update->{$key};

        # since we're not updating the key, copy the original value
        # into the update, because the REST interface has an annoying
        # tendency to reset those values if you don't explicitly set them
        if ( defined $self->data->{$key} ) {
            $update->{$key} = $self->data->{$key};
        }
    }

    return $self->issue->put_field( timetracking => $update );
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik Atlassian GreenHopper JRC ScriptRunner TODO
aggregateprogress aggregatetimeestimate aggregatetimeoriginalestimate
assigneeType avatar avatarUrls completeDate displayName duedate
emailAddress endDate fieldtype fixVersions fromString genericized iconUrl
isAssigneeTypeValid issueTypes issuekeys issuelinks issuetype jira jql
lastViewed maxResults originalEstimate originalEstimateSeconds parentkey
projectId rapidViewId remainingEstimate remainingEstimateSeconds
resolutiondate sprintlist startDate subtaskIssueTypes timeSpent
timeSpentSeconds timeestimate timeoriginalestimate timespent timetracking
toString updateAuthor worklog workratio

=head1 NAME

JIRA::REST::Class::Issue::TimeTracking - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the time tracking for a JIRA issue as an object.

=head1 VERSION

version 0.10

=head1 METHODS

=head2 B<set_originalEstimate>

Sets the original estimate to the amount of time given.  Accepts any time format that JIRA uses.

=head2 B<set_remainingEstimate>

Sets the remaining estimate to the amount of time given.  Accepts any time format that JIRA uses.

=head2 B<update>

Accepts a hashref of timetracking fields to update. The acceptable fields are determined by JIRA, but I think they're originalEstimate and remainingEstimate.

=head1 READ-ONLY ACCESSORS

=head2 B<originalEstimate>

Returns the original estimate as a number of seconds in numeric context, and as a w/d/h/m/s string in a string context.

=head2 B<remainingEstimate>

Returns the remaining estimate as a number of seconds in numeric context, and as a w/d/h/m/s string in a string context.

=head2 B<timeSpent>

Returns the time spent as a number of seconds in numeric context, and as a w/d/h/m/s string in a string context.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
