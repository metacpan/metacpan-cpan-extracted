#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Request::Common qw(GET);
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

# ---------------------------------------------------------------------------
# The bundled icon lives in the checkout's share tree, so record the repository
# root before the hermetic chdir moves the process out of it.
# ---------------------------------------------------------------------------
my $repo_root = getcwd();
my $bundled_icon = File::Spec->catfile( $repo_root, 'share', 'public', 'others', 'favicon.ico' );

# ---------------------------------------------------------------------------
# Hermetic runtime: both the layer stack and Config discovery resolve from the
# process HOME and from the deepest .developer-dashboard layer under the current
# working directory, so anchor HOME and the CWD inside one throwaway temp dir.
# ---------------------------------------------------------------------------
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
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

my $app = Developer::Dashboard::Web::App->new(
    actions  => $actions,
    auth     => $auth,
    config   => $config,
    pages    => $store,
    prompt   => $prompt,
    runtime  => $runtime,
    sessions => $sessions,
);

# read_raw($path)
# Slurps one file as raw bytes so icon comparisons stay byte-exact.
# Input: file path string.
# Output: file content byte string.
sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "Unable to close $path: $!";
    return $content;
}

# write_raw($path, $content)
# Writes one file as raw bytes, creating the parent directories on the way.
# Input: file path string and byte string content.
# Output: true on success.
sub write_raw {
    my ( $path, $content ) = @_;
    my $dir = ( File::Spec->splitpath($path) )[1];
    make_path($dir) if !-d $dir;
    open my $fh, '>:raw', $path or die "Unable to write $path: $!";
    print {$fh} $content or die "Unable to print to $path: $!";
    close $fh or die "Unable to close $path: $!";
    return 1;
}

# ---------------------------------------------------------------------------
# The bundled asset itself: browsers only accept a real icon, so pin both the
# packaging location and the ICO container structure.
# ---------------------------------------------------------------------------
ok( -f $bundled_icon, 'share/public/others/favicon.ico ships as a bundled public asset' );

my $icon_bytes = -f $bundled_icon ? read_raw($bundled_icon) : '';
ok( length($icon_bytes) > 0, 'the bundled favicon asset is not empty' );

my ( $ico_reserved, $ico_type, $ico_count ) = unpack 'v v v', $icon_bytes;
is( $ico_reserved, 0, 'the bundled favicon carries the reserved ICONDIR field' );
is( $ico_type,     1, 'the bundled favicon declares the ICO icon resource type' );
is( $ico_count,    1, 'the bundled favicon declares exactly one image' );

my ( $ico_width, $ico_height, $ico_colors, $ico_dir_reserved, $ico_planes, $ico_bits, $ico_length, $ico_offset )
  = unpack 'C C C C v v V V', substr( $icon_bytes, 6, 16 );
is( $ico_width,         16, 'the bundled favicon image is 16 pixels wide' );
is( $ico_height,        16, 'the bundled favicon image is 16 pixels tall' );
is( $ico_colors,         0, 'the bundled favicon declares a truecolor palette' );
is( $ico_dir_reserved,   0, 'the bundled favicon carries the reserved ICONDIRENTRY field' );
is( $ico_planes,         1, 'the bundled favicon declares a single colour plane' );
is( $ico_bits,          32, 'the bundled favicon declares 32 bits per pixel' );
is( $ico_offset,        22, 'the bundled favicon image starts right after the directory entry' );
is( $ico_offset + $ico_length, length($icon_bytes), 'the bundled favicon directory entry spans the whole file' );

# ---------------------------------------------------------------------------
# Backend contract: favicon_response serves the bundled icon with the ICO mime
# type when no layer overrides it.
# ---------------------------------------------------------------------------
{
    my $response = $app->favicon_response( path => '/favicon.ico', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } );
    is( $response->[0], 200, 'favicon_response serves the bundled icon' );
    is( $response->[1], 'image/x-icon', 'favicon_response answers with the ICO content type' );
    is( $response->[2], $icon_bytes, 'favicon_response streams the bundled icon bytes verbatim' );
}

# ---------------------------------------------------------------------------
# The automatic browser request must never depend on a session. handle() is the
# canonical full-request entry point, so the icon has to resolve there before
# the auth gate on every tier.
# ---------------------------------------------------------------------------
{
    my $outsider = $app->handle( path => '/favicon.ico', remote_addr => '203.0.113.9', headers => { host => '203.0.113.9' } );
    is( $outsider->[0], 200, 'handle serves /favicon.ico to an outsider with no helper users configured' );
    is( $outsider->[1], 'image/x-icon', 'the outsider favicon response keeps the ICO content type' );
    is( $outsider->[2], $icon_bytes, 'the outsider favicon response carries the bundled icon bytes' );

    my $admin = $app->handle( path => '/favicon.ico', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } );
    is( $admin->[0], 200, 'handle serves /favicon.ico on the loopback admin tier' );
}

$auth->add_user( username => 'helper407', password => 'favicon-secret-407', role => 'helper' );
ok( $auth->helper_users_enabled, 'a helper user is configured so the helper login tier is active' );

{
    my $unauthenticated = $app->handle( path => '/favicon.ico', remote_addr => '203.0.113.9', headers => { host => '203.0.113.9' } );
    is( $unauthenticated->[0], 200, 'handle serves /favicon.ico before login once helper users exist' );
    is( $unauthenticated->[1], 'image/x-icon', 'the pre-login favicon response keeps the ICO content type' );

    my $protected = $app->handle( path => '/system/status', remote_addr => '203.0.113.9', headers => { host => '203.0.113.9' } );
    is( $protected->[0], 401, 'an ordinary route still demands a helper login from the same outsider request' );
}

# ---------------------------------------------------------------------------
# Layered override: an operator or skill layer may brand the tab icon by placing
# its own others/favicon.ico in a layered public root, which then wins over the
# bundled asset.
# ---------------------------------------------------------------------------
{
    my $override_bytes = read_raw($bundled_icon) . "\x00override-407";
    my $override_path = File::Spec->catfile( $paths->runtime_root, 'dashboard', 'public', 'others', 'favicon.ico' );
    write_raw( $override_path, $override_bytes );

    my $response = $app->favicon_response( path => '/favicon.ico', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } );
    is( $response->[0], 200, 'favicon_response still answers when a layer overrides the icon' );
    is( $response->[1], 'image/x-icon', 'the layered favicon override keeps the ICO content type' );
    is( $response->[2], $override_bytes, 'the layered favicon override wins over the bundled asset' );

    unlink $override_path or die "Unable to unlink $override_path: $!";
    my $restored = $app->favicon_response( path => '/favicon.ico', remote_addr => '127.0.0.1', headers => { host => '127.0.0.1' } );
    is( $restored->[2], $icon_bytes, 'removing the layered override falls back to the bundled icon' );
}

# ---------------------------------------------------------------------------
# ATDD: the real Dancer2 route table must answer the automatic browser request
# with the icon and the dashboard default security headers, on the pre-login
# outsider tier as well as on loopback.
# ---------------------------------------------------------------------------
{
    my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app(
        app             => $app,
        default_headers => { 'X-Content-Type-Options' => 'nosniff' },
    );

    Local::PSGITest::test_psgi $psgi_app, sub {
        my ($cb) = @_;

        my $loopback = $cb->( GET 'http://127.0.0.1/favicon.ico' );
        is( $loopback->code, 200, 'the Dancer route table answers GET /favicon.ico instead of falling through to a 404' );
        is( $loopback->header('Content-Type'), 'image/x-icon', 'the Dancer favicon route answers with the ICO content type' );
        is( $loopback->header('X-Content-Type-Options'), 'nosniff', 'the Dancer favicon route carries the dashboard default security headers' );
        is( $loopback->content, $icon_bytes, 'the Dancer favicon route serves the bundled icon bytes' );

        my $outsider = $cb->( GET 'http://203.0.113.9/favicon.ico' );
        is( $outsider->code, 200, 'the Dancer favicon route stays reachable before a helper login' );
        is( $outsider->content, $icon_bytes, 'the pre-login Dancer favicon route serves the bundled icon bytes' );

        my $protected = $cb->( GET 'http://203.0.113.9/system/status' );
        is( $protected->code, 401, 'the Dancer route table still gates ordinary routes for the same outsider' );
    };
}

chdir $repo_root or die "Unable to chdir back to $repo_root: $!";

done_testing();

__END__

=head1 NAME

t/124-favicon-route.t - pin the dashboard browser tab icon route and asset

=head1 SYNOPSIS

  prove -lv t/124-favicon-route.t

=head1 DESCRIPTION

This test covers the C</favicon.ico> surface that every browser requests on its
own for every page load. It asserts that the distribution bundles a real 16x16
32-bit ICO public asset, that the backend serves it with the ICO mime type, that
the request resolves before the authorization gate on every trust tier, that a
layered public root may override the icon, and that the Dancer2 route table
answers the request with the dashboard default security headers rather than
letting it fall through to the catch-all 404.

=head1 PURPOSE

Its purpose is to keep the automatic browser icon request out of the error log.
Before this gate the route table had no handler for C</favicon.ico>, so every
page load produced a console 404 on the admin and read-only tiers and a 401
followed by a 404 on the helper tier.

=head1 WHY IT EXISTS

It exists because the defect was invisible to the rest of the suite: no test
requested the path a browser requests implicitly, and the catch-all route made
the miss look like ordinary "not found" behavior instead of a missing asset. It
also exists to pin the pre-authorization placement, which is easy to lose in a
later refactor of the route table.

=head1 WHEN TO USE

Use this file when changing the bundled public asset tree, the layered static
file roots, the authorization placement of unauthenticated routes, or the
Dancer2 route table.

=head1 HOW TO USE

Run it directly with C<prove -lv t/124-favicon-route.t>. It builds its own
throwaway HOME and working directory, so it needs no dashboard runtime state and
leaves none behind.

=head1 WHAT USES IT

The repository test suite runs it through C<prove -lr t>, and the coverage gate
runs it under Devel::Cover together with the rest of the web layer tests.

=head1 EXAMPLES

Example 1:

  prove -lv t/124-favicon-route.t

Run the favicon route gate on its own while iterating on the asset or the route.

Example 2:

  prove -lv t/124-favicon-route.t t/76-web-dancerapp-coverage.t

Run it alongside the Dancer route layer coverage test after a route table edit.

Example 3:

  prove -lv t/124-favicon-route.t t/web_app_static_files.t

Run it alongside the static asset test after changing the public asset roots.

Example 4:

  prove -lr t

Put the whole suite back through the default correctness gate before release.

=cut
