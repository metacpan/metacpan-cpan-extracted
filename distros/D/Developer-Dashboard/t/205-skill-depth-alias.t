#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Config;
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::CLI::Paths ();
use Developer::Dashboard::CLI::Files ();

# Warnings are fatal in this repository: collect any that escape and assert
# the whole run stayed clean.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; return; };

# Hermetic runtime rooted at a temp home (DD-1004). Skill config discovery
# resolves from the deepest .developer-dashboard layer above the cwd, so
# chdir into the temp home before building any registry.
my $home = abs_path( tempdir( CLEANUP => 1 ) );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $skills_root = File::Spec->catdir( $home, '.developer-dashboard', 'skills' );

# dies { CODE }
# Runs a code block and returns the exception text, or the empty string when
# it did not die - a tiny block-form helper so call sites read as
# `like( dies { ... }, qr/.../, ... )`.
sub dies (&) {
    my ($code) = @_;
    return eval { $code->(); 1 } ? '' : $@;
}

sub fresh_registries {
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    return ( $paths, $config );
}

sub read_json {
    my ($file) = @_;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    return json_decode(<$fh>);
}

sub run_path {
    my (@args) = @_;
    my ( $out, $err, @rest ) = capture {
        Developer::Dashboard::CLI::Paths::run_paths_command( command => 'path', args => [@args] );
    };
    return ( $out, $err );
}

sub run_file {
    my (@args) = @_;
    my ( $out, $err, @rest ) = capture {
        Developer::Dashboard::CLI::Files::run_files_command( command => 'file', args => [@args] );
    };
    return ( $out, $err );
}

# -------------------------------------------------------------------------
# split_skill_alias_name
# -------------------------------------------------------------------------
subtest 'split_skill_alias_name parses dotted alias names' => sub {
    my ( undef, $config ) = fresh_registries();

    is_deeply( [ $config->split_skill_alias_name('plain') ], [], 'an undotted name is not a skill-prefixed alias' );
    is_deeply( [ $config->split_skill_alias_name(undef) ],   [], 'an undef name is not a skill-prefixed alias' );

    is_deeply(
        [ $config->split_skill_alias_name('foo.something') ],
        [ ['foo'], 'something' ],
        'a single-dot name splits into a depth-1 skill segment and the alias',
    );
    is_deeply(
        [ $config->split_skill_alias_name('foo.bar.something') ],
        [ [ 'foo', 'bar' ], 'something' ],
        'a two-dot name splits into two skill segments and the alias',
    );
    is_deeply(
        [ $config->split_skill_alias_name('foo..something') ],
        [],
        'an empty interior segment is refused rather than silently dropped',
    );
    is_deeply( [ $config->split_skill_alias_name('foo.') ], [], 'a trailing dot with no alias name is refused' );
    is_deeply( [ $config->split_skill_alias_name('.foo') ], [], 'a leading dot with no skill segment is refused' );
};

# -------------------------------------------------------------------------
# nested_skill_dir_chain / skill_config_write_location (PathRegistry)
# -------------------------------------------------------------------------
subtest 'nested_skill_dir_chain resolves arbitrarily deep skill-in-skill nesting' => sub {
    my ($paths) = fresh_registries();

    is_deeply( [ $paths->nested_skill_dir_chain( [] ) ], [], 'an empty segment list resolves to nothing' );
    is_deeply( [ $paths->nested_skill_dir_chain(undef) ], [], 'a non-array argument resolves to nothing' );
    is_deeply( [ $paths->nested_skill_dir_chain( ['nosuchskill'] ) ], [], 'an uninstalled top-level skill resolves to nothing' );

    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    make_path($foo_dir);
    is_deeply( [ $paths->nested_skill_dir_chain( [ 'foo', 'bar' ] ) ], [],
        'a nested segment with no matching skills/ subdirectory resolves to nothing' );

    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    make_path($bar_dir);
    is_deeply(
        [ $paths->nested_skill_dir_chain( ['foo'] ) ],
        [$foo_dir],
        'a depth-1 chain resolves to the skill directory itself',
    );
    is_deeply(
        [ $paths->nested_skill_dir_chain( [ 'foo', 'bar' ] ) ],
        [ $foo_dir, $bar_dir ],
        'a depth-2 chain resolves through the nested skills/ subdirectory',
    );

    my $baz_dir = File::Spec->catdir( $bar_dir, 'skills', 'baz' );
    make_path($baz_dir);
    is_deeply(
        [ $paths->nested_skill_dir_chain( [ 'foo', 'bar', 'baz' ] ) ],
        [ $foo_dir, $bar_dir, $baz_dir ],
        'a depth-3 chain recurses arbitrarily deep',
    );

    remove_tree_quiet($skills_root);
};

subtest 'skill_config_write_location walks up past a .git-managed skill directory' => sub {
    my ($paths) = fresh_registries();

    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    make_path($bar_dir);

    # Case A: bar carries its own .git, foo does not - stop at foo.
    make_path( File::Spec->catdir( $bar_dir, '.git' ) );
    my $location_a = $paths->skill_config_write_location( [ 'foo', 'bar' ] );
    is( $location_a->{kind}, 'skill',    'Case A stops at a skill directory, not the global fallback' );
    is( $location_a->{dir},  $foo_dir,   'Case A walks up past the git-managed bar to the git-free foo' );
    is_deeply( $location_a->{remaining}, ['bar'], 'Case A leaves "bar" as the nesting still owed below foo' );

    # Case B: foo carries its own .git too - fall through to the global config.
    make_path( File::Spec->catdir( $foo_dir, '.git' ) );
    my $location_b = $paths->skill_config_write_location( [ 'foo', 'bar' ] );
    is( $location_b->{kind}, 'global', 'Case B falls all the way through to the global config' );
    is_deeply( $location_b->{remaining}, [ 'foo', 'bar' ], 'Case B keeps the full depth path for the global fallback' );

    remove_tree_quiet($skills_root);
};

subtest 'nested_skill_entries respects a nested skill\'s own .disabled marker' => sub {
    my ($paths) = fresh_registries();

    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    make_path($bar_dir);
    open my $fh, '>:raw', File::Spec->catfile( $bar_dir, '.disabled' ) or die $!;
    close $fh;

    my @default_segments = map { join( '.', @{ $_->{segments} } ) } $paths->nested_skill_entries;
    ok( ( grep { $_ eq 'foo' } @default_segments ),      'the enabled parent (foo) is still discovered by default' );
    ok( !( grep { $_ eq 'foo.bar' } @default_segments ), 'a disabled nested skill (bar) is excluded by default' );

    my @all_segments = map { join( '.', @{ $_->{segments} } ) } $paths->nested_skill_entries( include_disabled => 1 );
    ok( ( grep { $_ eq 'foo.bar' } @all_segments ), 'include_disabled => 1 still discovers the disabled nested skill' );

    remove_tree_quiet($skills_root);
};

subtest 'skill_config_write_location NEVER targets the skill itself, even with no .git anywhere (Q-182)' => sub {
    my ($paths) = fresh_registries();

    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    make_path($bar_dir);

    # Depth-2, no .git anywhere: the write must still skip bar (the target)
    # unconditionally and land at its parent, foo - never inside bar itself.
    my $location = $paths->skill_config_write_location( [ 'foo', 'bar' ] );
    is( $location->{kind}, 'skill',  'a depth-2 target with no .git anywhere still resolves to a skill ancestor, not global' );
    is( $location->{dir},  $foo_dir, 'the write location is the PARENT (foo), never the target itself (bar), regardless of .git' );
    is_deeply( $location->{remaining}, ['bar'], 'remaining still names "bar" as the nesting owed below the parent' );

    # Depth-1, no .git anywhere: foo has no parent skill at all, so it falls
    # straight through to the global fallback unconditionally.
    my $location1 = $paths->skill_config_write_location( ['foo'] );
    is( $location1->{kind}, 'global', 'a depth-1 target with no .git and no parent skill still falls to the global fallback (Q-182)' );
    is_deeply( $location1->{remaining}, ['foo'], 'remaining keeps the full (single-segment) depth path for the global fallback' );

    remove_tree_quiet($skills_root);
};

subtest 'skill_config_write_location resolves undef for an unresolved skill chain' => sub {
    my ($paths) = fresh_registries();
    is( $paths->skill_config_write_location( [] ),               undef, 'an empty segment list resolves to undef' );
    is( $paths->skill_config_write_location( ['nosuchskillxyz'] ), undef, 'an uninstalled skill resolves to undef' );
};

# -------------------------------------------------------------------------
# Full round trip: d2 path add foo.bar.something /foobar (Case A - foo has
# no .git, so the alias physically lands in skills/foo/config/config.json as
# a nested structure keyed by the remaining depth segment).
# -------------------------------------------------------------------------
subtest 'd2 path add writes a nested alias into the git-free ancestor skill config (Case A)' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    make_path($bar_dir);
    # bar is its own git-managed skill repo; foo is not.
    make_path( File::Spec->catdir( $bar_dir, '.git' ) );

    my ( $out, $err ) = run_path( 'add', 'foo.bar.something', '/foobar', '-o', 'json' );
    is( $err, '', 'path add writes nothing to STDERR' );
    my $saved = json_decode($out);
    is( $saved->{name},     'foo.bar.something', 'the reported alias name stays the full dotted form' );
    is( $saved->{path},     '/foobar',           'the reported alias path is the target directory' );
    is( $saved->{resolved}, '/foobar',           'the alias resolves to the target directory immediately' );

    my $config_file = File::Spec->catfile( $foo_dir, 'config', 'config.json' );
    ok( -f $config_file, 'the alias physically landed in the git-free ancestor (foo), not inside bar' );
    my $stored = read_json($config_file);
    is_deeply(
        $stored,
        { bar => { path_aliases => { something => '/foobar' } } },
        'the alias is stored as a NESTED hash mirroring the remaining depth segment, never a flattened dotted key',
    );

    my $bar_config_file = File::Spec->catfile( $bar_dir, 'config', 'config.json' );
    ok( !-f $bar_config_file, 'nothing was ever written inside the git-managed bar directory itself' );

    # Round trip: d2 path list / cdr must read the alias straight back out.
    my ( $paths, $config ) = fresh_registries();
    my $aliases = $config->path_aliases;
    is( $aliases->{'foo.bar.something'}, '/foobar', 'path_aliases() surfaces the nested alias under its full dotted name' );

    $paths->register_named_paths($aliases);
    is( $paths->resolve_dir('foo.bar.something'), '/foobar', 'cdr/resolve_dir resolves the nested alias to its target' );

    my ( $list_out, $list_err ) = run_path( 'list', '-o', 'json' );
    is( $list_err, '', 'path list writes nothing to STDERR' );
    my $listed = json_decode($list_out);
    is( $listed->{'foo.bar.something'}, '/foobar', 'dashboard path list shows the nested alias in its full JSON payload' );

    remove_tree_quiet($skills_root);
};

# -------------------------------------------------------------------------
# Full round trip: both foo and bar carry their own .git (Case B - global
# config fallback, nested under the owner-confirmed "skills" top-level key).
# -------------------------------------------------------------------------
subtest 'd2 path add falls through to the global config when every skill ancestor has .git (Case B)' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    make_path($bar_dir);
    make_path( File::Spec->catdir( $foo_dir, '.git' ) );
    make_path( File::Spec->catdir( $bar_dir, '.git' ) );

    my ( $out, $err ) = run_path( 'add', 'foo.bar.something', '/foobar', '-o', 'json' );
    is( $err, '', 'path add writes nothing to STDERR' );
    my $saved = json_decode($out);
    is( $saved->{name}, 'foo.bar.something', 'the reported alias name stays the full dotted form' );
    is( $saved->{path}, '/foobar',           'the reported alias path is the target directory' );

    my ( undef, $config ) = fresh_registries();
    my $global_file = $config->_global_config_file;
    ok( -f $global_file, 'the global config file exists after the Case B fallback write' );
    my $global_stored = read_json($global_file);
    is_deeply(
        $global_stored,
        { skills => { foo => { bar => { path_aliases => { something => '/foobar' } } } } },
        'Case B stores the FULL depth path as nested keys under the owner-confirmed "skills" top-level key (Q-181)',
    );

    ok( !-f File::Spec->catfile( $foo_dir, 'config', 'config.json' ), 'nothing was written inside the git-managed foo directory' );
    ok( !-f File::Spec->catfile( $bar_dir, 'config', 'config.json' ), 'nothing was written inside the git-managed bar directory' );

    # Round trip through the read side.
    my $aliases = $config->path_aliases;
    is( $aliases->{'foo.bar.something'}, '/foobar', 'path_aliases() surfaces the Case B alias under its full dotted name' );

    remove_tree_quiet($skills_root);
    unlink $global_file if -e $global_file;
};

# -------------------------------------------------------------------------
# An undotted name is completely unaffected (regression guard).
# -------------------------------------------------------------------------
subtest 'an undotted alias name keeps the exact existing global-config behavior' => sub {
    my ( $out, $err ) = run_path( 'add', 'plainalias', '/plain-target', '-o', 'json' );
    is( $err, '', 'path add writes nothing to STDERR for a plain name' );
    my $saved = json_decode($out);
    is( $saved->{name}, 'plainalias',    'the plain alias name is unqualified' );
    is( $saved->{path}, '/plain-target', 'the plain alias path is the target directory' );

    my ( undef, $config ) = fresh_registries();
    my $global_file = $config->_global_config_file;
    my $global_stored = read_json($global_file);
    is_deeply(
        $global_stored->{path_aliases},
        { plainalias => '/plain-target' },
        'an undotted alias name still writes flat into the top-level global path_aliases key, unaffected',
    );
    ok( !exists $global_stored->{skills}, 'an undotted alias write never touches the skills fallback section' );

    my ( $del_out, $del_err ) = run_path( 'del', 'plainalias', '-o', 'json' );
    is( $del_err, '', 'path del writes nothing to STDERR' );
    my $deleted = json_decode($del_out);
    is( $deleted->{removed}, 1, 'the plain alias was removed via the same dispatch path' );

    unlink $global_file if -e $global_file;
};

# -------------------------------------------------------------------------
# d2 path del symmetry for a dotted skill-depth alias.
# -------------------------------------------------------------------------
subtest 'd2 path del removes a nested skill-depth alias from wherever it was written' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    make_path($bar_dir);
    make_path( File::Spec->catdir( $bar_dir, '.git' ) );

    run_path( 'add', 'foo.bar.something', '/foobar', '-o', 'json' );
    my $config_file = File::Spec->catfile( $foo_dir, 'config', 'config.json' );
    ok( -f $config_file, 'sanity: the alias landed in the git-free ancestor before deletion' );

    my ( $del_out, $del_err ) = run_path( 'del', 'foo.bar.something', '-o', 'json' );
    is( $del_err, '', 'path del writes nothing to STDERR' );
    my $deleted = json_decode($del_out);
    is( $deleted->{name},    'foo.bar.something', 'the removal report names the full dotted alias' );
    is( $deleted->{removed}, 1,                   'the nested alias was actually removed' );

    my $stored = read_json($config_file);
    is_deeply( $stored, { bar => { path_aliases => {} } }, 'the leaf entry is gone but the surrounding nested structure is preserved' );

    my ( undef, $config ) = fresh_registries();
    ok( !exists $config->path_aliases->{'foo.bar.something'}, 'the alias no longer surfaces on read after deletion' );

    my ( $redel_out, $redel_err ) = run_path( 'del', 'foo.bar.something', '-o', 'json' );
    is( $redel_err, '', 'deleting an already-absent nested alias writes nothing to STDERR' );
    my $redeleted = json_decode($redel_out);
    is( $redeleted->{removed}, 0, 'deleting an already-absent nested alias is idempotent, not an error' );

    remove_tree_quiet($skills_root);
};

# -------------------------------------------------------------------------
# d2 file add / del mirror the same dotted-name support.
# -------------------------------------------------------------------------
subtest 'd2 file add/del support the identical skill-depth-prefixed shape (depth-1 always lands in the global fallback, Q-182)' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    make_path($foo_dir);

    my ( $out, $err ) = run_file( 'add', 'foo.something', '/foobar.txt', '-o', 'json' );
    is( $err, '', 'file add writes nothing to STDERR' );
    my $saved = json_decode($out);
    is( $saved->{name}, 'foo.something', 'the reported file alias name stays the full dotted form' );
    is( $saved->{path}, '/foobar.txt',   'the reported file alias path is the target file' );

    my $config_file = File::Spec->catfile( $foo_dir, 'config', 'config.json' );
    ok( !-f $config_file, 'a depth-1 alias NEVER lands inside the skill\'s own directory (Q-182), even with no .git anywhere' );

    my ( undef, $config ) = fresh_registries();
    my $global_file    = $config->_global_config_file;
    my $global_stored   = read_json($global_file);
    is_deeply(
        $global_stored,
        { skills => { foo => { file_aliases => { something => '/foobar.txt' } } } },
        'a depth-1 file alias is stored nested under the global "skills" fallback section, never flattened, never inside the skill',
    );

    is( $config->file_aliases->{'foo.something'}, '/foobar.txt', 'file_aliases() surfaces the alias under its full dotted name' );

    my ( $del_out, $del_err ) = run_file( 'del', 'foo.something', '-o', 'json' );
    is( $del_err, '', 'file del writes nothing to STDERR' );
    my $deleted = json_decode($del_out);
    is( $deleted->{removed}, 1, 'the file alias was removed' );

    unlink $global_file if -e $global_file;
    remove_tree_quiet($skills_root);
};

# -------------------------------------------------------------------------
# Q-182: a user's override always shadows a skill's own SHIPPED default at
# read time, and the skill's own file is never touched by the write that
# creates the override.
# -------------------------------------------------------------------------
subtest 'a user override shadows a skill-shipped default without ever touching the skill\'s own file' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    make_path($bar_dir);

    # bar SHIPS its own default for "something" - hand-authored by the skill,
    # exactly the DD-977/978 scenario, no .git anywhere.
    my $bar_config_dir  = File::Spec->catdir( $bar_dir, 'config' );
    make_path($bar_config_dir);
    my $bar_config_file = File::Spec->catfile( $bar_config_dir, 'config.json' );
    open my $fh, '>:raw', $bar_config_file or die $!;
    print {$fh} json_encode( { path_aliases => { something => '/shipped/default' } } );
    close $fh;
    my $bar_config_before = read_json($bar_config_file);

    my ( undef, $config_before ) = fresh_registries();
    is( $config_before->path_aliases->{'foo.bar.something'}, '/shipped/default',
        'before any override, the shipped default alone is visible under its qualified name' );

    my ( $out, $err ) = run_path( 'add', 'foo.bar.something', '/my/override', '-o', 'json' );
    is( $err, '', 'path add writes nothing to STDERR' );
    my $saved = json_decode($out);
    is( $saved->{path}, '/my/override', 'the override is reported back as saved' );

    is_deeply( read_json($bar_config_file), $bar_config_before,
        'bar\'s own shipped config.json is BYTE-FOR-BYTE UNCHANGED by the override write' );

    my ( undef, $config_after ) = fresh_registries();
    is( $config_after->path_aliases->{'foo.bar.something'}, '/my/override',
        'after the override, the user\'s value SHADOWS the skill\'s shipped default at read time' );

    my $foo_config_file = File::Spec->catfile( $foo_dir, 'config', 'config.json' );
    ok( -f $foo_config_file, 'the override physically landed in the parent (foo), not in bar' );

    remove_tree_quiet($skills_root);
};

# -------------------------------------------------------------------------
# Coverage gate: every defensive branch the new resolver/read/write code
# added must be genuinely exercised, not merely reachable in theory.
# -------------------------------------------------------------------------
subtest 'PathRegistry: nested_skill_dir_chain and skill_config_write_location argument guards' => sub {
    my ($paths) = fresh_registries();

    is_deeply( [ $paths->nested_skill_dir_chain( ['a/b'] ) ], [], 'an invalid (non-single) segment fails validated_path_segments and resolves to nothing' );

    is( $paths->skill_config_write_location('not-an-arrayref'), undef, 'a non-arrayref argument resolves to undef, not just an empty arrayref' );

    remove_tree_quiet($skills_root);
};

subtest 'Config: a discovered nested directory whose name itself fails segment validation is skipped, not fatal' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    # A directory name containing a backslash is a valid filename on Linux
    # but fails validated_path_segments (DD-1004's write-side safety check),
    # so nested_skill_entries discovers it as a real directory while
    # skill_config_write_location can never resolve it - the "or next" guard
    # in _nested_skill_alias_entries' pass 2 loop.
    my $weird_dir = File::Spec->catdir( $foo_dir, 'skills', 'weird\\name' );
    make_path($weird_dir);

    my ( undef, $config ) = fresh_registries();
    is( eval { $config->path_aliases; 1 }, 1, 'a nested skill directory with an unvalidatable name does not blow up path_aliases()' );

    my ($paths) = fresh_registries();
    my @found = grep { join( '.', @{ $_->{segments} } ) eq 'foo.weird\\name' } $paths->nested_skill_entries;
    ok( @found, 'nested_skill_entries still discovers the oddly-named directory on disk' );
    is( $paths->skill_config_write_location( $found[0]->{segments} ), undef,
        'skill_config_write_location cannot resolve it (its own segment fails validation), matching the "or next" it drives' );

    remove_tree_quiet($skills_root);
};

subtest 'Config: save_skill_path_alias/_remove_skill_alias direct argument and resolution guards' => sub {
    my ( undef, $config ) = fresh_registries();

    like( dies { $config->save_skill_path_alias( undef, 'x', '/y' ) },        qr/Missing skill-depth segments/, 'save_skill_path_alias rejects a non-arrayref segments argument' );
    like( dies { $config->save_skill_path_alias( [], 'x', '/y' ) },           qr/Missing skill-depth segments/, 'save_skill_path_alias rejects an empty segments arrayref' );
    like( dies { $config->save_skill_path_alias( ['foo'], undef, '/y' ) },    qr/Missing alias name/,           'save_skill_path_alias rejects an undef alias name' );
    like( dies { $config->save_skill_path_alias( ['foo'], '', '/y' ) },       qr/Missing alias name/,           'save_skill_path_alias rejects an empty alias name' );
    like( dies { $config->save_skill_path_alias( ['foo'], 'x', undef ) },     qr/Missing alias target/,         'save_skill_path_alias rejects an undef target path' );
    like( dies { $config->save_skill_path_alias( ['foo'], 'x', '' ) },        qr/Missing alias target/,         'save_skill_path_alias rejects an empty target path' );
    like( dies { $config->save_skill_path_alias( ['nosuchskillxyz'], 'x', '/y' ) }, qr/Unable to resolve installed skill path/,
        'save_skill_path_alias dies when the segments do not resolve to an installed skill at all' );

    like( dies { $config->remove_skill_path_alias( undef, 'x' ) },     qr/Missing skill-depth segments/, 'remove_skill_path_alias rejects a non-arrayref segments argument' );
    like( dies { $config->remove_skill_path_alias( [], 'x' ) },        qr/Missing skill-depth segments/, 'remove_skill_path_alias rejects an empty segments arrayref' );
    like( dies { $config->remove_skill_path_alias( ['foo'], undef ) }, qr/Missing alias name/,           'remove_skill_path_alias rejects an undef alias name' );
    like( dies { $config->remove_skill_path_alias( ['foo'], '' ) },    qr/Missing alias name/,           'remove_skill_path_alias rejects an empty-string alias name too' );

    is_deeply(
        $config->remove_skill_path_alias( ['nosuchskillxyz'], 'x' ),
        { name => 'nosuchskillxyz.x', removed => 0 },
        'remove_skill_path_alias on an unresolvable skill chain reports removed:0 rather than dying',
    );
};

subtest 'Config: writing the SAME nested location twice exercises the "already exists" branches' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    my $baz_dir = File::Spec->catdir( $bar_dir, 'skills', 'baz' );
    make_path($baz_dir);
    # baz and bar both carry .git, so the write walks all the way up to foo -
    # remaining = ['bar','baz'], a TWO-segment nesting inside foo's own file,
    # which is what exercises the "intermediate key already exists" branches
    # (ref($target->{$seg}) eq 'HASH' true vs false) on a second write.
    make_path( File::Spec->catdir( $bar_dir, '.git' ) );
    make_path( File::Spec->catdir( $baz_dir, '.git' ) );

    my ( undef, $config ) = fresh_registries();
    my $saved1 = $config->save_skill_path_alias( [ 'foo', 'bar', 'baz' ], 'first',  '/one' );
    is( $saved1->{name}, 'foo.bar.baz.first', 'first write into the two-deep nested structure succeeds' );
    # Second write: the "config_dir already exists" (make_path guard), the
    # "config file already exists" (-f guard), and the "intermediate key
    # already exists as HASH" guards are all now exercised on their TRUE
    # side, having been exercised FALSE on the first write above.
    my $saved2 = $config->save_skill_path_alias( [ 'foo', 'bar', 'baz' ], 'second', '/two' );
    is( $saved2->{name}, 'foo.bar.baz.second', 'second write into the SAME nested structure succeeds' );

    my $foo_config_file = File::Spec->catfile( $foo_dir, 'config', 'config.json' );
    is_deeply(
        read_json($foo_config_file),
        { bar => { baz => { path_aliases => { first => '/one', second => '/two' } } } },
        'both aliases coexist correctly nested two levels deep inside foo, alias_key already existing as a HASH on the second write',
    );

    is( $config->path_aliases->{'foo.bar.baz.first'},  '/one', 'both nested aliases read back correctly (first)' );
    is( $config->path_aliases->{'foo.bar.baz.second'}, '/two', 'both nested aliases read back correctly (second)' );

    # Removing one leaves the other and the surrounding structure intact -
    # exercises _remove_skill_alias's own "intermediate key" walk with real
    # multi-segment remaining, and the alias_key-exists-but-name-absent path
    # after the first delete.
    my $removed1 = $config->remove_skill_path_alias( [ 'foo', 'bar', 'baz' ], 'first' );
    is( $removed1->{removed}, 1, 'removing the first nested alias succeeds' );
    my $removed_again = $config->remove_skill_path_alias( [ 'foo', 'bar', 'baz' ], 'first' );
    is( $removed_again->{removed}, 0, 'removing it again is idempotent (alias_key exists as HASH, but the name is now absent)' );
    is_deeply(
        read_json($foo_config_file),
        { bar => { baz => { path_aliases => { second => '/two' } } } },
        'the surviving alias and the surrounding nested structure are intact after the removal',
    );

    remove_tree_quiet($skills_root);
};

subtest 'Config: _remove_skill_alias reports removed:0 without dying for every unreachable-target shape' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    make_path($foo_dir);
    my ( undef, $config ) = fresh_registries();

    is_deeply(
        $config->remove_skill_path_alias( ['foo'], 'never-written' ),
        { name => 'foo.never-written', removed => 0 },
        'removing from a skill with no config.json at all reports removed:0 (file missing)',
    );

    # A config.json exists but has no path_aliases key at all for this name -
    # and, for the GLOBAL fallback shape, a "skills" section that is present
    # but does not (yet) contain the requested nested path.
    make_path( File::Spec->catdir( $foo_dir, '.git' ) );    # foo now routes to the global fallback
    my ( undef, $config2 ) = fresh_registries();
    my $global_file = $config2->_global_config_file;
    open my $fh, '>:raw', $global_file or die $!;
    print {$fh} json_encode( { skills => { foo => { other => 'unrelated' } } } );
    close $fh;

    is_deeply(
        $config2->remove_skill_path_alias( [ 'foo' ], 'never-written' ),
        { name => 'foo.never-written', removed => 0 },
        'removing a name absent from an EXISTING global "skills" section reports removed:0 without dying',
    );

    # A deeper name whose intermediate segment is missing entirely from the
    # global "skills" tree - exercises the reachable=0 branch mid-walk.
    is_deeply(
        $config2->remove_skill_path_alias( [ 'foo', 'nosuchbar' ], 'x' ),
        { name => 'foo.nosuchbar.x', removed => 0 },
        'removing through a missing intermediate segment in the global fallback reports removed:0 (reachable=0 mid-walk)',
    );

    unlink $global_file if -e $global_file;
    remove_tree_quiet($skills_root);
};

subtest 'Config: _nested_skill_alias_entries tolerates a malformed nested shipped-default file' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    my $bar_config_dir = File::Spec->catdir( $bar_dir, 'config' );
    make_path($bar_config_dir);

    # Not a JSON object at all - pass 1 must skip it, not die.
    open my $fh, '>:raw', File::Spec->catfile( $bar_config_dir, 'config.json' ) or die $!;
    print {$fh} '[1,2,3]';
    close $fh;

    my ( undef, $config ) = fresh_registries();
    is( eval { $config->path_aliases; 1 }, 1, 'a non-object shipped config.json for a nested skill does not blow up path_aliases()' );
    ok( !exists $config->path_aliases->{'foo.bar.anything'}, 'nothing is surfaced from the malformed shipped file' );

    # A valid object but with no path_aliases key at all - the alias_key
    # ref-check false branch.
    open my $fh2, '>:raw', File::Spec->catfile( $bar_config_dir, 'config.json' ) or die $!;
    print {$fh2} json_encode( { unrelated => 1 } );
    close $fh2;
    my ( undef, $config2 ) = fresh_registries();
    ok( !exists $config2->path_aliases->{'foo.bar.anything'}, 'a shipped config with no path_aliases key contributes nothing, without dying' );

    # And the same malformed-file tolerance on the OVERRIDE (write-location)
    # read side: bar has its own .git so foo is the override location: make
    # foo's own config.json malformed too.
    make_path( File::Spec->catdir( $bar_dir, '.git' ) );
    my $foo_config_dir = File::Spec->catdir( $foo_dir, 'config' );
    make_path($foo_config_dir);
    open my $fh3, '>:raw', File::Spec->catfile( $foo_config_dir, 'config.json' ) or die $!;
    print {$fh3} 'not json at all {{{';
    close $fh3;
    my ( undef, $config3 ) = fresh_registries();
    is( eval { $config3->path_aliases; 1 }, 1, 'a malformed override-location config.json does not blow up path_aliases() either' );

    remove_tree_quiet($skills_root);
};

subtest 'Config: an empty-string alias key hand-authored in a nested shipped/override file is skipped, both passes' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    my $bar_config_dir = File::Spec->catdir( $bar_dir, 'config' );
    make_path($bar_config_dir);

    # PASS 1 (shipped default): bar has no .git, so it is its own read-only
    # shipped source; hand-author an empty-string key directly, exactly the
    # DD-977/978 precedent (this project's own established pathskill fixture
    # does the same for the flat case).
    open my $fh, '>:raw', File::Spec->catfile( $bar_config_dir, 'config.json' ) or die $!;
    print {$fh} json_encode( { path_aliases => { '' => '/should-be-skipped', real => '/kept' } } );
    close $fh;

    my ( undef, $config ) = fresh_registries();
    ok( !exists $config->path_aliases->{'foo.bar.'},     'pass 1 drops an empty-string alias name entirely, not as "foo.bar."' );
    is( $config->path_aliases->{'foo.bar.real'}, '/kept', 'pass 1 still keeps a real, non-empty alias name alongside the skipped one' );

    # PASS 2 (override): bar now carries its own .git, so foo becomes the
    # override location; hand-author the same empty-string-key shape there.
    make_path( File::Spec->catdir( $bar_dir, '.git' ) );
    my $foo_config_dir = File::Spec->catdir( $foo_dir, 'config' );
    make_path($foo_config_dir);
    open my $fh2, '>:raw', File::Spec->catfile( $foo_config_dir, 'config.json' ) or die $!;
    print {$fh2} json_encode( { bar => { path_aliases => { '' => '/should-be-skipped-2', real2 => '/kept2' } } } );
    close $fh2;

    my ( undef, $config2 ) = fresh_registries();
    ok( !exists $config2->path_aliases->{'foo.bar.'},      'pass 2 drops an empty-string alias name entirely too' );
    is( $config2->path_aliases->{'foo.bar.real2'}, '/kept2', 'pass 2 still keeps a real, non-empty alias name alongside the skipped one' );

    remove_tree_quiet($skills_root);
};

subtest 'Config: reading an installed-but-never-written skill chain hits every "nothing there yet" branch' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    make_path($bar_dir);
    make_path( File::Spec->catdir( $bar_dir, '.git' ) );    # bar's write/read location is foo (git-free)

    my $other_foo_dir = File::Spec->catdir( $skills_root, 'otherfoo' );
    make_path($other_foo_dir);
    make_path( File::Spec->catdir( $other_foo_dir, '.git' ) );    # a SECOND, unrelated depth-1 skill also routed to global

    my ( undef, $config ) = fresh_registries();
    # Nothing has ever been written anywhere - path_aliases() must not die,
    # and must surface nothing for either skill, exercising the "global_cfg
    # loaded but 'skills' key absent", "node not a HASH", and "$node->{seg}
    # not a HASH" false branches for a chain nobody has overridden yet.
    is( eval { $config->path_aliases; 1 }, 1, 'reading two never-written skill chains does not die' );
    ok( !exists $config->path_aliases->{'foo.bar.anything'},     'nothing surfaces for the never-written nested chain' );
    ok( !exists $config->path_aliases->{'otherfoo.anything'},    'nothing surfaces for the never-written second depth-1 chain either' );

    # Now write ONE override so a later read exercises "global_cfg already
    # loaded, 'skills' key present but this segment/skill absent" too.
    $config->save_skill_path_alias( ['otherfoo'], 'x', '/otherfoo-x' );
    my ( undef, $config2 ) = fresh_registries();
    is( $config2->path_aliases->{'otherfoo.x'}, '/otherfoo-x', 'the one real override still surfaces correctly' );
    ok( !exists $config2->path_aliases->{'foo.bar.anything'}, 'the still-unwritten chain surfaces nothing even once a SIBLING has an override' );

    remove_tree_quiet($skills_root);
    unlink $config->_global_config_file if -e $config->_global_config_file;
};

subtest 'Config: _remove_skill_alias kind=skill branch - missing file, missing intermediate segment, non-hash alias_key' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    my $baz_dir = File::Spec->catdir( $bar_dir, 'skills', 'baz' );
    make_path($baz_dir);
    make_path( File::Spec->catdir( $bar_dir, '.git' ) );
    make_path( File::Spec->catdir( $baz_dir, '.git' ) );    # foo.bar.baz always routes to foo (kind=skill)

    my ( undef, $config ) = fresh_registries();

    # foo has no config.json at all yet - kind=skill, file missing (TRUE side of !-f).
    is_deeply(
        $config->remove_skill_path_alias( [ 'foo', 'bar', 'baz' ], 'x' ),
        { name => 'foo.bar.baz.x', removed => 0 },
        'removing from a kind=skill location with no config.json at all reports removed:0',
    );

    # foo HAS a config.json, but the intermediate "bar" key is missing -
    # TRUE side of the ref($target->{$seg}) ne 'HASH' guard for kind=skill.
    my $foo_config_dir = File::Spec->catdir( $foo_dir, 'config' );
    make_path($foo_config_dir);
    my $foo_config_file = File::Spec->catfile( $foo_config_dir, 'config.json' );
    open my $fh, '>:raw', $foo_config_file or die $!;
    print {$fh} json_encode( { unrelated => 1 } );
    close $fh;
    is_deeply(
        $config->remove_skill_path_alias( [ 'foo', 'bar', 'baz' ], 'x' ),
        { name => 'foo.bar.baz.x', removed => 0 },
        'removing through a missing intermediate segment ("bar") reports removed:0 without dying',
    );

    # foo/bar exist, but foo's alias_key ("path_aliases") is present and NOT
    # a HASH (a skill author's config could shape it wrongly) - the false
    # side of ref($target->{$alias_key}) eq 'HASH'.
    open my $fh2, '>:raw', $foo_config_file or die $!;
    print {$fh2} json_encode( { bar => { baz => { path_aliases => 'not-a-hash' } } } );
    close $fh2;
    is_deeply(
        $config->remove_skill_path_alias( [ 'foo', 'bar', 'baz' ], 'x' ),
        { name => 'foo.bar.baz.x', removed => 0 },
        'a non-HASH alias_key value at the target reports removed:0 without dying',
    );

    remove_tree_quiet($skills_root);
};

subtest 'Config: writing TWICE into the global fallback exercises its "already exists" branches too' => sub {
    my $foo_dir = File::Spec->catdir( $skills_root, 'foo' );
    make_path($foo_dir);
    make_path( File::Spec->catdir( $foo_dir, '.git' ) );    # depth-1, always global anyway (Q-182) - .git is incidental here

    my $bar_dir = File::Spec->catdir( $foo_dir, 'skills', 'bar' );
    make_path($bar_dir);
    make_path( File::Spec->catdir( $bar_dir, '.git' ) );    # bar ALSO routes to global: foo.bar.something

    my ( undef, $config ) = fresh_registries();
    # First write seeds the global "skills" section from nothing.
    $config->save_skill_path_alias( ['foo'], 'first', '/one' );
    # Second write, DIFFERENT skill chain, reuses the now-existing "skills"
    # top-level key (false side of `ref($cfg->{skills}) ne 'HASH'`) and
    # builds a NEW nested "foo"."bar" path under it.
    $config->save_skill_path_alias( [ 'foo', 'bar' ], 'second', '/two' );
    # Third write, SAME chain as the second, exercises the "intermediate key
    # (foo, then bar) already exists as HASH" and "alias_key already exists"
    # branches for the global fallback specifically.
    $config->save_skill_path_alias( [ 'foo', 'bar' ], 'third', '/three' );

    my $global_file = $config->_global_config_file;
    is_deeply(
        read_json($global_file),
        {
            skills => {
                foo => {
                    path_aliases => { first => '/one' },
                    bar          => { path_aliases => { second => '/two', third => '/three' } },
                },
            },
        },
        'three writes into the global fallback (one fresh, two sharing/extending existing nested structure) land correctly',
    );

    # Removing one, then removing it AGAIN, exercises the global-kind
    # "alias_key exists as HASH but the name is now absent" idempotent path
    # (the skill-kind version of this is already covered elsewhere).
    my $removed1 = $config->remove_skill_path_alias( [ 'foo', 'bar' ], 'second' );
    is( $removed1->{removed}, 1, 'removing one alias from the global fallback nested structure succeeds' );
    my $removed_again = $config->remove_skill_path_alias( [ 'foo', 'bar' ], 'second' );
    is( $removed_again->{removed}, 0, 'removing it again from the global fallback is idempotent' );

    remove_tree_quiet($skills_root);
    unlink $global_file if -e $global_file;
};

sub remove_tree_quiet {
    my ($dir) = @_;
    require File::Path;
    File::Path::remove_tree( $dir, { safe => 1 } ) if -d $dir;
    return;
}

is_deeply( \@warnings, [], 'no warnings escaped the skill-depth alias suite' );

done_testing;

__END__

=pod

=head1 NAME

t/205-skill-depth-alias.t - skill-depth-prefixed dotted alias name support for
dashboard path/file add and del

=head1 PURPOSE

Covers DD-1004: C<dashboard path add>/C<dashboard file add> (and their C<del>
counterparts) now support a dotted alias name such as C<foo.bar.something>,
resolving it against arbitrarily nested C<skills/foo/skills/bar/> directories
and writing the alias into the correct skill's own C<config/config.json>
rather than always writing into the global config. It also covers the
owner's git-preservation correction: a skill directory that carries its own
C<.git> has its working tree overwritten on every C<d2 skill install>/update,
so the write walks upward to the nearest git-free ancestor directory (or all
the way to the global config, nested under the owner-confirmed C<"skills">
top-level key, when every ancestor including the first segment carries its
own C<.git>) - storing the alias as a nested hash mirroring the remaining
depth segments, never as a flattened dotted-string key.

=head1 WHY IT EXISTS

Skill-namespaced alias READING already existed (DD-977/DD-978) but only one
level deep and only for the global-config write path; the write side and the
nested skill-in-skill depth (and the git-preservation walk-up) did not exist
before this ticket. This file is the executable proof the whole chain
actually round-trips: write via the CLI, confirm the physical on-disk shape
in each of the git-preservation cases, then read the alias back out through
C<Config::path_aliases>/C<file_aliases> and the C<path resolve>/C<cdr>
machinery that consumes it.

=head1 WHEN TO USE

Use this file when changing C<Developer::Dashboard::Config>'s
C<split_skill_alias_name>, C<save_skill_path_alias>/C<save_skill_file_alias>,
C<remove_skill_path_alias>/C<remove_skill_file_alias>,
C<_nested_skill_alias_entries>, or
C<Developer::Dashboard::PathRegistry>'s C<nested_skill_dir_chain>,
C<nested_skill_entries>, or C<skill_config_write_location>.

=head1 HOW TO USE

Run C<prove -lv t/205-skill-depth-alias.t> while iterating, and keep it green
under C<prove -lr t> before release. The file is hermetic: it roots a
temporary home, chdirs into it, and builds real nested skill directory
fixtures (including C<.git> markers) under a temp C<skills/> tree rather than
stubbing the resolver.

=head1 WHAT USES IT

The repository test suite and developers changing skill-depth alias
resolution or the git-preservation write-location walk-up use this file to
confirm the write and read sides stay in agreement.

=head1 EXAMPLES

  prove -lv t/205-skill-depth-alias.t

Run this suite on its own while iterating.

  prove -lr t

Run it inside the full repository suite before release.

=cut
