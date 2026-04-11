use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(chdir cwd);
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Response;
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
my $m2_source_jar = File::Spec->catfile(
    $ENV{HOME}, '.m2', 'repository', 'com', 'example', 'archive-demo', '1.0.0',
    'archive-demo-1.0.0-sources.jar',
);
make_path( File::Spec->catdir( $ENV{HOME}, '.m2', 'repository', 'com', 'example', 'archive-demo', '1.0.0' ) );
_write_zip_entries(
    $m2_source_jar,
    {
        'com/example/Archived.java' => "package com.example;\npublic class Archived {}\n",
    },
);
{
    my $original_cwd = cwd();
    chdir $project_root or die "Unable to chdir to $project_root: $!";
    my @archive_named = Developer::Dashboard::CLI::OpenFile::_named_source_matches(
        paths => $registry,
        name  => 'com.example.Archived',
    );
    ok( @archive_named, 'Java class lookup returns a match extracted from a local source archive when no .java file exists in the project tree' );
    like( $archive_named[0], qr{/\Qopen-file/java-sources/\E}, 'Java archive lookup extracts matching source files into the dashboard cache tree' );
    open my $archive_source_fh, '<', $archive_named[0] or die "Unable to read $archive_named[0]: $!";
    my $archive_source = do { local $/; <$archive_source_fh> };
    close $archive_source_fh;
    like( $archive_source, qr/public class Archived/, 'Java archive lookup preserves the extracted source content' );
    chdir $original_cwd or die "Unable to restore cwd to $original_cwd: $!";
}
{
    my $download_fixture = File::Spec->catfile( $ENV{HOME}, 'downloaded-sources.jar' );
    my $expected_downloaded_jar = File::Spec->catfile(
        $registry->cache_root,
        'open-file',
        'maven-sources',
        'javax',
        'jws',
        'javax.jws-api',
        '1.0.0',
        'javax.jws-api-1.0.0-sources.jar',
    );
    unlink $expected_downloaded_jar if -f $expected_downloaded_jar;
    _write_zip_entries(
        $download_fixture,
        {
            'javax/jws/WebService.java' => "package javax.jws;\npublic \@interface WebService {}\n",
        },
    );
    my $mirrored_url = '';
    no warnings 'redefine';
    local *LWP::UserAgent::get = sub {
        return HTTP::Response->new(
            200,
            'OK',
            [],
            qq|{"response":{"docs":[{"g":"javax.jws","a":"javax.jws-api","v":"1.0.0","ec":["-sources.jar"]}]}}|,
        );
    };
    local *LWP::UserAgent::mirror = sub {
        my ( $self, $url, $target ) = @_;
        $mirrored_url = $url;
        open my $source_fh, '<', $download_fixture or die "Unable to read $download_fixture: $!";
        my $payload = do { local $/; <$source_fh> };
        close $source_fh;
        open my $target_fh, '>', $target or die "Unable to write $target: $!";
        binmode $target_fh;
        print {$target_fh} $payload;
        close $target_fh;
        return HTTP::Response->new( 200, 'OK', [], '' );
    };

    my @download_docs = Developer::Dashboard::CLI::OpenFile::_maven_search_documents('javax.jws.WebService');
    is( scalar(@download_docs), 1, 'maven search helper returns parsed document rows from the search response' );
    is( $download_docs[0]{a}, 'javax.jws-api', 'maven search helper preserves artifact coordinates' );

    my $downloaded_jar = Developer::Dashboard::CLI::OpenFile::_download_maven_source_jar(
        paths => $registry,
        doc   => $download_docs[0],
    );
    ok( defined $downloaded_jar && -f $downloaded_jar, 'maven source-jar downloader mirrors the source archive into the dashboard cache' );
    is(
        $downloaded_jar,
        $expected_downloaded_jar,
        'maven source-jar downloader writes the mirrored archive to the expected cache path',
    );
    like(
        $mirrored_url,
        qr{\Ahttps://repo1\.maven\.org/maven2/javax/jws/javax\.jws-api/1\.0\.0/javax\.jws-api-1\.0\.0-sources\.jar\z},
        'maven source-jar downloader mirrors the expected Maven Central source-jar URL',
    );

    my @downloaded_named = Developer::Dashboard::CLI::OpenFile::_download_java_source_matches(
        paths    => $registry,
        name     => 'javax.jws.WebService',
        relative => File::Spec->catfile( 'javax', 'jws', 'WebService.java' ),
    );
    ok( @downloaded_named, 'download helper extracts a matching Java source file from a mirrored Maven source jar' );
    open my $downloaded_fh, '<', $downloaded_named[0] or die "Unable to read $downloaded_named[0]: $!";
    my $downloaded_source = do { local $/; <$downloaded_fh> };
    close $downloaded_fh;
    like( $downloaded_source, qr/public \@interface WebService/, 'downloaded Java source extraction preserves the fetched source content' );
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

my $scope_root = File::Spec->catdir( $project_root, 'jq-parent', 'scope-fixtures' );
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
my $scope_ok_js = File::Spec->catfile( $scope_js_root, 'ok.js' );
open my $scope_ok_js_fh, '>', $scope_ok_js or die "Unable to write $scope_ok_js: $!";
print {$scope_ok_js_fh} "window.ok = true;\n";
close $scope_ok_js_fh;
my $scope_ok_json = File::Spec->catfile( $scope_js_root, 'ok.json' );
open my $scope_ok_json_fh, '>', $scope_ok_json or die "Unable to write $scope_ok_json: $!";
print {$scope_ok_json_fh} "{\"ok\":true}\n";
close $scope_ok_json_fh;
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
    'scoped jq search ranks exact jq helper and jq.js ahead of jquery.js and ignores unrelated parent-path matches outside the chosen scope root',
);
my ( $scope_regex_line, @scope_regex_match ) = Developer::Dashboard::CLI::OpenFile::_resolve_open_file_matches(
    paths => $registry,
    args  => [ $scope_root, 'Ok\\.js$' ],
);
is( $scope_regex_line, 0, 'scoped regex search keeps line number at zero' );
is_deeply(
    \@scope_regex_match,
    [$scope_ok_js],
    'scoped regex search treats each pattern as a real regex and does not match ok.json for Ok\\.js$',
);
like(
    _dies(
        sub {
            Developer::Dashboard::CLI::OpenFile::_resolve_open_file_matches(
                paths => $registry,
                args  => [ $scope_root, 'broken(' ],
            );
        }
    ),
    qr/Invalid regex 'broken\('/,
    'open-file scope search reports invalid regex patterns explicitly',
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

my ( $path_c, $file_c ) = Developer::Dashboard::CLI::Query::_split_query_args( 'sort', 'keys', '%$d', $notes_file );
is( $path_c, 'sort keys %$d', 'query splitting rejoins split Perl-expression argv pieces into one query path' );
is( $file_c, $notes_file, 'query splitting still extracts the file path when Perl-expression argv pieces are split' );

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

my $xml_data = Developer::Dashboard::CLI::Query::_parse_query_input(
    command => 'xmlq',
    text    => '<root><value>demo</value><item id="1">x</item><item id="2">y</item></root>',
);
is_deeply(
    $xml_data,
    {
        root => {
            value => 'demo',
            item  => [
                { _attributes => { id => '1' }, _text => 'x' },
                { _attributes => { id => '2' }, _text => 'y' },
            ],
        },
    },
    'XML query parsing decodes the document into nested Perl data instead of returning only raw XML',
);

is( Developer::Dashboard::CLI::Query::_extract_query_path( $json_data, 'alpha.gamma' ), 'ok', 'nested hash extraction works' );
is( Developer::Dashboard::CLI::Query::_extract_query_path( $json_data, 'alpha.beta.1' ), 2, 'array extraction works' );
is( Developer::Dashboard::CLI::Query::_extract_query_path( { 'alpha.beta' => 9 }, 'alpha.beta' ), 9, 'exact dotted-key extraction works before segment splitting' );
is_deeply( Developer::Dashboard::CLI::Query::_extract_query_path( $json_data, '$d' ), $json_data, 'whole-document selector returns the full data structure' );
is( Developer::Dashboard::CLI::Query::_extract_query_path( $xml_data, 'root.item.1._attributes.id' ), '2', 'XML dotted-path extraction works against decoded XML attribute hashes' );

ok( !Developer::Dashboard::CLI::Query::_path_uses_perl_expression('$d.alpha.beta'), 'plain $d dotted selectors stay on the dotted-path traversal route' );
ok( !Developer::Dashboard::CLI::Query::_path_uses_perl_expression('.'), 'dot shorthand stays on the dotted-path traversal route' );
ok( Developer::Dashboard::CLI::Query::_path_uses_perl_expression('sort keys %$d'), 'paths that use $d as a Perl expression are detected for eval handling' );

is_deeply(
    Developer::Dashboard::CLI::Query::_select_query_value( $json_data, '' ),
    $json_data,
    'query selection returns the whole document for an empty query path',
);

my $query_expression_scalar = Developer::Dashboard::CLI::Query::_select_query_value( $json_data, '$d->{alpha}{gamma}' );
is( $query_expression_scalar, 'ok', 'query selection evaluates scalar Perl expressions against decoded data' );

my $query_expression_list = Developer::Dashboard::CLI::Query::_select_query_value( { foo => [ 1, 2 ], bar => [ 3 ] }, 'sort keys %$d' );
is_deeply( $query_expression_list, [ 'bar', 'foo' ], 'query selection preserves list-valued Perl expressions as arrays' );

my $query_expression_single_list = Developer::Dashboard::CLI::Query::_select_query_value( { alpha => { beta => 2 } }, 'sort keys %$d' );
is_deeply( $query_expression_single_list, ['alpha'], 'query selection keeps one-item list expressions as arrays instead of collapsing them to scalars' );

my $query_expression_empty = Developer::Dashboard::CLI::Query::_select_query_value( $json_data, 'grep { $_ eq q(nope) } sort keys %$d' );
is_deeply( $query_expression_empty, [], 'query selection preserves empty list Perl-expression results as empty arrays' );

my $query_expression_plain_empty = Developer::Dashboard::CLI::Query::_select_query_value( $json_data, 'do { my $copy = $d; () }' );
is_deeply( $query_expression_plain_empty, [], 'query selection returns an empty array for non-list-preferring Perl expressions that yield no values' );

my $query_expression_join = Developer::Dashboard::CLI::Query::_select_query_value( { foo => [ 7, 8 ] }, 'join q(-), @{ $d->{foo} }' );
is( $query_expression_join, '7-8', 'query selection keeps join-based Perl expressions scalar even though they contain list operators internally' );

my $query_expression_zero = Developer::Dashboard::CLI::Query::_select_query_value( $json_data, 'scalar grep { $_ eq q(nope) } sort keys %$d' );
is( $query_expression_zero, 0, 'query selection preserves scalar Perl-expression results without turning them into empty arrays' );

my $query_expression_error = _dies(
    sub {
        Developer::Dashboard::CLI::Query::_select_query_value( $json_data, 'do { my $x = $d->{missing}; die q(nope) }' );
    }
);
like( $query_expression_error, qr/Query expression .* failed:/, 'query selection surfaces Perl-expression failures clearly' );

my $query_expression_compile_error = _dies(
    sub {
        Developer::Dashboard::CLI::Query::_select_query_value( $json_data, '$d->{' );
    }
);
like( $query_expression_compile_error, qr/Query expression .* failed:/, 'query selection surfaces Perl-expression compile failures clearly' );

my $xml_tree_error = _dies(
    sub {
        Developer::Dashboard::CLI::Query::_xml_tree_to_data('nope');
    }
);
like( $xml_tree_error, qr/XML tree must be an array reference/, 'XML tree decoding dies clearly for invalid tree inputs' );

my $xml_payload_error = _dies(
    sub {
        Developer::Dashboard::CLI::Query::_xml_element_payload('nope');
    }
);
like( $xml_payload_error, qr/XML element payload must be an array reference/, 'XML payload decoding dies clearly for invalid payload inputs' );

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

sub _dies {
    my ($code) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    return $error;
}

sub _write_zip_entries {
    my ( $archive, $entries ) = @_;
    my $zip = Archive::Zip->new();
    for my $name ( sort keys %{$entries || {}} ) {
        $zip->addString( $entries->{$name}, $name );
    }
    my $status = $zip->writeToFileNamed($archive);
    die "Unable to write $archive\n" if $status != AZ_OK;
    return 1;
}

__END__

=head1 NAME

15-cli-module-coverage.t - direct coverage tests for dashboard CLI helper modules

=head1 DESCRIPTION

This test exercises the in-process helper code behind the built-in
open-file and structured-data dashboard command paths so their library
coverage stays at 100%.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the hard-to-hit branches that keep library coverage honest. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the hard-to-hit branches that keep library coverage honest has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the hard-to-hit branches that keep library coverage honest, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/15-cli-module-coverage.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/15-cli-module-coverage.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/15-cli-module-coverage.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
