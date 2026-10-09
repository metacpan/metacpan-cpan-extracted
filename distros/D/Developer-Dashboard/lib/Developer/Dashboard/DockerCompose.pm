package Developer::Dashboard::DockerCompose;

use strict;
use warnings;

our $VERSION = '5.73';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use Encode qw(decode encode_utf8 FB_DEFAULT);
use Developer::Dashboard::DirEntries qw(sorted_dir_entries);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use YAML::XS ();

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

# _default_project_root(@candidates)
# Picks the first true candidate project root, falling back to the current directory.
# Input: zero or more candidate path values.
# Output: project root directory path string.
sub _default_project_root {
    my ( $self, @candidates ) = @_;
    for my $candidate (@candidates) {
        return $candidate if $candidate;
    }
    return cwd();
}

# resolve(%args)
# Resolves the effective docker compose context and overlay stack.
# Input: optional project_root, addons, modes, services, compose args, and an
#        internal execution flag that defers runtime service discovery.
# Output: hash reference describing files, env, layers, precedence, and final command.
sub resolve {
    my ( $self, %args ) = @_;
    my $defer_service_discovery = delete $args{_defer_service_discovery} ? 1 : 0;
    my $project_root = $self->_default_project_root( $args{project_root}, $self->{paths}->current_project_root );
    my $compose_root = $self->_base_compose_root($project_root);
    my $docker_cfg  = $self->{config}->docker_config;
    my $docker_root = $self->_docker_config_root;
    my @passthrough = @{ $args{args} || [] };
    my @compose_files = ();
    my @layers;

    my @base = $self->_discover_base_files($compose_root);
    # A supplied -f/--file can be the complete base stack even when no
    # conventional Compose file exists in the project directory. Only retain
    # legacy runtime-file seeding when neither source provides a base.
    if ( $defer_service_discovery && !@base ) {
        my $argument_parts = $self->_compose_argument_parts(
            args         => \@passthrough,
            compose_root => $compose_root,
        );
        $defer_service_discovery = 0 if !@{ $argument_parts->{files} };
    }
    my $local_compose_services = !$defer_service_discovery && @base ? $self->_local_compose_services(\@base) : undef;
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
    my @requested_services = @{ $args{services} || [] };
    my @inferred_services = $defer_service_discovery ? () : $self->_infer_services_from_args(
        args         => \@passthrough,
        project_root => $project_root,
        service_map  => \%service_map,
    );
    my $has_explicit_services = @requested_services || @inferred_services;
    my @services = $defer_service_discovery ? () : $self->_resolve_effective_services(
        requested             => \@requested_services,
        inferred              => \@inferred_services,
        project_root          => $project_root,
        service_map           => \%service_map,
        local_compose_services => $local_compose_services,
    );

    # DD-862: file-gathering must use every ENABLED service, not just the
    # requested/effective ones - a requested service's own compose file may
    # declare `depends_on` another configured service, and Docker Compose can
    # only auto-start that dependency if its definition is present in the
    # merged -f stack too. Narrowing this to @services silently dropped the
    # dependency's file whenever it was not itself named on the command line.
    # @services (the requested/effective set) still governs everything else
    # below - env resolution, the resolved "services" field - only the FILE
    # set widens here.
    my @enabled_services = $defer_service_discovery ? () : $has_explicit_services
      ? $self->_discover_enabled_services(
        project_root => $project_root,
        service_map  => \%service_map,
      )
      : @services;
    my %file_gather_seen;
    my @file_gather_services = grep { !$file_gather_seen{$_}++ } ( @services, @enabled_services );

    my $service_files = $self->_gather_service_files(
        services     => \@file_gather_services,
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
        compose_root => $compose_root,
        addons       => \@addons,
        modes        => \@modes,
        services     => \@services,
        files        => \@files,
        base_files   => [@base],
        project_files => [@project_overlays],
        service_files => [ @{$service_files} ],
        addon_files  => [ @{$addon_files} ],
        mode_files   => [ @{$mode_files} ],
        compose_args => [@passthrough],
        service_map  => \%service_map,
        docker_env_inputs => {
            docker_cfg  => $docker_cfg,
            docker_root => $docker_root,
            addons      => [@addons],
            addon_map   => \%addon_map,
            modes       => [@modes],
            mode_map    => \%mode_map,
        },
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
# Input: requested and pre-inferred service arrays, local Compose service map,
# project_root, and the service definition map.
# Output: deduplicated list of service names.
sub _resolve_effective_services {
    my ( $self, %args ) = @_;
    my @services = @{ $args{requested} };
    my @inferred_services = @{ $args{inferred} };
    my %service_seen;
    @services = grep { !$service_seen{$_}++ } ( @services, @inferred_services );
    if ( !@services ) {
        my @auto_services = $self->_discover_enabled_services(
            project_root           => $args{project_root},
            service_map            => $args{service_map},
            local_compose_services => $args{local_compose_services},
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

    # DD-887: a single combined pass over the ORIGINAL string, matching both
    # ${VAR} and bare $VAR forms in one alternation - never two sequential
    # passes, which would re-scan the first pass's OUTPUT as input to the
    # second, letting one env var's own value (if it happens to contain a
    # "$NAME"-shaped substring) get a second, unintended expansion using a
    # completely unrelated env var.
    $path =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)/
        my $name = defined $1 ? $1 : $2;
        defined $ENV{$name} ? $ENV{$name} : '';
    /gex;

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
# Discovers isolated compose files for a named service from all active docker config roots.
# Input: service name and optional project_root.
# Output: ordered file paths, with each compose.yml base followed by an opted-in development.compose.yml overlay.
sub _discover_service_files {
    my ( $self, %args ) = @_;
    my $service      = $args{service} || return;
    my $project_root = $self->_default_project_root( $args{project_root} );
    return if $self->_service_folder_is_disabled(
        project_root => $project_root,
        service      => $service,
    );

    my @roots = $self->_service_lookup_roots(
        project_root => $project_root,
        service      => $service,
    );

    my @files;
    my %seen_file;
    my $development_enabled = $self->_service_folder_is_development(
        project_root => $project_root,
        service      => $service,
    );
    for my $root (@roots) {
        my $service_root = File::Spec->catdir( $root, $service );

        my $compose = File::Spec->catfile( $service_root, 'compose.yml' );
        push @files, $compose if -f $compose && !$seen_file{$compose}++;

        next if !$development_enabled;
        my $development = File::Spec->catfile( $service_root, 'development.compose.yml' );
        push @files, $development if -f $development && !$seen_file{$development}++;
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
        (!ref( $args{local_compose_services} ) || exists $args{local_compose_services}{$_})
          && !$self->_service_folder_is_disabled(
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
    my $project_root = $self->_default_project_root( $args{project_root} );
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
    my $project_root = $self->_default_project_root( $args{project_root} );
    return if $self->_service_folder_is_disabled(
        project_root => $project_root,
        service      => $service,
    );

    my @roots = $self->_service_lookup_roots(
        project_root => $project_root,
        service      => $service,
    );

    my @skill_roots;
    for my $root (@roots) {
        my $service_root = File::Spec->catdir( $root, $service );

        my $development = File::Spec->catfile( $service_root, 'development.compose.yml' );
        my $compose     = File::Spec->catfile( $service_root, 'compose.yml' );
        next if !-f $development && !-f $compose;

        my $skill_root = dirname( dirname($root) );
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
    my $project_root = $self->_default_project_root( $args{project_root} );
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
# Output: boolean true when any matching service layer contains disabled.yml.
sub _service_folder_is_disabled {
    my ( $self, %args ) = @_;
    my $service      = $args{service} || return 0;
    my $project_root = $self->_default_project_root( $args{project_root} );
    my @roots = $self->_service_lookup_roots(
        project_root => $project_root,
        service      => $service,
    );
    for my $root (@roots) {
        my $service_root = File::Spec->catdir( $root, $service );
        return 1 if -f File::Spec->catfile( $service_root, q{disabled.yml} );
    }
    return 0;
}

# _service_folder_is_development(%args)
# Checks whether the effective isolated service folder opts into its development compose overlay.
# Input: service name and optional project_root.
# Output: boolean true when any matching service layer contains develop.yml.
sub _service_folder_is_development {
    my ( $self, %args ) = @_;
    my $service      = $args{service} || return 0;
    my $project_root = $self->_default_project_root( $args{project_root} );
    my @roots = $self->_service_lookup_roots(
        project_root => $project_root,
        service      => $service,
    );
    for my $root (@roots) {
        my $service_root = File::Spec->catdir( $root, $service );
        return 1 if -f File::Spec->catfile( $service_root, 'develop.yml' );
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
    my $project_root = $self->_default_project_root( $args{project_root} );
    my @roots;
    my %seen;
    for my $runtime_root ( $self->{paths}->runtime_layers ) {
        my @candidates = ();
        my $config_docker_root = File::Spec->catdir( $runtime_root, 'config', 'docker' );
        push @candidates, $config_docker_root;
        push @candidates, $self->_installed_skill_docker_roots_for_runtime($runtime_root);

        for my $root (@candidates) {
            next if $seen{$root}++;
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
    while (@queue) {
        my $parent = shift @queue;
        opendir my $dh, $parent or next;
        for my $entry ( sorted_dir_entries($dh) ) {
            my $skill_root = File::Spec->catdir( $parent, $entry );
            next if !-d $skill_root;
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
    my $project_root = $self->_default_project_root( $args{project_root} );
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
# Writes the isolated-service disabled marker into the selected home runtime docker root.
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
    close $fh or die "Unable to close $marker: $!";
    return {
        action   => 'disable',
        disabled => 1,
        marker   => $marker,
        service  => $service,
    };
}

# enable_service(%args)
# Removes every active-layer disabled marker from one isolated service.
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
    _remove_service_layer_markers(
        $self,
        project_root => $args{project_root},
        service      => $service,
        marker_name  => 'disabled.yml',
    );
    return {
        action   => 'enable',
        disabled => 0,
        marker   => $marker,
        service  => $service,
    };
}

# enable_service_development(%args)
# Writes the opt-in marker in the selected home runtime for a service's development compose overlay.
# Input: service name and optional project_root.
# Output: hash reference describing the enabled development state and marker path.
sub enable_service_development {
    my ( $self, %args ) = @_;
    my $service = $args{service} || die "Usage: dashboard docker development enable <service>\n";
    my $marker = $self->_service_development_marker_path(
        project_root => $args{project_root},
        service      => $service,
    );
    die "Refusing service name that escapes the docker config root: $service\n"
      if !defined $marker;
    my ( undef, $dir ) = File::Spec->splitpath($marker);
    make_path($dir) if !-d $dir;
    open my $fh, '>', $marker or die "Unable to write $marker: $!";
    print {$fh} "---\ndevelopment: 1\n";
    close $fh or die "Unable to close $marker: $!";
    return {
        action      => 'development-enable',
        development => 1,
        marker      => $marker,
        service     => $service,
    };
}

# disable_service_development(%args)
# Removes every active-layer marker that enables a service's development compose overlay.
# Input: service name and optional project_root.
# Output: hash reference describing the disabled development state and marker path.
sub disable_service_development {
    my ( $self, %args ) = @_;
    my $service = $args{service} || die "Usage: dashboard docker development disable <service>\n";
    my $marker = $self->_service_development_marker_path(
        project_root => $args{project_root},
        service      => $service,
    );
    die "Refusing service name that escapes the docker config root: $service\n"
      if !defined $marker;
    _remove_service_layer_markers(
        $self,
        project_root => $args{project_root},
        service      => $service,
        marker_name  => 'develop.yml',
    );
    return {
        action      => 'development-disable',
        development => 0,
        marker      => $marker,
        service     => $service,
    };
}

# list_services(%args)
# Lists isolated docker services together with their effective enabled or disabled state.
# Input: optional project_root and filter values all, enabled, or disabled.
# Output: array reference of service state hash references in sorted service order.
sub list_services {
    my ( $self, %args ) = @_;
    my $project_root = $self->_default_project_root( $args{project_root} );
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
    my $resolved = $self->resolve(
        %args,
        _defer_service_discovery => $args{dry_run} ? 0 : 1,
    );
    return $resolved if $args{dry_run};

    my $old = cwd();
    my $compose_root = $resolved->{compose_root};
    chdir $compose_root or die "Unable to chdir to $compose_root: $!";
    local @ENV{ keys %{ $resolved->{env} } } = values %{ $resolved->{env} } if %{ $resolved->{env} };
    my $run_command = $self->_materialized_command($resolved);
    local @ENV{ keys %{ $resolved->{env} } } = values %{ $resolved->{env} } if %{ $resolved->{env} };
    my ( $stdout, $stderr, $exit_code ) = capture {
        system @{$run_command};
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

# run_streaming(%args)
# Executes a resolved Docker Compose operation with inherited stdout/stderr so
# interactive and long-running Compose commands retain their normal terminal
# behavior. It materializes layered files first and removes the temporary merge
# only after Compose exits.
# Input: normal resolve() arguments, or a resolved hash reference under resolved.
# Output: resolution hash reference with exit_code from the operational command.
sub run_streaming {
    my ( $self, %args ) = @_;
    local $?;
    my $resolved = delete $args{resolved};
    $resolved = $self->resolve(
        %args,
        _defer_service_discovery => $args{dry_run} ? 0 : 1,
    ) if !defined $resolved;
    return $resolved if $args{dry_run};

    my $old = cwd();
    my ( $result, $error );
    my $ok = eval {
        my $compose_root = $resolved->{compose_root};
        chdir $compose_root or die "Unable to chdir to $compose_root: $!";
        local @ENV{ keys %{ $resolved->{env} } } = values %{ $resolved->{env} } if %{ $resolved->{env} };
        my $command = $self->_materialized_command($resolved);
        local @ENV{ keys %{ $resolved->{env} } } = values %{ $resolved->{env} } if %{ $resolved->{env} };
        my $status = system @{$command};
        die "Unable to execute Docker Compose: $!\n" if $status == -1;
        my $signal = $status & 127;
        my $exit_code = $signal ? 128 + $signal : $status >> 8;
        $result = { %$resolved, exit_code => $exit_code };
        1;
    };
    $error = $@ if !$ok;

    chdir $old or die "Unable to restore cwd to $old: $!";
    die $error if defined $error;
    return $result;
}

# _materialized_command($resolved)
# Resolves the base Compose service set, discovers only those services' runtime
# overlays, materializes the final YAML, and constructs the requested command.
# Input: resolution hash ref with explicit base/non-service file groups,
# passthrough args, runtime roots, and Compose project root.
# Output: command array ref using one temporary merged file; a non-Compose
# command is returned unchanged.
#
# WHY THIS EXISTS (Problem 40 / DD-857): Docker Compose must first resolve the
# base stack so its resulting services mapping, rather than raw source parsing
# or command-line service guesses, decides which per-service overlays exist in
# this invocation. The layered runtime stack (~/.developer-dashboard, installed
# skills, the project's own .developer-dashboard, service/addon/mode overlays)
# can spread one service's definition across several files. Passing every layer
# as its own -f flag makes the operational command depend on
# Compose's own multi-file merge resolving that service correctly on every
# invocation; materializing once via `config` and running the real command
# against a single, already-resolved file removes that dependency entirely -
# whatever Compose would have merged is now sitting in one file before the
# operational command ever runs, so a service defined only by the combination
# of several partial layers cannot come out "not found" because one layer
# happened to be looked up in the wrong place or the wrong order. The final
# command also retains the original Compose project directory so Compose does
# not derive project identity or relative paths from the temporary merged file.
sub _materialized_command {
    my ( $self, $resolved ) = @_;

    # DD-597 shape: system() below mutates the caller's global $? as a side
    # effect; without this guard that stays set in the caller's process
    # (run(), and anything run() is itself called from) after this sub
    # returns, regardless of the exit code already captured locally below.
    local $?;
    my $command = $resolved->{command} || [];
    return $command if @{$command} < 2 || $command->[0] ne 'docker' || $command->[1] ne 'compose';

    my @compose_args = @{ $resolved->{compose_args} || [] };
    if ( !exists $resolved->{compose_args} ) {
        @compose_args = @{$command}[ 2 .. $#{$command} ] if @{$command} > 2;
    }
    my $argument_parts = $self->_compose_argument_parts(
        args         => \@compose_args,
        compose_root => $resolved->{compose_root},
    );
    my @project_directory = @{ $argument_parts->{project_directory} };
    my @global_args       = @{ $argument_parts->{global_args} };
    my @explicit_files    = @{ $argument_parts->{files} };
    my @operation_args    = @{ $argument_parts->{operation_args} };
    my @requested_services = @{ $resolved->{services} || [] };
    my $help_requested = ( grep { defined $_ && ( $_ eq '--help' || $_ eq '-h' ) } @operation_args )
      || ( @operation_args && defined $operation_args[0] && $operation_args[0] eq 'help' );
    return $command if $help_requested;

    my @initial_files;
    if ( exists $resolved->{base_files} ) {
        @initial_files = (
            @{ $resolved->{base_files} || [] },
            @{ $resolved->{project_files} || [] },
            ( @{ $resolved->{base_files} || [] } ? () : @{ $resolved->{service_files} || [] } ),
            @{ $resolved->{addon_files} || [] },
            @{ $resolved->{mode_files} || [] },
            @explicit_files,
        );
        @initial_files = $self->_finalize_compose_files(
            compose_files => \@initial_files,
            project_root  => $resolved->{project_root},
        );
    }
    else {
        @initial_files = ( @{ $resolved->{files} || [] }, @explicit_files );
    }

    my @initial_file_args;
    for my $file (@initial_files) {
        push @initial_file_args, '-f', $file;
    }
    my @base_config_command = ( 'docker', 'compose', @global_args, @project_directory, @initial_file_args, 'config' );
    my ( $base_output, $base_stderr, $base_exit ) = capture {
        system @base_config_command;
        return $? >> 8;
    };
    die "Unable to materialize merged docker compose config ($base_exit): $base_stderr" if $base_exit != 0;

    $base_output = _compose_yaml_utf8_bytes($base_output);
    my $base_document = eval { YAML::XS::Load($base_output) };
    die "Unable to parse resolved base docker compose config: $@" if $@;
    die "Resolved base docker compose config must contain a mapping\n" if ref($base_document) ne 'HASH';
    my $base_services = exists $base_document->{services} ? $base_document->{services} : {};
    die "Resolved base docker compose services must be a mapping\n" if ref($base_services) ne 'HASH';
    my @services = sort keys %{$base_services};
    my ($invalid_service) = grep {
        $_ eq '' || $_ eq '.' || $_ eq '..' || m{[\\/\0]}
    } @services;
    die "Resolved base docker compose contains an invalid service name '$invalid_service'\n"
      if defined $invalid_service;

    my @service_files;
    if ( exists $resolved->{base_files} ) {
        my $service_map = $resolved->{service_map} || {};
        my $modes       = $resolved->{modes} || [];
        my $service_file_list = $self->_gather_service_files(
            services     => \@services,
            service_map  => $service_map,
            project_root => $resolved->{project_root},
            modes        => $modes,
        );
        @service_files = @{$service_file_list};
    }

    my @final_files = @initial_files;
    if ( exists $resolved->{base_files} ) {
        @final_files = $self->_finalize_compose_files(
            compose_files => [
                @{ $resolved->{base_files} || [] },
                @{ $resolved->{project_files} || [] },
                @service_files,
                @{ $resolved->{addon_files} || [] },
                @{ $resolved->{mode_files} || [] },
                @explicit_files,
            ],
            project_root => $resolved->{project_root},
        );
    }

    $resolved->{services} = \@services;
    $resolved->{service_files} = \@service_files;
    $resolved->{files} = \@final_files;
    if ( my $env_inputs = $resolved->{docker_env_inputs} ) {
        my $skill_env = $self->_resolve_skill_service_env(
            project_root => $resolved->{project_root},
            services     => [ $self->_compose_environment_services(
                requested_services => \@requested_services,
                operation_args     => \@operation_args,
                base_services      => \@services,
                project_root       => $resolved->{project_root},
            ) ],
        );
        my %env = $self->_resolve_docker_env(
            skill_env   => $skill_env,
            docker_cfg  => $env_inputs->{docker_cfg},
            docker_root => $env_inputs->{docker_root},
            addons      => $env_inputs->{addons},
            addon_map   => $env_inputs->{addon_map},
            modes       => $env_inputs->{modes},
            mode_map    => $env_inputs->{mode_map},
        );
        $resolved->{env} = \%env;
        $resolved->{env_files} = $skill_env->{files};
    }

    my $merged = $base_output;
    if (@service_files) {
        my @final_file_args;
        for my $file (@final_files) {
            push @final_file_args, '-f', $file;
        }
        my @final_config_command = ( 'docker', 'compose', @global_args, @project_directory, @final_file_args, 'config' );
        local @ENV{ keys %{ $resolved->{env} } } = values %{ $resolved->{env} } if %{ $resolved->{env} || {} };
        my ( $effective_output, $stderr, $exit_code ) = capture {
            system @final_config_command;
            return $? >> 8;
        };
        die "Unable to materialize merged docker compose config ($exit_code): $stderr" if $exit_code != 0;
        $merged = _compose_yaml_utf8_bytes($effective_output);
    }

    my $tmp_dir  = File::Temp::tempdir( CLEANUP => 1 );
    my $tmp_file = File::Spec->catfile( $tmp_dir, 'merged-compose.yml' );
    open my $fh, '>:raw', $tmp_file or die "Unable to write $tmp_file: $!";
    print {$fh} $merged;
    _close_materialized_compose_file($fh) or die "Unable to close $tmp_file: $!";

    return [ 'docker', 'compose', @global_args, @project_directory, '-f', $tmp_file, @operation_args ];
}

# _compose_environment_services(%args)
# Selects the service-specific skill env layers used for this invocation's
# global Compose interpolation, rather than letting an unrelated service's
# same-named variable win merely because its layer was enumerated last.
# Input: requested services, parsed operation arguments, effective base
# services, and the project root.
# Output: ordered service names used to resolve skill env files; falls back to
# all base services when the request names none of them.
sub _compose_environment_services {
    my ( $self, %args ) = @_;
    my @base_services = @{ $args{base_services} || [] };
    my %base_service = map { $_ => 1 } @base_services;
    my @requested = @{ $args{requested_services} || [] };

    if ( !@requested ) {
        my %base_service_map = map { $_ => {} } @base_services;
        @requested = $self->_infer_services_from_args(
            args         => $args{operation_args} || [],
            project_root => $args{project_root},
            service_map  => \%base_service_map,
        );
    }

    my %seen;
    my @selected = grep { $base_service{$_} && !$seen{$_}++ } @requested;
    return @selected ? @selected : @base_services;
}

# _close_materialized_compose_file($handle)
# Closes the temporary YAML file handle and reports the operating system result
# so the caller can preserve a clear path-specific error message.
# Input: open file handle for the materialized Compose YAML.
# Output: true on successful close, false on close failure.
sub _close_materialized_compose_file {
    my ($handle) = @_;
    return close $handle;
}

# _compose_argument_parts(%args)
# Separates Docker Compose global options, explicit base files, project directory,
# and the requested operation without relying on file-count offsets in argv.
# Input: Compose passthrough args array ref and compose root path.
# Output: hash reference containing global_args, files, project_directory, and operation_args.
sub _compose_argument_parts {
    my ( $self, %args ) = @_;
    my @args = @{ $args{args} || [] };
    my @global_args;
    my @files;
    my @operation_args;
    my @project_directory = ( '--project-directory', $args{compose_root} );
    my %takes_value = map { $_ => 1 } qw(-f --file -p --project-name --project-directory --env-file --profile --ansi --progress --parallel);
    my $operation_started = 0;
    my $argument_index = 0;

    while (@args) {
        my $argument = shift @args;
        $argument_index++;
        die "Docker Compose argument $argument_index is undefined\n" if !defined $argument;
        if ($operation_started) {
            push @operation_args, $argument;
            next;
        }
        if ( $argument eq '--' ) {
            $operation_started = 1;
            push @operation_args, @args;
            last;
        }
        if ( $argument eq '--project-directory' ) {
            my $path = @args ? shift @args : undef;
            die "Docker Compose --project-directory requires a path\n"
                if !defined $path || $path eq '' || $path =~ /^-/;
            @project_directory = ( $argument, $path );
            next;
        }
        if ( $argument =~ /^--project-directory=(.*)$/ ) {
            die "Docker Compose --project-directory requires a path\n" if $1 eq '';
            @project_directory = ($argument);
            next;
        }
        if ( $argument eq '-f' || $argument eq '--file' ) {
            my $path = @args ? shift @args : undef;
            die "Docker Compose $argument requires a path\n" if !defined $path || $path eq '';
            push @files, $path;
            next;
        }
        if ( $argument =~ /^--file=(.*)$/ ) {
            die "Docker Compose --file requires a path\n" if $1 eq '';
            push @files, $1;
            next;
        }
        if ( $argument =~ /^--(?:project-name|env-file|profile|ansi|progress|parallel)=/ || $argument =~ /^-p./ ) {
            push @global_args, $argument;
            next;
        }
        if ( $takes_value{$argument} ) {
            my $value = @args ? shift @args : undef;
            die "Docker Compose $argument requires a value\n" if !defined $value || $value eq '';
            push @global_args, $argument, $value;
            next;
        }
        if ( $argument =~ /^-/ ) {
            push @global_args, $argument;
            next;
        }
        $operation_started = 1;
        push @operation_args, $argument;
    }

    return {
        global_args       => \@global_args,
        files             => \@files,
        project_directory => \@project_directory,
        operation_args    => \@operation_args,
    };
}

# _compose_yaml_utf8_bytes($output)
# Keeps valid UTF-8 sequences unchanged and upgrades isolated legacy single-byte
# characters in Compose output to UTF-8 before the merged file is written.
# Input: captured Compose config output as a Perl scalar.
# Output: byte string containing well-formed UTF-8.
sub _compose_yaml_utf8_bytes {
    my ($output) = @_;
    $output = '' if !defined $output;
    my $bytes = utf8::is_utf8($output) ? encode_utf8($output) : $output;
    my $normalized = '';

    while ( length $bytes ) {
        if ( $bytes =~ /\A( [\x00-\x7F]
                          | [\xC2-\xDF][\x80-\xBF]
                          | \xE0[\xA0-\xBF][\x80-\xBF]
                          | [\xE1-\xEC\xEE-\xEF][\x80-\xBF]{2}
                          | \xED[\x80-\x9F][\x80-\xBF]
                          | \xF0[\x90-\xBF][\x80-\xBF]{2}
                          | [\xF1-\xF3][\x80-\xBF]{3}
                          | \xF4[\x80-\x8F][\x80-\xBF]{2}
                        )/x ) {
            my $sequence = $1;
            $normalized .= $sequence;
            substr $bytes, 0, length($sequence), '';
            next;
        }

        my $legacy_octet = substr $bytes, 0, 1, '';
        my $character = decode( 'Windows-1252', $legacy_octet, FB_DEFAULT );
        $normalized .= encode_utf8($character);
    }

    return $normalized;
}

# _close_local_compose_source($fh)
# Closes a raw local Compose source handle after its bytes have been read.
# Input: open filehandle glob.
# Output: the close result from Perl's built-in close operation.
sub _close_local_compose_source {
    my ($fh) = @_;
    return close $fh;
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

# _base_compose_root($project_root)
# Prefers an invocation-directory Compose file so the caller's local project
# defines the base stack; otherwise the discovered project root remains the
# base directory.
# Input: resolved project root directory.
# Output: invocation directory when it contains a standard Compose file, else
#         the supplied project root.
sub _base_compose_root {
    my ( $self, $project_root ) = @_;
    my $invocation_root = cwd();
    return $invocation_root if $self->_discover_base_files($invocation_root);
    return $project_root;
}

# _local_compose_services($files)
# Reads service names from local base Compose files to scope automatic runtime
# overlays to services the local project actually declares. It normalizes a
# raw read-copy before parsing so legacy single-byte text cannot fail before
# Compose itself materializes the effective configuration.
# Input: array reference of base Compose file paths.
# Output: hash reference keyed by declared service names; malformed YAML or
#         invalid services mappings die with the offending file named; file
#         read and close failures also die with the source path.
sub _local_compose_services {
    my ( $self, $files ) = @_;
    die "Compose base files must be an array reference\n" if ref($files) ne 'ARRAY';

    my %services;
    for my $file ( @{$files} ) {
        open my $fh, '<:raw', $file or die "Unable to read local Compose file '$file': $!";
        my $source;
        { local $/; $source = <$fh> }
        _close_local_compose_source($fh) or die "Unable to close local Compose file '$file': $!";
        $source = _compose_yaml_utf8_bytes($source);

        my $document = eval { YAML::XS::Load($source) };
        die "Unable to parse local Compose file '$file': $@" if $@;
        die "Local Compose file '$file' must contain a mapping\n" if ref($document) ne 'HASH';
        next if !exists $document->{services};
        die "Local Compose file '$file' services must be a mapping\n" if ref( $document->{services} ) ne 'HASH';
        for my $name ( keys %{ $document->{services} } ) {
            die "Local Compose file '$file' has an invalid service name\n" if $name eq '';
            $services{$name} = 1;
        }
    }
    return \%services;
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
# Resolves the disabled.yml marker path in the selected home runtime docker root.
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

# _service_development_marker_path(%args)
# Resolves a contained service path for the development-mode marker file.
# Input: service name and optional project_root.
# Output: absolute develop.yml marker path string, or undef if the service escapes its root.
sub _service_development_marker_path {
    my ( $self, %args ) = @_;
    my $service = $args{service} || die "Missing service\n";
    my $root = $self->_service_toggle_root(%args);
    my $service_root = _contained_service_path( $root, $service );
    return if !defined $service_root;
    return File::Spec->catfile( $service_root, 'develop.yml' );
}

# _service_toggle_root(%args)
# Returns the selected home config/docker root where toggle markers are written.
# Input: optional project_root accepted for call-site symmetry; marker writes stay home-scoped.
# Output: absolute docker root directory path string.
sub _service_toggle_root {
    my ( $self, %args ) = @_;
    return File::Spec->catdir( $self->{paths}->home_runtime_root, 'config', 'docker' );
}

# _remove_service_layer_markers($self, %args)
# Removes one supported marker from every existing runtime layer for a service.
# Input: DockerCompose object, service name, optional project root, and the
#        internal marker filename (disabled.yml or develop.yml).
# Output: count of removed marker files; dies with the affected path on failure.
sub _remove_service_layer_markers {
    my ( $self, %args ) = @_;
    my $service = $args{service} || die 'Missing service';
    my $marker_name = $args{marker_name} || die 'Missing service marker name';
    die "Unsupported service marker '$marker_name'\n"
      if $marker_name ne 'disabled.yml' && $marker_name ne 'develop.yml';

    my @roots = $self->_service_lookup_roots(
        project_root => $args{project_root},
        service      => $service,
    );
    my $removed = 0;
    for my $root (@roots) {
        my $service_root = _contained_service_path( $root, $service );
        die "Refusing service name that escapes the docker config root: $service\n"
          if !defined $service_root;
        my $marker = File::Spec->catfile( $service_root, $marker_name );
        next if !-e $marker && !-l $marker;
        unlink $marker or die "Unable to remove $marker: $!";
        $removed++;
    }

    return $removed;
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

When standard Compose files exist in the invocation directory, they are used
as the local base and the command runs from that directory. At execution time,
the resolver first runs C<docker compose config> using the base and configured
non-service layers, then reads the resulting C<services:> map. That resolved
service list is authoritative: CLI service names and service folders not
present in the base config cannot cause overlays to be loaded. Matching
service folders are then searched through home, project, and nested skill
runtime layers; C<disabled.yml> excludes a service overlay, while
C<development.compose.yml> is added only when a matching C<develop.yml>
marker exists. The resolver materializes the selected service overlays and
only then runs the requested Compose operation. Dry-run output remains a
non-executing preview. When no local base file exists, Compose resolves its
normal working-directory config before the same service-selection step. When
no local base or explicit Compose file exists but runtime service files do,
those enabled files seed the first config pass to preserve ecosystem-wide
auto-discovery; the emitted services map still determines the final stack.
Native Compose help requests and help arguments belonging to commands nested
under C<exec> bypass materialization and pass through unchanged, because their
output is not YAML config data.

Every Docker Compose operation is materialized before execution, even when
resolution selected no explicit layered files: Compose first discovers and
emits its effective base config from the Compose working directory, then the
requested verb consumes that generated temporary file. When Compose layers
are selected, the effective project directory is explicitly passed to both
the merge and final command.
This keeps lifecycle operations such as C<build>, C<up>, and C<down> anchored
to the invocation project rather than the temporary merged file. A user's
explicit C<--project-directory> takes precedence. Missing or empty values for
that option, and undefined argument values, are rejected before invoking
Compose. The public Docker helper executes operational requests through
C<run_streaming>, which uses the materialized merge, preserves the resolved
project directory, inherits stdout and stderr, and keeps the temporary file
available until the Compose child exits. This preserves live output for long
operations such as C<build>, C<up>, and log-following commands.

Captured merge output is normalized before it becomes a temporary file:
already-valid UTF-8 is preserved, isolated Windows-1252 bytes are converted to
UTF-8, and undefined Windows-1252 octets become the Unicode replacement
character. The temporary YAML file is written in raw mode, so every action
using the materializing runner receives valid UTF-8 rather than invalid bytes
inherited from one of its Compose layers.

=head1 METHODS

=head2 new, resolve, list_services, run, run_streaming

Construct, resolve, list, and optionally execute compose operations.
C<resolve> returns both the project discovery root and the effective Compose
working root so nested invocation directories retain their local project file.
C<run> captures output for callers that need a result payload. C<run_streaming>
executes the operational command with inherited stdout and stderr and returns
its exit code; it accepts the usual resolution arguments or a previously
resolved hash under C<resolved>. The public CLI uses this method so the
materialized file remains present until Compose completes.

=head2 enable_service_development, disable_service_development

Create or remove the selected-home-runtime C<develop.yml> marker for one
isolated service. A marker in any matching service folder across active runtime
layers enables C<development.compose.yml> overlays for the service. Removing
the marker removes every C<develop.yml> file for that service across those
layers. New markers use C<~/.developer-dashboard> when it exists (or when
neither runtime name exists), and C<~/.d2> only when that is the existing home
runtime name.
An existing C<compose.yml> remains the base and is loaded first. If development
is enabled but its file is absent, resolution continues with the base file and
does not report an error.

  $docker->enable_service_development( service => 'web' );
  $docker->disable_service_development( service => 'web' );

=head2 disable_service, enable_service

Write and remove the C<disabled.yml> marker for one isolated service, below the
selected home runtime C<config/docker> root.
Any matching service layer containing C<disabled.yml> disables the service;
enabling removes every such marker before reporting success. New markers use
the same home runtime name selection as development markers.

The service name reaches these methods straight from the command line and is
therefore untrusted. It is resolved below the toggle root and any name that
escapes that root is B<refused> - both methods die rather than fall back to the
unchecked path. Resolution is lexical and never consults the filesystem, so the
containment decision cannot change between the check and the write or unlink
that follows it. Marker removal walks only existing service folders discovered
by the layered service resolver, and marker names are restricted to the two
internal toggle files.

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

This module resolves and runs dashboard-managed Docker Compose stacks. For real
operations it resolves the base config first and selects layered
C<config/docker> service files only from Compose's resulting services map;
dry-run previews can infer candidate services without starting Compose. It also
exports the effective docker config root and constructs the final command.
Operational CLI requests use C<run_streaming> so layered configuration is
materialized before execution and normal terminal output remains live.

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
