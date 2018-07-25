use Test2::V0;
use Ion::Test;
use Coro;
use Coro::AnyEvent;
use Coro::Handle qw(unblock);
use AnyEvent::Util qw(portable_pipe);
use JSON::XS qw(encode_json decode_json);
use Ion;

subtest 'basics' => sub{
  my $server = Service{ uc $_[0] };

  ok $server, 'Server'
    or bail_out 'failed to bind service';

  my $conn;
  ok lives{ $conn = Connect('localhost', $server->port) }, 'Connect';

  ok $conn->connect, 'conn->connect'
    or bail_out sprintf('failed to connect to host %s:%s', $server->host || 'undef', $server->port || 'undef');

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
