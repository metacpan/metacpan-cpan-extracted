#!/usr/bin/env perl
#
# The signing lives in Mail::Send::DKIM and is tested here directly: no process
# to start and no message to capture, except where what is under test is the
# pipe to sendmail or the programme's own wiring.
#
# The key pair is made at run time, so no key material lives in the repository,
# and the public half is served to the verifier through a stubbed DNS lookup
# rather than being published anywhere.

use strict;
use warnings;

use Test::Most;

use Config;
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);

use lib File::Spec->catdir($Bin, File::Spec->updir(), 'lib');
use Mail::Send::DKIM;

my $SCRIPT = File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'mail-dkim');

BAIL_OUT("Cannot find $SCRIPT") unless(-r $SCRIPT);

plan skip_all => 'Mail::DKIM is needed to sign and verify'
	unless(eval { require Mail::DKIM::Signer; require Mail::DKIM::Verifier; require Mail::DKIM::DNS; require Net::DNS::RR; 1 });

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
my $KEYS = File::Spec->catdir($TMP, 'keys');
my $MANY = File::Spec->catdir($TMP, 'many-keys');
my $EMPTY = File::Spec->catdir($TMP, 'no-keys');
my $CAPTURE = File::Spec->catdir($TMP, 'capture');
foreach my $dir ($KEYS, $MANY, $EMPTY, $CAPTURE) {
	mkdir($dir) or BAIL_OUT("Cannot make $dir: $!");
}

# openssl announces "writing RSA key" on stderr, which has no place in the
# test output; the redirection goes in the command, so there is no filehandle
# to put back and no child to wait for.
my $DEVNULL = File::Spec->devnull;

sub gen_key
{
	my $path = shift;

	return system(qq{"$openssl" genrsa -out "$path" 2048 2>"$DEVNULL"}) == 0;
}

my $KEY = File::Spec->catfile($KEYS, 'selector1.private');
BAIL_OUT("openssl could not make $KEY") unless(gen_key($KEY));

# The same key published under two selectors: that is enough to test choosing
# between them, and the signature under either still verifies against the one
# public key the stubbed lookup answers with.
foreach my $selector ('selector1', 'selector2') {
	my $copy = File::Spec->catfile($MANY, "$selector.private");
	copy($KEY, $copy) or BAIL_OUT("Cannot copy $KEY to $copy: $!");
}

# The public half, as the TXT record at <selector>._domainkey.<domain> would
# carry it: base64 of the SubjectPublicKeyInfo, with the PEM markers gone.
# Made once - every verification asks the same question, so asking openssl
# again for each one would only repeat the answer.
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

sub verify_signature
{
	my $message = shift;

	# A receiving site hashes the message in its CRLF form, which is what the
	# sending MTA puts on the wire, so what the module signs is verified the
	# same way: after the line endings an MTA would have converted.
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

# Run a piece of the module with its warnings captured, so that "nothing was
# said" can be checked as well as what was said.
sub quietly
{
	my $code = shift;

	my $warnings = '';
	local $SIG{'__WARN__'} = sub { $warnings .= $_[0] };

	my @result = $code->();

	return (\@result, $warnings);
}

sub message
{
	my (%args) = @_;

	my $from = $args{'from'};
	my $headers = defined($from) ? "From: $from\n" : '';

	return $headers . <<'MESSAGE';
To: webmaster@example.org
Subject: Registration
Date: Mon, 17 Nov 2026 12:00:00 +0000
Message-ID: <message-1@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8

Body line one.
Body line two.
MESSAGE
}

sub signer
{
	my (%args) = @_;

	$args{'keydir'} = $KEYS unless(exists $args{'keydir'});

	return Mail::Send::DKIM->new(%args);
}

# A sendmail that records what it was given instead of sending.
my $FAKE = File::Spec->catfile($TMP, 'fake-sendmail.sh');

sub slurp
{
	my $path = shift;

	local $/;
	open(my $fh, '<', $path) or return '';
	my $text = <$fh>;
	close($fh);

	return $text;
}

open(my $fake, '>', $FAKE) or BAIL_OUT("Cannot write $FAKE: $!");
print $fake <<'SENDMAIL';
#!/bin/sh
cat > "$DKIM_TEST_CAPTURE/message"
: > "$DKIM_TEST_CAPTURE/args"
for arg in "$@"; do
	printf '%s\n' "$arg" >> "$DKIM_TEST_CAPTURE/args"
done
exit "${DKIM_TEST_EXIT:-0}"
SENDMAIL
close($fake);
chmod(0755, $FAKE) or BAIL_OUT("Cannot make $FAKE executable: $!");

subtest 'a message from a domain we sign for is signed, and the signature verifies' => sub {
	my $signer = signer(domains => ['example.org']);
	my ($result, $warnings) = quietly(sub { $signer->sign(message(from => 'alerts@example.org')) });
	my $signed = $result->[0];

	is($warnings, '', 'nothing was said') or diag($warnings);
	ok(defined($signed), 'a signed message came back');

	like($signed, qr/\ADKIM-Signature: /, 'the signature is the first header');
	like($signed, qr/d=example\.org/, 'it is for the domain in From:');
	like($signed, qr/s=selector1/, 'it names the selector from the key file');
	like($signed, qr/a=rsa-sha256/, 'it is rsa-sha256');
	like($signed, qr/c=relaxed/, 'canonicalization is relaxed');
	is(verify_signature($signed), 'pass', 'the signature verifies against the published key');

	like($signed, qr/^Subject: Registration$/m, 'the headers are still there');
	like($signed, qr/^Body line two\.$/m, 'so is the body');
	unlike($signed, qr/\r/, 'and no carriage return is handed to sendmail');
};

subtest 'a display name, and a domain in another case, are understood' => sub {
	my $signer = signer(domains => ['example.org']);
	my $signed = $signer->sign(message(from => '"Site Alerts" <Alerts@Example.ORG>'));

	ok(defined($signed), 'it was signed');
	like($signed, qr/d=example\.org/, 'the domain is the one in the address, not the display name');
	is(verify_signature($signed), 'pass', 'and it verifies');
};

subtest 'every domain in the list is signed, not only the first' => sub {
	my $signer = signer(domains => 'example.org, example.net');
	my $signed = $signer->sign(message(from => 'alerts@example.net'));

	ok(defined($signed), 'it was signed');
	like($signed, qr/d=example\.net/, 'the second domain is signed for itself');
	is(verify_signature($signed), 'pass', 'and it verifies');
};

subtest 'a message from a domain that is not ours is left alone' => sub {
	my $signer = signer(domains => ['example.org']);
	my ($result, $warnings) = quietly(sub { $signer->sign(message(from => 'someone@example.com')) });

	is($result->[0], undef, 'nothing was signed');
	is($warnings, '', 'and nothing was worth a warning');
};

subtest 'a message with no From: header is left alone' => sub {
	my $signer = signer(domains => ['example.org']);
	my $result = $signer->sign(message());

	is($result, undef, 'nothing to sign, so nothing was signed');
};

subtest 'with no domains configured nothing is signed' => sub {
	my $signer = signer();
	my $result = $signer->sign(message(from => 'alerts@example.org'));

	is($result, undef, 'the message was left alone');
};

subtest 'the domains come from the environment when the caller gives none' => sub {
	local $ENV{'DKIM_DOMAINS'} = 'example.org';
	local $ENV{'DKIM_KEYDIR'} = $KEYS;
	local $ENV{'DKIM_SELECTOR'} = 'selector1';

	my $signed = Mail::Send::DKIM->new()->sign(message(from => 'alerts@example.org'));

	ok(defined($signed), 'signed with nothing but the environment');
	is(verify_signature($signed), 'pass', 'and it verifies');
};

subtest 'a key file named outright is used, and names its selector' => sub {
	# keydir holds no key at all, so the only way this can sign is by the file
	# that was named - and its name is where the selector comes from.
	my $signer = signer(domains => ['example.org'], keydir => $EMPTY, keyfile => $KEY);
	my ($result, $warnings) = quietly(sub { $signer->sign(message(from => 'alerts@example.org')) });

	is($warnings, '', 'nothing was said') or diag($warnings);
	ok(defined($result->[0]), 'it was signed');
	like($result->[0], qr/s=selector1/, 'with the selector from the file name');
	is(verify_signature($result->[0]), 'pass', 'and it verifies');
};

subtest 'a missing key is a warning and an unsigned message, not a lost one' => sub {
	my $signer = signer(domains => ['example.org'], keydir => $EMPTY);
	my ($result, $warnings) = quietly(sub { $signer->sign(message(from => 'alerts@example.org')) });

	is($result->[0], undef, 'nothing was signed');
	like($warnings, qr/no readable key|0 key/, 'and the reason was said');
};

subtest 'more than one key and no selector is a warning, not a guess' => sub {
	my $signer = signer(domains => ['example.org'], keydir => $MANY);
	my ($result, $warnings) = quietly(sub { $signer->sign(message(from => 'alerts@example.org')) });

	is($result->[0], undef, 'nothing was signed');
	like($warnings, qr/2 key/, 'and it said why it could not choose');

	my $chosen = signer(domains => ['example.org'], keydir => $MANY, selector => 'selector1')
		->sign(message(from => 'alerts@example.org'));
	like($chosen, qr/s=selector1/, 'with a selector the named key is used');
	is(verify_signature($chosen), 'pass', 'and it verifies');
};

subtest 'send hands the message and the arguments to sendmail' => sub {
	my $signer = signer(sendmail => $FAKE);
	local $ENV{'DKIM_TEST_CAPTURE'} = $CAPTURE;
	unlink(File::Spec->catfile($CAPTURE, 'message'), File::Spec->catfile($CAPTURE, 'args'));

	my $status = $signer->send(message(from => 'alerts@example.org'),
		'-t', '-f', 'bounce@example.org', '-odq');

	is($status, 0, 'sendmail accepted it');
	is(slurp(File::Spec->catfile($CAPTURE, 'message')), message(from => 'alerts@example.org'),
		'and was given the message');
	is(slurp(File::Spec->catfile($CAPTURE, 'args')), "-t\n-f\nbounce\@example.org\n-odq\n",
		'and the arguments, in order');
};

subtest 'a message that arrives with CRLF leaves with none' => sub {
	my $signer = signer(domains => ['example.org'], sendmail => $FAKE);
	local $ENV{'DKIM_TEST_CAPTURE'} = $CAPTURE;
	my $capture = File::Spec->catfile($CAPTURE, 'message');
	unlink($capture);

	# What a tool that has read the message over SMTP hands over: the line
	# endings are already CRLF, and an MTA behind sendmail would add another
	# CR to each, so the receiver would see them doubled.
	(my $crlf = message(from => 'alerts@example.org')) =~ s/\n/\r\n/g;
	like($crlf, qr/\r\n/, 'the message under test really has CRLF in it');

	my $signed = $signer->sign($crlf);
	ok(defined($signed), 'it was signed');
	unlike($signed, qr/\r/, 'and the signed copy carries no carriage return');
	is(verify_signature($signed), 'pass', 'the signature is still over the CRLF form');

	is($signer->send($signed, '-t'), 0, 'sendmail took it');

	my $delivered = slurp($capture);
	unlike($delivered, qr/\r/, 'no carriage return reached sendmail');
	(my $rest = $delivered) =~ s/\ADKIM-Signature:[^\n]*\n(?:[ \t][^\n]*\n)*//;
	is($rest, message(from => 'alerts@example.org'), 'and the rest is the message with LF endings');

	# A message that is not signed never goes through sign, so the
	# normalisation has to sit in send as well or pass-through mail keeps its
	# carriage returns.
	(my $foreign = message(from => 'someone@example.com')) =~ s/\n/\r\n/g;
	unlink($capture);
	is($signer->send($foreign), 0, 'a foreign message was passed on');
	is(slurp($capture), message(from => 'someone@example.com'),
		'and arrived without a carriage return, and otherwise untouched');
};

subtest 'send returns sendmail\'s own exit status' => sub {
	my $signer = signer(sendmail => $FAKE);
	local $ENV{'DKIM_TEST_CAPTURE'} = $CAPTURE;
	local $ENV{'DKIM_TEST_EXIT'} = 75;

	is($signer->send(message(from => 'alerts@example.org')), 75, 'a sendmail that failed is reported as failed');
};

subtest 'send reports a sendmail that cannot be run' => sub {
	my $signer = signer(sendmail => File::Spec->catfile($TMP, 'no-such-sendmail'));
	my ($result, $warnings) = quietly(sub { $signer->send(message(from => 'alerts@example.org')) });

	is($result->[0], 1, 'the failure is a status, not an exception');
	like($warnings, qr/cannot run/, 'and it said it could not run sendmail');
};

# The programme is thin, but the wiring is what a crontab depends on: stdin in,
# sendmail's arguments out, sendmail's status back.
my $INPUT_ID = 0;

sub run_script
{
	my ($input, @args) = @_;

	my $file = File::Spec->catfile($TMP, 'stdin-' . ++$INPUT_ID);
	open(my $fh, '>', $file) or die "Cannot write $file: $!";
	print $fh $input;
	close($fh);

	unlink(File::Spec->catfile($CAPTURE, 'message'), File::Spec->catfile($CAPTURE, 'args'));

	my $out = File::Spec->catfile($TMP, 'stdout.txt');
	my $err = File::Spec->catfile($TMP, 'stderr.txt');

	my $pid = fork();
	die "fork: $!" unless(defined($pid));

	if(!$pid) {
		$ENV{'HOME'} = $TMP;
		$ENV{'DKIM_KEYDIR'} = $KEYS;
		$ENV{'DKIM_DOMAINS'} = 'example.org';
		delete($ENV{'DKIM_SELECTOR'});
		$ENV{'SENDMAIL'} = $FAKE;
		$ENV{'DKIM_TEST_CAPTURE'} = $CAPTURE;
		open(STDIN, '<', $file) or exit 127;
		open(STDOUT, '>', $out) or exit 127;
		open(STDERR, '>', $err) or exit 127;
		exec($^X, $SCRIPT, @args) or exit 127;
	}

	waitpid($pid, 0);

	return ($? >> 8, slurp($err), slurp(File::Spec->catfile($CAPTURE, 'message')),
		slurp(File::Spec->catfile($CAPTURE, 'args')));
}

# One run of the real programme, because everything else is the module: what is
# left to get wrong here is stdin, the argument list and the exit status.
subtest 'an installed copy finds the module under lib/perl5' => sub {
	# The layout INSTALL_BASE produces: PREFIX/bin/<script> and the module at
	# PREFIX/lib/perl5, with nothing on @INC pointing at the prefix.  cron is
	# the caller that cannot be given PERL5LIB, so the script has to look.
	my $prefix = File::Spec->catdir($TMP, 'prefix');
	my $bin = File::Spec->catdir($prefix, 'bin');
	my $installed_lib = File::Spec->catdir($prefix, 'lib', 'perl5', 'Mail', 'Send');
	make_path($bin, $installed_lib) or BAIL_OUT("Cannot make the prefix: $!");

	copy(File::Spec->catfile($Bin, File::Spec->updir(), 'lib', 'Mail', 'Send', 'DKIM.pm'),
		File::Spec->catfile($installed_lib, 'DKIM.pm'))
		or BAIL_OUT("Cannot copy the module into the prefix: $!");

	foreach my $script (qw(mail-dkim dmarc-check-mail.pl)) {
		my $installed = File::Spec->catfile($bin, $script);
		copy(File::Spec->catfile($Bin, File::Spec->updir(), 'bin', $script), $installed)
			or BAIL_OUT("Cannot copy $script into the prefix: $!");

		my $out = File::Spec->catfile($TMP, "compiled-$script.txt");
		my $pid = fork();
		die "fork: $!" unless(defined($pid));

		if(!$pid) {
			# Keep the dependencies' directories (CI installs Mail::DKIM into
			# local/lib/perl5), but drop any that could supply the module under
			# test, so the script has to find it by itself.
			my @keep = grep { length($_) && !-e File::Spec->catfile($_, 'Mail', 'Send', 'DKIM.pm') }
				split(/\Q$Config::Config{path_sep}\E/, $ENV{'PERL5LIB'} // '');
			if(@keep) {
				$ENV{'PERL5LIB'} = join($Config::Config{path_sep}, @keep);
			} else {
				delete($ENV{'PERL5LIB'});
			}
			open(STDOUT, '>', $out) or exit 127;
			open(STDERR, '>&', \*STDOUT) or exit 127;
			exec($^X, '-c', $installed) or exit 127;
		}

		waitpid($pid, 0);

		is($? >> 8, 0, "$script compiles with no PERL5LIB");
		like(slurp($out), qr/syntax OK/, 'and it found the module, rather than failing on @INC')
			or diag(slurp($out));
		unlike(slurp($out), qr/Can't locate Mail\/Send\/DKIM/, 'no missing-module error');
	}
};

subtest 'the programme, end to end: stdin in, sendmail out, status back' => sub {
	my $input = message(from => 'alerts@example.org');
	my ($status, $err, $sent, $args) = run_script($input, '-t', '-f', 'bounce@example.org');

	is($status, 0, 'it exited 0');
	is($err, '', 'nothing on stderr') or diag($err);
	like($sent, qr/\ADKIM-Signature: /, 'the message sendmail was given is signed');
	is(verify_signature($sent), 'pass', 'and the signature verifies');
	is($args, "-t\n-f\nbounce\@example.org\n", 'every argument was handed to sendmail');

	# The half a crontab depends on most: a domain this host does not sign
	# for still has to be delivered, and delivered as it arrived.
	my $foreign = message(from => 'someone@example.com');
	($status, undef, $sent) = run_script($foreign);

	is($status, 0, 'a foreign message also exits 0');
	is($sent, $foreign, 'and reached sendmail untouched');
};

done_testing();
