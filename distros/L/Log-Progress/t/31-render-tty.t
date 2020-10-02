#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use File::Temp;
use IO::File;
use Time::HiRes 'sleep';

use_ok 'Log::Progress::Parser'
and use_ok 'Log::Progress::RenderTTY'
	or BAIL_OUT;

my @tests= (
	[ 'plain progress', <<'END', qr/50%.*\n.*\(testing\)/ ],
progress: 5/10 (testing)
END
	[ 'one step', <<'END', qr/Do a Thing.*50%.*Half Way Through Step.*\n\s*\n.*25%.*\n\s*$/ ],
progress: s1 (.5) Do a Thing
progress: s1 .5 Half Way Through Step
END
	[ 'several steps', <<'END', qr/Thing1.*100%.*Thing2.*100%.*Thing3.*50%.*Thing4.*10%.*\(2\/20\).*Thing5.*100%.*72%/s ],
progress: s1 (.2) Thing1
progress: s2 (.2) Thing2
progress: s1 .5
progress: s1 .7
progress: s2 .1
progress: s3 (.2) Thing3
progress: s3 6/20
progress: s1 1
progress: s2 1
progress: s4 (.2) Thing4
progress: s4 .2
progress: s3 .5
progress: s4 1/20
progress: s5 (.2) Thing5
progress: s5 1
progress: s4 2/20
END

);

# First, test the formatting, which is isolated from terminal detection issues
my $renderer= Log::Progress::RenderTTY->new();
for (@tests) {
	my ($name, $in, $out_pattern)= @$_;
	my $parser= Log::Progress::Parser->new(input => $in);
	my $state= $parser->parse;
	my $text= $renderer->format($parser->parse, { cols => 80, rows => 50 });
	like( $text, $out_pattern, $name );
}

SKIP: {
	skip "No TERM defined", 1 unless $ENV{TERM};
	# Now test 'render', which might emit some warnings if it can't detect terminal
	# type or dimensions.  (but it should only warn, and not fail)
	open my $save_stdout, '>&', \*STDOUT or die $!;
	close STDOUT;
	open STDOUT, '>', \my $capture_stdout or die $!;

	open my $save_stderr, '>&', \*STDERR or die $!;
	close STDERR;
	open STDERR, '>', \my $capture_stderr or die $!;

	my $err;
	try {
		my $parser= Log::Progress::Parser->new(input => $tests[-1][1]);
		$renderer->parser($parser);
		$renderer->render;
	} catch { chomp($err= $_) };

	close STDOUT;
	open STDOUT, '>&', $save_stdout or die $!;

	close STDERR;
	open STDERR, '>&', $save_stderr or die $!;

	note "Exception: $err" if defined $err;
	note "STDERR: $capture_stderr" if length $capture_stderr;
	like( $capture_stdout, $tests[-1][2], 'rendered to stdout' );
}

done_testing;
