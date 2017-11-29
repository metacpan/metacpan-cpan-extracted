use Test2::Bundle::Extended;
use Coro;
use Coro::AnyEvent;
use Ion;

sub upper { uc $_[0] }

ok my $server = Listen(\&upper), 'Listen';
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
$timeout->safe_cancel;

done_testing;
