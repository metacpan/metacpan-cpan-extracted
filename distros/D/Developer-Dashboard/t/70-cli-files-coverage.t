#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use Capture::Tiny qw(capture);

use lib 'lib';

use Developer::Dashboard::CLI::Files;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Config;

# Collect (rather than print) any warning so the run can assert warning-cleanliness
# explicitly instead of leaking noise onto STDERR.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# Hermetic runtime rooted in a throwaway home. run_files_command resolves its
# config layer from the current working directory, so the CWD must be the temp
# home for the whole run.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};    # never inherit an outside config root
chdir $home or die "Unable to chdir to $home: $!";

# run_files_command prints to STDOUT and returns 1 on success. Capture output so
# it never contaminates the TAP stream, and return the command result.
sub run_ok {
    my (%args) = @_;
    my ( $stdout, $stderr, $rv ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command(%args);
    };
    return ( $stdout, $rv );
}

# Same as run_ok but for the die paths: swallow the exception and return its text.
sub run_die {
    my (%args) = @_;
    my $err = '';
    my ( $stdout, $stderr ) = capture {
        eval { Developer::Dashboard::CLI::Files::run_files_command(%args); 1 } or $err = $@;
    };
    return ( $stdout, $err );
}

# ---------------------------------------------------------------------------
# Argument guards on run_files_command itself.
# ---------------------------------------------------------------------------
{
    my ( undef, $err ) = run_die( args => [] );    # no command
    like( $err, qr/Missing command name/, 'run_files_command requires a command name' );
}
{
    my ( undef, $err ) = run_die( command => 'files' );    # no args
    like( $err, qr/Missing command arguments/, 'run_files_command requires an args value' );
}
{
    my ( undef, $err ) = run_die( command => 'files', args => 'not-an-array' );
    like( $err, qr/must be an array reference/, 'run_files_command rejects non-array args' );
}

# ---------------------------------------------------------------------------
# dashboard files (whole inventory).
# ---------------------------------------------------------------------------
{
    my ( $out, $rv ) = run_ok( command => 'files', args => [] );
    is( $rv, 1, 'files default table returns success' );
    like( $out, qr/File/, 'files default output renders the inventory table header' );
}
{
    my ( $out, $rv ) = run_ok( command => 'files', args => [ '-o', 'json' ] );
    is( $rv, 1, 'files json returns success' );
    like( $out, qr/^\s*\{/, 'files json output is a JSON object' );
}
{
    my ( undef, $rv ) = run_ok( command => 'files', args => [ '-o', 'table' ] );
    is( $rv, 1, 'files explicit table returns success' );
}
{
    my ( undef, $err ) = run_die( command => 'files', args => ['unexpected'] );
    like( $err, qr/Usage: dashboard files/, 'files rejects extra positional arguments' );
}
{
    my ( undef, $err ) = run_die( command => 'files', args => [ '-o', 'xml' ] );
    like( $err, qr/Usage: dashboard files/, 'files rejects an invalid output format' );
}

# ---------------------------------------------------------------------------
# dashboard file list (saved aliases).
# ---------------------------------------------------------------------------
{
    my ( $out, $rv ) = run_ok( command => 'file', args => ['list'] );
    is( $rv, 1, 'file list default table returns success' );
    like( $out, qr/Alias/, 'file list renders the alias table header' );
}
{
    my ( undef, $rv ) = run_ok( command => 'file', args => [ 'list', '-o', 'json' ] );
    is( $rv, 1, 'file list json returns success' );
}
{
    my ( undef, $rv ) = run_ok( command => 'file', args => [ 'list', '-o', 'table' ] );
    is( $rv, 1, 'file list explicit table returns success' );
}
{
    my ( undef, $err ) = run_die( command => 'file', args => [ 'list', 'extra' ] );
    like( $err, qr/Usage: dashboard file list/, 'file list rejects extra arguments' );
}
{
    my ( undef, $err ) = run_die( command => 'file', args => [ 'list', '-o', 'xml' ] );
    like( $err, qr/Usage: dashboard file list/, 'file list rejects an invalid output format' );
}

# ---------------------------------------------------------------------------
# dashboard file resolve and the empty-action fallthrough.
# ---------------------------------------------------------------------------
{
    my ( $out, $rv ) = run_ok( command => 'file', args => [ 'resolve', 'prompt_log' ] );
    is( $rv, 1, 'file resolve returns success' );
    like( $out, qr/prompt\.log/, 'file resolve prints the resolved builtin path' );
}
{
    my ( undef, $err ) = run_die( command => 'file', args => ['resolve'] );
    like( $err, qr/Usage: dashboard file resolve/, 'file resolve requires a name' );
}
{
    my ( undef, $err ) = run_die( command => 'file', args => [] );    # empty action
    like( $err, qr/Usage: dashboard file <resolve/, 'file with no action prints the top usage' );
}

# ---------------------------------------------------------------------------
# dashboard file add.
# ---------------------------------------------------------------------------
my $notes = File::Spec->catfile( $home, 'notes.txt' );
{
    my ( $out, $rv ) = run_ok( command => 'file', args => [ 'add', 'myalias', $notes ] );
    is( $rv, 1, 'file add returns success' );
    like( $out, qr/myalias/, 'file add renders the mutation table with the alias name' );
    like( $out, qr/saved/,   'file add reports the saved status' );
}
{
    my ( undef, $rv ) = run_ok( command => 'file', args => [ 'add', 'myalias2', $notes, '-o', 'json' ] );
    is( $rv, 1, 'file add json returns success' );
}
{
    my ( undef, $err ) = run_die( command => 'file', args => ['add'] );
    like( $err, qr/dashboard file add <name> <path>/, 'file add requires a name' );
}
{
    my ( undef, $err ) = run_die( command => 'file', args => [ 'add', 'only-name' ] );
    like( $err, qr/dashboard file add <name> <path>/, 'file add requires a path' );
}

# ---------------------------------------------------------------------------
# dashboard file del (existing, missing, and guard paths).
# ---------------------------------------------------------------------------
{
    run_ok( command => 'file', args => [ 'add', 'delme', $notes ] );
    my ( $out, $rv ) = run_ok( command => 'file', args => [ 'del', 'delme' ] );
    is( $rv, 1, 'file del returns success' );
    like( $out, qr/removed/, 'file del reports removal of an existing alias' );
}
{
    my ( $out, $rv ) = run_ok( command => 'file', args => [ 'del', 'never-existed' ] );
    is( $rv, 1, 'file del of a missing alias still returns success' );
    like( $out, qr/no-change/, 'file del of a missing alias reports no-change' );
}
{
    my ( undef, $rv ) = run_ok( command => 'file', args => [ 'del', 'delme', '-o', 'json' ] );
    is( $rv, 1, 'file del json returns success' );
}
{
    my ( undef, $err ) = run_die( command => 'file', args => ['del'] );
    like( $err, qr/dashboard file del <name>/, 'file del requires a name' );
}

# ---------------------------------------------------------------------------
# dashboard file locate: all three root-selection outcomes.
# ---------------------------------------------------------------------------
my $locdir = File::Spec->catdir( $home, 'locdir' );
make_path($locdir);
{
    open my $fh, '>', File::Spec->catfile( $locdir, 'target-note.txt' ) or die $!;
    print {$fh} "hello\n";
    close $fh;
}

# (a) first argument resolves to a real path -> used as the search root.
run_ok( command => 'file', args => [ 'add', 'locroot', $locdir ] );
{
    my ( $out, $rv ) = run_ok( command => 'file', args => [ 'locate', 'locroot', 'target' ] );
    is( $rv, 1, 'file locate via a resolvable alias root returns success' );
    like( $out, qr/target-note\.txt/, 'file locate finds files beneath a resolved alias root' );
}
{
    my ( undef, $rv ) = run_ok( command => 'file', args => [ 'locate', 'locroot', 'target', '-o', 'json' ] );
    is( $rv, 1, 'file locate json returns success' );
}

# (b) first argument neither resolves nor is a directory -> both root branches false.
{
    my ( undef, $rv ) = run_ok( command => 'file', args => [ 'locate', 'no-such-root-xyz', 'target' ] );
    is( $rv, 1, 'file locate with an unresolvable non-directory candidate returns success' );
}

# (c) first argument is a bare existing directory (not an alias) -> the -d elsif runs.
{
    my ( $out, $rv ) = run_ok( command => 'file', args => [ 'locate', 'locdir', 'target' ] );
    is( $rv, 1, 'file locate treats a bare existing directory as the search root' );
    like( $out, qr/target-note\.txt/, 'file locate searches a directory candidate directly' );
}

# (d) an alias whose stored value expands to a defined empty string: the resolve
# result is defined but eq '' so the "defined && ne ''" guard takes its middle path.
{
    my $inj_paths  = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );
    my $inj_files  = Developer::Dashboard::FileRegistry->new( paths => $inj_paths );
    my $inj_config = Developer::Dashboard::Config->new( files => $inj_files, paths => $inj_paths );
    $inj_config->save_global( { file_aliases => { emptyalias => '' } } );

    my ( undef, $rv ) = run_ok( command => 'file', args => [ 'locate', 'emptyalias', 'target' ] );
    is( $rv, 1, 'file locate tolerates an alias that resolves to an empty string' );
}

# ---------------------------------------------------------------------------
# Table renderers exercised directly for their defensive fallback sides.
# ---------------------------------------------------------------------------
{
    my $table = Developer::Dashboard::CLI::Files::_files_table(undef);
    like( $table, qr/File/, '_files_table renders a header even without an inventory hash' );
}
{
    my $table = Developer::Dashboard::CLI::Files::_aliases_table(undef);
    like( $table, qr/Alias/, '_aliases_table renders a header even without alias data' );
}
{
    my $table = Developer::Dashboard::CLI::Files::_list_table( 'Path', undef );
    like( $table, qr/Path/, '_list_table renders a header even without item data' );
}
{
    my $table = Developer::Dashboard::CLI::Files::_mutation_table( alias => 'lonely' );
    like( $table, qr/lonely/, '_mutation_table blanks missing stored/resolved/status fields' );
}
{
    my $removed = Developer::Dashboard::CLI::Files::_removal_table( alias => 'gone', removed => 1 );
    like( $removed, qr/removed/, '_removal_table reports removed aliases' );

    my $kept = Developer::Dashboard::CLI::Files::_removal_table( removed => 0 );
    like( $kept, qr/no-change/, '_removal_table reports no-change and blanks a missing alias' );
}
{
    my $empty = Developer::Dashboard::CLI::Files::_render_table( undef, undef );
    ok( defined $empty, '_render_table tolerates undef header and rows without dying' );

    my $undef_header = Developer::Dashboard::CLI::Files::_render_table( [ undef, 'X' ], [] );
    like( $undef_header, qr/X/, '_render_table blanks undef header cells' );

    my $normal = Developer::Dashboard::CLI::Files::_render_table( [ 'A', 'B' ], [ [ '1', '2' ] ] );
    like( $normal, qr/A\s+B/, '_render_table renders a populated header and row' );
}

# ---------------------------------------------------------------------------
# _build_paths with a falsy HOME exercises the "$ENV{HOME} || ''" fallback.
# ---------------------------------------------------------------------------
{
    local $ENV{HOME} = '';
    local $ENV{USERPROFILE};
    local $ENV{HOMEDRIVE};
    local $ENV{HOMEPATH};
    my $built = eval { Developer::Dashboard::CLI::Files::_build_paths() };
    ok( !defined $built, '_build_paths with an empty HOME cannot build a registry' );
    like( $@, qr/Missing home directory/, '_build_paths uses the empty-string HOME fallback before the missing-home guard fires' );
}

is( scalar @warnings, 0, 'exercising the file CLI helpers stays warning-clean' )
  or diag( "unexpected warnings:\n" . join( '', @warnings ) );

done_testing;

__END__

=pod

=head1 NAME

t/70-cli-files-coverage.t - branch and condition coverage closure for the file CLI helper

=head1 PURPOSE

This test is the executable coverage contract for the lightweight
C<dashboard file> and C<dashboard files> command runtime. It drives every
dispatch verb, every usage-guard die, every output-format rejection, and each
table renderer so the module reaches full branch and condition coverage without
loading the heavier dashboard runtime.

=head1 WHY IT EXISTS

The file CLI helper mixes argument validation, alias resolution, config-backed
persistence, directory-root selection for locate, and several defensive table
renderers. Many of those sides (a non-array argv, an alias that expands to an
empty string, an undef header cell, a falsy HOME) never occur on the normal
happy path, so they are only reachable from a test written to force them. This
file exists to hold those forced paths in one place so the coverage gate cannot
silently regress and so a reader can see exactly which edge each assertion pins.

=head1 WHEN TO USE

Use this file when changing the file command dispatch, the usage or output-format
guards, the alias add/del/list persistence contract, the locate root-selection
logic, or any of the summary table renderers.

=head1 HOW TO USE

Run C<perl -Ilib t/70-cli-files-coverage.t> or C<prove -lv t/70-cli-files-coverage.t>
while iterating, then keep it green under C<prove -lr t> and the Devel::Cover
gate before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the coverage gate all
rely on this file to keep the file CLI helper's branch and condition coverage
honest.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/70-cli-files-coverage.t

Run the focused coverage test standalone while changing the file CLI helper.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate after landing a change.

=cut
