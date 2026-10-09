package Developer::Dashboard::EnvLoader;

use strict;
use warnings;

our $VERSION = '5.73';

use Cwd qw(cwd);
use File::Basename qw(dirname);
use File::Spec;

use Developer::Dashboard::JSON qw(json_decode);
use Developer::Dashboard::EnvAudit;
use Developer::Dashboard::PathIdentity ();

our $INHERITED_ENV_KEYS = '_DEVELOPER_DASHBOARD_INHERITED_ENV_KEYS';

# load_runtime_layers(%args)
# Loads every participating plain-directory and DD-OOP-LAYER runtime env file
# from the configured root toward the current working directory. Optional scope
# selects all layers, home defaults only, or non-home descendant overrides.
# Caller-exported variables remain above all file values.
# Input: hash with paths => Developer::Dashboard::PathRegistry object and
# optional scope => all|home|descendants.
# Output: ordered array reference of loaded env file paths.
sub load_runtime_layers {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} or die "Missing paths\n";
    my $scope = $args{scope} || 'all';
    die "Unsupported runtime environment scope '$scope'\n"
      if $scope ne 'all' && $scope ne 'home' && $scope ne 'descendants';
    my $home_id = $class->_path_identity( $paths->home );
    my @plain_layers = $class->_plain_directory_layers($paths);
    my @runtime_layers = $paths->runtime_layers;
    if ( $scope ne 'all' ) {
        @plain_layers = grep {
            ( $class->_path_identity($_) eq $home_id ? 'home' : 'descendants' ) eq $scope
        } @plain_layers;
        @runtime_layers = grep {
            ( $class->_is_home_runtime_layer( $paths, $_ ) ? 'home' : 'descendants' ) eq $scope
        } @runtime_layers;
    }
    my @files;
    push @files, map { $class->_env_file_candidates($_) } @plain_layers;
    push @files, map { $class->_env_file_candidates($_) } @runtime_layers;
    return $class->load_files(
        files => \@files,
    );
}

# load_skill_runtime_layers(%args)
# Loads runtime environment layers around the active skill environment so home
# defaults are loaded first, skill and skill-CLI values override home values,
# and deeper runtime layers retain final precedence.
# Input: hash with paths => path registry and skill_layers => skill root paths.
# Output: ordered array reference of all environment files loaded.
sub load_skill_runtime_layers {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} or die "Missing paths\n";
    my $skill_layers = $args{skill_layers} || [];
    my @loaded;
    push @loaded, @{ $class->load_runtime_layers( paths => $paths, scope => 'home' ) };
    push @loaded, @{ $class->load_skill_layers( skill_layers => $skill_layers ) };
    push @loaded, @{ $class->load_skill_cli_layers( skill_layers => $skill_layers ) };
    push @loaded, @{ $class->load_runtime_layers( paths => $paths, scope => 'descendants' ) };
    return \@loaded;
}

# load_skill_layers(%args)
# Loads every participating skill-root env file from home skill layer to the
# deepest effective skill layer.
# Input: hash with skill_layers => array reference of skill root paths.
# Output: ordered array reference of loaded env file paths.
sub load_skill_layers {
    my ( $class, %args ) = @_;
    return $class->_load_skill_layer_specs(
        specs => $class->_skill_layer_specs( @{ $args{skill_layers} || [] } ),
    );
}

# load_skill_cli_layers(%args)
# Loads .env files that live directly under each participating skill's cli
# directory after the skill root env files have loaded.
# Input: hash with skill_layers => array reference of skill root paths.
# Output: ordered array reference of the env files that were actually loaded.
sub load_skill_cli_layers {
    my ( $class, %args ) = @_;
    my @files;
    for my $spec ( @{ $class->_skill_layer_specs( @{ $args{skill_layers} || [] } ) } ) {
        push @files, $class->_env_file_candidates( File::Spec->catdir( $spec->{root}, 'cli' ) );
    }
    return $class->load_files( files => \@files );
}

# load_skill_layers_into_hash(%args)
# Loads the ordered nested skill env chain into an isolated temporary
# environment and returns only the added or changed keys.
# Input: hash with skill_layers => array reference of skill root paths and
# optional base_env => hash reference of starting environment values.
# Output: hash reference with loaded file list and env overlay hash.
sub load_skill_layers_into_hash {
    my ( $class, %args ) = @_;
    my $base_env = ref( $args{base_env} ) eq 'HASH' ? { %{ $args{base_env} } } : { %ENV };
    my %before = %{$base_env};

    local %ENV = %{$base_env};
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT};
    local %Developer::Dashboard::EnvAudit::AUDIT;

    my $loaded = $class->_load_skill_layer_specs(
        specs => $class->_skill_layer_specs( @{ $args{skill_layers} || [] } ),
    );
    my %overlay;
    for my $key ( sort keys %ENV ) {
        next
          if exists $before{$key}
          && (
               ( !defined $before{$key} && !defined $ENV{$key} )
            || ( defined $before{$key} && defined $ENV{$key} && $before{$key} eq $ENV{$key} )
          );
        $overlay{$key} = $ENV{$key};
    }

    return {
        files => $loaded,
        env   => \%overlay,
    };
}

# load_files(%args)
# Loads a specific ordered list of .env and .env.pl files, updating both %ENV
# and the shared EnvAudit inventory while preserving caller-exported variables.
# Input: hash with files => array reference of candidate file paths.
# Output: ordered array reference of the env files that were actually loaded.
sub load_files {
    my ( $class, %args ) = @_;
    my @files = @{ $args{files} || [] };
    my $protected_env = $class->_capture_inherited_env;
    my @loaded;
    my %seen;
    my $ok = eval {
        for my $file (@files) {
            next if !defined $file || $file eq '';
            my $identity = $class->_path_identity($file);
            next if $seen{$identity}++;
            next if !-f $file;
            if ( $file =~ /\.env\.pl\z/ ) {
                $class->_load_env_pl_file($file);
                push @loaded, $file;
                next;
            }
            $class->_load_env_file($file);
            push @loaded, $file;
        }
        1;
    };
    my $error = $@;
    $class->_restore_inherited_env($protected_env);
    die $error if !$ok;
    return \@loaded;
}

# _capture_inherited_env()
# Saves caller-exported variables named by the private switchboard key list so
# env files cannot replace or delete explicit shell assignments.
# Input: none; reads the private inherited-key list from %ENV.
# Output: hash reference containing inherited values plus the private marker's
# current state, including absence.
sub _capture_inherited_env {
    my ($class) = @_;
    my $raw = $ENV{$INHERITED_ENV_KEYS};
    my %protected = ( $INHERITED_ENV_KEYS => $raw );
    return \%protected if !defined $raw || $raw eq '';
    my $keys = json_decode($raw);
    die "$INHERITED_ENV_KEYS must contain a JSON array of environment keys\n"
      if ref($keys) ne 'ARRAY';
    for my $key ( @{$keys} ) {
        die "$INHERITED_ENV_KEYS contains an invalid environment key\n"
          if !defined $key || ref($key) || $key !~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
        $protected{$key} = $ENV{$key} if exists $ENV{$key};
    }
    return \%protected;
}

# _restore_inherited_env($protected)
# Restores inherited caller variables after env files have run and removes
# their misleading file-origin audit records.
# Input: hash reference of environment key/value pairs captured before loading.
# Output: true value after restoring values or removing keys that were absent.
sub _restore_inherited_env {
    my ( $class, $protected ) = @_;
    return 1 if ref($protected) ne 'HASH';
    for my $key ( keys %{$protected} ) {
        if ( defined $protected->{$key} ) {
            $ENV{$key} = $protected->{$key};
        }
        else {
            delete $ENV{$key};
        }
        Developer::Dashboard::EnvAudit->forget($key) if $key ne $INHERITED_ENV_KEYS;
    }
    return 1;
}

# load_files_into_hash(%args)
# Loads a specific ordered list of env files into an isolated temporary
# environment and returns only the added or changed keys.
# Input: hash with files => array reference of candidate file paths and
# optional base_env => hash reference of starting environment values.
# Output: hash reference with loaded file list and env overlay hash.
sub load_files_into_hash {
    my ( $class, %args ) = @_;
    my $base_env = ref( $args{base_env} ) eq 'HASH' ? { %{ $args{base_env} } } : { %ENV };
    my %before = %{$base_env};

    local %ENV = %{$base_env};
    local $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT};
    local %Developer::Dashboard::EnvAudit::AUDIT;

    my $loaded = $class->load_files( files => $args{files} );
    my %overlay;
    for my $key ( sort keys %ENV ) {
        next
          if exists $before{$key}
          && (
               ( !defined $before{$key} && !defined $ENV{$key} )
            || ( defined $before{$key} && defined $ENV{$key} && $before{$key} eq $ENV{$key} )
          );
        $overlay{$key} = $ENV{$key};
    }

    return {
        files => $loaded,
        env   => \%overlay,
    };
}

# _is_home_runtime_layer($paths, $root)
# Identifies a runtime layer rooted directly under the user's home directory.
# Input: path registry object and runtime root path.
# Output: boolean true for .d2 or .developer-dashboard directly under home.
sub _is_home_runtime_layer {
    my ( $class, $paths, $root ) = @_;
    my $root_id = $class->_path_identity($root);
    for my $name ( '.d2', '.developer-dashboard' ) {
        my $home_layer = File::Spec->catdir( $paths->home, $name );
        return 1 if $root_id eq $class->_path_identity($home_layer);
    }
    return 0;
}

# _plain_directory_layers($paths)
# Resolves the ancestor directory chain whose plain .env files participate in
# env loading for the current working directory.
# Input: path registry object.
# Output: ordered list of directory paths from root to cwd.
sub _plain_directory_layers {
    my ( $class, $paths ) = @_;
    my $cwd = $paths->current_working_directory;
    return () if !defined $cwd || $cwd eq '';
    my $home = $paths->home;
    my $project_root = eval { $paths->current_project_root } || '';
    my $stop_dir = '';
    if ( $class->_same_or_descendant_path( $cwd, $home ) ) {
        $stop_dir = $home;
    }
    elsif ( $project_root ne '' && $class->_same_or_descendant_path( $cwd, $project_root ) ) {
        $stop_dir = $project_root;
    }
    else {
        $stop_dir = $cwd;
    }

    my @layers;
    my $dir = $cwd;
    while ($dir) {
        push @layers, $dir;
        last if $class->_path_identity($dir) eq $class->_path_identity($stop_dir);
        my $parent = dirname($dir);
        last if $parent eq $dir;
        $dir = $parent;
    }
    return reverse @layers;
}

# _env_file_candidates($root)
# Builds the candidate .env and .env.pl paths for one directory root.
# Input: directory root path.
# Output: ordered list of file paths.
sub _env_file_candidates {
    my ( $class, $root ) = @_;
    return (
        File::Spec->catfile( $root, '.env' ),
        File::Spec->catfile( $root, '.env.pl' ),
    );
}

# _load_skill_layer_specs(%args)
# Loads the ordered nested skill env chain while preserving caller-exported
# variables and overwritten parent values under cumulative skill-name aliases
# before deeper skill segments replace them.
# Trust note (DD-612, Q-027): preservation only applies to a key first set by a
# PREFIXED layer - the root/unprefixed layer's prefix is '' and never gets
# recorded in %key_prefix, so a root-set key later overwritten by any skill
# layer is silently replaced with no alias. This is deliberate, not an
# oversight: a root .env is the deployment's own baseline, and skill layers
# are expected to be able to override it without ceremony. Aliasing every
# base override would produce noisy PREFIX_KEY duplicates for common vars.
# Input: hash with specs => array reference of { root, prefix } hashes.
# Output: ordered array reference of the env files that were actually loaded.
sub _load_skill_layer_specs {
    my ( $class, %args ) = @_;
    my @specs = @{ $args{specs} || [] };
    my @loaded;
    my %seen;
    my %key_prefix;
    for my $spec (@specs) {
        next if ref($spec) ne 'HASH';
        my $prefix = $spec->{prefix} || '';
        for my $file ( $class->_env_file_candidates( $spec->{root} ) ) {
            my $identity = $class->_path_identity($file);
            next if $seen{$identity}++;
            next if !-f $file;

            my %before_env = %ENV;
            my $before_audit = Developer::Dashboard::EnvAudit->keys;
            my $protected_env = $class->_capture_inherited_env;
            my $ok = eval {
                if ( $file =~ /\.env\.pl\z/ ) {
                    $class->_load_env_pl_file($file);
                }
                else {
                    $class->_load_env_file($file);
                }
                1;
            };
            my $error = $@;
            $class->_restore_inherited_env($protected_env);
            die $error if !$ok;

            for my $key ( sort keys %ENV ) {
                next if $key eq 'DEVELOPER_DASHBOARD_ENV_AUDIT';
                next
                  if exists $before_env{$key}
                  && (
                       ( !defined $before_env{$key} && !defined $ENV{$key} )
                    || ( defined $before_env{$key} && defined $ENV{$key} && $before_env{$key} eq $ENV{$key} )
                  );
                if ( exists $key_prefix{$key} && $key_prefix{$key} ne $prefix && exists $before_env{$key} ) {
                    my $parent_key = $key_prefix{$key} . '_' . $key;
                    # The preserved parent value's provenance is always the
                    # audit source recorded for this key by the earlier layer.
                    my $parent_source = $before_audit->{$key}{envfile};
                    $ENV{$parent_key} = $before_env{$key};
                    Developer::Dashboard::EnvAudit->record( $parent_key, $before_env{$key}, $parent_source );
                }
                $key_prefix{$key} = $prefix if $prefix ne '';
            }
            push @loaded, $file;
        }
    }
    return \@loaded;
}

# _skill_layer_specs(@skill_layers)
# Expands one ordered list of effective skill roots into their root-to-leaf
# nested skill env chain, preserving DD-OOP layer order while deduplicating
# repeated ancestry roots.
# Input: ordered list of absolute skill root paths.
# Output: ordered list of hash references with root and cumulative prefix.
sub _skill_layer_specs {
    my ( $class, @skill_layers ) = @_;
    my @specs;
    my %seen;
    for my $skill_root (@skill_layers) {
        for my $spec ( $class->_nested_skill_layer_specs($skill_root) ) {
            my $identity = $class->_path_identity( $spec->{root} );
            next if $seen{$identity}++;
            push @specs, $spec;
        }
    }
    return \@specs;
}

# _nested_skill_layer_specs($skill_root)
# Expands one effective installed skill root into the cumulative nested
# root-to-leaf skill chain used for env loading and preserved-parent aliases.
# Input: absolute installed skill root path string.
# Output: ordered list of hash references with root and cumulative prefix.
sub _nested_skill_layer_specs {
    my ( $class, $skill_root ) = @_;
    return () if !defined $skill_root || $skill_root eq '';
    my @parts = File::Spec->splitdir( File::Spec->canonpath($skill_root) );
    my @skill_indexes = grep { $parts[$_] eq 'skills' } 0 .. $#parts - 1;
    return ( { root => $skill_root, prefix => $class->_normalize_skill_env_prefix( $parts[-1] || '' ) } ) if !@skill_indexes;

    my @specs;
    my @segments;
    for my $index (@skill_indexes) {
        push @segments, $parts[ $index + 1 ];
        my @root_parts = @parts[ 0 .. $index + 1 ];
        push @specs, {
            root   => File::Spec->catdir(@root_parts),
            prefix => join( '_', map { $class->_normalize_skill_env_prefix($_) } @segments ),
        };
    }
    return @specs;
}

# _normalize_skill_env_prefix($skill_name)
# Normalizes one skill segment into the underscore-safe env prefix used when a
# deeper nested skill preserves the parent segment's overwritten env keys.
# Input: skill segment name string.
# Output: normalized env-prefix fragment.
sub _normalize_skill_env_prefix {
    my ( $class, $skill_name ) = @_;
    return '' if !defined $skill_name || $skill_name eq '';
    $skill_name =~ s/[^A-Za-z0-9]+/_/g;
    $skill_name =~ s/\A_+|_+\z//g;
    return $skill_name;
}

# _load_env_file($file)
# Parses and applies one key=value env file, rejecting malformed lines and
# invalid environment variable names explicitly while honoring supported
# comment and expansion syntax.
# Input: absolute .env file path.
# Output: true value.
sub _load_env_file {
    my ( $class, $file ) = @_;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    my $line_no = 0;
    my $in_block_comment = 0;
    while ( my $line = <$fh> ) {
        ++$line_no;
        $line =~ s/\r?\n\z//;
        if ( my $spec = $class->_include_directive($line) ) {
            require Developer::Dashboard::EnvInclude;
            Developer::Dashboard::EnvInclude->include($spec);
            next;
        }
        $line = $class->_strip_env_comments(
            line             => $line,
            file             => $file,
            line_no          => $line_no,
            in_block_comment => \$in_block_comment,
        );
        next if $line =~ /\A\s*\z/;
        die "Invalid env line in $file line $line_no: $line\n"
          if $line !~ /\A\s*([^=\s]+)\s*=(.*)\z/;
        my ( $key, $value ) = ( $1, $2 );
        die "Invalid env key in $file line $line_no: $key\n"
          if $key !~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
        $value = $class->_expand_env_value(
            value   => $value,
            file    => $file,
            line_no => $line_no,
        );
        $ENV{$key} = $value;
        Developer::Dashboard::EnvAudit->record( $key, $value, $file );
    }
    close $fh or die "Unable to close $file: $!";
    die "Unterminated block comment in $file\n" if $in_block_comment;
    return 1;
}

# _load_env_pl_file($file)
# Executes one .env.pl file and records every added, changed, or explicitly
# re-assigned environment key against that file in the shared audit
# inventory.
# Input: absolute .env.pl file path.
# Output: true value.
sub _load_env_pl_file {
    my ( $class, $file ) = @_;
    my %before = %ENV;
    delete $INC{$file};
    require $file;

    # DD-1044: a .env.pl that assigns $ENV{KEY} to the value it already had
    # (inherited from the OS environment or an earlier layer) genuinely set
    # that key, but a pre/post %ENV value-diff alone cannot see it - the
    # value never changed. _env_pl_assigned_keys names every key this
    # specific file's own source explicitly assigns, so it is unioned with
    # the value-diff below rather than replacing it (a file can also touch
    # %ENV through constructs this static scan cannot see, e.g. a loop over
    # a computed key list - the diff still catches those).
    my %assigned_by_file = map { $_ => 1 } $class->_env_pl_assigned_keys($file);

    my @changed = grep {
        $_ ne 'DEVELOPER_DASHBOARD_ENV_AUDIT'
          && (
            $assigned_by_file{$_}
            || !exists $before{$_}
            || ( defined $before{$_} && defined $ENV{$_} && $before{$_} ne $ENV{$_} )
          )
    } sort keys %ENV;
    for my $key (@changed) {
        # The grep above already selects only genuinely new, changed, or
        # explicitly re-assigned keys, so every key reaching this point is
        # recorded without re-filtering.
        Developer::Dashboard::EnvAudit->record( $key, $ENV{$key}, $file );
    }
    return 1;
}

# _env_pl_assigned_keys($file)
# Statically scans one .env.pl file's own source text for literal
# $ENV{KEY} = ... assignment targets, so a same-value re-assignment (which a
# runtime %ENV diff cannot detect) is still attributed to this file.
# Input: absolute .env.pl file path.
# Output: list of environment key name strings (may be empty; duplicates
# removed).
sub _env_pl_assigned_keys {
    my ( $class, $file ) = @_;
    open my $fh, '<:raw', $file or return ();
    local $/;
    my $source = <$fh>;
    close $fh;
    return () if !defined $source;
    my %seen;
    return grep { !$seen{$_}++ } ( $source =~ /\$ENV\{\s*['"]?(\w+)['"]?\s*\}\s*=(?!=)/g );
}

# _path_identity($path)
# Returns a canonical path identity so duplicate files or macOS alias paths do
# not get loaded twice in the same process. Delegates to
# Developer::Dashboard::PathIdentity (DD-903) with empty_fallback => 0,
# preserving this class's historical behavior of returning an empty string
# as-is when abs_path() itself returns an empty string.
# Input: filesystem path.
# Output: canonical or stable path string.
sub _path_identity {
    my ( $class, $path ) = @_;
    return Developer::Dashboard::PathIdentity::_path_identity( $path, empty_fallback => 0 );
}

# _same_or_descendant_path($path, $root)
# Reports whether one directory path is the same as or nested beneath another.
# Delegates to Developer::Dashboard::PathIdentity (DD-903) with
# empty_fallback => 0, matching this class's own _path_identity.
# Input: candidate path string and root path string.
# Output: boolean.
sub _same_or_descendant_path {
    my ( $class, $path, $root ) = @_;
    return Developer::Dashboard::PathIdentity::_same_or_descendant_path( $path, $root, empty_fallback => 0 );
}

# _include_directive($line)
# Recognizes a "# include <skill.path>" or "# include <skill.path.*>" line
# before generic comment-stripping would otherwise silently discard it as an
# ordinary whole-line comment.
# Input: raw, not-yet-comment-stripped .env line string.
# Output: the include spec string, or undef when the line is not a directive.
sub _include_directive {
    my ( $class, $line ) = @_;
    my $trimmed = $line;    # the sole caller always passes a defined line read from an open filehandle
    $trimmed =~ s/\A\s+//;
    return undef if $trimmed !~ /\A#\s*include\s*<([^>]+)>\s*\z/;
    return $1;
}

# _strip_env_comments(%args)
# Removes supported comment syntaxes from one .env line while tracking
# multi-line block comment state across lines.
# Input: hash with line, file, line_no, and in_block_comment scalar ref.
# Output: uncommented line string.
sub _strip_env_comments {
    my ( $class, %args ) = @_;
    my $line = defined $args{line} ? $args{line} : '';
    my $state = $args{in_block_comment} || die "Missing in_block_comment state\n";
    my $trimmed = $line;
    $trimmed =~ s/\A\s+//;

    if ( ${$state} ) {
        if ( $trimmed =~ s/\A.*?\*\/// ) {
            ${$state} = 0;
            return $class->_strip_env_comments(
                line             => $trimmed,
                file             => $args{file},
                line_no          => $args{line_no},
                in_block_comment => $state,
            );
        }
        return '';
    }

    if ( $trimmed =~ /\A\/\*/ ) {
        ${$state} = 1;
        $trimmed =~ s/\A\/\*//;
        return $class->_strip_env_comments(
            line             => $trimmed,
            file             => $args{file},
            line_no          => $args{line_no},
            in_block_comment => $state,
        );
    }

    return '' if $trimmed =~ /\A#/;
    return '' if $trimmed =~ /\A\/\//;
    return $line;
}

# _expand_env_value(%args)
# Expands .env value expressions including leading home markers, environment
# references, defaults, and static Perl function calls.
# Input: hash with value, file, and line_no.
# Output: expanded scalar string.
sub _expand_env_value {
    my ( $class, %args ) = @_;
    my $value = defined $args{value} ? $args{value} : '';
    $value =~ s/\A~(?=\/|\z)/$ENV{HOME} || '~'/e;
    $value =~ s/\$\{([^}]+)\}/$class->_expand_braced_env_expression(
        expression => $1,
        file       => $args{file},
        line_no    => $args{line_no},
    )/ge;
    $value =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/$class->_lookup_env_symbol($1)/ge;
    return $value;
}

# _expand_braced_env_expression(%args)
# Expands one braced .env expression with optional default behavior.
# Input: hash with expression, file, and line_no.
# Output: expanded scalar string.
sub _expand_braced_env_expression {
    my ( $class, %args ) = @_;
    my $expression = $args{expression};
    my ( $symbol, $default ) = split /:-/, $expression, 2;
    my $value = $symbol =~ /\(\)\z/
      ? $class->_call_env_function(
        function => $symbol,
        file     => $args{file},
        line_no  => $args{line_no},
      )
      : $class->_lookup_env_symbol($symbol);
    return defined $value && $value ne ''
      ? $value
      : defined $default
      ? $class->_expand_env_value(
        value   => $default,
        file    => $args{file},
        line_no => $args{line_no},
      )
      : '';
}

# _lookup_env_symbol($name)
# Returns one environment variable value from the current effective process
# environment.
# Input: environment key string.
# Output: scalar value or undef.
sub _lookup_env_symbol {
    my ( $class, $name ) = @_;
    return undef if !defined $name || $name eq '';
    return $ENV{$name};
}

# _call_env_function(%args)
# Resolves and calls one static Perl function referenced from a .env value.
# Input: hash with function, file, and line_no.
# Output: scalar function return value.
sub _call_env_function {
    my ( $class, %args ) = @_;
    my $function = $args{function} || '';
    $function =~ s/\(\)\z//;
    die "Invalid env function in $args{file} line $args{line_no}: $function\n"
      if $function !~ /\A(?:[A-Za-z_][A-Za-z0-9_]*::)*[A-Za-z_][A-Za-z0-9_]*\z/;
    no strict 'refs';
    my $code = *{$function}{CODE};
    use strict 'refs';
    die "Invalid env function in $args{file} line $args{line_no}: $function\n"
      if !$code;
    my $value = eval { $code->() };
    die "Env function $function failed in $args{file} line $args{line_no}: $@\n" if $@;
    return $value;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::EnvLoader - load layered dashboard env files

=head1 SYNOPSIS

  use Developer::Dashboard::EnvLoader;

  Developer::Dashboard::EnvLoader->load_runtime_layers(paths => $paths);
  Developer::Dashboard::EnvLoader->load_skill_layers(skill_layers => \@skill_layers);

=head1 DESCRIPTION

This module loads plain C<.env> files and executable C<.env.pl> files from the
dashboard runtime layer chain and, when a skill command is running, from the
participating skill roots as well.

For skill execution the effective order is home runtime files, skill-root
files, skill C<cli/> files, then deeper project runtime files. Thus a skill
can override a same-named home default, while a closer project runtime layer
still has final precedence among file-based values. Values explicitly
inherited from the invoking process have higher precedence than every file
layer; files may set unset keys but cannot replace those caller values. The
switchboard carries only the names of those inherited keys to helper
processes, never their values.

Plain C<.env> files load before C<.env.pl> at every participating directory.
The plain-file parser accepts C<KEY=VALUE> lines, ignores blank lines, whole
line C<#> comments, whole line C<//> comments, and C</* ... */> block comments
that can span multiple lines. It expands a leading C<~> to C<$ENV{HOME}>, bare
C<$NAME> references, C<${NAME:-default}> expressions, and
C<${Namespace::function():-default}> expressions where the function resolves to
one static Perl subroutine. Missing functions, malformed keys, malformed
lines, and unterminated block comments fail explicitly instead of being
ignored.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the ordered env-file loader for the dashboard switchboard and skill dispatcher. Read it when you need to understand which env files participate, in what order they load, and how failures become explicit.

=head1 WHY IT EXISTS

It exists because env loading is now part of the DD-OOP-LAYERS contract. Keeping the file discovery, parsing, failure handling, and audit recording in one module keeps the public switchboard thin and makes the precedence rules testable.

=head1 WHEN TO USE

Use this module when wiring env loading into a runtime entrypoint, when changing the ordered env precedence rules, or when investigating why a command saw a particular env value.

=head1 HOW TO USE

Call C<load_runtime_layers(paths =E<gt> $paths)> from the thin dashboard
entrypoint after the command token is known and before helper or custom-command
execution. Call C<load_skill_runtime_layers(paths =E<gt> $paths,
skill_layers =E<gt> \@layers)> inside skill dispatch before executing hooks or
the final skill command; it applies the home/skill/project precedence order.
Both entrypoints preserve caller-exported values above the files they load.

=head1 WHAT USES IT

It is used by C<bin/dashboard>, by the skill dispatcher, by custom commands and hooks that inherit the loaded environment, and by tests that verify precedence and failure behavior.

=head1 EXAMPLES

Example 1:

  Developer::Dashboard::EnvLoader->load_runtime_layers(paths => $paths);

Load every participating plain-directory and runtime-layer env file from root to leaf for one dashboard process.

Example 2:

  Developer::Dashboard::EnvLoader->load_skill_runtime_layers(
      paths => $paths,
      skill_layers => \@skill_layers,
  );

Load home defaults, participating skill root and CLI env files, and deeper
project overrides in precedence order before executing a skill command.

Example 3:

  Developer::Dashboard::EnvLoader->load_files(files => \@files);

Apply an explicit ordered file list when you already know the participating env files.

Example 4:

  ROOT_CACHE=~/cache
  API_URL=https://example.test
  TOKEN=${ACCESS_TOKEN:-anonymous}
  GREETING=${Local::Env::Helper::message():-hello}

Show the supported plain C<.env> expansion forms for home-directory expansion,
env lookups, defaults, and static Perl functions.

=for comment FULL-POD-DOC END

=cut
