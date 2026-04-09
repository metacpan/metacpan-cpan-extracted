#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use IO::Select;
use IPC::Open3 qw(open3);
use JSON::XS qw(decode_json);
use Symbol qw(gensym);
use Time::HiRes qw(sleep time);

our $BROWSER_BINARY;

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
    my $runtime_root = File::Spec->catdir( $project, '.developer-dashboard' );
    my $cli_root = File::Spec->catdir( $runtime_root, 'cli' );
    my $update_root = File::Spec->catdir( $cli_root, 'update.d' );
    my $bookmarks = File::Spec->catdir( $runtime_root, 'dashboards' );
    my $configs   = File::Spec->catdir( $runtime_root, 'config' );
    my $profile   = '/tmp/developer-dashboard-browser-profile';
    my $project_cd = 'cd ' . _shell_quote($project) . ' && ';

    _assert( -f $tarball, 'host-built tarball is mounted into the container' );
    _reset_dir($dist_dir);
    _reset_dir($home);
    _reset_dir($compose);
    _reset_dir($project);
    _reset_dir($profile);

    local $ENV{HOME}                   = $home;
    local $ENV{PERL_MM_USE_DEFAULT}    = 1;
    local $ENV{NONINTERACTIVE_TESTING} = 1;
    local $ENV{PERL_CANARY_STABILITY_NOPROMPT} = 1;

    _run_shell( 'extract host-built tarball', "tar -xzf " . _shell_quote($tarball) . ' -C ' . _shell_quote($dist_dir) );
    my $source_root = _single_subdir($dist_dir);
    _assert( defined $source_root && -d $source_root, 'extracted tarball produced one source root' );
    my $expected_version = _distribution_version($source_root);
    _assert( defined $expected_version && $expected_version ne '', 'extracted tarball exposes a distribution version' );

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
        File::Spec->catfile( $configs, 'config.json' ),
        <<'JSON'
{
  "collectors": [
    {
      "name": "fake.config.collector",
      "command": "printf 'fake config collector output\n'",
      "cwd": "home",
      "interval": 30
    },
    {
      "name": "broken.collector",
      "code": "this is broken perl code",
      "cwd": "home",
      "interval": 1,
      "indicator": {
        "name": "broken.indicator",
        "label": "Broken",
        "icon": "B"
      }
    },
    {
      "name": "healthy.collector",
      "command": "printf 'healthy config collector output\n'",
      "cwd": "home",
      "interval": 1,
      "indicator": {
        "name": "healthy.indicator",
        "label": "Healthy",
        "icon": "H"
      }
    }
  ]
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
    _write_text(
        File::Spec->catfile( $bookmarks, 'legacy-ajax' ),
        <<'BOOKMARK'
TITLE: Legacy Ajax
:--------------------------------------------------------------------------------:
BOOKMARK: legacy-ajax
:--------------------------------------------------------------------------------:
HTML: <script>var configs = {};</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'configs.project.endpoint', type => 'text', file => 'project-endpoint.json', code => q{
print "saved-start\n";
warn "saved-warn\n";
system 'sh', '-c', 'printf "saved-child-out\n"; printf "saved-child-err\n" >&2';
die "saved-die\n";
};
BOOKMARK
    );
    _write_text(
        File::Spec->catfile( $bookmarks, 'legacy-ajax-stream' ),
        <<'BOOKMARK'
TITLE: Legacy Ajax Stream
:--------------------------------------------------------------------------------:
BOOKMARK: legacy-ajax-stream
:--------------------------------------------------------------------------------:
HTML: <script>var configs = {};</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'configs.project.stream', file => 'project-stream.txt', code => q{
for (1..3) {
    print "stream$_\n";
    sleep 1;
}
};
BOOKMARK
    );
    _write_text(
        File::Spec->catfile( $bookmarks, 'nav', 'alpha.tt' ),
        <<'BOOKMARK'
TITLE: Alpha Nav
:--------------------------------------------------------------------------------:
BOOKMARK: nav/alpha.tt
:--------------------------------------------------------------------------------:
HTML: [% IF env.current_page == '/app/project-home' %]<div id="nav-alpha">Alpha Nav Current</div>[% ELSE %]<a id="nav-alpha" href="/app/project-home">Alpha Nav Link</a>[% END %]
BOOKMARK
    );
    _write_text(
        File::Spec->catfile( $bookmarks, 'nav', 'beta.tt' ),
        <<'BOOKMARK'
TITLE: Beta Nav
:--------------------------------------------------------------------------------:
BOOKMARK: nav/beta.tt
:--------------------------------------------------------------------------------:
HTML: <div id="nav-beta">[% env.current_page %] / [% env.runtime_context.current_page %]</div>
BOOKMARK
    );

    _run_shell( 'init fake project git repo', 'git init ' . _shell_quote($project) );

    my $install = _run_shell( 'cpanm install host-built tarball', 'cpanm ' . _shell_quote($tarball) );
    _assert( $install->{exit_code} == 0, 'cpanm installed host-built distribution tarball' );

    my $bare = _run_shell( 'dashboard bare usage', 'dashboard', allow_fail => 1 );
    _assert( $bare->{exit_code} != 0, 'bare dashboard returns non-zero usage exit' );
    _assert_match( $bare->{stdout}, qr/Usage:/, 'bare dashboard prints usage output' );

    my $help = _run_shell( 'dashboard help', 'dashboard help' );
    _assert_match( $help->{stdout}, qr/Description:/, 'dashboard help renders extended POD help' );

    my $version = _run_shell( 'dashboard version', 'dashboard version' );
    _assert_match( $version->{stdout}, qr/^\Q$expected_version\E$/m, 'dashboard version reports the installed runtime version' );

    my $init = _run_shell( 'dashboard init', 'cd ' . _shell_quote($project) . ' && dashboard init' );
    my $init_data = decode_json( $init->{stdout} );
    _assert_match( $init_data->{runtime_root} || '', qr/\.developer-dashboard/, 'dashboard init returns runtime root' );
    _assert( !grep { $_ eq 'welcome' } @{ $init_data->{pages} || [] }, 'dashboard init no longer seeds welcome page' );
    _assert( grep { $_ eq 'api-dashboard' } @{ $init_data->{pages} || [] }, 'dashboard init seeds api-dashboard page' );
    _assert( grep { $_ eq 'sql-dashboard' } @{ $init_data->{pages} || [] }, 'dashboard init seeds sql-dashboard page' );

    make_path($update_root);
    _write_text(
        File::Spec->catfile( $cli_root, 'update' ),
        <<'PL'
#!/usr/bin/env perl
use strict;
use warnings;
print $ENV{RESULT} // '';
PL
    );
    chmod 0755, File::Spec->catfile( $cli_root, 'update' )
      or die "Unable to chmod runtime update command: $!";
    _write_text(
        File::Spec->catfile( $update_root, '01-runtime-update' ),
        <<'SH'
#!/bin/sh
printf 'runtime update ok\n'
SH
    );
    chmod 0755, File::Spec->catfile( $update_root, '01-runtime-update' )
      or die "Unable to chmod runtime update script: $!";
    _write_text(
        File::Spec->catfile( $update_root, '02-runtime-result.pl' ),
        <<'PL'
#!/usr/bin/env perl
use strict;
use warnings;
use Developer::Dashboard::Runtime::Result;
print Developer::Dashboard::Runtime::Result::stdout('01-runtime-update');
PL
    );
    chmod 0755, File::Spec->catfile( $update_root, '02-runtime-result.pl' )
      or die "Unable to chmod runtime result script: $!";
    _write_text(
        File::Spec->catfile( $update_root, '03-data.file' ),
        "skip\n"
    );
    chmod 0600, File::Spec->catfile( $update_root, '03-data.file' )
      or die "Unable to chmod runtime update data file: $!";

    my $update = _run_shell( 'dashboard update', 'cd ' . _shell_quote($project) . ' && dashboard update' );
    my $update_data = _decode_json_tail( $update->{stdout} );
    _assert( ref($update_data) eq 'HASH', 'dashboard update custom command returns structured trailing json summary from the common command hook path' );
    _assert( scalar(keys %{$update_data}) == 2, 'dashboard update custom command ran the seeded executable runtime update scripts only' );
    _assert( exists $update_data->{'01-runtime-update'}, 'dashboard update custom command reports the runtime update script filename' );
    _assert( exists $update_data->{'02-runtime-result.pl'}, 'dashboard update custom command reports the result-aware runtime update script filename' );
    _assert_match( $update_data->{'01-runtime-update'}{stdout} || '', qr/runtime update ok/, 'dashboard update custom command captures runtime update script stdout' );
    _assert_match( $update_data->{'02-runtime-result.pl'}{stdout} || '', qr/runtime update ok/, 'dashboard update custom command exposes the prior hook result to later hook scripts' );

    my $paths = _run_shell( 'dashboard paths', 'cd ' . _shell_quote($project) . ' && dashboard paths' );
    _assert_match( $paths->{stdout}, qr/"runtime_root"/, 'dashboard paths returns runtime json' );
    _assert_match( $paths->{stdout}, qr/\Q$bookmarks\E/, 'dashboard paths reflects fake bookmark override' );
    _assert_match( $paths->{stdout}, qr/\Q$configs\E/, 'dashboard paths reflects fake config override' );
    _assert_match( $paths->{stdout}, qr/\Q$cli_root\E/, 'dashboard paths reflects the runtime cli root' );

    my $path_list = _run_shell( 'dashboard path list', 'cd ' . _shell_quote($project) . ' && dashboard path list' );
    _assert_match( $path_list->{stdout}, qr/"runtime"/, 'dashboard path list returns named paths' );

    my $path_resolve = _run_shell( 'dashboard path resolve home', 'cd ' . _shell_quote($project) . ' && dashboard path resolve home' );
    _assert_match( $path_resolve->{stdout}, qr/^\Q$home\E/m, 'dashboard path resolve home returns integration home' );

    my $bookmark_resolve = _run_shell( 'dashboard path resolve bookmarks', 'cd ' . _shell_quote($project) . ' && dashboard path resolve bookmarks' );
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
    _assert_match(
        _read_text( File::Spec->catfile( $configs, 'config.json' ) ),
        qr/fake\.config\.collector/,
        'dashboard config init leaves an existing config.json untouched',
    );
    _write_text(
        File::Spec->catfile( $configs, 'config.json' ),
        <<'JSON'
{
  "collectors": [
    {
      "name": "fake.config.collector",
      "command": "printf 'fake config collector output\n'",
      "cwd": "home",
      "interval": 30
    },
    {
      "name": "broken.collector",
      "code": "this is broken perl code",
      "cwd": "home",
      "interval": 1,
      "indicator": {
        "name": "broken.indicator",
        "label": "Broken",
        "icon": "B"
      }
    },
    {
      "name": "healthy.collector",
      "command": "printf 'healthy config collector output\n'",
      "cwd": "home",
      "interval": 1,
      "indicator": {
        "name": "healthy.indicator",
        "label": "Healthy",
        "icon": "H"
      }
    }
  ]
}
JSON
    );

    my $config_show = _run_shell( 'dashboard config show', $project_cd . 'dashboard config show' );
    _assert_match( $config_show->{stdout}, qr/"collectors"/, 'dashboard config show includes collectors' );

    my $page_new = _run_shell( 'dashboard page new', $project_cd . q{dashboard page new sample "Sample Page"} );
    _assert_match( $page_new->{stdout}, qr/^TITLE:\s+Sample Page/m, 'dashboard page new emits bookmark instruction text' );

    _write_text( '/tmp/sample.bookmark', $page_new->{stdout} );
    my $page_save = _run_shell( 'dashboard page save', $project_cd . q{dashboard page save sample < /tmp/sample.bookmark} );
    _assert_match( $page_save->{stdout}, qr/sample$/, 'dashboard page save writes bookmark file' );
    _assert( -f File::Spec->catfile( $bookmarks, 'sample' ), 'dashboard page save wrote into fake project bookmark root' );

    my $page_list = _run_shell( 'dashboard page list', $project_cd . 'dashboard page list' );
    _assert_match( $page_list->{stdout}, qr/"sample"/, 'dashboard page list includes saved sample page' );
    _assert_match( $page_list->{stdout}, qr/"project-home"/, 'dashboard page list includes fake project bookmark page' );

    my $page_show = _run_shell( 'dashboard page show', $project_cd . 'dashboard page show sample' );
    _assert_match( $page_show->{stdout}, qr/^BOOKMARK:\s+sample/m, 'dashboard page show returns canonical bookmark source' );

    my $page_encode = _run_shell( 'dashboard page encode', $project_cd . 'dashboard page encode sample' );
    my $token = _trim( $page_encode->{stdout} );
    _assert( $token ne '', 'dashboard page encode returns a token' );

    my $page_decode = _run_shell( 'dashboard page decode', $project_cd . 'dashboard page decode ' . _shell_quote($token) );
    _assert_match( $page_decode->{stdout}, qr/^BOOKMARK:\s+sample/m, 'dashboard page decode restores bookmark source' );

    my $page_urls = _run_shell( 'dashboard page urls', $project_cd . 'dashboard page urls sample' );
    _assert_match( $page_urls->{stdout}, qr/"render"/, 'dashboard page urls returns edit and render links' );

    my $page_render = _run_shell( 'dashboard page render', $project_cd . 'dashboard page render sample' );
    _assert_match( $page_render->{stdout}, qr/Replace this body with your own page content/, 'dashboard page render produces html output' );

    my $page_source = _run_shell( 'dashboard page source', $project_cd . 'dashboard page source sample' );
    _assert_match( $page_source->{stdout}, qr/^BOOKMARK:\s+sample/m, 'dashboard page source returns instruction text' );

    my $action = _run_shell( 'dashboard action run system-status paths', $project_cd . 'dashboard action run system-status paths' );
    _assert_match( $action->{stdout}, qr/runtime/, 'dashboard action run executes builtin action' );

    my $collector_write = _run_shell( 'dashboard collector write-result', $project_cd . q{printf 'manual-output' | dashboard collector write-result manual.collector 0} );
    _assert( $collector_write->{exit_code} == 0, 'dashboard collector write-result accepts manual output' );

    my $fake_collector_run = _run_shell( 'dashboard collector run fake.config.collector', $project_cd . 'dashboard collector run fake.config.collector' );
    _assert_match( $fake_collector_run->{stdout}, qr/"exit_code"\s*:\s*0/, 'dashboard collector run succeeds for fake project config collector' );

    my $collector_list = _run_shell( 'dashboard collector list', $project_cd . 'dashboard collector list' );
    _assert_match( $collector_list->{stdout}, qr/manual\.collector/, 'dashboard collector list shows stored collectors' );
    _assert_match( $collector_list->{stdout}, qr/fake\.config\.collector/, 'dashboard collector list shows fake project config collector' );

    my $collector_job = _run_shell( 'dashboard collector job', $project_cd . 'dashboard collector job fake.config.collector' );
    _assert_match( $collector_job->{stdout}, qr/"command"/, 'dashboard collector job returns job metadata' );

    my $collector_status = _run_shell( 'dashboard collector status', $project_cd . 'dashboard collector status fake.config.collector' );
    _assert_match( $collector_status->{stdout}, qr/"enabled"/, 'dashboard collector status returns status data' );

    my $collector_output = _run_shell( 'dashboard collector output', $project_cd . 'dashboard collector output fake.config.collector' );
    _assert_match( $collector_output->{stdout}, qr/fake config collector output/, 'dashboard collector output returns prepared output' );

    my $collector_inspect = _run_shell( 'dashboard collector inspect', $project_cd . 'dashboard collector inspect fake.config.collector' );
    _assert_match( $collector_inspect->{stdout}, qr/"job"|"status"|"output"/, 'dashboard collector inspect returns combined view' );

    my $collector_start = _run_shell( 'dashboard collector start', $project_cd . 'dashboard collector start fake.config.collector' );
    _assert_match( $collector_start->{stdout}, qr/\d+/, 'dashboard collector start returns a pid' );

    sleep 2;

    my $collector_restart = _run_shell( 'dashboard collector restart', $project_cd . 'dashboard collector restart fake.config.collector' );
    _assert_match( $collector_restart->{stdout}, qr/\d+/, 'dashboard collector restart returns a pid' );

    my $collector_stop = _run_shell( 'dashboard collector stop', $project_cd . 'dashboard collector stop fake.config.collector' );
    _assert_match( $collector_stop->{stdout}, qr/\d+/, 'dashboard collector stop returns the stopped pid' );

    my $collector_log = _run_shell( 'dashboard collector log', $project_cd . 'dashboard collector log' );
    _assert( defined $collector_log->{stdout}, 'dashboard collector log returns log text' );

    my $auth_add = _run_shell( 'dashboard auth add-user', $project_cd . q{dashboard auth add-user explicit_helper explicit-pass-123} );
    _assert_match( $auth_add->{stdout}, qr/"username"\s*:\s*"explicit_helper"/, 'dashboard auth add-user creates helper user' );

    my $auth_list = _run_shell( 'dashboard auth list-users', $project_cd . 'dashboard auth list-users' );
    _assert_match( $auth_list->{stdout}, qr/"explicit_helper"/, 'dashboard auth list-users includes explicit helper' );

    my $auth_remove = _run_shell( 'dashboard auth remove-user', $project_cd . 'dashboard auth remove-user explicit_helper' );
    _assert_match( $auth_remove->{stdout}, qr/"removed"\s*:\s*"explicit_helper"/, 'dashboard auth remove-user removes explicit helper' );

    my $docker_dry = _run_shell(
        'dashboard docker compose --dry-run',
        'dashboard docker compose --project ' . _shell_quote($compose) . ' --dry-run config'
    );
    _assert_match( $docker_dry->{stdout}, qr/"command"\s*:/, 'dashboard docker compose dry-run returns resolved command' );
    _assert_match( $docker_dry->{stdout}, qr/compose\.yaml/, 'dashboard docker compose dry-run includes compose file' );

    my $serve = _run_shell( 'dashboard serve', $project_cd . 'dashboard serve' );
    _assert_match( $serve->{stdout}, qr/"pid"\s*:/, 'dashboard serve starts background web service' );
    _wait_for_http( 'http://127.0.0.1:7890/', 200 );

    my $blocked_transient = _run_shell(
        'curl transient token denied by default',
        'curl -sS -o /tmp/transient-denied.body -w \'%{http_code}\' ' . _shell_quote( 'http://127.0.0.1:7890/?token=' . $token ),
    );
    _assert_match( $blocked_transient->{stdout}, qr/^403$/, 'loopback transient token route is denied by default' );
    _assert_match( _read_text('/tmp/transient-denied.body'), qr/Transient token URLs are disabled/, 'loopback transient token denial explains the policy' );

    my $root = _run_shell( 'curl loopback root', q{curl -fsS http://127.0.0.1:7890/} );
    _assert_match( $root->{stdout}, qr/instruction-editor/, 'loopback root serves the bookmark editor' );
    my $root_dom = _run_browser_dom( 'browser loopback root', 'http://127.0.0.1:7890/', user_data_dir => $profile );
    _assert_match( $root_dom, qr/instruction-editor/, 'browser loopback root renders the editor DOM' );
    _assert_match( $root_dom, qr/TITLE:\s+Developer Dashboard/, 'browser loopback root shows bookmark source text' );

    my $project_dom = _run_browser_dom( 'browser fake project page', 'http://127.0.0.1:7890/app/project-home', user_data_dir => $profile );
    _assert_match( $project_dom, qr/project-marker/, 'browser renders fake project bookmark page' );
    _assert_match( $project_dom, qr/Fake Project Home/, 'browser renders fake project bookmark content' );
    _assert_match( $project_dom, qr/dashboard-nav-items/, 'browser renders shared nav container on fake project bookmark page' );
    _assert_match( $project_dom, qr/Alpha Nav Current/, 'browser renders shared nav TT output against the outer page path' );
    _assert_match( $project_dom, qr{<div id="nav-beta">/app/project-home / /app/project-home</div>}, 'browser exposes current_page through env and env.runtime_context for shared nav TT fragments' );
    _assert( index( $project_dom, 'nav-alpha' ) < index( $project_dom, 'nav-beta' ), 'browser renders shared nav bookmark fragments in sorted filename order' );
    _assert( index( $project_dom, 'dashboard-nav-items' ) < index( $project_dom, 'project-marker' ), 'browser renders shared nav fragments before the main page body' );
    my $legacy_ajax_page = _run_shell( 'curl legacy ajax saved page', q{curl -fsS http://127.0.0.1:7890/app/legacy-ajax} );
    _assert_match( $legacy_ajax_page->{stdout}, qr{/ajax/project-endpoint\.json\?type=text}, 'saved bookmark Ajax renders a stable file-backed ajax endpoint by default' );
    my $legacy_ajax_saved = _run_shell( 'curl saved bookmark ajax endpoint', q{curl -fsS 'http://127.0.0.1:7890/ajax/project-endpoint.json?type=text'} );
    _assert_match( $legacy_ajax_saved->{stdout}, qr/saved-start/, 'saved bookmark ajax endpoint streams direct perl stdout' );
    _assert_match( $legacy_ajax_saved->{stdout}, qr/saved-warn/, 'saved bookmark ajax endpoint streams perl stderr warnings' );
    _assert_match( $legacy_ajax_saved->{stdout}, qr/saved-child-out/, 'saved bookmark ajax endpoint streams child stdout' );
    _assert_match( $legacy_ajax_saved->{stdout}, qr/saved-child-err/, 'saved bookmark ajax endpoint streams child stderr' );
    _assert_match( $legacy_ajax_saved->{stdout}, qr/saved-die/, 'saved bookmark ajax endpoint streams uncaught perl die output' );
    my $legacy_ajax_stream_page = _run_shell( 'curl legacy ajax stream saved page', q{curl -fsS http://127.0.0.1:7890/app/legacy-ajax-stream} );
    _assert_match( $legacy_ajax_stream_page->{stdout}, qr{/ajax/project-stream\.txt\?type=text}, 'saved bookmark ajax stream page renders a stable default text ajax endpoint' );
    my $legacy_ajax_stream = _capture_stream_prefix(
        'curl saved bookmark ajax stream endpoint',
        q{curl --no-buffer -fsS 'http://127.0.0.1:7890/ajax/project-stream.txt'},
        expected_chunks => [ 'stream1', 'stream2' ],
        timeout         => 4,
    );
    _assert( @{ $legacy_ajax_stream->{events} || [] } >= 2, 'saved bookmark ajax stream endpoint produced multiple early chunks before process exit' );
    _assert( ( $legacy_ajax_stream->{events}[0]{at} || 99 ) < 1.5, 'saved bookmark ajax stream endpoint flushes the first chunk before the long-running ajax loop finishes' );
    _assert( ( $legacy_ajax_stream->{events}[1]{at} || 99 ) < 2.5, 'saved bookmark ajax stream endpoint keeps flushing later chunks during the long-running ajax loop' );

    my $container_ip = _trim( _run_shell( 'container ip', q{hostname -I | awk '{print $1}'} )->{stdout} );
    _assert( $container_ip ne '', 'container ip discovered for helper-access path' );

    my $helper_root_disabled = _run_shell(
        'curl helper root before helper user exists',
        'curl -sS -o /tmp/helper-root.html -w \'%{http_code}\' http://' . $container_ip . ':7890/'
    );
    _assert_match( $helper_root_disabled->{stdout}, qr/^401$/, 'non-loopback self-access stays unauthorized before any helper user exists' );
    _assert( _read_text('/tmp/helper-root.html') eq q{}, 'outsider bootstrap response keeps the body empty before any helper user exists' );
    _assert( _read_text('/tmp/helper-root.html') !~ /<form[^>]*action="\/login"/, 'outsider bootstrap response does not expose the login form before any helper user exists' );
    my $helper_disabled_dom = _run_browser_dom( 'browser helper root before helper user exists', "http://$container_ip:7890/", user_data_dir => $profile );
    _assert_match( $helper_disabled_dom, qr/HTTP ERROR 401/, 'browser outsider bootstrap response resolves to a generic 401 browser error page before any helper user exists' );
    _assert( $helper_disabled_dom !~ /Helper access is disabled until a helper user is added\./, 'browser outsider bootstrap response does not leak helper bootstrap guidance before any helper user exists' );
    _assert( $helper_disabled_dom !~ /action="\/login"/, 'browser outsider bootstrap response omits the login form before any helper user exists' );

    _run_shell( 'dashboard auth add helper-login user', $project_cd . q{dashboard auth add-user helper_login helper-login-pass-123} );
    my $helper_root = _run_shell(
        'curl helper root after helper user exists',
        'curl -sS -o /tmp/helper-root-after-enable.html -w \'%{http_code}\' http://' . $container_ip . ':7890/'
    );
    _assert_match( $helper_root->{stdout}, qr/^401$/, 'non-loopback self-access returns helper login after a helper user exists' );
    _assert_match( _read_text('/tmp/helper-root-after-enable.html'), qr/<form[^>]*action="\/login"/, 'helper root serves login page after a helper user exists' );
    my $helper_dom = _run_browser_dom( 'browser helper root after helper user exists', "http://$container_ip:7890/", user_data_dir => $profile );
    _assert_match( $helper_dom, qr/action="\/login"/, 'browser helper root renders login form after a helper user exists' );

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
        'curl -fsS -b ' . _shell_quote($cookie) . ' http://' . $container_ip . ':7890/app/api-dashboard'
    );
    _assert_match( $helper_page->{stdout}, qr/id="logout-url"/, 'helper page chrome renders logout link' );

    my $helper_logout = _run_shell(
        'helper logout',
        'curl -sS -b ' . _shell_quote($cookie) . ' -o /tmp/helper-logout.body -D /tmp/helper-logout.headers http://' . $container_ip . ':7890/logout'
    );
    _assert( $helper_logout->{exit_code} == 0, 'helper logout request completed' );
    _assert_match( _read_text('/tmp/helper-logout.headers'), qr/^HTTP\/1\.1 302/m, 'helper logout redirects to login' );

    my $post_logout_users = _run_shell( 'dashboard auth list-users after logout', $project_cd . 'dashboard auth list-users' );
    _assert( $post_logout_users->{stdout} !~ /helper_login/, 'helper logout removes helper account from auth store' );

    my $restart = _run_shell( 'dashboard restart', $project_cd . 'dashboard restart' );
    _assert_match( $restart->{stdout}, qr/"web_pid"\s*:/, 'dashboard restart returns structured lifecycle data' );
    _wait_for_http( 'http://127.0.0.1:7890/', 200 );

    sleep 2;

    my $restart_collectors = _run_shell( 'dashboard collector list after restart', $project_cd . 'dashboard collector list' );
    my $restart_collectors_data = decode_json( $restart_collectors->{stdout} );
    my %restart_collectors_by_name = map { ( $_->{name} || '' ) => $_ } @{$restart_collectors_data};
    _assert( exists $restart_collectors_by_name{'broken.collector'}, 'restart keeps the broken config collector visible in collector state' );
    _assert( exists $restart_collectors_by_name{'healthy.collector'}, 'restart keeps the healthy config collector visible in collector state' );
    my $broken_exit_code = defined $restart_collectors_by_name{'broken.collector'}{last_exit_code}
      ? $restart_collectors_by_name{'broken.collector'}{last_exit_code}
      : 0;
    my $healthy_exit_code = defined $restart_collectors_by_name{'healthy.collector'}{last_exit_code}
      ? $restart_collectors_by_name{'healthy.collector'}{last_exit_code}
      : 255;
    _assert( $broken_exit_code != 0, 'broken config collector keeps a non-zero exit code after restart' );
    _assert( $healthy_exit_code == 0, 'healthy config collector stays green after restart' );

    my $restart_indicators = _run_shell( 'dashboard indicator list after restart', $project_cd . 'dashboard indicator list' );
    _assert_match( $restart_indicators->{stdout}, qr/"name"\s*:\s*"broken\.indicator"(?s:.*?)"status"\s*:\s*"error"/, 'broken config collector indicator stays red after restart' );
    _assert_match( $restart_indicators->{stdout}, qr/"name"\s*:\s*"healthy\.indicator"(?s:.*?)"status"\s*:\s*"ok"/, 'healthy config collector indicator stays green after restart' );

    my $restart_ps1 = _run_shell( 'dashboard ps1 after restart', 'cd ' . _shell_quote($project) . ' && dashboard ps1 --jobs 0 --cwd ' . _shell_quote($project) );
    _assert_match( $restart_ps1->{stdout}, qr/🚨B/, 'prompt keeps the broken config collector visible after restart' );
    _assert_match( $restart_ps1->{stdout}, qr/✅H/, 'prompt keeps the healthy config collector visible after restart' );

    my $restart_status = _run_shell( 'curl system status after restart', q{curl -fsS http://127.0.0.1:7890/system/status} );
    _assert_match( $restart_status->{stdout}, qr/"prog"\s*:\s*"broken\.indicator"/, 'system status payload includes the broken config collector indicator' );
    _assert_match( $restart_status->{stdout}, qr/"prog"\s*:\s*"healthy\.indicator"/, 'system status payload includes the healthy config collector indicator' );

    my $stop = _run_shell( 'dashboard stop', $project_cd . 'dashboard stop' );
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
# Runs one shell command, streams stdout and stderr live, and returns structured command results.
# Input: human label, shell command string, and optional allow_fail flag.
# Output: hash reference with command, stdout, stderr, and exit_code.
sub _run_shell {
    my ( $label, $command, %opts ) = @_;
    print "==> $label\n";
    print "    $command\n";
    my $stderr_fh = gensym();
    my $pid = open3( undef, my $stdout_fh, $stderr_fh, 'sh', '-lc', $command );
    my $selector = IO::Select->new( $stdout_fh, $stderr_fh );
    my $stdout = '';
    my $stderr = '';
    my $stdout_fd = fileno($stdout_fh);
    my $stderr_fd = fileno($stderr_fh);

    while ( my @ready = $selector->can_read ) {
        for my $fh (@ready) {
            my $buffer = '';
            my $read = sysread( $fh, $buffer, 8192 );
            if ( !defined $read || $read == 0 ) {
                $selector->remove($fh);
                close $fh;
                next;
            }
            if ( defined fileno($fh) && fileno($fh) == $stdout_fd ) {
                $stdout .= $buffer;
                print $buffer;
                next;
            }
            if ( defined fileno($fh) && fileno($fh) == $stderr_fd ) {
                $stderr .= $buffer;
                print STDERR $buffer;
                next;
            }
        }
    }

    waitpid( $pid, 0 );
    my $exit_code = $? >> 8;
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

# _capture_stream_prefix($label, $command, %opts)
# Runs one streaming shell command and records when expected stdout chunks first appear.
# Input: human label, shell command string, expected_chunks array ref, and optional timeout seconds.
# Output: hash reference with stdout, stderr, and matched event timing data.
sub _capture_stream_prefix {
    my ( $label, $command, %opts ) = @_;
    my $expected = $opts{expected_chunks} || [];
    my $timeout  = $opts{timeout} || 5;
    print "==> $label\n";
    print "    $command\n";
    my $stderr_fh = gensym();
    my $pid = open3( undef, my $stdout_fh, $stderr_fh, 'sh', '-lc', $command );
    my $selector = IO::Select->new( $stdout_fh, $stderr_fh );
    my $stdout = '';
    my $stderr = '';
    my $stdout_fd = fileno($stdout_fh);
    my $stderr_fd = fileno($stderr_fh);
    my @events;
    my $start = time;
    my $deadline = $start + $timeout;

    while ( $selector->count && @events < @{$expected} && time < $deadline ) {
        my @ready = $selector->can_read(0.25);
        next if !@ready;
        for my $fh (@ready) {
            my $buffer = '';
            my $read = sysread( $fh, $buffer, 8192 );
            if ( !defined $read || $read == 0 ) {
                $selector->remove($fh);
                close $fh;
                next;
            }
            if ( defined fileno($fh) && fileno($fh) == $stdout_fd ) {
                $stdout .= $buffer;
                print $buffer;
                while ( @events < @{$expected} && index( $stdout, $expected->[@events] ) >= 0 ) {
                    push @events, {
                        chunk => $expected->[@events],
                        at    => time - $start,
                    };
                }
                next;
            }
            if ( defined fileno($fh) && fileno($fh) == $stderr_fd ) {
                $stderr .= $buffer;
                print STDERR $buffer;
            }
        }
    }

    kill 'TERM', $pid;
    waitpid( $pid, 0 );

    return {
        stdout => $stdout,
        stderr => $stderr,
        events => \@events,
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
    my $browser = _browser_binary();
    return join ' ',
      _shell_quote($browser),
      '--headless',
      '--no-sandbox',
      '--disable-gpu',
      '--disable-dev-shm-usage',
      '--virtual-time-budget=3000',
      '--user-data-dir=' . _shell_quote($profile),
      '--dump-dom',
      _shell_quote($url);
}

# _browser_binary()
# Resolves one available headless browser binary, installing Chromium when the image lacks one.
# Input: none.
# Output: absolute browser executable path string.
sub _browser_binary {
    return $BROWSER_BINARY if defined $BROWSER_BINARY && $BROWSER_BINARY ne '';

    for my $candidate ( qw(chromium chromium-browser google-chrome google-chrome-stable) ) {
        my $probe = _run_shell(
            "probe browser $candidate",
            "command -v $candidate",
            allow_fail => 1,
        );
        my $path = _trim( $probe->{stdout} );
        if ( $probe->{exit_code} == 0 && $path ne '' ) {
            $BROWSER_BINARY = $path;
            return $BROWSER_BINARY;
        }
    }

    _run_shell(
        'install chromium fallback',
        'apt-get update && apt-get install -y --no-install-recommends chromium',
    );

    my $installed = _run_shell(
        'probe installed chromium fallback',
        'command -v chromium',
        allow_fail => 1,
    );
    my $path = _trim( $installed->{stdout} );
    die "Unable to find a headless browser binary after installing chromium\n"
      if $installed->{exit_code} != 0 || $path eq '';

    $BROWSER_BINARY = $path;
    return $BROWSER_BINARY;
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

# _distribution_version($source_root)
# Reads the extracted distribution version from the main module file.
# Input: extracted source root directory path string.
# Output: version string or undef when it cannot be found.
sub _distribution_version {
    my ($source_root) = @_;
    return if !defined $source_root || $source_root eq '';
    my $module = File::Spec->catfile( $source_root, 'lib', 'Developer', 'Dashboard.pm' );
    return if !-f $module;
    my $text = _read_text($module);
    return $1 if $text =~ /our \$VERSION = '([^']+)'/;
    return;
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

=head2 main, _run_shell, _wait_for_http, _run_browser_dom, _browser_command, _browser_binary, _single_subdir, _decode_json_tail, _reset_dir, _write_text, _read_text, _trim, _shell_quote, _assert, _assert_match

Run and validate the host-built-tarball integration workflow.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Integration helper script in the Developer Dashboard codebase. This file drives the blank-environment tarball install and smoke verification flow inside the disposable integration container.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to make a repeatable host-or-container integration workflow explicit instead of burying release verification steps in ad-hoc shell history.

=head1 WHEN TO USE

Use this file when you are rerunning the documented integration workflow for its environment or debugging a release/install problem in that path.

=head1 HOW TO USE

Run the script as part of the documented integration plan for its environment. Treat failures here as release blockers, because these scripts represent the supported rerun path.

=head1 WHAT USES IT

It is used by maintainers running the documented install/runtime verification workflow for that environment, and by tests that validate the checked-in integration assets.

=head1 EXAMPLES

  perl integration/blank-env/run-integration.pl

Run the script from the documented integration environment so it can find the expected tarball, browser, or container prerequisites.

=for comment FULL-POD-DOC END

=cut
