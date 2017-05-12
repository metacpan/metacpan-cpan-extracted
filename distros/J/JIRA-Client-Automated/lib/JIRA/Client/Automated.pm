use strict;
use warnings;
use 5.010;

package JIRA::Client::Automated;
$JIRA::Client::Automated::VERSION = '1.6';
=head1 NAME

JIRA::Client::Automated - A JIRA REST Client for automated scripts

=head1 VERSION

version 1.6

=head1 SYNOPSIS

    use JIRA::Client::Automated;

    my $jira = JIRA::Client::Automated->new($url, $user, $password);

    # If your JIRA instance does not use username/password for authorization 
    my $jira = JIRA::Client::Automated->new($url);

    my $jira_ua = $jira->ua(); # to add in a proxy

    $jira->trace(1); # enable tracing of requests and responses

    # The simplest way to create an issue
    my $issue = $jira->create_issue($project, $type, $summary, $description);

    # The simplest way to create a subtask
    my $subtask = $jira->create_subtask($project, $summary, $description, $parent_key);

    # A complex but flexible way to create a new issue, story, task or subtask
    # if you know Jira issue hash structure well.
    my $issue = $jira->create({
        # Jira issue 'fields' hash
        project     => {
            key => $project,
        },
        issuetype   => {
            name => $type,      # "Bug", "Task", "Sub-task", etc.
        },
        summary     => $summary,
        description => $description,
        parent      => {        # only required for a subtask
            key => $parent_key,
        },
        ...
    });


    my $search_results = $jira->search_issues($jql, 1, 100); # query should be a single string of JQL
    my @issues = $jira->all_search_results($jql, 1000); # query should be a single string of JQL

    my $issue = $jira->get_issue($key);

    $jira->update_issue($key, $update_hash); # update_hash is { field => value, ... }
    $jira->create_comment($key, $text);
    $jira->attach_file_to_issue($key, $filename);

    $jira->transition_issue($key, $transition, $transition_hash); # transition_hash is { field => value, ... }

    $jira->close_issue($key, $resolve, $comment); # resolve is the resolution value
    $jira->delete_issue($key);

    $jira->add_issue_watchers($key, $watcher1, ......);
    $jira->add_issue_labels($key, $label1, ......);


=head1 DESCRIPTION

JIRA::Client::Automated is an adapter between any automated system and JIRA's
REST API. This module is explicitly designed to easily create and close issues
within a JIRA instance via automated scripts.

For example, if you run nightly batch jobs, you can use JIRA::Client::Automated
to have those jobs automatically create issues in JIRA for you when the script
runs into errors. You can attach error log files to the issues and then they'll
be waiting in someone's open issues list when they arrive at work the next day.

If you want to avoid creating the same issue more than once you can search JIRA
for it first, only creating it if it doesn't exist. If it does already exist
you can add a comment or a new error log to that issue.

=head1 WORKING WITH JIRA
6
Atlassian has made a very complete REST API for recent (> 5.0) versions of
JIRA. By virtue of being complete it is also somewhat large and a little
complex for the beginner. Reading their tutorials is *highly* recommended
before you start making hashes to update or transition issues.

L<https://developer.atlassian.com/display/JIRADEV/JIRA+REST+APIs>

This module was designed for the JIRA 5.2.11 REST API, as of March 2013, but it
works fine with JIRA 6.0 as well. Your mileage may vary with future versions.

=head1 JIRA ISSUE HASH FORMAT

When you work with an issue in JIRA's REST API, it gives you a JSON file that
follows this spec:

L<https://developer.atlassian.com/display/JIRADEV/The+Shape+of+an+Issue+in+JIRA+REST+APIs>

JIRA::Client::Automated tries to be nice to you and not make you deal directly
with JSON. When you create a new issue, you can pass in just the pieces you
want and L</"create_issue"> will transform them to JSON for you. The same for
closing and deleting issues.

Updating and transitioning issues is more complex.  Each JIRA installation will
have different fields available for each issue type and transition screen and
only you will know what they are. So in those cases you'll need to pass in an
"update_hash" which will be transformed to the proper JSON by the method.

An update_hash looks like this:

    { field1 => value, field2 => value2, ...}

For example:

    {
        host_id => "example.com",
        { resolution => { name => "Resolved" } }
    }

If you do not read JIRA's documentation about their JSON format you will hurt
yourself banging your head against your desk in frustration the first few times
you try to use L</"update_issue">. Please RTFM.

Note that even though JIRA requires JSON, JIRA::Client::Automated will
helpfully translate it to and from regular hashes for you. You only pass hashes
to JIRA::Client::Automated, not direct JSON.

I recommend connecting to your JIRA server and calling L</"get_issue"> with a
key you know exists and then dump the result. That'll get you started.

=head1 METHODS

=cut

use JSON;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common qw(GET POST PUT DELETE);
use LWP::Protocol::https;
use Carp;
use Data::Dump qw(pp);

=head2 new

    my $jira = JIRA::Client::Automated->new($url, $user, $password);

Create a new JIRA::Client::Automated object by passing in the following:

=over 3

=item 1.

URL for the JIRA server, such as "http://example.atlassian.net/"

=item 2.

Username to use to login to the JIRA server

=item 3.

Password for that user

=back

All three parameters are required if your JIRA instance uses basic
authorization, for which JIRA::Client::Automated must connect to the
JIRA instance using I<some> username and password. You may want to set up a
special "auto" or "batch" username to use just for use by scripts.

If you are using Google Account integration, the username and password to use
are the ones you set up at the very beginning of the registration process and
then never used again because Google logged you in.

If you have other ways of authorization, like GSSAPI based authorization, do
not provide username or password. 

    my $jira = JIRA::Client::Automated->new($url);

=cut

sub new {
    my ($class, $url, $user, $password) = @_;

    unless (defined $url && $url) {
        croak "Need to specify url to access JIRA";
    }
    my $no_user_pwd = !(defined $user || defined $password);
    unless ($no_user_pwd || defined $user && $user && defined $password && $password) {
        croak "Need to either specify both user and password, or provide none of them";
    }

    unless ($url =~ m{/$}) {
        $url .= '/';
    }

    # make sure we have a usable API URL
    my $auth_url = $url;
    unless ($auth_url =~ m{/rest/api/}) {
        $auth_url .= '/rest/api/latest/';
    }
    unless ($auth_url =~ m{/$}) {
        $auth_url .= '/';
    }
    $auth_url =~ s{//}{/}g;
    $auth_url =~ s{:/}{://};

    if ($auth_url !~ m|https?://|) {
        croak "URL for JIRA must be absolute, including 'http://' or 'https://'";
    }

    my $self = { url => $url, auth_url => $auth_url, user => $user, password => $password };
    bless $self, $class;

    # cached UserAgent for talking to JIRA
    $self->{_ua} = LWP::UserAgent->new();

    # cached JSON object for handling conversions
    $self->{_json} = JSON->new->utf8()->allow_nonref;

    return $self;
}


=head2 ua

    my $ua = $jira->ua();

Returns the L<LWP::UserAgent> object used to connect to the JIRA instance.
Typically used to setup proxies or make other customizations to the UserAgent.
For example:

    my $ua = $jira->ua();
    $ua->env_proxy();
    $ua->ssl_opts(...);
    $ua->conn_cache( LWP::ConnCache->new() );

=cut

sub ua {
    my $self = shift;
    $self->{_ua} = shift if @_;
    return $self->{_ua};
}


=head2 trace

    $jira->trace(1);       # enable
    $jira->trace(0);       # disable
    $trace = $jira->trace;

When tracing is enabled each request and response is logged using carp.

=cut

sub trace {
    my $self = shift;
    $self->{_trace} = shift if @_;
    return $self->{_trace};
}


sub _handle_error_response {
    my ($self, $response, $request) = @_;

    my $msg = $response->status_line;
    $msg .= pp($self->{_json}->decode($response->decoded_content))
        if $response->decoded_content;

    $msg .= "\n\nfor request:\n";
    $msg .= pp($self->{_json}->decode($request->decoded_content))
        if $request->decoded_content;

    croak sprintf "Unable to %s %s: %s",
        $request->method, $request->uri->path, $msg;
}


sub _perform_request {
    my ($self, $request, $handlers) = @_;

    if ((defined $self->{user}) && (defined $self->{password})) {
        $request->authorization_basic($self->{user}, $self->{password});
    }

    if ($self->trace) {
        carp sprintf "request %s %s: %s",
            $request->method, $request->uri->path, $request->decoded_content//'';
    }

    my $response = $self->{_ua}->request($request);

    if ($self->trace) {
        carp sprintf "response %s: %s",
            $response->status_line, $response->decoded_content//'';
    }

    return $response if $response->is_success();

    $handlers ||= {};
    my $handler = $handlers->{ $response->code } || sub {
        return $self->_handle_error_response($response, $request);
    };

    return $handler->($response, $request, $self);
}


=head2 create

    my $issue = $jira->create({
        # Jira issue 'fields' hash
        project     => {
            key => $project,
        },
        issuetype   => {
            name => $type,      # "Bug", "Task", "SubTask", etc.
        },
        summary     => $summary,
        description => $description,
        parent      => {        # only required for a subtask
            key => $parent_key,
        },
        ...
    });

Creating a new issue, story, task, subtask, etc.

Returns a hash containing only the basic information about the new issue, or
dies if there is an error. The hash looks like:

    {
        id => 24066,
        key => "TEST-57",
        self => "https://example.atlassian.net/rest/api/latest/issue/24066"
    }

See also L<https://developer.atlassian.com/display/JIRADEV/JIRA+REST+API+Example+-+Create+Issue>

=cut

sub _issue_type_meta {
    my ($self, $project, $issuetype) = @_;

    my $uri = "$self->{auth_url}issue/createmeta?projectKeys=${project}&expand=projects.issuetypes.fields";

    my $request = GET $uri,
      Content_Type => 'application/json';

    my $response = $self->_perform_request($request);

    my $meta = $self->{_json}->decode($response->decoded_content());
    foreach my $p (@{$meta->{projects}}) {
        if ($p->{key} eq $project) {
            foreach my $i (@{$p->{issuetypes}}) {
                return %{$i->{fields}} if $i->{name} eq $issuetype and exists $i->{fields};
            }
        }
    }

    return;
}

sub _custom_field_conversion_map {
    my ($self, $project, $issuetype) = @_;

    my %custom_field_meta = $self->_issue_type_meta($project, $issuetype);

    my %custom_field_conversion_map;
    while (my ($cf, $meta) = each %custom_field_meta) {
        if ($cf =~ /^customfield_/) {
            my $english_name = $meta->{name};
            $custom_field_conversion_map{english_to_customfield}{$english_name} = $cf;
            $custom_field_conversion_map{customfield_to_english}{$cf} = $english_name;
            $custom_field_conversion_map{meta}{$cf} = $meta;
        }
    }

    return \%custom_field_conversion_map;
}

sub _convert_to_custom_field_name {
    my ($self, $project, $issuetype, $field_name) = @_;

    $self->{custom_field_conversion_map}{$project}{$issuetype} ||= $self->_custom_field_conversion_map($project, $issuetype);

    return $self->{custom_field_conversion_map}{$project}{$issuetype}{english_to_customfield}{$field_name} || $field_name;
}

sub _convert_to_custom_field_value {
    my ($self, $project, $issuetype, $field_name, $field_value) = @_;

    $self->{custom_field_conversion_map}{$project}{$issuetype} ||= $self->_custom_field_conversion_map($project, $issuetype);

    my $custom_field_name = $self->{custom_field_conversion_map}{$project}{$issuetype}{english_to_customfield}{$field_name};
    if ($custom_field_name) { # If it's a custom field...
        my $custom_field_defn = $self->{custom_field_conversion_map}{$project}{$issuetype}{meta}{$custom_field_name};
        my $custom_field_name = $custom_field_defn->{custom_field_name};

        if (exists $custom_field_defn->{allowedValues}) {
            my %custom_values = map { $_->{value} => $_ } @{$custom_field_defn->{allowedValues}};
            my $custom_field_id = $custom_values{$field_value}{id} or die "Cannot find custom field value for $field_name value $field_value";
            return { id => $custom_field_id };
        } else {
            return $field_value;
        }
    } else {
        # It's a regular field, just pass it through
        return $field_value;
    }
}

sub _convert_to_customfields {
    my ($self, $project, $issuetype, $fields) = @_;

    my $converted_fields;
    while (my ($name, $value) = each %$fields) {
        my $converted_name = $self->_convert_to_custom_field_name($project, $issuetype, $name);
        my $converted_value;
        if (ref $value eq 'ARRAY') {
            $converted_value = [ map { $self->_convert_to_custom_field_value($project, $issuetype, $name, $_) } @$value ];
        } else {
            $converted_value = $self->_convert_to_custom_field_value($project, $issuetype, $name, $value);
        }
        $converted_fields->{$converted_name} = $converted_value;
    }

    return $converted_fields;
}

sub _issuetype_custom_fieldlist {
    my ($self, $project, $issuetype) = @_;

    $self->{custom_field_conversion_map}{$project}{$issuetype} ||= $self->_custom_field_conversion_map($project, $issuetype);

    return keys %{$self->{custom_field_conversion_map}{$project}{$issuetype}{customfield_to_english}};
}

sub _convert_from_custom_field_name {
    my ($self, $project, $issuetype, $field_name) = @_;

    $self->{custom_field_conversion_map}{$project}{$issuetype} ||= $self->_custom_field_conversion_map($project, $issuetype);

    return $self->{custom_field_conversion_map}{$project}{$issuetype}{customfield_to_english}{$field_name} || $field_name;
}

sub _convert_from_customfields {
    my ($self, $project, $issuetype, $fields) = @_;

    # Built-in fields
    my $converted_fields = { map {
        if ($_ !~ /^customfield_/) {
            ($_ => $fields->{$_})
        } else {
            ()
        }
    } keys %$fields };

    # And the custom fields.  For some reason, JIRA seems to give me a
    # list of *all* possible custom fields, not just ones relevant to
    # this issuetype
    for my $cfname ($self->_issuetype_custom_fieldlist($project, $issuetype)) {

        my $english_name = $self->_convert_from_custom_field_name($project, $issuetype, $cfname);
        if (exists $fields->{$cfname}) {
            my $value = $fields->{$cfname};
            my $converted_value;
            if (ref $value eq 'ARRAY') {
                $converted_value = [ map { $_->{value} } @$value ];
            } else {
                $converted_value = $value->{value};
            }
            $converted_fields->{$english_name} = $converted_value;
        } else {
            $converted_fields->{$english_name} = undef;
        }
    }

    return $converted_fields;
}

sub create {
    my ($self, $fields) = @_;

    my $project = $fields->{project}{key};
    my $issuetype = $fields->{issuetype}{name};
    my $issue = { fields => $self->_convert_to_customfields( $project, $issuetype, $fields ) };

    my $issue_json = $self->{_json}->encode($issue);
    my $uri        = "$self->{auth_url}issue/";

    my $request = POST $uri,
      Content_Type => 'application/json',
      Content      => $issue_json;

    my $response = $self->_perform_request($request);

    my $new_issue = $self->{_json}->decode($response->decoded_content());

    return $new_issue;
}


=head2 create_issue

    my $issue = $jira->create_issue($project, $type, $summary, $description, $fields);

Creating a new issue requires the project key, type ("Bug", "Task", etc.), and
a summary and description.

The optional $fields parameter can be used to pass a reference to a hash of
extra fields to be set when the issue is created, which avoids the need for a
separate L</update_issue> call. For example:

    $jira->create_issue($project, $type, $summary, $description, {
        labels => [ "foo", "bar" ]
    });

This method calls L</create> and return the same hash reference that it does.

=cut

sub create_issue {
    my ($self, $project, $type, $summary, $description, $fields) = @_;

    my $create_fields = {
        %{ $fields || {} },
        summary     => $summary,
        description => $description,
        issuetype   => { name => $type, },
        project     => { key => $project, },
    };

    return $self->create($create_fields);
}


=head2 create_subtask

    my $subtask = $jira->create_subtask($project, $summary, $description, $parent_key);
    # or with optional subtask type
    my $subtask = $jira->create_subtask($project, $summary, $description, $parent_key, 'sub-task');

Creating a subtask. If your JIRA instance does not call subtasks "Sub-task" or
"sub-task", then you will need to pass in your subtask type.

This method calls L</create> and return the same hash reference that it does.

=cut

sub create_subtask {
    my ($self, $project, $summary, $description, $parent_key, $type) = @_;

    # validate fields
    die "parent_key required" unless $parent_key;
    $type ||= 'Sub-task';

    my $fields = {
        project     => { key => $project, },
        issuetype   => { name => $type },
        summary     => $summary,
        description => $description,
        parent      => { key  => $parent_key},
    };

    return $self->create($fields);
}


=head2 update_issue

    $jira->update_issue($key, $field_update_hash, $update_verb_hash);

There are two ways to express the updates you want to make to an issue.

For simple changes you pass $field_update_hash as a reference to a hash of
field_name => new_value pairs. For example:

    $jira->update_issue($key, { summary => $new_summary });

That works for simple fields, but there are some, like comments, that can't be
updated in this way. For them you need to use $update_verb_hash.

The $update_verb_hash parameter allow you to express a series of specific
operations (verbs) to be performed on each field. For example:

    $jira->update_issue($key, undef, {
        labels   => [ { remove => "test" }, { add => "another" } ],
        comments => [ { remove => { id => 10001 } } ]
    });

The two forms of update can be combined in a single call.

For more information see:

    https://developer.atlassian.com/display/JIRADEV/JIRA+REST+API+Example+-+Edit+issues
    https://developer.atlassian.com/display/JIRADEV/Updating+an+Issue+via+the+JIRA+REST+APIs

=cut

sub update_issue {
    my ($self, $key, $field_update_hash, $update_verb_hash) = @_;

    my $issue = {};
    $issue->{fields} = $field_update_hash if $field_update_hash;
    $issue->{update} = $update_verb_hash  if $update_verb_hash;

    my $issue_json = $self->{_json}->encode($issue);
    my $uri        = "$self->{auth_url}issue/$key";

    my $request = PUT $uri,
      Content_Type => 'application/json',
      Content      => $issue_json;

    my $response = $self->_perform_request($request);

    return $key;
}


=head2 get_issue

    my $issue = $jira->get_issue($key);

Returns details for any issue, given its key. This call returns a hash
containing the information for the issue in JIRA's format. See L</"JIRA ISSUE
HASH FORMAT"> for details.

=cut

sub get_issue {
    my ($self, $key) = @_;
    my $uri = "$self->{auth_url}issue/$key";

    my $request = GET $uri, Content_Type => 'application/json';

    my $response = $self->_perform_request($request);

    my $new_issue = $self->{_json}->decode($response->decoded_content());

    my $project = $new_issue->{fields}{project}{key};
    my $issuetype = $new_issue->{fields}{issuetype}{name};
    my $english_fields = $self->_convert_from_customfields( $project, $issuetype, $new_issue->{fields} );
    $new_issue->{fields} = $english_fields;

    return $new_issue;
}


sub _get_transitions {
    my ($self, $key) = @_;
    my $uri = "$self->{auth_url}issue/$key/transitions";

    my $request = GET $uri, Content_Type => 'application/json';

    my $response = $self->_perform_request($request);

    my $transitions = $self->{_json}->decode($response->decoded_content())->{transitions};

    return $transitions;
}


# Each issue could have a different workflow and therefore a different
# transition id for 'Close Issue', so we have to look it up every time.
#
# Also, since transition names can be freely edited ('Close', 'Close it!')
# we also match against the destination status name, which is much more
# likely to remain stable ('Closed'). This is low risk because transition
# names are verbs and status names are nouns, so a clash is very unlikely,
# or if they are the same the effect is the same ('Open').
#
# We also allow the transition names to be specified as an array of names
# in which case the first one that matches either a transition or status is used.
# This makes it easier for scripts to handle the migration of names
# by allowing current and new names to be used so the later change in JIRA
# config doesn't cause any breakage.

sub _get_transition_id {
    my ($self, $key, $t_name) = @_;

    my $transitions = $self->_get_transitions($key);

    my %trans_names  = map { $_->{name}     => $_ } @$transitions;
    my %status_names = map { $_->{to}{name} => $_ } @$transitions;

    my @names = (ref $t_name) ? @$t_name : ($t_name);
    my @trans = map { $trans_names{$_} // $status_names{$_} } @names; # // is incompatible with perl <= 5.8
    my $tran = (grep { defined } @trans)[0]; # use the first defined one

    if (not defined $tran) {
        my @trans2status = map { "'$_->{name}' (to '$_->{to}{name}')" } @$transitions;
        croak sprintf "%s has no transition or reachable status called %s (available transitions: %s)",
            $key,
            join(", ", map { "'$_'" } @names),
            join(", ", sort @trans2status) || '<none>';
    }

    return $tran->{id} unless wantarray;
    return ($tran->{id}, $tran);
}


=head2 transition_issue

    $jira->transition_issue($key, $transition);
    $jira->transition_issue($key, $transition, $update_hash);

Transitioning an issue is what happens when you click the button that says
"Resolve Issue" or "Start Progress" on it. Doing this from code is harder, but
JIRA::Client::Automated makes it as easy as possible.

You pass this method the issue key, the name of the transition or the target
status (spacing and capitalization matter), and an optional update_hash
containing any fields that you want to update.

=head3 Specifying The Transition

The provided $transition name is first matched against the available
transitions for the $key issue ('Start Progress', 'Close Issue').
If there's no match then the names is matched against the available target
status names ('Open', 'Closed'). You can use whichever is most appropriate.
For example, in your configuration the transition names might vary between
different kinds of projects but the status names might be the same.
In which case scripts that are meant to work across multiple projects
might prefer to use the status names.

The $transition parameter can also be specified as a reference to an array of
names. In this case the first one that matches either a transition name or
status name is used.  This makes it easier for scripts to work across multiple
kinds of projects and/or handle the migration of names by allowing current and
future names to be used, so the later change in JIRA config doesn't cause any
breakage.

=head3 Specifying Updates

If you have required fields on the transition screen (such as "Resolution" for
the "Resolve Issue" screen), you must pass those fields in as part of the
update_hash or you will get an error from the server. See L</"JIRA ISSUE HASH
FORMAT"> for the format of the update_hash.

(Note: it appears that in some obscure cases missing required fields may cause the
transition to fail I<without> causing an error from the server. For example
a field that's required but isn't configured to appear on the transition screen.)

The $update_hash is a combination of the $field_update_hash and $update_verb_hash
parameters used by the L</update_issue> method. Like this:

    $update_hash = {
        fields => $field_update_hash,
        update => $update_verb_hash
    };

You can use it to express both simple field settings and more complex update
operations. For example:

    $jira->transition_issue($key, $transition, {
        fields => { summary => $new_summary },
        update => {
            labels   => [ { remove => "test" }, { add => "another" } ],
            comments => [ { remove => { id => 10001 } } ]
        }
    });

=cut

sub transition_issue {
    my ($self, $key, $t_name, $t_hash) = @_;

    my $t_id = $self->_get_transition_id($key, $t_name);
    $$t_hash{transition} = { id => $t_id };

    my $t_json = $self->{_json}->encode($t_hash);
    my $uri    = "$self->{auth_url}issue/$key/transitions";

    my $request = POST $uri,
      Content_Type => 'application/json',
      Content      => $t_json;

    my $response = $self->_perform_request($request);

    return $key;
}


=head2 close_issue

    $jira->close_issue($key);
    $jira->close_issue($key, $resolve);
    $jira->close_issue($key, $resolve, $comment);
    $jira->close_issue($key, $resolve, $comment, $update_hash);
    $jira->close_issue($key, $resolve, $comment, $update_hash, $operation);


Pass in the resolution reason and an optional comment to close an issue. Using
this method requires that the issue is is a status where it can use the "Close
Issue" transition (or other one, specified by $operation).
If not, you will get an error from the server.

Resolution ("Fixed", "Won't Fix", etc.) is only required if the issue hasn't
already been resolved in an earlier transition. If you try to resolve an issue
twice, you will get an error.

If you do not supply a comment, the default value is "Issue closed by script".

The $update_hash can be used to set or edit the values of other fields.

The $operation parameter can be used to specify the closing transition type. This
can be useful when your JIRA configuration uses nonstandard or localized
transition and status names, e.g.

	use utf8;
	$jira->close_issue($key, $resolve, $comment, $update_hash, "Done");

See L</transition_issue> for more details.

This method is a wrapper for L</transition_issue>.

=cut

sub close_issue {
    my ($self, $key, $resolve, $comment, $update_hash, $operation) = @_;

    $comment   //= 'Issue closed by script'; # // is incompatible with perl <= 5.8
    $operation //=  [ 'Close Issue', 'Close', 'Closed' ];

    $update_hash ||= {};

    push @{$update_hash->{update}{comment}}, {
        add => { body => $comment }
    };

    $update_hash->{fields}{resolution} = { name => $resolve }
        if $resolve;

    return $self->transition_issue($key, $operation, $update_hash);
}


=head2 delete_issue

    $jira->delete_issue($key);

Deleting issues is for testing your JIRA code. In real situations you almost
always want to close unwanted issues with an "Oops!" resolution instead.

=cut

sub delete_issue {
    my ($self, $key) = @_;

    my $uri = "$self->{auth_url}issue/$key";

    my $request = DELETE $uri;

    my $response = $self->_perform_request($request);

    return $key;
}


=head2 create_comment

    $jira->create_comment($key, $text);

You may use any valid JIRA markup in comment text. (This is handy for tables of
values explaining why something in the database is wrong.) Note that comments
are all created by the user you used to create your JIRA::Client::Automated
object, so you'll see that name often.

=cut

sub create_comment {
    my ($self, $key, $text) = @_;

    my $comment = { body => $text };

    my $comment_json = $self->{_json}->encode($comment);
    my $uri          = "$self->{auth_url}issue/$key/comment";

    my $request = POST $uri,
      Content_Type => 'application/json',
      Content      => $comment_json;

    my $response = $self->_perform_request($request);

    my $new_comment = $self->{_json}->decode($response->decoded_content());

    return $new_comment;
}


=head2 search_issues

    my @search_results = $jira->search_issues($jql, 1, 100, $fields);

You've used JQL before, when you did an "Advanced Search" in the JIRA web
interface. That's the only way to search via the REST API.

This is a paged method. Pass in the starting result number and number of
results per page and it will return issues a page at a time. If you know you
want all of the results, you can use L</"all_search_results"> instead.

Optional parameter $fields is the arrayref containing the list of fields to be returned.

This method returns a hashref containing up to five values:

=over 3

=item 1.

total => total number of results

=item 2.

start => result number for the first result

=item 3.

max => maximum number of results per page

=item 4.

issues => an arrayref containing the actual found issues

=item 5.

errors => an arrayref containing error messages

=back

For example, to page through all results C<$max> at a time:

    my (@all_results, @issues);
    do {
        $results = $self->search_issues($jql, $start, $max);
        if ($results->{errors}) {
            die join "\n", @{$results->{errors}};
        }
        @issues = @{$results->{issues}};
        push @all_results, @issues;
        $start += $max;
    } until (scalar(@issues) < $max);

(Or just use L</"all_search_results"> instead.)

=cut

# This is a paged method. You pass in the starting number and max to retrieve and it returns those and the total
# number of hits. To get the next page, call search_issues() again with the start value = start + max, until total
# < max
# Note: if $max is > 1000 (set by jira.search.views.default.max in
# http://jira.example.com/secure/admin/ViewSystemInfo.jspa) then it'll be truncated to 1000 anyway.
sub search_issues {
    my ($self, $jql, $start, $max, $fields) = @_;

	$fields ||= ['*navigable'];
    my $query = {
        jql        => $jql,
        startAt    => $start,
        maxResults => $max,
        fields     => $fields,
    };

    my $query_json = $self->{_json}->encode($query);
    my $uri        = "$self->{auth_url}search/";

    my $request = POST $uri,
      Content_Type => 'application/json',
      Content      => $query_json;

    my $response = $self->_perform_request($request, {
        400 => sub { # pass-thru 400 responses for us to deal with below
            my ($response, $request, $self) = @_;
            return $response;
        },
    });

    if ($response->code == 400) {
        my $error_msg = $self->{_json}->decode($response->decoded_content());
        return { total => 0, errors => $error_msg->{errorMessages} };
    }

    my $results = $self->{_json}->decode($response->decoded_content());

    return {
        total  => $$results{total},
        start  => $$results{startAt},
        max    => $$results{maxResults},
        issues => $$results{issues} };
}


=head2 all_search_results

    my @issues = $jira->all_search_results($jql, 1000);

Like L</"search_issues">, but returns all the results as an array of issues.
You can specify the maximum number to return, but no matter what, it can't
return more than the value of jira.search.views.default.max for your JIRA
installation.

=cut

sub all_search_results {
    my ($self, $jql, $max) = @_;

    my $start = 0;
    $max //= 100; # is a param for testing ; // is incompatible with perl <= 5.8
    my $total = 0;
    my (@all_results, @issues, $results);

    do {
        $results = $self->search_issues($jql, $start, $max);
        if ($results->{errors}) {
            die join "\n", @{ $results->{errors} };
        }
        @issues = @{ $results->{issues} };
        push @all_results, @issues;
        $start += $max;
    } until (scalar(@issues) < $max);

    return @all_results;
}

=head2 get_issue_comments

    $jira->get_issue_comments($key);

Returns arryref of all comments to the given issue.

=cut

sub  get_issue_comments {
    my ($self, $key) = @_;
    my $uri = "$self->{auth_url}issue/$key/comment";
    my $request = GET $uri;
    my $response = $self->_perform_request($request);
    my $content = $self->{_json}->decode($response->decoded_content());

    # dereference to get just the comments arrayref
    my $comments = $content->{comments};
    return $comments;
}

=head2 attach_file_to_issue

    $jira->attach_file_to_issue($key, $filename);

This method does not let you attach a comment to the issue at the same time.
You'll need to call L</"create_comment"> for that.

Watch out for file permissions! If the user running the script does not have
permission to read the file it is trying to upload, you'll get weird errors.

=cut

sub attach_file_to_issue {
    my ($self, $key, $filename) = @_;

    my $uri = "$self->{auth_url}issue/$key/attachments";

    my $request = POST $uri,
      Content_Type        => 'form-data',
      'X-Atlassian-Token' => 'nocheck',             # required by JIRA XSRF protection
      Content             => [file => [$filename],];

    my $response = $self->_perform_request($request);

    my $new_attachment = $self->{_json}->decode($response->decoded_content());

    return $new_attachment;
}


=head2 make_browse_url

    my $url = $jira->make_browse_url($key);

A helper method to return the "C<.../browse/$key>" url for the issue.
It's handy to make emails containing lists of bugs easier to create.

This just appends the key to the URL for the JIRA server so that you can click
on it and go directly to that issue.

=cut

sub make_browse_url {
    my ($self, $key) = @_;
    # use url + browse + key to synthesize URL
    my $url = $self->{url};
    $url =~ s/\/rest\/api\/.*//;
    $url .= '/' unless $url =~ m{/$};
    return $url . 'browse/' . $key;
}

=head2 get_link_types

    my $all_link_types = $jira->get_link_types();

Get the arrayref of all possible link types.

=cut

sub get_link_types {
    my ($self) = @_;

    my $uri = "$self->{auth_url}issueLinkType";
    my $request = GET $uri;
    my $response = $self->_perform_request($request);

    # dereference to arrayref, for convenience later
    my $content = $self->{_json}->decode($response->decoded_content());
    my $link_types = $content->{issueLinkTypes};

    return $link_types;
}

=head2 link_issues

    $jira->link_issues($from, $to, $type);

Establish a link of the type named $type from issue key $from to issue key $to .
Returns nothing on success; structure containing error messages otherwise.

=cut


sub link_issues {
    my ($self, $from, $to, $type) = @_;

    my $uri = "$self->{auth_url}issueLink/";
    my $link = {
        inwardIssue   => { key  => $to   },
        outwardIssue  => { key  => $from },
        type          => { name => $type },
    };

    my $link_json = $self->{_json}->encode($link);

    my $request = POST $uri,
      Content_Type        => 'application/json',
      Content             => $link_json;

    my $response = $self->_perform_request($request);

    if($response->code != 201) {
        return $self->{_json}->decode($response->decoded_content());
    }
    return;
}

=head2 add_issue_labels

    $jira->add_issue_labels($issue_key, @labels);

Adds one more more labels to the specified issue.

=cut


sub add_issue_labels {
    my ($self, $issue_key, @labels) = @_;
    $self->update_issue($issue_key,  {}, { labels => [ map {{ add => $_ }} @labels ] } );
}

=head2 remove_issue_labels

    $jira->remove_issue_labels($issue_key, @labels);

Removes one more more labels from the specified issue.

=cut

sub remove_issue_labels {
    my ($self, $issue_key, @labels) = @_;
    $self->update_issue($issue_key,  {}, { labels => [ map {{ remove => $_ }} @labels ] } );
}

=head2 add_issue_watchers

    $jira->add_issue_watchers($key, @watchers);

Adds watchers to the specified issue. Returns nothing if success; otherwise returns a structure containing error message.

=cut

sub add_issue_watchers {
    my ($self, $key, @watchers) = @_;
    my $uri = "$self->{auth_url}issue/$key/watchers";
    foreach my $w (@watchers) {
        my $request = POST $uri,
            Content_Type    => 'application/json',
            Content         => $self->{_json}->encode($w);
        my $response = $self->_perform_request($request);
        if($response->code != 204) {
              return $self->{_json}->decode($response->decoded_content());
        }
    }
    return;
}

=head2 get_issue_watchers

    $jira->get_issue_watchers($key);

Returns arryref of all watchers of the given issue.

=cut

sub  get_issue_watchers {
    my ($self, $key) = @_;
    my $uri = "$self->{auth_url}issue/$key/watchers";
    my $request = GET $uri;
    my $response = $self->_perform_request($request);
    my $content = $self->{_json}->decode($response->decoded_content());

    # dereference to get just the watchers arrayref
    my $watchers = $content->{watchers};
    return $watchers;
}

=head2 assign_issue

    $jira->assign_issue($key, $assignee_name);

Assigns the issue to that person. Returns the key of the issue if it succeeds.

=cut

sub assign_issue {
    my ($self, $key, $assignee_name) = @_;

    my $assignee = {};
    $assignee->{name} = $assignee_name;

    my $issue_json = $self->{_json}->encode($assignee);
    my $uri        = "$self->{auth_url}issue/$key/assignee";

    my $request = PUT $uri,
      Content_Type => 'application/json',
      Content      => $issue_json;

    my $response = $self->_perform_request($request);

    return $key;
}

=head2 add_issue_worklog

    $jira->add_issue_worklog($key, $worklog);

Adds a worklog to the specified issue. Returns nothing if success; otherwise returns a structure containing error message.

Sample worklog:
{
    "comment" => "I did some work here.",
    "started" => "2016-05-27T02:32:26.797+0000",
    "timeSpentSeconds" => 12000,
}

=cut

sub add_issue_worklog {
    my ($self, $key, $worklog) = @_;
    my $uri = "$self->{auth_url}issue/$key/worklog";
    my $request = POST $uri,
       Content_Type    => 'application/json',
       Content         => $self->{_json}->encode($worklog);
    my $response = $self->_perform_request($request);
    if($response->code != 201) {
         return $self->{_json}->decode($response->decoded_content());
    }
    return;
}

=head2 get_issue_worklogs

    $jira->get_issue_worklogs($key);

Returns arryref of all worklogs of the given issue.

=cut

sub  get_issue_worklogs {
    my ($self, $key) = @_;
    my $uri = "$self->{auth_url}issue/$key/worklog";
    my $request = GET $uri;
    my $response = $self->_perform_request($request);
    my $content = $self->{_json}->decode($response->decoded_content());

    # dereference to get just the worklogs arrayref
    my $worklogs = $content->{worklogs};
    return $worklogs;
}

=head1 FAQ

=head2 Why is there no object for a JIRA issue?

Because it seemed silly. You I<could> write such an object and give it methods
to transition itself, close itself, etc., but when you are working with JIRA
from batch scripts, you're never really working with just one issue at a time.
And when you have a hundred of them, it's easier to not objectify them and just
use JIRA::Client::Automated as a mediator. That said, if this is important to
you, I wouldn't say no to a patch offering this option.

=head1 BUGS

Please report bugs or feature requests to the author.

=head1 AUTHOR

Michael Friedman <frimicc@cpan.org>

=head1 CREDITS

Thanks very much to:

=over 4

=item Tim Bunce <timb@cpan.org>

=back

=over 4

=item Dominique Dumont <ddumont@cpan.org>

=back

=over 4

=item Zhuang (John) Li <7humblerocks@gmail.com>

=back

=over 4

=item Ivan E. Panchenko <panchenko@cpan.org>

=back

=encoding utf8

=over 4

=item José Antonio Perez Testa <japtesta@gmail.com>

=back

=over 4

=item Frank Schophuizen <Frank.Schophuizen@philips.com>

=back

=over 4

=item Zhenyi Zhou <zhenyz@cpan.org>

=back

=over 4

=item Roy Lyons <Roy.Lyons@cmegroup.com>

=back

=over 4

=item Neil Hemingway <hemingway@cpan.org>

=back


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Polyvore, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
