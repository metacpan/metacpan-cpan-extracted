#!perl -w

# White-box tests of the encapsulation, the i18n catalogue and the fixes made
# in the refactor: header injection, display names in From:, a missing HOME,
# and key directories whose names glob() would mangle.

use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

# Loaded at compile time, as production code does, so the private subs are
# wrapped before the test's own subs are compiled into the same package
BEGIN {
	use_ok('Log::Dispatch::Email::DKIM');
}

my $class = 'Log::Dispatch::Email::DKIM';

# A subclass may call the protected i18n(); anyone else may not
{
	package Reworded;
	our @ISA = ('Log::Dispatch::Email::DKIM');
	sub words { my $self = shift; return $self->i18n(@_) }
}

# The package under test, so that the private subs may be called
{
	package Log::Dispatch::Email::DKIM;
	sub test_private { my ($self, $name, @args) = @_; return $self->$name(@args) }
}

my $log = Log::Dispatch::Email::DKIM->new(
	'name' => 'VF', 'min_level' => 'debug',
	'from' => 'webmaster@bandsman.co.uk', 'to' => ['njh@bandsman.co.uk'],
	'subject' => 'Subject', 'buffered' => 0,
);
my $subclassed = Reworded->new(
	'name' => 'RW', 'min_level' => 'debug',
	'from' => 'webmaster@bandsman.co.uk', 'to' => ['njh@bandsman.co.uk'],
);

subtest 'encapsulation' => sub {
	# Sub::Private and Sub::Protected stand down under a test harness so that
	# white-box tests can reach the internals; switch that off to see them work
	local $ENV{'HARNESS_ACTIVE'} = 0;

	ok(!eval { $log->_one_line('x'); 1 }, 'a private routine cannot be called from outside');
	like($@, qr/private/i, 'and the error says why');
	is($log->test_private('_one_line', "a\r\nb"), 'a b', 'but it can from inside the package');
	ok(!eval { $log->i18n('no_key'); 1 }, 'the protected i18n() cannot be called from outside');
	is($subclassed->words('unknown_domain'), 'unknown domain', 'but a subclass can');
};

subtest 'i18n' => sub {
	is($subclassed->words('no_key', { 'domain' => 'example.com' }),
		'DKIM: no DKIM key for example.com; sending unsigned', 'interpolates the arguments');
	is($subclassed->words('no_key'), 'DKIM: no DKIM key for ; sending unsigned', 'a missing argument is empty');
	is($subclassed->words('no_such_key'), 'no_such_key', 'an unknown key is returned as the text');

	local $Log::Dispatch::Email::DKIM::MESSAGES{'files'} = {
		'one' => ['%s file', 'count'],
		'other' => ['%s files', 'count'],
		'feminine' => ['her %s file', 'count'],
	};
	is($subclassed->words('files', { 'count' => 1 }), '1 file', 'singular');
	is($subclassed->words('files', { 'count' => 2 }), '2 files', 'plural');
	is($subclassed->words('files', { 'count' => 0 }), '0 files', 'zero is plural');
	is($subclassed->words('files', { 'count' => 1, 'gender' => 'feminine' }), 'her 1 file', 'gender wins over count');
	is($subclassed->words('files', { 'count' => 1, 'gender' => 'neuter' }), '1 file', 'an unknown gender falls back');
	is($subclassed->words('files'), ' files', 'no count falls back to other');
};

subtest 'argument validation' => sub {
	# The validator warns about an odd-sized argument list; that is expected
	local $SIG{'__WARN__'} = sub { };

	ok(!eval { $log->send_email(); 1 }, 'no message croaks');
	like($@, qr/invalid arguments to send_email/, 'in the catalogue words');
	ok(!eval { $log->send_email('message' => undef); 1 }, 'an undefined message croaks');
	ok(!eval { $log->send_email(undef); 1 }, 'a lone undef croaks');
};

subtest 'addresses' => sub {
	my $address = $log->test_private('_parse_address', '"a@evil.com" <real@example.com>');
	is($address->host, 'example.com', 'an @ in the display name does not fool the domain');
	is($log->test_private('_parse_address', 'not an address'), undef, 'junk is not an address');
	is($log->test_private('_parse_address', undef), undef, 'undef is not an address');
	is($log->test_private('_parse_address', ''), undef, 'empty is not an address');
};

# Capture what sendmail is handed
my $bin = tempdir(CLEANUP => 1);
my $sendmail = File::Spec->catfile($bin, 'sendmail');
open(my $fh, '>', $sendmail) or die "Cannot write $sendmail: $!";
print $fh "#!/bin/sh\nexec cat > \"\$CAPFILE\"\n";
close($fh) or die $!;
chmod(0700, $sendmail) or die $!;

sub sent_by {
	my ($settings, $env) = @_;
	local @ENV{keys %{$env}} = values %{$env};
	local $ENV{'DKIM_SENDMAIL'} = $sendmail;
	local $ENV{'CAPFILE'} = File::Spec->catfile(tempdir(CLEANUP => 1), 'message');
	my @warnings;
	{
		local $SIG{'__WARN__'} = sub { push @warnings, @_ };
		my $appender = Log::Dispatch::Email::DKIM->new('name' => 'VF', 'min_level' => 'debug', 'buffered' => 0, %{$settings});
		$appender->log('level' => 'error', 'message' => "body\n");
	}
	my $sent = '';
	if(-r $ENV{'CAPFILE'}) {
		open(my $in, '<', $ENV{'CAPFILE'}) or die $!;
		local $/;
		$sent = <$in>;
	}
	return ($sent, \@warnings);
}

my $empty = tempdir(CLEANUP => 1);
my %nokey = ('DKIM_KEYDIR' => $empty);

subtest 'header injection' => sub {
	my ($sent) = sent_by({
		'from' => 'webmaster@bandsman.co.uk', 'to' => ['njh@bandsman.co.uk'],
		'subject' => "Hello\r\nBcc: victim\@example.com",
	}, \%nokey);
	like($sent, qr/^Subject: Hello Bcc: victim\@example\.com\r?$/m, 'a line break in the subject is a space');
	unlike($sent, qr/^Bcc:/m, 'so no header was added');
};

subtest 'From: with a display name' => sub {
	my ($sent, $warnings) = sent_by({
		'from' => '"Web Master" <webmaster@bandsman.co.uk>', 'to' => ['njh@bandsman.co.uk'], 'subject' => 'S',
	}, \%nokey);
	like($sent, qr/^From: "Web Master" <webmaster\@bandsman\.co\.uk>\r?$/m, 'the header keeps the display name');
	like(join('', @{$warnings}), qr/no DKIM key for bandsman\.co\.uk/, 'and the domain is that of the address');
};

subtest 'no usable From: loses the message, quietly' => sub {
	my $stderr = '';
	{
		open(my $capture, '>', \$stderr) or die $!;
		local *STDERR = $capture;
		my ($sent) = sent_by({ 'from' => 'nonsense', 'to' => ['njh@bandsman.co.uk'], 'subject' => 'S' }, \%nokey);
		is($sent, '', 'nothing was sent');
	}
	like($stderr, qr/no valid From address/, 'the reason went to STDERR');
};

subtest 'a key directory glob() would mangle' => sub {
	my $dir = File::Spec->catdir(tempdir(CLEANUP => 1), 'my keys [1]');
	make_path($dir);
	open(my $out, '>', File::Spec->catfile($dir, '202611.private')) or die $!;
	close($out);
	local $ENV{'DKIM_KEYDIR'} = $dir;
	is($log->test_private('_find_key_file'), File::Spec->catfile($dir, '202611.private'), 'the key is found');
};

subtest 'no HOME in the environment' => sub {
	local $ENV{'HOME'};
	delete $ENV{'HOME'};
	delete local $ENV{'DKIM_KEYDIR'};
	delete local $ENV{'DKIM_KEYFILE'};
	my $found = eval { $log->test_private('_find_key_file'); 1 };
	ok($found, 'looking for a key does not die') or diag($@);
};

subtest 'chaining' => sub {
	local $ENV{'DKIM_SENDMAIL'} = $sendmail;
	local $ENV{'CAPFILE'} = File::Spec->devnull();
	local $ENV{'DKIM_KEYDIR'} = $empty;
	local $SIG{'__WARN__'} = sub { };
	is($log->send_email('message' => "x\n"), $log, 'send_email returns $self');
	is($log->send_email({ 'message' => "x\n", 'level' => 'error' }), $log, 'a hash reference with extra keys is accepted');
};

done_testing();
