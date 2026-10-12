#!/usr/bin/env perl
# t/backends.t -- the Log::Abstraction::Backend objects that new() builds

use strict;
use warnings;

use Data::Dumper;
use Test::Mockingbird;
use Test::Most;

use Log::Abstraction;

# The classes of a logger's backends, in the order they get a message
sub classes {
	my ($log) = @_;
	return [ map { (my $c = ref($_)) =~ s/^Log::Abstraction::Backend:://; $c } @{$log->{_backends}} ];
}

subtest 'new() builds one backend per destination, in order' => sub {
	open(my $fd, '>', \my $buffer) or die $!;
	my $log = Log::Abstraction->new(
		logger => {
			fd       => $fd,
			array    => [],
			file     => 'x.log',
			sendmail => { to => 'ops@example.com' },
		},
		file => 'y.log',
	);
	is_deeply(classes($log), [qw(File Array Sendmail Fd File)], 'logger hash, then the top-level file');

	is_deeply(classes(Log::Abstraction->new(logger => sub { })), ['Code'], 'code reference');
	is_deeply(classes(Log::Abstraction->new(logger => [])), ['Array'], 'array reference');
	is_deeply(classes(Log::Abstraction->new('some.log')), ['File'], 'path');
	is_deeply(classes(Log::Abstraction->new(array => [], fd => $fd)), [qw(Array Fd)], 'top-level array and fd');
	is_deeply(classes(Log::Abstraction->new(logger => [], array => [])), ['Array'],
		'a top-level array is not used when there is a logger');
	isa_ok($_, 'Log::Abstraction::Backend') for @{$log->{_backends}};
};

subtest 'the syslog hash is not changed' => sub {
	my @sock;
	my $g1 = mock_scoped 'Sys::Syslog::setlogsock' => sub { push @sock, $_[0] };
	my $g2 = mock_scoped 'Sys::Syslog::openlog' => sub { 1 };
	my $g3 = mock_scoped 'Sys::Syslog::syslog' => sub { 1 };
	my $g4 = mock_scoped 'Sys::Syslog::closelog' => sub { 1 };

	my $syslog = { facility => 'local3', server => 'loghost', level => 'error', format => '%message%' };
	my $copy = { %{$syslog} };
	{
		my $log = Log::Abstraction->new(logger => { syslog => $syslog }, script_name => 'test');
		$log->error('one');
		$log->error('two');
	}
	is_deeply($syslog, $copy, 'facility, level, format and server are all still there')
		or diag(Dumper($syslog));
	is(scalar(@sock), 1, 'setlogsock called once');
	is_deeply($sock[0], { host => 'loghost' }, 'with server renamed host');

	# So the same hash can be used again, with the same result
	@sock = ();
	my @sent;
	my $g5 = mock_scoped 'Sys::Syslog::syslog' => sub { push @sent, [ @_ ] };
	my $log = Log::Abstraction->new(logger => { syslog => $syslog }, script_name => 'test');
	$log->warn('dropped');
	$log->error('kept');
	is_deeply(\@sent, [ [ 'err|local3', '%s', 'kept' ] ], 'second logger has the level and facility');
};

subtest 'new() reports what used to fail at the first message' => sub {
	throws_ok(sub { Log::Abstraction->new(logger => { nothing => 1 }) },
		qr/the logger hash has none of the keys/, 'logger hash without a backend');
	throws_ok(sub { Log::Abstraction->new(logger => \'string') },
		qr/the logger can't be a SCALAR reference/, 'scalar reference');
	throws_ok(sub { Log::Abstraction->new(logger => \*STDERR) },
		qr/the logger can't be a GLOB reference/, 'glob reference');
};

subtest 'a clone has its own backends' => sub {
	my (@a, @b);
	my $log = Log::Abstraction->new(logger => \@a, level => 'debug');
	my $clone = $log->new(logger => \@b);
	isnt($clone->{_backends}, $log->{_backends}, 'not shared');
	$log->info('parent');
	$clone->info('clone');
	is_deeply([ map { $_->{message} } @a ], ['parent'], 'parent logs to its array');
	is_deeply([ map { $_->{message} } @b ], ['clone'], 'clone logs to the new one');

	throws_ok(sub { $log->new(logger => \'x') }, qr/can't be a SCALAR reference/, 'clone with a bad logger croaks');
};

subtest 'an object not made by new() builds its backends when needed' => sub {
	my @array;
	my $bare = bless { level => 7, messages => [], logger => \@array }, 'Log::Abstraction';
	$bare->info('hello');
	is_deeply(\@array, [ { level => 'info', message => 'hello' } ], 'logged');
};

subtest 'backend carps point at the caller' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $g = mock_scoped 'Sys::Syslog::openlog' => sub { 1 };
	my $g2 = mock_scoped 'Sys::Syslog::syslog' => sub { die "down\n" };
	my $g3 = mock_scoped 'Sys::Syslog::closelog' => sub { 1 };
	my $log = Log::Abstraction->new(logger => { syslog => {} }, script_name => 'test');
	my $line = __LINE__; $log->warn('x');
	like($warnings[0], qr/syslog failed: down/, 'carped');
	like($warnings[0], qr/at \Q${\ __FILE__}\E line $line\b/, 'from the logging call');
};

subtest 'Log::Abstraction::Backend itself' => sub {
	throws_ok(sub { Log::Abstraction::Backend->new()->emit() }, qr/emit\(\) is not implemented/,
		'emit must be overridden');
	my $backend = Log::Abstraction::Backend->new(format => '%message%');
	is($backend->text({ render => sub { "rendered $_[0]" } }, 'plain'), 'rendered %message%', 'text uses the format');
	is(Log::Abstraction::Backend->new()->text({}, 'plain'), 'plain', 'or the default');
};

done_testing();
