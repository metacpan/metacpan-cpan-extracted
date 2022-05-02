# This tests downgrading and upgrading of character strings in the
# server.  Because this forks, we do two tests of essentially the same
# code.

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
    $client->send ({'JSON::Server::control' => 'stop'});
    waitpid ($pid, 0);
    exit;
}
else {
    my $server = JSON::Server->new (
	port => $port,
	handler => \&shmandler,
    );
    $server->serve ();
}

done_testing ();
exit;

sub shmandler
{
    my (undef, $input) = @_;
    utf8_check ($input);
    return $input;
}
