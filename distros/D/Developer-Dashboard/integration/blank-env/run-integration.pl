#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use JSON::XS qw(decode_json);
use Time::HiRes qw(sleep time);

# main()
# Executes the full blank-environment integration flow against a host-built tarball.
# Input: none.
# Output: process exit status via die on failure or zero on success.
sub main {
    my $tarball  = $ENV{DASHBOARD_TARBALL_IN_CONTAINER} || '/artifacts/Developer-Dashboard.tar.gz';
    my $dist_dir = '/tmp/developer-dashboard-dist';
    my $home     = '/tmp/developer-dashboard-integration-home';
    my $cookie   = '/tmp/developer-dashboard-cookies.txt';
    my $compose  = '/tmp/developer-dashboard-compose-project';
    my $project  = '/tmp/fake-project';
    my $bookmarks = File::Spec->catdir( $project, 'bookmarks' );
    my $configs   = File::Spec->catdir( $project, 'configs' );
    my $startup   = File::Spec->catdir( $project, 'startup' );
    my $profile   = '/tmp/developer-dashboard-browser-profile';

    _assert( -f $tarball, 'host-built tarball is mounted into the container' );
    _reset_dir($dist_dir);
    _reset_dir($home);
    _reset_dir($compose);
    _reset_dir($project);
    _reset_dir($profile);

    local $ENV{HOME}                   = $home;
    local $ENV{PERL_MM_USE_DEFAULT}    = 1;
    local $ENV{NONINTERACTIVE_TESTING} = 1;
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bookmarks;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS}   = $configs;
    local $ENV{DEVELOPER_DASHBOARD_STARTUP}   = $startup;

    _run_shell( 'extract host-built tarball', "tar -xzf " . _shell_quote($tarball) . ' -C ' . _shell_quote($dist_dir) );
    my $source_root = _single_subdir($dist_dir);
    _assert( defined $source_root && -d $source_root, 'extracted tarball produced one source root' );

    _write_text(
        File::Spec->catfile( $compose, 'compose.yaml' ),
        <<'YAML'
services:
  hello:
    image: busybox:latest
    command: ["echo", "hello"]
YAML
    );

    _write_text(
        File::Spec->catfile( $startup, 'fake.startup.collector.json' ),
        <<'JSON'
{
  "name": "fake.startup.collector",
  "command": "printf 'fake startup collector output\n'",
  "cwd": "home",
  "interval": 30
}
JSON
    );

    _write_text(
        File::Spec->catfile( $bookmarks, 'project-home' ),
        <<'BOOKMARK'
TITLE: Project Home
:--------------------------------------------------------------------------------:
BOOKMARK: project-home
:--------------------------------------------------------------------------------:
STASH: {}
:--------------------------------------------------------------------------------:
HTML: <div id="project-marker">Fake Project Home</div>
BOOKMARK
    );

    _run_shell( 'init fake project git repo', 'git init ' . _shell_quote($project) );

    my $install = _run_shell( 'cpanm install host-built tarball', 'cpanm --notest ' . _shell_quote($tarball) );
    _assert( $install->{exit_code} == 0, 'cpanm installed host-built distribution tarball' );

    my $bare = _run_shell( 'dashboard bare usage', 'dashboard', allow_fail => 1 );
    _assert( $bare->{exit_code} != 0, 'bare dashboard returns non-zero usage exit' );
    _assert_match( $bare->{stdout}, qr/Usage:/, 'bare dashboard prints usage output' );

    my $help = _run_shell( 'dashboard help', 'dashboard help' );
    _assert_match( $help->{stdout}, qr/Description:/, 'dashboard help renders extended POD help' );

    my $init = _run_shell( 'dashboard init', 'dashboard init' );
    my $init_data = decode_json( $init->{stdout} );
    _assert_match( $init_data->{runtime_root} || '', qr/\.developer-dashboard/, 'dashboard init returns runtime root' );
    _assert( grep { $_ eq 'welcome' } @{ $init_data->{pages} || [] }, 'dashboard init seeds welcome page' );

    my $update = _run_shell( 'dashboard update', 'cd ' . _shell_quote($source_root) . ' && dashboard update' );
    my $update_data = _decode_json_tail( $update->{stdout} );
    _assert( ref($update_data) eq 'ARRAY', 'dashboard update returns structured trailing json summary from extracted tarball source' );

    my $paths = _run_shell( 'dashboard paths', 'dashboard paths' );
    _assert_match( $paths->{stdout}, qr/"runtime_root"/, 'dashboard paths returns runtime json' );
    _assert_match( $paths->{stdout}, qr/\Q$bookmarks\E/, 'dashboard paths reflects fake bookmark override' );
    _assert_match( $paths->{stdout}, qr/\Q$configs\E/, 'dashboard paths reflects fake config override' );
    _assert_match( $paths->{stdout}, qr/\Q$startup\E/, 'dashboard paths reflects fake startup override' );

    my $path_list = _run_shell( 'dashboard path list', 'dashboard path list' );
    _assert_match( $path_list->{stdout}, qr/"runtime"/, 'dashboard path list returns named paths' );

    my $path_resolve = _run_shell( 'dashboard path resolve home', 'dashboard path resolve home' );
    _assert_match( $path_resolve->{stdout}, qr/^\Q$home\E/m, 'dashboard path resolve home returns integration home' );

    my $bookmark_resolve = _run_shell( 'dashboard path resolve bookmarks', 'dashboard path resolve bookmarks' );
    _assert_match( $bookmark_resolve->{stdout}, qr/^\Q$bookmarks\E/m, 'dashboard path resolve bookmarks returns fake project bookmark root' );

    my $path_project = _run_shell( 'dashboard path project-root', 'cd ' . _shell_quote($project) . ' && dashboard path project-root' );
    _assert_match( $path_project->{stdout}, qr/^\Q$project\E/m, 'dashboard path project-root detects fake project root' );

    my $codec = _run_shell( 'dashboard encode/decode', q{printf 'integration-codec' | dashboard encode | dashboard decode} );
    _assert_match( $codec->{stdout}, qr/integration-codec/, 'dashboard encode and decode round-trip text' );

    my $set_indicator = _run_shell( 'dashboard indicator set', q{dashboard indicator set integration "Integration" "I" ok} );
    _assert_match( $set_indicator->{stdout}, qr/"name"\s*:\s*"integration"/, 'dashboard indicator set persists state' );

    my $list_indicator = _run_shell( 'dashboard indicator list', 'dashboard indicator list' );
    _assert_match( $list_indicator->{stdout}, qr/"integration"/, 'dashboard indicator list includes integration indicator' );

    my $refresh_indicator = _run_shell( 'dashboard indicator refresh-core', 'cd ' . _shell_quote($project) . ' && dashboard indicator refresh-core ' . _shell_quote($project) );
    _assert_match( $refresh_indicator->{stdout}, qr/"docker"|"project"|"git"/, 'dashboard indicator refresh-core updates built-ins' );

    my $ps1 = _run_shell( 'dashboard ps1', 'cd ' . _shell_quote($project) . ' && dashboard ps1 --jobs 1 --cwd ' . _shell_quote($project) );
    _assert_match( $ps1->{stdout}, qr/fake-project|jobs/, 'dashboard ps1 renders prompt text for fake project' );

    my $shell = _run_shell( 'dashboard shell bash', 'dashboard shell bash' );
    _assert_match( $shell->{stdout}, qr/path resolve "\$1"|ps1 --jobs/, 'dashboard shell bash emits shell integration' );

    my $config_init = _run_shell( 'dashboard config init', 'dashboard config init' );
    _assert_match( $config_init->{stdout}, qr/config\.json/, 'dashboard config init writes config file' );

    my $config_show = _run_shell( 'dashboard config show', 'dashboard config show' );
    _assert_match( $config_show->{stdout}, qr/"collectors"/, 'dashboard config show includes collectors' );

    my $page_new = _run_shell( 'dashboard page new', q{dashboard page new sample "Sample Page"} );
    _assert_match( $page_new->{stdout}, qr/^TITLE:\s+Sample Page/m, 'dashboard page new emits bookmark instruction text' );

    _write_text( '/tmp/sample.bookmark', $page_new->{stdout} );
    my $page_save = _run_shell( 'dashboard page save', q{dashboard page save sample < /tmp/sample.bookmark} );
    _assert_match( $page_save->{stdout}, qr/sample$/, 'dashboard page save writes bookmark file' );
    _assert( -f File::Spec->catfile( $bookmarks, 'sample' ), 'dashboard page save wrote into fake project bookmark root' );

    my $page_list = _run_shell( 'dashboard page list', 'dashboard page list' );
    _assert_match( $page_list->{stdout}, qr/"sample"/, 'dashboard page list includes saved sample page' );
    _assert_match( $page_list->{stdout}, qr/"project-home"/, 'dashboard page list includes fake project bookmark page' );

    my $page_show = _run_shell( 'dashboard page show', 'dashboard page show sample' );
    _assert_match( $page_show->{stdout}, qr/^BOOKMARK:\s+sample/m, 'dashboard page show returns canonical bookmark source' );

    my $page_encode = _run_shell( 'dashboard page encode', 'dashboard page encode sample' );
    my $token = _trim( $page_encode->{stdout} );
    _assert( $token ne '', 'dashboard page encode returns a token' );

    my $page_decode = _run_shell( 'dashboard page decode', 'dashboard page decode ' . _shell_quote($token) );
    _assert_match( $page_decode->{stdout}, qr/^BOOKMARK:\s+sample/m, 'dashboard page decode restores bookmark source' );

    my $page_urls = _run_shell( 'dashboard page urls', 'dashboard page urls sample' );
    _assert_match( $page_urls->{stdout}, qr/"render"/, 'dashboard page urls returns edit and render links' );

    my $page_render = _run_shell( 'dashboard page render', 'dashboard page render sample' );
    _assert_match( $page_render->{stdout}, qr/Replace this body with your own page content/, 'dashboard page render produces html output' );

    my $page_source = _run_shell( 'dashboard page source', 'dashboard page source sample' );
    _assert_match( $page_source->{stdout}, qr/^BOOKMARK:\s+sample/m, 'dashboard page source returns instruction text' );

    my $action = _run_shell( 'dashboard action run system-status paths', 'dashboard action run system-status paths' );
    _assert_match( $action->{stdout}, qr/runtime/, 'dashboard action run executes builtin action' );

    my $collector_write = _run_shell( 'dashboard collector write-result', q{printf 'manual-output' | dashboard collector write-result manual.collector 0} );
    _assert( $collector_write->{exit_code} == 0, 'dashboard collector write-result accepts manual output' );

    my $collector_run = _run_shell( 'dashboard collector run', 'dashboard collector run example.collector' );
    _assert_match( $collector_run->{stdout}, qr/"exit_code"\s*:\s*0/, 'dashboard collector run succeeds for example collector' );

    my $fake_collector_run = _run_shell( 'dashboard collector run fake.startup.collector', 'dashboard collector run fake.startup.collector' );
    _assert_match( $fake_collector_run->{stdout}, qr/"exit_code"\s*:\s*0/, 'dashboard collector run succeeds for fake project startup collector' );

    my $collector_list = _run_shell( 'dashboard collector list', 'dashboard collector list' );
    _assert_match( $collector_list->{stdout}, qr/example\.collector|manual\.collector/, 'dashboard collector list shows stored collectors' );
    _assert_match( $collector_list->{stdout}, qr/fake\.startup\.collector/, 'dashboard collector list shows fake project startup collector' );

    my $collector_job = _run_shell( 'dashboard collector job', 'dashboard collector job example.collector' );
    _assert_match( $collector_job->{stdout}, qr/"command"/, 'dashboard collector job returns job metadata' );

    my $collector_status = _run_shell( 'dashboard collector status', 'dashboard collector status example.collector' );
    _assert_match( $collector_status->{stdout}, qr/"enabled"/, 'dashboard collector status returns status data' );

    my $collector_output = _run_shell( 'dashboard collector output', 'dashboard collector output example.collector' );
    _assert_match( $collector_output->{stdout}, qr/example collector output/, 'dashboard collector output returns prepared output' );

    my $collector_inspect = _run_shell( 'dashboard collector inspect', 'dashboard collector inspect example.collector' );
    _assert_match( $collector_inspect->{stdout}, qr/"job"|"status"|"output"/, 'dashboard collector inspect returns combined view' );

    my $collector_start = _run_shell( 'dashboard collector start', 'dashboard collector start example.collector' );
    _assert_match( $collector_start->{stdout}, qr/\d+/, 'dashboard collector start returns a pid' );

    sleep 2;

    my $collector_restart = _run_shell( 'dashboard collector restart', 'dashboard collector restart example.collector' );
    _assert_match( $collector_restart->{stdout}, qr/\d+/, 'dashboard collector restart returns a pid' );

    my $collector_stop = _run_shell( 'dashboard collector stop', 'dashboard collector stop example.collector' );
    _assert_match( $collector_stop->{stdout}, qr/\d+/, 'dashboard collector stop returns the stopped pid' );

    my $collector_log = _run_shell( 'dashboard collector log', 'dashboard collector log' );
    _assert( defined $collector_log->{stdout}, 'dashboard collector log returns log text' );

    my $auth_add = _run_shell( 'dashboard auth add-user', q{dashboard auth add-user explicit_helper explicit-pass-123} );
    _assert_match( $auth_add->{stdout}, qr/"username"\s*:\s*"explicit_helper"/, 'dashboard auth add-user creates helper user' );

    my $auth_list = _run_shell( 'dashboard auth list-users', 'dashboard auth list-users' );
    _assert_match( $auth_list->{stdout}, qr/"explicit_helper"/, 'dashboard auth list-users includes explicit helper' );

    my $auth_remove = _run_shell( 'dashboard auth remove-user', 'dashboard auth remove-user explicit_helper' );
    _assert_match( $auth_remove->{stdout}, qr/"removed"\s*:\s*"explicit_helper"/, 'dashboard auth remove-user removes explicit helper' );

    my $docker_dry = _run_shell(
        'dashboard docker compose --dry-run',
        'dashboard docker compose --project ' . _shell_quote($compose) . ' --dry-run config'
    );
    _assert_match( $docker_dry->{stdout}, qr/"command"\s*:/, 'dashboard docker compose dry-run returns resolved command' );
    _assert_match( $docker_dry->{stdout}, qr/compose\.yaml/, 'dashboard docker compose dry-run includes compose file' );

    my $serve = _run_shell( 'dashboard serve', 'dashboard serve' );
    _assert_match( $serve->{stdout}, qr/"pid"\s*:/, 'dashboard serve starts background web service' );
    _wait_for_http( 'http://127.0.0.1:7890/', 200 );

    my $root = _run_shell( 'curl loopback root', q{curl -fsS http://127.0.0.1:7890/} );
    _assert_match( $root->{stdout}, qr/instruction-editor/, 'loopback root serves the bookmark editor' );
    my $root_dom = _run_browser_dom( 'browser loopback root', 'http://127.0.0.1:7890/', user_data_dir => $profile );
    _assert_match( $root_dom, qr/instruction-editor/, 'browser loopback root renders the editor DOM' );
    _assert_match( $root_dom, qr/TITLE:\s+Developer Dashboard/, 'browser loopback root shows bookmark source text' );

    my $project_dom = _run_browser_dom( 'browser fake project page', 'http://127.0.0.1:7890/app/project-home', user_data_dir => $profile );
    _assert_match( $project_dom, qr/project-marker/, 'browser renders fake project bookmark page' );
    _assert_match( $project_dom, qr/Fake Project Home/, 'browser renders fake project bookmark content' );

    my $container_ip = _trim( _run_shell( 'container ip', q{hostname -I | awk '{print $1}'} )->{stdout} );
    _assert( $container_ip ne '', 'container ip discovered for helper-access path' );

    my $helper_root = _run_shell(
        'curl helper root',
        'curl -sS -o /tmp/helper-root.html -w \'%{http_code}\' http://' . $container_ip . ':7890/'
    );
    _assert_match( $helper_root->{stdout}, qr/^401$/, 'non-loopback self-access returns helper login' );
    _assert_match( _read_text('/tmp/helper-root.html'), qr/<form[^>]*action="\/login"/, 'helper root serves login page' );
    my $helper_dom = _run_browser_dom( 'browser helper root', "http://$container_ip:7890/", user_data_dir => $profile );
    _assert_match( $helper_dom, qr/action="\/login"/, 'browser helper root renders login form' );

    _run_shell( 'dashboard auth add helper-login user', q{dashboard auth add-user helper_login helper-login-pass-123} );
    my $login = _run_shell(
        'helper login',
        'curl -sS -c ' . _shell_quote($cookie) .
          ' -o /tmp/helper-login.body -D /tmp/helper-login.headers -d ' .
          _shell_quote('username=helper_login&password=helper-login-pass-123') .
          ' http://' . $container_ip . ':7890/login'
    );
    _assert( $login->{exit_code} == 0, 'helper login request completed' );
    _assert_match( _read_text('/tmp/helper-login.headers'), qr/^HTTP\/1\.1 302/m, 'helper login redirects after success' );

    my $helper_page = _run_shell(
        'helper page after login',
        'curl -fsS -b ' . _shell_quote($cookie) . ' http://' . $container_ip . ':7890/page/welcome'
    );
    _assert_match( $helper_page->{stdout}, qr/id="logout-url"/, 'helper page chrome renders logout link' );

    my $helper_logout = _run_shell(
        'helper logout',
        'curl -sS -b ' . _shell_quote($cookie) . ' -o /tmp/helper-logout.body -D /tmp/helper-logout.headers http://' . $container_ip . ':7890/logout'
    );
    _assert( $helper_logout->{exit_code} == 0, 'helper logout request completed' );
    _assert_match( _read_text('/tmp/helper-logout.headers'), qr/^HTTP\/1\.1 302/m, 'helper logout redirects to login' );

    my $post_logout_users = _run_shell( 'dashboard auth list-users after logout', 'dashboard auth list-users' );
    _assert( $post_logout_users->{stdout} !~ /helper_login/, 'helper logout removes helper account from auth store' );

    my $restart = _run_shell( 'dashboard restart', 'cd ' . _shell_quote($source_root) . ' && dashboard restart' );
    _assert_match( $restart->{stdout}, qr/"web_pid"\s*:/, 'dashboard restart returns structured lifecycle data' );
    _wait_for_http( 'http://127.0.0.1:7890/', 200 );

    my $stop = _run_shell( 'dashboard stop', 'dashboard stop' );
    _assert_match( $stop->{stdout}, qr/"web_pid"\s*:/, 'dashboard stop returns structured lifecycle data' );
    my $stopped = _run_shell(
        'curl after stop',
        q{curl -sS -o /tmp/after-stop.body -w '%{http_code}' http://127.0.0.1:7890/},
        allow_fail => 1,
    );
    _assert( $stopped->{exit_code} != 0, 'web service is no longer reachable after dashboard stop' );

    print "Blank-environment integration run passed\n";
    return 0;
}

# _run_shell($label, $command, %opts)
# Runs one shell command, captures stdout and stderr, and returns structured command results.
# Input: human label, shell command string, and optional allow_fail flag.
# Output: hash reference with command, stdout, stderr, and exit_code.
sub _run_shell {
    my ( $label, $command, %opts ) = @_;
    print "==> $label\n";
    print "    $command\n";
    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'sh', '-lc', $command;
        return $? >> 8;
    };
    print $stdout if defined $stdout && $stdout ne '';
    print STDERR $stderr if defined $stderr && $stderr ne '';
    if ( !$opts{allow_fail} && $exit_code != 0 ) {
        die "Command failed for [$label] with exit $exit_code\n";
    }
    return {
        command   => $command,
        exit_code => $exit_code,
        stdout    => defined $stdout ? $stdout : '',
        stderr    => defined $stderr ? $stderr : '',
    };
}

# _wait_for_http($url, $expected_code)
# Polls a URL until it returns the expected HTTP status code or times out.
# Input: URL string and expected numeric status code.
# Output: true on success or dies on timeout.
sub _wait_for_http {
    my ( $url, $expected_code ) = @_;
    my $deadline = time + 20;
    while ( time < $deadline ) {
        my $result = _run_shell(
            "wait for $url",
            "curl -sS -o /tmp/wait-http.body -w '%{http_code}' '$url'",
            allow_fail => 1,
        );
        return 1 if _trim( $result->{stdout} ) eq "$expected_code";
        sleep 0.5;
    }
    die "Timed out waiting for $url to return HTTP $expected_code\n";
}

# _run_browser_dom($label, $url, %opts)
# Loads one URL in headless Chromium and returns the rendered DOM after client-side JavaScript settles.
# Input: human label, URL string, and optional user_data_dir.
# Output: rendered DOM string from Chromium.
sub _run_browser_dom {
    my ( $label, $url, %opts ) = @_;
    my $command = _browser_command( $url, %opts );
    my $result = _run_shell( $label, $command );
    return $result->{stdout};
}

# _browser_command($url, %opts)
# Builds a reusable headless Chromium command line with persistent profile support.
# Input: URL string and optional user_data_dir.
# Output: shell-safe command string.
sub _browser_command {
    my ( $url, %opts ) = @_;
    my $profile = $opts{user_data_dir} || '/tmp/developer-dashboard-browser-profile';
    return join ' ',
      'chromium',
      '--headless',
      '--no-sandbox',
      '--disable-gpu',
      '--disable-dev-shm-usage',
      '--virtual-time-budget=3000',
      '--user-data-dir=' . _shell_quote($profile),
      '--dump-dom',
      _shell_quote($url);
}

# _single_subdir($dir)
# Returns the only immediate child directory under one extraction root.
# Input: directory path.
# Output: single child directory path or undef.
sub _single_subdir {
    my ($dir) = @_;
    opendir my $dh, $dir or die "Unable to open $dir: $!";
    my @children = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    my @dirs = grep { -d File::Spec->catdir( $dir, $_ ) } @children;
    return if @dirs != 1;
    return File::Spec->catdir( $dir, $dirs[0] );
}

# _decode_json_tail($text)
# Decodes the trailing JSON object or array embedded at the end of command output.
# Input: output text string.
# Output: decoded Perl structure.
sub _decode_json_tail {
    my ($text) = @_;
    $text = '' if !defined $text;
    if ( $text =~ /(\[\s*[\s\S]*\])\s*\z/ ) {
        return decode_json($1);
    }
    if ( $text =~ /(\{\s*[\s\S]*\})\s*\z/ ) {
        return decode_json($1);
    }
    die "Unable to locate trailing JSON payload in command output\n";
}

# _reset_dir($dir)
# Recreates a directory from scratch for clean integration state.
# Input: directory path.
# Output: none.
sub _reset_dir {
    my ($dir) = @_;
    remove_tree($dir) if -e $dir;
    make_path($dir);
}

# _write_text($file, $text)
# Writes text content to a file path, creating parent directories as needed.
# Input: file path string and text string.
# Output: none.
sub _write_text {
    my ( $file, $text ) = @_;
    my $dir = dirname($file);
    make_path($dir) if defined $dir && $dir ne '' && !-d $dir;
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} $text;
    close $fh;
}

# _read_text($file)
# Reads one whole text file into memory.
# Input: file path string.
# Output: file contents string.
sub _read_text {
    my ($file) = @_;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

# _trim($text)
# Trims leading and trailing whitespace from text.
# Input: text string.
# Output: trimmed string.
sub _trim {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    return $text;
}

# _shell_quote($text)
# Escapes one string for safe inclusion in a shell command line.
# Input: arbitrary text string.
# Output: single-quoted shell literal.
sub _shell_quote {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/'/'"'"'/g;
    return "'$text'";
}

# _assert($bool, $message)
# Stops the integration run when a required condition is false.
# Input: boolean condition and assertion message.
# Output: true on success or dies on failure.
sub _assert {
    my ( $bool, $message ) = @_;
    die "Assertion failed: $message\n" if !$bool;
    return 1;
}

# _assert_match($text, $regex, $message)
# Stops the integration run when text does not match the expected regular expression.
# Input: text string, compiled regex, and assertion message.
# Output: true on success or dies on failure.
sub _assert_match {
    my ( $text, $regex, $message ) = @_;
    die "Assertion failed: $message\n$text\n" if !defined $text || $text !~ $regex;
    return 1;
}

exit main();

__END__

=head1 NAME

run-integration.pl - blank-environment Docker integration runner for a host-built tarball

=head1 SYNOPSIS

  perl /opt/integration/run-integration.pl

=head1 DESCRIPTION

This script expects a host-built C<Developer-Dashboard> tarball to be mounted
into the container. It installs that tarball with C<cpanm>, extracts it to a
temporary source tree for update-script execution, and then exercises the
installed C<dashboard> CLI and web runtime against a fake project.

=head1 FUNCTIONS

=head2 main, _run_shell, _wait_for_http, _run_browser_dom, _browser_command, _single_subdir, _decode_json_tail, _reset_dir, _write_text, _read_text, _trim, _shell_quote, _assert, _assert_match

Run and validate the host-built-tarball integration workflow.

=cut
