package TestServer::IssueTypes;
use base qw( TestServer::Plugin );
use strict;
use warnings;
use 5.010;

use JSON::PP;

sub import {
    my $class = __PACKAGE__;
    $class->register_dispatch(
        '/rest/api/latest/issuetype' => sub { $class->issuetype_response(@_) },
    );
}

sub issuetype_response {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;

    $class->response($server, $class->issuetype_data($server, $cgi));
}

sub issuetype_filtered {
    my ( $class, $server, $cgi, @list ) = @_;
    my $url = "http://localhost:" . $server->port;

    my $data = $class->issuetype_data($server, $cgi);

    my $match = join '|', @list;

    return [ grep {
        $_->{id} =~ /^($match)$/
    } @$data ];
}

sub issuetype_data {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;

    return [
      {
        avatarId => 10310,
        description => "An improvement or enhancement to an existing feature or task.",
        iconUrl => "$url/secure/viewavatar?size=xsmall&avatarId=10310&avatarType=issuetype",
        id => 10005,
        name => "Improvement",
        self => "$url/rest/api/latest/issuetype/10005",
        subtask => JSON::PP::false
      },
      {
        avatarId => 10318,
        description => "A task that needs to be done.",
        iconUrl => "$url/secure/viewavatar?size=xsmall&avatarId=10318&avatarType=issuetype",
        id => 10002,
        name => "Task",
        self => "$url/rest/api/latest/issuetype/10002",
        subtask => JSON::PP::false
      },
      {
        avatarId => 10316,
        description => "The sub-task of the issue",
        iconUrl => "$url/secure/viewavatar?size=xsmall&avatarId=10316&avatarType=issuetype",
        id => 10003,
        name => "Sub-task",
        self => "$url/rest/api/latest/issuetype/10003",
        subtask => JSON::PP::true
      },
      {
        avatarId => 10311,
        description => "A new feature of the product, which has yet to be developed.",
        iconUrl => "$url/secure/viewavatar?size=xsmall&avatarId=10311&avatarType=issuetype",
        id => 10006,
        name => "New Feature",
        self => "$url/rest/api/latest/issuetype/10006",
        subtask => JSON::PP::false
      },
      {
        avatarId => 10303,
        description => "jira.translation.issuetype.bug.name.desc",
        iconUrl => "$url/secure/viewavatar?size=xsmall&avatarId=10303&avatarType=issuetype",
        id => 10004,
        name => "Bug",
        self => "$url/rest/api/latest/issuetype/10004",
        subtask => JSON::PP::false
      },
      {
        description => "gh.issue.epic.desc",
        iconUrl => "$url/images/icons/issuetypes/epic.svg",
        id => 10000,
        name => "Epic",
        self => "$url/rest/api/latest/issuetype/10000",
        subtask => JSON::PP::false
      },
      {
        description => "gh.issue.story.desc",
        iconUrl => "$url/images/icons/issuetypes/story.svg",
        id => 10001,
        name => "Story",
        self => "$url/rest/api/latest/issuetype/10001",
        subtask => JSON::PP::false
      }
    ];
} # issuetype_data

1;
