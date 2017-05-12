package JIRA::REST::Class::User;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA user as an object.

use Readonly 2.04;

Readonly my @ACCESSORS => qw( active avatarUrls displayName emailAddress key
                              name self timeZone );

__PACKAGE__->mk_data_ro_accessors( @ACCESSORS );

1;

#pod =accessor B<active>
#pod
#pod A boolean indicating whether or not the user is active.
#pod
#pod =accessor B<avatarUrls>
#pod
#pod A hashref of the different sizes available for the project's avatar.
#pod
#pod =accessor B<displayName>
#pod
#pod The display name of the user.
#pod
#pod =accessor B<emailAddress>
#pod
#pod The email address of the user.
#pod
#pod =accessor B<key>
#pod
#pod The key for the user.
#pod
#pod =accessor B<name>
#pod
#pod The short name of the user.
#pod
#pod =accessor B<self>
#pod
#pod The URL of the JIRA REST API for the user
#pod
#pod =accessor B<timeZone>
#pod
#pod The home time zone of the user.
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

JIRA::REST::Class::User - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA user as an object.

=head1 VERSION

version 0.10

=head1 READ-ONLY ACCESSORS

=head2 B<active>

A boolean indicating whether or not the user is active.

=head2 B<avatarUrls>

A hashref of the different sizes available for the project's avatar.

=head2 B<displayName>

The display name of the user.

=head2 B<emailAddress>

The email address of the user.

=head2 B<key>

The key for the user.

=head2 B<name>

The short name of the user.

=head2 B<self>

The URL of the JIRA REST API for the user

=head2 B<timeZone>

The home time zone of the user.

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
