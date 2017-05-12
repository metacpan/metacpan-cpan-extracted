package JIRA::REST::Class::Sprint;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the sprint of a JIRA issue as an object (if you're using L<Atlassian GreenHopper|https://www.atlassian.com/software/jira/agile>).

use Readonly 2.04;

Readonly my @ACCESSORS => qw( id rapidViewId state name startDate endDate
                              completeDate sequence );

__PACKAGE__->mk_ro_accessors( @ACCESSORS );

Readonly my $GREENHOPPER_SPRINT => qr{ com [.] atlassian [.] greenhopper [.]
                                       service [.] sprint [.] Sprint }x;

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    my $data = $self->data;
    $data =~ s{ $GREENHOPPER_SPRINT [ ^ \[ ]+ \[ }{}x;
    $data =~ s{\]$}{}x;
    my @fields = split /,/, $data;
    foreach my $field ( @fields ) {
        my ( $k, $v ) = split /=/, $field;
        if ( $v && $v eq '<null>' ) {
            undef $v;
        }
        $self->{$k} = $v;
    }

    return;
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

JIRA::REST::Class::Sprint - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents the sprint of a JIRA issue as an object (if you're using L<Atlassian GreenHopper|https://www.atlassian.com/software/jira/agile>).

=head1 VERSION

version 0.10

=head1 READ-ONLY ACCESSORS

=head2 B<id>

=head2 B<rapidViewId>

=head2 B<state>

=head2 B<name>

=head2 B<startDate>

=head2 B<endDate>

=head2 B<completeDate>

=head2 B<sequence>

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=back

# These methods don't work, probably because JIRA doesn't have a well-defined
# interface for adding/removing issues from a sprint.

sub greenhopper_api_url {
    my $self = shift;
    my $url  = $self->jira->rest_api_url_base;
    $url =~ s{/rest/api/.+}{/rest/greenhopper/latest};
    return $url;
}

sub add_issues {
    my $self = shift;
    my $url = join '/', q{},
      'sprint', $self->id, 'issues', 'add';

    my $args = { issueKeys => \@_ };
    my $host = $self->jira->{rest}->getHost;

    $self->jira->{rest}->setHost($self->greenhopper_api_url);
    $self->jira->{rest}->PUT($url, undef, $args);
    $self->jira->_content;
    $self->jira->{rest}->setHost($host);
}

sub remove_issues {
    my $self = shift;
    my $url = join '/', q{},
      'sprint', $self->id, 'issues', 'remove';
    my $args = { issueKeys => \@_ };
    my $host = $self->jira->{rest}->getHost;

    $self->jira->{rest}->setHost($self->greenhopper_api_url);
    $self->jira->{rest}->PUT($url, undef, $args);
    $self->jira->_content;
    $self->jira->{rest}->setHost($host);
}

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
