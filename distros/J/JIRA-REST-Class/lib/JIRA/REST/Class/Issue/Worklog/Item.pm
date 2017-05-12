package JIRA::REST::Class::Issue::Worklog::Item;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

use Readonly 2.04;

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an individual worklog item for a JIRA issue as an object.

Readonly my @USERS     => qw( author updateAuthor );
Readonly my @DATES     => qw( created updated );
Readonly my @ACCESSORS => qw( comment id self timeSpent timeSpentSeconds );

__PACKAGE__->mk_ro_accessors( @USERS, @DATES );
__PACKAGE__->mk_data_ro_accessors( @ACCESSORS );

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    # make user objects
    foreach my $field ( @USERS ) {
        $self->populate_scalar_data( $field, 'user', $field );
    }

    # make date objects
    foreach my $field ( @DATES ) {
        $self->populate_date_data( $field, $field );
    }

    return;
}

1;

#pod =accessor B<author>
#pod
#pod This method returns the author of the JIRA issue's work item as a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =accessor B<comment>
#pod
#pod This method returns the comment of the JIRA issue's work item as a string.
#pod
#pod =accessor B<created>
#pod
#pod This method returns the creation time of the JIRA issue's work item as a
#pod L<DateTime|DateTime> object.
#pod
#pod =accessor B<id>
#pod
#pod This method returns the ID of the JIRA issue's work item as a string.
#pod
#pod =accessor B<self>
#pod
#pod This method returns the JIRA REST API URL of the work item as a string.
#pod
#pod =accessor B<started>
#pod
#pod This method returns the start time of the JIRA issue's work item as a
#pod L<DateTime|DateTime> object.
#pod
#pod =accessor B<timeSpent>
#pod
#pod This method returns the time spent on the JIRA issue's work item as a string.
#pod
#pod =accessor B<timeSpentSeconds>
#pod
#pod This method returns the time spent on the JIRA issue's work item as a number
#pod of seconds.
#pod
#pod =accessor B<updateAuthor>
#pod
#pod This method returns the update author of the JIRA issue's work item as a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =accessor B<updated>
#pod
#pod This method returns the update time of the JIRA issue's work item as a
#pod L<DateTime|DateTime> object.
#pod
#pod =cut

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

JIRA::REST::Class::Issue::Worklog::Item - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an individual worklog item for a JIRA issue as an object.

=head1 VERSION

version 0.10

=head1 READ-ONLY ACCESSORS

=head2 B<author>

This method returns the author of the JIRA issue's work item as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<comment>

This method returns the comment of the JIRA issue's work item as a string.

=head2 B<created>

This method returns the creation time of the JIRA issue's work item as a
L<DateTime|DateTime> object.

=head2 B<id>

This method returns the ID of the JIRA issue's work item as a string.

=head2 B<self>

This method returns the JIRA REST API URL of the work item as a string.

=head2 B<started>

This method returns the start time of the JIRA issue's work item as a
L<DateTime|DateTime> object.

=head2 B<timeSpent>

This method returns the time spent on the JIRA issue's work item as a string.

=head2 B<timeSpentSeconds>

This method returns the time spent on the JIRA issue's work item as a number
of seconds.

=head2 B<updateAuthor>

This method returns the update author of the JIRA issue's work item as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<updated>

This method returns the update time of the JIRA issue's work item as a
L<DateTime|DateTime> object.

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
