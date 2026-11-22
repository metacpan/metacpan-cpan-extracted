use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64);

use lib 'examples';
use HTTP::API::Core::Example::Jira;

my @calls;
my $jira = HTTP::API::Core::Example::Jira->new(
    base_url => 'https://jira.example.test',
    username => 'example-user',
    password => 'example-password',
    transport => sub {
        my ($method, $url, $opts) = @_;
        push @calls, [$method, $url, $opts];
        my $content = $url =~ /startAt=0(?:&|$)/
            ? '{"issues":[{"key":"A-1"},{"key":"A-2"}],"total":3}'
            : '{"issues":[{"key":"A-3"}],"total":3}';
        return {
            status => 200,
            headers => { 'content-type' => 'application/json' },
            content => $content,
        };
    },
);

my $pager = $jira->issues_pager(
    jql => 'filter=12345',
    fields => [qw(summary description components)],
    max_results => 1000,
);
is scalar(@calls), 0, 'Jira pager remains lazy';
is_deeply [map { $_->{key} } $pager->all], [qw(A-1 A-2 A-3)],
    'Jira recipe iterates all issues despite capped pages';
is scalar(@calls), 2, 'Jira recipe stops at total without extra requests';
is $calls[0][0], 'GET', 'search uses GET';
like $calls[0][1], qr{\Ahttps://jira\.example\.test/rest/api/2/search\?},
    'uses Jira Server/Data Center search endpoint under the root context';
like $calls[0][1], qr/(?:\?|&)jql=filter%3D12345(?:&|$)/,
    'escapes JQL query';
like $calls[0][1], qr/(?:\?|&)fields=summary%2Cdescription%2Ccomponents(?:&|$)/,
    'maps array fields to a comma-separated query value';
like $calls[0][1], qr/(?:\?|&)maxResults=1000(?:&|$)/,
    'passes the requested size';
like $calls[0][1], qr/(?:\?|&)startAt=0(?:&|$)/,
    'starts at offset zero';
like $calls[1][1], qr/(?:\?|&)startAt=2(?:&|$)/,
    'advances by actual returned count rather than requested max';
is $calls[0][2]{headers}{Authorization},
    'Basic ' . encode_base64('example-user:example-password', ''),
    'uses the shared basic_auth helper';


# Jira deployments often have a context path such as /jira.
my @context_calls;
my $context_jira = HTTP::API::Core::Example::Jira->new(
    base_url => 'https://jira.example.test/jira',
    username => 'example-user',
    password => 'example-password',
    transport => sub {
        my ($method, $url, $opts) = @_;
        push @context_calls, [$method, $url, $opts];
        return {
            status => 200,
            headers => { 'content-type' => 'application/json' },
            content => '{"issues":[{"key":"B-1"}],"total":1}',
        };
    },
);
is_deeply [map { $_->{key} } $context_jira->issues_pager(jql => 'project = B')->all],
    ['B-1'], 'Jira context-path search returns issues';
is scalar(@context_calls), 1, 'Jira context path requires one request';
like $context_calls[0][1],
    qr{\Ahttps://jira\.example\.test/jira/rest/api/2/search\?},
    'Jira context path is used exactly once';

for my $case (
    [sub { $jira->issues_pager(fields => 'summary') }, qr/jql must be a non-empty scalar/],
    [sub { $jira->issues_pager(jql => 'x', fields => [{}]) }, qr/fields must contain/],
    [sub { $jira->issues_pager(jql => 'x', unknown => 1) }, qr/unknown issues_pager option/],
    [sub { HTTP::API::Core::Example::Jira->new(base_url => 'https://jira.example.test', username => 'x') }, qr/password is required/],
) {
    my ($action, $pattern) = @$case;
    my $error;
    eval { $action->(); 1 } or $error = $@;
    like "$error", $pattern, 'invalid Jira recipe arguments are rejected';
}

done_testing;
