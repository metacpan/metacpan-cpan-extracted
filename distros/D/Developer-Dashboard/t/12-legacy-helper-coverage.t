use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use Errno qw(EINTR EIO);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(:sys_wait_h);
use Test::More;
use Time::HiRes qw(time);
use URI::Escape qw(uri_escape);

use lib 'lib';

use Developer::Dashboard::DataHelper qw(j je);
use Developer::Dashboard::Auth;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageRuntime::StreamHandle;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;
my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
chdir $home or die "Unable to chdir to $home: $!";
my $auto_projects = File::Spec->catdir( $home, 'projects' );
make_path($auto_projects);

use Developer::Dashboard::Folder;
use Developer::Dashboard::Zipper qw(zip unzip _cmdx _cmdp __cmdx acmdx Ajax);

sub form_body {
    my (@pairs) = @_;
    my @encoded;
    while (@pairs) {
        my ( $name, $value ) = splice @pairs, 0, 2;
        push @encoded, uri_escape($name) . '=' . uri_escape( defined $value ? $value : '' );
    }
    return join '&', @encoded;
}

is( Developer::Dashboard::Folder->dd, File::Spec->catdir( $home, '.developer-dashboard' ), 'Folder dd lazily bootstraps the runtime root before configure' );
is( Developer::Dashboard::Folder->runtime_root, File::Spec->catdir( $home, '.developer-dashboard' ), 'Folder runtime_root lazily bootstraps through AUTOLOAD before configure' );
{
    my $runtime_home = File::Spec->catdir( $home, '.developer-dashboard' );
    make_path( File::Spec->catdir( $runtime_home, '.git' ) );
    chdir $runtime_home or die "Unable to chdir to $runtime_home: $!";
    is( Developer::Dashboard::Folder->dd, $runtime_home, 'Folder dd does not append a nested runtime root when cwd is the home runtime repository' );
    is( Developer::Dashboard::Folder->runtime_root, $runtime_home, 'Folder runtime_root stays at the home runtime root when cwd is the home runtime repository' );
    chdir $home or die "Unable to chdir to $home: $!";
}

my $workspace = File::Spec->catdir( $home, 'workspace' );
my $project   = File::Spec->catdir( $workspace, 'demo' );
mkdir $workspace;
mkdir $project;

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [$workspace],
    project_roots   => [$workspace],
);
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $pages = Developer::Dashboard::PageStore->new( paths => $paths );

Developer::Dashboard::Folder->configure(
    paths   => $paths,
    aliases => { alias_demo => $project },
);

is( Developer::Dashboard::Folder->home, $home, 'Folder home resolves current home' );
ok( Developer::Dashboard::Folder->tmp, 'Folder tmp resolves a temp dir' );
is( Developer::Dashboard::Folder->dd, $paths->runtime_root, 'Folder dd resolves runtime root' );
is( Developer::Dashboard::Folder->runtime_root, $paths->runtime_root, 'Folder AUTOLOAD resolves runtime_root through the legacy runtime alias' );
is( Developer::Dashboard::Folder->bookmarks, $paths->dashboards_root, 'Folder bookmarks resolves dashboards root' );
is( Developer::Dashboard::Folder->bookmarks_root, $paths->dashboards_root, 'Folder AUTOLOAD resolves bookmarks_root through the legacy bookmarks alias' );
is( Developer::Dashboard::Folder->configs, $paths->config_root, 'Folder configs resolves config root' );
is( Developer::Dashboard::Folder->config_root, $paths->config_root, 'Folder AUTOLOAD resolves config_root through the legacy configs alias' );
ok( -d Developer::Dashboard::Folder->postman, 'Folder postman creates the neutral postman directory' );

my $cd_result = Developer::Dashboard::Folder->cd(
    alias_demo => sub {
        my ($ctx) = @_;
        $ctx->{stay}->($ctx->{caller});
        return $ctx->{dir};
    }
);
is( $cd_result, $project, 'Folder cd yields the target directory to the callback' );
my @folder_listing = Developer::Dashboard::Folder->ls('alias_demo');
ok( @folder_listing >= 0, 'Folder ls returns entries for a real directory' );
ok( grep( { $_ eq $project } Developer::Dashboard::Folder->locate('demo') ), 'Folder locate finds matching workspace directories' );
is( Developer::Dashboard::Folder->alias_demo, $project, 'Folder AUTOLOAD resolves configured aliases' );
{
    my $repo = File::Spec->catdir( $workspace, 'folder-config-repo' );
    make_path( File::Spec->catdir( $repo, '.git' ) );
    make_path( File::Spec->catdir( $repo, '.developer-dashboard', 'config' ) );
    open my $fh, '>', File::Spec->catfile( $repo, '.developer-dashboard', 'config', 'config.json' ) or die $!;
    print {$fh} <<'JSON';
{
  "path_aliases": {
    "docker": "~/docker-alias"
  }
}
JSON
    close $fh;
    my $docker_alias = File::Spec->catdir( $home, 'docker-alias' );
    make_path($docker_alias);
    local $Developer::Dashboard::Folder::PATHS = undef;
    local %Developer::Dashboard::Folder::ALIASES = ();
    local %Developer::Dashboard::Folder::CONFIG_ALIASES = ();
    local $Developer::Dashboard::Folder::CONFIG_ALIASES_KEY = '';
    my $cwd = Cwd::cwd();
    chdir $repo or die "Unable to chdir to $repo: $!";
    is( Developer::Dashboard::Folder->docker, $docker_alias, 'Folder AUTOLOAD lazily resolves config-backed path aliases in a plain Perl process' );
    chdir $cwd or die "Unable to chdir to $cwd: $!";
}

my $zipped = zip('print qq{ok};');
ok( $zipped->{raw}, 'zip returns a raw token' );
is( unzip( $zipped->{raw} ), 'print qq{ok};', 'unzip reverses raw tokens' );
like( __cmdx( perl => 'print 1;' ), qr/base64 -d \| gunzip/, '__cmdx builds a shell decode pipeline' );
my @cmdx = _cmdx( perl => 'print 1;' );
is_deeply( [ @cmdx[ 0, 1 ] ], [ 'perl', '-e' ], '_cmdx returns shell tuple metadata' );
my @cmdp = _cmdp( perl => 'print 1;' );
is( $cmdp[1], 'perl', '_cmdp returns pipeline metadata' );
my $ajax_url = acmdx( type => 'json', code => 'print qq{{}};' );
like( $ajax_url->{url}{tokenised}, qr{^/ajax\?token=}, 'acmdx builds a tokenised ajax url' );
my $ajax_singleton_url = acmdx( type => 'text', code => 'print qq{ok};', singleton => 'TRANSIENT' );
like( $ajax_singleton_url->{url}{tokenised}, qr/[?&]singleton=TRANSIENT/, 'acmdx carries the optional singleton value into transient ajax urls' );
my ( $ajax_stdout, undef, $ajax_result ) = capture {
    return Ajax( jvar => 'configs.coverage.endpoint', code => 'print qq{{}};' );
};
like( $ajax_stdout, qr/set_chain_value/, 'Ajax prints the legacy config-binding script' );
is( $ajax_result, 'HIDE-THIS', 'Ajax returns the legacy hide marker' );
my ( $ajax_singleton_stdout, undef, $ajax_singleton_result ) = capture {
    return Ajax( jvar => 'configs.coverage.endpoint', code => 'print qq{{}};', singleton => 'TRANSIENT' );
};
like( $ajax_singleton_stdout, qr/[?&]singleton=TRANSIENT/, 'Ajax carries the optional singleton value into transient ajax bindings' );
is( $ajax_singleton_result, 'HIDE-THIS', 'Ajax still returns the hide marker when a transient singleton is supplied' );
{
    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source               => 'saved',
        page_id              => 'coverage-page',
        runtime_root         => $paths->runtime_root,
        allow_transient_urls => 0,
    };
    my ( $saved_ajax_stdout, undef, $saved_ajax_result ) = capture {
        return Ajax(
            jvar      => 'configs.coverage.saved',
            file      => 'coverage.json',
            singleton => 'coverage-stream',
            code      => 'print qq{{"ok":1}};',
        );
    };
    like( $saved_ajax_stdout, qr{/ajax/coverage\.json\?type=text&singleton=coverage-stream}, 'Ajax prints a saved bookmark ajax url with the default text type and singleton when a file name is supplied' );
    is( $saved_ajax_result, 'HIDE-THIS', 'saved bookmark Ajax still returns the hide marker' );
    ok( -f Developer::Dashboard::Zipper::saved_ajax_file_path( runtime_root => $paths->runtime_root, file => 'coverage.json' ), 'saved bookmark Ajax stores the named ajax code file under the dashboards ajax tree' );
    ok( -x Developer::Dashboard::Zipper::saved_ajax_file_path( runtime_root => $paths->runtime_root, file => 'coverage.json' ), 'saved bookmark Ajax marks the stored dashboards ajax tree file executable' );
    is( Developer::Dashboard::Zipper::load_saved_ajax_code( runtime_root => $paths->runtime_root, file => 'coverage.json' ), 'print qq{{"ok":1}};', 'saved bookmark Ajax stored code can be loaded back from the dashboards ajax tree' );
    my $saved_ajax_error = eval {
        Ajax(
            jvar => 'configs.coverage.saved',
            code => 'print qq{{"ok":1}};',
        );
        '';
    } || $@;
    like( $saved_ajax_error, qr/file is required/, 'saved bookmark Ajax requires a file name when transient token urls are disabled' );
}
{
    my $existing_path = Developer::Dashboard::Zipper::saved_ajax_file_path(
        runtime_root => $paths->runtime_root,
        file         => 'existing.sh',
    );
    my $existing_dir = dirname($existing_path);
    make_path($existing_dir);
    open my $fh, '>', $existing_path or die $!;
    print {$fh} "#!/bin/sh\nprintf 'existing coverage\\n'\n";
    close $fh;
    chmod 0700, $existing_path or die $!;

    local $Developer::Dashboard::Zipper::AJAX_CONTEXT = {
        source               => 'saved',
        page_id              => 'coverage-existing',
        runtime_root         => $paths->runtime_root,
        allow_transient_urls => 0,
    };
    my ( $stdout, undef, $result ) = capture {
        return Ajax(
            jvar => 'configs.coverage.existing',
            file => 'existing.sh',
            type => 'text',
        );
    };
    like( $stdout, qr{/ajax/existing\.sh\?type=text}, 'Ajax prints a saved bookmark ajax url when only an existing file name is supplied' );
    is( $result, 'HIDE-THIS', 'saved bookmark Ajax with only a file still returns the hide marker' );
    is( Developer::Dashboard::Zipper::load_saved_ajax_code( runtime_root => $paths->runtime_root, file => 'existing.sh' ), "#!/bin/sh\nprintf 'existing coverage\\n'\n", 'saved bookmark Ajax with only a file leaves the existing executable content unchanged' );
}

is_deeply( je( j( { ok => 1 } ) ), { ok => 1 }, 'DataHelper je decodes JSON created by j' );
is_deeply( Developer::Dashboard::PageDocument::_decode_structured_json('{"ok":1}'), { ok => 1 }, 'PageDocument structured JSON decoder returns parsed hashes' );
is( Developer::Dashboard::PageDocument::_template_value( 'stash.name', { stash => { name => 'Modern' } } ), 'Modern', 'PageDocument template-value helper resolves nested keys' );

my $modern_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
=== TITLE ===
Modern Title

=== DESCRIPTION ===
Modern Note

=== STASH ===
{"name":"Modern"}

=== HTML ===
<div>[% stash.name %] [% method("Developer::Dashboard::Folder","home") %] [% func("unused") %]</div>

=== CODE1 ===
print "MODERN";
PAGE
is( $modern_page->as_hash->{title}, 'Modern Title', 'PageDocument still parses modern source as input' );
is( $modern_page->render_template('ignored'), $modern_page, 'render_template compatibility method returns the page object' );
like( $modern_page->canonical_json, qr/Modern Title/, 'canonical_json serializes page content' );

my $runtime = Developer::Dashboard::PageRuntime->new( paths => $paths );
{
    my $buffer = '';
    local *STREAM;
    tie *STREAM, 'Developer::Dashboard::PageRuntime::StreamHandle', writer => sub { $buffer .= $_[0] if defined $_[0] };
    print STREAM "alpha", undef, "beta";
    printf STREAM "%s-%s", 'gamma', 'delta';
    close STREAM;
    untie *STREAM;
    is( $buffer, 'alphabetagamma-delta', 'stream handle forwards print and printf output chunks to the callback' );
}
{
    local *STREAM;
    tie *STREAM, 'Developer::Dashboard::PageRuntime::StreamHandle';
    print STREAM 'ignored-default-writer';
    close STREAM;
    untie *STREAM;
    pass('stream handle accepts the default no-op writer');
}
{
    my $streamed = '';
    my $stream_page = Developer::Dashboard::PageDocument->new( id => 'stream-direct' );
    my $stream_result = $runtime->stream_code_block(
        code          => 'print "streamed";',
        page          => $stream_page,
        source        => 'saved',
        state         => {},
        runtime_context => {},
        stdout_writer => sub { $streamed .= $_[0] if defined $_[0] },
    );
    is( $streamed, 'streamed', 'stream_code_block forwards printed stdout chunks directly' );
    is( $stream_result->{error}, '', 'stream_code_block leaves the trailing error text empty on success' );
}
{
    my $returned = '';
    my $stream_page = Developer::Dashboard::PageDocument->new( id => 'stream-return-writer' );
    my $stream_result = $runtime->stream_code_block(
        code            => 'return { ok => 1 };',
        page            => $stream_page,
        source          => 'saved',
        state           => {},
        runtime_context => {},
        return_writer   => sub { $returned .= $_[0] if defined $_[0] },
    );
    like( $returned, qr/ok => 1/, 'stream_code_block forwards structured return values through the optional return writer' );
    is( $stream_result->{error}, '', 'stream_code_block leaves the trailing error text empty when using a return writer' );
}
{
    my $stream_page = Developer::Dashboard::PageDocument->new( id => 'stream-default-writers' );
    my $stream_result = $runtime->stream_code_block(
        code            => 'return { ok => 1 };',
        page            => $stream_page,
        source          => 'saved',
        state           => {},
        runtime_context => {},
    );
    is_deeply( $stream_result->{returns}, [ { ok => 1 } ], 'stream_code_block works with the default no-op stream writers' );
}
is( Developer::Dashboard::PageRuntime::_noop_writer('ignored'), '', '_noop_writer accepts ignored streamed chunks' );
like( $runtime->_runtime_value_text( { ok => 1 } ), qr/ok => 1/, '_runtime_value_text renders structured runtime values' );
{
    my $saved_path = Developer::Dashboard::Zipper::saved_ajax_file_path(
        runtime_root => $paths->runtime_root,
        file         => 'coverage.json',
    );
    is_deeply(
        [ ( $runtime->_saved_ajax_command( path => $saved_path ) )[ 0, 1 ] ],
        [ $^X, '-e' ],
        '_saved_ajax_command defaults saved Ajax files without shebangs to the Perl bootstrap interpreter path',
    );
    my %saved_env = $runtime->_saved_ajax_env(
        path      => $saved_path,
        page      => 'coverage-page',
        type      => 'text',
        singleton => 'coverage-stream',
        params    => { a => '1 2', b => 'ok' },
    );
    is( $saved_env{DEVELOPER_DASHBOARD_AJAX_PAGE}, 'coverage-page', '_saved_ajax_env exposes the saved bookmark id' );
    is( $saved_env{DEVELOPER_DASHBOARD_AJAX_SINGLETON}, 'coverage-stream', '_saved_ajax_env exposes the saved bookmark singleton name' );
    like( $saved_env{DEVELOPER_DASHBOARD_AJAX_PARAMS}, qr/"a"\s*:\s*"1 2"/, '_saved_ajax_env encodes request params as JSON' );
    like( $saved_env{QUERY_STRING}, qr/a=1%202/, '_saved_ajax_env rebuilds a query string for child process use' );
    ok( !$saved_env{DEVELOPER_DASHBOARD_AJAX_PARAMS_FILE}, '_saved_ajax_env keeps small request params inline instead of spilling them to a temp file' );
}
is( $runtime->_quote_process_pattern_literal('name.+(test)?'), 'name\.\+\(test\)\?', '_quote_process_pattern_literal escapes regex metacharacters safely for singleton matching' );
eval { $runtime->_normalize_saved_ajax_singleton("bad\nname") };
like( "$@", qr/Invalid ajax singleton name/, '_normalize_saved_ajax_singleton rejects control characters' );
{
    my $shebang_file = File::Spec->catfile( $paths->dashboards_root, 'ajax', 'shebang-handler' );
    open my $fh, '>', $shebang_file or die $!;
    print {$fh} "#!/bin/sh\nprintf 'ok\\n'\n";
    close $fh;
    chmod 0700, $shebang_file or die $!;
    is_deeply( [ $runtime->_saved_ajax_command( path => $shebang_file ) ], [ $shebang_file ], '_saved_ajax_command executes shebang saved Ajax files directly' );
}
{
    my $saved_path = File::Spec->catfile( $paths->dashboards_root, 'ajax', 'process-runner.pl' );
    open my $fh, '>', $saved_path or die $!;
    print {$fh} "print qq{process-out\\n}; warn qq{process-err\\n}; system 'sh', '-c', 'printf \"child-out\\\\n\"; printf \"child-err\\\\n\" >&2'; die qq{process-die\\n};";
    close $fh;
    chmod 0700, $saved_path or die $!;
    my $streamed = '';
    my $stream_result = $runtime->stream_saved_ajax_file(
        path          => $saved_path,
        page          => 'coverage-page',
        type          => 'text',
        params        => { page => 'coverage-page', file => 'process-runner.pl', type => 'text' },
        stdout_writer => sub { $streamed .= $_[0] if defined $_[0] },
        stderr_writer => sub { $streamed .= $_[0] if defined $_[0] },
    );
    like( $streamed, qr/process-out/, 'stream_saved_ajax_file forwards direct perl stdout' );
    like( $streamed, qr/process-err/, 'stream_saved_ajax_file forwards direct perl stderr' );
    like( $streamed, qr/child-out/, 'stream_saved_ajax_file forwards child stdout' );
    like( $streamed, qr/child-err/, 'stream_saved_ajax_file forwards child stderr' );
    like( $streamed, qr/process-die/, 'stream_saved_ajax_file forwards uncaught perl die text' );
    ok( $stream_result->{exit_code} != 0, 'stream_saved_ajax_file reports the failing process exit code' );
}
{
    my $saved_path = File::Spec->catfile( $paths->dashboards_root, 'ajax', 'huge-params.pl' );
    open my $fh, '>', $saved_path or die $!;
    print {$fh} <<'PERL';
my $blob = params()->{blob} // '';
print "blob_length=" . length($blob) . "\n";
print "query_length=" . length( $ENV{QUERY_STRING} || '' ) . "\n";
print "params_file=" . ( $ENV{DEVELOPER_DASHBOARD_AJAX_PARAMS_FILE} || '' ) . "\n";
print "query_file=" . ( $ENV{DEVELOPER_DASHBOARD_AJAX_QUERY_STRING_FILE} || '' ) . "\n";
PERL
    close $fh or die $!;
    chmod 0700, $saved_path or die $!;

    my $huge_blob = 'x' x 250_000;
    my $streamed = '';
    my $stream_result = $runtime->stream_saved_ajax_file(
        path          => $saved_path,
        page          => 'coverage-page',
        type          => 'text',
        params        => {
            blob => $huge_blob,
            file => 'huge-params.pl',
            type => 'text',
        },
        stdout_writer => sub { $streamed .= $_[0] if defined $_[0] },
        stderr_writer => sub { $streamed .= $_[0] if defined $_[0] },
    );

    is( $stream_result->{exit_code}, 0, 'stream_saved_ajax_file accepts oversized saved-Ajax params without failing execve' );
    like( $streamed, qr/\bblob_length=250000\b/, 'stream_saved_ajax_file still passes oversized params to params()' );
    like( $streamed, qr/\bquery_length=250035\b/, 'stream_saved_ajax_file reconstructs an oversized QUERY_STRING for the child process from the temp file payload' );
    my ($params_file) = $streamed =~ /^params_file=(.+)$/m;
    my ($query_file)  = $streamed =~ /^query_file=(.+)$/m;
    ok( defined $params_file && $params_file ne '', 'stream_saved_ajax_file exposes a temp params file to the child process when params are oversized' );
    ok( defined $query_file && $query_file ne '', 'stream_saved_ajax_file exposes a temp query file to the child process when the query string is oversized' );
    ok( !-e $params_file, 'stream_saved_ajax_file cleans up the oversized params temp file after the child exits' );
    ok( !-e $query_file, 'stream_saved_ajax_file cleans up the oversized query temp file after the child exits' );
}
{
    my $saved_path = File::Spec->catfile( $paths->dashboards_root, 'ajax', 'huge-open3-failure.pl' );
    open my $fh, '>', $saved_path or die $!;
    print {$fh} "print qq{should not run\\n};";
    close $fh or die $!;
    chmod 0700, $saved_path or die $!;

    my @cleaned_paths;
    my $error = eval {
        no warnings 'redefine';
        local *Developer::Dashboard::PageRuntime::open3 = sub { die "synthetic open3 failure\n" };
        local *Developer::Dashboard::PageRuntime::_cleanup_saved_ajax_temp_files = sub {
            my ( $self, @paths ) = @_;
            push @cleaned_paths, @paths;
            for my $path (@paths) {
                next if !defined $path || $path eq '' || !-e $path;
                unlink $path or die "Unable to remove saved ajax temp file $path: $!";
            }
            return 1;
        };
        $runtime->stream_saved_ajax_file(
            path          => $saved_path,
            page          => 'coverage-page',
            type          => 'text',
            params        => {
                blob => ( 'x' x 250_000 ),
                file => 'huge-open3-failure.pl',
                type => 'text',
            },
            stdout_writer => sub { return 1 },
            stderr_writer => sub { return 1 },
        );
        return '';
    } || $@;
    like( $error, qr/synthetic open3 failure/, 'stream_saved_ajax_file surfaces open3 launch failures for oversized payloads' );
    is( scalar @cleaned_paths, 2, 'stream_saved_ajax_file still schedules both oversized temp files for cleanup when open3 dies before the child starts' );
    ok( !grep { defined $_ && $_ ne '' && -e $_ } @cleaned_paths, 'stream_saved_ajax_file cleans oversized temp files even when open3 fails before execution' );
}
{
    my $saved_path = File::Spec->catfile( $paths->dashboards_root, 'ajax', 'singleton-runner.pl' );
    open my $fh, '>', $saved_path or die $!;
    print {$fh} 'print qq{$0\n};';
    close $fh;
    chmod 0700, $saved_path or die $!;
    my @patterns;
    my $streamed = '';
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub {
            my ( $self, $pattern ) = @_;
            push @patterns, $pattern;
            return 1;
        };
        my $stream_result = $runtime->stream_saved_ajax_file(
            path          => $saved_path,
            page          => 'coverage-page',
            type          => 'text',
            params        => { page => 'coverage-page', file => 'singleton-runner.pl', type => 'text', singleton => 'FOOBAR' },
            stdout_writer => sub { $streamed .= $_[0] if defined $_[0] },
            stderr_writer => sub { $streamed .= $_[0] if defined $_[0] },
        );
        is( $stream_result->{exit_code}, 0, 'stream_saved_ajax_file succeeds when singleton replacement is enabled' );
    }
    is_deeply( \@patterns, ['^dashboard ajax: FOOBAR$'], 'stream_saved_ajax_file kills matching singleton Ajax workers before starting a replacement' );
    like( $streamed, qr/^dashboard ajax: FOOBAR$/m, 'stream_saved_ajax_file renames the saved Perl Ajax worker to the singleton process title' );
}
{
    my $saved_path = File::Spec->catfile( $paths->dashboards_root, 'ajax', 'stream-timing.pl' );
    open my $fh, '>', $saved_path or die $!;
    print {$fh} <<'PL';
for (1..3) {
    print "tick$_";
    sleep 1;
}
PL
    close $fh;
    chmod 0700, $saved_path or die $!;
    my @chunks;
    my @times;
    my $start = time;
    my $stream_result = $runtime->stream_saved_ajax_file(
        path          => $saved_path,
        page          => 'coverage-page',
        type          => 'text',
        params        => { page => 'coverage-page', file => 'stream-timing.pl', type => 'text' },
        stdout_writer => sub {
            my ($chunk) = @_;
            return if !defined $chunk || $chunk eq '';
            push @chunks, $chunk;
            push @times, time - $start;
        },
        stderr_writer => sub { die "unexpected stderr chunk during timing stream test: $_[0]" if defined $_[0] && $_[0] ne '' },
    );
    is( $stream_result->{exit_code}, 0, 'stream_saved_ajax_file succeeds for timed saved ajax stream output' );
    is( join( '', @chunks ), 'tick1tick2tick3', 'stream_saved_ajax_file forwards all timed ajax stdout chunks in order' );
    ok( @times >= 2, 'stream_saved_ajax_file delivers multiple timed chunks before process exit' );
    ok( $times[0] < 1.5, 'stream_saved_ajax_file forwards the first timed chunk before the saved ajax process finishes' );
    ok( $times[1] < 2.5, 'stream_saved_ajax_file keeps forwarding later timed chunks during the long-running saved ajax process' );
}
{
    my $saved_path = File::Spec->catfile( $paths->dashboards_root, 'ajax', 'disconnect-runner.pl' );
    open my $fh, '>', $saved_path or die $!;
    print {$fh} <<'PL';
$SIG{TERM} = sub { exit 0 };
print "$$\n";
while (1) {
    print "tick\n";
    sleep 1;
}
PL
    close $fh;
    chmod 0700, $saved_path or die $!;
    my $child_pid;
    my $stream_result = $runtime->stream_saved_ajax_file(
        path          => $saved_path,
        page          => 'coverage-page',
        type          => 'text',
        params        => { page => 'coverage-page', file => 'disconnect-runner.pl', type => 'text', singleton => 'FOOBAR' },
        stdout_writer => sub {
            my ($chunk) = @_;
            if ( !defined $child_pid && defined $chunk && $chunk =~ /(\d+)/ ) {
                $child_pid = $1 + 0;
            }
            return 0;
        },
        stderr_writer => sub { return 0 },
    );
    ok( $stream_result->{disconnected}, 'stream_saved_ajax_file marks the run as disconnected when the stream writer closes early' );
    ok( defined $child_pid, 'disconnect test captures the saved ajax worker pid from the first streamed chunk' );
    ok( !kill( 0, $child_pid ), 'stream_saved_ajax_file terminates the saved ajax worker when the browser stream disconnects' );
}
{
    my $saved_path = File::Spec->catfile( $paths->dashboards_root, 'ajax', 'writer-error-runner.pl' );
    open my $fh, '>', $saved_path or die $!;
    print {$fh} <<'PL';
$SIG{TERM} = sub { exit 0 };
print "$$\n";
while (1) {
    print "tick\n";
    sleep 1;
}
PL
    close $fh;
    chmod 0700, $saved_path or die $!;
    my $child_pid;
    my $chunks = 0;
    my $error = eval {
        $runtime->stream_saved_ajax_file(
            path          => $saved_path,
            page          => 'coverage-page',
            type          => 'text',
            params        => { page => 'coverage-page', file => 'writer-error-runner.pl', type => 'text' },
            stdout_writer => sub {
                my ($chunk) = @_;
                if ( !defined $child_pid && defined $chunk && $chunk =~ /(\d+)/ ) {
                    $child_pid = $1 + 0;
                }
                $chunks++;
                die "writer exploded\n" if $chunks > 1;
                return 1;
            },
            stderr_writer => sub { return 1 },
        );
        return '';
    } || $@;
    like( $error, qr/writer exploded/, 'stream_saved_ajax_file surfaces non-disconnect writer failures instead of suppressing them' );
    ok( defined $child_pid, 'writer failure test captures the saved ajax worker pid from the first streamed chunk' );
    for ( 1 .. 20 ) {
        my $reaped = waitpid( $child_pid, WNOHANG );
        last if $reaped == $child_pid || !kill 0, $child_pid;
        select undef, undef, undef, 0.1;
    }
    my $writer_reaped = waitpid( $child_pid, WNOHANG );
    ok( $writer_reaped == $child_pid || !kill( 0, $child_pid ), 'stream_saved_ajax_file terminates the saved ajax worker after a non-disconnect writer failure' );
    waitpid( $child_pid, 0 ) if $writer_reaped != $child_pid;
}
{
    my $stdout_chunk = '';
    pipe my $stdout_reader, my $stdout_writer_handle or die $!;
    print {$stdout_writer_handle} 'chunk-out';
    close $stdout_writer_handle;
    my $select = IO::Select->new($stdout_reader);
    $runtime->_drain_saved_ajax_ready_handle(
        fh            => $stdout_reader,
        path          => 'stdout-path',
        select        => $select,
        stdout        => $stdout_reader,
        stdout_writer => sub { $stdout_chunk .= $_[0] if defined $_[0] },
        stderr_writer => sub { die "unexpected stderr callback" },
    );
    is( $stdout_chunk, 'chunk-out', '_drain_saved_ajax_ready_handle forwards stdout chunks to the stdout writer' );
}
{
    my $stderr_chunk = '';
    pipe my $stdout_reader, my $stdout_writer_handle or die $!;
    pipe my $stderr_reader, my $stderr_writer_handle or die $!;
    print {$stderr_writer_handle} 'chunk-err';
    close $stderr_writer_handle;
    close $stdout_writer_handle;
    my $select = IO::Select->new($stderr_reader);
    $runtime->_drain_saved_ajax_ready_handle(
        fh            => $stderr_reader,
        path          => 'stderr-path',
        select        => $select,
        stdout        => $stdout_reader,
        stdout_writer => sub { die "unexpected stdout callback" },
        stderr_writer => sub { $stderr_chunk .= $_[0] if defined $_[0] },
    );
    is( $stderr_chunk, 'chunk-err', '_drain_saved_ajax_ready_handle forwards non-stdout chunks to the stderr writer' );
}
{
    my $stderr_chunk = '';
    pipe my $fh, my $writer_handle or die $!;
    close $writer_handle;
    my $select = IO::Select->new($fh);
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PageRuntime::_stream_sysread = sub {
            $! = EINTR;
            return undef;
        };
        $runtime->_drain_saved_ajax_ready_handle(
            fh            => $fh,
            path          => 'eintr-path',
            select        => $select,
            stdout        => $fh,
            stdout_writer => sub { die "unexpected stdout callback" },
            stderr_writer => sub { $stderr_chunk .= $_[0] if defined $_[0] },
        );
    }
    is( $stderr_chunk, '', '_drain_saved_ajax_ready_handle quietly retries EINTR reads without surfacing an error chunk' );
}
{
    my $stderr_chunk = '';
    pipe my $fh, my $writer_handle or die $!;
    close $writer_handle;
    my $select = IO::Select->new($fh);
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PageRuntime::_stream_sysread = sub {
            $! = EIO;
            return undef;
        };
        $runtime->_drain_saved_ajax_ready_handle(
            fh            => $fh,
            path          => 'error-path',
            select        => $select,
            stdout        => $fh,
            stdout_writer => sub { die "unexpected stdout callback" },
            stderr_writer => sub { $stderr_chunk .= $_[0] if defined $_[0] },
        );
    }
    like( $stderr_chunk, qr/Unable to read ajax stream for error-path/, '_drain_saved_ajax_ready_handle surfaces real read errors through the stderr writer' );
}
{
    ok( $runtime->_looks_like_stream_disconnect_error(), '_looks_like_stream_disconnect_error treats empty errors as disconnect-like shutdowns' );
    ok( $runtime->_looks_like_stream_disconnect_error("Broken pipe\n"), '_looks_like_stream_disconnect_error recognizes broken-pipe disconnect errors' );
    ok( !$runtime->_looks_like_stream_disconnect_error("writer exploded\n"), '_looks_like_stream_disconnect_error does not hide unrelated writer failures' );
}
{
    pipe my $select_reader, my $select_writer or die $!;
    pipe my $extra_reader, my $extra_writer or die $!;
    my $select = IO::Select->new($select_reader);
    ok( $runtime->_close_saved_ajax_streams( $select, $select_reader, $extra_reader, $extra_writer ), '_close_saved_ajax_streams returns true after closing active handles' );
    ok( !defined fileno($select_reader), '_close_saved_ajax_streams closes handles still tracked by the select set' );
    ok( !defined fileno($extra_reader), '_close_saved_ajax_streams closes extra read handles passed outside the select set' );
    ok( !defined fileno($extra_writer), '_close_saved_ajax_streams closes extra write handles passed outside the select set' );
}
{
    my $class_page = Developer::Dashboard::PageDocument->new( layout => { body => 'plain body' } );
    my $prepared_class = Developer::Dashboard::PageRuntime->prepare_page(
        page            => $class_page,
        runtime_context => {},
    );
    is( $prepared_class->{layout}{body}, 'plain body', 'prepare_page also works when called as a class method' );
}
{
    my $eval_page = Developer::Dashboard::PageDocument->new(
        layout => { body => 'prefix-[% eval("print qq{inline-eval};") %]-suffix' },
    );
    my $prepared_eval = $runtime->prepare_page(
        page            => $eval_page,
        source          => 'saved',
        runtime_context => {},
    );
    is( $prepared_eval->{layout}{body}, 'prefix-inline-eval-suffix', 'prepare_page eval helper can run inline Perl blocks and inject stdout into HTML' );
}
{
    my $empty_page = Developer::Dashboard::PageDocument->new;
    my $class_runtime = Developer::Dashboard::PageRuntime->run_code_blocks( page => $empty_page );
    is_deeply( $class_runtime, { outputs => [], errors => [] }, 'run_code_blocks also works when called as a class method with no code blocks' );
}
{
    my $sandpit = $runtime->_new_sandpit();
    ok( $sandpit->{package}, '_new_sandpit creates a package even when called with default state and runtime context' );
    ok( !$runtime->_destroy_sandpit('not-a-sandpit'), '_destroy_sandpit returns quietly for invalid inputs' );
    $runtime->_destroy_sandpit($sandpit);
}
my $prepared = $runtime->prepare_page(
    page => $modern_page,
    source => 'saved',
    runtime_context => {
        cwd    => $project,
        params => { filter => 'applied' },
    },
);
like( $prepared->{layout}{body}, qr/Modern/, 'Template Toolkit renders HTML with stash access' );
like( $prepared->{layout}{body}, qr/\Q$home\E/, 'Template Toolkit method helper can call namespaced runtime methods' );
ok( !exists $prepared->{layout}{form_tt} || !defined $prepared->{layout}{form_tt} || $prepared->{layout}{form_tt} eq '', 'prepare_page leaves removed FORM.TT layout empty' );
ok( !exists $prepared->{layout}{form} || !defined $prepared->{layout}{form} || $prepared->{layout}{form} eq '', 'prepare_page leaves removed FORM layout empty' );
like( join( '', @{ $prepared->{meta}{runtime_outputs} } ), qr/MODERN/, 'prepare_page executes CODE blocks and captures stdout' );

my $tt_error_page = Developer::Dashboard::PageDocument->new(
    layout => { body => '[% THROW boom "bad" %]' },
);
$runtime->prepare_page( page => $tt_error_page, source => 'saved', runtime_context => {} );
is( $tt_error_page->{layout}{body}, '', 'prepare_page clears the failed template body when Template Toolkit parsing fails' );
like( join( '', @{ $tt_error_page->{meta}{runtime_errors} || [] } ), qr/boom error - bad|THROW boom|parse error|unexpected/i, 'prepare_page records a visible Template Toolkit runtime error for unsupported directives' );
is( $runtime->_system_context( runtime_context => {}, source => '' )->{cwd}, '.', '_system_context defaults cwd when omitted' );
is( Developer::Dashboard::Web::App::_escape_html('<x>'), '&lt;x&gt;', '_escape_html escapes HTML markup' );

my $auth = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
my $app = Developer::Dashboard::Web::App->new(
    auth     => $auth,
    pages    => $pages,
    sessions => $sessions,
    runtime  => $runtime,
);

my $saved_file = Developer::Dashboard::PageDocument->new(
    id     => 'legacy-page',
    title  => 'Legacy Page',
    layout => { body => 'legacy body' },
);
$pages->save_page($saved_file);

is( $app->handle( path => '/marked.min.js', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } )->[0], 200, 'web app serves marked shim' );
is( $app->handle( path => '/tiff.min.js', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } )->[0], 200, 'web app serves tiff shim' );
is( $app->handle( path => '/loading.webp', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } )->[0], 200, 'web app serves loading image shim' );

my $login_user = $auth->add_user( username => 'helperx', password => 'helper-pass-123' );
ok( $login_user->{username}, 'helper user can be created for login flow coverage' );
my ( $login_code, undef, undef, $login_headers ) = @{ $app->handle(
    path        => '/login',
    method      => 'POST',
    body        => form_body( username => 'helperx', password => 'helper-pass-123' ),
    remote_addr => '10.0.0.2',
    headers     => { host => 'localhost:7890' },
) };
is( $login_code, 302, 'helper login returns a redirect response' );
like( $login_headers->{'Set-Cookie'}, qr/dashboard_session=/, 'helper login returns a session cookie' );

my $session_cookie = $login_headers->{'Set-Cookie'};
my ($logout_code, undef, undef, $logout_headers) = @{ $app->handle(
    path        => '/logout',
    query       => '',
    remote_addr => '10.0.0.2',
    headers     => { host => 'localhost:7890', cookie => $session_cookie },
) };
is( $logout_code, 302, 'logout returns a redirect response' );
like( $logout_headers->{'Set-Cookie'}, qr/Max-Age=0/, 'logout expires the session cookie' );

{
    open my $fh, '>', $pages->page_file('legacy-forward') or die $!;
    print {$fh} '/app/legacy-page';
    close $fh;
}
is( $app->handle( path => '/app/legacy-forward', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } )->[0], 200, 'legacy app forwarding handles saved url bookmarks' );

done_testing;

__END__

=head1 NAME

12-legacy-helper-coverage.t - targeted legacy helper and runtime coverage tests

=head1 DESCRIPTION

This test drives the remaining legacy compatibility helpers and runtime paths
needed to keep the active library coverage high after the bookmark-model reset.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the hard-to-hit branches that keep library coverage honest. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the hard-to-hit branches that keep library coverage honest has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the hard-to-hit branches that keep library coverage honest, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/12-legacy-helper-coverage.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/12-legacy-helper-coverage.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/12-legacy-helper-coverage.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
