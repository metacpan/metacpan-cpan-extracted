#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# CORE::GLOBAL overrides must exist before the module under test compiles so its
# opendir/open calls can be made to fail for exact registered paths only, which
# keeps the I/O error branches deterministic even when the suite runs as root.
our %FAIL;

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
}

use Test::More;
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::DockerCompose;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

sub mkfile {
    my ( $path, $content ) = @_;
    make_path( dirname($path) ) if !-d dirname($path);
    CORE::open( my $fh, '>', $path ) or die "Unable to write $path: $!";
    print {$fh} ( defined $content ? $content : '' );
    close $fh or die "Unable to close $path: $!";
    return;
}

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
my $repo = File::Spec->catdir( $home, 'projects', 'app' );
make_path( File::Spec->catdir( $repo, '.developer-dashboard' ) );
chdir $repo or die "Unable to chdir to $repo: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    project_roots   => [ File::Spec->catdir( $home, 'projects' ) ],
    workspace_roots => [ File::Spec->catdir( $home, 'projects' ) ],
);
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $docker = Developer::Dashboard::DockerCompose->new( config => $config, paths => $paths );

my $docker_root = File::Spec->catdir( $repo, '.developer-dashboard', 'config', 'docker' );
mkfile( File::Spec->catfile( $docker_root, 'green', 'compose.yml' ), "services:\n  green: {}\n" );

# --- service discovery and development probing defaults --------------------
{
    my @names = $docker->_discover_service_names( project_root => $repo );
    ok( ( grep { $_ eq 'green' } @names ), '_discover_service_names works without a service_map' );

    is( $docker->_service_folder_is_development(), 0, '_service_folder_is_development returns 0 when no service is given' );
    is( $docker->_service_folder_is_development( service => 'green' ), 0, '_service_folder_is_development defaults project_root to the cwd' );
}

# --- unreadable directories are skipped -----------------------------------
{
    my ($root) = grep { -d $_ } $docker->_service_lookup_roots( project_root => $repo, service => '__all__' );
    ok( defined $root, 'a docker lookup root exists to break' );
    local $FAIL{$root} = 1;
    my @names = eval { $docker->_discover_service_names( project_root => $repo ) };
    is( $@, '', '_discover_service_names skips a lookup root that cannot be opened' );
    ok( !( grep { $_ eq 'green' } @names ), 'services under the unreadable root are not listed' );
}

{
    my ($runtime_root) = $paths->runtime_layers;
    my $skills_root = File::Spec->catdir( $runtime_root, 'skills' );
    make_path( File::Spec->catdir( $skills_root, 'one' ) );
    local $FAIL{$skills_root} = 1;
    my @roots = eval { $docker->_installed_skill_docker_roots_for_runtime($runtime_root) };
    is( $@, '', '_installed_skill_docker_roots_for_runtime skips a skills directory that cannot be opened' );
    is_deeply( \@roots, [], 'no skill docker roots are reported for the unreadable skills directory' );
}

# --- toggle marker failures ------------------------------------------------
{
    for my $method (qw(enable_service_development disable_service_development)) {
        ok( !eval { $docker->$method(); 1 } && $@ =~ /Usage: dashboard docker development/, "$method requires a service" );
        ok( !eval { $docker->$method( service => '../escape' ); 1 } && $@ =~ /Refusing service name/, "$method refuses a service name that escapes the docker root" );
    }
    ok( !eval { $docker->_service_development_marker_path(); 1 } && $@ =~ /Missing service/, '_service_development_marker_path requires a service' );
    is( $docker->_service_development_marker_path( service => '../escape' ), undef, '_service_development_marker_path refuses an escaping service' );

    my $fresh = $docker->enable_service_development( service => 'fresh' );
    ok( -f $fresh->{marker}, 'enable_service_development creates the marker and its missing service directory' );
    $docker->disable_service_development( service => 'fresh' );
    ok( !-e $fresh->{marker}, 'disable_service_development removes the marker' );
    my $again = $docker->disable_service_development( service => 'fresh' );
    is( $again->{development}, 0, 'disable_service_development tolerates an already missing marker' );

    my $blocked = $docker->_service_development_marker_path( service => 'blocked' );
    die 'Unable to resolve the home development marker path' if !defined $blocked;
    make_path($blocked);
    ok( !eval { $docker->enable_service_development( service => 'blocked' ); 1 } && $@ =~ /Unable to write/, 'enable_service_development dies when the marker cannot be opened for writing' );
    ok( !eval { $docker->disable_service_development( service => 'blocked' ); 1 } && $@ =~ /Unable to remove/, 'disable_service_development dies when the marker cannot be unlinked' );

    my $disabled_dir = File::Spec->catfile( $docker_root, 'stuck', 'disabled.yml' );
    make_path($disabled_dir);
    ok( !eval { $docker->enable_service( service => 'stuck' ); 1 } && $@ =~ /Unable to remove/, 'enable_service dies when the disabled marker cannot be unlinked' );

    ok( !eval { $docker->_remove_service_layer_markers( marker_name => 'develop.yml' ); 1 } && $@ =~ /Missing service/,
        '_remove_service_layer_markers requires a service name' );
    ok( !eval { $docker->_remove_service_layer_markers( service => 'green' ); 1 } && $@ =~ /Missing service marker name/,
        '_remove_service_layer_markers requires a marker name' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::DockerCompose::_service_lookup_roots = sub { return ($docker_root) };
        ok( !eval {
                $docker->_remove_service_layer_markers(
                    service     => '../escape',
                    marker_name => 'develop.yml',
                );
                1;
            }
            && $@ =~ /Refusing service name/,
            '_remove_service_layer_markers rejects service paths outside the config root' );
    }

    my $removable = File::Spec->catfile( $docker_root, 'removable', 'develop.yml' );
    mkfile( $removable, "development: 1\n" );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::DockerCompose::_service_lookup_roots = sub { return ($docker_root) };
        cmp_ok(
            $docker->_remove_service_layer_markers(
                project_root => $repo,
                service      => 'removable',
                marker_name  => 'develop.yml',
            ),
            '>=', 1,
            '_remove_service_layer_markers unlinks existing markers in discovered layers',
        );
    }
    ok( !-e $removable, 'existing development marker was removed' );

    my $link_target = File::Spec->catfile( $docker_root, 'removable-link', 'target' );
    my $link_marker = File::Spec->catfile( $docker_root, 'removable-link', 'develop.yml' );
    make_path( dirname($link_marker) );
    symlink $link_target, $link_marker or die "Unable to create marker symlink $link_marker: $!";
    {
        no warnings 'redefine';
        local *Developer::Dashboard::DockerCompose::_service_lookup_roots = sub { return ($docker_root) };
        is(
            $docker->_remove_service_layer_markers(
                project_root => $repo,
                service      => 'removable-link',
                marker_name  => 'develop.yml',
            ),
            1,
            '_remove_service_layer_markers unlinks marker symlinks without following them',
        );
    }
    ok( !-l $link_marker && !-e $link_target, 'dangling marker symlink is removed without following its target' );
}

chdir '/';
done_testing;

__END__

=head1 NAME

t/361-dockercompose-coverage.t - branch and condition coverage for DockerCompose

=head1 DESCRIPTION

Covers the remaining Developer::Dashboard::DockerCompose paths: service
discovery without a service map, development probing defaults, unreadable
directories (injected through CORE::GLOBAL opendir), and the development and
disabled marker toggles (missing service, escaping service name, marker parent
creation, unwritable marker, unlinkable marker, already-missing marker).

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It closes the remaining Devel::Cover branch, condition and statement gaps for: branch and condition coverage for DockerCompose.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/361-dockercompose-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/361-dockercompose-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/361-dockercompose-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
