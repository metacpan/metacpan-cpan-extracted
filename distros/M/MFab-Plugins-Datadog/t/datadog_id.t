use strict;
use warnings;
use Test::More;
use Mojo::JSON qw(encode_json);
use MFab::Plugins::Datadog;

# Test that datadogId returns a value
my $id = MFab::Plugins::Datadog::datadogId();
ok(defined $id, 'datadogId returns a defined value');

# Test that the value is a number
like($id, qr/^-?\d+$/, 'datadogId returns a numeric value');

# Test Mojo::JSON serialization
my $json = encode_json({ id => $id });
like($json, qr/"id":-?\d+/, 'JSON encoded without quotes around the number');
unlike($json, qr/"id":"-?\d+"/, 'JSON encoded without string quotes');

# Test multiple calls produce different values
my $id2 = MFab::Plugins::Datadog::datadogId();
isnt($id, $id2, 'Multiple calls produce different values');

done_testing();
