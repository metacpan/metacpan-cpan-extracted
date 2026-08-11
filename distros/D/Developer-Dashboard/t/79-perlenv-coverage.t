#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Config ();
use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use File::Spec;

use lib 'lib';
use Developer::Dashboard::PerlEnv;

my $M = 'Developer::Dashboard::PerlEnv';

# Any warning is a hard failure: warnings are errors in this repository, and the
# environment-normalization paths under test must stay noise-free even when they
# are handed empty, undefined, or non-existent entries.
$SIG{__WARN__} = sub { die "unexpected warning: $_[0]" };

# Hermetic, isolated runtime: an empty HOME and a scratch working directory so
# nothing reads or writes the developer's real dashboard layers.
my $orig_cwd = getcwd();
my $home     = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "chdir $home: $!";
END { chdir $orig_cwd if defined $orig_cwd; }

# ---------------------------------------------------------------------------
# path_separator(): the MSWin32 arm is only reachable when $^O reports Windows.
# ---------------------------------------------------------------------------
is( Developer::Dashboard::PerlEnv::path_separator(), ':', 'path_separator is colon off Windows' );
{
    local $^O = 'MSWin32';
    is( Developer::Dashboard::PerlEnv::path_separator(), ';', 'path_separator is semicolon on Windows' );
}

# ---------------------------------------------------------------------------
# current_perl_bin_dir(): interpreter present, empty, and unresolvable.
# ---------------------------------------------------------------------------
{
    my $dir = Developer::Dashboard::PerlEnv::current_perl_bin_dir();
    ok( $dir ne '' && -d $dir, 'current_perl_bin_dir returns a real directory for the running interpreter' );
}
{
    local $^X = '';
    is( Developer::Dashboard::PerlEnv::current_perl_bin_dir(), '', 'current_perl_bin_dir is empty when $^X is empty' );
}
{
    # abs_path() fails (missing parent) so the || falls back to the raw path,
    # whose dirname is not an existing directory -> empty result.
    local $^X = '/nonexistent-perlenv-xyz/foo/perl';
    is( Developer::Dashboard::PerlEnv::current_perl_bin_dir(), '', 'current_perl_bin_dir is empty when interpreter dir does not exist' );
}

# ---------------------------------------------------------------------------
# current_shell_bin_dir(): shell present, empty, and unresolvable.
# ---------------------------------------------------------------------------
{
    my $dir = Developer::Dashboard::PerlEnv::current_shell_bin_dir();
    ok( $dir ne '' && -d $dir, 'current_shell_bin_dir returns a real directory for the configured shell' );
}
{
    local %Config::Config = %Config::Config;
    $Config::Config{sh} = '';
    is( Developer::Dashboard::PerlEnv::current_shell_bin_dir(), '', 'current_shell_bin_dir is empty when the shell path is empty' );
}
{
    local %Config::Config = %Config::Config;
    $Config::Config{sh} = '/nonexistent-perlenv-xyz/foo/sh';
    is( Developer::Dashboard::PerlEnv::current_shell_bin_dir(), '', 'current_shell_bin_dir is empty when the shell dir does not exist' );
}

# ---------------------------------------------------------------------------
# core_inc_paths(): the default all-valid path plus the skip arms (empty value,
# non-directory value, and a duplicate canonical path).
# ---------------------------------------------------------------------------
{
    my @paths = Developer::Dashboard::PerlEnv::core_inc_paths();
    ok( scalar(@paths) >= 1, 'core_inc_paths returns the real interpreter library directories' );
    ok( ( !grep { !-d $_ } @paths ), 'every default core_inc_paths entry is an existing directory' );
}
{
    mkdir File::Spec->catdir( $home, 'inc_dup' )  or die $!;
    mkdir File::Spec->catdir( $home, 'inc_real' ) or die $!;
    my $dup  = File::Spec->catdir( $home, 'inc_dup' );
    my $real = File::Spec->catdir( $home, 'inc_real' );

    local %Config::Config = %Config::Config;
    $Config::Config{archlibexp}   = '';                                      # empty value -> skipped
    $Config::Config{privlibexp}   = File::Spec->catdir( $home, 'no_such' );  # non-directory -> skipped
    $Config::Config{sitearchexp}  = $dup;
    $Config::Config{sitelibexp}   = $dup;                                    # duplicate canonpath -> skipped
    $Config::Config{vendorarchexp} = $real;
    $Config::Config{vendorlibexp} = '';                                      # empty value -> skipped

    my @paths = Developer::Dashboard::PerlEnv::core_inc_paths();
    is_deeply( \@paths, [ $dup, $real ], 'core_inc_paths skips empty, non-directory, and duplicate library entries' );
}

# ---------------------------------------------------------------------------
# dashboard_lib_roots(): undef, empty, non-existent, and the perl5/arch tree.
# ---------------------------------------------------------------------------
is_deeply( [ $M->dashboard_lib_roots(undef) ], [], 'dashboard_lib_roots is empty for an undefined root' );
is_deeply( [ $M->dashboard_lib_roots('') ],    [], 'dashboard_lib_roots is empty for an empty root' );
is_deeply(
    [ $M->dashboard_lib_roots( File::Spec->catdir( $home, 'no_such_root' ) ) ],
    [],
    'dashboard_lib_roots is empty when the root is not an existing directory'
);

{
    my $plain = File::Spec->catdir( $home, 'lib_plain' );
    mkdir $plain or die $!;
    is_deeply( [ $M->dashboard_lib_roots($plain) ], [$plain], 'dashboard_lib_roots returns the bare root when there is no perl5 subtree' );
}

{
    # perl5 present, archname set, but no matching arch subdirectory.
    my $root = File::Spec->catdir( $home, 'lib_noarch' );
    mkdir $root or die $!;
    mkdir File::Spec->catdir( $root, 'perl5' ) or die $!;
    local %Config::Config = %Config::Config;
    $Config::Config{archname} = 'x86_64-perlenv-test';
    is_deeply(
        [ $M->dashboard_lib_roots($root) ],
        [ $root, File::Spec->catdir( $root, 'perl5' ) ],
        'dashboard_lib_roots stops at perl5 when the arch subdir is absent'
    );
}

{
    # perl5 present with a real arch subdirectory.
    my $root = File::Spec->catdir( $home, 'lib_arch' );
    mkdir $root or die $!;
    mkdir File::Spec->catdir( $root, 'perl5' ) or die $!;
    mkdir File::Spec->catdir( $root, 'perl5', 'myarch' ) or die $!;
    local %Config::Config = %Config::Config;
    $Config::Config{archname} = 'myarch';
    is_deeply(
        [ $M->dashboard_lib_roots($root) ],
        [ $root, File::Spec->catdir( $root, 'perl5' ), File::Spec->catdir( $root, 'perl5', 'myarch' ) ],
        'dashboard_lib_roots includes the arch subdir when it exists'
    );
}

{
    # perl5 present but archname is empty -> arch candidate not built.
    my $root = File::Spec->catdir( $home, 'lib_emptyarch' );
    mkdir $root or die $!;
    mkdir File::Spec->catdir( $root, 'perl5' ) or die $!;
    local %Config::Config = %Config::Config;
    $Config::Config{archname} = '';
    is_deeply(
        [ $M->dashboard_lib_roots($root) ],
        [ $root, File::Spec->catdir( $root, 'perl5' ) ],
        'dashboard_lib_roots omits the arch candidate when archname is empty'
    );
}

{
    # archname of '.' makes the arch candidate canonicalize back onto perl5,
    # exercising the seen-duplicate skip.
    my $root = File::Spec->catdir( $home, 'lib_dotarch' );
    mkdir $root or die $!;
    mkdir File::Spec->catdir( $root, 'perl5' ) or die $!;
    local %Config::Config = %Config::Config;
    $Config::Config{archname} = '.';
    is_deeply(
        [ $M->dashboard_lib_roots($root) ],
        [ $root, File::Spec->catdir( $root, 'perl5' ) ],
        'dashboard_lib_roots deduplicates an arch candidate that resolves back to perl5'
    );
}

# ---------------------------------------------------------------------------
# perl5lib_list(): path separator override, empty split fields, dashboard_lib
# variants, extra handling, and undef/empty prefix entries.
# ---------------------------------------------------------------------------
mkdir File::Spec->catdir( $home, 'p5a' ) or die $!;
mkdir File::Spec->catdir( $home, 'p5b' ) or die $!;
my $p5a = File::Spec->catdir( $home, 'p5a' );
my $p5b = File::Spec->catdir( $home, 'p5b' );

{
    # Explicit path_sep provided -> the || short-circuits on the argument.
    my @list = $M->perl5lib_list( env => {}, existing => [], extra => [$p5a], path_sep => ':' );
    is_deeply( [ grep { $_ eq $p5a } @list ], [$p5a], 'perl5lib_list honours an explicit path separator' );
}
{
    # Leading empty split field (":<dir>") must be dropped.
    my @list = $M->perl5lib_list( env => { PERL5LIB => ":$p5a" }, extra => [] );
    ok( ( grep { $_ eq $p5a } @list ), 'perl5lib_list keeps a real inherited path' );
    ok( ( !grep { $_ eq '' } @list ), 'perl5lib_list drops empty PERL5LIB fields' );
}
{
    # No existing override and no PERL5LIB -> the inherited-path split runs on
    # the empty-string fallback of ($env->{PERL5LIB} || '').
    my @list = $M->perl5lib_list( env => {}, extra => [] );
    ok( scalar(@list) >= 1, 'perl5lib_list falls back to an empty inherited PERL5LIB' );
}
{
    # dashboard_lib defined but empty -> the ternary takes the empty-list arm.
    my @list = $M->perl5lib_list( env => {}, existing => [], dashboard_lib => '', extra => [$p5a] );
    is_deeply( [ grep { $_ eq $p5a } @list ], [$p5a], 'perl5lib_list treats an empty dashboard_lib as no roots' );
}
{
    # dashboard_lib absent -> defined() is false.
    my @list = $M->perl5lib_list( env => {}, existing => [] );
    ok( scalar(@list) >= 1, 'perl5lib_list works with no dashboard_lib argument' );
}
{
    # dashboard_lib a real root -> both sides of the guard are true.
    my $root = File::Spec->catdir( $home, 'p5_root' );
    mkdir $root or die $!;
    my @list = $M->perl5lib_list( env => {}, existing => [], dashboard_lib => $root, extra => [] );
    is_deeply( [ grep { $_ eq $root } @list ], [$root], 'perl5lib_list expands a real dashboard_lib root' );
}
{
    # extra absent -> the || [] fallback arm.
    my @list = $M->perl5lib_list( env => {}, existing => [] );
    ok( ( !grep { $_ eq $p5a } @list ), 'perl5lib_list adds nothing extra when extra is omitted' );
}
{
    # extra carries undef and empty entries alongside a real one; the undef and
    # empty entries hit the defined/empty skip arms without warning.
    my @list = $M->perl5lib_list( env => {}, existing => [], extra => [ undef, '', $p5a ] );
    is_deeply( [ grep { $_ eq $p5a } @list ], [$p5a], 'perl5lib_list skips undef and empty extra entries' );
}

# ---------------------------------------------------------------------------
# perl5lib_env(): joined string with and without an explicit separator.
# ---------------------------------------------------------------------------
{
    my $str   = $M->perl5lib_env( env => {}, existing => [ $p5a, $p5b ], path_sep => ',' );
    my @parts = split /,/, $str;
    is_deeply( [ @parts[ -2, -1 ] ], [ $p5a, $p5b ], 'perl5lib_env joins with an explicit separator' );
}
{
    my $str   = $M->perl5lib_env( env => {}, existing => [ $p5a, $p5b ] );
    my @parts = split /:/, $str;
    is_deeply( [ @parts[ -2, -1 ] ], [ $p5a, $p5b ], 'perl5lib_env joins with the default separator' );
}

# ---------------------------------------------------------------------------
# path_with_current_perl(): separator override, empty/absent PATH, empty split
# fields, non-directory entries, and an empty interpreter directory.
# ---------------------------------------------------------------------------
{
    my $str = $M->path_with_current_perl( env => { PATH => $p5a }, path_sep => ':' );
    ok( ( grep { $_ eq $p5a } split /:/, $str ), 'path_with_current_perl honours an explicit separator' );
}
{
    my $str = $M->path_with_current_perl( env => {} );
    ok( $str ne '', 'path_with_current_perl still yields the interpreter dir with no inherited PATH' );
}
{
    my $str = $M->path_with_current_perl( env => { PATH => File::Spec->catdir( $home, 'no_such_path' ) } );
    ok( ( !grep { $_ eq File::Spec->catdir( $home, 'no_such_path' ) } split /:/, $str ), 'path_with_current_perl drops non-directory PATH entries' );
}
{
    my $str = $M->path_with_current_perl( env => { PATH => ":$p5a" } );
    ok( ( grep { $_ eq $p5a } split /:/, $str ), 'path_with_current_perl keeps a real inherited PATH entry' );
    ok( ( !grep { $_ eq '' } split /:/, $str ), 'path_with_current_perl drops empty PATH fields' );
}
{
    # An empty interpreter directory ($^X empty) makes the first candidate the
    # empty string, exercising the $path eq '' skip arm.
    local $^X = '';
    my $str = $M->path_with_current_perl( env => { PATH => $p5a } );
    ok( ( grep { $_ eq $p5a } split /:/, $str ), 'path_with_current_perl skips an empty interpreter directory' );
}

# ---------------------------------------------------------------------------
# dashboard_child_env(): explicit env hash and the %ENV default.
# ---------------------------------------------------------------------------
{
    my $child = $M->dashboard_child_env( env => { PATH => $p5a, PERL5LIB => $p5b } );
    ok( exists $child->{PATH} && exists $child->{PERL5LIB}, 'dashboard_child_env builds PATH and PERL5LIB from an explicit env' );
    ok( ( grep { $_ eq $p5a } split /:/, $child->{PATH} ), 'dashboard_child_env carries the explicit PATH entry through' );
}
{
    my $child = $M->dashboard_child_env();
    ok( exists $child->{PATH} && exists $child->{PERL5LIB}, 'dashboard_child_env falls back to %ENV when no env is given' );
}

# ---------------------------------------------------------------------------
# bootstrap_perl5lib(): explicit env hash and the %ENV default.
# ---------------------------------------------------------------------------
{
    my %env   = ( PERL5LIB => $p5b );
    my $value = $M->bootstrap_perl5lib( env => \%env, existing => [$p5a] );
    is( $env{PERL5LIB}, $value, 'bootstrap_perl5lib writes the value back into an explicit env hash' );
    ok( ( grep { $_ eq $p5a } split /:/, $value ), 'bootstrap_perl5lib includes the supplied existing path' );
}
{
    local $ENV{PERL5LIB};
    my $value = $M->bootstrap_perl5lib( existing => [$p5a] );
    is( $ENV{PERL5LIB}, $value, 'bootstrap_perl5lib writes back into %ENV by default' );
}

chdir $orig_cwd or die "chdir back: $!";
done_testing;

__END__

=pod

=head1 NAME

t/79-perlenv-coverage.t - branch and condition coverage for the Perl environment normalizer

=head1 PURPOSE

This test drives every decision arm of C<Developer::Dashboard::PerlEnv> so that
the module's PATH and PERL5LIB normalization stays fully exercised: the platform
separator choice, interpreter and shell directory resolution, the core library
enumeration and its skip arms, dashboard library root expansion, and the child
environment and bootstrap builders.

=head1 WHY IT EXISTS

C<PerlEnv> is the single place that keeps dashboard-managed child processes on
the same Perl interpreter and a safe library ordering. Its correctness depends
on a set of small guard clauses - empty interpreter paths, non-existent shell
directories, duplicate library roots, undefined or empty caller-supplied path
entries - that ordinary happy-path tests never reach. This test exists to hold
those guards under coverage so a future refactor cannot silently drop one of
them and reintroduce interpreter drift or stale dual-life module shadowing.

=head1 WHEN TO USE

Run this file when changing how C<PerlEnv> resolves the interpreter or shell
directory, enumerates core library paths, expands dashboard library roots, or
merges inherited PATH and PERL5LIB values. It is also the right regression to
extend when adding a new environment guard clause.

=head1 HOW TO USE

Run C<prove -lv t/79-perlenv-coverage.t> while iterating, and keep it green in
the full C<prove -lr t> suite. To confirm coverage of the target arms, run it
under Devel::Cover and inspect the branch and condition columns for
C<lib/Developer/Dashboard/PerlEnv.pm>.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the coverage gate all use
this file to keep the Perl environment normalizer fully covered and warning
free.

=head1 EXAMPLES

Example 1:

  prove -lv t/79-perlenv-coverage.t

Run the PerlEnv coverage regression by itself.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
