#!perl

# Black-box tests of File::pfopen's public API, written from its POD alone.
# Every documented return state, error message and side effect is listed in
# %ledger; each is deleted when a subtest proves it, and the script fails if
# any are left, so a POD change that adds a state without a test is caught.

use strict;
use warnings;

# These need a newer Perl than the module does, so are recommended rather than required
use Test::Needs {
	'Readonly' => 0,
	'Test::Mockingbird' => '0.14',
	'Test::Returns' => '0.05',
};

use Config;
use Errno qw(EACCES);
use File::Spec;
use Readonly;
use Scalar::Util qw(openhandle);
use Test::Mockingbird;
use Test::Most;
use Test::Returns;
use Test::TempDir::Tiny;
use Test::Warnings;

# Filenames matching this fail to open, so "found but can't be opened" can be
#	reached without depending on file permissions, which root ignores
our $open_fails_for;

BEGIN {
	# Must be installed before File::pfopen is compiled to affect its open() calls
	mock_core('open' => sub {
		shift;	# The supplied $call_builtin can't autovivify the caller's lexical handle
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
	prefix => 'unit',
	suffix => 'txt',
	other_suffix => 'bin',
	first_content => "first\n",
	second_content => "second\n",
	written => "written\n",
	missing_dir => 'not_there_tulip',
	alarm_seconds => 60,
	usage_error => 'Usage: pfopen($path, $prefix, [$suffixes, [$mode]])',
	path_type_error => 'pfopen: path must be a string or an array reference',
	mode_error => q{pfopen: invalid mode '%s'},
	valid_modes => ['<', '>', '>>', '+<', '+>', '+>>', '<:raw', '<:encoding(UTF-8)'],
	invalid_modes => ['-|', '|-', '<&', '<&=', 'r', 'w', '+', '<<', ' <'],
);

# The OUTPUT schema from the POD's API SPECIFICATION, for list context
Readonly my %list_schema => (
	type => 'arrayref',
	min => 0,
	max => 2,
	callback => sub {
		my $rc = shift;
		return (scalar(@{$rc}) == 0) ||
			((scalar(@{$rc}) == 2) && defined(openhandle($rc->[0])) && !ref($rc->[1]));
	},
);

# Every documented outcome; a subtest deletes an entry once it has proved it
my %ledger = (
	'error: usage' => 'Usage message for a missing path or prefix, or an empty prefix',
	'error: path type' => 'Path that is a reference to something other than an array',
	'error: invalid mode' => "Mode that isn't a file mode",
	'returns: scalar handle' => 'Scalar context returns an open file handle',
	'returns: list handle and filename' => 'List context returns the handle and the full filename',
	'returns: scalar undef' => 'Not found returns undef in scalar context',
	'returns: list empty' => 'Not found returns an empty list in list context',
	'returns: nothing when unopenable' => "Found but can't be opened in the mode returns nothing",
	'returns: nothing for NUL' => 'NUL in the prefix or suffixes returns nothing',
	'side effect: remembered' => 'A repeated call reopens the remembered file without searching',
	'side effect: forgotten' => "A remembered file that can't be opened is forgotten",
	'side effect: string and array share' => 'A string and an array of the same directories share one remembered file',
	'side effect: globals' => q{$!, $@ and $_ are unchanged},
	'side effect: arguments' => q{The caller's arguments are unchanged},
);

sub proved
{
	my $state = shift;

	diag("proved: $state") if($ENV{TEST_VERBOSE});
	delete $ledger{$state};
}

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
	return File::Spec->rel2abs(tempdir(shift));
}

sub slurp
{
	my $fh = shift;

	local $/;
	return <$fh>;
}

# Black-box tests can't empty the remembered lookups, so each subtest uses its
#	own directories and therefore its own lookups
my $name = "$config{prefix}.$config{suffix}";

# ---------------------------------------------------------------------------
# RETURNS
# ---------------------------------------------------------------------------

subtest 'returns an open handle in scalar context' => sub {
	my $dir = make_dir('scalar');
	make_file($dir, $name, $config{first_content});

	my $fh = pfopen($dir, $config{prefix}, $config{suffix});
	returns_ok([$fh, 'x'], \%list_schema, 'an open handle');
	is(slurp($fh), $config{first_content}, 'of the right file');
	proved('returns: scalar handle');
};

subtest 'returns the handle and full filename in list context' => sub {
	my $dir = make_dir('list');
	my $file = make_file($dir, $name, $config{first_content});

	my @rc = pfopen($dir, $config{prefix}, $config{suffix});
	returns_ok(\@rc, \%list_schema, 'matches the OUTPUT schema');
	is(scalar(@rc), 2, 'two elements');
	is($rc[1], $file, 'the full filename');
	is(slurp($rc[0]), $config{first_content}, 'handle is for that file');
	proved('returns: list handle and filename');
};

subtest 'returns nothing when the file is not found' => sub {
	my $dir = make_dir('not_found');
	make_file($dir, $name, $config{first_content});

	my $fh = pfopen($dir, 'no_such_file', $config{suffix});
	ok(!defined($fh), 'undef in scalar context');
	proved('returns: scalar undef');

	my @rc = pfopen($dir, 'no_such_file', $config{suffix});
	returns_ok(\@rc, \%list_schema, 'matches the OUTPUT schema');
	is(scalar(@rc), 0, 'empty list in list context');
	proved('returns: list empty');

	@rc = pfopen($dir, $config{prefix}, '');
	is(scalar(@rc), 0, 'an empty suffix list matches nothing');
};

subtest 'returns nothing when the file cannot be opened in the mode' => sub {
	my $dir = make_dir('unopenable');
	my $file = make_file($dir, $name, $config{first_content});

	local $open_fails_for = qr/\A\Q$file\E\z/;
	my @rc = pfopen($dir, $config{prefix}, $config{suffix}, '<');
	is(scalar(@rc), 0, 'list context');
	ok(!defined(scalar(pfopen($dir, $config{prefix}, $config{suffix}, '<'))), 'scalar context');
	proved('returns: nothing when unopenable');
};

subtest 'returns nothing for names containing NUL' => sub {
	my $dir = make_dir('nul');
	make_file($dir, $name, $config{first_content});

	my @rc = pfopen($dir, "$config{prefix}\0", $config{suffix});
	is(scalar(@rc), 0, 'NUL in the prefix');
	@rc = pfopen($dir, $config{prefix}, "$config{suffix}\0");
	is(scalar(@rc), 0, 'NUL in the suffixes');
	proved('returns: nothing for NUL');
};

subtest 'directories are never returned' => sub {
	my $dir = make_dir('directory');
	mkdir(File::Spec->catdir($dir, $name)) or die "mkdir: $!";

	my @rc = pfopen($dir, $config{prefix}, $config{suffix}, '<');
	is(scalar(@rc), 0, 'a directory with the right name is not a file');
};

# ---------------------------------------------------------------------------
# ARGUMENTS
# ---------------------------------------------------------------------------

subtest '$path: separated string, searched in order' => sub {
	my $dir1 = make_dir('string_first');
	my $dir2 = make_dir('string_second');
	my $missing = File::Spec->catdir($dir1, $config{missing_dir});
	my $file2 = make_file($dir2, $name, $config{second_content});

	my (undef, $file) = pfopen("$missing$config{sep}$dir2", $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'found in the second directory');

	my $file1 = make_file($dir1, $name, $config{first_content});
	(undef, $file) = pfopen("$dir1$config{sep}$dir2", $config{prefix}, $config{suffix}, '<');
	is($file, $file1, 'the first directory takes precedence');
};

subtest '$path: array reference, searched in order' => sub {
	my $dir1 = make_dir('array_first');
	my $dir2 = make_dir('array_second');
	my $file1 = make_file($dir1, $name, $config{first_content});
	my $file2 = make_file($dir2, $name, $config{second_content});

	my (undef, $file) = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file1, 'first directory');
	(undef, $file) = pfopen([$dir2, $dir1], $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'reversed order');
};

subtest '$path: entries that are not usable directories are ignored' => sub {
	my $dir = make_dir('ignored');
	my $file = make_file($dir, $name, $config{first_content});
	my $missing = File::Spec->catdir($dir, $config{missing_dir});

	my (undef, $found) = pfopen([undef, '', $missing, "$dir\0", $file, $dir], $config{prefix}, $config{suffix}, '<');
	is($found, $file, 'undefined, empty, missing, NUL and non-directory entries skipped');

	(undef, $found) = pfopen("$config{sep}$missing$config{sep}$config{sep}$dir$config{sep}", $config{prefix}, $config{suffix}, '<');
	is($found, $file, 'the same in a string');
};

SKIP: {
	skip('Drive letters are only on Windows', 1) unless($^O eq 'MSWin32');

	subtest '$path: drive letters on Windows' => sub {
		my $dir = make_dir('drive');
		my $file = make_file($dir, $name, $config{first_content});
		like($dir, qr/\A[A-Za-z]:/, 'directory has a drive letter');

		my (undef, $found) = pfopen("C:\\$config{missing_dir};$dir", $config{prefix}, $config{suffix}, '<');
		is($found, $file, 'drive letters are not split');
	};
}

subtest '$suffixes: colon separated, directories before suffixes' => sub {
	my $dir1 = make_dir('suffix_first');
	my $dir2 = make_dir('suffix_second');
	my $bin = make_file($dir1, "$config{prefix}.$config{other_suffix}", $config{first_content});
	make_file($dir2, $name, $config{second_content});

	my (undef, $file) = pfopen([$dir1], $config{prefix}, "$config{suffix}:$config{other_suffix}", '<');
	is($file, $bin, 'the second suffix is tried');

	(undef, $file) = pfopen([$dir1, $dir2], $config{prefix}, "$config{suffix}:$config{other_suffix}", '<');
	is($file, $bin, 'an earlier directory beats an earlier suffix');
};

subtest '$suffixes: undefined means the prefix is the whole filename' => sub {
	my $dir = make_dir('no_suffix');
	my $file = make_file($dir, $name, $config{first_content});

	my (undef, $found) = pfopen($dir, $name, undef, '<');
	is($found, $file, 'undef');

	(undef, $found) = pfopen($dir, $name);
	is($found, $file, 'not given');
};

subtest '$mode: defaults to read/write' => sub {
	my $dir = make_dir('default_mode');

	foreach my $mode (undef, '', 0) {
		make_file($dir, $name, $config{first_content});	# The previous iteration wrote to it
		my $fh = pfopen($dir, $config{prefix}, $config{suffix}, $mode);
		my $label = defined($mode) ? "'$mode'" : 'undef';
		ok(defined($fh), "mode $label opens");
		is(slurp($fh), $config{first_content}, "mode $label can read");
		ok((print $fh $config{written}), "mode $label can write");
		close($fh);
	}
};

subtest '$mode: every documented file mode is accepted' => sub {
	my $dir = make_dir('modes');
	make_file($dir, $name, $config{first_content});

	foreach my $mode (@{$config{valid_modes}}) {
		my $fh;
		lives_ok { $fh = pfopen($dir, $config{prefix}, $config{suffix}, $mode) } "mode '$mode' accepted";
		ok(defined($fh), "mode '$mode' opens");
		close($fh) if($fh);
	}
};

# The POD warns that writing modes truncate, since only existing files are found
subtest q{$mode: '>' truncates the existing file} => sub {
	my $dir = make_dir('truncate');
	my $file = make_file($dir, $name, $config{first_content});

	my $fh = pfopen($dir, $config{prefix}, $config{suffix}, '>');
	ok(defined($fh), 'opened');
	close($fh);
	is(-s $file, 0, 'file is now empty');
};

# ---------------------------------------------------------------------------
# ERRORS
# ---------------------------------------------------------------------------

subtest 'croaks with the usage message' => sub {
	my $dir = make_dir('usage');
	my $re = croak_re($config{usage_error});

	throws_ok { pfopen() } $re, 'no arguments';
	throws_ok { pfopen(undef, $config{prefix}) } $re, 'undefined path';
	throws_ok { pfopen($dir) } $re, 'missing prefix';
	throws_ok { pfopen($dir, undef) } $re, 'undefined prefix';
	throws_ok { pfopen($dir, '') } $re, 'empty prefix';
	proved('error: usage');
};

subtest 'croaks when the path is the wrong kind of reference' => sub {
	my $dir = make_dir('path_type');
	my $re = croak_re($config{path_type_error});

	throws_ok { pfopen({ $dir => 1 }, $config{prefix}) } $re, 'hash reference';
	throws_ok { pfopen(sub { $dir }, $config{prefix}) } $re, 'code reference';
	throws_ok { pfopen(\$dir, $config{prefix}) } $re, 'scalar reference';
	throws_ok { pfopen(bless([$dir], 'Some::Class'), $config{prefix}) } $re, 'blessed array';
	proved('error: path type');
};

subtest 'croaks on modes that are not file modes' => sub {
	my $dir = make_dir('bad_mode');
	make_file($dir, $name, $config{first_content});

	foreach my $mode (@{$config{invalid_modes}}) {
		throws_ok { pfopen($dir, $config{prefix}, $config{suffix}, $mode) }
			croak_re(sprintf($config{mode_error}, $mode)), "mode '$mode'";
	}
	proved('error: invalid mode');
};

# ---------------------------------------------------------------------------
# SIDE EFFECTS
# ---------------------------------------------------------------------------

# A file added to an earlier directory after the first call is only seen if
#	the directories are searched again, which the POD says they aren't
subtest 'a repeated call reopens the remembered file' => sub {
	my $dir1 = make_dir('remember_first');
	my $dir2 = make_dir('remember_second');
	my $file2 = make_file($dir2, $name, $config{second_content});

	my (undef, $file) = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'found in the second directory');

	make_file($dir1, $name, $config{first_content});
	(undef, $file) = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'remembered, so the new file in the first directory is not seen');

	(undef, $file) = pfopen([$dir1, $dir2], $config{prefix}, $config{other_suffix}, '<');
	ok(!defined($file), 'different arguments are a different lookup');
	proved('side effect: remembered');
};

# Remember with one form of $path, then show the other form reuses it
subtest 'a string and an array of the same directories share one remembered file' => sub {
	my $dir1 = make_dir('share_first');
	my $dir2 = make_dir('share_second');
	my $file2 = make_file($dir2, $name, $config{second_content});

	my (undef, $file) = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'array form found the second directory');

	make_file($dir1, $name, $config{first_content});
	(undef, $file) = pfopen("$dir1$config{sep}$dir2", $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'string form reused it, so the new file in the first directory is not seen');
	proved('side effect: string and array share');
};

subtest 'a remembered file that cannot be opened is forgotten' => sub {
	my $dir1 = make_dir('forget_first');
	my $dir2 = make_dir('forget_second');
	my $file1 = make_file($dir1, $name, $config{first_content});
	my $file2 = make_file($dir2, $name, $config{second_content});

	my (undef, $file) = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file1, 'remembered the first directory');

	unlink($file1) or die "unlink $file1: $!";
	(undef, $file) = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file2, 'deleted file: searched again');

	{
		# Can't be opened, rather than doesn't exist
		local $open_fails_for = qr/\A\Q$file2\E\z/;
		my @rc = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
		is(scalar(@rc), 0, 'unopenable file: nothing returned');
	}

	# Had it been remembered, this would be found without a search and so
	#	not the new file
	$file1 = make_file($dir1, $name, $config{first_content});
	(undef, $file) = pfopen([$dir1, $dir2], $config{prefix}, $config{suffix}, '<');
	is($file, $file1, 'the failed file was forgotten, so the search found the new file');
	proved('side effect: forgotten');
};

subtest 'does not change $!, $@ or $_' => sub {
	my $dir = make_dir('globals');
	make_file($dir, $name, $config{first_content});
	my $missing = File::Spec->catdir($dir, $config{missing_dir});

	# Each call goes through failing file tests, which would set $!
	foreach my $call (
		[ 'found', [$missing, $dir], $config{prefix} ],
		[ 'not found', [$missing, $dir], 'no_such_file' ],
	) {
		my ($label, $path, $prefix) = @{$call};
		local $! = EACCES;
		local $@ = 'caller error';
		local $_ = 'caller topic';

		pfopen($path, $prefix, $config{suffix}, '<');
		is($! + 0, EACCES, "$label: \$! unchanged");
		is($@, 'caller error', "$label: \$\@ unchanged");
		is($_, 'caller topic', "$label: \$_ unchanged");
	}
	proved('side effect: globals');
};

subtest 'does not change the caller arguments' => sub {
	my $dir = make_dir('arguments');
	make_file($dir, $name, $config{first_content});

	my @path = (undef, '', $dir);
	my @before = @path;
	my ($prefix, $suffixes, $mode) = ($config{prefix}, $config{suffix}, '<');

	pfopen(\@path, $prefix, $suffixes, $mode);
	is_deeply(\@path, \@before, 'path array not filtered');
	is($prefix, $config{prefix}, 'prefix');
	is($suffixes, $config{suffix}, 'suffixes');
	is($mode, '<', 'mode');

	my $default;
	pfopen($dir, $prefix, $suffixes, $default);
	ok(!defined($default), 'default mode not written back');
	proved('side effect: arguments');
};

SKIP: {
	skip('alarm() is not available', 1) unless($Config{d_alarm});

	subtest 'does not disturb a pending alarm' => sub {
		my $dir = make_dir('alarm');
		make_file($dir, $name, $config{first_content});

		local $SIG{ALRM} = sub { die 'alarm fired during the test' };
		alarm($config{alarm_seconds});
		pfopen($dir, $config{prefix}, $config{suffix}, '<');
		my $remaining = alarm(0);
		diag("alarm remaining: $remaining") if($ENV{TEST_VERBOSE});
		cmp_ok($remaining, '>', 0, 'alarm still pending');
		cmp_ok($remaining, '<=', $config{alarm_seconds}, 'and not reset to a later time');
	};
}

restore_all();

# Anything left is a documented state with no test
if(my @untested = sort keys %ledger) {
	fail("untested POD states: @untested");
	diag("$_: $ledger{$_}") foreach @untested;
} else {
	pass('every documented state was tested');
}

done_testing();
