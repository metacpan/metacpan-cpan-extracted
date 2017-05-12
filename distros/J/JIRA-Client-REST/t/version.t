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
my $ver = $client->get_version("10001");
cmp_ok($ver->body->{name}, 'eq', '0.04', 'version name');

done_testing;
