#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;

use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IO::Compress::Gzip qw(gzip $GzipError);
use IO::Compress::Zip qw(zip $ZipError);
use Time::HiRes qw(time);

my $SCRIPT = File::Spec->catfile(dirname(File::Spec->rel2abs($0)), File::Spec->updir(), 'bin', 'dmarc-report.pl');
my $EXPECTED = '192.0.2.10';

BAIL_OUT("Cannot find $SCRIPT") unless(-r $SCRIPT);

sub slurp
{
	my $path = shift;

	local $/;
	open(my $fh, '<', $path) or return '';
	my $text = <$fh>;
	close($fh);

	return $text;
}

# Run the script as a program, because the exit status is half of what is being
# tested and half the cases are about what it does with files rather than with
# data.  Output goes to files so that a child writing more than a pipe buffer
# cannot deadlock the test.
sub run_script
{
	my (@args) = @_;

	my $out = File::Spec->catfile($main::TMP, 'stdout.txt');
	my $err = File::Spec->catfile($main::TMP, 'stderr.txt');

	my $pid = fork();
	die "fork: $!" unless(defined($pid));

	if(!$pid) {
		open(STDOUT, '>', $out) or exit 127;
		open(STDERR, '>', $err) or exit 127;
		# There is no built-in expected sender, so the default comes from the
		# environment; an explicit -e in @args still wins over it, and a test
		# that sets this to '' leaves the tool with nothing configured.
		$ENV{'DMARC_EXPECTED'} //= $EXPECTED;
		exec($^X, $SCRIPT, @args) or exit 127;
	}

	waitpid($pid, 0);

	return ($? >> 8, slurp($out), slurp($err));
}

# A report with one record, in the shape the reporters actually send.
sub report_xml
{
	my (%args) = @_;

	my $domain = $args{'domain'};
	my $ip = $args{'ip'} // $EXPECTED;
	my $count = $args{'count'} // 1;
	my $dkim = $args{'dkim'} // 'pass';
	my $spf = $args{'spf'} // 'pass';
	my $disposition = $args{'disposition'} // 'none';

	return <<XML;
<?xml version="1.0" encoding="UTF-8" ?>
<feedback>
 <report_metadata>
  <org_name>reporter.example</org_name>
  <report_id>$args{'name'}</report_id>
  <date_range><begin>1794355200</begin><end>1794441599</end></date_range>
 </report_metadata>
 <policy_published>
  <domain>$domain</domain><adkim>r</adkim><aspf>r</aspf><p>none</p><sp>none</sp><pct>100</pct>
 </policy_published>
 <record>
  <row>
   <source_ip>$ip</source_ip>
   <count>$count</count>
   <policy_evaluated><disposition>$disposition</disposition><dkim>$dkim</dkim><spf>$spf</spf></policy_evaluated>
  </row>
  <identifiers><header_from>$domain</header_from></identifiers>
  <auth_results>
   <dkim><domain>$domain</domain><selector>selector1</selector><result>$dkim</result></dkim>
   <spf><domain>$domain</domain><result>$spf</result></spf>
  </auth_results>
 </record>
</feedback>
XML
}

sub write_file
{
	my ($path, $content) = @_;

	open(my $fh, '>', $path) or die "Cannot write $path: $!";
	print $fh $content;
	close($fh) or die "Cannot close $path: $!";

	return $path;
}

# The totals section is one block per domain; pulling them out by heading lets
# an assertion be about one domain's figures without matching another's.
sub domain_blocks
{
	my $out = shift;

	my %blocks;
	while($out =~ /^([^\s:]+): \d+ message\(s\)[^\n]*\n(.*?)(?=^[^\s:]+: \d+ message\(s\)|\z)/msg) {
		$blocks{$1} = $2;
	}

	return %blocks;
}

$main::TMP = tempdir(CLEANUP => 1);

subtest 'each report format is read' => sub {
	my @cases = (
		['a.xml', 'xml', 'example.org', 4],
		['b.xml.gz', 'gz', 'example.net', 2],
		['c.zip', 'zip', 'example.com', 3],
	);

	my $messages = 0;
	foreach my $case (@cases) {
		my ($file, $format, $domain, $count) = @{$case};
		my $dir = File::Spec->catdir($main::TMP, "format-$format");
		mkdir($dir) or die "Cannot mkdir $dir: $!";

		my $xml = report_xml(name => $file, domain => $domain, count => $count);
		my $path = File::Spec->catfile($dir, $file);

		if($format eq 'xml') {
			write_file($path, $xml);
		} else {
			# The uncompressed source is written outside $dir: a second copy
			# inside it would be read as a report in its own right.
			my $plain = File::Spec->catfile($main::TMP, "source-$format.xml");
			write_file($plain, $xml);
			if($format eq 'gz') {
				gzip($plain => $path) or die "gzip: $GzipError";
			} else {
				zip($plain => $path) or die "zip: $ZipError";
			}
		}

		my ($status, $out, $err) = run_script('-d', $dir);
		is($status, 0, "$format: exits 0 when only the expected host sent");
		like($out, qr/Totals over 1 report\(s\): 1 record\(s\), $count message\(s\)/,
			"$format: the report was read and counted");
		like($out, qr/\Q$domain\E: \Q$count\E message\(s\)/, "$format: grouped under $domain");
		is($err, '', "$format: nothing on stderr");

		$messages += $count;
	}
};

subtest 'a non-report .gz and a multi-gigabyte .zip are skipped quickly' => sub {
	my $dir = File::Spec->catdir($main::TMP, 'junk');
	mkdir($dir) or die "Cannot mkdir $dir: $!";

	write_file(File::Spec->catfile($dir, 'real.xml'), report_xml(name => 'real.xml', domain => 'example.org', count => 5));

	# The shape that bit us: a data set that happens to be gzipped.  It is
	# small, so only the "is it a <feedback> document" check can reject it.
	my $csv = File::Spec->catfile($dir, 'cities.csv');
	write_file($csv, "Country,City,Population\nGB,London,8900000\n");
	gzip($csv => File::Spec->catfile($dir, 'worldcitiespop.txt.gz')) or die "gzip: $GzipError";

	# The same kind of thing under a report's own name.  The extension cannot
	# tell this from a report, so rejecting it is the <feedback> check's job,
	# and this is the case that keeps that check honest.
	gzip($csv => File::Spec->catfile($dir, 'notreally.xml.gz')) or die "gzip: $GzipError";

	# A sparse file: -s reports gigabytes, so the size guard is exercised
	# without writing gigabytes.  The old code read a 13 GB archive and sat
	# there until it was killed.
	my $huge = File::Spec->catfile($dir, 'openaddr-collected-global.zip');
	write_file($huge, '');
	truncate($huge, 3 * 1024 * 1024 * 1024) or die "Cannot make $huge sparse: $!";
	cmp_ok(-s $huge, '>', 3 * 1024 * 1024 * 1024 - 1, 'the stand-in really is multi-gigabyte');

	my $started = time();
	my ($status, $out, $err) = run_script('-d', $dir);
	my $elapsed = time() - $started;

	is($status, 0, 'exits 0: the only report came from the expected host');
	cmp_ok($elapsed, '<', 2, "finished in ${elapsed}s, so neither file was read");
	like($out, qr/Totals over 1 report\(s\)/, 'only the real report was counted');
	like($out, qr/example\.org: 5 message\(s\)/, 'the real report was summarised');
	unlike($out, qr/openaddr|worldcitiespop|notreally/, 'no non-report appears in the output');
	is($err, '', 'skipping them is not worth a warning');
};

subtest 'exit status reflects only whether a source is unexpected' => sub {
	my $clean = File::Spec->catdir($main::TMP, 'clean');
	mkdir($clean) or die "Cannot mkdir $clean: $!";
	write_file(File::Spec->catfile($clean, 'ok.xml'), report_xml(name => 'ok.xml', domain => 'example.org', count => 7));
	my ($status) = run_script('-d', $clean);
	is($status, 0, 'all from the expected host: exit 0');

	# Expected host, failing both checks: a problem, but not a different sender,
	# so the exit status stays 0 and the line says which it is.
	my $failing = File::Spec->catdir($main::TMP, 'failing');
	mkdir($failing) or die "Cannot mkdir $failing: $!";
	write_file(File::Spec->catfile($failing, 'fail.xml'),
		report_xml(name => 'fail.xml', domain => 'example.com', count => 2, dkim => 'fail', spf => 'fail'));
	my ($fail_status, $fail_out) = run_script('-d', $failing);
	is($fail_status, 0, 'expected host failing auth: still exit 0');
	like($fail_out, qr/expected, failing auth/, 'and said so');

	my $bad = File::Spec->catdir($main::TMP, 'bad');
	mkdir($bad) or die "Cannot mkdir $bad: $!";
	write_file(File::Spec->catfile($bad, 'bad.xml'),
		report_xml(name => 'bad.xml', domain => 'example.org', ip => '203.0.113.7', count => 3, dkim => 'fail', spf => 'fail'));
	my ($bad_status, $bad_out) = run_script('-d', $bad);
	is($bad_status, 1, 'a source that is not the expected host: exit 1');
	like($bad_out, qr/203\.0\.113\.7.*NOT $EXPECTED/, 'the line says which address it is');
	like($bad_out, qr/3 message\(s\) came from addresses that are not $EXPECTED/, 'and how many');

	# A different host can be allowed explicitly, which is how a second sender
	# or a migration is tested before it is believed.
	my ($allowed_status) = run_script('-d', $bad, '-e', $EXPECTED, '-e', '203.0.113.7');
	is($allowed_status, 0, 'the same messages exit 0 when the address is allowed');
};

subtest 'totals are kept per domain, not merged across domains' => sub {
	my $dir = File::Spec->catdir($main::TMP, 'per-domain');
	mkdir($dir) or die "Cannot mkdir $dir: $!";

	# The same host sends for two domains, in different volumes, which is the
	# case that used to be added into a single figure.  One domain also has a
	# sender of its own, to show that does not leak into the other's block.
	write_file(File::Spec->catfile($dir, 'a-example.xml'),
		report_xml(name => 'a-example.xml', domain => 'example.org', count => 4));
	write_file(File::Spec->catfile($dir, 'b-concert.xml'),
		report_xml(name => 'b-concert.xml', domain => 'example.net', count => 2));
	write_file(File::Spec->catfile($dir, 'c-concert-other.xml'),
		report_xml(name => 'c-concert-other.xml', domain => 'example.net',
			ip => '198.51.100.9', count => 1, dkim => 'fail', spf => 'fail'));

	my ($status, $out) = run_script('-d', $dir);
	is($status, 1, 'the foreign address in one domain still makes it exit 1');

	my %blocks = domain_blocks($out);
	ok($blocks{'example.org'}, 'example.org has a block of its own');
	ok($blocks{'example.net'}, 'example.net has a block of its own');

	like($blocks{'example.org'}, qr/192\.0\.2\.10\s+4\s+4\s+0/,
		'the expected host under example.org with its own count of 4');
	like($blocks{'example.net'}, qr/192\.0\.2\.10\s+2\s+2\s+0/,
		'the same host under example.net with its own count of 2');
	unlike($blocks{'example.org'}, qr/192\.0\.2\.10\s+6\b/,
		'example.org does not show the two domains added together');
	unlike($blocks{'example.org'}, qr/198\.51\.100\.9/,
		"one domain's foreign sender stays out of the other's block");

	like($out, qr/^example\.org: 4 message\(s\)/m, 'its heading counts only its own mail');
	like($out, qr/^example\.net: 3 message\(s\), 1 not from/m,
		'concert heading counts its own and names the foreign one');
};

subtest 'the reports it read can be listed for archiving' => sub {
	my $dir = File::Spec->catdir($main::TMP, 'listed');
	mkdir($dir) or die "Cannot mkdir $dir: $!";

	# Two real reports and two things that are not: the list has to name the
	# reports so that moving them aside cannot touch anything else.
	write_file(File::Spec->catfile($dir, 'one.xml'),
		report_xml(name => 'one.xml', domain => 'example.org'));
	my $source = File::Spec->catfile($main::TMP, 'listed-source.xml');
	write_file($source, report_xml(name => 'two.xml', domain => 'example.net'));
	zip($source => File::Spec->catfile($dir, 'two.zip')) or die "zip: $ZipError";

	my $csv = File::Spec->catfile($main::TMP, 'listed.csv');
	write_file($csv, "Country,City\nGB,London\n");
	gzip($csv => File::Spec->catfile($dir, 'not-a-report.xml.gz')) or die "gzip: $GzipError";

	my $list = File::Spec->catfile($main::TMP, 'read-files.txt');
	my ($status) = run_script('-d', $dir, '--file-list', $list);
	is($status, 0, 'exits 0');

	my @listed = grep { length } split /\n/, slurp($list);
	is(scalar(@listed), 2, 'exactly the two reports are listed');

	my %names = map { (split(m{/}, $_))[-1] => 1 } @listed;
	ok($names{'one.xml'}, 'the .xml report is listed');
	ok($names{'two.zip'}, 'the .zip report is listed');
	ok(!$names{'not-a-report.xml.gz'}, 'the non-report is not listed, so archiving cannot move it');

	like($listed[0], qr{\A/}, 'paths are absolute, so the caller can move them from anywhere');
};

subtest 'a message quarantined or rejected that should not have been is flagged' => sub {
	# Our own host, quarantined: the case that has to be fixed before any move
	# to p=reject, and the one that is easy to miss in the per-address totals.
	my $own = File::Spec->catdir($main::TMP, 'filed-own');
	mkdir($own) or die "Cannot mkdir $own: $!";
	write_file(File::Spec->catfile($own, 'own-quarantined.xml'),
		report_xml(name => 'own-quarantined.xml', domain => 'example.com',
			ip => $EXPECTED, count => 2, dkim => 'fail', spf => 'fail', disposition => 'quarantine'));
	my ($own_status, $own_out, $own_err) = run_script('-d', $own);
	is($own_status, 1, 'the expected host being quarantined fails the run');
	like($own_out, qr/\Q$EXPECTED\E.*expected host, not authenticating; expected sender, quarantined/,
		'the record line says both things');
	like($own_out, qr/^Filed by policy although it should not have been: 2 message\(s\)/m,
		'the summary counts them');
	like($own_out, qr/^  example\.com\s+\Q$EXPECTED\E\s+quarantine\s+2\s+expected sender, yet quarantined/m,
		'and names the address under its domain');
	is($own_err, '', 'nothing on stderr');

	# A rejection is the same failure, and the wording follows the disposition.
	my $rej = File::Spec->catdir($main::TMP, 'filed-reject');
	mkdir($rej) or die "Cannot mkdir $rej: $!";
	write_file(File::Spec->catfile($rej, 'own-rejected.xml'),
		report_xml(name => 'own-rejected.xml', domain => 'example.org',
			ip => $EXPECTED, count => 3, dkim => 'fail', spf => 'pass', disposition => 'reject'));
	my ($rej_status, $rej_out) = run_script('-d', $rej);
	is($rej_status, 1, 'a rejection fails the run too');
	like($rej_out, qr/\Q$EXPECTED\E.*expected sender, rejected though authenticated/,
		'the record line says rejected, and that it authenticated')
		or diag($rej_out);
	like($rej_out, qr/expected sender, and authenticated, yet rejected/, 'the summary uses the right word');

	# Authenticated but filed, from an address that is not one of ours: the
	# first half of the check, independent of who sent it.
	my $auth = File::Spec->catdir($main::TMP, 'filed-auth');
	mkdir($auth) or die "Cannot mkdir $auth: $!";
	write_file(File::Spec->catfile($auth, 'auth-quarantined.xml'),
		report_xml(name => 'auth-quarantined.xml', domain => 'example.org',
			ip => '198.51.100.7', count => 4, dkim => 'pass', spf => 'fail', disposition => 'quarantine'));
	my ($auth_status, $auth_out) = run_script('-d', $auth);
	is($auth_status, 1, 'a passing sender being quarantined fails the run');
	like($auth_out, qr/198\.51\.100\.7.*authenticated, but quarantined/, 'the record line says so');
	like($auth_out, qr/^  example\.org\s+198\.51\.100\.7\s+quarantine\s+4\s+authenticated, yet quarantined/m,
		'and the summary names it');

	# The case the check must not cry about: forged mail that failed both
	# checks.  It is an unexpected sender, so the run still fails, but nothing
	# was quarantined that should not have been.
	my $spam = File::Spec->catdir($main::TMP, 'filed-spam');
	mkdir($spam) or die "Cannot mkdir $spam: $!";
	write_file(File::Spec->catfile($spam, 'spam-quarantined.xml'),
		report_xml(name => 'spam-quarantined.xml', domain => 'example.org',
			ip => '203.0.113.9', count => 6, dkim => 'fail', spf => 'fail', disposition => 'quarantine'));
	my ($spam_status, $spam_out) = run_script('-d', $spam);
	is($spam_status, 1, 'a forged sender still fails the run, as it always did');
	unlike($spam_out, qr/Filed by policy/, 'but quarantining it is not reported as misfiled');
	like($spam_out, qr/6 message\(s\) came from addresses that are not \Q$EXPECTED\E/,
		'it is reported as an unexpected sender instead');

	# Nothing quarantined at all: the new check stays out of the way.
	my $clean = File::Spec->catdir($main::TMP, 'filed-clean');
	mkdir($clean) or die "Cannot mkdir $clean: $!";
	write_file(File::Spec->catfile($clean, 'delivered.xml'),
		report_xml(name => 'delivered.xml', domain => 'example.org', ip => $EXPECTED, count => 5));
	my ($clean_status, $clean_out) = run_script('-d', $clean);
	is($clean_status, 0, 'a clean run still exits 0');
	unlike($clean_out, qr/Filed by policy/, 'and says nothing about filed mail');
	like($clean_out, qr/Every message came from \Q$EXPECTED\E, and none was filed by policy/,
		'and the closing line says it is clean');
};

subtest 'an empty directory and a bad directory are errors' => sub {
	my $empty = File::Spec->catdir($main::TMP, 'empty');
	mkdir($empty) or die "Cannot mkdir $empty: $!";
	# die exits with $! when it is set, so these give the errno rather than a
	# fixed 255; what matters is that neither is a success.
	my ($status, $out, $err) = run_script('-d', $empty);
	cmp_ok($status, '>', 0, 'no reports at all is a failure, not a clean bill of health');
	like($err, qr/No reports found/, 'and it says so');

	($status, $out, $err) = run_script('-d', File::Spec->catdir($main::TMP, 'no-such-directory'));
	cmp_ok($status, '>', 0, 'a missing directory is a failure');
	like($err, qr/Not a directory/, 'and it says so');
};

subtest 'with no expected sender it stops with a usage error' => sub {
	# '' and not a real address: run_script only fills in the default when the
	# variable is unset, so this is the path with nothing configured at all.
	local $ENV{'DMARC_EXPECTED'} = '';
	my ($status, $out, $err) = run_script('-d', $main::TMP);

	is($status, 2, 'exit 2, so a cron job can tell it from a finding');
	is($out, '', 'nothing on stdout');
	like($err, qr/No expected sender/, 'the reason is on stderr');
	like($err, qr/--expected/, 'and names the option');
	like($err, qr/DMARC_EXPECTED/, 'and the environment variable');
};

done_testing();
