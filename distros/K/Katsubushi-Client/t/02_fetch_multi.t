use strict;
use Test::More 0.98;
use Test::TCP;
use Katsubushi::Client;
use version 0.77;

my $version = qx{katsubushi -version};
my ($v) = $version =~ /katsubushi version: ([\d.]+)/;
if ( !$v ) {
    Test::More::plan skip_all => "katsubushi is not installed.";
}
my $ver = version->parse($v);
my $enable_multi = version->parse("1.1.0");
if ($ver < $enable_multi) {
    Test::More::plan skip_all => "katsubushi $v do not support get_multi.";
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
my @id = $client->fetch_multi(10);
is scalar @id, 10;
for my $id (@id) {
    ok $id;
}
explain \@id;

done_testing;
