package JIRA::REST::Class::Issue;
use parent qw( JIRA::REST::Class::Abstract );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an
# individual JIRA issue as an object.

use Carp;
use Readonly 2.04;
use Scalar::Util qw( weaken );

# creating a bunch of read-only accessors

# contextual returns lists or arrayrefs, depending on context
Readonly my @CONTEXTUAL => qw( components versions );

__PACKAGE__->mk_contextual_ro_accessors( @CONTEXTUAL );

# fields that will be turned into JIRA::REST::Class::User objects
Readonly my @USERS => qw( assignee creator reporter );

# fields that will be turned into DateTime objects
Readonly my @DATES => qw( created duedate lastViewed resolutiondate updated );

# other fields we're objectifying and storing at the top level of the hash
Readonly my @TOP_LEVEL => qw( project issuetype status url );

__PACKAGE__->mk_ro_accessors( @TOP_LEVEL, @USERS, @DATES );

# fields that are under $self->{data}
Readonly my @DATA => qw( expand fields id key self );
__PACKAGE__->mk_data_ro_accessors( @DATA );

# fields that are under $self->{data}->{fields}
Readonly my @FIELDS => qw( aggregateprogress aggregatetimeestimate
                           aggregatetimeoriginalestimate aggregatetimespent
                           description environment fixVersions issuelinks
                           labels priority progress resolution summary
                           timeestimate timeoriginalestimate timespent
                           votes watches workratio );

__PACKAGE__->mk_field_ro_accessors( @FIELDS );

#pod =head1 DESCRIPTION
#pod
#pod This object represents a JIRA issue as an object.  It is overloaded so it
#pod returns the C<key> of the issue when stringified, and the C<id> of the issue
#pod when it is used in a numeric context.  If two of these objects are compared
#pod I<as strings>, the C<key> of the issues will be used for the comparison,
#pod while numeric comparison will compare the C<id>s of the issues.
#pod
#pod =cut

#<<<
use overload
    '""'  => sub { shift->key },
    '0+'  => sub { shift->id  },
    '<=>' => sub {
        my( $A, $B ) = @_;
        my $AA = ref $A ? $A->id : $A;
        my $BB = ref $B ? $B->id : $B;
        $AA <=> $BB
    },
    'cmp' => sub {
        my( $A, $B ) = @_;
        my $AA = ref $A ? $A->key : $A;
        my $BB = ref $B ? $B->key : $B;
        $AA cmp $BB
    };
#>>>

sub init {
    my $self = shift;
    $self->SUPER::init( @_ );

    my $jira = $self->jira;
    $self->{url} = $jira->strip_protocol_and_host( $self->self );

    # make user objects
    foreach my $field ( @USERS ) {
        $self->populate_scalar_field( $field, 'user', $field );
    }

    # make date objects
    foreach my $field ( @DATES ) {
        $self->{$field} = $self->make_date( $self->fields->{$field} );
    }

    $self->populate_list_field( 'components', 'projectcomp', 'components' );
    $self->populate_list_field( 'versions',   'projectvers', 'versions' );
    $self->populate_scalar_field( 'project',   'project',   'project' );
    $self->populate_scalar_field( 'issuetype', 'issuetype', 'issuetype' );
    $self->populate_scalar_field( 'status',    'status',    'status' );
    $self->populate_scalar_field(  #
        'timetracking', 'timetracking', 'timetracking',
    );

    unless ( defined &is_bug ) {

        # if we haven't defined booleans to determine whether or not this
        # issue is a particular type, define those methods now
        foreach my $type ( $jira->issue_types ) {
            ( my $subname = lc 'is_' . $type->name ) =~ s/\s+|\-/_/xmsg;
            $self->make_subroutine(
                $subname,
                sub {
                    shift->fields->{issuetype}->{id} == $type->id;
                }
            );
        }
    }
    return;
}

sub component_count { return scalar @{ shift->{components} } }

#
# rather than just use the minimal information in the issue's
# parent hash, fetch the parent issue fully when someone first
# uses the parent_accessor
#

sub has_parent { return exists shift->fields->{parent} }

__PACKAGE__->mk_lazy_ro_accessor(
    'parent',
    sub {
        my $self = shift;
        return unless $self->has_parent;  # some issues have no parent

        my $parent = $self->fields->{parent}->{self};
        my $url    = $self->jira->strip_protocol_and_host( $parent );
        return $self->make_object(
            'issue',
            {
                data => $self->jira->get( $url )
            }
        );
    }
);

__PACKAGE__->mk_lazy_ro_accessor(
    'changelog',
    sub {
        my $self = shift;
        return $self->make_object( 'changelog' );
    }
);

__PACKAGE__->mk_lazy_ro_accessor(
    'comments',
    sub {
        my $self = shift;
        my $data = $self->get( '/comment' );
        return $self->{comments} = [  #
            map {                     #
                $self->make_object( 'comment', { data => $_ } );
            } @{ $data->{comments} }
        ];
    }
);

__PACKAGE__->mk_lazy_ro_accessor(
    'worklog',
    sub {
        my $self = shift;
        return $self->make_object( 'worklog' );
    }
);

__PACKAGE__->mk_lazy_ro_accessor(
    'transitions',
    sub {
        my $self = shift;
        return $self->make_object( 'transitions' );
    }
);

__PACKAGE__->mk_lazy_ro_accessor(
    'timetracking',
    sub {
        my $self = shift;
        return $self->make_object( 'timetracking' );
    }
);

#pod =internal_method B<make_object>
#pod
#pod A pass-through method that calls
#pod L<JIRA::REST::Class::Factory::make_object()|JIRA::REST::Class::Factory/make_object>,
#pod but adds a weakened link to this issue in the object as well.
#pod
#pod =cut

sub make_object {
    my $self = shift;
    my $type = shift;
    my $args = shift || {};

    # if we weren't passed an issue, link to ourselves
    unless ( exists $args->{issue} ) {
        $args->{issue} = $self;
    }

    my $class = $self->factory->get_factory_class( $type );
    my $obj   = $class->new( $args );

    if ( exists $obj->{issue} ) {
        weaken $obj->{issue};  # make the link to ourselves weak
    }

    $obj->init( $self->factory );  # NOW we call init

    return $obj;
}

###########################################################################

#pod =method B<add_attachments>
#pod
#pod Accepts a list of filenames to be added to the issue as attachments.
#pod
#pod =cut

sub add_attachments {
    my ( $self, @args ) = @_;

    foreach my $file ( @args ) {
        croak "unable to find attachment $file"
            unless -f $file;

        $self->JIRA_REST->attach_files( $self->key, $file );
    }
    return;
}

#pod =method B<add_attachment>
#pod
#pod Accepts a single filename to be added to the issue as an attachment.
#pod
#pod =cut

sub add_attachment {
    my $self = shift;
    my $file = shift;

    croak "unable to find attachment $file"
        unless -f $file;

    return $self->JIRA_REST->attach_files( $self->key, $file );
}

#pod =method B<add_data_attachment>
#pod
#pod Accepts a fake filename and a scalar representing the contents of a file and
#pod adds it to the issue as an attachment.
#pod
#pod =cut

sub add_data_attachment {
    my $self = shift;
    my $name = shift;
    my $data = shift;
    my $url  = q{/} . join q{/}, 'issue', $self->key, 'attachments';

    return $self->jira->data_upload(
        {
            url  => $url,
            name => $name,
            data => $data
        }
    );
}

#pod =method B<add_comment>
#pod
#pod Adds whatever is passed in as a comment on the issue.
#pod
#pod =cut

sub add_comment {
    my $self = shift;
    my $text = shift;
    return $self->post( '/comment', { body => $text } );
}

#pod =method B<add_label>
#pod
#pod Adds whatever is passed in as a label for the issue.
#pod
#pod =cut

sub add_label {
    my $self  = shift;
    my $label = shift;
    return $self->update( labels => [ { add => $label } ] );
}

#pod =method B<remove_label>
#pod
#pod Removes whatever is passed in from the labels for the issue.
#pod
#pod =cut

sub remove_label {
    my $self  = shift;
    my $label = shift;
    return $self->update( labels => [ { remove => $label } ] );
}

#pod =method B<has_label>
#pod
#pod Returns true if the issue has the specified label.
#pod
#pod =cut

sub has_label {
    my $self  = shift;
    my $label = shift;
    foreach my $has ( $self->labels ) {
        return 1 if $label eq $has;
    }
    return 0;
}

#pod =method B<add_component>
#pod
#pod Adds whatever is passed in as a component for the issue.
#pod
#pod =cut

sub add_component {
    my $self = shift;
    my $comp = shift;
    return $self->update( components => [ { add => { name => $comp } } ] );
}

#pod =method B<remove_component>
#pod
#pod Removes whatever is passed in from the components for the issue.
#pod
#pod =cut

sub remove_component {
    my $self = shift;
    my $comp = shift;
    return $self->update( components => [ { remove => { name => $comp } } ] );
}

#pod =method B<set_assignee>
#pod
#pod Sets the assignee for the issue to be the user passed in.  Can either be a
#pod string representing the name or a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =cut

sub set_assignee {
    my ( $self, @args ) = @_;
    my $name = $self->name_for_user( @args );
    return $self->put_field( assignee => { name => $name } );
}

#pod =method B<set_reporter>
#pod
#pod Sets the reporter for the issue to be the user passed in.  Can either be a
#pod string representing the name or a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =cut

sub set_reporter {
    my $self = shift;
    my $name = $self->name_for_user( shift );
    return $self->put_field( reporter => { name => $name } );
}

#pod =method B<add_issue_link>
#pod
#pod Adds a link from this issue to another one.  Accepts the link type (either a
#pod string representing the name or a
#pod L<JIRA::REST::Class::Issue::LinkType|JIRA::REST::Class::Issue::LinkType>),
#pod the issue to be linked to, and (optionally) the direction of the link
#pod (inward/outward).  If the direction cannot be determined from the name of
#pod the link type, the default direction is 'inward';
#pod
#pod =cut

sub add_issue_link {
    my ( $self, $type, $key, $dir ) = @_;
    $key = $self->key_for_issue( $key );
    ( $type, $dir ) = $self->find_link_name_and_direction( $type, $dir );

    my $links = [
        {
            add => {
                type           => { name => $type },
                $dir . 'Issue' => { key  => $key },
            },
        }
    ];
    return $self->update( issuelinks => $links );
}

#pod =method B<add_subtask>
#pod
#pod Adds a subtask to the current issue.  Accepts a hashref with named parameters
#pod C<summary> and C<description>.  If the parameter C<issuetype> is specified,
#pod then a subtask of the specified type is created.  If no issuetype is
#pod specified, then the project is queried for valid subtask types, and, if there
#pod is only one, that type is used.  If the project has more than one valid
#pod subtask type, an issuetype B<MUST> be specified.
#pod
#pod The remaining named parameters are passed to the create issue call as fields.
#pod
#pod =cut

sub add_subtask {
    my ( $self, @args ) = @_;

    my $fields;
    if ( @args == 1 && ref $args[0] && ref $args[0] eq 'HASH' ) {
        $fields = $args[0];
    }
    else { ## backward compatibility
        $fields = $args[2] // {};

        $fields->{summary}     //= shift @args;
        $fields->{description} //= shift @args;
    }

    my $project   = $self->_get_subtask_project( $fields );
    my $parent    = $self->_get_subtask_parent( $fields );
    my $issuetype = $self->_get_subtask_issue_type( $project, $fields );

    my $data = {
        fields => {
            project   => { key => $project->key },
            parent    => { key => $parent->key },
            issuetype => { id  => $issuetype->id },
        }
    };

    if ( $fields ) {
        foreach my $field ( keys %$fields ) {
            next
                if $field eq 'project'
                || $field eq 'parent'
                || $field eq 'issuetype';
            $data->{fields}->{$field} = $fields->{$field};
        }
    }

    my $result = $self->jira->post( '/issue', $data );
    my $url = '/issue/' . $result->{id};

    return $self->factory->make_object(
        'issue',
        {
            data => $self->jira->get( $url )
        }
    );
}

sub _get_subtask_project {
    my ( $self, $fields ) = @_;

    return $self->project
        unless exists $fields->{project} && defined $fields->{project};

    my $proj = $fields->{project};

    if ( $self->obj_isa( $proj, 'project' ) ) {

        # we were passed an issue type object
        return $proj;
    }

    my ( $project ) = grep { ##
        $_->id eq $proj || $_->name eq $proj
    } $self->jira->projects;

    return $project if $project;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    confess "add_subtask() called with unknown project '$proj'";
}

sub _get_subtask_parent {
    my ( $self, $fields ) = @_;

    # if we're not passed a parent parameter, we're the parent
    return $self
        unless exists $fields->{parent} && defined $fields->{parent};

    my $issue = $fields->{parent};
    if ( $self->obj_isa( $issue, 'issue' ) ) {

        # we were passed an issue type object
        return $issue;
    }

    my ( $parent ) = $self->jira->issues( $issue );

    return $parent if $parent;

    local $Carp::CarpLevel = $Carp::CarpLevel + 2;
    confess "add_subtask() called with unknown parent '$issue'";
}

sub _get_subtask_issue_type {
    my ( $self, $project, $fields ) = @_;

    # let's set this once in case we need to throw an exception
    local $Carp::CarpLevel = $Carp::CarpLevel + 2;

    if ( exists $fields->{issuetype} && defined $fields->{issuetype} ) {
        my $type = $fields->{issuetype};

        if ( $self->obj_isa( $type, 'issuetype' ) ) {

            # we were passed an issue type object
            return $type if $type->subtask;

            confess
                "add_subtask() called with a non-subtask issue type: '$type'";
        }

        my ( $issuetype ) = grep { ##
            $_->id eq $type || $_->name eq $type
        } $project->issueTypes;

        return $issuetype if $issuetype && $issuetype->subtask;

        if ( !defined $issuetype ) {
            confess 'add_subtask() called with a value that does not '
                . "correspond to a known issue type: '$type'";
        }

        confess
            "add_subtask() called with a non-subtask issue type: '$issuetype'";
    }

    # we didn't get passed an issue type, so let's find one

    my @subtasks = $self->project->subtaskIssueTypes;

    if ( @subtasks == 1 ) {
        return $subtasks[0];
    }

    my $count = scalar @subtasks;
    my $list = join q{, } => @subtasks;

    confess 'add_subtask() called without specifying a subtask type; '
        . "there are $count subtask types: $list";
}

###########################################################################

#pod =method B<update>
#pod
#pod Puts an update to JIRA.  Accepts a hash of fields => values to be put.
#pod
#pod =cut

sub update {
    my $self = shift;
    my $hash = {};
    while ( @_ ) {
        my $field = shift;
        my $value = shift;
        $hash->{$field} = $value;
    }
    return $self->put(
        {
            update => $hash,
        }
    );
}

#pod =method B<put_field>
#pod
#pod Puts a value to a field.  Accepts the field name and the value as parameters.
#pod
#pod =cut

sub put_field {
    my $self  = shift;
    my $field = shift;
    my $value = shift;
    return $self->put(
        {
            fields => { $field => $value },
        }
    );
}

#pod =method B<reload>
#pod
#pod Reload the issue from the JIRA server.
#pod
#pod =cut

sub reload {
    my $self = shift;
    $self->{data} = $self->get;
    $self->init( $self->factory );
    return;
}

###########################################################################

#pod =internal_method B<get>
#pod
#pod Wrapper around C<JIRA::REST::Class>' L<get|JIRA::REST::Class/get> method that
#pod defaults to this issue's URL. Allows for extra parameters to be specified.
#pod
#pod =cut

sub get {
    my ( $self, $extra, @args ) = @_;
    $extra //= q{};
    return $self->jira->get( $self->url . $extra, @args );
}

#pod =internal_method B<post>
#pod
#pod Wrapper around C<JIRA::REST::Class>' L<post|JIRA::REST::Class/post> method
#pod that defaults to this issue's URL. Allows for extra parameters to be
#pod specified.
#pod
#pod =cut

sub post {
    my ( $self, $extra, @args ) = @_;
    $extra //= q{};
    return $self->jira->post( $self->url . $extra, @args );
}

#pod =internal_method B<put>
#pod
#pod Wrapper around C<JIRA::REST::Class>' L<put|JIRA::REST::Class/put> method that
#pod defaults to this issue's URL. Allows for extra parameters to be specified.
#pod
#pod =cut

sub put {
    my ( $self, @args ) = @_;
    return $self->jira->put( $self->url, @args );
}

#pod =internal_method B<delete>
#pod
#pod Wrapper around C<JIRA::REST::Class>' L<delete|JIRA::REST::Class/delete> method
#pod that defaults to this issue's URL. Allows for extra parameters to be
#pod specified.
#pod
#pod =cut

sub delete { ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $extra, @args ) = @_;
    $extra //= q{};
    return $self->jira->delete( $self->url . $extra, @args );
}

#pod =method B<sprints>
#pod
#pod Generates a list of L<JIRA::REST::Class::Sprint|JIRA::REST::Class::Sprint>
#pod objects from the fields for an issue.  Uses the field_name() accessor on the
#pod L<JIRA::REST::Class::Project|JIRA::REST::Class::Project/"field_name
#pod FIELD_KEY"> object to determine the name of the custom sprint
#pod field. Currently, this only really works if you're using L<Atlassian
#pod GreenHopper|https://www.atlassian.com/software/jira/agile>.
#pod
#pod =cut

__PACKAGE__->mk_lazy_ro_accessor(
    'sprints',
    sub {
        my $self = shift;

        # in my configuration, 'Sprint' is a custom field
        my $sprint_field = $self->project->field_name( 'Sprint' );

        my @sprints;
        foreach my $sprint ( @{ $self->fields->{$sprint_field} } ) {
            push @sprints, $self->make_object( 'sprint', { data => $sprint } );
        }
        return \@sprints;
    }
);

#<<<

#pod =method B<children>
#pod
#pod Returns a list of issue objects that are children of the issue. Currently
#pod requires the L<ScriptRunner
#pod plugin|https://marketplace.atlassian.com/plugins/com.onresolve.jira.groovy.groovyrunner/cloud/overview>.
#pod
#pod =cut

#>>>

sub children {
    my $self     = shift;
    my $key      = $self->key;
    my $children = $self->jira->query(
        {
            jql => qq{issueFunction in subtasksOf("key = $key")}
        }
    );

    return unless $children->issue_count;
    return $children->issues;
}

###########################################################################

#pod =method B<start_progress>
#pod
#pod Moves the status of the issue to 'In Progress', regardless of what the current
#pod status is.
#pod
#pod =cut

sub start_progress {
    my $self     = shift;
    my $callback = shift;
    $callback //= sub { };

    return $self->transitions->transition_walk(
        'In Progress',
        {
            'Open'     => 'In Progress',
            'Reopened' => 'In Progress',
            'In QA'    => 'In Progress',
            'Blocked'  => 'In Progress',
            'Resolved' => 'Reopened',
            'Verified' => 'Reopened',
            'Closed'   => 'Reopened',
        },
        $callback
    );
}

#pod =method B<start_qa>
#pod
#pod Moves the status of the issue to 'In QA', regardless of what the current
#pod status is.
#pod
#pod =cut

sub start_qa {
    my $self     = shift;
    my $callback = shift;
    $callback //= sub { };

    return $self->transitions->transition_walk(
        'In QA',
        {
            'Open'        => 'In Progress',
            'In Progress' => 'Resolved',
            'Reopened'    => 'Resolved',
            'Resolved'    => 'In QA',
            'Blocked'     => 'In QA',
            'Verified'    => 'Reopened',
            'Closed'      => 'Reopened',
        },
        $callback
    );
}

#pod =method B<resolve>
#pod
#pod Moves the status of the issue to 'Resolved', regardless of what the current
#pod status is.
#pod
#pod =cut

sub resolve {
    my $self     = shift;
    my $callback = shift;
    $callback //= sub { };

    return $self->transitions->transition_walk(
        'Resolved',
        {
            'Open'        => 'In Progress',
            'In Progress' => 'Resolved',
            'Reopened'    => 'Resolved',
            'Blocked'     => 'In Progress',
            'In QA'       => 'In Progress',
            'Verified'    => 'Reopened',
            'Closed'      => 'Reopened',
        },
        $callback
    );
}

#pod =method B<open>
#pod
#pod Moves the status of the issue to 'Open', regardless of what the current status is.
#pod
#pod =cut

sub open { ## no critic (ProhibitBuiltinHomonyms)
    my $self     = shift;
    my $callback = shift;
    $callback //= sub { };

    return $self->transitions->transition_walk(
        'Open',
        {
            'In Progress' => 'Open',
            'Reopened'    => 'In Progress',
            'Blocked'     => 'In Progress',
            'In QA'       => 'In Progress',
            'Resolved'    => 'Reopened',
            'Verified'    => 'Reopened',
            'Closed'      => 'Reopened',
        },
        $callback
    );
}

#pod =method B<close>
#pod
#pod Moves the status of the issue to 'Closed', regardless of what the current status is.
#pod
#pod =cut

sub close { ## no critic (ProhibitBuiltinHomonyms ProhibitAmbiguousNames)
    my $self     = shift;
    my $callback = shift;
    $callback //= sub { };

    return $self->transitions->transition_walk(
        'Closed',
        {
            'Open'        => 'In Progress',
            'In Progress' => 'Resolved',
            'Reopened'    => 'Resolved',
            'Blocked'     => 'In Progress',
            'In QA'       => 'Verified',
            'Resolved'    => 'Closed',
            'Verified'    => 'Closed',
        },
        $callback
    );
}

1;

#pod =accessor B<expand>
#pod
#pod A comma-separated list of fields in the issue that weren't expanded in the
#pod initial REST call.
#pod
#pod =accessor B<fields>
#pod
#pod Returns a reference to the fields hash for the issue.
#pod
#pod =accessor B<aggregateprogress>
#pod
#pod Returns the aggregate progress for the issue as a hash reference.
#pod
#pod TODO: Turn this into an object.
#pod
#pod =accessor B<aggregatetimeestimate>
#pod
#pod Returns the aggregate time estimate for the issue.
#pod
#pod TODO: Turn this into an object that can return either seconds or a w/d/h/m/s
#pod string.
#pod
#pod =accessor B<aggregatetimeoriginalestimate>
#pod
#pod Returns the aggregate time original estimate for the issue.
#pod
#pod TODO: Turn this into an object that can return either seconds or a w/d/h/m/s
#pod string.
#pod
#pod =accessor B<aggregatetimespent>
#pod
#pod Returns the aggregate time spent for the issue.
#pod
#pod TODO: Turn this into an object that can return either seconds or a w/d/h/m/s
#pod string.
#pod
#pod =accessor B<assignee>
#pod
#pod Returns the issue's assignee as a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =accessor B<changelog>
#pod
#pod Returns the issue's change log as a
#pod L<JIRA::REST::Class::Issue::Changelog|JIRA::REST::Class::Issue::Changelog>
#pod object.
#pod
#pod =accessor B<comments>
#pod
#pod Returns a list of the issue's comments as
#pod L<JIRA::REST::Class::Issue::Comment|JIRA::REST::Class::Issue::Comment>
#pod objects. If called in a scalar context, returns an array reference to the
#pod list, not the number of elements in the list.
#pod
#pod =accessor B<components>
#pod
#pod Returns a list of the issue's components as
#pod L<JIRA::REST::Class::Project::Component|JIRA::REST::Class::Project::Component>
#pod objects. If called in a scalar context, returns an array reference to the
#pod list, not the number of elements in the list.
#pod
#pod =accessor B<component_count>
#pod
#pod Returns a count of the issue's components.
#pod
#pod =accessor B<created>
#pod
#pod Returns the issue's creation date as a L<DateTime|DateTime> object.
#pod
#pod =accessor B<creator>
#pod
#pod Returns the issue's assignee as a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =accessor B<description>
#pod
#pod Returns the description of the issue.
#pod
#pod =accessor B<duedate>
#pod
#pod Returns the issue's due date as a L<DateTime|DateTime> object.
#pod
#pod =accessor B<environment>
#pod
#pod Returns the issue's environment as a hash reference.
#pod
#pod TODO: Turn this into an object.
#pod
#pod =accessor B<fixVersions>
#pod
#pod Returns a list of the issue's fixVersions.
#pod
#pod TODO: Turn this into a list of objects.
#pod
#pod =accessor B<issuelinks>
#pod
#pod Returns a list of the issue's links.
#pod
#pod TODO: Turn this into a list of objects.
#pod
#pod =accessor B<issuetype>
#pod
#pod Returns the issue type as a
#pod L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type> object.
#pod
#pod =accessor B<labels>
#pod
#pod Returns the issue's labels as an array reference.
#pod
#pod =accessor B<lastViewed>
#pod
#pod Returns the issue's last view date as a L<DateTime|DateTime> object.
#pod
#pod =accessor B<parent>
#pod
#pod Returns the issue's parent as a
#pod L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object.
#pod
#pod =accessor B<has_parent>
#pod
#pod Returns a boolean indicating whether the issue has a parent.
#pod
#pod =accessor B<priority>
#pod
#pod Returns the issue's priority as a hash reference.
#pod
#pod TODO: Turn this into an object.
#pod
#pod =accessor B<progress>
#pod
#pod Returns the issue's progress as a hash reference.
#pod
#pod TODO: Turn this into an object.
#pod
#pod =accessor B<project>
#pod
#pod Returns the issue's project as a
#pod L<JIRA::REST::Class::Project|JIRA::REST::Class::Project> object.
#pod
#pod =accessor B<reporter>
#pod
#pod Returns the issue's reporter as a
#pod L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.
#pod
#pod =accessor B<resolution>
#pod
#pod Returns the issue's resolution.
#pod
#pod TODO: Turn this into an object.
#pod
#pod =accessor B<resolutiondate>
#pod
#pod Returns the issue's resolution date as a L<DateTime|DateTime> object.
#pod
#pod =accessor B<status>
#pod
#pod Returns the issue's status as a
#pod L<JIRA::REST::Class::Issue::Status|JIRA::REST::Class::Issue::Status> object.
#pod
#pod =accessor B<summary>
#pod
#pod Returns the summary of the issue.
#pod
#pod =accessor B<timeestimate>
#pod
#pod Returns the time estimate for the issue.
#pod
#pod TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.
#pod
#pod =accessor B<timeoriginalestimate>
#pod
#pod Returns the time original estimate for the issue.
#pod
#pod TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.
#pod
#pod =accessor B<timespent>
#pod
#pod Returns the time spent for the issue.
#pod
#pod TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.
#pod
#pod =accessor B<timetracking>
#pod
#pod Returns the time tracking of the issue as a
#pod L<JIRA::REST::Class::Issue::TimeTracking|JIRA::REST::Class::Issue::TimeTracking>
#pod object.
#pod
#pod =accessor B<transitions>
#pod
#pod Returns the valid transitions for the issue as a
#pod L<JIRA::REST::Class::Issue::Transitions|JIRA::REST::Class::Issue::Transitions>
#pod object.
#pod
#pod =accessor B<updated>
#pod
#pod Returns the issue's updated date as a L<DateTime|DateTime> object.
#pod
#pod =accessor B<versions>
#pod
#pod versions
#pod
#pod =accessor B<votes>
#pod
#pod votes
#pod
#pod =accessor B<watches>
#pod
#pod watches
#pod
#pod =accessor B<worklog>
#pod
#pod Returns the issue's change log as a
#pod L<JIRA::REST::Class::Worklog|JIRA::REST::Class::Worklog> object.
#pod
#pod =accessor B<workratio>
#pod
#pod workratio
#pod
#pod =accessor B<id>
#pod
#pod Returns the issue ID.
#pod
#pod =accessor B<key>
#pod
#pod Returns the issue key.
#pod
#pod =accessor B<self>
#pod
#pod Returns the JIRA REST API's full URL for this issue.
#pod
#pod =accessor B<url>
#pod
#pod Returns the JIRA REST API's URL for this issue in a form used by
#pod L<JIRA::REST::Class|JIRA::REST::Class>.
#pod
#pod =for stopwords aggregatetimespent
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik aggregatetimespent Atlassian GreenHopper JRC
ScriptRunner TODO aggregateprogress aggregatetimeestimate
aggregatetimeoriginalestimate assigneeType avatar avatarUrls completeDate
displayName duedate emailAddress endDate fieldtype fixVersions fromString
genericized iconUrl isAssigneeTypeValid issueTypes issuekeys issuelinks
issuetype jira jql lastViewed maxResults originalEstimate
originalEstimateSeconds parentkey projectId rapidViewId remainingEstimate
remainingEstimateSeconds resolutiondate sprintlist startDate
subtaskIssueTypes timeSpent timeSpentSeconds timeestimate
timeoriginalestimate timespent timetracking toString updateAuthor worklog
workratio

=head1 NAME

JIRA::REST::Class::Issue - A helper class for L<JIRA::REST::Class|JIRA::REST::Class> that represents an

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This object represents a JIRA issue as an object.  It is overloaded so it
returns the C<key> of the issue when stringified, and the C<id> of the issue
when it is used in a numeric context.  If two of these objects are compared
I<as strings>, the C<key> of the issues will be used for the comparison,
while numeric comparison will compare the C<id>s of the issues.

=head1 METHODS

=head2 B<add_attachments>

Accepts a list of filenames to be added to the issue as attachments.

=head2 B<add_attachment>

Accepts a single filename to be added to the issue as an attachment.

=head2 B<add_data_attachment>

Accepts a fake filename and a scalar representing the contents of a file and
adds it to the issue as an attachment.

=head2 B<add_comment>

Adds whatever is passed in as a comment on the issue.

=head2 B<add_label>

Adds whatever is passed in as a label for the issue.

=head2 B<remove_label>

Removes whatever is passed in from the labels for the issue.

=head2 B<has_label>

Returns true if the issue has the specified label.

=head2 B<add_component>

Adds whatever is passed in as a component for the issue.

=head2 B<remove_component>

Removes whatever is passed in from the components for the issue.

=head2 B<set_assignee>

Sets the assignee for the issue to be the user passed in.  Can either be a
string representing the name or a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<set_reporter>

Sets the reporter for the issue to be the user passed in.  Can either be a
string representing the name or a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<add_issue_link>

Adds a link from this issue to another one.  Accepts the link type (either a
string representing the name or a
L<JIRA::REST::Class::Issue::LinkType|JIRA::REST::Class::Issue::LinkType>),
the issue to be linked to, and (optionally) the direction of the link
(inward/outward).  If the direction cannot be determined from the name of
the link type, the default direction is 'inward';

=head2 B<add_subtask>

Adds a subtask to the current issue.  Accepts a hashref with named parameters
C<summary> and C<description>.  If the parameter C<issuetype> is specified,
then a subtask of the specified type is created.  If no issuetype is
specified, then the project is queried for valid subtask types, and, if there
is only one, that type is used.  If the project has more than one valid
subtask type, an issuetype B<MUST> be specified.

The remaining named parameters are passed to the create issue call as fields.

=head2 B<update>

Puts an update to JIRA.  Accepts a hash of fields => values to be put.

=head2 B<put_field>

Puts a value to a field.  Accepts the field name and the value as parameters.

=head2 B<reload>

Reload the issue from the JIRA server.

=head2 B<sprints>

Generates a list of L<JIRA::REST::Class::Sprint|JIRA::REST::Class::Sprint>
objects from the fields for an issue.  Uses the field_name() accessor on the
L<JIRA::REST::Class::Project|JIRA::REST::Class::Project/"field_name
FIELD_KEY"> object to determine the name of the custom sprint
field. Currently, this only really works if you're using L<Atlassian
GreenHopper|https://www.atlassian.com/software/jira/agile>.

=head2 B<children>

Returns a list of issue objects that are children of the issue. Currently
requires the L<ScriptRunner
plugin|https://marketplace.atlassian.com/plugins/com.onresolve.jira.groovy.groovyrunner/cloud/overview>.

=head2 B<start_progress>

Moves the status of the issue to 'In Progress', regardless of what the current
status is.

=head2 B<start_qa>

Moves the status of the issue to 'In QA', regardless of what the current
status is.

=head2 B<resolve>

Moves the status of the issue to 'Resolved', regardless of what the current
status is.

=head2 B<open>

Moves the status of the issue to 'Open', regardless of what the current status is.

=head2 B<close>

Moves the status of the issue to 'Closed', regardless of what the current status is.

=head1 READ-ONLY ACCESSORS

=head2 B<expand>

A comma-separated list of fields in the issue that weren't expanded in the
initial REST call.

=head2 B<fields>

Returns a reference to the fields hash for the issue.

=head2 B<aggregateprogress>

Returns the aggregate progress for the issue as a hash reference.

TODO: Turn this into an object.

=head2 B<aggregatetimeestimate>

Returns the aggregate time estimate for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s
string.

=head2 B<aggregatetimeoriginalestimate>

Returns the aggregate time original estimate for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s
string.

=head2 B<aggregatetimespent>

Returns the aggregate time spent for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s
string.

=head2 B<assignee>

Returns the issue's assignee as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<changelog>

Returns the issue's change log as a
L<JIRA::REST::Class::Issue::Changelog|JIRA::REST::Class::Issue::Changelog>
object.

=head2 B<comments>

Returns a list of the issue's comments as
L<JIRA::REST::Class::Issue::Comment|JIRA::REST::Class::Issue::Comment>
objects. If called in a scalar context, returns an array reference to the
list, not the number of elements in the list.

=head2 B<components>

Returns a list of the issue's components as
L<JIRA::REST::Class::Project::Component|JIRA::REST::Class::Project::Component>
objects. If called in a scalar context, returns an array reference to the
list, not the number of elements in the list.

=head2 B<component_count>

Returns a count of the issue's components.

=head2 B<created>

Returns the issue's creation date as a L<DateTime|DateTime> object.

=head2 B<creator>

Returns the issue's assignee as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<description>

Returns the description of the issue.

=head2 B<duedate>

Returns the issue's due date as a L<DateTime|DateTime> object.

=head2 B<environment>

Returns the issue's environment as a hash reference.

TODO: Turn this into an object.

=head2 B<fixVersions>

Returns a list of the issue's fixVersions.

TODO: Turn this into a list of objects.

=head2 B<issuelinks>

Returns a list of the issue's links.

TODO: Turn this into a list of objects.

=head2 B<issuetype>

Returns the issue type as a
L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type> object.

=head2 B<labels>

Returns the issue's labels as an array reference.

=head2 B<lastViewed>

Returns the issue's last view date as a L<DateTime|DateTime> object.

=head2 B<parent>

Returns the issue's parent as a
L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object.

=head2 B<has_parent>

Returns a boolean indicating whether the issue has a parent.

=head2 B<priority>

Returns the issue's priority as a hash reference.

TODO: Turn this into an object.

=head2 B<progress>

Returns the issue's progress as a hash reference.

TODO: Turn this into an object.

=head2 B<project>

Returns the issue's project as a
L<JIRA::REST::Class::Project|JIRA::REST::Class::Project> object.

=head2 B<reporter>

Returns the issue's reporter as a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object.

=head2 B<resolution>

Returns the issue's resolution.

TODO: Turn this into an object.

=head2 B<resolutiondate>

Returns the issue's resolution date as a L<DateTime|DateTime> object.

=head2 B<status>

Returns the issue's status as a
L<JIRA::REST::Class::Issue::Status|JIRA::REST::Class::Issue::Status> object.

=head2 B<summary>

Returns the summary of the issue.

=head2 B<timeestimate>

Returns the time estimate for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.

=head2 B<timeoriginalestimate>

Returns the time original estimate for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.

=head2 B<timespent>

Returns the time spent for the issue.

TODO: Turn this into an object that can return either seconds or a w/d/h/m/s string.

=head2 B<timetracking>

Returns the time tracking of the issue as a
L<JIRA::REST::Class::Issue::TimeTracking|JIRA::REST::Class::Issue::TimeTracking>
object.

=head2 B<transitions>

Returns the valid transitions for the issue as a
L<JIRA::REST::Class::Issue::Transitions|JIRA::REST::Class::Issue::Transitions>
object.

=head2 B<updated>

Returns the issue's updated date as a L<DateTime|DateTime> object.

=head2 B<versions>

versions

=head2 B<votes>

votes

=head2 B<watches>

watches

=head2 B<worklog>

Returns the issue's change log as a
L<JIRA::REST::Class::Worklog|JIRA::REST::Class::Worklog> object.

=head2 B<workratio>

workratio

=head2 B<id>

Returns the issue ID.

=head2 B<key>

Returns the issue key.

=head2 B<self>

Returns the JIRA REST API's full URL for this issue.

=head2 B<url>

Returns the JIRA REST API's URL for this issue in a form used by
L<JIRA::REST::Class|JIRA::REST::Class>.

=head1 INTERNAL METHODS

=head2 B<make_object>

A pass-through method that calls
L<JIRA::REST::Class::Factory::make_object()|JIRA::REST::Class::Factory/make_object>,
but adds a weakened link to this issue in the object as well.

=head2 B<get>

Wrapper around C<JIRA::REST::Class>' L<get|JIRA::REST::Class/get> method that
defaults to this issue's URL. Allows for extra parameters to be specified.

=head2 B<post>

Wrapper around C<JIRA::REST::Class>' L<post|JIRA::REST::Class/post> method
that defaults to this issue's URL. Allows for extra parameters to be
specified.

=head2 B<put>

Wrapper around C<JIRA::REST::Class>' L<put|JIRA::REST::Class/put> method that
defaults to this issue's URL. Allows for extra parameters to be specified.

=head2 B<delete>

Wrapper around C<JIRA::REST::Class>' L<delete|JIRA::REST::Class/delete> method
that defaults to this issue's URL. Allows for extra parameters to be
specified.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Abstract|JIRA::REST::Class::Abstract>

=item * L<JIRA::REST::Class::Factory|JIRA::REST::Class::Factory>

=item * L<JIRA::REST::Class::Factory::make_object|JIRA::REST::Class::Factory::make_object>

=item * L<JIRA::REST::Class::Issue::Changelog|JIRA::REST::Class::Issue::Changelog>

=item * L<JIRA::REST::Class::Issue::Comment|JIRA::REST::Class::Issue::Comment>

=item * L<JIRA::REST::Class::Issue::LinkType|JIRA::REST::Class::Issue::LinkType>

=item * L<JIRA::REST::Class::Issue::Status|JIRA::REST::Class::Issue::Status>

=item * L<JIRA::REST::Class::Issue::TimeTracking|JIRA::REST::Class::Issue::TimeTracking>

=item * L<JIRA::REST::Class::Issue::Transitions|JIRA::REST::Class::Issue::Transitions>

=item * L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type>

=item * L<JIRA::REST::Class::Project|JIRA::REST::Class::Project>

=item * L<JIRA::REST::Class::Project::Component|JIRA::REST::Class::Project::Component>

=item * L<JIRA::REST::Class::Sprint|JIRA::REST::Class::Sprint>

=item * L<JIRA::REST::Class::User|JIRA::REST::Class::User>

=item * L<JIRA::REST::Class::Worklog|JIRA::REST::Class::Worklog>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
