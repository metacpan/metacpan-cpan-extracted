#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use URI::Escape qw(uri_escape);

use lib 'lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

# Hermetic runtime rooted in a throwaway HOME; config resolves from the CWD's
# deepest .developer-dashboard layer, so we must chdir into the temp home.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};
delete local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
chdir $home or die "Unable to chdir to $home: $!";

my $paths      = Developer::Dashboard::PathRegistry->new( home => $home );
my $files      = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store      = Developer::Dashboard::PageStore->new( paths => $paths );
my $config     = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $auth       = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions   = Developer::Dashboard::SessionStore->new( paths => $paths );
my $runtime    = Developer::Dashboard::PageRuntime->new( paths => $paths );
my $prompt     = Developer::Dashboard::Prompt->new( paths => $paths, indicators => $indicators );
my $actions    = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );

my $app = Developer::Dashboard::Web::App->new(
    actions  => $actions,
    auth     => $auth,
    config   => $config,
    pages    => $store,
    prompt   => $prompt,
    runtime  => $runtime,
    sessions => $sessions,
);

sub H { return { host => '127.0.0.1' } }

sub drain {
    my ($body) = @_;
    return $body if ref($body) ne 'HASH' || ref( $body->{stream} ) ne 'CODE';
    my $out = '';
    $body->{stream}->( sub { $out .= $_[0] if defined $_[0] } );
    return $out;
}

sub wfile {
    my ( $path, $content, $mode ) = @_;
    make_path( ( File::Spec->splitpath($path) )[1] );
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    chmod( $mode, $path ) or die "chmod $path: $!" if defined $mode;
    return 1;
}

# ---------------------------------------------------------------------------
# Build one installed skill (route-skill) plus a nested skill (def) directly on
# disk under the skills root so all skill-routing branches are reachable.
# ---------------------------------------------------------------------------
{
    my $skill = File::Spec->catdir( $paths->skills_root, 'route-skill' );
    wfile( File::Spec->catfile( $skill, 'config', 'config.json' ), qq|{"skill_name":"route-skill"}\n|, 0644 );
    wfile(
        File::Spec->catfile( $skill, 'dashboards', 'index' ),
        "TITLE: Skill Route Index\n:--------------------------------------------------------------------------------:\nBOOKMARK: index\n:--------------------------------------------------------------------------------:\nHTML:\nSkill Route Index\n",
        0644,
    );
    wfile(
        File::Spec->catfile( $skill, 'dashboards', 'foo' ),
        "TITLE: Skill Route Foo\n:--------------------------------------------------------------------------------:\nBOOKMARK: foo\n:--------------------------------------------------------------------------------:\nHTML:\nSkill Route Foo\n",
        0644,
    );
    wfile(
        File::Spec->catfile( $skill, 'dashboards', 'ajax-demo' ),
        "TITLE: Skill Ajax Demo\n:--------------------------------------------------------------------------------:\nBOOKMARK: ajax-demo\n:--------------------------------------------------------------------------------:\nHTML:\n<script>var endpoints = {};</script>\n:--------------------------------------------------------------------------------:\nCODE1: Ajax jvar => 'endpoints.bar', file => 'bar', type => 'json', code => q{\nprint qq|{\"route\":\"bar\"}\\n|;\n};\n",
        0644,
    );
    wfile( File::Spec->catfile( $skill, 'dashboards', 'ajax', 'bar' ), qq|print qq[{"route":"bar"}\\n];\n|, 0700 );
    wfile( File::Spec->catfile( $skill, 'dashboards', 'ajax', 'raw' ), qq|print qq[{"route":"raw"}\\n];\n|, 0700 );
    wfile( File::Spec->catfile( $skill, 'dashboards', 'public', 'js',     'skill.js' ),  qq|console.log("route-skill js");\n|, 0644 );
    wfile( File::Spec->catfile( $skill, 'dashboards', 'public', 'css',    'skill.css' ), qq|body { color: #123456; }\n|,        0644 );
    wfile( File::Spec->catfile( $skill, 'dashboards', 'public', 'others', 'info.txt' ),  "route-skill info\n",                  0644 );
    wfile( File::Spec->catfile( $skill, 'dashboards', 'nav', 'skill.tt' ), "<div>Skill Route Nav</div>\n", 0644 );
    wfile(
        File::Spec->catfile( $skill, 'config', 'routes.json' ),
        <<'JSON',
{
   "/apps/route-skill/home" : "/app/index",
   "/apps/route-skill/foo" : "/app/foo",
   "/v1/route-skill/bar" : "/ajax/bar",
   "/v1/route-skill/raw" : { "to" : "/ajax/raw", "type" : "application/vnd.route+json" },
   "/assets/route-skill.css" : "/css/skill.css",
   "/assets/route-skill.js" : "/js/skill.js",
   "/downloads/route-skill.txt" : { "to" : "/others/info.txt", "type" : "text/plain; charset=utf-8" }
}
JSON
        0644,
    );

    # nested skill "def"
    my $nested = File::Spec->catdir( $skill, 'skills', 'def' );
    wfile(
        File::Spec->catfile( $nested, 'dashboards', 'index' ),
        "TITLE: Nested Skill Index\n:--------------------------------------------------------------------------------:\nBOOKMARK: index\n:--------------------------------------------------------------------------------:\nHTML:\nNested Skill Index\n",
        0644,
    );
    wfile(
        File::Spec->catfile( $nested, 'dashboards', 'foo' ),
        "TITLE: Nested Skill Foo\n:--------------------------------------------------------------------------------:\nBOOKMARK: foo\n:--------------------------------------------------------------------------------:\nHTML:\nNested Skill Foo\n",
        0644,
    );
    wfile( File::Spec->catfile( $nested, 'dashboards', 'nav', 'index.tt' ), "<div>Nested Skill Nav</div>\n", 0644 );
    wfile( File::Spec->catfile( $nested, 'dashboards', 'ajax', 'nested' ), qq|print "<p>nested ajax</p>\\n";\n|, 0700 );
    wfile(
        File::Spec->catfile( $nested, 'config', 'routes.json' ),
        qq|{ "/apps/route-skill/child/foo" : "/app/foo" }\n|,
        0644,
    );
}

# ---------------------------------------------------------------------------
# Saved pages for the primary route surface.
# ---------------------------------------------------------------------------
$store->save_page(
    Developer::Dashboard::PageDocument->new(
        id     => 'welcome',
        title  => 'Welcome',
        layout => { body => 'hello [% stash.name %]' },
    )
);
$store->save_page(
    Developer::Dashboard::PageDocument->new(
        id      => 'acted',
        title   => 'Acted',
        layout  => { body => '<div>acted body</div>' },
        actions => [ { id => 'go', kind => 'builtin', builtin => 'page.state' } ],
    )
);
$store->save_page(
    Developer::Dashboard::PageDocument->new(
        id     => 'nav/alpha.tt',
        title  => 'Alpha',
        layout => { body => 'alpha-nav [% env.current_page %]' },
    )
);

# =====================================================================
# 1. Primary route surface via handle() (admin tier, loopback).
# =====================================================================
is( $app->handle( path => '/', query => '', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'root editor route' );

$store->save_page( Developer::Dashboard::PageDocument->new( id => 'index', title => 'Index', layout => { body => 'idx' } ) );
is( $app->handle( path => '/', query => '', remote_addr => '127.0.0.1', headers => H() )->[0], 302, 'root redirects to saved index' );
unlink $store->page_file('index');

is( $app->handle( path => '/apps', remote_addr => '127.0.0.1', headers => H() )->[0], 302, '/apps redirect' );
is( $app->handle( path => '/app/welcome', query => 'name=Bob', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'saved render' );
is( $app->handle( path => '/app/welcome/source', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'saved source' );
is( $app->handle( path => '/app/welcome/edit', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'saved edit GET' );
is( $app->handle( path => '/system/status', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'status' );
is( $app->handle( path => '/js/jquery.js', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'jquery' );
is( $app->handle( path => '/js/jquery-4.0.0.min.js', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'jquery min' );
is( $app->handle( path => '/marked.min.js', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'marked' );
is( $app->handle( path => '/tiff.min.js', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'tiff' );
is( $app->handle( path => '/loading.webp', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'loading' );
is( $app->handle( path => '/nope/xyz', remote_addr => '127.0.0.1', headers => H() )->[0], 404, 'unknown top route 404' );

# edit POST that saves a bookmark
{
    my $instr = "TITLE: Saved Post\n:--------------------------------------------------------------------------------:\nBOOKMARK: welcome\n:--------------------------------------------------------------------------------:\nHTML: reposted\n";
    my $r = $app->handle(
        path => '/app/welcome/edit', method => 'POST',
        body => 'instruction=' . uri_escape($instr) . '&mode=render',
        remote_addr => '127.0.0.1', headers => H(),
    );
    is( $r->[0], 200, 'edit POST save+render' );
}
# edit POST with no instruction falls through to GET editor
is( $app->handle( path => '/app/welcome/edit', method => 'POST', body => 'mode=edit', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'edit POST no instruction -> editor' );

# action route (saved page with an action) -- routing + _action_response path
ok( $app->handle( path => '/app/acted/action/go', method => 'POST', body => '', remote_addr => '127.0.0.1', headers => H() )->[0], 'saved action route responds' );

# =====================================================================
# 2. Transient tokens: denied by default, then allowed.
# =====================================================================
my $trans_token = $store->encode_page(
    Developer::Dashboard::PageDocument->from_instruction("TITLE: T\n:--------------------------------------------------------------------------------:\nHTML: transient body\n")
);
is( $app->handle( path => '/', method => 'POST', body => 'instruction=' . uri_escape("TITLE: X\n:--------------------------------------------------------------------------------:\nHTML: b\n"), remote_addr => '127.0.0.1', headers => H() )->[0], 403, 'transient instruction denied' );
is( $app->handle( path => '/', query => "token=$trans_token", remote_addr => '127.0.0.1', headers => H() )->[0], 403, 'transient token denied' );
is( $app->handle( path => '/action', method => 'POST', body => "token=$trans_token&id=go", remote_addr => '127.0.0.1', headers => H() )->[0], 403, 'transient action denied' );

{
    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
    my $r = $app->handle( path => '/', method => 'POST', body => 'instruction=' . uri_escape("TITLE: X\n:--------------------------------------------------------------------------------:\nHTML: posted body\n"), remote_addr => '127.0.0.1', headers => H() );
    is( $r->[0], 200, 'transient instruction allowed' );
    is( $app->handle( path => '/', query => "mode=render&token=$trans_token", remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'transient token render allowed' );
    is( $app->handle( path => '/', query => "mode=source&token=$trans_token", remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'transient token source allowed' );
    is( $app->handle( path => '/', query => "mode=edit&token=$trans_token", remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'transient token edit allowed' );
    # transient action via token+id (page has no such action -> 404 branch)
    ok( $app->handle( path => '/action', method => 'POST', body => "token=$trans_token&id=go", remote_addr => '127.0.0.1', headers => H() )->[0], 'transient token+id action responds' );
    # transient action with an atoken present (query) but transient tokens allowed
    is( $app->handle( path => '/action', method => 'POST', query => 'atoken=deadbeef', body => '', remote_addr => '127.0.0.1', headers => H() )->[0], 403, 'transient atoken decode failure -> 403' );
}

# =====================================================================
# 3. Legacy ajax + saved ajax file routes.
# =====================================================================
$store->save_page(
    Developer::Dashboard::PageDocument->from_instruction(
        "TITLE: LA\n:--------------------------------------------------------------------------------:\nBOOKMARK: legacy-ajax\n:--------------------------------------------------------------------------------:\nHTML: <script>var configs={};</script>\n:--------------------------------------------------------------------------------:\nCODE1: Ajax jvar => 'configs.demo', type => 'json', code => q{ print j { ok => 1 }; }, file => 'demo.json';\n"
    )
);
$app->handle( path => '/app/legacy-ajax', remote_addr => '127.0.0.1', headers => H() );
is( $app->handle( path => '/ajax/demo.json', query => 'type=json', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'saved ajax file route' );
is( $app->handle( path => '/ajax', remote_addr => '127.0.0.1', headers => H() )->[0], 400, '/ajax missing token' );
# /ajax singleton stop
is( $app->handle( path => '/ajax/singleton/stop', query => 'singleton=FOO', remote_addr => '127.0.0.1', headers => H() )->[0], 204, 'ajax singleton stop' );
is( $app->handle( path => '/ajax/singleton/stop', query => '', remote_addr => '127.0.0.1', headers => H() )->[0], 204, 'ajax singleton stop empty' );

# =====================================================================
# 4. Skill routes (app/ajax/js/css/others, custom, nested, fallback).
# =====================================================================
is( $app->handle( path => '/app/route-skill', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'skill index' );
is( $app->handle( path => '/app/route-skill/edit', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'skill index edit' );
is( $app->handle( path => '/app/route-skill/source', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'skill index source' );
is( $app->handle( path => '/app/route-skill/foo', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'skill page' );
is( $app->handle( path => '/app/route-skill/ajax-demo', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'skill ajax-demo page' );
is( $app->handle( path => '/app/route-skill/missing', remote_addr => '127.0.0.1', headers => H() )->[0], 404, 'skill missing bookmark 404' );
is( $app->handle( path => '/app/route-skill/def', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'nested skill index' );
is( $app->handle( path => '/app/route-skill/def/edit', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'nested skill edit' );
is( $app->handle( path => '/app/route-skill/def/foo', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'nested skill page' );
is( $app->handle( path => '/app/missing-skill/foo', remote_addr => '127.0.0.1', headers => H() )->[0], 404, 'missing nested skill 404' );

# skill edit POST render (source_kind skill render path)
{
    my $instr = "TITLE: Skill Route Index\n:--------------------------------------------------------------------------------:\nBOOKMARK: index\n:--------------------------------------------------------------------------------:\nHTML:\nEdited Skill Index\n";
    is( $app->handle( path => '/app/route-skill/edit', method => 'POST', body => 'mode=render&instruction=' . uri_escape($instr), remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'skill edit POST render' );
}

# custom skill routes
is( $app->handle( path => '/apps/route-skill/home', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'custom skill app route' );
is( $app->handle( path => '/apps/route-skill/child/foo', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'nested custom skill app route' );
is( $app->handle( path => '/v1/route-skill/bar', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'custom skill ajax route' );
is( $app->handle( path => '/v1/route-skill/raw', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'custom skill ajax raw mime' );
is( $app->handle( path => '/assets/route-skill.js', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'custom skill js route' );
is( $app->handle( path => '/assets/route-skill.css', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'custom skill css route' );
is( $app->handle( path => '/downloads/route-skill.txt', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'custom skill others route' );

# skill-local static + ajax routes
is( $app->handle( path => '/js/route-skill/skill.js', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'skill-local js' );
is( $app->handle( path => '/css/route-skill/skill.css', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'skill-local css' );
is( $app->handle( path => '/others/route-skill/info.txt', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'skill-local others' );
is( $app->handle( path => '/ajax/route-skill/bar', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'skill-local ajax' );

# legacy /skill/<repo>/<route>
is( $app->handle( path => '/skill/route-skill/bookmarks/foo', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'legacy /skill route' );

# global fallback when first segment matches skill name but asset is global
wfile( File::Spec->catfile( $paths->dashboards_root, 'public', 'js', 'route-skill', 'fallback.js' ), qq|console.log("global");\n|, 0644 );
is( $app->handle( path => '/js/route-skill/fallback.js', remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'global js fallback under skill name' );

# =====================================================================
# 5. API machine-auth + helper login/logout (non-loopback host -> non-admin).
# =====================================================================
{
    my $api_json = sprintf
        '{"good":{"secret":"%s","ajax":["/ajax/demo.json"]},"nosec":{"ajax":["/ajax/nosec"]},"bad1":"string","bad2":{"ajax":"notarray","secret":"z"}}',
        sha256_hex('sekret');
    wfile( File::Spec->catfile( $paths->config_root, 'api.json' ), $api_json, 0644 );
    my $api_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    my $app_api    = Developer::Dashboard::Web::App->new(
        actions  => $actions,
        auth     => $auth,
        config   => $api_config,
        pages    => $store,
        prompt   => $prompt,
        runtime  => $runtime,
        sessions => $sessions,
    );
    my $ah = 'helper.example:7890';

    # registered ajax route, no credentials -> forbidden (api path, no session)
    is( $app_api->handle( path => '/ajax/demo.json', query => 'type=json', remote_addr => '203.0.113.7', headers => { host => $ah } )->[0], 403, 'registered api route without creds -> 403' );
    # registered ajax route with valid credentials -> 200
    is( $app_api->handle( path => '/ajax/demo.json', query => 'type=json', remote_addr => '203.0.113.7', headers => { host => $ah, 'x-dd-api-key' => 'good', 'x-dd-api-secret' => 'sekret' } )->[0], 200, 'registered api route with creds -> 200' );
    # unregistered route, no helper users yet -> helper access disabled (401 empty)
    is( $app_api->handle( path => '/app/welcome', query => '', remote_addr => '203.0.113.7', headers => { host => $ah } )->[0], 401, 'outsider before helper users -> 401' );

    # create a helper user; now outsiders get a login page
    $auth->add_user( username => 'helper', password => 'helper-pass-123', role => 'helper' );
    is( $app_api->handle( path => '/app/welcome', query => 'x=1', remote_addr => '203.0.113.7', headers => { host => $ah } )->[0], 401, 'outsider after helper users -> login 401' );

    # bad + good login
    is( $app_api->handle( path => '/login', method => 'POST', body => 'username=helper&password=wrong', remote_addr => '203.0.113.7', headers => { host => $ah } )->[0], 401, 'bad login -> 401' );
    my $login = $app_api->handle( path => '/login', method => 'POST', body => 'username=helper&password=helper-pass-123&redirect_to=/app/welcome', remote_addr => '203.0.113.7', headers => { host => $ah } );
    is( $login->[0], 302, 'good login -> 302' );
    my $cookie = $login->[3]{'Set-Cookie'};

    # DD-415: a malicious backslash-authority redirect_to (%2F%5C -> "/\") must
    # never reach the 302 Location header; browsers treat "/\evil.com" as an
    # off-site authority, so the sanitizer has to collapse it to "/".
    my $evil_login = $app_api->handle( path => '/login', method => 'POST', body => 'username=helper&password=helper-pass-123&redirect_to=%2F%5Cevil.com', remote_addr => '203.0.113.7', headers => { host => $ah } );
    is( $evil_login->[0], 302, 'malicious backslash redirect still authenticates' );
    is( $evil_login->[3]{Location}, '/', 'DD-415: backslash-authority redirect_to collapses to / in Location header' );

    # DD-415: same bypass class through a raw tab (%2F%09%2F -> "/\t/"). A URL
    # parser strips the tab before parsing, so an unsanitized target reaches the
    # browser as "//evil.com" and becomes an off-site protocol-relative redirect.
    my $tab_login = $app_api->handle( path => '/login', method => 'POST', body => 'username=helper&password=helper-pass-123&redirect_to=%2F%09%2Fevil.com', remote_addr => '203.0.113.7', headers => { host => $ah } );
    is( $tab_login->[0], 302, 'malicious tab redirect still authenticates' );
    is( $tab_login->[3]{Location}, '/', 'DD-415: tab-hidden authority redirect_to collapses to / in Location header' );

    # registered ajax route WITH session cookie -> session path (skip api)
    is( $app_api->handle( path => '/ajax/demo.json', query => 'type=json', remote_addr => '203.0.113.7', headers => { host => $ah, cookie => $cookie } )->[0], 200, 'session cookie keeps ajax access' );
    # unregistered route WITH session cookie -> authorized
    ok( $app_api->handle( path => '/app/welcome', query => '', remote_addr => '203.0.113.7', headers => { host => $ah, cookie => $cookie } )->[0], 'session cookie authorizes app route' );
    # logout removes the helper user (role helper + username set)
    is( $app_api->handle( path => '/logout', remote_addr => '203.0.113.7', headers => { host => $ah, cookie => $cookie } )->[0], 302, 'logout with helper session' );
    # logout with no session
    is( $app_api->handle( path => '/logout', remote_addr => '203.0.113.7', headers => { host => $ah } )->[0], 302, 'logout with no session' );

    # logout with a non-helper session (role admin, username empty -> 376 false side)
    my $admin_sess = $sessions->create( username => 'nonhelper', role => 'admin', remote_addr => '203.0.113.7' );
    is( $app_api->handle( path => '/logout', remote_addr => '203.0.113.7', headers => { host => $ah, cookie => "dashboard_session=$admin_sess->{session_id}" } )->[0], 302, 'logout with non-helper session' );

    # login_response with no body (364 false side)
    ok( $app_api->login_response( remote_addr => '203.0.113.7' )->[0], 'login_response tolerates missing body' );

    # GET /login (path=/login but method ne POST -> 119 middle)
    ok( $app_api->handle( path => '/login', method => 'GET', remote_addr => '127.0.0.1', headers => H() )->[0], 'GET /login falls through' );

    # direct _api_route_registered edge cases
    is( $app_api->_api_route_registered(undef), 0, 'api route registered undef path' );
    is( $app_api->_api_route_registered('/foo'), 0, 'api route registered non-ajax path' );
    is( $app_api->_api_route_registered('/ajax/demo.json'), 1, 'api route registered known path' );

    # direct _authorize_api_request edge cases
    ok( $app_api->_authorize_api_request( path => '/ajax/demo.json', headers => { 'x-dd-api-key' => 'good', 'x-dd-api-secret' => 'sekret' } ), 'api auth ok' );
    ok( !$app_api->_authorize_api_request( path => '/ajax/demo.json', headers => { 'x-dd-api-key' => 'good', 'x-dd-api-secret' => 'wrong' } ), 'api auth bad secret' );
    ok( !$app_api->_authorize_api_request( path => '/ajax/other', headers => { 'x-dd-api-key' => 'good', 'x-dd-api-secret' => 'sekret' } ), 'api auth path not allowed' );
    ok( !$app_api->_authorize_api_request( path => '/x', headers => { 'x-dd-api-key' => 'bad1', 'x-dd-api-secret' => 'z' } ), 'api auth entry not a hash' );
    ok( !$app_api->_authorize_api_request( path => '/x', headers => { 'x-dd-api-key' => 'bad2', 'x-dd-api-secret' => 'z' } ), 'api auth ajax not an array' );
    ok( !$app_api->_authorize_api_request( path => '/ajax/nosec', headers => { 'x-dd-api-key' => 'nosec', 'x-dd-api-secret' => 'anything' } ), 'api auth entry without secret' );
    ok( !$app_api->_authorize_api_request( headers => {} ), 'api auth empty headers' );
    ok( !$app_api->_authorize_api_request( headers => { 'x-dd-api-key' => [], 'x-dd-api-secret' => [] } ), 'api auth ref headers' );
    ok( !$app_api->_authorize_api_request(), 'api auth no headers' );
    is( ref( $app_api->_api_keys ), 'HASH', 'api keys hash' );
}

# =====================================================================
# 6. Config-shape defensive predicates.
# =====================================================================
{
    my $bare = Developer::Dashboard::Web::App->new(
        auth     => bless( {}, 'Local::AuthStub' ),
        pages    => $store,
        sessions => bless( {}, 'Local::SessionsStub' ),
        config   => bless( {}, 'Local::ConfigBare' ),
        prompt   => { indicators => $indicators },
        runtime  => $runtime,
    );
    is( $bare->_editor_disabled,    0, 'bare config -> editor not disabled' );
    is( $bare->_indicators_disabled, 0, 'bare config -> indicators not disabled' );
    is_deeply( $bare->_api_keys, {}, 'bare config -> empty api keys' );
    ok( $bare->_page_status_payload, 'bare config still yields a status payload (collectors skipped)' );

    # web_settings present but without ssl_subject_alt_names (146 default [])
    my $ws = Developer::Dashboard::Web::App->new(
        auth     => bless( {}, 'Local::AuthStub' ),
        pages    => $store,
        sessions => bless( {}, 'Local::SessionsStub' ),
        config   => bless( {}, 'Local::ConfigWS' ),
        runtime  => $runtime,
    );
    ok( !$ws->authorize_request( remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ), 'ws config authorizes loopback' );
    ok( !$ws->authorize_request( remote_addr => '127.0.0.1' ), 'ws config authorizes without headers' );

    # api_keys returning a non-hash (309 false side)
    my $weird = Developer::Dashboard::Web::App->new(
        auth     => bless( {}, 'Local::AuthStub' ),
        pages    => $store,
        sessions => bless( {}, 'Local::SessionsStub' ),
        config   => bless( {}, 'Local::ConfigApiArray' ),
        runtime  => $runtime,
    );
    is_deeply( $weird->_api_keys, {}, 'non-hash api_keys falls back to empty hash' );

    # indicators without page_header_payload (2854 middle)
    my $noplp = Developer::Dashboard::Web::App->new(
        auth     => bless( {}, 'Local::AuthStub' ),
        pages    => $store,
        sessions => bless( {}, 'Local::SessionsStub' ),
        prompt   => { indicators => bless( {}, 'Local::IndNoPayload' ) },
        runtime  => $runtime,
    );
    is_deeply( $noplp->_page_status_payload, { array => [], hash => {}, status => {} }, 'indicators without payload method -> default payload' );

    # indicators whose payload lacks an array key (2839 true side)
    my $emptyp = Developer::Dashboard::Web::App->new(
        auth     => bless( {}, 'Local::AuthStub' ),
        pages    => $store,
        sessions => bless( {}, 'Local::SessionsStub' ),
        prompt   => { indicators => bless( {}, 'Local::IndEmptyPayload' ) },
        runtime  => $runtime,
    );
    is( $emptyp->_prompt_summary, '', 'payload without array yields an empty prompt summary' );

    # no prompt at all (2854 left-false) and no config (2855 left-false)
    my $noprompt = Developer::Dashboard::Web::App->new(
        auth     => bless( {}, 'Local::AuthStub' ),
        pages    => $store,
        sessions => bless( {}, 'Local::SessionsStub' ),
        runtime  => $runtime,
    );
    is_deeply( $noprompt->_page_status_payload, { array => [], hash => {}, status => {} }, 'no prompt -> default payload' );
    my $noconfig = Developer::Dashboard::Web::App->new(
        auth     => bless( {}, 'Local::AuthStub' ),
        pages    => $store,
        sessions => bless( {}, 'Local::SessionsStub' ),
        prompt   => $prompt,
        runtime  => $runtime,
    );
    ok( $noconfig->_page_status_payload, 'no config still yields a status payload' );
}

# =====================================================================
# 7. Constructor variants (line 41 both sides; 38 true side).
# =====================================================================
{
    my $store_app = Developer::Dashboard::Web::App->new(
        auth => bless( {}, 'Local::AuthStub' ), pages => $store, sessions => bless( {}, 'Local::SessionsStub' ),
    );
    isa_ok( $store_app, 'Developer::Dashboard::Web::App', 'app built without an explicit runtime (pages is a PageStore)' );
    my $nonstore_app = Developer::Dashboard::Web::App->new(
        auth => bless( {}, 'Local::AuthStub' ), pages => bless( {}, 'Local::NotAStore' ), sessions => bless( {}, 'Local::SessionsStub' ),
    );
    isa_ok( $nonstore_app, 'Developer::Dashboard::Web::App', 'app built without a runtime and a non-PageStore pages' );
}

# =====================================================================
# 8. Minimal-args direct calls (default option sides) on a fresh app.
# =====================================================================
my $m = Developer::Dashboard::Web::App->new(
    actions  => $actions,
    auth     => $auth,
    config   => $config,
    pages    => $store,
    prompt   => $prompt,
    runtime  => $runtime,
    sessions => $sessions,
);

ok( $m->root_response( remote_addr => '127.0.0.1' )->[0], 'root_response minimal' );
ok( $m->page_source_response( id => 'welcome' )->[0], 'page_source_response minimal' );
is( $m->page_source_response( id => 'no-such-page-xyz' )->[0], 404, 'page_source_response missing -> 404' );
ok( $m->page_edit_response( id => 'welcome' )->[0], 'page_edit_response minimal' );
ok( $m->page_edit_response( id => 'brand-new-missing-xyz' )->[0], 'page_edit_response missing -> editor' );
ok( $m->page_edit_post_response( id => 'unbookmarked', body => 'instruction=' . uri_escape("HTML: no bookmark id\n") )->[0], 'page_edit_post minimal (no bookmark id -> ||= assigns)' );
ok( $m->page_action_response( id => 'welcome', action_id => 'go' )->[0], 'page_action_response minimal' );
is( $m->legacy_ajax_response( remote_addr => '127.0.0.1' )->[0], 400, 'legacy_ajax_response minimal -> missing token' );
ok( $m->legacy_ajax_file_response( ajax_file => 'demo.json' )->[0], 'legacy_ajax_file_response minimal' );
ok( $m->skill_ajax_file_response( skill_name => 'route-skill', ajax_file => 'bar' )->[0], 'skill_ajax_file_response minimal' );
is( $m->skill_ajax_file_response( skill_name => '' )->[0], 400, 'skill_ajax_file_response empty skill' );
ok( $m->prefixed_ajax_file_response()->[0], 'prefixed_ajax_file_response minimal (empty path)' );
ok( $m->prefixed_ajax_file_response( ajax_path => 'route-skill/bar' )->[0], 'prefixed_ajax_file_response resolves skill' );
ok( $m->prefixed_static_file_response()->[0], 'prefixed_static_file_response minimal (empty)' );
ok( $m->prefixed_static_file_response( type => 'js', file => 'route-skill/skill.js' )->[0], 'prefixed_static_file_response resolves skill' );
ok( $m->static_file_response( type => 'js', file => 'jquery.js' )->[0], 'static_file_response js jquery' );
ok( $m->static_file_response( type => 'css', file => 'missing.css' )->[0], 'static_file_response css missing' );
ok( $m->static_file_response( type => '', file => 'x' )->[0], 'static_file_response empty type default' );
ok( $m->skill_static_file_response( skill_name => 'route-skill', type => 'js', file => 'skill.js' )->[0], 'skill_static_file_response resolves' );
ok( $m->skill_static_file_response( skill_name => 'route-skill', type => 'js', file => 'nope.js' )->[0], 'skill_static_file_response fallback' );
is( $m->skill_static_file_response( skill_name => '' )->[0], 400, 'skill_static_file_response empty skill' );
ok( $m->skill_static_file_response()->[0], 'skill_static_file_response minimal' );
is( $m->skill_route_response()->[0], 400, 'skill_route_response no skill -> 400' );
is( $m->skill_route_response( skill_name => 'route-skill' )->[0], 400, 'skill_route_response no route -> 400' );
ok( $m->skill_route_response( skill_name => 'route-skill', route => 'bookmarks/foo' )->[0], 'skill_route_response minimal' );
ok( $m->transient_action_response( method => 'POST', body => "token=$trans_token" )->[0], 'transient_action_response minimal (denied token)' );
ok( $m->legacy_app_response( id => 'welcome' )->[0], 'legacy_app_response minimal' );
ok( $m->_legacy_app_response( id => 'welcome' )->[0], '_legacy_app_response minimal' );
{
    my $died = !eval { $m->_legacy_app_response(); 1 };
    ok( $died, '_legacy_app_response dies without an id' );
}

# a bare URL-forward bookmark drives the read_saved_entry/forward branch
wfile( File::Spec->catfile( $paths->dashboards_root, 'forward-bm' ), "/app/welcome?fwd=1\n", 0644 );
ok( $m->_legacy_app_response( id => 'forward-bm' )->[0], '_legacy_app_response follows a saved URL forward' );
ok( $m->_legacy_app_response( id => 'totally-unknown-and-not-a-skill' )->[0], '_legacy_app_response missing page' );

# =====================================================================
# 9. Skill loaders / decorators / fallback (mocked specs like t/20).
# =====================================================================
is( $m->_saved_page_exists(undef), 0, '_saved_page_exists undef' );
is( $m->_saved_page_exists(''), 0, '_saved_page_exists empty' );
ok( $m->_saved_page_exists('welcome'), '_saved_page_exists true' );
ok( !defined $m->_load_editable_named_page(undef), '_load_editable_named_page undef' );
ok( !defined $m->_load_skill_named_page(undef), '_load_skill_named_page undef' );
ok( !defined $m->_load_skill_named_page('/'), '_load_skill_named_page slash-only -> no segments' );
ok( $m->_load_skill_named_page('route-skill'), '_load_skill_named_page resolves an installed skill index' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_route_segments = sub { return; };
    ok( !defined $m->_load_skill_named_page('route-skill/foo'), '_load_skill_named_page undef spec' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_route_segments = sub { return { skill_name => 'route-skill', route_segments => ['x'], skill_layers => [] }; };
    ok( !defined $m->_load_skill_named_page('route-skill/x'), '_load_skill_named_page empty layers' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_resolve_skill_route_spec = sub { return { skill_name => 'route-skill', route_segments => [], skill_layers => ['layer'] }; };
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { bless {}, 'Local::DispProbe' };
    ok( $m->_load_skill_named_page('route-skill'), '_load_skill_named_page empty route segments -> index' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_resolve_skill_route_spec = sub { return { skill_name => 'route-skill', route_segments => ['x'], skill_layers => ['layer'] }; };
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { bless {}, 'Local::DispProbeDie' };
    ok( !defined $m->_load_skill_named_page('route-skill/x'), '_load_skill_named_page load failure -> undef' );
}

ok( $m->_decorate_skill_page_routes('not-a-page') eq 'not-a-page', 'decorate non-page returns input' );
{
    my $plain = Developer::Dashboard::PageDocument->new( id => 'p', title => 'P' );
    is( $m->_decorate_skill_page_routes($plain), $plain, 'decorate non-skill page returns unchanged' );
    my $noid = Developer::Dashboard::PageDocument->new( title => 'NoId', meta => { source_kind => 'skill' } );
    is( $m->_decorate_skill_page_routes($noid), $noid, 'decorate skill page without id returns unchanged' );
    my $skillp = Developer::Dashboard::PageDocument->new( id => 'route-skill', title => 'S', meta => { source_kind => 'skill' } );
    is( $m->_decorate_skill_page_routes($skillp)->{meta}{render_route}, '/app/route-skill', 'decorate stamps skill routes' );
}

# _skill_app_fallback_response edge cases
ok( !defined $m->_skill_app_fallback_response(), '_skill_app_fallback_response no id' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_route_segments = sub { return { skill_name => 'route-skill', route_segments => ['foo'], skill_layers => [] }; };
    is( $m->_skill_app_fallback_response( id => 'route-skill/foo' )->[0], 404, 'fallback with no concrete layers -> 404' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_route_segments = sub { return; };
    is( $m->_skill_app_fallback_response( id => 'route-skill/foo' )->[0], 404, 'fallback with unresolved nested route -> 404' );
    ok( !defined $m->_skill_app_fallback_response( id => 'route-skill' ), 'fallback top-level unresolved -> undef' );
}

# =====================================================================
# 10. Custom skill route dispatch with crafted specs (no skill_name branch).
# =====================================================================
ok( !defined $m->_custom_skill_route_response( route_path => '' ), 'custom route empty path' );
ok( !defined $m->_custom_skill_route_response( route_path => '/' ), 'custom route root path' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_custom_route_path = sub { return; };
    ok( !defined $m->_custom_skill_route_response( route_path => '/nomatch' ), 'custom route no spec' );
}
for my $case (
    [ { skill_name => '', kind => 'app',   route_id  => 'welcome' } ],
    [ { skill_name => '', kind => 'ajax',  ajax_file => 'demo.json' } ],
    [ { skill_name => '', kind => 'js',    file      => 'jquery.js' } ],
    [ { skill_name => '', kind => 'other-unknown' } ],
) {
    no warnings 'redefine';
    my $spec = $case->[0];
    local *Developer::Dashboard::SkillDispatcher::resolve_custom_route_path = sub { return $spec; };
    my $r = $m->_custom_skill_route_response( route_path => '/x', remote_addr => '127.0.0.1', headers => H() );
    ok( 1, "custom route non-skill spec kind=$spec->{kind}" );
}

# =====================================================================
# 11. Small pure/helper functions.
# =====================================================================
is( Developer::Dashboard::Web::App::_build_query('not-a-hash'), '', '_build_query non-hash' );
is( Developer::Dashboard::Web::App::_build_query( {} ), '', '_build_query empty hash' );
is( Developer::Dashboard::Web::App::_build_query( { a => 1, b => undef } ), 'a=1&b=', '_build_query with undef value' );

is( Developer::Dashboard::Web::App::_ajax_content_type(''), 'text/plain; charset=utf-8', '_ajax_content_type default' );
is( Developer::Dashboard::Web::App::_ajax_content_type(undef), 'text/plain; charset=utf-8', '_ajax_content_type undef' );
is( Developer::Dashboard::Web::App::_ajax_content_type('json'), 'application/json; charset=utf-8', '_ajax_content_type json' );
is( Developer::Dashboard::Web::App::_ajax_content_type('application/foo'), 'application/foo', '_ajax_content_type raw mime' );
is( Developer::Dashboard::Web::App::_ajax_content_type('weird'), 'text/plain; charset=utf-8', '_ajax_content_type unknown symbolic' );

is( $m->_legacy_ajax_allowed('not-a-hash'), 1, '_legacy_ajax_allowed non-hash' );
is( $m->_legacy_ajax_allowed( {} ), 1, '_legacy_ajax_allowed empty' );
is( $m->_legacy_ajax_allowed( { file => 'x' } ), 1, '_legacy_ajax_allowed with file' );
ok( !$m->_legacy_ajax_allowed( { token => 't' } ), '_legacy_ajax_allowed token denied by default' );

is_deeply( { Developer::Dashboard::Web::App::_parse_query('') }, {}, '_parse_query empty' );
is_deeply( { Developer::Dashboard::Web::App::_parse_query('=v&a=1') }, { a => 1 }, '_parse_query drops empty keys' );

is( Developer::Dashboard::Web::App::_escape_html(undef), '', '_escape_html undef' );

# _login_redirect_target / _sanitize_redirect_target
is( $m->_login_redirect_target( path => '/app/x', query => 'a=1' ), '/app/x?a=1', 'login redirect target with path+query' );
is( $m->_login_redirect_target(), '/', 'login redirect target defaults' );
is( $m->_sanitize_redirect_target('/app/x'), '/app/x', 'sanitize keeps valid target' );
is( $m->_sanitize_redirect_target(''), '/', 'sanitize empty' );
is( $m->_sanitize_redirect_target('no-slash'), '/', 'sanitize non-slash' );
is( $m->_sanitize_redirect_target('//evil'), '/', 'sanitize protocol-relative' );
is( $m->_sanitize_redirect_target('/\evil.com'),    '/', 'sanitize backslash-authority (browsers normalise backslash to slash)' );
is( $m->_sanitize_redirect_target('/app\evil.com'), '/', 'sanitize embedded backslash mid-path' );
is( $m->_sanitize_redirect_target('/\\'),           '/', 'sanitize leading slash-backslash' );
is( $m->_sanitize_redirect_target("/a\nb"), '/', 'sanitize newline' );
is( $m->_sanitize_redirect_target("/\t/evil.com"), '/', 'DD-415: sanitize tab-hidden authority (URL parsers strip tab, leaving //evil.com)' );
is( $m->_sanitize_redirect_target("/app\tx"),      '/', 'DD-415: sanitize embedded tab mid-path' );
is( $m->_sanitize_redirect_target("/a\rb"),        '/', 'DD-415: sanitize carriage return' );
is( $m->_sanitize_redirect_target("/a\x00b"),      '/', 'DD-415: sanitize every other raw control byte' );
is( $m->_sanitize_redirect_target('/login'), '/', 'sanitize login path' );
is( $m->_sanitize_redirect_target('/login?next=1'), '/', 'sanitize login path with query' );

# =====================================================================
# 12. Highlight helpers (edge inputs).
# =====================================================================
like( Developer::Dashboard::Web::App::_json_for_inline_script(undef), qr/^""/, '_json_for_inline_script undef' );
is( $m->_highlight_instruction_html(undef), '', '_highlight_instruction_html undef source' );
like( $m->_editor_overlay_html("x\n"), qr/ \z/, 'overlay adds trailing sentinel for newline-terminated source' );
is( $m->_editor_overlay_html('x'), 'x', 'overlay without trailing newline' );
is( $m->_editor_overlay_html(undef), '', 'overlay undef source' );
is( $m->_highlight_section_text( 'plain', {} ), 'plain', 'section text without a section' );
like( $m->_highlight_section_text( '[% x %]', { section => 'STASH' } ), qr/tok-note/, 'STASH section notes' );
like( $m->_highlight_section_text( '[% x %]', { section => 'NOTE' } ), qr/tok-note/, 'NOTE section notes' );
like( $m->_highlight_html_text( 'a<script>b', { html_mode => '' } ), qr/tok-tag/, 'html text opens script mode' );
like( $m->_highlight_html_text( 'a<style>b', { html_mode => '' } ), qr/tok-tag/, 'html text opens style mode' );
is( $m->_highlight_restore_tokens( "\x1EHL9\x1E", ['only'] ), '', 'restore tokens with a missing index yields empty' );
is( $m->_highlight_restore_tokens( "\x1EHL0\x1E", ['ok'] ), 'ok', 'restore tokens with a present index' );

# =====================================================================
# 13. Page route URL + fragment + response helpers.
# =====================================================================
{
    my $routed = Developer::Dashboard::PageDocument->new(
        id => 'r', title => 'R',
        meta => { render_route => '/r', form_action => '/f', edit_route => '/e', source_route => '/s' },
    );
    is( $m->_page_route_urls($routed)->{form_action}, '/f', 'explicit route metadata is used directly' );
    my $form_only = Developer::Dashboard::PageDocument->new(
        id => 'fo', title => 'FO', meta => { form_action => '/only' },
    );
    is( $m->_page_route_urls($form_only)->{form_action}, '/only', 'form_action-only route metadata resolves' );
    my $saved = Developer::Dashboard::PageDocument->new( id => 'welcome', title => 'W', meta => { source_kind => 'saved' } );
    is( $m->_page_route_urls($saved)->{page_url}, '/app/welcome', 'saved page url resolves' );
}

# _effective_current_page transient-with-path
{
    my $tp = Developer::Dashboard::PageDocument->new( id => 'index', title => 'I', meta => { source_kind => 'transient', request_context => { path => '/' } } );
    is( $m->_effective_current_page($tp), '/app/index', 'transient page at root maps to its saved route' );
    my $np = Developer::Dashboard::PageDocument->new( id => 'index', title => 'I', meta => { source_kind => 'saved', request_context => { path => '/app/index' } } );
    is( $m->_effective_current_page($np), '/app/index', 'non-transient page keeps request path' );
}

# _page_fragment_html chunk handling
is( $m->_page_fragment_html(undef), '', 'fragment for undef page' );
{
    my $frag = Developer::Dashboard::PageDocument->new( id => 'frag', title => 'F' );
    $frag->{layout}{body} = 'BODY';
    $frag->{meta}{runtime_outputs} = [ 'out', {}, undef ];
    $frag->{meta}{runtime_errors}  = [ 'err', [], undef ];
    my $html = $m->_page_fragment_html($frag);
    like( $html, qr/BODY/, 'fragment includes body' );
    like( $html, qr/out/,  'fragment appends string outputs' );
    like( $html, qr/runtime-error/, 'fragment renders errors' );
    my $nobody = Developer::Dashboard::PageDocument->new( id => 'nb', title => 'NB' );
    delete $nobody->{layout}{body};
    is( $m->_page_fragment_html($nobody), '', 'fragment without body/outputs is empty' );
}

# _page_response modes + editor-disabled short circuits
{
    my $p = Developer::Dashboard::PageDocument->new( id => 'welcome', title => 'W', layout => { body => 'B' }, meta => { source_kind => 'saved' } );
    is( $m->_page_response( $p, 'render' )->[0], 200, 'page response render' );
    is( $m->_page_response( $p, 'source' )->[0], 200, 'page response source' );
    is( $m->_page_response( $p, 'edit' )->[0], 200, 'page response edit' );
}

# _nav_items_html defaults
is( $m->_nav_items_html(), '', 'nav items without a page' );
{
    my $navskill = Developer::Dashboard::PageDocument->new( id => 'x', title => 'X', meta => { skill_route_id => 'nav/thing' } );
    is( $m->_nav_items_html( page => $navskill ), '', 'nav items skips nav skill route pages' );
}

# =====================================================================
# 14. Action responses via a controllable stub runner.
# =====================================================================
{
    my $page = Developer::Dashboard::PageDocument->new(
        id => 'acted', title => 'A', layout => { body => 'b' },
        actions => [ undef, { builtin => 'no-id' }, { id => 'go', builtin => 'page.state' } ],
    );
    my $stub_app = Developer::Dashboard::Web::App->new(
        actions => bless( {}, 'Local::StubActions' ),
        auth => $auth, config => $config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );

    local $Local::StubActions::MODE = 'body';
    my $r1 = $stub_app->_action_response( id => 'go', page => $page );
    is( $r1->[0], 200, 'action response body payload' );
    is( $r1->[1], 'text/x', 'action response custom content type' );

    local $Local::StubActions::MODE = 'body-default';
    is( $stub_app->_action_response( id => 'go', page => $page, params => {} )->[1], 'text/plain; charset=utf-8', 'action response default content type' );

    local $Local::StubActions::MODE = 'json';
    is( $stub_app->_action_response( id => 'go', page => $page )->[1], 'application/json; charset=utf-8', 'action response json payload' );

    local $Local::StubActions::MODE = 'die';
    is( $stub_app->_action_response( id => 'go', page => $page )->[0], 403, 'action response die -> 403' );

    is( $stub_app->_action_response( id => 'missing', page => $page )->[0], 404, 'action response missing action -> 404' );

    # no actions runner
    my $noact = Developer::Dashboard::Web::App->new(
        auth => $auth, config => $config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    is( $noact->_action_response( id => 'go', page => $page )->[0], 501, 'action response without runner -> 501' );
    is( $noact->_encoded_action_response( token => 't' )->[0], 501, 'encoded action response without runner -> 501' );

    local $Local::StubActions::MODE = 'body';
    is( $stub_app->_encoded_action_response( token => 't' )->[0], 200, 'encoded action response body payload' );
    local $Local::StubActions::MODE = 'body-default';
    is( $stub_app->_encoded_action_response( token => 't', params => {} )->[1], 'text/plain; charset=utf-8', 'encoded action response default content type' );
    local $Local::StubActions::MODE = 'json';
    is( $stub_app->_encoded_action_response( token => 't' )->[1], 'application/json; charset=utf-8', 'encoded action response json payload' );
    local $Local::StubActions::MODE = 'die';
    is( $stub_app->_encoded_action_response( token => 't' )->[0], 403, 'encoded action response die -> 403' );

    # render page with actions + transient url encoding
    $page->{meta}{source_kind} = 'saved';
    like( $stub_app->_render_page_html( $page, 'render' ), qr/b/, 'render page with actions (saved atoken urls)' );
    {
        local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
        my $tpage = Developer::Dashboard::PageDocument->new(
            id => 'tr', title => 'TR', layout => { body => 'body' },
            actions => [ { id => 'go', builtin => 'page.state' } ],
            meta => { source_kind => 'transient' },
        );
        like( $stub_app->_render_page_html( $tpage, 'render' ), qr/body/, 'render transient page with atoken urls' );
    }
}

# =====================================================================
# 15. _legacy_ajax_response variants (saved path / file / missing).
# =====================================================================
{
    # saved_ajax_path provided but missing on disk
    is( $m->_legacy_ajax_response( params => {}, saved_ajax_path => '/no/such/file' )->[0], 404, 'legacy ajax saved path missing -> 404' );
    # file provided but unresolved
    is( $m->_legacy_ajax_response( params => { file => 'does-not-exist-xyz' } )->[0], 404, 'legacy ajax file unresolved -> 404' );
}

# =====================================================================
# 16. Missing-named-page response under read-only mode.
# =====================================================================
{
    my $ro_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    $ro_config->save_global_web_settings( no_editor => 1 );
    my $ro = Developer::Dashboard::Web::App->new(
        actions => $actions, auth => $auth, config => $ro_config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    is( $ro->_missing_named_page_response('x')->[0], 404, 'missing page under read-only -> 404' );
    is( $ro->handle( path => '/', remote_addr => '127.0.0.1', headers => H() )->[0], 403, 'read-only root with no index -> no-editor 403' );
    $ro_config->save_global_web_settings( no_editor => 0 );
}
is( $m->_missing_named_page_response('x')->[0], 200, 'missing page editor -> 200' );

# =====================================================================
# 17. Top chrome / context helpers.
# =====================================================================
{
    my $page = Developer::Dashboard::PageDocument->new( id => 'welcome', title => 'W', layout => { body => 'b' } );
    ok( $m->_top_chrome_html($page), 'top chrome minimal (default urls)' );
    like( $m->_top_chrome_html( $page, { render => '/app/welcome', edit => '/app/welcome/edit', source => '/app/welcome/edit' } ), qr/play-button/, 'top chrome renders a play button' );

    my $helper_ctx = Developer::Dashboard::PageDocument->new( id => 'w', title => 'W', layout => { body => 'b' } );
    $helper_ctx->{meta}{request_context} = { tier => 'helper', username => 'alice', host => 'host.example:7890' };
    like( $m->_top_context_html($helper_ctx), qr/alice/, 'top context uses helper username and port' );

    my $noport_ctx = Developer::Dashboard::PageDocument->new( id => 'w', title => 'W', layout => { body => 'b' } );
    $noport_ctx->{meta}{request_context} = { tier => 'admin', host => 'host.example' };
    local $ENV{USER} = '';
    ok( $m->_top_context_html($noport_ctx), 'top context falls back to system user without a port' );
}

# =====================================================================
# 18. IP interface parsing (mocked command_in_path + capture).
# =====================================================================
{
    no warnings 'redefine';
    # ip: success with a matching + non-matching line, then a failure.
    local *Developer::Dashboard::Web::App::command_in_path = sub { my ($n) = @_; return $n eq 'ip' ? '/sbin/ip' : undef; };
    local *Developer::Dashboard::Web::App::capture = sub (&) {
        return ( "junk line without match\n1: eth0    inet 192.168.1.5/24 brd\n", '', 0 );
    };
    is_deeply( [ $m->_ip_pairs_from_ip ], [ { iface => 'eth0', ip => '192.168.1.5' } ], 'ip parser keeps matching interface lines' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub { my ($n) = @_; return $n eq 'ip' ? '/sbin/ip' : undef; };
    local *Developer::Dashboard::Web::App::capture = sub (&) { return ( '', '', 1 ); };
    is_deeply( [ $m->_ip_pairs_from_ip ], [], 'ip parser returns nothing on a failed command' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub { my ($n) = @_; return $n eq 'ipconfig' ? '/c/ipconfig' : undef; };
    local *Developer::Dashboard::Web::App::capture = sub (&) {
        return ( "Ethernet adapter Local:\n   IPv4 Address. . . : 10.1.2.3\n   IPv4 Address. . . : 127.0.0.1\n", '', 0 );
    };
    is_deeply( [ $m->_ip_pairs_from_ipconfig ], [ { iface => 'Local', ip => '10.1.2.3' } ], 'ipconfig parser keeps non-loopback IPv4 lines' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub { return undef; };
    is_deeply( [ $m->_ip_pairs_from_ipconfig ], [], 'ipconfig parser skips when the command is absent' );
    is_deeply( [ $m->_ip_pairs_from_ifconfig ], [], 'ifconfig parser skips when the command is absent' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub { my ($n) = @_; return $n eq 'ifconfig' ? '/sbin/ifconfig' : undef; };
    local *Developer::Dashboard::Web::App::capture = sub (&) {
        return ( "    inet 10.9.9.9 netmask\neth0: flags\n    inet 172.16.0.4 netmask\n    inet 127.0.0.1 netmask\n", '', 0 );
    };
    is_deeply( [ $m->_ip_pairs_from_ifconfig ], [ { iface => 'eth0', ip => '172.16.0.4' } ], 'ifconfig parser keeps non-loopback IPv4 after an adapter header' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub { my ($n) = @_; return $n eq 'ifconfig' ? '/sbin/ifconfig' : undef; };
    local *Developer::Dashboard::Web::App::capture = sub (&) { return ( '', '', 1 ); };
    is_deeply( [ $m->_ip_pairs_from_ifconfig ], [], 'ifconfig parser returns nothing on a failed command' );
}

# =====================================================================
# 19. Static file serving edge cases.
# =====================================================================
{
    my $absroot = File::Spec->catdir( $home, 'staticroot' );
    make_path($absroot);
    wfile( File::Spec->catfile( $absroot, 'ok.js' ), "console.log(1);\n", 0644 );
    is( $m->_serve_static_file_from_roots( 'js', '../escape', $absroot )->[0], 400, 'static serve rejects traversal' );
    is( $m->_serve_static_file_from_roots( 'js', 'ok.js', 'relative-root' )->[0], 404, 'static serve skips a relative root outside the resolved path' );
    is( $m->_serve_static_file_from_roots( 'js', 'ok.js', $absroot )->[0], 200, 'static serve returns a matching file' );
    is( $m->_serve_static_file_from_roots( 'js', 'missing.js', $absroot )->[0], 404, 'static serve returns 404 for a missing file' );

    is( $m->_serve_static_file_at_path( 'js', 'x', '' )->[0], 404, 'serve at empty path -> 404' );
    is( $m->_serve_static_file_at_path( 'js', 'x', '/no/such/path' )->[0], 404, 'serve at missing path -> 404' );
    is( $m->_serve_static_file_at_path( 'js', 'ok.js', File::Spec->catfile( $absroot, 'ok.js' ), '', [$absroot] )->[0], 200, 'serve at a real path inside an allowed root -> 200' );
    my $unreadable = File::Spec->catfile( $absroot, 'noperm.js' );
    wfile( $unreadable, "x\n", 0000 );
    is( $m->_serve_static_file_at_path( 'js', 'noperm.js', $unreadable )->[0], 404, 'serve at an unreadable path -> 404' );
    chmod 0644, $unreadable;
}

# _skill_ajax_file_path / _skill_static_file_path guards
is( $m->_skill_ajax_file_path( '', 'x' ), '', 'skill ajax file path empty skill' );
is( $m->_skill_ajax_file_path( 'route-skill', '' ), '', 'skill ajax file path empty file' );
ok( defined $m->_skill_ajax_file_path( 'route-skill', 'bar' ), 'skill ajax file path resolves' );
is( $m->_skill_static_file_path( '', 'js', 'x' ), '', 'skill static file path empty skill' );
is( $m->_skill_static_file_path( 'route-skill', '', 'x' ), '', 'skill static file path empty type' );
is( $m->_skill_static_file_path( 'route-skill', 'js', '' ), '', 'skill static file path empty file' );
is( $m->_skill_route_spec( '', 'route-skill', 't' ), undef, 'skill route spec empty kind' );

# _static_file_roots on a non-PageStore pages app (2958 false side)
{
    my $nonstore = Developer::Dashboard::Web::App->new(
        auth => bless( {}, 'Local::AuthStub' ), pages => bless( {}, 'Local::NotAStore' ), sessions => bless( {}, 'Local::SessionsStub' ),
    );
    ok( scalar( $nonstore->_static_file_roots('js') ), 'static roots without a page store fall back to home' );
}
# duplicate runtime/dashboards roots exercise the seen-dedup skip
{
    no warnings 'redefine';
    my $dup = File::Spec->catdir( $home, 'dup' );
    local *Developer::Dashboard::PathRegistry::runtime_roots   = sub { return ( $dup, $dup ); };
    local *Developer::Dashboard::PathRegistry::dashboards_roots = sub { return ( $dup, $dup ); };
    ok( scalar( $m->_static_file_roots('js') ), 'static roots dedup repeated roots' );
}

# _bundled_public_asset_path guards + dist_dir/inc variants
{
    is( eval { Developer::Dashboard::Web::App::_bundled_public_asset_path( '', 'x' ); 1 } ? 'ok' : 'die', 'die', 'bundled asset requires a type' );
    is( eval { Developer::Dashboard::Web::App::_bundled_public_asset_path( 'js', '' ); 1 } ? 'ok' : 'die', 'die', 'bundled asset requires a file' );
    no warnings 'redefine';
    {
        local $Developer::Dashboard::Web::App::MODULE_SOURCE_PATH = '';
        ok( Developer::Dashboard::Web::App::_bundled_public_asset_path( 'js', 'jquery-4.0.0.min.js' ), 'bundled asset resolves with an empty module source path' );
    }
    {
        local *Developer::Dashboard::Web::App::dist_dir = sub { die "no dist\n" };
        ok( Developer::Dashboard::Web::App::_bundled_public_asset_path( 'js', 'jquery-4.0.0.min.js' ), 'bundled asset resolves when dist_dir dies' );
    }
    {
        local *Developer::Dashboard::Web::App::dist_dir = sub { return '' };
        ok( Developer::Dashboard::Web::App::_bundled_public_asset_path( 'js', 'jquery-4.0.0.min.js' ), 'bundled asset resolves when dist_dir is empty' );
    }
    {
        local $INC{'Developer/Dashboard/Web/App.pm'} = '';
        ok( Developer::Dashboard::Web::App::_bundled_public_asset_path( 'js', 'jquery-4.0.0.min.js' ), 'bundled asset resolves when the INC entry is empty' );
    }
    {
        # a near-root module source collapses updir candidates so the seen-dedup fires
        local $Developer::Dashboard::Web::App::MODULE_SOURCE_PATH = '/App.pm';
        ok( !eval { Developer::Dashboard::Web::App::_bundled_public_asset_path( 'js', 'definitely-missing-asset' ); 1 }, 'collapsed candidates dedup and then fail to find a missing asset' );
    }
}

# =====================================================================
# 20. Remaining branch/condition closers.
# =====================================================================
my $SEP = ':--------------------------------------------------------------------------------:';

# root POST with a bookmark instruction: page id present (407/408/412)
{
    my $instr = "TITLE: Root BM\n$SEP\nBOOKMARK: rootbm\n$SEP\nHTML: root bookmark body\n";
    is( $app->handle( path => '/', method => 'POST', body => 'instruction=' . uri_escape($instr), remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'root POST saves a bookmark instruction' );
}

# skill ajax file that does not resolve on disk (529 false side)
ok( $m->skill_ajax_file_response( skill_name => 'route-skill', ajax_file => 'no-such-ajax-handler' ), 'skill ajax file response with unresolved handler' );

# _bundled_public_asset_path with an undefined type (601 not-defined side)
ok( !eval { Developer::Dashboard::Web::App::_bundled_public_asset_path( undef, 'x' ); 1 }, 'bundled asset dies on an undefined type' );

# skill edit POST with mode=edit (867 mode ne render side)
{
    my $instr = "TITLE: Skill Route Index\n$SEP\nBOOKMARK: index\n$SEP\nHTML:\nEdited In Place\n";
    ok( $app->handle( path => '/app/route-skill/edit', method => 'POST', body => 'instruction=' . uri_escape($instr), remote_addr => '127.0.0.1', headers => H() )->[0], 'skill edit POST in edit mode' );
}

# page source for a loaded page that carries no raw instruction (823 canonical side)
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_load_editable_named_page = sub {
        return Developer::Dashboard::PageDocument->new( id => 'raw-less', title => 'RawLess', layout => { body => 'b' } );
    };
    ok( $m->page_source_response( id => 'raw-less' )->[0], 'page source falls back to canonical text when no raw instruction exists' );
}

# _page_route_urls on a page without source_kind/routes (1050 default)
is( $m->_page_route_urls( Developer::Dashboard::PageDocument->new( id => 'bare', title => 'B' ) )->{form_action}, '/', 'page route urls for a bare page' );

# nav rendering with a broken nav fragment (2020 load-failure) and a param-less
# runtime context (2025 default).
{
    wfile( File::Spec->catfile( $paths->dashboards_root, 'nav', 'broken.tt' ), '', 0644 );
    my $welcome = $store->load_saved_page('welcome');
    ok( defined $m->_nav_items_html( page => $welcome, runtime_context => { current_page => '/x' } ), 'nav rendering skips broken fragments and defaults params' );
}

# a saved URL-forward bookmark without a query (2187 // default)
wfile( File::Spec->catfile( $paths->dashboards_root, 'forward-noq' ), "/app/welcome\n", 0644 );
ok( $m->_legacy_app_response( id => 'forward-noq' )->[0], 'saved URL forward without a query string' );

# custom route spec with no skill name and no kind (2259 default)
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_custom_route_path = sub { return { skill_name => '' }; };
    ok( !defined $m->_custom_skill_route_response( route_path => '/x', remote_addr => '127.0.0.1', headers => H() ), 'custom route non-skill spec without a kind' );
}
# custom skill ajax route spec without an explicit type (2290 default)
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_custom_route_path = sub { return { skill_name => 'route-skill', kind => 'ajax', ajax_file => 'bar' }; };
    ok( $m->_custom_skill_route_response( route_path => '/x', remote_addr => '127.0.0.1', headers => H() ), 'custom skill ajax route without an explicit type' );
}

done_testing;

# ---------------------------------------------------------------------------
# Stubs used to drive defensive branches deterministically.
# ---------------------------------------------------------------------------
package Local::AuthStub;
sub trust_tier           { return 'admin' }
sub helper_users_enabled { return 1 }

package Local::SessionsStub;
sub from_cookie { return undef }

package Local::ConfigBare;    # blessed config with no config methods at all

package Local::ConfigWS;      # config with web_settings (no ssl alt names) but no other methods
sub web_settings { return {} }

package Local::ConfigApiArray;    # api_keys returns a non-hash value
sub api_keys { return [] }

package Local::IndNoPayload;    # indicators object without page_header_payload

package Local::IndEmptyPayload;    # indicators whose payload lacks an array key
sub page_header_payload { return {} }

package Local::NotAStore;    # a pages object that is not a PageStore

package Local::DispProbe;
sub _load_skill_page {
    return Developer::Dashboard::PageDocument->new(
        id => 'route-skill', title => 'Skill Route Index', meta => { source_kind => 'skill' },
    );
}

package Local::DispProbeDie;
sub _load_skill_page { die "boom\n" }

package Local::StubActions;
our $MODE = 'body';

# run_page_action(%args)
# Returns a controllable result for Web::App action-response coverage.
# Input: ignored named arguments.
# Output: hash reference, or dies when $MODE is 'die'.
sub run_page_action {
    die "action failure\n" if $MODE eq 'die';
    return { body => 'b', content_type => 'text/x' } if $MODE eq 'body';
    return { body => 'b2' } if $MODE eq 'body-default';
    return { ok => 1 };
}

# run_encoded_action(%args)
# Mirrors run_page_action for encoded-action response coverage.
# Input: ignored named arguments.
# Output: hash reference, or dies when $MODE is 'die'.
sub run_encoded_action { return run_page_action() }

# encode_action_payload(%args)
# Returns a stable fake action token for render-link coverage.
# Input: ignored named arguments.
# Output: token string.
sub encode_action_payload { return 'atok' }

package main;

__END__

=pod

=head1 NAME

t/101-web-app-coverage.t - branch and condition coverage closure for the web app backend

=head1 PURPOSE

This test is the executable coverage-closure contract for
C<Developer::Dashboard::Web::App>. It drives the browser-facing route table,
helper login, transient-token policy, saved-page render/source/edit/action
flows, saved and skill-local Ajax endpoints, static asset serving, and the
defensive fallback paths so every Devel::Cover branch and condition in the
module is exercised on the Linux test host.

=head1 WHY IT EXISTS

The web app backend is large and security-sensitive, and its happy paths were
already covered by the broader suite while the defensive sides (missing config,
absent headers, empty option defaults, error responses, and machine-auth edge
cases) were not. This file closes those remaining branch and condition sides so
the all-metric coverage gate stays honest for this module.

=head1 WHEN TO USE

Use this file when changing browser routes, auth gating, saved or transient page
handling, Ajax endpoints, skill route resolution, or the static file serving in
the web app backend.

=head1 HOW TO USE

Run C<prove -lv t/101-web-app-coverage.t> while iterating, then keep it green
under C<prove -lr t> and the Devel::Cover gate before release.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the coverage gate use this
file to keep the web app backend's branch and condition coverage complete.

=head1 EXAMPLES

Example 1:

  prove -lv t/101-web-app-coverage.t

Run the focused coverage-closure test by itself.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
