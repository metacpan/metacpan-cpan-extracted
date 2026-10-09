package Developer::Dashboard::Config;

use strict;
use warnings;

our $VERSION = '5.73';

use File::Spec;
use File::Path qw(make_path);
use Cwd qw(cwd);

use JSON::XS ();
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

# for_paths($paths)
# Constructs a configuration loader bound to a path registry, building the
# matching file registry itself - the shape both Housekeeper and Doctor
# needed identically (DD-763).
# Input: Developer::Dashboard::PathRegistry object.
# Output: Developer::Dashboard::Config object.
sub for_paths {
    my ( $class, $paths ) = @_;
    require Developer::Dashboard::FileRegistry;
    return $class->new( paths => $paths, files => Developer::Dashboard::FileRegistry->new( paths => $paths ) );
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
    return $self->_write_json_atomic( $self->_global_config_file, json_encode( $config || {} ) );
}

# _write_json_atomic($file, $text)
# Persists JSON text to a config file atomically: it stages the payload in a
# sibling temporary file, hardens the temp file, checks close(), and renames it
# over the target so a concurrent reader never observes a truncated or
# partially written config, and a failed write never destroys the previous file.
# Input: destination config file path string and already-encoded JSON text.
# Output: written destination file path string.
sub _write_json_atomic {
    my ( $self, $file, $text ) = @_;
    my $temp = $file . '.tmp.' . $$ . '.' . int( rand(1_000_000) );
    open my $fh, '>:raw', $temp or die "Unable to write $temp: $!";
    print {$fh} $text;
    close $fh or die "Unable to close $temp: $!";
    $self->{paths}->secure_file_permissions($temp);
    rename $temp, $file or die "Unable to rename $temp to $file: $!";
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

    # Collectors (by name) and providers (by id) are logical sets, so a single
    # contributing layer that already lists the same identity twice must not
    # leak a duplicate into the merged view. Re-collapse them by identity after
    # the merge regardless of how many layers contributed, letting the last
    # duplicate's fields win.
    $merged{collectors} = $self->_merge_named_hash_array( [], $merged{collectors}, 'name' )
      if ref( $merged{collectors} ) eq 'ARRAY';
    $merged{providers} = $self->_merge_named_hash_array( [], $merged{providers}, 'id' )
      if ref( $merged{providers} ) eq 'ARRAY';

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
        my %wanted = map { $_ => 1 } grep { $_ ne '' } split /:/, $filter;
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
# Normalizes one collector disable value into a stable boolean flag. A JSON
# literal true/false arrives from json_decode as a blessed boolean reference
# (JSON::XS::is_bool detects it), so it is unwrapped to its truth value
# BEFORE the reference test - otherwise "disable": false read as disabled
# (DD-813).
# Input: scalar config value from collector disable.
# Output: numeric boolean where 1 disables the collector and 0 keeps it active.
sub _collector_disable_flag {
    my ( $self, $value ) = @_;
    return 0 if !defined $value;
    $value = $value ? 1 : 0 if JSON::XS::is_bool($value);
    return 1 if ref($value);
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
# Returns configured path aliases from merged configuration, including any
# installed skill's own config/config.json path_aliases block, qualified by
# skill name (DD-977) so cdr/d2 paths can see them at all - a skill's own
# path_aliases were previously invisible outside the skill's own runtime.
# Input: none.
# Output: hash reference of path aliases.
sub path_aliases {
    my ($self) = @_;
    my $cfg = $self->merged;
    my %aliases;
    %aliases = %{ $self->_expand_path_aliases( $cfg->{path_aliases} ) } if ref( $cfg->{path_aliases} ) eq 'HASH';
    my $skill_aliases = $self->_expand_path_aliases( $self->_skill_path_aliases );
    @aliases{ keys %{$skill_aliases} } = values %{$skill_aliases};
    return \%aliases;
}

# _skill_path_aliases()
# Returns every installed skill's own path_aliases, each name qualified by its
# skill (DD-977), mirroring _skill_collectors' established
# "prefix unless already prefixed" convention so a skill can pre-qualify its
# own alias names without double-prefixing. A skill's own config already
# merges recursively across every DD-OOP-LAYER it participates in via
# _skill_config_hash (the same _merge_hashes recursion every other nested
# config key gets), so this is layer-merge-safe by construction.
# Input: none.
# Output: hash reference of skill-qualified path aliases (unexpanded).
sub _skill_path_aliases {
    my ($self) = @_;
    my %aliases;
    for my $entry ( $self->_skill_config_entries ) {
        my $skill_aliases = $entry->{config}{path_aliases};
        next if ref($skill_aliases) ne 'HASH';
        for my $name ( keys %{$skill_aliases} ) {
            next if $name eq '';
            my $qualified_name = $name =~ /^\Q$entry->{skill_name}\E\./
              ? $name
              : $entry->{skill_name} . '.' . $name;
            $aliases{$qualified_name} = $skill_aliases->{$name};
        }
    }
    my $nested = $self->_nested_skill_alias_entries('path_aliases');
    @aliases{ keys %{$nested} } = values %{$nested};
    return \%aliases;
}

# file_aliases()
# Returns configured file aliases from merged configuration, including any
# installed skill's own config/config.json file_aliases block, qualified by
# skill name (DD-978) so cdr/d2 paths can see them at all - a skill's own
# file_aliases were previously invisible outside the skill's own runtime.
# Input: none.
# Output: hash reference of file aliases.
sub file_aliases {
    my ($self) = @_;
    my $cfg = $self->merged;
    my %aliases;
    %aliases = %{ $self->_expand_path_aliases( $cfg->{file_aliases} ) } if ref( $cfg->{file_aliases} ) eq 'HASH';
    my $skill_aliases = $self->_expand_path_aliases( $self->_skill_file_aliases );
    @aliases{ keys %{$skill_aliases} } = values %{$skill_aliases};
    return \%aliases;
}

# _skill_file_aliases()
# Returns every installed skill's own file_aliases, each name qualified by its
# skill (DD-978), mirroring _skill_path_aliases' established
# "prefix unless already prefixed" convention so a skill can pre-qualify its
# own alias names without double-prefixing. A skill's own config already
# merges recursively across every DD-OOP-LAYER it participates in via
# _skill_config_hash (the same _merge_hashes recursion every other nested
# config key gets), so this is layer-merge-safe by construction.
# Input: none.
# Output: hash reference of skill-qualified file aliases (unexpanded).
sub _skill_file_aliases {
    my ($self) = @_;
    my %aliases;
    for my $entry ( $self->_skill_config_entries ) {
        my $skill_aliases = $entry->{config}{file_aliases};
        next if ref($skill_aliases) ne 'HASH';
        for my $name ( keys %{$skill_aliases} ) {
            next if $name eq '';
            my $qualified_name = $name =~ /^\Q$entry->{skill_name}\E\./
              ? $name
              : $entry->{skill_name} . '.' . $name;
            $aliases{$qualified_name} = $skill_aliases->{$name};
        }
    }
    my $nested = $self->_nested_skill_alias_entries('file_aliases');
    @aliases{ keys %{$nested} } = values %{$nested};
    return \%aliases;
}

# _nested_skill_alias_entries($alias_key)
# Shared read-side walker for skill-depth-prefixed path_aliases/file_aliases
# (DD-1004). Owner's rule (Q-182): "add" never writes into a skill's own
# config.json at any depth - so this reads in two priority-ordered passes,
# mirroring the write side exactly, never duplicating its resolution logic.
#
# PASS 1 (lower priority) - a nested (depth 2+) skill's own SHIPPED
# defaults, read directly from ITS OWN config.json regardless of .git,
# because that file is a read-only source here, never a write target. Depth
# 1 shipped defaults are deliberately left to the pre-existing
# _skill_config_entries path, which already covers them with full
# DD-OOP-LAYER multi-layer merging that a single-resolved-directory read
# does not attempt to reproduce.
#
# PASS 2 (higher priority, OVERRIDES pass 1 for the same qualified name) -
# whatever save_skill_path_alias/save_skill_file_alias actually wrote,
# resolved via the exact same PathRegistry::skill_config_write_location a
# write of those same segments would use: an ancestor skill's config.json,
# or the global config's fallback section when no git-free parent ancestor
# exists (always true at depth 1, since a depth-1 target has no parent
# skill at all - Q-182). This is what lets a user's "d2 path add" override a
# skill-shipped default without ever touching the skill's own file.
# Input: the config domain key to read, "path_aliases" or "file_aliases".
# Output: hash reference of fully-qualified dotted alias names (skill
# segments joined by "." plus the alias name) to their stored (unexpanded)
# path values.
sub _nested_skill_alias_entries {
    my ( $self, $alias_key ) = @_;
    my %aliases;
    my @entries = $self->{paths}->nested_skill_entries( include_disabled => 1 );

    # PASS 1: nested (depth 2+) shipped defaults, straight from the skill's
    # own file - never routed through the write-location resolver.
    for my $entry (@entries) {
        my $segments = $entry->{segments};
        next if @{$segments} == 1;
        my $config_file = File::Spec->catfile( $entry->{dir}, 'config', 'config.json' );
        next if !-f $config_file;
        my $node = eval { $self->_load_json_hash_file($config_file) };
        next if ref($node) ne 'HASH';
        my $leaf = ref( $node->{$alias_key} ) eq 'HASH' ? $node->{$alias_key} : {};
        for my $name ( keys %{$leaf} ) {
            next if $name eq '';
            $aliases{ join( '.', @{$segments}, $name ) } = $leaf->{$name};
        }
    }

    # PASS 2: user-written ancestor overrides, at every depth including 1 -
    # shadows pass 1 for the same qualified name.
    my $global_fallback_key = 'skills';    # Q-181: owner-confirmed top-level key for the global-config walk-up-exhausted fallback (DD-1004)
    my $global_cfg;
    for my $entry (@entries) {
        my $segments = $entry->{segments};
        my $location = $self->{paths}->skill_config_write_location($segments) or next;

        my $node;
        if ( $location->{kind} eq 'skill' ) {
            my $config_file = File::Spec->catfile( $location->{dir}, 'config', 'config.json' );
            next if !-f $config_file;
            $node = eval { $self->_load_json_hash_file($config_file) };
            next if ref($node) ne 'HASH';
        }
        else {
            $global_cfg = $self->_load_writable_global if !defined $global_cfg;    # loaded once, reused for every later entry needing the global fallback
            $node = ref( $global_cfg->{$global_fallback_key} ) eq 'HASH' ? $global_cfg->{$global_fallback_key} : {};
        }

        for my $seg ( @{ $location->{remaining} } ) {
            $node = ref( $node->{$seg} ) eq 'HASH' ? $node->{$seg} : {};
        }

        my $leaf = ref( $node->{$alias_key} ) eq 'HASH' ? $node->{$alias_key} : {};
        for my $name ( keys %{$leaf} ) {
            next if $name eq '';
            $aliases{ join( '.', @{$segments}, $name ) } = $leaf->{$name};    # overrides pass 1 for the same qualified name
        }
    }

    return \%aliases;
}

# split_skill_alias_name($name)
# Parses a dotted "dashboard path/file add" alias name into its skill-depth
# path plus the trailing alias segment (DD-1004), e.g. "foo.bar.something" ->
# (["foo","bar"], "something"). An undotted name is not a skill-prefixed
# alias at all.
# Input: raw alias name string as typed on the command line.
# Output: two-element list of (array reference of skill-name segments,
# trailing alias-name string) when the name contains at least one dot with a
# non-empty segment on both sides; empty list otherwise.
sub split_skill_alias_name {
    my ( $self, $name ) = @_;
    return if !defined $name || index( $name, '.' ) < 0;
    my @parts = split /\./, $name, -1;
    return if grep { $_ eq '' } @parts;    # split() on a plain string never yields an undef element, only possibly-empty ones, so an explicit !defined check here would be dead code
    my $alias = pop @parts;
    return ( \@parts, $alias );
}

# save_skill_path_alias(\@segments, $alias, $path)
# save_skill_file_alias(\@segments, $alias, $path)
# Persists a skill-depth-prefixed path/file alias (DD-1004) at whichever
# location PathRegistry::skill_config_write_location resolves for the given
# segments - NEVER the target skill's own config/config.json (Q-182: the
# owner's rule is unconditional, not only when the target itself carries a
# .git), always its nearest git-free PARENT ancestor, or the global config's
# fallback section when no such parent exists (always true at depth 1) -
# storing it as a NESTED hash mirroring the remaining depth segments, never a
# flattened dotted-string key, so the same structure round-trips through
# _nested_skill_alias_entries regardless of where the walk-up stopped, and
# shadows any shipped default the target skill's own file already declares
# for the same qualified name without ever modifying that file.
# Input: array reference of skill-name segments, trailing alias name string,
# and target path string.
# Output: hash reference containing the fully-qualified dotted alias name and
# its stored (expanded) path.
sub save_skill_path_alias { my ( $self, $segments, $alias, $path, %opts ) = @_; return $self->_save_skill_alias( 'path_aliases', $segments, $alias, $path, %opts ) }
sub save_skill_file_alias { my ( $self, $segments, $alias, $path, %opts ) = @_; return $self->_save_skill_alias( 'file_aliases', $segments, $alias, $path, %opts ) }

# _save_skill_alias($alias_key, \@segments, $alias, $path, %opts)
# Shared implementation behind save_skill_path_alias/save_skill_file_alias.
# Input: config domain key ("path_aliases"/"file_aliases"), array reference
# of skill-name segments, trailing alias name string, target path string,
# and optional %opts ("create"/"mode", DD-1005's lazy-create support - see
# save_global_path_alias for the full contract). The stored leaf value is a
# metadata hash when "create" is given, a bare path string otherwise -
# identical shape to the non-skill-depth storage, so
# _nested_skill_alias_entries's read side needs no change to see it.
# Output: hash reference containing the fully-qualified dotted alias name and
# its stored (expanded) path, plus "create"/"mode" when lazy-create.
sub _save_skill_alias {
    my ( $self, $alias_key, $segments, $alias, $path, %opts ) = @_;
    die 'Missing skill-depth segments' if ref($segments) ne 'ARRAY' || !@{$segments};
    die 'Missing alias name' if !defined $alias || $alias eq '';
    die 'Missing alias target' if !defined $path || $path eq '';

    my $location = $self->{paths}->skill_config_write_location($segments)
      or die "Unable to resolve installed skill path for '" . join( '.', @{$segments} ) . "'\n";
    my $stored_path = $self->_normalize_home_path($path);
    my $mode = defined $opts{mode} && $opts{mode} ne '' ? $opts{mode} : undef;
    my $stored_value = $opts{create}
      ? { path => $stored_path, create => 1, ( defined $mode ? ( mode => $mode ) : () ) }
      : $stored_path;

    if ( $location->{kind} eq 'skill' ) {
        my $config_dir = File::Spec->catdir( $location->{dir}, 'config' );
        make_path($config_dir) if !-d $config_dir;
        my $config_file = File::Spec->catfile( $config_dir, 'config.json' );
        my $cfg = -f $config_file ? $self->_load_json_hash_file($config_file) : {};
        my $target = $cfg;
        for my $seg ( @{ $location->{remaining} } ) {
            $target->{$seg} = {} if ref( $target->{$seg} ) ne 'HASH';
            $target = $target->{$seg};
        }
        $target->{$alias_key} = {} if ref( $target->{$alias_key} ) ne 'HASH';
        $target->{$alias_key}{$alias} = $stored_value;
        $self->_write_json_atomic( $config_file, json_encode($cfg) );
    }
    else {
        my $global_fallback_key = 'skills';    # Q-181: owner-confirmed top-level key for the global-config walk-up-exhausted fallback (DD-1004)
        my $cfg = $self->_load_writable_global;
        $cfg->{$global_fallback_key} = {} if ref( $cfg->{$global_fallback_key} ) ne 'HASH';
        my $target = $cfg->{$global_fallback_key};
        for my $seg ( @{ $location->{remaining} } ) {
            $target->{$seg} = {} if ref( $target->{$seg} ) ne 'HASH';
            $target = $target->{$seg};
        }
        $target->{$alias_key} = {} if ref( $target->{$alias_key} ) ne 'HASH';
        $target->{$alias_key}{$alias} = $stored_value;
        $self->save_global($cfg);
    }

    return {
        name => join( '.', @{$segments}, $alias ),
        path => $self->_expand_config_path($stored_path),
        ( $opts{create} ? ( create => 1, ( defined $mode ? ( mode => $mode ) : () ) ) : () ),
    };
}

# remove_skill_path_alias(\@segments, $alias)
# remove_skill_file_alias(\@segments, $alias)
# Deletes a skill-depth-prefixed path/file alias (DD-1004) from whichever
# location it would have been written to (symmetry with save_skill_*_alias),
# and remains idempotent when the alias was never present there.
# Input: array reference of skill-name segments and trailing alias name
# string.
# Output: hash reference containing the fully-qualified dotted alias name and
# a removal flag.
sub remove_skill_path_alias { my ( $self, $segments, $alias ) = @_; return $self->_remove_skill_alias( 'path_aliases', $segments, $alias ) }
sub remove_skill_file_alias { my ( $self, $segments, $alias ) = @_; return $self->_remove_skill_alias( 'file_aliases', $segments, $alias ) }

# _remove_skill_alias($alias_key, \@segments, $alias)
# Shared implementation behind remove_skill_path_alias/remove_skill_file_alias.
# Input: config domain key, array reference of skill-name segments, and
# trailing alias name string.
# Output: hash reference containing the fully-qualified dotted alias name and
# a removal flag.
sub _remove_skill_alias {
    my ( $self, $alias_key, $segments, $alias ) = @_;
    die 'Missing skill-depth segments' if ref($segments) ne 'ARRAY' || !@{$segments};
    die 'Missing alias name' if !defined $alias || $alias eq '';

    my $qualified_name = join( '.', @{$segments}, $alias );
    my $location = $self->{paths}->skill_config_write_location($segments);
    return { name => $qualified_name, removed => 0 } if !$location;

    my $removed = 0;
    if ( $location->{kind} eq 'skill' ) {
        my $config_file = File::Spec->catfile( $location->{dir}, 'config', 'config.json' );
        return { name => $qualified_name, removed => 0 } if !-f $config_file;
        my $cfg = $self->_load_json_hash_file($config_file);
        my $target = $cfg;
        for my $seg ( @{ $location->{remaining} } ) {
            return { name => $qualified_name, removed => 0 } if ref( $target->{$seg} ) ne 'HASH';
            $target = $target->{$seg};
        }
        if ( ref( $target->{$alias_key} ) eq 'HASH' && exists $target->{$alias_key}{$alias} ) {
            delete $target->{$alias_key}{$alias};
            $removed = 1;
        }
        $self->_write_json_atomic( $config_file, json_encode($cfg) );
    }
    else {
        my $global_fallback_key = 'skills';    # Q-181: owner-confirmed top-level key for the global-config walk-up-exhausted fallback (DD-1004)
        my $cfg = $self->_load_writable_global;
        my $target = ref( $cfg->{$global_fallback_key} ) eq 'HASH' ? $cfg->{$global_fallback_key} : {};
        my $reachable = 1;
        for my $seg ( @{ $location->{remaining} } ) {
            if ( ref( $target->{$seg} ) ne 'HASH' ) {
                $reachable = 0;
                last;
            }
            $target = $target->{$seg};
        }
        # $target is always a hashref here by the same loop invariant as above (it starts as one, and the
        # loop only ever reassigns it to a value already confirmed HASH), so no ref($target) eq 'HASH' check
        # is needed - unlike the loop's own guard, this line is never reached with reachable true and a
        # non-hash $target, so that check would be dead code.
        if ( $reachable && ref( $target->{$alias_key} ) eq 'HASH' && exists $target->{$alias_key}{$alias} ) {
            delete $target->{$alias_key}{$alias};
            $removed = 1;
        }
        $self->save_global($cfg);
    }

    return { name => $qualified_name, removed => $removed };
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

# watchdog_restart_limit()
# Returns the configured collector-watchdog restart limit, or undef if unset.
# DD-624: makes the tunable discoverable via config.json's "watchdog" section
# (key "restart_limit") rather than only the
# DEVELOPER_DASHBOARD_COLLECTOR_RESTART_LIMIT env var, which RuntimeManager's
# own _collector_restart_limit still checks first and takes precedence over
# this value when both are set.
# Input: none.
# Output: positive integer restart limit, or undef if unset/invalid.
sub watchdog_restart_limit {
    my ($self) = @_;
    my $cfg = $self->merged;
    my $value = $cfg->{watchdog}{restart_limit};
    return undef if !defined $value;
    return undef if $value !~ /^\d+$/;
    return undef if $value < 1;
    return $value + 0;
}

# watchdog_restart_window_seconds()
# Returns the configured collector-watchdog restart-tracking window, or undef
# if unset. See watchdog_restart_limit for the config-key/env-var precedence.
# Input: none.
# Output: positive integer number of seconds, or undef if unset/invalid.
sub watchdog_restart_window_seconds {
    my ($self) = @_;
    my $cfg = $self->merged;
    my $value = $cfg->{watchdog}{restart_window_seconds};
    return undef if !defined $value;
    return undef if $value !~ /^\d+$/;
    return undef if $value < 1;
    return $value + 0;
}

# watchdog_stall_grace_seconds()
# Returns the configured collector-watchdog stall grace period, or undef if
# unset. See watchdog_restart_limit for the config-key/env-var precedence.
# Input: none.
# Output: positive integer number of seconds, or undef if unset/invalid.
sub watchdog_stall_grace_seconds {
    my ($self) = @_;
    my $cfg = $self->merged;
    my $value = $cfg->{watchdog}{stall_grace_seconds};
    return undef if !defined $value;
    return undef if $value !~ /^\d+$/;
    return undef if $value < 1;
    return $value + 0;
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

# ssl_validity_days()
# The lifetime, in days, of a generated self-signed certificate.
# Input: none.
# Output: positive integer; 365 when unset or unusable.
#
# Guards are one per clause rather than one compound condition, matching
# web_workers above. That is not style: a single `||` chain leaves Devel::Cover's
# CONDITION metric with gaps that statement and branch coverage do not reveal, so
# the line reads as covered while one clause has never been observed (DD-624).
#
# The value is deliberately NOT capped. Browsers reject publicly-trusted
# certificates valid beyond 398 days, but that rule covers certificates issued by
# publicly trusted CAs and explicitly not locally-operated ones - so it does not
# reach a self-signed localhost certificate. Clamping here would enforce a rule
# that does not govern this certificate, silently, over a deliberate choice.
#
# That is not the whole story, and a caller warning about large values should say
# both halves. Apple's own guidance confirms the 398-day maximum applies to certs
# from PREINSTALLED roots and not to user- or administrator-added ones. But Safari
# still refuses a long enough certificate even from a user-added root - measured
# externally at roughly 825 days, accepting 398 and 800 and rejecting 1592. So a
# very large value here is honoured by this accessor and may still be rejected by
# the browser, and telling an operator only that the 398 limit does not apply to
# them is true, reassuring, and would leave them puzzled. The 825 figure is
# somebody else's measurement, not a published limit, and is not reproduced here.
# See docs/https-and-certificates.md.
sub ssl_validity_days {
    my ($self) = @_;
    my $cfg  = $self->merged;
    my $days = $cfg->{web}{ssl_validity_days};
    return 365 if !defined $days;
    return 365 if $days !~ /^\d+$/;
    return 365 if $days < 1;
    return $days + 0;
}

# ssl_warn_days()
# The number of days before a certificate's expiry at which dashboard doctor
# starts warning about it (DD-651). Separate return-undef-style guards rather
# than one compound condition, which is what keeps Devel::Cover's CONDITION
# metric at 100 (DD-624).
# Input: none.
# Output: positive integer number of days.
sub ssl_warn_days {
    my ($self) = @_;
    my $cfg  = $self->merged;
    my $days = $cfg->{web}{ssl_warn_days};
    return 30 if !defined $days;
    return 30 if $days !~ /^\d+$/;
    return 30 if $days < 1;
    return $days + 0;
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
# Output: hash reference with host, port, workers, ssl, no_editor, no_indicators, ssl_subject_alt_names, and ssl_validity_days keys.
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
        ssl_validity_days     => $self->ssl_validity_days,
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

# save_global_path_alias($name, $path, %opts)
# Persists or updates a user-global path alias without disturbing other config domains.
# Input: alias name string, target path string, and optional %opts
# ("create" boolean flag and "mode" octal-string, DD-1005's lazy-create
# support). When "create" is true, the alias is stored as a metadata hash
# ({path=>,create=>1,mode=>}) instead of a bare path string; omitting
# "create" preserves today's plain-string storage exactly (backward
# compatible with every alias written before DD-1005).
# Output: hash reference containing the stored alias mapping, plus "create"
# and "mode" when the alias was marked lazy-create.
sub save_global_path_alias {
    my ( $self, $name, $path, %opts ) = @_;
    die 'Missing path alias name' if !defined $name || $name eq '';
    die 'Missing path alias target' if !defined $path || $path eq '';

    my $cfg = $self->_load_writable_global;
    $cfg->{path_aliases} = {} if ref( $cfg->{path_aliases} ) ne 'HASH';
    my $stored_path = $self->_normalize_home_path($path);
    my $mode = defined $opts{mode} && $opts{mode} ne '' ? $opts{mode} : undef;
    $cfg->{path_aliases}{$name} = $opts{create}
      ? { path => $stored_path, create => 1, ( defined $mode ? ( mode => $mode ) : () ) }
      : $stored_path;
    $self->save_global($cfg);

    return {
        name => $name,
        path => $self->_expand_config_path($stored_path),
        ( $opts{create} ? ( create => 1, ( defined $mode ? ( mode => $mode ) : () ) ) : () ),
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

# save_global_file_alias($name, $path, %opts)
# Persists or updates a user-global file alias without disturbing other config domains.
# Input: alias name string, target file path string, and optional %opts
# ("create" boolean flag and "mode" octal-string, DD-1005's lazy-create
# support) - same contract as save_global_path_alias.
# Output: hash reference containing the stored alias mapping, plus "create"
# and "mode" when the alias was marked lazy-create.
sub save_global_file_alias {
    my ( $self, $name, $path, %opts ) = @_;
    die 'Missing file alias name' if !defined $name || $name eq '';
    die 'Missing file alias target' if !defined $path || $path eq '';

    my $cfg = $self->_load_writable_global;
    $cfg->{file_aliases} = {} if ref( $cfg->{file_aliases} ) ne 'HASH';
    my $stored_path = $self->_normalize_home_path($path);
    my $mode = defined $opts{mode} && $opts{mode} ne '' ? $opts{mode} : undef;
    $cfg->{file_aliases}{$name} = $opts{create}
      ? { path => $stored_path, create => 1, ( defined $mode ? ( mode => $mode ) : () ) }
      : $stored_path;
    $self->save_global($cfg);

    return {
        name => $name,
        path => $self->_expand_config_path($stored_path),
        ( $opts{create} ? ( create => 1, ( defined $mode ? ( mode => $mode ) : () ) ) : () ),
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

# save_path_alias($name, $path)
# save_file_alias($name, $path)
# Top-level "dashboard path/file add" entry point (DD-1004): routes a bare
# alias name to the existing global-config behaviour unchanged, and a dotted
# skill-depth-prefixed name (e.g. "foo.bar.something") to
# save_skill_path_alias/save_skill_file_alias instead - the ONE place this
# branch is made, so CLI::Paths and CLI::Files both go through it rather than
# each re-deciding where an alias belongs.
# Input: alias name string as typed on the command line, and target path
# string.
# Output: hash reference containing the stored alias name and path.
sub save_path_alias { my ( $self, $name, $path, %opts ) = @_; return $self->_save_named_alias( 'path', $name, $path, %opts ) }
sub save_file_alias { my ( $self, $name, $path, %opts ) = @_; return $self->_save_named_alias( 'file', $name, $path, %opts ) }

# _save_named_alias($domain, $name, $path, %opts)
# Shared implementation behind save_path_alias/save_file_alias.
# Input: domain string ("path" or "file"), alias name string, target path
# string, and optional %opts ("create"/"mode", DD-1005).
# Output: hash reference containing the stored alias name and path.
sub _save_named_alias {
    my ( $self, $domain, $name, $path, %opts ) = @_;
    my ( $segments, $alias ) = $self->split_skill_alias_name($name);
    return $segments
      ? ( $domain eq 'file' ? $self->save_skill_file_alias( $segments, $alias, $path, %opts ) : $self->save_skill_path_alias( $segments, $alias, $path, %opts ) )
      : ( $domain eq 'file' ? $self->save_global_file_alias( $name, $path, %opts ) : $self->save_global_path_alias( $name, $path, %opts ) );
}

# remove_path_alias($name)
# remove_file_alias($name)
# Top-level "dashboard path/file del|rm" entry point (DD-1004): the removal
# symmetry counterpart to save_path_alias/save_file_alias, using the exact
# same dotted-name routing decision.
# Input: alias name string as typed on the command line.
# Output: hash reference containing the alias name and a removal flag.
sub remove_path_alias { my ( $self, $name ) = @_; return $self->_remove_named_alias( 'path', $name ) }
sub remove_file_alias { my ( $self, $name ) = @_; return $self->_remove_named_alias( 'file', $name ) }

# _remove_named_alias($domain, $name)
# Shared implementation behind remove_path_alias/remove_file_alias.
# Input: domain string ("path" or "file"), alias name string.
# Output: hash reference containing the alias name and a removal flag.
sub _remove_named_alias {
    my ( $self, $domain, $name ) = @_;
    my ( $segments, $alias ) = $self->split_skill_alias_name($name);
    return $segments
      ? ( $domain eq 'file' ? $self->remove_skill_file_alias( $segments, $alias ) : $self->remove_skill_path_alias( $segments, $alias ) )
      : ( $domain eq 'file' ? $self->remove_global_file_alias($name) : $self->remove_global_path_alias($name) );
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
# Input: hash reference of alias-to-path mappings, where each value is
# either a bare path string (the pre-DD-1005 shape) or a DD-1005 lazy-create
# metadata hash ({path=>,create=>1,mode=>}).
# Output: hash reference with expanded values - a bare path string stays a
# bare path string, and a metadata hash stays a metadata hash with its
# "path" field expanded, so PathRegistry/FileRegistry's resolver can see the
# create/mode metadata without every OTHER caller of this method (which
# expects a plain string) needing to change.
sub _expand_path_aliases {
    my ( $self, $aliases ) = @_;
    my %expanded;
    for my $name ( keys %{ $aliases || {} } ) {
        my $value = $aliases->{$name};
        $expanded{$name} =
          ref($value) eq 'HASH'
          ? { %{$value}, path => $self->_expand_config_path( $value->{path} ) }
          : $self->_expand_config_path($value);
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
#
# DD-874: skill fragments are merged FIRST, as the lowest-priority defaults,
# with every project layer merged on top - never the other way round. Unlike
# _skill_config_fragments (which namespaces each skill's payload under
# {_skillname => ...} and so can never collide with a project key at all),
# _skill_api_fragments returns the raw, un-namespaced key hash: an installed
# skill naming the same API-client key as the operator's own deepest-layer
# config/api.json (set via `dashboard api add`) must never be able to silently
# replace its secret/routes or tombstone it. Putting skill fragments first
# just extends this file's own later-merged-wins idiom by one more rung below
# the project layers, rather than inventing new collision-rejection logic.
sub api_registry {
    my ($self) = @_;
    my $merged = {};
    for my $fragment ( $self->_skill_api_fragments ) {
        $merged = $self->_merge_api_key_hashes( $merged, $fragment );
    }
    for my $file ( reverse $self->_global_api_files ) {
        next if !-f $file;
        $merged = $self->_merge_api_key_hashes( $merged, $self->_load_json_hash_file($file) );
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
    return $self->_write_json_atomic(
        $file,
        json_encode(
            $self->_normalize_api_keys(
                $registry || {},
                preserve_disabled => 1,
            )
        ),
    );
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
        next if !defined $skill_name;
        my $config = $self->_skill_config_hash($skill_name);
        next if !%{$config};
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
        next if !defined $skill_name;
        my $api = $self->_skill_api_hash($skill_name);
        next if !%{$api};
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
        next if $name eq '';
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
        if ( $entry->{disabled} ) {
            delete $merged{$name};
            next;
        }
        $merged{$name} = $entry;
    }
    return \%merged;
}

# _api_key_disabled_flag($entry)
# Returns whether one raw API config entry is an explicit child-layer
# tombstone. A JSON literal true/false on the flag field arrives as a
# blessed boolean reference (JSON::XS::is_bool detects it) and is unwrapped
# before the reference test, so "disabled": false keeps the key visible
# (DD-813); any other reference still counts as a tombstone.
# Input: API entry hash reference.
# Output: numeric boolean flag.
sub _api_key_disabled_flag {
    my ( $self, $entry ) = @_;
    return 0 if ref($entry) ne 'HASH';
    for my $field (qw(disabled _disabled)) {
        next if !exists $entry->{$field};
        my $value = $entry->{$field};
        $value = $value ? 1 : 0 if JSON::XS::is_bool($value);
        return 1 if ref($value);
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

=head2 new, load_global, save_global, load_repo, merged, collectors, path_aliases, global_path_aliases, watchdog_restart_limit, watchdog_restart_window_seconds, watchdog_stall_grace_seconds, web_workers, save_global_web_workers, ssl_validity_days, web_settings, save_global_web_settings, save_global_path_alias, remove_global_path_alias, docker_config, api_keys, api_registry, writable_api_registry, save_writable_api_registry, providers

Load and expose configuration domains used by the runtime.

The watchdog_restart_limit(), watchdog_restart_window_seconds(), and
watchdog_stall_grace_seconds() methods (DD-624) expose the collector
watchdog's restart-limit/window/stall-grace tunables via config.json's
C<watchdog> section (keys C<restart_limit>, C<restart_window_seconds>, and
C<stall_grace_seconds>), so they no longer require reading source or setting
an env var to discover or change:

  { "watchdog": { "restart_limit": 5, "restart_window_seconds": 600, "stall_grace_seconds": 20 } }

Each returns C<undef> when unset or invalid so
L<Developer::Dashboard::RuntimeManager>'s own tunable getters can fall through
to their env-var check (still the top-precedence override) and then their
hardcoded default.

The web_settings() and save_global_web_settings() methods manage web service settings
including host, port, workers, ssl flag, the persisted C<no_editor> read-only
browser flag, and optional C<ssl_subject_alt_names> entries used to extend the
generated HTTPS certificate. C<ssl_validity_days> sets how long a generated
self-signed certificate is valid, defaulting to 365 when unset or unusable; it
is deliberately not capped, because the 398-day ceiling browsers enforce applies
to certificates issued by publicly trusted CAs and not to a self-signed
localhost certificate. These settings persist across restart, so
dashboard restart inherits the previous serve session configuration.
The api_keys() and api_registry() methods merge layered runtime and installed-skill
F<config/api.json> files into the exact saved C</ajax/...> machine-auth
allowlist used by the web backend. The writable_api_registry() and
save_writable_api_registry() methods operate on only the deepest writable
runtime layer so CLI management commands can update the correct OOP config
target without rewriting inherited parents.

The path_aliases() method (DD-977) and file_aliases() method (DD-978) also
surface every installed skill's own F<config/config.json>
C<path_aliases>/C<file_aliases> block, each name qualified by its skill
(C<E<lt>skillE<gt>.E<lt>aliasE<gt>>) unless already qualified - the same
convention collectors() already applies to skill-contributed collector names
via _skill_collectors(). A skill's own path_aliases/file_aliases already
merge across every DD-OOP-LAYER that skill participates in (the same
recursive _merge_hashes every nested config key gets), so this is
layer-safe without any new merge logic.

save_global_path_alias(), save_global_file_alias(), save_skill_path_alias()
and save_skill_file_alias() (DD-1005) accept optional C<create> and C<mode>
opts for lazy path/file creation: passing C<create =E<gt> 1> stores the
alias as a metadata hash (C<{path=E<gt>...,create=E<gt>1,mode=E<gt>...}>)
instead of a bare path string, which C<Developer::Dashboard::PathRegistry>'s
resolve_dir() and C<Developer::Dashboard::FileRegistry>'s resolve_file()
detect and act on (creating the missing target - a directory for a path
alias, only the parent directory for a file alias - on first resolution).
An alias saved without C<create> stores and reads back exactly as it did
before this feature existed.

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
