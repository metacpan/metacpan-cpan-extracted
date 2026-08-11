#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Request::Common qw(GET POST);
use Test::More;

use lib 'lib';
use lib 't/lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;
use Developer::Dashboard::Web::DancerApp;
use Local::PSGITest;

# The source-scan acceptance check reads lib/ directly, so record the checkout
# root before the hermetic chdir moves the process into a throwaway home.
my $repo_root = getcwd();

# Hermetic runtime: the layer stack and Config discovery both resolve from the
# process HOME and from the deepest .developer-dashboard layer beneath the
# current working directory, so anchor HOME and the CWD in one temp dir.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};
delete local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
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

# build_app(%overrides)
# Constructs one web app instance around the shared registries.
# Input: optional config override for api/alias fixtures.
# Output: Developer::Dashboard::Web::App object.
sub build_app {
    my (%overrides) = @_;
    return Developer::Dashboard::Web::App->new(
        actions  => $actions,
        auth     => $auth,
        config   => $overrides{config} || $config,
        pages    => $store,
        prompt   => $prompt,
        runtime  => $runtime,
        sessions => $sessions,
    );
}

my $app = build_app();

# request(%args)
# Issues one normalized request against a web app under test.
# Input: path plus optional app, method, query, body, remote_addr, host,
# cookie, origin, referer, api_key, and api_secret values.
# Output: list of ( status, body, headers hash reference ).
sub request {
    my (%args) = @_;
    my $target = $args{app} || $app;
    my %headers;
    $headers{host}              = $args{host}       if exists $args{host};
    $headers{cookie}            = $args{cookie}     if exists $args{cookie};
    $headers{origin}            = $args{origin}     if exists $args{origin};
    $headers{referer}           = $args{referer}    if exists $args{referer};
    $headers{'x-dd-api-key'}    = $args{api_key}    if exists $args{api_key};
    $headers{'x-dd-api-secret'} = $args{api_secret} if exists $args{api_secret};
    my $result = $target->handle(
        path        => $args{path},
        method      => $args{method} || 'GET',
        query       => defined $args{query} ? $args{query} : '',
        body        => defined $args{body} ? $args{body} : '',
        remote_addr => $args{remote_addr},
        headers     => \%headers,
    );
    return ( $result->[0], $result->[2], $result->[3] || {} );
}

# wfile($path, $content, $mode)
# Writes one fixture file, creating parent directories as needed.
# Input: absolute file path, content string, octal permission mode.
# Output: none; dies when the file cannot be written.
sub wfile {
    my ( $path, $content, $mode ) = @_;
    make_path( dirname($path) );
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    chmod $mode, $path;
    return;
}

my $ADMIN_HOST  = '127.0.0.1:7890';
my $HELPER_HOST = 'helper.example:7890';

# ---------------------------------------------------------------------------
# 1. Loopback-admin tier. The loopback shortcut authorizes without any cookie,
#    which is exactly what makes it CSRF-prone: any page the operator visits
#    can fire a state-changing request at 127.0.0.1. A foreign Origin (or a
#    foreign Referer when Origin is absent) must be rejected with an empty 403
#    before the request reaches any route, while a same-origin or headerless
#    request keeps working unchanged.
# ---------------------------------------------------------------------------
my $admin_control_code;
{
    ($admin_control_code) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
    );
    isnt( $admin_control_code, 403, 'control: headerless loopback-admin POST is not rejected' );

    my ( $code, $body ) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        origin      => 'http://evil.example',
    );
    is( $code, 403, 'foreign-Origin POST on the loopback-admin tier is rejected' );
    is( $body, '', 'the cross-site rejection carries an empty body' );

    ( $code, $body ) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        referer     => 'http://evil.example/trap.html',
    );
    is( $code, 403, 'foreign-Referer-only POST on the loopback-admin tier is rejected' );
    is( $body, '', 'the Referer-based rejection carries an empty body' );

    ($code) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        origin      => 'null',
    );
    is( $code, 403, 'an opaque "Origin: null" is foreign and rejected' );

    ($code) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        origin      => 'not a url',
    );
    is( $code, 403, 'an unparsable Origin value is foreign and rejected' );

    for my $method (qw(PUT DELETE PATCH)) {
        my ($state_code) = request(
            path        => '/app/anything',
            method      => $method,
            remote_addr => '127.0.0.1',
            host        => $ADMIN_HOST,
            origin      => 'http://evil.example',
        );
        is( $state_code, 403, "foreign-Origin $method is rejected like POST" );
    }

    ($code) = request(
        path        => '/',
        method      => 'post',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        origin      => 'http://evil.example',
    );
    is( $code, 403, 'a lowercase post method spelling cannot bypass the check' );

    ($code) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        origin      => 'http://127.0.0.1:7890',
    );
    is( $code, $admin_control_code, 'a same-origin POST (Origin matches Host) still works' );

    ($code) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        origin      => 'HTTP://127.0.0.1:7890',
    );
    is( $code, $admin_control_code, 'origin matching is case-insensitive on the scheme and authority' );

    ($code) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        origin      => 'http://localhost:9999',
    );
    is( $code, $admin_control_code, 'a localhost-family origin is a permitted local alias even on another port' );

    ($code) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        referer     => 'http://127.0.0.1:7890/app/some-page',
    );
    is( $code, $admin_control_code, 'a same-origin Referer-only POST still works' );

    # This GET is served, but NOT because GET is a safe method — it is not one
    # on this product, where /ajax/<file> executes an operator-written handler
    # from a plain GET. It is served because the request carries no
    # Sec-Fetch-Site, which is the shape a non-browser client produces and a
    # browser cannot. The fetch-metadata half of the same choke point refuses
    # the browser-issued version of this request on every method; t/140 pins
    # that. Do not restate this assertion as a GET exemption.
    ($code) = request(
        path        => '/',
        method      => 'GET',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        origin      => 'http://evil.example',
    );
    is( $code, 200, 'a GET with a foreign Origin but no fetch metadata is unaffected' );
}

# ---------------------------------------------------------------------------
# 2. Helper-session tier. A logged-in helper cookie rides along automatically
#    on cross-site requests, so the same foreign-Origin rejection must apply
#    before session dispatch — including to the login form itself (login CSRF).
# ---------------------------------------------------------------------------
{
    # Before any helper user exists, an outsider POST with a foreign Origin is
    # already a cross-site attempt: the CSRF rejection must win over the
    # helper-access-disabled 401 so the choke point sits before tier dispatch.
    my ( $pre_code, $pre_body ) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
        origin      => 'http://evil.example',
    );
    is( $pre_code, 403, 'foreign-Origin POST is rejected even before helper users exist' );
    is( $pre_body, '', 'that rejection also has an empty body' );

    $auth->add_user( username => 'helper', password => 'helper-pass-123', role => 'helper' );

    my ($login_csrf_code) = request(
        path        => '/login',
        method      => 'POST',
        body        => 'username=helper&password=helper-pass-123',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
        origin      => 'http://evil.example',
    );
    is( $login_csrf_code, 403, 'a foreign-Origin login POST is rejected (login CSRF)' );

    my ( $login_code, undef, $login_headers ) = request(
        path        => '/login',
        method      => 'POST',
        body        => 'username=helper&password=helper-pass-123',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
    );
    is( $login_code, 302, 'a headerless login POST still succeeds' );
    my ($cookie) = ( $login_headers->{'Set-Cookie'} || '' ) =~ /(dashboard_session=[^;]+)/;
    ok( $cookie, 'the login issued a session cookie' );

    my ($control_code) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
        cookie      => $cookie,
    );
    isnt( $control_code, 403, 'control: headerless helper-session POST is not rejected' );
    isnt( $control_code, 401, 'control: the helper session is actually authorized' );

    my ( $code, $body ) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
        cookie      => $cookie,
        origin      => 'http://evil.example',
    );
    is( $code, 403, 'foreign-Origin POST is rejected for an authenticated helper session' );
    is( $body, '', 'the helper-tier rejection carries an empty body' );

    ($code) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
        cookie      => $cookie,
        referer     => 'https://evil.example/trap.html',
    );
    is( $code, 403, 'foreign-Referer-only POST is rejected for a helper session' );

    ($code) = request(
        path        => '/',
        method      => 'POST',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
        cookie      => $cookie,
        origin      => 'https://helper.example:7890',
    );
    is( $code, $control_code, 'a same-origin POST keeps working for a helper session' );

    # SSL front-proxy mode: the proxy passes TLS bytes straight through, so
    # the backend sees the browser's own Host header and the same-origin
    # comparison must keep succeeding while a foreign Origin still fails.
    {
        local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED} = 1;
        my ($proxied_code) = request(
            path        => '/login',
            method      => 'POST',
            body        => 'username=helper&password=helper-pass-123',
            remote_addr => '127.0.0.1',
            host        => $HELPER_HOST,
            origin      => 'https://helper.example:7890',
        );
        is( $proxied_code, 302, 'a same-origin login POST through the SSL front-proxy still succeeds' );

        my ($proxied_foreign_code) = request(
            path        => '/login',
            method      => 'POST',
            body        => 'username=helper&password=helper-pass-123',
            remote_addr => '127.0.0.1',
            host        => $HELPER_HOST,
            origin      => 'http://evil.example',
        );
        is( $proxied_foreign_code, 403, 'a foreign-Origin login POST through the SSL front-proxy is rejected' );
    }
}

# ---------------------------------------------------------------------------
# 3. Ajax x-dd-api-key machine tier. Machine clients send no Origin/Referer
#    and must keep working; a browser-carried foreign Origin must be rejected
#    even when the request presents valid API credentials.
# ---------------------------------------------------------------------------
{
    wfile(
        File::Spec->catfile( $paths->dashboards_root, 'legacy-ajax' ),
        "TITLE: LA\n:--------------------------------------------------------------------------------:\nBOOKMARK: legacy-ajax\n:--------------------------------------------------------------------------------:\nHTML: <script>var configs={};</script>\n:--------------------------------------------------------------------------------:\nCODE1: Ajax jvar => 'configs.demo', type => 'json', code => q{ print j { ok => 1 }; }, file => 'demo.json';\n",
        0644,
    );
    request( path => '/app/legacy-ajax', remote_addr => '127.0.0.1', host => $ADMIN_HOST );

    my $api_json = sprintf '{"machine":{"secret":"%s","ajax":["/ajax/demo.json"]}}', sha256_hex('sekret');
    wfile( File::Spec->catfile( $paths->config_root, 'api.json' ), $api_json, 0644 );
    my $api_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    my $api_app    = build_app( config => $api_config );

    my ($machine_code) = request(
        app         => $api_app,
        path        => '/ajax/demo.json',
        method      => 'POST',
        query       => 'type=json',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
        api_key     => 'machine',
        api_secret  => 'sekret',
    );
    is( $machine_code, 200, 'a headerless machine POST with valid api credentials still works' );

    my ( $code, $body ) = request(
        app         => $api_app,
        path        => '/ajax/demo.json',
        method      => 'POST',
        query       => 'type=json',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
        api_key     => 'machine',
        api_secret  => 'sekret',
        origin      => 'http://evil.example',
    );
    is( $code, 403, 'foreign-Origin POST is rejected on the api tier even with valid credentials' );
    is( $body, '', 'the api-tier cross-site rejection body is empty, not the api-forbidden JSON' );

    ($code) = request(
        app         => $api_app,
        path        => '/ajax/demo.json',
        method      => 'POST',
        query       => 'type=json',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
        api_key     => 'machine',
        api_secret  => 'sekret',
        referer     => 'http://evil.example/trap.html',
    );
    is( $code, 403, 'foreign-Referer-only POST is rejected on the api tier too' );

    ($code) = request(
        app         => $api_app,
        path        => '/ajax/demo.json',
        method      => 'POST',
        query       => 'type=json',
        remote_addr => '203.0.113.7',
        host        => $HELPER_HOST,
        api_key     => 'machine',
        api_secret  => 'sekret',
        origin      => 'http://helper.example:7890',
    );
    is( $code, 200, 'a same-origin POST with valid api credentials still works' );
}

# ---------------------------------------------------------------------------
# 4. Configured SAN aliases are permitted origins. web.ssl_subject_alt_names
#    entries are the operator's declared alternate names for this dashboard,
#    so a POST whose Origin names one of them is same-site, mirroring the
#    loopback-alias semantics the trust tier already applies to Host.
# ---------------------------------------------------------------------------
{
    $config->save_global_web_settings( ssl_subject_alt_names => ['mybox.local'] );
    my $alias_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    my $alias_app    = build_app( config => $alias_config );

    my ($code) = request(
        app         => $alias_app,
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        origin      => 'https://mybox.local:7890',
    );
    is( $code, $admin_control_code, 'an Origin naming a configured SAN alias is accepted' );

    ($code) = request(
        app         => $alias_app,
        path        => '/',
        method      => 'POST',
        remote_addr => '127.0.0.1',
        host        => $ADMIN_HOST,
        origin      => 'https://otherbox.local:7890',
    );
    is( $code, 403, 'an Origin naming an unlisted host is still foreign' );
}

# ---------------------------------------------------------------------------
# 5. Dancer2 route layer. The PSGI adapter must forward Origin and Referer to
#    the backend, and every state-changing entrypoint it exposes — the
#    authorized routes and the POST /login route it calls without
#    authorization — must apply the same rejection.
# ---------------------------------------------------------------------------
{
    my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app( app => $app );
    Local::PSGITest::test_psgi $psgi_app, sub {
        my ($cb) = @_;

        my $foreign = $cb->(
            POST 'http://127.0.0.1:7890/',
            Origin  => 'http://evil.example',
            Content => [ x => 1 ],
        );
        is( $foreign->code, 403, 'Dancer layer rejects a foreign-Origin POST on an authorized route' );
        is( $foreign->content, '', 'Dancer-layer rejection body is empty' );

        my $foreign_referer = $cb->(
            POST 'http://127.0.0.1:7890/',
            Referer => 'http://evil.example/trap.html',
            Content => [ x => 1 ],
        );
        is( $foreign_referer->code, 403, 'Dancer layer rejects a foreign-Referer-only POST' );

        my $login = $cb->(
            POST 'http://127.0.0.1:7890/login',
            Origin  => 'http://evil.example',
            Content => [ username => 'helper', password => 'helper-pass-123' ],
        );
        is( $login->code, 403, 'Dancer layer rejects a foreign-Origin POST /login' );

        my $same_origin = $cb->(
            POST 'http://127.0.0.1:7890/',
            Origin  => 'http://127.0.0.1:7890',
            Content => [ x => 1 ],
        );
        isnt( $same_origin->code, 403, 'Dancer layer accepts a same-origin POST' );

        my $headerless = $cb->(
            POST 'http://127.0.0.1:7890/',
            Content => [ x => 1 ],
        );
        isnt( $headerless->code, 403, 'Dancer layer accepts a headerless POST unchanged' );

        my $get = $cb->( GET 'http://127.0.0.1:7890/', Origin => 'http://evil.example' );
        is( $get->code, 200, 'Dancer layer leaves a foreign-Origin GET unaffected' );
    };
}

# ---------------------------------------------------------------------------
# 6. Unit probes for the defense internals: header shapes an HTTP stack never
#    produces (missing hashes, reference values) must fail safe, and the
#    authority parser must treat every opaque or crafted value as foreign.
# ---------------------------------------------------------------------------
{
    my $authority = Developer::Dashboard::Web::App->can('_source_authority');
    ok( $authority, 'the web layer exposes the Origin/Referer authority parser' );
    is( $authority->(undef), undef, 'an undefined source value is unparsable' );
    is( $authority->(''), undef, 'an empty source value is unparsable' );
    is( $authority->('   '), undef, 'a whitespace-only source value is unparsable' );
    is( $authority->('NULL'), undef, 'the opaque null origin is unparsable in any case' );
    is( $authority->('http://user@evil.example'), undef, 'an authority with userinfo is rejected as crafted' );
    is( $authority->('https://a.example https://b.example'), undef, 'a multi-origin list is rejected as crafted' );
    is( $authority->(' https://ok.example:8443/path?q=1#f '), 'ok.example:8443', 'a full Referer URL reduces to its authority' );
    is( $authority->('custom+x.1://host'), 'host', 'any RFC-3986 scheme is accepted before the authority' );

    is( $app->_csrf_rejection_response( method => 'POST' ), undef, 'a POST with no headers hash at all is treated as headerless' );
    is(
        $app->_csrf_rejection_response( method => 'POST', headers => { origin => [], referer => {} } ),
        undef,
        'reference-valued origin/referer headers are treated as absent, never dereferenced',
    );
    is( $app->_csrf_rejection_response( headers => { origin => 'http://evil.example' } ), undef, 'a request with no method defaults to GET and skips the check' );

    ok(
        $app->_request_source_is_same_site(
            source  => 'http://127.0.0.1:7890',
            headers => { host => "  127.0.0.1:7890  " },
        ),
        'the request host is trimmed before the authority comparison',
    );
    ok(
        !$app->_request_source_is_same_site(
            source  => 'http://evil.example',
            headers => { host => ['127.0.0.1'] },
        ),
        'a reference-valued Host header cannot satisfy the comparison',
    );
    ok(
        !$app->_request_source_is_same_site( source => 'http://evil.example' ),
        'a foreign source with no headers hash at all stays foreign',
    );
    ok(
        $app->_request_source_is_same_site(
            source  => 'http://127.0.0.1',
            headers => {},
        ),
        'a loopback source stays same-site when the headers carry no Host',
    );

    # Local::T130::SanlessConfig
    # Duck-typed config stub whose web_settings answers without an
    # ssl_subject_alt_names entry, so the defense's empty-alias fallback is
    # exercised directly rather than through Config fixture defaults.
    {

        package Local::T130::SanlessConfig;

        # new()
        # Purpose: construct the stub. Input: class name. Output: blessed stub.
        sub new { my ($class) = @_; return bless {}, $class }

        # web_settings()
        # Purpose: mimic a config whose web section names no SSL aliases.
        # Input: none. Output: hash reference without ssl_subject_alt_names.
        sub web_settings { return {} }
    }

    my $sanless_app = Developer::Dashboard::Web::App->new(
        auth     => $auth,
        config   => Local::T130::SanlessConfig->new,
        pages    => $store,
        sessions => $sessions,
    );
    ok(
        !$sanless_app->_request_source_is_same_site(
            source  => 'http://evil.example',
            headers => { host => $ADMIN_HOST },
        ),
        'a web-settings hash without alias names contributes no extra aliases',
    );

    # Config objects without web_settings (or non-objects) contribute no extra
    # aliases; the comparison itself must still work.
    for my $bare_config ( {}, $paths ) {
        my $bare_app = Developer::Dashboard::Web::App->new(
            auth     => $auth,
            config   => $bare_config,
            pages    => $store,
            sessions => $sessions,
        );
        ok(
            !$bare_app->_request_source_is_same_site(
                source  => 'http://evil.example',
                headers => { host => $ADMIN_HOST },
            ),
            'a foreign source stays foreign when the config exposes no web settings',
        );
        ok(
            $bare_app->_request_source_is_same_site(
                source  => 'http://localhost',
                headers => { host => 'external.example:7890' },
            ),
            'the localhost family stays a permitted alias without web settings',
        );
    }

    ok( !$auth->host_is_local_alias( host => undef ), 'an undefined host is not a local alias' );
    ok( !$auth->host_is_local_alias( host => '   ' ), 'a blank host is not a local alias' );
    ok( $auth->host_is_local_alias( host => '[::1]:7890' ), 'a bracketed IPv6 loopback with port is a local alias' );
    ok( $auth->host_is_local_alias( host => 'LOCALHOST:80' ), 'localhost matching is case-insensitive and port-blind' );
    ok(
        $auth->host_is_local_alias(
            host                 => 'mybox.local:7890',
            extra_loopback_hosts => [ undef, '', 'MyBox.Local' ],
        ),
        'configured alias entries are canonicalized and blank entries are skipped',
    );
    ok(
        !$auth->host_is_local_alias( host => 'evil.example', extra_loopback_hosts => 'not-an-array' ),
        'a non-array alias list is ignored rather than dereferenced',
    );
}

# ---------------------------------------------------------------------------
# 7. Source scan: the active defense lives in the web layer, so the audit
#    greps for the control keep finding it.
# ---------------------------------------------------------------------------
{
    my $read = sub {
        my ($relative) = @_;
        my $path = File::Spec->catfile( $repo_root, split m{/}, $relative );
        open my $fh, '<', $path or die "Unable to read $path: $!";
        local $/;
        my $source = <$fh>;
        close $fh or die "Unable to close $path: $!";
        return $source;
    };
    like( $read->('lib/Developer/Dashboard/Web/App.pm'), qr/csrf/i, 'the web app source names the CSRF defense' );
    like( $read->('lib/Developer/Dashboard/Web/App.pm'), qr/referer/i, 'the web app source covers the Referer fallback' );
    like( $read->('lib/Developer/Dashboard/Web/DancerApp.pm'), qr/origin/i, 'the route adapter forwards the Origin header' );
}

chdir $repo_root or die "Unable to chdir back to $repo_root: $!";

done_testing();

__END__

=pod

=encoding UTF-8

=head1 NAME

t/130-csrf-origin-defense.t - cross-site requests cannot change dashboard state

=head1 PURPOSE

This test is the cross-site request forgery contract for the web layer. Every
state-changing request (POST, PUT, DELETE, PATCH) that carries a foreign
browser context — an Origin header naming another site, an opaque
C<Origin: null>, or, when Origin is absent, a Referer naming another site —
must be refused with an empty 403 before any tier logic runs. The check must
hold identically on the loopback-admin shortcut, on an authenticated helper
session, and on the ajax machine tier even when valid API credentials are
presented, because a browser attaches cookies and the ambient loopback trust
automatically to cross-site requests.

=head1 WHY IT EXISTS

DD-422 closed the gap DD-421 documented: the loopback-admin tier authorizes
with no cookie at all, so any web page an operator visited could fire
state-changing requests at 127.0.0.1 and they would execute with admin trust.
Browsers always attach an Origin header to cross-site state-changing
requests, so rejecting foreign origins at one choke point blocks that class
of attack. Requests with neither Origin nor Referer stay accepted because
machine clients such as curl and the registered API consumers send neither
header, and a hostile browser cannot suppress Origin on a cross-site
state-changing request.

=head1 WHEN TO USE

Use this file when changing the request authorization flow, the trust-tier
logic, the route adapter's header forwarding, the SSL front-proxy behavior,
or anything that adds a new state-changing route to the web layer.

=head1 HOW TO USE

Run C<prove -lv t/130-csrf-origin-defense.t> while iterating on the web
layer, then keep it green under C<prove -lr t>.

=head1 WHAT USES IT

Developers during TDD and the repository test suite use this file to keep
cross-site browser contexts unable to mutate dashboard state on any tier.

=head1 EXAMPLES

Example 1:

  prove -lv t/130-csrf-origin-defense.t

Example 2:

  prove -lr t

=cut
