use strict;
use warnings;
use Test::More;

use lib '../lib';
use LightTCP::SSLclient qw(ECONNECT EREQUEST ERESPONSE);

subtest 'redirect options in constructor' => sub {
    my $client = LightTCP::SSLclient->new(
        max_redirects   => 10,
        follow_redirects => 0,
    );

    is($client->get_max_redirects(), 10, 'max_redirects set in constructor');
    is($client->get_follow_redirects(), 0, 'follow_redirects set in constructor');
};

subtest 'redirect accessor methods' => sub {
    my $client = LightTCP::SSLclient->new();

    is($client->get_max_redirects(), 5, 'default max_redirects is 5');
    is($client->get_follow_redirects(), 1, 'default follow_redirects is 1');
    is($client->get_redirect_count(), 0, 'default redirect_count is 0');

    $client->set_max_redirects(3);
    is($client->get_max_redirects(), 3, 'set_max_redirects works');

    $client->set_follow_redirects(0);
    is($client->get_follow_redirects(), 0, 'set_follow_redirects works');
};

subtest 'redirect history is empty initially' => sub {
    my $client = LightTCP::SSLclient->new();

    my $history = $client->get_redirect_history();
    is(ref($history), 'ARRAY', 'redirect_history is an arrayref');
    is(scalar(@$history), 0, 'redirect_history is empty initially');
};

subtest 'resolve_relative_path' => sub {
    my $client = LightTCP::SSLclient->new();

    is($client->_resolve_relative_path('/path/to/resource', '../other'), '/path/other');
    is($client->_resolve_relative_path('/path/to/', 'file'), '/path/to/file');
    is($client->_resolve_relative_path('/path/to/file', 'sibling'), '/path/to/sibling');
};

subtest 'follow_redirects disabled' => sub {
    my $client = LightTCP::SSLclient->new(follow_redirects => 0);

    is($client->get_follow_redirects(), 0, 'follow_redirects is disabled');
    ok(!$client->{follow_redirects}, 'internal flag is 0');
};

subtest 'max_redirects set to zero' => sub {
    my $client = LightTCP::SSLclient->new(max_redirects => 0, follow_redirects => 1);

    is($client->get_max_redirects(), 0, 'max_redirects can be 0');
    is($client->get_follow_redirects(), 1, 'follow_redirects is still enabled');
};

done_testing();
