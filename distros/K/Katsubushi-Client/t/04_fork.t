use strict;
use Test::More 0.98;
use Test::TCP;
use Test::SharedFork;
use Katsubushi::Client;

my $version = qx{katsubushi -version};
if (  $version !~ /katsubushi version:/  ) {
    Test::More::plan skip_all => "katsubushi is not installed.";
}

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        exec "katsubushi", "-port", $port, "-worker-id", 1, "-log-level", "debug";
    },
);

my $client = Katsubushi::Client->new({
    servers => ["localhost:" . $server->port],
});
my $id = $client->fetch;
ok $id;
explain $id;

my $pid = fork();
if ($pid == 0) {
    Test::SharedFork->child;
    my $id2 = $client->fetch;
    ok $id2;
}
elsif (defined $pid) {
    Test::SharedFork->parent;
    waitpid $pid, 0;
    my $id3 = $client->fetch;
    ok $id3;
    done_testing;
} else {
    die "Cannot fork: $!";
};

