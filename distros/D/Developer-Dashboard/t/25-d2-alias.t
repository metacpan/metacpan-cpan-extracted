#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use Cwd ();

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::DockerCompose;
use Developer::Dashboard::EnvLoader;
use Developer::Dashboard::CLI::Which;
use Developer::Dashboard::Config;
use Developer::Dashboard::JSON qw(json_encode);

# AC-1: ~/.d2 alone is recognised as the home runtime layer.
{
    my $home = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $home, '.d2' ) );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is(
        $paths->home_runtime_path,
        File::Spec->catdir( $home, '.d2' ),
        'AC-1: home_runtime_path resolves to .d2 when only .d2 exists'
    );
}

# AC-2: $PWD/.d2 alone is recognised as a project-local runtime layer.
{
    my $home    = tempdir( CLEANUP => 1 );
    my $project = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $project, '.git' ) );
    make_path( File::Spec->catdir( $project, '.d2' ) );
    my $orig_cwd = Cwd::getcwd();
    chdir $project or die "Unable to chdir to $project: $!";
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is(
        $paths->project_runtime_root,
        File::Spec->catdir( $project, '.d2' ),
        'AC-2: project_runtime_root resolves to .d2 when only $PWD/.d2 exists'
    );
    chdir $orig_cwd or die "Unable to chdir back to $orig_cwd: $!";
}

# AC-3: when both exist at the home layer, .developer-dashboard wins (Q-146).
{
    my $home = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $home, '.d2' ) );
    make_path( File::Spec->catdir( $home, '.developer-dashboard' ) );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is(
        $paths->home_runtime_path,
        File::Spec->catdir( $home, '.developer-dashboard' ),
        'AC-3: .developer-dashboard is checked before .d2 when both exist (home layer)'
    );
}

# AC-3, project layer: same precedence.
{
    my $home    = tempdir( CLEANUP => 1 );
    my $project = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $project, '.git' ) );
    make_path( File::Spec->catdir( $project, '.d2' ) );
    make_path( File::Spec->catdir( $project, '.developer-dashboard' ) );
    my $orig_cwd = Cwd::getcwd();
    chdir $project or die "Unable to chdir to $project: $!";
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is(
        $paths->project_runtime_root,
        File::Spec->catdir( $project, '.developer-dashboard' ),
        'AC-3: .developer-dashboard is checked before .d2 when both exist (project layer)'
    );
    chdir $orig_cwd or die "Unable to chdir back to $orig_cwd: $!";
}

# AC-4: both directory names at each level are independent runtime roots. The
# long name remains the write target, while files in .d2 also participate in
# every resolver and env inheritance chain.
{
    local %ENV = %ENV;
    delete $ENV{DEVELOPER_DASHBOARD_RUNTIME_LAYERS};
    delete $ENV{DEVELOPER_DASHBOARD_CONFIGS};
    delete $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};

    my $home    = tempdir( CLEANUP => 1 );
    my $project = tempdir( CLEANUP => 1 );
    my @runtime_roots = (
        File::Spec->catdir( $home, '.d2' ),
        File::Spec->catdir( $home, '.developer-dashboard' ),
        File::Spec->catdir( $project, '.d2' ),
        File::Spec->catdir( $project, '.developer-dashboard' ),
    );

    make_path( File::Spec->catdir( $project, '.git' ), @runtime_roots );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $project );

    is_deeply( [ $paths->runtime_layers ], \@runtime_roots,
        'both names participate as home and project runtime layers in deterministic order' );
    is( $paths->runtime_root, $runtime_roots[-1],
        'the canonical project runtime remains the effective write target' );
    is( $paths->runtime_layer_root_for( File::Spec->catdir( $runtime_roots[0], 'config' ) ), $runtime_roots[0],
        'runtime security ownership recognizes the home .d2 root' );
    ok( $paths->is_home_runtime_path( File::Spec->catdir( $runtime_roots[0], 'config' ) ),
        'home-runtime classification recognizes the .d2 sibling' );
    is_deeply( [ $paths->cli_layers ],
        [ map { File::Spec->catdir( $_, 'cli' ) } @runtime_roots ],
        'CLI discovery includes both runtime directory names' );
    is_deeply( [ $paths->config_layers ],
        [ map { File::Spec->catdir( $_, 'config' ) } @runtime_roots ],
        'config discovery includes both runtime directory names' );
    is_deeply( [ $paths->dashboards_layers ],
        [ map { File::Spec->catdir( $_, 'dashboards' ) } @runtime_roots ],
        'dashboard discovery includes both runtime directory names' );
    is_deeply( [ $paths->skills_roots ],
        [ map { File::Spec->catdir( $_, 'skills' ) } reverse @runtime_roots ],
        'skill lookup includes both names with deepest-layer-first precedence' );

    my @skill_layers;

    for my $spec (
        [ $runtime_roots[0], 'in-short-name-folder' ],
        [ $runtime_roots[1], 'in-long-name-folder' ],
        [ $runtime_roots[2], 'in-short-project-folder' ],
        [ $runtime_roots[3], 'in-long-project-folder' ],
    ) {
        my ( $runtime_root, $name ) = @$spec;
        my $cli = File::Spec->catfile( $runtime_root, 'cli', $name );
        make_path( File::Spec->catdir( $runtime_root, 'cli' ) );
        open my $cli_fh, '>', $cli or die "Unable to write $cli: $!";
        print {$cli_fh} "#!/bin/sh\nexit 0\n";
        close $cli_fh or die "Unable to close $cli: $!";
        chmod 0755, $cli or die "Unable to make $cli executable: $!";
    }

    my $which_output = sub {
        my ($name) = @_;
        my $output = '';
        open my $output_fh, '>', \$output or die "Unable to capture which output: $!";
        {
            local *STDOUT = $output_fh;
            local *Developer::Dashboard::CLI::Which::build_paths = sub { $paths };
            Developer::Dashboard::CLI::Which::run_which_command(
                command => 'which',
                args    => [$name],
            );
        }
        close $output_fh or die "Unable to close captured output: $!";
        return $output;
    };

    like( $which_output->('in-short-name-folder'),
        qr/^COMMAND \Q$runtime_roots[0]\/cli\/in-short-name-folder\E$/m,
        'which resolves a custom command stored only under .d2' );
    like( $which_output->('in-long-name-folder'),
        qr/^COMMAND \Q$runtime_roots[1]\/cli\/in-long-name-folder\E$/m,
        'which resolves a custom command stored only under .developer-dashboard' );

    for my $index ( 0 .. $#runtime_roots ) {
        my $runtime_root = $runtime_roots[$index];
        my $value = "layer_$index";
        my $config_dir = File::Spec->catdir( $runtime_root, 'config' );
        make_path( $config_dir, File::Spec->catdir( $runtime_root, 'skills', 'parallel-skill' ) );
        push @skill_layers, File::Spec->catdir( $runtime_root, 'skills', 'parallel-skill' );

        my $config_file = File::Spec->catfile( $config_dir, 'config.json' );
        open my $config_fh, '>', $config_file or die "Unable to write $config_file: $!";
        print {$config_fh} json_encode( {
            "P21_CONFIG_$index" => $value,
            P21_CONFIG_ORDER   => $value,
        } );
        close $config_fh or die "Unable to close $config_file: $!";

        open my $env_fh, '>', File::Spec->catfile( $runtime_root, '.env' ) or die "Unable to write .env: $!";
        print {$env_fh} "P21_ENV_$index=$value\nP21_ENV_ORDER=$value\n";
        close $env_fh or die "Unable to close .env: $!";

        open my $env_pl_fh, '>', File::Spec->catfile( $runtime_root, '.env.pl' ) or die "Unable to write .env.pl: $!";
        print {$env_pl_fh} "\$ENV{P21_ENV_PL_$index} = '$value';\n1;\n";
        close $env_pl_fh or die "Unable to close .env.pl: $!";
    }

    my $merged_config = Developer::Dashboard::Config->for_paths($paths)->load_global;
    for my $index ( 0 .. $#runtime_roots ) {
        is( $merged_config->{"P21_CONFIG_$index"}, "layer_$index",
            "config merge reads config.json from runtime layer $index" );
    }
    is( $merged_config->{P21_CONFIG_ORDER}, 'layer_3',
        'configuration in the deepest canonical root wins across both names' );
    is_deeply( [ $paths->skill_layers('parallel-skill') ], \@skill_layers,
        'installed skill lookup discovers same-named skills under both runtime directories' );

    my $compose = Developer::Dashboard::DockerCompose->new(
        config => bless( {}, 'Test::EmptyDockerConfig' ),
        paths  => $paths,
    );
    my @docker_roots = map { File::Spec->catdir( $_, 'config', 'docker' ) } @runtime_roots;
    make_path( map { File::Spec->catdir( $_, 'sample' ) } @docker_roots );
    is_deeply(
        [ $compose->_service_lookup_roots( service => 'sample', project_root => $project ) ],
        \@docker_roots,
        'docker compose service discovery includes both runtime directory names'
    );

    my $loaded = Developer::Dashboard::EnvLoader->load_runtime_layers( paths => $paths );
    is( scalar @$loaded, 8, '.env and .env.pl load from both names at both runtime levels' );
    for my $index ( 0 .. $#runtime_roots ) {
        is( $ENV{"P21_ENV_$index"}, "layer_$index", ".env loads from runtime layer $index" );
        is( $ENV{"P21_ENV_PL_$index"}, "layer_$index", ".env.pl loads from runtime layer $index" );
    }
    is( $ENV{P21_ENV_ORDER}, 'layer_3', 'deeper canonical layer overrides earlier aliases' );
}

# Fresh write: neither name exists yet, so the canonical (long) name is what
# gets created - home_runtime_path names it even though nothing is on disk.
{
    my $home  = tempdir( CLEANUP => 1 );
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    is(
        $paths->home_runtime_path,
        File::Spec->catdir( $home, '.developer-dashboard' ),
        'fresh write: home_runtime_path names .developer-dashboard when neither exists'
    );
}

done_testing;

__END__

=head1 NAME

t/25-d2-alias.t - .d2 alias resolution for the runtime layer directory

=head1 PURPOSE

Verifies that C<.d2> is recognised at both the home and project runtime
layers. When both C<.d2> and C<.developer-dashboard> exist, both contribute
CLI, merged config, dashboard, installed skill, Docker Compose, and environment
data, while the canonical long-name directory remains the write target. A
fresh (neither-exists-yet) layer is still named C<.developer-dashboard>.

=head1 WHY IT EXISTS

DD-809 introduced C<.d2> as a shorter runtime directory name. Treating the
second name only as a fallback caused it to disappear whenever the canonical
directory also existed. This test locks down parallel participation across
the shared runtime-layer consumers and confirms the established canonical
write target remains stable.

=head1 WHEN TO USE

Run this test after any change to C<PathRegistry>'s runtime root discovery,
C<DockerCompose>'s runtime service roots, or C<EnvLoader>'s runtime environment
inheritance.

=head1 HOW TO USE

  prove -lv t/25-d2-alias.t

=head1 WHAT USES IT

L<Developer::Dashboard::PathRegistry>, L<Developer::Dashboard::CLI::Which>,
L<Developer::Dashboard::DockerCompose>, and L<Developer::Dashboard::EnvLoader>
use the layered root inventory verified here.

=head1 EXAMPLES

  # Full run with verbose output
  prove -lv t/25-d2-alias.t

  # Run as part of the full suite
  prove -lr t

=cut
