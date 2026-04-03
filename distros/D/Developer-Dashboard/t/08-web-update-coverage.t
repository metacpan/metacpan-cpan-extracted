use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use Encode qw(decode encode FB_CROAK);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Request::Common qw(GET POST);
use HTTP::Response;
use POSIX qw(:sys_wait_h);
use Plack::Test;
use Test::More;
use URI::Escape qw(uri_escape);

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::UpdateManager;
use Developer::Dashboard::Web::App;
use Developer::Dashboard::Web::DancerApp;
use Developer::Dashboard::Web::Server;

sub dies_like {
    my ( $code, $pattern, $label ) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    like( $error, $pattern, $label );
}

sub drain_stream_body {
    my ($body) = @_;
    return $body if ref($body) ne 'HASH' || ref( $body->{stream} ) ne 'CODE';
    my $output = '';
    $body->{stream}->( sub { $output .= $_[0] if defined $_[0] } );
    return $output;
}

sub decode_body_text {
    my ($body) = @_;
    return $body if !defined $body || utf8::is_utf8($body);
    return decode( 'UTF-8', $body, FB_CROAK );
}

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store = Developer::Dashboard::PageStore->new( paths => $paths );
my $runtime = Developer::Dashboard::PageRuntime->new( paths => $paths );
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
    runtime  => $runtime,
    sessions => $sessions,
);
dies_like( sub { Developer::Dashboard::Web::App->new( pages => $store, sessions => $sessions ) }, qr/Missing auth store/, 'web app requires auth store' );
dies_like( sub { Developer::Dashboard::Web::App->new }, qr/Missing auth store/, 'web app requires auth before other dependencies' );
dies_like( sub { Developer::Dashboard::Web::App->new( auth => $auth, sessions => $sessions ) }, qr/Missing page store/, 'web app requires page store' );
dies_like( sub { Developer::Dashboard::Web::App->new( auth => $auth, pages => $store ) }, qr/Missing session store/, 'web app requires session store' );

my ( $root_code, $root_type, $root_body ) = @{ $app->handle( path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $root_code, 200, 'root route responds with success' );
like( $root_body, qr/<textarea[^>]*name="instruction"/, 'root route renders free-form instruction editor' );

my $index_page = Developer::Dashboard::PageDocument->new(
    id     => 'index',
    title  => 'Index',
    layout => { body => 'index body' },
);
$store->save_page($index_page);
my ( $root_index_code, undef, undef, $root_index_headers ) = @{ $app->handle( path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $root_index_code, 302, 'root route redirects to the saved index page when it exists' );
is( $root_index_headers->{Location}, '/app/index', 'root route redirects to the canonical saved index bookmark path' );
unlink $store->page_file('index') or die "Unable to remove temporary index bookmark: $!";

my ( $apps_code, undef, undef, $apps_headers ) = @{ $app->handle( path => '/apps', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $apps_code, 302, '/apps redirects to default index bookmark' );
is( $apps_headers->{Location}, '/app/index', '/apps uses index bookmark as default target' );

my $token = uri_escape( $store->encode_page($page) );
my ( $blocked_code, $blocked_type, $blocked_body ) = @{ $app->handle( path => '/', query => "token=$token", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $blocked_code, 403, 'transient edit route is denied by default' );
like( $blocked_type, qr/text\/plain/, 'denied transient edit route returns plain text' );
like( $blocked_body, qr/Transient token URLs are disabled/, 'denied transient edit route explains the policy' );

local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;

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

my ( $saved_edit_code, undef, $saved_edit_body ) = @{ $app->handle( path => '/app/sample/edit', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $saved_edit_code, 200, 'saved edit route responds with success' );
like( $saved_edit_body, qr/Right Click Copy &amp; Share or Bookmark This Page/, 'saved edit route includes top chrome links' );
like( $saved_edit_body, qr{<form method="post" action="/app/sample/edit" id="instruction-form">}, 'saved edit route posts back to the named bookmark edit path' );
like( $saved_edit_body, qr{<a href="/app/sample" id="play-url">Play</a>}, 'saved edit route exposes a saved-page play link instead of a transient token url' );
my ( $saved_edit_post_without_instruction_code, undef, $saved_edit_post_without_instruction_body ) = @{ $app->handle(
    path        => '/app/sample/edit',
    method      => 'POST',
    body        => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $saved_edit_post_without_instruction_code, 200, 'saved edit POST without instruction falls back to the saved editor view' );
like( $saved_edit_post_without_instruction_body, qr{<form method="post" action="/app/sample/edit" id="instruction-form">}, 'saved edit POST fallback keeps the named bookmark edit form action' );

my $updated_instruction = join "\n",
    'TITLE: Sample',
    ':--------------------------------------------------------------------------------:',
    'BOOKMARK: sample',
    ':--------------------------------------------------------------------------------:',
    'HTML: updated saved bookmark body',
    '';
my ( $saved_update_code, undef, $saved_update_body ) = @{ $app->handle(
    path        => '/app/sample/edit',
    method      => 'POST',
    body        => 'instruction=' . uri_escape($updated_instruction),
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $saved_update_code, 200, 'saved edit post route responds with success while transient urls remain disabled' );
like( $saved_update_body, qr/updated saved bookmark body/, 'saved edit post route returns the updated bookmark editor content' );
my ( $saved_updated_source_code, undef, $saved_updated_source_body ) = @{ $app->handle( path => '/app/sample/source', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $saved_updated_source_code, 200, 'saved source route still responds after a saved edit post' );
like( $saved_updated_source_body, qr/^HTML:\s+updated saved bookmark body$/m, 'saved edit post route persists the updated bookmark source text' );

my ( $saved_source_code, undef, $saved_source_body ) = @{ $app->handle( path => '/app/sample/source', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $saved_source_code, 200, 'saved source route responds with success' );
like( $saved_source_body, qr/^BOOKMARK:\s+sample/m, 'saved source route returns canonical page instruction source' );
unlike( $saved_source_body, qr/request_host|request_path|request_remote_addr/, 'saved source route does not inject request metadata into source' );

my ( $saved_render_code, undef, $saved_render_body ) = @{ $app->handle( path => '/app/sample', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $saved_render_code, 200, 'saved render route responds with success' );
like( $saved_render_body, qr/updated saved bookmark body/, 'saved page route renders the latest saved bookmark body content' );

{
    my $broken_path = File::Spec->catfile( $paths->dashboards_root, 'broken-icons' );
    open my $broken_fh, '>:raw', $broken_path or die "Unable to write $broken_path: $!";
    print {$broken_fh} "TITLE: Broken Icons\n";
    print {$broken_fh} ":--------------------------------------------------------------------------------:\n";
    print {$broken_fh} "BOOKMARK: broken-icons\n";
    print {$broken_fh} ":--------------------------------------------------------------------------------:\n";
    print {$broken_fh} "HTML: <h2>";
    print {$broken_fh} pack( 'C*', 0xF0, 0x9F, 0x9A );
    print {$broken_fh} " Learning</h2>\n<span class=\"icon\">";
    print {$broken_fh} pack( 'C*', 0x95 );
    print {$broken_fh} "</span>\n<span class=\"icon\">" . encode( 'UTF-8', "\x{1F9D1}" );
    print {$broken_fh} pack( 'C*', 0xEF, 0xBF, 0xBD );
    print {$broken_fh} encode( 'UTF-8', "\x{1F4BB}</span>\n" );
    close $broken_fh or die "Unable to close $broken_path: $!";

    my ( $broken_source_code, undef, $broken_source_body ) = @{ $app->handle( path => '/app/broken-icons/source', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    my $broken_source_text = decode_body_text($broken_source_body);
    is( $broken_source_code, 200, 'saved source route still responds for malformed legacy bookmark bytes' );
    like( $broken_source_text, qr/◈ Learning/, 'saved source route repairs malformed legacy heading icon bytes into a stable fallback glyph' );
    like( $broken_source_text, qr/<span class="icon">🏷️<\/span>/, 'saved source route repairs malformed legacy item icon bytes into a stable fallback glyph' );
    like( $broken_source_text, qr/<span class="icon">🧑‍💻<\/span>/, 'saved source route repairs malformed joined legacy emoji into a browser-safe glyph' );
    unlike( $broken_source_text, qr/\x{FFFD}/, 'saved source route no longer exposes Unicode replacement glyphs for repaired icon markup' );
    unlike( $broken_source_text, qr/^HTML:\s+<h2> Learning<\/h2>$/m, 'saved source route keeps the repaired raw source text instead of replacing it with canonical text that drops the glyph position' );

    my ( $broken_edit_code, undef, $broken_edit_body ) = @{ $app->handle( path => '/app/broken-icons/edit', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    my $broken_edit_text = decode_body_text($broken_edit_body);
    is( $broken_edit_code, 200, 'saved edit route still responds for malformed legacy bookmark bytes' );
    like( $broken_edit_text, qr/◈ Learning/, 'saved edit route embeds repaired heading fallback glyphs into the browser editor source' );
    like( $broken_edit_text, qr/🏷️/, 'saved edit route embeds repaired item fallback glyphs into the browser editor source' );
    like( $broken_edit_text, qr/🧑‍💻/, 'saved edit route embeds repaired joined emoji glyphs into the browser editor source' );
}

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

{
    my $others_root = File::Spec->catdir( $paths->dashboards_root, 'public', 'others' );
    make_path($others_root);
    my $txt = File::Spec->catfile( $others_root, 'note.txt' );
    open my $txt_fh, '>', $txt or die $!;
    print {$txt_fh} "plain text asset\n";
    close $txt_fh;
    my ( $asset_code, $asset_type, $asset_body ) = @{ $app->handle( path => '/others/note.txt', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    is( $asset_code, 200, 'dispatch_request serves static files through the routed handler path' );
    like( $asset_type, qr/text\/plain/, 'txt assets resolve through the plain-text content type branch' );
    is( $asset_body, "plain text asset\n", 'txt assets return the saved file content' );
}

{
    my $fake_bin = File::Spec->catdir( $home, 'fake-bin' );
    make_path($fake_bin);
    my $ifconfig = File::Spec->catfile( $fake_bin, 'ifconfig' );
    open my $ifconfig_fh, '>', $ifconfig or die $!;
    print {$ifconfig_fh} <<'SH';
#!/bin/sh
cat <<'EOF'
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
    inet 10.0.0.4  netmask 255.255.255.0  broadcast 10.0.0.255
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
    inet 127.0.0.1  netmask 255.0.0.0
EOF
SH
    close $ifconfig_fh;
    chmod 0755, $ifconfig or die $!;
    no warnings 'redefine';
    local $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};
    local *Developer::Dashboard::Web::App::_ip_pairs_from_ip = sub { return (); };
    is_deeply(
        [ $app->_ip_interface_pairs ],
        [ { iface => 'eth0', ip => '10.0.0.4' } ],
        '_ip_interface_pairs falls back to ifconfig parsing when the ip command yields no candidates',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_ip_pairs_from_ip = sub { return (); };
    local *Developer::Dashboard::Web::App::_ip_pairs_from_ifconfig = sub { return (); };
    ok( !defined $app->_machine_ip, '_machine_ip returns undef when neither ip nor ifconfig yields a usable address' );
}

my ( $ajax_missing_code, $ajax_missing_type, $ajax_missing_body ) = @{ $app->handle( path => '/ajax', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
is( $ajax_missing_code, 400, 'legacy ajax route rejects requests without token or saved file parameters' );
like( $ajax_missing_type, qr/text\/plain/, 'legacy ajax missing-parameter route returns plain text' );
like( $ajax_missing_body, qr/missing token/, 'legacy ajax missing-parameter route explains the missing token' );

{
    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::decode_payload = sub { die "forced decode failure\n" };
    my ( $ajax_bad_token_code, $ajax_bad_token_type, $ajax_bad_token_body ) = @{ $app->handle( path => '/ajax', query => 'token=known-good-token&type=json', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    is( $ajax_bad_token_code, 400, 'legacy ajax route rejects decode failures cleanly' );
    like( $ajax_bad_token_type, qr/text\/plain/, 'legacy ajax decode-failure route returns plain text' );
    like( $ajax_bad_token_body, qr/forced decode failure/, 'legacy ajax decode-failure route returns the decode error text' );
}

{
    my ( $ajax_bad_file_code, $ajax_bad_file_type, $ajax_bad_file_body ) = @{ $app->handle( path => '/ajax', query => 'file=..%2Fbad&type=json', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    is( $ajax_bad_file_code, 400, 'legacy ajax route rejects invalid saved bookmark ajax file names cleanly' );
    like( $ajax_bad_file_type, qr/text\/plain/, 'legacy ajax invalid saved-file route returns plain text' );
    like( $ajax_bad_file_body, qr/invalid parent traversal/, 'legacy ajax invalid saved-file route returns the validation error text' );
}

{
    my $streaming_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
BOOKMARK: ajax-stream
:--------------------------------------------------------------------------------:
HTML: <script>var configs = {};</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'configs.demo.endpoint', type => 'text', file => 'stream.txt', code => q{
  print "first\n";
  print "second\n";
};
PAGE
    $store->save_page($streaming_page);
    my ( undef, undef, undef ) = @{ $app->handle( path => '/app/ajax-stream', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    my ( $ajax_stream_code, $ajax_stream_type, $ajax_stream_body ) = @{ $app->handle( path => '/ajax/stream.txt', query => 'type=text', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    is( $ajax_stream_code, 200, 'legacy ajax saved-file route responds successfully for streaming output' );
    like( $ajax_stream_type, qr/text\/plain/, 'legacy ajax saved-file route keeps the requested content type for streaming output' );
    is( drain_stream_body($ajax_stream_body), "first\nsecond\n", 'legacy ajax saved-file route streams raw printed output without page buffering' );
}

{
    my $process_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
BOOKMARK: ajax-process
:--------------------------------------------------------------------------------:
HTML: <script>var configs = {};</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'configs.demo.endpoint', type => 'text', file => 'process-endpoint.json', code => q{
print "perl-start\n";
warn "perl-warn\n";
system 'sh', '-c', 'printf "child-out\n"; printf "child-err\n" >&2';
die "perl-die\n";
};
PAGE
    $store->save_page($process_page);
    my ( undef, undef, undef ) = @{ $app->handle( path => '/app/ajax-process', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    my ( $ajax_process_code, $ajax_process_type, $ajax_process_body ) = @{ $app->handle( path => '/ajax/process-endpoint.json', query => 'type=text', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    my $ajax_process_output = drain_stream_body($ajax_process_body);
    is( $ajax_process_code, 200, 'legacy ajax saved-file process route responds successfully for mixed stdout and stderr output' );
    like( $ajax_process_type, qr/text\/plain/, 'legacy ajax saved-file process route keeps the requested content type' );
    like( $ajax_process_output, qr/perl-start/, 'legacy ajax saved-file process route streams direct perl stdout' );
    like( $ajax_process_output, qr/perl-warn/, 'legacy ajax saved-file process route streams perl stderr warnings' );
    like( $ajax_process_output, qr/child-out/, 'legacy ajax saved-file process route streams child process stdout' );
    like( $ajax_process_output, qr/child-err/, 'legacy ajax saved-file process route streams child process stderr' );
    like( $ajax_process_output, qr/perl-die/, 'legacy ajax saved-file process route streams uncaught perl die output' );
}

{
    my $singleton_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
BOOKMARK: ajax-singleton
:--------------------------------------------------------------------------------:
HTML: <script>var configs = {};</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'configs.demo.endpoint', type => 'text', singleton => 'FOOBAR', file => 'singleton-endpoint.txt', code => q{
print "$0\n";
};
PAGE
    $store->save_page($singleton_page);
    my ( undef, undef, $singleton_page_body ) = @{ $app->handle( path => '/app/ajax-singleton', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    like( $singleton_page_body, qr{/ajax/singleton-endpoint\.txt\?type=text&singleton=FOOBAR}, 'saved bookmark Ajax page emits the singleton query parameter in the generated ajax url' );
    like( $singleton_page_body, qr/dashboard_ajax_singleton_cleanup\('FOOBAR'\)/, 'saved bookmark Ajax page registers browser lifecycle cleanup for singleton-managed workers' );
    my ( $ajax_singleton_code, undef, $ajax_singleton_body ) = @{ $app->handle( path => '/ajax/singleton-endpoint.txt', query => 'type=text&singleton=FOOBAR', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    my $ajax_singleton_output = drain_stream_body($ajax_singleton_body);
    is( $ajax_singleton_code, 200, 'legacy ajax saved-file route responds successfully for singleton-managed requests' );
    like( $ajax_singleton_output, qr/^dashboard ajax: FOOBAR$/m, 'legacy ajax saved-file route renames singleton-managed Perl workers before streaming output' );
}

{
    my @patterns;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub {
            my ( $self, $pattern ) = @_;
            push @patterns, $pattern;
            return 1;
        };
        my ( $stop_code, undef, $stop_body ) = @{ $app->handle( path => '/ajax/singleton/stop', query => 'singleton=BROWSER-STOP', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
        is( $stop_code, 204, 'singleton stop route returns no content after lifecycle cleanup' );
        is( $stop_body, '', 'singleton stop route keeps the response body empty' );
    }
    is_deeply( \@patterns, ['^dashboard ajax: BROWSER-STOP$'], 'singleton stop route targets the matching saved ajax worker process title' );
}

{
    my $shebang_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
BOOKMARK: ajax-shebang
:--------------------------------------------------------------------------------:
HTML: <script>var configs = {};</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'configs.demo.endpoint', type => 'text', file => 'script-runner', code => qq{#!/bin/sh\nprintf 'shell-out\\n'\nprintf 'shell-err\\n' >&2\n};
PAGE
    $store->save_page($shebang_page);
    my ( undef, undef, undef ) = @{ $app->handle( path => '/app/ajax-shebang', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    my ( $ajax_shebang_code, undef, $ajax_shebang_body ) = @{ $app->handle( path => '/ajax/script-runner', query => 'type=text', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } ) };
    my $ajax_shebang_output = drain_stream_body($ajax_shebang_body);
    is( $ajax_shebang_code, 200, 'legacy ajax saved-file route executes shebang scripts directly' );
    like( $ajax_shebang_output, qr/shell-out/, 'legacy ajax saved-file route streams direct executable stdout' );
    like( $ajax_shebang_output, qr/shell-err/, 'legacy ajax saved-file route streams direct executable stderr' );
}

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

my ( $saved_login_required_code, undef, $saved_login_required_body ) = @{ $app->handle(
    path        => '/app/index',
    query       => 'from=helper',
    remote_addr => '127.0.0.1',
    headers     => { host => 'localhost:7890' },
) };
is( $saved_login_required_code, 401, 'helper access to a saved page requires login' );
like( $saved_login_required_body, qr{<input[^>]*name="redirect_to"[^>]*value="/app/index\?from=helper"}, 'login page keeps the originally requested path and query for post-login redirect' );

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

my ( $saved_login_code, undef, undef, $saved_login_headers ) = @{ $app->handle(
    path        => '/login',
    method      => 'POST',
    body        => 'username=helper&password=helper-pass-123&redirect_to=%2Fapp%2Findex%3Ffrom%3Dhelper',
    remote_addr => '127.0.0.1',
    headers     => { host => 'localhost:7890' },
) };
is( $saved_login_code, 302, 'valid helper login for a saved page redirects' );
is( $saved_login_headers->{Location}, '/app/index?from=helper', 'valid helper login returns to the originally requested saved page' );

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

my $server = Developer::Dashboard::Web::Server->new(
    app  => $app,
    host => '127.0.0.1',
    port => 0,
);
my $daemon = $server->start_daemon;
is( $daemon->sockhost, '127.0.0.1', 'start_daemon preserves the requested host' );
ok( $daemon->sockport > 0, 'start_daemon resolves a listen port' );
is( $server->listening_url($daemon), 'http://127.0.0.1:' . $daemon->sockport . '/', 'listening_url builds the daemon URL from the descriptor' );

{
    my $res;
    test_psgi $server->psgi_app, sub {
        my ($cb) = @_;
        $res = $cb->( GET 'http://127.0.0.1/app/sample/source' );
    };
    is( $res->code, 200, 'server PSGI app returns successful status code from app handle' );
    like( $res->header('Content-Type'), qr/text\/plain/, 'server PSGI app keeps the instruction source content type' );
    is( $res->header('X-Frame-Options'), 'DENY', 'server PSGI app sets frame-deny header' );
    like( $res->header('Content-Security-Policy'), qr/frame-ancestors 'none'/, 'server PSGI app sets CSP header' );
    is( $res->header('Cache-Control'), 'no-store', 'server PSGI app disables response caching' );
}

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
{
    my $res;
    test_psgi $header_server->psgi_app, sub {
        my ($cb) = @_;
        $res = $cb->( POST 'http://127.0.0.1/login', [ username => 'helper', password => 'helper-pass-123' ] );
    };
    is( $res->header('Location'), '/login', 'server forwards custom Location headers from the app' );
    is( $res->header('Set-Cookie'), 'dashboard_session=abc', 'server forwards custom Set-Cookie headers from the app' );
}

my $streaming_app = bless {}, 'Local::StreamingApp';
{
    no warnings 'once';
    *Local::StreamingApp::handle = sub {
        return [
            200,
            'text/plain; charset=utf-8',
            {
                stream => sub {
                    my ($writer) = @_;
                    $writer->("alpha\n");
                    $writer->("beta\n");
                },
            },
            { 'X-Test' => 'streaming' },
        ];
    };
}
my $streaming_server = Developer::Dashboard::Web::Server->new( app => $streaming_app );
{
    my $res;
    test_psgi $streaming_server->psgi_app, sub {
        my ($cb) = @_;
        $res = $cb->( GET 'http://127.0.0.1/ajax' );
    };
    is( $res->code, 200, 'streaming response path returns success' );
    like( $res->header('Content-Type'), qr/text\/plain/, 'streaming response keeps the content type header' );
    is( $res->header('X-Test'), 'streaming', 'streaming response keeps custom headers' );
    is( $res->content, "alpha\nbeta\n", 'streaming response writes streamed body chunks into the final response body' );
}

my $failing_stream_app = bless {}, 'Local::FailingStreamApp';
{
    no warnings 'once';
    *Local::FailingStreamApp::handle = sub {
        return [
            200,
            'text/plain; charset=utf-8',
            {
                stream => sub {
                    my ($writer) = @_;
                    $writer->("alpha\n");
                    die "stream exploded\n";
                },
            },
        ];
    };
}
my $failing_stream_server = Developer::Dashboard::Web::Server->new( app => $failing_stream_app );
{
    my $res;
    test_psgi $failing_stream_server->psgi_app, sub {
        my ($cb) = @_;
        $res = $cb->( GET 'http://127.0.0.1/ajax' );
    };
    is( $res->code, 200, 'streaming error responses keep the original success status' );
    like( $res->content, qr/alpha/, 'streaming error responses keep chunks written before the failure' );
    like( $res->content, qr/stream exploded/, 'streaming error responses append the streaming exception text' );
}

{
    no warnings 'redefine';
    my @chunks;
    local *Developer::Dashboard::Web::DancerApp::delayed = sub (&) { $_[0]->(); return 'delayed-ok' };
    local $Dancer2::Core::Route::RESPONDER = sub {
        my ($response) = @_;
        is( $response->[0], 200, 'disconnect coverage responder receives the original status code' );
        like( join( "\n", @{ $response->[1] || [] } ), qr/Content-Type\ntext\/plain/, 'disconnect coverage responder receives the content type header' );
        return bless {}, 'Local::DisconnectWriter';
    };
    {
        no warnings 'once';
        *Local::DisconnectWriter::write = sub {
            my ( $self, $chunk ) = @_;
            push @chunks, $chunk;
            die "Broken pipe\n" if @chunks > 1;
            return 1;
        };
        *Local::DisconnectWriter::close = sub { return 1 };
    }
    local $Developer::Dashboard::Web::DancerApp::BACKEND_APP = { app => bless( {}, 'Local::DisconnectBackend' ), default_headers => {} };
    my $result = Developer::Dashboard::Web::DancerApp::_response_from_result(
        [
            200,
            'text/plain; charset=utf-8',
            {
                stream => sub {
                    my ($writer) = @_;
                    is( $writer->("alpha\n"), 1, 'stream writer reports success before the client disconnects' );
                    is( $writer->("beta\n"), 0, 'stream writer reports a disconnect when Dancer content writes fail with broken pipe' );
                },
            },
            {},
        ]
    );
    is( $result, 'delayed-ok', '_response_from_result still completes the delayed wrapper when the client disconnects mid-stream' );
    is_deeply( \@chunks, [ "alpha\n", "beta\n" ], '_response_from_result stops treating broken-pipe writes as fatal backend exceptions' );
}

my $failing_app = bless {}, 'Local::FailingApp';
{
    no warnings 'once';
    *Local::FailingApp::handle = sub { die "exploded\n" };
}
my $failing_server = Developer::Dashboard::Web::Server->new( app => $failing_app );
{
    my $res;
    test_psgi $failing_server->psgi_app, sub {
        my ($cb) = @_;
        $res = $cb->( GET 'http://127.0.0.1/' );
    };
    is( $res->code, 500, 'server converts app exceptions into 500 responses' );
    like( $res->content, qr/exploded/, 'server includes error body for exceptions' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::DancerApp::splat = sub { return ['alpha', 'beta']; };
    is( Developer::Dashboard::Web::DancerApp::_capture(1), 'beta', '_capture unwraps arrayref-style splat payloads from Dancer route state' );
}

my $missing_route_app = bless {}, 'Local::MissingRouteApp';
my $missing_route_server = Developer::Dashboard::Web::Server->new( app => $missing_route_app );
{
    my $res;
    test_psgi $missing_route_server->psgi_app, sub {
        my ($cb) = @_;
        $res = $cb->( POST 'http://127.0.0.1/login', [ username => 'helper', password => 'helper-pass-123' ] );
    };
    is( $res->code, 500, 'server returns a backend failure when the login route backend implements neither login_response nor handle' );
    like( $res->content, qr/does not implement login_response or handle/, 'missing login route backend failures are exposed directly' );
}

{
    my $res;
    test_psgi $missing_route_server->psgi_app, sub {
        my ($cb) = @_;
        $res = $cb->( GET 'http://127.0.0.1/' );
    };
    is( $res->code, 500, 'server returns a backend failure when an authorized route backend implements neither a route method nor handle' );
    like( $res->content, qr/does not implement root_response or handle/, 'missing authorized route backend failures are exposed directly' );
}

{
    my $res = HTTP::Response->from_psgi(
        $server->psgi_app->(
            {
                REQUEST_METHOD    => 'GET',
                PATH_INFO         => '/',
                SCRIPT_NAME       => '',
                SERVER_NAME       => '127.0.0.1',
                SERVER_PORT       => 7890,
                'psgi.version'    => [ 1, 1 ],
                'psgi.url_scheme' => 'http',
                'psgi.input'      => do { open my $fh, '<', \q{} or die $!; $fh },
                'psgi.errors'     => *STDERR,
                'psgi.multithread' => 0,
                'psgi.multiprocess' => 0,
                'psgi.run_once'     => 0,
                'psgi.streaming'    => 1,
                'psgi.nonblocking'  => 0,
            }
        )
    );
    is( $res->code, 200, 'server treats missing URI queries as empty strings' );
}

{
    no warnings 'redefine';
    local *IO::Socket::INET::new = sub { return };
    local $! = 98;
    dies_like( sub { $server->run }, qr/Unable to start server/, 'server dies when daemon startup fails' );
}

{
    package Local::FakeRunner;
    our @parse_options;
    our $run_arg;
    sub new { bless {}, $_[0] }
    sub parse_options { @parse_options = @_[ 1 .. $#_ ]; return 1 }
    sub run { $run_arg = $_[1]; return 1 }
}

{
    no warnings 'redefine';
    local *Plack::Runner::new = sub { return Local::FakeRunner->new };
    my $fake_daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => '127.0.0.1',
        port => 5999,
    );
    ok( $server->serve_daemon($fake_daemon), 'serve_daemon delegates to the Plack runner successfully' );
    is_deeply(
        \@Local::FakeRunner::parse_options,
        [ '--server', 'Starman', '--host', '127.0.0.1', '--port', 5999, '--env', 'deployment', '--workers', '1' ],
        'serve_daemon configures Starman through Plack::Runner',
    );
    ok( ref( $Local::FakeRunner::run_arg ) eq 'CODE', 'serve_daemon hands a PSGI app coderef to the Plack runner' );
}

{
    no warnings 'redefine';
    local *Plack::Runner::new = sub { return Local::FakeRunner->new };
    my $worker_server = Developer::Dashboard::Web::Server->new(
        app     => $app,
        host    => '127.0.0.1',
        port    => 5998,
        workers => 4,
    );
    my $fake_daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => '127.0.0.1',
        port => 5998,
    );
    ok( $worker_server->serve_daemon($fake_daemon), 'serve_daemon accepts an explicit worker count' );
    is_deeply(
        \@Local::FakeRunner::parse_options,
        [ '--server', 'Starman', '--host', '127.0.0.1', '--port', 5998, '--env', 'deployment', '--workers', '4' ],
        'serve_daemon forwards the configured worker count to Starman',
    );
}

{
    no warnings 'redefine';
    my $served;
    local *Developer::Dashboard::Web::Server::start_daemon = sub {
        return Developer::Dashboard::Web::Server::Daemon->new( host => '127.0.0.1', port => 5999 );
    };
    local *Developer::Dashboard::Web::Server::serve_daemon = sub {
        my ( undef, $daemon ) = @_;
        $served = $daemon;
        return 1;
    };
    local *STDOUT;
    open STDOUT, '>', \my $captured or die $!;
    ok( $server->run, 'run returns the serve_daemon result' );
    like( $captured, qr/Developer Dashboard listening on http:\/\/127\.0\.0\.1:5999\//, 'run announces the listening URL' );
    is( $served->sockport, 5999, 'run passes the daemon descriptor through to serve_daemon' );
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
