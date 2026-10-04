#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL overrides must exist before the modules under test are
# compiled. They fail only for exact paths registered in %FAIL, so the I/O error
# branches run deterministically for any uid (a chmod-unreadable file is still
# readable for root). exec is faked on request so the exec-succeeded branch,
# which never returns in real life, can be exercised too.
our ( %FAIL, $EXEC_FAKE );

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL{ $_[2] } ) {
            $! = 13;
            return 0;
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && $FAIL{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };
    *CORE::GLOBAL::exec = sub (@) {
        return 1 if $EXEC_FAKE;
        no warnings;
        return CORE::exec(@_);
    };
}

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::SkillManager;
use Developer::Dashboard::Zipper;

sub write_file {
    my ( $path, $text ) = @_;
    my $dir = ( File::Spec->splitpath($path) )[1];
    make_path($dir) if !-d $dir;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $text;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

sub fails_with {
    my ( $path, $code, $pattern, $name ) = @_;
    local $FAIL{$path} = 1;
    my $result = eval { $code->(); 1 };
    my $error  = $@;
    ok( !$result && $error =~ $pattern, $name ) or diag $error;
    return;
}

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

# Zipper: Template->new failure and unreadable saved ajax file.
{
    no warnings qw(redefine once);
    local *Template::new = sub { return undef };
    eval { Developer::Dashboard::Zipper::_render_ajax_code_template( 'x', {} ) };
    like( $@, qr/Unable to initialise Ajax code template renderer/, 'a failing Template->new is reported' );
}
{
    my $root = File::Spec->catdir( $home, 'runtime' );
    my $file = Developer::Dashboard::Zipper::saved_ajax_file_path( runtime_root => $root, file => 'a.pl' );
    write_file( $file, "print 1;\n" );
    is( Developer::Dashboard::Zipper::load_saved_ajax_code( runtime_root => $root, file => 'a.pl' ), "print 1;\n", 'a readable saved ajax file loads' );
    fails_with( $file, sub { Developer::Dashboard::Zipper::load_saved_ajax_code( runtime_root => $root, file => 'a.pl' ) },
        qr/Unable to read \Q$file\E/, 'an unreadable saved ajax file dies' );
}

# SkillDispatcher fixtures.
my $skill = File::Spec->catdir( $home, '.developer-dashboard', 'skills', 'mk' );
write_file( File::Spec->catfile( $skill, 'cli', 'go' ), "#!/bin/sh\necho go\n" );
write_file( File::Spec->catfile( $skill, 'cli', 'go.d', '01-h' ), "#!/bin/sh\necho hook\n" );
chmod 0755, File::Spec->catfile( $skill, 'cli', 'go' ), File::Spec->catfile( $skill, 'cli', 'go.d', '01-h' );
write_file( File::Spec->catfile( $skill, 'config', 'config.json' ), '{"a":1}' );
write_file( File::Spec->catfile( $skill, 'dashboards', 'index' ), "TITLE: x\n:--------------------------------------------------------------------------------:\nHTML: hi\n" );
write_file( File::Spec->catfile( $skill, 'dashboards', 'nav', 'a.tt' ), "nav\n" );
write_file( File::Spec->catfile( $skill, '.env' ), "VERSION=1.0\n" );
write_file( File::Spec->catfile( $skill, 'config', 'routes.json' ), '{"version":1}' );
make_path( File::Spec->catdir( $skill, 'skills', 'child' ) );
write_file( File::Spec->catfile( $home, '.developer-dashboard', 'config', 'routes.json' ), '{"version":1}' );

my $paths      = Developer::Dashboard::PathRegistry->new( home => $home );
my $manager    = Developer::Dashboard::SkillManager->new( paths => $paths );
my $dispatcher = Developer::Dashboard::SkillDispatcher->new( manager => $manager );

my $hooks_dir = File::Spec->catdir( $skill, 'cli', 'go.d' );
fails_with( $hooks_dir, sub { $dispatcher->execute_hooks( 'mk', 'go' ) }, qr/Unable to read \Q$hooks_dir\E/, 'execute_hooks dies on an unreadable hooks dir' );
fails_with( $hooks_dir, sub { $dispatcher->_execute_hooks_streaming( 'mk', 'go', [$skill] ) }, qr/Unable to read \Q$hooks_dir\E/, 'streaming hooks die on an unreadable hooks dir' );
fails_with( $hooks_dir, sub { $dispatcher->command_hook_paths( 'mk', 'go' ) }, qr/Unable to read \Q$hooks_dir\E/, 'command_hook_paths dies on an unreadable hooks dir' );
is_deeply( [ map { ( File::Spec->splitpath($_) )[2] } $dispatcher->command_hook_paths( 'mk', 'go' ) ], ['01-h'], 'command_hook_paths lists the readable hook' );

my $devnull = File::Spec->devnull();
fails_with(
    $devnull,
    sub { $dispatcher->_run_child_command_streaming( command => ['true'], args => [], stdin_mode => 'null' ) },
    qr/Unable to open \Q$devnull\E for streaming/,
    'a null stdin that cannot open dies'
);

# Config, page, version, routes, and directory walkers.
my $config_file = File::Spec->catfile( $skill, 'config', 'config.json' );
is_deeply( $dispatcher->get_skill_config('mk'), { a => 1 }, 'config loads' );
{
    local $FAIL{$config_file} = 1;
    is_deeply( $dispatcher->get_skill_config('mk'), {}, 'an unreadable config yields an empty hash' );
}

my $page_file = File::Spec->catfile( $skill, 'dashboards', 'index' );
fails_with( $page_file, sub { $dispatcher->_load_skill_page( skill_name => 'mk', route_id => 'index' ) }, qr/Unable to read \Q$page_file\E/, 'an unreadable skill page dies' );

my $env_file = File::Spec->catfile( $skill, '.env' );
{
    local $FAIL{$env_file} = 1;
    like( $dispatcher->_native_version_fallback('mk')->{stdout}, qr/no version number found/, 'an unreadable .env is skipped' );
}
write_file( $env_file, '' );
like( $dispatcher->_native_version_fallback('mk')->{stdout}, qr/no version number found/, 'an empty .env has no version' );
write_file( $env_file, "VERSION=1.0\n" );
like( $dispatcher->_native_version_fallback('mk')->{stdout}, qr/1\.0/, 'a .env with a version reports it' );

my $routes_file = File::Spec->catfile( $skill, 'config', 'routes.json' );
fails_with( $routes_file, sub { $dispatcher->_load_skill_routes_file($routes_file) }, qr/Unable to read \Q$routes_file\E/, 'an unreadable routes file dies' );
is_deeply( $dispatcher->_load_skill_routes_file($routes_file)->{app} || {}, {}, 'a routes file with no kinds loads' );

is_deeply( [ $dispatcher->_runtime_custom_route_specs ], [], 'a runtime routes file without kinds yields no specs' );
is_deeply( $dispatcher->_skill_routes_for( 'mk', 'app' ), {}, 'a skill routes file without the kind yields no routes' );

write_file( File::Spec->catfile( $home, '.developer-dashboard', 'config', 'routes.json' ), '{"/rt-foo":"/app/rtfoo"}' );
write_file( $routes_file, '{"/mk-foo":"/app/foo"}' );
is( scalar( () = $dispatcher->_runtime_custom_route_specs ), 1, 'a runtime routes file with an app route yields one spec' );
is_deeply( [ keys %{ $dispatcher->_skill_routes_for( 'mk', 'app' ) } ], ['foo'], 'a skill routes file with an app route yields it' );

my $dash_root = File::Spec->catdir( $skill, 'dashboards' );
fails_with( $dash_root, sub { $dispatcher->_skill_bookmark_entries('mk') }, qr/Unable to read \Q$dash_root\E/, 'bookmark enumeration dies on an unreadable dashboards dir' );
is_deeply( [ $dispatcher->_skill_bookmark_entries('mk') ], ['index'], 'bookmark enumeration lists index' );

my $nested_root = File::Spec->catdir( $skill, 'skills' );
fails_with( $nested_root, sub { $dispatcher->_descendant_skill_names( 'mk', $skill ) }, qr/Unable to read \Q$nested_root\E/, 'nested skill walk dies on an unreadable dir' );
is_deeply( [ $dispatcher->_descendant_skill_names( 'mk', $skill ) ], [ 'mk', 'mk/child' ], 'nested skill walk lists children' );

my $nav_root = File::Spec->catdir( $skill, 'dashboards', 'nav' );
fails_with( $nav_root, sub { $dispatcher->_relative_files($nav_root) }, qr/Unable to read \Q$nav_root\E/, 'relative file walk dies on an unreadable dir' );
is_deeply( [ $dispatcher->_relative_files($nav_root) ], ['a.tt'], 'relative file walk lists nav files' );

# A faked successful exec falls through. Only one exec is exercised per process
# because Devel::Cover stops recording after the first exec; the failing exec
# is covered by the other skill tests.
{
    local $EXEC_FAKE = 1;
    ok( !$dispatcher->_exec_replacement( ['true'], [] ), 'an exec that hands off falls through without an error string' );
}

done_testing;

__END__

=pod

=head1 NAME

t/560-skilldispatcher-zipper-io-coverage.t - covers the I/O failure branches of SkillDispatcher and Zipper

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It injects open, opendir, Template and exec failures for exact registered paths so the error branches in Developer::Dashboard::SkillDispatcher and Developer::Dashboard::Zipper run for any uid.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate must be met without any C<# uncoverable> annotations, and chmod-based unreadable files do not fail when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change directory walking, config loading, page loading, hook execution or exec handoff in SkillDispatcher, or the saved-ajax loader in Zipper.

=head1 HOW TO USE

Run it directly with C<prove -lv t/560-skilldispatcher-zipper-io-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification.

=head1 EXAMPLES

Example 1:

  prove -lv t/560-skilldispatcher-zipper-io-coverage.t

Run this coverage-gap test by itself while editing SkillDispatcher.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/560-skilldispatcher-zipper-io-coverage.t

Confirm the I/O failure branches are reported as covered.

=cut
