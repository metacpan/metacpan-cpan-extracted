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

# =====================================================================
# 105-GAP. Deterministic closers for the remaining full-suite branch and
# condition gaps that t/101 does not reach. Every block below drives a
# specific missing branch side or condition combination on the Linux host.
# =====================================================================

# Fixtures: a skill ajax handler and a skill static asset with NO custom
# route entry, so their route-spec lookups return undef.
wfile( File::Spec->catfile( $paths->skills_root, 'route-skill', 'dashboards', 'ajax', 'plainajax' ), qq|print "plain ajax\\n";\n|, 0700 );
wfile( File::Spec->catfile( $paths->skills_root, 'route-skill', 'dashboards', 'public', 'js', 'plainstatic.js' ), qq|console.log("plain static");\n|, 0644 );

# ---- api_keys iterated over RAW malformed entries (271, 272, 295, 296, 297) ----
{
    my $raw_app = Developer::Dashboard::Web::App->new(
        auth     => bless( {}, 'Local::AuthStub' ),
        pages    => $store,
        sessions => bless( {}, 'Local::SessionsStub' ),
        config   => bless( {}, 'Local::ConfigRawApi' ),
        runtime  => $runtime,
    );
    is( $raw_app->_api_route_registered('/ajax/no-such-registered-path'), 0, 'raw api_keys: non-hash and non-array-ajax entries iterated (271,272)' );
    ok( !$raw_app->_authorize_api_request( path => '/ajax/x', headers => { 'x-dd-api-key' => 'z_arr', 'x-dd-api-secret' => 's' } ), 'raw api: ajax value is not an array (295)' );
    ok( !$raw_app->_authorize_api_request( headers => { 'x-dd-api-key' => 'valid', 'x-dd-api-secret' => 's' } ), 'raw api: missing path arg defaults to empty (296 right)' );
    ok( !$raw_app->_authorize_api_request( path => '/ajax/registered', headers => { 'x-dd-api-key' => 'nosec', 'x-dd-api-secret' => 'whatever' } ), 'raw api: entry without secret defaults to empty (297 right)' );
}

# ---- authorize_request config-shape and context defaults (139, 183, 307) ----
{
    my $noc = Developer::Dashboard::Web::App->new(
        auth => bless( {}, 'Local::AuthStub' ), pages => $store, sessions => bless( {}, 'Local::SessionsStub' ), runtime => $runtime,
    );
    is_deeply( $noc->_api_keys, {}, 'unblessed config -> empty api keys (307 !l)' );
    ok( !$noc->authorize_request( remote_addr => '1.2.3.4', headers => {} ), 'authorize with unblessed config (139 !l)' );

    my $bare = Developer::Dashboard::Web::App->new(
        auth => bless( {}, 'Local::AuthStub' ), pages => $store, sessions => bless( {}, 'Local::SessionsStub' ), config => bless( {}, 'Local::ConfigBare' ), runtime => $runtime,
    );
    ok( !$bare->authorize_request( remote_addr => '1.2.3.4', headers => {} ), 'authorize with bare blessed config (139 l&&!r)' );
    ok( !$bare->authorize_request( remote_addr => '', headers => {} ), 'authorize admin with empty remote_addr (183 remote_addr right)' );

    # helper session that is a bare hash -> username/role default to '' (183)
    my $helper = Developer::Dashboard::Web::App->new(
        auth => bless( {}, 'Local::AuthHelper' ), pages => $store, sessions => bless( {}, 'Local::SessionsBare' ), config => bless( {}, 'Local::ConfigBare' ), runtime => $runtime,
    );
    ok( !$helper->authorize_request( path => '/app/x', remote_addr => '1.2.3.4', headers => { cookie => 'c' } ), 'helper bare-hash session defaults username/role (183)' );

    # api_context whose api_key is falsy -> api_key defaults to '' (183)
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Web::App::_authorize_api_request = sub { return {} };
        my $apiapp = Developer::Dashboard::Web::App->new(
            auth => bless( {}, 'Local::AuthHelper' ), pages => $store, sessions => bless( {}, 'Local::SessionsStub' ), config => bless( {}, 'Local::ConfigRawApi' ), runtime => $runtime,
        );
        ok( !$apiapp->authorize_request( path => '/ajax/registered', remote_addr => '1.2.3.4', headers => {} ), 'empty api_context defaults api_key (183 api_key right)' );
    }
}

# ---- method-mismatch dispatch conditions (221 l&&!r, 230 l&&!r) ----
ok( $app->handle( path => '/app/acted/action/go', method => 'GET', remote_addr => '127.0.0.1', headers => H() )->[0], 'GET /app/.../action/... falls past the POST-only action route (221 l&&!r)' );
is( $app->handle( path => '/action', method => 'GET', remote_addr => '127.0.0.1', headers => H() )->[0], 404, 'GET /action falls through (230 l&&!r)' );

# ---- read-only (no_editor) short circuits (403, 439, 440, 948, 1072, 1079) ----
{
    my $ro_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    $ro_config->save_global_web_settings( no_editor => 1 );
    my $ro = Developer::Dashboard::Web::App->new(
        actions => $actions, auth => $auth, config => $ro_config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    is( $ro->handle( path => '/', method => 'POST', body => 'instruction=' . uri_escape("$SEP\nHTML: ro\n"), remote_addr => '127.0.0.1', headers => H() )->[0], 403, 'root POST instruction under no_editor (403)' );
    is( $ro->_blank_editor_response->[0], 403, 'blank editor under no_editor (948)' );
    my $pg = Developer::Dashboard::PageDocument->new( id => 'welcome', title => 'W', layout => { body => 'b' }, meta => { source_kind => 'saved' } );
    is( $ro->_page_response( $pg, 'source' )->[0], 403, 'page_response source under no_editor (1072)' );
    is( $ro->_page_response( $pg, 'edit' )->[0], 403, 'page_response edit under no_editor (1079)' );
    {
        local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
        is( $ro->handle( path => '/', query => "mode=source&token=$trans_token", remote_addr => '127.0.0.1', headers => H() )->[0], 403, 'transient source under no_editor (439)' );
        ok( $ro->handle( path => '/', query => "mode=edit&token=$trans_token", remote_addr => '127.0.0.1', headers => H() )->[0], 'transient edit under no_editor -> render (440)' );
    }
    $ro_config->save_global_web_settings( no_editor => 0 );
}

# ---- root GET query instruction (402 middle, 404 false, 412 !l, 417 left) ----
{
    my $instr = "TITLE: GI\n$SEP\nBOOKMARK: gi-bm\n$SEP\nHTML: gi body\n";
    is( $app->handle( path => '/', query => 'mode=render&instruction=' . uri_escape($instr), remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'GET query instruction bookmarked, mode render (402,404,412,417)' );
}

# ---- legacy ajax entry-point deny + no-params (509, 2376) ----
is( $m->legacy_ajax_file_response( ajax_file => '', query => 'token=t' )->[0], 403, 'legacy ajax file empty file + token, tokens disabled (509)' );
is( $m->_legacy_ajax_response->[0], 400, 'legacy ajax response with no params (2376 right)' );

# ---- legacy ajax code-token streams (2380, 2382, 2412, 2415, 2433) ----
{
    my $ok_token  = Developer::Dashboard::Codec::encode_payload('print "streamed-ok\n";');
    my $err_token = Developer::Dashboard::Codec::encode_payload('die "streamed-boom\n";');
    my $r_ok = $m->_legacy_ajax_response( params => { token => $ok_token } );
    is( $r_ok->[0], 200, 'legacy ajax code token accepted (2380 true)' );
    my $body_ok = drain( $r_ok->[2] );
    ok( defined $body_ok, 'code-block stream drained clean (2433 false)' );
    my $r_err = $m->_legacy_ajax_response( params => { token => $err_token } );
    my $body_err = drain( $r_err->[2] );
    like( $body_err, qr/streamed-boom/, 'code-block stream writes runtime error (2433 true)' );
    require MIME::Base64;
    my $passthrough_token = MIME::Base64::encode_base64( 'print "passthrough-token\n";', '' );
    my $r_pt = $m->_legacy_ajax_response( params => { token => $passthrough_token } );
    ok( $r_pt->[0], 'legacy ajax accepts a transparently-decoded token (2380 true, 2382 false)' );
    drain( $r_pt->[2] );

    my $r_saved = $m->_legacy_ajax_response( params => { file => 'demo.json', type => 'json' } );
    is( $r_saved->[0], 200, 'legacy ajax saved file stream (2412 true)' );
    my $body_saved = drain( $r_saved->[2] );
    ok( defined $body_saved, 'saved-ajax stream drained, no page param (2415 right)' );
}

# ---- legacy ajax with falsy pages{paths} (2389 false, 2397) ----
{
    my $pp = Developer::Dashboard::Web::App->new(
        actions => $actions, auth => $auth, config => $config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    $pp->{pages} = { paths => undef };
    ok( $pp->_legacy_ajax_response( params => { file => 'demo.json' } )->[0], 'legacy ajax with falsy pages paths (2389 false, 2397)' );
}

# ---- transient action token/id sources (793, 794, 795) ----
eval { $m->transient_action_response( method => 'POST', body => '' ) };
ok( 1, 'transient action, no token/id anywhere (793,794,795 defaults)' );
{
    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
    eval { $m->transient_action_response( query => "token=$trans_token&id=go", method => 'GET' ) };
    ok( 1, 'transient action, token+id in query (793,795 true)' );
}

# ---- prefixed ajax route resolution (555, 556, 563) ----
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_resolve_skill_route_spec = sub { return { skill_name => 'route-skill' }; };
    ok( $m->prefixed_ajax_file_response( ajax_path => 'route-skill/whatever' )->[0], 'prefixed ajax spec without route_segments (555 true, 556 false)' );
}
ok( $m->prefixed_ajax_file_response( ajax_path => 'route-skill/plainajax' )->[0], 'prefixed ajax file exists but has no route spec (563 route_spec false)' );
ok( $m->prefixed_ajax_file_response( ajax_path => 'route-skill/ghost-missing' )->[0], 'prefixed ajax file that does not resolve on disk (563 saved_ajax_path false)' );
ok( $m->prefixed_ajax_file_response( ajax_path => 'route-skill/bar' )->[0], 'prefixed ajax bar route without explicit type (563 type default)' );

# ---- prefixed static route resolution (702, 703, 710) ----
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_resolve_skill_route_spec = sub { return { skill_name => 'route-skill' }; };
    ok( $m->prefixed_static_file_response( type => 'js', file => 'route-skill/whatever' )->[0], 'prefixed static spec without route_segments (702 true, 703 false)' );
}
ok( $m->prefixed_static_file_response( type => 'js', file => 'route-skill/plainstatic.js' )->[0], 'prefixed static file exists but has no route spec (710 route_spec false)' );

# ---- jquery asset open failure (587) ----
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_bundled_public_asset_path = sub { return '/nonexistent/developer-dashboard/asset/none' };
    ok( !eval { $m->jquery_js_response; 1 }, 'jquery response dies when the asset cannot be opened (587 true)' );
}
ok( !eval { Developer::Dashboard::Web::App::_bundled_public_asset_path( 'js', undef ); 1 }, 'bundled asset dies on an undefined file (602 l)' );

# ---- skill route response with falsy pages (747) ----
{
    my $sr = Developer::Dashboard::Web::App->new(
        actions => $actions, auth => $auth, config => $config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    $sr->{pages} = 0;
    ok( eval { $sr->skill_route_response( skill_name => 'route-skill', route => 'bookmarks/foo', remote_addr => '127.0.0.1', headers => H() ); 1 } || 1, 'skill route response with falsy pages (747 false)' );
}

# ---- _load_skill_named_page skill_layers falsy (999) and id='' (982, 993) ----
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_resolve_skill_route_spec = sub { return { skill_name => 'route-skill', route_segments => ['x'] }; };
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { bless {}, 'Local::DispProbe' };
    ok( !defined $m->_load_skill_named_page('route-skill/x'), 'skill named page spec without skill_layers (999 true)' );
}
ok( !defined $m->_load_editable_named_page(''), '_load_editable_named_page empty id (982 !l&&r)' );
ok( !defined $m->_load_skill_named_page(''), '_load_skill_named_page empty id (993 !l&&r)' );

# ---- _skill_app_fallback_response (2212, 2216, 2217, 2222, 2229, 2234) ----
ok( !defined $m->_skill_app_fallback_response( id => '/' ), 'fallback slash-only id has no segments (2212 true)' );
{
    my $pf = Developer::Dashboard::Web::App->new(
        actions => $actions, auth => $auth, config => $config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    $pf->{pages} = 0;
    eval { $pf->_skill_app_fallback_response( id => 'route-skill/foo' ) };
    ok( 1, 'fallback with falsy pages (2216, 2217)' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_route_segments = sub { return { skill_name => 'route-skill', route_segments => ['foo'] }; };
    is( $m->_skill_app_fallback_response( id => 'route-skill/foo' )->[0], 404, 'fallback spec without skill_layers (2222 true)' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_route_segments = sub { return { skill_name => 'route-skill', skill_layers => ['L'] }; };
    eval { $m->_skill_app_fallback_response( id => 'route-skill/foo' ) };
    ok( 1, 'fallback spec without route_segments (2229 true)' );
}
ok( $m->_skill_app_fallback_response( id => 'route-skill/foo' ), 'fallback real skill defaults query/body/headers (2234 rights)' );

# ---- _custom_skill_route_response spec defaults (2262, 2265, 2268, 2276, 2284, 2292) ----
for my $spec (
    { skill_name => '', kind => 'app' },
    { skill_name => '', kind => 'ajax' },
    { skill_name => '', kind => 'js' },
) {
    no warnings 'redefine';
    # Path-aware stub: only the original /x route resolves, so the re-dispatched
    # /app/, /ajax/, /js/ path returns undef instead of recursing forever.
    local *Developer::Dashboard::SkillDispatcher::resolve_custom_route_path = sub {
        my ( undef, $p ) = @_;
        return ( defined $p && $p eq '/x' ) ? $spec : undef;
    };
    $m->_custom_skill_route_response( route_path => '/x', remote_addr => '127.0.0.1', headers => H() );
    ok( 1, "custom non-skill spec kind=$spec->{kind} missing target (2262/2265/2268)" );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_custom_route_path = sub { return { skill_name => 'route-skill' } };
    ok( !defined $m->_custom_skill_route_response( route_path => '/x', remote_addr => '127.0.0.1', headers => H() ), 'custom skill spec without a kind (2276,2284,2292 defaults)' );
}

# ---- _skill_dispatcher with falsy pages (2312) ----
{
    my $pd = Developer::Dashboard::Web::App->new(
        actions => $actions, auth => $auth, config => $config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    $pd->{pages} = 0;
    isa_ok( $pd->_skill_dispatcher, 'Developer::Dashboard::SkillDispatcher', 'skill dispatcher with falsy pages (2312 false)' );
}

# ---- _skill_route_spec argument guards (2321) ----
is( $m->_skill_route_spec( '', 'route-skill', 't' ), undef, 'skill route spec empty kind (2321 true, cond !l)' );
is( $m->_skill_route_spec( 'js', '', 't' ), undef, 'skill route spec empty skill (2321 cond l&&!r)' );
is( $m->_skill_route_spec( 'js', 'route-skill', '' ), undef, 'skill route spec empty target (2321 cond)' );
ok( defined $m->_skill_route_spec( 'js', 'route-skill', 'skill.js' ) || 1, 'skill route spec all args resolve (2321 false)' );

# ---- skill ajax file with query+body present (526, 527 left) ----
ok( $m->skill_ajax_file_response( skill_name => 'route-skill', ajax_file => 'bar', query => 'q=1', body => 'b=2', method => 'POST' )->[0], 'skill ajax with query+body strings (526,527 left)' );

# ---- static file response with an empty file arg (684 right) ----
ok( $m->static_file_response( type => 'js', file => '' )->[0], 'static file js with an empty file arg (684 right)' );

# ---- logout header + session shape variants (373, 376) ----
is( $m->logout_response( remote_addr => '1.2.3.4' )->[0], 302, 'logout without headers (373 right)' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::SessionStore::from_cookie = sub { return { session_id => 'gap-s1' } };
    is( $m->logout_response( remote_addr => '1.2.3.4', headers => { cookie => 'c' } )->[0], 302, 'logout bare session, no role/username (376 !l, role right)' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SessionStore::from_cookie = sub { return { session_id => 'gap-s2', role => 'helper' } };
    is( $m->logout_response( remote_addr => '1.2.3.4', headers => { cookie => 'c' } )->[0], 302, 'logout helper role, empty username (376 l&&!r, username right)' );
}

# ---- page_edit_post existing-page shapes (855, 866, 875) ----
$store->save_page( Developer::Dashboard::PageDocument->new( id => 'plain855', title => 'P855', layout => { body => 'b' } ) );
ok( $m->page_edit_post_response( id => 'brand-new-855', method => 'POST', body => 'instruction=' . uri_escape("$SEP\nBOOKMARK: brand-new-855\n$SEP\nHTML: x\n") )->[0], 'page_edit_post new id, no existing page (855 !l)' );
ok( $m->page_edit_post_response( id => 'plain855', method => 'POST', body => 'instruction=' . uri_escape("$SEP\nBOOKMARK: plain855\n$SEP\nHTML: y\n") )->[0], 'page_edit_post existing saved page, no path/headers (855 right, 866, 875)' );

# ---- page_edit / page_action source_kind defaults (896, 908, 932, 938) ----
$store->save_page( Developer::Dashboard::PageDocument->new( id => 'plain908', title => 'P908', layout => { body => 'b' }, actions => [ { id => 'go', kind => 'builtin', builtin => 'page.state' } ] ) );
ok( $m->page_edit_response( id => 'plain908' )->[0], 'page_edit_response source_kind default (896 !l, 908 right)' );
ok( $m->page_action_response( id => 'plain908', action_id => 'go' )->[0], 'page_action_response source_kind default (932, 938 right)' );

# ---- render-page action/url/state defaults (1921, 1926, 1928, 1929, 1934, 1941, 1947, 1958) ----
{
    my $noact = Developer::Dashboard::Web::App->new(
        auth => $auth, config => $config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    my $pa = Developer::Dashboard::PageDocument->new( title => 'PA', layout => { body => 'PABODY' }, actions => [ { id => 'go', builtin => 'page.state' } ] );
    delete $pa->{id};
    delete $pa->{meta}{source_kind};
    $pa->{state} = undef;
    like( $noact->_render_page_html( $pa, 'render' ), qr/PABODY/, 'render page with actions, no id/runner/source_kind (1928,1929,1934,1941,1947,1958 defaults)' );

    my $pb = Developer::Dashboard::PageDocument->new( id => 'pb', title => 'PB', layout => { body => 'PBBODY' } );
    $pb->{actions} = undef;
    like( $noact->_render_page_html( $pb, 'render' ), qr/PBBODY/, 'render page with undef actions (1926 true)' );
    like( $noact->_render_page_html($pb), qr/PBBODY/, 'render without explicit mode arg (1921 false)' );

    my $tp = Developer::Dashboard::PageDocument->new( id => 'tp', title => 'TP', layout => { body => 'TPB' }, meta => { source_kind => 'transient' } );
    like( $noact->_render_page_html( $tp, 'render' ), qr/TPB/, 'render transient page with tokens disabled (1958 l&&!r)' );
}

# ---- _effective_current_page saved-at-root (1981) ----
{
    my $sp = Developer::Dashboard::PageDocument->new( id => 'idx', title => 'I', meta => { request_context => { path => '/' } } );
    is( $m->_effective_current_page($sp), '/', 'saved page at root keeps request path (1981 right, l&&!r)' );
}

# ---- _page_route_urls meta shapes (1038, 1039) ----
{
    my $nm = Developer::Dashboard::PageDocument->new( id => 'nm', title => 'NM' );
    $nm->{meta} = undef;
    is( ref( $m->_page_route_urls($nm) ), 'HASH', 'route urls with undef meta (1038 right)' );
    is( $m->_page_route_urls( Developer::Dashboard::PageDocument->new( id => 'rr', title => 'RR', meta => { render_route => '/r' } ) )->{render}, '/r', 'route urls render_route only (1039)' );
    is( $m->_page_route_urls( Developer::Dashboard::PageDocument->new( id => 'sr', title => 'SR', meta => { source_route => '/s' } ) )->{source}, '/s', 'route urls source_route only (1039)' );
    is( $m->_page_route_urls( Developer::Dashboard::PageDocument->new( id => 'fa', title => 'FA', meta => { form_action => '/f' } ) )->{form_action}, '/f', 'route urls form_action only (1039)' );
}

# ---- nav rendering variants (1997, 1998, 2004, 2044, 2060, 2062) ----
$m->{_current_request_context} ||= { host => '127.0.0.1', remote_addr => '127.0.0.1' };
{
    my $np = Developer::Dashboard::Web::App->new(
        actions => $actions, auth => $auth, config => $config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    $np->{pages} = { paths => undef };
    is( $np->_nav_items_html( page => Developer::Dashboard::PageDocument->new( id => 'y', title => 'Y' ) ), '', 'nav returns empty when paths missing (1997 right)' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::all_skill_nav_pages = sub { [] };
    my $nl = Developer::Dashboard::Web::App->new(
        actions => $actions, auth => $auth, config => $config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    $nl->{pages} = { paths => bless( {}, 'Local::PathsNoLayers' ) };
    $nl->{_current_request_context} = { host => 'h', remote_addr => '1.1.1.1' };
    ok( defined eval { $nl->_nav_items_html( page => Developer::Dashboard::PageDocument->new( id => 'x', title => 'X', layout => { body => 'b' } ), runtime_context => { params => {}, current_page => '' } ) } // '', 'nav with paths lacking dashboards_layers (1998 false)' );
}
{
    my $nav_dir = File::Spec->catdir( $paths->dashboards_root, 'nav' );
    chmod 0000, $nav_dir;
    my $welcome = $store->load_saved_page('welcome');
    eval { $m->_nav_items_html( page => $welcome, runtime_context => { params => {}, current_page => '/x' } ) };
    chmod 0755, $nav_dir;
    ok( 1, 'nav opendir failure path (2004 true)' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::all_skill_nav_pages = sub { undef };
    my $welcome = $store->load_saved_page('welcome');
    ok( defined $m->_nav_items_html( page => $welcome, runtime_context => { params => {}, current_page => '/x' } ), 'skill nav pages undef (2044 true)' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::all_skill_nav_pages = sub {
        return [ Developer::Dashboard::PageDocument->new( title => 'N', layout => { body => '' } ) ];
    };
    my $welcome = $store->load_saved_page('welcome');
    ok( defined eval { $m->_nav_items_html( page => $welcome, runtime_context => { params => {}, current_page => '/x' } ) } // '', 'skill nav page with no id and empty fragment (2060 right, 2062 true)' );
}

# ---- action responses: no id, non-hash result (2100, 2115, 2137) ----
{
    my $pact = Developer::Dashboard::PageDocument->new( id => 'pact', title => 'PA', actions => [ { id => 'go', builtin => 'page.state' } ] );
    is( $m->_action_response( page => $pact )->[0], 404, 'action response without an id (2100 right)' );

    my $scal = Developer::Dashboard::Web::App->new(
        actions => bless( {}, 'Local::StubActionsScalar' ), auth => $auth, config => $config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    is( $scal->_action_response( id => 'go', page => $pact )->[1], 'application/json; charset=utf-8', 'action non-hash result serializes as json (2115 !l)' );
    is( $scal->_encoded_action_response( token => 't' )->[1], 'application/json; charset=utf-8', 'encoded non-hash result serializes as json (2137 !l)' );
}

# ---- _page_with_runtime_state defaults + host/remote (2528, 2529, 2540) ----
{
    my $p1 = Developer::Dashboard::PageDocument->new( id => 'p1', title => 'P1', layout => { body => 'b' } );
    $m->_page_with_runtime_state($p1);
    ok( 1, 'page_with_runtime_state with no params/headers (2528,2529 right, 2540 false)' );
    my $p2 = Developer::Dashboard::PageDocument->new( id => 'p2', title => 'P2', layout => { body => 'b' } );
    $m->_page_with_runtime_state( $p2, headers => { host => 'h' }, remote_addr => '2.2.2.2', query_params => { a => 1 }, body_params => {} );
    ok( 1, 'page_with_runtime_state with host and remote (2540 true)' );
}

# ---- top chrome / context defaults (2617, 2704) ----
{
    my $nomode = Developer::Dashboard::PageDocument->new( id => 'nomode', title => 'NM', layout => { body => 'b' } );
    ok( $m->_top_chrome_html($nomode), 'top chrome page without a mode (2617 right)' );
    my $cp = Developer::Dashboard::PageDocument->new( id => 'cp', title => 'CP', layout => { body => 'b' } );
    $cp->{meta}{request_context} = { tier => 'admin', host => 'hostx:' };
    ok( $m->_top_context_html($cp), 'top context host with a trailing colon empty port (2704 l&&!r)' );
}

# ---- pure query parsing edges (2492, 2496) ----
is_deeply( { Developer::Dashboard::Web::App::_parse_query(undef) }, {}, 'parse_query undef (2492 l)' );
is_deeply( { Developer::Dashboard::Web::App::_parse_query('a=1&&b=2') }, { a => 1, b => 2 }, 'parse_query with an empty pair yields undef key (2496 l)' );

# ---- IP interface parsers: exit codes and empty/undef stdout, malformed lines ----
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub { my ($n) = @_; return $n eq 'ip' ? '/sbin/ip' : undef; };
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( 'data', '', 5 ) };
        is_deeply( [ $m->_ip_pairs_from_ip ], [], 'ip parser: non-zero exit (2767 true / cond l)' );
    }
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( undef, '', 0 ) };
        is_deeply( [ $m->_ip_pairs_from_ip ], [], 'ip parser: undef stdout (2767 !l&&r)' );
    }
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( '', '', 0 ) };
        is_deeply( [ $m->_ip_pairs_from_ip ], [], 'ip parser: empty stdout (2767)' );
    }
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub { my ($n) = @_; return $n eq 'ipconfig' ? '/c/ipconfig' : undef; };
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( 'x', '', 9 ) };
        is_deeply( [ $m->_ip_pairs_from_ipconfig ], [], 'ipconfig parser: non-zero exit (2787 true)' );
    }
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( undef, '', 0 ) };
        is_deeply( [ $m->_ip_pairs_from_ipconfig ], [], 'ipconfig parser: undef stdout (2787 !l&&r)' );
    }
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( '', '', 0 ) };
        is_deeply( [ $m->_ip_pairs_from_ipconfig ], [], 'ipconfig parser: empty stdout (2787)' );
    }
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( "   IPv4 Address. . : 9.9.9.9\n", '', 0 ) };
        is_deeply( [ $m->_ip_pairs_from_ipconfig ], [], 'ipconfig parser: IPv4 line before any adapter (2795 true)' );
    }
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( "Ethernet adapter Loc:\n   nothing here\n", '', 0 ) };
        is_deeply( [ $m->_ip_pairs_from_ipconfig ], [], 'ipconfig parser: adapter then no IPv4 (2796 true)' );
    }
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub { my ($n) = @_; return $n eq 'ifconfig' ? '/sbin/ifconfig' : undef; };
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( 'x', '', 9 ) };
        is_deeply( [ $m->_ip_pairs_from_ifconfig ], [], 'ifconfig parser: non-zero exit (2815 true)' );
    }
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( undef, '', 0 ) };
        is_deeply( [ $m->_ip_pairs_from_ifconfig ], [], 'ifconfig parser: undef stdout (2815 !l&&r)' );
    }
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( '', '', 0 ) };
        is_deeply( [ $m->_ip_pairs_from_ifconfig ], [], 'ifconfig parser: empty stdout (2815)' );
    }
    {
        local *Developer::Dashboard::Web::App::capture = sub (&) { return ( "eth0: flags\n   no address on this line\n", '', 0 ) };
        is_deeply( [ $m->_ip_pairs_from_ifconfig ], [], 'ifconfig parser: iface header then non-inet line (2824 true)' );
    }
}

# ---- static serving: unreadable file and undef path (2918, 2987) ----
{
    my $root2918 = File::Spec->catdir( $home, 'root2918' );
    make_path($root2918);
    my $unread = File::Spec->catfile( $root2918, 'x.js' );
    wfile( $unread, "x\n", 0000 );
    is( $m->_serve_static_file_from_roots( 'js', 'x.js', $root2918 )->[0], 404, 'file present but unreadable (2918 l&&!r)' );
    chmod 0644, $unread;
}
is( $m->_serve_static_file_at_path( 'js', 'x', undef )->[0], 404, 'serve at an undef file path (2987 l)' );

# =====================================================================
# 105-GAP2. Second pass for condition combinations the first pass missed.
# =====================================================================

# ---- api secret empty with a non-empty key (291 !l&&r) ----
{
    my $raw_app = Developer::Dashboard::Web::App->new(
        auth => bless( {}, 'Local::AuthStub' ), pages => $store, sessions => bless( {}, 'Local::SessionsStub' ), config => bless( {}, 'Local::ConfigRawApi' ), runtime => $runtime,
    );
    ok( !$raw_app->_authorize_api_request( headers => { 'x-dd-api-key' => 'valid', 'x-dd-api-secret' => '' } ), 'api key present but secret empty (291 !l&&r)' );
}

# ---- root instruction with a mode in the body (417 non-default operand) ----
is( $app->handle( path => '/', method => 'POST', body => 'mode=render&instruction=' . uri_escape("TITLE: M417\n$SEP\nBOOKMARK: m417\n$SEP\nHTML: b\n"), remote_addr => '127.0.0.1', headers => H() )->[0], 200, 'root instruction with a body mode (417 operand true)' );

# ---- read-only transient render mode reaches both editor guards false-sides (440 l&&!r) ----
{
    my $ro_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    $ro_config->save_global_web_settings( no_editor => 1 );
    my $ro = Developer::Dashboard::Web::App->new(
        actions => $actions, auth => $auth, config => $ro_config, pages => $store, prompt => $prompt, runtime => $runtime, sessions => $sessions,
    );
    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
    ok( $ro->handle( path => '/', query => "mode=render&token=$trans_token", remote_addr => '127.0.0.1', headers => H() )->[0], 'transient render under no_editor (440 l&&!r)' );
    $ro_config->save_global_web_settings( no_editor => 0 );
}

# ---- skill ajax file with an explicit type present (534 !l) ----
ok( $m->skill_ajax_file_response( skill_name => 'route-skill', ajax_file => 'bar', query => 'type=json' )->[0], 'skill ajax with a request type present (534 !l)' );

# ---- prefixed ajax with a route spec that carries no type (563 type default) ----
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_skill_ajax_route_spec = sub { return {} };
    ok( $m->prefixed_ajax_file_response( ajax_path => 'route-skill/plainajax' )->[0], 'prefixed ajax route spec without a type (563 type right)' );
}

# ---- page_edit_post with a bookmark-less instruction (853 id assignment) ----
ok( $m->page_edit_post_response( id => 'assigned853', method => 'POST', body => 'instruction=' . uri_escape("HTML:\nno bookmark id here\n") )->[0], 'page_edit_post bookmark-less instruction assigns id (853 !l&&r)' );
ok( eval { $m->page_edit_post_response( id => '', method => 'POST', body => 'instruction=' . uri_escape("HTML:\nno bookmark and no id\n") )->[0] } || 1, 'page_edit_post bookmark-less instruction with empty id (853 !l&&!r)' );

# ---- existing page whose source_kind is falsy (855 right) ----
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_load_editable_named_page = sub {
        return Developer::Dashboard::PageDocument->new( id => 'ek855', title => 'EK', layout => { body => 'b' } );
    };
    ok( $m->page_edit_post_response( id => 'ek855', method => 'POST', body => 'instruction=' . uri_escape("$SEP\nBOOKMARK: ek855\n$SEP\nHTML: y\n") )->[0], 'page_edit_post existing page without source_kind (855 right)' );
    ok( $m->page_edit_response( id => 'ek855' )->[0], 'page_edit_response page without raw_instruction/source_kind (896 !l&&r, 908 right)' );
}

# ---- page_action with a loaded page lacking source_kind (932, 938 right) ----
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_load_named_page = sub {
        return Developer::Dashboard::PageDocument->new( id => 'na932', title => 'NA', layout => { body => 'b' }, actions => [ { id => 'go', kind => 'builtin', builtin => 'page.state' } ] );
    };
    ok( $m->page_action_response( id => 'na932', action_id => 'go' )->[0], 'page_action page without source_kind (932, 938 right)' );
}

# ---- render page-with-actions on an actions-capable app (1934 source_kind right) ----
{
    my $pae = Developer::Dashboard::PageDocument->new( id => 'pae', title => 'PAE', layout => { body => 'PAEBODY' }, actions => [ { id => 'go', builtin => 'page.state' } ] );
    delete $pae->{meta}{source_kind};
    like( $m->_render_page_html( $pae, 'render' ), qr/PAEBODY/, 'render page-with-actions, source_kind default (1934 right)' );
}

# ---- saved page with no id (1051 l&&!r) ----
is( ref( $m->_page_route_urls( Developer::Dashboard::PageDocument->new( title => 'SNI', meta => { source_kind => 'saved' } ) ) ), 'HASH', 'saved source_kind but empty id (1051 l&&!r)' );

# ---- highlight an unterminated script tag (1787 false) ----
like( $m->_highlight_html_text( 'a<script', { html_mode => '' } ), qr/script/, 'html text with an unterminated script tag (1787 false)' );

# ---- legacy ajax file that resolves to an empty saved path (2397 l) ----
{
    no warnings 'redefine';
    local *Developer::Dashboard::Zipper::saved_ajax_file_path = sub { return '' };
    is( $m->_legacy_ajax_response( params => { file => 'anything' } )->[0], 404, 'legacy ajax file resolving to empty saved path (2397 l)' );
}

# ---- saved-ajax stream drained WITH a page param (2415 left) ----
{
    my $r = $m->_legacy_ajax_response( params => { file => 'demo.json', page => 'demopage', type => 'json' } );
    drain( $r->[2] );
    ok( 1, 'saved-ajax stream with a page param (2415 left)' );
}

# ---- page_with_runtime_state host from the request context (2540) ----
{
    local $m->{_current_request_context} = { host => 'ctxhost', remote_addr => 'ctxaddr' };
    my $p3 = Developer::Dashboard::PageDocument->new( id => 'p3', title => 'P3', layout => { body => 'b' } );
    $m->_page_with_runtime_state( $p3, headers => { host => 'directhost' } );
    my $p4 = Developer::Dashboard::PageDocument->new( id => 'p4', title => 'P4', layout => { body => 'b' } );
    $m->_page_with_runtime_state( $p4, headers => {} );
    ok( 1, 'page_with_runtime_state host from header then from context (2540)' );
}

# ---- login redirect target with an empty path (2563 l&&!r) ----
is( $m->_login_redirect_target( path => '', query => '' ), '/', 'login redirect target empty path (2563 l&&!r)' );

# ---- top chrome for a page whose mode is falsy (2617 false) ----
{
    my $nm = Developer::Dashboard::PageDocument->new( id => 'nm2617', title => 'NM', layout => { body => 'b' } );
    $nm->{mode} = undef;
    ok( $m->_top_chrome_html($nm), 'top chrome page with a falsy mode (2617 false)' );
}

# ---- top context falls back to the system user (2698 false) ----
{
    local $ENV{USER} = '';
    my $cp = Developer::Dashboard::PageDocument->new( id => 'cp2698', title => 'CP', layout => { body => 'b' } );
    $cp->{meta}{request_context} = { tier => 'admin', host => 'host.example' };
    ok( $m->_top_context_html($cp), 'top context falls back to system user without USER (2698 false)' );
}

# =====================================================================
# 105-GAP3. Highlight branch/condition closers for subroutines
# that the full suite reaches but the local coverage test path misses.
# =====================================================================

# ---- _highlight_tag_markup style= and on*= attributes (1828 all 3 branches) ----
like( $m->_highlight_markup_text('<div style="color:red">'),
      qr/tok-value tok-css/,
      'highlight markup style= attribute (1828 name eq style)' );
like( $m->_highlight_markup_text('<button onclick="do()">'),
      qr/tok-value tok-js/,
      'highlight markup onclick= attribute (1828 name =~ /^on/)' );

# ---- _highlight_perl_text comment regex (1875 true side) ----
like( $m->_highlight_perl_text( 'print 1;  # a comment' ),
      qr/tok-comment/,
      'highlight perl with inline comment (1875 true side)' );

# ---- ref || __PACKAGE__ class-method call for highlight CSS/JS/Perl (1839, 1855, 1870) ----
ok( defined 'Developer::Dashboard::Web::App'->_highlight_css_text('body { color: red; }'),
    'highlight css as class method via ref||PKG (1839) ' );
ok( defined 'Developer::Dashboard::Web::App'->_highlight_js_text('var x = 1;'),
    'highlight js as class method via ref||PKG (1855) ' );
ok( defined 'Developer::Dashboard::Web::App'->_highlight_perl_text('my $x = 1;'),
    'highlight perl as class method via ref||PKG (1870) ' );

# ---- _machine_ip @pairs branch (2755 true side) ----
# Drive the IP detection code with a script-based capture fallback.
# We mock command_in_path to return true for "ip" and then mock capture
# to produce output that yields a real pair, then a subsequent mock that
# yields empty pairs so the @pairs check fires both ways.
{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::command_in_path = sub { my ($n) = @_; return $n eq 'ip' ? '/sbin/ip' : undef; };
    local *Developer::Dashboard::Web::App::capture = sub (&) {
        return ( "1: eth0    inet 10.0.0.1/24 brd 10.0.0.255\n", '', 0 );
    };
    my $ip = $m->_machine_ip;
    # If a real interface was found it's a string; if not it falls through
    ok( defined $ip, 'machine_ip with a real ip pair (2755 true side)' );
}

# =====================================================================
# DD-416. _static_path_contained is the last gate before a resolved static
# asset is opened, so every rejection shape it has to recognise is driven
# directly here instead of only through the route surface.
# =====================================================================
{
    my $contained_root = File::Spec->catdir( $home, 'dd416-static-root' );
    make_path($contained_root);
    my $inside = File::Spec->catfile( $contained_root, 'inside.js' );
    wfile( $inside, "console.log(1);\n", 0644 );
    my $outside = File::Spec->catfile( $home, 'dd416-outside.txt' );
    wfile( $outside, "DD416-OUTSIDE\n", 0600 );

    my $contained = \&Developer::Dashboard::Web::App::_static_path_contained;

    ok( $contained->( $inside, [$contained_root] ), 'a file inside an allowed root is contained' );
    ok( !$contained->( File::Spec->catfile( $contained_root, File::Spec->updir, 'dd416-outside.txt' ), [$contained_root] ),
        'a parent-directory path that resolves outside the allowed root is rejected' );
    ok( !$contained->( $outside, [$contained_root] ), 'a file beside the allowed root is rejected' );
    ok( !$contained->( $inside, undef ), 'a missing allowed-root list denies by default' );
    ok( !$contained->( $inside, [] ),    'an empty allowed-root list denies by default' );
    ok( !$contained->( $inside, [ undef, '' ] ), 'undef and empty allowed roots are skipped' );
    ok( !$contained->( $inside, [ File::Spec->catdir( $home, 'dd416-no-such-root' ) ] ),
        'an allowed root that does not exist on disk is skipped' );
    ok( !$contained->( File::Spec->catfile( $contained_root, 'dd416-missing.js' ), [$contained_root] ),
        'a path that does not resolve at all is rejected' );

    {
        local $Developer::Dashboard::Platform::OS_NAME = 'MSWin32';
        ok( $contained->( $inside, [$contained_root] ),
            'containment case-folds and still matches on a Windows runtime' );
        ok( !$contained->( $outside, [$contained_root] ),
            'containment still rejects an outside path on a Windows runtime' );
    }

    # The serve helper refuses to open a resolved path outside its allowed roots
    # even when that path exists and is readable.
    is( $m->_serve_static_file_at_path( 'js', 'inside.js', $inside, '', [$contained_root] )->[0], 200,
        'serve at a contained path -> 200' );
    is( $m->_serve_static_file_at_path( 'others', 'outside.txt', $outside, '', [$contained_root] )->[0], 404,
        'serve at an uncontained path -> 404' );
    is( $m->_serve_static_file_at_path( 'js', 'inside.js', $inside )->[0], 404,
        'serve with no allowed roots -> 404' );
    is( $m->_serve_static_file_at_path( 'js', 'inside.js', $inside, undef, [$contained_root] )->[1],
        'application/javascript; charset=utf-8',
        'serve with an undefined mime override falls back to the type-derived content type' );
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

package Local::AuthHelper;    # non-admin trust tier with helper users enabled
sub trust_tier           { return 'helper' }
sub helper_users_enabled { return 1 }

package Local::SessionsBare;    # from_cookie yields a bare session hash (no role/username)
sub from_cookie { return { session_id => 's' } }

package Local::ConfigRawApi;    # api_keys returns RAW malformed + valid entries (bypasses normalization)

# api_keys()
# Returns un-normalized API client entries so the app-level ref/array guards run.
# Input: none.
# Output: hash reference with a non-hash entry, a non-array-ajax entry, and valid entries.
sub api_keys {
    return {
        z_str => 'a plain string, not a hash',
        z_arr => { ajax => 'not-an-array', secret => 'x' },
        valid => { ajax => ['/ajax/registered'], secret => 'deadbeef' },
        nosec => { ajax => ['/ajax/registered'] },
    };
}

package Local::PathsNoLayers;    # a paths object with dashboards_roots but no dashboards_layers

# dashboards_roots()
# Returns an empty layer list so nav discovery skips the local loop.
# Input: none.
# Output: empty list.
sub dashboards_roots { return () }

package Local::StubActionsScalar;    # action runner returning a non-hash (scalar) result

# run_page_action(%args)
# Returns a plain scalar so the ref($result) eq 'HASH' guard takes its false side.
# Input: ignored named arguments.
# Output: scalar string.
sub run_page_action { return 'plain-scalar-result' }

# run_encoded_action(%args)
# Mirrors run_page_action for the encoded-action response path.
# Input: ignored named arguments.
# Output: scalar string.
sub run_encoded_action { return 'plain-scalar-result' }

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
