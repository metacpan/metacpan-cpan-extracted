use strict;
use warnings;

use Test::Exception;
use Test::More;
use Test::TCP;
use Test::Warnings 'warning';
use LWP::UserAgent;
use Mastodon::Client;
use Try::Tiny;

use lib 't/lib';

use Plack::Runner;
use Plack::App::Mastodon::MockServer::v1;

# use Log::Any::Adapter;
# Log::Any::Adapter->set( 'Stderr',
#   category => 'Mastodon',
#   log_level => 'debug',
# );

my $host = '127.0.0.1';

my $server = try {
  Test::TCP->new(
    host => $host,
    max_wait => 3, # seconds
    code => sub {
      my $port = shift;
      my $runner = Plack::Runner->new;
      $runner->parse_options(
        '--host'   => $host,
        '--port'   => $port,
        '--env'    => 'test',
        '--server' => 'HTTP::Server::PSGI'
      );
      $runner->run(Plack::App::Mastodon::MockServer::v1->new->to_app);
    }
  );
}
catch {
  plan skip_all => $_;
};

my $url = "http://$host:" . $server->port;

my $client = Mastodon::Client->new(
  instance => $url,
  coerce_entities => 1,
);

ok my $instance = $client->fetch_instance, 'fetch_instance succeeds';
isa_ok $instance, 'Mastodon::Entity::Instance';
isa_ok $client->instance, 'Mastodon::Entity::Instance';

# Override internal base URL
$client->instance->{uri} = $url;

# get_account
{
  my $response;
  ok $response = $client->get_account();
  isa_ok $response, 'Mastodon::Entity::Account';
  like $response->username, qr/a/i, 'Fetches self';

  is_deeply $response, $client->account, 'Cache self account';

  ok $response = $client->get_account(2);
  isa_ok $response, 'Mastodon::Entity::Account';
  like $response->username, qr/b/i, 'Fetches other';

  ok $response = $client->get_account({});
  isa_ok $response, 'Mastodon::Entity::Account';
  like $response->username, qr/a/i, 'Fetches self';

  ok $response = $client->get_account(2, {});
  isa_ok $response, 'Mastodon::Entity::Account';
  like $response->username, qr/b/i, 'Fetches other';
}

# followers
{
  use Mastodon::Types qw( is_Account );
  use List::Util qw( all );

  my $response;
  ok $response = $client->followers(), 'followers()';
  isa_ok $response, 'ARRAY';
  is scalar(@{$response}), 2, 'a has two followers';
  ok( (all { is_Account($_) } @{$response}), 'List of Account');
  like $response->[0]->username, qr/b/i, 'Followed by b';
  like $response->[1]->username, qr/c/i, 'Followed by c';

  ok $response = $client->followers(2), 'followers(Int)';
  isa_ok $response, 'ARRAY';
  is scalar(@{$response}), 0, 'b has no followers';

  ok $response = $client->followers({}), 'followers(HashRef)';
  isa_ok $response, 'ARRAY';
  is scalar(@{$response}), 2, 'a has two followers';
  ok( (all { is_Account($_) } @{$response}), 'List of Account');
  like $response->[0]->username, qr/b/i, 'a followed by b';
  like $response->[1]->username, qr/c/i, 'a followed by c';

  ok $response = $client->followers(2, {}), 'followers(Int, HashRef)';
  isa_ok $response, 'ARRAY';
  is scalar(@{$response}), 0, 'b has no followers';
}

# following
{
  use Mastodon::Types qw( is_Account );
  use List::Util qw( all );

  my $response;
  ok $response = $client->following(), 'following()';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Account($_) } @{$response}), 'List of Account');
  like $response->[0]->username, qr/c/i, 'a follows c';

  ok $response = $client->following(2), 'following(Int)';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Account($_) } @{$response}), 'List of Account');
  like $response->[0]->username, qr/a/i, 'b follows a';

  ok $response = $client->following({}), 'following(HashRef)';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Account($_) } @{$response}), 'List of Account');
  like $response->[0]->username, qr/c/i, 'a follows c';

  ok $response = $client->following(2, {}), 'following(Int, HashRef)';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Account($_) } @{$response}), 'List of Account');
  like $response->[0]->username, qr/a/i, 'b follows a';
}

# statuses
{
  use Mastodon::Types qw( is_Status );
  use List::Util qw( all );

  my $response;
  ok $response = $client->statuses(), 'statuses()';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Status($_) } @{$response}), 'List of Status');
  like $response->[0]->content, qr/#/i, 'Recent status has tag';
  like $response->[1]->content, qr/@/i, 'Recent status has mention';

  ok $response = $client->statuses(2), 'statuses(Int)';
  isa_ok $response, 'ARRAY';
  is scalar(@{$response}), 0, 'b has no statuses';

  ok $response = $client->statuses({}), 'statuses(HashRef)';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Status($_) } @{$response}), 'List of Status');
  like $response->[0]->content, qr/#/i, 'Recent status has tag';
  like $response->[1]->content, qr/@/i, 'Recent status has mention';

  ok $response = $client->statuses(2, {}), 'statuses(Int, HashRef)';
  isa_ok $response, 'ARRAY';
  is scalar(@{$response}), 0, 'b has no statuses';
}

# relationships
{
  use Mastodon::Types qw( is_Relationship );
  use List::Util qw( all );

  my $response;
  dies_ok { $client->relationships()   } 'relationships() dies';
  dies_ok { $client->relationships({}) } 'relationships(HashRef) dies';

  ok $response = $client->relationships(2),     'relationships(Int)';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Relationship($_) } @{$response}), 'List of Relationship');
  is scalar(@{$response}), 1, 'Requested one relationship';
  ok !$response->[0]->following, 'Not followed by b';

  ok $response = $client->relationships(2, 3),  'relationships(Int, Int)';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Relationship($_) } @{$response}), 'List of Relationship');
  is scalar(@{$response}), 2, 'Requested two relationships';
  ok !$response->[0]->following, 'Not followed by b';
  ok  $response->[1]->following, 'Followed by c';

  ok $response = $client->relationships(2, {}), 'relationships(Int, HashRef)';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Relationship($_) } @{$response}), 'List of Relationship');
  is scalar(@{$response}), 1, 'Requested one relationship';
  ok !$response->[0]->following, 'Not followed by b';
}

# search_accounts
{
  use Mastodon::Types qw( is_Account );
  use List::Util qw( all );

  my $response;
  dies_ok { $client->search_accounts()   } 'search_accounts() dies';
  dies_ok { $client->search_accounts({}) } 'search_accounts(HashRef) dies';
  dies_ok { $client->search_accounts('a', 'b') } 'search_accounts(Str, Str) dies';

  ok $response = $client->search_accounts('a'), 'search_accounts(Str)';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Account($_) } @{$response}), 'List of Account');
  is scalar(@{$response}), 1, 'Requested one relationship';
  like $response->[0]->username, qr/a/, 'Found self';

  ok $response = $client->search_accounts('a', {}), 'search_accounts(Str, HashRef)';
  isa_ok $response, 'ARRAY';
  ok( (all { is_Account($_) } @{$response}), 'List of Account');
  is scalar(@{$response}), 1, 'Requested one relationship';
  like $response->[0]->username, qr/a/, 'Found self';
}

undef $server;
done_testing();
