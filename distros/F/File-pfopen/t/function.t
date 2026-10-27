#!perl

# White-box tests for every function in lib/File/pfopen.pm.
# The module has a single function, pfopen(), so each subtest targets one
# branch or invariant of it: argument guards, the directory and suffix loops,
# the cache, and the file tests that decide whether a candidate is used.
# Most subtests are negative: they try to make pfopen() return something it
# shouldn't, warn, die unexpectedly, or corrupt its cache.

use strict;
use warnings;

# These need a newer Perl than the module does, so are recommended rather than required
use Test::Needs {
	'Readonly' => 0,
	'Test::Memory::Cycle' => 0,
	'Test::Mockingbird' => '0.14',
	'Test::Returns' => '0.05',
};

use Config;
use Errno qw(EACCES);
use File::Spec;
use Readonly;
use Scalar::Util qw(openhandle);
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Most;
use Test::Returns;
use Test::TempDir::Tiny;
use Test::Warnings;

# Filenames matching this regex fail to open, to inject failures part way through a search
our $open_fails_for;

# Every filename that pfopen() tried to open, to prove guards run before any I/O
our @open_calls;

BEGIN {
	# A CORE::GLOBAL override only affects code compiled after it is installed,
	#	so this must happen before File::pfopen is loaded
	mock_core('open' => sub {
		shift;	# The supplied $call_builtin can't autovivify the caller's lexical handle
		push @open_calls, $_[2];
		if(defined($open_fails_for) && defined($_[2]) && ($_[2] =~ $open_fails_for)) {
			$! = EACCES;
			return 0;
		}
		return CORE::open($_[0], $_[1], $_[2]);
	});
}

use File::pfopen qw(pfopen);

Readonly my %config => (
	sep => $Config{path_sep},
	prefix => 'target',
	suffix => 'txt',
	other_suffix => 'bin',
	first_content => "first\n",
	second_content => "second\n",
	appended => "appended\n",
	missing_dir => 'not_there_tulip',
	unreadable_mode => oct('000'),
	read_only_mode => oct('444'),
	writable_mode => oct('644'),
	many_dirs => 2_000,
	many_suffixes => 1_000,
	long_name_length => 5_000,
	usage_error => 'Usage: pfopen($path, $prefix, [$suffixes, [$mode]])',
	path_type_error => 'pfopen: path must be a string or an array reference',
	mode_error => 'pfopen: invalid mode',
);

Readonly my $IS_WINDOWS => ($^O eq 'MSWin32');
Readonly my $IS_ROOT => (!$IS_WINDOWS) && ($> == 0);

# Croak reports the caller's location, which is this file
sub croak_re
{
	my $message = shift;

	return qr/\A\Q$message\E at \Q${\__FILE__}\E line \d+\.?\n/;
}

sub make_file
{
	my ($dir, $name, $content) = @_;

	my $file = File::Spec->catfile($dir, $name);
	open(my $fout, '>', $file) or die "Can't create $file: $!";
	print $fout $content;
	close($fout) or die "Can't close $file: $!";
	return $file;
}

sub make_dir
{
	my $dir = File::Spec->rel2abs(tempdir(shift));
	diag("created $dir") if($ENV{TEST_VERBOSE});
	return $dir;
}

# Each subtest starts with an empty cache so results can't depend on test order
sub reset_state
{
	undef $File::pfopen::savedpaths;
	undef $open_fails_for;
	@open_calls = ();
}

sub cache_size
{
	return scalar(keys %{$File::pfopen::savedpaths || {}});
}

sub dump_cache
{
	return unless($ENV{TEST_VERBOSE});
	my $cache = $File::pfopen::savedpaths || {};
	foreach my $key (sort keys %{$cache}) {
		(my $printable = $key) =~ s/\0/\\0/g;
		diag("cache: '$printable' => '$cache->{$key}'");
	}
}

sub slurp
{
	my $fh = shift;

	local $/;
	return <$fh>;
}

my $dir1 = make_dir('first');
my $dir2 = make_dir('second');
my $missing = File::Spec->catdir($dir1, $config{missing_dir});
my $name = "$config{prefix}.$config{suffix}";
my $file1 = make_file($dir1, $name, $config{first_content});
my $file2 = make_file($dir2, $name, $config{second_content});

# ---------------------------------------------------------------------------
# Positive tests
# ---------------------------------------------------------------------------

# The documented calling conventions: a separated string, both contexts,
#	and the default read/write mode
subtest 'finds a file in a separated path, in both contexts' => sub {
	reset_state();

	my $fh = pfopen("$missing$config{sep}$dir2", $config{prefix}, $config{suffix});
	ok(defined(openhandle($fh)), 'scalar context returns an open handle');
	is(slurp($fh), $config{second_content}, 'from the first directory that has the file');

	reset_state();
	my @rc = pfopen("$missing$config{sep}$dir2", $config{prefix}, $config{suffix});
	returns_ok(\@rc, { type => 'arrayref', min => 2, max => 2 }, 'list context returns a handle and a filename');
	ok(defined(openhandle($rc[0])), 'first element is an open handle');
	returns_ok($rc[1], { type => 'string', matches => qr/\Q$name\E\z/ }, 'second element is the filename');
	is($rc[1], $file2, 'filename is the full path');

	# The default mode is documented as read/write, so writing must work
	my $wfh = $rc[0];
	seek($wfh, 0, 2);
	ok((print $wfh $config{appended}), 'default mode allows writing');
	close($wfh);
	open(my $check, '<', $file2) or die "$file2: $!";
	is(slurp($check), $config{second_content} . $config{appended}, 'write reached the file');
	close($check);
	make_file($dir2, $name, $config{second_content});	# Put it back for later tests
};

subtest 'array reference path is searched in order' => sub {
	reset_state();

	my ($fh, $file) = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file1, 'first directory wins');

	reset_state();
	($fh, $file) = pfopen([$dir2, $dir1], $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'reversed list reverses the result');
};

# The loop is directories outer, suffixes inner, so an earlier directory beats
#	an earlier suffix
subtest 'suffixes are tried in order within each directory' => sub {
	reset_state();
	my $dir = make_dir('suffixes');
	my $bin = make_file($dir, "$config{prefix}.$config{other_suffix}", $config{first_content});

	my (undef, $file) = pfopen([$dir], $config{prefix}, "$config{suffix}:$config{other_suffix}", '<');
	is($file, $bin, 'falls through to the second suffix');

	reset_state();
	(undef, $file) = pfopen([$dir, $dir1], $config{prefix}, "$config{suffix}:$config{other_suffix}", '<');
	is($file, $bin, 'an earlier directory beats an earlier suffix');

	reset_state();
	(undef, $file) = pfopen([$dir1], "$config{prefix}.$config{suffix}", undef, '<');
	is($file, $file1, 'undefined suffixes use the prefix as the whole name');
};

subtest 'explicit modes, including I/O layers, are honoured' => sub {
	reset_state();

	foreach my $mode ('<', '<:raw', '+<', '>>', '+>>') {
		reset_state();
		my $fh = pfopen([$dir1], $config{prefix}, $config{suffix}, $mode);
		ok(defined(openhandle($fh)), "mode '$mode' accepted");
		close($fh) if($fh);
	}

	reset_state();
	my $fh = pfopen([$dir1], $config{prefix}, $config{suffix}, '<');
	{
		# A read-only handle must refuse writes, proving '<' was used and not the default
		no warnings 'io';
		ok(!(print $fh 'x'), "mode '<' gives a read-only handle");
	}
	close($fh);
};

# The cache must answer a repeated lookup without searching again
subtest 'cache is used for repeated lookups' => sub {
	reset_state();

	my (undef, $first) = pfopen([$missing, $dir2], $config{prefix}, $config{suffix}, '<');
	is(cache_size(), 1, 'a successful lookup is cached');
	dump_cache();

	my $spy = spy('File::Spec', 'catfile');
	my (undef, $second) = pfopen([$missing, $dir2], $config{prefix}, $config{suffix}, '<');
	my @calls = $spy->();
	unmock('File::Spec::catfile');

	is($second, $first, 'same answer');
	is(scalar(@calls), 0, 'no filenames were built, so the directories were not searched again');
	memory_cycle_ok($File::pfopen::savedpaths, 'cache has no reference cycles');
};

subtest 'callers variables and globals are left alone' => sub {
	reset_state();

	my @path = (undef, '', $missing, $dir1);
	my @before = @path;
	my $mode = '<';
	local $_ = 'caller topic';
	local $@ = 'caller error';
	local $/ = 'caller separator';

	my $fh = pfopen(\@path, $config{prefix}, $config{suffix}, $mode);
	ok(defined($fh), 'found the file');
	is_deeply(\@path, \@before, 'path array was not filtered in place');
	is($mode, '<', 'mode variable unchanged');
	is($_, 'caller topic', '$_ unchanged');
	is($@, 'caller error', '$@ unchanged');
	is($/, 'caller separator', '$/ unchanged');
};

# ---------------------------------------------------------------------------
# Negative tests
# ---------------------------------------------------------------------------

# Missing arguments used to give "uninitialized" warnings and a silent failure
subtest 'croaks when required arguments are missing' => sub {
	reset_state();
	my $re = croak_re($config{usage_error});

	throws_ok { pfopen() } $re, 'no arguments';
	throws_ok { pfopen(undef, $config{prefix}) } $re, 'undefined path';
	throws_ok { pfopen($dir1) } $re, 'missing prefix';
	throws_ok { pfopen($dir1, undef, $config{suffix}) } $re, 'undefined prefix';
	throws_ok { pfopen($dir1, '', $config{suffix}) } $re, 'empty prefix would only ever match the directory';
	is(scalar(@open_calls), 0, 'nothing was opened');
	is(cache_size(), 0, 'nothing was cached');
};

# A hash reference used to be stringified to "HASH(0x...)" and searched as a directory
subtest 'croaks when the path is the wrong kind of reference' => sub {
	reset_state();
	my $re = croak_re($config{path_type_error});

	throws_ok { pfopen({ $dir1 => 1 }, $config{prefix}) } $re, 'hash reference';
	throws_ok { pfopen(sub { $dir1 }, $config{prefix}) } $re, 'code reference';
	throws_ok { pfopen(\$dir1, $config{prefix}) } $re, 'scalar reference';
	throws_ok { pfopen(bless([$dir1], 'Some::Class'), $config{prefix}) } $re, 'blessed array is not a plain array';
	is(scalar(@open_calls), 0, 'nothing was opened');
};

# Pipe and dup modes would run or duplicate rather than open a file:
#	'-|' would execute the found file as a command
subtest 'croaks on modes that are not plain file modes' => sub {
	reset_state();
	my $executable = make_file($dir1, 'script.sh', "#!/bin/sh\necho pwned\n");
	chmod(0755, $executable);
	@open_calls = ();	# make_file() went through the mocked open() too

	foreach my $mode ('-|', '|-', '<&', '<&=', '>&', 'r', 'w', '+', '<<', ' <', "<\n", '<>') {
		(my $printable = $mode) =~ s/\n/\\n/g;
		throws_ok { pfopen([$dir1], 'script', 'sh', $mode) } croak_re("$config{mode_error} '$mode'"),
			"mode '$printable' rejected";
	}
	is(scalar(@open_calls), 0, 'the guard runs before anything is opened');
	is(cache_size(), 0, 'and before anything is cached');
	unlink($executable);
};

subtest 'returns nothing, quietly, when the file is not found' => sub {
	reset_state();

	my $fh = pfopen([$dir1, $dir2], 'no_such_file', $config{suffix});
	ok(!defined($fh), 'undef in scalar context');

	my @rc = pfopen([$dir1, $dir2], 'no_such_file', $config{suffix});
	returns_ok(\@rc, { type => 'arrayref', max => 0 }, 'empty list in list context, not (undef, undef)');

	@rc = pfopen([$dir1], $config{prefix}, $config{other_suffix});
	is(scalar(@rc), 0, 'wrong suffix is not found');

	@rc = pfopen([$dir1], $config{prefix}, '');
	is(scalar(@rc), 0, 'an empty suffix list matches nothing');
	is(cache_size(), 0, 'misses are not cached, so failed lookups cannot fill memory');
};

# Opening a directory with '<' succeeds on UNIX, so the file test is all that stops it
subtest 'directories with a matching name are never returned' => sub {
	reset_state();
	my $dir = make_dir('dir_named_like_file');
	mkdir(File::Spec->catdir($dir, $name)) or die "mkdir: $!";

	foreach my $mode ('<', '+<') {
		reset_state();
		my @rc = pfopen([$dir], $config{prefix}, $config{suffix}, $mode);
		is(scalar(@rc), 0, "directory skipped with mode '$mode'");

		reset_state();
		my (undef, $file) = pfopen([$dir, $dir2], $config{prefix}, $config{suffix}, $mode);
		is($file, $file2, "search continues past the directory with mode '$mode'");
	}
};

subtest 'path entries that are not directories are skipped silently' => sub {
	reset_state();

	# Each of these used to be passed to -d, and undef warned
	my @junk = (undef, '', $missing, $file1);
	my (undef, $file) = pfopen([@junk, $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'found after the junk entries');

	reset_state();
	(undef, $file) = pfopen("$config{sep}$config{sep}$file1$config{sep}$dir2$config{sep}", $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'empty and non-directory entries in a string are skipped');

	reset_state();
	my @rc = pfopen([undef, ''], $config{prefix}, $config{suffix}, '<');
	is(scalar(@rc), 0, 'a list of nothing but junk finds nothing');
};

# A NUL can't be in a filename; the file tests warn if given one
subtest 'names containing NUL are rejected without warnings' => sub {
	reset_state();

	my @rc = pfopen([$dir1], "$config{prefix}\0", $config{suffix}, '<');
	is(scalar(@rc), 0, 'NUL in the prefix');

	@rc = pfopen([$dir1], $config{prefix}, "$config{suffix}\0", '<');
	is(scalar(@rc), 0, 'NUL in the suffixes');
	is(scalar(@open_calls), 0, 'nothing was opened');

	my (undef, $file) = pfopen(["$dir1\0", $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'a directory containing NUL is ignored and the search continues');

	# Truncation at the NUL must not let "dir\0anything" find the file in "dir"
	reset_state();
	@rc = pfopen("$dir1\0$config{missing_dir}", $config{prefix}, $config{suffix}, '<');
	is(scalar(@rc), 0, 'NUL cannot be used to truncate a path');
};

SKIP: {
	skip('Permission tests need a non-root UNIX user', 1) if($IS_WINDOWS || $IS_ROOT);

	subtest 'unreadable files are skipped' => sub {
		reset_state();
		my $dir = make_dir('unreadable');
		my $locked = make_file($dir, $name, $config{first_content});
		chmod($config{unreadable_mode}, $locked);

		my @rc = pfopen([$dir], $config{prefix}, $config{suffix}, '<');
		is(scalar(@rc), 0, 'unreadable file not returned');

		my (undef, $file) = pfopen([$dir, $dir2], $config{prefix}, $config{suffix}, '<');
		is($file, $file2, 'search continues to a readable copy');

		chmod($config{writable_mode}, $locked);
	};
}

SKIP: {
	skip('Root can write to read-only files', 1) if($IS_ROOT);

	# Readable but not writable passes -r, so it is open() that must fail and be survived
	subtest 'default read/write mode skips read-only files' => sub {
		reset_state();
		my $dir = make_dir('read_only');
		my $ro = make_file($dir, $name, $config{first_content});
		chmod($config{read_only_mode}, $ro);

		my @rc = pfopen([$dir], $config{prefix}, $config{suffix});
		is(scalar(@rc), 0, 'read-only file not returned for read/write');

		my (undef, $file) = pfopen([$dir, $dir2], $config{prefix}, $config{suffix});
		is($file, $file2, 'search continues to a writable copy');

		(undef, $file) = pfopen([$dir], $config{prefix}, $config{suffix}, '<');
		is($file, $ro, 'the read-only file is still found for reading');

		chmod($config{writable_mode}, $ro);
	};
}

# A file can pass -r and still fail to open (races, ACLs, quotas)
subtest 'open failures part way through the search are survived' => sub {
	reset_state();
	$open_fails_for = qr/\A\Q$file1\E\z/;

	my (undef, $file) = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'first candidate failed, second was used');
	is_deeply(\@open_calls, [$file1, $file2], 'both candidates were tried, in order');
	is($File::pfopen::savedpaths->{join("\0", $config{prefix}, $config{suffix}, $dir1, $dir2)}, $file2,
		'the file that opened is the one cached');

	reset_state();
	$open_fails_for = qr/./;
	my @rc = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
	is(scalar(@rc), 0, 'returns nothing when every open fails');
	is(cache_size(), 0, 'and caches nothing');
};

subtest 'a cached file that can no longer be opened is forgotten' => sub {
	reset_state();
	my $dir = make_dir('vanishing');
	my $file = make_file($dir, $name, $config{first_content});

	pfopen([$dir, $dir2], $config{prefix}, $config{suffix}, '<');
	is(cache_size(), 1, 'primed');

	unlink($file) or die "unlink $file: $!";
	my (undef, $found) = pfopen([$dir, $dir2], $config{prefix}, $config{suffix}, '<');
	is($found, $file2, 'searched again and found the other copy');
	dump_cache();
	is((values %{$File::pfopen::savedpaths})[0], $file2, 'cache now points at the new file');

	# Now make the remaining copy fail as well: the stale entry must go
	$open_fails_for = qr/./;
	my @rc = pfopen([$dir, $dir2], $config{prefix}, $config{suffix}, '<');
	is(scalar(@rc), 0, 'nothing returned');
	is(cache_size(), 0, 'stale cache entry deleted');
};

# '<' on a directory succeeds, so the cache must make the same check as the search
subtest 'a cached file replaced by a directory is not returned' => sub {
	reset_state();
	my $dir = make_dir('replaced');
	my $file = make_file($dir, $name, $config{first_content});

	pfopen([$dir], $config{prefix}, $config{suffix}, '<');
	unlink($file) or die "unlink $file: $!";
	mkdir($file) or die "mkdir $file: $!";

	my @rc = pfopen([$dir], $config{prefix}, $config{suffix}, '<');
	is(scalar(@rc), 0, 'directory is not returned from the cache');
	is(cache_size(), 0, 'and the entry is removed');
};

# Different arguments must never share a cache entry
subtest 'cache keys cannot collide' => sub {
	reset_state();

	# Old key was "prefix;path;suffixes", so these two were the same entry
	pfopen($dir1, $config{prefix}, $config{suffix}, '<');
	my @rc = pfopen("$dir1;$config{suffix}", $config{prefix}, undef, '<');
	is(scalar(@rc), 0, 'suffix can not be smuggled in through the path');

	# A directory whose name contains the separator, given as an array,
	#	must not answer for the same string split into two directories
	SKIP: {
		skip('Windows directory names cannot contain the separator', 2) if($IS_WINDOWS);
		reset_state();
		my $parent = make_dir('separator_in_name');
		my $odd = File::Spec->catdir($parent, "a$config{sep}b");
		mkdir($odd) or die "mkdir $odd: $!";
		make_file($odd, $name, $config{first_content});

		my (undef, $file) = pfopen([$odd], $config{prefix}, $config{suffix}, '<');
		ok(defined($file), 'array reference keeps the separator as part of the name');
		@rc = pfopen($odd, $config{prefix}, $config{suffix}, '<');
		is(scalar(@rc), 0, 'the string form splits it, and does not hit the cached entry');
	}

	reset_state();
	pfopen([$dir1], $config{prefix}, $config{suffix}, '<');
	@rc = pfopen([$dir1], $config{prefix}, $config{other_suffix}, '<');
	is(scalar(@rc), 0, 'different suffixes have different entries');
	memory_cycle_ok($File::pfopen::savedpaths, 'cache has no reference cycles');
};

# The 3-argument open must treat shell and open() metacharacters literally
subtest 'metacharacters in names are not interpreted' => sub {
	reset_state();

	foreach my $hostile ('| echo pwned', 'x; rm -rf ~', '>clobber', '< target.txt', '../../../etc/passwd|') {
		my @rc = pfopen([$dir1], $hostile, undef, '<');
		is(scalar(@rc), 0, "'$hostile' finds nothing");
	}
	ok(!-e File::Spec->catfile($dir1, 'clobber'), 'no file was created by a > in the name');

	SKIP: {
		skip("Windows filenames can't contain |", 1) if($IS_WINDOWS);
		my $piped = make_file($dir1, 'trailing|', $config{first_content});
		my $fh = pfopen([$dir1], 'trailing|', undef, '<');
		is(slurp($fh), $config{first_content}, 'a real file with a | in its name is read, not run');
		unlink($piped);
	}
};

# Large inputs must neither die nor take quadratic time
subtest 'large inputs are handled' => sub {
	reset_state();

	my @dirs = ((map { File::Spec->catdir($missing, $_) } 1..$config{many_dirs}), $dir2);
	my (undef, $file) = pfopen(\@dirs, $config{prefix}, $config{suffix}, '<');
	is($file, $file2, "found after $config{many_dirs} missing directories");

	reset_state();
	(undef, $file) = pfopen(join($config{sep}, @dirs), $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'and the same as one long string');

	reset_state();
	my $suffixes = join(':', (map { "s$_" } 1..$config{many_suffixes}), $config{suffix});
	(undef, $file) = pfopen([$dir1], $config{prefix}, $suffixes, '<');
	is($file, $file1, "found after $config{many_suffixes} wrong suffixes");

	reset_state();
	my @rc;
	lives_ok { @rc = pfopen([$dir1], 'x' x $config{long_name_length}, $config{suffix}, '<') }
		'a name longer than the OS allows does not die';
	is(scalar(@rc), 0, 'and finds nothing');
	is(cache_size(), 0, 'and caches nothing');
};

restore_all();

done_testing();
