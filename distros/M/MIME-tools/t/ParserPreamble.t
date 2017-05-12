#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 7;
use Test::Deep;

my %files = (
	'testmsgs/empty-preamble.msg' => [ '' ],
	'testmsgs/multi-simple.msg'   => [
		"This is the preamble.  It is to be ignored, though it\n",
		"is a handy place for mail composers to include an\n",
		"explanatory note to non-MIME conformant readers."
	],
	'testmsgs/ticket-60931.msg'   => [ ],
);

#-- Load MIME::Parser
use_ok("MIME::Parser");

#-- Prepare parser
my $parser = MIME::Parser->new();
$parser->output_to_core(1);
$parser->decode_bodies(0);

foreach my $file (keys %files) {
	#-- Parse quoted-printable encoded file
	open (my $fh, $file)
		or die "can't open testmsgs/empty-preamble.msg: $!";
	my $entity = $parser->parse($fh);

	$fh->seek(0,0);
	my $expected = do { local $/; <$fh> };
	close $fh;

	cmp_deeply( $entity->preamble(), $files{$file}, 'Preamble is as expected');

	is( $entity->as_string(), $expected, 'File with preamble roundtripped correctly');
}

1;
