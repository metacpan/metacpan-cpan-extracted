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
my $issue = $client->get_issue('TESTING-39');
cmp_ok($issue->body->{fields}->{priority}->{value}->{name}, 'eq', 'Minor', 'get_issue');

my $trans = $client->get_issue_transitions('TESTING-39');
cmp_ok($trans->body->{761}->{name}, 'eq', 'Stop Progress', 'get_issue_transitions');

my $votes = $client->get_issue_votes('TESTING-39');
cmp_ok($votes->body->{votes}, '==', 0, 'get_issue_votes');

cmp_ok($client->vote_for_issue('TESTING-1')->status, 'eq', 204, 'vote_for_issue');

cmp_ok($client->unvote_for_issue('TESTING-1')->status, 'eq', 204, 'vote_for_issue');

my $watchers = $client->get_issue_watchers('TESTING-39');
cmp_ok($watchers->body->{watchCount}, '==', 0, 'get_issue_watchers');

cmp_ok($client->watch_issue('TESTING-1', 'cory.watson')->status, '==', 204, 'watch_issue');

cmp_ok($client->unwatch_issue('TESTING-1', 'cory.watson')->status, '==', 204, 'unwatch_issue');

done_testing;
