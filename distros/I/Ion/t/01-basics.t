use Test2::Bundle::Extended;
use Coro;
use Coro::AnyEvent;
use Coro::Handle qw(unblock);
use AnyEvent::Util qw(portable_pipe);
use JSON::XS qw(encode_json decode_json);
use Ion;

subtest 'basics' => sub{
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
};

subtest 'wrapping handles' => sub{
  my $timeout = async {
    Coro::AnyEvent::sleep 10;
    die 'timed out';
  };

  my ($r, $w) = portable_pipe;
  my $in  = Connect(unblock($r)) << \&decode_json;
  my $out = Connect(unblock($w)) >> \&encode_json;

  ok $out->(['foo', 'bar']), 'pipe: out';
  is <$in>, ['foo', 'bar'],  'pipe: in';

  $timeout->safe_cancel;
};

done_testing;
