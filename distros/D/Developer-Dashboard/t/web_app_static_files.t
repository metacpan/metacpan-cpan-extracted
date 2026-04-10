#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(cwd);
use lib 'lib';
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;

# Test the static files serving functionality
BEGIN {
    use_ok('Developer::Dashboard::Web::App');
}

# Create mock app for testing
sub create_mock_app {
    my %args = @_;
    return bless \%args, 'Developer::Dashboard::Web::App';
}

# Test: _get_content_type for JavaScript
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('js', 'script.js');
    is($ct, 'application/javascript; charset=utf-8', 'JS content type correct');
}

# Test: _get_content_type for CSS
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('css', 'style.css');
    is($ct, 'text/css; charset=utf-8', 'CSS content type correct');
}

# Test: _get_content_type for JSON
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('others', 'data.json');
    is($ct, 'application/json; charset=utf-8', 'JSON content type correct');
}

# Test: _get_content_type for XML
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('others', 'config.xml');
    is($ct, 'application/xml; charset=utf-8', 'XML content type correct');
}

# Test: _get_content_type for PNG
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('others', 'image.png');
    is($ct, 'image/png', 'PNG content type correct');
}

# Test: _get_content_type for JPEG
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('others', 'photo.jpg');
    is($ct, 'image/jpeg', 'JPEG content type correct');
}

# Test: _get_content_type for GIF
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('others', 'animation.gif');
    is($ct, 'image/gif', 'GIF content type correct');
}

# Test: _get_content_type for WebP
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('others', 'image.webp');
    is($ct, 'image/webp', 'WebP content type correct');
}

# Test: _get_content_type for SVG
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('others', 'icon.svg');
    is($ct, 'image/svg+xml', 'SVG content type correct');
}

# Test: _get_content_type for ICO
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('others', 'favicon.ico');
    is($ct, 'image/x-icon', 'ICO content type correct');
}

# Test: _get_content_type for HTML
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('others', 'index.html');
    is($ct, 'text/html; charset=utf-8', 'HTML content type correct');
}

# Test: _get_content_type for unknown
{
    my $app = create_mock_app();
    my $ct = $app->_get_content_type('others', 'unknown.xyz');
    is($ct, 'application/octet-stream', 'Unknown content type is octet-stream');
}

# Test: _serve_static_file with directory traversal (security)
{
    my $app = create_mock_app();
    my $response = $app->_serve_static_file('js', '../../../etc/passwd');
    is($response->[0], 400, 'Directory traversal blocked');
}

# Test: _serve_static_file with nonexistent file
{
    my $app = create_mock_app();
    my $response = $app->_serve_static_file('js', 'nonexistent.js');
    is($response->[0], 404, 'Nonexistent file returns 404');
}

# Test: built-in jquery shim route exists for bookmark compatibility
{
    local $ENV{HOME} = tempdir(CLEANUP => 1);
    my $paths = Developer::Dashboard::PathRegistry->new(home => $ENV{HOME});
    my $store = Developer::Dashboard::PageStore->new(paths => $paths);
    my $app = create_mock_app( pages => $store );
    my $response = $app->jquery_js_response();
    is($response->[0], 200, 'built-in jquery shim returns 200');
    is($response->[1], 'application/javascript; charset=utf-8', 'built-in jquery shim returns javascript content type');
    like($response->[2], qr/window\.jQuery = \$;/, 'built-in jquery shim exposes window.jQuery');
    like($response->[2], qr/\$\.ajax = function/, 'built-in jquery shim exposes ajax support');
}

# Test: static_file_response routes the jquery compatibility alias through the built-in shim
{
    local $ENV{HOME} = tempdir(CLEANUP => 1);
    my $paths = Developer::Dashboard::PathRegistry->new(home => $ENV{HOME});
    my $store = Developer::Dashboard::PageStore->new(paths => $paths);
    my $app = create_mock_app( pages => $store );
    my $response = $app->static_file_response( type => 'js', file => 'jquery-4.0.0.min.js' );
    is($response->[0], 200, 'jquery compatibility alias returns 200');
    like($response->[1], qr/application\/javascript/, 'jquery compatibility alias returns javascript content');
    like($response->[2], qr/window\.jQuery = \$;/, 'jquery compatibility alias reuses the built-in jquery shim');
}


# Test: _serve_static_file resolves runtime-root dashboard/public assets
{
    local $ENV{HOME} = tempdir(CLEANUP => 1);
    my $paths = Developer::Dashboard::PathRegistry->new(home => $ENV{HOME});
    my $store = Developer::Dashboard::PageStore->new(paths => $paths);
    my $public_dir = File::Spec->catdir( $paths->runtime_root, 'dashboard', 'public', 'js' );
    mkdir File::Spec->catdir( $paths->runtime_root, 'dashboard' ) or die $! if !-d File::Spec->catdir( $paths->runtime_root, 'dashboard' );
    mkdir File::Spec->catdir( $paths->runtime_root, 'dashboard', 'public' ) or die $! if !-d File::Spec->catdir( $paths->runtime_root, 'dashboard', 'public' );
    mkdir $public_dir or die $! if !-d $public_dir;
    my $test_file = File::Spec->catfile($public_dir, 'test.js');
    open my $fh, '>', $test_file or die "Cannot create test file: $!";
    print {$fh} 'console.log("runtime");';
    close $fh;

    my $app = create_mock_app( pages => $store );
    my $response = $app->_serve_static_file('js', 'test.js');
    is($response->[0], 200, 'runtime public file returns 200');
    is($response->[1], 'application/javascript; charset=utf-8', 'runtime public file keeps javascript content type');
    is($response->[2], 'console.log("runtime");', 'runtime public file content is served');
}

# Test: _serve_static_file resolves dashboards/public assets
{
    local $ENV{HOME} = tempdir(CLEANUP => 1);
    my $paths = Developer::Dashboard::PathRegistry->new(home => $ENV{HOME});
    my $store = Developer::Dashboard::PageStore->new(paths => $paths);
    my $public_dir = File::Spec->catdir( $paths->dashboards_root, 'public', 'js' );
    mkdir File::Spec->catdir( $paths->dashboards_root, 'public' ) or die $! if !-d File::Spec->catdir( $paths->dashboards_root, 'public' );
    mkdir $public_dir or die $! if !-d $public_dir;
    my $test_file = File::Spec->catfile($public_dir, 'bookmark-local.js');
    open my $fh, '>', $test_file or die "Cannot create test file: $!";
    print {$fh} 'console.log("bookmark-local");';
    close $fh;

    my $app = create_mock_app( pages => $store );
    my $response = $app->_serve_static_file('js', 'bookmark-local.js');
    is($response->[0], 200, 'dashboards public file returns 200');
    is($response->[2], 'console.log("bookmark-local");', 'dashboards public file content is served');
}

done_testing();

__END__

=head1 NAME

web_app_static_files.t - Unit tests for static file serving functionality

=head1 DESCRIPTION

Tests the static file serving functionality added to Developer::Dashboard::Web::App.
Verifies MIME type detection, security checks, and file serving.

=head1 TESTS

- Content type detection for various file types (JS, CSS, JSON, images, etc)
- Directory traversal attack prevention
- 404 handling for missing files
- File content serving

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the local web application and server-facing routes. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the local web application and server-facing routes has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the local web application and server-facing routes, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/web_app_static_files.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/web_app_static_files.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/web_app_static_files.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
