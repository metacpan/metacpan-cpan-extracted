#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Temp;
use File::Spec;
use JSON;
use HTTP::Response;
use Test::MockModule;

BEGIN {
    use_ok('JIRA::Client::Automated');
}

sub dispatch {
    my %dispatch = @_;

    return sub {
        my ($self, $request) = @_;

        my $path = $request->uri->path;
        $path =~ s!^/rest/api/latest/!!;

        my $sub = $dispatch{$path} or die "no sub to dispatch to for [$path]";
        $sub->($request);
    };
}

my $JCA = 'JIRA::Client::Automated';

my $json = JSON->new->utf8()->allow_nonref;

my $jira = JIRA::Client::Automated->new('http://my.jira.server', 'username', 'password');

# Create new JCA object
ok $jira, 'new object';
isa_ok($jira, $JCA);

subtest 'create' => sub {
    subtest 'basic creation' => sub {
        my $request;
        my $ua = Test::MockModule->new('LWP::UserAgent');
        $ua->mock(request => dispatch(
            'issue/createmeta' => sub {
                return HTTP::Response->new('200', 'OK', [], $json->encode(createmeta()));
            },
            'issue/' => sub {
                my ($request_) = @_;

                $request = $request_;
                my $body = {
                    key => 'MyProject-123'
                };
                return HTTP::Response->new('200', 'OK', [], $json->encode($body));
            },
        ));

        # Create an issue
        my $issue = $jira->create_issue(
            'MyProject', 'Bug',
            "$JCA Test Script",
            "Created by $JCA Test Script automatically.",
            {
                labels => ["Commentary"] });

        ok($issue, 'create_issue');
        isa_ok($issue, 'HASH');
        is $issue->{key}, 'MyProject-123', 'hash returned contains key';

        my $request_content = $json->decode($request->decoded_content);
        cmp_deeply(
            $request_content,
            {
                'fields' => {
                    'description' => 'Created by JIRA::Client::Automated Test Script automatically.',
                    'issuetype' => {
                        'name' => 'Bug'
                    },
                    'labels' => [
                        'Commentary'
                    ],
                    'project' => {
                        'key' => 'MyProject'
                    },
                    'summary' => 'JIRA::Client::Automated Test Script'
                }
            },
            'request ok') or explain $request_content;
    };

    subtest 'creation with custom fields' => sub {
        subtest 'custom field isa single-select' => sub {
            my $request;
            my $ua = Test::MockModule->new('LWP::UserAgent');
            $ua->mock(request => dispatch(
                'issue/createmeta' => sub {
                    return HTTP::Response->new('200', 'OK', [], $json->encode(createmeta()));
                },
                'issue/' => sub {
                    my ($request_) = @_;

                    $request = $request_;
                    my $body = {
                        key => 'MyProject-123'
                    };
                    return HTTP::Response->new('200', 'OK', [], $json->encode($body));
                },
            ));

            # Create an issue
            my $issue = $jira->create_issue(
                'MyProject', 'Task',
                "$JCA Test Script",
                "Created by $JCA Test Script automatically.",
                {
                    Group => 'Management',
                }
            );

            ok($issue, 'create_issue');
            isa_ok($issue, 'HASH');
            is $issue->{key}, 'MyProject-123', 'hash returned contains key';

            my $request_content = $json->decode($request->decoded_content);
            cmp_deeply(
                $request_content,
                {
                    'fields' => {
                        'description' => 'Created by JIRA::Client::Automated Test Script automatically.',
                        'issuetype' => {
                            'name' => 'Task'
                        },
                        'project' => {
                            'key' => 'MyProject'
                        },
                        'summary' => 'JIRA::Client::Automated Test Script',
                        customfield_11883 => {
                            id => 13602,
                        },
                    }
                },
                'request ok') or explain $request_content;
        };

        subtest 'custom field isa multi-select' => sub {
            my $request;
            my $ua = Test::MockModule->new('LWP::UserAgent');
            $ua->mock(request => dispatch(
                'issue/createmeta' => sub {
                    return HTTP::Response->new('200', 'OK', [], $json->encode(createmeta()));
                },
                'issue/' => sub {
                    my ($request_) = @_;

                    $request = $request_;
                    my $body = {
                        key => 'MyProject-123'
                    };
                    return HTTP::Response->new('200', 'OK', [], $json->encode($body));
                },
            ));

            # Create an issue
            my $issue = $jira->create_issue(
                'MyProject', 'Task',
                "$JCA Test Script",
                "Created by $JCA Test Script automatically.",
                {
                    Group => [
                        'Management',
                        'DevOps',
                    ],
                }
            );

            ok($issue, 'create_issue');
            isa_ok($issue, 'HASH');
            is $issue->{key}, 'MyProject-123', 'hash returned contains key';

            my $request_content = $json->decode($request->decoded_content);
            cmp_deeply(
                $request_content,
                {
                    'fields' => {
                        'description' => 'Created by JIRA::Client::Automated Test Script automatically.',
                        'issuetype' => {
                            'name' => 'Task'
                        },
                        'project' => {
                            'key' => 'MyProject'
                        },
                        'summary' => 'JIRA::Client::Automated Test Script',
                        customfield_11883 => [
                            { id => 13602 },
                            { id => 13107 },
                        ],
                    }
                },
                'request ok') or explain $request_content;
        };
    };
};

subtest 'get_issue' => sub {
    my $request;
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock(request => dispatch(
        'issue/createmeta' => sub {
            return HTTP::Response->new('200', 'OK', [], $json->encode(createmeta()));
        },
        'issue/MyProject-123' => sub {
            my $body = _get_issue();
            return HTTP::Response->new('200', 'OK', [], $json->encode($body));
        },
    ));

    # Create an issue
    my $issue = $jira->get_issue('MyProject-123');

    isa_ok($issue, 'HASH');
    is $issue->{key}, 'MyProject-123', 'hash returned contains key';

    cmp_deeply(
        $issue,
        {
            expand => 'renderedFields,names,schema,transitions,operations,editmeta,changelog',
            key => 'MyProject-123',
            id => 499114,
            self => 'https://my.jira.server/rest/api/latest/issue/499114',
            fields => {
                description => 'Created by JIRA::Client::Automated Test Script automatically.',
                issuetype => {
                    description => "A task that needs to be done.",
                    iconUrl => "https://my.jira.server/images/icons/issuetypes/task.png",
                    id => 3,
                    name => "Task",
                    self => "https://my.jira.server/rest/api/2/issuetype/3",
                    subtask => bless(do{\(my $o = 0)}, "JSON::XS::Boolean"),
                },
                project => {
                    id => 12881,
                    key => 'MyProject',
                    name => 'My Project',
                    self => 'https://my.jira.server/rest/api/2/project/12881',
                },
                summary => 'JIRA::Client::Automated Test Script',
                'NBX Tiers' => [ 'WS', 'MW', 'AG' ],
                COS => 'Standard',
                Group => 'DevOps',
                Reviewers => undef,
                status => {
                    description => "This issue is being actively worked on at the moment by the assignee.",
                    iconUrl => "https://my.jira.server/images/icons/statuses/inprogress.png",
                    id => 3,
                    name => "In Development",
                    self => "https://my.jira.server/rest/api/2/status/3",
                    statusCategory => {
                        colorName => "yellow",
                        id => 4,
                        key => "indeterminate",
                        name => "In Progress",
                        self => "https://my.jira.server/rest/api/2/statuscategory/4",
                    },
                },
            }
        },
        'request ok') or explain $issue;
};

subtest 'update_issue' => sub {
    my $request;
    my $ua = Test::MockModule->new('LWP::UserAgent');
    $ua->mock(request => dispatch(
        'issue/createmeta' => sub {
            return HTTP::Response->new('200', 'OK', [], $json->encode(createmeta()));
        },
        'issue/MyProject-123' => sub {
            my $request = shift;
            
            if( $request->method eq 'GET'){
                my $body = _get_issue();
                return HTTP::Response->new('200', 'OK', [], $json->encode($body));
            }
            else { # It is a PUT request from update call
                my $content = $json->decode($request->content);
                
                # Intercept PUT request and verify fields were updated as expected
                ok( !exists $content->{fields}->{Group}, "Group field removed from fields");
                is $content->{fields}->{customfield_11883}->{id}, 13108, "Group converted to customfield correctly";
                
                ok( !exists $content->{update}->{COS}, "COS key removed from update");
                is( $content->{update}->{customfield_11882}->[0]->{set}->{value}, 'Expedite', "COS converted to customfield correctly");
                
                ok( exists $content->{update}->{customfield_12685});
                is $content->{update}->{customfield_12685}->[0]->{set}->{value}, 'AG', "Using customfield id directly still working";
                
                # Return a issue body
                my $body = _get_issue();
                return HTTP::Response->new('200', 'OK', [], $json->encode($body));
            }
            
        },
    ));

    # Update issue - tests are completed as part of the mock intercept defined above
    $jira->update_issue(
        'MyProject-123', 
        { 'Group' => 'DBA' },
        {
            'COS' => [ { set => { value => 'Expedite' }}],
            'customfield_12685' => [ { set => { value => 'AG' }}]
        }  
    );

    
};

done_testing();

sub createmeta {
    my $a = {
        expand   => "projects",
        projects => [
            {
                expand => "issuetypes",
                id => 11083,
                issuetypes => [
                    {
                        description => "A task that needs to be done.",
                        expand      => "fields",
                        fields      => {
                            assignee => {
                                hasDefaultValue => bless(do{\(my $o = 0)}, "JSON::XS::Boolean"),
                                name => "Assignee",
                                operations => ["set"],
                                required => 'fix',
                                schema => { system => "assignee", type => "user" },
                            },
                            customfield_11882 => {
                                allowedValues => [
                                    {
                                        id => 13094,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13094",
                                        value => "Expedite",
                                    },
                                    {
                                        id => 13862,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13862",
                                        value => "Defect",
                                    },
                                    {
                                        id => 13095,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13095",
                                        value => "Standard",
                                    },
                                    {
                                        id => 13096,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13096",
                                        value => "Fixed Date",
                                    },
                                    {
                                        id => 13097,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13097",
                                        value => "Intangeable",
                                    },
                                ],
                                hasDefaultValue => bless(do{\(my $o = 1)}, "JSON::XS::Boolean"),
                                name => "COS",
                                operations => ["set"],
                                required => 'fix',
                                schema => {
                                    custom => "com.atlassian.jira.plugin.system.customfieldtypes:select",
                                    customId => 11882,
                                    type => "string",
                                },
                            },
                            customfield_11883 => {
                                allowedValues => [
                                    {
                                        id => 13098,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13098",
                                        value => "Network",
                                    },
                                    {
                                        id => 13099,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13099",
                                        value => "Windows",
                                    },
                                    {
                                        id => 13101,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13101",
                                        value => "Linux / Unix",
                                    },
                                    {
                                        id => 13100,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13100",
                                        value => "Storage",
                                    },
                                    {
                                        id => 13107,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13107",
                                        value => "DevOps",
                                    },
                                    {
                                        id => 13108,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13108",
                                        value => "DBA",
                                    },
                                    {
                                        id => 13492,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13492",
                                        value => "DC",
                                    },
                                    {
                                        id => 13493,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13493",
                                        value => "VMWare",
                                    },
                                    {
                                        id => 13494,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13494",
                                        value => "Monitoring",
                                    },
                                    {
                                        id => 13495,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13495",
                                        value => "Backup",
                                    },
                                    {
                                        id => 13600,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13600",
                                        value => "Architect",
                                    },
                                    {
                                        id => 13601,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13601",
                                        value => "Infosec",
                                    },
                                    {
                                        id => 13602,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13602",
                                        value => "Management",
                                    },
                                    {
                                        id => 13603,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13603",
                                        value => "Jira Admin",
                                    },
                                    {
                                        id => 13861,
                                        self => "https://my.jira.server/rest/api/2/customFieldOption/13861",
                                        value => "VOIP",
                                    },
                                ],
                                hasDefaultValue => 'fix',
                                name => "Group",
                                operations => ["set"],
                                required => 'fix',
                                schema => {
                                    custom => "com.atlassian.jira.plugin.system.customfieldtypes:select",
                                    customId => 11883,
                                    type => "string",
                                },
                            },
                            customfield_12685 => {
                                allowedValues => [
                                    {
                                        id => 13869,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13869",
                                        value => "WS",
                                    },
                                    {
                                        id => 13870,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13870",
                                        value => "MW",
                                    },
                                    {
                                        id => 13871,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13871",
                                        value => "AG",
                                    },
                                    {
                                        id => 13872,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13872",
                                        value => "DB",
                                    },
                                ],
                                hasDefaultValue => 'fix',
                                name => "NBX Tiers",
                                operations => ["add", "set", "remove"],
                                required => 'fix',
                                schema => {
                                    custom   => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes",
                                    customId => 12685,
                                    items    => "string",
                                    type     => "array",
                                },
                            },
                            customfield_12885 => {
                                hasDefaultValue => 'fix',
                                name => "Reviewers",
                                operations => ["add", "set", "remove"],
                                required => 'fix',
                                schema => {
                                    custom   => "com.atlassian.jira.plugin.system.customfieldtypes:multiuserpicker",
                                    customId => 12885,
                                    items    => "user",
                                    type     => "array",
                                },
                            },
                            description => {
                                hasDefaultValue => 'fix',
                                name => "Description",
                                operations => ["set"],
                                required => 'fix',
                                schema => { system => "description", type => "string" },
                            },
                            duedate => {
                                hasDefaultValue => 'fix',
                                name => "Due Date",
                                operations => ["set"],
                                required => 'fix',
                                schema => { system => "duedate", type => "date" },
                            },
                            issuetype => {
                                allowedValues => [
                                    {
                                        description => "A task that needs to be done.",
                                        id => 3,
                                        name => "Task",
                                        self => "https://my.jira.server/rest/api/2/issuetype/3",
                                        subtask => 'fix',
                                    },
                                ],
                                hasDefaultValue => 'fix',
                                name => "Issue Type",
                                operations => [],
                                required => 'fix',
                                schema => { system => "issuetype", type => "issuetype" },
                            },
                            labels => {
                                hasDefaultValue => 'fix',
                                name => "Labels",
                                operations => ["add", "set", "remove"],
                                required => 'fix',
                                schema => { items => "string", system => "labels", type => "array" },
                            },
                            priority => {
                                allowedValues => [
                                    {
                                        id => 5,
                                        name => "0 - To be prioritized",
                                        self => "https://my.jira.server/rest/api/2/priority/5",
                                    },
                                    {
                                        id => 1,
                                        name => "1 - Critical",
                                        self => "https://my.jira.server/rest/api/2/priority/1",
                                    },
                                    {
                                        id => 2,
                                        name => "2- High",
                                        self => "https://my.jira.server/rest/api/2/priority/2",
                                    },
                                    {
                                        id => 3,
                                        name => "3 - Medium",
                                        self => "https://my.jira.server/rest/api/2/priority/3",
                                    },
                                    {
                                        id => 4,
                                        name => "4 - Low",
                                        self => "https://my.jira.server/rest/api/2/priority/4",
                                    },
                                ],
                                hasDefaultValue => 'fix',
                                name => "Priority",
                                operations => ["set"],
                                required => 'fix',
                                schema => { system => "priority", type => "priority" },
                            },
                            project => {
                                allowedValues => [
                                    {
                                        id => 11083,
                                        key => "CBGOPS",
                                        name => "Cambridge IT Operations",
                                        self => "https://my.jira.server/rest/api/2/project/11083",
                                    },
                                ],
                                hasDefaultValue => 'fix',
                                name => "Project",
                                operations => ["set"],
                                required => 'fix',
                                schema => { system => "project", type => "project" },
                            },
                            reporter => {
                                hasDefaultValue => 'fix',
                                name => "Reporter",
                                operations => ["set"],
                                required => 'fix',
                                schema => { system => "reporter", type => "user" },
                            },
                            summary => {
                                hasDefaultValue => 'fix',
                                name => "Summary",
                                operations => ["set"],
                                required => 'fix',
                                schema => { system => "summary", type => "string" },
                            },
                            customfield_11883 => {
                                allowedValues => [
                                    {
                                        id => 13098,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13098",
                                        value => "Network",
                                    },
                                    {
                                        id => 13099,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13099",
                                        value => "Windows",
                                    },
                                    {
                                               id => 13101,
                                               self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13101",
                                               value => "Linux / Unix",
                                           },
                                    {
                                        id => 13100,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13100",
                                        value => "Storage",
                                    }
                                        ,
                                    {
                                        id => 13107,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13107",
                                        value => "DevOps",
                                    },
                                    {
                                        id => 13108,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13108",
                                        value => "DBA",
                                    },
                                    {
                                        id => 13492,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13492",
                                        value => "DC",
                                    },
                                    {
                                        id => 13493,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13493",
                                        value => "VMWare",
                                    },
                                    {
                                        id => 13494,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13494",
                                        value => "Monitoring",
                                    },
                                    {
                                        id => 13495,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13495",
                                        value => "Backup",
                                    },
                                    {
                                        id => 13600,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13600",
                                        value => "Architect",
                                    },
                                    {
                                        id => 13601,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13601",
                                        value => "Infosec",
                                    },
                                    {
                                        id => 13602,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13602",
                                        value => "Management",
                                    },
                                    {
                                        id => 13603,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13603",
                                        value => "Jira Admin",
                                    },
                                    {
                                        id => 13861,
                                        self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13861",
                                        value => "VOIP",
                                    },
                                ],
                                hasDefaultValue => 'fix',
                                name => "Group",
                                operations => ["set"],
                                required => 'fix',
                                schema => {
                                    custom => "com.atlassian.jira.plugin.system.customfieldtypes:select",
                                    customId => 11883,
                                    type => "string",
                                },
                            },
                        },
                        id          => 3,
                        name        => "Task",
                        self        => "https://my.jira.server/rest/api/2/issuetype/3",
                        subtask     => bless(do{\(my $o = 0)}, "JSON::XS::Boolean"),
                    },
                ],
                key => "MyProject",
                name => "My project",
                self => "https://my.jira.server/rest/api/2/project/11083",
            },
        ],
    };

    return $a;
}

sub _get_issue {
    return {
        expand => "renderedFields,names,schema,transitions,operations,editmeta,changelog",
        fields => {
            customfield_10000 => [
                {
                    id => 10000,
                    self => "https://my.jira.server/rest/api/2/customFieldOption/10000",
                    value => "Impediment",
                },
            ],
            customfield_10980 => undef,
            customfield_10380 => '123456',
            customfield_11882 => {
                id => 13095,
                self => "https://my.jira.server/rest/api/2/customFieldOption/13095",
                value => "Standard",
            },
            customfield_11883 => {
                id => 13107,
                self => "https://my.jira.server/rest/api/2/customFieldOption/13107",
                value => "DevOps",
            },
            customfield_12885 => undef,
            customfield_12685 => [
                {
                    id => 13869,
                    self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13869",
                    value => "WS",
                },
                {
                    id => 13870,
                    self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13870",
                    value => "MW",
                },
                {
                    id => 13872,
                    self => "https://jordan.corporate.local/jira/rest/api/2/customFieldOption/13872",
                    value => "AG",
                },
            ],
            description => 'Created by JIRA::Client::Automated Test Script automatically.',
            issuetype => {
                description => "A task that needs to be done.",
                iconUrl => "https://my.jira.server/images/icons/issuetypes/task.png",
                id => 3,
                name => "Task",
                self => "https://my.jira.server/rest/api/2/issuetype/3",
                subtask => bless(do{\(my $o = 0)}, "JSON::XS::Boolean"),
            },
            project => {
                id => 12881,
                key => "MyProject",
                name => "My Project",
                self => "https://my.jira.server/rest/api/2/project/12881",
            },
            status => {
                description => "This issue is being actively worked on at the moment by the assignee.",
                iconUrl => "https://my.jira.server/images/icons/statuses/inprogress.png",
                id => 3,
                name => "In Development",
                self => "https://my.jira.server/rest/api/2/status/3",
                statusCategory => {
                    colorName => "yellow",
                    id => 4,
                    key => "indeterminate",
                    name => "In Progress",
                    self => "https://my.jira.server/rest/api/2/statuscategory/4",
                },
            },
            summary => 'JIRA::Client::Automated Test Script',
        },
        id => 499114,
        key => "MyProject-123",
        self => "https://my.jira.server/rest/api/latest/issue/499114",
    };
}
