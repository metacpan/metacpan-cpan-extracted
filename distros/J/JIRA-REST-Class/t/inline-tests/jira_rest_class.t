#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin test setup 1
$::__tc = Test::Builder->new->current_test;
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
is( Test::Builder->new->current_test - $::__tc, 1,
	'1 test was run in the section' );



# =begin testing new 5
$::__tc = Test::Builder->new->current_test;
{
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
}
is( Test::Builder->new->current_test - $::__tc, 5,
	'5 tests were run in the section' );



# =begin testing get
{
validate_wrapper_method( sub { get_test_client()->get('/test'); },
                         { GET => 'SUCCESS' }, 'get() method works' );
}



# =begin testing post
{
validate_wrapper_method( sub { get_test_client()->post('/test', "key=value"); },
                         { POST => 'SUCCESS' }, 'post() method works' );
}



# =begin testing put
{
validate_wrapper_method( sub { get_test_client()->put('/test', "key=value"); },
                         { PUT => 'SUCCESS' }, 'put() method works' );
}



# =begin testing delete
{
validate_wrapper_method( sub { get_test_client()->delete('/test'); },
                         { DELETE => 'SUCCESS' }, 'delete() method works' );
}



# =begin testing data_upload
{
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
}



# =begin testing issue_types 16
$::__tc = Test::Builder->new->current_test;
{
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
}
is( Test::Builder->new->current_test - $::__tc, 16,
	'16 tests were run in the section' );



# =begin testing projects 5
$::__tc = Test::Builder->new->current_test;
{
my $test = get_test_client();

try {
    validate_contextual_accessor($test, {
        method => 'projects',
        class  => 'project',
        data   => [ qw/ JRC KANBAN PACKAY PM SCRUM / ],
    });
};
}
is( Test::Builder->new->current_test - $::__tc, 5,
	'5 tests were run in the section' );



# =begin testing project 17
$::__tc = Test::Builder->new->current_test;
{
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
}
is( Test::Builder->new->current_test - $::__tc, 17,
	'17 tests were run in the section' );



# =begin testing parameter_accessors 7
$::__tc = Test::Builder->new->current_test;
{
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
}
is( Test::Builder->new->current_test - $::__tc, 7,
	'7 tests were run in the section' );




1;
