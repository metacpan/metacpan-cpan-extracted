#!/usr/bin/env perl

use strict;
use warnings;
use Errno qw(EACCES EIO);

# The CORE::GLOBAL overrides must exist before the modules under test are
# compiled. Each one fails only for an exact registered path (or for the next
# close/flock while a flag is set), so the failure runs deterministically for
# any uid, including root where chmod-based failures never happen.
our ( %FAIL_OPEN, %FAIL_OPENDIR, %FAIL_UNLINK, $FAIL_CLOSEDIR, $FAIL_CLOSE, $FAIL_FLOCK, $FAKE_GETPWUID );

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL_OPEN{ $_[2] } ) {
            $! = $FAIL_OPEN{ $_[2] } == 1 ? EACCES : $FAIL_OPEN{ $_[2] };
            return 0;
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && $FAIL_OPENDIR{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };
    *CORE::GLOBAL::closedir = sub (*) {
        my ($handle) = @_;
        if ($FAIL_CLOSEDIR) {
            $FAIL_CLOSEDIR = 0;
            $! = 5;
            return 0;
        }
        return CORE::closedir($handle);
    };
    *CORE::GLOBAL::unlink = sub (@) {
        my @left = grep { !$FAIL_UNLINK{$_} } @_;
        if ( @left != @_ ) {
            $! = 13;
            return 0;
        }
        return CORE::unlink(@_);
    };
    *CORE::GLOBAL::close = sub (;*) {
        my $handle = @_ ? $_[0] : undef;
        if ( $FAIL_CLOSE && ref $handle ) {
            $FAIL_CLOSE = 0;
            CORE::close($handle);
            $! = 5;
            return 0;
        }
        return CORE::close($handle) if ref $handle;
        return @_ ? CORE::close( Symbol::qualify_to_ref( $handle, scalar caller ) ) : CORE::close();
    };
    *CORE::GLOBAL::getpwuid = sub ($) {
        return $FAKE_GETPWUID->( $_[0] ) if $FAKE_GETPWUID;
        return wantarray ? CORE::getpwuid( $_[0] ) : scalar CORE::getpwuid( $_[0] );
    };
    *CORE::GLOBAL::flock = sub (*$) {
        if ($FAIL_FLOCK) {
            $! = 11;
            return 0;
        }
        return CORE::flock( $_[0], $_[1] );
    };
}

use Symbol ();
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Auth;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

sub write_file {
    my ( $path, $content ) = @_;
    CORE::open( my $fh, '>', $path ) or die "Unable to write $path: $!";
    print {$fh} $content;
    CORE::close($fh);
    return $path;
}

# --- Web::App: bundled jQuery close failure --------------------------------
{
    my $ok = eval {
        local $FAIL_CLOSE = 1;
        Developer::Dashboard::Web::App->jquery_js_response;
        1;
    };
    ok( !$ok, 'jquery_js_response dies when the asset handle cannot be closed' );
    like( $@, qr/Unable to close .*jquery/, 'jquery close failure names the asset' );
}

# --- Web::App: static file open failure -------------------------------------
{
    my $root = File::Spec->catdir( $home, 'public' );
    make_path($root);
    my $file = write_file( File::Spec->catfile( $root, 'a.js' ), 'var a = 1;' );
    my $store = Developer::Dashboard::PageStore->new( paths => $paths );
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $app   = Developer::Dashboard::Web::App->new(
        auth     => Developer::Dashboard::Auth->new( files => $files, paths => $paths ),
        pages    => $store,
        runtime  => Developer::Dashboard::PageRuntime->new( paths => $paths ),
        sessions => Developer::Dashboard::SessionStore->new( paths => $paths ),
    );
    is( $app->_serve_static_file_at_path( 'js', 'a.js', $file, '', [$root] )->[0], 200, 'a readable static file is served' );
    local $FAIL_OPEN{$file} = 1;
    is( $app->_serve_static_file_at_path( 'js', 'a.js', $file, '', [$root] )->[0], 404, 'a permission-denied static file open is indistinguishable from a missing file' );
    delete $FAIL_OPEN{$file};
    local $FAIL_OPEN{$file} = EIO;
    is( $app->_serve_static_file_at_path( 'js', 'a.js', $file, '', [$root] )->[0], 500, 'an unexpected static file open failure remains a 500' );
    delete $FAIL_OPEN{$file};

    # --- Web::App: unreadable nav directory --------------------------------
    my $nav_root = File::Spec->catdir( $paths->dashboards_root, 'nav' );
    make_path($nav_root);
    write_file( File::Spec->catfile( $nav_root, 'x.tt' ), "TITLE: X\n:--------------------------------------------------------------------------------:\nBOOKMARK: nav/x.tt\n:--------------------------------------------------------------------------------:\nHTML: <b>nav-x</b>\n" );
    my $page = Developer::Dashboard::PageDocument->new( id => 'p', title => 'P', layout => { body => 'b' } );
    my $html = $app->_nav_items_html( page => $page, runtime_context => { params => {} } );
    like( $html, qr/nav-x/, 'readable nav directories contribute fragments' );
    local $FAIL_OPENDIR{$nav_root} = 1;
    my $html_with_unopenable_root = $app->_nav_items_html( page => $page, runtime_context => { params => {} } );
    unlike( $html_with_unopenable_root, qr/nav-x/, 'an unopenable nav directory is skipped while other runtime layers may still contribute nav entries' );
}

# --- Prompt: explicit Git metadata I/O failures ---------------------------
{
    my $prompt = bless {}, 'Developer::Dashboard::Prompt';
    my $git_dir = File::Spec->catdir( $home, 'prompt-git' );
    my $origin  = File::Spec->catdir( $git_dir, 'refs', 'remotes', 'origin' );
    my $ref     = File::Spec->catfile( $git_dir, 'refs', 'heads', 'main' );
    my $origin_ref = File::Spec->catfile( $origin, 'main' );
    my $packed  = File::Spec->catfile( $git_dir, 'packed-refs' );
    my $commit  = '0123456789abcdef0123456789abcdef01234567';
    make_path( $origin, File::Spec->catdir( $git_dir, 'refs', 'heads' ) );
    write_file( $ref, "$commit\n" );
    write_file( $origin_ref, "$commit\n" );

    local $FAIL_OPENDIR{$origin} = 1;
    my $opendir_error = eval { $prompt->_origin_branch_for_commit( $git_dir, $commit ); 1 } ? '' : $@;
    like( $opendir_error, qr/Unable to open .*origin/, 'origin ref directory open failure is reported' );
    delete $FAIL_OPENDIR{$origin};

    local $FAIL_CLOSEDIR = 1;
    my $closedir_error = eval { $prompt->_origin_branch_for_commit( $git_dir, $commit ); 1 } ? '' : $@;
    like( $closedir_error, qr/Unable to close .*origin/, 'origin ref directory close failure is reported' );

    local $FAIL_OPEN{$origin_ref} = 1;
    my $origin_ref_open_error = eval { $prompt->_origin_branch_for_commit( $git_dir, $commit ); 1 } ? '' : $@;
    like( $origin_ref_open_error, qr/Unable to open .*main/, 'origin loose ref open failure is reported' );
    delete $FAIL_OPEN{$origin_ref};

    local $FAIL_CLOSE = 1;
    my $origin_ref_close_error = eval { $prompt->_origin_branch_for_commit( $git_dir, $commit ); 1 } ? '' : $@;
    like( $origin_ref_close_error, qr/Unable to close .*main/, 'origin loose ref close failure is reported' );

    local $FAIL_OPEN{$ref} = 1;
    my $ref_open_error = eval { $prompt->_git_ref_commit( $git_dir, 'refs/heads/main' ); 1 } ? '' : $@;
    like( $ref_open_error, qr/Unable to open .*main/, 'loose ref open failure is reported' );
    delete $FAIL_OPEN{$ref};
    delete $FAIL_OPEN{$ref};

    local $FAIL_CLOSE = 1;
    my $ref_close_error = eval { $prompt->_git_ref_commit( $git_dir, 'refs/heads/main' ); 1 } ? '' : $@;
    like( $ref_close_error, qr/Unable to close .*main/, 'loose ref close failure is reported' );

    write_file( $packed, "$commit refs/heads/packed\n" );
    {
        local $FAIL_CLOSE = 1;
        my $packed_match_close_error = eval { $prompt->_git_ref_commit( $git_dir, 'refs/heads/packed' ); 1 } ? '' : $@;
        like( $packed_match_close_error, qr/Unable to close .*packed-refs/, 'packed ref close failure is reported before returning an exact match' );
    }
    local $FAIL_OPEN{$packed} = 1;
    my $packed_open_error = eval { $prompt->_git_ref_commit( $git_dir, 'refs/heads/missing' ); 1 } ? '' : $@;
    like( $packed_open_error, qr/Unable to open .*packed-refs/, 'packed ref open failure is reported' );
    delete $FAIL_OPEN{$packed};

    local $FAIL_CLOSE = 1;
    my $packed_close_error = eval { $prompt->_git_ref_commit( $git_dir, 'refs/heads/missing' ); 1 } ? '' : $@;
    like( $packed_close_error, qr/Unable to close .*packed-refs/, 'packed ref close failure is reported' );

    my $packed_git_dir = File::Spec->catdir( $home, 'prompt-packed-git' );
    my $packed_origin  = File::Spec->catdir( $packed_git_dir, 'refs', 'remotes', 'origin' );
    my $packed_origin_file = File::Spec->catfile( $packed_git_dir, 'packed-refs' );
    make_path($packed_origin);
    write_file( $packed_origin_file, "$commit refs/remotes/origin/main\n" );
    local $FAIL_OPEN{$packed_origin_file} = 1;
    my $origin_packed_open_error = eval { $prompt->_origin_branch_for_commit( $packed_git_dir, $commit ); 1 } ? '' : $@;
    like( $origin_packed_open_error, qr/Unable to open .*packed-refs/, 'packed origin ref open failure is reported' );
    delete $FAIL_OPEN{$packed_origin_file};

    local $FAIL_CLOSE = 1;
    my $origin_packed_close_error = eval { $prompt->_origin_branch_for_commit( $packed_git_dir, $commit ); 1 } ? '' : $@;
    like( $origin_packed_close_error, qr/Unable to close .*packed-refs/, 'packed origin ref close failure is reported' );
}

# --- Web::App: top-right user name fallbacks ---------------------------------
{
    my $app = Developer::Dashboard::Web::App->new(
        auth     => Developer::Dashboard::Auth->new( files => Developer::Dashboard::FileRegistry->new( paths => $paths ), paths => $paths ),
        pages    => Developer::Dashboard::PageStore->new( paths => $paths ),
        runtime  => Developer::Dashboard::PageRuntime->new( paths => $paths ),
        sessions => Developer::Dashboard::SessionStore->new( paths => $paths ),
    );
    my $page = Developer::Dashboard::PageDocument->new( id => 'ctx', title => 'Ctx', layout => { body => 'b' } );
    local $ENV{USER};
    delete $ENV{USER};
    local $FAKE_GETPWUID = sub { return 'pwname' };
    like( $app->_top_context_html($page), qr/pwname/, 'the passwd entry names the user when USER is unset' );
    local $FAKE_GETPWUID = sub { return undef };
    like( $app->_top_context_html($page), qr/&#128129;&#127996; user</, 'the literal user name is the last fallback' );
    local $ENV{USER} = 'envname';
    like( $app->_top_context_html($page), qr/envname/, 'USER wins when present' );
}

# --- PageRuntime: saved-ajax temp file close failure -------------------------
{
    my $path = Developer::Dashboard::PageRuntime::_saved_ajax_temp_file( content => 'x' );
    ok( -f $path, 'the saved ajax temp file is written' );
    unlink $path;
    my $ok = eval {
        local $FAIL_CLOSE = 1;
        Developer::Dashboard::PageRuntime::_saved_ajax_temp_file( content => 'x' );
        1;
    };
    ok( !$ok, 'a temp file that cannot be closed is fatal' );
    like( $@, qr/Unable to close saved ajax temp file/, 'temp file close failure is named' );
}

# --- PageStore: unlink failure, undef read, close failure --------------------
{
    my $store = Developer::Dashboard::PageStore->new( paths => $paths );
    my $root  = $paths->dashboards_root;
    make_path($root);
    my $legacy = write_file(
        File::Spec->catfile( $root, 'legacy.json' ),
        Developer::Dashboard::PageDocument->new( id => 'legacy', title => 'Legacy', layout => { body => 'b' } )->canonical_json,
    );
    local $FAIL_UNLINK{$legacy} = 1;
    my $ok = eval { $store->migrate_legacy_json_pages; 1 };
    ok( !$ok, 'migration dies when the legacy json file cannot be removed' );
    like( $@, qr/Unable to remove/, 'unlink failure names the legacy file' );
    delete $FAIL_UNLINK{$legacy};

    # A directory opens fine but reading it fails, so closing it reports the read error.
    my $ok2 = eval { $store->_read_saved_instruction($root); 1 };
    ok( !$ok2, 'a bookmark that cannot be read to the end is fatal at close' );
    like( $@, qr/Unable to close/, 'bookmark close failure is named' );
}

# --- IndicatorStore: flock failure -------------------------------------------
{
    my $store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
    my $ok = eval {
        local $FAIL_FLOCK = 1;
        $store->set_indicator( 'lockless', status => 'ok' );
        1;
    };
    ok( !$ok, 'set_indicator dies when the lock cannot be taken' );
    like( $@, qr/Unable to lock/, 'lock failure is named' );
}

# --- Prompt: HEAD and .git open failures -------------------------------------
{
    my $prompt = Developer::Dashboard::Prompt->new(
        paths      => $paths,
        indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
    );
    my $repo = File::Spec->catdir( $home, 'repo' );
    make_path( File::Spec->catdir( $repo, '.git' ) );
    my $head = write_file( File::Spec->catfile( $repo, '.git', 'HEAD' ), "ref: refs/heads/main\n" );
    is( $prompt->_git_branch($repo), 'main', 'a readable HEAD yields the branch' );
    local $FAIL_OPEN{$head} = 1;
    is( $prompt->_git_branch($repo), undef, 'a HEAD that cannot be opened yields no branch' );
    delete $FAIL_OPEN{$head};

    my $wt = File::Spec->catdir( $home, 'worktree' );
    make_path($wt);
    my $git_file = write_file( File::Spec->catfile( $wt, '.git' ), "gitdir: $repo/.git\n" );
    is( $prompt->_git_metadata_dir($wt), "$repo/.git", 'a readable .git file resolves its gitdir' );
    local $FAIL_OPEN{$git_file} = 1;
    is( $prompt->_git_metadata_dir($wt), undef, 'a .git file that cannot be opened resolves no metadata dir' );
}

done_testing;

__END__

=pod

=head1 NAME

t/680-io-failure-s7-coverage.t - covers the I/O failure branches of the web app, page runtime, page store, indicator store, and prompt

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It installs BEGIN-time CORE::GLOBAL open, opendir, unlink, close, and flock overrides that fail only for registered paths or flagged calls, then drives each library failure branch (close, open, opendir, unlink, flock) deterministically.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate allows no uncoverable annotations, and chmod-based failures never happen for root, so the failures must be injected rather than provoked through file modes.

=head1 WHEN TO USE

Use this file when you change an open, opendir, unlink, close, or flock failure path in Web::App, PageRuntime, PageStore, IndicatorStore, or Prompt, or when a coverage run reports one of them as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/680-io-failure-s7-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/680-io-failure-s7-coverage.t

Run this coverage-gap test by itself while editing any of the I/O failure paths above.

=cut
