package Developer::Dashboard::CLI::Help;

use strict;
use warnings;

our $VERSION = '5.51';

use Developer::Dashboard::InternalCLI ();

my %COMMANDS = (
    action => {
        usage => 'dashboard action <run> <page-id> <action-id>',
        description => 'Run one saved-page action.',
        actions => {
            run => [ 'dashboard action run <page-id> <action-id>', 'Execute an action declared by a saved page.' ],
        },
    },
    api => {
        usage => 'dashboard api [ls|add|rm] [options]',
        description => 'Manage the layered machine-to-machine API registry.',
        actions => {
            ls  => [ 'dashboard api ls [--key <name>] [-o|--output json|table]', 'List registered keys and routes (the default action).' ],
            add => [ 'dashboard api add --key <name> [--secret <raw>|--maybe-secret <raw>] [--route /ajax/... ]... [-o json|table]', 'Create a key or add routes to a key.' ],
            rm  => [ 'dashboard api rm --key <name> [--route /ajax/... ]... [-o json|table]', 'Remove a key or one of its routes.' ],
        },
    },
    ask => {
        usage => 'dashboard ask [--claude|--codex|--copilot|--gemini|--nova] [options] <question>',
        description => 'Ask a configured coding assistant with optional file and workspace context.',
        options => [
            '--claude|--codex|--copilot|--gemini|--nova  Select the assistant backend (default: claude)',
            '--model, -m <name>                              Select a backend model',
            '--file, -f <path>                               Include a file; may be repeated',
            '--new, --reset                                  Start a fresh conversation',
            '--no-memory                                     Do not append to the workspace transcript',
            '--docs                                          Print onboarding context without contacting a backend',
        ],
    },
    auth => {
        usage => 'dashboard auth <add-user|list-users|remove-user> [arguments]',
        description => 'Manage browser dashboard helper users.',
        actions => {
            'add-user'    => [ 'dashboard auth add-user <username> <password>', 'Add a helper login.' ],
            'list-users'  => [ 'dashboard auth list-users', 'List configured helper usernames.' ],
            'remove-user' => [ 'dashboard auth remove-user <username>', 'Remove a helper login.' ],
        },
    },
    collector => {
        usage => 'dashboard collector <action> [arguments]',
        description => 'Inspect, run, and control configured collectors.',
        actions => {
            'write-result' => [ 'dashboard collector write-result <name> <exit-code>', 'Read collector stdout from standard input and store a result.' ],
            status         => [ 'dashboard collector status <name>', 'Print the collector status record.' ],
            list           => [ 'dashboard collector list', 'List known collectors.' ],
            job            => [ 'dashboard collector job <name>', 'Print the collector job definition.' ],
            output         => [ 'dashboard collector output <name>', 'Print the latest collector output record.' ],
            inspect        => [ 'dashboard collector inspect <name>', 'Print combined collector diagnostics.' ],
            log            => [ 'dashboard collector log [name]', 'Print one or all collector logs.' ],
            run            => [ 'dashboard collector run <name>', 'Run a configured collector once.' ],
            start          => [ 'dashboard collector start <name>', 'Start one collector.' ],
            stop           => [ 'dashboard collector stop <name>', 'Stop one collector.' ],
            restart        => [ 'dashboard collector restart <name>', 'Restart one collector.' ],
        },
    },
    complete => {
        usage => 'dashboard complete <index> <word0> <word1> ...',
        description => 'Print shell-completion candidates, one per line.',
    },
    config => {
        usage => 'dashboard config <init|show>',
        description => 'Initialize or inspect the effective configuration.',
        actions => {
            init => [ 'dashboard config init', 'Create the base configuration if it does not exist.' ],
            show => [ 'dashboard config show', 'Print the merged runtime configuration.' ],
        },
    },
    cpan => {
        usage => 'dashboard cpan <module> [module ...]',
        description => 'Install Perl modules into the active dashboard runtime.',
    },
    csvq => { usage => 'dashboard csvq [file] [query]', description => 'Query CSV input from a file or standard input.' },
    decode => { usage => 'dashboard decode <token> (or read token from standard input)', description => 'Decode a dashboard payload token.' },
    docker => {
        usage => 'dashboard docker <compose|list|enable|disable|development> [arguments]',
        description => 'Resolve Docker Compose configuration and manage service enablement.',
        actions => {
            compose     => [ 'dashboard docker compose [selectors] <compose-arguments...>', 'Resolve layered Compose files and execute Docker Compose; supports --addon, --mode, --service, --project, and --dry-run.' ],
            list        => [ 'dashboard docker list [--enabled|--disabled]', 'List detected Docker services.' ],
            enable      => [ 'dashboard docker enable <service> [service ...]', 'Enable one or more services.' ],
            disable     => [ 'dashboard docker disable <service> [service ...]', 'Disable one or more services.' ],
            development => [ 'dashboard docker development <enable|disable> <service> [service ...]', 'Enable or disable a service development overlay.' ],
        },
    },
    'docker development' => {
        usage => 'dashboard docker development <enable|disable> <service> [service ...]',
        description => 'Manage opt-in development Compose overlays.',
        actions => {
            enable  => [ 'dashboard docker development enable <service> [service ...]', 'Create development markers for services.' ],
            disable => [ 'dashboard docker development disable <service> [service ...]', 'Remove development markers for services.' ],
        },
    },
    'docker compose' => {
        usage => 'dashboard docker compose [selectors] <compose-arguments...>',
        description => 'Resolve layered Compose configuration and pass remaining arguments to Docker Compose.',
        passthrough_arguments => 1,
    },
    doctor => { usage => 'dashboard doctor [--fix]', description => 'Check the installation and optionally repair supported drift.' },
    encode => { usage => 'dashboard encode <text from standard input>', description => 'Encode input as a dashboard payload token.' },
    file => {
        usage => 'dashboard file <resolve|locate|add|del|list> [arguments]',
        description => 'Manage named file aliases and locate files.',
        actions => {
            resolve => [ 'dashboard file resolve <name>', 'Print the resolved alias path.' ],
            locate  => [ 'dashboard file locate [root-or-alias] <term...> [-o json|table]', 'Search beneath a directory for file names.' ],
            add     => [ 'dashboard file add <name> <path> [-c|--create[=MODE]] [-o json|table]', 'Register a named file alias.' ],
            del     => [ 'dashboard file del <name> [-o json|table]', 'Remove a named file alias.' ],
            list    => [ 'dashboard file list [-o json|table]', 'List named file aliases.' ],
        },
    },
    files => { usage => 'dashboard files [-o json|table]', description => 'List effective named file aliases.' },
    housekeeper => { usage => 'dashboard housekeeper [--dry-run]', description => 'Clean dashboard-managed stale runtime state.' },
    indicator => {
        usage => 'dashboard indicator <set|list|refresh-core> [arguments]',
        description => 'Manage prompt and dashboard indicators.',
        actions => {
            set          => [ 'dashboard indicator set <name> <label> <icon> <status>', 'Set an indicator.' ],
            list         => [ 'dashboard indicator list', 'List indicators.' ],
            'refresh-core' => [ 'dashboard indicator refresh-core [cwd]', 'Refresh built-in indicators.' ],
        },
    },
    iniq => { usage => 'dashboard iniq [file] [query]', description => 'Query INI input from a file or standard input.' },
    init => { usage => 'dashboard init', description => 'Initialize the user runtime and stage managed helper assets.' },
    jq => { usage => 'dashboard jq [file] [query]', description => 'Query JSON input from a file or standard input.' },
    log => {
        usage => 'dashboard log [web|collector [name]] [-n <lines>] [-f]',
        description => 'Print dashboard or collector logs.',
        actions => {
            web       => [ 'dashboard log web [-n <lines>] [-f]', 'Read or follow the web service log.' ],
            collector => [ 'dashboard log collector [name]', 'Read one or all collector logs.' ],
        },
    },
    of => {
        usage => 'dashboard of [options] <file-or-scope> [pattern ...] | grep <grep-args...>',
        description => 'Open, print, or content-search matching files.',
        passthrough_actions => { grep => 1 },
    },
    'open-file' => { usage => 'dashboard open-file [options] <file-or-scope> [pattern ...]', description => 'Alias for the file-opening helper.' },
    page => {
        usage => 'dashboard page <new|save|list|show|encode|decode|urls|render|source> [arguments]',
        description => 'Create, edit, inspect, encode, and render dashboard pages.',
        actions => {
            new    => [ 'dashboard page new [id] [title]', 'Print a starter page document.' ],
            save   => [ 'dashboard page save <id> < page-document', 'Save page JSON or instruction text from standard input.' ],
            list   => [ 'dashboard page list', 'List saved pages.' ],
            show   => [ 'dashboard page show <id>', 'Print a saved page document.' ],
            encode => [ 'dashboard page encode [id] (or read a page from standard input)', 'Encode a page as a transient URL token.' ],
            decode => [ 'dashboard page decode [token] (or read from standard input)', 'Decode a transient page token.' ],
            urls   => [ 'dashboard page urls <id>', 'Print edit, render, and source URLs.' ],
            render => [ 'dashboard page render [id-or-file] (or read from standard input)', 'Render a page as HTML.' ],
            source => [ 'dashboard page source <id-or-token>', 'Print canonical page source.' ],
        },
    },
    path => {
        usage => 'dashboard path <resolve|locate|cdr|complete-cdr|add|del|rm|project-root|list> [arguments]',
        description => 'Manage and resolve project path aliases.',
        actions => {
            resolve      => [ 'dashboard path resolve <name>', 'Print the resolved alias path.' ],
            locate       => [ 'dashboard path locate <term...> [-o json|table]', 'Search for project paths.' ],
            cdr          => [ 'dashboard path cdr [name] [term...]', 'Resolve a path alias or find a matching project directory.' ],
            'complete-cdr' => [ 'dashboard path complete-cdr <index> <word...>', 'Print path candidates for the shell cdr helper.' ],
            add          => [ 'dashboard path add <name> <path> [-c|--create[=MODE]] [-o json|table]', 'Register a path alias.' ],
            del          => [ 'dashboard path del <name> [-o json|table]', 'Remove a path alias.' ],
            rm           => [ 'dashboard path rm <name> [-o json|table]', 'Compatibility alias for path del.' ],
            'project-root' => [ 'dashboard path project-root', 'Print the resolved project root.' ],
            list         => [ 'dashboard path list [-o json|table]', 'List effective path aliases.' ],
        },
    },
    paths => { usage => 'dashboard paths [-o json|table]', description => 'List effective path aliases.' },
    ps1 => { usage => 'dashboard ps1 [options]', description => 'Render the shell prompt status line.', options => [] },
    propq => { usage => 'dashboard propq [file] [query]', description => 'Query Java properties input.' },
    restart => {
        usage => 'dashboard restart [web|collector [name]] [options]',
        description => 'Restart dashboard services or collectors.',
        actions => {
            web       => [ 'dashboard restart web [options]', 'Restart the web service.' ],
            collector => [ 'dashboard restart collector [name]', 'Restart one or all collectors.' ],
        },
    },
    serve => {
        usage => 'dashboard serve [logs|workers] [arguments]',
        description => 'Start the web service or manage its logs and worker count.',
        actions => {
            logs    => [ 'dashboard serve logs [-n <lines>] [-f]', 'Read or follow web-service logs.' ],
            workers => [ 'dashboard serve workers <count> [--host <host>] [--port <port>]', 'Set the web worker count.' ],
        },
    },
    shell => {
        usage => 'dashboard shell [bash|zsh|sh|ps|powershell|pwsh]',
        description => 'Print shell bootstrap code and install supported shell integrations.',
        actions => {
            bash       => [ 'dashboard shell bash', 'Print Bash bootstrap code.' ],
            zsh        => [ 'dashboard shell zsh', 'Print Zsh bootstrap code.' ],
            sh         => [ 'dashboard shell sh', 'Print POSIX shell bootstrap code.' ],
            ps         => [ 'dashboard shell ps', 'Print PowerShell bootstrap code.' ],
            powershell => [ 'dashboard shell powershell', 'Print PowerShell bootstrap code.' ],
            pwsh       => [ 'dashboard shell pwsh', 'Print PowerShell bootstrap code.' ],
        },
    },
    skills => {
        usage => 'dashboard skills <install|uninstall|enable|disable|list|usage> [arguments]',
        description => 'Install, inspect, and manage installed skills.',
        actions => {
            install   => [ 'dashboard skills install [--notest] [-b branch] [-o json|table] <git-url-or-local-dir> ...', 'Install one or more skills; branch selection applies to Git sources.' ],
            uninstall => [ 'dashboard skills uninstall <repo-name> [-o json|table]', 'Uninstall an installed skill.' ],
            enable    => [ 'dashboard skills enable <repo-name> [-o json|table]', 'Enable an installed skill.' ],
            disable   => [ 'dashboard skills disable <repo-name> [-o json|table]', 'Disable an installed skill.' ],
            list      => [ 'dashboard skills list [-o json|table]', 'List installed skills.' ],
            usage     => [ 'dashboard skills usage <repo-name> [-o json|table]', 'Show usage information for an installed skill.' ],
        },
    },
    source => { usage => 'dashboard source --files', description => 'List installed dashboard source files.' },
    stop => {
        usage => 'dashboard stop [web|collector [name]]',
        description => 'Stop dashboard services or collectors.',
        actions => {
            web       => [ 'dashboard stop web', 'Stop the web service.' ],
            collector => [ 'dashboard stop collector [name]', 'Stop one or all collectors.' ],
        },
    },
    tomq => { usage => 'dashboard tomq [file] [query]', description => 'Query TOML input from a file or standard input.' },
    upgrade => { usage => 'dashboard upgrade [--dry-run]', description => 'Download and run the canonical dashboard installer.' },
    version => { usage => 'dashboard version', description => 'Print the installed Developer Dashboard version.' },
    which => { usage => 'dashboard which [--edit] <cmd-or-skill-command>', description => 'Resolve a command and show its hook chain.' },
    workspace => { usage => 'dashboard workspace <name> [options]', description => 'Create or attach to a tmux workspace session.' },
    xmlq => { usage => 'dashboard xmlq [file] [query]', description => 'Query XML input from a file or standard input.' },
    yq => { usage => 'dashboard yq [file] [query]', description => 'Query YAML input from a file or standard input.' },
);

my %ACTION_ORDER = (
    action              => [qw(run)],
    api                 => [qw(ls add rm)],
    auth                => [qw(add-user list-users remove-user)],
    collector           => [qw(write-result status list job output inspect log run start stop restart)],
    config              => [qw(init show)],
    docker              => [qw(compose list enable disable development)],
    'docker development' => [qw(enable disable)],
    file                => [qw(resolve locate add del list)],
    indicator           => [qw(set list refresh-core)],
    page                => [qw(new save list show encode decode urls render source)],
    path                => [qw(resolve locate cdr complete-cdr add del rm project-root list)],
    restart             => [qw(web collector)],
    stop                => [qw(web collector)],
    log                 => [qw(web collector)],
    serve               => [qw(logs workers)],
    shell               => [qw(bash zsh sh ps powershell pwsh)],
    skills              => [qw(install uninstall enable disable list usage)],
);

my %OPTIONS = (
    ask                       => [qw(--claude --codex --copilot --gemini --nova --model -m --file -f --new --reset --no-memory --docs)],
    api                       => [qw(--key --output -o)],
    'api ls'                  => [qw(--output -o --key)],
    'api add'                 => [qw(--key --secret --maybe-secret --route --output -o)],
    'api rm'                  => [qw(--key --route --output -o)],
    'docker compose'          => [qw(--addon --mode --service --project --dry-run --no-dry-run)],
    'docker list'             => [qw(--enabled --no-enabled --disabled --no-disabled)],
    doctor                    => [qw(--fix --no-fix)],
    'file locate'             => [qw(--output -o)],
    'file add'                => [qw(--create -c --output -o)],
    'file del'                => [qw(--output -o)],
    'file list'               => [qw(--output -o)],
    files                     => [qw(--output -o)],
    housekeeper               => [qw(--dry-run --no-dry-run)],
    'path locate'             => [qw(--output -o)],
    'path add'                => [qw(--create -c --output -o)],
    'path del'                => [qw(--output -o)],
    'path rm'                 => [qw(--output -o)],
    'path list'               => [qw(--output -o)],
    paths                     => [qw(--output -o)],
    ps1                       => [qw(--jobs --cwd --mode --color --no-color --max-age --width --no-indicators --no-no-indicators)],
    'restart web'             => [qw(--output -o --host --port --workers --ssl --no-ssl)],
    'restart collector'       => [qw(--output -o --host --port --workers --ssl --no-ssl)],
    restart                   => [qw(--output -o --host --port --workers --ssl --no-ssl)],
    'stop web'                => [qw(--output -o --host --port --workers --ssl --no-ssl)],
    'stop collector'          => [qw(--output -o --host --port --workers --ssl --no-ssl)],
    stop                      => [qw(--output -o --host --port --workers --ssl --no-ssl)],
    'log web'                 => [qw(-f -n)],
    'log collector'           => [qw(-n)],
    log                       => [qw(-f -n)],
    'serve logs'              => [qw(-f -n)],
    'serve workers'           => [qw(--host --port)],
    serve                     => [qw(--host --port --workers --ssl --no-ssl --editor --no-editor --endit --no-endit --indicator --no-indicator --indicators --no-indicators --foreground --no-foreground)],
    'skills install'          => [qw(--ddfile --notest --branch -b --output -o)],
    'skills uninstall'        => [qw(--output -o)],
    'skills enable'           => [qw(--output -o)],
    'skills disable'          => [qw(--output -o)],
    'skills list'             => [qw(--output -o)],
    'skills usage'            => [qw(--output -o)],
    source                    => [qw(--files)],
    upgrade                   => [qw(--dry-run)],
    which                     => [qw(--edit --no-edit)],
    workspace                 => [qw(-c)],
    of                        => [qw(--print --no-print --line --editor --online --no-online)],
    'open-file'               => [qw(--print --no-print --line --editor --online --no-online)],
    cpan                      => [],
    'docker development'      => [],
    'serve workers'           => [qw(--host --port)],
);

# command_names()
# Returns the public names backed by managed internal CLI helpers.
# Input: none.
# Output: ordered list of canonical private helper names.
sub command_names {
    return ( Developer::Dashboard::InternalCLI::helper_names(), 'version' );
}

# overview_text()
# Renders the concise index shown for global help requests.
# Input: none.
# Output: newline-terminated overview containing every public command and its purpose.
sub overview_text {
    my $text = "Usage: dashboard <command> [arguments]\n\nAvailable built-in commands:\n";
    my @commands = command_names();
    for my $command ( sort @commands ) {
        my $spec = $COMMANDS{$command};
        $text .= "  $spec->{usage}\n    $spec->{description}\n";
    }
    $text .= "\nUse 'dashboard <command> --help' for command details and actions.\n";
    return $text;
}

# aliases()
# Returns the same compatibility aliases used by helper dispatch.
# Input: none.
# Output: hash reference mapping alias strings to canonical helper names.
sub aliases { return Developer::Dashboard::InternalCLI::helper_aliases() }

# actions_for($command)
# Returns supported public second-level actions for one command or nested path.
# Input: command name or space-separated parent/action path.
# Output: ordered list of action names.
sub actions_for {
    my ($command) = @_;
    return () if !defined $command || $command eq '';
    $command = _canonical_command($command);
    my $spec = $COMMANDS{$command} || return ();
    return () if ref($spec->{actions}) ne 'HASH';
    return @{ $ACTION_ORDER{$command} };
}

# options_for($command, $action)
# Returns option spellings accepted by a command or action.
# Input: command name and optional nested action name.
# Output: list of option tokens, including supported aliases and negated forms.
sub options_for {
    my ( $command, $action ) = @_;
    return () if !defined $command || $command eq '';
    my $name = _canonical_command($command);
    $name .= " $action" if defined $action && $action ne '';
    my @options = @{ $OPTIONS{$name} || [] };
    return ( @options, '-h', '--help' );
}

# help_text($command, $action)
# Renders concise, actionable help for one command or public subcommand.
# Input: command name and optional second-level action name.
# Output: UTF-8 help text ending in a newline, or dies for an unknown command/action.
sub help_text {
    my ( $command, $action ) = @_;
    die "Missing command name\n" if !defined $command || $command eq '';
    my $canonical = _canonical_command($command);
    if ( defined $action && $action ne '' ) {
        my $parent = "$canonical $action";
        my $nested = $COMMANDS{$parent};
        if ($nested) {
            return _render_root_help( $parent, $nested );
        }
        my $spec = $COMMANDS{$canonical} || die "Unknown dashboard command '$command'\n";
        my $entry = ref($spec->{actions}) eq 'HASH' ? $spec->{actions}{$action} : undef;
        die "Unknown action '$action' for dashboard command '$command'\n" if !$entry;
        return _render_action_help( $entry, $canonical, $action );
    }
    my $spec = $COMMANDS{$canonical} || die "Unknown dashboard command '$command'\n";
    return _render_root_help( $canonical, $spec );
}

# help_request(%args)
# Detects explicit help syntax before the requested command can run.
# Input: command name and argument array reference.
# Output: list of canonical command and optional action, or empty list when no help was requested.
sub help_request {
    my (%args) = @_;
    my $command = $args{command};
    my $argv = $args{args} || [];
    die "Help arguments must be an array reference\n" if ref($argv) ne 'ARRAY';
    return () if !defined $command || $command eq '';

    my @args = @{$argv};
    # Dotted skill commands re-enter this helper as "skills _exec <skill>
    # <command> ...". From _exec onward, arguments belong to the skill CLI,
    # including its own native help flags.
    return () if _canonical_command($command) eq 'skills'
      && @args
      && ( $args[0] // '' ) eq '_exec';

    my $help_index;
    for my $index ( 0 .. $#args ) {
        if ( defined $args[$index] && ( $args[$index] eq '--help' || $args[$index] eq '-h' ) ) {
            $help_index = $index;
            last;
        }
    }
    if ( defined $help_index ) {
        return () if _delegated_cli_owns_help( _canonical_command($command), \@args, $help_index );
        my @before = $help_index > 0 ? @args[ 0 .. $help_index - 1 ] : ();
        my @path = _leading_action_path(\@before);
        return _help_path( _canonical_command($command), \@path );
    }
    return () if !@args;
    if ( $args[0] eq 'help' ) {
        my @after_help = @args[ 1 .. $#args ];
        my @path = _leading_action_path(\@after_help);
        return _help_path( _canonical_command($command), \@path );
    }
    return () if $args[-1] ne 'help';
    return () if _delegated_cli_owns_help( _canonical_command($command), \@args, $#args );
    my @before = @args[ 0 .. $#args - 1 ];
    my @path = _leading_action_path(\@before);
    return _help_path( _canonical_command($command), \@path, 'trailing-help' );
}

# _delegated_cli_owns_help($command, $args, $help_index)
# Detects help tokens that occur after argument parsing has crossed into a
# delegated external CLI, even when Dashboard wrapper options precede it.
# Input: canonical Dashboard command, argument array reference, and the index
# of an explicit --help/-h or trailing literal help token.
# Output: true when the external CLI must receive the help request.
sub _delegated_cli_owns_help {
    my ( $command, $args, $help_index ) = @_;
    return 0 if ref($args) ne 'ARRAY' || !defined $help_index || $help_index < 0;

    my $spec = $COMMANDS{$command} || {};
    if ( ref( $spec->{passthrough_actions} ) eq 'HASH' ) {
        for my $index ( 0 .. $help_index - 1 ) {
            return 1 if $spec->{passthrough_actions}{ $args->[$index] || '' };
        }
    }

    my $compose = $COMMANDS{"$command compose"};
    # The catalog only has one <command> compose entry: Docker Compose. Its
    # passthrough contract is defined directly in that catalog entry.
    return 0 if !$compose;
    return 0 if !@{$args} || $args->[0] ne 'compose';

    my $index = 1;
    while ( $index < $help_index ) {
        my $argument = $args->[$index] // '';
        if ( $argument =~ /\A--(?:addon|mode|service|project)\z/ ) {
            # Dashboard's Compose wrapper consumes these selectors and their
            # separate values. A help token before any Docker command remains
            # Dashboard help even when selectors were supplied.
            $index += 2;
            next;
        }
        if ( $argument =~ /\A--(?:addon|mode|service|project)=/ || $argument eq '--dry-run' || $argument eq '--no-dry-run' ) {
            $index++;
            next;
        }
        # Any remaining token is part of Docker Compose's own argv. Forward
        # later help markers unchanged rather than substituting wrapper help.
        return 1;
    }
    return 0;
}

# _leading_action_path($args)
# Extracts leading positional action names without mistaking option values for actions.
# Input: array reference of arguments preceding an explicit help marker.
# Output: ordered leading positional tokens before the first option.
sub _leading_action_path {
    my ($args) = @_;
    return () if ref($args) ne 'ARRAY';
    my @path;
    for my $argument ( @{$args} ) {
        last if !defined $argument || $argument =~ /^-/;
        push @path, $argument if $argument ne '';
    }
    return @path;
}

# _help_path($command, $path, $marker)
# Resolves the public action path preceding a help token into a catalog key.
# Input: canonical command string, array reference of positional names, and
# optional marker kind identifying a literal trailing "help" token.
# Output: canonical command plus optional action, the containing command for
# an empty path, or an empty list when a delegated CLI owns the help request.
sub _help_path {
    my ( $command, $path, $marker ) = @_;
    return ( $command, undef ) if !$path || !@{$path};
    my $spec = $COMMANDS{$command} || {};
    return () if ref($spec->{passthrough_actions}) eq 'HASH'
      && $spec->{passthrough_actions}{ $path->[0] };
    if ( @{$path} > 1 ) {
        my $nested = "$command $path->[0]";
        if ( exists $COMMANDS{$nested} ) {
            return () if $COMMANDS{$nested}{passthrough_arguments};
            return ( $nested, $path->[1] ) if exists $COMMANDS{$nested}{actions}{ $path->[1] };
            return ( $command, $path->[0] );
        }
    }
    if ( $marker && $marker eq 'trailing-help' && @{$path} == 1 ) {
        my $nested = "$command $path->[0]";
        return () if $COMMANDS{$nested} && $COMMANDS{$nested}{passthrough_arguments};
    }
    return ( $command, $path->[0] );
}

# _canonical_command($command)
# Resolves helper aliases and nested help namespaces to their canonical metadata key.
# Input: public command or namespace string.
# Output: canonical metadata key.
sub _canonical_command {
    my ($command) = @_;
    return '' if !defined $command || $command !~ /\S/;
    my $helper = Developer::Dashboard::InternalCLI::canonical_helper_name($command);
    return $helper if $helper ne '';
    return $command if exists $COMMANDS{$command};
    my @parts = split /\s+/, $command;
    my $base = Developer::Dashboard::InternalCLI::canonical_helper_name( $parts[0] );
    $base = $parts[0] if $base eq '';
    return join ' ', $base, @parts[ 1 .. $#parts ] if @parts > 1;
    return $base;
}

# _render_root_help($name, $spec)
# Renders command synopsis, description, options, and known actions.
# Input: canonical help name and command specification hash reference.
# Output: formatted help text string.
sub _render_root_help {
    my ( $name, $spec ) = @_;
    my $text = "Usage: $spec->{usage}\n\n$spec->{description}\n";
    if ( $spec->{options} && @{ $spec->{options} } ) {
        $text .= "\nOptions:\n";
        $text .= "  $_\n" for @{ $spec->{options} };
    }
    else {
        my @options = options_for($name);
        my %seen;
        @options = grep { $_ ne '-h' && $_ ne '--help' && !$seen{$_}++ } @options;
        if (@options) {
            $text .= "\nOptions:\n";
            $text .= "  $_\n" for @options;
        }
    }
    my @actions = actions_for($name);
    if (@actions) {
        $text .= "\nActions:\n";
        for my $action (@actions) {
            my $entry = $spec->{actions}{$action};
            $text .= "  $entry->[0]\n    $entry->[1]\n";
            my $nested_name = "$name $action";
            my $nested = $COMMANDS{$nested_name};
            if ($nested) {
                for my $nested_action ( actions_for($nested_name) ) {
                    my $nested_entry = $nested->{actions}{$nested_action};
                    $text .= "    $nested_entry->[0]\n      $nested_entry->[1]\n";
                }
            }
        }
    }
    $text .= "\nHelp: dashboard $name --help | dashboard $name help\n";
    return $text;
}

# _render_action_help($entry, $command, $action)
# Renders one subcommand synopsis, purpose, and accepted options.
# Input: two-element usage/description array reference, command, and action name.
# Output: formatted help text string.
sub _render_action_help {
    my ( $entry, $command, $action ) = @_;
    my $name = "$command $action";
    my $text = "Usage: $entry->[0]\n\n$entry->[1]\n";
    my @options = options_for( $command, $action );
    my %seen;
    @options = grep { $_ ne '-h' && $_ ne '--help' && !$seen{$_}++ } @options;
    if (@options) {
        $text .= "\nOptions:\n";
        $text .= "  $_\n" for @options;
    }
    return $text . "\nHelp: dashboard $name --help | dashboard $name help\n";
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::Help - canonical command help and action metadata

=head1 PURPOSE

Provides the shared command catalog used to render explicit help and to keep
shell-completion subcommands aligned with private CLI dispatch.

=head1 WHY IT EXISTS

Help and completion had been maintained in unrelated places, leaving commands
without actionable help and valid actions out of TAB suggestions. This module
holds one tested inventory for built-in helpers, the switchboard's direct
C<version> command, compatibility aliases, nested actions, and concise synopsis
text.

=head1 WHEN TO USE

Use this module when adding a managed internal command, an actionable
subcommand, a compatibility alias, or changing the public CLI syntax.

=head1 HOW TO USE

  my $help = Developer::Dashboard::CLI::Help::help_text('docker', 'compose');
  my @actions = Developer::Dashboard::CLI::Help::actions_for('path');
  my @options = Developer::Dashboard::CLI::Help::options_for('api', 'add');
  my @request = Developer::Dashboard::CLI::Help::help_request(
      command => 'api', args => ['--help'],
  );
  my $overview = Developer::Dashboard::CLI::Help::overview_text();

The help request result is empty when the arguments do not explicitly ask for
help or when a delegated command owns the request, even if Dashboard wrapper
options precede the delegated command; otherwise it contains the
canonical command and an optional action name. In particular,
C<dashboard of grep --help> and C<dashboard docker compose config --help>
leave their trailing help options with grep or Docker Compose. That ownership
is preserved when C<of --print> or Docker Compose selectors occur before the
delegated command. Dotted skill invocations enter the private C<skills _exec>
dispatch; help detection stops there so a skill CLI receives its own C<-h> or
C<--help> unchanged. The built-in Compose synopsis remains available as
C<dashboard docker compose --help> or C<dashboard help docker compose>.

=head1 WHAT USES IT

The public switchboard and private helper dispatcher call this module before
running built-in operations. C<Developer::Dashboard::CLI::Complete> uses the
action and option catalogs to generate TAB candidates for commands, nested
actions, flags, and targets following global help.

=head1 EXAMPLES

  dashboard api --help
  dashboard path cdr --help
  dashboard of --print grep --help
  dashboard docker compose config --help
  dashboard docker compose --service dev exec dev docker --help
  dashboard of grep --help
  dashboard help docker development
  dashboard complete 3 dashboard api add -
  prove -lv t/265-cli-help-completion-contract.t

=cut
