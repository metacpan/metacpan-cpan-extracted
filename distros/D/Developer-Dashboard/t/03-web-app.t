use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use URI::Escape qw(uri_escape);

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

local $ENV{HOME} = tempdir(CLEANUP => 1);

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

my ($code1, $type1, $body1) = @{ $app->handle(path => '/', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1, 200, 'root editor route ok');
like($body1, qr/<textarea[^>]*name="instruction"/, 'root route renders editable instruction textarea');
unlike($body1, qr/Saved pages live under/, 'root route no longer renders landing list');
unlike($body1, qr/>Update</, 'root route does not render manual update button');
like($body1, qr/addEventListener\('change', function\(\) \{\s*ddForm\.submit\(\);/s, 'root route auto-submits textarea changes on blur');

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
    body        => 'instruction=TITLE%3A%20Developer%20Dashboard%0A%3A--------------------------------------------------------------------------------%3A%0ABOOKMARK%3A%20index%0A%3A--------------------------------------------------------------------------------%3A%0ASTASH%3A%20%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20HERE%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_bookmark, 200, 'posted bookmark instruction route ok');
ok( -f File::Spec->catfile( $paths->dashboards_root, 'index' ), 'root editor saves posted bookmark instructions to the bookmark store' );
like($body1d_bookmark, qr/BOOKMARK:\s+index/s, 'posted bookmark response preserves the bookmark id');
my ($code1d_saved, undef, $body1d_saved) = @{ $app->handle(path => '/app/index', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code1d_saved, 200, 'legacy /app/index route loads a bookmark saved from the root editor');
like($body1d_saved, qr/HERE/, 'legacy /app/index route renders the saved bookmark body');

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
like($body1d_tt, qr/instruction-highlight[\s\S]*?\[% title %\]/s, 'editor syntax highlight is built from raw TT bookmark source');
my ($code1d_tt_source, $type1d_tt_source, $body1d_tt_source) = @{ $app->handle(
    path        => '/page/index/source',
    query       => '',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt_source, 200, 'saved TT bookmark source route ok');
like($type1d_tt_source, qr/text\/plain/, 'saved TT bookmark source route returns plain text');
like($body1d_tt_source, qr/^HTML:\s+<h1>\[% title %\]<\/h1> \[% stash\.foo %\]$/m, 'saved TT bookmark source route preserves raw TT placeholders');
my ($play_url_tt) = $body1d_tt =~ m{<a href="([^"]+)" id="play-url">Play</a>};
ok($play_url_tt, 'TT bookmark play url extracted');
my ($play_query_tt) = $play_url_tt =~ /\?(.*)\z/;
my ($code1d_tt_render, undef, $body1d_tt_render) = @{ $app->handle(
    path        => '/',
    query       => $play_query_tt,
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt_render, 200, 'TT bookmark play route ok');
like($body1d_tt_render, qr{<h1>\s*Sample Dashboard\s*</h1>\s*1}s, 'TT render receives TITLE and STASH values');
my ($tt_view_source_url) = $body1d_tt_render =~ m{<a href="([^"]+)" id="view-source-url">View Source</a>};
ok($tt_view_source_url, 'TT render exposes a transient view source link');
my ($tt_view_source_query) = $tt_view_source_url =~ /\?(.*)\z/;
my ($code1d_tt_view_source, $type1d_tt_view_source, $body1d_tt_view_source) = @{ $app->handle(
    path        => '/',
    query       => $tt_view_source_query,
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is($code1d_tt_view_source, 200, 'transient TT view source route ok');
like($type1d_tt_view_source, qr/text\/html/, 'transient TT view source route returns the browser editor HTML');
like($body1d_tt_view_source, qr{<textarea[^>]*>[\s\S]*HTML:\s+&lt;h1&gt;\[% title %\]&lt;/h1&gt; \[% stash\.foo %\][\s\S]*</textarea>}m, 'transient TT view source editor keeps raw TT placeholders after render');
unlike($body1d_tt_view_source, qr{<textarea[^>]*>[\s\S]*HTML:\s+&lt;h1&gt;Sample Dashboard&lt;/h1&gt; 1[\s\S]*</textarea>}m, 'transient TT view source editor does not bake rendered values into source');

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
like($body1e, qr/tok-tag/, 'HTML sections highlight tag syntax');
like($body1e, qr/tok-css/, 'HTML sections highlight CSS syntax');
like($body1e, qr/tok-js/, 'HTML sections highlight JavaScript syntax');
like($body1e, qr/tok-perl-keyword/, 'CODE sections highlight Perl syntax');
like($body1e, qr/tok-perl-var/, 'CODE sections highlight Perl variables');

my ($code2, $type2, $body2) = @{ $app->handle(path => '/page/welcome', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code2, 200, 'saved page route ok');
like($body2, qr/Welcome/, 'saved page rendered');
unlike($body2, qr{<h1>\s*Welcome\s*</h1>}, 'page title is not injected into the page body');
like($body2, qr{<title>Welcome</title>}, 'page title is still rendered in the head title element');
unlike($body2, qr/id="logout-url"/, 'admin route does not render logout link');

my ($code2b, undef, $body2b) = @{ $app->handle(path => '/page/welcome', query => 'name=Michael', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code2b, 200, 'saved page with query state route ok');
like($body2b, qr/Michael/, 'query parameters are merged into page state during render');
unlike($body2, qr/id="play-url"/, 'render mode does not render play link');
like($body2, qr{href="/page/welcome/edit"[^>]+id="view-source-url"}, 'render mode view source points to edit route');

my $token = uri_escape( $store->encode_page($page) );
my ($code3, $type3, $body3) = @{ $app->handle(path => '/', query => "mode=source&token=$token", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code3, 200, 'transient source route ok');
like($type3, qr/text\/plain/, 'source mode returns plain text instructions');
like($body3, qr/^TITLE:\s+Welcome/m, 'source mode returns canonical legacy instruction page');

my ($code4, $type4, $body4) = @{ $app->handle(path => '/page/legacy-welcome', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
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
my ($code5, undef, $body5) = @{ $app->handle(path => '/', query => "token=$legacy_token", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
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
};
PAGE
$store->save_page($legacy_ajax_page);

my ($code6, undef, $body6) = @{ $app->handle(path => '/app/legacy-ajax', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code6, 200, 'legacy /app route renders bookmark');
like($body6, qr/set_chain_value\(configs,'demo\.endpoint','\/ajax\?token=/, 'legacy Ajax helper injects config endpoint');

my ($ajax_token) = $body6 =~ m{/ajax\?token=([^&]+)&type=json};
ok($ajax_token, 'legacy ajax token extracted from rendered page');
my ($code7, $type7, $body7) = @{ $app->handle(path => '/ajax', query => "token=$ajax_token&type=json", remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code7, 200, 'legacy ajax endpoint executes');
like($type7, qr/application\/json/, 'legacy ajax endpoint returns json type');
like($body7, qr/"ok"\s*:\s*1/, 'legacy ajax endpoint returns encoded payload output');

{
    open my $fh, '>', $store->page_file('legacy-forward') or die $!;
    print {$fh} '/ajax?type=text&token=' . $ajax_token;
    close $fh;
}
my ($code8, $type8, $body8) = @{ $app->handle(path => '/app/legacy-forward', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code8, 200, 'legacy /app saved-url forwarding works');
like($type8, qr/text\/plain/, 'forwarded saved-url bookmark preserves content type');
like($body8, qr/"ok"\s*:\s*1/, 'forwarded saved-url bookmark reaches ajax payload');

{
    open my $fh, '>', $store->page_file('legacy-forward-override') or die $!;
    print {$fh} '/ajax?type=text&token=' . $ajax_token . '&status=default';
    close $fh;
}
my ($code9, undef, $body9) = @{ $app->handle(path => '/app/legacy-forward-override', query => 'status=override', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' }) };
is($code9, 200, 'legacy /app saved-url forwarding with override works');
like($body9, qr/"ok"\s*:\s*1/, 'forwarded saved-url override still reaches ajax payload');

$auth->add_user( username => 'helper_user', password => 'helper-pass-123' );
my $helper_session = $sessions->create(
    username    => 'helper_user',
    role        => 'helper',
    remote_addr => '10.0.0.2',
);
my $helper_cookie = 'dashboard_session=' . $helper_session->{session_id};

my ($code10, undef, $body10) = @{ $app->handle(
    path        => '/page/welcome',
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
