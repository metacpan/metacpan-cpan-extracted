#!/usr/bin/env perl
#
# Which Python plt runs, and that it runs it properly.
#
# Until 0.315 the module ran "python3", which a stock Windows install does not
# have -- there it is "python", or the "py" launcher -- so on MSWin32 the module
# could not run a script wherever Python *was* installed.  It never showed up
# in a CPAN Testers report because the Windows smokers have no Python, so this
# file does not wait for one that does: on unix it sets $^O to "MSWin32" and
# puts stand-in interpreters, small shell scripts, on a PATH of their own,
# which is enough to drive the search in python_command() through every case.
# The same stand-ins check that MATPLOTLIB_SIMPLE_PYTHON, added in 0.317,
# overrides the search and python3 alike.
#
# What each stand-in prints is what the real thing prints: "Python 3.12.4" for
# "--version" (on STDOUT since Python 3.4, on STDERR before), and for the
# Microsoft Store stub that Windows 10 and 11 install as "python.exe" when no
# Python is present, "Python was not found; run without arguments to install
# from the Microsoft Store, or disable this shortcut from Settings > Apps >
# Advanced app settings > App execution aliases." with exit status 9009.
#
# On MSWin32 itself the stand-ins cannot run (they are /bin/sh scripts), so
# only the last block runs there: whatever python_command() found, if it found
# anything, must say it is Python 3.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use Matplotlib::Simple;
use Test::More;

my $TMP = tempdir( CLEANUP => 1 );
my $seq = 0;

# Write an executable /bin/sh stand-in called $name into $dir.
sub stub {
	my ( $dir, $name, $body ) = @_;
	my $path = File::Spec->catfile( $dir, $name );
	open my $o, '>', $path or die "can't write $path: $!";
	print {$o} "#!/bin/sh\n$body\n";
	close $o or die "can't close $path: $!";
	chmod 0755, $path or die "can't chmod $path: $!";
	return $path;
}

sub stub_dir {
	my $dir = File::Spec->catdir( $TMP, 'bin' . $seq++ );
	mkdir $dir or die "can't mkdir $dir: $!";
	return $dir;
}

my $STORE_STUB = q{echo 'Python was not found; run without arguments to install from the Microsoft Store, or disable this shortcut from Settings > Apps > Advanced app settings > App execution aliases.' >&2; exit 9009};

# The search as MSWin32 runs it, against the stand-ins in $dir alone.
sub search_as_windows {
	my ($dir) = @_;
	local $^O = 'MSWin32';
	local $ENV{PATH} = $dir;
	local $Matplotlib::Simple::Matplotlib::python_command = undef;    # not yet looked for
	local $ENV{MATPLOTLIB_SIMPLE_PYTHON};    # the search is what is under test, whatever the caller set
	return [ Matplotlib::Simple::Matplotlib::python_command() ];
}

SKIP: {
	skip( 'the stand-in interpreters are /bin/sh scripts', 13 ) if $^O eq 'MSWin32';

	# ------------------------------------------------------------------------
	# 1. The search on MSWin32.
	# ------------------------------------------------------------------------
	my $dir = stub_dir();
	stub( $dir, 'python', 'echo "Python 3.13.0"' );
	stub( $dir, 'py',     'echo "Python 3.12.4"' );
	is_deeply( search_as_windows($dir), ['python'], 'MSWin32: "python" is taken first when it is Python 3' );

	$dir = stub_dir();
	stub( $dir, 'python',  $STORE_STUB );
	stub( $dir, 'py',      '[ "$1" = "-3" ] && [ "$2" = "--version" ] && echo "Python 3.12.4" && exit 0; exit 1' );
	stub( $dir, 'python3', 'echo "Python 3.11.9"' );
	is_deeply( search_as_windows($dir), [ 'py', '-3' ], 'MSWin32: the Microsoft Store stub is passed over for "py -3"' );

	$dir = stub_dir();
	stub( $dir, 'python',  'echo "Python 2.7.18" >&2' );    # exit 0, but Python 2
	stub( $dir, 'python3', 'echo "Python 3.11.9" >&2' );     # before 3.4, on STDERR
	is_deeply( search_as_windows($dir), ['python3'], 'MSWin32: Python 2 is passed over, and a version on STDERR is read' );

	$dir = stub_dir();
	stub( $dir, 'python', $STORE_STUB );
	is_deeply( search_as_windows($dir), [], 'MSWin32: nothing is found when nothing is Python 3' );

	# The result is kept: a second call does not search again.
	{
		my $found = stub_dir();
		stub( $found, 'python', 'echo "Python 3.13.0"' );
		local $^O = 'MSWin32';
		local $Matplotlib::Simple::Matplotlib::python_command = undef;
		local $ENV{MATPLOTLIB_SIMPLE_PYTHON};
		my @first;
		{ local $ENV{PATH} = $found; @first = Matplotlib::Simple::Matplotlib::python_command() }
		local $ENV{PATH} = stub_dir();    # empty: a fresh search would find nothing
		is_deeply( [ Matplotlib::Simple::Matplotlib::python_command() ], \@first, 'the interpreter found is kept for later calls' );
	}

	# Everywhere else it is python3, as it always was, found or not.
	{
		local $^O = 'linux';
		local $ENV{PATH} = stub_dir();
		local $Matplotlib::Simple::Matplotlib::python_command = undef;
		local $ENV{MATPLOTLIB_SIMPLE_PYTHON};
		is_deeply( [ Matplotlib::Simple::Matplotlib::python_command() ], ['python3'], 'not MSWin32: the interpreter is python3, unsearched' );
	}

	# ------------------------------------------------------------------------
	# 1a. MATPLOTLIB_SIMPLE_PYTHON names the interpreter outright.
	# ------------------------------------------------------------------------
	# Added in 0.317 for an HPC whose python3 is 3.6.8 with matplotlib 3.0,
	# too old for the scripts plt writes, where the one that works is a venv
	# or a module-loaded Python. The path has a space in it, as
	# "C:\Program Files\..." does, and must come back as one word.
	my $named_dir = File::Spec->catdir( $TMP, 'My Python' );
	mkdir $named_dir or die "can't mkdir $named_dir: $!";
	my $named = stub( $named_dir, 'python3', 'echo "Python 3.12.4"' );
	{
		$dir = stub_dir();
		stub( $dir, 'python', 'echo "Python 3.13.0"' );
		local $^O = 'MSWin32';
		local $ENV{PATH} = $dir;
		local $ENV{MATPLOTLIB_SIMPLE_PYTHON} = $named;
		local $Matplotlib::Simple::Matplotlib::python_command = undef;
		is_deeply( [ Matplotlib::Simple::Matplotlib::python_command() ], [$named], 'MSWin32: MATPLOTLIB_SIMPLE_PYTHON is taken over the search, space and all' );
	}
	{
		local $^O = 'linux';
		local $ENV{MATPLOTLIB_SIMPLE_PYTHON} = $named;
		local $Matplotlib::Simple::Matplotlib::python_command = undef;
		is_deeply( [ Matplotlib::Simple::Matplotlib::python_command() ], [$named], 'not MSWin32: MATPLOTLIB_SIMPLE_PYTHON is taken over python3' );
	}
	{
		local $^O = 'linux';
		local $ENV{MATPLOTLIB_SIMPLE_PYTHON} = '';
		local $Matplotlib::Simple::Matplotlib::python_command = undef;
		is_deeply( [ Matplotlib::Simple::Matplotlib::python_command() ], ['python3'], 'an empty MATPLOTLIB_SIMPLE_PYTHON counts as unset' );
	}

	# ------------------------------------------------------------------------
	# 2. plt runs the interpreter chosen, with the script as one argument.
	# ------------------------------------------------------------------------
	# A temporary directory with a space in its name, as %TEMP% has under a
	# Windows user name with a space in it: the path must arrive whole.
	my $spaced = File::Spec->catdir( $TMP, 'Temp Dir' );
	mkdir $spaced or die "can't mkdir $spaced: $!";
	my $record = File::Spec->catfile( $TMP, 'argv.txt' );
	$dir = stub_dir();
	my $ok_stub = stub( $dir, 'fakepy', qq{printf '%s\\n' "\$#" "\$1" > '$record'; exit 0} );
	{
		local $ENV{TMPDIR} = $spaced;
		local $Matplotlib::Simple::Matplotlib::python_command = [$ok_stub];
		my ( $out, $err, $pyfile ) = capture {
			plt( plot_type => 'bar', data => { A => 1 }, output_file => File::Spec->catfile( $TMP, 'x.svg' ) );
		};
		open my $in, '<', $record or die "can't read $record: $!";
		chomp( my @argv = <$in> );
		close $in;
		is_deeply( \@argv, [ 1, $pyfile ], 'plt: the chosen interpreter gets the script path as one argument, space and all' );
		SKIP: {
			# File::Spec 3.3, 3.3101 and 3.39_02 (perls 5.10.1, 5.12.5 and 5.16.3)
			# keep the first tmpdir they find and never read TMPDIR again; 3.78 does.
			skip "File::Spec $File::Spec::VERSION does not read TMPDIR again once it has found a tmpdir", 1
			 unless File::Spec->tmpdir eq $spaced;
			like( $pyfile, qr/Temp Dir/, 'plt: and the script really was in the directory with the space' );
		}
	}
	{
		my $env_record = File::Spec->catfile( $TMP, 'env argv.txt' );
		my $env_stub = stub( $named_dir, 'envpy', qq{printf '%s\\n' "\$#" "\$1" > '$env_record'; exit 0} );
		local $ENV{MATPLOTLIB_SIMPLE_PYTHON} = $env_stub;
		local $Matplotlib::Simple::Matplotlib::python_command = undef;
		my ( $out, $err, $pyfile ) = capture {
			plt( plot_type => 'bar', data => { A => 1 }, output_file => File::Spec->catfile( $TMP, 'v.svg' ) );
		};
		open my $in, '<', $env_record or die "can't read $env_record: $!";
		chomp( my @argv = <$in> );
		close $in;
		is_deeply( \@argv, [ 1, $pyfile ], 'plt: runs the interpreter MATPLOTLIB_SIMPLE_PYTHON names, from a path with a space' );
	}

	my $fail_stub = stub( $dir, 'failpy', 'echo "Traceback: boom" >&2; exit 3' );
	{
		local $Matplotlib::Simple::Matplotlib::python_command = [ $fail_stub, '-X' ];
		my ( $out, $err ) = capture {
			eval { plt( plot_type => 'bar', data => { A => 1 }, output_file => File::Spec->catfile( $TMP, 'y.svg' ) ) };
		};
		( my $died = "$@" ) =~ s/\n\t.*\z//s;
		like( $died, qr/^\Q$fail_stub\E -X \S+ unexpectedly returned exit value 3/, 'plt: a failing script is reported under the command actually run' );
	}
}

# ----------------------------------------------------------------------------
# 3. With no interpreter, plt says so and says what it tried.
# ----------------------------------------------------------------------------
{
	local $Matplotlib::Simple::Matplotlib::python_command = [];    # looked for, none found
	my ( $out, $err ) = capture {
		eval { plt( plot_type => 'bar', data => { A => 1 }, output_file => File::Spec->catfile( $TMP, 'z.svg' ) ) };
	};
	( my $died = "$@" ) =~ s/\n\t.*\z//s;
	like( $died, qr/no Python 3 interpreter was found to run .* tried "python", "py -3", "python3"/, 'plt: no interpreter is an error naming the ones tried' );
	my @r;
	capture { @r = eval { plt( plot_type => 'bar', data => { A => 1 }, execute => 0, output_file => File::Spec->catfile( $TMP, 'w.svg' ) ) } };
	ok( defined $r[0] && -f $r[0], 'plt: with no interpreter, execute => 0 still writes the script' );
}

# ----------------------------------------------------------------------------
# 4. On this machine, as it is.
# ----------------------------------------------------------------------------
{
	my @py = Matplotlib::Simple::Matplotlib::python_command();
	SKIP: {
		skip( 'no Python 3 interpreter on this machine', 1 ) unless scalar @py;
		my ( $out, $err, $status ) = capture {
			no warnings 'exec';    # python3 on unix is not searched for, and may be absent
			system( @py, '--version' );
		};
		skip( "\"@py\" is not installed", 1 ) if $status == -1;
		like( "$out$err", qr/^Python 3\./m, "python_command() is Python 3: \"@py\"" );
	}
}

done_testing();
