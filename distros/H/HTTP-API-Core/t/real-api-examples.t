use strict;
use warnings;
use Test::More;

use lib 'examples';
use HTTP::API::Core::Example::GitHub;
use HTTP::API::Core::Example::Slack;
use HTTP::API::Core::Example::Cloudflare;

subtest github => sub {
    my @calls;
    my $client = HTTP::API::Core::Example::GitHub->new(
        token => 'github-token',
        transport => sub {
            my ($method, $url, $opts) = @_;
            push @calls, [$method, $url, $opts];
            my $content = $url =~ /page=1(?:&|$)/
                ? '[{"full_name":"example/one"},{"full_name":"example/two"}]'
                : '[]';
            return {
                status  => 200,
                headers => {
                    'Content-Type'          => 'application/json',
                    'X-RateLimit-Limit'     => '5000',
                    'X-RateLimit-Remaining' => '4999',
                },
                content => $content,
            };
        },
    );

    my @repos = $client->repositories_pager(per_page => 2)->all;
    is_deeply [map { $_->{full_name} } @repos],
        ['example/one', 'example/two'], 'reads a top-level array across pages';
    like $calls[0][1], qr{/user/repos\?page=1&per_page=2},
        'uses GitHub page parameters';
    is $calls[0][2]{headers}{Authorization}, 'Bearer github-token',
        'sends GitHub bearer token';
};

subtest slack => sub {
    my @calls;
    my $client = HTTP::API::Core::Example::Slack->new(
        token => 'slack-token',
        transport => sub {
            my ($method, $url, $opts) = @_;
            push @calls, [$method, $url, $opts];
            my $content = $url =~ /cursor=next-1/
                ? '{"ok":true,"messages":[{"ts":"2"}],"response_metadata":{"next_cursor":""}}'
                : '{"ok":true,"messages":[{"ts":"1"}],"response_metadata":{"next_cursor":"next-1"}}';
            return {
                status  => 200,
                headers => { 'Content-Type' => 'application/json' },
                content => $content,
            };
        },
    );

    my @messages = $client->messages_pager(channel => 'C123', limit => 50)->all;
    is_deeply [map { $_->{ts} } @messages], ['1', '2'],
        'follows Slack response_metadata cursor';
    like $calls[1][1], qr/(?:[?&])cursor=next-1(?:&|$)/,
        'sends Slack continuation cursor';
    like $calls[0][1], qr/(?:[?&])channel=C123(?:&|$)/,
        'sends Slack channel';
};

subtest cloudflare => sub {
    my @calls;
    my $client = HTTP::API::Core::Example::Cloudflare->new(
        token => 'cloudflare-token',
        transport => sub {
            my ($method, $url, $opts) = @_;
            push @calls, [$method, $url, $opts];
            my $page = $url =~ /page=2(?:&|$)/ ? 2 : 1;
            return {
                status  => 200,
                headers => { 'Content-Type' => 'application/json' },
                content => sprintf(
                    '{"success":true,"result":[{"name":"zone%d.example"}],"result_info":{"page":%d,"per_page":1,"total_pages":2}}',
                    $page,
                    $page,
                ),
            };
        },
    );

    my @zones = $client->zones_pager(status => 'active', per_page => 1)->all;
    is_deeply [map { $_->{name} } @zones],
        ['zone1.example', 'zone2.example'],
        'uses Cloudflare result_info total_pages';
    like $calls[1][1], qr/(?:[?&])page=2(?:&|$)/,
        'requests the second Cloudflare page';
    like $calls[0][1], qr/(?:[?&])status=active(?:&|$)/,
        'sends Cloudflare filters';
};

done_testing;
