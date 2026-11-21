#!/usr/bin/env perl
#
# White-box tests of every function in lib/Mail/Send/DKIM.pm, helpers included.
#
# Strategy: each function is run on its own.  Whatever it calls - another
# function of the module, a CPAN module, syslog - is replaced with a
# Test::Mockingbird mock, so a failure points at the one function and not at
# its neighbours.  The operating system itself (files, pipes) is not mocked:
# those behaviours are only real when the real thing is used, so sendmail is a
# tiny shell script in a temporary directory.
#
# Most of the tests try to break the code: names starting "FAIL:" feed it
# hostile or broken input, or make what it calls fail half way, and check that
# it fails in the way the POD says (a warning and a status, never an
# exception; or, where an exception is documented, exactly that exception).
#
# Set TEST_VERBOSE to see the internal state at the interesting points.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;

use Errno qw(ENOENT ENOTDIR);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Scalar::Util qw(weaken);
use Time::HiRes qw(time);

use lib File::Spec->catdir($Bin, File::Spec->updir(), 'lib');
use Mail::Send::DKIM;

# The helpers are private to the module.  A test harness switches that
# enforcement off by itself; this does the same when the file is run directly,
# because white-box tests are the one place that may reach them.
{
	no warnings 'once';
	$Sub::Private::BYPASS = 1;
	$Sub::Protected::BYPASS = 1;
}

# Every number and string that a test depends on, in one place.
Readonly my %CONFIG => (
	'SENTINEL' => 'the caller\'s $_',
	'BIG_BYTES' => 3_000_000,	# larger than any pipe buffer
	'MANY' => 5000,	# "many" recipients, domains, files
	'SLOW_SECONDS' => 10,	# no function may take longer than this on the large inputs
	'REFUSED_STATUS' => 75,
	'CALLER_STATUS' => 5,
	'KEEP_ERROR' => 'the caller\'s error',
	'MODE_PLAIN' => 0644,
	'MODE_RUNNABLE' => 0755,
	'MODE_NONE' => 0000,
);

# The environment would otherwise decide what new() builds.
delete @ENV{qw(DKIM_DOMAINS DKIM_KEYDIR DKIM_SELECTOR DKIM_KEYFILE SENDMAIL)};

my $TMP = tempdir('CLEANUP' => 1);

sub verbose
{
	diag(@_) if($ENV{'TEST_VERBOSE'});

	return;
}

# Runs one subtest with no mock left over from the one before, and checks that
# the function under test did not leave $_ changed.
sub scenario
{
	my ($name, $code) = @_;

	subtest $name => sub {
		restore_all();
		local $_ = $CONFIG{'SENTINEL'};
		$code->();
		is($_, $CONFIG{'SENTINEL'}, '$_ is as the caller left it');
		restore_all();
	};

	return;
}

sub new_dkim
{
	my %options = @_;

	return Mail::Send::DKIM->new('keydir' => File::Spec->catdir($TMP, 'no-such-dir'), %options);
}

# Records what carp is asked to say, instead of printing it.
sub capture_carp
{
	my @said;
	mock 'Mail::Send::DKIM::carp' => sub { push(@said, @_) };

	return \@said;
}

# Records the calls to _say, as [key, arguments].
sub capture_say
{
	my @said;
	mock 'Mail::Send::DKIM::_say' => sub { my ($self, $key, $args) = @_; push(@said, [$key, $args]); return $self };

	return \@said;
}

sub write_file
{
	my ($path, $content, $mode) = @_;

	open(my $fh, '>', $path) or BAIL_OUT("Cannot write $path: $!");
	print $fh $content;
	close($fh);
	chmod($mode, $path) or BAIL_OUT("Cannot chmod $path: $!") if(defined($mode));

	return $path;
}

# A sendmail that records its arguments and its input, then exits as told.
sub fake_sendmail
{
	my ($name, $exit_status) = @_;

	my $dir = File::Spec->catdir($TMP, $name);
	mkdir($dir) or BAIL_OUT("Cannot make $dir: $!");

	my $script = File::Spec->catfile($dir, 'sendmail');
	write_file($script, <<"SCRIPT", $CONFIG{'MODE_RUNNABLE'});
#!/bin/sh
cat > "$dir/input"
for arg in "\$@"; do printf '%s\\n' "\$arg" >> "$dir/args"; done
exit $exit_status
SCRIPT

	return ($script, $dir);
}

sub slurp
{
	my $path = shift;

	open(my $fh, '<', $path) or return '';
	local $/;
	my $text = <$fh>;
	close($fh);

	return $text;
}

# Stand-ins for what Mail::DKIM and Mail::Address would return.
{
	package Local::FakeSignature;
	sub new { my ($class, $text) = @_; return bless({ 'text' => $text }, $class) }
	sub as_string { return $_[0]->{'text'} }

	package Local::FakeSigner;
	our %Break;	# which method should die, and with what
	sub new { return bless({ 'printed' => '' }, shift) }
	sub PRINT { my ($self, $text) = @_; die $Break{'PRINT'} if(exists $Break{'PRINT'}); $self->{'printed'} .= $text; return 1 }
	sub CLOSE { die $Break{'CLOSE'} if(exists $Break{'CLOSE'}); return 1 }
	sub signature { return exists($Break{'signature'}) ? $Break{'signature'} : Local::FakeSignature->new('DKIM-Signature: fake') }

	package Local::FakeAddress;
	sub new { my ($class, %fields) = @_; return bless({ %fields }, $class) }
	sub host { return $_[0]->{'host'} }
	sub address { return $_[0]->{'address'} }
}

# ---------------------------------------------------------------------------
# new
# ---------------------------------------------------------------------------

scenario 'new: builds the object from options, then the environment, then defaults' => sub {
	my $dkim = Mail::Send::DKIM->new(
		'domains' => ['Example.ORG', 'example.org', 'EXAMPLE.net', ''],
		'keydir' => '/keys', 'selector' => 's1', 'keyfile' => '/keys/f.private', 'sendmail' => '/bin/sm',
	);

	returns_ok($dkim, { 'type' => 'object', 'isa' => 'Mail::Send::DKIM' }, 'returns the object');
	is_deeply($dkim->{'domains'}, { 'example.org' => 1, 'example.net' => 1 }, 'domains are lower-cased and de-duplicated');
	is($dkim->{'keydir'}, '/keys', 'keydir');
	is($dkim->{'selector'}, 's1', 'selector');
	is($dkim->{'keyfile'}, '/keys/f.private', 'keyfile');
	is($dkim->{'sendmail'}, '/bin/sm', 'sendmail');
	memory_cycle_ok($dkim, 'no reference cycle inside the object');

	{
		local @ENV{qw(DKIM_DOMAINS DKIM_KEYDIR DKIM_SELECTOR DKIM_KEYFILE SENDMAIL)} = ('a.org b.org', '/env/keys', 'envsel', '/env/key', '/env/sendmail');
		my $from_env = Mail::Send::DKIM->new();
		is_deeply($from_env->{'domains'}, { 'a.org' => 1, 'b.org' => 1 }, 'domains from the environment');
		is($from_env->{'keydir'}, '/env/keys', 'keydir from the environment');
		is($from_env->{'selector'}, 'envsel', 'selector from the environment');
		is($from_env->{'keyfile'}, '/env/key', 'keyfile from the environment');
		is($from_env->{'sendmail'}, '/env/sendmail', 'sendmail from the environment');

		my $option_wins = Mail::Send::DKIM->new('keydir' => '/option');
		is($option_wins->{'keydir'}, '/option', 'an option beats the environment');
	}

	my $defaults = Mail::Send::DKIM->new();
	is($defaults->{'sendmail'}, '/usr/sbin/sendmail', 'sendmail defaults to /usr/sbin/sendmail');
	like($defaults->{'keydir'}, qr{/dkim\z}, 'keydir defaults to a directory called dkim');
	is_deeply($defaults->{'domains'}, {}, 'no domains means nothing is signed');

	my $from_hashref = Mail::Send::DKIM->new({ 'domains' => 'h.org' });
	is_deeply($from_hashref->{'domains'}, { 'h.org' => 1 }, 'a hash reference works as well as a hash');
};

scenario 'new: passes the options through Object::Configure and then the validator' => sub {
	my (@configured, @validated);
	mock 'Object::Configure::configure' => sub { my ($class, $params) = @_; push(@configured, [$class, $params]); return { %{$params}, 'keydir' => '/from-config' } };
	mock 'Mail::Send::DKIM::validate_strict' => sub { my %args = @_; push(@validated, \%args); return $args{'input'} };

	my $dkim = Mail::Send::DKIM->new('selector' => 'x');

	is($configured[0][0], 'Mail::Send::DKIM', 'the class is given to configure');
	is($validated[0]{'input'}{'keydir'}, '/from-config', 'what configure returned is what is validated');
	is($validated[0]{'unknown_parameter_handler'}, 'ignore', 'unknown options are ignored, not refused');
	is($dkim->{'keydir'}, '/from-config', 'and what is validated is what is used');
};

scenario 'new: FAIL: a failure in configure or in validation is not swallowed' => sub {
	mock 'Object::Configure::configure' => sub { die "config file is broken\n" };
	throws_ok { Mail::Send::DKIM->new() } qr/\Aconfig file is broken\n\z/, 'configure\'s exception reaches the caller unchanged';
	restore_all();

	throws_ok { Mail::Send::DKIM->new('domains' => {}) } qr/domains/, 'FAIL: domains that are a hash';
	throws_ok { Mail::Send::DKIM->new('keydir' => []) } qr/keydir/, 'FAIL: a keydir that is a list';
	throws_ok { Mail::Send::DKIM->new('messages' => 'text') } qr/messages/, 'FAIL: messages that are a string';
	throws_ok { Mail::Send::DKIM->new('sendmail' => sub { }) } qr/sendmail/, 'FAIL: a sendmail that is code';
	throws_ok { Mail::Send::DKIM->new('home') } qr/./, 'FAIL: an odd number of arguments';
};

scenario 'new: FAIL: hostile environment values and options' => sub {
	local $ENV{'DKIM_DOMAINS'} = "a.org\nb.org\tc.org,,  ,D.ORG,\n";
	my $dkim = Mail::Send::DKIM->new();
	is_deeply($dkim->{'domains'}, { 'a.org' => 1, 'b.org' => 1, 'c.org' => 1, 'd.org' => 1 }, 'newlines, tabs, commas and empty items all separate');

	local $ENV{'DKIM_DOMAINS'} = join(',', map { "d$_.example" } 1 .. $CONFIG{'MANY'});
	my $start = time();
	my $many = Mail::Send::DKIM->new();
	is(scalar(keys %{ $many->{'domains'} }), $CONFIG{'MANY'}, 'thousands of domains are all kept');
	cmp_ok(time() - $start, '<', $CONFIG{'SLOW_SECONDS'}, 'and quickly');

	local $ENV{'DKIM_DOMAINS'} = '';
	is_deeply(Mail::Send::DKIM->new('domains' => undef)->{'domains'}, {}, 'an undef option is "not given"');
	is(Mail::Send::DKIM->new('selector' => '')->{'selector'}, '', 'but an empty string is a value');

	local $ENV{'HOME'} = '';
	like(Mail::Send::DKIM->new()->{'keydir'}, qr{/dkim\z}, 'an empty HOME still gives a key directory');
	delete local $ENV{'HOME'};
	like(Mail::Send::DKIM->new()->{'keydir'}, qr{/dkim\z}, 'so does a missing one');
};

scenario 'new: FAIL: objects share nothing that one of them can corrupt' => sub {
	my $first = new_dkim('messages' => { 'syslog_failed' => 'mine %{error}s' });
	my $second = new_dkim();

	eval { $first->{'messages'}{'keys_ambiguous'}{'one'} = 'EVIL' };
	eval { $first->{'messages'}{'syslog_failed'} = 'EVIL' };

	like($second->i18n('keys_ambiguous', { 'keydir' => 'd', 'count' => 1 }), qr/holds 1 key;/, 'the catalogue of another object is intact');
	like($second->i18n('syslog_failed', { 'error' => 'x' }), qr/cannot write to syslog/, 'and so is the default');
	memory_cycle_ok($first, 'no cycle after the abuse');

	my $weak = new_dkim();
	weaken(my $watch = $weak);
	undef($weak);
	is($watch, undef, 'an object is freed when the last reference goes');
};

# ---------------------------------------------------------------------------
# sign
# ---------------------------------------------------------------------------

scenario 'sign: asks _sign_for only about a domain it signs for' => sub {
	my (@asked, $domain);
	mock 'Mail::Send::DKIM::from_domain' => sub { return $domain };
	mock 'Mail::Send::DKIM::_sign_for' => sub { shift; push(@asked, [@_]); return 'SIGNED' };
	my $dkim = new_dkim('domains' => 'example.org');

	$domain = 'example.org';
	is($dkim->sign('msg'), 'SIGNED', 'a domain of ours: the result of _sign_for');
	is_deeply($asked[0], ['example.org', 'msg'], 'with the domain and the message');
	is($dkim->sign('message' => 'named'), 'SIGNED', 'the message can be named');
	is_deeply($asked[1], ['example.org', 'named'], 'and is the same message');

	@asked = ();
	$domain = 'example.net';
	is($dkim->sign('msg'), undef, 'a domain that is not ours: undef');
	$domain = undef;
	is($dkim->sign('msg'), undef, 'no domain at all: undef');
	is(scalar(@asked), 0, '_sign_for was never asked');
	returns_ok($dkim->sign('msg'), { 'type' => 'string', 'optional' => 1 }, 'the undef agrees with the schema');
};

scenario 'sign: FAIL: bad messages and bad arguments' => sub {
	my @seen;
	mock 'Mail::Send::DKIM::from_domain' => sub { push(@seen, $_[0]); return undef };
	my $dkim = new_dkim('domains' => 'example.org');

	is($dkim->sign(undef), undef, 'undef is no message');
	is($seen[0], '', 'it is looked at as an empty message');
	is($dkim->sign(''), undef, 'and so is the empty string');

	throws_ok { $dkim->sign([]) } qr/message.*must be a string/, 'FAIL: an array reference is refused, with the parameter named';
	throws_ok { $dkim->sign({}) } qr/message|string|hash/i, 'FAIL: so is a hash reference';
	throws_ok { $dkim->sign() } qr/Usage/, 'FAIL: no argument at all gives the usage';
	throws_ok { $dkim->sign('message' => 'x', 'extra' => 1) } qr/./, 'FAIL: an unknown named argument';

	my $big = ('x' x $CONFIG{'BIG_BYTES'});
	my $start = time();
	is($dkim->sign($big), undef, 'a message of megabytes is handled');
	cmp_ok(time() - $start, '<', $CONFIG{'SLOW_SECONDS'}, 'quickly');
	is($dkim->sign("From: a\@example.org\0\n\nbody"), undef, 'a NUL byte does not stop it');
};

scenario 'sign: FAIL: a domain is looked up as a key, never as a pattern or a method' => sub {
	my $domain;
	mock 'Mail::Send::DKIM::from_domain' => sub { return $domain };
	mock 'Mail::Send::DKIM::_sign_for' => sub { return 'SIGNED' };
	my $dkim = new_dkim('domains' => '0');

	$domain = '0';
	is($dkim->sign('m'), 'SIGNED', 'a domain that is false in Perl is still a domain');
	foreach my $hostile ('__proto__', 'constructor', 'ex.*', 'a b', '') {
		$domain = $hostile;
		is($dkim->sign('m'), undef, "'$hostile' is not one of our domains");
	}
};

# ---------------------------------------------------------------------------
# _sign_for
# ---------------------------------------------------------------------------

scenario '_sign_for: finds the key file, and signs only with a readable one' => sub {
	my $keydir = File::Spec->catdir($TMP, 'sf-keys');
	mkdir($keydir);
	my $key = write_file(File::Spec->catfile($keydir, 'sel.private'), 'key');
	my $named = write_file(File::Spec->catfile($TMP, 'named.key'), 'key');
	my @signed;
	mock 'Mail::Send::DKIM::_dkim_sign' => sub { shift; push(@signed, [@_]); return 'SIGNED' };
	mock 'Mail::Send::DKIM::selector' => sub { return 'sel' };

	my $dkim = new_dkim('keydir' => $keydir);
	is($dkim->_sign_for('example.org', 'msg'), 'SIGNED', 'returns what _dkim_sign returns');
	is_deeply($signed[0], ['example.org', 'sel', $key, 'msg'], 'the key is <keydir>/<selector>.private');

	my $with_file = new_dkim('keydir' => $keydir, 'keyfile' => $named);
	$with_file->_sign_for('example.org', 'msg');
	is($signed[1][2], $named, 'a key file named outright beats the directory');
};

scenario '_sign_for: FAIL: no selector, no key, or something that is not a key' => sub {
	my @signed;
	my $selector;
	mock 'Mail::Send::DKIM::_dkim_sign' => sub { push(@signed, 1); return 'SIGNED' };
	mock 'Mail::Send::DKIM::selector' => sub { return $selector };
	my $said = capture_say();
	my $dkim = new_dkim('keydir' => $TMP);

	$selector = undef;
	is($dkim->_sign_for('example.org', 'm'), undef, 'no selector: undef');
	is(scalar(@{$said}), 0, 'and nothing more is said (selector already said why)');

	$selector = 'absent';
	is($dkim->_sign_for('example.org', 'm'), undef, 'no such key file: undef');
	is($said->[0][0], 'key_unreadable', 'with the key_unreadable message');
	is_deeply($said->[0][1], { 'keyfile' => File::Spec->catfile($TMP, 'absent.private'), 'domain' => 'example.org' }, 'naming the file and the domain');

	my $directory = File::Spec->catdir($TMP, 'dir.private');
	mkdir($directory);
	$selector = 'dir';
	is($dkim->_sign_for('example.org', 'm'), undef, 'a directory is not a key');

	SKIP: {
		skip 'root can read anything', 1 if($> == 0);
		write_file(File::Spec->catfile($TMP, 'locked.private'), 'k', $CONFIG{'MODE_NONE'});
		$selector = 'locked';
		is($dkim->_sign_for('example.org', 'm'), undef, 'an unreadable key: undef');
	}

	is(scalar(@signed), 0, 'the signer was never reached for any of them');
	$selector = '../outside';
	is($dkim->_sign_for('example.org', 'm'), undef, 'a selector that climbs out of the directory finds no key, and does not die');
	verbose('said: ' . join(',', map { $_->[0] } @{$said}));
};

# ---------------------------------------------------------------------------
# _dkim_sign
# ---------------------------------------------------------------------------

scenario '_dkim_sign: signs the CRLF form and returns the local form behind the signature' => sub {
	my (%new_args, $signer);
	mock 'Mail::DKIM::Signer::new' => sub { my ($class, %args) = @_; %new_args = %args; return $signer = Local::FakeSigner->new() };
	my $dkim = new_dkim();

	my $result = $dkim->_dkim_sign('example.org', 'sel', '/k/sel.private', "a\r\nb\nc\r\n");

	is($result, "DKIM-Signature: fake\na\nb\nc\n", 'the signature, a newline, then the message with LF endings');
	is($signer->{'printed'}, "a\r\nb\r\nc\r\n", 'the signer saw every line ending as CRLF, none doubled');
	is_deeply(\%new_args, {
		'Algorithm' => 'rsa-sha256', 'Method' => 'relaxed', 'Domain' => 'example.org', 'Selector' => 'sel', 'KeyFile' => '/k/sel.private',
	}, 'rsa-sha256 and relaxed, with the domain, selector and key given');
	returns_ok($result, { 'type' => 'string' }, 'a string');
	memory_cycle_ok($signer, 'the signer is not kept alive by a cycle');

	local $@ = $CONFIG{'KEEP_ERROR'};
	$dkim->_dkim_sign('example.org', 'sel', '/k', 'm');
	is($@, $CONFIG{'KEEP_ERROR'}, '$@ is the caller\'s again afterwards');
};

scenario '_dkim_sign: FAIL: the signer breaks at every step' => sub {
	mock 'Mail::DKIM::Signer::new' => sub { return Local::FakeSigner->new() };
	my $said = capture_say();
	my $dkim = new_dkim();

	foreach my $step (qw(PRINT CLOSE)) {
		local %Local::FakeSigner::Break = ($step => "$step failed \n\n");
		is($dkim->_dkim_sign('example.org', 's', '/k', 'm'), undef, "$step dies: undef, not an exception");
		is_deeply($said->[-1], ['sign_failed', { 'domain' => 'example.org', 'error' => "$step failed" }], 'and the reason, without trailing whitespace, is said');
	}

	{
		local %Local::FakeSigner::Break = ('signature' => undef);
		is($dkim->_dkim_sign('example.org', 's', '/k', 'm'), undef, 'a signer with no signature: undef');
		like($said->[-1][1]{'error'}, qr/\S/, 'and the reason is not empty');
	}

	mock 'Mail::DKIM::Signer::new' => sub { die "cannot load key\n" };
	is($dkim->_dkim_sign('example.org', 's', '/k', 'm'), undef, 'a key that will not load: undef');
	is($said->[-1][1]{'error'}, 'cannot load key', 'with the signer\'s own words');

	mock 'Mail::DKIM::Signer::new' => sub { die { 'code' => 7 } };
	is($dkim->_dkim_sign('example.org', 's', '/k', 'm'), undef, 'an exception that is a reference: undef');

	mock 'Mail::DKIM::Signer::new' => sub { die '' };
	is($dkim->_dkim_sign('example.org', 's', '/k', 'm'), undef, 'an exception with no text: undef');
	like($said->[-1][1]{'error'}, qr/\S/, 'and it still says something');

	my $big = "line\n" x $CONFIG{'BIG_BYTES'};
	mock 'Mail::DKIM::Signer::new' => sub { return Local::FakeSigner->new() };
	like($dkim->_dkim_sign('example.org', 's', '/k', $big), qr/\ADKIM-Signature: fake\nline\n/, 'a message of megabytes is signed');
};

# ---------------------------------------------------------------------------
# send
# ---------------------------------------------------------------------------

scenario 'send: writes the local form to sendmail with the arguments, literally' => sub {
	my ($script, $dir) = fake_sendmail('send-ok', 0);
	my $dkim = new_dkim('sendmail' => $script);
	my $capture = capture_carp();
	my $metachar = '$(touch ' . File::Spec->catfile($dir, 'PWNED') . ');`id`';

	my $status = $dkim->send("a\r\nb\rc\n", '-t', '-f', 'x@example.org', $metachar);

	returns_ok($status, { 'type' => 'integer', 'min' => 0, 'max' => 255 }, 'an exit status');
	is($status, 0, 'sendmail accepted it: 0');
	is(slurp(File::Spec->catfile($dir, 'input')), "a\nb" . "c\n", 'what sendmail read has no carriage return');
	is(slurp(File::Spec->catfile($dir, 'args')), "-t\n-f\nx\@example.org\n$metachar\n", 'the arguments arrived one by one');
	ok(!-e File::Spec->catfile($dir, 'PWNED'), 'FAIL: a shell metacharacter in an argument was not run by a shell');
	is(scalar(@{$capture}), 0, 'nothing was said');
	verbose(slurp(File::Spec->catfile($dir, 'args')));
};

scenario 'send: FAIL: sendmail refuses, dies, or is not there' => sub {
	my $said = capture_say();

	my ($refuse) = fake_sendmail('send-refuse', $CONFIG{'REFUSED_STATUS'});
	is(new_dkim('sendmail' => $refuse)->send("m\n"), $CONFIG{'REFUSED_STATUS'}, 'a refusal is sendmail\'s own status');

	my ($killed_dir) = (File::Spec->catdir($TMP, 'send-killed'));
	mkdir($killed_dir);
	my $killed = write_file(File::Spec->catfile($killed_dir, 'sendmail'), "#!/bin/sh\nkill -9 \$\$\n", $CONFIG{'MODE_RUNNABLE'});
	is(new_dkim('sendmail' => $killed)->send("m\n"), 1, 'a sendmail killed by a signal is 1, never 0');

	my $absent = File::Spec->catfile($TMP, 'no-such', 'sendmail');
	is(new_dkim('sendmail' => $absent)->send("m\n"), 1, 'a sendmail that is not there: 1');
	is($said->[-1][0], 'sendmail_failed', 'with the sendmail_failed message');
	is($said->[-1][1]{'sendmail'}, $absent, 'naming the program');
	{
		local $! = ENOENT;
		is($said->[-1][1]{'os_error'}, "$!", 'and the operating system\'s words');
	}
	is(scalar(@{$said}), 1, 'once');

	my $plain = write_file(File::Spec->catfile($TMP, 'not-executable'), "#!/bin/sh\nexit 0\n", $CONFIG{'MODE_PLAIN'});
	is(new_dkim('sendmail' => $plain)->send("m\n"), 1, 'a file that cannot be run: 1');

	is(new_dkim('sendmail' => $TMP)->send("m\n"), 1, 'a directory: 1');
	is(new_dkim('sendmail' => '')->send("m\n"), 1, 'an empty name: 1');
	{
		local $! = ENOENT;
		is($said->[-1][1]{'os_error'}, "$!", 'and it says the program was not found, not something unrelated');
	}
};

scenario 'send: FAIL: a sendmail that stops reading does not kill the caller, and nothing global is left changed' => sub {
	my ($refuse_early) = (File::Spec->catdir($TMP, 'send-early'));
	mkdir($refuse_early);
	my $script = write_file(File::Spec->catfile($refuse_early, 'sendmail'), "#!/bin/sh\nexit $CONFIG{'REFUSED_STATUS'}\n", $CONFIG{'MODE_RUNNABLE'});
	my $dkim = new_dkim('sendmail' => $script);
	my $big = ('x' x 79 . "\n") x int($CONFIG{'BIG_BYTES'} / 80);

	local $SIG{'PIPE'} = 'DEFAULT';
	local $? = $CONFIG{'CALLER_STATUS'};
	local $@ = $CONFIG{'KEEP_ERROR'};
	is($dkim->send($big), $CONFIG{'REFUSED_STATUS'}, 'the early exit is reported as its status, not as SIGPIPE');
	is($SIG{'PIPE'}, 'DEFAULT', '$SIG{PIPE} is restored');
	is($?, $CONFIG{'CALLER_STATUS'}, '$? is the caller\'s again');
	is($@, $CONFIG{'KEEP_ERROR'}, '$@ is untouched');
};

scenario 'send: FAIL: odd messages' => sub {
	my ($script, $dir) = fake_sendmail('send-odd', 0);
	my $dkim = new_dkim('sendmail' => $script);
	my $capture = capture_carp();

	is($dkim->send(undef), 0, 'an undefined message is sent as an empty one');
	is(slurp(File::Spec->catfile($dir, 'input')), '', 'empty');
	is($dkim->send("a\0b\n"), 0, 'a NUL byte is sent');
	is(slurp(File::Spec->catfile($dir, 'input')), "a\0b\n", 'unchanged');
	is($dkim->send("\r\r\r"), 0, 'a message of only carriage returns');
	is(slurp(File::Spec->catfile($dir, 'input')), '', 'is empty after the local form is made');
	is(scalar(@{$capture}), 0, 'with nothing said');
};

# ---------------------------------------------------------------------------
# log_send
# ---------------------------------------------------------------------------

scenario 'log_send: makes one line from the arguments and the headers, and passes it on' => sub {
	my ($line, $result) = (undef, 1);
	mock 'Mail::Send::DKIM::_write_syslog' => sub { $line = $_[1]; return $result };
	my $dkim = new_dkim();
	my $message = "From: Me <me\@example.org>\nTo: a\@example.net, \"B, C\" <b\@example.net>\nCc: c\@example.net\nBcc: d\@example.net\nSubject: Hello\n  there\n\nbody\n";

	is($dkim->log_send($message, '-t', 'arg@example.net'), 1, 'true when the line was written');
	is($line, 'sender=me@example.org recipient=arg@example.net,a@example.net,b@example.net,c@example.net,d@example.net subject=Hello there',
		'sender from From:, recipients from the arguments then the headers, and a folded subject');

	$dkim->log_send($message, '-f', 'bounce@example.org');
	is($line, 'sender=bounce@example.org recipient=- subject=Hello there', 'with -f the sender is its value, and without -t no header recipients');

	$result = 0;
	is($dkim->log_send($message), 0, 'false when the line could not be written');
	$result = undef;
	is($dkim->log_send($message), 0, 'and an undefined answer counts as false');
	returns_ok($dkim->log_send($message), { 'type' => 'integer', 'min' => 0, 'max' => 1 }, 'always 0 or 1');
};

scenario 'log_send: FAIL: a message cannot forge or flood the log' => sub {
	my $line;
	mock 'Mail::Send::DKIM::_write_syslog' => sub { $line = $_[1]; return 1 };
	my $dkim = new_dkim();

	$dkim->log_send("From: a\@example.org\nSubject: one\x01two\x1b[31m\x7f\n\nb\n", 'r@example.net');
	unlike($line, qr/[[:cntrl:]]/, 'FAIL: control characters in the subject are gone');

	$dkim->log_send("From: a\@example.org\nSubject: x\r\n sender=evil\n\nb\n", "r\@example.net\nsender=evil", "-f\nforged");
	unlike($line, qr/[\r\n]/, 'FAIL: line breaks in the subject and in the arguments are gone');
	is(scalar(split(/\n/, $line)), 1, 'what an attacker typed is data inside the one line');

	$dkim->log_send(undef, '-t');
	is($line, 'sender=- recipient=- subject=-', 'FAIL: an undefined message logs dashes');
	$dkim->log_send('', '-t');
	is($line, 'sender=- recipient=- subject=-', 'FAIL: so does an empty one');
	$dkim->log_send("Subject:\n\nb\n");
	like($line, qr/subject=-\z/, 'FAIL: an empty subject is a dash');

	my @many = map { "r$_\@example.net" } 1 .. $CONFIG{'MANY'};
	my $start = time();
	$dkim->log_send("From: a\@example.org\n\nb\n", @many);
	is(scalar(() = $line =~ /,/g), $CONFIG{'MANY'} - 1, 'FAIL: thousands of recipients are all there');
	cmp_ok(time() - $start, '<', $CONFIG{'SLOW_SECONDS'}, 'and quickly');
};

# ---------------------------------------------------------------------------
# _parse_sendmail_args
# ---------------------------------------------------------------------------

scenario '_parse_sendmail_args: reads the options the way sendmail does' => sub {
	my @cases = (
		# name, arguments, sender, recipients, reads headers
		['nothing', [], undef, [], undef],
		['recipients', ['a@x', 'b@x'], undef, ['a@x', 'b@x'], undef],
		['-t', ['-t'], undef, [], 1],
		['-f separate', ['-f', 's@x', 'r@x'], 's@x', ['r@x'], undef],
		['-f attached', ['-fs@x', 'r@x'], 's@x', ['r@x'], undef],
		['clustered flags', ['-ti'], undef, [], 1],
		['-oi, -odq', ['-oi', '-odq', 'r@x'], undef, ['r@x'], undef],
		['-o separate', ['-o', 'i', 'r@x'], undef, ['r@x'], undef],
		['--', ['--', 'r@x'], undef, ['r@x'], undef],
		['-F value with t', ['-FNigelTest', 'r@x'], undef, ['r@x'], undef],
		['-F separate', ['-F', 'Test Name', 'r@x'], undef, ['r@x'], undef],
		['-bt is not -t', ['-bt'], undef, [], undef],
		['-f takes the next thing, even -t', ['-f', '-t'], '-t', [], undef],
		['-f at the end has no value', ['r@x', '-f'], undef, ['r@x'], undef],
		['empty -f is a null sender', ['-f', ''], '', [], undef],
		['a lone dash is no option and no t', ['-'], undef, [], undef],
		['the last -f wins', ['-fa@x', '-fb@x'], 'b@x', [], undef],
	);

	foreach my $case (@cases) {
		my ($name, $args, $sender, $recipients, $reads) = @{$case};
		my @before = @{$args};
		my $parsed = Mail::Send::DKIM::_parse_sendmail_args($args);

		is($parsed->{'sender'}, $sender, "$name: sender");
		is_deeply($parsed->{'recipients'}, $recipients, "$name: recipients");
		is($parsed->{'reads_headers'}, $reads, "$name: reads headers");
		is_deeply($args, \@before, "$name: the argument list is not changed");
	}

	returns_ok(Mail::Send::DKIM::_parse_sendmail_args([]), { 'type' => 'hashref' }, 'a hash reference');
	my $first = Mail::Send::DKIM::_parse_sendmail_args(['a@x']);
	my $second = Mail::Send::DKIM::_parse_sendmail_args([]);
	is_deeply($second->{'recipients'}, [], 'FAIL: one call leaves nothing behind for the next');
	memory_cycle_ok($first, 'no cycle');
};

# ---------------------------------------------------------------------------
# _write_syslog
# ---------------------------------------------------------------------------

scenario '_write_syslog: opens, writes the line as data, and always closes' => sub {
	my @calls;
	mock 'Sys::Syslog::openlog' => sub { push(@calls, ['openlog', @_]) };
	mock 'Sys::Syslog::syslog' => sub { push(@calls, ['syslog', @_]) };
	mock 'Sys::Syslog::closelog' => sub { push(@calls, ['closelog']) };
	my $dkim = new_dkim();

	is($dkim->_write_syslog('the line'), 1, 'true on success');
	is_deeply(\@calls, [
		['openlog', 'mail-dkim', 'pid,ndelay', 'mail'],
		['syslog', 'info', '%s', 'the line'],
		['closelog'],
	], 'the identity, the options, the facility, the level, then the line, then close');

	@calls = ();
	$dkim->_write_syslog('100%s %n %x');
	is($calls[1][-1], '100%s %n %x', 'FAIL: a line with format characters is data, not a format');
	is($calls[1][2], '%s', 'because the format is fixed');
};

scenario '_write_syslog: FAIL: syslog breaks at each step' => sub {
	my @calls;
	my %die_in;
	mock 'Sys::Syslog::openlog' => sub { push(@calls, 'openlog'); die $die_in{'openlog'} if($die_in{'openlog'}) };
	mock 'Sys::Syslog::syslog' => sub { push(@calls, 'syslog'); die $die_in{'syslog'} if($die_in{'syslog'}) };
	mock 'Sys::Syslog::closelog' => sub { push(@calls, 'closelog'); die $die_in{'closelog'} if($die_in{'closelog'}) };
	my $said = capture_say();
	my $dkim = new_dkim();

	%die_in = ('openlog' => "no socket \n");
	ok(!$dkim->_write_syslog('x'), 'openlog dies: false');
	is_deeply($said->[-1], ['syslog_failed', { 'error' => 'no socket' }], 'with the reason, trimmed');
	is_deeply(\@calls, ['openlog', 'closelog'], 'the connection is still closed, and the line never written');

	@calls = ();
	%die_in = ('syslog' => "refused\n");
	ok(!$dkim->_write_syslog('x'), 'syslog dies: false');
	is_deeply(\@calls, ['openlog', 'syslog', 'closelog'], 'and the connection is closed anyway');

	@calls = ();
	%die_in = ('closelog' => "close failed\n");
	is($dkim->_write_syslog('x'), 1, 'a failure to close does not turn a written line into a failure');
	is(scalar(@{$said}), 2, 'and says nothing about it');

	%die_in = ();
	local $@ = $CONFIG{'KEEP_ERROR'};
	$dkim->_write_syslog('x');
	is($@, $CONFIG{'KEEP_ERROR'}, '$@ is the caller\'s again');
};

# ---------------------------------------------------------------------------
# _parse_headers
# ---------------------------------------------------------------------------

scenario '_parse_headers: the first header of each name, unfolded, names in lower case' => sub {
	my $headers = Mail::Send::DKIM::_parse_headers("From: a\@x\r\nSUBJECT:   one\r\n  two\r\nSubject: second\r\nX-Empty:\r\n\r\nFrom: in-the-body\r\n");

	is_deeply($headers, { 'from' => 'a@x', 'subject' => 'one two', 'x-empty' => '' }, 'unfolded, first wins, the body is not read');
	returns_ok($headers, { 'type' => 'hashref' }, 'a hash reference');
	is_deeply(Mail::Send::DKIM::_parse_headers("A: 1\nB: 2\n"), { 'a' => 1, 'b' => 2 }, 'a message with no blank line is all header');

	$headers->{'from'} = 'changed';
	is(Mail::Send::DKIM::_parse_headers("From: a\@x\n\n")->{'from'}, 'a@x', 'FAIL: changing a result does not change the next one');
	memory_cycle_ok($headers, 'no cycle');
};

scenario '_parse_headers: FAIL: input that is not a header block' => sub {
	is_deeply(Mail::Send::DKIM::_parse_headers(''), {}, 'empty');
	is_deeply(Mail::Send::DKIM::_parse_headers("\n\nFrom: a\@x\n"), {}, 'a message that starts with the blank line has no headers');
	is_deeply(Mail::Send::DKIM::_parse_headers("no colon here\n: no name\n bad continuation\n\n"), {}, 'lines that are not headers are skipped');
	is_deeply(Mail::Send::DKIM::_parse_headers("Fr om: x\n\n"), {}, 'a name with a space is not a name');
	is(Mail::Send::DKIM::_parse_headers("From : a\@x\n\n")->{'from'}, undef, 'nor is one with a space before the colon');
	is_deeply(Mail::Send::DKIM::_parse_headers("A:\0\n\n"), { 'a' => "\0" }, 'a NUL in a value is kept, not fatal');

	my $long = "Subject: " . ('x' x $CONFIG{'BIG_BYTES'}) . "\n\nbody\n";
	my $start = time();
	is(length(Mail::Send::DKIM::_parse_headers($long)->{'subject'}), $CONFIG{'BIG_BYTES'}, 'a header of megabytes is read');
	cmp_ok(time() - $start, '<', $CONFIG{'SLOW_SECONDS'}, 'quickly');

	my $folds = 'Subject: x' . ("\n y" x $CONFIG{'MANY'}) . "\n\n";
	$start = time();
	is(length(Mail::Send::DKIM::_parse_headers($folds)->{'subject'}), 1 + 2 * $CONFIG{'MANY'}, 'thousands of folds are joined');
	cmp_ok(time() - $start, '<', $CONFIG{'SLOW_SECONDS'}, 'quickly');

	my $no_break = 'a' x $CONFIG{'BIG_BYTES'};
	$start = time();
	Mail::Send::DKIM::_parse_headers($no_break);
	cmp_ok(time() - $start, '<', $CONFIG{'SLOW_SECONDS'}, 'a megabytes of text with no line break takes no longer');
};

# ---------------------------------------------------------------------------
# _addresses
# ---------------------------------------------------------------------------

scenario '_addresses: the addresses of a header value, as a list that is never undef' => sub {
	is_deeply(Mail::Send::DKIM::_addresses('A <a@x.org>, "B, C" <b@x.org>, c@x.org (comment)'), ['a@x.org', 'b@x.org', 'c@x.org'], 'names and comments are dropped, a quoted comma does not split');
	returns_ok(Mail::Send::DKIM::_addresses('a@x.org'), { 'type' => 'arrayref' }, 'an array reference');
	is_deeply(Mail::Send::DKIM::_addresses(undef), [], 'FAIL: undef: nothing');
	is_deeply(Mail::Send::DKIM::_addresses(''), [], 'FAIL: empty: nothing');
	is_deeply(Mail::Send::DKIM::_addresses('undisclosed-recipients:;'), [], 'FAIL: an empty group: nothing');
	is_deeply(Mail::Send::DKIM::_addresses('<>'), [], 'FAIL: the null address is no address');
};

scenario '_addresses: FAIL: the parser misbehaves or is fed rubbish' => sub {
	mock 'Mail::Address::parse' => sub { return (Local::FakeAddress->new('address' => undef), Local::FakeAddress->new('address' => ''), Local::FakeAddress->new('address' => 'ok@x.org')) };
	is_deeply(Mail::Send::DKIM::_addresses('anything'), ['ok@x.org'], 'addresses that are undef or empty are dropped');
	restore_all();

	my @rubbish = ('"unbalanced <a@x.org', 'a@@@x', ',,,,', '<<<>>>', "a\@x.org\0b\@y.org", '(((((', 'a@x.org,' x $CONFIG{'MANY'});
	my @warnings;
	local $SIG{'__WARN__'} = sub { push(@warnings, @_) };
	foreach my $value (@rubbish) {
		my $result;
		lives_ok { $result = Mail::Send::DKIM::_addresses($value) } 'does not die on ' . substr($value, 0, 20);
		ok(!grep({ !length } @{$result}), '... and has no empty address');
	}
	is_deeply(\@warnings, [], 'and the parser\'s complaints about them are not passed on');
};

scenario '_parse_addresses: hands the value to Mail::Address, and keeps its complaints to itself' => sub {
	my @given;
	mock 'Mail::Address::parse' => sub { push(@given, [@_]); warn "parser complaint\n"; return (Local::FakeAddress->new('address' => 'a@x.org')) };
	my @warnings;
	local $SIG{'__WARN__'} = sub { push(@warnings, @_) };

	my @found = Mail::Send::DKIM::_parse_addresses('some value');
	is_deeply(\@given, [['Mail::Address', 'some value']], 'the value goes to Mail::Address->parse');
	is(scalar(@found), 1, 'and what it found comes back as a list');
	is_deeply(\@warnings, [], 'FAIL: its warning was not passed on');
	is(ref($SIG{'__WARN__'}), 'CODE', 'the caller\'s warning handler is back afterwards');
};

# ---------------------------------------------------------------------------
# from_domain
# ---------------------------------------------------------------------------

scenario 'from_domain: the lower-case host of the first author address' => sub {
	my ($from, $addresses) = ('x', []);
	mock 'Mail::Send::DKIM::_parse_headers' => sub { return defined($from) ? { 'from' => $from } : {} };
	mock 'Mail::Address::parse' => sub { return @{$addresses} };

	$addresses = [Local::FakeAddress->new('host' => 'Example.ORG'), Local::FakeAddress->new('host' => 'second.org')];
	is(Mail::Send::DKIM::from_domain('m'), 'example.org', 'lower case, and the first address');
	is(Mail::Send::DKIM->from_domain('m'), 'example.org', 'as a class method');
	is(Mail::Send::DKIM::from_domain(new_dkim(), 'm'), 'example.org', 'as an object method');
	returns_ok(Mail::Send::DKIM::from_domain('m'), { 'type' => 'string', 'matches' => qr/\A[a-z0-9.-]+\z/ }, 'a host name');
	verbose('from_domain was given the header: ' . $from);
};

scenario 'from_domain: FAIL: no usable domain' => sub {
	my ($from, $addresses) = ('x', []);
	mock 'Mail::Send::DKIM::_parse_headers' => sub { return defined($from) ? { 'from' => $from } : {} };
	mock 'Mail::Address::parse' => sub { return @{$addresses} };

	$from = undef;
	is(Mail::Send::DKIM::from_domain('m'), undef, 'no From: header: undef');

	$from = 'x';
	$addresses = [];
	is(Mail::Send::DKIM::from_domain('m'), undef, 'the parser finds no address: undef');

	foreach my $host (undef, '', 'exa_mple.org', 'a b.org', "example.org\n", "example.org\0", 'exa/mple', 'b' . "\x{fc}" . 'cher.example', '-', 'a@b') {
		$addresses = [Local::FakeAddress->new('host' => $host)];
		my $shown = defined($host) ? $host : 'undef';
		$shown =~ s/([^ -~])/sprintf('\\x%02x', ord($1))/ge;
		my $got = Mail::Send::DKIM::from_domain('m');
		ok(!defined($got) || $got =~ /\A[a-z0-9.-]+\z/, "'$shown' is not passed on as it is");
	}

	$addresses = [Local::FakeAddress->new('host' => "example.org\n")];
	is(Mail::Send::DKIM::from_domain('m'), undef, 'a trailing newline does not slip past the check');
};

scenario 'from_domain: FAIL: arguments that are not a message' => sub {
	throws_ok { Mail::Send::DKIM::from_domain([]) } qr/message.*must be a string/, 'a reference is refused, naming the parameter';
	is(Mail::Send::DKIM::from_domain(undef), undef, 'undef has no From:');
	is(Mail::Send::DKIM::from_domain(), undef, 'neither has no argument at all');
	is(Mail::Send::DKIM::from_domain("From: evil\@example.org\0\@good.org\n\n"), undef, 'a NUL in the address: no domain is trusted from it');
	is(Mail::Send::DKIM::from_domain("From: a\@example.org\x1b\n\n"), undef, 'nor an escape character');
	is(Mail::Send::DKIM::from_domain("From:\ta\@example.org\n\n"), 'example.org', 'but a tab is ordinary white space');
};

# ---------------------------------------------------------------------------
# selector and _private_keys
# ---------------------------------------------------------------------------

scenario 'selector: the order in which a selector is chosen' => sub {
	my ($keys, $said) = ([], capture_say());
	mock 'Mail::Send::DKIM::_private_keys' => sub { return $keys };

	is(new_dkim('selector' => 'given', 'keyfile' => '/k/other.private')->selector(), 'given', 'a selector that was given');
	is(new_dkim('keyfile' => '/etc/dkim/2026.private')->selector(), '2026', 'else the name of the key file');
	is(new_dkim('keyfile' => '/k/name.key')->selector(), 'name', '.key is not part of the name');
	is(new_dkim('keyfile' => '/k/name.pem')->selector(), 'name', 'nor .pem');
	is(new_dkim('keyfile' => '/k/plain')->selector(), 'plain', 'a name with no suffix is the name');

	$keys = ['only.private'];
	is(new_dkim()->selector(), 'only', 'else the only key in the directory');
	returns_ok(new_dkim()->selector(), { 'type' => 'string', 'optional' => 1 }, 'a string');
	is(scalar(@{$said}), 0, 'nothing was said');
};

scenario 'selector: FAIL: nothing to choose, or too much' => sub {
	my ($keys, $said) = (undef, capture_say());
	mock 'Mail::Send::DKIM::_private_keys' => sub { return $keys };
	my $dkim = new_dkim('keydir' => '/the/dir');

	is($dkim->selector(), undef, 'an unreadable directory: undef');
	is(scalar(@{$said}), 0, 'with nothing more said (_private_keys said why)');

	$keys = [];
	is($dkim->selector(), undef, 'no keys: undef');
	is_deeply($said->[-1], ['keys_ambiguous', { 'keydir' => '/the/dir', 'count' => 0 }], 'with the count of 0');

	$keys = ['a.private', 'b.private'];
	is($dkim->selector(), undef, 'two keys: undef');
	is($said->[-1][1]{'count'}, 2, 'with the count of 2');

	is(new_dkim('selector' => '')->selector(), undef, 'an empty selector is no selector');
	foreach my $keyfile ('/k/.private', '/k/.key', '/', '') {
		my $got = new_dkim('keyfile' => $keyfile)->selector();
		ok(!defined($got) || length($got), "a key file '$keyfile' never gives an empty selector");
	}
	is(new_dkim('keyfile' => '/k/dir/')->selector(), 'dir', 'a trailing slash is not part of the name');
};

scenario '_private_keys: the key files of a directory, sorted' => sub {
	my $dir = File::Spec->catdir($TMP, 'pk-ok');
	mkdir($dir);
	write_file(File::Spec->catfile($dir, $_), 'k') foreach qw(b.private a.private notes.txt);
	my $said = capture_say();

	my $keys = new_dkim('keydir' => $dir)->_private_keys();
	is_deeply($keys, ['a.private', 'b.private'], 'only the .private files, in order');
	returns_ok($keys, { 'type' => 'arrayref' }, 'an array reference');
	is(scalar(@{$said}), 0, 'nothing was said');
	memory_cycle_ok($keys, 'no cycle');
};

scenario '_private_keys: FAIL: directories that are missing, wrong, or full of tricks' => sub {
	my $said = capture_say();
	my $missing = File::Spec->catdir($TMP, 'pk-missing');

	is(new_dkim('keydir' => $missing)->_private_keys(), undef, 'a missing directory: undef');
	is($said->[-1][0], 'keydir_unreadable', 'with the keydir_unreadable message');
	is($said->[-1][1]{'keydir'}, $missing, 'naming the directory');
	{
		local $! = ENOENT;
		is($said->[-1][1]{'os_error'}, "$!", 'and the operating system\'s words');
	}

	my $file = write_file(File::Spec->catfile($TMP, 'pk-a-file'), 'x');
	is(new_dkim('keydir' => $file)->_private_keys(), undef, 'a file where a directory should be: undef');
	{
		local $! = ENOTDIR;
		is($said->[-1][1]{'os_error'}, "$!", 'with the matching words');
	}

	SKIP: {
		skip 'root can read anything', 1 if($> == 0);
		my $locked = File::Spec->catdir($TMP, 'pk-locked');
		mkdir($locked, $CONFIG{'MODE_NONE'});
		is(new_dkim('keydir' => $locked)->_private_keys(), undef, 'a directory that may not be read: undef');
		chmod($CONFIG{'MODE_RUNNABLE'}, $locked);
	}

	my $tricks = File::Spec->catdir($TMP, 'pk-tricks');
	mkdir($tricks);
	mkdir(File::Spec->catdir($tricks, 'dir.private'));
	write_file(File::Spec->catfile($tricks, '.private'), 'k');
	write_file(File::Spec->catfile($tricks, 'real.private.bak'), 'k');
	write_file(File::Spec->catfile($tricks, 'real.PRIVATE'), 'k');
	write_file(File::Spec->catfile($tricks, "new\nline.private"), 'k');
	is_deeply(new_dkim('keydir' => $tricks)->_private_keys(), ["new\nline.private"], 'a directory, a bare .private, and near misses are not keys');

	my $crowd = File::Spec->catdir($TMP, 'pk-crowd');
	mkdir($crowd);
	write_file(File::Spec->catfile($crowd, sprintf('k%05d.private', $_)), '') foreach (1 .. $CONFIG{'MANY'});
	my $start = time();
	my $keys = new_dkim('keydir' => $crowd)->_private_keys();
	is(scalar(@{$keys}), $CONFIG{'MANY'}, 'thousands of keys are listed');
	is($keys->[0], 'k00001.private', 'in order');
	cmp_ok(time() - $start, '<', $CONFIG{'SLOW_SECONDS'}, 'quickly');

	SKIP: {
		skip 'no /proc/self/fd to count descriptors with', 1 unless(-d '/proc/self/fd');
		my $before = () = glob('/proc/self/fd/*');
		new_dkim('keydir' => $crowd)->_private_keys() for (1 .. 20);
		new_dkim('keydir' => $missing)->_private_keys() for (1 .. 20);
		my $after = () = glob('/proc/self/fd/*');
		is($after, $before, 'no directory handle is left open');
	}
};

# ---------------------------------------------------------------------------
# i18n, _choose_format, _interpolate
# ---------------------------------------------------------------------------

scenario 'i18n: picks the format, then fills it in' => sub {
	my @calls;
	mock 'Mail::Send::DKIM::_choose_format' => sub { push(@calls, ['choose', @_]); return 'FORMAT' };
	mock 'Mail::Send::DKIM::_interpolate' => sub { my ($self, $key, $format, $args) = @_; push(@calls, ['interpolate', $key, $format, $args]); return 'TEXT' };
	my $dkim = new_dkim('messages' => { 'mine' => 'my entry' });
	my $args = { 'a' => 1 };

	is($dkim->i18n('mine', $args), 'TEXT', 'the filled-in text');
	is($calls[0][1], 'my entry', 'the entry of the object\'s own catalogue was chosen from');
	is($calls[0][2], $args, 'with the arguments');
	is_deeply($calls[1], ['interpolate', 'mine', 'FORMAT', $args], 'and what was chosen is what is filled in');

	$dkim->i18n('syslog_failed', { 'error' => 'x' });
	like($calls[2][1], qr/cannot write to syslog/, 'a message the object does not override comes from the default catalogue');
	returns_ok($dkim->i18n('mine'), { 'type' => 'string' }, 'a string');
};

scenario 'i18n: FAIL: a message that is not there, or arguments that are not right' => sub {
	my $dkim = new_dkim();

	throws_ok { $dkim->i18n('no_such_key') } qr/\AMail::Send::DKIM: no message is defined for the key "no_such_key" at /, 'FAIL: an unknown key, with exactly this text';
	throws_ok { $dkim->i18n(undef) } qr/no message is defined for the key ""/, 'FAIL: an undefined key is an unknown key, not a Perl warning';
	throws_ok { $dkim->i18n("a\nb") } qr/no message is defined for the key "a\nb"/, 'FAIL: a key with a newline is quoted, not interpreted';
	throws_ok { $dkim->i18n('__proto__') } qr/no message is defined/, 'FAIL: a key that looks like a prototype';
	throws_ok { $dkim->i18n('syslog_failed', []) } qr/\AMail::Send::DKIM: the arguments of a message must be a hash reference, not ARRAY at /, 'FAIL: arguments that are an array';
	throws_ok { $dkim->i18n('syslog_failed', 'text') } qr/not a plain value at /, 'FAIL: arguments that are a string';
	throws_ok { $dkim->i18n('syslog_failed', {}) } qr/\AMail::Send::DKIM: the message "syslog_failed" needs the argument "error" at /, 'FAIL: a missing argument, named';

	my $blanked = new_dkim('messages' => { 'unknown_message' => undef, 'bad_arguments' => undef });
	throws_ok { $blanked->i18n('no_such_key') } qr/no message is defined/, 'FAIL: a catalogue cannot blank the message about missing messages';
	throws_ok { $blanked->i18n('syslog_failed', []) } qr/must be a hash reference/, 'FAIL: nor the one about bad arguments';
};

scenario '_choose_format: a string stays, a hash is chosen from' => sub {
	is(Mail::Send::DKIM::_choose_format('plain', {}), 'plain', 'a string is the format');

	my $entry = { 'zero' => 'Z', 'one' => 'O', 'other' => 'M', 'f' => 'F', 'f.one' => 'F1', 'f.other' => 'FM' };
	my @table = (
		[{ 'count' => 0 }, 'Z'], [{ 'count' => 1 }, 'O'], [{ 'count' => 2 }, 'M'], [{ 'count' => -1 }, 'M'], [{ 'count' => 1.5 }, 'M'],
		[{ 'count' => '1' }, 'O'], [{ 'count' => '0.0' }, 'Z'], [{}, 'M'],
		[{ 'variant' => 'f' }, 'F'], [{ 'variant' => 'f', 'count' => 1 }, 'F1'], [{ 'variant' => 'f', 'count' => 5 }, 'FM'],
		[{ 'variant' => 'f', 'count' => 0 }, 'F'], [{ 'variant' => 'm', 'count' => 1 }, 'O'],
	);
	foreach my $row (@table) {
		is(Mail::Send::DKIM::_choose_format($entry, $row->[0]), $row->[1], join(',', map { "$_=$row->[0]{$_}" } sort keys %{ $row->[0] }) || 'no arguments');
	}
	returns_ok(Mail::Send::DKIM::_choose_format($entry, {}), { 'type' => 'string' }, 'a string');
};

scenario '_choose_format: FAIL: counts and entries that make no sense' => sub {
	my @warnings;
	local $SIG{'__WARN__'} = sub { push(@warnings, @_) };
	my $entry = { 'one' => 'O', 'other' => 'M' };

	foreach my $count ('abc', '', 'NaN-ish', '1e', [], undef, "1\n") {
		my $shown = defined($count) ? (ref($count) || $count) : 'undef';
		$shown =~ s/\n/\\n/;
		my $got = Mail::Send::DKIM::_choose_format($entry, { 'count' => $count });
		ok($got eq 'M' || $got eq 'O', "count '$shown' gives a form, and not a failure");
	}
	is(Mail::Send::DKIM::_choose_format({}, { 'count' => 1 }), '', 'an empty entry says nothing');
	is(Mail::Send::DKIM::_choose_format({ 'other' => undef }, {}), '', 'an entry that is undef says nothing');
	is(Mail::Send::DKIM::_choose_format({ 'weird' => 'W' }, { 'count' => 3 }), 'W', 'with no usable form, any form is better than none');
	is(Mail::Send::DKIM::_choose_format($entry, { 'variant' => '.*' }), 'M', 'a variant is a name, never a pattern');
	is_deeply(\@warnings, [], 'and none of it made Perl warn');
};

scenario '_interpolate: named placeholders become sprintf arguments' => sub {
	my $dkim = new_dkim();

	is($dkim->_interpolate('k', 'plain text', {}), 'plain text', 'no placeholder');
	is($dkim->_interpolate('k', '%{a}s-%{b}d', { 'a' => 'x', 'b' => 7 }), 'x-7', 'two placeholders');
	is($dkim->_interpolate('k', '%{a}s %{a}s', { 'a' => 'x' }), 'x x', 'the same name twice');
	is($dkim->_interpolate('k', '[%{a}-4s][%{b}04d]', { 'a' => 'x', 'b' => 7 }), '[x   ][0007]', 'flags and width');
	is($dkim->_interpolate('k', '100%% %{a}s', { 'a' => 'x' }), '100% x', 'a doubled percent is one percent');
	is($dkim->_interpolate('k', '%{a}s', { 'a' => 'x', 'unused' => 1 }), 'x', 'an argument nobody asked for is ignored');
	returns_ok($dkim->_interpolate('k', 'x', {}), { 'type' => 'string' }, 'a string');
};

scenario '_interpolate: FAIL: values and formats that try to be something else' => sub {
	my $dkim = new_dkim();
	my @warnings;
	local $SIG{'__WARN__'} = sub { push(@warnings, @_) };

	is($dkim->_interpolate('k', '%{a}s', { 'a' => '%s%n%{b}s' }), '%s%n%{b}s', 'FAIL: a value that looks like a format is data');
	is($dkim->_interpolate('k', '<%{a}s>', { 'a' => undef }), '<>', 'FAIL: an undef value is empty, without a warning');
	is($dkim->_interpolate('k', '<%{a}s>', { 'a' => "x\0y\n" }), "<x\0y\n>", 'FAIL: NUL and newline pass through');
	is($dkim->_interpolate('k', '%{a}s', { 'a' => 'x' x $CONFIG{'BIG_BYTES'} }) =~ tr/x//, $CONFIG{'BIG_BYTES'}, 'FAIL: a value of megabytes');
	is($dkim->_interpolate('k', '%{ a}s %{a b}s %{}s', { 'a' => 'x' }), '%{ a}s %{a b}s %{}s', 'FAIL: a placeholder with an odd name is left as written');
	is_deeply(\@warnings, [], 'and none of it made Perl warn');

	my @said;
	mock 'Mail::Send::DKIM::i18n' => sub { my ($self, $key, $args) = @_; push(@said, [$key, $args]); return "MISSING:$args->{'argument'}" };
	throws_ok { $dkim->_interpolate('k', '%{a}s %{b}s', { 'a' => 1 }) } qr/\AMISSING:b at /, 'FAIL: a missing argument croaks with the missing_argument message';
	is_deeply($said[0], ['missing_argument', { 'key' => 'k', 'argument' => 'b' }], 'naming the message and the argument');
	throws_ok { $dkim->_interpolate('k', '%{a}s', {}) } qr/MISSING:a/, 'FAIL: an empty argument hash is not a free pass';
};

# ---------------------------------------------------------------------------
# _say
# ---------------------------------------------------------------------------

scenario '_say: warns with the catalogue\'s text and chains' => sub {
	my $capture = capture_carp();
	mock 'Mail::Send::DKIM::i18n' => sub { my ($self, $key, $args) = @_; return "TEXT($key,$args->{'x'})" };
	my $dkim = new_dkim();

	is($dkim->_say('some_key', { 'x' => 1 }), $dkim, 'returns the object, so calls chain');
	is_deeply($capture, ['TEXT(some_key,1)'], 'what carp was given is the text i18n made');
};

scenario '_say: FAIL: an unknown message is an exception, not a warning' => sub {
	my $capture = capture_carp();
	my $dkim = new_dkim();

	throws_ok { $dkim->_say('no_such_key') } qr/no message is defined for the key "no_such_key"/, 'FAIL: the exception of i18n is not swallowed';
	is(scalar(@{$capture}), 0, 'and nothing was warned');
	throws_ok { $dkim->_say('syslog_failed') } qr/needs the argument "error"/, 'FAIL: nor is a missing argument';
};

# ---------------------------------------------------------------------------
# _local, _domain_set, _trim_error
# ---------------------------------------------------------------------------

scenario '_local: removes every carriage return and nothing else' => sub {
	is(Mail::Send::DKIM::_local("a\r\nb\rc\n"), "a\nbc\n", 'CRLF becomes LF, a lone CR goes');
	is(Mail::Send::DKIM::_local(''), '', 'empty');
	is(Mail::Send::DKIM::_local("\0\t \x{e9}\n"), "\0\t \x{e9}\n", 'other characters stay');
	returns_ok(Mail::Send::DKIM::_local('x'), { 'type' => 'string' }, 'a string');

	my $original = "a\r\n";
	Mail::Send::DKIM::_local($original);
	is($original, "a\r\n", 'FAIL: the caller\'s own copy is not changed');
	is(Mail::Send::DKIM::_local("\r" x $CONFIG{'BIG_BYTES'}), '', 'FAIL: megabytes of carriage returns');
	is(Mail::Send::DKIM::_local("\x{1F600}\r"), "\x{1F600}", 'FAIL: wide characters survive');
};

scenario '_domain_set: a set of lower-case domains from a list or a string' => sub {
	is_deeply(Mail::Send::DKIM::_domain_set('A.org, b.org  C.org'), { 'a.org' => 1, 'b.org' => 1, 'c.org' => 1 }, 'a string, split on commas and spaces');
	is_deeply(Mail::Send::DKIM::_domain_set(['A.org', 'a.org']), { 'a.org' => 1 }, 'a list, folded to lower case and de-duplicated');
	returns_ok(Mail::Send::DKIM::_domain_set('a.org'), { 'type' => 'hashref' }, 'a hash reference');

	my $list = ['A.org'];
	Mail::Send::DKIM::_domain_set($list);
	is_deeply($list, ['A.org'], 'FAIL: the caller\'s list is not changed');
	is_deeply(Mail::Send::DKIM::_domain_set(undef), {}, 'FAIL: undef: none');
	is_deeply(Mail::Send::DKIM::_domain_set(''), {}, 'FAIL: empty: none');
	is_deeply(Mail::Send::DKIM::_domain_set(" ,\t,\n, "), {}, 'FAIL: only separators: none');
	is_deeply(Mail::Send::DKIM::_domain_set([undef, '', 'a.org', undef]), { 'a.org' => 1 }, 'FAIL: undef items in a list are skipped, without a warning');
	is_deeply(Mail::Send::DKIM::_domain_set([]), {}, 'FAIL: an empty list: none');
	is_deeply(Mail::Send::DKIM::_domain_set(['a.org b.org']), { 'a.org b.org' => 1 }, 'an item of a list is one domain, not split again');
};

scenario '_trim_error: removes trailing whitespace and leaves the rest' => sub {
	is(Mail::Send::DKIM::_trim_error("boom at x line 1.\n"), 'boom at x line 1.', 'a trailing newline');
	is(Mail::Send::DKIM::_trim_error("a\nb \t\r\n\n"), "a\nb", 'a run of whitespace, and inner lines are kept');
	is(Mail::Send::DKIM::_trim_error('  keep leading'), '  keep leading', 'leading space is kept');
	is(Mail::Send::DKIM::_trim_error(''), '', 'FAIL: empty');
	is(Mail::Send::DKIM::_trim_error(" \n\t"), '', 'FAIL: only whitespace');
	is(Mail::Send::DKIM::_trim_error("x" . (" " x $CONFIG{'BIG_BYTES'})), 'x', 'FAIL: megabytes of trailing spaces, quickly');
	like(Mail::Send::DKIM::_trim_error({}), qr/\AHASH\(0x[0-9a-f]+\)\z/, 'FAIL: an exception object is turned into text');
};

# ---------------------------------------------------------------------------
# Hostile input, end to end through the real helpers
# ---------------------------------------------------------------------------

scenario 'sign: FAIL: hostile messages through the real helpers never raise, and never sign without a key' => sub {
	my @warnings;
	local $SIG{'__WARN__'} = sub { push(@warnings, @_) };
	my $dkim = new_dkim('domains' => 'example.org');
	my %hostile = (
		'only carriage returns' => "\r\r\r",
		'From with no address' => "From:\n\nb\n",
		'From with only a display name' => "From: Somebody\n\nb\n",
		'From with an empty address' => "From: <>\n\nb\n",
		'From with a missing domain' => "From: a\@\n\nb\n",
		'From with two @ signs' => "From: a\@b\@example.org\n\nb\n",
		'From with an escape character' => "From: a\@example.org\x1b[0m\n\nb\n",
		'From with a NUL' => "From: a\@example.org\0\n\nb\n",
		'From with a trailing dot' => "From: a\@example.org.\n\nb\n",
		'From with a huge domain' => "From: a\@" . ('a' x $CONFIG{'BIG_BYTES'}) . ".org\n\nb\n",
		'a thousand From headers' => ("From: a\@example.net\n" x 1000) . "\nb\n",
		'a message of only separators' => "\n\n\n\n",
		'header names that are not names' => ": x\n:\n \n\t\n\nb\n",
		'a body that looks like a header' => "Subject: x\n\nFrom: a\@example.org\n",
	);

	foreach my $name (sort keys %hostile) {
		my $result;
		lives_ok { $result = $dkim->sign($hostile{$name}) } "$name: no exception";
		is($result, undef, "$name: not signed");
	}

	my $without_key = "From: a\@example.org\n\nb\n";
	is($dkim->sign($without_key), undef, 'a message from our domain with no key directory is not signed');
	like(join('', @warnings), qr/cannot read|no readable key/, 'and the reason was said');
	verbose(scalar(@warnings) . ' warnings: ' . join(' | ', map { s/\s+\z//r } @warnings));
};

scenario 'send and log_send: FAIL: hostile arguments do not raise and do not reach a shell' => sub {
	my ($script, $dir) = fake_sendmail('hostile-args', 0);
	my $dkim = new_dkim('sendmail' => $script);
	my @lines;
	mock 'Mail::Send::DKIM::_write_syslog' => sub { push(@lines, $_[1]); return 1 };
	my @warnings;
	local $SIG{'__WARN__'} = sub { push(@warnings, @_) };

	my @arguments = ('', ' ', "-t\n", '-f' . ("x" x 10_000), "\0", '--', '-', '$(id)', '`id`', '; id', '| id', "> $TMP/never", "a'b\"c");
	foreach my $argument (@arguments) {
		my $shown = $argument;
		$shown =~ s/([^ -~])/sprintf('\\x%02x', ord($1))/ge;
		$shown = substr($shown, 0, 20);
		my ($status, $logged);
		lives_ok { $status = $dkim->send("m\n", $argument) } "send with '$shown': no exception";
		lives_ok { $logged = $dkim->log_send("From: a\@example.org\n\nm\n", $argument) } "log_send with '$shown': no exception";
		is($logged, 1, "log_send with '$shown' still logs");
		unlike($lines[-1], qr/[[:cntrl:]]/, "and the line has no control character");
	}
	ok(!-e File::Spec->catfile($TMP, 'never'), 'nothing was redirected into a file');
	is_deeply(\@warnings, [], 'and Perl did not warn about any of it') or diag(join('', @warnings));
};

scenario 'i18n: FAIL: a thousand hostile keys and argument names' => sub {
	my $dkim = new_dkim();
	my @keys = ('', ' ', '0', '%s', '%{x}s', '${x}', '@{[ 1 ]}', '../etc/passwd', "a\0b", 'k' x 10_000, 'SYSLOG_FAILED', 'Syslog_Failed', 'syslog_failed ', ' syslog_failed');

	foreach my $key (@keys) {
		my $shown = substr($key =~ s/([^ -~])/sprintf('\\x%02x', ord($1))/ger, 0, 20);
		throws_ok { $dkim->i18n($key) } qr/\AMail::Send::DKIM: no message is defined for the key "/, "key '$shown' is not a message";
	}

	my $args = { 'error' => '%{error}s' };
	is($dkim->i18n('syslog_failed', $args), 'Mail::Send::DKIM: cannot write to syslog: %{error}s', 'a value that is itself a placeholder is not expanded a second time');
	lives_ok { $dkim->i18n('syslog_failed', { 'error' => 'x', "evil\n" => 1, '' => 2 }) } 'argument names that mean nothing are ignored';
};

scenario '_parse_sendmail_args: FAIL: arguments that are empty, huge or odd' => sub {
	my @flags = ('-' . ('t' x $CONFIG{'MANY'}), '-' . ('i' x $CONFIG{'MANY'}));
	my $start = time();
	my $parsed = Mail::Send::DKIM::_parse_sendmail_args([@flags]);
	is($parsed->{'reads_headers'}, 1, 'thousands of letters in one flag cluster');
	cmp_ok(time() - $start, '<', $CONFIG{'SLOW_SECONDS'}, 'quickly');

	$parsed = Mail::Send::DKIM::_parse_sendmail_args(['', 'a@x', '']);
	is_deeply($parsed->{'recipients'}, ['a@x'], 'an empty argument names nobody');

	$parsed = Mail::Send::DKIM::_parse_sendmail_args([map { "r$_\@x" } 1 .. $CONFIG{'MANY'}]);
	is(scalar(@{ $parsed->{'recipients'} }), $CONFIG{'MANY'}, 'thousands of recipients');

	$parsed = Mail::Send::DKIM::_parse_sendmail_args(["-f\n", "-t\0"]);
	is($parsed->{'sender'}, "\n", 'a newline as the value of -f is kept as data');
	is($parsed->{'reads_headers'}, 1, 'a NUL in a cluster of flags does not hide the t');

	$parsed = Mail::Send::DKIM::_parse_sendmail_args(['-f', '-f', '-f']);
	is($parsed->{'sender'}, '-f', '-f -f: the second -f is the value');
	is_deeply($parsed->{'recipients'}, [], 'and a third -f with no value names nobody');
	lives_ok { Mail::Send::DKIM::_parse_sendmail_args([]) } 'an empty list is fine';
};

done_testing();
