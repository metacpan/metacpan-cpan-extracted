#!perl -T
use strict;
use warnings;
use Test::More tests => 16;
use Hatena::API::Auth;
use URI::QueryParam;

my $api = Hatena::API::Auth->new({
    api_key => 'test',
    secret  => 'hoge',
});

is '8d03c299aa049c9e47e4f99e03f2df53', $api->api_sig({ api_key => 'test' });
is 'auth.hatena.ne.jp', $api->uri_to_login->host;
is '8d03c299aa049c9e47e4f99e03f2df53', $api->uri_to_login->query_param('api_sig');
is '59d7fb76ceeacc8850ccd2428fd2b0f0', $api->uri_to_login(foo => 'bar')->query_param('api_sig');
is 'bar', $api->uri_to_login(foo => 'bar')->query_param('foo');
is 'c166e2ea4984224375a88e080cd7cce6', $api->uri_to_login(foo => 'bar', 'bar' => 'baz')->query_param('api_sig');
is 'bar', $api->uri_to_login(foo => 'bar', 'bar' => 'baz')->query_param('foo');
is 'baz', $api->uri_to_login(foo => 'bar', 'bar' => 'baz')->query_param('bar');
isa_ok $api->ua, 'LWP::UserAgent';

ok not $api->login('invalidfrob');
like $api->errstr, qr/Invalid API key/;

{
    # hacking for testing
    no warnings;
    *Hatena::API::Auth::_get_auth_as_json = sub {
        return <<EOF;
{
  status : true,
  user : {
    name : "naoya",
    image_url : "http://www.hatena.ne.jp/users/na/naoya/profile.gif",
    thumbnail_url : "http://www.hatena.ne.jp/users/na/naoya/profile_s.gif" 
  }
}
EOF
    };
}

my $user = $api->login("dummy_frob");
ok ref($user);
is ref($user), 'Hatena::API::Auth::User';
is $user->name, 'naoya';
is $user->image_url, 'http://www.hatena.ne.jp/users/na/naoya/profile.gif';
is $user->thumbnail_url, 'http://www.hatena.ne.jp/users/na/naoya/profile_s.gif';

1;
