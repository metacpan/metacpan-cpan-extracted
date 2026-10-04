#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Capture::Tiny qw(capture);
use Cwd qw(abs_path cwd);
use File::Basename qw(basename);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::CLI::Paths ();
use Developer::Dashboard::CLI::TableHelpers ();
use Developer::Dashboard::JSON qw(json_decode);
use Developer::Dashboard::PathRegistry;

# Warnings are fatal in this repository: collect any that escape and assert the
# whole run stayed clean.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; return; };

# Hermetic runtime rooted at a temp home. The config root resolves from the
# deepest .developer-dashboard layer above the cwd, so chdir into the temp home
# before building any registry or running any command.
my $home = abs_path( tempdir( CLEANUP => 1 ) );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $cwd       = cwd();
my $preferred = basename($cwd);

my $run              = \&Developer::Dashboard::CLI::Paths::run_paths_command;
my $build_paths      = \&Developer::Dashboard::CLI::TableHelpers::build_paths;
my $normalize_delete = \&Developer::Dashboard::CLI::Paths::_normalize_delete_argument;
my $resolve_alias    = \&Developer::Dashboard::CLI::Paths::_resolve_path_alias;
my $folder_aliases   = \&Developer::Dashboard::CLI::Paths::_skill_folder_path_aliases;
my $folder_target    = \&Developer::Dashboard::CLI::Paths::_skill_folder_alias_target;
my $cdr_payload      = \&Developer::Dashboard::CLI::Paths::_cdr_payload;
my $cdr_completion   = \&Developer::Dashboard::CLI::Paths::_cdr_completion;
my $initial          = \&Developer::Dashboard::CLI::Paths::_cdr_initial_candidates;
my $dir_candidates   = \&Developer::Dashboard::CLI::Paths::_cdr_directory_candidates;
my $paths_table      = \&Developer::Dashboard::CLI::Paths::_paths_table;
my $aliases_table    = \&Developer::Dashboard::CLI::TableHelpers::aliases_table;
my $list_table       = \&Developer::Dashboard::CLI::TableHelpers::list_table;
my $mutation_table   = \&Developer::Dashboard::CLI::TableHelpers::mutation_table;
my $removal_table    = \&Developer::Dashboard::CLI::TableHelpers::removal_table;
my $render_table     = \&Developer::Dashboard::CLI::TableHelpers::render_table;

{
    package Test::CLIPaths::PathsStub;

    # new(%args)
    # Builds one injectable stand-in for the path registry so the module's
    # defensive fallbacks can be driven with payloads a real registry never
    # produces.
    # Input: named_paths hash reference or undef, dirs array reference, cwd
    # string, and an expand code reference.
    # Output: Test::CLIPaths::PathsStub object.
    sub new {
        my ( $class, %args ) = @_;
        return bless {%args}, $class;
    }

    # named_paths()
    # Returns the stubbed alias inventory, including the undef payload used to
    # drive the module's empty-registry fallback.
    # Input: none.
    # Output: hash reference or undef.
    sub named_paths { return $_[0]->{named_paths}; }

    # current_working_directory()
    # Returns the stubbed invocation directory.
    # Input: none.
    # Output: directory path string.
    sub current_working_directory { return $_[0]->{cwd}; }

    # locate_dirs_under($root, @terms)
    # Returns the canned match list, including undef, empty, root-equal, and
    # duplicate-basename entries.
    # Input: search root and narrowing terms, both ignored by the stub.
    # Output: list of match entries.
    sub locate_dirs_under {
        my ($self) = @_;
        return @{ $self->{dirs} || [] };
    }

    # resolve_dir($name)
    # Returns one injected configured target or raises the registry-style
    # unknown-alias diagnostic used by cdr payload fallback tests.
    # Input: alias name string.
    # Output: configured target string, or dies when the name is absent.
    sub resolve_dir {
        my ( $self, $name ) = @_;
        return $self->{resolve}->($name) if ref( $self->{resolve} ) eq 'CODE';
        die "unknown alias '$name'\n";
    }

    # _expand_home($path)
    # Delegates to the injected home-expansion code reference.
    # Input: raw alias target string.
    # Output: whatever the injected code reference returns, or dies.
    sub _expand_home {
        my ( $self, $path ) = @_;
        return $self->{expand}->($path);
    }
}

{
    package Test::CLIPaths::ConfigStub;

    # new(%args)
    # Builds one injectable stand-in for the config object.
    # Input: path_aliases hash reference or undef.
    # Output: Test::CLIPaths::ConfigStub object.
    sub new {
        my ( $class, %args ) = @_;
        return bless {%args}, $class;
    }

    # path_aliases()
    # Returns the stubbed alias mapping, including the undef payload used to
    # drive the module's empty-alias fallback.
    # Input: none.
    # Output: hash reference or undef.
    sub path_aliases { return $_[0]->{path_aliases}; }
}

{
    package Test::CLIPaths::FolderPaths;

    # new(%args)
    # Creates a minimal installed-skill registry for malformed Folder.pm
    # fixtures without involving the real runtime layer scanner.
    # Input: nested_skill_entries list and optional named_paths hash.
    # Output: a path-registry stand-in accepted by the Folder alias helpers.
    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    # nested_skill_entries()
    # Returns the injected skill roots in the list context expected by Paths.
    # Input: none.
    # Output: list of installed skill entry hash references.
    sub nested_skill_entries { return @{ $_[0]->{entries} || [] }; }

    # named_paths()
    # Returns the configured alias map used by completion's config precedence.
    # Input: none.
    # Output: hash reference or undef.
    sub named_paths { return $_[0]->{named_paths}; }

    # _expand_home($path)
    # Keeps fixture aliases deterministic while preserving the path helper API.
    # Input: one target path string.
    # Output: the same target path string.
    sub _expand_home { return $_[1]; }

    # resolve_dir($name)
    # Produces a stable unknown-alias error for completion code paths.
    # Input: alias name.
    # Output: never returns; dies with the unknown alias name.
    sub resolve_dir { die "unknown alias '$_[1]'\n"; }
}

# _write_folder_fixture($name, $source)
# Writes one isolated skill Folder.pm source file for defensive path tests.
# Input: skill directory name and complete Perl source text.
# Output: an installed-skill entry hash with dir, segments, lib, and file.
sub _write_folder_fixture {
    my ( $name, $source ) = @_;
    my $dir  = File::Spec->catdir( $home, 'fixture-skills', $name );
    my $lib  = File::Spec->catdir( $dir, 'lib' );
    my $file = File::Spec->catfile( $lib, 'Folder.pm' );
    make_path($lib);
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} $source;
    close $fh or die "Unable to close $file: $!";
    return { dir => $dir, segments => [$name], lib => $lib, file => $file };
}

subtest 'run_paths_command rejects malformed dispatch arguments' => sub {
    my $missing_command = eval { $run->( args => [] ); 1 };
    is( $missing_command, undef, 'a missing command name aborts dispatch' );
    like( $@, qr/^Missing command name$/m, 'the missing command name is reported' );

    my $missing_args = eval { $run->( command => 'paths' ); 1 };
    is( $missing_args, undef, 'missing command arguments abort dispatch' );
    like( $@, qr/^Missing command arguments$/m, 'the missing argument list is reported' );

    my $bad_args = eval { $run->( command => 'paths', args => {} ); 1 };
    is( $bad_args, undef, 'a non-array argument payload aborts dispatch' );
    like( $@, qr/^Command arguments must be an array reference$/m, 'the argument type error is reported' );
};

subtest 'paths and path list reject leftover positional arguments' => sub {
    my $paths_extra = eval { $run->( command => 'paths', args => ['leftover'] ); 1 };
    is( $paths_extra, undef, 'dashboard paths refuses a stray positional argument' );
    like( $@, qr/^Usage: dashboard paths \[-o json\|table\]$/m, 'the paths usage message is printed' );

    my $list_extra = eval { $run->( command => 'path', args => [ 'list', 'leftover' ] ); 1 };
    is( $list_extra, undef, 'dashboard path list refuses a stray positional argument' );
    like( $@, qr/^Usage: dashboard path list \[-o json\|table\]$/m, 'the list usage message is printed' );
};

subtest 'path dispatch reports usage for missing verbs and operands' => sub {
    my $no_action = eval { $run->( command => 'path', args => [] ); 1 };
    is( $no_action, undef, 'an empty path argument list falls through to the dispatch usage error' );
    like( $@, qr/^Usage: dashboard path <resolve\|locate\|cdr\|complete-cdr\|add\|del\|rm\|project-root\|list> \.\.\.$/m,
        'the path dispatch usage message is printed' );

    my $no_name = eval { $run->( command => 'path', args => ['resolve'] ); 1 };
    is( $no_name, undef, 'path resolve without a name aborts' );
    like( $@, qr/^Usage: dashboard path resolve <name>$/m, 'the resolve usage message is printed' );
};

subtest 'path complete-cdr defaults a missing or empty completion index' => sub {
    my ( $missing_index_out, $missing_index_err ) = capture {
        $run->( command => 'path', args => ['complete-cdr'] );
    };
    is( $missing_index_out, "\n", 'a missing completion index yields no candidates' );
    is( $missing_index_err, '',   'a missing completion index writes nothing to STDERR' );

    my ( $empty_index_out, $empty_index_err ) = capture {
        $run->( command => 'path', args => [ 'complete-cdr', '' ] );
    };
    is( $empty_index_out, "\n", 'an empty completion index yields no candidates' );
    is( $empty_index_err, '',   'an empty completion index writes nothing to STDERR' );
};

subtest 'path project-root prints nothing outside a project checkout' => sub {
    my ( $stdout, $stderr ) = capture {
        $run->( command => 'path', args => ['project-root'] );
    };
    is( $stdout, '', 'a cwd with no git root above it prints an empty project root' );
    is( $stderr, '', 'the empty project root writes nothing to STDERR' );
};

subtest 'path add reports usage for every incomplete operand form' => sub {
    my $no_operands = eval { $run->( command => 'path', args => ['add'] ); 1 };
    is( $no_operands, undef, 'path add without operands aborts' );
    like( $@, qr/^Usage: dashboard path add <name> <path>$/m, 'the add usage message is printed for no operands' );

    my $lone_name = eval { $run->( command => 'path', args => [ 'add', 'solo' ] ); 1 };
    is( $lone_name, undef, 'a single non-dot operand is not the current-directory shorthand' );
    like( $@, qr/^Usage: dashboard path add <name> <path>$/m, 'the add usage message is printed for a lone alias name' );

    my $empty_name = eval { $run->( command => 'path', args => [ 'add', '', 'target' ] ); 1 };
    is( $empty_name, undef, 'an empty alias name aborts' );
    like( $@, qr/^Usage: dashboard path add <name> <path>$/m, 'the add usage message is printed for an empty alias name' );
};

subtest '_normalize_delete_argument guards its injected dependencies' => sub {
    my $config = Test::CLIPaths::ConfigStub->new( path_aliases => {} );
    my $paths  = Test::CLIPaths::PathsStub->new( expand => sub { return $_[0] } );

    my $no_paths = eval { $normalize_delete->( config => $config, name => 'alpha' ); 1 };
    is( $no_paths, undef, 'a missing path registry aborts alias deletion' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is reported' );

    my $no_config = eval { $normalize_delete->( paths => $paths, name => 'alpha' ); 1 };
    is( $no_config, undef, 'a missing config aborts alias deletion' );
    like( $@, qr/^Missing config$/m, 'the missing config is reported' );

    my $no_name = eval { $normalize_delete->( paths => $paths, config => $config ); 1 };
    is( $no_name, undef, 'an undefined alias name aborts alias deletion' );
    like( $@, qr/^Usage: dashboard path del <name>$/m, 'the del usage message is printed for an undefined name' );

    my $empty_name = eval { $normalize_delete->( paths => $paths, config => $config, name => '' ); 1 };
    is( $empty_name, undef, 'an empty alias name aborts alias deletion' );
    like( $@, qr/^Usage: dashboard path del <name>$/m, 'the del usage message is printed for an empty name' );
};

subtest '_normalize_delete_argument falls back to the directory basename' => sub {
    my $identity = Test::CLIPaths::PathsStub->new( expand => sub { return $_[0] } );

    is(
        $normalize_delete->(
            paths  => $identity,
            config => Test::CLIPaths::ConfigStub->new( path_aliases => undef ),
            name   => '.',
        ),
        $preferred,
        'an absent alias mapping falls back to the current directory basename',
    );

    is(
        $normalize_delete->(
            paths  => $identity,
            config => Test::CLIPaths::ConfigStub->new(
                path_aliases => {
                    'aaa-undefined-target' => undef,
                    'bbb-empty-target'     => '',
                },
            ),
            name => '.',
        ),
        $preferred,
        'aliases with undefined or empty targets are skipped during the current-directory scan',
    );
};

subtest '_normalize_delete_argument survives unexpandable alias targets' => sub {
    my $unexpandable = Test::CLIPaths::PathsStub->new( expand => sub { die "unable to expand\n" } );
    my $blanking     = Test::CLIPaths::PathsStub->new( expand => sub { return '' } );
    my $elsewhere    = File::Spec->catdir( $home, 'not-the-current-directory' );

    is(
        $normalize_delete->(
            paths  => $unexpandable,
            config => Test::CLIPaths::ConfigStub->new( path_aliases => { $preferred => $elsewhere } ),
            name   => '.',
        ),
        $preferred,
        'a failing home expansion falls back to the raw alias target and keeps the basename answer',
    );

    is(
        $normalize_delete->(
            paths  => $blanking,
            config => Test::CLIPaths::ConfigStub->new( path_aliases => { $preferred => 'raw-alias-target' } ),
            name   => '.',
        ),
        $preferred,
        'a blank home expansion falls back to the raw alias target and keeps the basename answer',
    );
};

subtest '_build_paths tolerates an empty home environment' => sub {
    local $ENV{HOME} = '';
    delete local $ENV{USERPROFILE};
    delete local $ENV{HOMEDRIVE};
    delete local $ENV{HOMEPATH};

    my $built = eval { $build_paths->() };
    is( $built, undef, 'an empty HOME leaves no resolvable home directory' );
    like( $@, qr/Missing home directory/, 'the unresolvable home directory is reported' );
};

subtest '_resolve_path_alias validates its inputs and reports unknown aliases' => sub {
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );

    my $missing_paths = eval { $resolve_alias->( name => 'missing' ); 1 };
    is( $missing_paths, undef, 'a missing registry aborts alias resolution' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry has a direct diagnostic' );

    my $missing_name = eval { $resolve_alias->( paths => $paths ); 1 };
    is( $missing_name, undef, 'a missing alias name aborts resolution' );
    like( $@, qr/Missing path name/, 'the missing alias name has a direct diagnostic' );

    my $empty_name = eval { $resolve_alias->( paths => $paths, name => '' ); 1 };
    is( $empty_name, undef, 'an empty alias name aborts resolution' );
    like( $@, qr/Missing path name/, 'the empty alias name has a direct diagnostic' );

    my $unknown = eval { $resolve_alias->( paths => $paths, name => 'unknown.alias' ); 1 };
    is( $unknown, undef, 'an alias absent from config and installed skills is rejected' );
    like( $@, qr/unknown\.alias/, 'the registry reports which unknown alias failed resolution' );
};

subtest 'Folder alias discovery validates registries and safely skips invalid candidates' => sub {
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );

    my $missing_registry = eval { $folder_aliases->(); 1 };
    is( $missing_registry, undef, 'Folder alias enumeration requires a registry' );
    like( $@, qr/^Missing paths registry$/m, 'Folder alias enumeration reports a missing registry' );

    is_deeply( $folder_aliases->( paths => $paths ), {}, 'Folder alias enumeration is empty when no skills are installed' );

    for my $invalid ( undef, [], "bad\nname", 'unqualified', 'skill..alias', 'skill.__list__', 'skill.can' ) {
        ok( !defined $folder_target->( paths => $paths, name => $invalid ), 'invalid or reserved Folder alias target is rejected before lookup' );
    }
    ok( !defined $folder_target->( paths => $paths, name => 'missing-skill.alias' ), 'a qualified alias with no installed skill resolves to undef' );
    ok( !defined $folder_target->( paths => $paths, name => 'one-part' ), 'a single path component is not a skill-qualified alias' );
    ok( !defined $folder_target->( paths => $paths, name => 'missing-skill.123bad' ), 'an invalid method identifier is rejected before loading a skill' );
};

subtest 'Folder.pm alias validation reports malformed providers and unsafe layouts' => sub {
    my @entries;
    my $paths = Test::CLIPaths::FolderPaths->new( entries => \@entries );

    my $entries_missing_paths = eval { Developer::Dashboard::CLI::Paths::_skill_folder_entries(); 1 };
    is( $entries_missing_paths, undef, '_skill_folder_entries rejects a missing path registry' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is named' );

    push @entries, { dir => $home };
    my @entries_without_segments = Developer::Dashboard::CLI::Paths::_skill_folder_entries($paths);
    is( $entries_without_segments[0]{name}, '',
        'a skill entry without segments defaults to an empty name safely' );
    @entries = ();

    my $missing_entry = eval { Developer::Dashboard::CLI::Paths::_load_skill_folder_module(undef); 1 };
    is( $missing_entry, undef, '_load_skill_folder_module rejects a non-hash entry' );
    like( $@, qr/^Missing skill Folder entry$/m, 'the malformed skill entry has a direct error' );

    my $missing_file = eval { Developer::Dashboard::CLI::Paths::_load_skill_folder_module( { dir => $home, lib => $home } ); 1 };
    is( $missing_file, undef, '_load_skill_folder_module rejects an entry without a file path' );
    like( $@, qr/^Missing skill Folder\.pm path$/m, 'the missing Folder.pm path is named' );

    my $absent = { dir => $home, lib => File::Spec->catdir( $home, 'absent-lib' ), file => File::Spec->catfile( $home, 'absent-lib', 'Folder.pm' ) };
    ok( !Developer::Dashboard::CLI::Paths::_load_skill_folder_module($absent), 'a skill with no Folder.pm is skipped' );

    push @entries, _write_folder_fixture( 'no-list', "package Folder; sub here { '/here' } 1;\n" );
    is_deeply( $folder_aliases->( paths => $paths ), {}, 'a valid Folder.pm without __list__ contributes no aliases' );

    my $array_entry = _write_folder_fixture( 'array-list', "package Folder; sub __list__ { return ['here'] } 1;\n" );
    @entries = ($array_entry);
    my $array_error = eval { $folder_aliases->( paths => $paths ); 1 };
    is( $array_error, undef, 'Folder->__list__ returning an arrayref is rejected' );
    like( $@, qr/must return a list of alias names, not an array reference/, 'the arrayref/list-context contract is explicit' );

    my $bad_name_entry = _write_folder_fixture( 'bad-name', "package Folder; sub __list__ { return ('bad-name') } 1;\n" );
    @entries = ($bad_name_entry);
    my $bad_name_error = eval { $folder_aliases->( paths => $paths ); 1 };
    is( $bad_name_error, undef, 'Folder->__list__ returning an invalid method name is rejected' );
    like( $@, qr/returned an invalid alias name/, 'the invalid listed alias is named' );

    my $missing_method_entry = _write_folder_fixture( 'missing-method', "package Folder; sub __list__ { return ('there') } 1;\n" );
    @entries = ($missing_method_entry);
    my $missing_method_error = eval { $folder_aliases->( paths => $paths ); 1 };
    is( $missing_method_error, undef, 'Folder->__list__ naming an absent method is rejected' );
    like( $@, qr/listed 'there' but Folder->there is not available/, 'the missing method is named' );

    my $empty_target_entry = _write_folder_fixture( 'empty-target', "package Folder; sub __list__ { return ('here') } sub here { '' } 1;\n" );
    @entries = ($empty_target_entry);
    my $empty_target_error = eval { $folder_aliases->( paths => $paths ); 1 };
    is( $empty_target_error, undef, 'Folder methods returning an empty target are rejected' );
    like( $@, qr/must return a non-empty path string/, 'the empty target contract is explicit' );

    @entries = ( { dir => $empty_target_entry->{dir}, segments => ['empty-target'] } );
    ok( !defined $folder_target->( paths => $paths, name => 'empty-target.unknown' ), 'a skill with Folder.pm but no requested method returns undef' );

    my $bad_return_entry = _write_folder_fixture( 'bad-return', "package Folder; sub broken { return [] } 1;\n" );
    @entries = ($bad_return_entry);
    my $bad_return_error = eval { $folder_target->( paths => $paths, name => 'bad-return.broken' ); 1 };
    is( $bad_return_error, undef, 'an alias method returning a reference is rejected' );
    like( $@, qr/must return a non-empty path string/, 'the alias return type error is explicit' );

    my $undefined_target_entry = _write_folder_fixture( 'undefined-target', "package Folder; sub here { return undef } 1;\n" );
    @entries = ($undefined_target_entry);
    my $undefined_target_error = eval { $folder_target->( paths => $paths, name => 'undefined-target.here' ); 1 };
    is( $undefined_target_error, undef, 'an alias method returning undef is rejected' );
    like( $@, qr/must return a non-empty path string/, 'an undefined alias target has a direct error' );

    my $compile_entry = _write_folder_fixture( 'compile-error', "package Folder; sub broken { ; 1;\n" );
    my $compile_error = eval { Developer::Dashboard::CLI::Paths::_load_skill_folder_module($compile_entry); 1 };
    is( $compile_error, undef, 'a syntactically invalid Folder.pm is rejected' );
    like( $@, qr/Unable to load skill Folder\.pm.*syntax error/s, 'the Perl compile error is preserved' );

    my $false_entry = _write_folder_fixture( 'false-return', "package Folder; 0;\n" );
    my $false_error = eval { Developer::Dashboard::CLI::Paths::_load_skill_folder_module($false_entry); 1 };
    is( $false_error, undef, 'a Folder.pm whose final expression is false is rejected' );
    like( $@, qr/did not return a true value/, 'the false module return is reported' );

    my $undefined_entry = _write_folder_fixture( 'undefined-return', "package Folder; \$! = 0; undef;\n" );
    local $! = 0;
    my $undefined_error = eval { Developer::Dashboard::CLI::Paths::_load_skill_folder_module($undefined_entry); 1 };
    is( $undefined_error, undef, 'a Folder.pm whose final expression is undef is rejected' );
    like( $@, qr/did not return a true value|Unable to load skill Folder\.pm/, 'the undefined module return has a visible error' );

    my $failed_read_entry = _write_folder_fixture( 'failed-read', "package Folder; \$! = 2; undef;\n" );
    my $failed_read_error = eval { Developer::Dashboard::CLI::Paths::_load_skill_folder_module($failed_read_entry); 1 };
    is( $failed_read_error, undef, 'an undefined load with errno is rejected' );
    like( $@, qr/Unable to load skill Folder\.pm/, 'the errno load failure is not swallowed' );

    my $outside_file = File::Spec->catfile( $home, 'outside-Folder.pm' );
    open my $outside_fh, '>', $outside_file or die "Unable to write $outside_file: $!";
    print {$outside_fh} "package Folder; 1;\n";
    close $outside_fh or die "Unable to close $outside_file: $!";
    my $unresolvable_skill = File::Spec->catdir( $home, 'unresolvable-skill-a' );
    my $unresolvable_loop  = File::Spec->catdir( $home, 'unresolvable-skill-b' );
    symlink $unresolvable_loop, $unresolvable_skill or die "Unable to symlink $unresolvable_skill: $!";
    symlink $unresolvable_skill, $unresolvable_loop or die "Unable to symlink $unresolvable_loop: $!";
    my $missing_skill_entry = { dir => $unresolvable_skill, lib => $home, file => $outside_file };
    my $missing_skill_error = eval { Developer::Dashboard::CLI::Paths::_load_skill_folder_module($missing_skill_entry); 1 };
    is( $missing_skill_error, undef, 'an unresolvable skill root is rejected' );
    like( $@, qr/Unable to resolve skill Folder\.pm/, 'the failed realpath is reported' );

    my $symlink_root = File::Spec->catdir( $home, 'symlink-skill' );
    my $external_lib = File::Spec->catdir( $home, 'external-lib' );
    my $symlink_lib  = File::Spec->catdir( $symlink_root, 'lib' );
    make_path( $symlink_root, $external_lib );
    my $external_folder = File::Spec->catfile( $external_lib, 'Folder.pm' );
    open my $external_fh, '>', $external_folder or die "Unable to write $external_folder: $!";
    print {$external_fh} "package Folder; 1;\n";
    close $external_fh or die "Unable to close $external_folder: $!";
    symlink $external_lib, $symlink_lib or die "Unable to symlink $symlink_lib: $!";
    my $outside_lib_error = eval { Developer::Dashboard::CLI::Paths::_load_skill_folder_module( { dir => $symlink_root, lib => $symlink_lib, file => File::Spec->catfile( $symlink_lib, 'Folder.pm' ) } ); 1 };
    is( $outside_lib_error, undef, 'a Folder.pm lib directory escaping its skill root is rejected' );
    like( $@, qr/resolves outside its skill root/, 'the escaped lib path is reported' );

    my $contained_root = File::Spec->catdir( $home, 'contained-skill' );
    my $contained_lib  = File::Spec->catdir( $contained_root, 'lib' );
    make_path($contained_lib);
    my $outside_file_link = File::Spec->catfile( $contained_lib, 'Folder.pm' );
    symlink $outside_file, $outside_file_link or die "Unable to symlink $outside_file_link: $!";
    my $outside_file_error = eval { Developer::Dashboard::CLI::Paths::_load_skill_folder_module( { dir => $contained_root, lib => $contained_lib, file => $outside_file_link } ); 1 };
    is( $outside_file_error, undef, 'a Folder.pm symlink escaping its skill lib directory is rejected' );
    like( $@, qr/resolves outside its skill lib directory/, 'the escaped source path is reported' );

    my $resolved_entry = _write_folder_fixture( 'abs-path-failure', "package Folder; sub here { '/here' } 1;\n" );
    my $real_abs_path = \&Developer::Dashboard::CLI::Paths::abs_path;
    for my $field (qw(lib file)) {
        my $failed_path = $resolved_entry->{$field};
        no warnings 'redefine';
        local *Developer::Dashboard::CLI::Paths::abs_path = sub {
            return undef if defined $_[0] && $_[0] eq $failed_path;
            return $real_abs_path->(@_);
        };
        my $unresolved = eval { Developer::Dashboard::CLI::Paths::_load_skill_folder_module($resolved_entry); 1 };
        is( $unresolved, undef, "an unresolvable Folder.pm $field path is refused" );
        like( $@, qr/Unable to resolve skill Folder\.pm/, "the unresolvable $field path is reported" );
    }
};

subtest '_cdr_payload guards its arguments and empty term lists' => sub {
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );

    my $no_paths = eval { $cdr_payload->( args => [] ); 1 };
    is( $no_paths, undef, 'a missing path registry aborts the cdr payload' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is reported' );

    my $bad_args = eval { $cdr_payload->( paths => $paths, args => {} ); 1 };
    is( $bad_args, undef, 'a non-array cdr argument payload aborts' );
    like( $@, qr/^cdr args must be an array reference$/m, 'the cdr argument type error is reported' );

    is_deeply(
        $cdr_payload->( paths => $paths ),
        { target => '', matches => [] },
        'an absent argument list defaults to an empty term list and an empty target',
    );
};

subtest '_cdr_payload treats a blank alias target as no alias' => sub {
    my $alias_cwd = File::Spec->catdir( $home, 'blank-alias-cwd' );
    make_path($alias_cwd);
    my $paths = Developer::Dashboard::PathRegistry->new(
        home        => $home,
        cwd         => $alias_cwd,
        named_paths => { emptyalias => '' },
    );

    is( $paths->resolve_dir('emptyalias'), '', 'the fixture alias really does resolve to a blank target' );
    is_deeply(
        $cdr_payload->( paths => $paths, args => ['emptyalias'] ),
        { target => '', matches => [] },
        'a blank alias target falls through to a current-directory search instead of being used as a root',
    );
};

subtest '_cdr_payload keeps the first unregistered word as a search term' => sub {
    my $search_root = File::Spec->catdir( $home, 'cdr-first-unregistered-term' );
    my $match = File::Spec->catdir( $search_root, 'alpha-team', 'red-fox' );
    make_path($match);
    my $paths = Developer::Dashboard::PathRegistry->new(
        home        => $home,
        cwd         => $search_root,
        named_paths => {},
    );

    is_deeply(
        $cdr_payload->( paths => $paths, args => [ 'alpha', 'red' ] ),
        { target => $match, matches => [] },
        'the first non-alias argument is AND-matched with later search terms',
    );
};

subtest 'skill Folder aliases resolve after config aliases and appear in paths without being persisted' => sub {
    my $skill_root = File::Spec->catdir( $home, '.developer-dashboard', 'skills', 'folder-skill' );
    my $skill_config_dir = File::Spec->catdir( $skill_root, 'config' );
    my $skill_lib_dir = File::Spec->catdir( $skill_root, 'lib' );
    my $skill_helper_dir = File::Spec->catdir( $skill_lib_dir, 'Skill' );
    make_path( $skill_config_dir, $skill_helper_dir );

    my $skill_config_file = File::Spec->catfile( $skill_config_dir, 'config.json' );
    open my $config_fh, '>', $skill_config_file or die "Unable to write $skill_config_file: $!";
    print {$config_fh} '{"path_aliases":{"docs":"/configured/docs"}}';
    close $config_fh or die "Unable to close $skill_config_file: $!";

    my $helper_file = File::Spec->catfile( $skill_helper_dir, 'Helper.pm' );
    open my $helper_fh, '>', $helper_file or die "Unable to write $helper_file: $!";
    print {$helper_fh} "package Skill::Helper; sub path { return '/module/only' } 1;\n";
    close $helper_fh or die "Unable to close $helper_file: $!";

    my $folder_file = File::Spec->catfile( $skill_lib_dir, 'Folder.pm' );
    open my $folder_fh, '>', $folder_file or die "Unable to write $folder_file: $!";
    print {$folder_fh} <<'FOLDER_MODULE';
package Folder;
use Skill::Helper;
sub docs { return '/module/docs' }
sub module_only { return Skill::Helper::path() }
sub __list__ { return ('docs', 'module_only') }
1;
FOLDER_MODULE
    close $folder_fh or die "Unable to close $folder_file: $!";

    my ( $config_cdr, $config_cdr_err ) = capture {
        $run->( command => 'path', args => [ 'cdr', 'folder-skill.docs' ] );
    };
    is( $config_cdr_err, '', 'a configured skill alias resolves without a Folder.pm error' );
    is( json_decode($config_cdr)->{target}, '/configured/docs', 'config/config.json takes precedence over a colliding Folder.pm method' );

    my ( $folder_cdr, $folder_cdr_err ) = capture {
        $run->( command => 'path', args => [ 'cdr', 'folder-skill.module_only' ] );
    };
    is( $folder_cdr_err, '', 'a Folder.pm-only skill alias resolves without diagnostics' );
    is( json_decode($folder_cdr)->{target}, '/module/only', 'cdr resolves an alias from the skill Folder.pm method' );

    my ( $resolved_output, $resolved_err ) = capture {
        $run->( command => 'path', args => [ 'resolve', 'folder-skill.module_only' ] );
    };
    is( $resolved_err, '', 'path resolve handles Folder.pm aliases without diagnostics' );
    is( $resolved_output, "/module/only\n", 'path resolve consults Folder.pm after configured aliases' );

    my ( $paths_json, $paths_err ) = capture {
        $run->( command => 'paths', args => [ '-o', 'json' ] );
    };
    is( $paths_err, '', 'paths lists Folder.pm aliases without diagnostics' );
    my $listed_paths = json_decode($paths_json);
    is( $listed_paths->{'folder-skill.docs'}, '/configured/docs', 'paths keeps the config alias value when a Folder.pm alias collides' );
    is( $listed_paths->{'folder-skill.module_only'}, '/module/only', 'paths merges aliases returned by Folder->__list__ and Folder methods' );

    my ( $path_list_json, $path_list_err ) = capture {
        $run->( command => 'path', args => [ 'list', '-o', 'json' ] );
    };
    is( $path_list_err, '', 'path list includes Folder.pm aliases without diagnostics' );
    is( json_decode($path_list_json)->{'folder-skill.module_only'}, '/module/only', 'path list merges the listed Folder.pm aliases without persisting them' );

    my ( $completion, $completion_err ) = capture {
        $run->( command => 'path', args => [ 'complete-cdr', 1, 'cdr', 'folder-skill.m' ] );
    };
    is( $completion_err, '', 'cdr completion includes Folder.pm aliases without diagnostics' );
    like( $completion, qr/^folder-skill\.module_only$/m, 'cdr completion suggests the qualified Folder.pm alias' );

    my ( $add_output, $add_err ) = capture {
        $run->( command => 'path', args => [ 'add', 'folder-skill.added', '/configured/added', '-o', 'json' ] );
    };
    is( $add_err, '', 'path add writes a skill-qualified config alias without diagnostics' );
    like( $add_output, qr/folder-skill\.added/, 'path add reports the added qualified alias' );

    open my $saved_skill_config_fh, '<', $skill_config_file or die "Unable to read $skill_config_file: $!";
    local $/;
    my $saved_skill_config = json_decode( <$saved_skill_config_fh> );
    close $saved_skill_config_fh;
    is_deeply( $saved_skill_config->{path_aliases}, { docs => '/configured/docs' }, 'path add does not rewrite the skill-owned Folder.pm or config defaults' );

    my $global_config_file = File::Spec->catfile( $home, '.developer-dashboard', 'config', 'config.json' );
    open my $global_config_fh, '<', $global_config_file or die "Unable to read $global_config_file: $!";
    my $global_config = json_decode( do { local $/; <$global_config_fh> } );
    close $global_config_fh;
    is( $global_config->{skills}{'folder-skill'}{path_aliases}{added}, '/configured/added', 'path add persists the override in config/config.json' );
};

subtest '_cdr_completion guards its injected arguments' => sub {
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );

    my $no_paths = eval { $cdr_completion->( words => [], index => 0 ); 1 };
    is( $no_paths, undef, 'a missing path registry aborts completion' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is reported' );

    my $no_words = eval { $cdr_completion->( paths => $paths, index => 0 ); 1 };
    is( $no_words, undef, 'a missing word list aborts completion' );
    like( $@, qr/^Missing completion words$/m, 'the missing word list is reported' );

    my $no_index = eval { $cdr_completion->( paths => $paths, words => [] ); 1 };
    is( $no_index, undef, 'a missing completion index aborts completion' );
    like( $@, qr/^Missing completion index$/m, 'the missing completion index is reported' );

    my $bad_words = eval { $cdr_completion->( paths => $paths, words => 'cdr', index => 0 ); 1 };
    is( $bad_words, undef, 'a non-array word list aborts completion' );
    like( $@, qr/^cdr completion words must be an array reference$/m, 'the word list type error is reported' );

    is_deeply( [ $cdr_completion->( paths => $paths, words => [], index => 0 ) ],
        [], 'an empty word list yields no candidates' );
};

subtest '_cdr_completion uses an unregistered first word to narrow later candidates' => sub {
    my $root = File::Spec->catdir( $home, 'cdr-completion-first-unregistered-term' );
    make_path(
        File::Spec->catdir( $root, 'alpha-team', 'second-match' ),
        File::Spec->catdir( $root, 'alpha-team', 'other-match' ),
        File::Spec->catdir( $root, 'beta-team', 'second-match' ),
    );
    my $paths = Developer::Dashboard::PathRegistry->new(
        home        => $home,
        cwd         => $root,
        named_paths => {},
    );

    is_deeply(
        [ $cdr_completion->( paths => $paths, words => [ 'cdr', 'alpha', 'se' ], index => 2 ) ],
        ['second-match'],
        'the unregistered first word narrows completion to its matching directory branch',
    );
};

subtest '_cdr_completion handles out-of-range indexes and blank alias roots' => sub {
    my $alias_cwd = File::Spec->catdir( $home, 'completion-cwd' );
    make_path($alias_cwd);
    my $paths = Developer::Dashboard::PathRegistry->new(
        home        => $home,
        cwd         => $alias_cwd,
        named_paths => { emptyalias => '' },
    );

    is_deeply(
        [ $cdr_completion->( paths => $paths, words => ['cdr'], index => 5 ) ],
        [],
        'an index past the end of the word list yields no candidates and no unresolvable alias root',
    );

    is_deeply(
        [ $cdr_completion->( paths => $paths, words => [ 'cdr', 'emptyalias', 'x' ], index => 2 ) ],
        [],
        'a blank alias target is narrowed under the current directory rather than used as a completion root',
    );
};

subtest '_cdr_initial_candidates guards its arguments and empty registries' => sub {
    my $stub = Test::CLIPaths::PathsStub->new( named_paths => undef, dirs => [] );

    my $no_paths = eval { $initial->( include => [] ); 1 };
    is( $no_paths, undef, 'a missing path registry aborts initial completion' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is reported' );

    my $bad_roots = eval { $initial->( paths => $stub, prefix => '', include => 'nope' ); 1 };
    is( $bad_roots, undef, 'a non-array include list aborts initial completion' );
    like( $@, qr/^cdr completion include roots must be an array reference$/m, 'the include list type error is reported' );

    is_deeply( [ $initial->( paths => $stub, include => [] ) ],
        [], 'an empty alias registry and an absent prefix yield no candidates' );

    is_deeply(
        [ $initial->( paths => Test::CLIPaths::PathsStub->new( named_paths => { alpha => '/alpha' } ), prefix => '' ) ],
        ['alpha'],
        'an absent include list defaults to no extra directory roots',
    );
};

subtest '_cdr_initial_candidates filters unusable roots and blank aliases' => sub {
    my $root = File::Spec->catdir( $home, 'initial-root' );
    make_path( File::Spec->catdir( $root, 'beta', 'nested-child' ) );
    open my $file_fh, '>', File::Spec->catfile( $root, 'plain-file' ) or die $!;
    close $file_fh or die $!;
    my $stub = Test::CLIPaths::PathsStub->new(
        named_paths => { '' => '/blank-alias-name', 'alpha' => '/alpha' },
        cwd         => $root,
    );

    is_deeply(
        [ $initial->( paths => $stub, prefix => '', include => [ undef, '', $root ] ) ],
        [ 'alpha', 'beta' ],
        'initial cdr completion lists direct child directories without recursively scanning nested trees',
    );
};

subtest '_cdr_directory_candidates guards its arguments' => sub {
    my $stub = Test::CLIPaths::PathsStub->new( dirs => [] );

    my $no_paths = eval { $dir_candidates->( root => '/somewhere' ); 1 };
    is( $no_paths, undef, 'a missing path registry aborts directory completion' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is reported' );

    is_deeply( [ $dir_candidates->( paths => $stub ) ], [], 'an absent search root yields no candidates' );

    my $bad_terms = eval { $dir_candidates->( paths => $stub, root => '/somewhere', terms => 'nope' ); 1 };
    is( $bad_terms, undef, 'a non-array term list aborts directory completion' );
    like( $@, qr/^cdr completion terms must be an array reference$/m, 'the term list type error is reported' );
};

subtest '_cdr_directory_candidates walks only the explicitly narrowed branch' => sub {
    my $root = File::Spec->catdir( $home, 'directory-candidates-root' );
    make_path(
        File::Spec->catdir( $root, 'alpha', 'nested', 'deep' ),
        File::Spec->catdir( $root, 'beta', 'nested', 'other' ),
        File::Spec->catdir( $root, 'alpha-one', 'same-name' ),
        File::Spec->catdir( $root, 'alpha-two', 'same-name' ),
    );
    open my $file_fh, '>', File::Spec->catfile( $root, 'alpha-file' ) or die $!;
    close $file_fh or die $!;
    my $stub = Test::CLIPaths::PathsStub->new( cwd => $root );

    is_deeply(
        [ $dir_candidates->( paths => $stub, root => $root ) ],
        [qw(alpha alpha-one alpha-two beta)],
        'unfiltered completion lists only immediate child directories',
    );
    is_deeply(
        [ $dir_candidates->( paths => $stub, root => $root, terms => [ 'alpha', undef, '' ], prefix => 'n' ) ],
        ['nested'],
        'a prior completion term narrows to its direct child instead of recursively searching the whole tree',
    );
    is_deeply(
        [ $dir_candidates->( paths => $stub, root => $root, terms => [ 'alpha', 'nested' ], prefix => '' ) ],
        ['deep'],
        'each accepted term descends exactly one level before listing the next candidates',
    );
    is_deeply(
        [ $dir_candidates->( paths => $stub, root => $root, terms => ['alpha-'], prefix => '' ) ],
        ['same-name'],
        'candidate basenames duplicated under separate matching parents are returned once',
    );
};

subtest 'cdr completion handles disappearing and unreadable directories and close failures' => sub {
    my $root = File::Spec->catdir( $home, 'completion-directory-failures' );
    make_path( File::Spec->catdir( $root, 'alpha', 'child' ) );
    my $paths = Test::CLIPaths::PathsStub->new( cwd => $root, named_paths => {} );

    is( Developer::Dashboard::CLI::Paths::_open_completion_directory( File::Spec->catdir( $root, 'missing' ) ), undef,
        'a missing completion directory has no open handle' );

    for my $stage (qw(initial narrowing candidates)) {
        no warnings 'redefine';
        local *Developer::Dashboard::CLI::Paths::_open_completion_directory = sub { return; };
        my @result = $stage eq 'initial'
          ? $initial->( paths => $paths, prefix => '', include => [$root] )
          : $dir_candidates->(
            paths => $paths,
            root  => $root,
            ( $stage eq 'narrowing' ? ( terms => ['alpha'] ) : () ),
        );
        is_deeply( \@result, [], "a directory that disappears before the $stage read contributes no candidates" );
    }

    my $close_root = File::Spec->catdir( $root, 'alpha' );
    my $dh = Developer::Dashboard::CLI::Paths::_open_completion_directory($close_root);
    ok($dh, 'completion directory opens before close validation');
    Developer::Dashboard::CLI::Paths::_close_completion_directory( $dh, $close_root );

    my @close_warnings;
    my $ok;
    {
        local $SIG{__WARN__} = sub { push @close_warnings, $_[0]; return; };
        $ok = eval { Developer::Dashboard::CLI::Paths::_close_completion_directory( $dh, $close_root ); 1 };
    }
    is( $ok, undef, 'closing the same handle twice reports failure' );
    like( $@, qr/^Unable to close directory \Q$close_root\E:/, 'the close failure names the affected directory' );
    like( $close_warnings[0] // '', qr/closedir\(\) attempted on invalid dirhandle/i, 'the expected invalid-handle warning is captured by the test' );
};

subtest 'summary tables tolerate absent payloads' => sub {
    like( $paths_table->(undef),          qr/^Path\s+Value$/m,          'the paths table renders headers for an absent inventory' );
    like( $aliases_table->(undef),        qr/^Alias\s+Path$/m,          'the aliases table renders headers for an absent registry' );
    like( $list_table->( 'Path', undef ), qr/^Path$/m,                  'the list table renders headers for an absent item list' );
    like( $mutation_table->( alias => 'solo' ), qr/^solo\s*$/m,         'the mutation table blanks every absent column' );
    like( $removal_table->( removed => 0 ),     qr/^\s*no\s+no-change/m, 'the removal table reports a no-change removal with a blank alias' );
};

subtest '_render_table tolerates absent headers, rows, and cells' => sub {
    is( $render_table->( undef, undef ), "\n\n", 'an absent header and row set render as an empty table' );
    is( $render_table->( ['Head'], undef ), "Head\n----\n", 'an absent row set renders header and rule only' );
    is( $render_table->( [undef], [] ), "\n\n", 'an undefined header cell renders as a zero-width column' );
};

subtest 'Folder alias filtering, validation and cdr fallback cover alternate provider shapes' => sub {
    my $first = _write_folder_fixture(
        'filter-first',
        "package Folder; sub __list__ { return ('here') } sub here { return '/first' } 1;\n",
    );
    my $second = _write_folder_fixture(
        'filter-second',
        "package Folder; sub __list__ { return ('there') } sub there { return '/second' } 1;\n",
    );
    my $paths = Test::CLIPaths::FolderPaths->new(
        entries     => [ $first, $second ],
        named_paths => undef,
    );

    is_deeply(
        $folder_aliases->( paths => $paths, skill_name => 'filter-first' ),
        { 'filter-first.here' => '/first' },
        'skill_name filters out Folder.pm providers from other installed skills',
    );
    is_deeply(
        $folder_aliases->( paths => $paths, skill_name => 'not-installed' ),
        {},
        'a skill filter with no matching installed root returns an empty alias set',
    );
    is( $resolve_alias->( paths => $paths, name => 'filter-first.here' ), '/first',
        'alias resolution falls back to Folder.pm when the configured alias map is absent' );

    for my $invalid ( undef, [], "bad\nname", 'unqualified', 'skill.', '.alias', 'skill..alias', 'skill.__list__' ) {
        ok(
            !defined $folder_target->( paths => $paths, name => $invalid ),
            'qualified Folder alias resolver refuses undefined, referenced, control, empty-part and reserved names',
        );
    }
    my $missing_paths = eval { $folder_target->( name => 'skill.here' ); 1 };
    is( $missing_paths, undef, 'direct Folder alias resolution requires a path registry' );
    like( $@, qr/^Missing paths registry$/m, 'direct Folder alias resolution names the missing registry' );

    ok( Developer::Dashboard::CLI::Paths::_valid_folder_method_name('path_1'), 'plain Perl identifier is a valid Folder alias method' );
    for my $reserved ( undef, [], 'bad-name', 'can', 'isa', 'DOES', 'VERSION', 'DESTROY' ) {
        ok( !Developer::Dashboard::CLI::Paths::_valid_folder_method_name($reserved), 'non-identifiers and inherited methods are not Folder aliases' );
    }

    my $fallback_paths = Test::CLIPaths::PathsStub->new(
        named_paths => undef,
        cwd         => '/current',
        resolve     => sub { die "unknown alias '$_[0]'\n" },
    );
    is_deeply(
        $cdr_payload->(
            paths                => $fallback_paths,
            args                 => ['filter-first.here'],
            folder_alias_resolver => sub { return '/from-folder' },
        ),
        { target => '/from-folder', matches => [] },
        'cdr uses the Folder provider when configured aliases are absent and registry resolution misses',
    );
    is_deeply(
        $cdr_payload->(
            paths                 => $fallback_paths,
            args                  => ['missing'],
            folder_alias_resolver => [],
        ),
        { target => '', matches => [] },
        'cdr ignores a Folder fallback provider that is not a code reference',
    );
    my $configured_provider_calls = 0;
    my $configured_paths = Test::CLIPaths::PathsStub->new(
        named_paths => { configured => '/configured' },
        cwd         => '/current',
        resolve     => sub { die "unknown alias '$_[0]'\n" },
    );
    is_deeply(
        $cdr_payload->(
            paths                 => $configured_paths,
            args                  => ['configured'],
            folder_alias_resolver => sub { $configured_provider_calls++; die 'configured aliases must suppress Folder fallback'; },
        ),
        { target => '', matches => [] },
        'cdr does not query the Folder provider after the configured alias map claims the name',
    );
    is( $configured_provider_calls, 0, 'configured path names prevent Folder.pm alias lookup' );
};

subtest 'Folder alias discovery exercises absent modules, invalid list names, and invalid targets' => sub {
    my $absent = { name => 'absent', dir => $home, lib => File::Spec->catdir( $home, 'not-installed-lib' ), file => File::Spec->catfile( $home, 'not-installed-lib', 'Folder.pm' ) };
    my $paths = Test::CLIPaths::FolderPaths->new( entries => [$absent], named_paths => {} );
    is_deeply( $folder_aliases->( paths => $paths ), {}, 'Folder alias enumeration skips installed skills without Folder.pm' );
    ok( !defined $folder_target->( paths => $paths, name => 'absent.here' ),
        'resolving an alias for an installed skill without Folder.pm returns undef' );
    ok( !defined $folder_target->( paths => $paths, name => 'not-installed.here' ),
        'resolving an alias for an unknown skill returns undef' );

    my $without_method = _write_folder_fixture(
        'direct-missing-method',
        "package Folder; sub here { return '/here' } 1;\n",
    );
    $paths = Test::CLIPaths::FolderPaths->new( entries => [$without_method], named_paths => {} );
    ok( !defined $folder_target->( paths => $paths, name => 'direct-missing-method.no_such_alias' ),
        'a loaded Folder.pm without the requested method returns no alias target' );

    for my $invalid_name ( undef, [], 'bad-name', '__list__' ) {
        my $source = 'package Folder; sub __list__ { return ( ' . (defined $invalid_name ? "'$invalid_name'" : 'undef') . ' ) } 1;';
        my $entry = _write_folder_fixture( 'list-invalid-' . (defined $invalid_name ? 'value' : 'undef'), "$source\n" );
        $paths = Test::CLIPaths::FolderPaths->new( entries => [$entry], named_paths => {} );
        my $listed = eval { $folder_aliases->( paths => $paths ); 1 };
        is( $listed, undef, 'Folder->__list__ rejects invalid names, including its reserved method name' );
        like( $@, qr/returned an invalid alias name/, 'the invalid list member is diagnosed' );
    }

    for my $case ( [ undef, 'undefined' ], [ [], 'reference' ], [ '', 'empty' ] ) {
        my ( $target, $label ) = @{$case};
        my $source = 'package Folder; sub __list__ { return ("here") } sub here { return ';
        $source .= ref($target) eq 'ARRAY' ? '[]' : !defined($target) ? 'undef' : "''";
        $source .= " } 1;\n";
        my $entry = _write_folder_fixture( "list-target-$label", $source );
        $paths = Test::CLIPaths::FolderPaths->new( entries => [$entry], named_paths => {} );
        my $listed = eval { $folder_aliases->( paths => $paths ); 1 };
        is( $listed, undef, "Folder->__list__ rejects a $label method result" );
        like( $@, qr/must return a non-empty path string/, 'the invalid target return is diagnosed' );
    }

};

subtest '_cdr_directory_candidates reports malformed narrowing expressions' => sub {
    my $root = File::Spec->catdir( $home, 'invalid-cdr-regex-root' );
    make_path($root);
    my $directory_paths = Test::CLIPaths::PathsStub->new( cwd => $root );
    my $ok = eval { $dir_candidates->( paths => $directory_paths, root => $root, terms => ['['] ); 1 };
    is( $ok, undef, 'an invalid prior narrowing expression aborts completion' );
    like( $@, qr/^Invalid regex '\[':/, 'the malformed completion expression is reported' );
};

is_deeply( \@warnings, [], 'no warnings escaped the CLI::Paths coverage run' );

done_testing;

__END__

=pod

=head1 NAME

t/90-cli-paths-coverage.t - branch and condition coverage for the path CLI runtime

=head1 PURPOSE

This test drives every remaining decision point in
C<Developer::Dashboard::CLI::Paths> that the behavioural suites never reach: the
dispatch argument guards, the usage errors for each C<dashboard path> verb, the
current-directory delete shorthand when alias targets are missing, blank, or
unexpandable, the C<cdr> payload and completion helpers when an alias resolves
to a blank target or the completion index runs past the supplied words,
skill-provided C<Folder.pm> path aliases, and the table renderers when headers,
rows, or cells are absent. The Folder fixtures include absent C<__list__>,
arrayref lists, invalid and missing method names, bad return values, compile and
false module returns, and symlink escapes from the skill root and C<lib/>.

=head1 WHY IT EXISTS

The repository gate requires C<lib/> to sit at 100.0 on all four Devel::Cover
metrics, statement, subroutine, branch, and condition. The path CLI is almost
entirely defensive at its edges: it validates injected registries, config
objects, argument references, and completion indexes that the normal shell
helpers never send it malformed. Those guards are the ones that keep C<cdr>,
C<dd_cdr>, and C<which_dir> from emitting raw Perl errors into an interactive
shell, so they need executable coverage rather than an annotation.

=head1 WHEN TO USE

Use this file when changing the argument validation, usage messages, alias
loading, current-directory shorthand, C<cdr> target selection, skill-provided
C<Folder.pm> aliases, shell-completion candidates, or table rendering inside
the path CLI runtime.

=head1 HOW TO USE

Run C<prove -lv t/90-cli-paths-coverage.t> while iterating, and keep it green
under C<prove -lr t> before release. The file is hermetic: it roots a temporary
home, chdirs into it so the layered runtime resolves from that directory, and
injects small stand-in registry and config objects for the payloads a real
C<Developer::Dashboard::PathRegistry> or C<Developer::Dashboard::Config> cannot
produce, such as an absent alias inventory, an alias target that fails home
expansion, or a directory search that returns undefined entries. To confirm the
coverage contribution, run the suite under
C<HARNESS_PERL_SWITCHES=-MDevel::Cover> and check the branch and condition
columns for the path CLI module.

=head1 WHAT USES IT

The repository test suite, the Devel::Cover gate, and developers changing the
path CLI runtime use this file to keep the defensive edges of C<dashboard path>
and C<dashboard paths> behaving as documented. Its skill fixture also pins
config-first resolution, list-context C<Folder-E<gt>__list__> discovery, and
the rule that C<path add> writes config without editing an installed skill. It
also verifies that C<cdr> completion lists direct children and descends one
level per entered term instead of recursively traversing large project trees.
An unregistered first C<cdr> word remains a search term for target resolution
and completion of later arguments.
The file covers absent skill modules, invalid alias return values, and
unresolved module paths.

=head1 EXAMPLES

Example 1:

  prove -lv t/90-cli-paths-coverage.t

Run the path CLI coverage checks on their own while iterating.

Example 2:

  prove -lr t

Run them inside the full repository suite before release.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Run them under the coverage gate to confirm the path CLI branch and condition
columns stay at 100.

=cut
