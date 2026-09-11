package Developer::Dashboard::DockerCompose;

use strict;
use warnings;

our $VERSION = '4.31';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use Developer::Dashboard::DirEntries qw(sorted_dir_entries);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;

use Developer::Dashboard::EnvLoader;
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
    my $project_root = $args{project_root} || $self->{paths}->current_project_root || cwd();    # uncoverable condition false cwd never returns a false value
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

    my %addon_map = (
        %{ $docker_cfg->{addons} || {} },
    );
    my %mode_map = (
        %{ $docker_cfg->{modes} || {} },
    );
    my %service_map = (
        %{ $docker_cfg->{services} || {} },
    );
    my @services = $self->_resolve_effective_services(
        requested    => $args{services} || [],
        passthrough  => \@passthrough,
        project_root => $project_root,
        service_map  => \%service_map,
    );

    my $service_files = $self->_gather_service_files(
        services     => \@services,
        service_map  => \%service_map,
        project_root => $project_root,
        modes        => \@modes,
    );
    push @compose_files, @{$service_files};
    push @layers, { name => 'service', files => [ @{$service_files} ] } if @{$service_files};

    my $addon_files = $self->_gather_addon_files(
        addons    => \@addons,
        addon_map => \%addon_map,
        modes     => \@modes,    # pushed into by this call - addons may inject extra modes
    );
    push @compose_files, @{$addon_files};
    push @layers, { name => 'addon', files => [ @{$addon_files} ] } if @{$addon_files};

    my $mode_files = $self->_gather_mode_files(
        modes    => \@modes,
        mode_map => \%mode_map,
    );
    push @compose_files, @{$mode_files};
    push @layers, { name => 'mode', files => [ @{$mode_files} ] } if @{$mode_files};

    my @files = $self->_finalize_compose_files(
        compose_files => \@compose_files,
        project_root  => $project_root,
    );

    my $skill_env = $self->_resolve_skill_service_env(
        project_root => $project_root,
        services     => \@services,
    );
    my %env = $self->_resolve_docker_env(
        skill_env   => $skill_env,
        docker_cfg  => $docker_cfg,
        docker_root => $docker_root,
        addons      => \@addons,
        addon_map   => \%addon_map,
        modes       => \@modes,
        mode_map    => \%mode_map,
    );

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
        env_files    => $skill_env->{files},
        layers       => \@layers,
        precedence   => [ qw(base project service addon mode) ],
    };
}

# _resolve_effective_services(%args)
# Determines the final service list: explicitly requested services, plus any
# inferred from passthrough args, falling back to auto-discovered enabled
# services when nothing else names any.
# Input: requested (array ref), passthrough (array ref), project_root,
# service_map (hash ref).
# Output: deduplicated list of service names.
sub _resolve_effective_services {
    my ( $self, %args ) = @_;
    my @services = @{ $args{requested} };
    my @inferred_services = $self->_infer_services_from_args(
        args         => $args{passthrough},
        project_root => $args{project_root},
        service_map  => $args{service_map},
    );
    my %service_seen;
    @services = grep { !$service_seen{$_}++ } ( @services, @inferred_services );
    if ( !@services ) {
        my @auto_services = $self->_discover_enabled_services(
            project_root => $args{project_root},
            service_map  => $args{service_map},
        );
        @services = grep { !$service_seen{$_}++ } @auto_services;
    }
    return @services;
}

# _gather_service_files(%args)
# Collects the compose files a resolved service list contributes, both from
# its static config entry and from filesystem discovery.
# Input: services (array ref), service_map (hash ref), project_root, modes
# (array ref).
# Output: array reference of compose file paths.
sub _gather_service_files {
    my ( $self, %args ) = @_;
    my ( $services, $service_map, $project_root, $modes ) = @args{qw(services service_map project_root modes)};
    my @service_files;
    for my $service ( @{$services} ) {
        my $def = $service_map->{$service};
        next if ref($def) ne 'HASH';
        push @service_files, @{ $def->{files} } if ref( $def->{files} ) eq 'ARRAY';
    }
    for my $service ( @{$services} ) {
        push @service_files, $self->_discover_service_files(
            service      => $service,
            project_root => $project_root,
            modes        => $modes,
        );
    }
    return \@service_files;
}

# _gather_addon_files(%args)
# Collects the compose files a resolved addon list contributes, mutating the
# shared modes list in place since an addon definition may inject extra modes.
# Input: addons (array ref), addon_map (hash ref), modes (array ref, mutated).
# Output: array reference of compose file paths.
sub _gather_addon_files {
    my ( $self, %args ) = @_;
    my ( $addons, $addon_map, $modes ) = @args{qw(addons addon_map modes)};
    my @addon_files;
    for my $addon ( @{$addons} ) {
        my $def = $addon_map->{$addon};
        next if ref($def) ne 'HASH';
        push @addon_files, @{ $def->{files} } if ref( $def->{files} ) eq 'ARRAY';
        push @{$modes}, @{ $def->{modes} } if ref( $def->{modes} ) eq 'ARRAY';
    }
    return \@addon_files;
}

# _gather_mode_files(%args)
# Collects the compose files a resolved mode list contributes.
# Input: modes (array ref), mode_map (hash ref).
# Output: array reference of compose file paths.
sub _gather_mode_files {
    my ( $self, %args ) = @_;
    my ( $modes, $mode_map ) = @args{qw(modes mode_map)};
    my @mode_files;
    for my $mode ( @{$modes} ) {
        my $def = $mode_map->{$mode};
        next if ref($def) ne 'HASH';
        push @mode_files, @{ $def->{files} } if ref( $def->{files} ) eq 'ARRAY';
    }
    return \@mode_files;
}

# _finalize_compose_files(%args)
# Expands, absolutizes, deduplicates, and existence-filters the accumulated
# compose file list.
# Input: compose_files (array ref), project_root.
# Output: list of existing, absolute, deduplicated compose file paths.
sub _finalize_compose_files {
    my ( $self, %args ) = @_;
    my ( $compose_files, $project_root ) = @args{qw(compose_files project_root)};
    my @files;
    my %seen;
    for my $file ( @{$compose_files} ) {
        next if !defined $file || $file eq '';
        $file = $self->_expand_env_path($file);
        $file = File::Spec->catfile( $project_root, $file ) if !File::Spec->file_name_is_absolute($file);
        next if $seen{$file}++;
        push @files, $file if -f $file;
    }
    return @files;
}

# _resolve_docker_env(%args)
# Merges skill, project, addon, and mode environment layers into the final
# environment hash for the resolved docker compose invocation.
# Input: skill_env (hash ref), docker_cfg (hash ref), docker_root, addons
# (array ref), addon_map (hash ref), modes (array ref), mode_map (hash ref).
# Output: merged environment hash.
sub _resolve_docker_env {
    my ( $self, %args ) = @_;
    my ( $skill_env, $docker_cfg, $docker_root, $addons, $addon_map, $modes, $mode_map )
      = @args{qw(skill_env docker_cfg docker_root addons addon_map modes mode_map)};
    my %env = (
        %{ $skill_env->{env} },
        %{ $docker_cfg->{env} || {} },
        DDDC => $docker_root,
    );
    for my $addon ( @{$addons} ) {
        my $def = $addon_map->{$addon};
        next if ref($def) ne 'HASH' || ref( $def->{env} ) ne 'HASH';
        @env{ keys %{ $def->{env} } } = values %{ $def->{env} };
    }
    for my $mode ( @{$modes} ) {
        my $def = $mode_map->{$mode};
        next if ref($def) ne 'HASH' || ref( $def->{env} ) ne 'HASH';
        @env{ keys %{ $def->{env} } } = values %{ $def->{env} };
    }
    return %env;
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
    my $project_root = $args{project_root} || cwd();    # uncoverable condition false cwd never returns a false value
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
        next if !defined $root;    # uncoverable branch true lookup roots are interpolated paths, never undef
        my $service_root = File::Spec->catdir( $root, $service );
        next if !-d $service_root;    # uncoverable branch true lookup roots already filtered to existing service folders

        my $development = File::Spec->catfile( $service_root, 'development.compose.yml' );
        if ( -f $development ) {
            push @files, $development if !$seen{$development}++;    # uncoverable branch false lookup roots are deduplicated so each development path is seen once
            next;
        }

        my $compose = File::Spec->catfile( $service_root, 'compose.yml' );
        push @files, $compose if -f $compose && !$seen{$compose}++;    # uncoverable condition right lookup roots are deduplicated so each compose path is seen once
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

# _resolve_skill_service_env(%args)
# Loads .env files from installed skill roots whose config/docker/<service>
# folder contributes one compose file to the effective service stack.
# Input: project_root and ordered service list array reference.
# Output: hash reference with loaded env file list and env overlay hash.
sub _resolve_skill_service_env {
    my ( $self, %args ) = @_;
    my $project_root = $args{project_root} || cwd();    # uncoverable condition false cwd never returns a false value
    my @services     = @{ $args{services} || [] };
    return { files => [], env => {} } if !@services;

    my @skill_layers;
    my %env;
    my %seen;
    for my $service (@services) {
        for my $skill_root ( $self->_discover_service_skill_roots(
            project_root => $project_root,
            service      => $service,
        ) )
        {
            for my $docker_var ( $self->_skill_docker_env_keys($skill_root) ) {
                $env{$docker_var} = File::Spec->catdir( $skill_root, 'config', 'docker' );
            }
            next if $seen{$skill_root}++;
            push @skill_layers, $skill_root;
        }
    }

    my $loaded = @skill_layers
      ? Developer::Dashboard::EnvLoader->load_skill_layers_into_hash(
        base_env => { %ENV },
        skill_layers => \@skill_layers,
      )
      : {
        files => [],
        env   => {},
      };
    my %merged_env = (
        %env,
        %{ $loaded->{env} },
    );
    return {
        files => $loaded->{files},
        env   => \%merged_env,
    };
}

# _discover_service_skill_roots(%args)
# Resolves the installed skill roots whose config/docker/<service> folders
# contribute compose files for one effective service.
# Input: service name and optional project_root.
# Output: ordered list of participating skill root directory paths.
sub _discover_service_skill_roots {
    my ( $self, %args ) = @_;
    my $service      = $args{service} || return;
    my $project_root = $args{project_root} || cwd();    # uncoverable condition false cwd never returns a false value
    return if $self->_service_folder_is_disabled(
        project_root => $project_root,
        service      => $service,
    );

    my @roots = $self->_service_lookup_roots(
        project_root => $project_root,
        service      => $service,
    );

    my @skill_roots;
    my %seen;
    for my $root (@roots) {
        next if !defined $root;    # uncoverable branch true lookup roots are interpolated paths, never undef
        my $service_root = File::Spec->catdir( $root, $service );
        next if !-d $service_root;    # uncoverable branch true lookup roots already filtered to existing service folders

        my $development = File::Spec->catfile( $service_root, 'development.compose.yml' );
        my $compose     = File::Spec->catfile( $service_root, 'compose.yml' );
        next if !-f $development && !-f $compose;

        next if File::Spec->canonpath($root) !~ m{(?:^|/)config/docker\z};    # uncoverable branch true every lookup root ends in config/docker
        my $skill_root = dirname( dirname($root) );
        next if !-d $skill_root;    # uncoverable branch true the config/docker parent directory always exists
        next if $seen{$skill_root}++;    # uncoverable branch true distinct roots always map to distinct skill roots
        push @skill_roots, $skill_root;
    }

    return @skill_roots;
}

# _skill_name_segments_from_root($skill_root)
# Extracts one installed skill path's cumulative name segments from an
# absolute skill root, including nested skills/<repo> chains.
# Input: absolute skill root directory path.
# Output: ordered list of skill name segments.
sub _skill_name_segments_from_root {
    my ( $self, $skill_root ) = @_;
    return () if !defined $skill_root || $skill_root eq '';
    my @parts = File::Spec->splitdir( File::Spec->canonpath($skill_root) );
    my @segments;
    for my $index ( 0 .. $#parts - 1 ) {
        next if $parts[$index] ne 'skills';
        next if !defined $parts[ $index + 1 ];    # uncoverable branch true the loop bound guarantees a defined following segment
        push @segments, $parts[ $index + 1 ];
    }
    return @segments;
}

# _skill_docker_env_keys($skill_root)
# Builds the leaf and cumulative nested compose env variable names that point
# at one participating installed skill's config/docker root.
# Input: absolute skill root directory path.
# Output: ordered list of env key strings.
sub _skill_docker_env_keys {
    my ( $self, $skill_root ) = @_;
    my @segments = $self->_skill_name_segments_from_root($skill_root);
    return () if !@segments;
    my @keys = (
        $self->_skill_docker_env_key( $segments[-1] ),
        $self->_skill_docker_env_key( join '_', @segments ),
    );
    my %seen;
    return grep { !$seen{$_}++ } @keys;
}

# _skill_docker_env_key($skill_name)
# Normalizes one skill name into the skill-specific compose env variable name
# that points at the owning config/docker root.
# Input: skill repository name string.
# Output: env key string such as cloudflare_DDDC.
sub _skill_docker_env_key {
    my ( $self, $skill_name ) = @_;
    return undef if !defined $skill_name || $skill_name eq '';
    my $env_key = $skill_name;
    $env_key =~ s/[^A-Za-z0-9_]/_/g;
    $env_key =~ s/\A_+|_+\z//g;
    return $env_key eq '' ? undef : $env_key . '_DDDC';
}

# _discover_service_names(%args)
# Lists known compose service names from config maps and isolated service folders.
# Input: project_root and optional service_map hash reference.
# Output: sorted list of service name strings.
sub _discover_service_names {
    my ( $self, %args ) = @_;
    my $project_root = $args{project_root} || cwd();    # uncoverable condition false cwd never returns a false value
    my $service_map  = $args{service_map} || {};
    my %names = map { $_ => 1 } grep { $_ ne '' } keys %{$service_map};

    for my $root ( $self->_service_lookup_roots( project_root => $project_root, service => '__all__' ) ) {
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
    my $project_root = $args{project_root} || cwd();    # uncoverable condition false cwd never returns a false value
    my @roots = $self->_service_lookup_roots(
        project_root => $project_root,
        service      => $service,
    );
    return 0 if !@roots;
    for my $root ( reverse @roots ) {
        my $service_root = File::Spec->catdir( $root, $service );
        next if !-d $service_root;
        return 1 if -f File::Spec->catfile( $service_root, 'disabled.yml' );
        return 0;
    }

    return 0;
}

# _service_lookup_roots(%args)
# Returns the docker roots that should be searched for one isolated service across
# home config, installed skills, and deeper runtime-layer config/docker roots.
# Input: service name and optional project_root.
# Output: ordered list of docker root directory path strings.
sub _service_lookup_roots {
    my ( $self, %args ) = @_;
    my $service      = $args{service} || return;
    my $project_root = $args{project_root} || cwd();    # uncoverable condition false cwd never returns a false value
    my @roots;
    my %seen;
    for my $runtime_root ( $self->{paths}->runtime_layers ) {
        my @candidates = ();
        my $config_docker_root = File::Spec->catdir( $runtime_root, 'config', 'docker' );
        push @candidates, $config_docker_root;
        push @candidates, $self->_installed_skill_docker_roots_for_runtime($runtime_root);

        for my $root (@candidates) {
            next if !defined $root;    # uncoverable branch true candidate roots are interpolated paths, never undef
            next if $seen{$root}++;    # uncoverable branch true candidate roots across runtime layers are already distinct
            if ( $service eq '__all__' ) {
                push @roots, $root;
                next;
            }
            my $service_root = File::Spec->catdir( $root, $service );
            push @roots, $root if -d $service_root;
        }
    }

    return @roots;
}

# _installed_skill_docker_roots_for_runtime($runtime_root)
# Recursively lists config/docker roots contributed by installed skills beneath
# one runtime layer, including nested skills/<repo> chains while skipping any
# skill roots disabled at their own level or by a disabled ancestor.
# Input: runtime root directory path string.
# Output: ordered list of skill config/docker root directory path strings.
sub _installed_skill_docker_roots_for_runtime {
    my ( $self, $runtime_root ) = @_;
    return () if !defined $runtime_root || $runtime_root eq '';
    my $skills_root = File::Spec->catdir( $runtime_root, 'skills' );
    return () if !-d $skills_root;

    my @roots;
    my @queue = ($skills_root);
    my %seen;
    while (@queue) {
        my $parent = shift @queue;
        opendir my $dh, $parent or next;
        for my $entry ( sorted_dir_entries($dh) ) {
            my $skill_root = File::Spec->catdir( $parent, $entry );
            next if !-d $skill_root;
            next if $seen{$skill_root}++;    # uncoverable branch true the breadth-first walk visits each skill root once
            next if $self->_skill_root_chain_disabled($skill_root);
            push @roots, File::Spec->catdir( $skill_root, 'config', 'docker' );
            my $nested_root = File::Spec->catdir( $skill_root, 'skills' );
            push @queue, $nested_root if -d $nested_root;
        }
        closedir $dh;
    }

    return @roots;
}

# _skill_root_chain_disabled($skill_root)
# Reports whether one installed skill root or any of its nested-skill parents
# is disabled through a .disabled marker.
# Input: absolute installed skill root directory path.
# Output: boolean true when the chain is disabled.
sub _skill_root_chain_disabled {
    my ( $self, $skill_root ) = @_;
    return 0 if !defined $skill_root || $skill_root eq '';
    my @parts = File::Spec->splitdir( File::Spec->canonpath($skill_root) );
    for my $index ( 0 .. $#parts - 1 ) {
        next if $parts[$index] ne 'skills';
        next if !defined $parts[ $index + 1 ];    # uncoverable branch true the loop bound guarantees a defined following segment
        my $candidate = File::Spec->catdir( @parts[ 0 .. $index + 1 ] );
        return 1 if -f File::Spec->catfile( $candidate, '.disabled' );
    }
    return 0;
}

# _infer_services_from_args(%args)
# Infers service names from passthrough docker compose arguments before the real command is executed.
# Input: args array reference, project_root, and optional service_map hash reference.
# Output: ordered list of inferred service name strings.
sub _infer_services_from_args {
    my ( $self, %args ) = @_;
    my $argv         = $args{args} || [];
    my $project_root = $args{project_root} || cwd();    # uncoverable condition false cwd never returns a false value
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

# disable_service(%args)
# Writes the isolated-service disabled marker into the deepest runtime docker root for one service.
# Input: service name and optional project_root.
# Output: hash reference describing the toggled service and marker path.
sub disable_service {
    my ( $self, %args ) = @_;
    my $service = $args{service} || die "Usage: dashboard docker disable <service>\n";
    my $marker = $self->_service_disabled_marker_path(
        project_root => $args{project_root},
        service      => $service,
    );
    die "Refusing service name that escapes the docker config root: $service\n"
      if !defined $marker;
    my ( undef, $dir ) = File::Spec->splitpath($marker);
    make_path($dir) if !-d $dir;
    open my $fh, '>', $marker or die "Unable to write $marker: $!";
    print {$fh} "---\ndisabled: 1\n";
    close $fh or die "Unable to close $marker: $!";    # uncoverable branch true the deferred write failure surfaces only on close, unreproducible on the test host
    return {
        action   => 'disable',
        disabled => 1,
        marker   => $marker,
        service  => $service,
    };
}

# enable_service(%args)
# Removes the isolated-service disabled marker from the deepest runtime docker root for one service.
# Input: service name and optional project_root.
# Output: hash reference describing the toggled service and marker path.
sub enable_service {
    my ( $self, %args ) = @_;
    my $service = $args{service} || die "Usage: dashboard docker enable <service>\n";
    my $marker = $self->_service_disabled_marker_path(
        project_root => $args{project_root},
        service      => $service,
    );
    die "Refusing service name that escapes the docker config root: $service\n"
      if !defined $marker;
    unlink $marker or die "Unable to remove $marker: $!" if -e $marker;
    return {
        action   => 'enable',
        disabled => 0,
        marker   => $marker,
        service  => $service,
    };
}

# list_services(%args)
# Lists isolated docker services together with their effective enabled or disabled state.
# Input: optional project_root and filter values all, enabled, or disabled.
# Output: array reference of service state hash references in sorted service order.
sub list_services {
    my ( $self, %args ) = @_;
    my $project_root = $args{project_root} || cwd();    # uncoverable condition false cwd never returns a false value
    my $filter = defined $args{filter} && $args{filter} ne '' ? $args{filter} : 'all';
    die "Usage: dashboard docker list [--enabled|--disabled]\n"
      if $filter !~ /\A(?:all|enabled|disabled)\z/;

    my @services = $self->_discover_service_names(
        project_root => $project_root,
        service_map  => $self->{config}->docker_config->{services} || {},
    );

    my @listed;
    for my $service (@services) {
        my $disabled = $self->_service_folder_is_disabled(
            project_root => $project_root,
            service      => $service,
        ) ? 1 : 0;
        next if $filter eq 'enabled'  && $disabled;
        next if $filter eq 'disabled' && !$disabled;
        push @listed, {
            disabled => $disabled,
            enabled  => $disabled ? 0 : 1,
            marker   => $self->_service_disabled_marker_path(
                project_root => $project_root,
                service      => $service,
            ),
            service => $service,
            status  => $disabled ? 'disabled' : 'enabled',
        };
    }

    return \@listed;
}

# run(%args)
# Executes the resolved docker compose command or returns dry-run data.
# Input: same resolution arguments plus optional dry_run flag.
# Output: resolution hash reference with stdout/stderr/exit_code when executed.
sub run {
    my ( $self, %args ) = @_;

    # DD-597: system() below mutates the caller's global $? as a side effect;
    # without this guard that stays set in the caller's process after this
    # sub returns, regardless of the exit code already captured in this
    # sub's own return value.
    local $?;
    my $resolved = $self->resolve(%args);
    return $resolved if $args{dry_run};

    my $old = cwd();
    chdir $resolved->{project_root} or die "Unable to chdir to $resolved->{project_root}: $!";
    local @ENV{ keys %{ $resolved->{env} } } = values %{ $resolved->{env} } if %{ $resolved->{env} };    # uncoverable branch false the resolved env always carries the DDDC key
    my ( $stdout, $stderr, $exit_code ) = capture {
        system @{ $resolved->{command} };
        return $? >> 8;
    };
    chdir $old or die "Unable to restore cwd to $old: $!";    # uncoverable branch true the saved cwd remains valid for the duration of the run

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

# _contained_service_path($root, $service)
# Resolves an untrusted service name below the docker toggle root and refuses any
# result that escapes it. The service name arrives straight from the command line
# (dashboard docker disable|enable), and File::Spec->catfile neither canonicalises
# a path nor rejects a parent-directory run, so without this a name containing
# '../' steered a write to any location the user could reach and an unlink to any
# file named disabled.yml. Resolution is lexical and never consults the
# filesystem, so the decision cannot change between the check and the write that
# follows it.
# Input: docker toggle root path string and the untrusted service name.
# Output: contained service directory path string, or undef when it escapes.
sub _contained_service_path {
    my ( $root, $service ) = @_;
    my @resolved;

    for my $part ( grep { $_ !~ m{\A\.?\z} } split m{[\\/]+}, $service ) {
        if ( $part eq '..' ) {
            return if !@resolved;
            pop @resolved;
            next;
        }
        push @resolved, $part;
    }

    return if !@resolved;
    return File::Spec->catdir( $root, @resolved );
}

# _service_disabled_marker_path(%args)
# Resolves the disabled.yml marker path in the deepest runtime docker root for one isolated service.
# Input: service name and optional project_root.
# Output: absolute disabled.yml marker file path string, or undef when the
#         service name escapes the docker toggle root.
sub _service_disabled_marker_path {
    my ( $self, %args ) = @_;
    my $service = $args{service} || die 'Missing service';
    my $root = $self->_service_toggle_root(%args);
    my $dir = _contained_service_path( $root, $service );
    return if !defined $dir;
    return File::Spec->catfile( $dir, 'disabled.yml' );
}

# _service_toggle_root(%args)
# Returns the deepest participating config/docker root where isolated-service
# toggle markers should be written.
# Input: optional project_root.
# Output: absolute docker root directory path string.
sub _service_toggle_root {
    my ( $self, %args ) = @_;
    my @layers = $self->{paths}->runtime_layers;
    my $runtime_root = @layers ? $layers[-1] : $self->{paths}->home_runtime_root;    # uncoverable branch false runtime_layers always includes at least the home runtime root
    return File::Spec->catdir( $runtime_root, 'config', 'docker' );
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

=head2 new, resolve, list_services, run

Construct, resolve, list, and optionally execute compose operations.

=head2 disable_service, enable_service

Write and remove the C<disabled.yml> marker for one isolated service, below the
deepest runtime C<config/docker> root.

The service name reaches these methods straight from the command line and is
therefore untrusted. It is resolved below the toggle root and any name that
escapes that root is B<refused> - both methods die rather than fall back to the
unchecked path. Resolution is lexical and never consults the filesystem, so the
containment decision cannot change between the check and the write or unlink
that follows it.

The refusal protects two distinct sinks, and the second is the one usually
underestimated: C<disable_service> creates directories and writes a file, while
C<enable_service> B<removes> one, so an uncontained name gave arbitrary deletion
of any file with that fixed leaf name, not merely arbitrary creation.

One case is deliberately outside this containment: a parent directory that is
itself a symlink pointing outside the root is lexically innocent and is not
rejected here. Resolving it would require consulting the filesystem and would
reopen the time-of-check-to-time-of-use window this approach closes.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module resolves and runs dashboard-managed Docker Compose stacks. It maps wrapper flags to compose files under layered runtime C<config/docker> roots, infers service names, exports the effective docker config root, and builds the final C<docker compose> command that the wrapper C<exec>s.

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

  dashboard docker list --disabled

Inspect the effective disabled-service view through the same resolver rules as
compose discovery.

Example 4:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
