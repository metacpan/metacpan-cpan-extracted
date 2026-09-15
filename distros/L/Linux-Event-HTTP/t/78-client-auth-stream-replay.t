use v5.36;
use strict;
use warnings;

use Test::More;
use Uniform::HTTP::Auth;

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new;
my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    on_request => sub ($conn, $req, $res) {
        $res->status(401);
        $res->header('WWW-Authenticate', 'Basic realm="Members"');
        $res->body('AUTH');
    },
);

my $origin = 'http://127.0.0.1:' . $server->port;
my $auth = Uniform::HTTP::Auth->new(
    origin => $origin,
    schemes => ['basic'],
    credentials => {
        username => 'user',
        password => 'secret',
    },
);
my $client = Linux::Event::HTTP::Client->new(loop => $loop, auth => $auth);
my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 3,
    on_timer => sub ($timer) {
        die "streaming auth replay test timed out\n";
    },
);

my ($operation, $error, $response_hits, $complete_hits) = (undef, undef, 0, 0);
$operation = $client->post(
    "$origin/upload",
    headers => [ [ 'Content-Length', 4 ] ],
    stream_body => {},
    on_response => sub ($tx, $res) {
        ++$response_hits;
    },
    on_complete => sub ($tx) {
        ++$complete_hits;
    },
    on_error => sub ($tx, $message) {
        $error = $message;
        $guard->cancel;
        $client->close;
        $server->close;
        $loop->stop;
    },
);

$operation->request_body->complete('DATA');
$loop->run;

ok($operation->is_terminal, 'streaming authentication operation is terminal');
is($operation->state, 'error',
    'satisfiable challenge fails rather than replaying streaming producer');
is($operation->transaction_count, 1,
    'streaming authentication failure creates no retry Transaction');
is($operation->auth_retry_count, 0,
    'rejected streaming replay does not count as performed auth retry');
like($error // '', qr/streaming Request body because the producer is not replayable/,
    'error explains why automatic authentication retry was refused');
is($response_hits, 0,
    'intermediate satisfiable authentication challenge is not final on_response');
is($complete_hits, 0,
    'terminal authentication replay error does not report successful completion');

done_testing;
