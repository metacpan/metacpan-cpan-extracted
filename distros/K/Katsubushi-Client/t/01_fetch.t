use strict;
use Test::More 0.98;
use Test::TCP;
use Katsubushi::Client;

my $version = qx{katsubushi -version};
if (  $version !~ /katsubushi version:/  ) {
    Test::More::plan skip_all => "katsubushi is not installed.";
}

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        exec "katsubushi", "-port", $port, "-worker-id", 1;
    },
);

my $client = Katsubushi::Client->new({
    servers => ["localhost:" . $server->port],
});
my $id = $client->fetch;
ok $id;
explain $id;

done_testing;
