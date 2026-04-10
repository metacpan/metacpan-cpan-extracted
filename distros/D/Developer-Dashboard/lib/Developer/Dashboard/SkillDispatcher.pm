package Developer::Dashboard::SkillDispatcher;

use strict;
use warnings;

our $VERSION = '2.17';

use File::Spec;
use JSON::XS qw(encode_json decode_json);
use Capture::Tiny qw(capture);
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

    my $skill_path = $self->{manager}->get_skill_path($skill_name);
    return { error => "Skill '$skill_name' not found" } if !$skill_path;

    my $cmd_path = $self->command_path( $skill_name, $command );
    return { error => "Command '$command' not found in skill '$skill_name'" } if !$cmd_path;

    my $hook_result = $self->execute_hooks( $skill_name, $command, @args );
    return $hook_result if $hook_result->{error};

    my %env = $self->_skill_env(
        skill_name   => $skill_name,
        skill_path   => $skill_path,
        command      => $command,
        result_state => $hook_result->{result_state} || {},
    );
    my @command = command_argv_for_path($cmd_path);

    my ( $stdout, $stderr, $exit ) = capture {
        local %ENV = ( %ENV, %env );
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
    my $skill_path = $self->{manager}->get_skill_path($skill_name);
    return { hooks => {}, result_state => {} } if !$skill_path;

    my $hooks_dir = File::Spec->catdir( $skill_path, 'cli', "$command.d" );
    return { hooks => {}, result_state => {} } if !-d $hooks_dir;

    my %results;
    opendir( my $dh, $hooks_dir ) or return {};
    for my $entry ( sort grep { $_ ne '.' && $_ ne '..' } readdir($dh) ) {
        my $hook_path = File::Spec->catfile( $hooks_dir, $entry );
        next unless is_runnable_file($hook_path);

        my %env = $self->_skill_env(
            skill_name   => $skill_name,
            skill_path   => $skill_path,
            command      => $command,
            result_state => \%results,
        );
        my @command = command_argv_for_path($hook_path);
        my ( $stdout, $stderr, $exit ) = capture {
            local %ENV = ( %ENV, %env );
            system( @command, @args );
        };
        $results{$entry} = {
            stdout    => $stdout,
            stderr    => $stderr,
            exit_code => $exit,
        };
    }
    closedir($dh);
    return {
        hooks        => \%results,
        result_state => \%results,
    };
}

# get_skill_config($skill_name)
# Reads and returns a skill's configuration.
# Input: skill repo name.
# Output: hash ref with config or empty hash.
sub get_skill_config {
    my ( $self, $skill_name ) = @_;
    
    return {} if !$skill_name;
    
    my $skill_path = $self->{manager}->get_skill_path($skill_name);
    return {} if !$skill_path;
    
    my $config_file = File::Spec->catfile( $skill_path, 'config', 'config.json' );
    return {} if !-f $config_file;
    
    open( my $fh, '<', $config_file ) or return {};
    my $json_text = do { local $/; <$fh> };
    close($fh);
    
    my $config = eval { decode_json($json_text) } || {};
    return $config;
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
    my $skill_path = $self->{manager}->get_skill_path($skill_name) or return;
    return resolve_runnable_file( File::Spec->catfile( $skill_path, 'cli', $command ) );
}

# route_response(%args)
# Serves isolated skill bookmark routes under /skill/<repo>/<route>.
# Input: skill name, route path, and optional web app for rendering.
# Output: array reference HTTP response.
sub route_response {
    my ( $self, %args ) = @_;
    my $skill_name = $args{skill_name} || '';
    my $route      = $args{route} || '';
    my $skill_path = $self->{manager}->get_skill_path($skill_name)
      or return [ 404, 'text/plain; charset=utf-8', "Skill '$skill_name' not found\n" ];

    my @parts = grep { defined && $_ ne '' } split m{/+}, $route;
    return [ 404, 'text/plain; charset=utf-8', "Skill route '$route' not found\n" ] if !@parts;

    if ( $parts[0] eq 'bookmarks' ) {
        my $dashboards_root = File::Spec->catdir( $skill_path, 'dashboards' );
        return [ 404, 'text/plain; charset=utf-8', "Skill '$skill_name' does not provide bookmarks\n" ]
          if !-d $dashboards_root;

        if ( @parts == 1 ) {
            opendir( my $dh, $dashboards_root ) or die "Unable to read $dashboards_root: $!";
            my @items = sort grep { $_ ne '.' && $_ ne '..' && -f File::Spec->catfile( $dashboards_root, $_ ) } readdir($dh);
            closedir($dh);
            return [ 200, 'application/json; charset=utf-8', encode_json( { skill => $skill_name, bookmarks => \@items } ) ];
        }

        my $id = join '/', @parts[ 1 .. $#parts ];
        my $file = File::Spec->catfile( $dashboards_root, $id );
        return [ 404, 'text/plain; charset=utf-8', "Skill bookmark '$id' not found\n" ] if !-f $file;

        require Developer::Dashboard::PageDocument;
        open my $fh, '<', $file or die "Unable to read $file: $!";
        local $/;
        my $instruction = <$fh>;
        close $fh;
        my $page = Developer::Dashboard::PageDocument->from_instruction($instruction);
        $page->{id} = $id;
        $page->{meta}{source_kind} = 'skill';
        $page->{meta}{raw_instruction} = $instruction;
        return $args{app}->_page_response( $page, 'render' );
    }

    return [ 404, 'text/plain; charset=utf-8', "Skill route '$route' not found\n" ];
}

# _skill_env(%args)
# Builds the isolated environment passed to skill hooks and commands.
# Input: skill name, skill path, command name, and accumulated RESULT state.
# Output: hash of environment variables.
sub _skill_env {
    my ( $self, %args ) = @_;
    my $skill_path = $args{skill_path} || die 'Missing skill path';
    my $local_root = File::Spec->catdir( $skill_path, 'local' );
    my $local_lib  = File::Spec->catdir( $local_root, 'lib', 'perl5' );
    my $path_sep   = $^O eq 'MSWin32' ? ';' : ':';
    my @perl5lib   = grep { defined && $_ ne '' } split /\Q$path_sep\E/, ( $ENV{PERL5LIB} || '' );
    unshift @perl5lib, $local_lib if -d $local_lib;

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
        RESULT                                => encode_json( $args{result_state} || {} ),
        PERL5LIB                              => join( $path_sep, @perl5lib ),
    );
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

This module executes installed skill commands and serves skill bookmark routes. It resolves a skill command path, runs any sorted hook files under C<cli/E<lt>commandE<gt>.d>, prepares the isolated skill environment, captures stdout/stderr, and can render bookmarks under C</skill/E<lt>repoE<gt>/bookmarks/...> through the main page renderer.

=head1 WHY IT EXISTS

It exists because the skill system needs a boundary between skill installation and skill execution. Dispatching commands, hook chaining, isolated environment variables, and bookmark routing all belong in one module instead of being hand-built in the web layer or CLI wrappers.

=head1 WHEN TO USE

Use this file when changing skill command execution, hook order, the skill environment contract, or the bookmark route behavior exposed under the C</skill/...> URL space.

=head1 HOW TO USE

Construct it with a skill manager, call C<dispatch> for one command invocation, or call C<route_response> when the web app needs a bookmark response from a skill. Keep skill execution isolation here instead of folding it into generic command code.

=head1 WHAT USES IT

It is used by the C<dashboard skill> command, by the skill bookmark web routes, by skill installation flows that later need execution, and by skill-system and web-route regression tests.

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
