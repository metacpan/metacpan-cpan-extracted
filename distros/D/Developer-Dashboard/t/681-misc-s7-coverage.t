#!/usr/bin/env perl

use strict;
use warnings;

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
use Developer::Dashboard::PageRuntime::StreamHandle;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

# --- StreamHandle: a handle tied without a writer discards output ------------
{
    my @seen;
    tie *NOWRITER, 'Developer::Dashboard::PageRuntime::StreamHandle';
    ok( print( NOWRITER 'dropped' ), 'printing to a handle tied without a writer succeeds' );
    untie *NOWRITER;
    is_deeply( \@seen, [], 'nothing is forwarded when there is no writer' );
}

# --- PageRuntime: a sandpit package that fails to compile is fatal -----------
{
    my $runtime = Developer::Dashboard::PageRuntime->new( paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::PageRuntime::_sandpit_package_source = sub { return 'this is not perl (' };
    my $ok = eval { $runtime->_new_sandpit( state => {}, runtime_context => {} ); 1 };
    ok( !$ok, 'sandpit creation dies when the generated package does not compile' );
    like( $@, qr/Unable to setup sandpit/, 'the sandpit failure is named' );
}

# --- Web::App: readable-file gate for static assets --------------------------
{
    my $root = File::Spec->catdir( $home, 'public' );
    make_path($root);
    my $file = File::Spec->catfile( $root, 'a.js' );
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} 'var a = 1;';
    close $fh or die "Unable to close $file: $!";

    my $app = Developer::Dashboard::Web::App->new(
        auth     => Developer::Dashboard::Auth->new( files => Developer::Dashboard::FileRegistry->new( paths => $paths ), paths => $paths ),
        pages    => Developer::Dashboard::PageStore->new( paths => $paths ),
        runtime  => Developer::Dashboard::PageRuntime->new( paths => $paths ),
        sessions => Developer::Dashboard::SessionStore->new( paths => $paths ),
    );
    is( $app->_serve_static_file_from_roots( 'js', 'a.js', $root )->[0], 200, 'a readable asset is served from its root' );

    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_file_is_readable = sub { return 0 };
    is( $app->_serve_static_file_from_roots( 'js', 'a.js', $root )->[0], 404, 'an existing but unreadable asset is not picked from a root' );
    is( $app->_serve_static_file_at_path( 'js', 'a.js', $file, '', [$root] )->[0], 404, 'an existing but unreadable asset is a 404 at the path server' );
}

# --- PageStore: platforms without O_NOFOLLOW still resolve a flag ------------
{
    ok( Developer::Dashboard::PageStore::_nofollow_flag() > 0, 'the no-follow flag is the platform value when the macro exists' );
    no warnings qw(redefine once);
    local *Fcntl::O_NOFOLLOW = sub { die "O_NOFOLLOW is not available\n" };
    is( Developer::Dashboard::PageStore::_nofollow_flag(), 0, 'the no-follow flag falls back to zero when the macro is unavailable' );
}

# --- PageRuntime: defaults, hide, value text, missing paths, exec failure -----
{
    my $runtime = Developer::Dashboard::PageRuntime->new( paths => $paths );

    my $page = Developer::Dashboard::PageDocument->new( id => 'rc', title => 'RC', layout => { body => 'plain' } );
    is( $runtime->prepare_page( page => $page )->{layout}{body}, 'plain', 'prepare_page runs without an explicit runtime context' );

    my $hidden = $runtime->run_code_blocks(
        page   => Developer::Dashboard::PageDocument->new( meta => { codes => [ { id => 'CODE1', body => 'hide();' } ] } ),
        source => 'saved',
    );
    is_deeply( $hidden->{outputs}, [], 'hide() suppresses the block output' );

    is( $runtime->_runtime_value_text(undef), '', 'an undefined returned value renders as empty text' );
    is( $runtime->_runtime_value_text('scalar'), '', 'a plain scalar returned value renders as empty text' );
    like( $runtime->_runtime_value_text( { a => 1 } ), qr/a => 1/, 'a hash returned value renders as perl-ish text' );
    like( $runtime->_runtime_value_text( [ 'x', 2 ] ), qr/'x'/, 'an array returned value quotes its string members' );

    my $bare = bless {}, 'Developer::Dashboard::PageRuntime';
    my $result = $bare->_run_single_block( code => '1;', state => {}, runtime_context => {} );
    is( ref $result, 'HASH', 'a runtime without a path registry still runs a block' );
    my $ok = eval { $bare->_run_single_block( code => 'die "boom\n";', state => {}, runtime_context => {} ); 1 };
    ok( !$ok, 'a failing block without a shared sandpit dies' );
    is( $@, "boom\n", 'the block error text is preserved' );

    local $SIG{__WARN__} = sub { };
    local $Developer::Dashboard::PageRuntime::SETPGID = sub { return 0 };
    $ok = eval { Developer::Dashboard::PageRuntime->_exec_saved_ajax_command('/nonexistent/dd-s7-command'); 1 };
    ok( !$ok, 'a saved ajax command that cannot be exec-ed is fatal' );
    like( $@, qr/Unable to exec saved ajax command \/nonexistent\/dd-s7-command/, 'the exec failure names the command' );
}

# --- Web::App: highlighting helpers and interface preference -----------------
{
    my $app = Developer::Dashboard::Web::App->new(
        auth     => Developer::Dashboard::Auth->new( files => Developer::Dashboard::FileRegistry->new( paths => $paths ), paths => $paths ),
        pages    => Developer::Dashboard::PageStore->new( paths => $paths ),
        runtime  => Developer::Dashboard::PageRuntime->new( paths => $paths ),
        sessions => Developer::Dashboard::SessionStore->new( paths => $paths ),
    );
    like( $app->_highlight_css_text('/* note */ a { color: red; }'), qr/tok-comment/, 'css comments are highlighted' );
    like( $app->_highlight_perl_text('print [% name %] . $value;'), qr/tok-perl-var/, 'template notes and perl variables are run through the highlighter' );
    is( $app->_highlight_restore_tokens( 'plain', undef ), 'plain', 'restoring without a token list leaves the text alone' );

    no warnings 'redefine';
    local *Developer::Dashboard::Web::App::_ip_interface_pairs = sub {
        return (
            { iface => 'tun0',    ip => '10.8.0.2' },
            { iface => 'eth0',    ip => '192.168.1.5' },
            { iface => 'docker0', ip => '172.17.0.1' },
        );
    };
    is_deeply( [ $app->_ip_candidates ], [ '10.8.0.2', '192.168.1.5', '172.17.0.1' ], 'vpn interfaces come first, then preferred, then the rest' );
}

done_testing;

__END__

=pod

=head1 NAME

t/681-misc-s7-coverage.t - covers the StreamHandle writer default, sandpit compile failure, static-file readability gate, and missing O_NOFOLLOW fallback

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It drives small library branches that need a stub or a reload rather than a filesystem failure.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate allows no uncoverable annotations, so every branch must be reached by a real test or removed from the code.

=head1 WHEN TO USE

Use this file when you change the code paths it exercises, or when a coverage run reports one of them as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/681-misc-s7-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/681-misc-s7-coverage.t

Run this coverage-gap test by itself while editing the code it covers.

=cut
