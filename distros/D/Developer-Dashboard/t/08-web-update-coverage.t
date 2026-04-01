use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use URI::Escape qw(uri_escape);

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::UpdateManager;
use Developer::Dashboard::Web::App;
use Developer::Dashboard::Web::Server;

sub dies_like {
    my ( $code, $pattern, $label ) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    like( $error, $pattern, $label );
}

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store = Developer::Dashboard::PageStore->new( paths => $paths );
my $auth = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );

my $page = Developer::Dashboard::PageDocument->new(
    id     => 'sample',
    title  => 'Sample',
    layout => { body => 'body text [% stash.name %]' },
);
$store->save_page($page);

my $app = Developer::Dashboard::Web::App->new(
    auth     => $auth,
    pages    => $store,
    sessions => $sessions,
);
dies_like( sub { Developer::Dashboard::Web::App->new( pages => $store, sessions => $sessions ) }, qr/Missing auth store/, 'web app requires auth store' );
dies_like( sub { Developer::Dashboard::Web::App->new }, qr/Missing auth store/, 'web app requires auth before other dependencies' );
dies_like( sub { Developer::Dashboard::Web::App->new( auth => $auth, sessions => $sessions ) }, qr/Missing page store/, 'web app requires page store' );
dies_like( sub { Developer::Dashboard::Web::App->new( auth => $auth, pages => $store ) }, qr/Missing session store/, 'web app requires session store' );

my ( $root_code, $root_type, $root_body ) = @{ $app->handle( path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $root_code, 200, 'root route responds with success' );
like( $root_body, qr/<textarea[^>]*name="instruction"/, 'root route renders free-form instruction editor' );

my ( $apps_code, undef, undef, $apps_headers ) = @{ $app->handle( path => '/apps', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $apps_code, 302, '/apps redirects to default index bookmark' );
is( $apps_headers->{Location}, '/app/index', '/apps uses index bookmark as default target' );

my $token = uri_escape( $store->encode_page($page) );
my ( $edit_code, $edit_type, $edit_body ) = @{ $app->handle( path => '/', query => "token=$token", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $edit_code, 200, 'transient edit route responds with success' );
like( $edit_body, qr/<textarea[^>]*name="instruction"/, 'edit route renders editable source textarea' );
unlike( $edit_body, qr/request_host|request_path|request_remote_addr/, 'edit route does not persist synthetic request metadata into source' );

my ( $render_code, undef, $render_body ) = @{ $app->handle( path => '/', query => "mode=render&token=$token", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $render_code, 200, 'transient render route responds with success' );
like( $render_body, qr/body text/, 'render route includes body text' );

my ( $source_code, $source_type, $source_body ) = @{ $app->handle( path => '/', query => "mode=source&token=$token", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $source_code, 200, 'transient source route responds with success' );
like( $source_type, qr/text\/plain/, 'source route emits instruction text' );
like( $source_body, qr/^TITLE:\s+Sample/m, 'source route returns canonical instruction text' );

my ( $saved_edit_code, undef, $saved_edit_body ) = @{ $app->handle( path => '/page/sample/edit', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $saved_edit_code, 200, 'saved edit route responds with success' );
like( $saved_edit_body, qr/Right Click Copy &amp; Share or Bookmark This Page/, 'saved edit route includes top chrome links' );

my ( $saved_source_code, undef, $saved_source_body ) = @{ $app->handle( path => '/page/sample/source', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $saved_source_code, 200, 'saved source route responds with success' );
like( $saved_source_body, qr/^BOOKMARK:\s+sample/m, 'saved source route returns canonical page instruction source' );
unlike( $saved_source_body, qr/request_host|request_path|request_remote_addr/, 'saved source route does not inject request metadata into source' );

my ( $saved_render_code, undef, $saved_render_body ) = @{ $app->handle( path => '/page/sample', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $saved_render_code, 200, 'saved render route responds with success' );
like( $saved_render_body, qr/body text/, 'saved page route renders bookmark body content' );
is(
    $app->_nav_items_html(
        page            => $page,
        runtime_context => { params => {} },
    ),
    '',
    'shared nav renderer returns empty html when the nav root does not exist',
);

my ( $escaped_code, undef, $escaped_body ) = @{ $app->handle( path => '/', query => "token=$token&name=hello%20world&empty", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $escaped_code, 200, 'query parser tolerates values without equals signs' );
like( $escaped_body, qr/\[% stash\.name %\]/, 'edit mode keeps raw TT source instead of pre-rendered HTML after query parsing' );
my ( $escaped_render_code, undef, $escaped_render_body ) = @{ $app->handle( path => '/', query => "mode=render&token=$token&name=hello%20world&empty", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $escaped_render_code, 200, 'render mode route still responds with success after query parsing' );
like( $escaped_render_body, qr/hello world/, 'render mode still applies query-decoded TT state when rendering' );
is( $app->handle( query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } )->[0], 200, 'handle defaults the path to root when omitted' );
my %parsed = Developer::Dashboard::Web::App::_parse_query('=value&encoded%20key=hello%20world');
is_deeply( \%parsed, { 'encoded key' => 'hello world' }, '_parse_query skips empty keys and decodes URI escapes' );

my $nav_empty = Developer::Dashboard::PageDocument->new(
    id     => 'nav/empty.tt',
    title  => 'Empty Nav',
    layout => {},
);
$store->save_page($nav_empty);
my $nav_form = Developer::Dashboard::PageDocument->new(
    id     => 'nav/form.tt',
    title  => 'Form Nav',
    layout => { form_tt => '<form id="nav-form"></form>', form => '<div id="nav-form-body"></div>' },
);
$store->save_page($nav_form);
my $nav_missing_file = File::Spec->catfile( $paths->dashboards_root, 'nav', 'broken.tt' );
open my $nav_missing_fh, '>', $nav_missing_file or die $!;
print {$nav_missing_fh} "not a bookmark\n";
close $nav_missing_fh;

my $nav_render = $app->_nav_items_html(
    page            => $page,
    runtime_context => { params => {} },
);
like( $nav_render, qr/dashboard-nav-items/, 'shared nav renderer emits a nav container when valid nav tt files exist' );
like( $nav_render, qr/nav-form/, 'shared nav renderer includes form_tt content from nav tt bookmarks' );
like( $nav_render, qr/nav-form-body/, 'shared nav renderer includes form content from nav tt bookmarks' );
unlike( $nav_render, qr/broken\.tt/, 'shared nav renderer skips invalid nav tt bookmark files' );
unlike( $nav_render, qr/empty\.tt/, 'shared nav renderer skips nav tt bookmarks that render an empty fragment' );

my $nav_self_render = $app->_nav_items_html(
    page            => $nav_form,
    runtime_context => { params => {} },
);
is( $nav_self_render, '', 'shared nav renderer does not inject nav items while rendering a nav bookmark itself' );

my $fragment = $app->_page_fragment_html(
    Developer::Dashboard::PageDocument->new(
        layout => { body => '<div id="frag-body"></div>', form_tt => '<div id="frag-form-tt"></div>', form => '<div id="frag-form"></div>' },
        meta   => { runtime_outputs => ['<div id="frag-output"></div>'], runtime_errors => ['boom'] },
    )
);
like( $fragment, qr/frag-body/, '_page_fragment_html includes the page body' );
like( $fragment, qr/frag-form-tt/, '_page_fragment_html includes form_tt content' );
like( $fragment, qr/frag-form/, '_page_fragment_html includes form content' );
like( $fragment, qr/frag-output/, '_page_fragment_html includes runtime output fragments' );
like( $fragment, qr/runtime-error/, '_page_fragment_html renders runtime errors' );
is( $app->_page_fragment_html(), '', '_page_fragment_html returns empty html when no page is provided' );

my ( $not_found_code, $not_found_type, $not_found_body ) = @{ $app->handle( path => '/missing', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $not_found_code, 404, 'unknown routes return not found' );
like( $not_found_type, qr/text\/plain/, 'not found route emits plain text' );
like( $not_found_body, qr/Not found/, 'not found route returns a plain error body' );

is( $auth->trust_tier( remote_addr => '127.0.0.1', host => '127.0.0.1:7890' ), 'admin', 'exact loopback with numeric host is admin' );
is( $auth->trust_tier( remote_addr => '127.0.0.1', host => 'localhost:7890' ), 'helper', 'localhost is not trusted as admin' );
is( $auth->trust_tier( remote_addr => '10.0.0.8', host => '127.0.0.1:7890' ), 'helper', 'non-loopback client is helper' );
my @initial_users = $auth->list_users;
is( scalar @initial_users, 0, 'auth store starts empty' );
ok( !$auth->verify_user( username => 'helper', password => 'nope' ), 'missing user does not verify' );
like( $auth->login_page( message => '<unsafe>' ), qr/&lt;unsafe&gt;/, 'login page escapes message content' );

my ( $login_required_code, undef, $login_required_body ) = @{ $app->handle( path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => 'localhost:7890' } ) };
is( $login_required_code, 401, 'localhost requests require login' );
like( $login_required_body, qr/Helper access requires login/, 'helper request sees login page' );

my $user = $auth->add_user( username => 'helper', password => 'helper-pass-123', role => 'helper' );
is( $user->{role}, 'helper', 'helper user can be created' );
ok( $auth->verify_user( username => 'helper', password => 'helper-pass-123' ), 'correct password verifies' );
ok( !$auth->verify_user( username => 'helper', password => 'wrong' ), 'wrong password does not verify' );
my $alpha = $auth->add_user( username => 'alpha', password => 'alpha-pass-123', role => 'helper' );
is( $alpha->{username}, 'alpha', 'second helper user can be created' );
my @listed_users = $auth->list_users;
is( scalar @listed_users, 2, 'created helper users are listed' );
is_deeply( [ map { $_->{username} } @listed_users ], [ 'alpha', 'helper' ], 'listed users are sorted by username' );

my ( $bad_login_code, undef, $bad_login_body ) = @{ $app->handle(
    path        => '/login',
    method      => 'POST',
    body        => 'username=helper&password=wrong',
    remote_addr => '127.0.0.1',
    headers     => { host => 'localhost:7890' },
) };
is( $bad_login_code, 401, 'bad login is rejected' );
like( $bad_login_body, qr/Invalid username or password/, 'bad login renders error message' );

my ( $login_code, undef, undef, $login_headers ) = @{ $app->handle(
    path        => '/login',
    method      => 'POST',
    body        => 'username=helper&password=helper-pass-123',
    remote_addr => '127.0.0.1',
    headers     => { host => 'localhost:7890' },
) };
is( $login_code, 302, 'valid helper login redirects' );
is( $login_headers->{Location}, '/', 'valid helper login redirects to home' );
like( $login_headers->{'Set-Cookie'}, qr/^dashboard_session=/, 'valid helper login sets session cookie' );

my $session = $sessions->from_cookie( $login_headers->{'Set-Cookie'}, remote_addr => '127.0.0.1' );
is( $session->{username}, 'helper', 'session can be loaded from response cookie' );
ok( !$sessions->from_cookie( $login_headers->{'Set-Cookie'}, remote_addr => '10.0.0.8' ), 'session cookie is bound to the original remote address' );
my $expired = $sessions->create( username => 'helper', role => 'helper', remote_addr => '127.0.0.1', ttl_seconds => -1 );
ok( !$sessions->from_cookie( "dashboard_session=$expired->{session_id}", remote_addr => '127.0.0.1' ), 'expired session is rejected and purged' );
my ( $helper_code, undef, $helper_body ) = @{ $app->handle(
    path        => '/',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => {
        host   => 'localhost:7890',
        cookie => $login_headers->{'Set-Cookie'},
    },
) };
is( $helper_code, 200, 'logged-in helper can view home route' );
like( $helper_body, qr/Developer Dashboard/, 'logged-in helper receives app content' );

my ( $logout_code, undef, undef, $logout_headers ) = @{ $app->handle(
    path        => '/logout',
    method      => 'GET',
    remote_addr => '127.0.0.1',
    headers     => {
        host   => 'localhost:7890',
        cookie => $login_headers->{'Set-Cookie'},
    },
) };
is( $logout_code, 302, 'logout redirects' );
is( $logout_headers->{Location}, '/login', 'logout redirects to login page' );
like( $logout_headers->{'Set-Cookie'}, qr/Max-Age=0/, 'logout expires the session cookie' );
ok( !$sessions->from_cookie( $login_headers->{'Set-Cookie'} ), 'logout deletes the stored session' );

dies_like( sub { Developer::Dashboard::Web::Server->new }, qr/Missing web app/, 'web server requires an app' );
my $default_server = Developer::Dashboard::Web::Server->new( app => $app );
is( $default_server->{host}, '0.0.0.0', 'web server defaults to all interfaces' );
is( $default_server->{port}, 7890, 'web server keeps default port 7890' );

{
    package Local::FakeURI;
    sub new { bless $_[1], $_[0] }
    sub path { $_[0]->{path} }
    sub query { $_[0]->{query} }

    package Local::FakeRequest;
    sub new { bless $_[1], $_[0] }
    sub uri { $_[0]->{uri} }
    sub method { $_[0]->{method} || 'GET' }
    sub content { $_[0]->{content} || '' }
    sub header { $_[0]->{headers}{ $_[1] } }

    package Local::FakeResponse;
    sub new { bless { code => $_[1], headers => {}, content => '' }, $_[0] }
    sub header { $_[0]->{headers}{ $_[1] } = $_[2]; return }
    sub content { $_[0]->{content} = $_[1]; return }

    package Local::FakeConnection;
    sub new { bless { requests => $_[1], sent => [], closed => 0 }, $_[0] }
    sub get_request { shift @{ $_[0]->{requests} } }
    sub send_response { push @{ $_[0]->{sent} }, $_[1]; return }
    sub close { $_[0]->{closed} = 1; return }
    sub peerhost { $_[0]->{peerhost} || '127.0.0.1' }

    package Local::FakeDaemon;
    our @connections;
    sub new { bless { accepted => 0 }, $_[0] }
    sub sockhost { '127.0.0.1' }
    sub sockport { 5999 }
    sub accept { shift @connections }
}

my $server = Developer::Dashboard::Web::Server->new(
    app  => $app,
    host => '127.0.0.1',
    port => 5999,
);

my $conn_one = Local::FakeConnection->new(
    [
        Local::FakeRequest->new(
            {
                uri => Local::FakeURI->new(
                    {
                        path  => '/page/sample/source',
                        query => '',
                    }
                ),
                headers => { Host => '127.0.0.1:5999' },
            }
        ),
    ]
);

{
    no warnings 'redefine';
    local *HTTP::Daemon::new   = sub { Local::FakeDaemon->new(@_) };
    local *HTTP::Response::new = sub { Local::FakeResponse->new( $_[1] ) };
    local @Local::FakeDaemon::connections = ($conn_one);
    my ( $stdout, undef, $exit_code ) = capture {
        system $^X, '-e', 'print q()';
        return $? >> 8;
    };
    is( $exit_code, 0, 'capture test command exits cleanly' );
    local *STDOUT;
    open STDOUT, '>', \my $captured or die $!;
    $server->run;
    like( $captured, qr/Developer Dashboard listening on http:\/\/127\.0\.0\.1:5999\//, 'server announces listening URL' );
}

is( scalar @{ $conn_one->{sent} }, 1, 'server sends one response for the request' );
is( $conn_one->{sent}[0]{code}, 200, 'server returns successful status code from app handle' );
like( $conn_one->{sent}[0]{headers}{'Content-Type'}, qr/text\/plain/, 'server copies instruction source content type onto HTTP response' );
is( $conn_one->{sent}[0]{headers}{'X-Frame-Options'}, 'DENY', 'server sets frame-deny header' );
like( $conn_one->{sent}[0]{headers}{'Content-Security-Policy'}, qr/frame-ancestors 'none'/, 'server sets CSP header' );
is( $conn_one->{sent}[0]{headers}{'Cache-Control'}, 'no-store', 'server disables response caching' );
is( $conn_one->{closed}, 1, 'server closes the connection after processing' );

my $header_app = bless {}, 'Local::HeaderApp';
{
    no warnings 'once';
    *Local::HeaderApp::handle = sub {
        return [
            302,
            'text/plain; charset=utf-8',
            "Redirecting\n",
            {
                Location   => '/login',
                'Set-Cookie' => 'dashboard_session=abc',
            },
        ];
    };
}
my $header_server = Developer::Dashboard::Web::Server->new( app => $header_app );
my $conn_header = Local::FakeConnection->new(
    [
        Local::FakeRequest->new(
            {
                uri     => Local::FakeURI->new( { path => '/login', query => '' } ),
                method  => 'POST',
                content => 'username=helper&password=helper-pass-123',
                headers => { Host => 'localhost:7890' },
            }
        ),
    ]
);
{
    no warnings 'redefine';
    local *HTTP::Daemon::new   = sub { Local::FakeDaemon->new(@_) };
    local *HTTP::Response::new = sub { Local::FakeResponse->new( $_[1] ) };
    local @Local::FakeDaemon::connections = ($conn_header);
    local *STDOUT;
    open STDOUT, '>', \my $captured or die $!;
    $header_server->run;
}
is( $conn_header->{sent}[0]{headers}{Location}, '/login', 'server forwards custom Location headers from the app' );
is( $conn_header->{sent}[0]{headers}{'Set-Cookie'}, 'dashboard_session=abc', 'server forwards custom Set-Cookie headers from the app' );

my $failing_app = bless {}, 'Local::FailingApp';
{
    no warnings 'once';
    *Local::FailingApp::handle = sub { die "exploded\n" };
}
my $failing_server = Developer::Dashboard::Web::Server->new( app => $failing_app );
my $conn_two = Local::FakeConnection->new(
    [
        Local::FakeRequest->new(
            {
                uri => Local::FakeURI->new(
                    {
                        path  => '/',
                        query => '',
                    }
                ),
                headers => { Host => '127.0.0.1:7890' },
            }
        ),
    ]
);
{
    no warnings 'redefine';
    local *HTTP::Daemon::new   = sub { Local::FakeDaemon->new(@_) };
    local *HTTP::Response::new = sub { Local::FakeResponse->new( $_[1] ) };
    local @Local::FakeDaemon::connections = ($conn_two);
    local *STDOUT;
    open STDOUT, '>', \my $captured or die $!;
    $failing_server->run;
}
is( $conn_two->{sent}[0]{code}, 500, 'server converts app exceptions into 500 responses' );
like( $conn_two->{sent}[0]{content}, qr/exploded/, 'server includes error body for exceptions' );

my $conn_three = Local::FakeConnection->new(
    [
        Local::FakeRequest->new(
            {
                uri => Local::FakeURI->new(
                    {
                        path  => '/',
                        query => undef,
                    }
                ),
                headers => { Host => '127.0.0.1:5999' },
            }
        ),
    ]
);
{
    no warnings 'redefine';
    local *HTTP::Daemon::new   = sub { Local::FakeDaemon->new(@_) };
    local *HTTP::Response::new = sub { Local::FakeResponse->new( $_[1] ) };
    local @Local::FakeDaemon::connections = ($conn_three);
    local *STDOUT;
    open STDOUT, '>', \my $captured or die $!;
    $server->run;
}
is( $conn_three->{sent}[0]{code}, 200, 'server treats undef URI queries as empty strings' );

{
    no warnings 'redefine';
    local *HTTP::Daemon::new = sub { return };
    local $! = 98;
    dies_like( sub { $server->run }, qr/Unable to start server/, 'server dies when daemon startup fails' );
}

my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $collector = Developer::Dashboard::Collector->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector,
    files      => $files,
    paths      => $paths,
);
my $updater = Developer::Dashboard::UpdateManager->new(
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);

dies_like( sub { Developer::Dashboard::UpdateManager->new( config => $config ) }, qr/Missing file registry/, 'update manager requires file registry' );
dies_like( sub { Developer::Dashboard::UpdateManager->new( config => $config, files => $files ) }, qr/Missing path registry/, 'update manager requires path registry' );
dies_like( sub { Developer::Dashboard::UpdateManager->new( config => $config, files => $files, paths => $paths ) }, qr/Missing collector runner/, 'update manager requires collector runner' );

my $update_root = tempdir(CLEANUP => 1);
my $update_dir  = File::Spec->catdir( $update_root, 'updates' );
my $collector_state = $paths->collectors_root;
make_path($update_dir);

open my $one_pl, '>', File::Spec->catfile( $update_dir, '01-one.pl' ) or die $!;
print {$one_pl} <<"PL";
print "one\\n";
PL
close $one_pl;

open my $two_sh, '>', File::Spec->catfile( $update_dir, '02-two.sh' ) or die $!;
print {$two_sh} <<"SH";
printf 'two\\n'
SH
close $two_sh;

open my $skip_txt, '>', File::Spec->catfile( $update_dir, '99-skip.txt' ) or die $!;
print {$skip_txt} "skip\n";
close $skip_txt;
make_path( File::Spec->catdir( $update_dir, 'subdir' ) );

open my $pid_a, '>', File::Spec->catfile( $collector_state, 'alpha.pid' ) or die $!;
print {$pid_a} "12345\n";
close $pid_a;
open my $pid_b, '>', File::Spec->catfile( $collector_state, 'beta.pid' ) or die $!;
print {$pid_b} "12346\n";
close $pid_b;

$config->save_global(
    {
        collectors => [
            { name => 'alpha', command => q{printf alpha}, cwd => 'home' },
            { name => 'gamma', command => q{printf gamma}, cwd => 'home' },
            'skip-non-hash',
        ],
    }
);

{
    package Local::TrackingRunner;
    sub new { bless { stop => [], start => [] }, $_[0] }
    sub running_loops { return ( { name => 'alpha' }, { name => 'beta' } ) }
    sub stop_loop { push @{ $_[0]->{stop} }, $_[1]; return $_[1] }
    sub start_loop { push @{ $_[0]->{start} }, $_[1]{name}; return 100 }
}

my $tracking_runner = Local::TrackingRunner->new;
my $tracking_updater = Developer::Dashboard::UpdateManager->new(
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $tracking_runner,
);

{
    no warnings 'redefine';
    local *Developer::Dashboard::UpdateManager::updates_dir = sub { $update_dir };
    my $cwd = getcwd();
    chdir $update_root or die $!;
    local *STDOUT;
    open STDOUT, '>', \my $captured or die $!;
    my $results = $tracking_updater->run;
    chdir $cwd or die $!;
    is_deeply( [ map { $_->{file} } @$results ], [ '01-one.pl', '02-two.sh' ], 'run executes supported update scripts in sorted order' );
    like( $captured, qr/Run Update: 01-one\.pl/, 'run prints update progress for perl scripts' );
    like( $captured, qr/Run Update: 02-two\.sh/, 'run prints update progress for shell scripts' );
    is_deeply( $tracking_runner->{stop}, [ 'alpha', 'beta' ], 'run stops every running collector before updates' );
    is_deeply( $tracking_runner->{start}, ['alpha'], 'run restarts only wanted hash-backed collectors' );
}

open my $silent_pl, '>', File::Spec->catfile( $update_dir, '03-silent.pl' ) or die $!;
print {$silent_pl} <<"PL";
1;
PL
close $silent_pl;
{
    no warnings 'redefine';
    local *Developer::Dashboard::UpdateManager::updates_dir = sub { $update_dir };
    unlink File::Spec->catfile( $collector_state, 'alpha.pid' );
    unlink File::Spec->catfile( $collector_state, 'beta.pid' );
    local *STDOUT;
    open STDOUT, '>', \my $captured or die $!;
    my $results = $tracking_updater->run;
    like( $captured, qr/Run Update: 03-silent\.pl/, 'run executes later silent scripts too' );
    unlike( $captured, qr/\n1\n>> Finished\./, 'run skips printing empty output payloads' );
    is_deeply( [ map { $_->{file} } @$results ], [ '01-one.pl', '02-two.sh', '03-silent.pl' ], 'run still skips unsupported files and directories' );
}

unlink File::Spec->catfile( $collector_state, 'alpha.pid' );
unlink File::Spec->catfile( $collector_state, 'beta.pid' );
open my $other_state, '>', File::Spec->catfile( $collector_state, 'ignore.me' ) or die $!;
print {$other_state} "x\n";
close $other_state;
is_deeply( [ $updater->_running_collectors ], [], '_running_collectors returns an empty list when there are no pidfiles' );
is( $updater->updates_dir, File::Spec->catdir( getcwd(), 'updates' ), 'updates_dir follows the current working directory' );

{
    package Local::RunnerWithLoops;
    sub new { bless {}, $_[0] }
    sub running_loops { return ( { name => 'alpha' }, { name => 'beta' } ) }
    sub stop_loop { return }
    sub start_loop { return }
}
my $loop_updater = Developer::Dashboard::UpdateManager->new(
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => Local::RunnerWithLoops->new,
);
is_deeply( [ $loop_updater->_running_collectors ], [ 'alpha', 'beta' ], '_running_collectors delegates validation to collector runner state' );

done_testing;

__END__

=head1 NAME

08-web-update-coverage.t - extended web and updater behavior tests

=head1 DESCRIPTION

This test verifies extended web server bridging, auth behavior, and update
manager edge cases.

=cut
