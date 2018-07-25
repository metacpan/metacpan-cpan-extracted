use Test2::V0;
use Ion::Test;
use Coro;
use Coro::AnyEvent;
use Storable qw(freeze thaw);
use MIME::Base64 qw(encode_base64 decode_base64);
use Ion;

my $message = {foo => 'bar', baz => [1, 2, qq{
bat
  bat
    bat
      bat
    bat
  bat
bat
}]};

my ($request, $response);

my $server = Service{ $request = $_[0] }
  >> sub{ freeze(shift) } >> sub{ encode_base64(shift, '') }
  << sub{ decode_base64(shift) } << sub{ thaw(shift) };

my $client = Connect('localhost', $server->port);
$client >>= sub{ freeze(shift) };
$client >>= sub{ encode_base64(shift, '') };
$client <<= sub{ decode_base64(shift) };
$client <<= sub{ thaw(shift) };

my $timeout = async {
  Coro::AnyEvent::sleep 10;
  $server->stop;
};

$client->($message);
$response = <$client>;
$client->close;
$server->stop;

is $request,  $message, 'request in expected format';
is $response, $message, 'response in expected format';

done_testing;
