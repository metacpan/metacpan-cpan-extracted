# This is a test for module JSON::Server.

use FindBin '$Bin';
use lib "$Bin";
use JST;

use_ok ('JSON::Server');

use JSON::Server;
use JSON::Client;

my $verbose = undef;
my $pid = fork ();
my $port = '9999';
if ($pid) {
    # Give the server some time to start.
    sleep (1);
    # Parent process
    ok ($pid, "Started a server at $pid");
    my $client = JSON::Client->new (port => $port, verbose => $verbose);
    my $reply = $client->send ({'JSON::Server::control' => 'stop'});
    ok ($reply, "Got reply from server");
    is ($reply->{'JSON::Server::response'}, 'stopping', "Got stopping reply");
    waitpid ($pid, 0);
}
else {
    # Child process
    my $server = JSON::Server->new (port => $port, verbose => $verbose);
    $server->serve ();
    exit;
}
ok (1, "Started and halted server");

done_testing ();
# Local variables:
# mode: perl
# End:
