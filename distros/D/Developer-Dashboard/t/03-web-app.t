use strict;
use warnings;
use utf8;

use Encode qw(decode);
use File::Path qw(make_path);
use IO::Socket::INET;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use URI::Escape qw(uri_escape);
use Capture::Tiny qw(capture);

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::Codec qw(encode_payload);
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

sub drain_stream_body {
    my ($body) = @_;
    return $body if ref($body) ne 'HASH' || ref( $body->{stream} ) ne 'CODE';
    my $output = '';
    $body->{stream}->( sub { $output .= $_[0] if defined $_[0] } );
    return $output;
}

local $ENV{HOME} = tempdir(CLEANUP => 1);
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
my $repo_root = File::Spec->rel2abs('.');
my $repo_lib = File::Spec->catdir( $repo_root, 'lib' );
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";
my $dashboard_bin = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my ( $seed_init_stdout, $seed_init_stderr, $seed_init_exit ) = capture {
    system( $^X, "-I$repo_lib", $dashboard_bin, 'init' );
};
is( $seed_init_exit, 0, 'dashboard init exits cleanly for web app fixture setup' );
is( $seed_init_stderr, '', 'dashboard init does not emit stderr for web app fixture setup' );

my $paths = Developer::Dashboard::PathRegistry->new;
my $store = Developer::Dashboard::PageStore->new(paths => $paths);
my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $indicators = Developer::Dashboard::IndicatorStore->new(paths => $paths);
my $auth = Developer::Dashboard::Auth->new(
    files => $files,
    paths => $paths,
);
my $sessions = Developer::Dashboard::SessionStore->new(paths => $paths);
my $runtime = Developer::Dashboard::PageRuntime->new(paths => $paths);
my $prompt = Developer::Dashboard::Prompt->new(
    paths      => $paths,
    indicators => $indicators,
);
my $app = Developer::Dashboard::Web::App->new(
    auth     => $auth,
    config   => $config,
    pages    => $store,
    prompt   => $prompt,
    runtime  => $runtime,
    sessions => $sessions,
);
{
    no warnings 'redefine';
    *Developer::Dashboard::Web::App::_machine_ip = sub { '10.20.30.40' };
}

my $page = Developer::Dashboard::PageDocument->new(
    id     => 'welcome',
    title  => 'Welcome',
    layout => { body => 'hello from app [% stash.name %]' },
);
$store->save_page($page);

my $legacy_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Legacy Welcome
:--------------------------------------------------------------------------------:
BOOKMARK: legacy-welcome
:--------------------------------------------------------------------------------:
STASH:
  name => 'World'
:--------------------------------------------------------------------------------:
HTML: <section>Hello [% name %]</section>
:--------------------------------------------------------------------------------:
CODE1: print "<div>Runtime</div>";
PAGE
$store->save_page($legacy_page);

my $nav_alpha = Developer::Dashboard::PageDocument->new(
    id     => 'nav/alpha.tt',
    title  => 'Alpha Nav',
    layout => { body => '[% IF env.current_page == \'/app/index\' %]Home[% ELSE %]<a href="/app/index">Home</a>[% END %]' },
);
$store->save_page($nav_alpha);

my $nav_beta = Developer::Dashboard::PageDocument->new(
    id     => 'nav/beta.tt',
    title  => 'Beta Nav',
    layout => { body => 'nav-current=[% env.current_page %] nav-rt=[% env.runtime_context.current_page %]' },
);
$store->save_page($nav_beta);

my ($code1, $type1, $body1) = @{ $app->handle(path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1, 200, 'root editor route ok');
like($body1, qr/<textarea[^>]*name="instruction"/, 'root route renders editable instruction textarea');
unlike($body1, qr/Saved pages live under/, 'root route no longer renders landing list');
unlike($body1, qr/>Update</, 'root route does not render manual update button');
like($body1, qr/addEventListener\('change', function\(\) \{\s*ddForm\.submit\(\);/s, 'root route auto-submits textarea changes on blur');

my $root_index = Developer::Dashboard::PageDocument->new(
    id     => 'index',
    title  => 'Index',
    layout => { body => 'index body' },
);
$store->save_page($root_index);
my ($root_index_code, undef, undef, $root_index_headers) = @{ $app->handle(path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($root_index_code, 302, 'root route redirects to the saved index bookmark when it exists');
is($root_index_headers->{Location}, '/app/index', 'root route uses the canonical saved index bookmark path');
unlink $store->page_file('index') or die "Unable to remove temporary index bookmark: $!";

my ($unknown_code, undef, $unknown_body) = @{ $app->handle(path => '/app/foobar', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($unknown_code, 200, 'unknown saved app routes open the editor instead of returning a not-found page');
like($unknown_body, qr/<textarea[^>]*name="instruction"/, 'unknown saved app routes render the bookmark editor');
like($unknown_body, qr/BOOKMARK:\s+\/app\/foobar/, 'unknown saved app routes prefill the requested bookmark path');
like($unknown_body, qr/HTML:\s*\nBlank page/s, 'unknown saved app routes prefill the blank page body');

my $prefixed_saved_page = Developer::Dashboard::PageDocument->new(
    id     => '/app/prefixed-save',
    title  => 'Prefixed Save',
    layout => { body => 'prefixed body' },
);
$store->save_page($prefixed_saved_page);
ok(-f File::Spec->catfile( $paths->dashboards_root, 'prefixed-save' ), 'save_page normalizes a leading /app/ prefix to the relative dashboards path');
my $loaded_prefixed_page = $store->load_saved_page('prefixed-save');
is($loaded_prefixed_page->as_hash->{title}, 'Prefixed Save', 'load_saved_page resolves normalized prefixed bookmark ids');

my ( $api_page_stdout, $api_page_stderr, $api_page_exit ) = capture {
    system( $^X, "-I$repo_lib", $dashboard_bin, 'page', 'source', 'api-dashboard' );
};
is( $api_page_exit, 0, 'api-dashboard source command exits cleanly for web app fixture setup' );
is( $api_page_stderr, '', 'api-dashboard source command does not emit stderr for web app fixture setup' );
my $api_page = Developer::Dashboard::PageDocument->from_instruction($api_page_stdout);
$store->save_page($api_page);
my ( $api_render_code, undef, $api_render_body ) = @{ $app->handle( path => '/app/api-dashboard', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $api_render_code, 200, 'api-dashboard saved route renders through the web app' );
like( $api_render_body, qr/Import Postman Collection/, 'api-dashboard render exposes Postman collection import controls' );
like( $api_render_body, qr/Export Postman Collection/, 'api-dashboard render exposes Postman collection export controls' );
like( $api_render_body, qr/New Tab/, 'api-dashboard render exposes request tab controls' );
like( $api_render_body, qr/api-response-preview/, 'api-dashboard render exposes a dedicated response preview surface' );
like( $api_render_body, qr/history\.pushState/, 'api-dashboard render updates browser history for navigation-aware workspace locations' );
like( $api_render_body, qr/window\.addEventListener\('popstate'/, 'api-dashboard render restores workspace state on browser back and forward navigation' );
like( $api_render_body, qr/URLSearchParams/, 'api-dashboard render reads bookmark workspace location from the URL' );
like( $api_render_body, qr{set_chain_value\(configs,'collections\.bootstrap','/ajax/api-dashboard-bootstrap\?type=json'\)}, 'api-dashboard render binds the bootstrap collection ajax endpoint' );
like( $api_render_body, qr{set_chain_value\(configs,'collections\.save','/ajax/api-dashboard-collections-save\?type=json'\)}, 'api-dashboard render binds the collection save ajax endpoint' );
like( $api_render_body, qr{set_chain_value\(configs,'collections\.delete','/ajax/api-dashboard-collections-delete\?type=json'\)}, 'api-dashboard render binds the collection delete ajax endpoint' );
like( $api_render_body, qr{set_chain_value\(configs,'send\.request','/ajax/api-dashboard-send-request\?type=json'\)}, 'api-dashboard render binds the saved request sender ajax endpoint' );
like( $api_render_body, qr/var requestPayload = payload && payload\.request \|\| \{\};/, 'api-dashboard render guards request detail rendering when the UI shows a transient status payload' );
like( $api_render_body, qr/var responsePayload = payload && payload\.response \|\| \{\};/, 'api-dashboard render guards response detail rendering when the UI shows a transient status payload' );
like( $api_render_body, qr/Show Credentials/, 'api-dashboard render exposes a hide and show credentials section in the workspace' );
like( $api_render_body, qr/id="api-auth-kind"/, 'api-dashboard render exposes a credentials type selector in the workspace' );
like( $api_render_body, qr/Apple Login/, 'api-dashboard render exposes the Apple login credentials preset' );
like( $api_render_body, qr/Amazon Login/, 'api-dashboard render exposes the Amazon login credentials preset' );
like( $api_render_body, qr/Facebook Login/, 'api-dashboard render exposes the Facebook login credentials preset' );
like( $api_render_body, qr/Microsoft Login/, 'api-dashboard render exposes the Microsoft login credentials preset' );
like( $api_page_stdout, qr/use LWP::Protocol::https \(\);/, 'api-dashboard saved ajax sender explicitly loads HTTPS protocol support' );
my $api_dashboard_config_root = File::Spec->catdir( $paths->config_root, 'api-dashboard' );
make_path($api_dashboard_config_root);
my $bootstrap_collection_file = File::Spec->catfile( $api_dashboard_config_root, 'Bootstrap Collection.json' );
open my $bootstrap_collection_fh, '>', $bootstrap_collection_file or die "Unable to write $bootstrap_collection_file: $!";
print {$bootstrap_collection_fh} json_encode(
    {
        info     => {
            name        => 'Bootstrap Collection',
            description => 'Bootstrapped from config/api-dashboard',
            schema      => 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
        },
        variable => [
            {
                key   => 'base_url',
                value => 'https://example.test',
            },
        ],
        item     => [],
    }
);
close $bootstrap_collection_fh or die "Unable to close $bootstrap_collection_file: $!";
my ($api_bootstrap_code, $api_bootstrap_type, $api_bootstrap_body_ref) = @{ $app->handle(
    path        => '/ajax/api-dashboard-bootstrap',
    query       => 'type=json',
    method      => 'GET',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $api_bootstrap_code, 200, 'api-dashboard bootstrap ajax endpoint responds through the saved ajax file route' );
like( $api_bootstrap_type, qr/application\/json/, 'api-dashboard bootstrap ajax endpoint returns json content' );
my $api_bootstrap_payload = json_decode( drain_stream_body($api_bootstrap_body_ref) );
ok( ref($api_bootstrap_payload) eq 'HASH', 'api-dashboard bootstrap ajax endpoint returns a json object' );
ok( exists $api_bootstrap_payload->{collections}, 'api-dashboard bootstrap ajax payload includes collections' );
ok( exists $api_bootstrap_payload->{errors}, 'api-dashboard bootstrap ajax payload includes explicit bootstrap errors' );
is_deeply(
    [ map { $_->{info}{name} } @{ $api_bootstrap_payload->{collections} || [] } ],
    ['Bootstrap Collection'],
    'api-dashboard bootstrap ajax endpoint loads Postman collections from config/api-dashboard',
);

my $save_collection_payload = json_encode(
    {
        info     => {
            name        => 'Saved Collection',
            description => 'Saved through the api-dashboard ajax endpoint',
            schema      => 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
        },
        variable => [
            {
                key   => 'token',
                value => 'abc123',
            },
        ],
        item     => [
            {
                name    => 'List Orders',
                request => {
                    method      => 'GET',
                    header      => [
                        {
                            key   => 'Accept',
                            value => 'application/json',
                        },
                    ],
                    url         => {
                        raw => 'https://example.test/orders',
                    },
                    description => 'List all orders.',
                },
            },
        ],
    }
);
my ($api_collection_save_code, $api_collection_save_type, $api_collection_save_body_ref) = @{ $app->handle(
    path        => '/ajax/api-dashboard-collections-save',
    query       => 'type=json',
    method      => 'POST',
    body        => 'collection=' . uri_escape($save_collection_payload),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $api_collection_save_code, 200, 'api-dashboard collection save endpoint responds through the saved ajax file route' );
like( $api_collection_save_type, qr/application\/json/, 'api-dashboard collection save endpoint returns json content' );
my $api_collection_save_payload = json_decode( drain_stream_body($api_collection_save_body_ref) );
ok( $api_collection_save_payload->{ok}, 'api-dashboard collection save endpoint reports success' );
is( $api_collection_save_payload->{collection}{info}{name}, 'Saved Collection', 'api-dashboard collection save endpoint returns the saved Postman collection' );
my $saved_collection_file = File::Spec->catfile( $api_dashboard_config_root, 'Saved Collection.json' );
ok( -f $saved_collection_file, 'api-dashboard collection save endpoint writes config/api-dashboard/<collection-name>.json' );
is( sprintf( '%04o', ( stat($api_dashboard_config_root) )[2] & 07777 ), '0700', 'api-dashboard collection directory is tightened to owner-only permissions' );
is( sprintf( '%04o', ( stat($saved_collection_file) )[2] & 07777 ), '0600', 'api-dashboard collection files are tightened to owner-only permissions' );
my $saved_collection_raw = do {
    open my $saved_collection_fh, '<', $saved_collection_file or die "Unable to read $saved_collection_file: $!";
    local $/;
    my $raw = <$saved_collection_fh>;
    close $saved_collection_fh or die "Unable to close $saved_collection_file: $!";
    $raw;
};
my $saved_collection_json = json_decode($saved_collection_raw);
is( $saved_collection_json->{info}{name}, 'Saved Collection', 'api-dashboard collection save endpoint stores Postman collection info.name' );
is( $saved_collection_json->{item}[0]{name}, 'List Orders', 'api-dashboard collection save endpoint stores Postman collection items' );
like( $saved_collection_raw, qr/\Q"schema" : "https:\/\/schema.getpostman.com\/json\/collection\/v2.1.0\/collection.json"\E/, 'api-dashboard collection save endpoint stores Postman schema metadata in the json file' );

my $large_collection_payload = json_encode(
    {
        info     => {
            name        => 'Large Saved Collection',
            description => 'Saved through the api-dashboard ajax endpoint with an oversized request body payload',
            schema      => 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
        },
        variable => [],
        item     => [
            {
                name    => 'Large Saved Request',
                request => {
                    method      => 'POST',
                    header      => [
                        {
                            key   => 'Content-Type',
                            value => 'application/json',
                        },
                    ],
                    body        => {
                        mode => 'raw',
                        raw  => ( 'A' x 250_000 ),
                    },
                    url         => {
                        raw => 'https://example.test/large-save',
                    },
                    description => 'Large save regression fixture.',
                },
            },
        ],
    }
);
my ($api_large_collection_save_code, $api_large_collection_save_type, $api_large_collection_save_body_ref) = @{ $app->handle(
    path        => '/ajax/api-dashboard-collections-save',
    query       => 'type=json',
    method      => 'POST',
    body        => 'collection=' . uri_escape($large_collection_payload),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $api_large_collection_save_code, 200, 'api-dashboard collection save endpoint accepts an oversized collection payload' );
like( $api_large_collection_save_type, qr/application\/json/, 'api-dashboard oversized collection save returns json content' );
my $api_large_collection_save_payload = json_decode( drain_stream_body($api_large_collection_save_body_ref) );
ok( $api_large_collection_save_payload->{ok}, 'api-dashboard oversized collection save reports success' );
my $large_saved_collection_file = File::Spec->catfile( $api_dashboard_config_root, 'Large Saved Collection.json' );
ok( -f $large_saved_collection_file, 'api-dashboard oversized collection save writes config/api-dashboard/<collection-name>.json' );
my $large_saved_collection_json = json_decode( do {
    open my $large_saved_collection_fh, '<', $large_saved_collection_file or die "Unable to read $large_saved_collection_file: $!";
    local $/;
    my $raw = <$large_saved_collection_fh>;
    close $large_saved_collection_fh or die "Unable to close $large_saved_collection_file: $!";
    $raw;
} );
is( length( $large_saved_collection_json->{item}[0]{request}{body}{raw} || '' ), 250_000, 'api-dashboard oversized collection save preserves the full request body payload' );

my $save_collection_update_payload = json_encode(
    {
        info     => {
            name        => 'Saved Collection',
            description => 'Updated through the api-dashboard ajax endpoint',
            schema      => 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
        },
        variable => [
            {
                key   => 'token',
                value => 'xyz789',
            },
        ],
        item     => [
            {
                name    => 'List Customers',
                request => {
                    method      => 'GET',
                    header      => [],
                    url         => {
                        raw => 'https://example.test/customers',
                    },
                    description => 'List all customers.',
                },
            },
        ],
    }
);
my ($api_collection_update_code, $api_collection_update_type, $api_collection_update_body_ref) = @{ $app->handle(
    path        => '/ajax/api-dashboard-collections-save',
    query       => 'type=json',
    method      => 'POST',
    body        => 'collection=' . uri_escape($save_collection_update_payload),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $api_collection_update_code, 200, 'api-dashboard collection save endpoint updates an existing collection file when the collection name is unchanged' );
like( $api_collection_update_type, qr/application\/json/, 'api-dashboard collection update returns json content' );
my $api_collection_update_payload = json_decode( drain_stream_body($api_collection_update_body_ref) );
ok( $api_collection_update_payload->{ok}, 'api-dashboard collection update reports success' );
my $updated_collection_json = json_decode( do {
    open my $updated_collection_fh, '<', $saved_collection_file or die "Unable to read $saved_collection_file: $!";
    local $/;
    my $raw = <$updated_collection_fh>;
    close $updated_collection_fh or die "Unable to close $saved_collection_file: $!";
    $raw;
} );
is( $updated_collection_json->{item}[0]{name}, 'List Customers', 'api-dashboard collection update overwrites the existing file with the latest Postman collection item data' );

my $rename_collection_payload = json_encode(
    {
        info     => {
            name        => 'Renamed Collection',
            description => 'Renamed through the api-dashboard ajax endpoint',
            schema      => 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
        },
        variable => [],
        item     => [],
    }
);
my ($api_collection_rename_code, $api_collection_rename_type, $api_collection_rename_body_ref) = @{ $app->handle(
    path        => '/ajax/api-dashboard-collections-save',
    query       => 'type=json',
    method      => 'POST',
    body        => 'collection=' . uri_escape($rename_collection_payload) . '&original_name=' . uri_escape('Saved Collection'),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $api_collection_rename_code, 200, 'api-dashboard collection save endpoint supports renaming an existing saved collection' );
like( $api_collection_rename_type, qr/application\/json/, 'api-dashboard collection rename returns json content' );
my $api_collection_rename_payload = json_decode( drain_stream_body($api_collection_rename_body_ref) );
ok( $api_collection_rename_payload->{ok}, 'api-dashboard collection rename reports success' );
ok( !-e $saved_collection_file, 'api-dashboard collection rename removes the previous collection file name' );
my $renamed_collection_file = File::Spec->catfile( $api_dashboard_config_root, 'Renamed Collection.json' );
ok( -f $renamed_collection_file, 'api-dashboard collection rename writes the new collection file name' );

my ($api_collection_delete_code, $api_collection_delete_type, $api_collection_delete_body_ref) = @{ $app->handle(
    path        => '/ajax/api-dashboard-collections-delete',
    query       => 'type=json',
    method      => 'POST',
    body        => 'name=' . uri_escape('Renamed Collection'),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $api_collection_delete_code, 200, 'api-dashboard collection delete endpoint responds through the saved ajax file route' );
like( $api_collection_delete_type, qr/application\/json/, 'api-dashboard collection delete endpoint returns json content' );
my $api_collection_delete_payload = json_decode( drain_stream_body($api_collection_delete_body_ref) );
ok( $api_collection_delete_payload->{ok}, 'api-dashboard collection delete endpoint reports success' );
ok( !-e $renamed_collection_file, 'api-dashboard collection delete endpoint removes config/api-dashboard/<collection-name>.json' );

my $probe_listener = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen    => 1,
    Proto     => 'tcp',
    ReuseAddr => 1,
) or die "Unable to start probe listener: $!";
my $probe_port = $probe_listener->sockport;
my $probe_pid = fork();
die "Unable to fork probe listener: $!" if !defined $probe_pid;
if ( !$probe_pid ) {
    my $client = $probe_listener->accept or die "Unable to accept probe connection: $!";
    my $request = '';
    while ( my $line = <$client> ) {
        $request .= $line;
        last if $line =~ /^\r?\n$/;
    }
    print {$client} "HTTP/1.1 201 Created\r\n";
    print {$client} "Content-Type: application/json\r\n";
    print {$client} "X-Probe: active\r\n";
    print {$client} "Content-Length: 18\r\n";
    print {$client} "\r\n";
    print {$client} "{\"ok\":true,\"id\":7}";
    close $client or die "Unable to close probe client: $!";
    exit 0;
}
close $probe_listener or die "Unable to close parent probe listener: $!";
my $api_send_settings = json_encode(
    {
        method           => 'GET',
        url              => "http://127.0.0.1:$probe_port/check",
        headers_text     => "Accept: application/json\nX-Test: api-dashboard",
        body             => '',
        timeout_s        => 5,
        follow_redirects => 1,
        insecure_tls     => 0,
    }
);
my ($api_send_code, $api_send_type, $api_send_body_ref) = @{ $app->handle(
    path        => '/ajax/api-dashboard-send-request',
    query       => 'type=json',
    method      => 'POST',
    body        => 'settings=' . uri_escape($api_send_settings),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $api_send_code, 200, 'api-dashboard saved request sender responds through the saved ajax file route' );
like( $api_send_type, qr/application\/json/, 'api-dashboard saved request sender returns json content' );
my $api_send_payload = json_decode( drain_stream_body($api_send_body_ref) );
ok( $api_send_payload->{ok}, 'api-dashboard saved request sender reports a successful upstream request' );
is( $api_send_payload->{response}{status}, 201, 'api-dashboard saved request sender preserves upstream status codes' );
is( $api_send_payload->{response}{content_type}, 'application/json', 'api-dashboard saved request sender preserves upstream content type' );
is( $api_send_payload->{response}{body_mode}, 'json', 'api-dashboard saved request sender classifies JSON payloads for formatted rendering' );
my $api_send_rendered_json = json_decode( $api_send_payload->{response}{body} );
ok( $api_send_rendered_json->{ok}, 'api-dashboard saved request sender pretty prints upstream JSON response bodies with the ok field preserved' );
is( $api_send_rendered_json->{id}, 7, 'api-dashboard saved request sender pretty prints upstream JSON response bodies with the id field preserved' );
is( $api_send_payload->{request}{method}, 'GET', 'api-dashboard saved request sender returns the dispatched request method' );
is( $api_send_payload->{request}{url}, "http://127.0.0.1:$probe_port/check", 'api-dashboard saved request sender returns the dispatched request URL' );
like( $api_send_payload->{request}{headers_text}, qr/X-Test: api-dashboard/, 'api-dashboard saved request sender returns request headers for detailed inspection' );
my $probe_wait_pid = waitpid( $probe_pid, 0 );
is( $probe_wait_pid, $probe_pid, 'probe listener child exits after the api-dashboard sender call' );
is( $?, 0, 'probe listener child exits cleanly after serving the api-dashboard sender call' );

my $auth_listener = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen    => 1,
    Proto     => 'tcp',
    ReuseAddr => 1,
) or die "Unable to start auth listener: $!";
my $auth_port = $auth_listener->sockport;
my $auth_pid = fork();
die "Unable to fork auth listener: $!" if !defined $auth_pid;
if ( !$auth_pid ) {
    my $client = $auth_listener->accept or die "Unable to accept auth connection: $!";
    my $request_line = <$client>;
    die "Unable to read auth request line" if !defined $request_line;
    $request_line =~ s/\r?\n\z//;
    my ( $method, $target ) = split /\s+/, $request_line;
    my %headers;
    while ( my $line = <$client> ) {
        $line =~ s/\r?\n\z//;
        last if $line eq '';
        my ( $key, $value ) = split /:\s*/, $line, 2;
        $headers{ lc($key) } = defined $value ? $value : '';
    }
    my $payload = json_encode(
        {
            ok            => 1,
            method        => $method || '',
            target        => $target || '',
            authorization => $headers{authorization} || '',
        }
    );
    print {$client} "HTTP/1.1 200 OK\r\n";
    print {$client} "Content-Type: application/json\r\n";
    print {$client} "Content-Length: " . length($payload) . "\r\n";
    print {$client} "\r\n";
    print {$client} $payload;
    close $client or die "Unable to close auth client: $!";
    exit 0;
}
close $auth_listener or die "Unable to close parent auth listener: $!";
my $api_auth_send_settings = json_encode(
    {
        method           => 'GET',
        url              => "http://127.0.0.1:$auth_port/secure",
        headers_text     => "Accept: application/json\nAuthorization: Bearer stale-token",
        body             => '',
        timeout_s        => 5,
        follow_redirects => 1,
        insecure_tls     => 0,
        auth             => {
            type     => 'basic',
            username => 'api-user',
            password => 'api-pass',
        },
    }
);
my ($api_auth_send_code, $api_auth_send_type, $api_auth_send_body_ref) = @{ $app->handle(
    path        => '/ajax/api-dashboard-send-request',
    query       => 'type=json',
    method      => 'POST',
    body        => 'settings=' . uri_escape($api_auth_send_settings),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $api_auth_send_code, 200, 'api-dashboard sender accepts request auth settings through the saved ajax route' );
like( $api_auth_send_type, qr/application\/json/, 'api-dashboard sender keeps auth-backed requests inside the json envelope' );
my $api_auth_send_payload = json_decode( drain_stream_body($api_auth_send_body_ref) );
ok( $api_auth_send_payload->{ok}, 'api-dashboard sender reports success for auth-backed requests' );
my $api_auth_echo = json_decode( $api_auth_send_payload->{response}{body} );
is(
    $api_auth_echo->{authorization},
    'Basic YXBpLXVzZXI6YXBpLXBhc3M=',
    'api-dashboard sender replaces stale Authorization headers with Basic auth credentials from the request auth settings'
);
my $auth_wait_pid = waitpid( $auth_pid, 0 );
is( $auth_wait_pid, $auth_pid, 'auth listener child exits after the api-dashboard auth sender call' );
is( $?, 0, 'auth listener child exits cleanly after serving the api-dashboard auth sender call' );

my $apikey_listener = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen    => 1,
    Proto     => 'tcp',
    ReuseAddr => 1,
) or die "Unable to start api key listener: $!";
my $apikey_port = $apikey_listener->sockport;
my $apikey_pid = fork();
die "Unable to fork api key listener: $!" if !defined $apikey_pid;
if ( !$apikey_pid ) {
    my $client = $apikey_listener->accept or die "Unable to accept api key connection: $!";
    my $request_line = <$client>;
    die "Unable to read api key request line" if !defined $request_line;
    $request_line =~ s/\r?\n\z//;
    my ( $method, $target ) = split /\s+/, $request_line;
    while ( my $line = <$client> ) {
        last if $line =~ /^\r?\n$/;
    }
    my $payload = json_encode(
        {
            ok     => 1,
            method => $method || '',
            target => $target || '',
        }
    );
    print {$client} "HTTP/1.1 200 OK\r\n";
    print {$client} "Content-Type: application/json\r\n";
    print {$client} "Content-Length: " . length($payload) . "\r\n";
    print {$client} "\r\n";
    print {$client} $payload;
    close $client or die "Unable to close api key client: $!";
    exit 0;
}
close $apikey_listener or die "Unable to close parent api key listener: $!";
my $api_apikey_send_settings = json_encode(
    {
        method           => 'GET',
        url              => "http://127.0.0.1:$apikey_port/secure?name=ping",
        headers_text     => "Accept: application/json",
        body             => '',
        timeout_s        => 5,
        follow_redirects => 1,
        insecure_tls     => 0,
        auth             => {
            type  => 'apikey',
            key   => 'api_key',
            value => 'abc123',
            in    => 'query',
        },
    }
);
my ($api_apikey_send_code, $api_apikey_send_type, $api_apikey_send_body_ref) = @{ $app->handle(
    path        => '/ajax/api-dashboard-send-request',
    query       => 'type=json',
    method      => 'POST',
    body        => 'settings=' . uri_escape($api_apikey_send_settings),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $api_apikey_send_code, 200, 'api-dashboard sender accepts API key auth settings through the saved ajax route' );
like( $api_apikey_send_type, qr/application\/json/, 'api-dashboard sender returns api key requests as json payloads' );
my $api_apikey_send_payload = json_decode( drain_stream_body($api_apikey_send_body_ref) );
ok( $api_apikey_send_payload->{ok}, 'api-dashboard sender reports success for API key requests' );
is(
    $api_apikey_send_payload->{request}{url},
    "http://127.0.0.1:$apikey_port/secure?name=ping&api_key=abc123",
    'api-dashboard sender appends query-style API key auth to the dispatched request URL'
);
my $api_apikey_echo = json_decode( $api_apikey_send_payload->{response}{body} );
is(
    $api_apikey_echo->{target},
    '/secure?name=ping&api_key=abc123',
    'api-dashboard sender forwards query-style API key auth to the upstream request target'
);
my $apikey_wait_pid = waitpid( $apikey_pid, 0 );
is( $apikey_wait_pid, $apikey_pid, 'api key listener child exits after the api-dashboard api key sender call' );
is( $?, 0, 'api key listener child exits cleanly after serving the api-dashboard api key sender call' );

my $preview_listener = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen    => 1,
    Proto     => 'tcp',
    ReuseAddr => 1,
) or die "Unable to start preview listener: $!";
my $preview_port = $preview_listener->sockport;
my $preview_pid = fork();
die "Unable to fork preview listener: $!" if !defined $preview_pid;
if ( !$preview_pid ) {
    my $client = $preview_listener->accept or die "Unable to accept preview connection: $!";
    my $request = '';
    while ( my $line = <$client> ) {
        $request .= $line;
        last if $line =~ /^\r?\n$/;
    }
    my $png = pack( 'H*', '89504e470d0a1a0a0000000d4948445200000001000000010802000000907753de0000000c49444154789c63606060000000040001f61738550000000049454e44ae426082' );
    print {$client} "HTTP/1.1 200 OK\r\n";
    print {$client} "Content-Type: image/png\r\n";
    print {$client} "Content-Length: " . length($png) . "\r\n";
    print {$client} "\r\n";
    print {$client} $png;
    close $client or die "Unable to close preview client: $!";
    exit 0;
}
close $preview_listener or die "Unable to close parent preview listener: $!";
my $preview_settings = json_encode(
    {
        method           => 'GET',
        url              => "http://127.0.0.1:$preview_port/image",
        headers_text     => "Accept: image/png",
        body             => '',
        timeout_s        => 5,
        follow_redirects => 1,
        insecure_tls     => 0,
    }
);
my ($preview_code, $preview_type, $preview_body_ref) = @{ $app->handle(
    path        => '/ajax/api-dashboard-send-request',
    query       => 'type=json',
    method      => 'POST',
    body        => 'settings=' . uri_escape($preview_settings),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $preview_code, 200, 'api-dashboard sender returns previewable media payloads through the saved ajax file route' );
like( $preview_type, qr/application\/json/, 'api-dashboard sender keeps previewable media responses inside the json envelope' );
my $preview_payload = json_decode( drain_stream_body($preview_body_ref) );
ok( $preview_payload->{ok}, 'api-dashboard sender reports previewable media responses as successful' );
is( $preview_payload->{response}{body_mode}, 'preview', 'api-dashboard sender classifies previewable media responses for browser rendering' );
is( $preview_payload->{response}{preview_media_type}, 'image/png', 'api-dashboard sender returns the preview media type for browser rendering' );
like( $preview_payload->{response}{preview_url}, qr{\Adata:image/png;base64,}, 'api-dashboard sender returns a browser-previewable data URL for images' );
my $preview_wait_pid = waitpid( $preview_pid, 0 );
is( $preview_wait_pid, $preview_pid, 'preview listener child exits after the api-dashboard media sender call' );
is( $?, 0, 'preview listener child exits cleanly after serving the api-dashboard media sender call' );

my $saved_token = uri_escape( $store->encode_page($page) );
my ($code1_forbidden_post, $type1_forbidden_post, $body1_forbidden_post) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Posted%20Page%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20posted%20body%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1_forbidden_post, 403, 'posted transient instruction route is denied by default');
like($type1_forbidden_post, qr/text\/plain/, 'posted transient instruction denial returns plain text');
like($body1_forbidden_post, qr/Transient token URLs are disabled/, 'posted transient instruction denial explains the policy');

my ($code1_forbidden_token, undef, $body1_forbidden_token) = @{ $app->handle(
    path        => '/',
    query       => "mode=render&token=$saved_token",
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1_forbidden_token, 403, 'tokenized transient page route is denied by default');
like($body1_forbidden_token, qr/Transient token URLs are disabled/, 'tokenized transient page denial explains the policy');

my ($code1_allowed_bookmark, undef, $body1_allowed_bookmark) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Saved%20From%20Default%20Policy%0A%3A--------------------------------------------------------------------------------%3A%0ABOOKMARK%3A%20allowed-under-default%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20saved%20body%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1_allowed_bookmark, 200, 'posted bookmark instruction is still allowed when transient URLs are disabled');
like($body1_allowed_bookmark, qr/saved body/, 'posted bookmark instruction still renders after it is saved');
ok( -f File::Spec->catfile( $paths->dashboards_root, 'allowed-under-default' ), 'posted bookmark instruction still persists bookmark files when transient URLs are disabled' );

local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;

my ($code1b, undef, $body1b) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Posted%20Page%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20posted%20body%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1b, 200, 'posted instruction route ok');
like($body1b, qr/posted body/, 'posted instruction renders through the root route');
unlike($body1b, qr/"instruction"\s*:/, 'posted instruction text is not folded back into stash');
unlike($body1b, qr/"request_host"\s*:/, 'posted instruction does not persist request metadata into stash');
my ($play_url) = $body1b =~ m{<a href="([^"]+)" id="play-url">Play</a>};
ok($play_url, 'play url extracted from root editor response');
unlike($body1b, qr/id="view-source-url"/, 'edit mode does not render view source link');
my ($play_query) = $play_url =~ /\?(.*)\z/;
my ($code1c, undef, $body1c) = @{ $app->handle(
    path        => '/',
    query       => $play_query,
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1c, 200, 'play url round-trips through token query parsing');
like($body1c, qr/posted body/, 'play url token survives browser-style query transport');
like($body1c, qr/nav-current=\/ nav-rt=\//, 'unnamed transient play route exposes the root path to shared nav tt fragments');
my $raw_plus_query = $play_query;
$raw_plus_query =~ s/%2B/+/g;
my ($code1c_plus, undef, $body1c_plus) = @{ $app->handle(
    path        => '/',
    query       => $raw_plus_query,
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1c_plus, 200, 'play url survives raw plus token query transport');
like($body1c_plus, qr/posted body/, 'raw plus token query still decodes correctly');

my ($code1d, undef, $body1d) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A+Plus+Page%0A%3A--------------------------------------------------------------------------------%3A%0ACODE1%3A+print+123%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d, 200, 'form-urlencoded instruction with plus spacing route ok');
like($body1d, qr/123/, 'form-urlencoded root editor can execute opted-in transient CODE blocks');
unlike($body1d, qr/"instruction"\s*:/, 'form-urlencoded update does not pollute stash with instruction text');
unlike($body1d, qr/"request_host"\s*:/, 'form-urlencoded update does not persist request metadata');

my ($code1d_bookmark, undef, $body1d_bookmark) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Developer%20Dashboard%0A%3A--------------------------------------------------------------------------------%3A%0ABOOKMARK%3A%20index%0A%3A--------------------------------------------------------------------------------%3A%0ASTASH%3A%20%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20HERE%20%5B%25%20env.current_page%20%25%5D%20%5B%25%20env.runtime_context.current_page%20%25%5D%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_bookmark, 200, 'posted bookmark instruction route ok');
ok( -f File::Spec->catfile( $paths->dashboards_root, 'index' ), 'root editor saves posted bookmark instructions to the bookmark store' );
like($body1d_bookmark, qr/BOOKMARK:\s+index/s, 'posted bookmark response preserves the bookmark id');
my ($code1d_saved, undef, $body1d_saved) = @{ $app->handle(path => '/app/index', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_saved, 200, 'legacy /app/index route loads a bookmark saved from the root editor');
like($body1d_saved, qr/HERE \/app\/index \/app\/index/, 'legacy /app/index route renders the saved bookmark body with current page context');
like($body1d_saved, qr/class="dashboard-nav-items"/, 'saved page render includes shared nav section when nav tt pages exist');
like($body1d_saved, qr{<li data-nav-id="nav/alpha\.tt">Home</li>}s, 'shared nav fragments evaluate Template Toolkit conditionals against the current page');
like($body1d_saved, qr/nav-current=\/app\/index nav-rt=\/app\/index/, 'shared nav fragments receive env.current_page and env.runtime_context.current_page');

my $saved_play_token = uri_escape( $store->encode_page( Developer::Dashboard::PageDocument->from_instruction(<<'PAGE') ) );
TITLE: Saved Bookmark Via Token
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML: token body
PAGE
my ($code1d_saved_play, undef, $body1d_saved_play) = @{ $app->handle(
    path        => '/',
    query       => "mode=render&token=$saved_play_token",
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_saved_play, 200, 'transient render route responds for a named bookmark token');
like($body1d_saved_play, qr/class="dashboard-nav-items"/, 'transient render for a named bookmark keeps the shared nav section');
like($body1d_saved_play, qr{<li data-nav-id="nav/alpha\.tt">Home</li>}s, 'transient render for a named bookmark evaluates nav tt fragments against the saved page route');
like($body1d_saved_play, qr/nav-current=\/app\/index nav-rt=\/app\/index/, 'transient render for a named bookmark exposes the saved page path to nav tt fragments');

my ($code1d_nav, undef, $body1d_nav) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Nav%20Editor%0A%3A--------------------------------------------------------------------------------%3A%0ABOOKMARK%3A%20nav%2Ffoo.tt%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20%3Ca%20href%3D%22%2Ffoo%22%3EFoo%20Nav%3C%2Fa%3E%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_nav, 200, 'posted nested nav bookmark route ok');
ok( -f File::Spec->catfile( $paths->dashboards_root, 'nav', 'foo.tt' ), 'root editor saves nested nav bookmark instructions under nav/' );
my ($code1d_nav_page, undef, $body1d_nav_page) = @{ $app->handle(path => '/app/nav/foo.tt', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_nav_page, 200, 'legacy /app route loads nested nav bookmark ids');
like($body1d_nav_page, qr/Foo Nav/, 'legacy /app nested nav route renders the saved nav bookmark body');
my ($code1d_nav_source, $type1d_nav_source, $body1d_nav_source) = @{ $app->handle(path => '/app/nav/foo.tt/source', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_nav_source, 200, 'nested nav bookmark source route ok');
like($type1d_nav_source, qr/text\/plain/, 'nested nav bookmark source route returns plain text');
like($body1d_nav_source, qr/^BOOKMARK:\s+nav\/foo.tt$/m, 'nested nav bookmark source route preserves nested bookmark id');
open my $raw_nav_fh, '>', File::Spec->catfile( $paths->dashboards_root, 'nav', 'here.tt' ) or die $!;
print {$raw_nav_fh} <<'TT';
[% index = '/app/index' %]
[% foo = '/app/foobar' %]
<a href=[% index %]>[% index %]</a>
TT
close $raw_nav_fh;
my ($code1d_raw_nav_page, undef, $body1d_raw_nav_page) = @{ $app->handle(path => '/app/nav/here.tt', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_raw_nav_page, 200, 'legacy /app route loads raw nav tt fragment ids');
like($body1d_raw_nav_page, qr{<a href=/app/index>/app/index</a>}s, 'legacy /app nested nav route renders raw nav tt fragment files through Template Toolkit');
my ($code1d_raw_nav_source, $type1d_raw_nav_source, $body1d_raw_nav_source) = @{ $app->handle(path => '/app/nav/here.tt/source', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_raw_nav_source, 200, 'raw nav tt source route ok');
like($type1d_raw_nav_source, qr/text\/plain/, 'raw nav tt source route returns plain text');
like($body1d_raw_nav_source, qr/\[% index = '\/app\/index' %\]/, 'raw nav tt source route preserves the original raw nav tt source');
my ($code1d_saved_with_raw_nav, undef, $body1d_saved_with_raw_nav) = @{ $app->handle(path => '/app/index', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_saved_with_raw_nav, 200, 'legacy /app/index route still responds after adding a raw nav tt fragment');
like($body1d_saved_with_raw_nav, qr{<li data-nav-id="nav/here\.tt">\s*<a href=/app/index>/app/index</a>\s*</li>}s, 'saved page render includes raw nav tt fragment files in the shared nav output');
open my $broken_raw_nav_fh, '>', File::Spec->catfile( $paths->dashboards_root, 'nav', 'here.tt' ) or die $!;
print {$broken_raw_nav_fh} <<'TT';
[% index = '/app/index' %]
<a href="[% IF index %]">[% index %]</a>
TT
close $broken_raw_nav_fh;
my ($code1d_broken_raw_nav_page, undef, $body1d_broken_raw_nav_page) = @{ $app->handle(path => '/app/nav/here.tt', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_broken_raw_nav_page, 200, 'legacy /app route still responds for a raw nav tt fragment with a syntax error');
like($body1d_broken_raw_nav_page, qr/runtime-error/, 'legacy /app raw nav tt route exposes a runtime error for TT syntax failures');
unlike($body1d_broken_raw_nav_page, qr/\[%\s*IF\s+index\s*%\]|\[%\s*index\s*%\]/, 'legacy /app raw nav tt route does not leak raw TT source when Template Toolkit parsing fails');
my ($code1d_saved_with_broken_raw_nav, undef, $body1d_saved_with_broken_raw_nav) = @{ $app->handle(path => '/app/index', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_saved_with_broken_raw_nav, 200, 'legacy /app/index route still responds after a raw nav tt fragment gains a syntax error');
like($body1d_saved_with_broken_raw_nav, qr/runtime-error/, 'saved page render surfaces nav TT syntax failures as runtime errors');
unlike($body1d_saved_with_broken_raw_nav, qr/\[%\s*IF\s+index\s*%\]|\[%\s*index\s*%\]/, 'saved page render does not leak raw nav TT source when Template Toolkit parsing fails');

my ($code1d_tt, undef, $body1d_tt) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Sample%20Dashboard%0A%3A--------------------------------------------------------------------------------%3A%0ABOOKMARK%3A%20index%0A%3A--------------------------------------------------------------------------------%3A%0ASTASH%3A%20foo%20%3D%3E%201%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20%3Ch1%3E%5B%25%20title%20%25%5D%3C%2Fh1%3E%20%5B%25%20stash.foo%20%25%5D%0A%0AHello%20World%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt, 200, 'posted TT bookmark instruction route ok');
like($body1d_tt, qr/\[% title %\]/, 'editor preserves TT placeholders in the posted source view');
like($body1d_tt, qr/HTML:\s*&lt;h1&gt;\[% title %\]&lt;\/h1&gt;/s, 'editor textarea keeps TT placeholders inside HTML sections');
like($body1d_tt, qr/ddEditor\.value = "[^"]*\[% title %\][^"]*"\s*;\s*ddRenderEditor/s, 'editor boot script keeps TT placeholders in the browser-loaded instruction text');
like($body1d_tt, qr/instruction-highlight[\s\S]*?<span class="tok-directive">HTML:<\/span>\s*<span class="tok-tag">&lt;h1<\/span><span class="tok-tag">&gt;<\/span><span class="tok-note">\[% title %\]<\/span>/s, 'editor syntax highlight is built from highlighted bookmark source');
my ($code1d_tt_source, $type1d_tt_source, $body1d_tt_source) = @{ $app->handle(
    path        => '/app/index/source',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt_source, 200, 'saved TT bookmark source route ok');
like($type1d_tt_source, qr/text\/plain/, 'saved TT bookmark source route returns plain text');
like($body1d_tt_source, qr/^HTML:\s+<h1>\[% title %\]<\/h1> \[% stash\.foo %\]$/m, 'saved TT bookmark source route preserves raw TT placeholders');
my ($play_url_tt) = $body1d_tt =~ m{<a href="([^"]+)" id="play-url">Play</a>};
ok($play_url_tt, 'TT bookmark play url extracted');
is($play_url_tt, '/app/index', 'saved TT bookmark play url stays on the named saved route');
my ($code1d_tt_render, undef, $body1d_tt_render) = @{ $app->handle(
    path        => '/app/index',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt_render, 200, 'TT bookmark play route ok');
like($body1d_tt_render, qr{<h1>\s*Sample Dashboard\s*</h1>\s*1}s, 'TT render receives TITLE and STASH values');
my ($tt_view_source_url) = $body1d_tt_render =~ m{<a href="([^"]+)" id="view-source-url">View Source</a>};
is($tt_view_source_url, '/app/index/edit', 'TT render exposes a saved bookmark view source link');
my $broken_tt_instruction = <<'PAGE';
TITLE: Broken TT Bookmark
:--------------------------------------------------------------------------------:
BOOKMARK: broken-tt
:--------------------------------------------------------------------------------:
HTML: <div>before [% IF stash.foo %] broken</div>
PAGE
$store->save_page( Developer::Dashboard::PageDocument->from_instruction($broken_tt_instruction) );
my ($code1d_broken_tt_render, undef, $body1d_broken_tt_render) = @{ $app->handle(
    path        => '/app/broken-tt',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_broken_tt_render, 200, 'TT bookmark render route still responds when Template Toolkit parsing fails');
like($body1d_broken_tt_render, qr/runtime-error/, 'TT bookmark render route surfaces the Template Toolkit syntax error');
unlike($body1d_broken_tt_render, qr/\[%\s*IF\s+stash\.foo\s*%\]/, 'TT bookmark render route does not leak raw TT syntax when Template Toolkit parsing fails');
my ($code1d_tt_view_source, $type1d_tt_view_source, $body1d_tt_view_source) = @{ $app->handle(
    path        => '/app/index/edit',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt_view_source, 200, 'transient TT view source route ok');
like($type1d_tt_view_source, qr/text\/html/, 'transient TT view source route returns the browser editor HTML');
like($body1d_tt_view_source, qr{<textarea[^>]*>[\s\S]*HTML:\s+&lt;h1&gt;\[% title %\]&lt;/h1&gt; \[% stash\.foo %\][\s\S]*</textarea>}m, 'transient TT view source editor keeps raw TT placeholders after render');
unlike($body1d_tt_view_source, qr{<textarea[^>]*>[\s\S]*HTML:\s+&lt;h1&gt;Sample Dashboard&lt;/h1&gt; 1[\s\S]*</textarea>}m, 'transient TT view source editor does not bake rendered values into source');
my $prefixed_page = Developer::Dashboard::PageDocument->new(
    id     => '/app/index',
    title  => 'Prefixed Route',
    layout => { body => '<div>prefixed route body</div>' },
    meta   => {
        source_kind     => 'saved',
        request_context => { path => '/app/index', remote_addr => '127.0.0.1', host => '127.0.0.1' },
    },
);
my $prefixed_render = $app->_render_page_html( $prefixed_page, 'render' );
like( $prefixed_render, qr{href="/app/index/edit" id="view-source-url"}, 'saved route rendering normalizes bookmark ids that already include /app/ when building the view-source link' );
unlike( $prefixed_render, qr{/app//app/index/edit}, 'saved route rendering does not duplicate the /app prefix in edit links' );

my $highlight_source = join "\n",
    'TITLE: Highlight Demo',
    ':--------------------------------------------------------------------------------:',
    q{HTML: <style>body { color: red; }</style><script>const run = 1;</script><div style="color:red" onclick="run()">[% stash.name %]</div>},
    ':--------------------------------------------------------------------------------:',
    q{CODE1: my $name = 'Michael'; print $name;},
    '';
my ($code1e, undef, $body1e) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=' . uri_escape($highlight_source),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1e, 200, 'highlight demo route ok');
like($body1e, qr/wrap="off"/, 'editor textarea disables soft wrapping so long bookmark lines keep exact geometry');
like($body1e, qr/white-space:\s*pre;/, 'editor stack keeps preformatted line geometry instead of wrapping overlay lines differently from the textarea');
like($body1e, qr/class="editor-overlay-viewport"/, 'editor route renders a clipped overlay viewport above the textarea');
like($body1e, qr/function ddSyncEditorOverlay\(\)/, 'editor route exposes a dedicated overlay sync helper');
like($body1e, qr/ddHighlight\.style\.transform = 'translate\('/, 'editor route syncs overlay position through transforms instead of a second scrollbox');
my ($demo_overlay) = $body1e =~ m{<pre class="editor-overlay" id="instruction-highlight">(.*?)</pre>}s;
like($demo_overlay, qr/<span class="tok-directive">HTML:<\/span>/, 'editor overlay highlights bookmark directives');
like($demo_overlay, qr/<span class="tok-tag">&lt;style<\/span>/, 'editor overlay highlights HTML tag names');
like($demo_overlay, qr/<span class="tok-js">const<\/span> run = 1;/, 'editor overlay highlights JavaScript keywords');
like($demo_overlay, qr/<span class="tok-note">\[% stash\.name %\]<\/span>/, 'editor overlay highlights TT placeholders inside HTML sections');

my $broken_editor_source = <<'BOOKMARK';
BOOKMARK: test
:--------------------------------------------------------------------------------:
HTML: <script src="/js/jquery.js"></script>
<script>var foo = {};
$(document).ready(function () {
    let lastLength = 0;

    $.ajax({
        url: foo.bar,
        type: 'GET',
        dataType: 'text',
        cache: false,

        xhr: function () {
            const xhr = new window.XMLHttpRequest();

            xhr.onprogress = function () {
                const response = xhr.responseText;

                // Replace whole content with everything received so far
                $('.display').text(response);

                // If you want only the new chunk instead, use this:
                // const newChunk = response.substring(lastLength);
                // $('.display').append(newChunk);
                // lastLength = response.length;
            };

            return xhr;
        },

        success: function (response) {
            $('.display').text(response);
        },

        error: function (xhr, status, error) {
            console.error('Stream error:', status, error);
        }
    });
});
</script>
TEST2: <span class=display></span>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'foo.bar', file => 'foobar', code => q{
while (1) {
  print 123;
  sleep 1;
}
};
~
BOOKMARK
my ( $broken_editor_code, undef, $broken_editor_body ) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=' . uri_escape($broken_editor_source),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $broken_editor_code, 200, 'exact bookmark editor repro route ok' );
like( $broken_editor_body, qr/Stream error:/, 'exact bookmark editor repro keeps the original bookmark text visible in the editor route' );
my ($broken_editor_overlay) = $broken_editor_body =~ m{<pre class="editor-overlay" id="instruction-highlight">(.*?)</pre>}s;
like( $broken_editor_overlay, qr/<span class="tok-js">let<\/span> lastLength = 0;/, 'exact bookmark editor repro keeps the JavaScript source text visible in the editor overlay' );
like( $broken_editor_overlay, qr/<span class="tok-string">'Stream error:'<\/span>/, 'exact bookmark editor repro highlights JavaScript string text in the overlay' );
like( $broken_editor_overlay, qr/<span class="tok-string">'GET'<\/span>/, 'exact bookmark editor repro highlights JavaScript string literals without leaking markup text' );
unlike( $broken_editor_overlay, qr/class=&quot;tok-string&quot;&gt;GET/, 'exact bookmark editor repro no longer leaks span attribute text into the visible editor overlay' );
unlike( $broken_editor_overlay, qr/\x1EHL\d+\x1E/, 'exact bookmark editor repro does not leak placeholder markers into the overlay output' );

my ($code2, $type2, $body2) = @{ $app->handle(path => '/app/welcome', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code2, 200, 'saved page route ok');
like($body2, qr/Welcome/, 'saved page rendered');
unlike($body2, qr{<h1>\s*Welcome\s*</h1>}, 'page title is not injected into the page body');
like($body2, qr{<title>Welcome</title>}, 'page title is still rendered in the head title element');
unlike($body2, qr/id="logout-url"/, 'admin route does not render logout link');

my ($code2b, undef, $body2b) = @{ $app->handle(path => '/app/welcome', query => 'name=Michael', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code2b, 200, 'saved page with query state route ok');
like($body2b, qr/Michael/, 'query parameters are merged into page state during render');
like($body2b, qr{<li data-nav-id="nav/alpha\.tt"><a href="/app/index">Home</a></li>}s, 'shared nav TT fragments render conditional output against non-index pages');
like($body2b, qr/nav-current=\/app\/welcome nav-rt=\/app\/welcome/s, 'shared nav TT fragments receive the current page path on non-index pages');
like($body2b, qr/\.dashboard-nav-items ul \{\s*list-style: none;\s*margin: 0;\s*padding: 0;\s*display: flex;\s*flex-wrap: wrap;/s, 'shared nav renderer styles nav items as a wrapping horizontal row');
like($body2b, qr/\.dashboard-nav-items \{\s*margin: 0 0 24px;\s*padding: 14px 18px;\s*border: 1px solid var\(--line\);\s*background: var\(--panel/s, 'shared nav container inherits panel styling through CSS variables instead of a hardcoded pale background');
like($body2b, qr/\.dashboard-nav-items a \{\s*color: var\(--text, var\(--ink\)\);\s*text-decoration-color: var\(--accent, currentColor\);\s*\}/s, 'shared nav links inherit theme-aware foreground colors');
my $nav_pos = index($body2b, 'class="dashboard-nav-items"');
my $body_pos = index($body2b, '<section class="body">');
my $alpha_pos = index($body2b, 'data-nav-id="nav/alpha.tt"');
my $beta_pos = index($body2b, 'data-nav-id="nav/beta.tt"');
ok($nav_pos > -1 && $nav_pos < $body_pos, 'shared nav section renders before the main page body');
ok($alpha_pos > -1 && $beta_pos > $alpha_pos, 'shared nav tt bookmarks render in sorted filename order');
unlike($body2b, qr/display:flex;flex-direction:column/, 'shared nav markup no longer hardcodes a vertical inline flex layout');
unlike($body2, qr/id="play-url"/, 'render mode does not render play link');
like($body2, qr{href="/app/welcome/edit"[^>]+id="view-source-url"}, 'render mode view source points to edit route');

my $token = $saved_token;
my ($code3, $type3, $body3) = @{ $app->handle(path => '/', query => "mode=source&token=$token", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code3, 200, 'transient source route ok');
like($type3, qr/text\/plain/, 'source mode returns plain text instructions');
like($body3, qr/^TITLE:\s+Welcome/m, 'source mode returns canonical legacy instruction page');

my ($code4, $type4, $body4) = @{ $app->handle(path => '/app/legacy-welcome', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code4, 200, 'legacy saved page route ok');
like($body4, qr/Hello World/, 'legacy placeholders render from stash state');
like($body4, qr/Runtime/, 'trusted legacy code output is rendered on saved pages');
like($body4, qr/Right Click Copy &amp; Share or Bookmark This Page/, 'legacy render includes top chrome share link');
unlike($body4, qr/\{legacy-welcome:[^}]+\}/, 'top chrome does not dump shell prompt project context');
unlike($body4, qr/\[\w{3}\s+\w{3}/, 'top chrome does not dump shell prompt timestamps');
like($body4, qr/id="status-on-top"/, 'legacy render includes old top-status container');
like($body4, qr/class="user-name-and-icon"/, 'legacy render includes top-right user marker');
like($body4, qr/id="status-server"/, 'legacy render includes top-right server marker');
like($body4, qr/10\.20\.30\.40/, 'legacy render includes machine ip instead of request host');
like($body4, qr/id="status-datetime"/, 'legacy render includes live-updated date-time marker');

my ($status_code, $status_type, $status_body) = @{ $app->handle(path => '/system/status', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($status_code, 200, 'legacy status endpoint route ok');
like($status_type, qr/application\/json/, 'legacy status endpoint returns json');
like($status_body, qr/"array"\s*:/, 'legacy status endpoint returns array payload');
$config->save_global(
    {
        collectors => [
            {
                name      => 'vpn',
                code      => 'return 0;',
                cwd       => 'home',
                indicator => {
                    icon => '🔑',
                },
            },
        ],
    }
);
my ($status_icon_code, undef, $status_icon_body) = @{ $app->handle(path => '/system/status', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($status_icon_code, 200, 'legacy status endpoint still responds after syncing config-backed collector indicators');
like(decode('UTF-8', $status_icon_body), qr/"alias"\s*:\s*"🔑"/, 'legacy status endpoint exposes configured collector indicator icons instead of collector names');
like($app->_prompt_summary, qr/🔑/, 'page top-right prompt summary prefers the configured collector indicator icon');
$config->save_global_web_settings( no_editor => 1 );
my ($readonly_render_code, undef, $readonly_render_body) = @{ $app->handle(path => '/app/welcome', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($readonly_render_code, 200, 'no-editor mode still renders saved pages');
unlike($readonly_render_body, qr/id="share-url"/, 'no-editor mode hides the share link from render views');
unlike($readonly_render_body, qr/id="view-source-url"/, 'no-editor mode hides the view-source link from render views');
unlike($readonly_render_body, qr/id="play-url"/, 'no-editor mode hides the play link from render views');
my ($readonly_source_code, $readonly_source_type, $readonly_source_body) = @{ $app->handle(path => '/app/welcome/source', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($readonly_source_code, 403, 'no-editor mode blocks saved page source routes');
like($readonly_source_type, qr/text\/plain/, 'no-editor blocked source route returns plain text');
like($readonly_source_body, qr/read-only|no-editor/i, 'no-editor blocked source route explains the read-only restriction');
my ($readonly_edit_code, $readonly_edit_type, $readonly_edit_body) = @{ $app->handle(path => '/app/welcome/edit', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($readonly_edit_code, 403, 'no-editor mode blocks saved page editor routes');
like($readonly_edit_type, qr/text\/plain/, 'no-editor blocked editor route returns plain text');
like($readonly_edit_body, qr/read-only|no-editor/i, 'no-editor blocked editor route explains the read-only restriction');
my $readonly_post_instruction = uri_escape("TITLE: Changed\n:--------------------------------------------------------------------------------:\nBOOKMARK: welcome\n:--------------------------------------------------------------------------------:\nHTML: changed\n");
my ($readonly_post_code, $readonly_post_type, $readonly_post_body) = @{ $app->handle(
    path        => '/app/welcome/edit',
    method      => 'POST',
    body        => 'instruction=' . $readonly_post_instruction,
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($readonly_post_code, 403, 'no-editor mode blocks saved page editor POST saves');
like($readonly_post_type, qr/text\/plain/, 'no-editor blocked editor POST returns plain text');
like($readonly_post_body, qr/read-only|no-editor/i, 'no-editor blocked editor POST explains the read-only restriction');
my $welcome_after_block = $store->load_saved_page('welcome');
is($welcome_after_block->as_hash->{layout}{body}, 'hello from app [% stash.name %]', 'no-editor mode leaves the saved bookmark unchanged after a blocked POST');
my ($readonly_root_code, $readonly_root_type, $readonly_root_body, $readonly_root_headers) = @{ $app->handle(path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($readonly_root_code, 302, 'no-editor mode still lets the root route redirect to a saved index page');
like($readonly_root_type, qr/text\/plain/, 'no-editor root redirect still returns the standard plain-text redirect body');
is($readonly_root_headers->{Location}, '/app/index', 'no-editor root redirect still targets the saved index page');
$config->save_global_web_settings( no_editor => 0 );
$config->save_global_web_settings( no_indicators => 1 );
my ($noind_render_code, undef, $noind_render_body) = @{ $app->handle(path => '/app/welcome', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($noind_render_code, 200, 'no-indicators mode still renders saved pages');
unlike($noind_render_body, qr/id="status-on-top"/, 'no-indicators mode hides the top-right indicator strip');
unlike($noind_render_body, qr/id="status-datetime"/, 'no-indicators mode hides the top-right date-time marker');
unlike($noind_render_body, qr/id="status-server"/, 'no-indicators mode hides the top-right server marker');
unlike($noind_render_body, qr/class="user-name-and-icon"/, 'no-indicators mode hides the top-right username marker');
like($app->_prompt_summary, qr/🔑/, 'no-indicators mode does not change prompt-summary data generation');
my ($noind_status_code, undef, $noind_status_body) = @{ $app->handle(path => '/system/status', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($noind_status_code, 200, 'no-indicators mode keeps the status endpoint available');
like(decode('UTF-8', $noind_status_body), qr/"alias"\s*:\s*"🔑"/, 'no-indicators mode keeps status endpoint indicator payloads intact');
$config->save_global_web_settings( no_indicators => 0 );
$config->save_global(
    {
        collectors => [
            {
                name      => 'vpn-renamed',
                code      => 'return 0;',
                cwd       => 'home',
                indicator => {
                    icon => '🔑',
                },
            },
        ],
    }
);
my ($status_rename_code, undef, $status_rename_body) = @{ $app->handle(path => '/system/status', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($status_rename_code, 200, 'legacy status endpoint still responds after a collector rename');
unlike($status_rename_body, qr/"prog"\s*:\s*"vpn"/, 'legacy status endpoint removes stale managed collector indicators after a collector rename');
like($status_rename_body, qr/"prog"\s*:\s*"vpn-renamed"/, 'legacy status endpoint keeps the renamed collector indicator');

my $legacy_token = $store->encode_page($legacy_page);
my ($code5, undef, $body5) = @{ $app->handle(path => '/', query => "mode=render&token=$legacy_token", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code5, 200, 'legacy transient page route ok');
like($body5, qr/<div>Runtime<\/div>/, 'legacy transient pages execute CODE blocks through the same runtime');

my ($code5b, undef, $body5b) = @{ $app->handle(path => '/app/legacy-welcome', query => 'name=Michael', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code5b, 200, 'legacy /app route with query params ok');
like($body5b, qr/Hello Michael/, 'legacy /app bookmark merges request params into stash');

my $legacy_ajax_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Legacy Ajax
:--------------------------------------------------------------------------------:
BOOKMARK: legacy-ajax
:--------------------------------------------------------------------------------:
HTML: <script>var configs = {};</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'configs.demo.endpoint', type => 'json', code => q{
  print j { ok => 1 };
}, file => 'demo.json';
PAGE
$store->save_page($legacy_ajax_page);

my ($code6, undef, $body6) = @{ $app->handle(path => '/app/legacy-ajax', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code6, 200, 'legacy /app route renders bookmark');
like($body6, qr/set_chain_value\(configs,'demo\.endpoint','\/ajax\/demo\.json\?type=json/, 'legacy Ajax helper injects a saved bookmark ajax endpoint when a file is supplied');
ok( -f File::Spec->catfile( $paths->dashboards_root, 'ajax', 'demo.json' ), 'legacy Ajax helper stores the saved bookmark ajax code under the dashboards ajax tree' );

my ($code7, $type7, $body7) = @{ $app->handle(path => '/ajax/demo.json', query => "type=json", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code7, 200, 'legacy ajax endpoint executes through the saved bookmark ajax file route');
like($type7, qr/application\/json/, 'legacy ajax endpoint returns json type');
like(drain_stream_body($body7), qr/"ok"\s*:\s*1/, 'legacy ajax endpoint returns encoded payload output as a stream');

my $existing_ajax_dir = File::Spec->catdir( $paths->dashboards_root, 'ajax' );
make_path($existing_ajax_dir);
my $existing_ajax_file = File::Spec->catfile( $existing_ajax_dir, 'existing.sh' );
open my $existing_ajax_fh, '>', $existing_ajax_file or die $!;
print {$existing_ajax_fh} "#!/bin/sh\nprintf 'existing-out\\n'\nprintf 'existing-err\\n' >&2\n";
close $existing_ajax_fh;
chmod 0700, $existing_ajax_file or die $!;

my $legacy_existing_ajax_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
TITLE: Legacy Existing Ajax
:--------------------------------------------------------------------------------:
BOOKMARK: legacy-ajax-existing
:--------------------------------------------------------------------------------:
HTML: <script>var configs = {};</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'configs.demo.endpoint', type => 'text', file => 'existing.sh';
PAGE
$store->save_page($legacy_existing_ajax_page);

my ($code7b, undef, $body7b) = @{ $app->handle(path => '/app/legacy-ajax-existing', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code7b, 200, 'legacy /app route renders bookmark that points at an existing ajax file');
like($body7b, qr/set_chain_value\(configs,'demo\.endpoint','\/ajax\/existing\.sh\?type=text/, 'legacy Ajax helper injects an existing saved bookmark ajax endpoint when only a file is supplied');
my $bootstrap_pos = index( $body7b, 'function set_chain_value' );
my $binding_pos   = index( $body7b, q{set_chain_value(configs,'demo.endpoint','/ajax/existing.sh?type=text'} );
ok( $bootstrap_pos > -1 && $binding_pos > $bootstrap_pos, 'legacy bootstrap is defined before saved Ajax bindings run in render mode' );

my ($code7d, $type7d, $body7d) = @{ $app->handle(path => '/ajax/existing.sh', query => "type=text", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code7d, 200, 'saved bookmark ajax file route executes an existing ajax executable from the dashboards ajax tree');
like($type7d, qr/text\/plain/, 'existing ajax executable returns text type');
my $existing_stream = drain_stream_body($body7d);
like($existing_stream, qr/existing-out/, 'existing ajax executable streams stdout');
like($existing_stream, qr/existing-err/, 'existing ajax executable streams stderr');

my ($jquery_code, $jquery_type, $jquery_body) = @{ $app->handle(path => '/js/jquery.js', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($jquery_code, 200, 'built-in jquery bookmark helper route is available');
like($jquery_type, qr/application\/javascript/, 'built-in jquery bookmark helper route returns javascript');
like($jquery_body, qr/window\.jQuery = \$;/, 'built-in jquery bookmark helper exposes window.jQuery');
like($jquery_body, qr/var method = opts\.method \|\| opts\.type \|\| 'GET';/, 'built-in jquery bookmark helper honors the jQuery method alias used by api-dashboard');
like($jquery_body, qr/xhr\.done = function \(callback\)/, 'built-in jquery bookmark helper exposes jqXHR-style done chaining');
like($jquery_body, qr/xhr\.fail = function \(callback\)/, 'built-in jquery bookmark helper exposes jqXHR-style fail chaining');
like($jquery_body, qr/xhr\.always = function \(callback\)/, 'built-in jquery bookmark helper exposes jqXHR-style always chaining');

my $legacy_jquery_ajax_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
BOOKMARK: test-jquery-ajax
:--------------------------------------------------------------------------------:
HTML: <script src="/js/jquery.js"></script>
<script>var foo = {};
$(document).ready(_ => {
    $.ajax({
        url: foo.bar,
        type: 'GET',
        dataType: 'text',
        success: function (response) {
            $('.display').text(response);
        },
        error: function (xhr, status, error) {
            console.error(error);
        }
    });
});
</script>
TEST2: <span class=disply></span>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'foo.bar', file => 'foobar', code => q{
print 123
};
PAGE
$store->save_page($legacy_jquery_ajax_page);

my ($jquery_page_code, undef, $jquery_page_body) = @{ $app->handle(path => '/app/test-jquery-ajax', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($jquery_page_code, 200, 'legacy jquery ajax bookmark route renders');
like($jquery_page_body, qr{<script src="/js/jquery\.js"></script>}, 'legacy jquery ajax bookmark keeps the jquery helper script tag');
like($jquery_page_body, qr{set_chain_value\(foo,'bar','/ajax/foobar\?type=text'\)}, 'legacy jquery ajax bookmark binds foo.bar to the saved ajax endpoint with default text type');
my ($jquery_ajax_code, $jquery_ajax_type, $jquery_ajax_body) = @{ $app->handle(path => '/ajax/foobar', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($jquery_ajax_code, 200, 'legacy jquery ajax bookmark saved endpoint is executable');
like($jquery_ajax_type, qr/text\/plain/, 'legacy jquery ajax bookmark saved endpoint defaults to text content type when no type is supplied');
is(drain_stream_body($jquery_ajax_body), '123', 'legacy jquery ajax bookmark saved endpoint returns the code output');

my $fetch_stream_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
BOOKMARK: fetch-stream-helpers
:--------------------------------------------------------------------------------:
HTML: <script src="/js/jquery.js"></script>
<span id="foo"></span><br>
<div id="bar"></div>
<span id="mike"></span><br>
<script>
var endpoints = {};
$(document).ready(function () {
  fetch_value(endpoints.foo, '#foo');
  stream_value(endpoints.bar, '#bar', { type: 'text' });
  fetch_value(endpoints.mike, '#mike', { type: 'json' }, function (value) {
    return value.ok > 0 ? 'OK' : 'Error';
  });
});
</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'endpoints.foo', file => 'foo', code => q{
  print "This is foo echo";
};
:--------------------------------------------------------------------------------:
CODE2: Ajax jvar => 'endpoints.bar', file => 'bar', singleton => 'BAR', code => q{
  print "bar-one\n";
  print "bar-two\n";
};
:--------------------------------------------------------------------------------:
CODE3: Ajax jvar => 'endpoints.mike', file => 'mike', type => 'json', code => q{
  use Developer::Dashboard::DataHelper qw( j );
  print j { ok => 1 };
};
PAGE
$store->save_page($fetch_stream_page);
my ($fetch_stream_code, undef, $fetch_stream_body) = @{ $app->handle(path => '/app/fetch-stream-helpers', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($fetch_stream_code, 200, 'legacy bookmark with fetch_value and stream_value helpers renders');
like($fetch_stream_body, qr/function fetch_value\(url, target, options, formatter\)/, 'legacy bookmark bootstrap exposes fetch_value helper');
like($fetch_stream_body, qr/function stream_value\(url, target, options, formatter\)/, 'legacy bookmark bootstrap exposes stream_value helper');
like($fetch_stream_body, qr/function stream_data\(url, target, options, formatter\)/, 'legacy bookmark bootstrap exposes stream_data helper');
like($fetch_stream_body, qr/new XMLHttpRequest\(\)/, 'legacy bookmark streaming helper uses XMLHttpRequest for progressive browser updates');
like($fetch_stream_body, qr/xhr\.onprogress = function \(\)/, 'legacy bookmark streaming helper updates targets from incremental ajax progress events');
my $foo_bind_pos = index($fetch_stream_body, q{set_chain_value(endpoints,'foo','/ajax/foo?type=text'});
my $bar_bind_pos = index($fetch_stream_body, q{set_chain_value(endpoints,'bar','/ajax/bar?type=text&singleton=BAR'});
my $mike_bind_pos = index($fetch_stream_body, q{set_chain_value(endpoints,'mike','/ajax/mike?type=json'});
my $endpoints_decl_pos = index($fetch_stream_body, q{var endpoints = {};});
my $fetch_call_pos = index($fetch_stream_body, q{fetch_value(endpoints.foo, '#foo');});
ok($foo_bind_pos > -1 && $bar_bind_pos > -1 && $mike_bind_pos > -1, 'legacy bookmark render includes all saved Ajax endpoint bindings for fetch_value and stream_value');
ok($endpoints_decl_pos > -1, 'legacy bookmark render keeps the caller endpoint variable declaration');
ok($foo_bind_pos > $endpoints_decl_pos && $bar_bind_pos > $endpoints_decl_pos && $mike_bind_pos > $endpoints_decl_pos, 'saved Ajax endpoint bindings render after the caller declares the endpoint root object');
ok($fetch_call_pos > -1, 'legacy bookmark render keeps the inline fetch helper call');
like($fetch_stream_body, qr/dashboard_ajax_singleton_cleanup\('BAR'\)/, 'legacy bookmark render keeps singleton cleanup bindings for stream_value pages');

my $stream_data_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
BOOKMARK: stream-data-helper
:--------------------------------------------------------------------------------:
HTML: <script src="/js/jquery.js"></script>
<script>var foo = {};
$(document).ready(function () {
  stream_data(foo.bar, '.display');
});
</script>
TEST2: <span class=display></span>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'foo.bar', singleton => 'FOOBAR', file => 'foobar', code => q{
    while (1) {
      print 123;
      sleep 1;
    }
};
PAGE
$store->save_page($stream_data_page);
my ($stream_data_code, undef, $stream_data_body) = @{ $app->handle(path => '/app/stream-data-helper', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($stream_data_code, 200, 'legacy bookmark with stream_data helper renders');
like($stream_data_body, qr{stream_data\(foo\.bar, '\.display'\);}, 'legacy bookmark render keeps the inline stream_data helper call');
like($stream_data_body, qr{set_chain_value\(foo,'bar','/ajax/foobar\?type=text&singleton=FOOBAR'\)}, 'legacy bookmark render binds stream_data ajax endpoint before browser execution');

{
    open my $fh, '>', $store->page_file('legacy-forward') or die $!;
    print {$fh} '/ajax/demo.json?type=text';
    close $fh;
}
my ($code8, $type8, $body8) = @{ $app->handle(path => '/app/legacy-forward', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code8, 200, 'legacy /app saved-url forwarding works');
like($type8, qr/text\/plain/, 'forwarded saved-url bookmark preserves content type');
like(drain_stream_body($body8), qr/"ok"\s*:\s*1/, 'forwarded saved-url bookmark reaches ajax payload through the stream response');

{
    open my $fh, '>', $store->page_file('legacy-forward-override') or die $!;
    print {$fh} '/ajax/demo.json?type=text&status=default';
    close $fh;
}
my ($code9, undef, $body9) = @{ $app->handle(path => '/app/legacy-forward-override', query => 'status=override', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code9, 200, 'legacy /app saved-url forwarding with override works');
like(drain_stream_body($body9), qr/"ok"\s*:\s*1/, 'forwarded saved-url override still reaches ajax payload through the stream response');

{
    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 0;
    my $manual_ajax_token = uri_escape( encode_payload(q{print j { blocked => 1 };}) );
    my ($blocked_ajax_code, $blocked_ajax_type, $blocked_ajax_body) = @{ $app->handle(path => '/ajax', query => "token=$manual_ajax_token&type=json", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
    is($blocked_ajax_code, 403, 'legacy ajax token route is denied when transient token URLs are disabled');
    like($blocked_ajax_type, qr/text\/plain/, 'legacy ajax token denial returns plain text');
    like($blocked_ajax_body, qr/Transient token URLs are disabled/, 'legacy ajax token denial explains the policy');
}
{
    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
    my $manual_ajax_token = uri_escape( encode_payload(q{die "token ajax died\n";}) );
    my ($manual_ajax_error_code, $manual_ajax_error_type, $manual_ajax_error_body) = @{ $app->handle(path => '/ajax', query => "token=$manual_ajax_token&type=text", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
    is($manual_ajax_error_code, 200, 'legacy ajax token runtime errors still return the streaming response shape');
    like($manual_ajax_error_type, qr/text\/plain/, 'legacy ajax token runtime errors keep the requested content type');
    like(drain_stream_body($manual_ajax_error_body), qr/token ajax died/, 'legacy ajax token runtime errors stream the runtime error text');
}

my $script_breakout_source = join "\n",
    'BOOKMARK: script-breakout',
    ':--------------------------------------------------------------------------------:',
    q{HTML: <script src="/js/jquery.js"></script>},
    q{<script>console.log("hello")</script>},
    ':--------------------------------------------------------------------------------:',
    q{CODE1: print 123;},
    '';
my ($script_breakout_code, undef, $script_breakout_body) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=' . uri_escape($script_breakout_source),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($script_breakout_code, 200, 'editor route handles source containing literal script tags');
like($script_breakout_body, qr{<textarea[^>]*>[\s\S]*&lt;script src="/js/jquery\.js"&gt;&lt;/script&gt;[\s\S]*</textarea>}m, 'editor textarea keeps literal script tags escaped in source view');
like($script_breakout_body, qr/ddEditor\.value = ".*\\u003c\/script\\u003e.*"\s*;\s*ddRenderEditor/s, 'editor boot script escapes closing script tags inside inline JSON assignment');
unlike($script_breakout_body, qr{</html>\s*[\s\S]*ddRenderEditor}m, 'editor boot script text does not leak into the rendered page body');

$auth->add_user( username => 'helper_user', password => 'helper-pass-123' );
my $helper_session = $sessions->create(
    username    => 'helper_user',
    role        => 'helper',
    remote_addr => '10.0.0.2',
);
my $helper_cookie = 'dashboard_session=' . $helper_session->{session_id};

my ($code10, undef, $body10) = @{ $app->handle(
    path        => '/app/welcome',
    query       => '',
    remote_addr => '10.0.0.2',
    headers     => { host => '10.0.0.3:7890', cookie => $helper_cookie },
) };
is($code10, 200, 'helper route with session ok');
like($body10, qr/id="logout-url"/, 'helper route renders logout link');
like($body10, qr/class="user-name-and-icon".*helper_user/s, 'helper route shows helper username in the top chrome');

my ($code11, undef, $body11, $headers11) = @{ $app->handle(
    path        => '/logout',
    query       => '',
    remote_addr => '10.0.0.2',
    headers     => { host => '10.0.0.3:7890', cookie => $helper_cookie },
) };
is($code11, 302, 'helper logout redirects');
like($body11, qr/Redirecting/, 'helper logout returns redirect body');
is($headers11->{Location}, '/login', 'helper logout redirects to login');
like($headers11->{'Set-Cookie'}, qr/dashboard_session=;/, 'helper logout expires session cookie');
ok(!defined $auth->get_user('helper_user'), 'helper logout removes helper account');
ok(!defined $sessions->get($helper_session->{session_id}), 'helper logout removes helper session');

done_testing;

__END__

=head1 NAME

03-web-app.t - basic web application route tests

=head1 DESCRIPTION

This test verifies the local web app home, page, and transient source routes.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the local web application and server-facing routes. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the local web application and server-facing routes has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the local web application and server-facing routes, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/03-web-app.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/03-web-app.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/03-web-app.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
