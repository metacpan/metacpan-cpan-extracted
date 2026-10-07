#!/usr/bin/env perl
# t/redact.t -- redact => [qr/password=\S+/]: secrets removed before any backend

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Mockingbird;
use Test::Most;

use Log::Abstraction;

my $tmpdir = tempdir(CLEANUP => 1);

# Read a log file back as text, tolerating CRLF line endings on Windows
sub slurp {
	my ($path) = @_;
	open(my $fin, '<:raw', $path) or die "$path: $!";
	local $/;
	my $data = <$fin>;
	close $fin;
	$data =~ s/\r\n/\n/g;
	return $data;
}

# An object logger that records each call
{
	package Local::Recorder;
	sub new { return bless { got => [] }, shift }
	sub info { my $self = shift; push @{$self->{got}}, [@_]; return }
}

# An object whose stringification is a secret
{
	package Local::Secret;
	use overload '""' => sub { 'password=' . $_[0]->{pw} }, fallback => 1;
	sub new { my ($class, $pw) = @_; return bless { pw => $pw }, $class }
}

subtest 'patterns are replaced in the history and array backends' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array, redact => [qr/password=\S+/]);

	$log->info('user=fred password=hunter2 ok');
	is($array[0]{message}, 'user=fred [REDACTED] ok', 'array backend');
	is($log->messages->[0]{message}, 'user=fred [REDACTED] ok', 'history');
};

subtest 'forms of the redact option' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array, redact => qr/secret/);
	$log->info('a secret');
	is($array[0]{message}, 'a [REDACTED]', 'a single qr//');

	$log = Log::Abstraction->new(level => 'debug', logger => \@array, redact => 'p[aeiou]ss');
	$log->info('pass puss');
	is($array[1]{message}, '[REDACTED] [REDACTED]', 'a string is a regular expression');

	$log = Log::Abstraction->new(level => 'debug', logger => \@array, redact => [qr/one/i, 'two']);
	$log->info('ONE two three');
	is($array[2]{message}, '[REDACTED] [REDACTED] three', 'an array of both, keeping their flags');

	for my $none ([], undef, [undef]) {
		$log = Log::Abstraction->new(level => 'debug', logger => \@array, redact => $none);
		$log->info('one');
		is($array[-1]{message}, 'one', 'no patterns: ' . (defined($none) ? '[' . join(',', map { $_ // 'undef' } @{$none}) . ']' : 'undef'));
	}
};

subtest '\K keeps the start of a match' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array, redact => qr/password=\K\S+/);
	$log->info('password=hunter2');
	is($array[0]{message}, 'password=[REDACTED]', 'password=[REDACTED]');
};

subtest 'a match may span the arguments' => sub {
	my (@array, @code);
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array, redact => qr/password=\S+/);
	$log->info('password=', 'hunter2', ' ok');
	is($array[0]{message}, '[REDACTED] ok', 'joined, then redacted');

	$log = Log::Abstraction->new(level => 'debug', logger => sub { push @code, $_[0] }, redact => qr/password=\S+/);
	$log->info('password=', 'hunter2');
	is_deeply($code[0]{message}, ['[REDACTED]'], 'a CODE logger gets the one redacted string');

	my $obj = Local::Recorder->new();
	$log = Log::Abstraction->new(level => 'debug', logger => $obj, redact => qr/password=\S+/);
	$log->info('password=', 'hunter2');
	is_deeply($obj->{got}, [['[REDACTED]']], 'so does an object logger');
};

subtest 'without redact, the CODE logger still gets the parts' => sub {
	my @code;
	my $log = Log::Abstraction->new(level => 'debug', logger => sub { push @code, $_[0] });
	$log->info('password=', 'hunter2');
	is_deeply($code[0]{message}, ['password=', 'hunter2'], 'parts unchanged');
};

subtest 'a replacement is not matched again' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array, redact => [qr/secret/, qr/RED/]);
	$log->info('secret RED');
	is($array[0]{message}, '[REDACTED] [REDACTED]', 'the marker is left alone');
};

subtest 'text, JSON and fd output' => sub {
	my $file = File::Spec->catfile($tmpdir, 'text.log');
	my $json = File::Spec->catfile($tmpdir, 'json.log');
	my $out = '';
	open(my $fh, '>', \$out) or die $!;

	my $log = Log::Abstraction->new(level => 'debug', redact => qr/password=\S+/,
		logger => { file => $file, fd => $fh, array => { array => [], format => 'json' } });
	$log->info('login password=hunter2', { user => 'fred' });
	close $fh;
	like(slurp($file), qr/login \[REDACTED\] user=fred$/m, 'file');
	like($out, qr/login \[REDACTED\] user=fred$/m, 'fd');
	unlike(slurp($file) . $out, qr/hunter2/, 'the secret is in neither');

	$log = Log::Abstraction->new(level => 'debug', file => $json, format => 'json', logger => [], redact => qr/password=\S+/);
	$log->info('login password=hunter2', { note => 'password=xyz' });
	require JSON::PP;
	my $entry = JSON::PP->new->decode(slurp($json));
	is($entry->{message}, 'login [REDACTED]', 'JSON message');
	is($entry->{fields}{note}, '[REDACTED]', 'JSON field');
};

subtest 'structured fields are redacted' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array, redact => qr/password=\K\S+/);
	my %fields = (
		plain  => 'password=a',
		number => 42,
		nested => { list => ['password=b', { deep => 'password=c' }] },
		object => Local::Secret->new('d'),
		code   => \&slurp,
	);
	$log->info('msg', \%fields);
	my $got = $array[0]{fields};
	is($got->{plain}, 'password=[REDACTED]', 'string value');
	is($got->{number}, 42, 'number unchanged');
	is_deeply($got->{nested}, { list => ['password=[REDACTED]', { deep => 'password=[REDACTED]' }] }, 'inside hashes and arrays');
	is($got->{object}, 'password=[REDACTED]', 'object whose stringification matches');
	is($got->{code}, \&slurp, 'other references unchanged');
	is($fields{plain}, 'password=a', "the caller's hash is unchanged");
	is($fields{nested}{list}[0], 'password=b', '... and so is its contents');

	my $clean = bless {}, 'Local::Recorder';
	$log->info('msg', { obj => $clean });
	is($array[1]{fields}{obj}, $clean, 'an object that does not match is kept');

	my $cycle = { name => 'password=e' };
	$cycle->{self} = $cycle;
	lives_ok(sub { $log->info('msg', { cycle => $cycle }) }, 'a cycle does not loop');
	is($array[2]{fields}{cycle}{name}, 'password=[REDACTED]', 'and is redacted');
	is($array[2]{fields}{cycle}{self}, '[REDACTED]', 'the recurring reference becomes the marker');

	my $shared = ['password=f'];
	$log->info('msg', { a => $shared, b => $shared });
	is_deeply([ @{$array[3]{fields}}{qw(a b)} ], [ ['password=[REDACTED]'], ['password=[REDACTED]'] ],
		'a reference used twice (not a cycle) is redacted both times');
};

subtest 'syslog' => sub {
	my @sent;
	my $g1 = Test::Mockingbird::mock_scoped('Sys::Syslog::openlog' => sub { 1 });
	my $g2 = Test::Mockingbird::mock_scoped('Sys::Syslog::syslog' => sub { push @sent, [@_] });
	my $g3 = Test::Mockingbird::mock_scoped('Sys::Syslog::closelog' => sub { 1 });

	my $log = Log::Abstraction->new(level => 'debug', script_name => 'rd', logger => { syslog => {} },
		redact => qr/password=\S+/);
	$log->info('login password=hunter2', { pw => 'password=x' });
	is($sent[0][2], 'login [REDACTED] pw=[REDACTED]', 'message and fields');
	undef $log;
};

subtest 'carp and croak are redacted' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $log = Log::Abstraction->new(logger => [], carp_on_warn => 1, croak_on_error => 1, redact => qr/password=\S+/);

	$log->warn('bad password=hunter2');
	is(scalar(@warnings), 1, 'one warning');
	like($warnings[0], qr/^bad \[REDACTED\] at /, 'carp');

	throws_ok(sub { $log->error('bad password=hunter2') }, qr/^bad \[REDACTED\] at /, 'croak');
	throws_ok(sub { $log->error({ warning => ['bad ', 'password=hunter2'] }) }, qr/^bad \[REDACTED\] at /,
		'the warning => [...] form');
};

subtest 'messages below the level are not redacted (nor logged)' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'warning', logger => \@array, redact => qr/x/);
	$log->debug('x');
	is(scalar(@array), 0, 'dropped');
};

subtest 'clones' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array, redact => qr/secret/);

	$log->new()->info('secret');
	is($array[0]{message}, '[REDACTED]', 'a clone inherits redact');

	$log->new(redact => 'other')->info('secret other');
	is($array[1]{message}, 'secret [REDACTED]', 'a clone can replace it');

	$log->new(redact => undef)->info('secret');
	is($array[2]{message}, 'secret', 'or turn it off');

	throws_ok(sub { $log->new(redact => '(') }, qr/invalid redact pattern/, 'and is validated');

	$log->info('secret');
	is($array[3]{message}, '[REDACTED]', 'the original is unchanged');
};

subtest 'invalid patterns croak' => sub {
	throws_ok(sub { Log::Abstraction->new(logger => [], redact => '(') },
		qr/^Log::Abstraction: invalid redact pattern '\(': Unmatched \(/, 'a string that does not compile');
	unlike($@, qr/Abstraction\.pm line/, 'without the location inside the module');
	throws_ok(sub { Log::Abstraction->new(logger => [], redact => qr/x*/) },
		qr/^Log::Abstraction: redact pattern \S+ matches the empty string/, 'a pattern matching the empty string');
	throws_ok(sub { Log::Abstraction->new(logger => [], redact => [qr/a/, '']) },
		qr/redact patterns must be regular expressions or non-empty strings/, 'an empty string');
	throws_ok(sub { Log::Abstraction->new(logger => [], redact => [{}]) },
		qr/redact patterns must be regular expressions or non-empty strings/, 'a hash reference');

	my @patterns = ('a', qr/b/);
	Log::Abstraction->new(logger => [], redact => \@patterns);
	is($patterns[0], 'a', "the caller's array is unchanged");
};

subtest 'patterns from a config file' => sub {
	my $config = File::Spec->catfile($tmpdir, 'redact.yaml');
	open(my $fout, '>', $config) or die "$config: $!";
	print $fout "level: debug\nredact:\n  - 'password=\\S+'\n  - 'token=\\w+'\n";
	close $fout;

	my @array;
	my $log = Log::Abstraction->new(config_file => $config, array => \@array);
	$log->info('password=hunter2 token=abc ok');
	is($array[0]{message}, '[REDACTED] [REDACTED] ok', 'strings in a YAML list');
};

subtest 'through Log::Any' => sub {
	eval { require Log::Any; require Log::Any::Adapter; 1 } or plan(skip_all => "Log::Any is not installed\n");

	my @array;
	Log::Any::Adapter->set('Abstraction', level => 'debug', logger => \@array, redact => qr/password=\S+/);
	Log::Any->get_logger(category => 'redact')->info('login password=hunter2');
	is($array[0]{message}, 'login [REDACTED]', 'redacted');
	Log::Any::Adapter->remove(Log::Any::Adapter->set('Null'));
};

done_testing();
