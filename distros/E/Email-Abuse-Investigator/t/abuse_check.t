#!/usr/bin/env perl
# =============================================================================
# t/abuse_check.t -- Black-box tests for bin/abuse_check
#
# Runs the script as a subprocess using IPC::Open3 so no SMTP connection
# is made and no network calls escape from the test harness.
# =============================================================================

use strict;
use warnings;
use Test::More;
use File::Temp  qw(tempfile);
use IPC::Open3  qw(open3);
use File::Spec;
use FindBin     qw($Bin);

my $SCRIPT = File::Spec->catfile($Bin, '..', 'bin', 'abuse_check');
$SCRIPT = File::Spec->catfile($Bin, '..', 'abuse_check')
	unless -f $SCRIPT;
my $PERL = $^X;
my $LIB  = File::Spec->catfile($Bin, '..', 'lib');

plan skip_all => "abuse_check not found at $SCRIPT"
	unless -f $SCRIPT;

# ---------------------------------------------------------------------------
# Helper: run the script with the given arguments
# Returns (stdout, stderr, exit_code)
# ---------------------------------------------------------------------------
sub run_script {
	my (@args) = @_;
	# Route child stderr to a temp file so the only IPC pipe is stdout.
	# Reading stdout then stderr sequentially from two pipes causes a
	# classic deadlock on Windows (small ~4 KB pipe buffer): the child
	# fills the stderr pipe while the parent blocks on stdout, and both
	# sides stall.  A file has no buffer limit so it never blocks.
	my ($err_fh, $err_path) = tempfile(SUFFIX => '.err', UNLINK => 1);
	my ($in, $out);
	my $pid = open3($in, $out, $err_fh,
		$PERL, "-I$LIB", $SCRIPT, @args);
	close $in;
	my $stdout = do { local $/; <$out> } // '';
	close $out;
	waitpid $pid, 0;
	my $exit = $? >> 8;
	seek $err_fh, 0, 0;
	my $stderr = do { local $/; <$err_fh> } // '';
	close $err_fh;
	return ($stdout, $stderr, $exit);
}

# Verify the script compiles cleanly.  Pass a non-existent file rather than
# reading from stdin: on Windows, closing the parent's write end of an
# anonymous pipe does not reliably signal EOF to the child's <STDIN> read,
# causing the script to block indefinitely.  A missing-file path causes an
# immediate croak after module load, which is all we need for a compile check.
{
	my ($out, $err, $exit) = run_script('/no/such/file.for.compile.check.eml');
	unlike $err, qr/syntax error/i, 'script compiles without syntax errors';
}

# ---------------------------------------------------------------------------
# Helper: write a minimal .eml to a temp file and return the path
# ---------------------------------------------------------------------------
sub make_eml {
	my ($fh, $path) = tempfile(SUFFIX => '.eml', UNLINK => 1);
	print $fh join("\r\n",
		'Received: from ext (ext [198.51.100.1]) by mx.example with ESMTP',
		'From: Spammer <spam@gmail.com>',
		'To: <victim@example.com>',
		'Subject: Test',
		'Date: Mon, 30 Mar 2026 12:00:00 +0000',
		'Message-ID: <test@example>',
		'',
		'Buy now!',
		'',
	);
	close $fh;
	return $path;
}

# ---------------------------------------------------------------------------
# 1. Valid .eml file: script produces a report and exits 0
# ---------------------------------------------------------------------------
subtest 'valid .eml file produces a report' => sub {
	# abuse_check calls report() which runs the full DNS/WHOIS pipeline.
	# These calls cannot be stubbed from outside the module process, and
	# IO::Select-based timeouts are unreliable on Windows, so the subtest
	# is skipped in any environment that prohibits live network calls.
	plan skip_all => 'NO_NETWORK_TESTING set; script makes real DNS/WHOIS calls'
		if $ENV{NO_NETWORK_TESTING};

	my $eml = make_eml();
	my ($out, $err, $exit) = run_script($eml);
	is $exit, 0, 'exit status 0 for valid email file';
	like $out, qr/abuse|report|ip|domain/i,
		'stdout contains abuse-report content';
};

# ---------------------------------------------------------------------------
# 2. Non-existent file: exits non-zero with an error message
# ---------------------------------------------------------------------------
subtest 'non-existent file exits non-zero' => sub {
	my ($out, $err, $exit) = run_script('/no/such/file.eml');
	ok $exit != 0, 'exit status non-zero for missing file';
};

# ---------------------------------------------------------------------------
# 3. Path traversal rejected
# ---------------------------------------------------------------------------
subtest 'path traversal in filename is rejected' => sub {
	# Strategy: the path validation regex rejects any path containing ../
	# before the file is opened, so neither Perl's open nor the filesystem
	# ever see the traversal attempt.
	my ($out, $err, $exit) = run_script('../../../etc/passwd');
	my $combined = $out . $err;
	ok $exit != 0, 'exit status non-zero for traversal path';
	like $combined, qr/traversal/i,
		'error message mentions traversal';
};

# NUL bytes in argv cannot be tested via subprocess: POSIX execve(2) uses
# NUL-terminated strings, so the OS truncates any argv element at the first
# NUL before the child process sees it.  The in-script guard is still useful
# when the script is invoked from Perl with a tainted variable.

done_testing();
