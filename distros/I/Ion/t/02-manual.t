use Test2::V0;
use Ion::Test;
use Coro;
use Coro::AnyEvent;
use Ion;

ok my $server = Listen, 'Listen';
$server->start;

ok my $conn = Connect('localhost', $server->port), 'Connect';

my $service = async {
  while (my $client = <$server>) {
    while (my $msg = <$client>) {
      $client->(uc($msg));
    }
  }
};

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
