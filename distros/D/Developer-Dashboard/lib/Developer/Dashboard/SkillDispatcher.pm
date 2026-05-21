package Developer::Dashboard::SkillDispatcher;

use strict;
use warnings;

our $VERSION = '3.90';

use Config ();
use IPC::Open3 qw(open3);
use File::Spec;
use IO::Select;
use JSON::XS qw(encode_json decode_json);
use Capture::Tiny qw(capture);
use File::Basename qw(dirname basename);
use Symbol qw(gensym);
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

# exec_command($skill_name, $command, @args)
# Executes one skill command by streaming hooks first and then replacing the
# current helper process with the resolved skill command so interactive stdin,
# stdout, and stderr behave exactly like a direct invocation.
# Input: skill repo name, command name, and command arguments.
# Output: never returns on success; otherwise returns an error hash.
sub exec_command {
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

    my @skill_layers = $command_spec ? @{ $command_spec->{skill_layers} || [] } : $self->_skill_layers($skill_name);
    my $hook_result = $self->_execute_hooks_streaming( $skill_name, $command_spec ? $command_spec->{command_name} : $command, \@skill_layers, @args );
    return $hook_result if $hook_result->{error};

    my %env = $self->_skill_env(
        skill_name   => $skill_name,
        skill_path   => $command_skill_path || $skill_path,
        skill_layers => \@skill_layers,
        command      => $command_spec ? $command_spec->{command_name} : $command,
        result_state => $hook_result->{result_state} || {},
    );
    my @command = command_argv_for_path($cmd_path);
    %ENV = ( %ENV, %env );
    Developer::Dashboard::Runtime::Result::set_current( $hook_result->{result_state} || {} );
    if ( ref( $hook_result->{last_result} ) eq 'HASH' && %{ $hook_result->{last_result} } ) {
        Developer::Dashboard::Runtime::Result::set_last_result( $hook_result->{last_result} );
    }
    else {
        Developer::Dashboard::Runtime::Result::clear_last_result();
    }
    Developer::Dashboard::EnvLoader->load_runtime_layers( paths => $self->{manager}{paths} );
    Developer::Dashboard::EnvLoader->load_skill_layers( skill_layers => \@skill_layers );
    return $self->_exec_resolved_command( $cmd_path, \@command, \@args );
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
            my $result_key = $entry;
            if ( exists $results{$entry} ) {
                my $leaf = basename( dirname($hook_path) );
                $result_key = $leaf . '/' . basename($hook_path);
            }
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

# _execute_hooks_streaming($skill_name, $command, $skill_layers, @args)
# Executes skill hook files while preserving live stdio so interactive hooks
# and later main commands can still read from the caller's stdin and print
# prompts without buffering surprises.
# Input: skill repo name, resolved command name, array reference of skill layer
# paths, and command arguments.
# Output: hash reference containing hook captures, result_state, and
# last_result.
sub _execute_hooks_streaming {
    my ( $self, $skill_name, $command, $skill_layers, @args ) = @_;
    return { hooks => {}, result_state => {} } if !$skill_name || !$command;
    my @skill_layers = @{ $self->_arrayref_or_empty($skill_layers) };
    return { hooks => {}, result_state => {} } if !@skill_layers;

    my %results;
    my $last_result = {};
    for my $layer_path (@skill_layers) {
        my $hooks_dir = File::Spec->catdir( $layer_path, 'cli', "$command.d" );
        next if !-d $hooks_dir;
        opendir( my $dh, $hooks_dir ) or die "Unable to read $hooks_dir: $!";
        for my $entry ( sort grep { $_ ne '.' && $_ ne '..' } readdir($dh) ) {
            my $hook_path = File::Spec->catfile( $hooks_dir, $entry );
            next unless is_runnable_file($hook_path);

            my %env = $self->_skill_env(
                skill_name   => $skill_name,
                skill_path   => $layer_path,
                skill_layers => \@skill_layers,
                command      => $command,
                result_state => \%results,
            );
            my @hook_command = command_argv_for_path($hook_path);
            my $run = $self->_run_child_command_streaming(
                command      => \@hook_command,
                args         => \@args,
                env          => \%env,
                skill_layers => \@skill_layers,
                result_state => \%results,
                last_result  => $last_result,
                stdin_mode   => 'null',
            );
            my $result_key = $entry;
            if ( exists $results{$entry} ) {
                my $leaf = basename( dirname($hook_path) );
                $result_key = $leaf . '/' . basename($hook_path);
            }
            $results{$result_key} = {
                stdout    => $run->{stdout},
                stderr    => $run->{stderr},
                exit_code => $run->{exit_code},
            };
            $last_result = {
                file   => $hook_path,
                exit   => $run->{exit_code},
                STDOUT => $run->{stdout},
                STDERR => $run->{stderr},
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

# _run_child_command_streaming(%args)
# Launches one child command with inherited stdin, streams stdout and stderr
# live, and still captures both streams for RESULT-aware callers.
# Input: hash containing command array ref, args array ref, env hash ref,
# skill_layers array ref, result_state hash ref, optional last_result hash
# ref, and optional stdin_mode string.
# Output: hash reference containing stdout, stderr, and exit_code.
sub _run_child_command_streaming {
    my ( $self, %args ) = @_;
    my @command = @{ $self->_arrayref_or_empty( $args{command} ) };
    my @argv = @{ $self->_arrayref_or_empty( $args{args} ) };
    my %env = %{ $self->_hashref_or_empty( $args{env} ) };
    my @skill_layers = @{ $self->_arrayref_or_empty( $args{skill_layers} ) };
    my $result_state = $self->_hashref_or_empty( $args{result_state} );
    my $last_result = $args{last_result};
    my $stdin_mode = $self->_defined_or_default( $args{stdin_mode}, 'inherit' );
    my $stdin_spec = '<&STDIN';
    my $stdin_fh;
    if ( $stdin_mode eq 'null' ) {
        open $stdin_fh, '<', File::Spec->devnull() or die "Unable to open " . File::Spec->devnull() . " for streaming skill hook stdin: $!";
        $stdin_spec = '<&' . fileno($stdin_fh);
    }
    my $stderr = gensym();
    my $stdout;
    my ( $stdout_text, $stderr_text ) = ( '', '' );
    my $pid;
    {
        local %ENV = ( %ENV, %env );
        Developer::Dashboard::Runtime::Result::set_current($result_state);
        if ( ref($last_result) eq 'HASH' && %{$last_result} ) {
            Developer::Dashboard::Runtime::Result::set_last_result($last_result);
        }
        else {
            Developer::Dashboard::Runtime::Result::clear_last_result();
        }
        Developer::Dashboard::EnvLoader->load_runtime_layers( paths => $self->{manager}{paths} );
        Developer::Dashboard::EnvLoader->load_skill_layers( skill_layers => \@skill_layers );
        $pid = open3( $stdin_spec, $stdout, $stderr, @command, @argv );
    }
    close $stdin_fh if $stdin_fh;

    my $selector  = IO::Select->new( $stdout, $stderr );
    my $stdout_fd = fileno($stdout);
    my $stderr_fd = fileno($stderr);
    local $| = 1;
    STDOUT->autoflush(1);
    STDERR->autoflush(1);

    while ( my @ready = $selector->can_read ) {
        for my $fh (@ready) {
            my $buffer = '';
            my $read = sysread( $fh, $buffer, 8192 );
            if ( !defined $read || $read == 0 ) {
                $selector->remove($fh);
                close $fh;
                next;
            }

            if ( fileno($fh) == $stdout_fd ) {
                print STDOUT $buffer;
                $stdout_text .= $buffer;
                next;
            }

            if ( fileno($fh) == $stderr_fd ) {
                print STDERR $buffer;
                $stderr_text .= $buffer;
                next;
            }
        }
    }

    waitpid( $pid, 0 );
    return {
        stdout    => $stdout_text,
        stderr    => $stderr_text,
        exit_code => $? >> 8,
    };
}

# _exec_resolved_command($cmd_path, $command, $args)
# Replaces the current helper process with the resolved skill command after
# hooks and environment setup have completed.
# Input: resolved command path string, array reference of base command argv, and
# array reference of user argument strings.
# Output: never returns on success; otherwise returns an error hash.
sub _exec_resolved_command {
    my ( $self, $cmd_path, $command, $args ) = @_;
    my @command = @{ $self->_arrayref_or_empty($command) };
    my @args = @{ $self->_arrayref_or_empty($args) };
    my $error = $self->_exec_replacement( \@command, \@args );
    if ( defined $error && $error ne '' ) {
        return { error => "Unable to exec $cmd_path: $error" };
    }
}

# _exec_replacement($command, $args)
# Performs the final exec handoff for one resolved skill command.
# Input: array reference of base command argv and array reference of user
# argument strings.
# Output: never returns on success; otherwise returns the system error string.
sub _exec_replacement {
    my ( $self, $command, $args ) = @_;
    my @command = @{ $self->_arrayref_or_empty($command) };
    my @args = @{ $self->_arrayref_or_empty($args) };
    if ( !exec @command, @args ) {
        my $error = "$!";
        return $error;
    }
}

# _arrayref_or_empty($value)
# Normalizes optional array references so downstream callers can dereference them
# safely without using short-circuit fallbacks that obscure coverage.
# Input: candidate array reference or undef.
# Output: original array reference when valid, otherwise an empty array reference.
sub _arrayref_or_empty {
    my ( $self, $value ) = @_;
    return $value if ref($value) eq 'ARRAY';
    my @empty;
    my $empty = \@empty;
    return $empty;
}

# _hashref_or_empty($value)
# Normalizes optional hash references for callers that need a stable hash ref.
# Input: candidate hash reference or undef.
# Output: original hash reference when valid, otherwise an empty hash reference.
sub _hashref_or_empty {
    my ( $self, $value ) = @_;
    return $value if ref($value) eq 'HASH';
    my %empty;
    my $empty = \%empty;
    return $empty;
}

# _merge_array_items_by_identity($left_items, $right_items, $field)
# Merges two layered array payloads by replacing hash items that share one
# logical identity field while preserving unmatched entries in order.
# Input: two array references plus the hash key name that identifies one item.
# Output: merged array reference.
sub _merge_array_items_by_identity {
    my ( $self, $left_items, $right_items, $field ) = @_;
    my @combined;
    my %positions;
    my $left = $self->_arrayref_or_empty($left_items);
    my $right = $self->_arrayref_or_empty($right_items);

    for my $item ( @{$left} ) {
        push @combined, $item;
        next if ref($item) ne 'HASH';
        my $identity = $item->{$field};
        next if !defined $identity || $identity eq '';
        $positions{$identity} = $#combined;
    }

    for my $item ( @{$right} ) {
        if ( ref($item) eq 'HASH' ) {
            my $identity = $item->{$field};
            if ( defined $identity && $identity ne '' ) {
                if ( exists $positions{$identity} ) {
                    $combined[ $positions{$identity} ] = $item;
                    next;
                }
                $positions{$identity} = scalar @combined;
            }
        }
        push @combined, $item;
    }

    return \@combined;
}

# _defined_or_default($value, $default)
# Supplies a default scalar only when the candidate value is undef.
# Input: candidate scalar and fallback scalar.
# Output: original scalar when defined, otherwise the fallback scalar.
sub _defined_or_default {
    my ( $self, $value, $default ) = @_;
    return defined $value ? $value : $default;
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
    for my $skill_name ( $self->_all_installed_skill_names ) {
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
    my $local_root = File::Spec->catdir( $skill_path, 'perl5' );
    my $shared_root = File::Spec->catdir( $self->{manager}{paths}->home, 'perl5' );
    my $path_sep   = $^O eq 'MSWin32' ? ';' : ':';
    my @perl5lib   = grep { defined && $_ ne '' } split /\Q$path_sep\E/, ( $ENV{PERL5LIB} || '' );
    for my $shared_lib (
        File::Spec->catdir( $shared_root, 'lib', 'perl5' ),
        File::Spec->catdir( $shared_root, 'lib', 'perl5', $Config::Config{archname} || '' ),
    ) {
        unshift @perl5lib, $shared_lib if defined $shared_lib && $shared_lib ne '' && -d $shared_lib;
    }
    for my $layer_path ( reverse @{ $args{skill_layers} || [] } ) {
        for my $local_lib (
            File::Spec->catdir( $layer_path, 'perl5', 'lib', 'perl5' ),
            File::Spec->catdir( $layer_path, 'perl5', 'lib', 'perl5', $Config::Config{archname} || '' ),
        ) {
            unshift @perl5lib, $local_lib if defined $local_lib && $local_lib ne '' && -d $local_lib;
        }
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
    my @segments = grep { defined && $_ ne '' } split m{/+}, $skill_name;
    return () if !@segments;
    my $root_skill = shift @segments;
    my $paths = $self->{manager}{paths};
    my @layers = $paths->can('skill_layers')
      ? $paths->skill_layers( $root_skill, %args )
      : do {
            my $skill_path = $self->{manager}->get_skill_path( $root_skill, %args ) or return ();
            ($skill_path);
        };
    return @layers if !@segments;

    for my $nested_skill (@segments) {
        my @next_layers;
        for my $skill_path (@layers) {
            my $nested_path = $self->_nested_skill_path( $skill_path, [$nested_skill] );
            next if !-d $nested_path;
            my $disabled = -f File::Spec->catfile( $nested_path, '.disabled' ) ? 1 : 0;
            next if !$args{include_disabled} && $disabled;
            push @next_layers, $nested_path;
        }
        return () if !@next_layers;
        @layers = @next_layers;
    }

    return @layers;
}

# _skill_lookup_roots($skill_name)
# Returns the participating installed roots for one skill in effective lookup order.
# Input: skill repository name string and optional include_disabled flag.
# Output: ordered list of skill root directory path strings from leaf to home.
sub _skill_lookup_roots {
    my ( $self, $skill_name, %args ) = @_;
    return reverse $self->_skill_layers( $skill_name, %args );
}

# resolve_route_segments($segments)
# Resolves the longest installed skill-prefix from one slash-delimited route tail.
# Input: array reference of path segments and optional include_disabled flag.
# Output: hash reference containing skill_name, route_segments, and skill_layers, or undef.
sub resolve_route_segments {
    my ( $self, $segments, %args ) = @_;
    my @segments = grep { defined && $_ ne '' } @{ $segments || [] };
    return if !@segments;
    my $best;
    for my $prefix_length ( 1 .. scalar @segments ) {
        my $candidate_skill = join '/', @segments[ 0 .. $prefix_length - 1 ];
        my @skill_layers = $self->_skill_layers( $candidate_skill, %args );
        next if !@skill_layers;
        $best = {
            skill_name    => $candidate_skill,
            route_segments => [ @segments[ $prefix_length .. $#segments ] ],
            skill_layers  => \@skill_layers,
        };
    }
    return $best;
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

# skill_route_spec($kind, $skill_name, $target)
# Resolves one custom config/routes.json route definition for a skill route kind.
# Input: route kind string, skill repository name string, and relative route target path.
# Output: normalized route spec hash reference or undef when no custom route exists.
sub skill_route_spec {
    my ( $self, $kind, $skill_name, $target ) = @_;
    return if !$kind || !$skill_name || !$target;
    my $routes = $self->_skill_routes_for( $skill_name, $kind );
    return $routes->{$target};
}

# skill_ajax_route_spec($skill_name, $ajax_file)
# Resolves one custom config/routes.json ajax route definition for a skill.
# Input: skill repository name string and relative ajax file path.
# Output: normalized route spec hash reference or undef when no custom route exists.
sub skill_ajax_route_spec {
    my ( $self, $skill_name, $ajax_file ) = @_;
    return $self->skill_route_spec( 'ajax', $skill_name, $ajax_file );
}

# resolve_custom_route_path($path)
# Resolves one canonical or alias custom route path across installed skills and route kinds.
# Input: absolute request path string.
# Output: normalized route spec hash reference or undef when no custom route matches.
sub resolve_custom_route_path {
    my ( $self, $path ) = @_;
    return if !defined $path || $path eq '';
    for my $spec ( reverse $self->_runtime_custom_route_specs ) {
        return $spec if ( $spec->{path} || '' ) eq $path;
        my $aliases = $spec->{aliases};
        $aliases = [] if ref($aliases) ne 'ARRAY';
        return $spec if grep { $_ eq $path } @{$aliases};
    }
    for my $skill_name ( $self->_all_installed_skill_names ) {
        for my $kind (qw(app ajax js css others)) {
            my $routes = $self->_skill_routes_for( $skill_name, $kind );
            for my $target ( sort keys %{$routes} ) {
                my $spec = $routes->{$target};
                return $spec if ( $spec->{path} || '' ) eq $path;
                my $aliases = $spec->{aliases};
                $aliases = [] if ref($aliases) ne 'ARRAY';
                return $spec if grep { $_ eq $path } @{$aliases};
            }
        }
    }
    return;
}

# _runtime_custom_route_specs()
# Loads runtime-level config/routes.json custom route metadata across every
# participating DD-OOP-LAYER config root.
# Input: none.
# Output: ordered list of normalized route specs from home to deepest layer.
sub _runtime_custom_route_specs {
    my ($self) = @_;
    my $paths = $self->{manager}{paths};
    return () if !$paths || !$paths->can('config_layers');

    my @specs;
    for my $config_root ( $paths->config_layers ) {
        my $routes_file = File::Spec->catfile( $config_root, 'routes.json' );
        next if !-f $routes_file;
        my $payload = $self->_load_skill_routes_file($routes_file);
        for my $kind (qw(app ajax js css others)) {
            my $kind_routes = $payload->{$kind} || {};
            for my $target ( sort keys %{$kind_routes} ) {
                push @specs, $self->_normalize_skill_route_spec(
                    kind        => $kind,
                    routes_file => $routes_file,
                    spec        => $kind_routes->{$target},
                    target      => $target,
                );
            }
        }
    }

    return @specs;
}

# resolve_ajax_route_path($path)
# Resolves one canonical or alias custom ajax route path across installed skills.
# Input: absolute request path string.
# Output: normalized route spec hash reference or undef when no custom ajax route matches.
sub resolve_ajax_route_path {
    my ( $self, $path ) = @_;
    my $spec = $self->resolve_custom_route_path($path);
    return if !$spec || ( $spec->{kind} || '' ) ne 'ajax';
    return $spec;
}

# _skill_routes_for($skill_name, $kind)
# Loads and merges config/routes.json metadata for one layered skill and route kind.
# Input: skill repository name string and route kind string.
# Output: hash reference keyed by relative route target with normalized route specs.
sub _skill_routes_for {
    my ( $self, $skill_name, $kind ) = @_;
    return {} if !$skill_name || !$kind;
    my %routes;
    my %claimed_paths;

    for my $skill_path ( $self->_skill_lookup_roots($skill_name) ) {
        my $routes_file = File::Spec->catfile( $skill_path, 'config', 'routes.json' );
        next if !-f $routes_file;
        my $payload = $self->_load_skill_routes_file($routes_file);
        my $kind_routes = $payload->{$kind} || {};
        for my $target ( sort keys %{$kind_routes} ) {
            next if exists $routes{$target};
            my $spec = $self->_normalize_skill_route_spec(
                kind       => $kind,
                skill_name => $skill_name,
                target     => $target,
                routes_file => $routes_file,
                spec       => $kind_routes->{$target},
            );
            for my $route_path ( $spec->{path}, @{ $spec->{aliases} || [] } ) {
                next if !defined $route_path || $route_path eq '';
                die "Duplicate $kind route path '$route_path' in skill '$skill_name'"
                  if $claimed_paths{$route_path}++;
            }
            $routes{$target} = $spec;
        }
    }

    return \%routes;
}

# _skill_ajax_routes_for($skill_name)
# Backward-compatible wrapper for the ajax-specific custom route map loader.
# Input: skill repository name string.
# Output: hash reference keyed by ajax file path.
sub _skill_ajax_routes_for {
    my ( $self, $skill_name ) = @_;
    return $self->_skill_routes_for( $skill_name, 'ajax' );
}

# _load_skill_routes_file($routes_file)
# Parses one config/routes.json file and validates the top-level schema.
# Input: absolute routes.json file path.
# Output: decoded hash reference.
sub _load_skill_routes_file {
    my ( $self, $routes_file ) = @_;
    open my $fh, '<', $routes_file or die "Unable to read $routes_file: $!";
    local $/;
    my $json_text = <$fh>;
    close $fh;
    my $payload = eval { decode_json($json_text) };
    die "Invalid JSON in $routes_file: $@" if $@;
    die "$routes_file must contain a JSON object" if ref($payload) ne 'HASH';
    my @non_version_keys = grep { $_ ne 'version' } keys %{$payload};
    my $has_flat_keys = grep { m{\A/} } @non_version_keys;
    my $has_typed_keys = grep { /^(?:app|ajax|js|css|others)$/ } @non_version_keys;
    die "$routes_file must not mix flat custom-path routes with typed route sections"
      if $has_flat_keys && $has_typed_keys;
    if ($has_flat_keys) {
        my @invalid = grep { $_ !~ m{\A/} } @non_version_keys;
        die "$routes_file flat routes must use absolute custom-path keys"
          if @invalid;
        return $self->_expand_flat_skill_routes_payload( $routes_file, $payload );
    }
    my @unknown = grep { $_ !~ /^(?:app|ajax|js|css|others)$/ } @non_version_keys;
    die "$routes_file contains unsupported top-level keys: @unknown"
      if @unknown;
    die "$routes_file version must be 1" if exists $payload->{version} && ( $payload->{version} || 0 ) != 1;
    for my $kind (qw(app ajax js css others)) {
        if ( exists $payload->{$kind} ) {
            die "$routes_file $kind must be a JSON object" if ref( $payload->{$kind} ) ne 'HASH';
        }
        else {
            $payload->{$kind} = {};
        }
    }
    return $payload;
}

# _expand_flat_skill_routes_payload($routes_file, $payload)
# Converts the flat custom-path config/routes.json schema into the internal typed route map.
# Input: absolute routes.json file path and decoded payload hash reference.
# Output: normalized payload hash reference with app/ajax/js/css/others maps.
sub _expand_flat_skill_routes_payload {
    my ( $self, $routes_file, $payload ) = @_;
    my %expanded = map { $_ => {} } qw(app ajax js css others);
    my %claimed_targets;
    for my $route_path ( sort grep { $_ ne 'version' } keys %{$payload} ) {
        die "$routes_file route path '$route_path' must start with /"
          if $route_path !~ m{\A/};
        my $route = $payload->{$route_path};
        my ( $to, $type );
        if ( !ref($route) ) {
            $to = $route;
        }
        elsif ( ref($route) eq 'HASH' ) {
            my @unknown = grep { $_ ne 'to' && $_ ne 'type' } keys %{$route};
            die "$routes_file route path '$route_path' contains unsupported keys: @unknown"
              if @unknown;
            $to   = $route->{to};
            $type = $route->{type};
        }
        else {
            die "$routes_file route path '$route_path' must map to a string or JSON object";
        }
        die "$routes_file route path '$route_path' must map to a non-empty route target"
          if !defined $to || ref($to) || $to eq '';
        my ( $kind, $target ) = $to =~ m{\A/(ajax|app|js|css|others)/(.*)\z};
        die "$routes_file route path '$route_path' must map to /ajax/, /app/, /js/, /css/, or /others/"
          if !$kind;
        die "$routes_file route path '$route_path' target must not be empty"
          if !defined $target || $target eq '';
        die "$routes_file route path '$route_path' type must be a scalar"
          if defined $type && ref($type);
        die "$routes_file route path '$route_path' type must not be empty"
          if defined $type && $type eq '';
        die "$routes_file route path '$route_path' does not allow type for /app targets"
          if defined $type && $kind eq 'app';
        die "$routes_file route path '$route_path' does not allow type for /js targets"
          if defined $type && $kind eq 'js';
        die "$routes_file route path '$route_path' does not allow type for /css targets"
          if defined $type && $kind eq 'css';
        die "Duplicate $kind route target '/$kind/$target' in $routes_file"
          if $claimed_targets{"$kind:$target"}++;
        $type = 'json' if !defined $type && $kind eq 'ajax';
        $expanded{$kind}{$target} = {
            path => $route_path,
            ( defined $type ? ( type => $type ) : () ),
        };
    }
    return \%expanded;
}

# _normalize_skill_route_spec(%args)
# Validates and normalizes one config/routes.json route entry.
# Input: kind, skill_name, target, routes_file, and raw spec hash reference.
# Output: normalized route spec hash reference.
sub _normalize_skill_route_spec {
    my ( $self, %args ) = @_;
    my $kind = $args{kind} || die 'Missing kind';
    my $skill_name = $args{skill_name};
    my $target = $args{target} || die 'Missing target';
    my $routes_file = $args{routes_file} || die 'Missing routes_file';
    my $spec = $args{spec};
    die "$routes_file $kind entry '$target' must be a JSON object" if ref($spec) ne 'HASH';
    die "$routes_file $kind entry '$target' path is required"
      if !defined $spec->{path} || $spec->{path} eq '';
    die "$routes_file $kind entry '$target' path must start with /"
      if $spec->{path} !~ m{\A/};
    my $aliases = $spec->{aliases};
    $aliases = [] if !defined $aliases;
    die "$routes_file $kind entry '$target' aliases must be an array"
      if ref($aliases) ne 'ARRAY';
    my @aliases = grep { defined $_ && $_ ne '' } @{$aliases};
    for my $alias (@aliases) {
        die "$routes_file $kind entry '$target' aliases must start with /"
          if $alias !~ m{\A/};
    }
    if ( exists $spec->{type} ) {
        die "$routes_file $kind entry '$target' type must be a scalar"
          if ref( $spec->{type} );
        die "$routes_file $kind entry '$target' type must not be empty"
          if !defined $spec->{type} || $spec->{type} eq '';
        die "$routes_file app entry '$target' must not declare type"
          if $kind eq 'app';
    }
    my $normalized = {
        aliases     => \@aliases,
        kind        => $kind,
        path        => $spec->{path},
        source_file => $routes_file,
        target      => $target,
        type        => $spec->{type},
    };
    $normalized->{skill_name} = $skill_name if defined $skill_name && $skill_name ne '';
    $normalized->{ajax_file} = $target if $kind eq 'ajax';
    $normalized->{route_id}  = $target if $kind eq 'app';
    $normalized->{file}      = $target if $kind ne 'ajax' && $kind ne 'app';
    return $normalized;
}

# skill_ajax_file_path($skill_name, $ajax_file)
# Resolves one layered skill-local dashboards/ajax file in deepest-first order.
# Input: skill repository name string and relative ajax file path.
# Output: absolute file path string or undef when missing.
sub skill_ajax_file_path {
    my ( $self, $skill_name, $ajax_file ) = @_;
    return if !$skill_name || !$ajax_file;
    for my $skill_path ( $self->_skill_lookup_roots($skill_name) ) {
        my $file = File::Spec->catfile( $skill_path, 'dashboards', 'ajax', split m{/+}, $ajax_file );
        return $file if -f $file;
    }
    return;
}

# skill_static_file_path($skill_name, $type, $file)
# Resolves one layered skill-local dashboards/public asset in deepest-first order.
# Input: skill repository name string, static asset type, and relative file path.
# Output: absolute file path string or undef when missing.
sub skill_static_file_path {
    my ( $self, $skill_name, $type, $file ) = @_;
    return if !$skill_name || !$type || !$file;
    for my $skill_path ( $self->_skill_lookup_roots($skill_name) ) {
        my $candidate = File::Spec->catfile( $skill_path, 'dashboards', 'public', $type, split m{/+}, $file );
        return $candidate if -f $candidate;
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
                && $_ ne 'routes.json'
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
        for my $entry ( $self->_relative_files($nav_root) ) {
            $routes{$entry} ||= 'nav/' . $entry;
        }
    }
    return %routes;
}

# _all_installed_skill_names()
# Enumerates every enabled installed skill name, including nested skills/<repo>
# trees, in deterministic order for shared nav rendering and similar global
# skill discovery paths.
# Input: none.
# Output: ordered list of slash-delimited installed skill names.
sub _all_installed_skill_names {
    my ($self) = @_;
    my @names;
    for my $skill_root ( $self->{manager}{paths}->installed_skill_roots ) {
        my ($skill_name) = $skill_root =~ m{/([^/]+)\z};
        next if !defined $skill_name || $skill_name eq '';
        push @names, $self->_descendant_skill_names( $skill_name, $skill_root );
    }
    return @names;
}

# _descendant_skill_names($skill_name, $skill_root)
# Recursively enumerates one installed skill and any nested skills/<repo>
# descendants while skipping disabled nested skills from normal runtime lookup.
# Input: installed skill name string and absolute skill root path.
# Output: ordered list of slash-delimited skill names.
sub _descendant_skill_names {
    my ( $self, $skill_name, $skill_root ) = @_;
    return () if !$skill_name || !$skill_root || !-d $skill_root;

    my @names = ($skill_name);
    my $nested_root = File::Spec->catdir( $skill_root, 'skills' );
    return @names if !-d $nested_root;

    opendir my $dh, $nested_root or die "Unable to read $nested_root: $!";
    for my $entry (
        sort grep {
               $_ ne '.'
            && $_ ne '..'
            && -d File::Spec->catdir( $nested_root, $_ )
        } readdir $dh
      )
    {
        my $child_root = File::Spec->catdir( $nested_root, $entry );
        next if -f File::Spec->catfile( $child_root, '.disabled' );
        push @names, $self->_descendant_skill_names( $skill_name . '/' . $entry, $child_root );
    }
    closedir $dh;

    return @names;
}

# _relative_files($root)
# Recursively lists files beneath one root as forward-slash relative paths so
# nested nav fragments can be routed without flattening subdirectories.
# Input: absolute root directory path.
# Output: sorted list of relative file path strings.
sub _relative_files {
    my ( $self, $root ) = @_;
    return () if !$root || !-d $root;

    my @relative_files;
    opendir my $dh, $root or die "Unable to read $root: $!";
    for my $entry ( sort grep { $_ ne '.' && $_ ne '..' } readdir $dh ) {
        my $path = File::Spec->catfile( $root, $entry );
        if ( -d $path ) {
            push @relative_files, map { $entry . '/' . $_ } $self->_relative_files($path);
            next;
        }
        push @relative_files, $entry if -f $path;
    }
    closedir $dh;

    return @relative_files;
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
                $merged{$key} = $self->_merge_array_items_by_identity( $left->{$key}, $right->{$key}, 'name' );
                next;
            }
            if ( $key eq 'providers' ) {
                $merged{$key} = $self->_merge_array_items_by_identity( $left->{$key}, $right->{$key}, 'id' );
                next;
            }
        }
        $merged{$key} = $right->{$key};
    }

    return \%merged;
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
