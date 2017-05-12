package JIRA::REST::Class::Project;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA project as an object.

use Readonly 2.04;

Readonly my @DATA => qw( avatarUrls expand id key name projectTypeKey self );

__PACKAGE__->mk_data_ro_accessors( @DATA );

Readonly my @LAZY => qw( category assigneeType components description
                         issueTypes subtaskIssueTypes lead roles versions );

for my $field ( @LAZY ) {
    __PACKAGE__->mk_lazy_ro_accessor(
        $field,
        sub {
            my $self = shift;
            $self->_do_lazy_load( @_ );
            $self->{$field};
        }
    );
}

#
# I'm putting this here as a reminder to myself and as an explanation to
# anyone who wonders why I'm lazily loading so much information. There are
# two ways this object can be instantiated: either as a request for all the
# information on a particular project, or as an accessor object wrapping
# the data returned by the GET /rest/api/latest/project API call, which
# only returns the following attributes: "self", "id", "key", "name",
# "avatarUrls", and "projectCategory".  I didn't want to incur a REST API
# call for each of these objects if all they were being used for is
# accessing the data in the project list, so I made the accessors for
# information that wasn't in that list be lazily loaded.  If the end user
# gets an object from the project list method and asks for information that
# only comes from making the full /rest/api/latest/project/{projectIdOrKey}
# API call, we make the call at that time.
#

sub _do_lazy_load {
    my ( $self, @fields ) = @_;

    ( my $url = $self->self ) =~ s{.*/project}{/project}x;
    my $data = $self->jira->get( $url );

    $self->{assigneeType} = $data->{assigneeType};

    my $make_component = sub {
        my $comp = shift;
        return $self->make_object( 'projectcomp', { data => $comp } );
    };

    $self->{components} = [ ##
        map { $make_component->( $_ ) } @{ $data->{components} }
    ];

    $self->{description} = $data->{description};

    my $make_issue_type = sub {
        my $type = shift;
        return $self->make_object( 'issuetype', { data => $type } );
    };

    $self->{issueTypes} = [ ##
        map { $make_issue_type->( $_ ) } @{ $data->{issueTypes} }
    ];

    $self->{subtaskIssueTypes} = [ ##
        grep { $_->subtask } @{ $self->{issueTypes} }
    ];

    $self->{lead} = $self->make_object( 'user', { data => $data->{lead} } );

    $self->{roles} = $data->{roles};

    my $make_project_version = sub {
        my $pv = shift;
        my $vers = $self->make_object( 'projectvers', { data => $pv } );
        $self->{version_hash}->{ $vers->id }
            = $self->{version_hash}->{ $vers->name } = $vers;
        return $vers;
    };

    $self->{versions} = [ ##
        map { $make_project_version->( $_ ) } @{ $data->{versions} }
    ];

    foreach my $field ( @fields ) {
        $self->{lazy_loaded}->{$field} = 1;
    }

    return;
}

#pod =accessor B<assigneeType>
#pod
#pod This accessor returns the assignee type of the project.
#pod
#pod =accessor B<avatarUrls>
#pod
#pod A hashref of the different sizes available for the project's avatar.
#pod
#pod =accessor B<components>
#pod
#pod A list of the components for the project as
#pod L<JIRA::REST::Class::Project::Component|JIRA::REST::Class::Project::Component>
#pod objects.
#pod
#pod =accessor B<description>
#pod
#pod Returns the description of the project.
#pod
#pod =accessor B<expand>
#pod
#pod A comma-separated list of fields in the project that weren't expanded in the initial REST call.
#pod
#pod =accessor B<id>
#pod
#pod Returns the id of the project.
#pod
#pod =accessor B<issueTypes>
#pod
#pod A list of valid issue types for the project as
#pod L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type> objects.
#pod
#pod =accessor B<subtaskIssueTypes>
#pod
#pod Taking a page from the old SOAP interface, this accessor returns a list of
#pod all issue types (as
#pod L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type> objects)
#pod whose subtask field is true.
#pod
#pod =accessor B<key>
#pod
#pod Returns the key of the project.
#pod
#pod =accessor B<lead>
#pod
#pod Returns the project lead as a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =accessor B<name>
#pod
#pod Returns the name of the project.
#pod
#pod =accessor B<category>
#pod
#pod Returns a hashref of the category of the project as
#pod L<JIRA::REST::Class::Project::Category|JIRA::REST::Class::Project::Category>
#pod objects.
#pod
#pod =accessor B<self>
#pod
#pod Returns the JIRA REST API URL of the project.
#pod
#pod =accessor B<versions>
#pod
#pod Returns a list of the versions of the project as
#pod L<JIRA::REST::Class::Project::Version|JIRA::REST::Class::Project::Version>
#pod objects.
#pod
#pod =accessor B<metadata>
#pod
#pod Returns the metadata associated with this project.
#pod
#pod =cut

sub metadata {
    my $self = shift;

    unless ( defined $self->{metadata} ) {
        my ( $first_issue ) = $self->jira->issues(
            {
                jql        => 'project = ' . $self->key,
                maxResults => 1,
            }
        );
        my $issuekey = $first_issue->key;
        $self->{metadata} = $self->jira->get( "/issue/$issuekey/editmeta" );
    }

    return $self->{metadata};
}

#pod =accessor B<allowed_components>
#pod
#pod Returns a list of the allowed values for the 'components' field in the project.
#pod
#pod =cut

sub allowed_components {
    return shift->allowed_field_values( 'components', @_ );
}

#pod =accessor B<allowed_versions>
#pod
#pod Returns a list of the allowed values for the 'versions' field in the project.
#pod
#pod =cut

sub allowed_versions { return shift->allowed_field_values( 'versions', @_ ); }

#pod =accessor B<allowed_fix_versions>
#pod
#pod Returns a list of the allowed values for the 'fixVersions' field in the project.
#pod
#pod =cut

sub allowed_fix_versions {
    return shift->allowed_field_values( 'fixVersions', @_ );
}

#pod =accessor B<allowed_issue_types>
#pod
#pod Returns a list of the allowed values for the 'issuetype' field in the project.
#pod
#pod =cut

sub allowed_issue_types {
    return shift->allowed_field_values( 'issuetype', @_ );
}

#pod =accessor B<allowed_priorities>
#pod
#pod Returns a list of the allowed values for the 'priority' field in the project.
#pod
#pod =cut

sub allowed_priorities {
    return shift->allowed_field_values( 'priority', @_ );
}

#pod =internal_method B<allowed_field_values> FIELD_NAME
#pod
#pod Returns a list of allowable values for the specified field in the project.
#pod
#pod =cut

sub allowed_field_values {
    my $self = shift;
    my $name = shift;

    my @list = map { $_->{name} }
        @{ $self->field_metadata( $name )->{allowedValues} };

    return @list;
}

#pod =internal_method B<field_metadata_exists> FIELD_NAME
#pod
#pod Boolean indicating whether there is metadata for a given field in the project. Read-only.
#pod
#pod =cut

sub field_metadata_exists {
    my $self   = shift;
    my $name   = shift;
    my $fields = $self->metadata->{fields};
    return 1 if exists $fields->{$name};
    my $name2 = $self->field_name( $name );
    return ( exists $fields->{$name2} ? 1 : 0 );
}

#pod =internal_method B<field_metadata> FIELD_NAME
#pod
#pod Looks for metadata under either a field's key or name in the project. Read-only.
#pod
#pod =cut

sub field_metadata {
    my $self   = shift;
    my $name   = shift;
    my $fields = $self->metadata->{fields};
    if ( exists $fields->{$name} ) {
        return $fields->{$name};
    }
    my $name2 = $self->field_name( $name );
    if ( exists $fields->{$name2} ) {
        return $fields->{$name2};
    }
    return;
}

#pod =internal_method B<field_name> FIELD_KEY
#pod
#pod Looks up field names in the project metadata in the project. Read-only.
#pod
#pod =cut

sub field_name {
    my $self = shift;
    my $name = shift;

    unless ( $self->{field_names} ) {
        my $data = $self->metadata->{fields};

        $self->{field_names} = { ##
            map { $data->{$_}->{name} => $_ } keys %$data
        };
    }

    return $self->{field_names}->{$name};
}

#pod =head1 DESCRIPTION
#pod
#pod This object represents a JIRA project as an object.  It is overloaded so it returns the C<key> of the project when stringified, and the C<id> of the project when it is used in a numeric context.  Note, however, that if two of these objects are compared I<as strings>, the C<name> of the projects will be used for the comparison (numeric comparison will compare the C<id>s of the projects).
#pod
#pod =cut

#<<<
use overload
    '""'  => sub { shift->key },
    '0+'  => sub { shift->id },
    '<=>' => sub {
        my ( $A, $B ) = @_;
        my $AA = ref $A ? $A->id : $A;
        my $BB = ref $B ? $B->id : $B;
        $AA <=> $BB;
    },
    'cmp' => sub {
        my ( $A, $B ) = @_;
        my $AA = ref $A ? $A->name : $A;
        my $BB = ref $B ? $B->name : $B;
        $AA cmp $BB;
    };
#>>>

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

JIRA::REST::Class::Project - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents a JIRA project as an object.

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This object represents a JIRA project as an object.  It is overloaded so it returns the C<key> of the project when stringified, and the C<id> of the project when it is used in a numeric context.  Note, however, that if two of these objects are compared I<as strings>, the C<name> of the projects will be used for the comparison (numeric comparison will compare the C<id>s of the projects).

=head1 READ-ONLY ACCESSORS

=head2 B<assigneeType>

This accessor returns the assignee type of the project.

=head2 B<avatarUrls>

A hashref of the different sizes available for the project's avatar.

=head2 B<components>

A list of the components for the project as
L<JIRA::REST::Class::Project::Component|JIRA::REST::Class::Project::Component>
objects.

=head2 B<description>

Returns the description of the project.

=head2 B<expand>

A comma-separated list of fields in the project that weren't expanded in the initial REST call.

=head2 B<id>

Returns the id of the project.

=head2 B<issueTypes>

A list of valid issue types for the project as
L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type> objects.

=head2 B<subtaskIssueTypes>

Taking a page from the old SOAP interface, this accessor returns a list of
all issue types (as
L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type> objects)
whose subtask field is true.

=head2 B<key>

Returns the key of the project.

=head2 B<lead>

Returns the project lead as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<name>

Returns the name of the project.

=head2 B<category>

Returns a hashref of the category of the project as
L<JIRA::REST::Class::Project::Category|JIRA::REST::Class::Project::Category>
objects.

=head2 B<self>

Returns the JIRA REST API URL of the project.

=head2 B<versions>

Returns a list of the versions of the project as
L<JIRA::REST::Class::Project::Version|JIRA::REST::Class::Project::Version>
objects.

=head2 B<metadata>

Returns the metadata associated with this project.

=head2 B<allowed_components>

Returns a list of the allowed values for the 'components' field in the project.

=head2 B<allowed_versions>

Returns a list of the allowed values for the 'versions' field in the project.

=head2 B<allowed_fix_versions>

Returns a list of the allowed values for the 'fixVersions' field in the project.

=head2 B<allowed_issue_types>

Returns a list of the allowed values for the 'issuetype' field in the project.

=head2 B<allowed_priorities>

Returns a list of the allowed values for the 'priority' field in the project.

=head1 INTERNAL METHODS

=head2 B<allowed_field_values> FIELD_NAME

Returns a list of allowable values for the specified field in the project.

=head2 B<field_metadata_exists> FIELD_NAME

Boolean indicating whether there is metadata for a given field in the project. Read-only.

=head2 B<field_metadata> FIELD_NAME

Looks for metadata under either a field's key or name in the project. Read-only.

=head2 B<field_name> FIELD_KEY

Looks up field names in the project metadata in the project. Read-only.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type>

=item * L<JIRA::REST::Class::Project::Category|JIRA::REST::Class::Project::Category>

=item * L<JIRA::REST::Class::Project::Component|JIRA::REST::Class::Project::Component>

=item * L<JIRA::REST::Class::Project::Version|JIRA::REST::Class::Project::Version>

=item * L<JIRA::REST::Class::User|JIRA::REST::Class::User>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
