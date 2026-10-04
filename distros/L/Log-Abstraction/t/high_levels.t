#!/usr/bin/env perl
# t/high_levels.t -- the critical(), alert() and emergency() methods

use strict;
use warnings;

use Test::Mockingbird;
use Test::Most;

use Log::Abstraction;

my @HIGH = qw(critical alert emergency);

subtest 'each level is recorded under its own name' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array);

	for my $level (@HIGH) {
		is($log->$level("$level message"), $log, "$level returns \$self");
	}
	is_deeply(\@array, [ map { { level => $_, message => "$_ message" } } @HIGH ], 'levels kept')
		or diag(explain(\@array));
	is_deeply([ map { $_->{level} } @{$log->messages()} ], \@HIGH, 'history has the levels');
};

subtest 'argument forms are the same as warn()' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array);

	$log->critical('a', 'b');
	$log->alert(warning => 'named');
	$log->emergency({ warning => ['x', 'y'] });
	$log->critical('with fields', { disk => 'sda' });
	$log->alert();

	is_deeply([ map { $_->{message} } @array ], ['ab', 'named', 'xy', 'with fields'], 'messages');
	is_deeply($array[3]{fields}, { disk => 'sda' }, 'fields');
};

subtest 'level threshold' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'alert', logger => \@array);

	$log->error('e')->critical('c')->alert('a')->emergency('m');
	is_deeply([ map { $_->{level} } @array ], ['alert', 'emergency'], 'only alert and above at level alert');
};

subtest 'croak and carp behave as for error()' => sub {
	for my $level (@HIGH) {
		my $log = Log::Abstraction->new(level => 'debug', logger => [], croak_on_error => 1);
		throws_ok(sub { $log->$level("boom $level") }, qr/boom $level/, "$level croaks with croak_on_error");

		$log = Log::Abstraction->new(level => 'debug', logger => [], carp_on_warn => 1);
		warning_like(sub { $log->$level("carp $level") }, qr/carp $level/, "$level carps with carp_on_warn");

		throws_ok(sub { Log::Abstraction->$level("class $level") }, qr/class $level/,
			"$level as a class method croaks");
	}
};

subtest 'text format shows the upper-cased level' => sub {
	my $out = '';
	open(my $fh, '>', \$out) or die $!;
	my $log = Log::Abstraction->new(level => 'debug', fd => $fh, array => []);

	$log->critical('c');
	$log->emergency('e');
	close $fh;
	like($out, qr/^CRITICAL> .* c\nEMERGENCY> .* e\n\z/, 'CRITICAL and EMERGENCY');
};

subtest 'CODE backend gets the level and the caller' => sub {
	my @calls;
	my $log = Log::Abstraction->new(level => 'debug', logger => sub { push @calls, $_[0] });

	my $line = __LINE__; $log->alert('where');
	is($calls[0]{level}, 'alert', 'level');
	is($calls[0]{file}, __FILE__, 'file is the caller');
	is($calls[0]{line}, $line, 'line is the caller');
};

subtest 'syslog priorities' => sub {
	my @sent;
	my $g1 = Test::Mockingbird::mock_scoped('Sys::Syslog::openlog' => sub { 1 });
	my $g2 = Test::Mockingbird::mock_scoped('Sys::Syslog::syslog' => sub { push @sent, $_[0] });
	my $g3 = Test::Mockingbird::mock_scoped('Sys::Syslog::closelog' => sub { 1 });

	my $log = Log::Abstraction->new(level => 'debug', script_name => 'hl', logger => { syslog => {} });
	$log->$_('x') for(@HIGH);
	is_deeply(\@sent, ['crit|local0', 'alert|local0', 'emerg|local0'], 'crit, alert, emerg');
	undef $log;
};

subtest 'object logger without the method falls back to fatal, then error' => sub {
	{
		package Local::WithFatal;
		sub new { return bless { got => [] }, shift }
		sub fatal { my $self = shift; push @{$self->{got}}, ['fatal', @_] }
		sub error { my $self = shift; push @{$self->{got}}, ['error', @_] }

		package Local::ErrorOnly;
		sub new { return bless { got => [] }, shift }
		sub error { my $self = shift; push @{$self->{got}}, ['error', @_] }

		package Local::Full;
		sub new { return bless { got => [] }, shift }
		sub critical { my $self = shift; push @{$self->{got}}, ['critical', @_] }
		sub error { my $self = shift; push @{$self->{got}}, ['error', @_] }

		package Local::None;
		sub new { return bless {}, shift }
	}

	my $obj = Local::WithFatal->new();
	Log::Abstraction->new(level => 'debug', logger => $obj)->$_($_) for(@HIGH);
	is_deeply($obj->{got}, [ map { ['fatal', $_] } @HIGH ], 'fatal used when there is no method');

	$obj = Local::ErrorOnly->new();
	Log::Abstraction->new(level => 'debug', logger => $obj)->alert('a');
	is_deeply($obj->{got}, [ ['error', 'a'] ], 'error used when there is no fatal');

	$obj = Local::Full->new();
	Log::Abstraction->new(level => 'debug', logger => $obj)->critical('c');
	is_deeply($obj->{got}, [ ['critical', 'c'] ], 'the method itself is preferred');

	throws_ok(sub { Log::Abstraction->new(level => 'debug', logger => Local::None->new())->emergency('x') },
		qr/doesn't know how to deal with the emergency message/, 'croaks with no usable method');
};

done_testing();
