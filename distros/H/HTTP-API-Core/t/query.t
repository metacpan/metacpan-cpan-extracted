use strict;
use warnings;
use Test::More;
use utf8;

use HTTP::API::Core;

my @seen;
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    transport => sub {
        my ($method, $url, $opts) = @_;
        push @seen, $url;
        return { status => 200, reason => 'OK', headers => {}, content => '{}' };
    },
);

$api->get('/users', query => { q => 'hello world', page => 2 });
is $seen[-1], 'https://api.example.test/users?page=2&q=hello%20world', 'scalar query values encoded deterministically';

$api->get('/users', query => { tag => ['admin', 'staff'], skip => undef });
is $seen[-1], 'https://api.example.test/users?tag=admin&tag=staff', 'arrays repeat keys and undef is omitted';

$api->get('/users?sort=name', query => { page => 3 });
is $seen[-1], 'https://api.example.test/users?sort=name&page=3', 'existing query string preserved';

$api->get('/users#section', query => { q => 'x' });
is $seen[-1], 'https://api.example.test/users?q=x#section', 'query inserted before fragment';

$api->get('https://other.example.test/items?x=1#frag', query => { y => 'a/b' });
is $seen[-1], 'https://other.example.test/items?x=1&y=a%2Fb#frag', 'absolute URL supports query and fragment';

$api->get('/unicode', query => { q => '東京' });
is $seen[-1], 'https://api.example.test/unicode?q=%E6%9D%B1%E4%BA%AC', 'UTF-8 encoded as percent bytes';

$api->get('/empty', query => {});
is $seen[-1], 'https://api.example.test/empty', 'empty query leaves URL unchanged';

my $error;
eval { $api->get('/bad', query => []) };
$error = $@;
like $error, qr/query must be a hash reference/, 'query must be hashref';

eval { $api->get('/bad', query => { nested => { x => 1 } }) };
$error = $@;
like $error, qr/query values must be scalars/, 'nested query values rejected';

my $hook_url;
my $hook_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    hooks => { before_request => sub { $hook_url = $_[0]{url} } },
    transport => sub { return { status => 200, reason => 'OK', headers => {}, content => '{}' } },
);
$hook_api->get('/hook', query => { q => 'a b' });
is $hook_url, 'https://api.example.test/hook?q=a%20b', 'before_request sees encoded URL';

done_testing;
