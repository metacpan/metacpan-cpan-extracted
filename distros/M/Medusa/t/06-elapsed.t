#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

our $file = 't/test.log';

plan tests => 4;
{
	package LALALA;

	use Medusa LOG_FILE => 't/test.log';

	sub new { bless {}, $_[0]; }

	sub audit :Audit {
		select(undef, undef, undef, 0.25);
		return 211;
	}
}

my $lalala = LALALA->new();
is($lalala->audit(0), 211, 'value check');

open my $fh, '<', $file or die $!;
my $content = do { local $/; <$fh> };
close $fh;
my @lines = split "\n", $content;

like($lines[0], qr/args/, 'args');
like($lines[1], qr/returned/, 'returns');
like($lines[1], qr/elapsed_call=†0.*/, 'elapsed');

unlink $file;

done_testing();
