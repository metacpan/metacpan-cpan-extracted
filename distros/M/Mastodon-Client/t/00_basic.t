use strict;
use warnings;

use Test::More;

use Mastodon::Client;

my $client = Mastodon::Client->new(
    instance      => 'mastodon.cloud',
    name          => 'JJ',
    client_id     => 'id',
    client_secret => 'secret',
    access_token  => 'token',
    scopes        => [qw( read write )],
);


isa_ok( $client, 'Mastodon::Client' );

is $client->name, 'JJ', 'Correct name';

is_deeply $client->scopes, [qw( read write )], 'Correct scopes';

$client = Mastodon::Client->new;

is $client->name, undef, 'Name has no default';

is_deeply $client->scopes, ['read'],
  'Scopes default to read only';

like $client->instance->uri, qr/mastodon\.social/,
  'Instance defaults to mastodon.social';

done_testing();
