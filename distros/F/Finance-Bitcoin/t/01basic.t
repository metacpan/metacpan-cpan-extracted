use Test::More tests => 2;
BEGIN { use_ok('Finance::Bitcoin') };

my $api = Finance::Bitcoin::API->new(
	endpoint => 'http://user:pass@www.example.com:1234/',
	);

is(
	$api->endpoint,
	'http://user:pass@www.example.com:1234/',
	'Accessors seem to work.',
	);

# There's not much else to do without a JSONRPC server to actually connect to.