#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for Fugu::TestLog, the quiet process default logger

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use Fugu::Log;
use Fugu::TestLog;

# capture_stderr($code):
#	Run $code with standard error redirected to a string.
sub capture_stderr ($code)
{
	my $captured = '';
	open my $saved, '>&', \*STDERR or die "dup STDERR: $!";
	close STDERR;
	open STDERR, '>', \$captured or die "reopen STDERR: $!";
	$code->();
	close STDERR;
	open STDERR, '>&', $saved or die "restore STDERR: $!";
	close $saved;

	return $captured;
}

subtest 'the import sets a quiet default' => sub {
	my $output = capture_stderr(
		sub { Fugu::Log->default->error('dropped message') } );
	is( $output, '', 'the default drops a message' );
};

subtest 'stderr puts the noisy default back' => sub {
	Fugu::TestLog->stderr;
	my $output = capture_stderr(
		sub { Fugu::Log->default->error('visible message') } );
	like( $output, qr/visible message/, 'the default reports again' );

	Fugu::TestLog->quiet;
	$output = capture_stderr(
		sub { Fugu::Log->default->error('dropped again') } );
	is( $output, '', 'quiet drops messages again' );
};

done_testing();
