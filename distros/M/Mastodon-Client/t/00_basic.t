use Test2::V0;

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

is $client->scopes, [qw( read write )], 'Correct scopes';

$client = Mastodon::Client->new;

is $client->name, undef, 'Name has no default';

is $client->scopes, ['read'],
  'Scopes default to read only';

like $client->instance->uri, qr/mastodon\.social/,
  'Instance defaults to mastodon.social';

done_testing();
