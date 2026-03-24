#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 10;

use Medusa;

my $format = $Medusa::LOG{FORMAT_MESSAGE};
my $quote = $Medusa::LOG{QUOTE};

# basic message with no params
{
	my $out = $format->(
		message => 'simple test',
		prefix => 'arg',
		level => 'debug',
		params => [],
	);
	like($out, qr/DEBUG/, 'contains log level');
	like($out, qr/message=${quote}simple test${quote}/, 'contains message');
}

# message with scalar params
{
	my $out = $format->(
		message => 'sub called',
		prefix => 'arg',
		level => 'info',
		params => ['hello', 42],
	);
	like($out, qr/INFO/, 'info level');
	like($out, qr/arg0=${quote}.*hello/, 'first param formatted');
	like($out, qr/arg1=${quote}.*42/, 'second param formatted');
}

# message with elapsed time
{
	my $out = $format->(
		message => 'sub returned',
		prefix => 'return',
		level => 'debug',
		params => [7],
		elapsed => 123.456,
	);
	like($out, qr/elapsed=${quote}123\.456${quote}/, 'elapsed time included');
	like($out, qr/return0=${quote}.*7/, 'return value formatted');
}

# message with hash ref param
{
	my $out = $format->(
		message => 'hash test',
		prefix => 'arg',
		level => 'error',
		params => [{ key => 'value' }],
	);
	like($out, qr/ERROR/, 'error level');
	like($out, qr/key/, 'hash key present in output');
}

# timestamp is present
{
	my $out = $format->(
		message => 'time check',
		prefix => 'arg',
		level => 'debug',
		params => [],
	);
	like($out, qr/^\w{3}\s+\w{3}\s+\d+/, 'starts with timestamp');
}
done_testing();
