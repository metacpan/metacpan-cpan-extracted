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

my $print_error = '';
my ( $print_stdout, undef ) = capture {
    local *Developer::Dashboard::CLI::OpenFile::_command_exit = sub { die "EXIT:$_[0]" };
    eval {
        run_open_file_command(
            paths => $registry,
            args  => [ '--print', 'home', 'alpha-notes' ],
        );
    };
    $print_error = $@;
};
like( $print_error, qr/^EXIT:0\b/, 'print-mode open-file path exits cleanly through the test hook' );
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

my $duplicate_file = File::Spec->catfile( $project_root, 'alpha-second-notes.txt' );
open my $duplicate_fh, '>', $duplicate_file or die "Unable to write $duplicate_file: $!";
print {$duplicate_fh} "alpha second\n";
close $duplicate_fh;

my $scope_root = File::Spec->catdir( $project_root, 'scope-fixtures' );
my $scope_cli_root = File::Spec->catdir( $scope_root, 'cli' );
my $scope_js_root  = File::Spec->catdir( $scope_root, 'public', 'js' );
make_path( $scope_cli_root, $scope_js_root );
my $scope_jq = File::Spec->catfile( $scope_cli_root, 'jq' );
open my $scope_jq_fh, '>', $scope_jq or die "Unable to write $scope_jq: $!";
print {$scope_jq_fh} "#!/bin/sh\n";
close $scope_jq_fh;
my $scope_jq_js = File::Spec->catfile( $scope_js_root, 'jq.js' );
open my $scope_jq_js_fh, '>', $scope_jq_js or die "Unable to write $scope_jq_js: $!";
print {$scope_jq_js_fh} "window.jq = true;\n";
close $scope_jq_js_fh;
my $scope_jquery = File::Spec->catfile( $scope_js_root, 'jquery.js' );
open my $scope_jquery_fh, '>', $scope_jquery or die "Unable to write $scope_jquery: $!";
print {$scope_jquery_fh} "window.jquery = true;\n";
close $scope_jquery_fh;
my ( $scope_line, @scope_match ) = Developer::Dashboard::CLI::OpenFile::_resolve_open_file_matches(
    paths => $registry,
    args  => [ $scope_root, 'jq' ],
);
is( $scope_line, 0, 'scoped jq search keeps line number at zero' );
is_deeply(
    \@scope_match,
    [ $scope_jq, $scope_jq_js, $scope_jquery ],
    'scoped jq search ranks exact jq helper and jq.js ahead of jquery.js',
);
is(
    Developer::Dashboard::CLI::OpenFile::_scope_match_rank(
        file     => '/tmp/tools/jq',
        patterns => ['jq'],
    ),
    0,
    'scope rank prefers exact basename matches',
);
is(
    Developer::Dashboard::CLI::OpenFile::_scope_match_rank(
        file     => '/tmp/tools/jq.js',
        patterns => ['jq'],
    ),
    1,
    'scope rank prefers basename stem matches next',
);
is(
    Developer::Dashboard::CLI::OpenFile::_scope_match_rank(
        file     => '/tmp/tools/jquery.js',
        patterns => ['jq'],
    ),
    2,
    'scope rank then prefers basename prefix matches',
);
is(
    Developer::Dashboard::CLI::OpenFile::_scope_match_rank(
        file     => '/tmp/tools/my-jq-helper.js',
        patterns => ['jq'],
    ),
    3,
    'scope rank then falls back to basename substring matches',
);
is(
    Developer::Dashboard::CLI::OpenFile::_scope_match_rank(
        file     => '/tmp/jq/helper-script',
        patterns => ['jq'],
    ),
    4,
    'scope rank handles path-component matches that are not basename hits',
);
is(
    Developer::Dashboard::CLI::OpenFile::_scope_match_rank(
        file     => '/tmp/tools/helper-jq/path',
        patterns => ['jq'],
    ),
    5,
    'scope rank finally falls back to full-path substring matches',
);
is(
    Developer::Dashboard::CLI::OpenFile::_scope_match_rank(
        file     => '',
        patterns => ['jq'],
    ),
    50,
    'scope rank handles empty file paths without crashing',
);
is_deeply(
    [
        Developer::Dashboard::CLI::OpenFile::_ordered_scope_matches(
            patterns => ['jq'],
            files    => [ '/tmp/tools/jquery.js', '/tmp/tools/jq.js', '/tmp/tools/jq' ],
        )
    ],
    [ '/tmp/tools/jq', '/tmp/tools/jq.js', '/tmp/tools/jquery.js' ],
    'ordered scope matches sorts by rank while preserving ties by discovery order',
);

my $interactive_error = '';
my ( $interactive_stdout, $interactive_stderr ) = capture {
    local *Developer::Dashboard::CLI::OpenFile::_command_exec = sub {
        $captured_exec = join "\n", @_;
        die "EXEC";
    };
    open my $stdin_fh, '<', \"2\n" or die 'Unable to open scalar stdin handle for open-file selection';
    local *STDIN = $stdin_fh;
    eval {
        run_open_file_command(
            paths => $registry,
            args  => [ $project_root, 'alpha' ],
        );
    };
    $interactive_error = $@;
};
like( $interactive_error, qr/^EXEC/, 'interactive open-file path reaches the exec hook' );
like( $interactive_stdout, qr/^\d+: \Q$notes_file\E$/m, 'interactive open-file lists the first matching alpha file' );
like( $interactive_stdout, qr/^\d+: \Q$duplicate_file\E$/m, 'interactive open-file lists the second matching alpha file' );
like( $interactive_stdout, qr/> \z/, 'interactive open-file prompts with the legacy selector marker' );
my ($interactive_selected) = $interactive_stdout =~ /^2:\s+(.*)$/m;
is( $captured_exec, "vim\n-p\n$interactive_selected", 'interactive open-file falls back to vim tabs and opens the selected match' );
is( $interactive_stderr, '', 'interactive open-file keeps stderr clean while prompting' );

eval {
    local *Developer::Dashboard::CLI::OpenFile::_command_exec = sub {
        $captured_exec = join "\n", @_;
        die "EXEC";
    };
    run_open_file_command(
        paths => $registry,
        args  => [ $notes_file ],
    );
};
like( $@, qr/^EXEC/, 'single-match open-file path reaches the exec hook' );
like( $captured_exec, qr/^vim\n-p\n\Q$notes_file\E$/m, 'single-match open-file falls back to vim tab mode when no editor is configured' );

my $blank_select_error = '';
my ( $blank_select_stdout, $blank_select_stderr ) = capture {
    local *Developer::Dashboard::CLI::OpenFile::_command_exec = sub {
        $captured_exec = join "\n", @_;
        die "EXEC";
    };
    open my $stdin_fh, '<', \"\n" or die 'Unable to open scalar stdin handle for blank selection';
    local *STDIN = $stdin_fh;
    eval {
        run_open_file_command(
            paths => $registry,
            args  => [ $project_root, 'alpha' ],
        );
    };
    $blank_select_error = $@;
};
like( $blank_select_error, qr/^EXEC/, 'blank interactive open-file selection reaches the exec hook' );
my @blank_exec = split /\n/, $captured_exec;
is( shift @blank_exec, 'vim', 'blank interactive open-file selection still targets vim' );
is( shift @blank_exec, '-p', 'blank interactive open-file selection uses vim tab mode' );
is_deeply( [ sort @blank_exec ], [ sort ( $notes_file, $duplicate_file ) ], 'blank interactive open-file selection falls back to opening all matches' );
is( $blank_select_stderr, '', 'blank interactive open-file selection keeps stderr clean' );
like( $blank_select_stdout, qr/> \z/, 'blank interactive open-file selection still renders the chooser prompt' );

my $multi_select_error = '';
my ( $multi_select_stdout, $multi_select_stderr ) = capture {
    local *Developer::Dashboard::CLI::OpenFile::_command_exec = sub {
        $captured_exec = join "\n", @_;
        die "EXEC";
    };
    open my $stdin_fh, '<', \"1,2\n" or die 'Unable to open scalar stdin handle for multi selection';
    local *STDIN = $stdin_fh;
    eval {
        run_open_file_command(
            paths => $registry,
            args  => [ $project_root, 'alpha' ],
        );
    };
    $multi_select_error = $@;
};
like( $multi_select_error, qr/^EXEC/, 'comma-separated interactive selection reaches the exec hook' );
my @multi_exec = split /\n/, $captured_exec;
is( shift @multi_exec, 'vim', 'comma-separated interactive selection still targets vim' );
is( shift @multi_exec, '-p', 'comma-separated interactive selection uses vim tab mode' );
is_deeply( [ sort @multi_exec ], [ sort ( $notes_file, $duplicate_file ) ], 'comma-separated interactive selection opens the chosen matches' );
is( $multi_select_stderr, '', 'comma-separated interactive selection keeps stderr clean' );
like( $multi_select_stdout, qr/> \z/, 'comma-separated interactive selection shows the chooser prompt' );

my $range_select_error = '';
my ( $range_select_stdout, $range_select_stderr ) = capture {
    local *Developer::Dashboard::CLI::OpenFile::_command_exec = sub {
        $captured_exec = join "\n", @_;
        die "EXEC";
    };
    open my $stdin_fh, '<', \"1-2\n" or die 'Unable to open scalar stdin handle for range selection';
    local *STDIN = $stdin_fh;
    eval {
        run_open_file_command(
            paths => $registry,
            args  => [ $project_root, 'alpha' ],
        );
    };
    $range_select_error = $@;
};
like( $range_select_error, qr/^EXEC/, 'range interactive selection reaches the exec hook' );
my @range_exec = split /\n/, $captured_exec;
is( shift @range_exec, 'vim', 'range interactive selection still targets vim' );
is( shift @range_exec, '-p', 'range interactive selection uses vim tab mode' );
is_deeply( [ sort @range_exec ], [ sort ( $notes_file, $duplicate_file ) ], 'range interactive selection opens the chosen range' );

ok( Developer::Dashboard::CLI::OpenFile::_editor_supports_tabs( command => ['vim'] ), 'vim supports tab-open mode' );
ok( Developer::Dashboard::CLI::OpenFile::_editor_supports_tabs( command => ['nvim'] ), 'nvim supports tab-open mode' );
ok( !Developer::Dashboard::CLI::OpenFile::_editor_supports_tabs( command => ['fake-editor'] ), 'non-vim editors do not receive tab-open mode' );
is( $range_select_stderr, '', 'range interactive selection keeps stderr clean' );
like( $range_select_stdout, qr/> \z/, 'range interactive selection shows the chooser prompt' );

eval {
    run_open_file_command( paths => $registry, args => [] );
};
like( $@, qr/^Usage: open-file/, 'open-file command rejects missing arguments' );

eval {
    run_open_file_command( paths => $registry, args => [ '--print', $project_root, 'missing-pattern' ] );
};
like( $@, qr/^No files found/, 'open-file command rejects unmatched searches' );

my $invalid_error = '';
my ($invalid_stdout) = capture {
    eval {
        open my $stdin_fh, '<', \"not-a-number\n" or die 'Unable to open scalar stdin handle for invalid selection';
        local *STDIN = $stdin_fh;
        run_open_file_command( paths => $registry, args => [ $project_root, 'alpha' ] );
    };
    $invalid_error = $@;
};
like( $invalid_error, qr/^Invalid file selection 'not-a-number'/, 'open-file rejects non-numeric interactive selections' );
like( $invalid_stdout, qr/> \z/, 'open-file invalid-selection path still renders the numbered prompt' );

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
    command => 'jq',
    text    => qq|{"alpha":{"beta":[1,2],"gamma":"ok"}}|,
);
is_deeply( $json_data, { alpha => { beta => [ 1, 2 ], gamma => 'ok' } }, 'JSON query parsing works' );

my $yaml_data = Developer::Dashboard::CLI::Query::_parse_query_input(
    command => 'yq',
    text    => "alpha:\n  beta: 3\n",
);
is_deeply( $yaml_data, { alpha => { beta => 3 } }, 'YAML query parsing works' );

my $toml_data = Developer::Dashboard::CLI::Query::_parse_query_input(
    command => 'tomq',
    text    => "[alpha]\nbeta = 4\n",
);
is_deeply( $toml_data, { alpha => { beta => 4 } }, 'TOML query parsing works' );

my $props_data = Developer::Dashboard::CLI::Query::_parse_query_input(
    command => 'propq',
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

my $scalar_return;
my ($scalar_stdout) = capture {
    $scalar_return = Developer::Dashboard::CLI::Query::_print_query_value('value');
};
ok( $scalar_return, 'scalar query output returns true' );
is( $scalar_stdout, "value\n", 'scalar query output prints a trailing newline' );

my $ref_return;
my ($ref_stdout) = capture {
    $ref_return = Developer::Dashboard::CLI::Query::_print_query_value( { answer => 42 } );
};
ok( $ref_return, 'ref query output returns true' );
is_deeply( json_decode($ref_stdout), { answer => 42 }, 'ref query output prints canonical JSON' );

my $query_error = '';
my ( $query_stdout, undef ) = capture {
    local *Developer::Dashboard::CLI::Query::_command_exit = sub { die "EXIT:$_[0]" };
    my $stdin_json = qq|{"alpha":{"beta":7}}|;
    open my $query_stdin, '<', \$stdin_json or die "Unable to open scalar query stdin: $!";
    local *STDIN = $query_stdin;
    eval {
        run_query_command(
            command => 'jq',
            args    => ['alpha.beta'],
        );
    };
    $query_error = $@;
};
like( $query_error, qr/^EXIT:0\b/, 'run_query_command exits through the test hook' );
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

15-cli-module-coverage.t - direct coverage tests for dashboard CLI helper modules

=head1 DESCRIPTION

This test exercises the in-process helper code behind the built-in
open-file and structured-data dashboard command paths so their library
coverage stays at 100%.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Test file in the Developer Dashboard codebase. This file covers CLI module branches not exercised by the broader smoke tests.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/15-cli-module-coverage.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

  prove -lv t/15-cli-module-coverage.t

Run that command while working on the behaviour this test owns, then rerun C<prove -lr t> before release.

=for comment FULL-POD-DOC END

=cut
