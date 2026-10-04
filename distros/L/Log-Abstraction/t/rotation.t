#!/usr/bin/env perl
# t/rotation.t -- rotate_size, rotate_interval, rotate_keep, and logrotate

use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::Most;

use Log::Abstraction;

my $tmpdir = tempdir(CLEANUP => 1);
my $count  = 0;

# A new, unused log-file path
sub new_path { return "$tmpdir/log" . ++$count . '.log' }

# Read a file's lines, tolerating CRLF line endings on Windows
sub lines {
	my ($path) = @_;
	open(my $fin, '<', $path) or return;
	my @lines = map { s/\r?\n\z//r } <$fin>;
	close $fin;
	return @lines;
}

# Create a file with one line, last modified $age seconds ago.  It is written
# raw, so it is 4 bytes everywhere: in text mode Windows writes "old\r\n"
sub old_file {
	my ($path, $age) = @_;
	open(my $fout, '>:raw', $path) or die "$path: $!";
	print $fout "old\n";
	close $fout;
	my $when = time() - $age;
	utime($when, $when, $path) or die "utime $path: $!";
	return;
}

# A logger writing just the message to $path
sub logger {
	my ($path, %args) = @_;
	return Log::Abstraction->new(level => 'info', file => $path, array => [], format => '%message%', %args);
}

subtest 'size rotation' => sub {
	my $path = new_path();
	my $log = logger($path, rotate_size => 20, rotate_keep => 2);

	# Each line is 10 bytes with its newline (11 with CRLF on Windows), so a
	# file holds two either way
	$log->info(sprintf('line %04d', $_)) for(1 .. 7);

	is_deeply([ lines($path) ], ['line 0007'], 'the current file has the newest line');
	is_deeply([ lines("$path.1") ], ['line 0005', 'line 0006'], '.1 has the previous two');
	is_deeply([ lines("$path.2") ], ['line 0003', 'line 0004'], '.2 has the two before');
	ok(!-e "$path.3", 'nothing beyond rotate_keep');
};

subtest 'no rotation below the size' => sub {
	my $path = new_path();
	my $log = logger($path, rotate_size => '1K');
	$log->info('a')->info('b');
	is_deeply([ lines($path) ], ['a', 'b'], 'both lines in one file');
	ok(!-e "$path.1", 'no rotated file');
};

subtest 'rotate_keep defaults to 5' => sub {
	my $path = new_path();
	my $log = logger($path, rotate_size => 1);
	$log->info("m$_") for(1 .. 8);
	ok(-e "$path.$_", ".$_ exists") for(1 .. 5);
	ok(!-e "$path.6", '.6 does not');
	is_deeply([ lines("$path.5") ], ['m3'], 'the oldest kept is the fifth previous');
};

subtest 'rotate_keep 0 deletes the old file' => sub {
	my $path = new_path();
	my $log = logger($path, rotate_size => 1, rotate_keep => 0);
	$log->info('first')->info('second');
	is_deeply([ lines($path) ], ['second'], 'only the newest line');
	ok(!-e "$path.1", 'no rotated file');
};

subtest 'rotate_size units' => sub {
	my %sizes = ('1K' => 1024, '2m' => 2 * 1024**2, ' 1 G ' => 1024**3, '10KB' => 10_240, 512 => 512);
	for my $size (sort keys %sizes) {
		is(Log::Abstraction->new(logger => [], rotate_size => $size)->{rotate_size}, $sizes{$size}, "'$size'");
	}
};

subtest 'time rotation' => sub {
	my %cases = (
		hourly  => [2 * 3600, 'two hours old'],
		daily   => [2 * 86_400, 'two days old'],
		weekly  => [8 * 86_400, 'eight days old'],
		monthly => [40 * 86_400, 'forty days old'],
	);
	for my $interval (sort keys %cases) {
		my ($age, $what) = @{$cases{$interval}};

		my $path = new_path();
		old_file($path, $age);
		logger($path, rotate_interval => $interval)->info('new');
		is_deeply([ lines($path) ], ['new'], "$interval: a file $what is rotated");
		is_deeply([ lines("$path.1") ], ['old'], "$interval: and kept as .1");

		$path = new_path();
		old_file($path, 0);
		logger($path, rotate_interval => uc($interval))->info('new');
		is_deeply([ lines($path) ], ['old', 'new'], "$interval: a file from now is not rotated");
	}
};

subtest 'time rotation in UTC' => sub {
	my $path = new_path();
	old_file($path, 2 * 86_400);
	logger($path, rotate_interval => 'daily', utc => 1)->info('new');
	is_deeply([ lines($path) ], ['new'], 'rotated');
};

subtest 'size and time together' => sub {
	my $path = new_path();
	old_file($path, 0);
	my $log = logger($path, rotate_interval => 'daily', rotate_size => 5);
	# old_file's 4 bytes are under the limit; with "x\n" (or "x\r\n" on
	# Windows) the file is 6 or 7 bytes, so the next write rotates it
	$log->info('x');
	is_deeply([ lines($path) ], ['old', 'x'], 'not yet due');
	$log->info('y');
	is_deeply([ lines($path) ], ['y'], 'size makes it due');
	is_deeply([ lines("$path.1") ], ['old', 'x'], 'rotated');
};

subtest 'every path backend rotates' => sub {
	my $path = new_path();
	my $log = Log::Abstraction->new(level => 'info', logger => $path, format => '%message%', rotate_size => 1);
	$log->info('a')->info('b');
	is_deeply([ lines("$path.1") ], ['a'], 'scalar logger');

	$path = new_path();
	$log = Log::Abstraction->new(level => 'info', logger => { file => $path }, format => '%message%', rotate_size => 1);
	$log->info('a')->info('b');
	is_deeply([ lines("$path.1") ], ['a'], 'logger hash file');
};

subtest 'fd backends are not rotated' => sub {
	my $out = '';
	open(my $fh, '>', \$out) or die $!;
	my $log = Log::Abstraction->new(level => 'info', fd => $fh, array => [], format => '%message%', rotate_size => 1);
	lives_ok(sub { $log->info('a')->info('b') }, 'logging to an fd with rotate_size');
	close $fh;
	is($out, "a\nb\n", 'both lines written');
};

subtest 'a failed rotation still writes the line' => sub {
	my $path = new_path();
	my $log = logger($path, rotate_size => 1, rotate_keep => 1);
	$log->info('first');
	mkdir("$path.1") or die "mkdir: $!";    # can't be unlinked or renamed over
	lives_ok(sub { $log->info('second') }, 'does not die');
	is_deeply([ lines($path) ], ['first', 'second'], 'the line is appended to the unrotated file');
	rmdir("$path.1");
};

subtest 'logrotate: a renamed file is replaced without SIGHUP' => sub {
	my $path = new_path();
	my $log = logger($path);
	$log->info('before');
	rename($path, "$path.logrotate") or die "rename: $!";
	$log->info('after');
	is_deeply([ lines("$path.logrotate") ], ['before'], 'the renamed file is untouched');
	is_deeply([ lines($path) ], ['after'], 'the next message creates a new file');
};

subtest 'invalid options croak' => sub {
	for my $bad (0, -1, 'abc', '10X', '1.5M', '') {
		throws_ok(sub { Log::Abstraction->new(logger => [], rotate_size => $bad) },
			qr/rotate_size must be a positive number of bytes/, "rotate_size '$bad'");
	}
	for my $bad ('yearly', '') {
		throws_ok(sub { Log::Abstraction->new(logger => [], rotate_interval => $bad) },
			qr/rotate_interval must be hourly, daily, weekly or monthly/, "rotate_interval '$bad'");
	}
	for my $bad (-1, 'x', 1.5) {
		throws_ok(sub { Log::Abstraction->new(logger => [], rotate_keep => $bad) },
			qr/rotate_keep must be a non-negative integer/, "rotate_keep '$bad'");
	}
	throws_ok(sub { Log::Abstraction->new(logger => [])->new(rotate_interval => 'never') },
		qr/rotate_interval must be/, 'checked when cloning too');
	is(Log::Abstraction->new(logger => [])->new(rotate_size => '2K')->{rotate_size}, 2048,
		'and normalised when cloning');
};

done_testing();
