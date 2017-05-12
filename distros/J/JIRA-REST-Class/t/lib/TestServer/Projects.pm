package TestServer::Projects;
use base qw( TestServer::Plugin );
use strict;
use warnings;
use 5.010;

use JSON;

use TestServer::IssueTypes;
use TestServer::Users;

sub import {
    my $class = __PACKAGE__;
    $class->register_dispatch(
        '/rest/api/latest/project' =>
            sub { $class->project_response(@_) },
        '/rest/api/latest/project/SCRUM' =>
            sub { $class->project_SCRUM_response(@_) },
        '/rest/api/latest/project/10002' =>
            sub { $class->project_SCRUM_response(@_) },
        '/rest/api/latest/projectCategory' =>
            sub { $class->project_category_response(@_) },
        '/rest/api/latest/projectCategory/10000' =>
            sub { $class->project_category_response(@_, 10000) },
        '/rest/api/latest/projectCategory/10001' =>
            sub { $class->project_category_response(@_, 10001) },
        '/rest/api/latest/projectCategory/10002' =>
            sub { $class->project_category_response(@_, 10002) },
    );
}

sub project_response {
    my ( $class, $server, $cgi ) = @_;
    return $class->response($server, $class->project_data($server, $cgi));
}

sub project_SCRUM_response {
    my ( $class, $server, $cgi ) = @_;
    return $class->response($server, $class->project_SCRUM_data($server, $cgi));
}

sub project_category_response {
    my ( $class, $server, $cgi ) = @_;
    return $class->response($server, $class->categories($server, $cgi));
}

sub project_categoryN_response {
    my ( $class, $server, $cgi, $id ) = @_;
    return $class->response($server, $class->category($server, $cgi, $id));
}

sub category {
    my ( $class, $server, $cgi, $id ) = @_;

    my ($category) = grep {
        $_->{id} = $id
    } @{ $class->categories($server, $cgi) };

    return $category;
}

sub projectAvatars {
    my ($url, $pid, $id) = @_;
    my $end = "avatarId=$id";
    $end = join '&', "pid=$pid", $end if (defined $pid);
    $url .= '/secure/projectavatar';
    return {
        "16x16" => "$url?size=xsmall&$end",
        "24x24" => "$url?size=small&$end",
        "32x32" => "$url?size=medium&$end",
        "48x48" => "$url?$end",
    };
}

sub project_data {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;
    return [
      {
        avatarUrls => projectAvatars($url, 10003, 10204),
        expand => "description,lead,url,projectKeys",
        id => 10003,
        key => "JRC",
        name => "JIRA::REST::Class",
        projectCategory => $class->category($server, $cgi, 10002),
        projectTypeKey => "software",
        self => "$url/rest/api/2/project/10003"
      },
      {
        avatarUrls => projectAvatars($url, undef, 10324),
        expand => "description,lead,url,projectKeys",
        id => 10001,
        key => "KANBAN",
        name => "Kanban software development sample project",
        projectCategory => $class->category($server, $cgi, 10000),
        projectTypeKey => "software",
        self => "$url/rest/api/2/project/10001"
      },
      {
        avatarUrls => projectAvatars($url, 10004, 10001),
        expand => "description,lead,url,projectKeys",
        id => 10004,
        key => "PACKAY",
        name => "PacKay Productions",
        projectCategory => $class->category($server, $cgi, 10001),
        projectTypeKey => "business",
        self => "$url/rest/api/2/project/10004"
      },
      {
        avatarUrls => projectAvatars($url, 10000, 10327),
        expand => "description,lead,url,projectKeys",
        id => 10000,
        key => "PM",
        name => "Project Management Sample Project",
        projectCategory => $class->category($server, $cgi, 10000),
        projectTypeKey => "business",
        self => "$url/rest/api/2/project/10000"
      },
      {
        avatarUrls => projectAvatars($url, 10002, 10325),
        expand => "description,lead,url,projectKeys",
        id => 10002,
        key => "SCRUM",
        name => "Scrum Software Development Sample Project",
        projectCategory => $class->category($server, $cgi, 10000),
        projectTypeKey => "software",
        self => "$url/rest/api/2/project/10002"
      }
    ];
}

sub categories {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;
    return [
        {
          description => "These are the demo projects that came with JIRA",
          id => 10000,
          name => "Demo",
          self => "$url/rest/api/latest/projectCategory/10000"
        },
        {
          description => "These are Packy's Perl projects",
          id => 10002,
          name => "Perl",
          self => "$url/rest/api/latest/projectCategory/10002"
        },
        {
          description => "These are projects for PacKay Productions",
          id => 10001,
          name => "Puppet",
          self => "$url/rest/api/latest/projectCategory/10001"
        },
    ];
}

sub project_SCRUM_data {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;

    return {
        assigneeType => "UNASSIGNED",
        avatarUrls => projectAvatars($url, 10002, 10325),
        components => [],
        description => "",
        expand => "description,lead,url,projectKeys",
        id => 10002,
        issueTypes => $class->project_SCRUM_issuetype_data($server, $cgi),
        key => "SCRUM",
        lead => $class->user_packy($server, $cgi),
        name => "Scrum Software Development Sample Project",
        projectCategory => $class->category($server, $cgi, 10000),
        projectTypeKey => "software",
        roles => {
            Administrators => "$url/rest/api/latest/project/10002/role/10002",
            Developers => "$url/rest/api/latest/project/10002/role/10100"
        },
        self => "$url/rest/api/latest/project/10002",
        versions => $class->project_SCRUM_version_data($server, $cgi)
    };
}

sub project_SCRUM_issuetype_data {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;

    return TestServer::IssueTypes->issuetype_filtered(
        $server, $cgi, 10000, 10001, 10002, 10003, 10004
    );
}

sub project_SCRUM_version_data {
    my ( $class, $server, $cgi ) = @_;
    my $url = "http://localhost:" . $server->port;

    return [
        {
            archived => JSON::PP::false,
            id => 10001,
            name => "Version 1.0",
            projectId => 10002,
            releaseDate => "2016-11-20",
            released => JSON::PP::true,
            self => "$url/rest/api/latest/version/10001",
            userReleaseDate => "20/Nov/16"
        },
        {
            archived => JSON::PP::false,
            id => 10002,
            name => "Version 2.0",
            overdue => JSON::PP::false,
            projectId => 10002,
            releaseDate => "2016-12-04",
            released => JSON::PP::false,
            self => "$url/rest/api/latest/version/10002",
            userReleaseDate => "04/Dec/16"
        },
        {
            archived => JSON::PP::false,
            id => 10003,
            name => "Version 3.0",
            projectId => 10002,
            released => JSON::PP::false,
            self => "$url/rest/api/latest/version/10003"
        }
    ];
}

sub user_packy {
    my ( $class, $server, $cgi ) = @_;
    return TestServer::Users->minuser(
        $server, $cgi, 'packy'
    );
}

1;
