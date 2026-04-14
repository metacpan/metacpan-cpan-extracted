use strict;
use warnings;
use Test::More;

use Enum::Declare;

# declare all enums up front in main
enum Color { Red, Green, Blue };
enum Level :Str { Debug, Info, Warn };
enum Perm :Flags { Read, Write, Execute };

subtest 'exhaustive match' => sub {
	my $meta = Color();

	my $result = $meta->match(0, {
		Red   => sub { 'red' },
		Green => sub { 'green' },
		Blue  => sub { 'blue' },
	});
	is($result, 'red', 'match Red returns "red"');

	$result = $meta->match(2, {
		Red   => sub { 'r' },
		Green => sub { 'g' },
		Blue  => sub { 'b' },
	});
	is($result, 'b', 'match Blue returns "b"');
};

subtest 'handler receives value' => sub {
	my $meta = Color();

	my $result = $meta->match(1, {
		Red   => sub { $_[0] * 10 },
		Green => sub { $_[0] * 10 },
		Blue  => sub { $_[0] * 10 },
	});
	is($result, 10, 'handler receives value as argument');
};

subtest 'non-exhaustive match dies' => sub {
	my $meta = Color();

	eval {
		$meta->match(0, {
			Red  => sub { 'r' },
			Blue => sub { 'b' },
		});
	};
	like($@, qr/Non exhaustive match for Color: missing Green/,
		'dies with missing variant');

	eval {
		$meta->match(0, {
			Red => sub { 'r' },
		});
	};
	like($@, qr/Non exhaustive match for Color: missing Green, Blue/,
		'lists all missing variants');
};

subtest 'wildcard default' => sub {
	my $meta = Color();

	my $result = $meta->match(0, {
		Red => sub { 'stop' },
		_   => sub { 'go' },
	});
	is($result, 'stop', 'matched variant takes priority');

	$result = $meta->match(1, {
		Red => sub { 'stop' },
		_   => sub { 'go' },
	});
	is($result, 'go', 'unmatched variant falls to _');

	$result = $meta->match(99, {
		Red => sub { 'stop' },
		_   => sub { "unknown: $_[0]" },
	});
	is($result, 'unknown: 99', 'catches unknown values');
};

subtest 'unknown value without wildcard dies' => sub {
	my $meta = Color();

	eval {
		$meta->match(99, {
			Red   => sub { 'r' },
			Green => sub { 'g' },
			Blue  => sub { 'b' },
		});
	};
	like($@, qr/No match for value '99' in Color/, 'dies for unknown value');
};

subtest 'string enum match' => sub {
	my $meta = Level();

	my $result = $meta->match('info', {
		Debug => sub { 0 },
		Info  => sub { 1 },
		Warn  => sub { 2 },
	});
	is($result, 1, 'string enum match works');
};

subtest 'flags enum match' => sub {
	my $meta = Perm();

	my $result = $meta->match(2, {
		Read    => sub { 'r' },
		Write   => sub { 'w' },
		Execute => sub { 'x' },
	});
	is($result, 'w', 'flags enum match works');
};

done_testing();
