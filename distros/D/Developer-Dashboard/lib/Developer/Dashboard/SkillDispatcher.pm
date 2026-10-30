package Developer::Dashboard::SkillDispatcher;

use strict;
use warnings;

our $VERSION = '6.06';

use Config ();
use Developer::Dashboard::DirEntries qw(sorted_dir_entries);
use IPC::Open3 qw(open3);
use File::Spec;
use IO::Select;
use JSON::XS qw(encode_json decode_json);
use Capture::Tiny qw(capture);
use File::Basename qw(dirname basename);
use Scalar::Util qw(refaddr);
use Time::HiRes ();
use Symbol qw(gensym);
use bytes ();
use URI;
use URI::Escape qw(uri_escape uri_unescape);
use Developer::Dashboard::CLI::Suggest;
use Developer::Dashboard::StreamDrain qw(_drain_ready_handle);
use Developer::Dashboard::EnvLoader;
use Developer::Dashboard::PathRegistry ();
use Developer::Dashboard::PerlEnv ();
use Developer::Dashboard::Runtime::Result;
use Developer::Dashboard::SkillManager;
use Developer::Dashboard::Platform qw(command_argv_for_path is_runnable_file resolve_runnable_file);
our $MODULE_SOURCE_PATH = File::Spec->rel2abs(__FILE__);

# new()
# Creates a SkillDispatcher instance to execute skill commands.
# Input: none.
# Output: SkillDispatcher object.
sub new {
    my ( $class, %args ) = @_;
    my $manager = $args{manager};
    $manager = Developer::Dashboard::SkillManager->new( paths => $args{paths} ) if !$manager;
    return bless {
        manager => $manager,
    }, $class;
}

# DESTROY()
# Releases the aggregate skill-nav filesystem watcher before the dispatcher is
# discarded, reporting native cleanup failures instead of leaking descriptors.
# Input: dispatcher object being destroyed by Perl.
# Output: none; emits an explicit warning if watcher shutdown fails.
sub DESTROY {
    my ($self) = @_;
    my $watcher = delete $self->{_skill_nav_pages_watcher};
    return if !ref($watcher);
    my $closed = eval { $watcher->close };
    if ( !$closed ) {
        my $error = $@;
        # eval leaves $@ as a string (empty on successful close), so the
        # undefined case is not reachable here and needlessly duplicates the
        # following last_error normalization.
        $error = $watcher->can('last_error') ? $watcher->last_error : undef
          if $error eq '';
        $error = 'unknown watcher shutdown failure' if !defined $error || $error eq '';
        warn "Skill nav snapshot watcher shutdown failed: $error\n";
    }
    return;
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
    if ( !$cmd_path ) {
        return $self->_native_version_fallback($skill_name) if $command eq 'version';
        return { error => $suggest->unknown_skill_command_message( $skill_name, $command ) };
    }

    my $hook_result = $self->execute_hooks( $skill_name, $command, @args );
    return $hook_result if $hook_result->{error};
    my @skill_layers = @{ $command_spec->{skill_layers} };
    my @env_skill_layers = @{ $command_spec->{env_skill_layers} || \@skill_layers };

    my %env = $self->_skill_env(
        skill_name   => $skill_name,
        skill_path   => $command_skill_path,
        skill_layers => \@env_skill_layers,
        command      => $command_spec->{command_name},
        result_state => $hook_result->{result_state},
    );
    my @command = command_argv_for_path($cmd_path);
    _prepend_skill_lib_to_perl_argv( \@command, $command_skill_path );

    my ( $stdout, $stderr, $exit ) = capture {
        local %ENV = ( %ENV, %env );
        Developer::Dashboard::Runtime::Result::set_current( $hook_result->{result_state} );
        if ( ref( $hook_result->{last_result} ) eq 'HASH' ) {
            Developer::Dashboard::Runtime::Result::set_last_result( $hook_result->{last_result} );
        }
        else {
            Developer::Dashboard::Runtime::Result::clear_last_result();
        }
        Developer::Dashboard::EnvLoader->load_skill_runtime_layers(
            paths        => $self->{manager}{paths},
            skill_layers => \@env_skill_layers,
        );
        system( @command, @args );
    };
    my $hook_stdout = join '', map { $_->{stdout} } values %{ $hook_result->{hooks} };
    my $hook_stderr = join '', map { $_->{stderr} } values %{ $hook_result->{hooks} };
    return {
        stdout    => $hook_stdout . $stdout,
        stderr    => $hook_stderr . $stderr,
        exit_code => $exit >> 8,
        hooks     => $hook_result->{hooks},
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
    if ( !$cmd_path ) {
        if ( $command eq 'version' ) {
            my $fallback = $self->_native_version_fallback($skill_name);
            return $self->_exec_resolved_command( '<native version fallback>', [ $^X, '-e', 'print $ARGV[0]' ], [ $fallback->{stdout} ] );
        }
        return { error => $suggest->unknown_skill_command_message( $skill_name, $command ) };
    }

    my @skill_layers = @{ $command_spec->{skill_layers} };
    my @env_skill_layers = @{ $command_spec->{env_skill_layers} || \@skill_layers };
    my $hook_result = $self->_execute_hooks_streaming( $skill_name, $command_spec->{command_name}, \@skill_layers, { env_skill_layers => \@env_skill_layers }, @args );
    return $hook_result if $hook_result->{error};

    my %env = $self->_skill_env(
        skill_name   => $skill_name,
        skill_path   => $command_skill_path,
        skill_layers => \@env_skill_layers,
        command      => $command_spec->{command_name},
        result_state => $hook_result->{result_state},
    );
    my @command = command_argv_for_path($cmd_path);
    _prepend_skill_lib_to_perl_argv( \@command, $command_skill_path );
    %ENV = ( %ENV, %env );
    Developer::Dashboard::Runtime::Result::set_current( $hook_result->{result_state} );
    if ( ref( $hook_result->{last_result} ) eq 'HASH' ) {
        Developer::Dashboard::Runtime::Result::set_last_result( $hook_result->{last_result} );
    }
    else {
        Developer::Dashboard::Runtime::Result::clear_last_result();
    }
    Developer::Dashboard::EnvLoader->load_skill_runtime_layers(
        paths        => $self->{manager}{paths},
        skill_layers => \@env_skill_layers,
    );
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
    my @skill_layers = $command_spec ? @{ $command_spec->{skill_layers} } : $self->_skill_layers($skill_name);
    my @env_skill_layers = $command_spec ? @{ $command_spec->{env_skill_layers} || \@skill_layers } : @skill_layers;
    return { hooks => {}, result_state => {} } if !@skill_layers;
    my $resolved_command = $command_spec ? $command_spec->{command_name} : $command;

    my %results;
    my $last_result = {};
    for my $layer_path (@skill_layers) {
        my $hooks_dir = File::Spec->catdir( $layer_path, 'cli', "$resolved_command.d" );
        next if !-d $hooks_dir;
        opendir( my $dh, $hooks_dir ) or die "Unable to read $hooks_dir: $!";
        for my $entry ( sorted_dir_entries($dh) ) {
            my $hook_path = File::Spec->catfile( $hooks_dir, $entry );
            next unless is_runnable_file($hook_path);

            my %env = $self->_skill_env(
                skill_name   => $skill_name,
                skill_path   => $layer_path,
                skill_layers => \@env_skill_layers,
                command      => $resolved_command,
                result_state => \%results,
            );
            my @command = command_argv_for_path($hook_path);
            _prepend_skill_lib_to_perl_argv( \@command, $layer_path );
            my ( $stdout, $stderr, $exit ) = capture {
                local %ENV = ( %ENV, %env );
                Developer::Dashboard::Runtime::Result::set_current( \%results );
                if (%{$last_result}) {
                    Developer::Dashboard::Runtime::Result::set_last_result($last_result);
                }
                else {
                    Developer::Dashboard::Runtime::Result::clear_last_result();
                }
                Developer::Dashboard::EnvLoader->load_skill_runtime_layers(
                    paths        => $self->{manager}{paths},
                    skill_layers => \@env_skill_layers,
                );
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
                exit_code => $exit >> 8,
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
    my $options = @args && ref( $args[0] ) eq 'HASH' && exists $args[0]{env_skill_layers} ? shift @args : {};
    my @env_layers = @{ $self->_arrayref_or_empty( $options->{env_skill_layers} ) };
    @env_layers = @skill_layers if !@env_layers;
    my %results;
    my $last_result = {};
    for my $layer_path (@skill_layers) {
        my $hooks_dir = File::Spec->catdir( $layer_path, 'cli', "$command.d" );
        next if !-d $hooks_dir;
        opendir( my $dh, $hooks_dir ) or die "Unable to read $hooks_dir: $!";
        for my $entry ( sorted_dir_entries($dh) ) {
            my $hook_path = File::Spec->catfile( $hooks_dir, $entry );
            next unless is_runnable_file($hook_path);

            my %env = $self->_skill_env(
                skill_name   => $skill_name,
                skill_path   => $layer_path,
                skill_layers => \@env_layers,
                command      => $command,
                result_state => \%results,
            );
            my @hook_command = command_argv_for_path($hook_path);
            _prepend_skill_lib_to_perl_argv( \@hook_command, $layer_path );
            my $run = $self->_run_child_command_streaming(
                command      => \@hook_command,
                args         => \@args,
                env          => \%env,
                skill_layers => \@env_layers,
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

    # DD-597: waitpid below reads $? into this sub's own return value, but
    # without this guard the raw $? from that reap stays set in the caller's
    # process after this sub returns.
    local $?;
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
        Developer::Dashboard::EnvLoader->load_skill_runtime_layers(
            paths        => $self->{manager}{paths},
            skill_layers => \@skill_layers,
        );
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
            my $chunk_ref = $self->_drain_ready_handle( $selector, $fh ) or next;

            if ( fileno($fh) == $stdout_fd ) {
                print STDOUT ${$chunk_ref};
                $stdout_text .= ${$chunk_ref};
                next;
            }

            # The selector only watches stdout and stderr, so anything that is
            # not stdout is stderr.
            print STDERR ${$chunk_ref};
            $stderr_text .= ${$chunk_ref};
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
    return { error => "Unable to exec $cmd_path: $error" };
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
    return {} if !%{$config};
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
    my $resolved_command = $command_spec->{command_name};

    for my $layer_path ( @{ $command_spec->{skill_layers} } ) {
        my $hooks_dir = File::Spec->catdir( $layer_path, 'cli', "$resolved_command.d" );
        next if !-d $hooks_dir;
        opendir( my $dh, $hooks_dir ) or die "Unable to read $hooks_dir: $!";
        for my $entry ( sorted_dir_entries($dh) ) {
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

    my @parts = grep { $_ ne '' } split m{/+}, $route;
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
    my @skill_layers = $self->_skill_layers($skill_name);
    return [] if !@skill_layers;
    return $self->_skill_nav_pages_for_layers( $skill_name, \@skill_layers );
}

# _skill_nav_pages_for_layers($skill_name, $skill_layers, $cache_literal_nav)
# Loads all nav pages for one skill using its already-resolved layered roots.
# Input: skill repository name, home-to-leaf layer array reference, and optional
# boolean enabling bounded reuse of unchanged static literal nav pages. It also
# obtains stable, inventory-derived route segments for its private page lookups.
# Output: array reference of nav page documents.
sub _skill_nav_pages_for_layers {
    my ( $self, $skill_name, $skill_layers, $cache_literal_nav ) = @_;
    return [] if !$skill_name || ref($skill_layers) ne 'ARRAY' || !@{$skill_layers};
    my %route_segments;
    my %route_ids = $self->_skill_nav_route_ids( $skill_name, $skill_layers, \%route_segments );
    return [] if !%route_ids;

    my @pages;
    for my $entry ( sort keys %route_ids ) {
        push @pages, $self->_load_skill_page(
            skill_name => $skill_name,
            route_id   => $route_ids{$entry},
            validated_route_segments => $route_segments{$entry},
            layers     => $skill_layers,
            cache_literal_nav => $cache_literal_nav ? 1 : 0,
        );
    }
    return \@pages;
}

# all_skill_nav_pages()
# Loads nav bookmark pages from every installed skill in deterministic skill order.
# Unchanged literal raw fragments reuse read-only, high-resolution-stat-checked
# page documents in a bounded per-dispatcher cache; dynamic/structured pages are
# read and parsed for each request. A native watcher can validate an aggregate
# snapshot of literal pages and bypass repeated per-page path resolution.
# Input: none.
# Output: array ref of prepared page documents before runtime state is applied.
sub all_skill_nav_pages {
    my ($self) = @_;
    my $cached_pages = $self->_cached_all_skill_nav_pages;
    return $cached_pages if $cached_pages;
    my @pages;
    my ( @skill_roots, @skill_layers );
    my $paths = $self->{manager}{paths};
    die 'Skill paths are required for nav discovery' if !$paths;
    if ( $paths->can('installed_skill_entries') ) {
        for my $entry ( $paths->installed_skill_entries ) {
            die 'Invalid installed skill entry for nav discovery'
              if ref($entry) ne 'HASH'
              || !$entry->{skill_name}
              || !$entry->{skill_root}
              || ref( $entry->{layers} ) ne 'ARRAY';
            push @skill_roots, $entry->{skill_root};
            push @skill_layers, @{ $entry->{layers} };
            my @skill_names = $self->_descendant_skill_names(
                $entry->{skill_name},
                $entry->{skill_root},
            );
            for my $skill_name (@skill_names) {
                my $layers = $skill_name eq $entry->{skill_name}
                  ? $entry->{layers}
                  : [ $self->_skill_layers($skill_name) ];
                push @skill_layers, @{$layers};
                push @pages, @{ $self->_skill_nav_pages_for_layers( $skill_name, $layers, 1 ) };
            }
        }
        $self->_cache_all_skill_nav_pages( \@pages, \@skill_roots, \@skill_layers );
        return \@pages;
    }

    for my $skill_name ( $self->_all_installed_skill_names ) {
        push @pages, @{ $self->skill_nav_pages($skill_name) };
    }
    return \@pages;
}

# all_skill_nav_literal_items_html($escape_attribute)
# Returns the pre-rendered list items for a watcher-validated aggregate of
# literal skill-nav fragments. Dynamic or non-aggregated pages return undef so
# callers can use the ordinary per-request renderer.
# Input: attribute-escaping coderef.
# Output: cached concatenated <li> HTML, including an empty string for a valid
#         empty snapshot, or undef when pages are unavailable or no safe
#         aggregate snapshot is available.
sub all_skill_nav_literal_items_html {
    my ( $self, $escape_attribute ) = @_;
    die 'Skill-nav attribute escaper must be a code reference'
      if ref($escape_attribute) ne 'CODE';
    my $pages = $self->all_skill_nav_pages;
    my $snapshot = $self->{_skill_nav_pages_snapshot};
    return if ref($snapshot) ne 'HASH'
      || ref( $snapshot->{pages} ) ne 'ARRAY'
      || ref($pages) ne 'ARRAY'
      || refaddr( $snapshot->{pages} ) != refaddr($pages);
    if ( exists $snapshot->{html} ) {
        die 'Malformed rendered skill-nav HTML cache'
          if !defined $snapshot->{html} || ref( $snapshot->{html} );
        return $snapshot->{html};
    }

    my @items;
    my $bytes = 0;
    for my $page ( @{$pages} ) {
        die 'Malformed page in literal skill-nav snapshot'
          if ref($page) ne 'Developer::Dashboard::PageDocument'
          || ref( $page->{meta} ) ne 'HASH'
          || ref( $page->{layout} ) ne 'HASH';
        my $body = $page->{layout}{body};
        my $codes = $page->{meta}{codes};
        return if ($page->{meta}{source_format} || '') ne 'raw-nav-tt'
          || !defined $body || ref($body) || index( $body, '[%' ) >= 0
          || ( defined $codes && ref($codes) ne 'ARRAY' )
          || ( ref($codes) eq 'ARRAY' && @{$codes} );
        my $id = $page->{id};
        die 'Malformed route id in literal skill-nav snapshot' if !defined $id || ref($id);
        my $escaped_id = $escape_attribute->($id);
        die 'Skill-nav attribute escaper returned a non-scalar value'
          if !defined $escaped_id || ref($escaped_id);
        push @items, '<li data-nav-id="' . $escaped_id . '">' . $body . '</li>';
        $bytes += bytes::length( $items[-1] );
    }
    my $html = join '', @items;
    $snapshot->{html} = $html if $bytes <= 10_485_760;
    return $html;
}

# _cached_all_skill_nav_pages()
# Returns the prepared literal-nav page snapshot only when its configured native
# watcher confirms that no watched skill, layer, or nav directory changed.
# Input: none.
# Output: cached array reference on an event-free watch, or undef for a miss.
sub _cached_all_skill_nav_pages {
    my ($self) = @_;
    my $cache = $self->{_skill_nav_pages_snapshot};
    return if ref($cache) ne 'HASH';
    die 'Malformed aggregate skill-nav page cache' if ref( $cache->{pages} ) ne 'ARRAY';
    die 'Malformed aggregate skill-nav page cache signature'
      if !defined $cache->{signature} || ref( $cache->{signature} );
    my $paths_signature = $self->_skill_nav_paths_signature;
    if ( !defined $paths_signature || ref( $cache->{paths_signature} ) ne 'ARRAY'
        || @{ $cache->{paths_signature} } != @{$paths_signature} )
    {
        delete $self->{_skill_nav_pages_snapshot};
        return;
    }
    for my $index ( 0 .. $#{$paths_signature} ) {
        if ( !defined $cache->{paths_signature}[$index]
            || $cache->{paths_signature}[$index] ne $paths_signature->[$index] )
        {
            delete $self->{_skill_nav_pages_snapshot};
            return;
        }
    }
    my $watcher = $self->_skill_nav_pages_watcher;
    if ( !$watcher ) {
        delete $self->{_skill_nav_pages_snapshot};
        return;
    }
    return $cache->{pages} if $watcher->unchanged( $cache->{signature} );
    my $error = $watcher->can('last_error') ? $watcher->last_error : undef;
    if ( defined $error && $error ne '' ) {
        warn "Skill nav snapshot watch disabled: $error\n";
        $watcher->close or warn "Skill nav snapshot watcher close failed: "
          . ( $watcher->last_error || 'unknown close failure' ) . "\n";
        delete $self->{_skill_nav_pages_watcher};
        $self->{_skill_nav_pages_watcher_unavailable} = 1;
    }
    delete $self->{_skill_nav_pages_snapshot};
    return;
}

# _skill_nav_paths_signature()
# Captures the identity of the paths registry and its current ordered runtime
# roots so process-environment or runtime-layer changes cannot reuse an
# aggregate page snapshot configured for another path context.
# Input: none; reads the dispatcher's current paths registry.
# Output: array reference containing registry identity and runtime roots, or undef when the provider cannot
#         expose a runtime-root inventory.
sub _skill_nav_paths_signature {
    my ($self) = @_;
    my $paths = $self->{manager}{paths};
    return if !ref($paths) || !$paths->can('runtime_roots');
    my @runtime_roots = $paths->runtime_roots;
    die 'Invalid runtime root in skill-nav paths signature' if grep { !defined $_ || ref($_) } @runtime_roots;
    return [ refaddr($paths), @runtime_roots ];
}

# _skill_nav_pages_watcher()
# Lazily constructs the existing optional native filesystem watcher for an
# aggregate literal-nav snapshot; absent optional backends retain portable page
# inventory validation rather than disabling route loading. It resolves the
# module relative to this absolute source path so nested skill working-directory
# changes cannot invalidate a relative @INC entry.
# Input: none.
# Output: watcher object or undef when the current platform has no backend.
sub _skill_nav_pages_watcher {
    my ($self) = @_;
    return $self->{_skill_nav_pages_watcher}
      if ref( $self->{_skill_nav_pages_watcher} );
    return if $self->{_skill_nav_pages_watcher_unavailable};
    if ( !$INC{'Developer/Dashboard/IndicatorStore/Watch.pm'} ) {
        my $watcher_module = File::Spec->catfile(
            dirname($MODULE_SOURCE_PATH), 'IndicatorStore', 'Watch.pm'
        );
        require $watcher_module;
    }
    my $watcher = Developer::Dashboard::IndicatorStore::Watch->new;
    if ( !$watcher ) {
        $self->{_skill_nav_pages_watcher_unavailable} = 1;
        return;
    }
    $self->{_skill_nav_pages_watcher} = $watcher;
    return $watcher;
}

# _cache_all_skill_nav_pages($pages, $skill_roots, $skill_layers)
# Configures a native watcher and caches the aggregate array only when every
# page is an unchanged-independent literal nav fragment and the bounded cache
# size is respected. It watches each skill root, its parent, dashboards/nav
# parents, and all recursively inventoried nav directories so both content and
# route namespace changes invalidate the snapshot.
# Input: page array reference, installed skill-root array, and contributing
#        layered-skill-root array.
# Output: true if the aggregate snapshot is installed; false when unsafe,
#         oversized, or unsupported. Watch setup failures are warned visibly.
sub _cache_all_skill_nav_pages {
    my ( $self, $pages, $skill_roots, $skill_layers ) = @_;
    die 'Aggregate skill-nav pages must be an array reference' if ref($pages) ne 'ARRAY';
    die 'Aggregate skill roots must be an array reference' if ref($skill_roots) ne 'ARRAY';
    die 'Aggregate skill layers must be an array reference' if ref($skill_layers) ne 'ARRAY';
    delete $self->{_skill_nav_pages_snapshot};
    return 0 if @{$pages} > 8192;
    my $paths_signature = $self->_skill_nav_paths_signature;
    return 0 if !defined $paths_signature;
    my $bytes = 0;
    for my $page ( @{$pages} ) {
        return 0 if ref($page) ne 'Developer::Dashboard::PageDocument';
        my $meta = $page->{meta};
        my $body = $page->{layout}{body};
        return 0 if ref($meta) ne 'HASH'
          || ($meta->{source_format} || '') ne 'raw-nav-tt'
          || !defined $body || ref($body) || index( $body, '[%' ) >= 0
          || ( defined $meta->{codes} && ref( $meta->{codes} ) ne 'ARRAY' )
          || ( ref( $meta->{codes} ) eq 'ARRAY' && @{ $meta->{codes} } );
        $bytes += length($body);
        return 0 if $bytes > 8 * 1024 * 1024;
    }

    my $paths = $self->{manager}{paths};
    my @runtime_roots = $paths->can('runtime_roots') ? $paths->runtime_roots : ();
    my @skills_roots = $paths->can('skills_roots') ? $paths->skills_roots : ();
    my @directories;
    my $add_existing_ancestor = sub {
        my ($target) = @_;
        return if !defined $target || ref($target) || $target eq '';
        my $directory = $target;
        while ( !-d $directory ) {
            my $parent = dirname($directory);
            return if $parent eq $directory;
            $directory = $parent;
        }
        push @directories, $directory;
    };
    for my $root ( @runtime_roots, @skills_roots ) {
        next if !defined $root || ref($root) || $root eq '';
        $add_existing_ancestor->($root);
        $add_existing_ancestor->( dirname($root) );
    }
    for my $root ( @{$skill_roots} ) {
        next if !defined $root || ref($root) || $root eq '';
        # Skill-level state such as the .disabled marker is written directly
        # inside the installed root. Inotify watches are not recursive, so the
        # parent watch alone cannot observe that marker changing.
        $add_existing_ancestor->($root);
        $add_existing_ancestor->( dirname($root) );
    }
    for my $layer ( @{$skill_layers} ) {
        next if !defined $layer || ref($layer) || $layer eq '';
        $add_existing_ancestor->( File::Spec->catdir( $layer, 'skills' ) );
        $add_existing_ancestor->( File::Spec->catdir( $layer, 'dashboards' ) );
        $add_existing_ancestor->( File::Spec->catdir( $layer, 'dashboards', 'nav' ) );
    }
    my $inventory = $self->{_skill_nav_inventory_cache};
    if ( defined $inventory ) {
        die 'Malformed aggregate skill-nav inventory cache' if ref($inventory) ne 'HASH'
          || ref( $inventory->{entries} ) ne 'HASH';
        for my $entry ( values %{ $inventory->{entries} } ) {
            die 'Malformed aggregate skill-nav inventory directories' if ref($entry) ne 'HASH'
              || ref( $entry->{directories} ) ne 'ARRAY';
            $add_existing_ancestor->( $_->[0] ) for @{ $entry->{directories} };
        }
    }
    my %seen;
    my @watch_paths = sort grep { !$seen{$_}++ } @directories;
    return 0 if !@watch_paths;
    my $signature = join "\0", @watch_paths;
    my $watcher = $self->_skill_nav_pages_watcher;
    return 0 if !$watcher;
    if ( !$watcher->configure( $signature, \@watch_paths ) ) {
        my $error = $watcher->can('last_error') ? $watcher->last_error : undef;
        warn "Skill nav snapshot watch setup failed: "
          . ( defined $error && $error ne '' ? $error : 'unknown watcher error' ) . "\n";
        if ( !$watcher->close ) {
            my $close_error = $watcher->can('last_error') ? $watcher->last_error : undef;
            warn "Skill nav snapshot watcher close failed: "
              . ( defined $close_error && $close_error ne '' ? $close_error : 'unknown close failure' ) . "\n";
        }
        delete $self->{_skill_nav_pages_watcher};
        $self->{_skill_nav_pages_watcher_unavailable} = 1;
        return 0;
    }
    $self->{_skill_nav_pages_snapshot} = {
        signature      => $signature,
        paths_signature => $paths_signature,
        pages          => $pages,
    };
    return 1;
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
    return [ 404, 'text/plain; charset=utf-8', "Skill bookmark '$args{route_id}' not found\n" ] if !$page;
    if ( $args{app} && ($page->{meta}{source_format} || '') eq 'raw-url' ) {
        my $target = _merge_saved_url_query(
            $page->{meta}{raw_url},
            { %{ $args{query_params} || {} }, %{ $args{body_params} || {} } },
        );
        return [ 302, 'text/plain; charset=utf-8', "Redirecting\n", { Location => $target } ];
    }
    return [ 200, 'text/plain; charset=utf-8', $page->{meta}{raw_url} ]
      if ($page->{meta}{source_format} || '') eq 'raw-url';
    if ( !$args{app} ) {
        my $instruction = $page->{meta}{raw_instruction};
        $instruction = $page->canonical_instruction if !$instruction;
        return [ 200, 'text/plain; charset=utf-8', $instruction ];
    }

    my $app = $args{app};
    $page = $app->_decorate_skill_page_routes($page);
    my $page_path = $args{path};
    $page_path = '/app/' . $page->{id} if !$page_path;
    $page = $app->_page_with_runtime_state(
        $page,
        query_params => $args{query_params} || {},
        body_params  => $args{body_params}  || {},
        path         => $page_path,
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

# _merge_saved_url_query($target, $params)
# Merges request parameters into a saved skill bookmark URL, replacing matching
# keys while preserving saved keys that were not supplied by the request.
# Input: absolute or path URL string and flat request parameter hash reference.
# Output: URL string with the merged, encoded query string.
sub _merge_saved_url_query {
    my ( $target, $params ) = @_;
    my $uri = URI->new($target);
    my %merged;
    for my $pair ( split /&/, scalar( $uri->query // '' ) ) {
        next if $pair eq '';
        my ( $key, $value ) = split /=/, $pair, 2;
        $merged{ uri_unescape($key) } = uri_unescape( defined $value ? $value : '' );
    }
    for my $key ( keys %{ $params || {} } ) {
        next if $key eq 'splat';
        my $value = $params->{$key};
        $value = $value->[ -1 ] if ref($value) eq 'ARRAY';
        $merged{$key} = defined $value ? $value : '';
    }
    $uri->query( join '&', map { uri_escape($_) . '=' . uri_escape( $merged{$_} ) } sort keys %merged )
      if %merged;
    return $uri->as_string;
}

# _load_skill_page(%args)
# Loads one layered skill page document from dashboards/<id> and namespaces its
# page id under /app/<skill>/.... Internal nav callers may opt into reuse of
# unchanged literal raw fragments; dynamic page sources always reload.
# Input: skill name, relative route id such as index, foo, or nav/file.tt, and
# optional resolved skill layers, literal-nav-cache flag, and route segments
# derived from the stable internal nav inventory.
# Output: page document object.
sub _load_skill_page {
    my ( $self, %args ) = @_;
    my $skill_name = $args{skill_name} || die 'Missing skill name';
    my $route_id   = $args{route_id}   || die 'Missing route id';
    my $provided_layers = ref( $args{layers} ) eq 'ARRAY';
    my @skill_layers = $provided_layers ? @{ $args{layers} } : $self->_skill_layers($skill_name);
    my ( $file, $skill_path, $file_stat ) = $self->_page_location(
        $skill_name,
        $route_id,
        layers => \@skill_layers,
        ( exists $args{validated_route_segments}
            ? ( validated_route_segments => $args{validated_route_segments} )
            : () ),
    );
    die "Skill bookmark '$route_id' not found" if !defined $file;

    my $is_raw_nav = $route_id =~ m{\Anav/.+\.tt\z};
    my $cache_key;
    my $cache_fingerprint;
    if ( $args{cache_literal_nav} && $is_raw_nav && ref($file_stat) eq 'ARRAY' ) {
        $cache_key = join "\0", $skill_name, $route_id, $file, @skill_layers;
        $cache_fingerprint = _skill_nav_fingerprint($file_stat);
        my $cached_page = $self->_cached_literal_skill_nav_page( $cache_key, $cache_fingerprint );
        return $cached_page if $cached_page;
    }

    require Developer::Dashboard::PageDocument;
    my $instruction = $self->_read_skill_page_instruction($file);

    my $raw_url = $instruction;
    $raw_url =~ s/\A\s+|\s+\z//g;
    my $page;
    my $parse_error = '';
    if ( $is_raw_nav && $raw_url !~ m{\A(?:https?:)?//[^\s]+\z}
        && !_looks_like_skill_page_instruction($instruction) )
    {
        $page = Developer::Dashboard::PageDocument->new(
            id     => $skill_name . '/' . $route_id,
            title  => $route_id,
            layout => { body => $instruction },
            meta   => { source_format => 'raw-nav-tt' },
        );
    }
    else {
        $page = eval { Developer::Dashboard::PageDocument->from_instruction($instruction) };
        $parse_error = $@;
    }
    if ( !$page && $raw_url =~ m{\A(?:https?:)?//[^\s]+\z} ) {
        $page = Developer::Dashboard::PageDocument->new(
            id     => $skill_name . ( $route_id eq 'index' ? '' : '/' . $route_id ),
            title  => $route_id,
            layout => { body => $raw_url },
            meta   => { source_format => 'raw-url', raw_url => $raw_url },
        );
    }
    if ( !$page && $is_raw_nav ) {
        $page = Developer::Dashboard::PageDocument->new(
            id     => $skill_name . '/' . $route_id,
            title  => $route_id,
            layout => { body => $instruction },
            meta   => { source_format => 'raw-nav-tt' },
        );
    }
    die $parse_error if !$page;

    $page->{id} = $skill_name . ( $route_id eq 'index' ? '' : '/' . $route_id );
    $page->{meta}{source_kind}      = 'skill';
    $page->{meta}{skill_name}       = $skill_name;
    $page->{meta}{skill_route_id}   = $route_id;
    $page->{meta}{skill_path}       = $skill_path;
    $page->{meta}{skill_layers}     = \@skill_layers;
    $page->{meta}{raw_instruction}  = $instruction;
    if ( defined $cache_key
        && ( $page->{meta}{source_format} || '' ) eq 'raw-nav-tt'
        && index( $instruction, '[%' ) < 0 )
    {
        $self->_cache_literal_skill_nav_page(
            $cache_key,
            $cache_fingerprint,
            $page,
            bytes::length($instruction),
        );
    }
    return $page;
}

# _read_skill_page_instruction($file, $close_callback)
# Reads one skill dashboard instruction file using the existing text-mode
# behavior required by the page parser. An optional close callback provides a
# deterministic way to test close failures; normal callers use Perl's close.
# Input: resolved skill dashboard file path and optional close coderef.
# Output: complete instruction text scalar; open and close failures are fatal.
sub _read_skill_page_instruction {
    my ( $self, $file, $close_callback ) = @_;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    my $instruction = <$fh>;
    my $closed = ref($close_callback) eq 'CODE' ? $close_callback->($fh) : close $fh;
    die "Unable to close $file: $!" if !$closed;
    return $instruction;
}

# _skill_nav_fingerprint($stat)
# Converts a high-resolution stat result into a stable identity for one literal
# skill-nav cache entry.
# Input: stat array reference returned while resolving the existing page path.
# Output: NUL-separated device, inode, mode, size, mtime, and ctime fingerprint.
sub _skill_nav_fingerprint {
    my ($stat) = @_;
    return if ref($stat) ne 'ARRAY' || @{$stat} < 11;
    return join "\0", @{$stat}[ 0, 1, 2, 7, 9, 10 ];
}

# _cached_literal_skill_nav_page($key, $fingerprint)
# Returns a previously parsed literal nav page only when its current file stat
# identity matches; a mismatch removes the stale cache entry.
# Input: layer-aware cache key and the current high-resolution file fingerprint.
# Output: cached page object or undef for a miss or stale entry.
sub _cached_literal_skill_nav_page {
    my ( $self, $key, $fingerprint ) = @_;
    return if !defined $key || !defined $fingerprint;
    my $cache = $self->{_skill_literal_nav_cache};
    return if ref($cache) ne 'HASH' || ref( $cache->{entries} ) ne 'HASH';
    die 'Malformed literal skill-nav cache order'
      if ref( $cache->{order} ) ne 'ARRAY';
    die 'Malformed literal skill-nav cache byte count'
      if !defined $cache->{bytes} || $cache->{bytes} !~ /\A\d+\z/;
    my $entry = $cache->{entries}{$key};
    return if ref($entry) ne 'HASH';
    if ( defined $entry->{fingerprint}
        && $entry->{fingerprint} eq $fingerprint
        && ref( $entry->{page} ) eq 'Developer::Dashboard::PageDocument' )
    {
        return $entry->{page};
    }
    die 'Malformed literal skill-nav cache entry size'
      if !defined $entry->{bytes} || $entry->{bytes} !~ /\A\d+\z/;
    $cache->{bytes} -= $entry->{bytes};
    delete $cache->{entries}{$key};
    @{ $cache->{order} } = grep { $_ ne $key } @{ $cache->{order} };
    return;
}

# _cache_literal_skill_nav_page($key, $fingerprint, $page, $size)
# Stores a read-only literal nav page in a bounded per-dispatcher FIFO cache.
# Input: layer-aware key, matching file fingerprint, page object, and size.
# Output: true after insertion, false when cache inputs are unusable.
sub _cache_literal_skill_nav_page {
    my ( $self, $key, $fingerprint, $page, $size ) = @_;
    return 0
      if !defined $key
      || !defined $fingerprint
      || ref($page) ne 'Developer::Dashboard::PageDocument'
      || !defined $size
      || $size !~ /\A\d+\z/;
    my $cache = $self->{_skill_literal_nav_cache};
    if ( ref($cache) ne 'HASH' ) {
        $cache = $self->{_skill_literal_nav_cache} = { bytes => 0, entries => {}, order => [] };
    }
    return 0
      if ref( $cache->{entries} ) ne 'HASH'
      || ref( $cache->{order} ) ne 'ARRAY'
      || !defined $cache->{bytes}
      || $cache->{bytes} !~ /\A\d+\z/;
    if ( exists $cache->{entries}{$key} ) {
        my $old = $cache->{entries}{$key};
        $cache->{bytes} -= ref($old) eq 'HASH' ? ( $old->{bytes} || 0 ) : 0;
        @{ $cache->{order} } = grep { $_ ne $key } @{ $cache->{order} };
    }
    $cache->{entries}{$key} = {
        fingerprint => $fingerprint,
        page        => $page,
        bytes       => $size,
    };
    $cache->{bytes} += $size;
    push @{ $cache->{order} }, $key;
    while ( @{ $cache->{order} } > 256 || $cache->{bytes} > 8_388_608 ) {
        my $evict = shift @{ $cache->{order} };
        next if !exists $cache->{entries}{$evict};
        my $old = delete $cache->{entries}{$evict};
        $cache->{bytes} -= ref($old) eq 'HASH' ? ( $old->{bytes} || 0 ) : 0;
    }
    return 1;
}

# _looks_like_skill_page_instruction($text)
# Identifies the section markers that make a skill nav file a structured page
# document; ordinary TT/HTML fragments bypass the exception-driven parser.
# Input: decoded instruction text scalar.
# Output: true for modern markers, legacy separators, or a legacy section header.
sub _looks_like_skill_page_instruction {
    my ($text) = @_;
    return 0 if !defined $text || ref($text);
    return 1 if $text =~ /^===\s*[A-Z][A-Z0-9.]*\s*===/m;
    return 1 if $text =~ /^\Q$Developer::Dashboard::PageDocument::LEGACY_SEP\E\s*$/m;
    return 1 if $text =~ /^\s*---\s*$/m;
    my $first_content = $text;
    $first_content =~ s/\A[\r\n\s]+//;
    return $first_content =~ /\A(?:TITLE|ICON|BOOKMARK|STASH|NOTE|HEAD|HTML|CODE\d+)\s*:/i ? 1 : 0;
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
    my @perl5lib_extra;
    my %seen_perl5lib_extra;
    my @skill_paths = ( $skill_path, reverse @{ $args{skill_layers} || [] } );
    for my $layer_path (@skill_paths) {
        next if !defined $layer_path || $layer_path eq '';
        my $skill_lib = File::Spec->catdir( $layer_path, 'lib' );
        if ( -d $skill_lib && !$seen_perl5lib_extra{$skill_lib}++ ) {
            push @perl5lib_extra, $skill_lib;
        }
        for my $local_lib (
            File::Spec->catdir( $layer_path, 'perl5', 'lib', 'perl5' ),
            File::Spec->catdir( $layer_path, 'perl5', 'lib', 'perl5', $Config::Config{archname} ),
        ) {
            if ( -d $local_lib && !$seen_perl5lib_extra{$local_lib}++ ) {
                push @perl5lib_extra, $local_lib;
            }
        }
    }
    for my $shared_lib (
        File::Spec->catdir( $shared_root, 'lib', 'perl5' ),
        File::Spec->catdir( $shared_root, 'lib', 'perl5', $Config::Config{archname} ),
    ) {
        if ( -d $shared_lib && !$seen_perl5lib_extra{$shared_lib}++ ) {
            push @perl5lib_extra, $shared_lib;
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
        %{ Developer::Dashboard::PerlEnv->dashboard_child_env(
            extra => \@perl5lib_extra,
        ) },
    );
}

# _prepend_skill_lib_to_perl_argv($argv, $skill_path)
# Makes the skill providing one Perl CLI script its first Perl module lookup
# root, before the generic dashboard library injected by command_argv_for_path.
# Input: mutable command argv array reference and skill directory path.
# Output: same array reference, with a leading skill-lib -I pair for Perl argv.
sub _prepend_skill_lib_to_perl_argv {
    my ( $argv, $skill_path ) = @_;
    return $argv if ref($argv) ne 'ARRAY' || @$argv < 3 || $argv->[0] ne $^X;
    return $argv if !defined $skill_path || $skill_path eq '';
    my $skill_lib = File::Spec->catdir( $skill_path, 'lib' );
    return $argv if !-d $skill_lib;
    splice @$argv, 1, 0, ( '-I', $skill_lib );
    return $argv;
}

# _skill_layers($skill_name)
# Returns the participating installed roots for one skill in inheritance order,
# refusing any skill name whose slash-delimited segments fail the shared path
# validation so a crafted name can never address a directory outside the
# layered skills trees.
# Input: skill repository name string and optional include_disabled flag.
# Output: ordered list of skill root directory path strings from home to leaf.
sub _skill_layers {
    my ( $self, $skill_name, %args ) = @_;
    return () if !$skill_name;
    my @segments = Developer::Dashboard::PathRegistry::validated_path_segments($skill_name);
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
# Output: hash reference containing cmd_path, skill_path, command-provider
# skill_layers, inherited env_skill_layers, and command_name.
sub _command_spec {
    my ( $self, $skill_name, $command ) = @_;
    return if !$skill_name || !$command;

    my @segments = grep { $_ ne '' } split /\./, $command;
    return if !@segments;

    my @command_root_specs = $self->_command_root_specs( \@segments );

    # Resolve every explicit command before considering any initializer. An
    # initializer on an intermediate nested skill must not hide an explicit
    # command (or the initializer) on a deeper nested skill.
    for my $command_root_spec (@command_root_specs) {
        next if $command_root_spec->{init_only};
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
            my @env_skill_layers;
            my @env_frontier = $self->_skill_layers($skill_name);
            push @env_skill_layers, @env_frontier;
            for my $nested_segment ( @{ $command_root_spec->{nested_segments} } ) {
                my @next_frontier;
                for my $root_path (@env_frontier) {
                    my $nested_path = $self->_nested_skill_path( $root_path, [$nested_segment] );
                    push @next_frontier, $nested_path if -d $nested_path;
                }
                @env_frontier = @next_frontier;
                push @env_skill_layers, @env_frontier;
            }
            return {
                cmd_path      => $cmd_path,
                skill_path    => $provider_path,
                skill_layers  => \@provider_layers,
                env_skill_layers => \@env_skill_layers,
                command_name  => $command_root_spec->{command_name},
            };
        }
    }

    # Search initializer fallbacks from the deepest provider back toward the
    # root. This allows a dotted command tail to name a nested skill directly
    # (foo.bar -> foo/skills/bar/cli/__init__) and ensures a deeper nested
    # initializer wins over an ancestor's generic __init__.
    for my $command_root_spec ( reverse @command_root_specs ) {
        my @provider_layers = ();
        for my $skill_path ( $self->_skill_layers($skill_name) ) {
            my $provider_path = $self->_nested_skill_path( $skill_path, $command_root_spec->{nested_segments} );
            next if @{ $command_root_spec->{nested_segments} } && !-d $provider_path;
            push @provider_layers, $provider_path;
        }
        next if !@provider_layers;

        for my $provider_path ( reverse @provider_layers ) {
            my $cmd_path = resolve_runnable_file( File::Spec->catfile( $provider_path, 'cli', '__init__' ) );
            next if !$cmd_path;
            my @env_skill_layers;
            my @env_frontier = $self->_skill_layers($skill_name);
            push @env_skill_layers, @env_frontier;
            for my $nested_segment ( @{ $command_root_spec->{nested_segments} } ) {
                my @next_frontier;
                for my $root_path (@env_frontier) {
                    my $nested_path = $self->_nested_skill_path( $root_path, [$nested_segment] );
                    push @next_frontier, $nested_path if -d $nested_path;
                }
                @env_frontier = @next_frontier;
                push @env_skill_layers, @env_frontier;
            }
            return {
                cmd_path      => $cmd_path,
                skill_path    => $provider_path,
                skill_layers  => \@provider_layers,
                env_skill_layers => \@env_skill_layers,
                command_name  => $command_root_spec->{init_only} ? '__init__' : $command_root_spec->{command_name},
            };
        }
    }

    return;
}

# _native_version_fallback($skill_name)
# Answers `d2 <skill>.version` natively when the skill ships no cli/version
# script of its own, by reading a raw VERSION= line from the skill's own
# layered .env files (leaf-most layer first, same precedence order
# _command_spec already uses for resolving a real command file).
# Input: skill repository name string and optional home-to-leaf layer array ref.
# Output: hash reference with stdout, stderr, and exit_code (never an error -
# a missing .env or a missing VERSION= key are reported in stdout, not failed).
sub _native_version_fallback {
    my ( $self, $skill_name ) = @_;
    for my $skill_path ( reverse $self->_skill_layers($skill_name) ) {
        my $env_file = File::Spec->catfile( $skill_path, '.env' );
        next if !-f $env_file;
        open my $fh, '<:raw', $env_file or next;
        local $/;
        my $body = <$fh>;
        close $fh;
        return { stdout => "$1\n", stderr => '', exit_code => 0 } if $body =~ /^\s*VERSION\s*=\s*(\S+)\s*$/m;
    }
    return { stdout => "no version number found\n", stderr => '', exit_code => 0 };
}

# _command_root_specs(\@segments)
# Builds candidate nested-skill command roots from the dotted command tail.
# Input: array reference of dotted command segments.
# Output: ordered explicit-command candidates, followed by a terminal nested
# initializer candidate when the complete tail can name a nested skill.
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
        my @nested_segments = @segments[ 0 .. $split_index - 1 ];
        my @validated_nested_segments = Developer::Dashboard::PathRegistry::validated_path_segments( join '/', @nested_segments );
        next if @validated_nested_segments != @nested_segments;
        push @specs, {
            nested_segments => \@nested_segments,
            command_name    => join( '.', @segments[ $split_index .. $#segments ] ),
        };
    }

    my @validated_terminal_segments = Developer::Dashboard::PathRegistry::validated_path_segments( join '/', @segments );
    if ( @validated_terminal_segments == @segments ) {
        push @specs, {
            nested_segments => [@segments],
            command_name    => '__init__',
            init_only       => 1,
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

# _page_location($skill_name, $route_id, %args)
# Resolves one skill dashboard file across every participating skill layer,
# refusing unsafe route segments. Browser-supplied ids use the shared path
# validator; private inventory callers can reuse validated segments after
# explicit per-segment separator, control-byte, and traversal checks.
# Input: skill repository name, route id string such as index or nav/foo.tt,
# optional pre-resolved layers, and optional inventory-derived route segments.
# Output: file path string, serving skill layer root, and high-resolution stat
# array reference for the located regular file; or the empty list when missing.
sub _page_location {
    my ( $self, $skill_name, $route_id, %args ) = @_;
    return if !$skill_name || !$route_id;
    my @segments;
    if ( exists $args{validated_route_segments} ) {
        return if ref( $args{validated_route_segments} ) ne 'ARRAY';
        @segments = @{ $args{validated_route_segments} };
        return if !@segments || grep {
               !defined $_
            || ref($_)
            || $_ eq ''
            || $_ eq '.'
            || $_ eq '..'
            || $_ =~ m{[\\/\x00-\x1F\x7F]}
        } @segments;
        return if $segments[0] =~ /\A[A-Za-z]:/;
    }
    else {
        @segments = Developer::Dashboard::PathRegistry::validated_path_segments($route_id);
    }
    return if !@segments;
    my @skill_roots = ref( $args{layers} ) eq 'ARRAY'
      ? reverse @{ $args{layers} }
      : $self->_skill_lookup_roots($skill_name);
    for my $skill_path (@skill_roots) {
        my $file = File::Spec->catfile( $skill_path, 'dashboards', @segments );
        my @stat = Time::HiRes::stat($file);
        return ( $file, $skill_path, \@stat ) if @stat && -f _;
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
        return $spec if $spec->{path} eq $path;
        return $spec if grep { $_ eq $path } @{ $spec->{aliases} };
    }
    for my $skill_name ( $self->_all_installed_skill_names ) {
        for my $kind (qw(app ajax js css others)) {
            my $routes = $self->_skill_routes_for( $skill_name, $kind );
            for my $target ( sort keys %{$routes} ) {
                my $spec = $routes->{$target};
                return $spec if $spec->{path} eq $path;
                return $spec if grep { $_ eq $path } @{ $spec->{aliases} };
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
            my $kind_routes = $payload->{$kind};
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
    return if !$spec || $spec->{kind} ne 'ajax';
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
        my $kind_routes = $payload->{$kind};
        for my $target ( sort keys %{$kind_routes} ) {
            next if exists $routes{$target};
            my $spec = $self->_normalize_skill_route_spec(
                kind       => $kind,
                skill_name => $skill_name,
                target     => $target,
                routes_file => $routes_file,
                spec       => $kind_routes->{$target},
            );
            for my $route_path ( $spec->{path}, @{ $spec->{aliases} } ) {
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
# Input: skill repository name, optional pre-resolved skill layers, and optional
# hash reference to receive validated route segments keyed by nav filename.
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
          if $target eq '';
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
# Resolves one layered skill-local dashboards/ajax file in deepest-first order,
# refusing any ajax file path whose segments fail the shared path validation so
# a browser-supplied name can never address a file outside a skill ajax tree.
# Input: skill repository name string and relative ajax file path.
# Output: absolute file path string or undef when missing or invalid.
sub skill_ajax_file_path {
    my ( $self, $skill_name, $ajax_file ) = @_;
    return if !$skill_name || !$ajax_file;
    my @segments = Developer::Dashboard::PathRegistry::validated_path_segments($ajax_file);
    return if !@segments;
    for my $skill_path ( $self->_skill_lookup_roots($skill_name) ) {
        my $file = File::Spec->catfile( $skill_path, 'dashboards', 'ajax', @segments );
        return $file if -f $file;
    }
    return;
}

# skill_static_roots($skill_name, $type)
# Lists the layered dashboards/public/<type> roots one skill may serve static
# assets from, in effective lookup order, so the web layer can assert that a
# resolved asset path stays inside one of them before opening it. The asset
# type must be exactly one validated path segment.
# Input: skill repository name string and static asset type string.
# Output: ordered list of public root directory path strings, or an empty list
# when the skill name or asset type is missing or invalid.
sub skill_static_roots {
    my ( $self, $skill_name, $type ) = @_;
    return () if !$skill_name || !$type;
    my @type_segments = Developer::Dashboard::PathRegistry::validated_path_segments($type);
    return () if @type_segments != 1;
    return map { File::Spec->catdir( $_, 'dashboards', 'public', $type ) } $self->_skill_lookup_roots($skill_name);
}

# skill_static_file_path($skill_name, $type, $file)
# Resolves one layered skill-local dashboards/public asset in deepest-first
# order, refusing any asset type or file path whose segments fail the shared
# path validation so a browser-supplied name can never address a file outside
# a skill public tree.
# Input: skill repository name string, static asset type, and relative file path.
# Output: absolute file path string or undef when missing or invalid.
sub skill_static_file_path {
    my ( $self, $skill_name, $type, $file ) = @_;
    return if !$skill_name || !$type || !$file;
    my @file_segments = Developer::Dashboard::PathRegistry::validated_path_segments($file);
    return if !@file_segments;
    for my $public_root ( $self->skill_static_roots( $skill_name, $type ) ) {
        my $candidate = File::Spec->catfile( $public_root, @file_segments );
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
# duplicates overriding shallower layers. A bounded inventory cache avoids
# recursively reopening unchanged nav directories; directory stat fingerprints
# invalidate it when routes are created, removed, or moved.
# Input: skill repository name string.
# Output: hash of nav filenames to route ids.
sub _skill_nav_route_ids {
    my ( $self, $skill_name, $skill_layers, $validated_routes ) = @_;
    return () if !$skill_name;
    my %routes;
    $validated_routes = undef if ref($validated_routes) ne 'HASH';
    my @lookup_roots = ref($skill_layers) eq 'ARRAY'
      ? reverse @{$skill_layers}
      : $self->_skill_lookup_roots($skill_name);
    for my $skill_path (@lookup_roots) {
        my $nav_root = File::Spec->catdir( $skill_path, 'dashboards', 'nav' );
        my %inventory_segments;
        for my $entry ( $self->_skill_nav_inventory( $nav_root, \%inventory_segments ) ) {
            if ( !exists $routes{$entry} ) {
                $routes{$entry} = 'nav/' . $entry;
                if ($validated_routes) {
                    my $segments = $inventory_segments{$entry};
                    $validated_routes->{$entry} = defined $segments
                      ? [ 'nav', @{$segments} ]
                      : undef;
                }
            }
        }
    }
    return %routes;
}

# _skill_nav_directory_fingerprint($directory)
# Builds a high-resolution identity for one directory in a cached nav inventory.
# Input: directory path string.
# Output: NUL-separated stat identity or undef when the directory cannot be statted.
sub _skill_nav_directory_fingerprint {
    my ($directory) = @_;
    return if !defined $directory || $directory eq '';
    my @stat = Time::HiRes::stat($directory);
    return if !@stat;
    return if !-d $directory;
    return join "\0", @stat[ 0, 1, 2, 7, 9, 10 ];
}

# _skill_nav_inventory($nav_root)
# Returns recursively discovered nav file ids, reusing a bounded inventory only
# while every directory in that tree has the same high-resolution stat identity.
# Input: nav root directory, optional hash reference receiving validated
# relative segments by file, and private force-refresh boolean for benchmarks.
# Output: sorted relative file paths, or an empty list for a missing root.
sub _skill_nav_inventory {
    my ( $self, $nav_root, $validated_segments ) = @_;
    return () if !$nav_root;
    return () if !-d $nav_root;

    my $cache = $self->{_skill_nav_inventory_cache};
    if ( defined $cache ) {
        die 'Malformed skill-nav inventory cache' if ref($cache) ne 'HASH';
        die 'Malformed skill-nav inventory entries' if ref( $cache->{entries} ) ne 'HASH';
        die 'Malformed skill-nav inventory order' if ref( $cache->{order} ) ne 'ARRAY';
        my $entry = $cache->{entries}{$nav_root};
        if ( defined $entry ) {
            die 'Malformed skill-nav inventory entry' if ref($entry) ne 'HASH';
            die 'Malformed skill-nav inventory files' if ref( $entry->{files} ) ne 'ARRAY';
            die 'Malformed skill-nav inventory directories' if ref( $entry->{directories} ) ne 'ARRAY';
            my $valid = 1;
            for my $directory ( @{ $entry->{directories} } ) {
                die 'Malformed skill-nav inventory directory fingerprint' if ref($directory) ne 'ARRAY';
                die 'Malformed skill-nav inventory directory fingerprint width' if @{$directory} != 2;
                my $current = _skill_nav_directory_fingerprint( $directory->[0] );
                if ( !defined $current ) {
                    $valid = 0;
                    last;
                }
                if ( $current ne $directory->[1] ) {
                    $valid = 0;
                    last;
                }
            }
            if ($valid) {
                my $segments = $entry->{segments};
                die 'Malformed skill-nav inventory segments' if ref($segments) ne 'HASH';
                for my $file ( @{ $entry->{files} } ) {
                    die 'Malformed skill-nav inventory segment entry'
                      if !exists $segments->{$file}
                      || ( defined $segments->{$file} && ref( $segments->{$file} ) ne 'ARRAY' );
                }
                if ( ref($validated_segments) eq 'HASH' ) {
                    %{$validated_segments} = map {
                        $_ => ( ref( $segments->{$_} ) eq 'ARRAY' ? [ @{ $segments->{$_} } ] : undef )
                    } keys %{$segments};
                }
                return @{ $entry->{files} };
            }
            delete $cache->{entries}{$nav_root};
            @{ $cache->{order} } = grep { $_ ne $nav_root } @{ $cache->{order} };
        }
    }

    my ( @directories, @before_scan );
    my @files = $self->_relative_files( $nav_root, \@directories, \@before_scan );
    my %segments_by_file;
    for my $file (@files) {
        my @segments = Developer::Dashboard::PathRegistry::validated_path_segments($file);
        $segments_by_file{$file} = @segments ? \@segments : undef;
    }
    %{$validated_segments} = map {
        $_ => ( ref( $segments_by_file{$_} ) eq 'ARRAY' ? [ @{ $segments_by_file{$_} } ] : undef )
    } keys %segments_by_file
      if ref($validated_segments) eq 'HASH';
    my @before = map { [ $directories[$_], $before_scan[$_] ] } 0 .. $#directories;
    my $stable = !grep { !defined $_->[1] } @before;
    if ($stable) {
        my @after = map { [ $_, _skill_nav_directory_fingerprint($_) ] } @directories;
        for my $index ( 0 .. $#before ) {
            if ( !defined $after[$index][1] || $before[$index][1] ne $after[$index][1] ) {
                $stable = 0;
                last;
            }
        }
    }
    my $entry_bytes = 0;
    if ($stable) {
        $entry_bytes += length($_) for @files;
        $entry_bytes += 8 + length($_) for @files;
        $entry_bytes += 8 + length($_) for map { @{ $segments_by_file{$_} || [] } } @files;
        $entry_bytes += length( $_->[0] ) + length( $_->[1] ) for @before;
    }
    if ( $stable
        && _skill_nav_inventory_within_limits( scalar @directories, scalar @files, $entry_bytes ) )
    {
        if ( !defined $cache ) {
            $cache = $self->{_skill_nav_inventory_cache} = { entries => {}, order => [] };
        }
        $cache->{entries}{$nav_root} = {
            files       => [@files],
            segments    => \%segments_by_file,
            directories => \@before,
        };
        push @{ $cache->{order} }, $nav_root;
        while ( @{ $cache->{order} } > 128 ) {
            my $expired = shift @{ $cache->{order} };
            delete $cache->{entries}{$expired};
        }
    }
    return @files;
}

# _skill_nav_inventory_within_limits($directory_count, $file_count, $bytes)
# Keeps a single cached route inventory below fixed memory and traversal bounds.
# Input: counts and byte size for one nav-tree inventory.
# Output: true when that inventory is safe to retain, otherwise false.
sub _skill_nav_inventory_within_limits {
    my ( $directory_count, $file_count, $bytes ) = @_;
    return 0 if !defined $directory_count || $directory_count > 4096;
    return 0 if !defined $file_count || $file_count > 8192;
    return 0 if !defined $bytes || $bytes > 262_144;
    return 1;
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
        next if !defined $skill_name;
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

# _relative_files($root, $visited_directories)
# Recursively lists files beneath one root as forward-slash relative paths so
# nested nav fragments can be routed without flattening subdirectories. When an
# accumulator is supplied, each visited directory is appended for cache checks.
# Input: absolute root directory path and optional directory-path array reference.
# Output: sorted list of relative file path strings.
sub _relative_files {
    my ( $self, $root, $visited_directories, $initial_fingerprints ) = @_;
    return () if !$root || !-d $root;

    push @{$visited_directories}, $root if ref($visited_directories) eq 'ARRAY';
    push @{$initial_fingerprints}, _skill_nav_directory_fingerprint($root)
      if ref($initial_fingerprints) eq 'ARRAY';
    my @relative_files;
    opendir my $dh, $root or die "Unable to read $root: $!";
    for my $entry ( sorted_dir_entries($dh) ) {
        my $path = File::Spec->catfile( $root, $entry );
        if ( -d $path ) {
            push @relative_files,
              map { $entry . '/' . $_ }
              $self->_relative_files( $path, $visited_directories, $initial_fingerprints );
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

Every browser-facing resolver (skill names, route ids, ajax files, and static
asset paths) validates its untrusted path input through the shared
C<Developer::Dashboard::PathRegistry::validated_path_segments> guard before
joining it onto a skill root, so parent-directory, absolute, drive-qualified,
backslash, and control-byte shapes resolve to nothing instead of escaping the
layered skills trees, and C<skill_static_roots> exposes the layered
C<dashboards/public> roots the web layer asserts containment against.

Installed-skill navigation discovery caches each sorted relative route list in
a bounded per-dispatcher FIFO. Every request fingerprints each directory in a
cached tree before reusing its route list; a changed or missing directory
causes a rescan. This avoids repeated directory enumeration without caching
resolved files or skipping the normal path containment and file-identity
checks. The cache retains at most 128 roots, with each inventory limited to
4,096 directories, 8,192 file paths, and 256 KiB of route and fingerprint data.

When every installed skill nav page is a literal raw fragment, the dispatcher
also keeps one aggregate page-array snapshot behind the existing optional
cross-platform filesystem watcher. Its watch set includes runtime and skill
roots, their creation parents, dashboards/nav directories, and every discovered
nested nav directory. An event invalidates the aggregate and returns loading to
the normal route-inventory and per-file stat checks. Dynamic or structured
pages are never held in the aggregate snapshot. If the watcher is unavailable,
fails setup, or fails while polling, aggregate reuse is disabled and the
portable page-loading path remains active; watcher shutdown is explicit when
the dispatcher is destroyed. Failed watcher closure is reported even when an
optional watcher implementation does not provide a diagnostic method.

Skill command and hook environments are loaded through
C<Developer::Dashboard::EnvLoader::load_skill_runtime_layers>: home runtime
files provide defaults, skill and skill-CLI files override those defaults, and
deeper project runtime files retain final precedence.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module executes installed skill commands and serves skill bookmark routes. It resolves a skill command path, runs any sorted hook files under C<cli/E<lt>commandE<gt>.d>, prepares the isolated skill environment, hands hook state through C<Developer::Dashboard::Runtime::Result> so oversized hook payloads spill into C<RESULT_FILE> automatically, captures stdout/stderr, and can render bookmarks under C</skill/E<lt>repoE<gt>/bookmarks/...> through the main page renderer.

=head1 WHY IT EXISTS

It exists because the skill system needs a boundary between skill installation and skill execution. Dispatching commands, hook chaining, isolated environment variables, and bookmark routing all belong in one module instead of being hand-built in the web layer or CLI wrappers. It also answers C<E<lt>skillE<gt>.version> natively (DD-1043) by reading a raw C<VERSION=> line from the skill's own layered C<.env> when the skill ships no C<cli/version> script of its own, so no skill needs to hand-write one just to expose a version number.

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
