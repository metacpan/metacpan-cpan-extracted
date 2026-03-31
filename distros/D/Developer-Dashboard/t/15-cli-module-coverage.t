use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(chdir cwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::OpenFile qw(build_path_registry run_open_file_command);
use Developer::Dashboard::CLI::Query qw(run_query_command);
use Developer::Dashboard::JSON qw(json_decode);

local $ENV{HOME} = tempdir(CLEANUP => 1);
for my $dir (qw(projects src work)) {
    make_path( File::Spec->catdir( $ENV{HOME}, $dir ) );
}

my $registry = build_path_registry();
isa_ok( $registry, 'Developer::Dashboard::PathRegistry', 'build_path_registry returns a path registry' );

my $project_root = File::Spec->catdir( $ENV{HOME}, 'projects', 'sample-project' );
make_path($project_root);
my $notes_file = File::Spec->catfile( $project_root, 'alpha-notes.txt' );
open my $notes_fh, '>', $notes_file or die "Unable to write $notes_file: $!";
print {$notes_fh} "alpha\n";
close $notes_fh;

my ( $line_from_ref, @ref_match ) = Developer::Dashboard::CLI::OpenFile::_resolve_open_file_matches(
    paths => $registry,
    args  => [ "$notes_file:18" ],
);
is( $line_from_ref, 18, 'file:line resolution preserves the line number' );
is_deeply( \@ref_match, [$notes_file], 'file:line resolution returns the file path' );

my ( $line_from_file, @file_match ) = Developer::Dashboard::CLI::OpenFile::_resolve_open_file_matches(
    paths => $registry,
    args  => [$notes_file],
);
is( $line_from_file, 0, 'plain file resolution has no line override' );
is_deeply( \@file_match, [$notes_file], 'plain file resolution returns the file path' );

my $perl_lib = File::Spec->catdir( $project_root, 'lib', 'My' );
make_path($perl_lib);
my $perl_module_file = File::Spec->catfile( $perl_lib, 'Tool.pm' );
open my $perl_fh, '>', $perl_module_file or die "Unable to write $perl_module_file: $!";
print {$perl_fh} "package My::Tool;\n1;\n";
close $perl_fh;

{
    my $original_cwd = cwd();
    chdir $project_root or die "Unable to chdir to $project_root: $!";
    local @INC = ( File::Spec->catdir( $project_root, 'lib' ), @INC );
    my @perl_named = Developer::Dashboard::CLI::OpenFile::_named_source_matches(
        paths => $registry,
        name  => 'My::Tool',
    );
    ok( grep( $_ eq $perl_module_file, @perl_named ), 'Perl module lookup resolves module file paths' );
    chdir $original_cwd or die "Unable to restore cwd to $original_cwd: $!";
}

my $java_root = File::Spec->catdir( $project_root, 'src', 'main', 'java', 'com', 'example' );
make_path($java_root);
my $java_file = File::Spec->catfile( $java_root, 'App.java' );
open my $java_fh, '>', $java_file or die "Unable to write $java_file: $!";
print {$java_fh} "package com.example;\nclass App {}\n";
close $java_fh;

{
    my $original_cwd = cwd();
    chdir $project_root or die "Unable to chdir to $project_root: $!";
    my @java_named = Developer::Dashboard::CLI::OpenFile::_named_source_matches(
        paths => $registry,
        name  => 'com.example.App',
    );
    ok( grep( $_ eq $java_file, @java_named ), 'Java class lookup resolves class file paths' );
    chdir $original_cwd or die "Unable to restore cwd to $original_cwd: $!";
}

my $src_root = File::Spec->catdir( $ENV{HOME}, 'src' );
my $named_prefix_file = File::Spec->catfile( $src_root, 'pkg', 'Demo.pm' );
make_path( File::Spec->catdir( $src_root, 'pkg' ) );
open my $prefix_fh, '>', $named_prefix_file or die "Unable to write $named_prefix_file: $!";
print {$prefix_fh} "package pkg::Demo;\n1;\n";
close $prefix_fh;
my @prefixed = Developer::Dashboard::CLI::OpenFile::_existing_named_files(
    roots    => [$ENV{HOME}],
    relative => File::Spec->catfile( 'pkg', 'Demo.pm' ),
    prefixes => [ '', 'src' ],
);
ok( grep( $_ eq $named_prefix_file, @prefixed ), 'named file lookup honors configured prefixes' );

{
    my $original_cwd = cwd();
    chdir $project_root or die "Unable to chdir to $project_root: $!";
    my ( $fallback_line, @fallback_match ) = Developer::Dashboard::CLI::OpenFile::_resolve_open_file_matches(
        paths => $registry,
        args  => ['alpha'],
    );
    is( $fallback_line, 0, 'fallback project search keeps line number at zero' );
    ok( grep( $_ eq $notes_file, @fallback_match ), 'fallback project search finds matching files below current project root' );
    my @roots = Developer::Dashboard::CLI::OpenFile::_open_file_roots( paths => $registry );
    ok( grep( $_ eq $project_root, @roots ), 'open-file roots include the current project root' );
    chdir $original_cwd or die "Unable to restore cwd to $original_cwd: $!";
}

my ( $print_stdout, undef ) = capture {
    local *Developer::Dashboard::CLI::OpenFile::_command_exit = sub { die "EXIT:$_[0]" };
    eval {
        run_open_file_command(
            paths => $registry,
            args  => [ '--print', 'home', 'alpha-notes' ],
        );
    };
    like( $@, qr/^EXIT:0\b/, 'print-mode open-file path exits cleanly through the test hook' );
};
like( $print_stdout, qr/\Q$notes_file\E/, 'print-mode open-file command emits the resolved path' );

my $captured_exec = '';
eval {
    local *Developer::Dashboard::CLI::OpenFile::_command_exec = sub {
        $captured_exec = join "\n", @_;
        die "EXEC";
    };
    run_open_file_command(
        paths => $registry,
        args  => [ '--editor', 'fake-editor --wait', "$notes_file:12" ],
    );
};
like( $@, qr/^EXEC/, 'editor-mode open-file path reaches the exec hook' );
like( $captured_exec, qr/^fake-editor\n--wait\n\+12\n\Q$notes_file\E$/m, 'editor-mode open-file command builds the expected editor invocation' );

eval {
    run_open_file_command( paths => $registry, args => [] );
};
like( $@, qr/^Usage: open-file/, 'open-file command rejects missing arguments' );

eval {
    run_open_file_command( paths => $registry, args => [ '--print', $project_root, 'missing-pattern' ] );
};
like( $@, qr/^No files found/, 'open-file command rejects unmatched searches' );

my ( $path_a, $file_a ) = Developer::Dashboard::CLI::Query::_split_query_args( '$d', $notes_file );
is( $path_a, '$d', 'query splitting keeps the query path when it comes first' );
is( $file_a, $notes_file, 'query splitting keeps the file path when it comes second' );

my ( $path_b, $file_b ) = Developer::Dashboard::CLI::Query::_split_query_args( $notes_file, 'alpha.beta' );
is( $path_b, 'alpha.beta', 'query splitting keeps the query path when it comes second' );
is( $file_b, $notes_file, 'query splitting keeps the file path when it comes first' );

my $json_file = File::Spec->catfile( $project_root, 'sample.json' );
open my $json_fh, '>', $json_file or die "Unable to write $json_file: $!";
print {$json_fh} qq|{"alpha":{"beta":[1,2],"gamma":"ok"}}|;
close $json_fh;
is( Developer::Dashboard::CLI::Query::_read_query_input($json_file), qq|{"alpha":{"beta":[1,2],"gamma":"ok"}}|, 'query input reads from files' );

my $stdin_text = qq|{"stdin":1}|;
open my $stdin_fh, '<', \$stdin_text or die "Unable to open scalar stdin handle: $!";
local *STDIN = $stdin_fh;
is( Developer::Dashboard::CLI::Query::_read_query_input(''), $stdin_text, 'query input reads from STDIN when no file is supplied' );

my $json_data = Developer::Dashboard::CLI::Query::_parse_query_input(
    command => 'pjq',
    text    => qq|{"alpha":{"beta":[1,2],"gamma":"ok"}}|,
);
is_deeply( $json_data, { alpha => { beta => [ 1, 2 ], gamma => 'ok' } }, 'JSON query parsing works' );

my $yaml_data = Developer::Dashboard::CLI::Query::_parse_query_input(
    command => 'pyq',
    text    => "alpha:\n  beta: 3\n",
);
is_deeply( $yaml_data, { alpha => { beta => 3 } }, 'YAML query parsing works' );

my $toml_data = Developer::Dashboard::CLI::Query::_parse_query_input(
    command => 'ptomq',
    text    => "[alpha]\nbeta = 4\n",
);
is_deeply( $toml_data, { alpha => { beta => 4 } }, 'TOML query parsing works' );

my $props_data = Developer::Dashboard::CLI::Query::_parse_query_input(
    command => 'pjp',
    text    => "alpha.beta=5\npath = one\\\\two\nwrapped = first\\\n second\n",
);
is_deeply(
    $props_data,
    {
        'alpha.beta' => '5',
        path         => "one\\\two",
        wrapped      => 'first second',
    },
    'Java properties query parsing works, including escaped and continued values',
);

eval {
    Developer::Dashboard::CLI::Query::_parse_query_input(
        command => 'unknown',
        text    => '{}',
    );
};
like( $@, qr/Unsupported data query command/, 'unsupported query command dies clearly' );

is( Developer::Dashboard::CLI::Query::_extract_query_path( $json_data, 'alpha.gamma' ), 'ok', 'nested hash extraction works' );
is( Developer::Dashboard::CLI::Query::_extract_query_path( $json_data, 'alpha.beta.1' ), 2, 'array extraction works' );
is( Developer::Dashboard::CLI::Query::_extract_query_path( { 'alpha.beta' => 9 }, 'alpha.beta' ), 9, 'exact dotted-key extraction works before segment splitting' );
is_deeply( Developer::Dashboard::CLI::Query::_extract_query_path( $json_data, '$d' ), $json_data, 'whole-document selector returns the full data structure' );

eval { Developer::Dashboard::CLI::Query::_extract_query_path( $json_data, 'alpha.missing' ) };
like( $@, qr/Missing path segment 'missing'/, 'missing hash segment dies clearly' );

eval { Developer::Dashboard::CLI::Query::_extract_query_path( $json_data, 'alpha.beta.x' ) };
like( $@, qr/Array index 'x' is invalid/, 'invalid array index dies clearly' );

eval { Developer::Dashboard::CLI::Query::_extract_query_path( 'scalar', 'alpha' ) };
like( $@, qr/does not resolve through a nested structure/, 'scalar traversal dies clearly' );

my ($scalar_stdout) = capture {
    ok( Developer::Dashboard::CLI::Query::_print_query_value('value'), 'scalar query output returns true' );
};
is( $scalar_stdout, "value\n", 'scalar query output prints a trailing newline' );

my ($ref_stdout) = capture {
    ok( Developer::Dashboard::CLI::Query::_print_query_value( { answer => 42 } ), 'ref query output returns true' );
};
is_deeply( json_decode($ref_stdout), { answer => 42 }, 'ref query output prints canonical JSON' );

my ( $query_stdout, undef ) = capture {
    local *Developer::Dashboard::CLI::Query::_command_exit = sub { die "EXIT:$_[0]" };
    my $stdin_json = qq|{"alpha":{"beta":7}}|;
    open my $query_stdin, '<', \$stdin_json or die "Unable to open scalar query stdin: $!";
    local *STDIN = $query_stdin;
    eval {
        run_query_command(
            command => 'pjq',
            args    => ['alpha.beta'],
        );
    };
    like( $@, qr/^EXIT:0\b/, 'run_query_command exits through the test hook' );
};
is( $query_stdout, "7\n", 'run_query_command prints extracted scalar values' );

{
    my $pid = fork();
    die "fork failed: $!" if !defined $pid;
    if (!$pid) {
        Developer::Dashboard::CLI::Query::_command_exit(7);
    }
    waitpid( $pid, 0 );
    is( $? >> 8, 7, 'query command exit helper delegates to process exit' );
}

{
    my $pid = fork();
    die "fork failed: $!" if !defined $pid;
    if (!$pid) {
        Developer::Dashboard::CLI::OpenFile::_command_exit(9);
    }
    waitpid( $pid, 0 );
    is( $? >> 8, 9, 'open-file exit helper delegates to process exit' );
}

my $exec_script = File::Spec->catfile( $project_root, 'fake-editor.sh' );
open my $exec_fh, '>', $exec_script or die "Unable to write $exec_script: $!";
print {$exec_fh} "#!/bin/sh\nexit 0\n";
close $exec_fh;
chmod 0755, $exec_script or die "Unable to chmod $exec_script: $!";

{
    my $pid = fork();
    die "fork failed: $!" if !defined $pid;
    if (!$pid) {
        Developer::Dashboard::CLI::OpenFile::_command_exec( $exec_script, '--wait', $notes_file );
    }
    waitpid( $pid, 0 );
    is( $? >> 8, 0, 'open-file exec helper delegates to process exec' );
}

done_testing;

__END__

=head1 NAME

15-cli-module-coverage.t - direct coverage tests for lightweight standalone CLI helper modules

=head1 DESCRIPTION

This test exercises the in-process helper code behind the standalone open-file
and structured-data query executables so their library coverage stays at 100%.

=cut
