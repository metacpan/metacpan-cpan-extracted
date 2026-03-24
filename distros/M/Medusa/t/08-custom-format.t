#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

our $file = 't/test-format.log';

plan tests => 6;

{
	package TestFormat;

	use Medusa (
		LOG_FILE => 't/test-format.log',
		FORMAT_MESSAGE => sub {
			my %params = @_;
			return sprintf("CUSTOM|%s|%s",
				$params{level},
				$params{message},
			);
		},
	);

	sub new { bless {}, $_[0]; }

	sub greet :Audit {
		my ($self, $name) = @_;
		return "hello $name";
	}
}

my $obj = TestFormat->new();
my $result = $obj->greet('world');
is($result, 'hello world', 'audited sub returns correct value');

open my $fh, '<', $file or die $!;
my $content = do { local $/; <$fh> };
close $fh;

my @lines = split "\n", $content;

like($lines[0], qr/^CUSTOM\|/, 'custom format applied to call log');
like($lines[0], qr/\|debug\|/, 'custom format includes level');
like($lines[0], qr/called with args/, 'custom format includes call message');
like($lines[1], qr/^CUSTOM\|/, 'custom format applied to return log');
like($lines[1], qr/returned/, 'custom format includes return message');

unlink $file;

done_testing();
