# Make sure array references are OK

use FindBin '$Bin';
use lib "$Bin";
use JST;

my $in = [qw!monster baby!];

# This failure:
# http://www.cpantesters.org/cpan/report/5cceb166-6d3a-11eb-9f75-d8046d6b008a
# is odd, but probably due to simultaneous with utf8-server.t which
# was using the same port number before.

my $port = empty_port ();
my $pid = fork ();
my $rt; # round trip
if ($pid) {
    my $client = JSON::Client->new (port => $port);
    sleep (1);
    $rt = $client->send ($in);
    sleep (1);
    my $reply = $client->send ({'JSON::Server::control' => 'stop'});
    waitpid ($pid, 0);
}
else {
    my $server = JSON::Server->new (
	port => $port,
	handler => \&JSON::Server::echo,
    );
    $server->serve ();
    exit;
}
is_deeply ($rt, $in, "Sent an array reference");
done_testing ();
