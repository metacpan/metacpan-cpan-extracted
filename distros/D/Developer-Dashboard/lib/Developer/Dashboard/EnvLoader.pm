package Developer::Dashboard::EnvLoader;

use strict;
use warnings;

our $VERSION = '3.14';

use Cwd qw(abs_path cwd);
use File::Basename qw(dirname);
use File::Spec;

use Developer::Dashboard::EnvAudit;

# load_runtime_layers(%args)
# Loads every participating plain-directory and DD-OOP-LAYER runtime env file
# from the configured root toward the current working directory.
# Input: hash with paths => Developer::Dashboard::PathRegistry object.
# Output: ordered array reference of loaded env file paths.
sub load_runtime_layers {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} or die "Missing paths\n";
    return $class->load_files(
        files => [
            $class->_plain_directory_env_files($paths),
            $class->_runtime_layer_env_files($paths),
        ],
    );
}

# load_skill_layers(%args)
# Loads every participating skill-root env file from home skill layer to the
# deepest effective skill layer.
# Input: hash with skill_layers => array reference of skill root paths.
# Output: ordered array reference of loaded env file paths.
sub load_skill_layers {
    my ( $class, %args ) = @_;
    my @skill_layers = @{ $args{skill_layers} || [] };
    my @files;
    for my $skill_root (@skill_layers) {
        push @files, $class->_env_file_candidates($skill_root);
    }
    return $class->load_files( files => \@files );
}

# load_files(%args)
# Loads a specific ordered list of .env and .env.pl files, updating both %ENV
# and the shared EnvAudit inventory.
# Input: hash with files => array reference of candidate file paths.
# Output: ordered array reference of the env files that were actually loaded.
sub load_files {
    my ( $class, %args ) = @_;
    my @files = @{ $args{files} || [] };
    my @loaded;
    my %seen;
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
    return \@loaded;
}

# _plain_directory_env_files($paths)
# Builds the env file list contributed by ancestor directories from the active
# root toward the current working directory.
# Input: path registry object.
# Output: ordered list of plain directory env file paths.
sub _plain_directory_env_files {
    my ( $class, $paths ) = @_;
    my @files;
    for my $dir ( $class->_plain_directory_layers($paths) ) {
        push @files, $class->_env_file_candidates($dir);
    }
    return @files;
}

# _runtime_layer_env_files($paths)
# Builds the env file list contributed by participating DD-OOP-LAYER runtime
# roots from home runtime to deepest child runtime.
# Input: path registry object.
# Output: ordered list of runtime env file paths.
sub _runtime_layer_env_files {
    my ( $class, $paths ) = @_;
    my @files;
    for my $runtime_root ( $paths->runtime_layers ) {
        push @files, $class->_env_file_candidates($runtime_root);
    }
    return @files;
}

# _plain_directory_layers($paths)
# Resolves the ancestor directory chain whose plain .env files participate in
# env loading for the current working directory.
# Input: path registry object.
# Output: ordered list of directory paths from root to cwd.
sub _plain_directory_layers {
    my ( $class, $paths ) = @_;
    my $cwd = cwd();
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
        return ();
    }

    my @layers;
    my $dir = $cwd;
    while ($dir) {
        push @layers, $dir;
        last if $class->_path_identity($dir) eq $class->_path_identity($stop_dir);
        my $parent = dirname($dir);
        last if !defined $parent || $parent eq '' || $parent eq $dir;
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
# Executes one .env.pl file and records every added or changed environment key
# against that file in the shared audit inventory.
# Input: absolute .env.pl file path.
# Output: true value.
sub _load_env_pl_file {
    my ( $class, $file ) = @_;
    my %before = %ENV;
    delete $INC{$file};
    require $file;
    my @changed = grep {
        $_ ne 'DEVELOPER_DASHBOARD_ENV_AUDIT'
          && (
            !exists $before{$_}
            || ( defined $before{$_} && defined $ENV{$_} && $before{$_} ne $ENV{$_} )
            || ( defined $before{$_} xor defined $ENV{$_} )
          )
    } sort keys %ENV;
    for my $key (@changed) {
        next if exists $before{$key} && defined $before{$key} && defined $ENV{$key} && $before{$key} eq $ENV{$key};
        next if exists $before{$key} && !defined $before{$key} && !defined $ENV{$key};
        Developer::Dashboard::EnvAudit->record( $key, $ENV{$key}, $file );
    }
    return 1;
}

# _path_identity($path)
# Returns a canonical path identity so duplicate files or macOS alias paths do
# not get loaded twice in the same process.
# Input: filesystem path.
# Output: canonical or stable path string.
sub _path_identity {
    my ( $class, $path ) = @_;
    return '' if !defined $path || $path eq '';
    my $resolved = eval { abs_path($path) };
    return defined $resolved && $resolved ne '' ? $resolved : File::Spec->canonpath($path);
}

# _same_or_descendant_path($path, $root)
# Reports whether one directory path is the same as or nested beneath another.
# Input: candidate path string and root path string.
# Output: boolean.
sub _same_or_descendant_path {
    my ( $class, $path, $root ) = @_;
    return 0 if !defined $path || $path eq '' || !defined $root || $root eq '';
    my $path_id = $class->_path_identity($path);
    my $root_id = $class->_path_identity($root);
    return 1 if $path_id eq $root_id;
    return index( $path_id, $root_id . '/' ) == 0 ? 1 : 0;
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
execution. Call C<load_skill_layers(skill_layers =E<gt> \@layers)> inside skill
dispatch after the base skill env has been prepared and before executing hooks
or the final skill command.

=head1 WHAT USES IT

It is used by C<bin/dashboard>, by the skill dispatcher, by custom commands and hooks that inherit the loaded environment, and by tests that verify precedence and failure behavior.

=head1 EXAMPLES

Example 1:

  Developer::Dashboard::EnvLoader->load_runtime_layers(paths => $paths);

Load every participating plain-directory and runtime-layer env file from root to leaf for one dashboard process.

Example 2:

  Developer::Dashboard::EnvLoader->load_skill_layers(skill_layers => \@skill_layers);

Load every participating skill env file from the base skill layer to the deepest active skill layer before executing a skill command.

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
