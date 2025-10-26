use Test2::V0;

use GD::Barcode::QRcode;

# Test basic QRcode object creation
my $qr1 = GD::Barcode::QRcode->new('1234567');
ok($qr1, 'QRcode object creation with numeric text');
is(ref($qr1), 'GD::Barcode::QRcode', 'Object is correct type');
is($qr1->{text}, '1234567', 'Text is stored correctly');

# Test with different text types
my $qr2 = GD::Barcode::QRcode->new('Hello World!');
ok($qr2, 'QRcode object creation with alphanumeric text');

my $qr3 = GD::Barcode::QRcode->new('https://example.com/test?param=value');
ok($qr3, 'QRcode object creation with URL (8-bit mode)');

# Test with parameters
my $qr4 = GD::Barcode::QRcode->new('Test', {Ecc => 'M', ModuleSize => 2});
ok($qr4, 'QRcode object creation with parameters');
is($qr4->{Ecc}, 'M', 'Error correction level is set correctly');
is($qr4->{ModuleSize}, 2, 'Module size is set correctly');

# Test invalid error correction level (should be normalized)
my $qr5 = GD::Barcode::QRcode->new('Test', {Ecc => 'X'});
ok($qr5, 'QRcode handles invalid Ecc parameter');
is($qr5->{Ecc}, 'M', 'Invalid Ecc is normalized to M');

# Test barcode pattern generation (should work without GD)
my $pattern = $qr1->barcode();
ok($pattern, 'Barcode pattern generation works');
like($pattern, qr/^[01\s]+$/, 'Pattern contains only 0s, 1s, and whitespace');
ok(length($pattern) > 0, 'Pattern is not empty');

# Test pattern structure
my @lines = split(/\n/, $pattern);
ok(scalar(@lines) > 10, 'Pattern has multiple lines');
ok(length($lines[0]) > 10, 'Each line has reasonable length');

# Test edge cases
my $qr_empty = GD::Barcode::QRcode->new('');
ok($qr_empty, 'Empty text creates valid QRcode object');
my $empty_pattern = $qr_empty->barcode();
ok($empty_pattern, 'Empty text still generates a pattern');

done_testing;