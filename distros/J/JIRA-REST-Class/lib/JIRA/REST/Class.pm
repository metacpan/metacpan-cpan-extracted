package JIRA::REST::Class;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: An OO Class module built atop L<JIRA::REST|JIRA::REST> for dealing with JIRA issues and their data as objects.

use Carp;
use Clone::Any qw( clone );
use Readonly 2.04;

use JIRA::REST;
use JIRA::REST::Class::Factory;
use parent qw(JIRA::REST::Class::Mixins);

#---------------------------------------------------------------------------
# Constants

Readonly my $DEFAULT_MAXRESULTS => 50;

#---------------------------------------------------------------------------

sub new {
    my ( $class, @arglist ) = @_;

    my $args = $class->_get_known_args(
        \@arglist,
        qw/ url username password rest_client_config
            proxy ssl_verify_none anonymous /
    );

    return bless {
        jira_rest => $class->JIRA_REST( clone( $args ) ),
        factory   => $class->factory( clone( $args ) ),
        args      => clone( $args ),
    }, $class;
}

#---------------------------------------------------------------------------
#
# using Inline::Test to generate testing files from tests
# declared next to the code that it's testing
#

#pod =begin test setup 1
#pod
#pod use File::Basename;
#pod use lib dirname($0).'/..';
#pod use MyTest;
#pod use 5.010;
#pod
#pod TestServer_setup();
#pod
#pod END {
#pod     TestServer_stop();
#pod }
#pod
#pod use_ok('JIRA::REST::Class');
#pod
#pod sub get_test_client {
#pod     state $test =
#pod         JIRA::REST::Class->new(TestServer_url(), 'username', 'password');
#pod     $test->REST_CLIENT->setTimeout(5);
#pod     return $test;
#pod };
#pod
#pod =end test
#pod
#pod =cut

#---------------------------------------------------------------------------

#pod =begin testing new 5
#pod
#pod my $jira;
#pod try {
#pod     $jira = JIRA::REST::Class->new({
#pod         url       => TestServer_url(),
#pod         username  => 'user',
#pod         password  => 'pass',
#pod         proxy     => '',
#pod         anonymous => 0,
#pod         ssl_verify_none => 1,
#pod         rest_client_config => {},
#pod     });
#pod }
#pod catch {
#pod     $jira = $_; # as good a place as any to stash the error, because
#pod                 # isa_ok() will complain that it's not an object.
#pod };
#pod
#pod isa_ok($jira, 'JIRA::REST::Class', 'JIRA::REST::Class->new');
#pod
#pod my $needs_url_regexp = qr/'?url'? argument must be defined/i;
#pod
#pod throws_ok(
#pod     sub {
#pod         JIRA::REST::Class->new();
#pod     },
#pod     $needs_url_regexp,
#pod     'JIRA::REST::Class->new with no parameters throws an exception',
#pod );
#pod
#pod throws_ok(
#pod     sub {
#pod         JIRA::REST::Class->new({
#pod             username  => 'user',
#pod             password  => 'pass',
#pod         });
#pod     },
#pod     $needs_url_regexp,
#pod     'JIRA::REST::Class->new with no url throws an exception',
#pod );
#pod
#pod throws_ok(
#pod     sub {
#pod         JIRA::REST::Class->new('http://not.a.good.server.com');
#pod     },
#pod     qr/No credentials found/,
#pod     q{JIRA::REST::Class->new with just url tries to find credentials},
#pod );
#pod
#pod lives_ok(
#pod     sub {
#pod         JIRA::REST::Class->new(TestServer_url(), 'user', 'pass');
#pod     },
#pod     q{JIRA::REST::Class->new with url, username, and password does't croak!},
#pod );
#pod
#pod =end testing
#pod
#pod =cut

#---------------------------------------------------------------------------

#pod =method B<issues> QUERY
#pod
#pod =method B<issues> KEY [, KEY...]
#pod
#pod The C<issues> method can be called two ways: either by providing a list of
#pod issue keys, or by proving a single hash reference which describes a JIRA
#pod query in the same format used by L<JIRA::REST|JIRA::REST> (essentially,
#pod C<< jql => "JQL query string" >>).
#pod
#pod The return value is an array of L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> objects.
#pod
#pod =cut

sub issues {
    my ( $self, @args ) = @_;
    if ( @args == 1 && ref $args[0] eq 'HASH' ) {
        return $self->query( shift )->issues;
    }
    else {
        my $jql = sprintf 'key in (%s)', join q{,} => @args;
        return $self->query( { jql => $jql } )->issues;
    }
}

#---------------------------------------------------------------------------
#
# =begin testing issues
# =end testing
#
#---------------------------------------------------------------------------

#pod =method B<query> QUERY
#pod
#pod The C<query> method takes a single parameter: a hash reference which
#pod describes a JIRA query in the same format used by L<JIRA::REST|JIRA::REST>
#pod (essentially, C<< jql => "JQL query string" >>).
#pod
#pod The return value is a single L<JIRA::REST::Class::Query|JIRA::REST::Class::Query> object.
#pod
#pod =cut

sub query {
    my $self = shift;
    my $args = shift;

    my $query = $self->post( '/search', $args );
    return $self->make_object( 'query', { data => $query } );
}

#---------------------------------------------------------------------------
#
# =begin testing query
# =end testing
#
#---------------------------------------------------------------------------

#pod =method B<iterator> QUERY
#pod
#pod The C<query> method takes a single parameter: a hash reference which
#pod describes a JIRA query in the same format used by L<JIRA::REST|JIRA::REST>
#pod (essentially, C<< jql => "JQL query string" >>).  It accepts an additional
#pod field, however: C<restart_if_lt_total>.  If this field is set to a true value,
#pod the iterator will keep track of the number of results fetched and, if when
#pod the results run out this number doesn't match the number of results
#pod predicted by the query, it will restart the query.  This is particularly
#pod useful if you are transforming a number of issues through an iterator, and
#pod the transformation causes the issues to no longer match the query.
#pod
#pod The return value is a single
#pod L<JIRA::REST::Class::Iterator|JIRA::REST::Class::Iterator> object.  The
#pod issues returned by the query can be obtained in serial by repeatedly calling
#pod L<next|JIRA::REST::Class::Iterator/next> on this object, which returns a
#pod series of L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> objects.
#pod
#pod =cut

sub iterator {
    my $self = shift;
    my $args = shift;
    return $self->make_object( 'iterator', { iterator_args => $args } );
}

#---------------------------------------------------------------------------
#
# =begin testing iterator
# =end testing
#
#---------------------------------------------------------------------------

#pod =internal_method B<get>
#pod
#pod A wrapper for C<JIRA::REST>'s L<GET|JIRA::REST/"GET RESOURCE [, QUERY]"> method.
#pod
#pod =cut

sub get {
    my ( $self, $url, @args ) = @_;
    return $self->JIRA_REST->GET( $url, undef, @args );
}

#---------------------------------------------------------------------------

#pod =begin testing get
#pod
#pod validate_wrapper_method( sub { get_test_client()->get('/test'); },
#pod                          { GET => 'SUCCESS' }, 'get() method works' );
#pod
#pod =end testing
#pod
#pod =cut

#---------------------------------------------------------------------------

#pod =internal_method B<post>
#pod
#pod Wrapper around C<JIRA::REST>'s L<POST|JIRA::REST/"POST RESOURCE, QUERY, VALUE [, HEADERS]"> method.
#pod
#pod =cut

sub post {
    my ( $self, $url, @args ) = @_;
    return $self->JIRA_REST->POST( $url, undef, @args );
}

#---------------------------------------------------------------------------

#pod =begin testing post
#pod
#pod validate_wrapper_method( sub { get_test_client()->post('/test', "key=value"); },
#pod                          { POST => 'SUCCESS' }, 'post() method works' );
#pod
#pod =end testing
#pod
#pod =cut

#---------------------------------------------------------------------------

#pod =internal_method B<put>
#pod
#pod Wrapper around C<JIRA::REST>'s L<PUT|JIRA::REST/"PUT RESOURCE, QUERY, VALUE [, HEADERS]"> method.
#pod
#pod =cut

sub put {
    my ( $self, $url, @args ) = @_;
    return $self->JIRA_REST->PUT( $url, undef, @args );
}

#---------------------------------------------------------------------------

#pod =begin testing put
#pod
#pod validate_wrapper_method( sub { get_test_client()->put('/test', "key=value"); },
#pod                          { PUT => 'SUCCESS' }, 'put() method works' );
#pod
#pod =end testing
#pod
#pod =cut

#---------------------------------------------------------------------------

#pod =internal_method B<delete>
#pod
#pod Wrapper around C<JIRA::REST>'s L<DELETE|JIRA::REST/"DELETE RESOURCE [, QUERY]"> method.
#pod
#pod =cut

sub delete { ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, $url, @args ) = @_;
    return $self->JIRA_REST->DELETE( $url, @args );
}

#---------------------------------------------------------------------------

#pod =begin testing delete
#pod
#pod validate_wrapper_method( sub { get_test_client()->delete('/test'); },
#pod                          { DELETE => 'SUCCESS' }, 'delete() method works' );
#pod
#pod =end testing
#pod
#pod =cut

#---------------------------------------------------------------------------

#pod =internal_method B<data_upload>
#pod
#pod Similar to
#pod L<< JIRA::REST->attach_files|JIRA::REST/"attach_files ISSUE FILE..." >>,
#pod but entirely from memory and only attaches one file at a time. Returns the
#pod L<HTTP::Response|HTTP::Response> object from the post request.  Takes the
#pod following named parameters:
#pod
#pod =over 4
#pod
#pod =item + B<url>
#pod
#pod The relative URL to POST to.  This will have the hostname and REST version
#pod information prepended to it, so all you need to provide is something like
#pod C</issue/>I<issueIdOrKey>C</attachments>.  I'm allowing the URL to be
#pod specified in case I later discover something this can be used for besides
#pod attaching files to issues.
#pod
#pod =item + B<name>
#pod
#pod The name that is specified for this file attachment.
#pod
#pod =item + B<data>
#pod
#pod The actual data to be uploaded.  If a reference is provided, it will be
#pod dereferenced before posting the data.
#pod
#pod =back
#pod
#pod I guess that makes it only a I<little> like
#pod C<< JIRA::REST->attach_files >>...
#pod
#pod =cut

sub data_upload {
    my ( $self, @args ) = @_;
    my $args = $self->_get_known_args( \@args, qw/ url name data / );
    $self->_check_required_args(
        $args,
        url  => 'you must specify a URL to upload to',
        name => 'you must specify a name for the file data',
        data => 'you must specify the file data',
    );

    my $name = $args->{name};
    my $data = ref $args->{data} ? ${ $args->{data} } : $args->{data};

    # code cribbed from JIRA::REST
    #
    my $url      = $self->rest_api_url_base . $args->{url};
    my $rest     = $self->REST_CLIENT;
    my $response = $rest->getUseragent()->post(
        $url,
        %{ $rest->{_headers} },
        'X-Atlassian-Token' => 'nocheck',
        'Content-Type'      => 'form-data',
        'Content'           => [
            file => [ undef, $name, Content => $data ],
        ],
    );

    #<<< perltidy should ignore these lines
    $response->is_success
        or croak $self->JIRA_REST->_error( ## no critic (ProtectPrivateSubs)
            $self->_croakmsg( $response->status_line, $name )
        );
    #>>>

    return $response;
}

#---------------------------------------------------------------------------

#pod =begin testing data_upload
#pod
#pod my $expected = {
#pod   "Content-Disposition" => "form-data; name=\"file\"; filename=\"file.txt\"",
#pod   POST => "SUCCESS",
#pod   data => "An OO Class module built atop L<JIRA::REST|JIRA::REST> for dealing with "
#pod        .  "JIRA issues and their data as objects.",
#pod   name => "file.txt"
#pod };
#pod
#pod my $test1_name = 'return value from data_upload()';
#pod my $test2_name = 'data_upload() method succeeded';
#pod my $test3_name = 'data_upload() method returned expected data';
#pod
#pod my $test = get_test_client();
#pod my $results;
#pod my $got;
#pod
#pod try {
#pod     $results = $test->data_upload({
#pod         url  => "/data_upload",
#pod         name => $expected->{name},
#pod         data => $expected->{data},
#pod     });
#pod     $got = $test->JSON->decode($results->decoded_content);
#pod }
#pod catch {
#pod     $results = $_;
#pod     diag($test->REST_CLIENT->getHost);
#pod };
#pod
#pod my $test1_ok = isa_ok( $results, 'HTTP::Response', $test1_name );
#pod my $test2_ok = ok($test1_ok && $results->is_success, $test2_name );
#pod $test2_ok ? is_deeply( $got, $expected, $test3_name ) : fail( $test3_name );
#pod
#pod =end testing
#pod
#pod =cut

#---------------------------------------------------------------------------

#pod =method B<maxResults>
#pod
#pod A getter/setter method that allows setting a global default for the L<maxResults pagination parameter for JIRA's REST API |https://docs.atlassian.com/jira/REST/latest/#pagination>.  This determines the I<maximum> number of results returned by the L<issues|/"issues QUERY"> and L<query|/"query QUERY"> methods; and the initial number of results fetched by the L<iterator|/"iterator QUERY"> (when L<next|JIRA::REST::Class::Iterator/next> exhausts that initial cache of results it will automatically make subsequent calls to the REST API to fetch more results).
#pod
#pod Defaults to 50.
#pod
#pod   say $jira->maxResults; # returns 50
#pod
#pod   $jira->maxResults(10); # only return 10 results at a time
#pod
#pod =cut

sub maxResults {
    my $self = shift;
    if ( @_ ) {
        $self->{maxResults} = shift;
    }
    unless ( exists $self->{maxResults} && defined $self->{maxResults} ) {
        $self->{maxResults} = $DEFAULT_MAXRESULTS;
    }
    return $self->{maxResults};
}

#pod =method B<issue_types>
#pod
#pod Returns a list of defined issue types (as
#pod L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type> objects)
#pod for this server.
#pod
#pod =cut

sub issue_types {
    my $self = shift;

    unless ( $self->{issue_types} ) {
        my $types = $self->get( '/issuetype' );
        $self->{issue_types} = [  # stop perltidy from pulling
            map {                 # these lines together
                $self->make_object( 'issuetype', { data => $_ } );
            } @$types
        ];
    }

    return @{ $self->{issue_types} } if wantarray;
    return $self->{issue_types};
}

#---------------------------------------------------------------------------

#pod =begin testing issue_types 16
#pod
#pod try {
#pod     my $test = get_test_client();
#pod
#pod     validate_contextual_accessor($test, {
#pod         method => 'issue_types',
#pod         class  => 'issuetype',
#pod         data   => [ sort qw/ Bug Epic Improvement Sub-task Story Task /,
#pod                     'New Feature' ],
#pod     });
#pod
#pod     print "#\n# Checking the 'Bug' issue type\n#\n";
#pod
#pod     my ($bug) = sort $test->issue_types;
#pod
#pod     can_ok_abstract( $bug, qw/ description iconUrl id name self subtask / );
#pod
#pod     my $host = TestServer_url();
#pod
#pod     validate_expected_fields( $bug, {
#pod         description => "jira.translation.issuetype.bug.name.desc",
#pod         iconUrl => "$host/secure/viewavatar?size=xsmall&avatarId=10303"
#pod                 .  "&avatarType=issuetype",
#pod         id => 10004,
#pod         name => "Bug",
#pod         self => "$host/rest/api/latest/issuetype/10004",
#pod         subtask => JSON::PP::false,
#pod     });
#pod };
#pod
#pod =end testing
#pod
#pod =cut

#---------------------------------------------------------------------------

#pod =method B<projects>
#pod
#pod Returns a list of projects (as
#pod L<JIRA::REST::Class::Project|JIRA::REST::Class::Project> objects) for this
#pod server.
#pod
#pod =cut

sub projects {
    my $self = shift;

    unless ( $self->{project_list} ) {

        # get the project list from JIRA
        my $projects = $self->get( '/project' );

        # build a list, and make a hash so we can
        # grab projects later by id, key, or name.

        my $list = $self->{project_list} = [];

        my $make_project_hash_entry = sub {
            my $prj = shift;
            my $obj = $self->make_object( 'project', { data => $prj } );

            push @$list, $obj;

            return $obj->id => $obj, $obj->key => $obj, $obj->name => $obj;
        };

        $self->{project_hash} = { ##
            map { $make_project_hash_entry->( $_ ) } @$projects
        };
    }

    return @{ $self->{project_list} } if wantarray;
    return $self->{project_list};
}

#---------------------------------------------------------------------------

#pod =begin testing projects 5
#pod
#pod my $test = get_test_client();
#pod
#pod try {
#pod     validate_contextual_accessor($test, {
#pod         method => 'projects',
#pod         class  => 'project',
#pod         data   => [ qw/ JRC KANBAN PACKAY PM SCRUM / ],
#pod     });
#pod };
#pod
#pod =end testing
#pod
#pod =cut

#---------------------------------------------------------------------------

#pod =method B<project> PROJECT_ID || PROJECT_KEY || PROJECT_NAME
#pod
#pod Returns a L<JIRA::REST::Class::Project|JIRA::REST::Class::Project> object
#pod for the project specified. Returns undef if the project doesn't exist.
#pod
#pod =cut

sub project {
    my $self = shift;
    my $proj = shift || return;  # if nothing was passed, we return nothing

    # if we were passed a project object, just return it
    return $proj if $self->obj_isa( $proj, 'project' );

    $self->projects;  # load the project hash if it hasn't been loaded

    return unless exists $self->{project_hash}->{$proj};
    return $self->{project_hash}->{$proj};
}

#---------------------------------------------------------------------------

#pod =begin testing project 17
#pod
#pod try {
#pod     print "#\n# Checking the SCRUM project\n#\n";
#pod
#pod     my $test = get_test_client();
#pod
#pod     my $proj = $test->project('SCRUM');
#pod
#pod     can_ok_abstract( $proj, qw/ avatarUrls expand id key name self
#pod                                 category assigneeType components
#pod                                 description issueTypes lead roles versions
#pod                                 allowed_components allowed_versions
#pod                                 allowed_fix_versions allowed_issue_types
#pod                                 allowed_priorities allowed_field_values
#pod                                 field_metadata_exists field_metadata
#pod                                 field_name
#pod                               / );
#pod
#pod     validate_expected_fields( $proj, {
#pod         expand => "description,lead,url,projectKeys",
#pod         id => 10002,
#pod         key => 'SCRUM',
#pod         name => "Scrum Software Development Sample Project",
#pod         projectTypeKey => "software",
#pod         lead => {
#pod             class => 'user',
#pod             expected => {
#pod                 key => 'packy'
#pod             },
#pod         },
#pod     });
#pod
#pod     validate_contextual_accessor($proj, {
#pod         method => 'versions',
#pod         class  => 'projectvers',
#pod         name   => "SCRUM project's",
#pod         data   => [ "Version 1.0", "Version 2.0", "Version 3.0" ],
#pod     });
#pod };
#pod
#pod =end testing
#pod
#pod =cut

#---------------------------------------------------------------------------

#pod =method B<SSL_verify_none>
#pod
#pod Sets to false the SSL options C<SSL_verify_mode> and C<verify_hostname> on
#pod the L<LWP::UserAgent|LWP::UserAgent> object that is used by
#pod L<REST::Client|REST::Client> (which, in turn, is used by
#pod L<JIRA::REST|JIRA::REST>, which is used by this module).
#pod
#pod =cut

sub SSL_verify_none { ## no critic (NamingConventions::Capitalization)
    my $self = shift;
    return $self->REST_CLIENT->getUseragent()->ssl_opts(
        SSL_verify_mode => 0,
        verify_hostname => 0
    );
}

#pod =internal_method B<rest_api_url_base>
#pod
#pod Returns the base URL for this JIRA server's REST API.  For example, if your JIRA server is at C<http://jira.example.com>, this would return C<http://jira.example.com/rest/api/latest>.
#pod
#pod =cut

sub rest_api_url_base {
    my $self = shift;
    if ( $self->_JIRA_REST_version_has_separate_path ) {
        ( my $host = $self->REST_CLIENT->getHost ) =~ s{/$}{}xms;
        my $path = $self->JIRA_REST->{path} // q{/rest/api/latest};
        return $host . $path;
    }
    else {
        my ( $base )
            = $self->REST_CLIENT->getHost =~ m{^(.+?rest/api/[^/]+)/?}xms;
        return $base // $self->REST_CLIENT->getHost . '/rest/api/latest';
    }
}

#pod =internal_method B<strip_protocol_and_host>
#pod
#pod A method to take the provided URL and strip the protocol and host from it.  For example, if the URL C<http://jira.example.com/rest/api/latest> was passed to this method, C</rest/api/latest> would be returned.
#pod
#pod =cut

sub strip_protocol_and_host {
    my $self = shift;
    my $host = $self->REST_CLIENT->getHost;
    ( my $url = shift ) =~ s{^$host}{}xms;
    return $url;
}

#pod =accessor B<args>
#pod
#pod An accessor that returns a copy of the arguments passed to the
#pod constructor. Useful for passing around to utility objects.
#pod
#pod =cut

sub args { return shift->{args} }

#pod =accessor B<url>
#pod
#pod An accessor that returns the C<url> parameter passed to this object's
#pod constructor.
#pod
#pod =cut

sub url { return shift->args->{url} }

#pod =accessor B<username>
#pod
#pod An accessor that returns the username used to connect to the JIRA server,
#pod even if the username was read from a C<.netrc> or
#pod L<Config::Identity|Config::Identity> file.
#pod
#pod =cut

sub username { return shift->args->{username} }

#pod =accessor B<password>
#pod
#pod An accessor that returns the password used to connect to the JIRA server,
#pod even if the password was read from a C<.netrc> or
#pod L<Config::Identity|Config::Identity> file.
#pod
#pod =cut

sub password { return shift->args->{password} }

#pod =accessor B<rest_client_config>
#pod
#pod An accessor that returns the C<rest_client_config> parameter passed to this
#pod object's constructor.
#pod
#pod =cut

sub rest_client_config { return shift->args->{rest_client_config} }

#pod =accessor B<anonymous>
#pod
#pod An accessor that returns the C<anonymous> parameter passed to this object's constructor.
#pod
#pod =cut

sub anonymous { return shift->args->{anonymous} }

#pod =accessor B<proxy>
#pod
#pod An accessor that returns the C<proxy> parameter passed to this object's constructor.
#pod
#pod =cut

sub proxy { return shift->args->{proxy} }

#---------------------------------------------------------------------------

#pod =begin testing parameter_accessors 7
#pod
#pod try{
#pod     my $test = get_test_client();
#pod     my $url  = TestServer_url();
#pod
#pod     my $args = {
#pod         url       => $url,
#pod         username  => 'username',
#pod         password  => 'password',
#pod         proxy     => undef,
#pod         anonymous => undef,
#pod         rest_client_config => undef,
#pod         ssl_verify_none => undef,
#pod     };
#pod
#pod     # the args accessor will have keys for ALL the possible arguments,
#pod     # whether they were passed in or not.
#pod
#pod     cmp_deeply( $test,
#pod                 methods( args      => { %$args, },
#pod                          url       => $args->{url},
#pod                          username  => $args->{username},
#pod                          password  => $args->{password},
#pod                          proxy     => $args->{proxy},
#pod                          anonymous => $args->{anonymous},
#pod                          rest_client_config => $args->{rest_client_config} ),
#pod                 q{All accessors for parameters passed }.
#pod                 q{into the constructor okay});
#pod
#pod     my $ua = $test->REST_CLIENT->getUseragent();
#pod     $test->SSL_verify_none;
#pod     cmp_deeply($ua->{ssl_opts}, { SSL_verify_mode => 0, verify_hostname => 0 },
#pod                q{SSL_verify_none() does disable SSL verification});
#pod
#pod     is($test->rest_api_url_base($url . "/rest/api/latest/foo"),
#pod        $url . "/rest/api/latest", q{rest_api_url_base() works as expected});
#pod
#pod     is($test->strip_protocol_and_host($test->REST_CLIENT->getHost . "/foo"),
#pod        "/foo", q{strip_protocol_and_host() works as expected});
#pod
#pod     is($test->maxResults, 50, q{maxResults() default is correct});
#pod
#pod     is($test->maxResults(10), 10, q{maxResults(N) returns N});
#pod
#pod     is($test->maxResults, 10,
#pod        q{maxResults() was successfully set by previous call});
#pod };
#pod
#pod =end testing
#pod
#pod =cut

#---------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik gnustavo jira JRC Gustavo Leite de Mendonça
Chaves Atlassian GreenHopper ScriptRunner TODO aggregateprogress
aggregatetimeestimate aggregatetimeoriginalestimate assigneeType avatar
avatarUrls completeDate displayName duedate emailAddress endDate fieldtype
fixVersions fromString genericized iconUrl isAssigneeTypeValid issueTypes
issuekeys issuelinks issuetype jql lastViewed maxResults originalEstimate
originalEstimateSeconds parentkey projectId rapidViewId remainingEstimate
remainingEstimateSeconds resolutiondate sprintlist startDate
subtaskIssueTypes timeSpent timeSpentSeconds timeestimate
timeoriginalestimate timespent timetracking toString updateAuthor worklog
workratio

=head1 NAME

JIRA::REST::Class - An OO Class module built atop L<JIRA::REST|JIRA::REST> for dealing with JIRA issues and their data as objects.

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use JIRA::REST::Class;

  my $jira = JIRA::REST::Class->new({
      url             => 'https://jira.example.net',
      username        => 'myuser',
      password        => 'mypass',
      SSL_verify_none => 1, # if your server uses self-signed SSL certs
  });

  # get issue by key
  my ($issue) = $jira->issues( 'MYPROJ-101' );

  # get multiple issues by key
  my @issues = $jira->issues( 'MYPROJ-101', 'MYPROJ-102', 'MYPROJ-103' );

  # get multiple issues through search
  my @issues =
      $jira->issues({ jql => q/project = "MYPROJ" and status = "open" / });

  # get an iterator for a search
  my $search =
      $jira->iterator({ jql => q/project = "MYPROJ" and status = "open" / });

  if ( $search->issue_count ) {
      printf "Found %d open issues in MYPROJ:\n", $search->issue_count;
      while ( my $issue = $search->next ) {
          printf "  Issue %s is open\n", $issue->key;
      }
  }
  else {
      print "No open issues in MYPROJ.\n";
  }

=head1 DESCRIPTION

An OO Class module built atop L<JIRA::REST|JIRA::REST> for dealing with JIRA
issues and their data as objects.

This code is a work in progress, so it's bound to be incomplete.  I add methods
to it as I discover I need them.  I have also coded for fields that might exist
in my JIRA server's configuration but not in yours.  It is my I<intent>,
however, to make things more generic as I go on so they will "just work" no
matter how your server is configured.

I'm actively working with the author of L<JIRA::REST|JIRA::REST> (thanks
gnustavo!) to keep the arguments for C<< JIRA::REST::Class->new >> exactly
the same as C<< JIRA::REST->new >>, so I'm just duplicating the
documentation for L<< JIRA::REST->new|JIRA::REST/CONSTRUCTOR >>:

=head1 CONSTRUCTOR

=head2 B<new> I<HASHREF>

=head2 B<new> I<URL>, I<USERNAME>, I<PASSWORD>, I<REST_CLIENT_CONFIG>, I<ANONYMOUS>, I<PROXY>, I<SSL_VERIFY_NONE>

The constructor can take its arguments from a single hash reference or from
a list of positional parameters. The first form is preferred because it lets
you specify only the arguments you need. The second form forces you to pass
undefined values if you need to pass a specific value to an argument further
to the right.

The arguments are described below with the names which must be used as the
hash keys:

=over 4

=item * B<url>

A string or a URI object denoting the base URL of the JIRA server. This is a
required argument.

The REST methods described below all accept as a first argument the
endpoint's path of the specific API method to call. In general you can pass
the complete path, beginning with the prefix denoting the particular API to
use (C</rest/api/VERSION>, C</rest/servicedeskapi>, or
C</rest/agile/VERSION>). However, to make it easier to invoke JIRA's Core
API if you pass a path not starting with C</rest/> it will be prefixed with
C</rest/api/latest> or with this URL's path if it has one. This way you can
choose a specific version of the JIRA Core API to use instead of the latest
one. For example:

    my $jira = JIRA::REST::Class->new({
        url => 'https://jira.example.net/rest/api/1',
    });

=item * B<username>

=item * B<password>

The username and password of a JIRA user to use for authentication.

If B<anonymous> is false then, if either B<username> or B<password> isn't
defined the module looks them up in either the C<.netrc> file or via
L<Config::Identity|Config::Identity> (which allows C<gpg> encrypted credentials).

L<Config::Identity|Config::Identity> will look for F<~/.jira-identity> or
F<~/.jira>.  You can change the filename stub from C<jira> to a custom stub
with the C<JIRA_REST_IDENTITY> environment variable.

=item * B<rest_client_config>

A JIRA::REST object uses a L<REST::Client|REST::Client> object to make the REST
invocations. This optional argument must be a hash reference that can be fed
to the REST::Client constructor. Note that the C<url> argument
overwrites any value associated with the C<host> key in this hash.

As an extension, the hash reference also accepts one additional argument
called B<proxy> that is an extension to the REST::Client configuration and
will be removed from the hash before passing it on to the REST::Client
constructor. However, this argument is deprecated since v0.017 and you
should avoid it. Instead, use the following argument instead.

=item * B<proxy>

To use a network proxy set this argument to the string or URI object
describing the fully qualified URL (including port) to your network proxy.

=item * B<ssl_verify_none>

Sets the C<SSL_verify_mode> and C<verify_hostname ssl> options on the
underlying L<REST::Client|REST::Client>'s user agent to 0, thus disabling
them. This allows access to JIRA servers that have self-signed certificates
that don't pass L<LWP::UserAgent|LWP::UserAgent>'s verification methods.

=item * B<anonymous>

Tells the module that you want to connect to the specified JIRA server with
no username or password.  This way you can access public JIRA servers
without needing to authenticate.

=back

=head1 METHODS

=head2 B<issues> QUERY

=head2 B<issues> KEY [, KEY...]

The C<issues> method can be called two ways: either by providing a list of
issue keys, or by proving a single hash reference which describes a JIRA
query in the same format used by L<JIRA::REST|JIRA::REST> (essentially,
C<< jql => "JQL query string" >>).

The return value is an array of L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> objects.

=head2 B<query> QUERY

The C<query> method takes a single parameter: a hash reference which
describes a JIRA query in the same format used by L<JIRA::REST|JIRA::REST>
(essentially, C<< jql => "JQL query string" >>).

The return value is a single L<JIRA::REST::Class::Query|JIRA::REST::Class::Query> object.

=head2 B<iterator> QUERY

The C<query> method takes a single parameter: a hash reference which
describes a JIRA query in the same format used by L<JIRA::REST|JIRA::REST>
(essentially, C<< jql => "JQL query string" >>).  It accepts an additional
field, however: C<restart_if_lt_total>.  If this field is set to a true value,
the iterator will keep track of the number of results fetched and, if when
the results run out this number doesn't match the number of results
predicted by the query, it will restart the query.  This is particularly
useful if you are transforming a number of issues through an iterator, and
the transformation causes the issues to no longer match the query.

The return value is a single
L<JIRA::REST::Class::Iterator|JIRA::REST::Class::Iterator> object.  The
issues returned by the query can be obtained in serial by repeatedly calling
L<next|JIRA::REST::Class::Iterator/next> on this object, which returns a
series of L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> objects.

=head2 B<maxResults>

A getter/setter method that allows setting a global default for the L<maxResults pagination parameter for JIRA's REST API |https://docs.atlassian.com/jira/REST/latest/#pagination>.  This determines the I<maximum> number of results returned by the L<issues|/"issues QUERY"> and L<query|/"query QUERY"> methods; and the initial number of results fetched by the L<iterator|/"iterator QUERY"> (when L<next|JIRA::REST::Class::Iterator/next> exhausts that initial cache of results it will automatically make subsequent calls to the REST API to fetch more results).

Defaults to 50.

  say $jira->maxResults; # returns 50

  $jira->maxResults(10); # only return 10 results at a time

=head2 B<issue_types>

Returns a list of defined issue types (as
L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type> objects)
for this server.

=head2 B<projects>

Returns a list of projects (as
L<JIRA::REST::Class::Project|JIRA::REST::Class::Project> objects) for this
server.

=head2 B<project> PROJECT_ID || PROJECT_KEY || PROJECT_NAME

Returns a L<JIRA::REST::Class::Project|JIRA::REST::Class::Project> object
for the project specified. Returns undef if the project doesn't exist.

=head2 B<SSL_verify_none>

Sets to false the SSL options C<SSL_verify_mode> and C<verify_hostname> on
the L<LWP::UserAgent|LWP::UserAgent> object that is used by
L<REST::Client|REST::Client> (which, in turn, is used by
L<JIRA::REST|JIRA::REST>, which is used by this module).

=head2 B<name_for_user>

When passed a scalar that could be a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object, returns the name
of the user if it is a C<JIRA::REST::Class::User>
object, or the unmodified scalar if it is not.

=head2 B<key_for_issue>

When passed a scalar that could be a
L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object, returns the key
of the issue if it is a C<JIRA::REST::Class::Issue>
object, or the unmodified scalar if it is not.

=head2 B<find_link_name_and_direction>

When passed two scalars, one that could be a
L<JIRA::REST::Class::Issue::LinkType|JIRA::REST::Class::Issue::LinkType>
object and another that is a direction (inward/outward), returns the name of
the link type and direction if it is a C<JIRA::REST::Class::Issue::LinkType>
object, or attempts to determine the link type and direction from the
provided scalars.

=head2 B<dump>

Returns a stringified representation of the object's data generated somewhat
by L<Data::Dumper::Concise|Data::Dumper::Concise>, but not descending into
any objects that might be part of that data.  If it finds objects in the
data, it will attempt to represent them in some abbreviated fashion which
may not display all the data in the object.  For instance, if the object has
a C<JIRA::REST::Class::Issue> object in it for an issue with the key
C<'JRC-1'>, the object would be represented as the string C<<
'JIRA::REST::Class::Issue->key(JRC-1)' >>.  The goal is to provide a gist of
what the contents of the object are without exhaustively dumping EVERYTHING.
I use it a lot for figuring out what's in the results I'm getting back from
the JIRA API.

=head1 READ-ONLY ACCESSORS

=head2 B<args>

An accessor that returns a copy of the arguments passed to the
constructor. Useful for passing around to utility objects.

=head2 B<url>

An accessor that returns the C<url> parameter passed to this object's
constructor.

=head2 B<username>

An accessor that returns the username used to connect to the JIRA server,
even if the username was read from a C<.netrc> or
L<Config::Identity|Config::Identity> file.

=head2 B<password>

An accessor that returns the password used to connect to the JIRA server,
even if the password was read from a C<.netrc> or
L<Config::Identity|Config::Identity> file.

=head2 B<rest_client_config>

An accessor that returns the C<rest_client_config> parameter passed to this
object's constructor.

=head2 B<anonymous>

An accessor that returns the C<anonymous> parameter passed to this object's constructor.

=head2 B<proxy>

An accessor that returns the C<proxy> parameter passed to this object's constructor.

=head1 INTERNAL METHODS

=head2 B<get>

A wrapper for C<JIRA::REST>'s L<GET|JIRA::REST/"GET RESOURCE [, QUERY]"> method.

=head2 B<post>

Wrapper around C<JIRA::REST>'s L<POST|JIRA::REST/"POST RESOURCE, QUERY, VALUE [, HEADERS]"> method.

=head2 B<put>

Wrapper around C<JIRA::REST>'s L<PUT|JIRA::REST/"PUT RESOURCE, QUERY, VALUE [, HEADERS]"> method.

=head2 B<delete>

Wrapper around C<JIRA::REST>'s L<DELETE|JIRA::REST/"DELETE RESOURCE [, QUERY]"> method.

=head2 B<data_upload>

Similar to
L<< JIRA::REST->attach_files|JIRA::REST/"attach_files ISSUE FILE..." >>,
but entirely from memory and only attaches one file at a time. Returns the
L<HTTP::Response|HTTP::Response> object from the post request.  Takes the
following named parameters:

=over 4

=item + B<url>

The relative URL to POST to.  This will have the hostname and REST version
information prepended to it, so all you need to provide is something like
C</issue/>I<issueIdOrKey>C</attachments>.  I'm allowing the URL to be
specified in case I later discover something this can be used for besides
attaching files to issues.

=item + B<name>

The name that is specified for this file attachment.

=item + B<data>

The actual data to be uploaded.  If a reference is provided, it will be
dereferenced before posting the data.

=back

I guess that makes it only a I<little> like
C<< JIRA::REST->attach_files >>...

=head2 B<rest_api_url_base>

Returns the base URL for this JIRA server's REST API.  For example, if your JIRA server is at C<http://jira.example.com>, this would return C<http://jira.example.com/rest/api/latest>.

=head2 B<strip_protocol_and_host>

A method to take the provided URL and strip the protocol and host from it.  For example, if the URL C<http://jira.example.com/rest/api/latest> was passed to this method, C</rest/api/latest> would be returned.

=head2 B<jira>

Returns a L<JIRA::REST::Class|JIRA::REST::Class> object with credentials for the last JIRA user.

=head2 B<factory>

An accessor for the L<JIRA::REST::Class::Factory|JIRA::REST::Class::Factory>.

=head2 B<JIRA_REST>

An accessor that returns the L<JIRA::REST|JIRA::REST> object being used.

=head2 B<REST_CLIENT>

An accessor that returns the L<REST::Client|REST::Client> object inside the L<JIRA::REST|JIRA::REST> object being used.

=head2 B<JSON>

An accessor that returns the L<JSON|JSON> object inside the L<JIRA::REST|JIRA::REST> object being used.

=head2 B<make_object>

A pass-through method that calls L<JIRA::REST::Class::Factory::make_object()|JIRA::REST::Class::Factory/make_object>.

=head2 B<make_date>

A pass-through method that calls L<JIRA::REST::Class::Factory::make_date()|JIRA::REST::Class::Factory/make_date>.

=head2 B<class_for>

A pass-through method that calls L<JIRA::REST::Class::Factory::get_factory_class()|JIRA::REST::Class::Factory/get_factory_class>.

=head2 B<obj_isa>

When passed a scalar that I<could> be an object and a class string,
returns whether the scalar is, in fact, an object of that class.
Looks up the actual class using C<class_for()>, which calls
L<JIRA::REST::Class::Factory::get_factory_class()|JIRA::REST::Class::Factory/get_factory_class>.

=head2 B<cosmetic_copy> I<THING>

A utility function to produce a "cosmetic" copy of a thing: it clones
the data structure, but if anything in the structure (other than the
structure itself) is a blessed object, it replaces it with a
stringification of that object that probably doesn't contain all the
data in the object.  For instance, if the object has a
C<JIRA::REST::Class::Issue> object in it for an issue with the key
C<'JRC-1'>, the object would be represented as the string
C<< 'JIRA::REST::Class::Issue->key(JRC-1)' >>.  The goal is to provide a
gist of what the contents of the object are without exhaustively dumping
EVERYTHING.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class::Factory|JIRA::REST::Class::Factory>

=item * L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue>

=item * L<JIRA::REST::Class::Issue::Type|JIRA::REST::Class::Issue::Type>

=item * L<JIRA::REST::Class::Iterator|JIRA::REST::Class::Iterator>

=item * L<JIRA::REST::Class::Mixins|JIRA::REST::Class::Mixins>

=item * L<JIRA::REST::Class::Project|JIRA::REST::Class::Project>

=item * L<JIRA::REST::Class::Query|JIRA::REST::Class::Query>

=back

=begin test setup 1

use File::Basename;
use lib dirname($0).'/..';
use MyTest;
use 5.010;

TestServer_setup();

END {
    TestServer_stop();
}

use_ok('JIRA::REST::Class');

sub get_test_client {
    state $test =
        JIRA::REST::Class->new(TestServer_url(), 'username', 'password');
    $test->REST_CLIENT->setTimeout(5);
    return $test;
};

=end test

=begin testing new 5

my $jira;
try {
    $jira = JIRA::REST::Class->new({
        url       => TestServer_url(),
        username  => 'user',
        password  => 'pass',
        proxy     => '',
        anonymous => 0,
        ssl_verify_none => 1,
        rest_client_config => {},
    });
}
catch {
    $jira = $_; # as good a place as any to stash the error, because
                # isa_ok() will complain that it's not an object.
};

isa_ok($jira, 'JIRA::REST::Class', 'JIRA::REST::Class->new');

my $needs_url_regexp = qr/'?url'? argument must be defined/i;

throws_ok(
    sub {
        JIRA::REST::Class->new();
    },
    $needs_url_regexp,
    'JIRA::REST::Class->new with no parameters throws an exception',
);

throws_ok(
    sub {
        JIRA::REST::Class->new({
            username  => 'user',
            password  => 'pass',
        });
    },
    $needs_url_regexp,
    'JIRA::REST::Class->new with no url throws an exception',
);

throws_ok(
    sub {
        JIRA::REST::Class->new('http://not.a.good.server.com');
    },
    qr/No credentials found/,
    q{JIRA::REST::Class->new with just url tries to find credentials},
);

lives_ok(
    sub {
        JIRA::REST::Class->new(TestServer_url(), 'user', 'pass');
    },
    q{JIRA::REST::Class->new with url, username, and password does't croak!},
);

=end testing

=begin testing get

validate_wrapper_method( sub { get_test_client()->get('/test'); },
                         { GET => 'SUCCESS' }, 'get() method works' );


=end testing

=begin testing post

validate_wrapper_method( sub { get_test_client()->post('/test', "key=value"); },
                         { POST => 'SUCCESS' }, 'post() method works' );


=end testing

=begin testing put

validate_wrapper_method( sub { get_test_client()->put('/test', "key=value"); },
                         { PUT => 'SUCCESS' }, 'put() method works' );


=end testing

=begin testing delete

validate_wrapper_method( sub { get_test_client()->delete('/test'); },
                         { DELETE => 'SUCCESS' }, 'delete() method works' );


=end testing

=begin testing data_upload

my $expected = {
  "Content-Disposition" => "form-data; name=\"file\"; filename=\"file.txt\"",
  POST => "SUCCESS",
  data => "An OO Class module built atop L<JIRA::REST|JIRA::REST> for dealing with "
       .  "JIRA issues and their data as objects.",
  name => "file.txt"
};

my $test1_name = 'return value from data_upload()';
my $test2_name = 'data_upload() method succeeded';
my $test3_name = 'data_upload() method returned expected data';

my $test = get_test_client();
my $results;
my $got;

try {
    $results = $test->data_upload({
        url  => "/data_upload",
        name => $expected->{name},
        data => $expected->{data},
    });
    $got = $test->JSON->decode($results->decoded_content);
}
catch {
    $results = $_;
    diag($test->REST_CLIENT->getHost);
};

my $test1_ok = isa_ok( $results, 'HTTP::Response', $test1_name );
my $test2_ok = ok($test1_ok && $results->is_success, $test2_name );
$test2_ok ? is_deeply( $got, $expected, $test3_name ) : fail( $test3_name );

=end testing

=begin testing issue_types 16

try {
    my $test = get_test_client();

    validate_contextual_accessor($test, {
        method => 'issue_types',
        class  => 'issuetype',
        data   => [ sort qw/ Bug Epic Improvement Sub-task Story Task /,
                    'New Feature' ],
    });

    print "#\n# Checking the 'Bug' issue type\n#\n";

    my ($bug) = sort $test->issue_types;

    can_ok_abstract( $bug, qw/ description iconUrl id name self subtask / );

    my $host = TestServer_url();

    validate_expected_fields( $bug, {
        description => "jira.translation.issuetype.bug.name.desc",
        iconUrl => "$host/secure/viewavatar?size=xsmall&avatarId=10303"
                .  "&avatarType=issuetype",
        id => 10004,
        name => "Bug",
        self => "$host/rest/api/latest/issuetype/10004",
        subtask => JSON::PP::false,
    });
};

=end testing

=begin testing projects 5

my $test = get_test_client();

try {
    validate_contextual_accessor($test, {
        method => 'projects',
        class  => 'project',
        data   => [ qw/ JRC KANBAN PACKAY PM SCRUM / ],
    });
};

=end testing

=begin testing project 17

try {
    print "#\n# Checking the SCRUM project\n#\n";

    my $test = get_test_client();

    my $proj = $test->project('SCRUM');

    can_ok_abstract( $proj, qw/ avatarUrls expand id key name self
                                category assigneeType components
                                description issueTypes lead roles versions
                                allowed_components allowed_versions
                                allowed_fix_versions allowed_issue_types
                                allowed_priorities allowed_field_values
                                field_metadata_exists field_metadata
                                field_name
                              / );

    validate_expected_fields( $proj, {
        expand => "description,lead,url,projectKeys",
        id => 10002,
        key => 'SCRUM',
        name => "Scrum Software Development Sample Project",
        projectTypeKey => "software",
        lead => {
            class => 'user',
            expected => {
                key => 'packy'
            },
        },
    });

    validate_contextual_accessor($proj, {
        method => 'versions',
        class  => 'projectvers',
        name   => "SCRUM project's",
        data   => [ "Version 1.0", "Version 2.0", "Version 3.0" ],
    });
};

=end testing

=begin testing parameter_accessors 7

try{
    my $test = get_test_client();
    my $url  = TestServer_url();

    my $args = {
        url       => $url,
        username  => 'username',
        password  => 'password',
        proxy     => undef,
        anonymous => undef,
        rest_client_config => undef,
        ssl_verify_none => undef,
    };

    # the args accessor will have keys for ALL the possible arguments,
    # whether they were passed in or not.

    cmp_deeply( $test,
                methods( args      => { %$args, },
                         url       => $args->{url},
                         username  => $args->{username},
                         password  => $args->{password},
                         proxy     => $args->{proxy},
                         anonymous => $args->{anonymous},
                         rest_client_config => $args->{rest_client_config} ),
                q{All accessors for parameters passed }.
                q{into the constructor okay});

    my $ua = $test->REST_CLIENT->getUseragent();
    $test->SSL_verify_none;
    cmp_deeply($ua->{ssl_opts}, { SSL_verify_mode => 0, verify_hostname => 0 },
               q{SSL_verify_none() does disable SSL verification});

    is($test->rest_api_url_base($url . "/rest/api/latest/foo"),
       $url . "/rest/api/latest", q{rest_api_url_base() works as expected});

    is($test->strip_protocol_and_host($test->REST_CLIENT->getHost . "/foo"),
       "/foo", q{strip_protocol_and_host() works as expected});

    is($test->maxResults, 50, q{maxResults() default is correct});

    is($test->maxResults(10), 10, q{maxResults(N) returns N});

    is($test->maxResults, 10,
       q{maxResults() was successfully set by previous call});
};

=end testing

=head1 SEE ALSO

=over

=item * L<JIRA::REST|JIRA::REST>

C<JIRA::REST::Class> uses C<JIRA::REST> to perform all its interaction with JIRA.

=item * L<REST::Client|REST::Client>

C<JIRA::REST> uses a C<REST::Client> object to perform its low-level interactions.

=item * L<JIRA REST API Reference|https://docs.atlassian.com/jira/REST/latest/>

Atlassian's official JIRA REST API Reference.

=back

=head1 REPOSITORY

L<https://github.com/packy/JIRA-REST-Class|https://github.com/packy/JIRA-REST-Class>

=head1 CREDITS

=over 4

=item L<Gustavo Leite de Mendonça Chaves|https://metacpan.org/author/GNUSTAVO> <gnustavo@cpan.org>

Many thanks to Gustavo for L<JIRA::REST|JIRA::REST>, which is what I started
working with when I first wanted to automate my interactions with JIRA in
the summer of 2016, and without which I would have had a LOT of work to do.

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Alexey Melezhik

Alexey Melezhik <melezhik@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
