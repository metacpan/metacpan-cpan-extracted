#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for Fugu::Sandbox: the no-op contract everywhere,
# real enforcement on OpenBSD. Enforcement runs in child processes.
# A pledge violation kills the violator with an uncatchable SIGABRT.
# An unveil restricts the caller permanently. The parent must stay
# unrestricted, or it takes down the rest of the suite. Never assert
# in the children. The children share the TAP stream.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use POSIX qw(SIGABRT);

use_ok('Fugu::Sandbox');

my $lib = "$RealBin/../../lib";
my $dir = tempdir( CLEANUP => 1 );

# run_child($source):
#	Run perl code in a subprocess with core dumps disabled.
#	Without this, the SIGABRT from a pledge violation drops
#	perl.core into the repository root. The shell must exec perl,
#	not fork it. The shell reaps a forked child's death-by-signal
#	and reports exit code 134. That loses the signal from the wait
#	status this function returns.
sub run_child ($source)
{
	my $script = "$dir/child-$$-" . int( rand 10000 ) . '.pl';
	open my $fh, '>', $script or die "write $script: $!";
	print $fh $source;
	close $fh;

	system( 'sh', '-c', "ulimit -c 0; exec '$^X' -I'$lib' '$script'" );
	unlink $script;

	return $?;
}

# The test defines the child sources at file scope. Thus the compile
# subtest below syntax-checks them on every platform. The children
# themselves only run on OpenBSD. A heredoc interpolation slip in one
# once stayed hidden until a VM run.
my $violation_child = <<'EOF';
use v5.36;
use Fugu::Sandbox;
use Socket qw(AF_INET SOCK_STREAM);
use POSIX ();
Fugu::Sandbox->pledge(promises => 'stdio');
socket(my $s, AF_INET, SOCK_STREAM, 0);
POSIX::_exit(0);    # only reachable if the pledge did not enforce
EOF

# The exit codes identify the failing step. Exit 1: a file outside
# the view stayed readable. Exit 2: the file inside did not open.
my $unveil_child = <<EOF . <<'BODY';
use v5.36;
use Fugu::Sandbox;
use POSIX ();
my \$dir = '$dir';
EOF
Fugu::Sandbox->unveil(paths => [[$dir, 'r']]);
Fugu::Sandbox->unveil_lock;
POSIX::_exit(1) if open(my $out, '<', '/etc/services');
POSIX::_exit(2) unless open(my $in, '<', "$dir/inside.txt");
POSIX::_exit(0);
BODY

# Exit 3: unveil silently accepted a missing required path. Exit 4:
# unveil did not skip a missing optional path cleanly. Exit 5:
# on_skip did not report the skipped path.
my $dispositions_child = <<EOF . <<'BODY';
use v5.36;
use Fugu::Sandbox;
use POSIX ();
my \$dir = '$dir';
EOF
my @skipped;
eval {
	Fugu::Sandbox->unveil(
		paths   => [["$dir/no-such-entry", 'r']],
	);
	1;
} and POSIX::_exit(3);
eval {
	Fugu::Sandbox->unveil(
		paths => [
			["$dir/no-such-entry", 'r', { optional => 1 }],
			[$dir, 'r'],
		],
		on_skip => sub ($path) { push @skipped, $path },
	);
	1;
} or POSIX::_exit(4);
POSIX::_exit(5) unless @skipped == 1;
POSIX::_exit(0);
BODY

subtest 'is_supported reflects the platform' => sub {
	is( !!Fugu::Sandbox->is_supported,
		!!( $^O eq 'openbsd' ),
		'true exactly on OpenBSD' );
};

subtest 'child sources compile on every platform' => sub {
	my %children = (
		violation    => $violation_child,
		unveil       => $unveil_child,
		dispositions => $dispositions_child,
	);
	for my $name ( sort keys %children ) {
		my $script = "$dir/compile-$name.pl";
		open my $fh, '>', $script or die "write $script: $!";
		print $fh $children{$name};
		close $fh;

		is( system("'$^X' -I'$lib' -c '$script' >/dev/null 2>&1"),
			0, "$name child source compiles" );
		unlink $script;
	}
};

subtest 'malformed arguments die on every platform' => sub {
	ok( !eval { Fugu::Sandbox->pledge; 1 },
		'pledge without promises dies' );
	ok( !eval { Fugu::Sandbox->pledge( promises => '' ); 1 },
		'pledge with an empty promise set dies' );
	ok( !eval { Fugu::Sandbox->unveil; 1 },
		'unveil without paths dies' );
	ok( !eval { Fugu::Sandbox->unveil( paths => 'not-a-ref' ); 1 },
		'unveil with a non-arrayref dies' );
};

subtest 'no-op platforms return success from every method' => sub {
	plan skip_all => 'this platform enforces for real'
	    if Fugu::Sandbox->is_supported;

	is( Fugu::Sandbox->pledge( promises => 'stdio rpath' ),
		1, 'pledge is a successful no-op' );
	is( Fugu::Sandbox->unveil( paths => [ [ $dir, 'r' ] ] ),
		1, 'unveil is a successful no-op' );
	is( Fugu::Sandbox->unveil_lock, 1, 'lock is a successful no-op' );

	# None of the methods restricted anything
	ok( open( my $fh, '<', $0 ), 'filesystem still fully visible' );
	close $fh if $fh;
};

subtest 'pledge violation aborts the violator' => sub {
	plan skip_all => 'pledge(2) only enforced on OpenBSD'
	    unless Fugu::Sandbox->is_supported;

	my $status = run_child($violation_child);
	is( $status & 127, SIGABRT,
		'socket(2) outside the promise set delivers SIGABRT' );
	unlink 'perl.core';    # a second guard: ulimit already forbids it
};

subtest 'a bogus promise string dies rather than being accepted' => sub {
	plan skip_all => 'pledge(2) only enforced on OpenBSD'
	    unless Fugu::Sandbox->is_supported;

	# An unknown promise fails with EINVAL before any restriction
	# starts. Thus this test is safe in-process.
	ok( !eval {
		Fugu::Sandbox->pledge( promises => 'nosuchpromise' );
		1;
	    },
	    'unknown promise dies'
	);
	like( $@, qr/pledge\(nosuchpromise\)/, 'error names the promises' );
};

subtest 'unveil restricts the filesystem view' => sub {
	plan skip_all => 'unveil(2) only enforced on OpenBSD'
	    unless Fugu::Sandbox->is_supported;

	my $inside = "$dir/inside.txt";
	open my $fh, '>', $inside or die "write $inside: $!";
	print $fh "visible\n";
	close $fh;

	my $status = run_child($unveil_child);
	is( $status >> 8, 0, 'outside unreadable, inside readable' );
};

subtest 'required and optional dispositions' => sub {
	plan skip_all => 'unveil(2) only enforced on OpenBSD'
	    unless Fugu::Sandbox->is_supported;

	my $status = run_child($dispositions_child);
	is( $status >> 8, 0,
		'missing required dies, missing optional is skipped and reported'
	);
};

# The two inventory builders assemble data and call no syscall. Thus
# they run on every platform, and never touch the filesystem view.
subtest 'perl_lib_dirs names the interpreter build' => sub {
	require Config;

	my @dirs = Fugu::Sandbox->perl_lib_dirs;
	ok( @dirs, 'the list is not empty' );

	my %seen = map { $_ => 1 } @dirs;
	for my $key (qw(privlibexp archlibexp)) {
		my $dir = $Config::Config{$key};
		next unless defined $dir && length $dir;
		ok( $seen{$dir}, "$key is in the list" );
	}

	# The list is the interpreter build, never the live @INC. A
	# directory that a program adds at run time must not appear.
	my $added = '/nonexistent/added/at/run/time';
	local @INC = ( @INC, $added );
	my %again = map { $_ => 1 } Fugu::Sandbox->perl_lib_dirs;
	ok( !$again{$added}, 'a run-time @INC entry stays out' );

	is_deeply(
		[ Fugu::Sandbox->perl_lib_dirs ],
		\@dirs,
		'the list is deterministic'
	);
};

subtest 'system_paths is the shared read-only inventory' => sub {
	my @paths = Fugu::Sandbox->system_paths;
	my %row   = map { $_->[0] => $_ } @paths;

	for my $path (
		'/dev/urandom',   '/etc/resolv.conf',
		'/etc/hosts',     '/etc/services',
		'/etc/protocols', '/etc/localtime'
	    )
	{
		ok( exists $row{$path}, "$path is in the inventory" );
		is( $row{$path}[1], 'r', "$path is read-only" );
	}

	ok( !$row{'/dev/urandom'}[2]{optional}, '/dev/urandom is required' );
	for my $path (
		'/etc/resolv.conf', '/etc/hosts',
		'/etc/services',    '/etc/protocols',
		'/etc/localtime'
	    )
	{
		ok( $row{$path}[2]{optional}, "$path is optional" );
	}

	ok( ( !grep { $_->[1] =~ /[wcx]/ } @paths ),
		'no entry grants write, create or execute' );

	# The entries have the shape that unveil takes. The test does
	# not call unveil: on OpenBSD that would restrict the view of
	# the whole test file.
	my $shape = 1;
	for my $entry (@paths) {
		$shape = 0
		    unless ref $entry eq 'ARRAY'
		    && defined $entry->[0]
		    && defined $entry->[1]
		    && ( @$entry < 3 || ref $entry->[2] eq 'HASH' );
	}
	ok( $shape, 'every entry has the shape that unveil takes' );
};

done_testing();
