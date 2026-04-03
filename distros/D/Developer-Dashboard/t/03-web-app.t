use strict;
use warnings;

use File::Path qw(make_path);
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use URI::Escape qw(uri_escape);

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::Codec qw(encode_payload);
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
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
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";

my $paths = Developer::Dashboard::PathRegistry->new;
my $store = Developer::Dashboard::PageStore->new(paths => $paths);
my $auth = Developer::Dashboard::Auth->new(
    files => Developer::Dashboard::FileRegistry->new(paths => $paths),
    paths => $paths,
);
my $sessions = Developer::Dashboard::SessionStore->new(paths => $paths);
my $runtime = Developer::Dashboard::PageRuntime->new(paths => $paths);
my $prompt = Developer::Dashboard::Prompt->new(
    paths      => $paths,
    indicators => Developer::Dashboard::IndicatorStore->new(paths => $paths),
);
my $app = Developer::Dashboard::Web::App->new(
    auth     => $auth,
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
HTML: <script src="/js/jq.js"></script>
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

=cut
