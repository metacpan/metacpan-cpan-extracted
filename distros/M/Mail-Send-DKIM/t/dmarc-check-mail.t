#!/usr/bin/env perl
#
# dmarc-check-mail.pl is the "does mail from this host authenticate?" tester:
# it signs one message and either prints it or hands it to sendmail, so that a
# mailbox you can read shows what receivers make of this host's mail.
#
# The key pair is made at run time, so no key material lives in the repository,
# and the public half is served to the verifier through a stubbed DNS lookup
# rather than being published anywhere.  What is under test is the programme's
# own behaviour: the signature it prints, the absence of one under --plain, and
# what it says when there is no key to sign with.

use strict;
use warnings;

use Test::Most;
use Test::Needs;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);

my $SCRIPT = File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'dmarc-check-mail.pl');

BAIL_OUT("Cannot find $SCRIPT") unless(-r $SCRIPT);

# What signing and verifying need; the suite is skipped, not failed, without them.
test_needs qw(Mail::DKIM::Signer Mail::DKIM::Verifier Mail::DKIM::DNS Net::DNS::RR);

my $openssl;
foreach my $dir (File::Spec->path()) {
	my $candidate = File::Spec->catfile($dir, 'openssl');
	if(-x $candidate) {
		$openssl = $candidate;
		last;
	}
}
plan skip_all => 'openssl is needed to make a key pair' unless($openssl);

my $TMP = tempdir(CLEANUP => 1);

# One HOME with a key in the place the programme looks first, and one with
# nothing, so that "found by itself" and "found nothing" are both real.
my $HOME = File::Spec->catdir($TMP, 'home');
my $KEYS = File::Spec->catdir($HOME, 'dkim');
my $EMPTY_HOME = File::Spec->catdir($TMP, 'empty-home');
make_path($KEYS, $EMPTY_HOME) or BAIL_OUT("Cannot make the test directories: $!");

my $KEY = File::Spec->catfile($KEYS, 'selector1.private');
my $DEVNULL = File::Spec->devnull;
system(qq{"$openssl" genrsa -out "$KEY" 2048 2>"$DEVNULL"}) == 0
	or BAIL_OUT("openssl could not make $KEY");

# The public half, as the TXT record at <selector>._domainkey.<domain> would
# carry it: base64 of the SubjectPublicKeyInfo, with the PEM markers gone.
# Made once - every verification asks the same question.
my @TXT_RECORD;

sub txt_record
{
	unless(@TXT_RECORD) {
		open(my $pipe, '-|', qq{"$openssl" rsa -in "$KEY" -pubout 2>"$DEVNULL"})
			or BAIL_OUT("Cannot run openssl: $!");
		my $pem = do { local $/; <$pipe> };
		close($pipe);
		BAIL_OUT("openssl could not read $KEY") unless($pem =~ /KEY-----/);

		$pem =~ s/-----[^-]+-----//g;
		$pem =~ s/\s+//g;
		my $record = 'v=DKIM1; k=rsa; p=' . $pem;
		for(my $offset = 0; $offset < length($record); $offset += 255) {
			push @TXT_RECORD, substr($record, $offset, 255);
		}
	}

	return @TXT_RECORD;
}

# A receiving site hashes the message in its CRLF form, which is what the
# sending MTA puts on the wire, so what the programme signs is verified the
# same way: after the line endings an MTA would have converted.
sub verify_signature
{
	my $message = shift;

	$message =~ s/\r\n/\n/g;
	$message =~ s/\n/\r\n/g;

	my @chunks = txt_record();

	no warnings qw(once redefine);
	local *Mail::DKIM::DNS::query = sub {
		return Net::DNS::RR->new(type => 'TXT', txtdata => \@chunks);
	};

	my $verifier = Mail::DKIM::Verifier->new();
	$verifier->PRINT($message);
	$verifier->CLOSE;

	return $verifier->result;
}

sub slurp
{
	my $path = shift;

	local $/;
	open(my $fh, '<', $path) or return '';
	my $text = <$fh>;
	close($fh);

	return $text;
}

# The programme reads nothing on stdin and writes a whole message to stdout, so
# a run is a process and three files.  The environment is built from scratch:
# a DKIM_KEYFILE or DMARC_TEST_* left over in the developer's shell would
# otherwise decide the outcome of a test about finding keys.
sub run_script
{
	my ($home, @args) = @_;

	my $out = File::Spec->catfile($TMP, 'stdout.txt');
	my $err = File::Spec->catfile($TMP, 'stderr.txt');

	my $pid = fork();
	die "fork: $!" unless(defined($pid));

	if(!$pid) {
		foreach my $name (qw(DKIM_KEYFILE SENDMAIL DMARC_TEST_TO DMARC_TEST_FROM
				DMARC_TEST_DOMAIN DMARC_TEST_SELECTOR)) {
			delete($ENV{$name});
		}
		$ENV{'HOME'} = $home;
		open(STDIN, '<', File::Spec->devnull()) or exit 127;
		open(STDOUT, '>', $out) or exit 127;
		open(STDERR, '>', $err) or exit 127;
		exec($^X, $SCRIPT, @args) or exit 127;
	}

	waitpid($pid, 0);

	return ($? >> 8, slurp($out), slurp($err));
}

subtest '--dry-run prints a signed message, and the signature verifies' => sub {
	# No --keyfile: the key has to be found in ~/dkim by its selector, which
	# is the way the programme is meant to be used.
	my ($status, $out, $err) = run_script($HOME,
		'--dry-run', '--from' => 'alerts@example.org', '--to' => 'webmaster@example.org',
		'--domain' => 'example.org', '--selector' => 'selector1');

	is($status, 0, 'it exited 0');
	is($err, '', 'nothing on stderr') or diag($err);

	like($out, qr/\ADKIM-Signature: /, 'the message starts with the signature');
	like($out, qr/d=example\.org/, 'for the domain asked for');
	like($out, qr/s=selector1/, 'under the selector asked for');
	like($out, qr/^From: alerts\@example\.org$/m, 'and it is the message that was asked for');
	like($out, qr/^To: webmaster\@example\.org$/m, 'to the address asked for');
	like($out, qr/nothing was sent/, 'and it said nothing was sent');

	# The printed message is what the mailbox would have shown, so take it
	# back out of the output - the marker line is not part of it.
	(my $signed = $out) =~ s/\n--- .*\z//s;
	is(verify_signature($signed), 'pass', 'the signature verifies against the published key');
};

subtest '--keyfile signs with the key it names' => sub {
	# Run from a HOME with no key, so the only key in play is the one named.
	my ($status, $out, $err) = run_script($EMPTY_HOME,
		'--dry-run', '--keyfile' => $KEY, '--from' => 'alerts@example.org',
		'--domain' => 'example.org', '--selector' => 'selector1');

	is($status, 0, 'it exited 0');
	is($err, '', 'nothing on stderr') or diag($err);
	like($out, qr/\ADKIM-Signature: /, 'the message is signed');

	(my $signed = $out) =~ s/\n--- .*\z//s;
	is(verify_signature($signed), 'pass', 'and the signature verifies');
};

subtest '--plain prints a message with no signature at all' => sub {
	# Deliberately run with no key anywhere: --plain must not need one, since
	# it exists to show what the unsigned path looks like.
	my ($status, $out, $err) = run_script($EMPTY_HOME,
		'--plain', '--dry-run', '--from' => 'alerts@example.org', '--to' => 'webmaster@example.org');

	is($status, 0, 'it exited 0');
	is($err, '', 'and did not complain about the missing key') or diag($err);

	unlike($out, qr/DKIM-Signature/, 'there is no signature in it');
	like($out, qr/^From: alerts\@example\.org$/m, 'but the message is still there');
	like($out, qr/unsigned/, 'and it says the message went unsigned');
};

subtest 'with no key to be found it says so, and what to do about it' => sub {
	my ($status, $out, $err) = run_script($EMPTY_HOME,
		'--dry-run', '--from' => 'alerts@example.org', '--to' => 'webmaster@example.org');

	isnt($status, 0, 'it failed rather than printing an unsigned message');
	is($out, '', 'so no message was printed');

	like($err, qr/No DKIM key found/, 'it said there was no key');
	like($err, qr/--keyfile/, 'and how to name one');
	like($err, qr/--plain/, 'and how to send unsigned on purpose');
};

subtest 'a key that cannot be read is reported as such' => sub {
	my $unreadable = File::Spec->catfile($TMP, 'not-there.private');

	my ($status, $out, $err) = run_script($EMPTY_HOME,
		'--dry-run', '--keyfile' => $unreadable, '--from' => 'alerts@example.org');

	isnt($status, 0, 'it failed');
	is($out, '', 'and printed no message');
	like($err, qr/Cannot read \Q$unreadable\E/, 'naming the file it could not read');
};

# A sendmail that records what it was given and then leaves with the status it
# is told to, so that a transport that reports a failure can be told apart from
# one that is not there at all.
sub stub_sendmail
{
	my ($name, $exit) = @_;

	my $path = File::Spec->catfile($TMP, $name);
	my $capture = File::Spec->catfile($TMP, "$name.capture");

	open(my $fh, '>', $path) or BAIL_OUT("Cannot write $path: $!");
	print $fh <<"SENDMAIL";
#!/bin/sh
cat > "$capture"
exit $exit
SENDMAIL
	close($fh);
	chmod(0755, $path) or BAIL_OUT("Cannot make $path executable: $!");

	return ($path, $capture);
}

subtest 'a --save file that cannot be written fails, and nothing is sent' => sub {
	my ($sendmail, $capture) = stub_sendmail('sendmail-idle', 0);
	my $nowhere = File::Spec->catfile($TMP, 'not-a-directory', 'message.txt');

	# No --dry-run, so a run that got past the write would hand the message to
	# sendmail: that nothing was handed over is the point of the subtest.
	my ($status, $out, $err) = run_script($HOME,
		'--plain', '--save' => $nowhere, '--sendmail' => $sendmail,
		'--from' => 'alerts@example.org', '--to' => 'webmaster@example.org');

	is($status, 1, 'it exits 1: nothing was sent');
	is($out, '', 'and printed no message');
	like($err, qr/Cannot write \Q$nowhere\E/, 'naming the file it could not write');
	ok(!-e $capture, 'sendmail was never given the message');
};

subtest 'a sendmail that cannot be run fails, and names it' => sub {
	my $missing = File::Spec->catfile($TMP, 'not-a-sendmail');

	my ($status, $out, $err) = run_script($HOME,
		'--plain', '--sendmail' => $missing,
		'--from' => 'alerts@example.org', '--to' => 'webmaster@example.org');

	is($status, 1, 'it exits 1');
	is($out, '', 'so it did not claim the message was sent');
	like($err, qr/Cannot run \Q$missing\E/, 'naming the sendmail it could not run');
};

subtest 'a sendmail that reports a failure fails, having seen the message' => sub {
	my ($sendmail, $capture) = stub_sendmail('sendmail-fails', 75);

	my ($status, $out, $err) = run_script($HOME,
		'--plain', '--sendmail' => $sendmail,
		'--from' => 'alerts@example.org', '--to' => 'webmaster@example.org');

	is($status, 1, 'it exits 1 rather than passing 75 on');
	is($out, '', 'and does not print it as sent');
	like($err, qr/sendmail reported a failure/, 'it said sendmail failed');
	like(slurp($capture), qr/^To: webmaster\@example\.org$/m,
		'and sendmail had been given the message itself');
};

subtest 'sendmail\'s own 2 is not passed off as a usage error' => sub {
	# 2 is the status for options that cannot be used; a transport that fails
	# with it must still be told apart from that.
	my ($sendmail, $capture) = stub_sendmail('sendmail-exit2', 2);

	my ($status, $out, $err) = run_script($HOME,
		'--plain', '--sendmail' => $sendmail,
		'--from' => 'alerts@example.org', '--to' => 'webmaster@example.org');

	is($status, 1, 'it exits 1, not 2');
	like($err, qr/sendmail reported a failure/, 'and says what failed');
};

subtest 'options that cannot be used are refused, and nothing is signed' => sub {
	# The exit status the POD promises for these: 2.  Each is run against a
	# HOME that holds a key, so a run that got as far as signing would succeed
	# and exit 0 - refusing means the options were checked first.
	# The third thing is what stderr should hold: Getopt::Long names an unknown
	# option itself, and the address checks are silent.
	my @refused = (
		['an unknown option', ['--not-an-option'], qr/Unknown option: not-an-option/],
		['no --to', ['--to' => '', '--from' => 'alerts@example.org']],
		['no --from', ['--to' => 'webmaster@example.org', '--from' => '']],
		['a --to holding a newline, as a header injection would',
			['--to' => "webmaster\@example.org\nBcc: someone\@example.net", '--from' => 'alerts@example.org']],
		['a --to holding a space', ['--to' => 'web master@example.org', '--from' => 'alerts@example.org']],
		['a --from holding a space', ['--to' => 'webmaster@example.org', '--from' => 'alerts @example.org']],
		['a --from beginning with a dash', ['--to' => 'webmaster@example.org', '--from' => '-lead@example.org']],
		['a --to beginning with a dash', ['--to' => '-lead@example.org', '--from' => 'alerts@example.org']],
	);

	foreach my $case (@refused) {
		my ($what, $args, $complaint) = @$case;
		my ($status, $out, $err) = run_script($HOME, '--dry-run', @$args);

		is($status, 2, "$what: exit 2");
		like($out, qr/Usage:/, "$what: it printed the usage") or diag($out);
		unlike($out, qr/DKIM-Signature/, "$what: nothing was signed");
		if($complaint) {
			like($err, $complaint, "$what: it named the option on stderr") or diag($err);
		} else {
			is($err, '', "$what: nothing on stderr") or diag($err);
		}
	}
};

done_testing();
