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
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

# ---------------------------------------------------------------------------
# Minimal action runner stub so _action_response can be driven without the real
# ActionRunner (which would need on-disk action definitions).
# ---------------------------------------------------------------------------
{

    package T118::Actions;

    # new()
    # Builds the stub page-action runner used by this test.
    # Input: class name.
    # Output: blessed stub object.
    sub new { return bless {}, shift }

    # run_page_action(%args)
    # Pretends to execute one page action and returns a fixed body payload.
    # Input: action, page, params, and source key/value pairs.
    # Output: hash reference with body and content_type.
    sub run_page_action {
        my ( $self, %args ) = @_;
        return { body => 'stub-action-body', content_type => 'text/plain; charset=utf-8' };
    }
}

# ---------------------------------------------------------------------------
# Page resolver stub that hands back a nav page carrying no meta source_kind, so
# the `source_kind || 'saved'` fallback inside the nav renderer is exercised.
# ---------------------------------------------------------------------------
{

    package T118::Resolver;

    # new()
    # Builds the stub page resolver used by this test.
    # Input: class name.
    # Output: blessed stub object.
    sub new { return bless {}, shift }

    # load_named_page($id)
    # Returns a fresh page document with no source_kind metadata.
    # Input: saved page id string.
    # Output: Developer::Dashboard::PageDocument object.
    sub load_named_page {
        my ( $self, $id ) = @_;
        return Developer::Dashboard::PageDocument->new(
            id     => $id,
            title  => 'Kindless Nav',
            layout => { body => '<div id="kindless-nav">Kindless Nav</div>' },
        );
    }
}

# Hermetic runtime rooted in a throwaway HOME; config resolves from the CWD's
# deepest .developer-dashboard layer, so we must chdir into the temp home.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{USER} = 'coverage-user';
delete local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS};
delete local $ENV{DEVELOPER_DASHBOARD_SSL_PROXIED};
chdir $home or die "Unable to chdir to $home: $!";

my $paths    = Developer::Dashboard::PathRegistry->new( home => $home );
my $files    = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $store    = Developer::Dashboard::PageStore->new( paths => $paths );
my $config   = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $auth     = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
my $runtime  = Developer::Dashboard::PageRuntime->new( paths => $paths );

# build_app(%extra)
# Builds one web application object over the shared hermetic runtime stack.
# Input: extra constructor key/value pairs merged over the defaults.
# Output: Developer::Dashboard::Web::App object.
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

# write_file($path, $content)
# Writes one fixture file, creating its parent directory first.
# Input: absolute path string and file content string.
# Output: 1 on success.
sub write_file {
    my ( $path, $content ) = @_;
    make_path( ( File::Spec->splitpath($path) )[1] );
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return 1;
}

# ---------------------------------------------------------------------------
# Fixtures: one ordinary saved page, one saved nav bookmark, and one non-.tt
# file sitting beside it inside the nav directory.
# ---------------------------------------------------------------------------
my $welcome = Developer::Dashboard::PageDocument->new(
    id     => 'welcome',
    title  => 'Welcome',
    layout => { body => '<p>Welcome body</p>' },
);
$store->save_page($welcome);

my $nav_bookmark = Developer::Dashboard::PageDocument->new(
    id     => 'nav/one.tt',
    title  => 'Nav One',
    layout => { body => '<div id="nav-one">Nav One</div>' },
);
$store->save_page($nav_bookmark);

my $nav_root = File::Spec->catdir( $paths->dashboards_root, 'nav' );
write_file( File::Spec->catfile( $nav_root, 'notes.txt' ), "plain notes, not a template\n" );
ok( -f File::Spec->catfile( $nav_root, 'notes.txt' ), 'nav directory holds a non-template sibling file' );
ok( -f File::Spec->catfile( $nav_root, 'one.tt' ),    'nav directory holds the saved nav template' );

my $saved_welcome = $store->load_saved_page('welcome');

# ---------------------------------------------------------------------------
# 1. Nav rendering with a runtime context: the nav scan must skip the non-.tt
#    sibling (the `l && !r` side of the entry filter) while still rendering the
#    real nav template, and the request context host/params sides are taken.
# ---------------------------------------------------------------------------
{
    my $app = build_app();
    $app->{_current_request_context} = { host => 'host.example', remote_addr => '127.0.0.1' };
    my $html = $app->_nav_items_html(
        page            => $saved_welcome,
        runtime_context => { params => { extra => 'yes' }, current_page => '/app/welcome' },
    );
    like( $html, qr/dashboard-nav-items/, 'nav renderer emits a nav container for the saved nav template' );
    like( $html, qr/nav-one/,             'nav renderer includes the saved nav template body' );
    unlike( $html, qr/notes\.txt/, 'nav renderer skips the non-template sibling file in the nav directory' );
}

# ---------------------------------------------------------------------------
# 2. Nav rendering with no runtime context at all and no request context, over a
#    resolver that returns a page without source_kind metadata. This drives the
#    `runtime_context || {}`, `host || ''`, and `source_kind || 'saved'`
#    fallbacks together.
# ---------------------------------------------------------------------------
{
    my $app = build_app( resolver => T118::Resolver->new );
    my $html = $app->_nav_items_html( page => $saved_welcome );
    like( $html, qr/kindless-nav/, 'nav renderer defaults the runtime context, host, and source kind' );
}

# ---------------------------------------------------------------------------
# 3. Page action dispatch: a page whose actions list is present exercises the
#    hash/non-hash and id/no-id sides, and a page whose actions list is missing
#    entirely exercises the empty-list deref fallback.
# ---------------------------------------------------------------------------
{
    my $app = build_app( actions => T118::Actions->new );

    my $acted = Developer::Dashboard::PageDocument->new(
        id      => 'acted',
        title   => 'Acted',
        layout  => { body => '<p>acted</p>' },
        actions => [ 'not-a-hash', { builtin => 'no-id-here' }, { id => 'go', builtin => 'page.state' } ],
    );
    my $hit = $app->_action_response( page => $acted, id => 'go', source => 'saved', params => {} );
    is( $hit->[0], 200,               'action response runs the matching action' );
    is( $hit->[2], 'stub-action-body', 'action response returns the runner body' );

    my $actionless = Developer::Dashboard::PageDocument->new(
        id     => 'actionless',
        title  => 'Actionless',
        layout => { body => '<p>actionless</p>' },
    );
    $actionless->{actions} = undef;
    my $miss = $app->_action_response( page => $actionless, id => 'go', source => 'saved', params => {} );
    is( $miss->[0], 404, 'action response 404s when the page carries no actions list at all' );
    like( $miss->[2], qr/Action not found/, 'action response explains the missing action' );
}

# ---------------------------------------------------------------------------
# 4. Top-right context line: all three helper-tier/username combinations.
# ---------------------------------------------------------------------------
{
    my $app = build_app();

    my $admin = Developer::Dashboard::PageDocument->new( id => 'ctx-admin', title => 'A', layout => { body => 'b' } );
    $admin->{meta}{request_context} = { tier => 'admin', username => 'ignored', host => 'host.example' };
    like( $app->_top_context_html($admin), qr/coverage-user/, 'top context uses the environment user for a non-helper tier' );

    my $nameless = Developer::Dashboard::PageDocument->new( id => 'ctx-nameless', title => 'N', layout => { body => 'b' } );
    $nameless->{meta}{request_context} = { tier => 'helper', username => '', host => 'host.example' };
    like( $app->_top_context_html($nameless), qr/coverage-user/, 'top context falls back to the environment user for a nameless helper' );

    my $helper = Developer::Dashboard::PageDocument->new( id => 'ctx-helper', title => 'H', layout => { body => 'b' } );
    $helper->{meta}{request_context} = { tier => 'helper', username => 'alice', host => 'host.example:8080' };
    like( $app->_top_context_html($helper), qr/alice/, 'top context uses the helper username when one is present' );
}

# ---------------------------------------------------------------------------
# 5. Editor HTML: the form action always resolves through _page_route_urls.
# ---------------------------------------------------------------------------
{
    my $app  = build_app();
    my $html = $app->_edit_html($saved_welcome);
    like( $html, qr{action="/app/welcome/edit"}, 'edit html posts back to the saved page edit route' );
}

# ---------------------------------------------------------------------------
# 6. Static serving from an explicit absolute root resolves the candidate path.
# ---------------------------------------------------------------------------
{
    my $app        = build_app();
    my $static_dir = File::Spec->catdir( $home, 'static-root' );
    write_file( File::Spec->catfile( $static_dir, 'probe.js' ), "var probe = 1;\n" );
    my $served = $app->_serve_static_file_from_roots( 'js', 'probe.js', $static_dir );
    is( $served->[0], 200, 'static serving returns the file found under the absolute root' );
    like( $served->[2], qr/var probe/, 'static serving returns the file body' );
}

done_testing;

__END__

=pod

=head1 NAME

t/118-web-app-coverage-3.t - branch and condition closure for the browser web application builder

=head1 PURPOSE

This test closes the last uncovered branch and condition sides in the
browser-facing web application response builder. It drives the nav-fragment
scanner over a nav directory that mixes templates with an unrelated plain file,
renders nav items both with and without a runtime context, dispatches a page
action for a page whose actions list is missing entirely, and walks every
helper-tier permutation of the top-right context line.

=head1 WHY IT EXISTS

The repository requires one hundred percent coverage on every coverage metric,
including branch and condition, and the web application builder is the largest
module in the tree. The sides collected here are only reachable through
deliberately awkward inputs: a nav directory entry that is neither a dot entry
nor a template, a nav page loaded through an injected resolver that omits source
metadata, a page document whose actions key is undefined rather than an empty
list, and a request context that names a helper tier without a username. Without
a dedicated file those sides drift back to uncovered whenever the surrounding
routes are refactored.

=head1 WHEN TO USE

Use this file when changing nav fragment discovery or rendering, page action
dispatch, the top-right user and host context line, the editor HTML form target,
or static asset resolution inside the web application builder.

=head1 HOW TO USE

Run C<prove -lv t/118-web-app-coverage-3.t> while iterating. For the coverage
gate, run the suite under Devel::Cover and confirm the web application builder
still reports one hundred percent on statement, subroutine, branch, and
condition.

=head1 WHAT USES IT

The repository test suite and the coverage gate use this file. Developers
touching the web response builder use it as the fast feedback loop for the
awkward fallback paths that ordinary route tests never reach.

=head1 EXAMPLES

Example 1:

  prove -lv t/118-web-app-coverage-3.t

Run this branch and condition closure file on its own.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Run it inside the full suite while collecting coverage for the release gate.

=cut
