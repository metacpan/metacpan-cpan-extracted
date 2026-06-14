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
like($body1, qr/class="editor-blocks" id="instruction-blocks"/, 'root route renders a split-block instruction editor container');
like($body1, qr/ddForm\.addEventListener\('focusout', function\(\) \{/s, 'root route auto-submits when focus leaves the whole editor form');
like($body1, qr/function ddApplyDirectiveAssist\(editor\)/, 'root route editor script includes directive assist helper for one editor block');
like($body1, qr/function ddSplitInstruction\(\w+\)/, 'root route editor script can split bookmark source into visible blocks');
like($body1, qr/function ddComposeInstruction\(\)/, 'root route editor script recomposes visible blocks back into the hidden bookmark source');
like($body1, qr/if \(priorDirective === 'TITLE'\) \{\s*if \(!directives\.BOOKMARK\) return 'BOOKMARK: ';\s*return directives\.HTML \? '' : 'HTML: ';/s, 'directive assist offers BOOKMARK before HTML when TITLE is the current block');
like($body1, qr/if \(priorDirective === 'HTML' \|\| \/\^CODE\\d\+\$\/\.test\(priorDirective\)\) \{\s*return 'CODE' \+ \(ddHighestCodeDirective\(fullText\) \+ 1\) \+ ': ';/s, 'directive assist advances CODE directives from HTML and CODE sections');
like($body1, qr/if \(event\.key !== 'Tab' \|\| event\.shiftKey \|\| event\.ctrlKey \|\| event\.altKey \|\| event\.metaKey\) return;/s, 'split editor reserves plain Tab to start a new section block');
like($body1, qr/ddInsertBlockAfter\(wrapper\);/s, 'split editor creates a new block when the user presses Tab inside a section');

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

my ($unknown_edit_code, undef, $unknown_edit_body) = @{ $app->handle(path => '/app/foobar/edit', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($unknown_edit_code, 200, 'unknown saved edit routes open the editor instead of dying in page resolution');
like($unknown_edit_body, qr/<textarea[^>]*name="instruction"/, 'unknown saved edit routes render the bookmark editor');
like($unknown_edit_body, qr/BOOKMARK:\s+\/app\/foobar/, 'unknown saved edit routes prefill the requested bookmark path');
like($unknown_edit_body, qr/HTML:\s*\nBlank page/s, 'unknown saved edit routes prefill the blank page body');

my $prefixed_saved_page = Developer::Dashboard::PageDocument->new(
    id     => '/app/prefixed-save',
    title  => 'Prefixed Save',
    layout => { body => 'prefixed body' },
);
$store->save_page($prefixed_saved_page);
ok(-f File::Spec->catfile( $paths->dashboards_root, 'prefixed-save' ), 'save_page normalizes a leading /app/ prefix to the relative dashboards path');
my $loaded_prefixed_page = $store->load_saved_page('prefixed-save');
is($loaded_prefixed_page->as_hash->{title}, 'Prefixed Save', 'load_saved_page resolves normalized prefixed bookmark ids');

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
my ($play_url) = $body1b =~ m{<button type="button" class="chrome-button" id="play-button" data-play-url="([^"]+)">Play</button>};
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

{
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_machine_ip = sub { return undef };
    my $remote_page = Developer::Dashboard::PageDocument->new(
        id     => 'context-remote',
        title  => 'Context Remote',
        layout => { body => 'body' },
    );
    $remote_page->{meta}{request_context} = {
        remote_addr => '192.0.2.55',
    };
    my $remote_html = $app->_top_context_html($remote_page);
    like( $remote_html, qr{href="http://192\.0\.2\.55"}, '_top_context_html falls back to remote_addr when machine and host values are absent' );

    my $default_page = Developer::Dashboard::PageDocument->new(
        id     => 'context-default',
        title  => 'Context Default',
        layout => { body => 'body' },
    );
    $default_page->{meta}{request_context} = {};
    my $default_html = $app->_top_context_html($default_page);
    like( $default_html, qr{href="http://127\.0\.0\.1"}, '_top_context_html falls back to loopback when no machine, host, or remote address is available' );
}
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
like($body1d_tt, qr/ddSource\.value = "[^"]*\[% title %\][^"]*"\s*;\s*ddLoadBlocks\(ddSource\.value\);/s, 'editor boot script keeps TT placeholders in the browser-loaded hidden instruction source before it splits blocks');
like($app->_editor_overlay_html("HTML: <h1>[% title %]</h1>\n"), qr/<span class="tok-directive">HTML:<\/span>\s*<span class="tok-tag">&lt;h1<\/span><span class="tok-tag">&gt;<\/span><span class="tok-note">\[% title %\]<\/span>/s, 'editor syntax highlight is still built from highlighted bookmark source lines');
my ($code1d_tt_source, $type1d_tt_source, $body1d_tt_source) = @{ $app->handle(
    path        => '/app/index/source',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt_source, 200, 'saved TT bookmark source route ok');
like($type1d_tt_source, qr/text\/plain/, 'saved TT bookmark source route returns plain text');
like($body1d_tt_source, qr/^HTML:\s+<h1>\[% title %\]<\/h1> \[% stash\.foo %\]$/m, 'saved TT bookmark source route preserves raw TT placeholders');
my ($play_url_tt) = $body1d_tt =~ m{<button type="button" class="chrome-button" id="play-button" data-play-url="([^"]+)">Play</button>};
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
like($body1e, qr/viewport\.className = 'editor-overlay-viewport';/, 'editor route builds a clipped overlay viewport for each visible block');
like($body1e, qr/function ddSyncEditorOverlay\(editor, highlight\)/, 'editor route exposes a dedicated overlay sync helper for one block overlay');
like($body1e, qr/function ddAutoResizeEditor\(editor\)/, 'editor route exposes a dedicated auto-resize helper for each block textarea');
like($body1e, qr/editor\.style\.height = 'auto';\s*editor\.style\.height = Math\.max\(editor\.scrollHeight, 48\) \+ 'px';/s, 'editor route grows each block textarea to match its content height');
like($body1e, qr/highlight\.style\.transform = 'translate\('/, 'editor route syncs each block overlay position through transforms instead of a second scrollbox');
like($body1e, qr/function ddCreateEditorBlock\(/, 'editor route builds visible block editors dynamically from bookmark sections');
like($body1e, qr/function ddRenderEditor\(editor, highlight\) \{\s*highlight\.innerHTML = ddOverlayHtml\(editor\.value\);\s*ddAutoResizeEditor\(editor\);\s*ddSyncEditorOverlay\(editor, highlight\);/s, 'editor route auto-resizes a block before syncing its overlay');
like($body1e, qr/window\.addEventListener\('resize', function\(\) \{\s*Array\.prototype\.slice\.call\(ddBlocks\.querySelectorAll\('\.editor-block'\)\)\.forEach\(function\(block\) \{\s*const editor = block\.querySelector\('\.instruction-block-editor'\);\s*const highlight = block\.querySelector\('\.editor-overlay'\);\s*ddAutoResizeEditor\(editor\);\s*ddSyncEditorOverlay\(editor, highlight\);/s, 'editor route reapplies auto-resize when the window size changes');
my $demo_overlay = $app->_editor_overlay_html($highlight_source);
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
my $broken_editor_overlay = $app->_editor_overlay_html($broken_editor_source);
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
unlike($body2, qr/id="play-button"/, 'render mode does not render play button');
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
unlike($readonly_render_body, qr/id="play-button"/, 'no-editor mode hides the play button from render views');
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
like($jquery_body, qr/jQuery v4\.0\.0/, 'built-in jquery bookmark helper route ships the bundled jQuery 4 asset');
like($jquery_body, qr/define\("jquery"/, 'built-in jquery bookmark helper keeps the packaged jQuery module wrapper');
like($jquery_body, qr/e\.jQuery=e\.\$=T/, 'built-in jquery bookmark helper exposes jQuery on the window object');

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
like($script_breakout_body, qr/ddSource\.value = ".*\\u003c\/script\\u003e.*"\s*;\s*ddLoadBlocks\(ddSource\.value\);/s, 'editor boot script escapes closing script tags inside the hidden JSON-backed source assignment before block loading');
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

my $index_file = $store->page_file('index');
unlink $index_file if -f $index_file;
my ($code10b, undef, $body10b) = @{ $app->handle(
    path        => '/',
    query       => '',
    remote_addr => '10.0.0.2',
    headers     => { host => '10.0.0.3:7890', cookie => $helper_cookie },
) };
is($code10b, 200, 'helper root route with session ok');
like($body10b, qr/id="logout-url"/, 'helper root blank editor renders logout link');
like($body10b, qr/class="user-name-and-icon".*helper_user/s, 'helper root blank editor shows helper username in the top chrome');

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

is(
    $app->_custom_skill_route_response( route_path => '/' ),
    undef,
    '_custom_skill_route_response ignores the root path so custom fallback only runs after smart routing misses',
);

{
    package Local::UnknownRouteDispatcher;
    sub resolve_custom_route_path { return { kind => 'bogus' } }
    package main;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { return bless {}, 'Local::UnknownRouteDispatcher' };
    is(
        $app->_custom_skill_route_response( route_path => '/bogus/custom/path' ),
        undef,
        '_custom_skill_route_response returns undef when custom route metadata resolves to an unsupported route kind',
    );
}

{
    package Local::UnknownSkillOwnedRouteDispatcher;
    sub resolve_custom_route_path { return { kind => 'bogus', skill_name => 'example-skill' } }
    package main;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { return bless {}, 'Local::UnknownSkillOwnedRouteDispatcher' };
    is(
        $app->_custom_skill_route_response( route_path => '/bogus/skill/path' ),
        undef,
        '_custom_skill_route_response also returns undef when one skill-owned custom route resolves to an unsupported route kind',
    );
}

{
    package Local::RuntimeAjaxAliasDispatcher;
    sub resolve_custom_route_path { return { kind => 'ajax', ajax_file => 'runtime/status' } }
    package main;
    my @captured;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { return bless {}, 'Local::RuntimeAjaxAliasDispatcher' };
    local *Developer::Dashboard::Web::App::dispatch_request = sub {
        my ( $self, %args ) = @_;
        push @captured, $args{path};
        return [ 200, 'text/plain; charset=utf-8', "runtime ajax alias\n" ];
    };
    is_deeply(
        $app->_custom_skill_route_response( route_path => '/runtime/status' ),
        [ 200, 'text/plain; charset=utf-8', "runtime ajax alias\n" ],
        '_custom_skill_route_response dispatches runtime ajax aliases back through the built-in ajax route family',
    );
    is_deeply( \@captured, ['/ajax/runtime/status'], 'runtime ajax aliases dispatch to the matching built-in ajax path' );
}

{
    package Local::RuntimeStaticAliasDispatcher;
    sub resolve_custom_route_path { return { kind => 'js', file => 'site/main.js' } }
    package main;
    my @captured;
    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { return bless {}, 'Local::RuntimeStaticAliasDispatcher' };
    local *Developer::Dashboard::Web::App::dispatch_request = sub {
        my ( $self, %args ) = @_;
        push @captured, $args{path};
        return [ 200, 'application/javascript', "console.log('runtime static alias');\n" ];
    };
    is_deeply(
        $app->_custom_skill_route_response( route_path => '/runtime/main.js' ),
        [ 200, 'application/javascript', "console.log('runtime static alias');\n" ],
        '_custom_skill_route_response dispatches runtime static aliases back through the built-in static route families',
    );
    is_deeply( \@captured, ['/js/site/main.js'], 'runtime static aliases dispatch to the matching built-in static path' );
}

is_deeply(
    $app->_serve_static_file_at_path( 'css', 'missing.css', '' ),
    [ 404, 'text/plain; charset=utf-8', "Not Found\n" ],
    '_serve_static_file_at_path returns an explicit 404 when the caller does not resolve a readable asset path',
);

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
