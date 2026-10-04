package Developer::Dashboard::CLI::Paths;

use strict;
use warnings;

our $VERSION = '5.51';

use Cwd qw(abs_path cwd);
use File::Basename qw(basename);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::CLI::TableHelpers qw(
    build_paths
    aliases_table
    list_table
    mutation_table
    removal_table
    render_table
);

# run_paths_command(%args)
# Dispatches the lightweight dashboard path/paths CLI behaviour without loading
# the main dashboard runtime.
# Input: command name under "command" plus the remaining argv array reference
# under "args".
# Output: prints the requested path data to STDOUT and exits successfully, or
# dies with a usage message when the arguments are invalid.
sub run_paths_command {
    my (%args) = @_;
    my $command = $args{command} || die "Missing command name\n";
    my $argv    = $args{args}    || die "Missing command arguments\n";
    die "Command arguments must be an array reference\n" if ref($argv) ne 'ARRAY';

    my $paths = build_paths();
    my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    my $load_configured_path_aliases = sub {
        $paths->register_named_paths( $config->path_aliases );
        return 1;
    };
    my $load_skill_folder_aliases = sub {
        $load_configured_path_aliases->();
        my $configured = $paths->named_paths;
        my $folder_aliases = _skill_folder_path_aliases( paths => $paths );
        my %extra = map { exists $configured->{$_} ? () : ( $_ => $folder_aliases->{$_} ) } keys %{$folder_aliases};
        $paths->register_named_paths( \%extra );
        return 1;
    };
    my %ctx = (
        paths           => $paths,
        config          => $config,
        load_paths      => $load_configured_path_aliases,
        load_folder_paths => $load_skill_folder_aliases,
    );

    if ( $command eq 'paths' ) {
        return _paths_action_paths( %ctx, argv => [ @{$argv} ] );
    }

    my @argv = @{$argv};
    my $action = shift @argv || '';
    if ( $action eq 'resolve' )      { return _paths_action_resolve( %ctx, argv => \@argv ) }
    if ( $action eq 'locate' )       { return _paths_action_locate( %ctx, argv => \@argv ) }
    if ( $action eq 'cdr' )          { return _paths_action_cdr( %ctx, argv => \@argv ) }
    if ( $action eq 'complete-cdr' ) { return _paths_action_complete_cdr( %ctx, argv => \@argv ) }
    if ( $action eq 'add' )          { return _paths_action_add( %ctx, argv => \@argv ) }
    if ( $action eq 'del' || $action eq 'rm' ) { return _paths_action_del( %ctx, argv => \@argv ) }
    if ( $action eq 'project-root' ) { return _paths_action_project_root( %ctx, argv => \@argv ) }
    if ( $action eq 'list' )         { return _paths_action_list( %ctx, argv => \@argv ) }

    die "Usage: dashboard path <resolve|locate|cdr|complete-cdr|add|del|rm|project-root|list> ...\n";
}

# _paths_action_paths(%args)
# Implements the top-level "dashboard paths" inventory listing.
# Input: paths registry, config, alias-loader closure, and argv under "paths",
# "config", "load_paths", and "argv".
# Output: prints the full path inventory as JSON or a summary table; returns 1.
sub _paths_action_paths {
    my (%args) = @_;
    my ( $paths, $load_folder_paths, $argv ) = @args{qw(paths load_folder_paths argv)};
    my @argv = @{$argv};
    my $output = 'table';
    GetOptionsFromArray( \@argv, 'o|output=s' => \$output );
    die "Usage: dashboard paths [-o json|table]\n" if @argv || ( $output ne 'json' && $output ne 'table' );
    $load_folder_paths->();
    if ( $output eq 'json' ) {
        print json_encode( $paths->all_paths );
        return 1;
    }
    print _paths_table( $paths->all_paths );
    return 1;
}

# _paths_action_resolve(%args)
# Implements "dashboard path resolve <name>".
# Input: paths registry, alias-loader closure, and argv under "paths",
# "load_paths", and "argv".
# Output: prints the resolved directory for the named alias; returns 1.
sub _paths_action_resolve {
    my (%args) = @_;
    my ( $paths, $load_paths, $argv ) = @args{qw(paths load_paths argv)};
    $load_paths->();
    my $name = shift( @{$argv} ) || die "Usage: dashboard path resolve <name>\n";
    my $target = _resolve_path_alias( paths => $paths, name => $name );
    print $target, "\n";
    return 1;
}

# _paths_action_locate(%args)
# Implements "dashboard path locate [-o json|table] <term...>".
# Input: paths registry and argv under "paths" and "argv".
# Output: prints the matched project paths as JSON or a summary table;
# returns 1.
sub _paths_action_locate {
    my (%args) = @_;
    my ( $paths, $argv ) = @args{qw(paths argv)};
    my @argv = @{$argv};
    my $output = 'table';
    GetOptionsFromArray( \@argv, 'o|output=s' => \$output );
    die "Usage: dashboard path locate [-o json|table] <term...>\n" if $output ne 'json' && $output ne 'table';
    my $matches = [ $paths->locate_projects(@argv) ];
    if ( $output eq 'json' ) {
        print json_encode($matches);
        return 1;
    }
    print list_table( 'Path', $matches );
    return 1;
}

# _paths_action_cdr(%args)
# Implements "dashboard path cdr <term...>".
# Input: paths registry, alias-loader closure, and argv under "paths",
# "load_paths", and "argv".
# Output: prints the cdr resolution payload as JSON; returns 1.
sub _paths_action_cdr {
    my (%args) = @_;
    my ( $paths, $load_paths, $argv ) = @args{qw(paths load_paths argv)};
    $load_paths->();
    print json_encode(
        _cdr_payload(
            paths                => $paths,
            args                 => $argv,
            folder_alias_resolver => sub { _skill_folder_alias_target( paths => $paths, name => $_[0] ) },
        )
    );
    return 1;
}

# _paths_action_complete_cdr(%args)
# Implements "dashboard path complete-cdr <index> <word...>".
# Input: paths registry, alias-loader closure, and argv under "paths",
# "load_paths", and "argv".
# Output: prints newline-separated shell-completion candidates; returns 1.
sub _paths_action_complete_cdr {
    my (%args) = @_;
    my ( $paths, $load_folder_paths, $argv ) = @args{qw(paths load_folder_paths argv)};
    $load_folder_paths->();
    my $index = shift( @{$argv} );
    $index = 0 if !defined $index || $index eq '';
    print join( "\n", _cdr_completion( paths => $paths, words => $argv, index => $index ) ), "\n";
    return 1;
}

# _parse_create_option($raw_value)
# Validates and normalizes a "-c|--create[:s]" option's raw Getopt::Long
# value into (create boolean, mode string-or-undef) for DD-1005's lazy-create
# support. Getopt::Long's ":s" optional-argument spec leaves $raw_value
# undef when the flag was not given at all, '' when given bare
# (--create/-c with no value), or the literal argument text otherwise -
# covering all four required syntax forms (bare, "--create 0777",
# "--create=0777", "-c 0777") because ":s" consumes the next argv token as
# the value unless that token itself looks like another option.
# Input: the raw scalar Getopt::Long populated (undef, '', or a string).
# Output: two-element list (create boolean, octal mode string or undef). A
# non-empty value that is not a valid octal digit string (a leading 0
# followed by digits 0-7) dies with a usage message rather than being
# silently misread as decimal, per the ticket's explicit requirement.
sub _parse_create_option {
    my ($raw_value) = @_;
    return ( 0, undef ) if !defined $raw_value;
    return ( 1, undef ) if $raw_value eq '';
    die "Usage: --create/-c mode must be an octal string like 0777, got '$raw_value'\n"
      if $raw_value !~ /\A0[0-7]+\z/;
    return ( 1, $raw_value );
}

# _paths_action_add(%args)
# Implements "dashboard path add <name> <path> [-c|--create[=MODE]] [-o json|table]".
# Input: paths registry, config, and argv under "paths", "config", and "argv".
# Output: prints the saved alias as JSON or a mutation summary table;
# returns 1.
sub _paths_action_add {
    my (%args) = @_;
    my ( $paths, $config, $argv ) = @args{qw(paths config argv)};
    my @argv = @{$argv};
    my $output = 'table';
    my $create_raw;
    GetOptionsFromArray( \@argv, 'o|output=s' => \$output, 'c|create:s' => \$create_raw );
    die "Usage: dashboard path add <name> <path> [-c|--create[=MODE]] [-o json|table]\n" if $output ne 'json' && $output ne 'table';
    my ( $create, $mode ) = _parse_create_option($create_raw);
    my ( $name, $path ) = _normalize_add_arguments(@argv);
    my $saved = $config->save_path_alias( $name, $path, ( $create ? ( create => 1, ( defined $mode ? ( mode => $mode ) : () ) ) : () ) );
    $paths->register_named_paths( { $saved->{name} => ( $saved->{create} ? { path => $saved->{path}, create => 1, ( defined $saved->{mode} ? ( mode => $saved->{mode} ) : () ) } : $saved->{path} ) } );
    $saved->{resolved} = $paths->resolve_dir( $saved->{name} );
    if ( $output eq 'json' ) {
        print json_encode($saved);
        return 1;
    }
    print mutation_table(
        alias    => $saved->{name},
        stored   => $saved->{path},
        resolved => $saved->{resolved},
        status   => 'saved',
    );
    return 1;
}

# _paths_action_del(%args)
# Implements "dashboard path del|rm <name> [-o json|table]".
# Input: paths registry, config, and argv under "paths", "config", and "argv".
# Output: prints the removed alias as JSON or a removal summary table;
# returns 1.
sub _paths_action_del {
    my (%args) = @_;
    my ( $paths, $config, $argv ) = @args{qw(paths config argv)};
    my @argv = @{$argv};
    my $output = 'table';
    GetOptionsFromArray( \@argv, 'o|output=s' => \$output );
    die "Usage: dashboard path del <name> [-o json|table]\n" if $output ne 'json' && $output ne 'table';
    my $name = _normalize_delete_argument(
        paths  => $paths,
        config => $config,
        name   => shift(@argv),
    );
    my $deleted = $config->remove_path_alias($name);
    $paths->unregister_named_path($name);
    if ( $output eq 'json' ) {
        print json_encode($deleted);
        return 1;
    }
    print removal_table(
        alias   => $deleted->{name},
        removed => $deleted->{removed},
    );
    return 1;
}

# _paths_action_project_root(%args)
# Implements "dashboard path project-root".
# Input: paths registry under "paths".
# Output: prints the current project root, or nothing when there is none;
# returns 1.
sub _paths_action_project_root {
    my (%args) = @_;
    my $paths = $args{paths};
    my $root = $paths->current_project_root;
    print defined $root ? "$root\n" : '';
    return 1;
}

# _paths_action_list(%args)
# Implements "dashboard path list [-o json|table]".
# Input: paths registry, alias-loader closure, and argv under "paths",
# "load_paths", and "argv".
# Output: prints the configured path aliases as JSON or a summary table;
# returns 1.
sub _paths_action_list {
    my (%args) = @_;
    my ( $paths, $load_folder_paths, $argv ) = @args{qw(paths load_folder_paths argv)};
    my @argv = @{$argv};
    my $output = 'table';
    GetOptionsFromArray( \@argv, 'o|output=s' => \$output );
    die "Usage: dashboard path list [-o json|table]\n" if @argv || ( $output ne 'json' && $output ne 'table' );
    $load_folder_paths->();
    if ( $output eq 'json' ) {
        print json_encode( $paths->all_path_aliases );
        return 1;
    }
    print aliases_table( $paths->all_path_aliases );
    return 1;
}

# _normalize_add_arguments(@argv)
# Expands dashboard path add shorthand so "." points at the current working
# directory and a lone "." also derives the alias name from that directory.
# Input: raw argv entries that follow "dashboard path add".
# Output: alias name string plus target path string.
sub _normalize_add_arguments {
    my (@argv) = @_;
    die "Usage: dashboard path add <name> <path>\n" if !@argv;

    if ( @argv == 1 && $argv[0] eq '.' ) {
        my $cwd = cwd();
        return ( basename($cwd), $cwd );
    }

    my $name = shift @argv || die "Usage: dashboard path add <name> <path>\n";
    my $path = shift @argv || die "Usage: dashboard path add <name> <path>\n";
    $path = cwd() if $path eq '.';
    return ( $name, $path );
}

# _normalize_delete_argument(%args)
# Expands dashboard path del/rm shorthand so "." removes the alias that points
# at the current working directory.
# Input: hash containing the path registry under "paths", the config under
# "config", and the raw alias token under "name".
# Output: alias name string to remove.
sub _normalize_delete_argument {
    my (%args) = @_;
    my $paths  = $args{paths}  || die "Missing paths registry\n";
    my $config = $args{config} || die "Missing config\n";
    my $name   = $args{name};
    die "Usage: dashboard path del <name>\n" if !defined $name || $name eq '';
    return $name if $name ne '.';

    my $cwd = cwd();
    my %aliases = %{ $config->path_aliases || {} };
    my $preferred = basename($cwd);
    if ( exists $aliases{$preferred} ) {
        my $resolved = eval { $paths->_expand_home( $aliases{$preferred} ) };
        $resolved = $aliases{$preferred} if !defined $resolved || $resolved eq '';
        return $preferred if $resolved eq $cwd;
    }
    for my $candidate ( sort keys %aliases ) {
        my $target = $aliases{$candidate};
        next if !defined $target || $target eq '';
        my $resolved = eval { $paths->_expand_home($target) };
        $resolved = $target if !defined $resolved || $resolved eq '';
        return $candidate if $resolved eq $cwd;
    }

    return basename($cwd);
}

# _resolve_path_alias(%args)
# Resolves a configured path alias first, then consults the matching installed
# skill's lib/Folder.pm method when no config alias exists.
# Input: path registry under "paths" and one qualified alias under "name".
# Output: expanded path string, or the registry's unknown-alias error.
sub _resolve_path_alias {
    my (%args) = @_;
    my $paths = $args{paths} || die "Missing paths registry\n";
    my $name  = $args{name};
    die 'Missing path name' if !defined $name || $name eq '';

    my $configured = $paths->named_paths || {};
    return $paths->resolve_dir($name) if exists $configured->{$name};

    my $target = _skill_folder_alias_target( paths => $paths, name => $name );
    return $paths->_expand_home($target) if defined $target;
    return $paths->resolve_dir($name);
}

# _skill_folder_path_aliases(%args)
# Reads listed path aliases from every installed skill Folder.pm without
# changing config files; configured aliases remain authoritative on collision.
# Input: path registry under "paths".
# Output: hash reference of skill-qualified alias names to returned paths.
sub _skill_folder_path_aliases {
    my (%args) = @_;
    my $paths = $args{paths} || die "Missing paths registry\n";
    my $skill_name = $args{skill_name};
    my %aliases;

    for my $entry ( _skill_folder_entries($paths) ) {
        next if defined $skill_name && $entry->{name} ne $skill_name;
        next if !_load_skill_folder_module($entry);
        my $list = Folder->can('__list__') or next;
        my @names = $list->('Folder');
        die "Folder->__list__ in '$entry->{file}' must return a list of alias names, not an array reference\n"
          if @names == 1 && ref($names[0]) eq 'ARRAY';
        for my $name (@names) {
            die "Folder->__list__ in '$entry->{file}' returned an invalid alias name\n"
              if !_valid_folder_method_name($name) || $name eq '__list__';
            my $method = Folder->can($name)
              or die "Folder->__list__ in '$entry->{file}' listed '$name' but Folder->$name is not available\n";
            my $target = $method->('Folder');
            die "Folder->$name in '$entry->{file}' must return a non-empty path string\n"
              if !defined $target || ref($target) || $target eq '';
            $aliases{ $entry->{name} . '.' . $name } = $paths->_expand_home($target);
        }
    }

    return \%aliases;
}

# _skill_folder_alias_target(%args)
# Loads one installed skill Folder.pm on demand and calls the method named by a
# qualified alias, after config aliases have already had first refusal.
# Input: path registry under "paths" and one dotted alias under "name".
# Output: returned path string, or undef when no matching skill method exists.
sub _skill_folder_alias_target {
    my (%args) = @_;
    my $paths = $args{paths} || die "Missing paths registry\n";
    my $name  = $args{name};
    return if !defined $name || ref($name) || $name =~ /[\x00-\x1F\x7F]/;

    my @parts = split /\./, $name, -1;
    return if @parts < 2 || grep { $_ eq '' } @parts;
    my $method_name = pop @parts;
    return if !_valid_folder_method_name($method_name) || $method_name eq '__list__';
    my $skill_name = join '.', @parts;
    my ($entry) = grep { $_->{name} eq $skill_name } _skill_folder_entries($paths);
    return if !$entry || !_load_skill_folder_module($entry);

    my $method = Folder->can($method_name) or return;
    my $target = $method->('Folder');
    die "Folder->$method_name in '$entry->{file}' must return a non-empty path string\n"
      if !defined $target || ref($target) || $target eq '';
    return $paths->_expand_home($target);
}

# _skill_folder_entries($paths)
# Enumerates installed top-level and nested skill roots with their dotted names
# and optional Folder.pm file locations.
# Input: path registry object.
# Output: list of hash references containing name, dir, and file.
sub _skill_folder_entries {
    my ($paths) = @_;
    die "Missing paths registry\n" if !$paths;
    return map {
        my $dir = $_->{dir};
        my $lib = File::Spec->catdir( $dir, 'lib' );
        {
            name => join( '.', @{ $_->{segments} || [] } ),
            dir  => $dir,
            file => File::Spec->catfile( $lib, 'Folder.pm' ),
            lib  => $lib,
        }
    } $paths->nested_skill_entries;
}

# _load_skill_folder_module($entry)
# Loads one skill's Folder.pm with its lib directory first in @INC and clears
# the reserved Folder package between skills so identical method names from
# separate skills cannot bleed into one another.
# Input: skill entry hash reference from _skill_folder_entries.
# Output: true if a module was loaded, false when Folder.pm is absent.
sub _load_skill_folder_module {
    my ($entry) = @_;
    die "Missing skill Folder entry\n" if ref($entry) ne 'HASH';
    my $file = $entry->{file} || die "Missing skill Folder.pm path\n";
    return 0 if !-f $file;

    my $real_skill = abs_path( $entry->{dir} );
    my $real_lib   = abs_path( $entry->{lib} );
    my $real_file  = abs_path($file);
    die "Unable to resolve skill Folder.pm '$file'\n"
      if !defined $real_skill || !defined $real_lib || !defined $real_file;
    my @lib_parts = File::Spec->splitdir( File::Spec->abs2rel( $real_lib, $real_skill ) );
    die "Skill Folder.pm lib directory '$entry->{lib}' resolves outside its skill root\n"
      if $lib_parts[0] eq File::Spec->updir();
    my @relative_parts = File::Spec->splitdir( File::Spec->abs2rel( $real_file, $real_lib ) );
    die "Skill Folder.pm '$file' resolves outside its skill lib directory\n"
      if $relative_parts[0] eq File::Spec->updir();

    {
        no strict 'refs';
        %Folder:: = ();
    }
    local @INC = ( $entry->{lib}, @INC );
    my $loaded = do $file;
    if ( !defined $loaded ) {
        die "Unable to load skill Folder.pm '$file': $@" if $@;
        die "Unable to load skill Folder.pm '$file': $!\n" if $!;
        die "Skill Folder.pm '$file' did not return a true value\n";
    }
    die "Skill Folder.pm '$file' did not return a true value\n" if !$loaded;
    return 1;
}

# _valid_folder_method_name($name)
# Accepts a plain Perl identifier for a Folder.pm method while excluding
# inherited UNIVERSAL methods that are not path aliases.
# Input: candidate alias/method name.
# Output: boolean true when it is a safe method identifier.
sub _valid_folder_method_name {
    my ($name) = @_;
    return 0 if !defined $name || ref($name) || $name !~ /\A[A-Za-z_]\w*\z/;
    return 0 if $name =~ /\A(?:can|isa|DOES|VERSION|DESTROY)\z/;
    return 1;
}

# _cdr_payload(%args)
# Resolves the shell helper target for cdr/which_dir without pushing fuzzy
# search logic into shell code.
# Input: hash containing a path registry under "paths" and an argv array
# reference under "args".
# Output: hash reference with "target" and "matches" keys.
sub _cdr_payload {
    my (%args) = @_;
    my $paths = $args{paths} || die "Missing paths registry\n";
    my $argv  = $args{args}  || [];
    die "cdr args must be an array reference\n" if ref($argv) ne 'ARRAY';

    my @terms = @{$argv};
    return { target => '', matches => [] } if !@terms;

    my $first = $terms[0];
    my $configured_aliases = $paths->named_paths || {};
    my $alias_target = eval { $paths->resolve_dir($first) };
    if ( !defined $alias_target && !exists $configured_aliases->{$first} && ref( $args{folder_alias_resolver} ) eq 'CODE' ) {
        $alias_target = $args{folder_alias_resolver}->($first);
    }
    if ( defined $alias_target && $alias_target ne '' ) {
        shift @terms;
        return { target => $alias_target, matches => [] } if !@terms;
        my @matches = $paths->locate_dirs_under( $alias_target, @terms );
        return {
            target  => @matches == 1 ? $matches[0] : $alias_target,
            matches => @matches == 1 ? [] : \@matches,
        };
    }

    my @matches = $paths->locate_dirs_under( $paths->current_working_directory, @terms );
    return {
        target  => @matches == 1 ? $matches[0] : '',
        matches => @matches == 1 ? [] : \@matches,
    };
}

# _cdr_completion(%args)
# Returns shell-completion candidates for the cdr/dd_cdr/which_dir helpers.
# Input: hash containing a path registry under "paths", the raw shell words
# array reference under "words", and the active completion index under "index".
# Output: ordered list of candidate strings.
sub _cdr_completion {
    my (%args) = @_;
    my $paths = $args{paths} || die "Missing paths registry\n";
    my $words = $args{words} || die "Missing completion words\n";
    my $index = defined $args{index} ? $args{index} : die "Missing completion index\n";
    die "cdr completion words must be an array reference\n" if ref($words) ne 'ARRAY';

    my @words = @{$words};
    return () if !@words;

    my $current = defined $words[$index] ? $words[$index] : '';
    my @args = @words > 1 ? @words[ 1 .. $#words ] : ();
    my $arg_index = $index - 1;

    if ( $arg_index <= 0 ) {
        return _cdr_initial_candidates(
            paths   => $paths,
            prefix  => $current,
            include => [ $paths->current_working_directory ],
        );
    }

    my $first = $args[0] // '';
    my $alias_target = eval { $paths->resolve_dir($first) };
    my $base_root = defined $alias_target && $alias_target ne '' ? $alias_target : $paths->current_working_directory;
    my $filter_start = defined $alias_target && $alias_target ne '' ? 1 : 0;
    my @filters = @args >= $arg_index ? @args[ $filter_start .. ( $arg_index - 1 ) ] : ();

    return _cdr_directory_candidates(
        paths   => $paths,
        root    => $base_root,
        terms   => \@filters,
        prefix  => $current,
    );
}

# _cdr_initial_candidates(%args)
# Builds first-argument completion candidates for cdr-family shell helpers from
# saved aliases and direct child directories beneath the current directory.
# Input: hash containing the path registry under "paths", one current-token
# prefix under "prefix", and an array reference of roots under "include".
# Output: ordered list of alias or direct-child directory candidate strings.
sub _cdr_initial_candidates {
    my (%args) = @_;
    my $paths  = $args{paths}   || die "Missing paths registry\n";
    my $prefix = defined $args{prefix} ? $args{prefix} : '';
    my $roots  = $args{include} || [];
    die "cdr completion include roots must be an array reference\n" if ref($roots) ne 'ARRAY';

    my @candidates = grep { index( $_, $prefix ) == 0 } keys %{ $paths->named_paths || {} };
    for my $root ( grep { defined && $_ ne '' && -d $_ } @{$roots} ) {
        my $dh = _open_completion_directory($root);
        next if !$dh;
        while ( my $entry = readdir $dh ) {
            next if $entry eq '.' || $entry eq '..';
            next if index( $entry, $prefix ) != 0;
            my $path = File::Spec->catdir( $root, $entry );
            next if !-d $path;
            push @candidates, $entry;
        }
        _close_completion_directory( $dh, $root );
    }

    my %seen;
    return sort grep { $_ ne '' && !$seen{$_}++ } @candidates;
}

# _cdr_directory_candidates(%args)
# Builds unique directory-basename candidates beneath one root without
# recursively searching unrelated subtrees during shell completion.
# Input: hash containing the path registry under "paths", one search root under
# "root", an array reference of already-accepted narrowing terms under "terms",
# and the current token prefix under "prefix". Each accepted term narrows one
# directory level before the next level is inspected.
# Output: ordered list of directory basename strings.
sub _cdr_directory_candidates {
    my (%args) = @_;
    my $paths  = $args{paths} || die "Missing paths registry\n";
    my $root   = $args{root}  || return ();
    my $terms  = $args{terms} || [];
    my $prefix = defined $args{prefix} ? $args{prefix} : '';
    die "cdr completion terms must be an array reference\n" if ref($terms) ne 'ARRAY';

    my @parents = ($root);
    for my $term ( grep { defined && $_ ne '' } @{$terms} ) {
        my $regex = eval { qr/$term/i };
        die "Invalid regex '$term': $@\n" if !$regex;
        my @next;
        for my $parent (@parents) {
            my $dh = _open_completion_directory($parent);
            next if !$dh;
            while ( my $entry = readdir $dh ) {
                next if $entry eq '.' || $entry eq '..';
                next if $entry !~ $regex;
                my $path = File::Spec->catdir( $parent, $entry );
                push @next, $path if -d $path;
            }
            _close_completion_directory( $dh, $parent );
        }
        @parents = @next;
        last if !@parents;
    }

    my %seen;
    my @candidates;
    for my $parent (@parents) {
        my $dh = _open_completion_directory($parent);
        next if !$dh;
        while ( my $entry = readdir $dh ) {
            next if $entry eq '.' || $entry eq '..';
            next if $prefix ne '' && index( $entry, $prefix ) != 0;
            my $path = File::Spec->catdir( $parent, $entry );
            next if !-d $path;
            next if $seen{$entry}++;
            push @candidates, $entry;
        }
        _close_completion_directory( $dh, $parent );
    }

    return sort @candidates;
}

# _open_completion_directory($path)
# Opens one directory for bounded cdr completion, returning no handle when the
# directory disappeared or cannot be read during completion.
# Input: directory path string.
# Output: open directory handle, or undef when opendir fails.
sub _open_completion_directory {
    my ($path) = @_;
    opendir my $dh, $path or return;
    return $dh;
}

# _close_completion_directory($handle, $path)
# Closes one directory opened for cdr completion and reports a close failure.
# Input: open directory handle and its path for diagnostics.
# Output: true on success; dies naming the path when closedir fails.
sub _close_completion_directory {
    my ( $dh, $path ) = @_;
    closedir $dh or die "Unable to close directory $path: $!";
    return 1;
}

# _paths_table($paths_hash)
# Renders one full path inventory as a two-column summary table.
# Input: hash reference keyed by logical path name.
# Output: formatted table text string.
sub _paths_table {
    my ($all_paths) = @_;
    my @rows = map { [ $_, $all_paths->{$_} ] } sort keys %{ $all_paths || {} };
    return render_table( [ 'Path', 'Value' ], \@rows );
}

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::Paths - lightweight path and paths helper dispatch

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Paths qw(run_paths_command);
  run_paths_command(command => 'paths', args => \@ARGV);

=head1 DESCRIPTION

Implements the lightweight C<dashboard path> and C<dashboard paths> commands so
the public entrypoint can hand off path-related work to an extracted helper
script under F<~/.developer-dashboard/cli/>. That includes the shared
target-selection logic used by shell helpers such as C<cdr> and
C<which_dir>.
Installed skills may also expose path methods from C<lib/Folder.pm>: config
aliases take precedence, while a skill's optional C<Folder-E<gt>__list__>
provides additional aliases for lookup, completion, and path inventories.

=head1 FUNCTIONS

=head2 run_paths_command

Dispatch the path helper command.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the command runtime behind C<dashboard paths> and C<dashboard path ...>. It prints the active runtime roots, resolves named aliases, persists alias add/delete operations, computes the JSON payload used by shell helpers such as C<cdr> and C<which_dir>, and returns the live completion candidates used by the C<cdr> shell functions.

=head1 WHY IT EXISTS

It exists because path reporting and shell-navigation semantics should live in Perl, not in duplicated shell code. That keeps the layered runtime rules, alias loading, and regex-based directory narrowing consistent across bash, zsh, POSIX sh, and PowerShell.

=head1 WHEN TO USE

Use this file when changing the output of C<dashboard paths>, the behavior of C<dashboard path resolve/add/del/rm/list/project-root>, the C<cdr> payload contract consumed by shell helpers, or the completion candidates exposed to C<cdr>, C<dd_cdr>, and C<which_dir>.

=head1 HOW TO USE

Call C<run_paths_command> with the public command name and argv list. The
module builds a lightweight path registry, loads configured aliases on demand,
keeps shell-plumbing verbs such as C<resolve>, C<project-root>, C<cdr>, and
C<complete-cdr> on their direct line or JSON contracts, and renders the
operator-facing inventory and mutation verbs as human-readable tables by
default with C<-o json> available for the full machine payload. For
C<dashboard path cdr>, the first argument is
treated as a saved alias when one exists; otherwise it becomes the first search
regex under the current directory. Any remaining narrowing terms are
case-insensitive regexes and all of them must match a candidate path. A single
match becomes the target directory; multiple matches are returned as a list
while the target stays at the alias root or current directory. For
C<dashboard path complete-cdr>, pass the shell completion index followed by the
raw shell words, for example C<cdr foobar alp>; the helper returns newline
delimited completion candidates for aliases or matching directory basenames.

An installed skill can define C<lib/Folder.pm> with C<package Folder;> and
methods that return path strings. C<cdr E<lt>skillE<gt>.E<lt>aliasE<gt>> and
C<dashboard path resolve> consult the effective C<config/config.json> path
alias first, then call the matching method from C<Folder.pm>. If the module
implements C<__list__>, its list-context alias names are called and merged
into C<dashboard paths>, C<dashboard path list>, and completion output. This
is a read-only merge: C<dashboard path add> continues to write aliases only
to config, where a configured value overrides a same-named module method. C<cdr>
completion includes aliases and only direct child directories; each entered
term narrows one level before the next candidates are listed. It avoids
recursive walks of unrelated checkout and dependency trees on every TAB.

=head1 WHAT USES IT

It is used by the staged path helpers, by the shell bootstrap generated from
C<_dashboard-core>, and by tests that cover alias resolution, regex narrowing,
current-directory fallback, layered runtime lookup, and platform-portable shell
output.

=head1 EXAMPLES

  dashboard paths
  dashboard path resolve bookmarks
  dashboard path cdr project alpha ".*service"
  cdr ch.workspace
  d2 paths -o json
  dashboard path complete-cdr 2 cdr project alp
  dashboard path add work ~/projects/work
  dashboard path add .
  dashboard path add scratch /tmp/scratch --create
  dashboard path add scratch /tmp/scratch --create 0777
  dashboard path rm work
  dashboard path list

=for comment FULL-POD-DOC END

=cut
