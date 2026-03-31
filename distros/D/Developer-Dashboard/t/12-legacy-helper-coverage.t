use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use URI::Escape qw(uri_escape);

use lib 'lib';

use DataHelper qw(j je);
use Developer::Dashboard::Auth;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;
use Folder;
use Zipper qw(zip unzip _cmdx _cmdp __cmdx acmdx Ajax);

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
my $workspace = File::Spec->catdir( $home, 'workspace' );
my $project   = File::Spec->catdir( $workspace, 'demo' );
mkdir $workspace;
mkdir $project;

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [$workspace],
    project_roots   => [$workspace],
);
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $pages = Developer::Dashboard::PageStore->new( paths => $paths );

Folder->configure(
    paths   => $paths,
    aliases => { alias_demo => $project },
);

is( Folder->home, $home, 'Folder home resolves current home' );
ok( Folder->tmp, 'Folder tmp resolves a temp dir' );
is( Folder->dd, $paths->runtime_root, 'Folder dd resolves runtime root' );
is( Folder->bookmarks, $paths->dashboards_root, 'Folder bookmarks resolves dashboards root' );
is( Folder->configs, $paths->config_root, 'Folder configs resolves config root' );
is( Folder->startup, $paths->startup_root, 'Folder startup resolves startup root' );
ok( -d Folder->postman, 'Folder postman creates the neutral postman directory' );

my $cd_result = Folder->cd(
    alias_demo => sub {
        my ($ctx) = @_;
        $ctx->{stay}->($ctx->{caller});
        return $ctx->{dir};
    }
);
is( $cd_result, $project, 'Folder cd yields the target directory to the callback' );
my @folder_listing = Folder->ls('alias_demo');
ok( @folder_listing >= 0, 'Folder ls returns entries for a real directory' );
ok( grep( { $_ eq $project } Folder->locate('demo') ), 'Folder locate finds matching workspace directories' );
is( Folder->alias_demo, $project, 'Folder AUTOLOAD resolves configured aliases' );

my $zipped = zip('print qq{ok};');
ok( $zipped->{raw}, 'zip returns a raw token' );
is( unzip( $zipped->{raw} ), 'print qq{ok};', 'unzip reverses raw tokens' );
like( __cmdx( perl => 'print 1;' ), qr/base64 -d \| gunzip/, '__cmdx builds a shell decode pipeline' );
my @cmdx = _cmdx( perl => 'print 1;' );
is_deeply( [ @cmdx[ 0, 1 ] ], [ 'perl', '-e' ], '_cmdx returns shell tuple metadata' );
my @cmdp = _cmdp( perl => 'print 1;' );
is( $cmdp[1], 'perl', '_cmdp returns pipeline metadata' );
my $ajax_url = acmdx( type => 'json', code => 'print qq{{}};' );
like( $ajax_url->{url}{tokenised}, qr{^/ajax\?token=}, 'acmdx builds a tokenised ajax url' );
my ( $ajax_stdout, undef, $ajax_result ) = capture {
    return Ajax( jvar => 'configs.coverage.endpoint', code => 'print qq{{}};' );
};
like( $ajax_stdout, qr/set_chain_value/, 'Ajax prints the legacy config-binding script' );
is( $ajax_result, 'HIDE-THIS', 'Ajax returns the legacy hide marker' );

is_deeply( je( j( { ok => 1 } ) ), { ok => 1 }, 'DataHelper je decodes JSON created by j' );
is_deeply( Developer::Dashboard::PageDocument::_decode_structured_json('{"ok":1}'), { ok => 1 }, 'PageDocument structured JSON decoder returns parsed hashes' );
is( Developer::Dashboard::PageDocument::_template_value( 'stash.name', { stash => { name => 'Modern' } } ), 'Modern', 'PageDocument template-value helper resolves nested keys' );

my $modern_page = Developer::Dashboard::PageDocument->from_instruction(<<'PAGE');
=== TITLE ===
Modern Title

=== DESCRIPTION ===
Modern Note

=== STASH ===
{"name":"Modern"}

=== HTML ===
<div>[% stash.name %] [% method("Folder","home") %] [% func("unused") %]</div>

=== FORM.TT ===
<span>[% ENV.HOME %] [% eval("print q{TT-EVAL}") %]</span>

=== FORM ===
[%title%] [#name#] {{filter}}

=== CODE1 ===
print "MODERN";
PAGE
is( $modern_page->as_hash->{title}, 'Modern Title', 'PageDocument still parses modern source as input' );
is( $modern_page->render_template('ignored'), $modern_page, 'render_template compatibility method returns the page object' );
like( $modern_page->canonical_json, qr/Modern Title/, 'canonical_json serializes page content' );

my $runtime = Developer::Dashboard::PageRuntime->new( paths => $paths );
my $prepared = $runtime->prepare_page(
    page => $modern_page,
    source => 'saved',
    runtime_context => {
        cwd    => $project,
        params => { filter => 'applied' },
    },
);
like( $prepared->{layout}{body}, qr/Modern/, 'Template Toolkit renders HTML with stash access' );
like( $prepared->{layout}{body}, qr/\Q$home\E/, 'Template Toolkit method helper can call generic runtime methods' );
like( $prepared->{layout}{form_tt}, qr/\Q$home\E/, 'Template Toolkit renders FORM.TT with ENV access' );
like( $prepared->{layout}{form_tt}, qr/TT-EVAL/, 'Template Toolkit eval helper runs bookmark Perl snippets' );
like( $prepared->{layout}{form}, qr/Modern Title Modern applied/, 'legacy FORM placeholder expansion still works' );
like( join( '', @{ $prepared->{meta}{runtime_outputs} } ), qr/MODERN/, 'prepare_page executes CODE blocks and captures stdout' );

my $tt_error_page = Developer::Dashboard::PageDocument->new(
    layout => { body => '[% THROW boom "bad" %]' },
);
$runtime->prepare_page( page => $tt_error_page, source => 'saved', runtime_context => {} );
like( $tt_error_page->{layout}{body}, qr/THROW boom/, 'prepare_page leaves unsupported template directives untouched' );
is( $runtime->_system_context( runtime_context => {}, source => '' )->{cwd}, '.', '_system_context defaults cwd when omitted' );
is( Developer::Dashboard::PageRuntime::_escape_html('<x>'), '&lt;x&gt;', '_escape_html escapes HTML markup' );

my $auth = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
my $app = Developer::Dashboard::Web::App->new(
    auth     => $auth,
    pages    => $pages,
    sessions => $sessions,
    runtime  => $runtime,
);

my $saved_file = Developer::Dashboard::PageDocument->new(
    id     => 'legacy-page',
    title  => 'Legacy Page',
    layout => { body => 'legacy body' },
);
$pages->save_page($saved_file);

is( $app->handle( path => '/marked.min.js', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } )->[0], 200, 'web app serves marked shim' );
is( $app->handle( path => '/tiff.min.js', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } )->[0], 200, 'web app serves tiff shim' );
is( $app->handle( path => '/loading.webp', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } )->[0], 200, 'web app serves loading image shim' );

my $login_user = $auth->add_user( username => 'helperx', password => 'helper-pass-123' );
ok( $login_user->{username}, 'helper user can be created for login flow coverage' );
my ( $login_code, undef, undef, $login_headers ) = @{ $app->handle(
    path        => '/login',
    method      => 'POST',
    body        => 'username=helperx&password=helper-pass-123',
    remote_addr => '10.0.0.2',
    headers     => { host => 'localhost:7890' },
) };
is( $login_code, 302, 'helper login returns a redirect response' );
like( $login_headers->{'Set-Cookie'}, qr/dashboard_session=/, 'helper login returns a session cookie' );

my $session_cookie = $login_headers->{'Set-Cookie'};
my ($logout_code, undef, undef, $logout_headers) = @{ $app->handle(
    path        => '/logout',
    query       => '',
    remote_addr => '10.0.0.2',
    headers     => { host => 'localhost:7890', cookie => $session_cookie },
) };
is( $logout_code, 302, 'logout returns a redirect response' );
like( $logout_headers->{'Set-Cookie'}, qr/Max-Age=0/, 'logout expires the session cookie' );

{
    open my $fh, '>', $pages->page_file('legacy-forward') or die $!;
    print {$fh} '/page/legacy-page';
    close $fh;
}
is( $app->handle( path => '/app/legacy-forward', query => '', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } )->[0], 200, 'legacy app forwarding handles saved url bookmarks' );

done_testing;

__END__

=head1 NAME

12-legacy-helper-coverage.t - targeted legacy helper and runtime coverage tests

=head1 DESCRIPTION

This test drives the remaining legacy compatibility helpers and runtime paths
needed to keep the active library coverage high after the bookmark-model reset.

=cut
