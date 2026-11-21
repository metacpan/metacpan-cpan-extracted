#!/usr/bin/env perl
#
# The wrapper is what cron actually runs, and what it does with the files is
# its own behaviour rather than the summariser's: which reports it moves, where
# to, and what it does on a week with nothing in it.  That is worth testing
# separately, and one bug already got through without it - a dry run was
# archiving the reports, because the clean-week path returned before DRY_RUN was
# ever looked at.

use strict;
use warnings;

use Test::Most;
use Test::Needs;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

my $WRAPPER = File::Spec->catfile(dirname(File::Spec->rel2abs($0)), File::Spec->updir(), 'bin', 'dmarc-weekly.sh');
my $EXPECTED = '192.0.2.10';

# Only the signed-alert subtest needs openssl, and it skips itself without it.
my $OPENSSL;
foreach my $dir (File::Spec->path()) {
	my $candidate = File::Spec->catfile($dir, 'openssl');
	if(-x $candidate) {
		$OPENSSL = $candidate;
		last;
	}
}

BAIL_OUT("Cannot find $WRAPPER") unless(-x $WRAPPER);

sub slurp
{
	my $path = shift;

	local $/;
	open(my $fh, '<', $path) or return '';
	my $text = <$fh>;
	close($fh);

	return $text;
}

sub write_file
{
	my ($path, $content) = @_;

	open(my $fh, '>', $path) or die "Cannot write $path: $!";
	print $fh $content;
	close($fh) or die "Cannot close $path: $!";

	return $path;
}

# A report with one record, in the shape the reporters actually send.
sub report_xml
{
	my (%args) = @_;

	my $domain = $args{'domain'};
	my $ip = $args{'ip'} // $EXPECTED;
	my $count = $args{'count'} // 1;

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
   <policy_evaluated><disposition>none</disposition><dkim>pass</dkim><spf>pass</spf></policy_evaluated>
  </row>
  <identifiers><header_from>$domain</header_from></identifiers>
  <auth_results>
   <dkim><domain>$domain</domain><selector>selector1</selector><result>pass</result></dkim>
   <spf><domain>$domain</domain><result>pass</result></spf>
  </auth_results>
 </record>
</feedback>
XML
}

# Run the wrapper the way cron does: no arguments at all, its behaviour chosen
# entirely by the environment.  HOME points into the temporary directory so the
# default archive and log paths are the ones under test, and MAIL_COMMAND keeps
# any mail in a file instead of trying to find a transport.
sub run_wrapper
{
	my @rest = @_;
	my $args = (ref($rest[0]) eq 'ARRAY') ? shift(@rest) : [];
	my %env = @rest;

	# Which copy of the wrapper to run: the one in the source tree by default,
	# and an installed copy where a subtest is about the installed layout.  It
	# is taken out of the environment, so it never reaches the child as a
	# variable the script might read.
	my $program = delete($env{'program'}) // $WRAPPER;

	my $out = File::Spec->catfile($main::TMP, 'stdout.txt');
	my $err = File::Spec->catfile($main::TMP, 'stderr.txt');
	my $mail = File::Spec->catfile($main::TMP, 'mail.txt');
	unlink($mail);

	my %set = (
		HOME => $main::HOME,
		PERL => $^X,
		DMARC_EXPECTED => $EXPECTED,
		DMARC_LOG => File::Spec->catfile($main::HOME, 'dmarc-report.log'),
		MAIL_COMMAND => "cat > $mail",
		%env,
	);

	# A setting given as undef is left out of the environment altogether, which
	# is how a subtest asks the wrapper to choose for itself.
	foreach my $name (grep { !defined($set{$_}) } keys %set) {
		delete($set{$name});
	}

	my $pid = fork();
	die "fork: $!" unless(defined($pid));

	if(!$pid) {
		foreach my $name (keys %set) {
			$ENV{$name} = $set{$name};
		}
		# Not inherited from whatever ran prove, so a variable that would
		# change the outcome cannot leak in from the developer's shell.
		foreach my $name (qw(DMARC_ARCHIVE_DIR DMARC_ARCHIVE DRY_RUN
				DKIM_DOMAINS DKIM_KEYDIR DKIM_SELECTOR SENDMAIL MAIL_FROM MAIL_DKIM PERL)) {
			delete($ENV{$name}) unless(exists($set{$name}));
		}
		open(STDOUT, '>', $out) or exit 127;
		open(STDERR, '>', $err) or exit 127;
		exec($program, @$args) or exit 127;
	}

	waitpid($pid, 0);

	return ($? >> 8, slurp($out), slurp($err), (-e $mail ? slurp($mail) : ''));
}

# Whether a perl can load the module the report needs, without its complaint on
# the terminal when it cannot.
sub can_load_xmlpp
{
	my $perl = shift;

	local *STDERR;
	open(STDERR, '>', File::Spec->devnull()) or die "Cannot redirect stderr: $!";

	return system($perl, '-MXML::PP', '-e', '1') == 0;
}

# A perl on this machine that can load it, looked for the way the wrapper looks
# for one: the interpreter running the tests first, then the others.  undef when
# there is none, so that a subtest about the choice skips rather than failing on
# a machine that could not run the report anyway.
sub perl_with_xmlpp
{
	my @candidates = ($^X, glob("$ENV{'HOME'}/perl5/perlbrew/perls/*/bin/perl"),
		'/usr/local/bin/perl', '/usr/bin/perl', '/opt/homebrew/bin/perl');

	foreach my $perl (@candidates) {
		next unless(defined($perl) && -x $perl);
		return $perl if(can_load_xmlpp($perl));
	}

	return;
}

sub reports_dir
{
	my ($name) = @_;

	my $dir = File::Spec->catdir($main::TMP, $name);
	mkdir($dir) or die "Cannot mkdir $dir: $!";

	return $dir;
}

# A HOME of its own for each subtest: the wrapper's archive and log defaults are
# derived from it, and sharing one would let an earlier subtest's leftovers
# decide a later subtest's result.
sub fresh_home
{
	my ($name) = @_;

	my $home = File::Spec->catdir($main::TMP, "home-$name");
	mkdir($home) or die "Cannot mkdir $home: $!";

	return $home;
}

$main::TMP = tempdir(CLEANUP => 1);
$main::HOME = fresh_home('default');

subtest 'a dry run moves nothing' => sub {
	my $home = fresh_home('dry');
	my $ARCHIVE = File::Spec->catdir($home, 'dmarc-archive');

	# A week with a finding, so the run has something it would archive and
	# something it would say.
	my $dir = reports_dir('dry-dirty');
	write_file(File::Spec->catfile($dir, 'ok.xml'), report_xml(name => 'ok.xml', domain => 'example.org'));
	write_file(File::Spec->catfile($dir, 'bad.xml'),
		report_xml(name => 'bad.xml', domain => 'example.org', ip => '203.0.113.7', count => 3));

	my ($status, $out, $err) = run_wrapper(HOME => $home, DMARC_DIR => $dir, DRY_RUN => 1);
	is($status, 1, 'the finding still sets the exit status');
	like($out, qr/would archive 2 report\(s\) to \Q$ARCHIVE\E/, 'it says what it would have archived, and where');
	is(join(',', sort { $a cmp $b } do { opendir(my $dh, $dir); grep { $_ ne '.' && $_ ne '..' } readdir($dh) }),
		'bad.xml,ok.xml', 'both reports are still in place');
	ok(!-d $ARCHIVE, 'no archive directory was created');

	# The regression that prompted these tests: on a week with nothing to
	# report, the wrapper returned before consulting DRY_RUN and archived the
	# lot anyway.
	my $clean = reports_dir('dry-clean');
	write_file(File::Spec->catfile($clean, 'ok.xml'), report_xml(name => 'ok.xml', domain => 'example.org'));

	($status, $out, $err) = run_wrapper(HOME => $home, DMARC_DIR => $clean, DRY_RUN => 1);
	is($status, 0, 'a clean week in rehearsal exits 0');
	is($out . $err, '', 'and says nothing');
	ok(-f File::Spec->catfile($clean, 'ok.xml'), 'the report is still there: a rehearsal has no side effects');
	ok(!-d $ARCHIVE, 'and still no archive directory');
};

subtest 'an empty directory is a quiet week' => sub {
	my $home = fresh_home('empty');
	my $ARCHIVE = File::Spec->catdir($home, 'dmarc-archive');
	my $dir = reports_dir('empty');
	my $log = File::Spec->catfile($main::TMP, 'empty.log');

	my ($status, $out, $err, $mail) = run_wrapper(HOME => $home, DMARC_DIR => $dir, DMARC_LOG => $log);
	is($status, 0, 'exits 0: nothing to report is not a failure');
	is($out . $err, '', 'says nothing on either stream');
	is($mail, '', 'sends no mail');
	ok(!-e $log, 'writes nothing to the log');
	ok(!-d $ARCHIVE, 'and creates no archive directory');

	# Silence has to mean "nothing new", not "the job broke": a directory that
	# does not exist is still a failure worth hearing about.  The wrapper takes
	# the summariser's own stderr into its message rather than passing it
	# through, so it shows up in the mail instead of on the cron stream.
	my $missing = File::Spec->catdir($main::TMP, 'no-such-directory');
	($status, $out, $err, $mail) = run_wrapper(HOME => $home, DMARC_DIR => $missing);
	cmp_ok($status, '>', 0, 'a missing directory is a failure');
	like($mail, qr/Not a directory/, 'and the failure is reported, not mistaken for a quiet week');
};

subtest 'a repeat download keeps both copies' => sub {
	my $home = fresh_home('repeat');
	my $ARCHIVE = File::Spec->catdir($home, 'dmarc-archive');
	my $dir = reports_dir('repeat');
	my $report = File::Spec->catfile($dir, 'a.xml');
	write_file($report, report_xml(name => 'a.xml', domain => 'example.org', count => 4));

	my ($status) = run_wrapper(HOME => $home, DMARC_DIR => $dir);
	is($status, 0, 'first week is clean');
	ok(-f File::Spec->catfile($ARCHIVE, 'a.xml'), 'the report was archived');

	# The same report fetched again, which happens when a reporter resends or a
	# download is repeated.  It must not overwrite the copy already there.
	write_file($report, report_xml(name => 'a.xml', domain => 'example.org', count => 9));
	($status) = run_wrapper(HOME => $home, DMARC_DIR => $dir);
	is($status, 0, 'second week is clean too');

	opendir(my $dh, $ARCHIVE) or die "Cannot open $ARCHIVE: $!";
	my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
	closedir($dh);

	is(scalar(@names), 2, 'both copies are kept');
	is($names[0], 'a.xml', 'the first copy keeps the plain name');
	like($names[1], qr/\Aa\.xml\.\d{14}\z/, 'the second gets a timestamp suffix');
	like(slurp(File::Spec->catfile($ARCHIVE, 'a.xml')), qr/<count>4<\/count>/,
		'the first copy is untouched, not overwritten by the repeat');
	like(slurp(File::Spec->catfile($ARCHIVE, $names[1])), qr/<count>9<\/count>/,
		'and the repeat is the one that was kept alongside it');
};

subtest 'a finding is mailed, and names the archive' => sub {
	my $home = fresh_home('finding');
	my $ARCHIVE = File::Spec->catdir($home, 'dmarc-archive');
	my $dir = reports_dir('finding');
	write_file(File::Spec->catfile($dir, 'bad.xml'),
		report_xml(name => 'bad.xml', domain => 'example.org', ip => '203.0.113.7', count => 3));

	my ($status, $out, $err, $mail) = run_wrapper(HOME => $home, DMARC_DIR => $dir);
	is($status, 1, 'exits 1');
	is($err, '', 'nothing on stderr, because a transport was available');
	like($mail, qr/^Subject: .*needs looking at/m, 'the mail has a subject');
	like($mail, qr/203\.0\.113\.7/, 'it carries the finding');
	like($mail, qr/1 report\(s\) moved to \Q$ARCHIVE\E/, 'and says where the reports went');
	ok(-f File::Spec->catfile($ARCHIVE, 'bad.xml'), 'the report was archived');
	like(slurp(File::Spec->catfile($main::HOME, 'dmarc-report.log')), qr/exit 1/,
		'the log records the run even though the mail went out');
};

subtest 'a crontab line can be printed, and nothing is run' => sub {
	my $home = fresh_home('crontab');
	my ($status, $out, $err, $mail) = run_wrapper(['--crontab'],
		HOME => $home, DMARC_EXPECTED => '192.0.2.10', MAIL_TO => 'alerts@example.org');

	is($status, 0, 'it exited 0');
	is($err, '', 'nothing on stderr');
	is($mail, '', 'nothing was mailed');

	like($out, qr/^# /m, 'it explains itself');
	like($out, qr/^\S+ \S+ \S+ \S+ \S+ DMARC_EXPECTED=/m, 'the line starts with the five cron fields');
	my ($command) = $out =~ /^(?:\S+ ){8}(\S+)$/m;
	is($command, abs_path($WRAPPER), 'and runs the wrapper by its full path');
	like($out, qr/\bDMARC_EXPECTED=192\.0\.2\.10\b/, 'with the expected sender');
	like($out, qr/\bMAIL_TO=alerts\@example\.org\b/, 'the address a finding is mailed to');
	like($out, qr/\bPERL=\//, 'and an absolute perl, because cron has no useful PATH');

	# Printing must not be a rehearsal run of the check itself.
	ok(!-e File::Spec->catfile($home, 'dmarc-archive'), 'no archive directory was made');
	ok(!-e File::Spec->catfile($home, 'dmarc-report.log'), 'and nothing was logged');
};

subtest 'the crontab line names a perl that can load XML::PP' => sub {
	plan skip_all => 'no perl on this machine can load XML::PP'
		unless(defined(perl_with_xmlpp()));

	# PERL left out of the environment, so the wrapper has to find one itself:
	# the path it used to assume is somebody else's.
	# The wrapper looks on PATH, under perlbrew and at three fixed places; the
	# perl running these tests is not necessarily in any of them (a smoker
	# starts it by its full path), so its directory is put first on PATH, as
	# it would be for whoever set up the cron job.
	my $home = fresh_home('probed-perl');
	my $found = perl_with_xmlpp();
	my ($status, $out, $err, $mail) = run_wrapper(['--crontab'],
		HOME => $home, PERL => undef, DMARC_EXPECTED => '192.0.2.10',
		MAIL_TO => 'alerts@example.org',
		PATH => dirname($found) . ":$ENV{'PATH'}");

	is($status, 0, 'it exited 0');
	is($err, '', 'nothing on stderr');
	is($mail, '', 'nothing was mailed');

	my ($named) = $out =~ /\bPERL=(\S+)/;
	ok(defined($named), 'the line names a perl');
	return unless(defined($named));

	like($named, qr{\A/}, 'by an absolute path, because cron has no useful PATH');
	ok(can_load_xmlpp($named), "$named is one that can load XML::PP");
	ok(!-e File::Spec->catfile($home, 'dmarc-report.log'), 'and nothing was run');
};

subtest 'the alert is signed by mail-dkim when it is there' => sub {
	plan skip_all => 'openssl is needed to make a key' unless($OPENSSL);
	test_needs 'Mail::DKIM::Signer';

	my $home = fresh_home('signed-alert');
	my $dir = reports_dir('signed-alert');
	write_file(File::Spec->catfile($dir, 'bad.xml'),
		report_xml(name => 'bad.xml', domain => 'example.org', ip => '203.0.113.7', count => 3));

	my $keys = File::Spec->catdir($home, 'keys');
	mkdir($keys) or die "Cannot mkdir $keys: $!";
	system(qq{"$OPENSSL" genrsa -out "$keys/selector1.private" 2048 2>} . File::Spec->devnull()) == 0
		or BAIL_OUT('openssl could not make a key');

	# A sendmail that keeps what it was given, so the message the signer
	# produced can be read rather than inferred.
	my $capture = File::Spec->catfile($home, 'sent.txt');
	my $sendmail = File::Spec->catfile($home, 'sendmail');
	write_file($sendmail, "#!/bin/sh\ncat > \"$capture\"\n");
	chmod(0755, $sendmail) or die "Cannot make $sendmail executable: $!";

	# No MAIL_COMMAND and no MAIL_DKIM: the signer that ships beside the
	# wrapper is the one that has to be found and used.
	my ($status, $out, $err) = run_wrapper(HOME => $home, DMARC_DIR => $dir,
		MAIL_COMMAND => '', DKIM_DOMAINS => 'example.org', DKIM_KEYDIR => $keys,
		MAIL_FROM => 'alerts@example.org', SENDMAIL => $sendmail);

	is($status, 1, 'the finding still sets the exit status');
	is($err, '', 'nothing on stderr: the alert went out') or diag($err);

	my $sent = slurp($capture);
	like($sent, qr/\ADKIM-Signature: /, 'the alert was signed on its way out');
	like($sent, qr/d=example\.org/, 'for the site domain');
	like($sent, qr/s=selector1/, 'with the key that was published');
	like($sent, qr/^From: alerts\@example\.org$/m, 'sent as MAIL_FROM');
	like($sent, qr/^To: /m, 'to the address the alert goes to');
	like($sent, qr/^Subject: /m, 'with the subject line');
	like($sent, qr/203\.0\.113\.7/, 'and it still carries the finding');
};

subtest 'the shipped signer runs under the perl the wrapper uses, not the first one on PATH' => sub {
	plan skip_all => 'openssl is needed to make a key' unless($OPENSSL);
	test_needs 'Mail::DKIM::Signer';

	my $home = fresh_home('signer-perl');
	my $dir = reports_dir('signer-perl');
	write_file(File::Spec->catfile($dir, 'bad.xml'),
		report_xml(name => 'bad.xml', domain => 'example.org', ip => '203.0.113.7', count => 3));

	my $keys = File::Spec->catdir($home, 'keys');
	mkdir($keys) or die "Cannot mkdir $keys: $!";
	system(qq{"$OPENSSL" genrsa -out "$keys/selector1.private" 2048 2>} . File::Spec->devnull()) == 0
		or BAIL_OUT('openssl could not make a key');

	my $capture = File::Spec->catfile($home, 'sent.txt');
	my $sendmail = File::Spec->catfile($home, 'sendmail');
	write_file($sendmail, "#!/bin/sh\ncat > \"$capture\"\n");
	chmod(0755, $sendmail) or die "Cannot make $sendmail executable: $!";

	# A perl first on PATH that has none of the modules, like the system perl
	# on a machine whose modules are in another perl.  The signer starts with
	# "#!/usr/bin/env perl", so left to itself it would run under this one.
	my $decoys = File::Spec->catdir($home, 'decoy-bin');
	mkdir($decoys) or die "Cannot mkdir $decoys: $!";
	my $decoy = File::Spec->catfile($decoys, 'perl');
	write_file($decoy, "#!/bin/sh\necho \"decoy perl was used\" >&2\nexit 127\n");
	chmod(0755, $decoy) or die "Cannot make $decoy executable: $!";

	my ($status, $out, $err) = run_wrapper(HOME => $home, DMARC_DIR => $dir,
		MAIL_COMMAND => '', DKIM_DOMAINS => 'example.org', DKIM_KEYDIR => $keys,
		MAIL_FROM => 'alerts@example.org', SENDMAIL => $sendmail,
		PATH => "$decoys:$ENV{'PATH'}");

	is($status, 1, 'the finding still sets the exit status');
	unlike($err, qr/decoy perl/, 'the perl first on PATH was not used for the signer') or diag($err);
	is($err, '', 'nothing on stderr') or diag($err);
	like(slurp($capture), qr/\ADKIM-Signature: /, 'the alert was signed by the perl the wrapper was given');
};

subtest 'without a signer the alert still goes, by the plain route' => sub {
	my $home = fresh_home('no-signer');
	my $dir = reports_dir('no-signer');
	write_file(File::Spec->catfile($dir, 'bad.xml'),
		report_xml(name => 'bad.xml', domain => 'example.org', ip => '203.0.113.7', count => 3));

	# MAIL_DKIM names a signer that is not there, so the fallback is reached
	# whatever the wrapper's own directory happens to hold.
	my ($status, $out, $err, $mail) = run_wrapper(HOME => $home, DMARC_DIR => $dir,
		MAIL_DKIM => File::Spec->catfile($home, 'no-such-mail-dkim'));

	is($status, 1, 'the finding still sets the exit status');
	is($err, '', 'and the transport it fell back to worked') or diag($err);
	like($mail, qr/^From: /m, 'the fallback was given a From: header');
	like($mail, qr/^Subject: /m, 'and a subject');
	like($mail, qr/203\.0\.113\.7/, 'and the finding is still in the mail');
	unlike($mail, qr/DKIM-Signature/, 'with no signature claiming what did not happen');

	# A signer that is there but cannot sign is the same story: the week's
	# report must not be lost because the key is wrong.
	my $broken = File::Spec->catfile($home, 'broken-mail-dkim');
	write_file($broken, "#!/bin/sh\nexit 1\n");
	chmod(0755, $broken) or die "Cannot make $broken executable: $!";

	my $second = reports_dir('no-signer-broken');
	write_file(File::Spec->catfile($second, 'worse.xml'),
		report_xml(name => 'worse.xml', domain => 'example.org', ip => '198.51.100.23', count => 5));

	($status, $out, $err, $mail) = run_wrapper(HOME => $home, DMARC_DIR => $second, MAIL_DKIM => $broken);

	is($status, 1, 'a signer that fails does not change the status');
	like($mail, qr/198\.51\.100\.23/, 'and the mail went by the fallback anyway');
};

subtest 'the installed wrapper works from a prefix, with no PERL5LIB' => sub {
	# The layout INSTALL_BASE produces: everything in PREFIX/bin, the module in
	# PREFIX/lib/perl5, and nothing on @INC pointing at the prefix.  The wrapper
	# execs the summariser beside itself and, on a finding, the signer beside
	# itself, which in turn has to find the module down in lib/perl5.
	my $prefix = File::Spec->catdir($main::TMP, 'installed-prefix');
	my $bin = File::Spec->catdir($prefix, 'bin');
	my $module_dir = File::Spec->catdir($prefix, 'lib', 'perl5', 'Mail', 'Send');
	make_path($bin, $module_dir) or die "Cannot make the installed prefix: $!";

	my $root = File::Spec->catdir(dirname($WRAPPER), File::Spec->updir());
	foreach my $file (qw(dmarc-weekly.sh dmarc-report.pl mail-dkim)) {
		copy(File::Spec->catfile($root, 'bin', $file), File::Spec->catfile($bin, $file))
			or die "Cannot copy $file into the prefix: $!";
		chmod(0755, File::Spec->catfile($bin, $file))
			or die "Cannot make $file executable: $!";
	}
	copy(File::Spec->catfile($root, 'lib', 'Mail', 'Send', 'DKIM.pm'),
		File::Spec->catfile($module_dir, 'DKIM.pm'))
		or die "Cannot copy the module into the prefix: $!";

	my $installed = File::Spec->catfile($bin, 'dmarc-weekly.sh');
	my $home = fresh_home('installed');
	my $archive = File::Spec->catdir($home, 'dmarc-archive');

	my $clean = reports_dir('installed-clean');
	write_file(File::Spec->catfile($clean, 'ok.xml'),
		report_xml(name => 'ok.xml', domain => 'example.org'));

	my ($status, $out, $err) = run_wrapper(HOME => $home, DMARC_DIR => $clean, program => $installed);
	is($status, 0, 'a clean week from the installed copy exits 0');
	is($out . $err, '', 'and says nothing') or diag($out . $err);
	ok(-f File::Spec->catfile($archive, 'ok.xml'),
		'so the summariser beside it ran, and the report was archived');

	# The alert is the interesting half: the wrapper hands it to the signer
	# beside itself, which loads the module from PREFIX/lib/perl5 or not at all.
	subtest 'the installed copy signs an alert' => sub {
		plan skip_all => 'openssl is needed to make a key' unless($OPENSSL);
		test_needs 'Mail::DKIM::Signer';

		my $keys = File::Spec->catdir($home, 'keys');
		mkdir($keys) or die "Cannot mkdir $keys: $!";
		system(qq{"$OPENSSL" genrsa -out "$keys/selector1.private" 2048 2>} . File::Spec->devnull()) == 0
			or BAIL_OUT('openssl could not make a key');

		my $capture = File::Spec->catfile($home, 'sent.txt');
		my $sendmail = File::Spec->catfile($home, 'sendmail');
		write_file($sendmail, "#!/bin/sh\ncat > \"$capture\"\n");
		chmod(0755, $sendmail) or die "Cannot make $sendmail executable: $!";

		my $finding = reports_dir('installed-finding');
		write_file(File::Spec->catfile($finding, 'bad.xml'),
			report_xml(name => 'bad.xml', domain => 'example.org', ip => '203.0.113.7', count => 3));

		my ($code, $stdout, $stderr) = run_wrapper(HOME => $home, DMARC_DIR => $finding, program => $installed,
			MAIL_COMMAND => '', DKIM_DOMAINS => 'example.org', DKIM_KEYDIR => $keys,
			MAIL_FROM => 'alerts@example.org', SENDMAIL => $sendmail);

		is($code, 1, 'a finding from the installed copy still exits 1');
		is($stderr, '', 'and says nothing on stderr') or diag($stderr);
		like(slurp($capture), qr/\ADKIM-Signature: /,
			'the alert was signed, so the signer found the module under lib/perl5');
	};
};

done_testing();
