use Test::More;

BEGIN {

  if ($ENV{GUARDIAN_API_KEY}) {
    plan tests => 29;
  } else {
    plan skip_all => 'Please set environment variable GUARDIAN_API_KEY';
  }

  use_ok('Guardian::OpenPlatform::API');
}

ok(my $client = Guardian::OpenPlatform::API->new(
  api_key => $ENV{GUARDIAN_API_KEY},
), 'Got client');
isa_ok($client, 'Guardian::OpenPlatform::API');

is($client->format, 'json', 'Default format correct');
isa_ok($client->ua, 'LWP::UserAgent');
is($client->api_key, $ENV{GUARDIAN_API_KEY}, 'API key correct');

eval { $client->content({
  qry => 'environment',
  mode => 'not a mode',
}); };

ok($@, 'Throws an exception');
like($@, qr/Invalid mode/, 'Throws the right exception');

my $resp = $client->content({
  qry => 'environment',
});

ok($resp, 'Got a response');
isa_ok($resp, 'HTTP::Response');
like($resp->header('Content-type'), qr/json/, 'Correct type - json');

$resp = $client->content({
  qry => 'environment',
  format => 'xml',
});

ok($resp, 'Got a response');
isa_ok($resp, 'HTTP::Response');
like($resp->header('Content-type'), qr/xml/, 'Correct type - xml');

$resp = $client->content({
  mode => 'tags',
});

ok($resp, 'Got a response');
isa_ok($resp, 'HTTP::Response');
like($resp->header('Content-type'), qr/json/, 'Correct type - json');

$resp = $client->content({
  mode => 'search',
  qry => 'environment',
  filter => '/society',
});

ok($resp, 'Got a response');
isa_ok($resp, 'HTTP::Response');
like($resp->header('Content-type'), qr/json/, 'Correct type - json');

$resp = $client->content({
  mode => 'search',
  qry => 'environment',
  filter => ['/society', '/global/comment' ],
});

ok($resp, 'Got a response');
isa_ok($resp, 'HTTP::Response');
like($resp->header('Content-type'), qr/json/, 'Correct type - json');

$resp = $client->content({
  mode => 'tags',
  qry => 'environment',
});

ok($resp, 'Got a response');
isa_ok($resp, 'HTTP::Response');
like($resp->header('Content-type'), qr/json/, 'Correct type - json');

$resp = $client->content({
  mode => 'tags',
  format => 'xml',
  qry => 'environment',
});

ok($resp, 'Got a response');
isa_ok($resp, 'HTTP::Response');
like($resp->header('Content-type'), qr/xml/, 'Correct type - xml');
