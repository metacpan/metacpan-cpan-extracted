#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::Web::App;

# Hermetic runtime rooted in a throwaway HOME.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{USER} = 'coverage-user';
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};
delete local $ENV{_PORT};
chdir $home or die "Unable to chdir to $home: $!";

my $paths    = Developer::Dashboard::PathRegistry->new( home => $home );
my $files    = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store    = Developer::Dashboard::PageStore->new( paths => $paths );
my $config   = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $auth     = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
my $runtime  = Developer::Dashboard::PageRuntime->new( paths => $paths );

sub build_app {
    my (%extra) = @_;
    return Developer::Dashboard::Web::App->new(
        auth     => $auth,
        config   => $config,
        pages    => $store,
        runtime  => $runtime,
        sessions => $sessions,
        %extra,
    );
}

sub write_file {
    my ( $path, $content ) = @_;
    make_path( ( File::Spec->splitpath($path) )[1] );
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return 1;
}

my $app = build_app();

# ---------------------------------------------------------------------------
# skill_ajax_file_response: a resolved skill spec that carries no skill_layers.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_route_segments = sub { return {}; };
    my $res = $app->skill_ajax_file_response(
        skill_name  => 'layerless-skill',
        ajax_file   => 'missing.json',
        remote_addr => '127.0.0.1',
        headers     => {},
    );
    is( ref($res), 'ARRAY', 'a skill spec without skill_layers still produces a response' );
}

# ---------------------------------------------------------------------------
# _load_named_page: a resolver that returns nothing without raising.
# ---------------------------------------------------------------------------
{
    package T331::SilentResolver;
    sub new { return bless {}, $_[0]; }
    sub load_named_page { return; }
}
{
    my $silent = build_app( resolver => T331::SilentResolver->new );
    is( $silent->_load_named_page('anything'), undef, 'a resolver returning nothing yields no page and no error' );
}

# ---------------------------------------------------------------------------
# _legacy_app_response: saved bookmark targets that carry an external authority.
# ---------------------------------------------------------------------------
sub bookmark {
    my ( $id, $target ) = @_;
    write_file( File::Spec->catfile( $paths->dashboards_root, $id ), "$target\n" );
    return $id;
}

{
    # A scheme-relative //host/path target parses as URI::_generic, which has
    # no host() of its own; the real code must still treat it as external.
    my $res = $app->_legacy_app_response( id => bookmark( 'bm-schemeless', '//example.com/dest' ) );
    is( $res->[0], 302, 'a scheme-relative bookmark redirects' );
    is( $res->[3]{Location}, '//example.com/dest', 'a scheme-relative bookmark keeps its target as the location' );

    $res = $app->_legacy_app_response( id => bookmark( 'bm-schemeless-nohost', '///dest' ) );
    isnt( $res->[0], 302, 'a scheme-relative bookmark without a host is not an external redirect' );

    $res = $app->_legacy_app_response( id => bookmark( 'bm-ftp', 'ftp://example.com/x' ) );
    is( $res->[0], 400, 'an unsupported bookmark scheme is rejected' );

    $res = $app->_legacy_app_response( id => bookmark( 'bm-https', 'https://example.com/x' ) );
    is( $res->[0], 302, 'an https bookmark redirects' );

    $res = $app->_legacy_app_response(
        id           => 'bm-https',
        query_params => { a => 1 },
        body_params  => { b => 2 },
    );
    like( $res->[3]{Location}, qr/\Ahttps:\/\/example\.com\/x\?/, 'request params are appended to an external redirect' );
}

{
    my @cases = (
        [ 'bm-local-ok',        'http://127.0.0.1:4321/app/welcome?token=abc', 4321,  'a local token bookmark is dispatched internally' ],
        [ 'bm-local-https',     'https://127.0.0.1:4321/app/welcome?token=abc', 4321, 'https is never a local token bookmark' ],
        [ 'bm-local-otherhost', 'http://10.0.0.1:4321/app/welcome?token=abc',   4321, 'another host is never a local token bookmark' ],
        [ 'bm-local-noport',    'http://127.0.0.1:4321/app/welcome?token=abc',  undef, 'no configured port is never a local token bookmark' ],
        [ 'bm-local-badport',   'http://127.0.0.1:4321/app/welcome?token=abc',  9999, 'a different port is never a local token bookmark' ],
        [ 'bm-local-notoken',   'http://127.0.0.1:4321/app/welcome?x=1',        4321, 'a query without a token is never a local token bookmark' ],
    );
    for my $case (@cases) {
        my ( $id, $target, $port, $label ) = @{$case};
        bookmark( $id, $target );
        local $ENV{_PORT} = $port if defined $port;
        my $res = $app->_legacy_app_response( id => $id );
        if ( $id eq 'bm-local-ok' ) {
            isnt( $res->[0], 302, $label );
        }
        else {
            is( $res->[0], 302, $label );
        }
    }

    bookmark( 'bm-local-emptypath', 'http://127.0.0.1:4321?token=abc' );
    local $ENV{_PORT} = 4321;
    is( $app->_legacy_app_response( id => 'bm-local-emptypath' )->[0], 400, 'a local token bookmark with an empty path is rejected' );
}

{
    # A relative bookmark whose parsed path is undefined is rejected.
    no warnings qw(redefine once);
    bookmark( 'bm-undef-path', '/app/welcome' );
    local *URI::_generic::path = sub { return; };
    is( $app->_legacy_app_response( id => 'bm-undef-path' )->[0], 400, 'a bookmark with an undefined URI path is rejected' );
}

# ---------------------------------------------------------------------------
# _legacy_external_redirect_response.
# ---------------------------------------------------------------------------
{
    is( $app->_legacy_external_redirect_response( target => "http://a/\x01" )->[0], 400, 'a control character in the target is rejected' );
    my $res = $app->_legacy_external_redirect_response();
    is( $res->[3]{Location}, '', 'a missing target redirects to an empty location' );

    is( $app->_legacy_external_redirect_response( target => 'http://a/', raw_query => "x=\x01" )->[0], 400, 'a control character in the raw query is rejected' );
    is( $app->_legacy_external_redirect_response( target => 'http://a/', raw_query => 'x=1' )->[3]{Location}, 'http://a/?x=1', 'a raw query is appended with ?' );
    is( $app->_legacy_external_redirect_response( target => 'http://a/?q=1', raw_query => 'x=1' )->[3]{Location}, 'http://a/?q=1&x=1', 'a raw query is appended with & when the target has a query' );
    is( $app->_legacy_external_redirect_response( target => 'http://a/', raw_query => '' )->[3]{Location}, 'http://a/', 'an empty raw query falls back to params and appends nothing' );
    is( $app->_legacy_external_redirect_response( target => 'http://a/', params => { k => 'v' } )->[3]{Location}, 'http://a/?k=v', 'params are used when no raw query exists' );
}

# ---------------------------------------------------------------------------
# _resolve_legacy_selected_params: undefined position is ignored.
# ---------------------------------------------------------------------------
{
    my $params = { x => [ 'a', 'b' ], 'x.selected.pos' => undef, y => [ 'c', 'd' ], 'y.selected.pos' => 1 };
    Developer::Dashboard::Web::App::_resolve_legacy_selected_params($params);
    $params->{'z.selected.pos'} = 'abc';
    $params->{z} = [ 'p', 'q' ];
    $params->{'w.selected.pos'} = 0;
    $params->{w} = 'scalar';
    $params->{'v.selected.pos'} = 5;
    $params->{v} = ['only'];
    Developer::Dashboard::Web::App::_resolve_legacy_selected_params($params);
    is_deeply( $params->{z}, [ 'p', 'q' ], 'a non-numeric selected position leaves the array untouched' );
    is( $params->{w}, 'scalar', 'a non-array value is left alone' );
    is_deeply( $params->{v}, ['only'], 'an out-of-range position leaves the array untouched' );
    is( Developer::Dashboard::Web::App::_resolve_legacy_selected_params('not-a-hash'), undef, 'a non-hash argument is ignored' );
    is_deeply( $params->{x}, [ 'a', 'b' ], 'an undefined selected position leaves the array untouched' );
    is( $params->{y}, 'd', 'a numeric selected position picks the element' );
}

# ---------------------------------------------------------------------------
# _ip_pairs_from_ip: run a real `ip` executable (a stub placed first on PATH).
# ---------------------------------------------------------------------------
{
    my $bin = File::Spec->catdir( $home, 'fake-bin' );
    make_path($bin);
    my $ip = File::Spec->catfile( $bin, 'ip' );
    write_file( $ip, "#!/bin/sh\necho '2: eth9    inet 10.9.8.7/24 brd 10.9.8.255 scope global eth9'\n" );
    chmod 0755, $ip or die "Unable to chmod $ip: $!";
    local $ENV{PATH} = join ':', $bin, $ENV{PATH};
    is_deeply( [ $app->_ip_pairs_from_ip ], [ { iface => 'eth9', ip => '10.9.8.7' } ], 'a real ip executable output is parsed' );
}

# ---------------------------------------------------------------------------
# _static_file_roots: no page store, and HOME/USERPROFILE fallbacks.
# ---------------------------------------------------------------------------
{
    my $bare = build_app();
    $bare->{pages} = undef;
    local $ENV{HOME};
    delete $ENV{HOME};
    delete $ENV{USERPROFILE};
    my @roots = $bare->_static_file_roots('css');
    is_deeply(
        \@roots,
        [ File::Spec->catdir( '/root', '.developer-dashboard', 'dashboard', 'public', 'css' ) ],
        'without pages, HOME or USERPROFILE only the /root fallback root remains',
    );

    local $ENV{USERPROFILE} = '/profile-home';
    @roots = $bare->_static_file_roots('css');
    is(
        $roots[-1],
        File::Spec->catdir( '/profile-home', '.developer-dashboard', 'dashboard', 'public', 'css' ),
        'USERPROFILE is used when HOME is absent',
    );

    my $foreign = build_app( pages => bless( {}, 'T331::ForeignPages' ) );
    @roots = $foreign->_static_file_roots('css');
    is( scalar @roots, 1, 'a non PageStore pages object contributes no store roots' );
}

# ---------------------------------------------------------------------------
# static_file_response, transient_action_response gate, _get_content_type.
# ---------------------------------------------------------------------------
{
    for my $file ( 'jquery.js', 'jquery-4.0.0.min.js' ) {
        is( $app->static_file_response( type => 'js', file => $file )->[0], 200, "static_file_response serves the bundled $file" );
    }
    my $other = $app->static_file_response( type => 'js', file => 'not-jquery-at-all.js' );
    is( $other->[0], 404, 'static_file_response falls through to the public tree for other js files' );

    local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 0;
    is(
        $app->transient_action_response( path => '/action', query => 'atoken=abc', body => '', headers => {}, remote_addr => '127.0.0.1' )->[0],
        403,
        'an action token is refused while transient URLs are disabled',
    );
}

{
    my %expected = (
        'x.json' => 'application/json; charset=utf-8',
        'x.xml'  => 'application/xml; charset=utf-8',
        'x.txt'  => 'text/plain; charset=utf-8',
        'x.html' => 'text/html; charset=utf-8',
        'x.svg'  => 'image/svg+xml',
        'x.png'  => 'image/png',
        'x.jpg'  => 'image/jpeg',
        'x.gif'  => 'image/gif',
        'x.webp' => 'image/webp',
        'x.ico'  => 'image/x-icon',
        'x.bin'  => 'application/octet-stream',
    );
    is( $app->_get_content_type( 'other', $_ ), $expected{$_}, "content type for $_" ) for sort keys %expected;
    is( $app->_get_content_type( 'js',  'x.js' ),  'application/javascript; charset=utf-8', 'content type for js type' );
    is( $app->_get_content_type( 'css', 'x.css' ), 'text/css; charset=utf-8',               'content type for css type' );
}

done_testing;

__END__

=pod

=head1 NAME

t/331-web-app-bookmark-static-coverage.t - remaining branch coverage for Developer::Dashboard::Web::App

=head1 PURPOSE

Covers saved external bookmark handling (scheme-relative targets, unsupported
schemes, local token bookmarks and every short-circuit of the local-token test,
redirect query merging, selected-position resolution), a resolver that returns
nothing, a skill spec without layers, the real C<ip> subprocess parser, and the
static root list when no page store or HOME is available.

=head1 WHY IT EXISTS

These paths need unusual state (an unset C<_PORT>, a stub C<ip> on PATH, a
page store that is not a C<PageStore>) that the other web-app tests never
construct, so they were the remaining uncovered branches and conditions.

=head1 WHEN TO USE

Run it when changing legacy bookmark forwarding, external redirect building,
interface discovery, or static root resolution.

=head1 HOW TO USE

  prove -lv t/331-web-app-bookmark-static-coverage.t

=head1 WHAT USES IT

Developers during TDD and the Devel::Cover gate.

=head1 EXAMPLES

  prove -lv t/331-web-app-bookmark-static-coverage.t

=cut
