#!perl -w

# White-box tests of every routine in Log::Dispatch::Email::DKIM, the
# private helpers included.  Each routine is tested alone: whatever it calls
# (in this module or outside it) is replaced by a Test::Mockingbird mock, so
# a failure points at the routine under test and not at its neighbours.
#
# The POD is the specification.  Most subtests are negative on purpose: they
# feed a routine hostile input, break its collaborators half way through, and
# check that it fails in the way the POD promises (or not at all).

use strict;
use warnings;

# Sub::Private and Sub::Protected stand down when HARNESS_ACTIVE is set, which
# is what lets a white-box test call the private routines.  Set it here so
# that "perl t/function.t" behaves the same as "prove".
BEGIN { $ENV{'HARNESS_ACTIVE'} = 1 }

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use File::Spec;
use File::Temp qw(tempdir);
use Scalar::Util qw(weaken);

BEGIN {
	use_ok('Log::Dispatch::Email::DKIM');
}
require Mail::Send::DKIM;	# loaded here so that its methods can be mocked

# Strings and numbers the tests share, named once
Readonly my $CLASS => 'Log::Dispatch::Email::DKIM';
Readonly my %CFG => (
	'from' => 'webmaster@example.com',
	'to' => 'njh@example.com',
	'subject' => 'Error in shop',
	'message' => "Something went wrong\n",
	'default_sendmail' => '/usr/sbin/sendmail',
	'big_message_size' => 1_000_000,
	'long_text_size' => 100_000,
);
Readonly my @SETTINGS => qw(domain selector keyfile keydir sendmail);
Readonly my %ENV_NAME => (
	'domain' => 'DKIM_DOMAIN', 'selector' => 'DKIM_SELECTOR',
	'keyfile' => 'DKIM_KEYFILE', 'keydir' => 'DKIM_KEYDIR',
	'sendmail' => 'DKIM_SENDMAIL',
);

# A stand-in for an Email::Address::XS object
{
	package FakeAddress;
	sub new { my ($class, %args) = @_; return bless { 'valid' => 1, 'host' => 'example.com', 'address' => 'webmaster@example.com', %args }, $class }
	sub is_valid { return $_[0]{'valid'} }
	sub host { return $_[0]{'host'} }
	sub address { return $_[0]{'address'} }
}

# A subclass is how the protected i18n() is reached from outside
{
	package Reworded;
	our @ISA = ($CLASS);
}

# Diagnostics only when asked for, so a normal run stays quiet
sub verbose_diag { diag(@_) if($ENV{'TEST_VERBOSE'}); return }

# An appender built by hand, so that Log::Dispatch's own constructor is not
# part of what is being tested
sub new_object {
	my %override = @_;

	return bless {
		'from' => $CFG{'from'}, 'to' => [$CFG{'to'}], 'subject' => $CFG{'subject'}, 'buffered' => 0,
		%override,
	}, $CLASS;
}

# Run $code with STDERR collected in a string
sub stderr_of(&) {
	my $code = shift;
	my $text = '';
	{
		local *STDERR;
		open(STDERR, '>', \$text) or BAIL_OUT("cannot capture STDERR: $!");
		$code->();
	}
	return $text;
}

# Run $code and return the warnings it raised
sub warnings_of(&) {
	my $code = shift;
	my @warnings;
	{
		local $SIG{'__WARN__'} = sub { push @warnings, @_ };
		$code->();
	}
	return \@warnings;
}

# Make the named empty files (or directories, with a trailing /) in $dir
sub populate {
	my ($dir, @names) = @_;
	foreach my $name (@names) {
		my $path = File::Spec->catfile($dir, $name);
		if($name =~ s{/\z}{}) {
			mkdir(File::Spec->catdir($dir, $name)) or BAIL_OUT("mkdir $name: $!");
		} else {
			open(my $fh, '>', $path) or BAIL_OUT("cannot write $path: $!");
			close($fh);
		}
	}
	return $dir;
}

# No override from the caller's environment may decide what a test sees
sub clean_environment {
	delete @ENV{values %ENV_NAME};
	return;
}
clean_environment();

my $object = new_object();

# ---------------------------------------------------------------- i18n

subtest 'i18n: turns a key and arguments into text' => sub {
	my $text = $object->i18n('no_key', { 'domain' => 'example.com' });

	is($text, 'DKIM: no DKIM key for example.com; sending unsigned', 'the argument is interpolated');
	returns_ok($text, { 'type' => 'string' }, 'a string is returned');
	is($object->i18n('unknown_domain'), 'unknown domain', 'a message with no arguments needs no arguments hash');
	verbose_diag("i18n said: $text");
};

subtest 'i18n: hostile and incomplete input' => sub {
	local $_ = 'sentinel';
	my $warnings = warnings_of {
		is($object->i18n('no_such_key'), 'no_such_key', 'an unknown key is returned as the text');
		is($object->i18n('%s%n%x'), '%s%n%x', 'a key full of format characters is not used as a format');
		is($object->i18n(''), '', 'an empty key gives an empty text');
		is($object->i18n('no_key'), 'DKIM: no DKIM key for ; sending unsigned', 'a missing argument is empty');
		is($object->i18n('no_key', undef), 'DKIM: no DKIM key for ; sending unsigned', 'undef arguments are accepted');
		is($object->i18n('no_key', { 'domain' => '%s%n%x' }), 'DKIM: no DKIM key for %s%n%x; sending unsigned', 'format characters in an argument are inert');
		is($object->i18n('no_key', { 'domain' => "a\nb" }), "DKIM: no DKIM key for a\nb; sending unsigned", 'a newline in an argument is kept as it is');
		is(length($object->i18n('no_key', { 'domain' => 'x' x $CFG{'long_text_size'} })), 100_000 + length('DKIM: no DKIM key for ; sending unsigned'), 'a very long argument is handled');
	};
	is_deeply($warnings, [], 'none of that warns');
	is($_, 'sentinel', '$_ is left alone');
};

subtest 'i18n: a message with variants that has none to give is not fatal' => sub {
	local $Log::Dispatch::Email::DKIM::MESSAGES{'odd'} = { 'something_else' => ['x'] };
	my $text;
	lives_ok { $text = $object->i18n('odd', { 'count' => 3 }) } 'it does not die';
	is($text, 'odd', 'the key is shown instead, as for an unknown key');
};

subtest 'i18n: uses _choose_variant for the wording' => sub {
	my @seen;
	mock "${CLASS}::_choose_variant" => sub { push @seen, [@_[1 .. $#_]]; return ['chosen %s', 'name'] };

	is($object->i18n('no_key', { 'name' => 'Ann' }), 'chosen Ann', 'the variant it returns is the one formatted');
	is(scalar(@seen), 1, '_choose_variant was called once');
	is_deeply($seen[0][0], ['DKIM: no DKIM key for %s; sending unsigned', 'domain'], 'with the catalogue entry');
	is_deeply($seen[0][1], { 'name' => 'Ann' }, 'and the arguments');

	mock "${CLASS}::_choose_variant" => sub { return undef };
	is($object->i18n('no_key'), 'no_key', 'no usable variant: the key is returned');

	restore_all();
};

subtest 'i18n: plural and gender reach the text' => sub {
	local %Log::Dispatch::Email::DKIM::MESSAGES = (
		%Log::Dispatch::Email::DKIM::MESSAGES,
		'files' => { 'one' => ['%s file', 'count'], 'other' => ['%s files', 'count'], 'feminine' => ['her %s file', 'count'] },
	);
	is($object->i18n('files', { 'count' => 1 }), '1 file', 'one');
	is($object->i18n('files', { 'count' => 5 }), '5 files', 'other');
	is($object->i18n('files', { 'count' => 1, 'gender' => 'feminine' }), 'her 1 file', 'gender');
};

# ------------------------------------------------------- _choose_variant

subtest '_choose_variant: picks a variant' => sub {
	my $plain = ['text %s', 'a'];
	my $variants = { 'one' => ['1'], 'other' => ['n'], 'feminine' => ['f'] };

	is($object->_choose_variant($plain, {}), $plain, 'an array entry comes back as it is (same reference)');
	is_deeply($object->_choose_variant($variants, { 'count' => 1 }), ['1'], 'count 1 is "one"');
	is_deeply($object->_choose_variant($variants, { 'count' => '1.0' }), ['1'], 'the string 1.0 is also one');
	is_deeply($object->_choose_variant($variants, { 'count' => 2 }), ['n'], 'count 2 is "other"');
	is_deeply($object->_choose_variant($variants, { 'count' => 0 }), ['n'], 'count 0 is "other"');
	is_deeply($object->_choose_variant($variants, {}), ['n'], 'no count is "other"');
	is_deeply($object->_choose_variant($variants, { 'count' => 1, 'gender' => 'feminine' }), ['f'], 'gender beats count');
	returns_ok($object->_choose_variant($variants, {}), { 'type' => 'arrayref' }, 'an arrayref is returned');
};

subtest '_choose_variant: hostile input' => sub {
	my $variants = { 'one' => ['1'], 'other' => ['n'] };

	local $_ = 'sentinel';
	my $warnings = warnings_of {
		is_deeply($object->_choose_variant($variants, { 'count' => 'abc' }), ['n'], 'a count that is not a number is not one');
		is_deeply($object->_choose_variant($variants, { 'count' => '' }), ['n'], 'an empty count is not one');
		is_deeply($object->_choose_variant($variants, { 'count' => undef }), ['n'], 'an undef count is not one');
		is_deeply($object->_choose_variant($variants, { 'count' => '1e0' }), ['1'], 'scientific one is one');
		is_deeply($object->_choose_variant($variants, { 'count' => 'NaN' }), ['n'], 'NaN is not one');
		is_deeply($object->_choose_variant($variants, { 'gender' => 'nonexistent' }), ['n'], 'an unknown gender falls back');
		is_deeply($object->_choose_variant($variants, { 'gender' => '__proto__' }), ['n'], 'a hostile gender name is just an unknown one');
		is($object->_choose_variant({ 'x' => ['x'] }, { 'count' => 1 }), undef, 'no variant that applies gives undef');
		is($object->_choose_variant({}, {}), undef, 'an empty hash of variants gives undef');
	};
	is_deeply($warnings, [], 'none of that warns');
	is($_, 'sentinel', '$_ is left alone');
	is_deeply($variants, { 'one' => ['1'], 'other' => ['n'] }, 'the variants were not changed');
};

# ------------------------------------------------------------ _warn_user

subtest '_warn_user: warns with the translated text' => sub {
	my (@carped, @asked);
	mock "${CLASS}::carp" => sub { push @carped, [@_] };
	mock "${CLASS}::i18n" => sub { push @asked, [@_[1 .. $#_]]; return 'TRANSLATED' };

	my $args = { 'domain' => 'example.com' };
	is($object->_warn_user('no_key', $args), $object, 'it returns $self, for chaining');
	is_deeply(\@carped, [['TRANSLATED']], 'carp got exactly the translated text');
	is($asked[0][0], 'no_key', 'i18n was asked for the key');
	is($asked[0][1], $args, 'with the same arguments');

	restore_all();
};

subtest '_warn_user: carp failing is not hidden' => sub {
	mock "${CLASS}::carp" => sub { die "carp exploded\n" };
	mock "${CLASS}::i18n" => sub { 'x' };

	throws_ok { $object->_warn_user('no_key') } qr/\Acarp exploded\n\z/, 'the error reaches the caller';

	restore_all();
};

# ------------------------------------------------------- _say_to_stderr

subtest '_say_to_stderr: writes a line, and does not warn' => sub {
	mock "${CLASS}::i18n" => sub { "TEXT" };

	my $returned;
	my $warnings;
	my $stderr = stderr_of { $warnings = warnings_of { $returned = $object->_say_to_stderr('no_sender') } };

	is($stderr, "TEXT\n", 'one line on STDERR');
	is_deeply($warnings, [], 'and no warning, which a handler could send back to us');
	is($returned, $object, 'it returns $self');

	restore_all();
};

subtest '_say_to_stderr: hostile text and a broken STDERR' => sub {
	mock "${CLASS}::i18n" => sub { "two\nlines %s %n" };
	is(stderr_of { $object->_say_to_stderr('x') }, "two\nlines %s %n\n", 'text is written verbatim, not used as a format');

	mock "${CLASS}::i18n" => sub { 'TEXT' };
	my $survived;
	my $warnings = warnings_of {
		local *STDERR;
		close(STDERR) if(fileno(STDERR));
		$survived = eval { $object->_say_to_stderr('x'); 1 };
	};
	ok($survived, 'a closed STDERR does not make the logger die') or diag($@);
	verbose_diag(explain($warnings));

	restore_all();
};

# --------------------------------------------------- _validated_arguments

subtest '_validated_arguments: hands the arguments to the validator' => sub {
	my (@get_params_args, %validate_args);
	mock "${CLASS}::get_params" => sub { @get_params_args = @_; return { 'message' => 'm' } };
	mock "${CLASS}::validate_strict" => sub { %validate_args = @_; return { 'message' => 'm' } };

	my $arguments = ['message', 'm'];
	my $validated = $object->_validated_arguments('send_email', $arguments);

	is_deeply($validated, { 'message' => 'm' }, 'the validated hash is returned');
	returns_ok($validated, { 'type' => 'hashref' }, 'a hashref');
	is_deeply(\@get_params_args, [undef, $arguments], 'get_params saw undef and the argument list');
	is_deeply($validate_args{'input'}, { 'message' => 'm' }, 'the validator was given what get_params returned');
	is($validate_args{'unknown_parameter_handler'}, 'ignore', 'unknown keys (level, name) are ignored, not rejected');
	is_deeply([keys %{ $validate_args{'schema'} }], ['message'], 'the schema is about the message only');

	restore_all();
};

subtest '_validated_arguments: failures croak in the catalogue words' => sub {
	mock "${CLASS}::get_params" => sub { {} };

	mock "${CLASS}::validate_strict" => sub { die "boom\n" };
	throws_ok { $object->_validated_arguments('send_email', []) }
		qr/\ADKIM: invalid arguments to send_email: boom at /, 'a validator error is reported with its reason, on one line';

	mock "${CLASS}::validate_strict" => sub { return { 'message' => undef } };
	throws_ok { $object->_validated_arguments('send_email', []) }
		qr/\ADKIM: invalid arguments to send_email: message is required at /, 'an undef message is refused';

	mock "${CLASS}::validate_strict" => sub { return {} };
	throws_ok { $object->_validated_arguments('send_email', []) }
		qr/\ADKIM: invalid arguments to send_email: message is required at /, 'a missing message is refused';

	mock "${CLASS}::validate_strict" => sub { return undef };
	throws_ok { $object->_validated_arguments('send_email', []) }
		qr/message is required/, 'a validator that returns nothing is refused too';

	mock "${CLASS}::validate_strict" => sub { return { 'message' => '' } };
	lives_ok { $object->_validated_arguments('send_email', []) } 'an empty message is allowed';

	restore_all();
};

subtest '_validated_arguments: the real validator, hostile input' => sub {
	foreach my $case (
		['no arguments', []],
		['a lone undef', [undef]],
		['an array reference as the message', ['message', []]],
		['a hash reference as the message', ['message', {}]],
		['a code reference as the message', ['message', sub { 1 }]],
		['an undef message', ['message', undef]],
	) {
		my ($name, $arguments) = @{$case};
		my $warnings = warnings_of { throws_ok { $object->_validated_arguments('send_email', $arguments) } qr/\ADKIM: invalid arguments to send_email: /, $name };
		verbose_diag("$name: " . explain($warnings));
	}

	my $big = 'x' x $CFG{'big_message_size'};
	is(length($object->_validated_arguments('send_email', ['message', $big])->{'message'}), $CFG{'big_message_size'}, 'a message of a million characters is accepted whole');
	is($object->_validated_arguments('send_email', [{ 'message' => 'a', 'level' => 'error', 'name' => 'x' }])->{'message'}, 'a', 'extra keys from Log::Dispatch are ignored');
	is($object->_validated_arguments('send_email', ['message', "line\r\nbreak"])->{'message'}, "line\r\nbreak", 'the body is not altered (line breaks are fixed later, by Mail::Send::DKIM)');
};

# -------------------------------------------------------- _parse_address

subtest '_parse_address: uses Email::Address::XS' => sub {
	my @parsed;
	mock 'Email::Address::XS::parse' => sub { push @parsed, [@_[1 .. $#_]]; return (FakeAddress->new()) };

	my $address = $object->_parse_address($CFG{'from'});
	isa_ok($address, 'FakeAddress', 'a valid address is returned as the parser made it');
	is_deeply(\@parsed, [[$CFG{'from'}]], 'the text was handed to the parser');

	mock 'Email::Address::XS::parse' => sub { return (FakeAddress->new('valid' => 0)) };
	is($object->_parse_address('x'), undef, 'an address the parser calls invalid is undef');

	mock 'Email::Address::XS::parse' => sub { return () };
	is($object->_parse_address('x'), undef, 'no address at all is undef');

	restore_all();
};

subtest '_parse_address: the parser is not called with nothing, and cannot make noise' => sub {
	my $calls = 0;
	mock 'Email::Address::XS::parse' => sub { $calls++; warn "parser noise\n"; return () };

	is($object->_parse_address(undef), undef, 'undef');
	is($object->_parse_address(''), undef, 'an empty string');
	is($calls, 0, 'the parser was not called for either');

	my $marker = sub { };
	my $warnings;
	{
		local $SIG{'__WARN__'} = $marker;
		$warnings = warnings_of { $object->_parse_address('x') };
		is($SIG{'__WARN__'}, $marker, 'the caller\'s warn handler is put back');
	}
	is($calls, 1, 'the parser was called for text');
	is_deeply($warnings, [], 'a warning raised by the parser does not escape');

	restore_all();
};

subtest '_parse_address: the real parser, hostile input' => sub {
	my $address = $object->_parse_address('"Web Master" <webmaster@example.com>');
	is($address->address, 'webmaster@example.com', 'a display name is stripped');
	is($object->_parse_address('"a@evil.com" <real@example.com>')->host, 'example.com', 'an @ in the display name does not fool it');

	my $warnings = warnings_of {
		foreach my $junk ("\0", 'a@', '@b', '<>', 'plain text', ',,,', "a\@b\r\nBcc: c\@d", 'x' x $CFG{'long_text_size'}, "\x{1F600}") {
			my $result = eval { $object->_parse_address($junk) };
			ok(!$@, 'does not die') or diag($@);
			ok(!$result || $result->is_valid, 'is undef or a valid address');
		}
	};
	is_deeply($warnings, [], 'no warnings for any of it');
};

# ------------------------------------------------------------- _one_line

subtest '_one_line: flattens line breaks' => sub {
	is($object->_one_line('plain'), 'plain', 'nothing to change');
	is($object->_one_line(''), '', 'empty');
	is($object->_one_line("a\nb"), 'a b', 'LF');
	is($object->_one_line("a\rb"), 'a b', 'CR');
	is($object->_one_line("a\r\nb"), 'a b', 'CRLF is one space, not two');
	is($object->_one_line("a\r\n\r\n\nb"), 'a b', 'a run of breaks is one space');
	is($object->_one_line("\n"), ' ', 'only a break');
	returns_ok($object->_one_line("a\nb"), { 'type' => 'string' }, 'a string');
};

subtest '_one_line: header injection' => sub {
	foreach my $attack ("Hi\r\nBcc: victim\@example.com", "Hi\nBcc: victim\@example.com", "Hi\rBcc: victim\@example.com", "Hi\r\n\r\nbody injected") {
		my $result = $object->_one_line($attack);
		unlike($result, qr/[\r\n]/, 'no line break survives');
	}
	my $original = "a\nb";
	$object->_one_line($original);
	is($original, "a\nb", 'the caller\'s string is not changed in place');

	local $_ = 'sentinel';
	$object->_one_line("a\nb");
	is($_, 'sentinel', '$_ is left alone');
};

# ------------------------------------------------------ _from_environment

subtest '_from_environment: reads the variable that goes with a setting' => sub {
	foreach my $setting (@SETTINGS) {
		local @ENV{values %ENV_NAME};
		delete @ENV{values %ENV_NAME};
		is($object->_from_environment($setting), undef, "$setting: unset is undef");
		$ENV{$ENV_NAME{$setting}} = 'value';
		is($object->_from_environment($setting), 'value', "$setting: set is its value");
	}
};

subtest '_from_environment: empty means unset, and nothing else does' => sub {
	local $ENV{'DKIM_DOMAIN'} = '';
	is($object->_from_environment('domain'), undef, 'an empty string is undef');
	$ENV{'DKIM_DOMAIN'} = '0';
	is($object->_from_environment('domain'), '0', 'the string 0 is a value');
	$ENV{'DKIM_DOMAIN'} = " \n";
	is($object->_from_environment('domain'), " \n", 'white space is a value');
	$ENV{'DKIM_DOMAIN'} = "evil\nBcc: x";
	is($object->_from_environment('domain'), "evil\nBcc: x", 'the value is not altered here (the signer rejects bad domains)');
};

subtest '_from_environment: a setting it does not know croaks' => sub {
	local $_ = 'sentinel';
	foreach my $bad ('bogus', '', 'DOMAIN', 'domain ', '../etc') {
		throws_ok { $object->_from_environment($bad) } qr/\ADKIM: unknown setting \Q$bad\E at /, "'$bad' is refused";
	}
	my $warnings = warnings_of { eval { $object->_from_environment(undef) } };
	like($@, qr/\ADKIM: unknown setting /, 'undef is refused too');
	is($_, 'sentinel', '$_ is left alone');
};

# -------------------------------------------------------- _find_key_file

subtest '_find_key_file: the file named in the environment wins' => sub {
	my $dir = populate(tempdir(CLEANUP => 1), '999.private');
	local $ENV{'DKIM_KEYFILE'} = '/no/such/202611.private';
	local $ENV{'DKIM_KEYDIR'} = $dir;

	is($object->_find_key_file(), '/no/such/202611.private', 'returned as given, even if it does not exist');
};

subtest '_find_key_file: highest name in the key directory' => sub {
	clean_environment();
	my $dir = populate(tempdir(CLEANUP => 1), qw(202611.private 202701.private 202512.private notes.txt 999.pem));
	local $ENV{'DKIM_KEYDIR'} = $dir;

	my $found = $object->_find_key_file();
	is($found, File::Spec->catfile($dir, '202701.private'), 'the highest .private name');
	returns_ok($found, { 'type' => 'string' }, 'a string');
	verbose_diag("found $found");
};

subtest '_find_key_file: nothing usable gives undef' => sub {
	clean_environment();
	my $tmp = tempdir(CLEANUP => 1);
	local $ENV{'DKIM_KEYDIR'} = populate(tempdir(CLEANUP => 1));
	is($object->_find_key_file(), undef, 'an empty directory');

	$ENV{'DKIM_KEYDIR'} = populate(tempdir(CLEANUP => 1), 'readme.txt', 'private', 'x.private.bak');
	is($object->_find_key_file(), undef, 'no file with the suffix');

	$ENV{'DKIM_KEYDIR'} = File::Spec->catdir($tmp, 'missing');
	is($object->_find_key_file(), undef, 'a directory that does not exist');

	$ENV{'DKIM_KEYDIR'} = populate(tempdir(CLEANUP => 1), 'afile');
	$ENV{'DKIM_KEYDIR'} = File::Spec->catfile($ENV{'DKIM_KEYDIR'}, 'afile');
	is($object->_find_key_file(), undef, 'a plain file where the directory should be');
};

subtest '_find_key_file: only regular files are keys' => sub {
	clean_environment();
	my $dir = populate(tempdir(CLEANUP => 1), '202611.private', '999999.private/');
	symlink('/no/such/target', File::Spec->catfile($dir, '999998.private'));
	local $ENV{'DKIM_KEYDIR'} = $dir;

	is($object->_find_key_file(), File::Spec->catfile($dir, '202611.private'), 'a directory and a dangling link with a higher name are passed over');
};

subtest '_find_key_file: awkward directory and file names' => sub {
	clean_environment();
	my $dir = File::Spec->catdir(tempdir(CLEANUP => 1), 'my keys [1] *');
	mkdir($dir) or BAIL_OUT("mkdir: $!");
	populate($dir, 'a b.private', 'z[1].private', '*.private');
	local $ENV{'DKIM_KEYDIR'} = $dir;

	is($object->_find_key_file(), File::Spec->catfile($dir, 'z[1].private'), 'spaces and glob characters are plain characters');
};

subtest '_find_key_file: a directory that cannot be read is no key, not a crash' => sub {
	clean_environment();
	my $dir = populate(tempdir(CLEANUP => 1), '202611.private');
	chmod(0000, $dir);
	local $ENV{'DKIM_KEYDIR'} = $dir;

	SKIP: {
		skip('this user can read a directory with no permissions', 2) if(opendir(my $handle, $dir));
		my $found;
		lives_ok { $found = $object->_find_key_file() } 'no exception from the logger';
		is($found, undef, 'and no key');
	}
	chmod(0700, $dir);
};

subtest '_find_key_file: falls back to ~/dkim, and copes with no home' => sub {
	clean_environment();
	my $home = tempdir(CLEANUP => 1);
	mkdir(File::Spec->catdir($home, 'dkim')) or BAIL_OUT("mkdir: $!");
	populate(File::Spec->catdir($home, 'dkim'), '202611.private');

	mock 'File::HomeDir::my_home' => sub { $home };
	is($object->_find_key_file(), File::Spec->catfile($home, 'dkim', '202611.private'), 'the key in ~/dkim');

	mock 'File::HomeDir::my_home' => sub { undef };
	is($object->_find_key_file(), undef, 'no home directory: no key, and no relative-path surprise');

	local $ENV{'DKIM_KEYDIR'} = '';
	mock 'File::HomeDir::my_home' => sub { $home };
	is($object->_find_key_file(), File::Spec->catfile($home, 'dkim', '202611.private'), 'an empty DKIM_KEYDIR counts as unset');

	restore_all();
};

subtest '_find_key_file: localises $_' => sub {
	clean_environment();
	local $ENV{'DKIM_KEYDIR'} = populate(tempdir(CLEANUP => 1), '1.private', '2.private');
	local $_ = 'sentinel';
	$object->_find_key_file();
	is($_, 'sentinel', '$_ is left alone');
};

# ---------------------------------------------------------- _signing_key

subtest '_signing_key: domain, selector and key file' => sub {
	my %env;
	mock "${CLASS}::_find_key_file" => sub { '/keys/202611.private' };
	mock "${CLASS}::_from_environment" => sub { $env{ $_[1] } };
	my $sender = FakeAddress->new('host' => 'example.com');

	my $key = $object->_signing_key($sender);
	is_deeply($key, { 'domain' => 'example.com', 'selector' => '202611', 'keyfile' => '/keys/202611.private' }, 'the domain from From:, the selector from the file name');
	returns_ok($key, { 'type' => 'hashref' }, 'a hashref');

	%env = ('domain' => 'other.org');
	is($object->_signing_key($sender)->{'domain'}, 'other.org', 'the environment domain wins');
	%env = ('selector' => 'custom');
	is($object->_signing_key($sender)->{'selector'}, 'custom', 'the environment selector wins');

	restore_all();
};

subtest '_signing_key: odd key file names' => sub {
	my $keyfile;
	mock "${CLASS}::_find_key_file" => sub { $keyfile };
	mock "${CLASS}::_from_environment" => sub { undef };
	my $sender = FakeAddress->new();

	$keyfile = undef;
	is_deeply($object->_signing_key($sender), { 'domain' => 'example.com', 'selector' => undef, 'keyfile' => undef }, 'no key: the domain is still known');

	$keyfile = '/keys/mykey.pem';
	is($object->_signing_key($sender)->{'selector'}, undef, 'no .private suffix: no selector');

	$keyfile = '/keys/.private';
	is($object->_signing_key($sender)->{'selector'}, undef, 'an empty selector is none');

	$keyfile = '/keys/a.b.private';
	is($object->_signing_key($sender)->{'selector'}, 'a.b', 'dots inside the name are kept');

	$keyfile = "/keys/20\n26.private";
	is($object->_signing_key($sender)->{'selector'}, undef, 'a line break in the name cannot become part of the signature');

	$keyfile = '/keys/202611.private.bak';
	is($object->_signing_key($sender)->{'selector'}, undef, 'the suffix must be at the end');

	local $_ = 'sentinel';
	$object->_signing_key($sender);
	is($_, 'sentinel', '$_ is left alone');

	restore_all();
};

subtest '_signing_key: a broken sender or lookup is not hidden' => sub {
	mock "${CLASS}::_from_environment" => sub { undef };
	mock "${CLASS}::_find_key_file" => sub { die "disk on fire\n" };
	throws_ok { $object->_signing_key(FakeAddress->new()) } qr/\Adisk on fire\n\z/, 'an error from the key lookup reaches the caller';

	mock "${CLASS}::_find_key_file" => sub { undef };
	throws_ok { $object->_signing_key(undef) } qr/Can't call method "host" on an undefined value/, 'no sender is a programming error, not a silent unsigned mail';

	restore_all();
};

# -------------------------------------------------------- _without_stderr

subtest '_without_stderr: runs the code and returns its result' => sub {
	is($object->_without_stderr(sub { 42 }), 42, 'the result');
	is($object->_without_stderr(sub { 0 }), 0, 'a false result is passed on as false');
	is($object->_without_stderr(sub { undef }), undef, 'an undef result too');
	my @args;
	$object->_without_stderr(sub { @args = @_; 1 });
	is_deeply(\@args, [], 'the code is called with no arguments');
};

subtest '_without_stderr: STDERR is silent inside and restored outside' => sub {
	my $stderr = stderr_of {
		$object->_without_stderr(sub { print STDERR "hidden\n"; 1 });
		print STDERR "visible\n";
	};
	is($stderr, "visible\n", 'only what was written outside the call is seen');
};

subtest '_without_stderr: hostile code' => sub {
	my $stderr = stderr_of {
		throws_ok { $object->_without_stderr(sub { die "inside\n" }) } qr/\Ainside\n\z/, 'an exception passes through';
		print STDERR "after the exception\n";
	};
	is($stderr, "after the exception\n", 'STDERR is restored even then');

	throws_ok { $object->_without_stderr('not code') } qr/Can't use string|Undefined subroutine|Not a CODE reference/, 'something that is not code is refused';
	throws_ok { $object->_without_stderr(undef) } qr/Can't use an undefined value as a subroutine reference/, 'undef is refused';

	$stderr = stderr_of {
		is($object->_without_stderr(sub { $object->_without_stderr(sub { print STDERR "x"; 7 }) }), 7, 'calls can nest');
		print STDERR "ok";
	};
	is($stderr, 'ok', 'and STDERR still comes back');
};

subtest '_without_stderr: no null device means run anyway' => sub {
	mock 'File::Spec::devnull' => sub { '/no/such/directory/null' };
	my $ran = 0;
	my $result;
	my $survived = eval { $result = $object->_without_stderr(sub { $ran++; 'done' }); 1 };
	ok($survived, 'it does not die') or diag($@);
	is($ran, 1, 'the code ran once');
	is($result, 'done', 'and its result came back');
	restore_all();
};

# --------------------------------------------------------------- _deliver

# Everything _deliver talks to is replaced; what it did is written to %seen
{
	my (%seen, @warned, $close_result, $signing_key, $sendmail_env);

	my $arrange = sub {
		%seen = ('new' => [], 'sign' => [], 'send' => []);
		@warned = ();
		$close_result = 0;
		$sendmail_env = undef;
		$signing_key = { 'domain' => 'example.com', 'selector' => '202611', 'keyfile' => $0 };
		mock 'Mail::Send::DKIM::new' => sub { shift; push @{ $seen{'new'} }, {@_}; return bless {}, 'Mail::Send::DKIM' };
		mock 'Mail::Send::DKIM::sign' => sub { shift; push @{ $seen{'sign'} }, [@_]; return "DKIM-Signature: x\n$_[0]" };
		mock 'Mail::Send::DKIM::send' => sub { shift; push @{ $seen{'send'} }, [@_]; return $close_result };
		mock "${CLASS}::_signing_key" => sub { $signing_key };
		mock "${CLASS}::_from_environment" => sub { $sendmail_env };
		mock "${CLASS}::_warn_user" => sub { push @warned, [@_[1 .. $#_]]; $_[0] };
		mock "${CLASS}::_without_stderr" => sub { $_[1]->() };
	};

	subtest '_deliver: builds and sends a signed message' => sub {
		$arrange->();
		local $ENV{'SENDMAIL'};
		my $obj = new_object('to' => ['a@example.com', 'b@example.com']);

		is($obj->_deliver(FakeAddress->new(), $CFG{'message'}), $obj, 'it returns $self');
		is_deeply($seen{'new'}[0], {
			'domains' => ['example.com'], 'signing_domain' => 'example.com', 'selector' => '202611',
			'keyfile' => $0, 'sendmail' => $CFG{'default_sendmail'},
		}, 'Mail::Send::DKIM is given the domain, the key details and the default sendmail');
		my $text = "To: a\@example.com,b\@example.com\nFrom: $CFG{from}\nSubject: $CFG{subject}\n\n$CFG{'message'}";
		is_deeply($seen{'sign'}[0], [$text], 'the headers, a blank line and the body are signed');
		is_deeply($seen{'send'}[0], ["DKIM-Signature: x\n$text", '-t', '-f', 'webmaster@example.com'], 'the signed message goes to sendmail with the bare envelope sender');
		is_deeply(\@warned, [], 'no warning for a signed message');
		verbose_diag(explain(\%seen));
		restore_all();
	};

	subtest '_deliver: sendmail comes from the environment when set' => sub {
		$arrange->();
		$sendmail_env = '/tmp/capture';
		$object->_deliver(FakeAddress->new(), 'm');
		is($seen{'new'}[0]{'sendmail'}, '/tmp/capture', 'DKIM_SENDMAIL is used');
		restore_all();
	};

	subtest '_deliver: SENDMAIL is used when DKIM_SENDMAIL is not set' => sub {
		$arrange->();
		local $ENV{'SENDMAIL'} = '/tmp/plain-sendmail';
		$object->_deliver(FakeAddress->new(), 'm');
		is($seen{'new'}[0]{'sendmail'}, '/tmp/plain-sendmail', 'SENDMAIL is the fallback');

		$sendmail_env = '/tmp/capture';
		$object->_deliver(FakeAddress->new(), 'm');
		is($seen{'new'}[1]{'sendmail'}, '/tmp/capture', 'DKIM_SENDMAIL wins over it');

		$ENV{'SENDMAIL'} = '';
		$sendmail_env = undef;
		$object->_deliver(FakeAddress->new(), 'm');
		is($seen{'new'}[2]{'sendmail'}, $CFG{'default_sendmail'}, 'an empty SENDMAIL counts as unset');
		restore_all();
	};

	subtest '_deliver: unsigned mail is sent with a warning' => sub {
		foreach my $case (
			['no domain', { 'domain' => undef, 'selector' => 's', 'keyfile' => $0 }, 'unknown domain'],
			['no selector', { 'domain' => 'example.com', 'selector' => undef, 'keyfile' => $0 }, 'example.com'],
			['no key file', { 'domain' => 'example.com', 'selector' => 's', 'keyfile' => undef }, 'example.com'],
			['an unreadable key file', { 'domain' => 'example.com', 'selector' => 's', 'keyfile' => '/no/such/key' }, 'example.com'],
			['everything missing', { 'domain' => undef, 'selector' => undef, 'keyfile' => undef }, 'unknown domain'],
		) {
			my ($name, $key, $shown) = @{$case};
			$arrange->();
			$signing_key = $key;
			$object->_deliver(FakeAddress->new(), 'm');
			is(scalar(@{ $seen{'send'} }), 1, "$name: the message is still sent");
			is(scalar(@{ $seen{'sign'} }), 0, "$name: and not signed");
			is_deeply($warned[0], ['no_key', { 'domain' => $shown eq 'unknown domain' ? 'unknown domain' : $shown }], "$name: warns that it is unsigned");
			restore_all();
		}
	};

	subtest '_deliver: a failed send is reported' => sub {
		$arrange->();
		$close_result = 1;
		is($object->_deliver(FakeAddress->new(), 'm'), $object, 'it still returns $self');
		is_deeply(\@warned, [['send_failed', { 'sender' => 'webmaster@example.com' }]], 'one warning, naming the sender');

		$arrange->();
		$close_result = 75;
		$object->_deliver(FakeAddress->new(), 'm');
		is(scalar(@warned), 1, 'sendmail\'s own exit status is a failure too');
		restore_all();
	};

	subtest '_deliver: header injection through every header' => sub {
		$arrange->();
		my $obj = new_object(
			'to' => ["a\@example.com\r\nBcc: victim\@example.com"],
			'from' => "\"X\"\r\nBcc: v\@example.com <webmaster\@example.com>",
			'subject' => "Hi\nBcc: victim\@example.com",
		);
		$obj->_deliver(FakeAddress->new(), 'm');
		my ($headers) = split(/\n\n/, $seen{'send'}[0][0], 2);
		$headers =~ s/\A(?:DKIM-Signature:[^\n]*\n)//;
		is(scalar(() = $headers =~ /\n/g), 2, 'three header lines and no more');
		unlike($headers, qr/^Bcc:/m, 'no header was added');
		restore_all();
	};

	subtest '_deliver: failures from its collaborators are not swallowed' => sub {
		$arrange->();
		mock 'Mail::Send::DKIM::new' => sub { die "from is not a valid envelope sender\n" };
		throws_ok { $object->_deliver(FakeAddress->new(), 'm') } qr/\Afrom is not a valid envelope sender\n\z/, 'an error from Mail::Send::DKIM reaches the caller';

		$arrange->();
		mock "${CLASS}::_signing_key" => sub { die "no key store\n" };
		throws_ok { $object->_deliver(FakeAddress->new(), 'm') } qr/\Ano key store\n\z/, 'an error from the key lookup too';

		$arrange->();
		mock 'Mail::Send::DKIM::send' => sub { die "pipe closed\n" };
		throws_ok { $object->_deliver(FakeAddress->new(), 'm') } qr/\Apipe closed\n\z/, 'and one from sending';

		$arrange->();
		my $survived = eval { new_object('to' => 'not a list')->_deliver(FakeAddress->new(), 'm'); 1 };
		ok(!$survived, 'to that is not a list is refused rather than sent');
		restore_all();
	};
}

# ------------------------------------------------------------- send_email

{
	my (@delivered, @said, $validated, $parsed);

	my $arrange = sub {
		@delivered = (); @said = ();
		$validated = { 'message' => $CFG{'message'} };
		$parsed = FakeAddress->new();
		mock "${CLASS}::_validated_arguments" => sub { $validated };
		mock "${CLASS}::_parse_address" => sub { $parsed };
		mock "${CLASS}::_say_to_stderr" => sub { push @said, $_[1]; $_[0] };
		mock "${CLASS}::_deliver" => sub { push @delivered, [@_[1 .. $#_]]; $_[0] };
	};

	subtest 'send_email: delivers' => sub {
		$arrange->();
		my $obj = new_object();
		is($obj->send_email('message' => 'x'), $obj, 'it returns $self, so calls can be chained');
		returns_ok($obj->send_email('message' => 'x'), { 'type' => 'object', 'isa' => $CLASS }, 'an object of this class');
		is($delivered[0][0], $parsed, 'the parsed sender was passed on');
		is($delivered[0][1], $CFG{'message'}, 'and the validated message');
		is_deeply(\@said, [], 'nothing was said to STDERR');
		restore_all();
	};

	subtest 'send_email: what it hands to its helpers' => sub {
		$arrange->();
		my (@parse_args, @validate_args);
		mock "${CLASS}::_parse_address" => sub { @parse_args = @_[1 .. $#_]; $parsed };
		mock "${CLASS}::_validated_arguments" => sub { @validate_args = @_[1 .. $#_]; $validated };

		new_object()->send_email('message' => 'x', 'level' => 'error');
		is_deeply(\@parse_args, [$CFG{'from'}], 'the From setting is what is parsed');
		is($validate_args[0], 'send_email', 'validation is told the routine name');
		is_deeply($validate_args[1], ['message', 'x', 'level', 'error'], 'and the caller\'s arguments');
		restore_all();
	};

	subtest 'send_email: no recipient means nothing is sent' => sub {
		foreach my $case (['no to', { 'to' => undef }], ['an empty list', { 'to' => [] }], ['a string', { 'to' => 'a@example.com' }], ['a hash', { 'to' => {} }]) {
			my ($name, $override) = @{$case};
			$arrange->();
			my $obj = new_object(%{$override});
			is($obj->send_email('message' => 'x'), $obj, "$name: still returns \$self");
			is_deeply(\@said, ['no_recipient'], "$name: says so on STDERR");
			is(scalar(@delivered), 0, "$name: sends nothing");
			restore_all();
		}
	};

	subtest 'send_email: no usable sender means nothing is sent' => sub {
		$arrange->();
		$parsed = undef;
		my $obj = new_object();
		$obj->send_email('message' => 'x');
		is_deeply(\@said, ['no_sender'], 'says so on STDERR');
		is(scalar(@delivered), 0, 'sends nothing');

		$arrange->();
		$parsed = undef;
		new_object('to' => [])->send_email('message' => 'x');
		is_deeply(\@said, ['no_recipient'], 'with neither, the recipient is reported first');
		restore_all();
	};

	subtest 'send_email: bad arguments stop everything' => sub {
		$arrange->();
		mock "${CLASS}::_validated_arguments" => sub { die "bad arguments\n" };
		throws_ok { $object->send_email() } qr/\Abad arguments\n\z/, 'the error reaches the caller';
		is(scalar(@delivered) + scalar(@said), 0, 'and nothing was delivered or printed');
		restore_all();
	};

	subtest 'send_email: a failing delivery is not hidden' => sub {
		$arrange->();
		mock "${CLASS}::_deliver" => sub { die "sendmail exploded\n" };
		throws_ok { $object->send_email('message' => 'x') } qr/\Asendmail exploded\n\z/, 'the error reaches the caller';

		$arrange->();
		mock "${CLASS}::_parse_address" => sub { die "parser exploded\n" };
		throws_ok { $object->send_email('message' => 'x') } qr/\Aparser exploded\n\z/, 'and so does one from the parser';
		restore_all();
	};

	subtest 'send_email: an empty message is still a message' => sub {
		$arrange->();
		$validated = { 'message' => '' };
		$object->send_email('message' => '');
		is($delivered[0][1], '', 'it is delivered');
		restore_all();
	};
}

# ----------------------------------------------------- memory and cleanup

subtest 'memory: no cycles, and the object is freed' => sub {
	my $obj = new_object();
	mock "${CLASS}::_deliver" => sub { $_[0] };
	$obj->send_email('message' => 'x');
	$obj->i18n('no_key', { 'domain' => 'x' });
	memory_cycle_ok($obj, 'the appender holds no cycle');

	my $weak = $obj;
	weaken($weak);
	undef $obj;
	is($weak, undef, 'and it is freed when the last reference goes');

	restore_all();
};

subtest 'mocks leave nothing behind' => sub {
	restore_all();
	lives_ok { $object->_one_line("a\nb") } 'the real routines are back';
	ok(defined(&Mail::Send::DKIM::send), 'and so are the ones outside this module');
	is($object->i18n('unknown_domain'), 'unknown domain', 'i18n is the real one');
};

done_testing();
