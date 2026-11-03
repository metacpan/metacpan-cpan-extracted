#!/usr/bin/env perl
use strict;
use warnings;

# Usage: xbin/run-sibling-tests.pl php|go|rust
#
# Runs the test suite of one of the newer runtimes from dist.ini's run_test and
# run_before_release. A toolchain that is missing or older than the port needs
# is SKIPPED with a visible message and exit 0 instead of failing the release
# on a machine that does not build that language. CI is the other half: the
# workflow .github/workflows/test.yml runs all six suites and must not skip.
#
# A bare `command -v` is not enough: on a box with an old /usr/bin/go the
# suite would silently run against a toolchain the port does not support. So
# every candidate is asked for its version, and the first one that is new
# enough wins. Besides $PATH, the usual per-user install dirs are searched.

use File::Spec;
use FindBin qw($Bin);

my $root = File::Spec->rel2abs("$Bin/..");
my $home = $ENV{HOME} // '';

# Minimum versions are the floors the ports themselves declare:
#   go   go.mod            "go 1.21"
#   rust rust/Cargo.toml   rust-version = "1.67" for the crate, but the test
#                          dependency serde_json needs Rust 1.71
#   php  composer.json     "php": ">=8.0" for the package, but the test
#                          dependency phpunit ^11.5 needs PHP 8.2
my %runtime = (
	php => {
		tool    => 'php',
		min     => [ 8, 2 ],
		version => [ '-r', 'echo PHP_VERSION;' ],
		dirs    => [],
	},
	go => {
		tool    => 'go',
		min     => [ 1, 21 ],
		version => ['version'],
		dirs    => [ "$home/opt/go/bin", "$home/go/bin", '/usr/local/go/bin' ],
	},
	rust => {
		tool    => 'cargo',
		min     => [ 1, 71 ],
		version => ['--version'],
		dirs    => ["$home/.cargo/bin"],
	},
);

my $name = shift // '';
my $rt = $runtime{$name} or die "usage: $0 php|go|rust\n";

sub skip {
	print "Skipping $name tests: @_\n";
	exit 0;
}

sub find_in {
	my ( $tool, @dirs ) = @_;
	return grep { -x $_ && !-d $_ } map { File::Spec->catfile( $_, $tool ) } @dirs;
}

sub version_of {
	my ( $exe, @args ) = @_;
	open my $fh, '-|', $exe, @args or return;
	my $out = do { local $/; <$fh> };
	close $fh;
	return unless defined $out && $out =~ /(\d+)\.(\d+)(?:\.(\d+))?/;
	return [ $1, $2, $3 // 0 ];
}

sub at_least {
	my ( $have, $min ) = @_;
	return $have->[0] > $min->[0] || ( $have->[0] == $min->[0] && $have->[1] >= $min->[1] );
}

# find a usable executable: first candidate with a new enough version
sub find_tool {
	my ($spec) = @_;
	my @candidates = ( find_in( $spec->{tool}, File::Spec->path ), find_in( $spec->{tool}, @{ $spec->{dirs} } ) );
	my @seen;
	for my $exe (@candidates) {
		my $have = version_of( $exe, @{ $spec->{version} } ) or next;
		return ( $exe, $have ) if at_least( $have, $spec->{min} );
		push @seen, "$exe is " . join( '.', @$have );
	}
	return ( undef, undef, \@seen );
}

my ( $exe, $have, $seen ) = find_tool($rt);
skip(
	"no $rt->{tool} >= " . join( '.', @{ $rt->{min} } ) . ' found'
		. ( $seen && @$seen ? ' (' . join( ', ', @$seen ) . ')' : '' )
) unless $exe;

chdir $root or die "cannot chdir to $root: $!\n";

# put the chosen toolchain first so child processes (cargo -> rustc) agree
my ( undef, $exe_dir ) = File::Spec->splitpath($exe);
$ENV{PATH} = join ':', $exe_dir, grep { length } $ENV{PATH};

sub run {
	my @cmd = @_;
	print "+ @cmd\n";
	system(@cmd) == 0 or die "command failed (exit @{[ $? >> 8 ]}): @cmd\n";
}

if ( $name eq 'go' ) {
	run( $exe, 'test', './go/...' );
}
elsif ( $name eq 'rust' ) {
	run( $exe, 'test', '--manifest-path', 'rust/Cargo.toml' );
}
else {
	# PHPUnit needs these extensions; without them it dies with an unhelpful
	# message, which is an environment gap and not a failing suite.
	my $loaded = `$exe -m`;
	my @missing = grep { $loaded !~ /^\Q$_\E$/mi } qw(dom json libxml mbstring tokenizer xml xmlwriter);
	skip( "PHP extensions missing for PHPUnit: " . join( ',', @missing ) ) if @missing;
	my ($composer) = find_in( 'composer', File::Spec->path );
	skip('no composer found') unless $composer || -x 'vendor/bin/phpunit';
	run( $composer, 'install', '--no-interaction', '--no-progress', '--prefer-dist' ) unless -x 'vendor/bin/phpunit';
	run( $exe, 'vendor/bin/phpunit', '-c', 'php/phpunit.xml.dist' );
}
