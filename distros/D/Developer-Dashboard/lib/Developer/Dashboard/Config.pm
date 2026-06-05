package Developer::Dashboard::Config;

use strict;
use warnings;

our $VERSION = '4.03';

use File::Spec;
use Cwd qw(cwd);

use Developer::Dashboard::JSON qw(json_decode json_encode);

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
    my $current = $self->_load_writable_global;
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
                $merged[ $positions{ $item->{$identity_key} } ] = $self->_merge_named_hash_item(
                    $merged[ $positions{ $item->{$identity_key} } ],
                    $item,
                );
                next;
            }
            $positions{ $item->{$identity_key} } = scalar @merged;
        }
        push @merged, $item;
    }

    return \@merged;
}

# _merge_named_hash_item($left, $right)
# Merges two logical array members so deeper layers can override individual keys
# without discarding inherited nested hash settings.
# Input: left and right item values from a named array.
# Output: merged item value with right-hand overrides applied.
sub _merge_named_hash_item {
    my ( $self, $left, $right ) = @_;
    return $right if ref($left) ne 'HASH' || ref($right) ne 'HASH';
    return $self->_merge_hashes( $left, $right );
}

# collectors()
# Returns all configured collectors from merged configuration.
# Input: none.
# Output: array reference of collector job hash references.
sub collectors {
    my ($self) = @_;
    my $cfg = $self->merged;
    my @jobs = @{ $self->_builtin_collectors };

    if ( ref( $cfg->{collectors} ) eq 'ARRAY' ) {
        @jobs = @{ $self->_merge_named_hash_array( \@jobs, $cfg->{collectors}, 'name' ) };
    }
    @jobs = @{ $self->_merge_named_hash_array( \@jobs, [ $self->_skill_collectors ], 'name' ) };

    if ( my $filter = $ENV{DEVELOPER_DASHBOARD_CHECKERS} ) {
        my %wanted = map { $_ => 1 } grep { defined && $_ ne '' } split /:/, $filter;
        @jobs = grep { ref($_) eq 'HASH' && $wanted{ $_->{name} } } @jobs;
    }

    @jobs = map { $self->_normalize_collector_job($_) } @jobs;
    return \@jobs;
}

# _normalize_collector_job($job)
# Applies collector execution defaults and validates bounded multiple-mode
# settings so the runtime sees a stable config contract.
# Input: collector job hash reference.
# Output: normalized collector job hash reference.
sub _normalize_collector_job {
    my ( $self, $job ) = @_;
    return $job if ref($job) ne 'HASH';
    my %normalized = %{$job};
    $normalized{disable} = $self->_collector_disable_flag( $normalized{disable} );
    $normalized{mode} = defined $normalized{mode} && $normalized{mode} ne '' ? $normalized{mode} : 'singleton';
    die "Collector '$normalized{name}' has unsupported mode '$normalized{mode}'"
      if $normalized{mode} ne 'singleton' && $normalized{mode} ne 'multiple';
    if ( $normalized{mode} eq 'multiple' ) {
        my $parallel = defined $normalized{multiple} ? $normalized{multiple} : 2;
        die "Collector '$normalized{name}' multiple value must be a positive integer"
          if $parallel !~ /^\d+$/ || $parallel < 1;
        $normalized{multiple} = $parallel + 0;
    }
    else {
        $normalized{multiple} = 1;
    }
    return \%normalized;
}

# _collector_disable_flag($value)
# Normalizes one collector disable value into a stable boolean flag.
# Input: scalar config value from collector disable.
# Output: numeric boolean where 1 disables the collector and 0 keeps it active.
sub _collector_disable_flag {
    my ( $self, $value ) = @_;
    return 0 if !defined $value;
    return $value ? 1 : 0 if ref($value);
    return 0 if $value =~ /\A(?:0|false|no|off)\z/i;
    return $value ne '' ? 1 : 0;
}

# _builtin_collectors()
# Returns the built-in collector job definitions that ship with the runtime.
# Input: none.
# Output: array reference of collector job hash references.
sub _builtin_collectors {
    return [
        {
            name     => 'housekeeper',
            code     => <<'PERL',
my $housekeeper = Developer::Dashboard::Housekeeper->new(
    paths => Developer::Dashboard::PathRegistry->new(
        workspace_roots => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
        project_roots   => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
    ),
);
print Developer::Dashboard::JSON::json_encode( $housekeeper->run );
0;
PERL
            cwd      => 'home',
            interval => 900,
        },
    ];
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

# file_aliases()
# Returns configured file aliases from merged configuration.
# Input: none.
# Output: hash reference of file aliases.
sub file_aliases {
    my ($self) = @_;
    my $cfg = $self->merged;
    return {} if ref( $cfg->{file_aliases} ) ne 'HASH';
    return $self->_expand_path_aliases( $cfg->{file_aliases} );
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

# global_file_aliases()
# Returns only the user-global configured file aliases.
# Input: none.
# Output: hash reference of global file aliases.
sub global_file_aliases {
    my ($self) = @_;
    my $cfg = $self->load_global;
    return {} if ref( $cfg->{file_aliases} ) ne 'HASH';
    return $self->_expand_path_aliases( $cfg->{file_aliases} );
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

    my $cfg = $self->_load_writable_global;
    $cfg->{web} = {} if ref( $cfg->{web} ) ne 'HASH';
    $cfg->{web}{workers} = $workers + 0;
    $self->save_global($cfg);

    return {
        workers => $workers + 0,
    };
}

# web_settings()
# Returns the current web service settings (host, port, workers, ssl, no_editor, no_indicators, and optional SSL SAN aliases).
# Loads from global config with sensible defaults if not configured.
# Input: none.
# Output: hash reference with host, port, workers, ssl, no_editor, no_indicators, and ssl_subject_alt_names keys.
sub web_settings {
    my ($self) = @_;
    my $cfg = $self->merged;
    my $web = $cfg->{web} || {};

    return {
        host                  => $web->{host} || '0.0.0.0',
        port                  => defined $web->{port} && $web->{port} =~ /^\d+$/ ? $web->{port} + 0 : 7890,
        workers               => defined $web->{workers} && $web->{workers} =~ /^\d+$/ && $web->{workers} > 0 ? $web->{workers} + 0 : 1,
        ssl                   => $web->{ssl} ? 1 : 0,
        no_editor             => $web->{no_editor} ? 1 : 0,
        no_indicators         => $web->{no_indicators} ? 1 : 0,
        ssl_subject_alt_names => $self->_normalize_ssl_subject_alt_names( $web->{ssl_subject_alt_names} ),
    };
}

# save_global_web_settings(%args)
# Persists web service settings (host, port, workers, ssl, no_editor, no_indicators, and optional SSL SAN aliases) in the writable runtime config.
# Only saves settings that are explicitly provided, leaving others untouched.
# Input: named arguments (host, port, workers, ssl, no_editor, no_indicators, ssl_subject_alt_names) - any or all can be omitted.
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

    if ( defined $args{no_editor} ) {
        $result->{no_editor} = $args{no_editor} ? 1 : 0;
    }

    if ( defined $args{no_indicators} ) {
        $result->{no_indicators} = $args{no_indicators} ? 1 : 0;
    }

    if ( exists $args{ssl_subject_alt_names} ) {
        $result->{ssl_subject_alt_names} = $self->_normalize_ssl_subject_alt_names( $args{ssl_subject_alt_names} );
    }

    # Load current config and update with new values
    my $cfg = $self->_load_writable_global;
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

    my $cfg = $self->_load_writable_global;
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

    my $cfg = $self->_load_writable_global;
    $cfg->{path_aliases} = {} if ref( $cfg->{path_aliases} ) ne 'HASH';
    my $removed = delete $cfg->{path_aliases}{$name} ? 1 : 0;
    $self->save_global($cfg);

    return {
        name    => $name,
        removed => $removed,
    };
}

# save_global_file_alias($name, $path)
# Persists or updates a user-global file alias without disturbing other config domains.
# Input: alias name string and target file path string.
# Output: hash reference containing the stored alias mapping.
sub save_global_file_alias {
    my ( $self, $name, $path ) = @_;
    die 'Missing file alias name' if !defined $name || $name eq '';
    die 'Missing file alias target' if !defined $path || $path eq '';

    my $cfg = $self->_load_writable_global;
    $cfg->{file_aliases} = {} if ref( $cfg->{file_aliases} ) ne 'HASH';
    my $stored_path = $self->_normalize_home_path($path);
    $cfg->{file_aliases}{$name} = $stored_path;
    $self->save_global($cfg);

    return {
        name => $name,
        path => $self->_expand_config_path($stored_path),
    };
}

# remove_global_file_alias($name)
# Deletes a user-global file alias when present and otherwise remains idempotent.
# Input: alias name string.
# Output: hash reference containing alias name and removal flag.
sub remove_global_file_alias {
    my ( $self, $name ) = @_;
    die 'Missing file alias name' if !defined $name || $name eq '';

    my $cfg = $self->_load_writable_global;
    $cfg->{file_aliases} = {} if ref( $cfg->{file_aliases} ) ne 'HASH';
    my $removed = delete $cfg->{file_aliases}{$name} ? 1 : 0;
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

# api_keys()
# Returns layered API-key ajax authorization config from config/api.json files.
# Input: none.
# Output: hash reference keyed by API client name with secret and ajax route list.
sub api_keys {
    my ($self) = @_;
    return $self->api_registry;
}

# api_registry()
# Returns the visible layered API-key ajax authorization config from
# config/api.json files, excluding child-layer tombstones.
# Input: none.
# Output: hash reference keyed by API client name with secret and ajax route list.
sub api_registry {
    my ($self) = @_;
    my $merged = {};
    for my $file ( reverse $self->_global_api_files ) {
        next if !-f $file;
        $merged = $self->_merge_api_key_hashes( $merged, $self->_load_json_hash_file($file) );
    }
    for my $fragment ( $self->_skill_api_fragments ) {
        $merged = $self->_merge_api_key_hashes( $merged, $fragment );
    }
    return $self->_normalize_api_keys($merged);
}

# writable_api_registry()
# Loads only the writable runtime layer config/api.json payload without
# merging inherited parent layers.
# Input: none.
# Output: normalized writable-layer API config hash reference.
sub writable_api_registry {
    my ($self) = @_;
    return $self->_normalize_api_keys(
        $self->_load_writable_api_registry,
        preserve_disabled => 1,
    );
}

# save_writable_api_registry($registry)
# Persists the writable runtime-layer config/api.json payload.
# Input: API config hash reference keyed by API client name.
# Output: written config file path string.
sub save_writable_api_registry {
    my ( $self, $registry ) = @_;
    my $file = $self->_global_api_file;
    $self->{paths}->ensure_dir( $self->{paths}->config_root );
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode(
        $self->_normalize_api_keys(
            $registry || {},
            preserve_disabled => 1,
        )
    );
    close $fh or die "Unable to close $file: $!";
    $self->{paths}->secure_file_permissions($file);
    return $file;
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

# _global_api_file()
# Returns the writable runtime-layer config/api.json path.
# Input: none.
# Output: writable API config file path string.
sub _global_api_file {
    my ($self) = @_;
    return File::Spec->catfile( $self->{paths}->config_root, 'api.json' );
}

# _global_config_files()
# Returns the global configuration file candidates in effective lookup order.
# Input: none.
# Output: ordered list of configuration file path strings.
sub _global_config_files {
    my ($self) = @_;
    return map { File::Spec->catfile( $_, 'config.json' ) } $self->{paths}->config_roots;
}

# _global_api_files()
# Returns the layered config/api.json candidates in effective lookup order.
# Input: none.
# Output: ordered list of configuration file path strings.
sub _global_api_files {
    my ($self) = @_;
    return map { File::Spec->catfile( $_, 'api.json' ) } $self->{paths}->config_roots;
}

# _load_writable_global()
# Loads only the writable runtime layer configuration file without merging
# inherited parent-layer settings into the returned hash.
# Input: none.
# Output: configuration hash reference for the writable layer only.
sub _load_writable_global {
    my ($self) = @_;
    my $file = $self->_global_config_file;
    return {} if !-f $file;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    return json_decode(<$fh>);
}

# _load_writable_api_registry()
# Loads only the writable runtime-layer config/api.json payload.
# Input: none.
# Output: decoded API config hash reference for the writable layer only.
sub _load_writable_api_registry {
    my ($self) = @_;
    my $file = $self->_global_api_file;
    return {} if !-f $file;
    return $self->_load_json_hash_file($file);
}

# _load_json_hash_file($file)
# Reads one JSON config file and requires it to decode to a hash reference.
# Input: readable filesystem path string.
# Output: decoded hash reference.
sub _load_json_hash_file {
    my ( $self, $file ) = @_;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    my $decoded = json_decode(<$fh>);
    die "Expected JSON object in $file\n" if ref($decoded) ne 'HASH';
    return $decoded;
}

# _skill_config_fragments()
# Loads installed skill config/config.json payloads as underscored runtime config fragments.
# Input: none.
# Output: ordered list of hash refs such as { _skill_name => { ... } }.
sub _skill_config_fragments {
    my ($self) = @_;
    my @fragments;
    for my $entry ( $self->_skill_config_entries ) {
        push @fragments, { '_' . $entry->{skill_name} => $entry->{config} };
    }
    return @fragments;
}

# _skill_config_entries()
# Enumerates installed skill config payloads together with the skill name and installed root.
# Input: none.
# Output: ordered list of hash refs with skill_name, skill_root, and config.
sub _skill_config_entries {
    my ($self) = @_;
    my @entries;
    for my $skill_root ( $self->{paths}->installed_skill_roots ) {
        my ($skill_name) = $skill_root =~ m{/([^/]+)\z};
        next if !defined $skill_name || $skill_name eq '';
        my $config = $self->_skill_config_hash($skill_name);
        next if ref($config) ne 'HASH' || !%{$config};
        push @entries,
          {
            skill_name => $skill_name,
            skill_root => $skill_root,
            config     => $config,
          };
    }
    return @entries;
}

# _skill_api_fragments()
# Loads installed skill config/api.json payloads as layered API auth fragments.
# Input: none.
# Output: ordered list of api-key hash refs.
sub _skill_api_fragments {
    my ($self) = @_;
    my @fragments;
    for my $entry ( $self->_skill_api_entries ) {
        push @fragments, $entry->{api};
    }
    return @fragments;
}

# _skill_api_entries()
# Enumerates installed skill API auth payloads together with their skill names.
# Input: none.
# Output: ordered list of hash refs with skill_name, skill_root, and api.
sub _skill_api_entries {
    my ($self) = @_;
    my @entries;
    for my $skill_root ( $self->{paths}->installed_skill_roots ) {
        my ($skill_name) = $skill_root =~ m{/([^/]+)\z};
        next if !defined $skill_name || $skill_name eq '';
        my $api = $self->_skill_api_hash($skill_name);
        next if ref($api) ne 'HASH' || !%{$api};
        push @entries,
          {
            skill_name => $skill_name,
            skill_root => $skill_root,
            api        => $api,
          };
    }
    return @entries;
}

# _skill_config_hash($skill_name)
# Reads and merges config/config.json from every participating layer of one installed skill.
# Input: skill repository name string.
# Output: merged skill configuration hash reference.
sub _skill_config_hash {
    my ( $self, $skill_name ) = @_;
    return {} if !defined $skill_name || $skill_name eq '';
    my @layers = $self->{paths}->skill_layers( $skill_name, include_disabled => 1 );
    return {} if !@layers;
    my $merged = {};
    for my $skill_path (@layers) {
        my $config_file = File::Spec->catfile( $skill_path, 'config', 'config.json' );
        next if !-f $config_file;
        open my $fh, '<:raw', $config_file or die "Unable to read $config_file: $!";
        local $/;
        my $config = eval { json_decode(<$fh>) } || {};
        close $fh;
        return {} if ref($config) ne 'HASH';
        $merged = $self->_merge_hashes( $merged, $config );
    }
    return $merged;
}

# _skill_api_hash($skill_name)
# Reads and merges config/api.json from every participating layer of one installed skill.
# Input: skill repository name string.
# Output: merged API auth configuration hash reference.
sub _skill_api_hash {
    my ( $self, $skill_name ) = @_;
    return {} if !defined $skill_name || $skill_name eq '';
    my @layers = $self->{paths}->skill_layers( $skill_name, include_disabled => 1 );
    return {} if !@layers;
    my $merged = {};
    for my $skill_path (@layers) {
        my $api_file = File::Spec->catfile( $skill_path, 'config', 'api.json' );
        next if !-f $api_file;
        $merged = $self->_merge_hashes( $merged, $self->_load_json_hash_file($api_file) );
    }
    return $merged;
}

# _normalize_api_keys($keys)
# Normalizes one layered API auth hash into trimmed secrets and ajax route lists.
# Input: hash reference keyed by API client name.
# Output: normalized hash reference with malformed entries removed.
sub _normalize_api_keys {
    my ( $self, $keys, %args ) = @_;
    return {} if ref($keys) ne 'HASH';
    my %normalized;
    for my $name ( keys %{$keys} ) {
        next if !defined $name || ref($name) || $name eq '';
        my $entry = $keys->{$name};
        next if ref($entry) ne 'HASH';
        my $disabled = $self->_api_key_disabled_flag($entry);
        if ($disabled) {
            $normalized{$name} = { disabled => 1 } if $args{preserve_disabled};
            next;
        }
        my $secret = defined $entry->{secret} && !ref( $entry->{secret} ) ? $entry->{secret} : '';
        $secret =~ s/^\s+//;
        $secret =~ s/\s+$//;
        next if $secret eq '';
        my $ajax = $self->_normalize_api_ajax_routes( $entry->{ajax} );
        $normalized{$name} = {
            secret => $secret,
            ajax   => $ajax,
        };
    }
    return \%normalized;
}

# _merge_api_key_hashes($left, $right)
# Merges layered API auth config while allowing a deeper layer to tombstone one
# inherited key entirely.
# Input: left and right hash references keyed by API client name.
# Output: merged hash reference.
sub _merge_api_key_hashes {
    my ( $self, $left, $right ) = @_;
    $left  ||= {};
    $right ||= {};
    my %merged = %{ $self->_normalize_api_keys( $left, preserve_disabled => 1 ) };
    my $normalized_right = $self->_normalize_api_keys( $right, preserve_disabled => 1 );
    for my $name ( keys %{$normalized_right} ) {
        my $entry = $normalized_right->{$name};
        if ( ref($entry) eq 'HASH' && $entry->{disabled} ) {
            delete $merged{$name};
            next;
        }
        $merged{$name} = $entry;
    }
    return \%merged;
}

# _api_key_disabled_flag($entry)
# Returns whether one raw API config entry is an explicit child-layer
# tombstone.
# Input: API entry hash reference.
# Output: numeric boolean flag.
sub _api_key_disabled_flag {
    my ( $self, $entry ) = @_;
    return 0 if ref($entry) ne 'HASH';
    for my $field (qw(disabled _disabled)) {
        next if !exists $entry->{$field};
        my $value = $entry->{$field};
        return $value ? 1 : 0 if ref($value);
        return 0 if !defined $value || $value eq '' || $value =~ /\A(?:0|false|no|off)\z/i;
        return 1;
    }
    return 0;
}

# _normalize_api_ajax_routes($routes)
# Normalizes one API auth ajax route allowlist into unique /ajax paths.
# Input: array reference of route strings.
# Output: normalized array reference with blank, duplicate, and non-/ajax routes removed.
sub _normalize_api_ajax_routes {
    my ( $self, $routes ) = @_;
    return [] if ref($routes) ne 'ARRAY';
    my @normalized;
    my %seen;
    for my $route ( @{$routes} ) {
        next if !defined $route || ref($route);
        $route =~ s/^\s+//;
        $route =~ s/\s+$//;
        next if $route eq '';
        next if $route !~ m{\A/ajax(?:/|\z)};
        next if $seen{$route}++;
        push @normalized, $route;
    }
    return \@normalized;
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
Dashboard. Matching collector and provider entries merge by logical identity,
so deeper layers can override fields such as C<interval> or nested
C<indicator> metadata without discarding inherited defaults.

=head1 METHODS

=head2 new, load_global, save_global, load_repo, merged, collectors, path_aliases, global_path_aliases, web_workers, save_global_web_workers, web_settings, save_global_web_settings, save_global_path_alias, remove_global_path_alias, docker_config, api_keys, api_registry, writable_api_registry, save_writable_api_registry, providers

Load and expose configuration domains used by the runtime.

The web_settings() and save_global_web_settings() methods manage web service settings
including host, port, workers, ssl flag, the persisted C<no_editor> read-only
browser flag, and optional C<ssl_subject_alt_names> entries used to extend the
generated HTTPS certificate. These settings persist across restart, so
dashboard restart inherits the previous serve session configuration.
The api_keys() and api_registry() methods merge layered runtime and installed-skill
F<config/api.json> files into the exact saved C</ajax/...> machine-auth
allowlist used by the web backend. The writable_api_registry() and
save_writable_api_registry() methods operate on only the deepest writable
runtime layer so CLI management commands can update the correct OOP config
target without rewriting inherited parents.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module owns runtime configuration files such as F<config/config.json>,
F<config/api.json>, path aliases, web settings, collector definitions, and
feature-specific config trees. It loads the effective config through
C<DD-OOP-LAYERS> and writes changes back to the deepest participating runtime
root.

=head1 WHY IT EXISTS

It exists because configuration has to obey the same layered runtime rules as pages, hooks, and state. Centralizing config lookup and writes prevents commands from accidentally ignoring project-local overrides or overwriting the wrong runtime layer.

=head1 WHEN TO USE

Use this file when changing config schema defaults, alias persistence, collector definitions from config, or any feature that reads or writes under F<config/> in the runtime tree.

=head1 HOW TO USE

Construct it with the file registry and path registry, then use the accessor
and persistence methods instead of reading config JSON directly. New
config-backed features should register their data under the appropriate
runtime config directory and let this module handle loading rules. Matching
collectors merge by C<name>, so a config entry such as C<housekeeper> can
override only C<interval> or C<indicator> while still inheriting the built-in
collector C<code> and C<cwd>.

=head1 WHAT USES IT

It is used by init flows, path alias commands, auth/session bootstrap, collector refresh, web server settings, and release/integration tests that verify runtime config behavior.

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
