use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More;
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
local $ENV{DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS} = 1;

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

my $nav_alpha = Developer::Dashboard::PageDocument->new(
    id     => 'nav/alpha.tt',
    title  => 'Alpha Nav',
    layout => { body => '[% IF env.current_page == \'/app/index\' %]<div id="nav-alpha">Home Current</div>[% ELSE %]<div id="nav-alpha">Home Other [% env.current_page %]</div>[% END %]' },
);
$store->save_page($nav_alpha);

my $nav_beta = Developer::Dashboard::PageDocument->new(
    id     => 'nav/beta.tt',
    title  => 'Beta Nav',
    layout => { body => '<div id="nav-beta">[% env.current_page %] / [% env.runtime_context.current_page %]</div>' },
);
$store->save_page($nav_beta);

my ($transient_post_code, undef, $transient_post_body) = @{ $app->handle(
    path        => '/',
    method      => 'POST',
    body        => 'instruction=TITLE%3A%20Transient%20Nav%20Test%0A%3A--------------------------------------------------------------------------------%3A%0AHTML%3A%20transient%20body%0A',
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $transient_post_code, 200, 'transient bookmark play source route responds' );
my ($transient_play_url) = $transient_post_body =~ m{<a href="([^"]+)" id="play-url">Play</a>};
ok( $transient_play_url, 'transient bookmark play url extracted from editor response' );
my ($transient_play_query) = $transient_play_url =~ /\?(.*)\z/;
my ($transient_play_code, undef, $transient_play_body) = @{ $app->handle(
    path        => '/',
    query       => $transient_play_query,
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $transient_play_code, 200, 'transient bookmark play route responds' );
like( $transient_play_body, qr/class="dashboard-nav-items"/, 'transient bookmark play renders shared nav output when nav bookmarks exist' );
like( $transient_play_body, qr{<div id="nav-alpha">Home Other /</div>}s, 'transient bookmark play executes nav bookmarks against the root play path' );
like( $transient_play_body, qr{<div id="nav-beta">/ / /</div>}s, 'transient bookmark play exposes root current-page context to nav bookmarks' );

my $named_token = uri_escape( $store->encode_page( Developer::Dashboard::PageDocument->from_instruction(<<'BOOKMARK') ) );
TITLE: Named Bookmark Nav Test
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML: named body
BOOKMARK
my ($named_play_code, undef, $named_play_body) = @{ $app->handle(
    path        => '/',
    query       => "mode=render&token=$named_token",
    remote_addr => '127.0.0.1',
    headers     => { host => '127.0.0.1' },
) };
is( $named_play_code, 200, 'named bookmark token play route responds' );
like( $named_play_body, qr/class="dashboard-nav-items"/, 'named bookmark token play keeps shared nav output' );
like( $named_play_body, qr{<div id="nav-alpha">Home Current</div>}s, 'named bookmark token play evaluates nav bookmarks against the saved bookmark route' );
like( $named_play_body, qr{<div id="nav-beta">/app/index / /app/index</div>}s, 'named bookmark token play exposes the saved bookmark current-page context to nav bookmarks' );

done_testing;

__END__

=head1 NAME

16-bookmark-play-nav.t - verify shared nav bookmark output on play routes

=head1 DESCRIPTION

This test verifies that saved C<nav/*.tt> bookmark fragments still execute and
render during transient play routes, including named bookmark token play where
the effective current-page context must stay aligned with the saved
C</app/E<lt>idE<gt>> route.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Test file in the Developer Dashboard codebase. This file tests bookmark play mode and shared nav rendering behaviour.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/16-bookmark-play-nav.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

  prove -lv t/16-bookmark-play-nav.t

Run that command while working on the behaviour this test owns, then rerun C<prove -lr t> before release.

=for comment FULL-POD-DOC END

=cut
