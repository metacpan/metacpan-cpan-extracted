#!/usr/bin/env perl

# mutant_killers.t - Targeted tests to kill surviving mutants identified by
# App::Test::Generator mutation testing of Log::Abstraction.
#
# Each subtest is labelled with the mutant ID it kills and explains exactly
# which condition flip or boundary shift it detects.

use strict;
use warnings;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Log::Abstraction;
use Test::Most;
use Test::Mockingbird qw(mock_scoped);

sub tmp_file {
	my ($fh, $path) = tempfile(SUFFIX => '.log', UNLINK => 1);
	close $fh;
	return $path;
}
sub slurp { open my $fh, '<', $_[0] or die $!; local $/; <$fh> }

# ============================================================
# COND_INV_209_4 — line 209:  if($array) { $args{'array'} = $array }
#
# Mutation: invert to unless($array)
# Effect:   caller's arrayref is NOT restored after config merge, so
#           messages go nowhere (or into a config-sourced backend instead).
#
# Kill strategy: construct with config_file AND array => \@log; log a
# message; assert the message arrived in the caller's array.  A mutant
# that inverts the condition would silently drop the array, so @log
# stays empty and the test fails.
# ============================================================

subtest 'COND_INV_209_4 — config_file load preserves caller array (if($array) not unless)' => sub {
	plan tests => 3;

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = File::Spec->catfile($dir, 'test.yaml');
	open my $fh, '>', $cfg or die $!;
	# Config sets level but does NOT set an array — the caller's array must survive
	print $fh "level: debug\n";
	close $fh;

	my @log;
	my $logger = Log::Abstraction->new(
		config_file => $cfg,
		array       => \@log,
	);
	isa_ok($logger, 'Log::Abstraction');

	$logger->debug('must reach caller array');
	is(scalar(@log), 1, 'message reached caller array — if($array) preserved it');
	is($log[0]{message}, 'must reach caller array', 'correct message in caller array');
};

subtest 'COND_INV_209_4 — without array arg, array not spuriously set (false branch)' => sub {
	plan tests => 2;

	# When no array is passed, $array is undef/false — the if($array) body
	# must NOT run.  A unless($array) mutant would run it with undef, setting
	# $args{'array'} = undef and potentially masking the real backend.
	# Verify the logger still works (falls back to default Log4perl).
	my $dir = tempdir(CLEANUP => 1);
	my $cfg = File::Spec->catfile($dir, 'test.yaml');
	open my $fh, '>', $cfg or die $!;
	print $fh "level: debug\n";
	close $fh;

	my $logger;
	lives_ok(
		sub { $logger = Log::Abstraction->new(config_file => $cfg) },
		'config_file without array does not crash'
	);
	isa_ok($logger, 'Log::Abstraction');
};

# ============================================================
# COND_INV_565_4 — line 565 in _log(), top-level FILE path:
#   if(blessed($self) eq __PACKAGE__) { shorter format } else { longer format }
#
# Mutation: invert to unless(blessed($self) eq __PACKAGE__)
# Effect:   base-class loggers get the longer format (includes %class% token),
#           subclass loggers get the shorter format (omits %class% token).
#
# Kill strategy: use top-level `file =>` (not logger=>{file=>}) to hit line 565.
#   (a) Base class → default format must NOT contain class name
#   (b) Subclass   → default format MUST contain class name
#
# The two subtests together kill the mutant: if inverted, (a) would contain
# the class name and (b) would not — opposite of what we assert.
# ============================================================

subtest 'COND_INV_565_4 — top-level file: base class default format omits class token' => sub {
	plan tests => 1;

	# blessed($self) eq __PACKAGE__ is TRUE → shorter format chosen
	# (no %class% placeholder → class name absent from output)
	# Mutant (unless): FALSE → longer format chosen → class name present → test fails
	my $path = tmp_file();
	my @sink;	# prevent _high_priority Carp fallback for warn/error
	my $logger = Log::Abstraction->new(
		file  => $path,
		array => \@sink,
		level => 'debug',
		# no format => let it use the default
	);
	$logger->debug('base class file test');
	my $content = slurp($path);
	unlike($content, qr/Log::Abstraction/,
		'base-class top-level file default format does not include class name');
};

subtest 'COND_INV_565_4 — top-level file: subclass default format includes class token' => sub {
	plan tests => 1;

	# blessed($self) eq __PACKAGE__ is FALSE → longer format chosen (%class% present)
	# Mutant (unless): TRUE → shorter format → class name absent → test fails
	{ package My::FileLogger; our @ISA = ('Log::Abstraction'); }

	my $path = tmp_file();
	my @sink;
	my $logger = bless Log::Abstraction->new(
		file  => $path,
		array => \@sink,
		level => 'debug',
	), 'My::FileLogger';

	$logger->debug('subclass file test');
	my $content = slurp($path);
	like($content, qr/My::FileLogger/,
		'subclass top-level file default format includes class name');
};

# ============================================================
# COND_INV_587_3 — line 587 in _log(), top-level FD path:
#   if(blessed($self) eq __PACKAGE__) { shorter format } else { longer format }
#
# Identical logic to 565 but for the top-level `fd =>` attribute path.
#
# Kill strategy: same as above but using `fd =>` instead of `file =>`.
# ============================================================

subtest 'COND_INV_587_3 — top-level fd: base class default format omits class token' => sub {
	plan tests => 1;

	my ($fh, $path) = tempfile(SUFFIX => '.log', UNLINK => 1);
	my @sink;
	my $logger = Log::Abstraction->new(
		fd    => $fh,
		array => \@sink,
		level => 'debug',
	);
	$logger->debug('base class fd test');
	close $fh;

	my $content = slurp($path);
	unlike($content, qr/Log::Abstraction/,
		'base-class top-level fd default format does not include class name');
};

subtest 'COND_INV_587_3 — top-level fd: subclass default format includes class token' => sub {
	plan tests => 1;

	{ package My::FdLogger; our @ISA = ('Log::Abstraction'); }

	my ($fh, $path) = tempfile(SUFFIX => '.log', UNLINK => 1);
	my @sink;
	my $logger = bless Log::Abstraction->new(
		fd    => $fh,
		array => \@sink,
		level => 'debug',
	), 'My::FdLogger';

	$logger->debug('subclass fd test');
	close $fh;

	my $content = slurp($path);
	like($content, qr/My::FdLogger/,
		'subclass top-level fd default format includes class name');
};

done_testing();
