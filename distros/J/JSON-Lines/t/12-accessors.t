use Test::More;

use JSON::Lines;

my $jsonl = JSON::Lines->new();

# Test pretty accessor
ok(!$jsonl->pretty, 'pretty defaults to false');
$jsonl->pretty(1);
ok($jsonl->pretty, 'pretty set to true');
my $encoded = $jsonl->encode([{ a => 1 }]);
like($encoded, qr/\n.*\n/, 'pretty output has newlines');
$jsonl->pretty(0);
ok(!$jsonl->pretty, 'pretty set back to false');

# Test canonical accessor
ok(!$jsonl->canonical, 'canonical defaults to false');
$jsonl->canonical(1);
ok($jsonl->canonical, 'canonical set to true');
my $canonical_out = $jsonl->encode([{ z => 1, a => 2, m => 3 }]);
like($canonical_out, qr/"a".*"m".*"z"/, 'canonical output is sorted');
$jsonl->canonical(0);

# Test utf8 accessor
ok(!$jsonl->utf8, 'utf8 defaults to false');
$jsonl->utf8(1);
ok($jsonl->utf8, 'utf8 set to true');
$jsonl->utf8(0);
ok(!$jsonl->utf8, 'utf8 set back to false');

# Test parse_headers accessor
ok(!$jsonl->parse_headers, 'parse_headers defaults to false');
$jsonl->parse_headers(1);
ok($jsonl->parse_headers, 'parse_headers set to true');
$jsonl->parse_headers(0);
ok(!$jsonl->parse_headers, 'parse_headers set to false');

# Test error_cb accessor
is($jsonl->error_cb, undef, 'error_cb defaults to undef');
my $error_cb = sub { return 'error handled' };
$jsonl->error_cb($error_cb);
is($jsonl->error_cb, $error_cb, 'error_cb set to coderef');
$jsonl->error_cb(undef);
is($jsonl->error_cb, undef, 'error_cb set back to undef');

# Test success_cb accessor
is($jsonl->success_cb, undef, 'success_cb defaults to undef');
my $success_cb = sub { return 'success' };
$jsonl->success_cb($success_cb);
is($jsonl->success_cb, $success_cb, 'success_cb set to coderef');
$jsonl->success_cb(undef);
is($jsonl->success_cb, undef, 'success_cb set back to undef');

# Test chaining
my $chained = $jsonl->pretty(1)->canonical(1)->utf8(0);
is($chained, $jsonl, 'setters return $self for chaining');
ok($jsonl->pretty, 'chained pretty is set');
ok($jsonl->canonical, 'chained canonical is set');

# Reset for other tests
$jsonl->pretty(0)->canonical(0);

done_testing();
