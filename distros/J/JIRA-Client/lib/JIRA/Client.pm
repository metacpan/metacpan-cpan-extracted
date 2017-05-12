package JIRA::Client;
# ABSTRACT: (DEPRECATED) Extended interface to JIRA's SOAP API
$JIRA::Client::VERSION = '0.45';
use strict;
use warnings;

use Carp;
use Data::Util qw(:check);
use SOAP::Lite;


sub new {
    my ($class, @args) = @_;

    my $args;

    if (@args == 1) {
	$args = shift @args;
	is_hash_ref($args) or croak "$class::new sole argument must be a hash-ref.\n";
	foreach my $arg (qw/baseurl user password/) {
	    exists $args->{$arg}
		or croak "Missing $arg key to $class::new hash argument.\n";
	}
	$args->{soapargs} = [] unless exists $args->{soapargs};
    } elsif (@args >= 3) {
        my $baseurl  = shift @args;
        my $user     = shift @args;
        my $password = shift @args;
	$args = {
	    baseurl  => $baseurl,
	    user     => $user,
	    password => $password,
	    soapargs => \@args,
	};
    } else {
	croak "Invalid number of arguments to $class::new.\n";
    }

    $args->{wsdl} = '/rpc/soap/jirasoapservice-v2?wsdl' unless exists $args->{wsdl};

    my $url = $args->{baseurl};
    $url =~ s{/$}{}; # clean trailing slash
    $url .= $args->{wsdl};

    my $soap = SOAP::Lite->proxy($url, @{$args->{soapargs}});

    # Make all scalars be encoded as strings by default.
    $soap->typelookup({default => [0, sub {1}, 'as_string']});

    my $auth = $soap->login($args->{user}, $args->{password});
    croak $auth->faultcode(), ', ', $auth->faultstring()
        if defined $auth->fault();

    my $auth_result = $auth->result()
	or croak "Unknown error while connecting to JIRA. Please, check the URL.\n";

    my $self = {
        soap  => $soap,
        auth  => $auth_result,
        iter  => undef,
        cache => {
            components => {}, # project_key => {name => RemoteComponent}
            versions   => {}, # project_key => {name => RemoteVersion}
        },
    };

    return bless $self, $class;
}

# This empty DESTROY is necessary because we're using AUTOLOAD.
# http://www.perlmonks.org/?node_id=93045
sub DESTROY { }

# The issue "https://jira.atlassian.com/browse/JRA-12300" explains why
# some fields in JIRA have nonintuitive names. Here we map them.

my %JRA12300 = (
    affectsVersions => 'versions',
    type            => 'issuetype',
);

my %JRA12300_backwards = reverse %JRA12300;

# These are some helper functions to convert names into ids.

sub _convert_type {
    my ($self, $type) = @_;
    if ($type =~ /\D/) {
        my $types = $self->get_issue_types();
        return $types->{$type}{id} if exists $types->{$type};

	$types = $self->get_subtask_issue_types();
        return $types->{$type}{id} if exists $types->{$type};

        croak "There is no issue type called '$type'.\n";
    }
    return $type;
}

sub _convert_priority {
    my ($self, $prio) = @_;
    if ($prio =~ /\D/) {
        my $prios = $self->get_priorities();
        croak "There is no priority called '$prio'.\n"
            unless exists $prios->{$prio};
        return $prios->{$prio}{id};
    }
    return $prio;
}

sub _convert_resolution {
    my ($self, $resolution) = @_;
    if ($resolution =~ /\D/) {
        my $resolutions = $self->get_resolutions();
        croak "There is no resolution called '$resolution'.\n"
            unless exists $resolutions->{$resolution};
        return $resolutions->{$resolution}{id};
    }
    return $resolution;
}

sub _convert_security_level {
    my ($self, $seclevel, $project) = @_;
    if ($seclevel =~ /\D/) {
        my $seclevels = $self->get_security_levels($project);
        croak "There is no security level called '$seclevel'.\n"
            unless exists $seclevels->{$seclevel};
        return $seclevels->{$seclevel}{id};
    }
    return $seclevel;
}

# This routine receives an array with a list of $components specified
# by RemoteComponent objects, names, and ids. It returns an array of
# RemoteComponent objects.

sub _convert_components {
    my ($self, $components, $project) = @_;
    is_array_ref($components) or croak "The 'components' value must be an ARRAY ref.\n";
    my @converted;
    my $pcomponents;		# project components
    foreach my $component (@{$components}) {
	if (is_instance($component => 'RemoteComponent')) {
	    push @converted, $component;
	} elsif (is_integer($component)) {
	    push @converted, RemoteComponent->new($component);
	} else {
	    # It's a component name. Let us convert it into its id.
	    croak "Cannot convert component names because I don't know for which project.\n"
		unless $project;
	    $pcomponents = $self->get_components($project) unless defined $pcomponents;
	    croak "There is no component called '$component'.\n"
		unless exists $pcomponents->{$component};
	    push @converted, RemoteComponent->new($pcomponents->{$component}{id});
	}
    }
    return \@converted;
}

# This routine receives an array with a list of $versions specified by
# RemoteVersion objects, names, and ids. It returns an array of
# RemoteVersion objects.

sub _convert_versions {
    my ($self, $versions, $project) = @_;
    is_array_ref($versions) or croak "The '$versions' value must be an ARRAY ref.\n";
    my @converted;
    my $pversions;		# project versions
    foreach my $version (@{$versions}) {
	if (is_instance($version => 'RemoteVersion')) {
	    push @converted, $version;
	} elsif (is_integer($version)) {
	    push @converted, RemoteVersion->new($version);
	} else {
	    # It is a version name. Let us convert it into its id.
	    croak "Cannot convert version names because I don't know for which project.\n"
		unless $project;
	    $pversions = $self->get_versions($project) unless defined $pversions;
	    croak "There is no version called '$version'.\n"
		unless exists $pversions->{$version};
	    push @converted, RemoteVersion->new($pversions->{$version}{id});
	}
    }
    return \@converted;
}

# This routine returns a duedate as a SOAP::Data object with type
# 'date'. It can generate this from a DateTime object or from a string
# in the format YYYY-MM-DD.

sub _convert_duedate {
    my ($self, $duedate) = @_;
    if (is_instance($duedate => 'DateTime')) {
	return SOAP::Data->type(date => $duedate->strftime('%F'));
    } elsif (is_string($duedate)) {
	if (my ($year, $month, $day) = ($duedate =~ /^(\d{4})-(\d{2})-(\d{2})/)) {
	    $month >= 1 and $month <= 12
		or croak "Invalid duedate ($duedate).\n";
	    return SOAP::Data->type(date => $duedate);
	}
    }
    return $duedate;
}

# This routine receives a hash mapping custom field's ids to
# values. The ids can be specified by their real id or by their id's
# numeric suffix (as the 1000 in 'customfield_1000'). Scalar values
# are substituted by references to arrays containing the original
# value. The routine returns a hash-ref to another hash with converted
# keys and values.

sub _convert_custom_fields {
    my ($self, $custom_fields) = @_;
    is_hash_ref($custom_fields) or croak "The 'custom_fields' value must be a HASH ref.\n";
    my %converted;
    while (my ($id, $values) = each %$custom_fields) {
	my $realid = $id;
        unless ($realid =~ /^customfield_\d+$/) {
            my $cfs = $self->get_custom_fields();
            croak "Can't find custom field named '$id'.\n"
                unless exists $cfs->{$id};
            $realid = $cfs->{$id}{id};
        }

	# Custom field values must be specified as ARRAYs but we allow for some short-cuts.
	if (is_value($values)) {
	    $converted{$realid} = [$values];
	} elsif (is_array_ref($values)) {
	    $converted{$realid} = $values;
	} elsif (is_hash_ref($values)) {
	    # This is a short-cut for a Cascading select field, which
	    # must be specified like this: http://tinyurl.com/2bmthoa
	    # The short-cut requires a HASH where each cascading level
	    # is indexed by its level number, starting at zero.
	    foreach my $level (sort {$a <=> $b} keys %$values) {
		my $level_values = $values->{$level};
		$level_values = [$level_values] unless ref $level_values;
		if ($level eq '0') {
		    # The first level doesn't have a colon
		    $converted{$realid} = $level_values
		} elsif ($level =~ /^\d+$/) {
		    $converted{"$realid:$level"} = $level_values;
		} else {
		    croak "Invalid cascading field values level spec ($level). It must be a natural number.\n";
		}
	    }
	} else {
	    croak "Custom field '$id' got a '", ref($values), "' reference as a value.\nValues can only be specified as scalars, ARRAYs, or HASHes though.\n";
	}
    }
    return \%converted;
}

my %_converters = (
    affectsVersions => \&_convert_versions,
    components      => \&_convert_components,
    custom_fields   => \&_convert_custom_fields,
    duedate         => \&_convert_duedate,
    fixVersions     => \&_convert_versions,
    priority        => \&_convert_priority,
    resolution      => \&_convert_resolution,
    type            => \&_convert_type,
);

# Accept both names for fields with duplicate names.
foreach my $field (keys %JRA12300) {
    $_converters{$JRA12300{$field}} = $_converters{$field};
}

# This routine applies all the previous conversions to the $params
# hash. It returns a reference another hash with converted keys and
# values, which is the base for invoking the methods createIssue,
# UpdateIssue, and progressWorkflowAction.

sub _convert_params {
    my ($self, $params, $project) = @_;

    my %converted;

    # Convert fields' values
    while (my ($field, $value) = each %$params) {
	$converted{$field} =
	    exists $_converters{$field}
		? $_converters{$field}->($self, $value, $project)
		    : $value;
    }

    return \%converted;
}

# This routine gets a hash produced by _convert_params and flatens in
# place its Component, Version, and custom_fields fields. It also
# converts the hash's key according with the %JRA12300 table. It goes
# a step further before invoking the methods UpdateIssue and
# progressWorkflowAction.

sub _flaten_components_and_versions {
    my ($params) = @_;

    # Flaten Component and Version fields
    for my $field (grep {exists $params->{$_}} qw/components affectsVersions fixVersions/) {
	$params->{$field} = [map {$_->{id}} @{$params->{$field}}];
    }

    # Flaten the customFieldValues field
    if (my $custom_fields = delete $params->{custom_fields}) {
        while (my ($id, $values) = each %$custom_fields) {
            $params->{$id} = $values;
        }
    }

    # Due to a bug in JIRA we have to substitute the names of some fields.
    foreach my $field (grep {exists $params->{$_}} keys %JRA12300) {
	$params->{$JRA12300{$field}} = delete $params->{$field};
    }

    return;
}


sub create_issue
{
    my ($self, $params, $seclevel) = @_;
    is_hash_ref($params) or croak "create_issue's requires a HASH-ref argument.\n";
    for my $field (qw/project summary type/) {
        croak "create_issue's HASH ref must define a '$field'.\n"
            unless exists $params->{$field};
    }

    $params = $self->_convert_params($params, $params->{project});

    # Substitute customFieldValues array for custom_fields hash
    if (my $cfs = delete $params->{custom_fields}) {
        $params->{customFieldValues} = [map {RemoteCustomFieldValue->new($_, $cfs->{$_})} keys %$cfs];
    }

    if (my $parent = delete $params->{parent}) {
	if (defined $seclevel) {
	    return $self->createIssueWithParentWithSecurityLevel($params, $parent, _convert_security_level($self, $seclevel, $params->{project}));
	} else {
	    return $self->createIssueWithParent($params, $parent);
	}
    } else {
	if (defined $seclevel) {
	    return $self->createIssueWithSecurityLevel($params, _convert_security_level($self, $seclevel, $params->{project}));
	} else {
	    return $self->createIssue($params);
	}
    }
}


sub update_issue
{
    my ($self, $issue, $params) = @_;
    my $key;
    if (is_instance($issue => 'RemoteIssue')) {
	$key = $issue->{key};
    } else {
	$key = $issue;
	$issue = $self->getIssue($key);
    }

    is_hash_ref($params) or croak "update_issue second argument must be a HASH ref.\n";

    my ($project) = ($key =~ /^([^-]+)/);

    $params = $self->_convert_params($params, $project);

    _flaten_components_and_versions($params);

    return $self->updateIssue($key, $params);
}


sub get_issue_types {
    my ($self) = @_;
    $self->{cache}{issue_types} ||= {map {$_->{name} => $_} @{$self->getIssueTypes()}};
    return $self->{cache}{issue_types};
}


sub get_subtask_issue_types {
    my ($self) = @_;
    $self->{cache}{subtask_issue_types} ||= {map {$_->{name} => $_} @{$self->getSubTaskIssueTypes()}};
    return $self->{cache}{subtask_issue_types};
}


sub get_statuses {
    my ($self) = @_;
    $self->{cache}{statuses} ||= {map {$_->{name} => $_} @{$self->getStatuses()}};
    return $self->{cache}{statuses};
}


sub get_priorities {
    my ($self) = @_;
    $self->{cache}{priorities} ||= {map {$_->{name} => $_} @{$self->getPriorities()}};
    return $self->{cache}{priorities};
}


sub get_resolutions {
    my ($self) = @_;
    $self->{cache}{resolutions} ||= {map {$_->{name} => $_} @{$self->getResolutions()}};
    return $self->{cache}{resolutions};
}


sub get_security_levels {
    my ($self, $project_key) = @_;
    $self->{cache}{seclevels}{$project_key} ||= {map {$_->{name} => $_} @{$self->getSecurityLevels($project_key)}};
    return $self->{cache}{seclevels}{$project_key};
}


sub get_custom_fields {
    my ($self) = @_;
    $self->{cache}{custom_fields} ||= {map {$_->{name} => $_} @{$self->getCustomFields()}};
    return $self->{cache}{custom_fields};
}


sub set_custom_fields {
    my ($self, $cfs) = @_;
    $self->{cache}{custom_fields} = $cfs;
    return;
}


sub get_components {
    my ($self, $project_key) = @_;
    $self->{cache}{components}{$project_key} ||= {map {$_->{name} => $_} @{$self->getComponents($project_key)}};
    return $self->{cache}{components}{$project_key};
}


sub get_versions {
    my ($self, $project_key) = @_;
    $self->{cache}{versions}{$project_key} ||= {map {$_->{name} => $_} @{$self->getVersions($project_key)}};
    return $self->{cache}{versions}{$project_key};
}


sub get_favourite_filters {
    my ($self) = @_;
    $self->{cache}{filters} ||= {map {$_->{name} => $_} @{$self->getFavouriteFilters()}};
    return $self->{cache}{filters};
}


sub set_filter_iterator {
    my ($self, $filter, $cache_size) = @_;

    if ($filter =~ /\D/) {
        my $filters = $self->getSavedFilters();
        foreach my $f (@$filters) {
            if ($f->{name} eq $filter) {
                $filter = $f->{id};
                last;
            }
        }
        croak "Can't find filter '$filter'\n" if $filter =~ /\D/;
    }

    if ($cache_size) {
        croak "set_filter_iterator's second arg must be a number ($cache_size).\n"
            if $cache_size =~ /\D/;
    }

    $self->{iter} = {
        id     => $filter,
        offset => 0,  # offset to be used in the next call to getIssuesFromFilterWithLimit
        issues => [], # issues returned by the last call to getIssuesFromFilterWithLimit
        size   => $cache_size || 128,
    };

    return;
}


sub next_issue {
    my ($self) = @_;
    defined $self->{iter}
        or croak "You must call setFilterIterator before calling nextIssue\n";
    my $iter = $self->{iter};
    if (@{$iter->{issues}} == 0) {
        if ($iter->{id}) {
            my $issues = eval {$self->getIssuesFromFilterWithLimit($iter->{id}, $iter->{offset}, $iter->{size})};
            if ($@) {
                # The getIssuesFromFilterWithLimit appeared in JIRA
                # 3.13.4. Before that we had to use the unsafe
                # getIssuesFromFilter. Here we detect that we're talking
                # with an old JIRA and resort to the deprecated method
                # instead.
                croak $@ unless $@ =~ /No such operation/;
                $iter->{issues} = $self->getIssuesFromFilter($iter->{id});
                $iter->{id}     = undef;
            }
            elsif (@$issues) {
                $iter->{offset} += @$issues;
                $iter->{issues}  =  $issues;
            }
            else {
                $self->{iter} = undef;
                return;
            }
        }
        else {
            return;
        }
    }
    return shift @{$iter->{issues}};
}


sub progress_workflow_action_safely {
    my ($self, $issue, $action, $params) = @_;
    my $key;
    if (is_instance($issue => 'RemoteIssue')) {
        $key   = $issue->{key};
    } else {
	$key   = $issue;
	$issue = undef;
    }
    $params = {} unless defined $params;
    is_hash_ref($params) or croak "progress_workflow_action_safely's third arg must be a HASH-ref\n";

    # Grok the action id if it's not a number
    if ($action =~ /\D/) {
        my @available_actions = @{$self->getAvailableActions($key)};
        my @named_actions     = grep {$action eq $_->{name}} @available_actions;
        if (@named_actions) {
            $action = $named_actions[0]->{id};
        } else {
            croak "Unavailable action ($action).\n";
        }
    }

    # Make sure $params contains all the fields that are present in
    # the action screen.
    my @fields = @{$self->getFieldsForAction($key, $action)};
    foreach my $id (map {$_->{id}} @fields) {
        # Due to a bug in JIRA we have to substitute the names of some fields.
	$id = $JRA12300_backwards{$id} if $JRA12300_backwards{$id};

        next if exists $params->{$id};

        $issue = $self->getIssue($key) unless defined $issue;
        if (exists $issue->{$id}) {
            $params->{$id} = $issue->{$id} if defined $issue->{$id};
        }
	# NOTE: It's not a problem if we can't find a missing
	# parameter in the issue. It will simply stay undefined.
    }

    my ($project) = ($key =~ /^([^-]+)/);

    $params = $self->_convert_params($params, $project);

    _flaten_components_and_versions($params);

    return $self->progressWorkflowAction($key, $action, $params);
}


sub get_issue_custom_field_values {
    my ($self, $issue, @cfs) = @_;
    my @values;
    my $cfs;
  CUSTOM_FIELD:
    foreach my $cf (@cfs) {
        unless ($cf =~ /^customfield_\d+$/) {
            $cfs = $self->get_custom_fields() unless defined $cfs;
            croak "Can't find custom field named '$cf'.\n"
                unless exists $cfs->{$cf};
            $cf = $cfs->{$cf}{id};
        }
        foreach my $rcfv (@{$issue->{customFieldValues}}) {
            if ($rcfv->{customfieldId} eq $cf) {
                push @values, $rcfv->{values};
                next CUSTOM_FIELD;
            }
        }
        push @values, undef;    # unset custom field
    }
    return wantarray ? @values : \@values;
}


sub attach_files_to_issue {
    my ($self, $issue, @files) = @_;

    # First we process the @files specification. Filenames are pushed
    # in @filenames and @attachments will end up with IO objects from
    # which the file contents are going to be read later.

    my (@filenames, @attachments);

    for my $file (@files) {
	if (is_string($file)) {
	    require File::Basename;
	    push @filenames, File::Basename::basename($file);
	    open my $fh, '<:raw', $file
		or croak "Can't open $file: $!\n";
	    push @attachments, $fh;
            close $fh;
	} elsif (is_hash_ref($file)) {
	    while (my ($name, $contents) = each %$file) {
		push @filenames, $name;
		if (is_string($contents)) {
		    open my $fh, '<:raw', $contents
			or croak "Can't open $contents: $!\n";
		    push @attachments, $fh;
                    close $fh;
		} elsif (is_glob_ref($contents)
			     || is_instance($contents => 'IO::File')
				 || is_instance($contents => 'FileHandle')) {
		    push @attachments, $contents;
		} else {
		    croak "Invalid content specification for file $name.\n";
		}
	    }
	} else {
	    croak "Files must be specified by STRINGs or HASHes, not by " . ref($file) . "s\n";
	}
    }

    # Now we have to read all file contents and encode them to Base64.

    require MIME::Base64;
    for my $i (0 .. $#attachments) {
	my $fh = $attachments[$i];
	my $attachment = '';
	my $chars_read;
	while ($chars_read = read $fh, my $buf, 57*72) {
	    $attachment .= MIME::Base64::encode_base64($buf);
	}
	defined $chars_read
	    or croak "Error reading '$filenames[$i]': $!\n";
	length $attachment
	    or croak "Can't attach empty file '$filenames[$i]'\n";
	$attachments[$i] = $attachment;
    }

    return $self->addBase64EncodedAttachmentsToIssue($issue, \@filenames, \@attachments);
}


sub attach_strings_to_issue {
    my ($self, $issue, $hash) = @_;

    require MIME::Base64;

    my (@filenames, @attachments);

    while (my ($filename, $contents) = each %$hash) {
	push @filenames,   $filename;
	push @attachments, MIME::Base64::encode_base64($contents);
    }

    return $self->addBase64EncodedAttachmentsToIssue($issue, \@filenames, \@attachments);
}


sub filter_issues_unsorted {
    my ($self, $filter, $limit) = @_;

    $filter =~ s/^\s*"?//;
    $filter =~ s/"?\s*$//;

    if ($filter =~ /^(?:[A-Z]+-\d+\s+)*[A-Z]+-\d+$/i) {
        # space separated key list

        # Let's construct a JQL query in the form "issuekey IN (...)" to
        # pass to getIssuesFromJqlSearch.

        my %keys = map {($_ => undef)} split / /, $filter; # discard duplicates
        my @keys = keys %keys;

        # If the list is too big we split it up and invoke
        # getIssuesFromJqlSearch several times.
        my @issues;
        while (my @subkeys = splice(@keys, 0, 128)) {
            my $jql = 'issuekey IN (' . join(',', @subkeys) . ')';
            push @issues, @{$self->getIssuesFromJqlSearch($jql, 1000)};
        }
        return @issues;
    } elsif ($filter =~ /^[\w-]+$/i) {
        # saved filter
        return @{$self->getIssuesFromFilterWithLimit($filter, 0, $limit || 1000)};
    } else {
        # JQL filter
        return @{$self->getIssuesFromJqlSearch($filter, $limit || 1000)};
    }
}


sub filter_issues {
    my ($self, $filter, $limit) = @_;

    # Order the issues by project key and then by numeric value using
    # a Schwartzian transform.
    return
        map  {$_->[2]}
            sort {$a->[0] cmp $b->[0] or $a->[1] <=> $b->[1]}
                map  {my ($p, $n) = ($_->{key} =~ /([A-Z]+)-(\d+)/); [$p, $n, $_]}
                    filter_issues_unsorted($self, $filter, $limit);
}


## no critic (Modules::ProhibitMultiplePackages)

package RemoteFieldValue;
$RemoteFieldValue::VERSION = '0.45';
sub new {
    my ($class, $id, $values) = @_;

    # Due to a bug in JIRA we have to substitute the names of some fields.
    $id = $JRA12300{$id} if exists $JRA12300{$id};

    $values = [$values] unless ref $values;
    return bless({id => $id, values => $values}, $class);
}


package RemoteCustomFieldValue;
$RemoteCustomFieldValue::VERSION = '0.45';
sub new {
    my ($class, $id, $values) = @_;

    $values = [$values] unless ref $values;
    return bless({customfieldId => $id, key => undef, values => $values} => $class);
}


package RemoteComponent;
$RemoteComponent::VERSION = '0.45';
sub new {
    my ($class, $id, $name) = @_;
    my $o = bless({id => $id}, $class);
    $o->{name} = $name if $name;
    return $o;
}


package RemoteVersion;
$RemoteVersion::VERSION = '0.45';
sub new {
    my ($class, $id, $name) = @_;
    my $o = bless({id => $id}, $class);
    $o->{name} = $name if $name;
    return $o;
}

package JIRA::Client;

# Almost all of the JIRA API parameters are strings. The %typeof hash
# specifies the exceptions. It maps a method name to a hash mapping a
# parameter position to its type. (The parameter position is
# zero-based, after the authentication token.

my %typeof = (
    addActorsToProjectRole                   => {1 => \&_cast_remote_project_role},
    addAttachmentsToIssue              	     => \&_cast_attachments,
    addBase64EncodedAttachmentsToIssue 	     => \&_cast_base64encodedattachments,
    addComment                         	     => {0 => \&_cast_issue_key, 1 => \&_cast_remote_comment},
    addDefaultActorsToProjectRole            => {1 => \&_cast_remote_project_role},
    # addPermissionTo
    # addUserToGroup
    # addVersion
    addWorklogAndAutoAdjustRemainingEstimate => {0 => \&_cast_issue_key},
    addWorklogAndRetainRemainingEstimate     => {0 => \&_cast_issue_key},
    addWorklogWithNewRemainingEstimate       => {0 => \&_cast_issue_key},
    archiveVersion                     	     => {2 => 'boolean'},
    # createGroup
    # createIssue
    createIssueWithParent                    => {1 => \&_cast_issue_key},
    createIssueWithParentWithSecurityLevel   => {1 => \&_cast_issue_key, 2 => 'long'},
    createIssueWithSecurityLevel       	     => {1 => 'long'},
    # createPermissionScheme
    # createProject
    # createProjectFromObject
    createProjectRole                        => {0 => \&_cast_remote_project_role},
    # createUser
    # deleteGroup
    deleteIssue                 	     => {0 => \&_cast_issue_key},
    # deletePermissionFrom
    # deletePermissionScheme
    # deleteProject
    deleteProjectAvatar                	     => {0 => 'long'},
    deleteProjectRole                  	     => {0 => \&_cast_remote_project_role, 1 => 'boolean'},
    # deleteUser
    # deleteWorklogAndAutoAdjustRemainingEstimate
    # deleteWorklogAndRetainRemainingEstimate
    # deleteWorklogWithNewRemainingEstimate
    # editComment
    # getAllPermissions
    getAssociatedNotificationSchemes         => {0 => \&_cast_remote_project_role},
    getAssociatedPermissionSchemes           => {0 => \&_cast_remote_project_role},
    getAttachmentsFromIssue           	     => {0 => \&_cast_issue_key},
    getAvailableActions           	     => {0 => \&_cast_issue_key},
    getComment                         	     => {0 => 'long'},
    getComments                        	     => {0 => \&_cast_issue_key},
    # getComponents
    # getConfiguration
    # getCustomFields
    getDefaultRoleActors                     => {0 => \&_cast_remote_project_role},
    # getFavouriteFilters
    getFieldsForAction                 	     => {0 => \&_cast_issue_key},
    getFieldsForCreate                       => {1 => 'long'},
    getFieldsForEdit                 	     => {0 => \&_cast_issue_key},
    # getGroup
    getIssue	                 	     => {0 => \&_cast_issue_key},
    # getIssueById
    getIssueCountForFilter             	     => {0 => \&_cast_filter_name_to_id},
    getIssuesFromFilter                	     => {0 => \&_cast_filter_name_to_id},
    getIssuesFromFilterWithLimit       	     => {0 => \&_cast_filter_name_to_id, 1 => 'int', 2 => 'int'},
    getIssuesFromJqlSearch             	     => {1 => 'int'},
    # getIssuesFromTextSearch
    getIssuesFromTextSearchWithLimit   	     => {1 => 'int', 2 => 'int'},
    getIssuesFromTextSearchWithProject 	     => {2 => 'int'},
    # getIssueTypes
    # getIssueTypesForProject
    # getNotificationSchemes
    # getPermissionSchemes
    # getPriorities
    # getProjectAvatar
    getProjectAvatars                  	     => {1 => 'boolean'},
    getProjectById                     	     => {0 => 'long'},
    # getProjectByKey
    getProjectRole                     	     => {0 => 'long'},
    getProjectRoleActors               	     => {0 => \&_cast_remote_project_role},
    # getProjectRoles
    # getProjectsNoSchemes
    getProjectWithSchemesById          	     => {0 => 'long'},
    getResolutionDateById              	     => {0 => 'long'},
    getResolutionDateByKey             	     => {0 => \&_cast_issue_key},
    # getResolutions
    # getSavedFilters
    getSecurityLevel             	     => {0 => \&_cast_issue_key},
    # getSecurityLevels
    # getSecuritySchemes
    # getServerInfo
    # getStatuses
    # getSubTaskIssueTypes
    # getSubTaskIssueTypesForProject
    # getUser
    # getVersions
    getWorklogs		             	     => {0 => \&_cast_issue_key},
    hasPermissionToCreateWorklog       	     => {0 => \&_cast_issue_key},
    # hasPermissionToDeleteWorklog
    # hasPermissionToEditComment
    # hasPermissionToUpdateWorklog
    # isProjectRoleNameUnique
    # login ##NOT USED##
    # logout ##NOT USED##
    progressWorkflowAction             	     => {0 => \&_cast_issue_key, 2 => \&_cast_remote_field_values},
    # refreshCustomFields
    # releaseVersion
    removeActorsFromProjectRole              => {1 => \&_cast_remote_project_role},
    # removeAllRoleActorsByNameAndType
    # removeAllRoleActorsByProject
    removeDefaultActorsFromProjectRole       => {1 => \&_cast_remote_project_role},
    # removeUserFromGroup
    # setNewProjectAvatar
    setProjectAvatar                   	     => {1 => 'long'},
    # setUserPassword
    # updateGroup
    updateIssue                        	     => {0 => \&_cast_issue_key, 1 => \&_cast_remote_field_values},
    # updateProject
    updateProjectRole                        => {0 => \&_cast_remote_project_role},
    # updateUser
    # updateWorklogAndAutoAdjustRemainingEstimate
    # updateWorklogAndRetainRemainingEstimate
    # updateWorklogWithNewRemainingEstimate
);

sub _cast_issue_key {
    my ($self, $issue) = @_;
    return ref $issue ? $issue->{key} : $issue;
}

sub _cast_remote_comment {
    my ($self, $arg) = @_;
    return ref $arg ? $arg : bless({body => $arg} => 'RemoteComment');
}

sub _cast_filter_name_to_id {
    my ($self, $arg) = @_;
    is_string($arg) or croak "Filter arg must be a string.\n";
    return $arg unless $arg =~ /\D/;
    my $filters = $self->get_favourite_filters();
    exists $filters->{$arg} or croak "Unknown filter: $arg\n";
    return $filters->{$arg}{id};
}

sub _cast_remote_field_values {
    my ($self, $arg) = @_;
    return is_hash_ref($arg) ? [map {RemoteFieldValue->new($_, $arg->{$_})} keys %$arg] : $arg;
}

sub _cast_remote_project_role {
    my ($self, $arg) = @_;
    if (is_instance($arg => 'RemoteProjectRole') && exists $arg->{id} && is_string($arg->{id})) {
	$arg->{id} = SOAP::Data->type(long => $arg->{id});
    }
    return $arg;
}

sub _cast_attachments {
    my ($self, $method, $args) = @_;
    # The addAttachmentsToIssue method is deprecated and requires too
    # much overhead to pass the file contents over the wire. Here we
    # convert the arguments to call the newer
    # addBase64EncodedAttachmentsToIssue method instead.
    require MIME::Base64;
    for my $content (@{$args->[2]}) {
	$content = MIME::Base64::encode_base64($content);
    }
    $$method = 'addBase64EncodedAttachmentsToIssue';
    _cast_base64encodedattachments($self, $method, $args);
    return;
}

sub _cast_base64encodedattachments {
    my ($self, $method, $args) = @_;
    $args->[0] = _cast_issue_key($self, $args->[0]);
    # We have to set the names of the arrays and of its elements
    # because the default naming isn't properly understood by JIRA.
    for my $i (1 .. 2) {
	$args->[$i] = SOAP::Data->name(
	    "array$i",
	    [map {SOAP::Data->name("elem$i", $_)} @{$args->[$i]}],
	);
    }
    return;
}

# All methods follow the same call convention, which makes it easy to
# implement them all with an AUTOLOAD.

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self, @args) = @_;
    (my $method = $AUTOLOAD) =~ s/.*:://;

    # Perform any non-default type coersion
    if (my $typeof = $typeof{$method}) {
	if (is_hash_ref($typeof)) {
	    while (my ($i, $type) = each %$typeof) {
		if (is_code_ref($type)) {
		    $args[$i] = $type->($self, $args[$i]);
		} elsif (is_value($args[$i])) {
		    $args[$i] = SOAP::Data->type($type => $args[$i]);
		} elsif (is_array_ref($args[$i])) {
		    foreach (@{$args[$i]}) {
			$_ = SOAP::Data->type($type => $_);
		    }
		} elsif (is_hash_ref($args[$i])) {
		    foreach (values %{$args[$i]}) {
			$_ = SOAP::Data->type($type => $_);
		    }
		} else {
		    croak "Can't coerse argument $i of method $AUTOLOAD.\n";
		}
	    }
	} elsif (is_code_ref($typeof)) {
	    $typeof->($self, \$method, \@args);
	}
    }

    my $call = $self->{soap}->call($method, $self->{auth}, @args);
    croak $call->faultcode(), ', ', $call->faultstring()
        if defined $call->fault();
    return $call->result();
}


1; # End of JIRA::Client

__END__

=pod

=encoding UTF-8

=head1 NAME

JIRA::Client - (DEPRECATED) Extended interface to JIRA's SOAP API

=head1 VERSION

version 0.45

=head1 SYNOPSIS

  use JIRA::Client;

  my $jira = JIRA::Client->new('http://jira.example.com/jira', 'user', 'passwd');

  my $issue = $jira->create_issue(
    {
      project => 'TST',
      type => 'Bug',
      summary => 'Summary of the bug',
      assignee => 'gustavo',
      components => ['compa', 'compb'],
      fixVersions => ['1.0.1'],
      custom_fields => {Language => 'Perl', Architecture => 'Linux'},
    }
  );

  $issue = eval { $jira->getIssue('TST-123') };
  die "Can't getIssue(): $@" if $@;

  $jira->set_filter_iterator('my-filter');
  while (my $issue = $jira->next_issue()) {
      # ...
  }

=head1 DESCRIPTION

B<DEPRECATION WARNING>: Please, before using this module consider using the
newer L<JIRA::REST> because JIRA's SOAP API was
L<deprecated|https://developer.atlassian.com/jiradev/latest-updates/soap-and-xml-rpc-api-deprecation-notice>
on JIRA 6.0 and isn't available anymore on JIRA 7.0.

JIRA is a proprietary bug tracking system from Atlassian
(L<http://www.atlassian.com/software/jira/>).

This module implements an Object Oriented wrapper around JIRA's SOAP
API, which is specified in
L<http://docs.atlassian.com/software/jira/docs/api/rpc-jira-plugin/latest/com/atlassian/jira/rpc/soap/JiraSoapService.html>.
(This version is known work against JIRA 4.4.)

Moreover, it implements some other methods to make it easier to do
some common operations.

=head1 API METHODS

With the exception of the API C<login> and C<logout> methods, which
aren't needed, all other methods are available through the
JIRA::Client object interface. You must call them with the same name
as documented in the specification but you should not pass the
C<token> argument, because it is supplied transparently by the
JIRA::Client object.

All methods fail by throwing exceptions (croaking, actually). You may
want to guard against this by invoking them within an eval block, like
this:

  my $issue = eval { $jira->getIssue('TST-123') };
  die "Can't getIssue('TST-123'): $@" if $@;

Some of the API methods require hard-to-build data structures as
arguments. This module tries to make them easier to call by accepting
simpler structures and implicitly constructing the more elaborated
ones before making the actual SOAP call. Note that this is an option,
i.e, you can either pass the elaborate structures by yourself or the
simpler ones in the call.

The items below are all the implemented implicit conversions. Wherever
a parameter of the type specified first is required (as an rvalue, not
as an lvalue) by an API method you can safely pass a value of the type
specified second.

=over 4

=item A B<issue key> as a string can be specified by a B<RemoteIssue> object.

=item A B<RemoteComment> object can be specified by a string.

=item A B<filterId> as a string can be specified by a B<RemoteFilter> object.

=item A B<RemoteFieldValue> object array can be specified by a hash mapping field names to values.

=back

=head1 EXTRA METHODS

This module implements some extra methods to add useful functionality
to the API. They are described below. Note that their names don't
follow the CamelCase convention used by the native API methods but the
more Perlish underscore_separated_words convention so that you can
distinguish them and we can avoid future name clashes.

=head2 B<new> BASEURL, USER, PASSWD [, <SOAP::Lite arguments>]

C<BASEURL> is the JIRA server's base URL (e.g.,
C<https://jira.example.net> or C<https://example.net/jira>), to which
the default WSDL descriptor path
(C</rpc/soap/jirasoapservice-v2?wsdl>) will be appended in order to
construct the underlying SOAP::Lite object.

C<USER> and C<PASSWD> are the credentials that will be used to
authenticate into JIRA.

Any other arguments will be passed to the L<SOAP::Lite> object that
will be created to talk to JIRA.

=head2 B<new> HASH_REF

You can invoke the constructor with a single hash-ref argument. The
same arguments that are passed as a list above can be passed by name
with a hash. This constructor is also more flexible, as it makes room
for extra arguments.

The valid hash keys are listed below.

=over

=item baseurl => STRING

(Required) The JIRA server's base URL.

=item wsdl => STRING

(Optional) JIRA's standard WSDL descriptor path is
C</rpc/soap/jirasoapservice-v2?wsdl>. If your JIRA instance has a
non-standard path to the WSDL service, you may specify it here.

=item user => STRING

(Required) The username to authenticate into JIRA.

=item password => STRING

(Required) The password to authenticate into JIRA.

=item soapargs => ARRAY_REF

(Optional) Extra arguments to be passed to the L<SOAP::Lite> object
that will be created to talk to JIRA.

=back

=head2 B<create_issue> HASH_REF [, SECURITYLEVEL]

Creates a new issue given a hash containing the initial values for its
fields and, optionally, a security-level. The hash must specify at
least the fields C<project>, C<summary>, and C<type>.

This is an easier to use version of the createIssue API method. For
once it accepts symbolic values for some of the issue fields that the
API method does not. Specifically:

=over 4

=item C<type> can be specified by I<name> instead of by I<id>.

=item C<priority> can be specified by I<name> instead of by I<id>.

=item C<component> can be specified by a list of component I<names> or
I<ids> instead of a list of C<RemoteComponent> objects.

=item C<affectsVersions> and C<fixVersions> can be specified by a list
of version I<names> or I<ids> instead of a list of C<RemoteVersion>
objects.

=item C<duedate> can be specified by a DateTime object or by a string
in ISO standard format (YYYY-MM-DD...). (Note that up to JIRA 4.3 you
could pass a string in the format "d/MMM/yy", which was passed as is
to JIRA, which expected a B<string> SOAP type. However, since JIRA 4.4
the server expects a B<date> SOAP type, which must be in the ISO
standard format.)

=back

It accepts a 'magic' field called B<parent>, which specifies the issue
key from which the created issue must be a sub-task.

It accepts another 'magic' field called B<custom_fields> to make it
easy to set custom fields. It accepts a hash mapping each custom field
to its value. The custom field can be specified by its id (in the
format B<customfield_NNNNN>) or by its name, in which case the method
will try to convert it to its id. Note that to do that conversion the
user needs administrator rights.

A simple custom field value can be specified by a scalar, which will
be properly placed inside an ARRAY in order to satisfy the
B<RemoteFieldValue>'s structure.

Cascading select fields are properly specified like this:
http://tinyurl.com/2bmthoa. The magic short-cut requires a HASH where
each cascading level is indexed by its level number, starting at
zero. So, instead of specifying it like this:

    {
        id => 'customfield_10011',
        values => [ SOAP::Data->type(string => '10031' ) ]
    },
    {
        id => 'customfield_10011:1',
        values => [ SOAP::Data->type(string => '10188') ],
    },

You can do it like this:

    {customfield_10011 => {'0' => 10031, '1' => 10188}},

Note that the original hash keys and values are completely preserved.

=head2 B<update_issue> ISSUE_OR_KEY, HASH_REF

Update a issue given a hash containing the values for its fields. The
first argument may be an issue key or a RemoteIssue object. The second
argument must be a hash-ref specifying the fields's values just like
documented in the create_issue function above.

This is an easier to use version of the updateIssue API method because
it accepts the same shortcuts that create_issue does.

=head2 B<get_issue_types>

Returns a hash mapping the server's issue type names to the
RemoteIssueType objects describing them.

=head2 B<get_subtask_issue_types>

Returns a hash mapping the server's sub-task issue type names to the
RemoteIssueType objects describing them.

=head2 B<get_statuses>

Returns a hash mapping the server's status names to the
RemoteStatus objects describing them.

=head2 B<get_priorities>

Returns a hash mapping a server's priorities names to the
RemotePriority objects describing them.

=head2 B<get_resolutions>

Returns a hash mapping a server's resolution names to the
RemoteResolution objects describing them.

=head2 B<get_security_levels> PROJECT-KEY

Returns a hash mapping a project's security level names to the
RemoteSecurityLevel objects describing them.

=head2 B<get_custom_fields>

Returns a hash mapping JIRA's custom field names to the RemoteField
representing them. It's useful since when you get a RemoteIssue object
from this API it doesn't contain the custom field's names, but just
their identifiers. From the RemoteField object you can obtain the
field's B<id>, which is useful when calling the B<updateIssue> method.

The method calls the getCustomFields API method the first time and
keeps the custom fields information in a cache.

=head2 B<set_custom_fields> HASHREF

Passes a hash mapping JIRA's custom field names to the RemoteField
representing them to populate the custom field's cache. This can be
useful if you don't have administrative privileges to the JIRA
instance, since only administrators can call the B<getCustomFields>
API method.

=head2 B<get_components> PROJECT_KEY

Returns a hash mapping a project's components names to the
RemoteComponent objects describing them.

=head2 B<get_versions> PROJECT_KEY

Returns a hash mapping a project's versions names to the RemoteVersion
objects describing them.

=head2 B<get_favourite_filters>

Returns a hash mapping the user's favourite filter names to its filter
ids.

=head2 B<set_filter_iterator> FILTER [, CACHE_SIZE]

Sets up an iterator for the filter identified by FILTER. It must
be called before calls to B<next_issue>.

FILTER can be either a filter I<id> or a filter I<name>, in which case
it's converted to a filter id with a call to C<getSavedFilters>.

CACHE_SIZE defines the number of issues that will be pre-fetched by
B<nect_issue> using C<getIssuesFromFilterWithLimit>. If not specified,
a suitable default will be used.

=head2 B<next_issue>

This must be called after a call to B<set_filter_iterator>. Each call
returns a reference to the next issue from the filter. When there are
no more issues it returns undef.

=head2 B<progress_workflow_action_safely> ISSUE, ACTION, PARAMS

This is a safe and easier to use version of the
B<progressWorkflowAction> API method which is used to progress an
issue through a workflow's action while making edits to the fields
that are shown in the action screen. The API method is dangerous
because if you forget to provide new values to all the fields shown in
the screen, then the fields not provided will become undefined in the
issue. The problem has a pending issue on Atlassian's JIRA
L<http://jira.atlassian.com/browse/JRA-8717>.

This method plays it safe by making sure that all fields shown in the
screen that already have a value are given new (or the same) values so
that they don't get undefined. It calls the B<getFieldsForAction> API
method to grok all fields that are shown in the screen. If there is
any field not set in the ACTION_PARAMS then it calls B<getIssue> to
grok the missing fields current values. As a result it constructs the
necessary RemoteFieldAction array that must be passed to
progressWorkflowAction.

The method is also easier to use because its arguments are more
flexible:

=over 4

=item C<ISSUE> can be either an issue key or a RemoteIssue object
returned by a previous call to, e.g., C<getIssue>.

=item C<ACTION> can be either an action I<id> or an action I<name>.

=item C<PARAMS> must be a hash mapping field names to field
values. This hash is treated in the same way as the hash passed to the
function B<create_issue> above.

=back

For example, instead of using this:

  my $action_id = somehow_grok_the_id_of('close');
  $jira->progressWorkflowAction('PRJ-5', $action_id, [
    RemoteFieldValue->new(2, 'new value'),
    ..., # all fields must be specified here
  ]);

And risking to forget to pass some field you can do this:

  $jira->progress_workflow_action_safely('PRJ-5', 'close', {2 => 'new value'});

=head2 B<get_issue_custom_field_values> ISSUE, NAME_OR_IDs

This method receives a RemoteField object and a list of names or ids
of custom fields. It returns a list of references to the ARRAYs
containing the values of the ISSUE's custom fields denoted by their
NAME_OR_IDs. Returns undef for custom fields not set on the issue.

In scalar context it returns a reference to the list.

=head2 B<attach_files_to_issue> ISSUE, FILES...

This method attaches one or more files to an issue. The ISSUE argument
may be an issue key or a B<RemoteIssue> object. The attachments may be
specified in two ways:

=over 4

=item STRING

A string denotes a filename to be open and read. In this case, the
attachment name is the file's basename.

=item HASHREF

When you want to specify a different name to the attachment or when
you already have an IO object (a GLOB, a IO::File, or a FileHandle)
you must pass them as values of a hash. The keys of the hash are taken
as the attachment name. You can specify more than one attachment in
each hash.

=back

The method returns the value returned by the
B<addBase64EncodedAttachmentsToIssue> API method.

In the example below, we attach three files to the issue TST-1. The
first is called C<file1.txt> and its contents are read from
C</path/to/file1.txt>. The second is called C<text.txt> and its
contents are read from C</path/to/file2.txt>. the third is called
C<me.jpg> and its contents are read from the object referred to by
C<$fh>.

    $jira->attach_files_to_issue('TST-1',
                                 '/path/to/file1.txt',
                                 {
                                     'text.txt' => '/path/to/file2.txt',
                                     'me.jpg'   => $fh,
                                 },
    );

=head2 B<attach_strings_to_issue> ISSUE, HASHREF

This method attaches one or more strings to an issue. The ISSUE
argument may be an issue key or a B<RemoteIssue> object. The
attachments are specified by a HASHREF in which the keys denote the
file names and the values their contents.

The method returns the value returned by the
B<addBase64EncodedAttachmentsToIssue> API method.

=head2 B<filter_issues_unsorted> FILTER [, LIMIT]

This method returns a list of RemoteIssue objects from the specified
FILTER, which is a string that is understood in one of these ways (in
order):

=over

=item A space-separated list of issue keys

To specify issues explicitly by their keys, which must match
/[A-Z]+-\d+/i. The letters in the key are upcased before being passed
to getIssue. For example:

    KEY-123 chave-234 CLAVE-345

Note that the result list doesn't respect the order in which the keys are
specified and also that duplicate keys are discarded and the corresponding
issue appear only once in the resulting list.

=item The name of a saved filter

If FILTER is a single word, it is passed to
getIssuesFromFilterWithLimit as a filter name. For example:

    sprint-backlok-filter

=item A JQL expression

As a last resort, FILTER is passed to getIssuesFromJqlSearch as a JQL
expression. For example:

    project = CDS AND fixVersion = sprint-5

=back

The optional LIMIT argument specified the maximum number of issues
that can be returned. It has a default limit of 1000, but this can be
overridden by the JIRA server configuration.

This method is meant to be used as a flexible interface for human
beings to request a list of issues. Be warned, however, that you are
responsible to de-taint the FILTER argument before passing it to the
method.

=head2 B<filter_issues> FILTER [, LIMIT]

This method invokes the B<filter_issues_unsorted> method with the same
arguments and returns the list of RemoteIssue objects sorted by issue key.

=head1 OTHER CONSTRUCTORS

The JIRA SOAP API uses several types of objects (i.e., classes) for
which the Perl SOAP interface does not provide the necessary
constructors. This module implements some of them.

=head2 B<RemoteFieldValue-E<gt>new> ID, VALUES

The RemoteFieldValue object represents the value of a field of an
issue. It needs two arguments:

=over

=item ID

The field name, which must be a valid key for the ISSUE hash.

=item VALUES

A scalar or an array of scalars.

=back

=head2 B<RemoteCustomFieldValue-E<gt>new> ID, VALUES

The RemoteCustomFieldValue object represents the value of a
custom_field of an issue. It needs two arguments:

=over

=item ID

The field name, which must be a valid custom_field key.

=item VALUES

A scalar or an array of scalars.

=back

=head2 B<RemoteComponent-E<gt>new> ID, NAME

=head2 B<RemoteVersion-E<gt>new> ID, NAME

=head1 EXAMPLES

Please, see the examples under the C<examples> directory in the module
distribution.

=head1 SEE ALSO

=over

=item * L<JIRA::REST>

=back

=head1 REPOSITORY

L<https://github.com/gnustavo/JIRA-Client>

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by CPqD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
