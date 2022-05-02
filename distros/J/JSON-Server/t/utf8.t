# This tests downgrading and upgrading of character strings.

use FindBin '$Bin';
use lib "$Bin";
use JST;

my $port = empty_port ();
my $pid = fork ();
if ($pid) {
    sleep (1);
    my $babi = {"場" => "ビ"};
    my $client = JSON::Client->new (port => $port);
    my $reply = $client->send ($babi);
    utf8_check ($reply);
    $client->send ({'JSON::Server::control' => 'stop'});
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

done_testing ();
exit;
