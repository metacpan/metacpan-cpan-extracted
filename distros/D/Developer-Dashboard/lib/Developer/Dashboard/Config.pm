package Developer::Dashboard::Config;

use strict;
use warnings;

our $VERSION = '2.35';

use File::Spec;
use Cwd qw(cwd);

use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::SkillDispatcher;

# new(%args)
# Constructs a configuration loader bound to files and paths.
# Input: files and paths objects, plus optional repo_root.
# Output: Developer::Dashboard::Config object.
sub new {
    my ( $class, %args ) = @_;
    my $files = $args{files} || die 'Missing file registry';
    my $paths = $args{paths} || die 'Missing path registry';
    return bless {
        files => $files,
        paths => $paths,
        repo_root => $args{repo_root},
    }, $class;
}

# load_global()
# Loads the user-global dashboard configuration file.
# Input: none.
# Output: configuration hash reference.
sub load_global {
    my ($self) = @_;
    my $merged = {};
    for my $file ( reverse $self->_global_config_files ) {
        next if !-f $file;
        open my $fh, '<:raw', $file or die "Unable to read $file: $!";
        local $/;
        $merged = $self->_merge_hashes( $merged, json_decode(<$fh>) );
    }
    for my $fragment ( $self->_skill_config_fragments ) {
        $merged = $self->_merge_hashes( $merged, $fragment );
    }
    return $merged;
}

# save_global($config)
# Saves the user-global dashboard configuration file.
# Input: configuration hash reference.
# Output: written file path string.
sub save_global {
    my ( $self, $config ) = @_;
    my $file = $self->_global_config_file;
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode( $config || {} );
    close $fh;
    $self->{paths}->secure_file_permissions($file);
    return $file;
}

# save_global_defaults($defaults)
# Persists only missing global configuration defaults without overwriting
# existing user settings in config.json.
# Input: defaults hash reference.
# Output: written file path string.
sub save_global_defaults {
    my ( $self, $defaults ) = @_;
    $defaults ||= {};
    my $current = $self->load_global;
    my $merged = $self->_merge_hashes( $defaults, $current );
    return $self->save_global($merged);
}

# ensure_global_file()
# Ensures the writable config.json exists, seeding '{}' only when the file is
# missing and leaving any existing file untouched.
# Input: none.
# Output: writable configuration file path string.
sub ensure_global_file {
    my ($self) = @_;
    my $file = $self->_global_config_file;
    return $file if -e $file;
    return $self->save_global( {} );
}

# load_repo()
# Loads repo-local configuration from the active project root.
# Input: none.
# Output: configuration hash reference.
sub load_repo {
    my ($self) = @_;
    $self->{repo_root} = $self->{paths}->current_project_root if !$self->{repo_root};
    my $repo = $self->{repo_root} || return {};
    my $file = File::Spec->catfile( $repo, '.developer-dashboard.json' );
    return {} if !-f $file;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    return json_decode(<$fh>);
}

# merged()
# Returns the merged global and repo-local configuration view.
# Input: none.
# Output: merged configuration hash reference.
sub merged {
    my ($self) = @_;
    my $global = $self->load_global;
    my $repo   = $self->load_repo;

    return $self->_merge_hashes( $global, $repo );
}

# _merge_hashes($left, $right)
# Recursively merges configuration hashes so nested config domains can extend each other.
# Input: two hash references where right-hand values override left-hand values.
# Output: merged hash reference.
sub _merge_hashes {
    my ( $self, $left, $right ) = @_;
    $left  ||= {};
    $right ||= {};

    my %merged = (%{$left});
    for my $key ( keys %{$right} ) {
        if ( ref( $left->{$key} ) eq 'HASH' && ref( $right->{$key} ) eq 'HASH' ) {
            $merged{$key} = $self->_merge_hashes( $left->{$key}, $right->{$key} );
            next;
        }
        if ( ref( $left->{$key} ) eq 'ARRAY' && ref( $right->{$key} ) eq 'ARRAY' ) {
            if ( $key eq 'collectors' ) {
                $merged{$key} = $self->_merge_named_hash_array( $left->{$key}, $right->{$key}, 'name' );
                next;
            }
            if ( $key eq 'providers' ) {
                $merged{$key} = $self->_merge_named_hash_array( $left->{$key}, $right->{$key}, 'id' );
                next;
            }
        }
        $merged{$key} = $right->{$key};
    }

    return \%merged;
}

# _merge_named_hash_array($left, $right, $identity_key)
# Merges configuration arrays of hashes while preserving order and allowing
# deeper layers to override matching logical identities.
# Input: left and right array references plus the identity key string.
# Output: merged array reference.
sub _merge_named_hash_array {
    my ( $self, $left, $right, $identity_key ) = @_;
    my @merged = ();
    my %positions;

    for my $item ( @{ $left || [] }, @{ $right || [] } ) {
        if (
            ref($item) eq 'HASH'
            && defined $identity_key
            && $identity_key ne ''
            && defined $item->{$identity_key}
            && $item->{$identity_key} ne ''
        ) {
            if ( exists $positions{ $item->{$identity_key} } ) {
                $merged[ $positions{ $item->{$identity_key} } ] = $item;
                next;
            }
            $positions{ $item->{$identity_key} } = scalar @merged;
        }
        push @merged, $item;
    }

    return \@merged;
}

# collectors()
# Returns all configured collectors from merged configuration.
# Input: none.
# Output: array reference of collector job hash references.
sub collectors {
    my ($self) = @_;
    my $cfg = $self->merged;
    my @jobs = ();

    if ( ref( $cfg->{collectors} ) eq 'ARRAY' ) {
        push @jobs, @{ $cfg->{collectors} };
    }
    push @jobs, $self->_skill_collectors;

    if ( my $filter = $ENV{DEVELOPER_DASHBOARD_CHECKERS} ) {
        my %wanted = map { $_ => 1 } grep { defined && $_ ne '' } split /:/, $filter;
        @jobs = grep { ref($_) eq 'HASH' && $wanted{ $_->{name} } } @jobs;
    }

    return \@jobs;
}

# path_aliases()
# Returns configured path aliases from merged configuration.
# Input: none.
# Output: hash reference of path aliases.
sub path_aliases {
    my ($self) = @_;
    my $cfg = $self->merged;
    return {} if ref( $cfg->{path_aliases} ) ne 'HASH';
    return $self->_expand_path_aliases( $cfg->{path_aliases} );
}

# global_path_aliases()
# Returns only the user-global configured path aliases.
# Input: none.
# Output: hash reference of global path aliases.
sub global_path_aliases {
    my ($self) = @_;
    my $cfg = $self->load_global;
    return {} if ref( $cfg->{path_aliases} ) ne 'HASH';
    return $self->_expand_path_aliases( $cfg->{path_aliases} );
}

# web_workers()
# Returns the configured default Starman worker count.
# Input: none.
# Output: positive integer worker count.
sub web_workers {
    my ($self) = @_;
    my $cfg = $self->merged;
    my $workers = $cfg->{web}{workers};
    return 1 if !defined $workers;
    return 1 if $workers !~ /^\d+$/;
    return 1 if $workers < 1;
    return $workers + 0;
}

# save_global_web_workers($workers)
# Persists the default Starman worker count in the writable runtime config.
# Input: positive integer worker count.
# Output: hash reference containing the saved worker count.
sub save_global_web_workers {
    my ( $self, $workers ) = @_;
    die 'Missing worker count' if !defined $workers || $workers eq '';
    die 'Worker count must be a positive integer' if $workers !~ /^\d+$/ || $workers < 1;

    my $cfg = $self->load_global;
    $cfg->{web} = {} if ref( $cfg->{web} ) ne 'HASH';
    $cfg->{web}{workers} = $workers + 0;
    $self->save_global($cfg);

    return {
        workers => $workers + 0,
    };
}

# web_settings()
# Returns the current web service settings (host, port, workers, ssl, and optional SSL SAN aliases).
# Loads from global config with sensible defaults if not configured.
# Input: none.
# Output: hash reference with host, port, workers, ssl, and ssl_subject_alt_names keys.
sub web_settings {
    my ($self) = @_;
    my $cfg = $self->merged;
    my $web = $cfg->{web} || {};

    return {
        host                  => $web->{host} || '0.0.0.0',
        port                  => defined $web->{port} && $web->{port} =~ /^\d+$/ ? $web->{port} + 0 : 7890,
        workers               => defined $web->{workers} && $web->{workers} =~ /^\d+$/ && $web->{workers} > 0 ? $web->{workers} + 0 : 1,
        ssl                   => $web->{ssl} ? 1 : 0,
        ssl_subject_alt_names => $self->_normalize_ssl_subject_alt_names( $web->{ssl_subject_alt_names} ),
    };
}

# save_global_web_settings(%args)
# Persists web service settings (host, port, workers, ssl, and optional SSL SAN aliases) in the writable runtime config.
# Only saves settings that are explicitly provided, leaving others untouched.
# Input: named arguments (host, port, workers, ssl, ssl_subject_alt_names) - any or all can be omitted.
# Output: hash reference containing the saved settings.
sub save_global_web_settings {
    my ( $self, %args ) = @_;
    my $result = {};

    # Validate and prepare each setting
    if ( defined $args{host} ) {
        die 'Host cannot be empty' if $args{host} eq '';
        $result->{host} = $args{host};
    }

    if ( defined $args{port} ) {
        die 'Port must be numeric' if $args{port} !~ /^\d+$/;
        die 'Port must be between 1 and 65535' if $args{port} < 1 || $args{port} > 65535;
        $result->{port} = $args{port} + 0;
    }

    if ( defined $args{workers} ) {
        die 'Worker count must be numeric' if $args{workers} !~ /^\d+$/;
        die 'Worker count must be at least 1' if $args{workers} < 1;
        $result->{workers} = $args{workers} + 0;
    }

    if ( defined $args{ssl} ) {
        $result->{ssl} = $args{ssl} ? 1 : 0;
    }

    if ( exists $args{ssl_subject_alt_names} ) {
        $result->{ssl_subject_alt_names} = $self->_normalize_ssl_subject_alt_names( $args{ssl_subject_alt_names} );
    }

    # Load current config and update with new values
    my $cfg = $self->load_global;
    $cfg->{web} = {} if ref( $cfg->{web} ) ne 'HASH';

    for my $key ( keys %{$result} ) {
        $cfg->{web}{$key} = $result->{$key};
    }

    $self->save_global($cfg);

    return $result;
}

# _normalize_ssl_subject_alt_names($names)
# Normalizes one configured SSL SAN list into simple trimmed strings.
# Input: array reference of names/IPs or any other value.
# Output: normalized array reference with blank entries removed.
sub _normalize_ssl_subject_alt_names {
    my ( $self, $names ) = @_;
    return [] if ref($names) ne 'ARRAY';
    my @normalized;
    for my $name ( @{$names} ) {
        next if !defined $name;
        next if ref($name);
        $name =~ s/^\s+//;
        $name =~ s/\s+$//;
        next if $name eq '';
        push @normalized, $name;
    }
    return \@normalized;
}

# save_global_path_alias($name, $path)
# Persists or updates a user-global path alias without disturbing other config domains.
# Input: alias name string and target path string.
# Output: hash reference containing the stored alias mapping.
sub save_global_path_alias {
    my ( $self, $name, $path ) = @_;
    die 'Missing path alias name' if !defined $name || $name eq '';
    die 'Missing path alias target' if !defined $path || $path eq '';

    my $cfg = $self->load_global;
    $cfg->{path_aliases} = {} if ref( $cfg->{path_aliases} ) ne 'HASH';
    my $stored_path = $self->_normalize_home_path($path);
    $cfg->{path_aliases}{$name} = $stored_path;
    $self->save_global($cfg);

    return {
        name => $name,
        path => $self->_expand_config_path($stored_path),
    };
}

# remove_global_path_alias($name)
# Deletes a user-global path alias when present and otherwise remains idempotent.
# Input: alias name string.
# Output: hash reference containing alias name and removal flag.
sub remove_global_path_alias {
    my ( $self, $name ) = @_;
    die 'Missing path alias name' if !defined $name || $name eq '';

    my $cfg = $self->load_global;
    $cfg->{path_aliases} = {} if ref( $cfg->{path_aliases} ) ne 'HASH';
    my $removed = delete $cfg->{path_aliases}{$name} ? 1 : 0;
    $self->save_global($cfg);

    return {
        name    => $name,
        removed => $removed,
    };
}

# _normalize_home_path($path)
# Rewrites home-relative absolute paths into portable $HOME-prefixed config values.
# Input: path string that may live under the current home directory.
# Output: path string suitable for config persistence.
sub _normalize_home_path {
    my ( $self, $path ) = @_;
    return $path if !defined $path || $path eq '';

    my $home = $self->{paths}->home;
    return $path if !defined $home || $home eq '';
    return '$HOME' if $path eq $home;

    my $home_prefix = $home . '/';
    return '$HOME/' . substr( $path, length($home_prefix) ) if index( $path, $home_prefix ) == 0;

    return $path;
}

# _expand_config_path($path)
# Expands stored $HOME-style config paths back into concrete local filesystem paths.
# Input: stored path string that may start with $HOME or ~.
# Output: expanded path string for runtime use.
sub _expand_config_path {
    my ( $self, $path ) = @_;
    return $path if !defined $path || $path eq '';

    my $home = $self->{paths}->home;
    return $home if defined $home && $path eq '$HOME';
    return $home . substr( $path, 5 ) if defined $home && $path =~ /^\$HOME(?=\/)/;
    return $home . substr( $path, 1 ) if defined $home && $path =~ /^~/;

    return $path;
}

# _expand_path_aliases($aliases)
# Expands stored path-alias targets into runtime-ready absolute paths.
# Input: hash reference of alias-to-path mappings.
# Output: hash reference with expanded path values.
sub _expand_path_aliases {
    my ( $self, $aliases ) = @_;
    my %expanded;
    for my $name ( keys %{ $aliases || {} } ) {
        $expanded{$name} = $self->_expand_config_path( $aliases->{$name} );
    }
    return \%expanded;
}

# docker_config()
# Returns docker compose configuration from merged configuration.
# Input: none.
# Output: docker configuration hash reference.
sub docker_config {
    my ($self) = @_;
    my $cfg = $self->merged;
    return {} if ref( $cfg->{docker} ) ne 'HASH';
    return { %{ $cfg->{docker} } };
}

# providers()
# Returns configured provider page definitions.
# Input: none.
# Output: array reference of provider hashes.
sub providers {
    my ($self) = @_;
    my $cfg = $self->merged;
    my @providers = ();
    push @providers, @{ $cfg->{providers} } if ref( $cfg->{providers} ) eq 'ARRAY';
    return \@providers;
}

# _global_config_file()
# Returns the writable global configuration file path for the effective runtime root.
# Input: none.
# Output: writable configuration file path string.
sub _global_config_file {
    my ($self) = @_;
    return File::Spec->catfile( $self->{paths}->config_root, 'config.json' );
}

# _global_config_files()
# Returns the global configuration file candidates in effective lookup order.
# Input: none.
# Output: ordered list of configuration file path strings.
sub _global_config_files {
    my ($self) = @_;
    return map { File::Spec->catfile( $_, 'config.json' ) } $self->{paths}->config_roots;
}

# _skill_config_fragments()
# Loads installed skill config/config.json payloads as underscored runtime config fragments.
# Input: none.
# Output: ordered list of hash refs such as { _skill_name => { ... } }.
sub _skill_config_fragments {
    my ($self) = @_;
    my @fragments;
    for my $entry ( $self->_skill_config_entries ) {
        my $fragment = $entry->{dispatcher}->config_fragment( $entry->{skill_name} );
        push @fragments, $fragment if ref($fragment) eq 'HASH' && %{$fragment};
    }
    return @fragments;
}

# _skill_config_entries()
# Enumerates installed skill config payloads together with the skill name and dispatcher.
# Input: none.
# Output: ordered list of hash refs with skill_name, skill_root, config, and dispatcher.
sub _skill_config_entries {
    my ($self) = @_;
    my $dispatcher = Developer::Dashboard::SkillDispatcher->new( paths => $self->{paths} );
    my @entries;
    for my $skill_root ( $self->{paths}->installed_skill_roots ) {
        my ($skill_name) = $skill_root =~ m{/([^/]+)\z};
        next if !defined $skill_name || $skill_name eq '';
        my $config = $dispatcher->get_skill_config($skill_name);
        next if ref($config) ne 'HASH' || !%{$config};
        push @entries,
          {
            skill_name => $skill_name,
            skill_root => $skill_root,
            config     => $config,
            dispatcher => $dispatcher,
          };
    }
    return @entries;
}

# _skill_collectors()
# Expands installed skill config collectors into the managed fleet using repo-qualified names.
# Input: none.
# Output: ordered list of collector job hash references.
sub _skill_collectors {
    my ($self) = @_;
    my @jobs;
    for my $entry ( $self->_skill_config_entries ) {
        my $collectors = $entry->{config}{collectors};
        next if ref($collectors) ne 'ARRAY';
        for my $job ( @{$collectors} ) {
            next if ref($job) ne 'HASH';
            next if !defined $job->{name} || $job->{name} eq '';
            my $qualified_name = $job->{name} =~ /^\Q$entry->{skill_name}\E\./
              ? $job->{name}
              : $entry->{skill_name} . '.' . $job->{name};
            push @jobs,
              {
                %{$job},
                name       => $qualified_name,
                skill_name => $entry->{skill_name},
                skill_root => $entry->{skill_root},
              };
        }
    }
    return @jobs;
}

1;

__END__

=head1 NAME

Developer::Dashboard::Config - merged configuration loader

=head1 SYNOPSIS

  my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);
  my $merged = $config->merged;

=head1 DESCRIPTION

This module loads and merges global and repo-local configuration for Developer
Dashboard.

=head1 METHODS

=head2 new, load_global, save_global, load_repo, merged, collectors, path_aliases, global_path_aliases, web_workers, save_global_web_workers, web_settings, save_global_web_settings, save_global_path_alias, remove_global_path_alias, docker_config, providers

Load and expose configuration domains used by the runtime.

The web_settings() and save_global_web_settings() methods manage web service settings
including host, port, workers, ssl flag, and optional C<ssl_subject_alt_names>
entries used to extend the generated HTTPS certificate. These settings persist
across restart, so dashboard restart inherits the previous serve session
configuration.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module owns runtime configuration files such as F<config/config.json>, path aliases, web settings, collector definitions, and feature-specific config trees. It loads the effective config through C<DD-OOP-LAYERS> and writes changes back to the deepest participating runtime root.

=head1 WHY IT EXISTS

It exists because configuration has to obey the same layered runtime rules as pages, hooks, and state. Centralizing config lookup and writes prevents commands from accidentally ignoring project-local overrides or overwriting the wrong runtime layer.

=head1 WHEN TO USE

Use this file when changing config schema defaults, alias persistence, collector definitions from config, or any feature that reads or writes under F<config/> in the runtime tree.

=head1 HOW TO USE

Construct it with the file registry and path registry, then use the accessor and persistence methods instead of reading config JSON directly. New config-backed features should register their data under the appropriate runtime config directory and let this module handle loading rules.

=head1 WHAT USES IT

It is used by init flows, path alias commands, auth/session bootstrap, collector refresh, web server settings, api-dashboard/sql-dashboard config storage, and release/integration tests that verify runtime config behavior.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Config -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/06-env-overrides.t t/18-web-service-config.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
