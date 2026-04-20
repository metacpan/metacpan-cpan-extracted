package Developer::Dashboard::SkillDispatcher;

use strict;
use warnings;

our $VERSION = '2.72';

use File::Spec;
use JSON::XS qw(encode_json decode_json);
use Capture::Tiny qw(capture);
use File::Basename qw(dirname basename);
use Developer::Dashboard::CLI::Suggest;
use Developer::Dashboard::EnvLoader;
use Developer::Dashboard::Runtime::Result;
use Developer::Dashboard::SkillManager;
use Developer::Dashboard::Platform qw(command_argv_for_path is_runnable_file resolve_runnable_file);

# new()
# Creates a SkillDispatcher instance to execute skill commands.
# Input: none.
# Output: SkillDispatcher object.
sub new {
    my ( $class, %args ) = @_;
    my $manager = $args{manager} || Developer::Dashboard::SkillManager->new( paths => $args{paths} );
    return bless {
        manager => $manager,
    }, $class;
}

# dispatch($skill_name, $command, @args)
# Executes a command from an installed skill.
# Input: skill repo name, command name, and command arguments.
# Output: command output or error hash.
sub dispatch {
    my ( $self, $skill_name, $command, @args ) = @_;
    return { error => 'Missing skill name' } if !$skill_name;
    return { error => 'Missing command name' } if !$command;

    my $skill_path = $self->{manager}->get_skill_path( $skill_name, include_disabled => 1 );
    my $suggest = Developer::Dashboard::CLI::Suggest->new(
        paths   => $self->{manager}{paths},
        manager => $self->{manager},
    );
    return { error => $suggest->unknown_skill_command_message( $skill_name, $command ) } if !$skill_path;
    return { error => $suggest->unknown_skill_command_message( $skill_name, $command ) } if !$self->{manager}->is_enabled($skill_name);

    my $command_spec = $self->_command_spec( $skill_name, $command );
    my $cmd_path = $command_spec ? $command_spec->{cmd_path} : undef;
    my $command_skill_path = $command_spec ? $command_spec->{skill_path} : undef;
    return { error => $suggest->unknown_skill_command_message( $skill_name, $command ) } if !$cmd_path;

    my $hook_result = $self->execute_hooks( $skill_name, $command, @args );
    return $hook_result if $hook_result->{error};
    my @skill_layers = $command_spec ? @{ $command_spec->{skill_layers} || [] } : $self->_skill_layers($skill_name);

    my %env = $self->_skill_env(
        skill_name   => $skill_name,
        skill_path   => $command_skill_path || $skill_path,
        skill_layers => \@skill_layers,
        command      => $command_spec ? $command_spec->{command_name} : $command,
        result_state => $hook_result->{result_state} || {},
    );
    my @command = command_argv_for_path($cmd_path);

    my ( $stdout, $stderr, $exit ) = capture {
        local %ENV = ( %ENV, %env );
        Developer::Dashboard::Runtime::Result::set_current( $hook_result->{result_state} || {} );
        if ( ref( $hook_result->{last_result} ) eq 'HASH' && %{ $hook_result->{last_result} } ) {
            Developer::Dashboard::Runtime::Result::set_last_result( $hook_result->{last_result} );
        }
        else {
            Developer::Dashboard::Runtime::Result::clear_last_result();
        }
        Developer::Dashboard::EnvLoader->load_runtime_layers( paths => $self->{manager}{paths} );
        Developer::Dashboard::EnvLoader->load_skill_layers( skill_layers => \@skill_layers );
        system( @command, @args );
    };
    my $hook_stdout = join '', map { defined $_->{stdout} ? $_->{stdout} : '' } values %{ $hook_result->{hooks} || {} };
    my $hook_stderr = join '', map { defined $_->{stderr} ? $_->{stderr} : '' } values %{ $hook_result->{hooks} || {} };
    return {
        stdout    => $hook_stdout . $stdout,
        stderr    => $hook_stderr . $stderr,
        exit_code => $exit,
        hooks     => $hook_result->{hooks} || {},
    };
}

# execute_hooks($skill_name, $command, @args)
# Executes hook files from skill's cli/<command>.d/ directory before main command.
# Input: skill repo name, command name, and command arguments.
# Output: hash with hook results and environment.
sub execute_hooks {
    my ( $self, $skill_name, $command, @args ) = @_;
    return { hooks => {}, result_state => {} } if !$skill_name || !$command;
    my $skill_path = $self->{manager}->get_skill_path( $skill_name, include_disabled => 1 );
    return { hooks => {}, result_state => {} } if !$skill_path;
    return { hooks => {}, result_state => {} } if !$self->{manager}->is_enabled($skill_name);
    my $command_spec = $self->_command_spec( $skill_name, $command );
    my @skill_layers = $command_spec ? @{ $command_spec->{skill_layers} || [] } : $self->_skill_layers($skill_name);
    return { hooks => {}, result_state => {} } if !@skill_layers;
    my $resolved_command = $command_spec ? $command_spec->{command_name} : $command;

    my %results;
    my $last_result = {};
    for my $layer_path (@skill_layers) {
        my $hooks_dir = File::Spec->catdir( $layer_path, 'cli', "$resolved_command.d" );
        next if !-d $hooks_dir;
        opendir( my $dh, $hooks_dir ) or die "Unable to read $hooks_dir: $!";
        for my $entry ( sort grep { $_ ne '.' && $_ ne '..' } readdir($dh) ) {
            my $hook_path = File::Spec->catfile( $hooks_dir, $entry );
            next unless is_runnable_file($hook_path);

            my %env = $self->_skill_env(
                skill_name   => $skill_name,
                skill_path   => $layer_path,
                skill_layers => \@skill_layers,
                command      => $resolved_command,
                result_state => \%results,
            );
            my @command = command_argv_for_path($hook_path);
            my ( $stdout, $stderr, $exit ) = capture {
                local %ENV = ( %ENV, %env );
                Developer::Dashboard::Runtime::Result::set_current( \%results );
                if (%{$last_result}) {
                    Developer::Dashboard::Runtime::Result::set_last_result($last_result);
                }
                else {
                    Developer::Dashboard::Runtime::Result::clear_last_result();
                }
                Developer::Dashboard::EnvLoader->load_runtime_layers( paths => $self->{manager}{paths} );
                Developer::Dashboard::EnvLoader->load_skill_layers( skill_layers => \@skill_layers );
                system( @command, @args );
            };
            my $result_key = exists $results{$entry} ? $self->_hook_result_key($hook_path) : $entry;
            $results{$result_key} = {
                stdout    => $stdout,
                stderr    => $stderr,
                exit_code => $exit,
            };
            $last_result = {
                file   => $hook_path,
                exit   => $exit,
                STDOUT => $stdout,
                STDERR => $stderr,
            };
        }
        closedir($dh);
    }
    my %payload = (
        hooks        => \%results,
        result_state => \%results,
    );
    $payload{last_result} = $last_result if %{$last_result};
    return \%payload;
}

# get_skill_config($skill_name)
# Reads and returns a skill's configuration.
# Input: skill repo name.
# Output: hash ref with config or empty hash.
sub get_skill_config {
    my ( $self, $skill_name ) = @_;
    
    return {} if !$skill_name;

    my @skill_layers = $self->_skill_layers($skill_name);
    return {} if !@skill_layers;

    my $merged = {};
    for my $skill_path (@skill_layers) {
        my $config_file = File::Spec->catfile( $skill_path, 'config', 'config.json' );
        next if !-f $config_file;

        open( my $fh, '<', $config_file ) or return {};
        my $json_text = do { local $/; <$fh> };
        close($fh);

        my $config = eval { decode_json($json_text) } || {};
        return {} if ref($config) ne 'HASH';
        $merged = $self->_merge_skill_hashes( $merged, $config );
    }

    return $merged;
}

# config_fragment($skill_name)
# Wraps one installed skill config under its underscored runtime key for merged config use.
# Input: skill repo name.
# Output: hash ref containing one underscored skill key and its decoded config.
sub config_fragment {
    my ( $self, $skill_name ) = @_;
    return {} if !$skill_name;
    my $config = $self->get_skill_config($skill_name);
    return {} if ref($config) ne 'HASH' || !%{$config};
    return { '_' . $skill_name => $config };
}

# get_skill_path($skill_name)
# Returns the path to an installed skill.
# Input: skill repo name.
# Output: skill path string or undef.
sub get_skill_path {
    my ( $self, $skill_name ) = @_;
    
    return if !$skill_name;
    return $self->{manager}->get_skill_path($skill_name);
}

# command_path($skill_name, $command)
# Resolves one executable command within the isolated skill CLI tree.
# Input: skill repo name and command name.
# Output: executable file path string or undef.
sub command_path {
    my ( $self, $skill_name, $command ) = @_;
    return if !$skill_name || !$command;
    my $command_spec = $self->_command_spec( $skill_name, $command );
    return $command_spec ? $command_spec->{cmd_path} : undef;
}

# command_spec($skill_name, $command)
# Resolves one dotted skill command and returns the internal command
# specification used for dispatch.
# Input: skill repo name and command name.
# Output: hash reference containing cmd_path, skill_path, skill_layers, and
# command_name, or undef when the command cannot be resolved.
sub command_spec {
    my ( $self, $skill_name, $command ) = @_;
    return if !$skill_name || !$command;
    return $self->_command_spec( $skill_name, $command );
}

# command_hook_paths($skill_name, $command)
# Enumerates the skill-local hook files that would execute before one resolved
# skill command across every participating skill layer.
# Input: skill repo name and command name.
# Output: ordered list of absolute hook file paths.
sub command_hook_paths {
    my ( $self, $skill_name, $command ) = @_;
    return () if !$skill_name || !$command;
    my $command_spec = $self->_command_spec( $skill_name, $command );
    return () if !$command_spec;

    my @hooks;
    my $resolved_command = $command_spec->{command_name} || '';
    return () if $resolved_command eq '';

    for my $layer_path ( @{ $command_spec->{skill_layers} || [] } ) {
        my $hooks_dir = File::Spec->catdir( $layer_path, 'cli', "$resolved_command.d" );
        next if !-d $hooks_dir;
        opendir( my $dh, $hooks_dir ) or die "Unable to read $hooks_dir: $!";
        for my $entry ( sort grep { $_ ne '.' && $_ ne '..' } readdir($dh) ) {
            my $hook_path = File::Spec->catfile( $hooks_dir, $entry );
            next unless is_runnable_file($hook_path);
            push @hooks, $hook_path;
        }
        closedir($dh);
    }

    return @hooks;
}

# route_response(%args)
# Serves isolated skill browser routes and the older /skill bookmark namespace.
# Input: skill name, route path, and optional web app for rendering.
# Output: array reference HTTP response.
sub route_response {
    my ( $self, %args ) = @_;
    my $skill_name = $args{skill_name} || '';
    my $route      = defined $args{route} ? $args{route} : '';
    my @skill_layers = $self->_skill_layers($skill_name);
    return [ 404, 'text/plain; charset=utf-8', "Skill '$skill_name' not found\n" ] if !@skill_layers;

    my @parts = grep { defined && $_ ne '' } split m{/+}, $route;
    my @dashboards_roots = map { File::Spec->catdir( $_, 'dashboards' ) } @skill_layers;
    return [ 404, 'text/plain; charset=utf-8', "Skill '$skill_name' does not provide dashboards\n" ]
      if !grep { -d $_ } @dashboards_roots;

    if ( @parts && $parts[0] eq 'bookmarks' ) {
        if ( @parts == 1 ) {
            my @items = $self->_skill_bookmark_entries($skill_name);
            return [ 404, 'text/plain; charset=utf-8', "Skill '$skill_name' does not provide dashboards\n" ] if !@items;
            return [ 200, 'application/json; charset=utf-8', encode_json( { skill => $skill_name, bookmarks => \@items } ) ];
        }

        my $legacy_id = join '/', @parts[ 1 .. $#parts ];
        return $self->_skill_page_response(
            %args,
            skill_name => $skill_name,
            route_id   => $legacy_id,
        );
    }

    my $route_id = @parts ? join( '/', @parts ) : 'index';
    return $self->_skill_page_response(
        %args,
        skill_name => $skill_name,
        route_id   => $route_id,
    );
}

# skill_nav_pages($skill_name)
# Loads the skill-local nav/*.tt or bookmark pages used by /app/<skill> routes.
# Input: skill repo name.
# Output: array ref of prepared page documents before runtime state is applied.
sub skill_nav_pages {
    my ( $self, $skill_name ) = @_;
    return [] if !$skill_name;
    my %route_ids = $self->_skill_nav_route_ids($skill_name);
    return [] if !%route_ids;

    my @pages;
    for my $entry ( sort keys %route_ids ) {
        push @pages, $self->_load_skill_page(
            skill_name => $skill_name,
            route_id   => $route_ids{$entry},
        );
    }
    return \@pages;
}

# all_skill_nav_pages()
# Loads nav bookmark pages from every installed skill in deterministic skill order.
# Input: none.
# Output: array ref of prepared page documents before runtime state is applied.
sub all_skill_nav_pages {
    my ($self) = @_;
    my @pages;
    for my $skill_root ( $self->{manager}{paths}->installed_skill_roots ) {
        my ($skill_name) = $skill_root =~ m{/([^/]+)\z};
        next if !defined $skill_name || $skill_name eq '';
        push @pages, @{ $self->skill_nav_pages($skill_name) || [] };
    }
    return \@pages;
}

# _skill_page_response(%args)
# Loads one skill page and optionally hands it to the web app renderer.
# Input: skill name, skill path, route id, and optional app plus request metadata.
# Output: response array reference.
sub _skill_page_response {
    my ( $self, %args ) = @_;
    my $page = eval {
        $self->_load_skill_page(
            skill_name => $args{skill_name},
            route_id   => $args{route_id},
        );
    };
    return [ 404, 'text/plain; charset=utf-8', "Skill bookmark '$args{route_id}' not found\n" ] if !$page || $@;
    return [ 200, 'text/plain; charset=utf-8', $page->{meta}{raw_instruction} || $page->canonical_instruction ]
      if !$args{app};

    my $app = $args{app};
    $page = $app->_page_with_runtime_state(
        $page,
        query_params => $args{query_params} || {},
        body_params  => $args{body_params}  || {},
        path         => $args{path} || '/app/' . $page->{id},
        remote_addr  => $args{remote_addr},
        headers      => $args{headers} || {},
    );
    $page = $app->{runtime}->prepare_page(
        page            => $page,
        source          => 'skill',
        runtime_context => { params => { %{ $args{query_params} || {} }, %{ $args{body_params} || {} } } },
    );
    return $app->_page_response( $page, 'render' );
}

# _load_skill_page(%args)
# Loads one layered skill page document from dashboards/<id> and namespaces its
# page id under /app/<skill>/...
# Input: skill name and relative route id such as index, foo, or nav/file.tt.
# Output: page document object.
sub _load_skill_page {
    my ( $self, %args ) = @_;
    my $skill_name = $args{skill_name} || die 'Missing skill name';
    my $route_id   = $args{route_id}   || die 'Missing route id';
    my ( $file, $skill_path ) = $self->_page_location( $skill_name, $route_id );
    die "Skill bookmark '$route_id' not found" if !defined $file || !-f $file;

    require Developer::Dashboard::PageDocument;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    my $instruction = <$fh>;
    close $fh;

    my $page = eval { Developer::Dashboard::PageDocument->from_instruction($instruction) };
    if ( !$page && $route_id =~ m{\Anav/.+\.tt\z} ) {
        $page = Developer::Dashboard::PageDocument->new(
            id     => $skill_name . '/' . $route_id,
            title  => $route_id,
            layout => { body => $instruction },
            meta   => { source_format => 'raw-nav-tt' },
        );
    }
    die( $@ || "Unable to parse skill bookmark '$route_id'" ) if !$page;

    $page->{id} = $skill_name . ( $route_id eq 'index' ? '' : '/' . $route_id );
    $page->{meta}{source_kind}      = 'skill';
    $page->{meta}{skill_name}       = $skill_name;
    $page->{meta}{skill_route_id}   = $route_id;
    $page->{meta}{skill_path}       = $skill_path;
    $page->{meta}{raw_instruction}  = $instruction;
    return $page;
}

# _skill_env(%args)
# Builds the isolated environment passed to skill hooks and commands.
# Input: skill name, skill path, and command name.
# Output: hash of environment variables.
sub _skill_env {
    my ( $self, %args ) = @_;
    my $skill_path = $args{skill_path} || die 'Missing skill path';
    my $local_root = File::Spec->catdir( $skill_path, 'local' );
    my $path_sep   = $^O eq 'MSWin32' ? ';' : ':';
    my @perl5lib   = grep { defined && $_ ne '' } split /\Q$path_sep\E/, ( $ENV{PERL5LIB} || '' );
    for my $layer_path ( reverse @{ $args{skill_layers} || [] } ) {
        my $local_lib = File::Spec->catdir( $layer_path, 'local', 'lib', 'perl5' );
        unshift @perl5lib, $local_lib if -d $local_lib;
    }

    return (
        DEVELOPER_DASHBOARD_SKILL_NAME        => $args{skill_name},
        DEVELOPER_DASHBOARD_SKILL_ROOT        => $skill_path,
        DEVELOPER_DASHBOARD_SKILL_COMMAND     => $args{command},
        DEVELOPER_DASHBOARD_SKILL_CLI_ROOT    => File::Spec->catdir( $skill_path, 'cli' ),
        DEVELOPER_DASHBOARD_SKILL_CONFIG_ROOT => File::Spec->catdir( $skill_path, 'config' ),
        DEVELOPER_DASHBOARD_SKILL_DOCKER_ROOT => File::Spec->catdir( $skill_path, 'config', 'docker' ),
        DEVELOPER_DASHBOARD_SKILL_STATE_ROOT  => File::Spec->catdir( $skill_path, 'state' ),
        DEVELOPER_DASHBOARD_SKILL_LOGS_ROOT   => File::Spec->catdir( $skill_path, 'logs' ),
        DEVELOPER_DASHBOARD_SKILL_LOCAL_ROOT  => $local_root,
        PERL5LIB                              => join( $path_sep, @perl5lib ),
    );
}

# _skill_layers($skill_name)
# Returns the participating installed roots for one skill in inheritance order.
# Input: skill repository name string and optional include_disabled flag.
# Output: ordered list of skill root directory path strings from home to leaf.
sub _skill_layers {
    my ( $self, $skill_name, %args ) = @_;
    return () if !$skill_name;
    my $paths = $self->{manager}{paths};
    return $paths->skill_layers( $skill_name, %args ) if $paths->can('skill_layers');
    my $skill_path = $self->{manager}->get_skill_path( $skill_name, %args ) or return ();
    return ($skill_path);
}

# _skill_lookup_roots($skill_name)
# Returns the participating installed roots for one skill in effective lookup order.
# Input: skill repository name string and optional include_disabled flag.
# Output: ordered list of skill root directory path strings from leaf to home.
sub _skill_lookup_roots {
    my ( $self, $skill_name, %args ) = @_;
    return reverse $self->_skill_layers( $skill_name, %args );
}

# _command_spec($skill_name, $command)
# Resolves one runnable skill command across every participating skill layer,
# including nested skills/<repo>/cli command trees addressed through dotted
# command tails such as foo.bar.
# Input: skill repository name string and command name string.
# Output: hash reference containing cmd_path, skill_path, skill_layers, and command_name.
sub _command_spec {
    my ( $self, $skill_name, $command ) = @_;
    return if !$skill_name || !$command;

    my @segments = grep { defined && $_ ne '' } split /\./, $command;
    return if !@segments;

    for my $command_root_spec ( $self->_command_root_specs( \@segments ) ) {
        my @provider_layers = ();
        for my $skill_path ( $self->_skill_layers($skill_name) ) {
            my $provider_path = $skill_path;
            if ( @{ $command_root_spec->{nested_segments} } ) {
                $provider_path = $self->_nested_skill_path( $skill_path, $command_root_spec->{nested_segments} );
                next if !-d $provider_path;
            }
            push @provider_layers, $provider_path;
        }
        next if !@provider_layers;

        for my $provider_path ( reverse @provider_layers ) {
            my $cmd_path = resolve_runnable_file( File::Spec->catfile( $provider_path, 'cli', $command_root_spec->{command_name} ) );
            next if !$cmd_path;
            return {
                cmd_path      => $cmd_path,
                skill_path    => $provider_path,
                skill_layers  => \@provider_layers,
                command_name  => $command_root_spec->{command_name},
            };
        }
    }

    return;
}

# _command_root_specs(\@segments)
# Builds candidate nested-skill command roots from the dotted command tail.
# Input: array reference of dotted command segments.
# Output: ordered list of hash references with nested_segments and command_name.
sub _command_root_specs {
    my ( $self, $segments ) = @_;
    my @segments = @{ $segments || [] };
    return () if !@segments;

    my @specs = (
        {
            nested_segments => [],
            command_name    => join( '.', @segments ),
        },
    );

    for my $split_index ( 1 .. $#segments ) {
        push @specs, {
            nested_segments => [ @segments[ 0 .. $split_index - 1 ] ],
            command_name    => join( '.', @segments[ $split_index .. $#segments ] ),
        };
    }

    return @specs;
}

# _nested_skill_path($skill_path, \@nested_segments)
# Resolves one nested installed-skill tree where each dotted skill segment lives
# beneath its own repeated skills/<repo> directory pair.
# Input: installed skill root path string and array reference of nested skill names.
# Output: absolute nested skill root path string.
sub _nested_skill_path {
    my ( $self, $skill_path, $nested_segments ) = @_;
    my @segments = @{ $nested_segments || [] };
    return $skill_path if !@segments;

    my @parts = ($skill_path);
    for my $segment (@segments) {
        push @parts, 'skills', $segment;
    }
    return File::Spec->catdir(@parts);
}

# _page_location($skill_name, $route_id)
# Resolves one skill dashboard file across every participating skill layer.
# Input: skill repository name string and route id string such as index or nav/foo.tt.
# Output: file path string and the skill layer root that provided it.
sub _page_location {
    my ( $self, $skill_name, $route_id ) = @_;
    return if !$skill_name || !$route_id;
    for my $skill_path ( $self->_skill_lookup_roots($skill_name) ) {
        my $file = File::Spec->catfile( $skill_path, 'dashboards', split m{/+}, $route_id );
        return ( $file, $skill_path ) if -f $file;
    }
    return;
}

# _skill_bookmark_entries($skill_name)
# Enumerates non-nav bookmark files contributed by one layered skill with deepest
# duplicates overriding shallower layers.
# Input: skill repository name string.
# Output: sorted list of bookmark entry names.
sub _skill_bookmark_entries {
    my ( $self, $skill_name ) = @_;
    return () if !$skill_name;
    my %entries;
    for my $skill_path ( $self->_skill_lookup_roots($skill_name) ) {
        my $dashboards_root = File::Spec->catdir( $skill_path, 'dashboards' );
        next if !-d $dashboards_root;
        opendir( my $dh, $dashboards_root ) or die "Unable to read $dashboards_root: $!";
        for my $entry (
            grep {
                   $_ ne '.'
                && $_ ne '..'
                && $_ ne 'nav'
                && -f File::Spec->catfile( $dashboards_root, $_ )
            } readdir($dh)
          )
        {
            $entries{$entry} ||= 1;
        }
        closedir($dh);
    }
    return sort keys %entries;
}

# _skill_nav_route_ids($skill_name)
# Enumerates nav/*.tt routes contributed by one layered skill with deepest
# duplicates overriding shallower layers.
# Input: skill repository name string.
# Output: hash of nav filenames to route ids.
sub _skill_nav_route_ids {
    my ( $self, $skill_name ) = @_;
    return () if !$skill_name;
    my %routes;
    for my $skill_path ( $self->_skill_lookup_roots($skill_name) ) {
        my $nav_root = File::Spec->catdir( $skill_path, 'dashboards', 'nav' );
        next if !-d $nav_root;
        opendir my $dh, $nav_root or die "Unable to read $nav_root: $!";
        for my $entry (
            grep {
                   $_ ne '.'
                && $_ ne '..'
                && -f File::Spec->catfile( $nav_root, $_ )
            } readdir $dh
          )
        {
            $routes{$entry} ||= 'nav/' . $entry;
        }
        closedir $dh;
    }
    return %routes;
}

# _hook_result_key($hook_path)
# Builds a deterministic unique result key for duplicate hook basenames across
# layered skill hook directories.
# Input: absolute hook file path string.
# Output: result key string.
sub _hook_result_key {
    my ( $self, $hook_path ) = @_;
    my $leaf = basename( dirname($hook_path) );
    return $leaf . '/' . basename($hook_path);
}

# _merge_skill_hashes($left, $right)
# Recursively merges layered skill config hashes so deeper layers override keys
# while missing keys continue to fall back to inherited base layers.
# Input: two hash references where right-hand values override left-hand values.
# Output: merged hash reference.
sub _merge_skill_hashes {
    my ( $self, $left, $right ) = @_;
    $left  ||= {};
    $right ||= {};

    my %merged = (%{$left});
    for my $key ( keys %{$right} ) {
        if ( ref( $left->{$key} ) eq 'HASH' && ref( $right->{$key} ) eq 'HASH' ) {
            $merged{$key} = $self->_merge_skill_hashes( $left->{$key}, $right->{$key} );
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
# Merges named array entries so deeper skill layers can override logical items
# without discarding unmatched inherited items.
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

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::SkillDispatcher - execute commands from installed skills

=head1 SYNOPSIS

  use Developer::Dashboard::SkillDispatcher;
  my $dispatcher = Developer::Dashboard::SkillDispatcher->new();
  
  my $result = $dispatcher->dispatch('skill-name', 'cmd', 'arg1', 'arg2');
  my $hooks = $dispatcher->execute_hooks('skill-name', 'cmd');
  my $config = $dispatcher->get_skill_config('skill-name');
  my $path = $dispatcher->get_skill_path('skill-name');

=head1 DESCRIPTION

Dispatches commands to and manages execution of installed dashboard skills.
Handles:
- Command execution with isolation
- Hook file execution in sorted order
- Configuration reading
- Skill path resolution
- Command output capture

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module executes installed skill commands and serves skill bookmark routes. It resolves a skill command path, runs any sorted hook files under C<cli/E<lt>commandE<gt>.d>, prepares the isolated skill environment, hands hook state through C<Developer::Dashboard::Runtime::Result> so oversized hook payloads spill into C<RESULT_FILE> automatically, captures stdout/stderr, and can render bookmarks under C</skill/E<lt>repoE<gt>/bookmarks/...> through the main page renderer.

=head1 WHY IT EXISTS

It exists because the skill system needs a boundary between skill installation and skill execution. Dispatching commands, hook chaining, isolated environment variables, and bookmark routing all belong in one module instead of being hand-built in the web layer or CLI wrappers.

=head1 WHEN TO USE

Use this file when changing skill command execution, hook order, the skill environment contract, or the bookmark route behavior exposed under the C</skill/...> URL space.

=head1 HOW TO USE

Construct it with a skill manager, call C<dispatch> for one command invocation, or call C<route_response> when the web app needs a bookmark response from a skill. Keep skill execution isolation here instead of folding it into generic command code.

=head1 WHAT USES IT

It is used by dotted C<dashboard E<lt>repo-nameE<gt>.E<lt>commandE<gt>> dispatch routed through the C<skills> helper, by the skill bookmark web routes, by skill installation flows that later need execution, and by skill-system and web-route regression tests.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::SkillDispatcher -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/19-skill-system.t t/20-skill-web-routes.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
