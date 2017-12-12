use Test2::Bundle::Extended;
use Coro;
use Coro::AnyEvent;
use Ion;

ok my $server = Service { uc $_[0] }, 'Server';
ok my $conn   = Connect($server->host, $server->port), 'Connect';

my $timeout = async {
  Coro::AnyEvent::sleep 10;
  $server->stop;
};

ok $conn->('hello world'), 'conn->(msg)';
is <$conn>, 'HELLO WORLD', '<conn>';

ok $conn->('how now brown bureaucrat'), 'conn->(msg)';
is <$conn>, 'HOW NOW BROWN BUREAUCRAT', '<conn>';

ok $conn->close, 'conn: close';

ok $server->stop, 'server: stop';
ok $server->join, 'server: join';

$timeout->safe_cancel;

done_testing;
