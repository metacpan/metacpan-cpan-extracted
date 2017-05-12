use strict;
use Test::More;
use JIRA::Client::REST;

if(!$ENV{JIRA_CLIENT_REST_URL}) {
    plan skip_all => 'Set JIRA_CLIENT_REST_URL';
}

my $client = JIRA::Client::REST->new(
    username => $ENV{JIRA_CLIENT_REST_USER},
    password => $ENV{JIRA_CLIENT_REST_PASS},
    url => $ENV{JIRA_CLIENT_REST_URL},
    debug => 1
);
my $proj = $client->get_project("TESTING");

cmp_ok($proj->body->{name}, 'eq', 'TESTING', 'project name');

my $vers = $client->get_project_versions("TESTING");
ok(scalar(@{ $vers->body }) > 0, 'got versions');

done_testing;
