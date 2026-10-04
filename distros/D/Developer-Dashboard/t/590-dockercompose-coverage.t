#!/usr/bin/env perl

use strict;
use warnings;

# CORE::GLOBAL overrides must exist before the module under test is compiled.
# Each one fails only for exact registered paths (or a registered path pattern),
# so the failure branches run for any uid, including root.
our ( %FAIL_CLOSE, %FAIL_CHDIR, $FAIL_OPEN_RE, $FAIL_CLOSE_RE );
my %close_handles;

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL_OPEN_RE && $_[2] =~ $FAIL_OPEN_RE ) {
            $! = 13;
            return 0;
        }
        my $rc = @_ == 2 ? CORE::open( $_[0], $_[1] ) : CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
        if ( $rc && @_ >= 3 && defined $_[2] && !ref $_[2]
            && ( $FAIL_CLOSE{"$_[1]|$_[2]"} || ( $FAIL_CLOSE_RE && $_[2] =~ $FAIL_CLOSE_RE ) ) )
        {
            $close_handles{ Scalar::Util::refaddr( $_[0] ) } = 1;
        }
        return $rc;
    };
    *CORE::GLOBAL::close = sub (;*) {
        my $fail = @_ && ref $_[0] && delete $close_handles{ Scalar::Util::refaddr( $_[0] ) };
        my $rc = @_ ? CORE::close( $_[0] ) : CORE::close();
        if ($fail) {
            $! = 5;
            return 0;
        }
        return $rc;
    };
    *CORE::GLOBAL::chdir = sub (;$) {
        if ( @_ && defined $_[0] && $FAIL_CHDIR{ $_[0] } ) {
            $! = 2;
            return 0;
        }
        return @_ ? CORE::chdir( $_[0] ) : CORE::chdir();
    };
}

use Test::More;
use Cwd qw(getcwd);
use Scalar::Util ();
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
    open my $fh, '>', $path or die "Unable to write $path: $!";
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

# --- project root defaulting ------------------------------------------------
{
    is( $docker->_default_project_root('/given'), '/given', 'a given project root wins' );
    is( $docker->_default_project_root( undef, '/second' ), '/second', 'the next true candidate wins' );
    is( $docker->_default_project_root(), getcwd(), 'with no candidate the cwd is used' );
}

# --- duplicate candidate roots are collapsed --------------------------------
{
    my $docker_root = File::Spec->catdir( $repo, '.developer-dashboard', 'config', 'docker' );
    mkfile( File::Spec->catfile( $docker_root, 'dup', 'compose.yml' ), "services:\n  dup: {}\n" );
    my @layers = $paths->runtime_layers;
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::runtime_layers = sub { return ( @layers, @layers ) };
    my @roots = $docker->_service_lookup_roots( project_root => $repo, service => 'dup' );
    is( scalar @roots, 1, 'a runtime layer listed twice yields one lookup root' );
}

# --- toggle root without layers ---------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::runtime_layers = sub { return () };
    is(
        $docker->_service_toggle_root( project_root => $repo ),
        File::Spec->catdir( $paths->home_runtime_root, 'config', 'docker' ),
        'with no runtime layers the toggle root falls back to the home runtime root',
    );
}

# --- marker close failures --------------------------------------------------
{
    my $disable_marker = $docker->_service_disabled_marker_path( project_root => $repo, service => 'closer' );
    local $FAIL_CLOSE{">|$disable_marker"} = 1;
    ok( !eval { $docker->disable_service( project_root => $repo, service => 'closer' ); 1 }, 'disable_service dies when the marker close fails' );
    like( $@, qr/Unable to close \Q$disable_marker\E/, 'the disable close failure names the marker' );

    my $dev_marker = $docker->_service_development_marker_path( project_root => $repo, service => 'closer' );
    local $FAIL_CLOSE{">|$dev_marker"} = 1;
    ok( !eval { $docker->enable_service_development( project_root => $repo, service => 'closer' ); 1 }, 'enable_service_development dies when the marker close fails' );
    like( $@, qr/Unable to close \Q$dev_marker\E/, 'the development close failure names the marker' );
}

# --- run(): empty env, failed cwd restore -----------------------------------
{
    my $work = File::Spec->catdir( $home, 'work' );
    make_path($work);
    no warnings 'redefine';
    local *Developer::Dashboard::DockerCompose::resolve = sub {
        return {
            project_root => $work,
            compose_root => $work,
            env          => {},
            files        => [],
            command      => ['true'],
        };
    };
    local *Developer::Dashboard::DockerCompose::_materialized_command = sub { return ['true'] };

    my $result = $docker->run();
    is( $result->{exit_code}, 0, 'run works with an empty resolved env' );

    my $before = getcwd();
    local $FAIL_CHDIR{$before} = 1;
    ok( !eval { $docker->run(); 1 }, 'run dies when the original cwd cannot be restored' );
    like( $@, qr/Unable to restore cwd to \Q$before\E/, 'the restore failure names the saved cwd' );
    CORE::chdir $before or die "Unable to chdir back to $before: $!";
}

# --- _materialized_command: tmp file open and close failures ----------------
{
    my $bin = tempdir( CLEANUP => 1 );
    mkfile( File::Spec->catfile( $bin, 'docker' ), "#!/bin/sh\necho 'services: {}'\n" );
    chmod 0755, File::Spec->catfile( $bin, 'docker' ) or die "Unable to chmod fake docker: $!";
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    my $resolved = { files => ['/x/compose.yml'], command => [ 'docker', 'compose', '-f', '/x/compose.yml', 'up' ] };

    my $cmd = $docker->_materialized_command($resolved);
    is( $cmd->[-1], 'up', 'the passthrough arguments are preserved' );

    local $FAIL_OPEN_RE = qr/merged-compose\.yml\z/;
    ok( !eval { $docker->_materialized_command($resolved); 1 }, 'an unwritable merged file is fatal' );
    like( $@, qr/Unable to write .*merged-compose\.yml/, 'the open failure names the merged file' );

    local $FAIL_OPEN_RE  = undef;
    local $FAIL_CLOSE_RE = qr/merged-compose\.yml\z/;
    ok( !eval { $docker->_materialized_command($resolved); 1 }, 'a merged file close failure is fatal' );
    like( $@, qr/Unable to close .*merged-compose\.yml/, 'the close failure names the merged file' );
}

chdir q{/} or die "Unable to chdir: $!";

done_testing;

__END__

=pod

=head1 NAME

t/590-dockercompose-coverage.t - covers the failure-injection and defaulting branches of Developer::Dashboard::DockerCompose

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces close, open and chdir
failures and duplicate runtime layers without uncoverable annotations. Its
mocked C<resolve()> result includes both C<project_root> and C<compose_root>,
matching the resolved-result contract consumed by C<run()>.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate must be met without any C<# uncoverable> annotation, and these paths can only be reached by injecting failures that work for any uid, including root.

=head1 WHEN TO USE

Use this file when you change Developer::Dashboard::DockerCompose, or when a coverage run reports one of these paths as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/590-dockercompose-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/590-dockercompose-coverage.t

Run this coverage-gap test by itself while editing Developer::Dashboard::DockerCompose.

=cut
