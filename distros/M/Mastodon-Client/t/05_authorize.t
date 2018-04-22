use Test2::V0;

use Mastodon::Client;

my $client = Mastodon::Client->new();

like dies { $client->authorize; },
    qr/cannot authorize client without/i,
    'Cannot authorize a client without ID and secret';

$client = Mastodon::Client->new(
    client_id     => 'id',
    client_secret => 'secret',
    access_token  => 'token',
);

# ok warning { $client->authorize; }, 'Warns if access_token already exists';

done_testing();
