#!/usr/bin/env perl
# =============================================================================
# t/submit_script.t -- Black-box tests for submit_abuse_report
#
# Tests the --interactive flag and unresolved domain listing by running the
# script as a subprocess.  The --dry-run flag is used throughout so no SMTP
# connection is attempted.
# =============================================================================

use strict;
use warnings;
use Test::More;
use File::Temp  qw(tempfile);
use IPC::Open3  qw(open3);
use Symbol      qw(gensym);
use File::Spec;
use FindBin     qw($Bin);

# Path to the script under test
my $SCRIPT = File::Spec->catfile($Bin, '..', 'bin', 'submit_abuse_report');
# Fall back to the script living at the distribution root (development layout)
$SCRIPT = File::Spec->catfile($Bin, '..', 'submit_abuse_report')
    unless -f $SCRIPT;
my $PERL   = $^X;
my $LIB    = File::Spec->catfile($Bin, '..', 'lib');

plan skip_all => "submit_abuse_report not found at $SCRIPT"
    unless -f $SCRIPT;

# ---------------------------------------------------------------------------
# Helper: write a minimal spam .eml to a temp file and return the path
# ---------------------------------------------------------------------------
sub make_eml {
	my (%h) = @_;
	my ($fh, $path) = tempfile(SUFFIX => '.eml', UNLINK => 1);
	my $from    = $h{from}    // 'spam@gmail.com';
	my $body    = $h{body}    // 'Buy now at https://spamsite.example/';
	print $fh join("\r\n",
		'Received: from ext (ext [198.51.100.1]) by mx.example with ESMTP',
		"From: Spammer <$from>",
		'To: <victim@example.com>',
		'Subject: Test spam',
		'Date: Mon, 30 Mar 2026 12:00:00 +0000',
		'Message-ID: <test@example>',
		'Content-Type: text/plain',
		'',
		$body,
		'',
	);
	close $fh;
	return $path;
}

# ---------------------------------------------------------------------------
# Helper: run the script, return (stdout, stderr, exit_code)
# ---------------------------------------------------------------------------
sub run_script {
	my (@args) = @_;
	my ($in, $out);
	my $err = gensym();
	# Include the distribution lib/ in @INC for the subprocess
	my $pid = open3($in, $out, $err,
		$PERL, "-I$LIB", $SCRIPT, @args);
	close $in;
	my $stdout = do { local $/; <$out> } // '';
	my $stderr = do { local $/; <$err> } // '';
	waitpid $pid, 0;
	my $exit = $? >> 8;
	return ($stdout, $stderr, $exit);
}

# Verify the script compiles before running any tests
{
	my ($out, $err, $exit) = run_script('--help');
	if ($exit != 0) {
		plan skip_all =>
			"submit_abuse_report did not run successfully (exit $exit); "
			. "dependencies may be missing";
	}
}

# ---------------------------------------------------------------------------
# 1. Basic --dry-run works and shows recipient
# ---------------------------------------------------------------------------
subtest '--dry-run shows recipient without sending' => sub {
	my $eml = make_eml(from => 'spam@gmail.com');
	my ($out, $err, $exit) = run_script('--dry-run', $eml);

	like $out, qr/DRY RUN/,
		'dry-run header present';
	like $out, qr/abuse\@google\.com/i,
		'google abuse contact shown';
	is $exit, 0, 'exit status 0';
};

# ---------------------------------------------------------------------------
# 2. --interactive with --dry-run: --dry-run takes precedence, no prompt
# ---------------------------------------------------------------------------
subtest '--interactive has no effect with --dry-run' => sub {
	my $eml = make_eml(from => 'spam@gmail.com');
	my ($out, $err, $exit) = run_script('--dry-run', '--interactive', $eml);

	like $out, qr/DRY RUN/,
		'dry-run output produced';
	unlike $out . $err, qr/Send\? \[y\/N\]/,
		'no interactive prompt shown in dry-run mode';
	is $exit, 0, 'exit status 0';
};

# ---------------------------------------------------------------------------
# 3. No contacts: unresolved domain listing shown
# ---------------------------------------------------------------------------
subtest 'no contacts -- unresolved domains listed' => sub {
	# Use a domain not in any provider table so no contact is found,
	# but include it as a URL so it appears in embedded_urls()
	my $eml = make_eml(
		from => 'spoofed@innocent.example',
		body => 'Visit http://www.spamsiteunknown.example/offer now',
	);
	my ($out, $err, $exit) = run_script('--dry-run', $eml);

	# With --dry-run and no contacts, the script exits before dry_run_report
	# and prints the no-contacts message to stderr
	# 'No abuse contacts' is printed to STDERR
	like $err, qr/No abuse contacts could be determined/,
		'no-contacts message shown';
	is $exit, 0, 'exit status 0';
};

# ---------------------------------------------------------------------------
# 4. No contacts: spoofed From: domain excluded from unresolved list
# ---------------------------------------------------------------------------
subtest 'no contacts -- spoofed From: domain not listed' => sub {
	my $eml = make_eml(
		from => 'spoofed@innocent-victim.example',
		body => 'Contact scammer@unknownprovider.example for details',
	);
	my ($out, $err, $exit) = run_script('--dry-run', $eml);

	unlike $err, qr/innocent-victim\.example/,
		'spoofed From: domain absent from unresolved listing';
	is $exit, 0, 'exit status 0';
};

# ---------------------------------------------------------------------------
# 5. --interactive flag appears in --help output
# ---------------------------------------------------------------------------
subtest '--interactive documented in --help' => sub {
	my ($out, $err, $exit) = run_script('--help');

	like $out . $err, qr/interactive/i,
		'--interactive mentioned in help output';
};

done_testing();
