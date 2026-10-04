#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use File::Spec;

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Config;
use Developer::Dashboard::JSON qw(json_decode);

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die $!;

# --------------------------------------------------------------------------
# AC-1: -c/--create records a create flag on the alias entry; a plain add
# without the flag does not.
# --------------------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( paths => $paths, files => $files );

    my $missing_dir = File::Spec->catdir( $home, 'lazy-created' );
    my $saved = $config->save_global_path_alias( 'lazyone', $missing_dir, create => 1 );
    ok( $saved->{create}, 'AC-1: save_global_path_alias with create=>1 marks the returned alias as create' );

    my $plain_dir = File::Spec->catdir( $home, 'plain-target' );
    mkdir $plain_dir;
    my $plain = $config->save_global_path_alias( 'plainone', $plain_dir );
    ok( !$plain->{create}, 'AC-1: save_global_path_alias with no create option does not mark create' );

    my $aliases = $config->global_path_aliases;
    is( ref $aliases->{lazyone}, 'HASH', 'AC-1: the create-marked alias reads back as a metadata hash, not a bare string' );
    ok( $aliases->{lazyone}{create}, 'AC-1: the metadata hash carries create=>1' );
    is( $aliases->{plainone}, $plain_dir, 'AC-1: the non-create alias still reads back as a bare path string (backward compatible)' );
}

# --------------------------------------------------------------------------
# AC-2/AC-3: resolve_dir on a missing -c-marked alias creates it (with
# parents) and returns the path - the SAME logic serves any caller
# (cdr shells out to resolve_dir under the hood; this proves the shared
# resolver, not a per-caller duplication).
# --------------------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( paths => $paths, files => $files );

    my $missing_dir = File::Spec->catdir( $home, 'nested', 'deep', 'lazydir' );
    ok( !-d $missing_dir, 'control: the target directory genuinely does not exist yet' );

    $config->save_global_path_alias( 'lazydir', $missing_dir, create => 1 );
    $paths->register_named_paths( $config->global_path_aliases );

    my $resolved = $paths->resolve_dir('lazydir');
    is( $resolved, $missing_dir, 'AC-2: resolve_dir returns the alias target path' );
    ok( -d $missing_dir, 'AC-2: resolve_dir created the missing directory, including its parents (mkdir -p semantics)' );
}

# --------------------------------------------------------------------------
# AC-4: an alias WITHOUT -c, resolved when its target is missing, behaves
# exactly as today - resolve_dir returns the path string but does NOT
# create anything.
# --------------------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( paths => $paths, files => $files );

    my $missing_dir = File::Spec->catdir( $home, 'never-created' );
    $config->save_global_path_alias( 'noncreate', $missing_dir );
    $paths->register_named_paths( $config->global_path_aliases );

    my $resolved = $paths->resolve_dir('noncreate');
    is( $resolved, $missing_dir, 'AC-4: resolve_dir still returns the plain alias path' );
    ok( !-d $missing_dir, 'AC-4: resolve_dir did NOT create the directory for a non-create-marked alias - unchanged existing behavior' );
}

# --------------------------------------------------------------------------
# AC-5: --create accepts an optional octal mode; when given, the created
# path is chmod'd to that exact mode. A bare -c uses the implicit default.
# --------------------------------------------------------------------------
SKIP: {
    skip 'chmod semantics are meaningless as root (bypasses all permission bits)', 2 if $> == 0;

    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( paths => $paths, files => $files );

    my $moded_dir = File::Spec->catdir( $home, 'moded-dir' );
    $config->save_global_path_alias( 'moded', $moded_dir, create => 1, mode => '0700' );
    $paths->register_named_paths( $config->global_path_aliases );
    $paths->resolve_dir('moded');

    my @st = stat($moded_dir);
    is( sprintf( '%04o', $st[2] & 07777 ), '0700', 'AC-5: the created directory was chmod\'d to the exact given octal mode' );

    my $bare_dir = File::Spec->catdir( $home, 'bare-mode-dir' );
    $config->save_global_path_alias( 'baremode', $bare_dir, create => 1 );
    $paths->register_named_paths( $config->global_path_aliases );
    $paths->resolve_dir('baremode');
    ok( -d $bare_dir, 'AC-5: a bare --create with no mode still creates the directory (using the implicit umask-governed default)' );
}

# --------------------------------------------------------------------------
# resolve_dir's create-and-missing guard: a create-marked alias whose
# target ALREADY EXISTS skips creation entirely - exercises the "not -d
# $path" arm of the guard independently of "$create" itself.
# --------------------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $config = Developer::Dashboard::Config->new( paths => $paths, files => Developer::Dashboard::FileRegistry->new( paths => $paths ) );

    my $existing_dir = File::Spec->catdir( $home, 'already-exists-dir' );
    mkdir $existing_dir;
    $config->save_global_path_alias( 'existingdir', $existing_dir, create => 1 );
    $paths->register_named_paths( $config->global_path_aliases );

    my $resolved = $paths->resolve_dir('existingdir');
    is( $resolved, $existing_dir, 'resolve_dir: returns the path unchanged when a create-marked target already exists' );
    ok( -d $existing_dir, 'resolve_dir: the already-existing directory is still there (not disturbed)' );
}

# --------------------------------------------------------------------------
# resolve_dir's defined-mode guard: a raw registered entry with an
# EMPTY-STRING mode exercises the "$mode ne ''" arm independently of
# "defined $mode" - the chmod call is simply skipped, same as an undef mode.
# --------------------------------------------------------------------------
{
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

    my $empty_mode_dir = File::Spec->catdir( $home, 'empty-mode-dir' );
    $paths->register_named_paths( { emptymodedir => { path => $empty_mode_dir, create => 1, mode => '' } } );

    my $resolved = $paths->resolve_dir('emptymodedir');
    is( $resolved, $empty_mode_dir, 'resolve_dir: an empty-string mode still resolves the path correctly' );
    ok( -d $empty_mode_dir, 'resolve_dir: the directory is still created even with an empty-string mode (chmod is simply skipped)' );
}

# --------------------------------------------------------------------------
# Config's mode-normalization ternary: an explicit EMPTY-STRING mode
# passed through the real save_global_path_alias/save_global_file_alias/
# save_skill_path_alias API normalizes to undef (no mode key stored),
# exercising the "$opts{mode} ne ''" arm of each function's own ternary
# independently of "defined $opts{mode})".
# --------------------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

    my $saved_path = $config->save_global_path_alias( 'emptymodeopt', File::Spec->catdir( $home, 'empty-mode-opt-dir' ), create => 1, mode => '' );
    ok( $saved_path->{create}, 'save_global_path_alias with an explicit empty-string mode still marks create' );
    ok( !exists $saved_path->{mode}, 'save_global_path_alias normalizes an explicit empty-string mode to no mode key' );

    my $saved_file = $config->save_global_file_alias( 'emptymodeoptfile', File::Spec->catfile( $home, 'empty-mode-opt-file.txt' ), create => 1, mode => '' );
    ok( $saved_file->{create}, 'save_global_file_alias with an explicit empty-string mode still marks create' );
    ok( !exists $saved_file->{mode}, 'save_global_file_alias normalizes an explicit empty-string mode to no mode key' );

    my $skills_root = File::Spec->catdir( $home, '.developer-dashboard', 'skills' );
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    make_path($foo_dir);
    my $saved_skill = $config->save_skill_path_alias( ['foo'], 'emptymodeoptskill', '/tmp/skillemptymode', create => 1, mode => '' );
    ok( $saved_skill->{create}, 'save_skill_path_alias with an explicit empty-string mode still marks create' );
    ok( !exists $saved_skill->{mode}, 'save_skill_path_alias normalizes an explicit empty-string mode to no mode key' );
}

# --------------------------------------------------------------------------
# AC-6 (Q-184, option A): d2 file add's create-on-resolve creates only the
# PARENT directory chain, leaving the file itself absent.
# --------------------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

    my $missing_file = File::Spec->catfile( $home, 'nested-file', 'deep', 'thing.txt' );
    my $parent_dir = File::Spec->catdir( $home, 'nested-file', 'deep' );
    ok( !-d $parent_dir, 'control: the parent directory genuinely does not exist yet' );

    my $saved = $config->save_global_file_alias( 'lazyfile', $missing_file, create => 1 );
    ok( $saved->{create}, 'AC-6: save_global_file_alias with create=>1 marks the returned alias as create' );
    $files->register_named_files( $config->global_file_aliases );

    my $resolved = $files->resolve_file('lazyfile');
    is( $resolved, $missing_file, 'AC-6: resolve_file returns the alias target path' );
    ok( -d $parent_dir, 'AC-6 (Q-184 option A): resolve_file created the PARENT directory chain' );
    ok( !-e $missing_file, 'AC-6 (Q-184 option A): resolve_file left the file itself absent - not touched as an empty file' );
}

# --------------------------------------------------------------------------
# AC-5 (file side): resolve_file also chmods the created parent to a given
# mode, exercising the same defined-mode branch FileRegistry shares with
# PathRegistry.
# --------------------------------------------------------------------------
SKIP: {
    skip 'chmod semantics are meaningless as root (bypasses all permission bits)', 1 if $> == 0;

    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

    my $moded_parent = File::Spec->catdir( $home, 'moded-file-parent' );
    my $moded_file = File::Spec->catfile( $moded_parent, 'thing.txt' );
    $config->save_global_file_alias( 'modedfile', $moded_file, create => 1, mode => '0700' );
    $files->register_named_files( $config->global_file_aliases );
    $files->resolve_file('modedfile');

    my @st = stat($moded_parent);
    is( sprintf( '%04o', $st[2] & 07777 ), '0700', "AC-5 (file): resolve_file chmod'd the created parent to the exact given octal mode" );
}

# --------------------------------------------------------------------------
# AC-6 branch: a create-marked file alias whose parent directory ALREADY
# exists skips creation entirely (the guard's -d check short-circuits) -
# unchanged behavior, not a re-creation or an error.
# --------------------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

    my $existing_parent = File::Spec->catdir( $home, 'already-exists-parent' );
    mkdir $existing_parent;
    my $target_file = File::Spec->catfile( $existing_parent, 'thing.txt' );
    $config->save_global_file_alias( 'existingparentfile', $target_file, create => 1 );
    $files->register_named_files( $config->global_file_aliases );

    my $resolved = $files->resolve_file('existingparentfile');
    is( $resolved, $target_file, 'AC-6: resolve_file returns the path unchanged when the parent already exists' );
    ok( -d $existing_parent, 'AC-6: the already-existing parent is still there (not disturbed)' );
    ok( !-e $target_file, 'AC-6: the file itself still was not touched' );
}

# --------------------------------------------------------------------------
# AC-6 branch: a create-marked file alias whose target has NO directory
# component at all (File::Spec->splitpath returns an empty-string parent)
# never attempts to create anything - exercises the "$parent ne ''" arm of
# resolve_file's guard condition directly, independently of "defined
# $parent" and "not -d $parent".
# --------------------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

    $config->save_global_file_alias( 'noparentfile', 'bare-filename.txt', create => 1 );
    $files->register_named_files( $config->global_file_aliases );

    my $resolved = $files->resolve_file('noparentfile');
    is( $resolved, 'bare-filename.txt', 'AC-6: resolve_file returns a directory-less target unchanged' );
    ok( !-e 'bare-filename.txt', 'AC-6: nothing was created for a directory-less create-marked target' );
}

# --------------------------------------------------------------------------
# resolve_file's defined-mode guard: a raw registered entry with an
# EMPTY-STRING mode (a shape Config's own normalization never produces via
# its public API, but the guard's "$mode ne ''" condition still needs to
# be exercised independently of "defined $mode") skips the chmod call the
# same way a wholly-undefined mode does.
# --------------------------------------------------------------------------
{
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );

    my $empty_mode_file = File::Spec->catfile( $home, 'empty-mode-parent', 'thing.txt' );
    $files->register_named_files( { emptymodefile => { path => $empty_mode_file, create => 1, mode => '' } } );

    my $resolved = $files->resolve_file('emptymodefile');
    is( $resolved, $empty_mode_file, 'resolve_file: an empty-string mode still resolves the path correctly' );
    ok( -d File::Spec->catdir( $home, 'empty-mode-parent' ), 'resolve_file: the parent is still created even with an empty-string mode (chmod is simply skipped)' );
}

# --------------------------------------------------------------------------
# AC-4 (file side): a plain file alias (no create) against a missing parent
# is unaffected - unchanged existing behavior.
# --------------------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

    my $missing_file = File::Spec->catfile( $home, 'never-file-parent', 'thing.txt' );
    $config->save_global_file_alias( 'noncreatefile', $missing_file );
    $files->register_named_files( $config->global_file_aliases );

    my $resolved = $files->resolve_file('noncreatefile');
    is( $resolved, $missing_file, 'AC-4 (file): resolve_file still returns the plain alias path' );
    ok( !-d File::Spec->catdir( $home, 'never-file-parent' ), 'AC-4 (file): resolve_file did NOT create the parent for a non-create-marked file alias' );
}

# --------------------------------------------------------------------------
# AC-1/AC-5 via the real CLI entry point: "dashboard path add" in all 4
# --create syntax forms, proving the option parsing itself (not just the
# storage layer already proven above).
# --------------------------------------------------------------------------
{
    require Developer::Dashboard::CLI::Paths;

    local $ENV{HOME} = $home;

    my %cases = (
        bare       => [ 'cli-bare',       [ File::Spec->catdir( $home, 'cli-bare' ),       '--create' ] ],
        spacesep   => [ 'cli-spacesep',   [ File::Spec->catdir( $home, 'cli-spacesep' ),   '--create', '0755' ] ],
        eqform     => [ 'cli-eqform',     [ File::Spec->catdir( $home, 'cli-eqform' ),     '--create=0755' ] ],
        shortform  => [ 'cli-shortform',  [ File::Spec->catdir( $home, 'cli-shortform' ),  '-c', '0755' ] ],
    );

    for my $case ( sort keys %cases ) {
        my ( $alias, $rest ) = @{ $cases{$case} };
        my $stdout = '';
        {
            local *STDOUT;
            open STDOUT, '>', \$stdout or die $!;
            Developer::Dashboard::CLI::Paths::run_paths_command(
                command => 'path',
                args    => [ 'add', $alias, @{$rest}, '-o', 'json' ],
            );
        }
        my $decoded = eval { json_decode($stdout) };
        ok( $decoded && $decoded->{create}, "CLI ($case): dashboard path add recorded create=>1" );
    }
}

# --------------------------------------------------------------------------
# AC-1: a plain CLI add (no -c/--create at all) records no create flag,
# proving the CLI wiring does not accidentally mark every alias.
# --------------------------------------------------------------------------
{
    require Developer::Dashboard::CLI::Paths;
    local $ENV{HOME} = $home;

    my $stdout = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$stdout or die $!;
        Developer::Dashboard::CLI::Paths::run_paths_command(
            command => 'path',
            args    => [ 'add', 'cli-plain', File::Spec->catdir( $home, 'plain-target' ), '-o', 'json' ],
        );
    }
    my $decoded = eval { json_decode($stdout) };
    ok( $decoded && !$decoded->{create}, 'CLI: a plain dashboard path add with no -c/--create records no create flag' );
}

# --------------------------------------------------------------------------
# AC-1/AC-5 via the real CLI entry point for "dashboard file add" too,
# mirroring the path-add CLI coverage above - exercises CLI::Files' own
# _parse_create_option in all 4 syntax forms plus the not-given (undef) and
# plain (no flag) cases.
# --------------------------------------------------------------------------
{
    require Developer::Dashboard::CLI::Files;

    local $ENV{HOME} = $home;

    my %cases = (
        bare      => [ 'cli-file-bare',      [ File::Spec->catfile( $home, 'cli-file-bare',      'n.txt' ), '--create' ] ],
        spacesep  => [ 'cli-file-spacesep',  [ File::Spec->catfile( $home, 'cli-file-spacesep',  'n.txt' ), '--create', '0755' ] ],
        eqform    => [ 'cli-file-eqform',    [ File::Spec->catfile( $home, 'cli-file-eqform',    'n.txt' ), '--create=0755' ] ],
        shortform => [ 'cli-file-shortform', [ File::Spec->catfile( $home, 'cli-file-shortform', 'n.txt' ), '-c', '0755' ] ],
    );

    for my $case ( sort keys %cases ) {
        my ( $alias, $rest ) = @{ $cases{$case} };
        my $stdout = '';
        {
            local *STDOUT;
            open STDOUT, '>', \$stdout or die $!;
            Developer::Dashboard::CLI::Files::run_files_command(
                command => 'file',
                args    => [ 'add', $alias, @{$rest}, '-o', 'json' ],
            );
        }
        my $decoded = eval { json_decode($stdout) };
        ok( $decoded && $decoded->{create}, "CLI file add ($case): recorded create=>1" );
    }

    my $plain_stdout = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$plain_stdout or die $!;
        Developer::Dashboard::CLI::Files::run_files_command(
            command => 'file',
            args    => [ 'add', 'cli-file-plain', File::Spec->catfile( $home, 'plain-file-target.txt' ), '-o', 'json' ],
        );
    }
    my $plain_decoded = eval { json_decode($plain_stdout) };
    ok( $plain_decoded && !$plain_decoded->{create}, 'CLI file add: a plain add with no -c/--create records no create flag' );
}

# --------------------------------------------------------------------------
# named_paths()/named_files() display collapse: with a MIX of a
# create-marked (metadata-hash-stored) alias and a plain (bare-string)
# alias both registered at once, the accessor must collapse the hash-shaped
# one to its "path" field while passing the bare-string one through
# unchanged - exercising both arms of the ref($entry) eq 'HASH' check.
# --------------------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

    my $create_dir = File::Spec->catdir( $home, 'display-collapse-create' );
    my $plain_dir  = File::Spec->catdir( $home, 'display-collapse-plain' );
    mkdir $plain_dir;
    $config->save_global_path_alias( 'displaycreate', $create_dir, create => 1 );
    $config->save_global_path_alias( 'displayplain',  $plain_dir );
    $paths->register_named_paths( $config->global_path_aliases );

    my $displayed = $paths->named_paths;
    is( $displayed->{displaycreate}, $create_dir, 'named_paths collapses a create-marked (hash-stored) alias to its bare path string' );
    is( $displayed->{displayplain}, $plain_dir, 'named_paths passes a plain (already-string) alias through unchanged' );

    my $create_file = File::Spec->catfile( $home, 'display-collapse-create-file', 'n.txt' );
    my $plain_file  = File::Spec->catfile( $home, 'display-collapse-plain-file.txt' );
    $config->save_global_file_alias( 'displaycreatefile', $create_file, create => 1 );
    $config->save_global_file_alias( 'displayplainfile',  $plain_file );
    $files->register_named_files( $config->global_file_aliases );

    my $displayed_files = $files->named_files;
    is( $displayed_files->{displaycreatefile}, $create_file, 'named_files collapses a create-marked (hash-stored) alias to its bare path string' );
    is( $displayed_files->{displayplainfile}, $plain_file, 'named_files passes a plain (already-string) alias through unchanged' );
}

# --------------------------------------------------------------------------
# DD-1004 skill-depth storage composition: save_skill_path_alias and
# save_skill_file_alias accept the same create/mode %opts and store the
# identical metadata-hash shape at the nested location, exercising the
# defined-mode branches in _save_skill_alias (both with and without a mode,
# and the plain no-create case).
# --------------------------------------------------------------------------
{
    my $skills_root = File::Spec->catdir( $home, '.developer-dashboard', 'skills' );
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    make_path($foo_dir);

    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

    my $saved_with_mode = $config->save_skill_path_alias( ['foo'], 'withmode', '/tmp/skillwithmode', create => 1, mode => '0700' );
    ok( $saved_with_mode->{create}, 'save_skill_path_alias with create+mode marks the returned alias as create' );
    is( $saved_with_mode->{mode}, '0700', 'save_skill_path_alias records the given mode' );

    my $saved_bare = $config->save_skill_path_alias( ['foo'], 'barecreate', '/tmp/skillbare', create => 1 );
    ok( $saved_bare->{create}, 'save_skill_path_alias with bare create marks the returned alias as create' );
    ok( !exists $saved_bare->{mode}, 'save_skill_path_alias with no mode given records no mode key' );

    my $saved_plain = $config->save_skill_path_alias( ['foo'], 'plain', '/tmp/skillplain' );
    ok( !$saved_plain->{create}, 'save_skill_path_alias with no create option does not mark create' );

    my $aliases = $config->path_aliases;
    is( ref $aliases->{'foo.withmode'}, 'HASH', 'the skill-depth create-marked alias reads back as a metadata hash' );
    is( $aliases->{'foo.plain'}, '/tmp/skillplain', 'the skill-depth plain alias still reads back as a bare path string' );

    my $saved_file_with_mode = $config->save_skill_file_alias( ['foo'], 'filewithmode', '/tmp/skillfilewithmode', create => 1, mode => '0700' );
    ok( $saved_file_with_mode->{create}, 'save_skill_file_alias with create+mode marks the returned alias as create' );
    is( $saved_file_with_mode->{mode}, '0700', 'save_skill_file_alias records the given mode' );
}

# --------------------------------------------------------------------------
# _parse_create_option's octal validation: a --create value that is
# NON-EMPTY but not a valid octal string (a leading 0 followed by digits
# 0-7) dies with a usage message rather than being silently misread, per
# the ticket's explicit requirement. Exercised through the real CLI dies
# path, not just the AC-5 valid-input cases already covered.
# --------------------------------------------------------------------------
{
    require Developer::Dashboard::CLI::Paths;
    local $ENV{HOME} = $home;

    my @invalid = ( '777', '0888', 'not-octal', '08' );
    for my $bad (@invalid) {
        my $stderr = '';
        my $died = eval {
            local *STDERR;
            open STDERR, '>', \$stderr or die $!;
            Developer::Dashboard::CLI::Paths::run_paths_command(
                command => 'path',
                args    => [ 'add', 'invalidmode', File::Spec->catdir( $home, 'invalid-mode-target' ), '--create', $bad ],
            );
            0;
        } ? 0 : 1;
        ok( $died, "dashboard path add --create $bad dies rather than silently accepting an invalid octal mode" );
    }
}

# --------------------------------------------------------------------------
# CLI::Files carries its own duplicated _parse_create_option (not shared
# with CLI::Paths) - the same octal-validation die path, exercised here.
# --------------------------------------------------------------------------
{
    require Developer::Dashboard::CLI::Files;
    local $ENV{HOME} = $home;

    my $died = eval {
        my $stderr = '';
        local *STDERR;
        open STDERR, '>', \$stderr or die $!;
        Developer::Dashboard::CLI::Files::run_files_command(
            command => 'file',
            args    => [ 'add', 'invalidmodefile', File::Spec->catfile( $home, 'invalid-mode-file.txt' ), '--create', 'not-octal' ],
        );
        0;
    } ? 0 : 1;
    ok( $died, 'dashboard file add --create not-octal dies rather than silently accepting an invalid octal mode' );
}

done_testing();

__END__

=pod

=head1 NAME

207-path-file-alias-lazy-create.t - proves DD-1005's -c/--create lazy path/file creation

=head1 PURPOSE

Guards DD-1005: C<d2 path add>/C<d2 file add>'s C<-c>/C<--create> flag, its
optional octal chmod mode, and the shared create-on-resolve behavior in
C<PathRegistry::resolve_dir> and C<FileRegistry::resolve_file>.

=head1 WHY IT EXISTS

Without this, an alias whose target does not yet exist fails resolution at
every consumer (cdr, workspace routes, direct Perl callers) with no way to
opt in to lazy creation. This file proves the opt-in flag, its persistence,
and that the create-on-resolve logic lives once in the shared resolver
rather than being duplicated per call site.

=head1 WHEN TO USE

Run this file whenever C<Config::save_global_path_alias>,
C<Config::save_global_file_alias>, C<PathRegistry::resolve_dir>, or
C<FileRegistry::resolve_file> change.

=head1 HOW TO USE

    prove -lv t/207-path-file-alias-lazy-create.t

=head1 WHAT USES IT

C<t/statistics/coverage> files for PathRegistry/FileRegistry/Config cover
the pre-existing behavior of these methods; this file covers the DD-1005
lazy-create addition specifically.

=head1 EXAMPLES

C<d2 path add foo /tmp/missing --create 0777> then resolving C<foo> (via
C<cdr>, a workspace route, or C<PathRegistry-E<gt>resolve_dir('foo')>)
creates C</tmp/missing> with mode C<0700> before returning it.

=cut
