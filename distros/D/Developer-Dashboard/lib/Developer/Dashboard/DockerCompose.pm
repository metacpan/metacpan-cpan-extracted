package Developer::Dashboard::DockerCompose;

use strict;
use warnings;

our $VERSION = '2.17';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Spec;

use Developer::Dashboard::JSON qw(json_encode);

# new(%args)
# Constructs the docker compose resolver and launcher.
# Input: config and paths objects.
# Output: Developer::Dashboard::DockerCompose object.
sub new {
    my ( $class, %args ) = @_;
    my $config = $args{config} || die 'Missing config';
    my $paths  = $args{paths}  || die 'Missing path registry';
    return bless {
        config => $config,
        paths  => $paths,
    }, $class;
}

# resolve(%args)
# Resolves the effective docker compose context and overlay stack.
# Input: optional project_root, addons, modes, services, and compose args.
# Output: hash reference describing files, env, layers, precedence, and final command.
sub resolve {
    my ( $self, %args ) = @_;
    my $project_root = $args{project_root} || $self->{paths}->current_project_root || cwd();
    my $docker_cfg  = $self->{config}->docker_config;
    my $docker_root = $self->_docker_config_root;
    my @passthrough = @{ $args{args} || [] };
    my @compose_files = ();
    my @layers;

    my @base = $self->_discover_base_files($project_root);
    push @compose_files, @base;
    push @layers, { name => 'base', files => [@base] };

    my @project_overlays = ( @{ $docker_cfg->{files} || [] }, @{ $docker_cfg->{project_overlays} || [] } );
    push @compose_files, @project_overlays;
    push @layers, { name => 'project', files => [@project_overlays] } if @project_overlays;

    my @addons = @{ $args{addons} || [] };
    my @modes  = @{ $args{modes}  || [] };
    my @services = @{ $args{services} || [] };

    my %addon_map = (
        %{ $docker_cfg->{addons} || {} },
    );
    my %mode_map = (
        %{ $docker_cfg->{modes} || {} },
    );
    my %service_map = (
        %{ $docker_cfg->{services} || {} },
    );
    my @inferred_services = $self->_infer_services_from_args(
        args         => \@passthrough,
        project_root => $project_root,
        service_map  => \%service_map,
    );
    my %service_seen;
    @services = grep { !$service_seen{$_}++ } ( @services, @inferred_services );
    if ( !@services ) {
        my @auto_services = $self->_discover_enabled_services(
            project_root => $project_root,
            service_map  => \%service_map,
        );
        @services = grep { !$service_seen{$_}++ } @auto_services;
    }

    my @service_files;
    for my $service (@services) {
        my $def = $service_map{$service};
        next if ref($def) ne 'HASH';
        push @service_files, @{ $def->{files} || [] } if ref( $def->{files} ) eq 'ARRAY';
    }
    for my $service (@services) {
        push @service_files, $self->_discover_service_files(
            service      => $service,
            project_root => $project_root,
            modes        => \@modes,
        );
    }
    push @compose_files, @service_files;
    push @layers, { name => 'service', files => [@service_files] } if @service_files;

    my @addon_files;
    for my $addon (@addons) {
        my $def = $addon_map{$addon};
        next if ref($def) ne 'HASH';
        push @addon_files, @{ $def->{files} || [] } if ref( $def->{files} ) eq 'ARRAY';
        push @modes, @{ $def->{modes} || [] } if ref( $def->{modes} ) eq 'ARRAY';
    }
    push @compose_files, @addon_files;
    push @layers, { name => 'addon', files => [@addon_files] } if @addon_files;

    my @mode_files;
    for my $mode (@modes) {
        my $def = $mode_map{$mode};
        next if ref($def) ne 'HASH';
        push @mode_files, @{ $def->{files} || [] } if ref( $def->{files} ) eq 'ARRAY';
    }
    push @compose_files, @mode_files;
    push @layers, { name => 'mode', files => [@mode_files] } if @mode_files;

    my @files;
    my %seen;
    for my $file (@compose_files) {
        next if !defined $file || $file eq '';
        $file = $self->_expand_env_path($file);
        $file = File::Spec->catfile( $project_root, $file ) if !File::Spec->file_name_is_absolute($file);
        next if $seen{$file}++;
        push @files, $file if -f $file;
    }

    my %env = (
        %{ $docker_cfg->{env} || {} },
        DDDC => $docker_root,
    );
    for my $addon (@addons) {
        my $def = $addon_map{$addon};
        next if ref($def) ne 'HASH' || ref( $def->{env} ) ne 'HASH';
        @env{ keys %{ $def->{env} } } = values %{ $def->{env} };
    }
    for my $mode (@modes) {
        my $def = $mode_map{$mode};
        next if ref($def) ne 'HASH' || ref( $def->{env} ) ne 'HASH';
        @env{ keys %{ $def->{env} } } = values %{ $def->{env} };
    }

    my @command = ('docker', 'compose');
    for my $file (@files) {
        push @command, '-f', $file;
    }
    push @command, @passthrough;

    return {
        project_root => $project_root,
        addons       => \@addons,
        modes        => \@modes,
        services     => \@services,
        files        => \@files,
        env          => \%env,
        command      => \@command,
        layers       => \@layers,
        precedence   => [ qw(base project service addon mode) ],
    };
}

# _expand_env_path($path)
# Expands ${VAR} and $VAR environment placeholders in configured compose file paths.
# Input: file path string that may contain environment variable placeholders.
# Output: expanded file path string.
sub _expand_env_path {
    my ( $self, $path ) = @_;
    return $path if !defined $path || $path eq '';

    $path =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/defined $ENV{$1} ? $ENV{$1} : ''/ge;
    $path =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/defined $ENV{$1} ? $ENV{$1} : ''/ge;

    return $path;
}

# _docker_config_root()
# Returns the dashboard docker configuration root used for isolated service folders.
# Input: none.
# Output: absolute directory path string.
sub _docker_config_root {
    my ($self) = @_;
    return File::Spec->catdir( $self->{paths}->config_root, 'docker' );
}

# _home_docker_config_root()
# Returns the home-backed docker configuration root used as the fallback for isolated service folders.
# Input: none.
# Output: absolute directory path string.
sub _home_docker_config_root {
    my ($self) = @_;
    return File::Spec->catdir( $self->{paths}->home_runtime_root, 'config', 'docker' );
}

# _discover_service_files(%args)
# Discovers the preferred old-style isolated compose file for a named service from repo-local and global docker config roots.
# Input: service name and optional project_root.
# Output: ordered list of discovered compose file paths, preferring development.compose.yml over compose.yml per folder.
sub _discover_service_files {
    my ( $self, %args ) = @_;
    my $service      = $args{service} || return;
    my $project_root = $args{project_root} || cwd();
    return if $self->_service_folder_is_disabled(
        project_root => $project_root,
        service      => $service,
    );

    my @roots = $self->_service_lookup_roots(
        project_root => $project_root,
        service      => $service,
    );

    my @files;
    my %seen;
    for my $root (@roots) {
        next if !defined $root || $root eq '';
        my $service_root = File::Spec->catdir( $root, $service );
        next if !-d $service_root;

        my $development = File::Spec->catfile( $service_root, 'development.compose.yml' );
        if ( -f $development ) {
            push @files, $development if !$seen{$development}++;
            next;
        }

        my $compose = File::Spec->catfile( $service_root, 'compose.yml' );
        push @files, $compose if -f $compose && !$seen{$compose}++;
    }

    return @files;
}

# _discover_enabled_services(%args)
# Lists isolated services that should be auto-loaded when no service is selected in the command.
# Input: project_root and optional service_map hash reference.
# Output: ordered list of auto-loaded service name strings.
sub _discover_enabled_services {
    my ( $self, %args ) = @_;
    my @services = $self->_discover_service_names(%args);
    return grep {
        !$self->_service_folder_is_disabled(
            project_root => $args{project_root},
            service      => $_,
        )
    } @services;
}

# _discover_service_names(%args)
# Lists known compose service names from config maps and isolated service folders.
# Input: project_root and optional service_map hash reference.
# Output: sorted list of service name strings.
sub _discover_service_names {
    my ( $self, %args ) = @_;
    my $project_root = $args{project_root} || cwd();
    my $service_map  = $args{service_map} || {};
    my %names = map { $_ => 1 } grep { defined && $_ ne '' } keys %{$service_map};

    for my $root (
        File::Spec->catdir( $project_root, '.developer-dashboard', 'docker' ),
        $self->_home_docker_config_root,
      )
    {
        next if !-d $root;
        opendir my $dh, $root or next;
        while ( my $entry = readdir $dh ) {
            next if $entry eq '.' || $entry eq '..';
            next if !-d File::Spec->catdir( $root, $entry );
            $names{$entry} = 1;
        }
        closedir $dh;
    }

    return sort keys %names;
}

# _service_folder_is_disabled(%args)
# Checks whether an isolated service folder opts out of automatic compose inclusion.
# Input: service name and optional project_root.
# Output: boolean true when the service folder contains a disabled.yml marker.
sub _service_folder_is_disabled {
    my ( $self, %args ) = @_;
    my $service      = $args{service} || return 0;
    my $project_root = $args{project_root} || cwd();
    my @roots = $self->_service_lookup_roots(
        project_root => $project_root,
        service      => $service,
    );
    return 0 if !@roots;
    my $service_root = File::Spec->catdir( $roots[0], $service );
    return 1 if -f File::Spec->catfile( $service_root, 'disabled.yml' );

    return 0;
}

# _service_lookup_roots(%args)
# Returns the docker roots that should be searched for one isolated service with project-local precedence over home runtime fallbacks.
# Input: service name and optional project_root.
# Output: ordered list of docker root directory path strings.
sub _service_lookup_roots {
    my ( $self, %args ) = @_;
    my $service      = $args{service} || return;
    my $project_root = $args{project_root} || cwd();
    my $project_docker_root = File::Spec->catdir( $project_root, '.developer-dashboard', 'docker' );
    my $project_service_root = File::Spec->catdir( $project_docker_root, $service );
    return ($project_docker_root) if -d $project_service_root;
    return ( $self->_home_docker_config_root );
}

# _infer_services_from_args(%args)
# Infers service names from passthrough docker compose arguments before the real command is executed.
# Input: args array reference, project_root, and optional service_map hash reference.
# Output: ordered list of inferred service name strings.
sub _infer_services_from_args {
    my ( $self, %args ) = @_;
    my $argv         = $args{args} || [];
    my $project_root = $args{project_root} || cwd();
    my $service_map  = $args{service_map} || {};
    my %known = map { $_ => 1 } $self->_discover_service_names(
        project_root => $project_root,
        service_map  => $service_map,
    );

    my @services;
    my %seen;
    for my $arg ( @{$argv} ) {
        next if !defined $arg || $arg eq '';
        next if $arg =~ /^-/;
        next if !$known{$arg};
        next if $seen{$arg}++;
        push @services, $arg;
    }

    return @services;
}

# run(%args)
# Executes the resolved docker compose command or returns dry-run data.
# Input: same resolution arguments plus optional dry_run flag.
# Output: resolution hash reference with stdout/stderr/exit_code when executed.
sub run {
    my ( $self, %args ) = @_;
    my $resolved = $self->resolve(%args);
    return $resolved if $args{dry_run};

    my $old = cwd();
    chdir $resolved->{project_root} or die "Unable to chdir to $resolved->{project_root}: $!";
    local @ENV{ keys %{ $resolved->{env} } } = values %{ $resolved->{env} } if %{ $resolved->{env} };
    my ( $stdout, $stderr, $exit_code ) = capture {
        system @{ $resolved->{command} };
        return $? >> 8;
    };
    chdir $old or die "Unable to restore cwd to $old: $!";

    return {
        %$resolved,
        stdout    => $stdout,
        stderr    => $stderr,
        exit_code => $exit_code,
    };
}

# _discover_base_files($root)
# Finds standard base compose files under a project root.
# Input: project root directory path.
# Output: ordered list of existing compose file paths.
sub _discover_base_files {
    my ( $self, $root ) = @_;
    my @candidates = qw(compose.yml compose.yaml docker-compose.yml docker-compose.yaml);
    return grep { -f $_ } map { File::Spec->catfile( $root, $_ ) } @candidates;
}

1;

__END__

=head1 NAME

Developer::Dashboard::DockerCompose - compose resolver and launcher

=head1 SYNOPSIS

  my $docker = Developer::Dashboard::DockerCompose->new(
      config  => $config,
      paths   => $paths,
      plugins => $plugins,
  );

=head1 DESCRIPTION

This module resolves layered docker compose inputs into a final transparent
docker compose command line and can optionally execute it.

=head1 METHODS

=head2 new, resolve, run

Construct, resolve, and optionally execute compose operations.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module resolves and runs dashboard-managed Docker Compose stacks. It maps wrapper flags to compose files under layered runtime config roots, infers service names, exports the effective docker config root, and builds the final C<docker compose> command that the wrapper C<exec>s.

=head1 WHY IT EXISTS

It exists because dashboard-specific Compose resolution has more rules than a plain passthrough wrapper: isolated service folders, disabled markers, addon/mode selection, and layered runtime lookup all need one tested owner.

=head1 WHEN TO USE

Use this file when changing compose file discovery, wrapper-only flags, service inference, environment exports such as C<DDDC>, or the dry-run versus exec behavior of the docker helper.

=head1 HOW TO USE

Feed the parsed wrapper arguments into this module and let it return or execute the effective docker compose command. Avoid rebuilding compose discovery logic in the CLI wrapper or in project-local scripts.

=head1 WHAT USES IT

It is used by the C<dashboard docker compose> helper, by docker-focused tests, and by developers who keep Compose stacks under F<.developer-dashboard/config/docker/> instead of shell aliases.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::DockerCompose -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/10-extension-action-docker.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
