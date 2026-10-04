#!/usr/bin/env perl
# t/is_level.t -- is_trace, is_debug, ... is_emergency

use strict;
use warnings;

use Test::Most;

use Log::Abstraction;

my @METHODS = qw(trace debug info notice warn error critical alert emergency);

# For each configured level, the methods expected to return 1
my %expect = (
	trace     => [qw(trace debug info notice warn error critical alert emergency)],
	debug     => [qw(trace debug info notice warn error critical alert emergency)],
	info      => [qw(info notice warn error critical alert emergency)],
	notice    => [qw(notice warn error critical alert emergency)],
	warning   => [qw(warn error critical alert emergency)],
	error     => [qw(error critical alert emergency)],
	critical  => [qw(critical alert emergency)],
	alert     => [qw(alert emergency)],
	emergency => [qw(emergency)],
);

subtest 'every method at every level' => sub {
	for my $level (sort keys %expect) {
		my $log = Log::Abstraction->new(level => $level, logger => []);
		my %on = map { $_ => 1 } @{$expect{$level}};
		for my $method (@METHODS) {
			is($log->${\"is_$method"}(), $on{$method} ? 1 : 0, "level $level: is_$method");
		}
	}
};

subtest 'is_* agrees with what is actually logged' => sub {
	for my $level (sort keys %expect) {
		my @array;
		my $log = Log::Abstraction->new(level => $level, logger => \@array);
		for my $method (@METHODS) {
			@array = ();
			$log->$method('x');
			is(scalar(@array), $log->${\"is_$method"}(), "level $level: is_$method matches $method()");
		}
	}
};

subtest 'follows level() changes' => sub {
	my $log = Log::Abstraction->new(level => 'error', logger => []);
	is($log->is_warn(), 0, 'is_warn false at error');
	$log->level('warning');
	is($log->is_warn(), 1, 'is_warn true after level(warning)');
	is($log->is_info(), 0, 'is_info still false');
	$log->level('trace');
	is($log->is_trace(), 1, 'is_trace true after level(trace)');
};

subtest 'numeric level 0 (emergency)' => sub {
	my $log = Log::Abstraction->new(logger => []);
	$log->{level} = 0;
	is($log->is_emergency(), 1, 'is_emergency true at 0');
	is($log->is_alert(), 0, 'is_alert false at 0');
	is($log->is_debug(), 0, 'is_debug false at 0');
};

subtest 'Log::Any detection methods delegate' => sub {
	my $ok = eval { require Log::Any; require Log::Any::Adapter; 1 };
	plan skip_all => 'Log::Any not installed' unless($ok);

	my $la = Log::Abstraction->new(level => 'notice', logger => []);
	Log::Any::Adapter->set('Abstraction', instance => $la);
	my $log = Log::Any->get_logger(category => 'IsLevel');

	ok($log->is_notice(), 'is_notice');
	ok($log->is_warning(), 'is_warning maps to is_warn');
	ok(!$log->is_info(), 'is_info false');
	$la->level('info');
	ok($log->is_info(), 'follows level() on the instance');
};

done_testing();
