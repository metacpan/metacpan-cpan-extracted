#!/usr/bin/env perl
# t/file_handles.t -- log files are kept open between messages: reopen(),
# reopen_interval, SIGHUP, and noticing a file that has been renamed or deleted

use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::Most;

use_ok('Log::Abstraction');

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

# A logger writing just the message to $path
sub logger {
	my ($path, %args) = @_;
	return Log::Abstraction->new(level => 'info', file => $path, format => '%message%', %args);
}

# The handle the logger has open on $path, if any
sub handle { return $_[0]->{_handles}{$_[1]} && $_[0]->{_handles}{$_[1]}{fh} }

# The program's own SIGHUP handler, set before any file is logged to, which
# the module's handler must still call
my $program_hup = 0;
$SIG{HUP} = sub { $program_hup++ };
my $program_handler = $SIG{HUP};

subtest 'the file is opened once, and each line is written at once' => sub {
	my $path = new_path();
	my $log = logger($path);
	$log->info('one');
	my $fh = handle($log, $path);
	ok($fh, 'the file is open');
	is_deeply([ lines($path) ], ['one'], 'the line is in the file before the next message');
	$log->info('two');
	is(handle($log, $path), $fh, 'the same handle is used for the next line');
	is_deeply([ lines($path) ], ['one', 'two'], 'both lines');
};

subtest 'every way of logging to a path' => sub {
	my ($p1, $p2, $p3) = (new_path(), new_path(), new_path());
	my $log = Log::Abstraction->new(level => 'info', format => '%message%',
		logger => { file => $p1, array => [] }, file => $p2);
	$log->info('x');
	ok(handle($log, $p1) && handle($log, $p2), 'logger hash file and top-level file');
	my $plain = Log::Abstraction->new($p3);
	$plain->warn('y');
	ok(handle($plain, $p3), 'logger path');
};

subtest 'reopen()' => sub {
	my $path = new_path();
	my $log = logger($path);
	$log->info('before');
	local ($@, $!) = ('error', 0);
	is($log->reopen(), $log, 'returns the logger');
	is($@, 'error', '$@ is unchanged');
	ok(!handle($log, $path), 'the file is closed');

	# As logrotate's postrotate SIGHUP would; on Windows an open file can't be renamed
	rename($path, "$path.1") or die "rename: $!";
	$log->info('after');
	is_deeply([ lines("$path.1") ], ['before'], 'the renamed file is untouched');
	is_deeply([ lines($path) ], ['after'], 'the next message opens a new file');
	lives_ok(sub { Log::Abstraction->new(logger => [])->reopen() }, 'nothing open');
};

subtest 'a renamed or deleted file is noticed' => sub {
	plan skip_all => "an open file can't be renamed or deleted on $^O" if($^O eq 'MSWin32');

	my $path = new_path();
	my $log = logger($path, reopen_interval => -1);
	$log->info('one');
	rename($path, "$path.old") or die "rename: $!";
	$log->info('two');
	is_deeply([ lines("$path.old") ], ['one'], 'renamed file');
	is_deeply([ lines($path) ], ['two'], 'new file');

	unlink($path) or die "unlink: $!";
	$log->info('three');
	is_deeply([ lines($path) ], ['three'], 'a deleted file is created again');
};

subtest 'a truncated file is appended to from the start' => sub {
	plan skip_all => "an open file can't be truncated on $^O" if($^O eq 'MSWin32');

	my $path = new_path();
	my $log = logger($path);
	$log->info('a long line before copytruncate');
	truncate($path, 0) or die "truncate: $!";
	$log->info('after');
	is_deeply([ lines($path) ], ['after'], 'no hole at the start of the file');
};

subtest "SIGHUP reopens every logger's files" => sub {
	if($^O eq 'MSWin32') {
		logger(new_path())->info('x');
		is($SIG{HUP}, $program_handler, 'no SIGHUP handler is installed on Windows');
		return;
	}

	my ($p1, $p2) = (new_path(), new_path());
	my ($log1, $log2) = (logger($p1), logger($p2, reopen_interval => -1));
	$_->info('one') for($log1, $log2);
	my ($fh1, $fh2) = (handle($log1, $p1), handle($log2, $p2));
	isnt($SIG{HUP}, $program_handler, 'the module has installed its handler');

	kill('HUP', $$) or die "kill: $!";
	is($program_hup, 1, "the program's handler is still called");
	ok(handle($log1, $p1), 'the files are not closed in the handler');

	$_->info('two') for($log1, $log2);
	isnt(handle($log1, $p1), $fh1, 'the first logger opened its file again');
	isnt(handle($log2, $p2), $fh2, 'and so did the second, whose reopen_interval is -1');
	$fh1 = handle($log1, $p1);
	$log1->info('three');
	is(handle($log1, $p1), $fh1, 'then keeps it open until the next SIGHUP');
	is_deeply([ lines($p1) ], [qw(one two three)], 'every line written once');
	is_deeply([ lines($p2) ], [qw(one two)], 'in both files');
};

# Checked in a new perl, because whether the handler is put back depends on
# every logger that used it having been freed.  In this process, a tool such
# as Devel::Cover (the CI dashboard) can keep a logger from an earlier
# subtest alive, which then (correctly) keeps the handler installed
my $restore_script = <<'SCRIPT';
use strict;
use warnings;
use Log::Abstraction;

my $dir = shift;
my $n = 0;
sub logger {
	return Log::Abstraction->new(level => 'info', format => '%message%', file => "$dir/restore" . ++$n . '.log', @_);
}

my $program = sub { };
$SIG{HUP} = $program;
sub state {
	my $h = $SIG{HUP};
	return !defined($h) ? 'undef' : !ref($h) ? $h : ($h == $program) ? 'program' : 'module';
}

{
	my $log1 = logger();
	my $log2 = logger();
	$_->info('x') for($log1, $log2);
	my $clone = $log1->new(level => 'debug');
	$clone->info('x');
	print state(), "\n";
	undef $log1;
	print state(), "\n";
	undef $log2;
	print state(), "\n";
}
print state(), "\n";
{
	my $log = logger();
	$log->info('x');
	print state(), "\n";
}
print state(), "\n";
for my $previous ('IGNORE', 'DEFAULT') {
	local $SIG{HUP} = $previous;
	{ logger()->info('x') }
	print state(), "\n";
}
my $mine = sub { };
{
	my $log = logger();
	$log->info('x');
	$SIG{HUP} = $mine;
	undef $log;
	print(($SIG{HUP} == $mine) ? "mine\n" : state() . "\n");
}
$SIG{HUP} = $program;
{
	my $log = logger(reopen_interval => 0);
	$log->info('x');
	print state(), "\n";
}
SCRIPT

subtest 'the previous SIGHUP handler is put back' => sub {
	plan skip_all => "no SIGHUP handler on $^O" if($^O eq 'MSWin32');

	my $script = "$tmpdir/restore.pl";
	open(my $fout, '>', $script) or die "$script: $!";
	print $fout $restore_script;
	close $fout;

	# The child finds the module where this perl did (lib or blib), and
	# runs without coverage or debugger options
	require Config;
	local $ENV{PERL5LIB} = join($Config::Config{path_sep}, grep { !ref } @INC);
	delete local $ENV{PERL5OPT};
	open(my $child, '-|', $^X, $script, $tmpdir) or die "$^X: $!";
	my @states = map { s/\r?\n\z//r } <$child>;
	ok(close($child), 'the child perl ran') or diag("exit status $?");

	is_deeply(\@states, [
		'module',     # two loggers and a clone have files open
		'module',     # one logger freed
		'module',     # the clone still uses it
		'program',    # all freed: the program's handler is back
		'module',     # installed again by the next logger
		'program',    # and put back again
		'IGNORE',     # IGNORE is put back
		'DEFAULT',    # and DEFAULT
		'mine',       # a handler the program set afterwards isn't changed
		'program',    # not installed with reopen_interval 0
	], 'the handler is installed while loggers use it, and put back after') or diag(explain(\@states));
};

subtest 'reopen_interval' => sub {
	my $path = new_path();
	my $log = logger($path);
	$log->info('one');
	my $fh = handle($log, $path);
	$log->{_handles}{$path}{opened} -= 299;
	$log->info('two');
	is(handle($log, $path), $fh, 'kept open for less than 5 minutes');
	$log->{_handles}{$path}{opened} -= 1;
	$log->info('three');
	isnt(handle($log, $path), $fh, 'opened again after 5 minutes');

	$log = logger($path, reopen_interval => 10);
	$log->info('four');
	$fh = handle($log, $path);
	$log->{_handles}{$path}{opened} -= 10;
	$log->info('five');
	isnt(handle($log, $path), $fh, 'reopen_interval given');

	$log = logger($path, reopen_interval => -1);
	$log->info('six');
	$fh = handle($log, $path);
	$log->{_handles}{$path}{opened} -= 1_000_000;
	$log->info('seven');
	is(handle($log, $path), $fh, '-1: not reopened because of time');

	$log = logger($path, reopen_interval => 0);
	$log->info('eight');
	ok(!handle($log, $path), '0: closed after the write');
	$log->info('nine');
	ok(!handle($log, $path), 'and after the next');
	is_deeply([ lines($path) ], [qw(one two three four five six seven eight nine)], 'every line written once');

	for my $bad (-2, 'x', 1.5, '', '+1') {
		throws_ok(sub { Log::Abstraction->new(logger => [], reopen_interval => $bad) },
			qr/reopen_interval must be a number of seconds, 0 or -1/, "reopen_interval '$bad'");
	}
	throws_ok(sub { Log::Abstraction->new(logger => [])->new(reopen_interval => 'x') },
		qr/reopen_interval must be/, 'checked when cloning too');
};

subtest 'rotation closes the file first' => sub {
	my $path = new_path();
	my $log = logger($path, rotate_size => 1);
	$log->info('first');
	my $fh = handle($log, $path);
	$log->info('second');
	isnt(handle($log, $path), $fh, 'a new handle after rotating');
	is_deeply([ lines("$path.1") ], ['first'], 'rotated file');
	is_deeply([ lines($path) ], ['second'], 'new file');
};

subtest 'a failed write closes the file' => sub {
	my $path = new_path();
	my $log = logger($path);
	$log->info('one');
	close(handle($log, $path));
	{
		local $SIG{__WARN__} = sub { };    # print() on closed filehandle
		lives_ok(sub { $log->info('lost') }, 'does not die');
	}
	ok(!handle($log, $path), 'the handle is dropped');
	$log->info('two');
	is_deeply([ lines($path) ], ['one', 'two'], 'the next write opens the file again');
};

subtest 'clones open their own files' => sub {
	my $path = new_path();
	my $log = logger($path);
	$log->info('parent');
	{
		my $clone = $log->new(level => 'debug');
		$clone->info('clone');
		isnt(handle($clone, $path), handle($log, $path), 'not the same handle');
		$clone->reopen();
		ok(handle($log, $path), "the clone's reopen() leaves the parent's file open");
	}
	$log->info('parent again');
	is_deeply([ lines($path) ], ['parent', 'clone', 'parent again'], 'all lines written');
};

done_testing();
