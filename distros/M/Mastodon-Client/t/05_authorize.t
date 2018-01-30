use strict;
use warnings;

use Test::Exception;
use Test::More;

use Mastodon::Client;

my $client = Mastodon::Client->new();

dies_ok { $client->authorize; }
  'Cannot authorize a client without ID and secret';

$client = Mastodon::Client->new(
    client_id     => 'id',
    client_secret => 'secret',
    access_token  => 'token',
);

# ok warning { $client->authorize; }, 'Warns if access_token already exists';

done_testing();
