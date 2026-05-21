package Developer::Dashboard::CLI::RuntimeControl;

use strict;
use warnings;

our $VERSION = '3.90';

use Getopt::Long qw(GetOptionsFromArray);

use Developer::Dashboard::CLI::Progress;
use Developer::Dashboard::JSON qw(json_encode);

# run_runtime_command(%args)
# Dispatches the shared dashboard runtime control commands for restart, stop,
# log, and logs.
# Input: command name, argv array reference, runtime manager, config object,
# and collector store.
# Output: numeric process exit code after printing the requested output.
sub run_runtime_command {
    my (%args) = @_;
    my $command    = $args{command}    || die "Missing runtime control command\n";
    my $argv       = $args{args}       || die "Missing runtime control argv\n";
    my $runtime    = $args{runtime}    || die "Missing runtime manager\n";
    my $config     = $args{config}     || die "Missing runtime config\n";
    my $collectors = $args{collectors} || die "Missing collector store\n";
    die "Runtime control argv must be an array reference\n" if ref($argv) ne 'ARRAY';

    return _run_log_command(
        command    => $command,
        args       => $argv,
        runtime    => $runtime,
        config     => $config,
        collectors => $collectors,
    ) if $command eq 'log' || $command eq 'logs';

    return _run_lifecycle_command(
        command => $command,
        args    => $argv,
        runtime => $runtime,
        config  => $config,
    ) if $command eq 'restart' || $command eq 'stop';

    die "Unsupported runtime control command '$command'\n";
}

# _run_lifecycle_command(%args)
# Parses one restart or stop request, runs the scoped lifecycle action, and
# renders the final summary.
# Input: command name, argv array reference, runtime manager, and config object.
# Output: numeric process exit code.
sub _run_lifecycle_command {
    my (%args) = @_;
    my $command = $args{command};
    my @argv = @{ $args{args} };
    my $runtime = $args{runtime};
    my $config  = $args{config};

    my $scope = 'all';
    $scope = shift @argv if @argv && $argv[0] !~ /^-/ && $argv[0] =~ /\A(?:web|collector)\z/;

    my $target;
    if ( $scope eq 'collector' && @argv && $argv[0] !~ /^-/ ) {
        $target = shift @argv;
    }

    my $output  = 'table';
    my $host    = $config->web_settings->{host};
    my $port    = $config->web_settings->{port};
    my $workers = $config->web_settings->{workers};
    my $ssl     = $config->web_settings->{ssl};

    GetOptionsFromArray(
        \@argv,
        'o|output=s' => \$output,
        'host=s'     => \$host,
        'port=i'     => \$port,
        'workers=i'  => \$workers,
        'ssl!'       => \$ssl,
    );

    die _lifecycle_usage($command) if $output ne 'json' && $output ne 'table';
    die _lifecycle_usage($command) if @argv;
    die "Collector name is required after '$command collector'\n" if $scope eq 'collector' && defined $target && $target eq '';

    my $progress = _lifecycle_progress(
        title => "dashboard $command progress",
        tasks => $command eq 'restart'
          ? $runtime->restart_progress_tasks( scope => $scope, name => $target )
          : $runtime->stop_progress_tasks( scope => $scope, name => $target ),
    );

    my $result = $command eq 'restart'
      ? $runtime->restart_target(
        scope    => $scope,
        name     => $target,
        host     => $host,
        port     => $port,
        workers  => $workers,
        ssl      => $ssl,
        progress => $progress ? $progress->callback : undef,
      )
      : $runtime->stop_target(
        scope    => $scope,
        name     => $target,
        progress => $progress ? $progress->callback : undef,
      );
    $progress->finish if $progress;

    if ( $output eq 'json' ) {
        print json_encode($result);
    }
    else {
        print _lifecycle_summary_table($result);
    }
    return 0;
}

# _run_log_command(%args)
# Parses one top-level dashboard log or logs request and prints the requested
# log stream.
# Input: command name, argv array reference, runtime manager, config object,
# and collector store.
# Output: numeric process exit code.
sub _run_log_command {
    my (%args) = @_;
    my @argv = @{ $args{args} };
    my $runtime    = $args{runtime};
    my $config     = $args{config};
    my $collectors = $args{collectors};

    my $scope = @argv && $argv[0] !~ /^-/ ? shift @argv : 'all';
    my $name;
    if ( $scope eq 'collector' && @argv && $argv[0] !~ /^-/ ) {
        $name = shift @argv;
    }

    my $follow = 0;
    my $lines;
    GetOptionsFromArray(
        \@argv,
        'f'   => \$follow,
        'n=i' => \$lines,
    );
    die _log_usage() if @argv;
    die _log_usage() if $scope !~ /\A(?:all|web|collector)\z/;

    if ( $scope eq 'web' ) {
        print $runtime->web_log(
            follow => $follow,
            ( defined $lines ? ( lines => $lines ) : () ),
        );
        return 0;
    }

    die "Follow mode is only supported for dashboard log web\n" if $follow;

    if ( $scope eq 'collector' ) {
        print _collector_logs_text(
            collectors => $collectors,
            config     => $config,
            name       => $name,
        );
        return 0;
    }

    my $web_log = $runtime->web_log( ( defined $lines ? ( lines => $lines ) : () ) );
    my $collector_log = _collector_logs_text(
        collectors => $collectors,
        config     => $config,
    );
    my @parts;
    push @parts, "=== dashboard web ===\n$web_log" if defined $web_log && $web_log ne '';
    push @parts, $collector_log if defined $collector_log && $collector_log ne '';
    print join "\n", @parts;
    return 0;
}

# _collector_logs_text(%args)
# Builds the collector log text for top-level dashboard log/logs commands.
# Input: collector store, config object, and optional collector name.
# Output: log text string or dies for unknown named collectors.
sub _collector_logs_text {
    my (%args) = @_;
    my $collectors = $args{collectors};
    my $config     = $args{config};
    my $name       = $args{name};

    if ( defined $name && $name ne '' ) {
        die "Unknown collector '$name'\n" if !_collector_known( $collectors, $config, $name );
        my $log = $collectors->read_log($name);
        return "No log entries are available yet for collector '$name'.\n"
          if !defined $log || $log eq '';
        return $log;
    }

    my @names = _known_collector_names( $collectors, $config );
    return "No collector logs are available yet.\n" if !@names;

    my @logs;
    for my $collector_name (@names) {
        my $log = $collectors->read_log($collector_name);
        $log = "No log entries are available yet for collector '$collector_name'.\n"
          if !defined $log || $log eq '';
        push @logs, $log;
    }
    return join "\n", @logs;
}

# _known_collector_names($collectors, $config)
# Returns the stable union of configured and persisted collector names.
# Input: collector store and config object.
# Output: ordered list of collector name strings.
sub _known_collector_names {
    my ( $collectors, $config ) = @_;
    my %seen;
    my @names;
    for my $job ( @{ $config->collectors } ) {
        my $name = ref($job) eq 'HASH' ? $job->{name} : undef;
        next if !defined $name || $name eq '' || $seen{$name}++;
        push @names, $name;
    }
    for my $status ( $collectors->list_collectors ) {
        my $name = ref($status) eq 'HASH' ? $status->{name} : undef;
        next if !defined $name || $name eq '' || $seen{$name}++;
        push @names, $name;
    }
    return @names;
}

# _collector_known($collectors, $config, $name)
# Returns whether one collector exists in config or persisted runtime state.
# Input: collector store, config object, and collector name string.
# Output: boolean true when the collector exists.
sub _collector_known {
    my ( $collectors, $config, $name ) = @_;
    return 0 if !defined $name || $name eq '';
    return 1 if grep { ref($_) eq 'HASH' && ( $_->{name} || '' ) eq $name } @{ $config->collectors };
    return $collectors->collector_exists($name) ? 1 : 0;
}

# _lifecycle_progress(%args)
# Builds the optional progress board for dashboard restart and stop commands.
# Input: title string and ordered task array reference.
# Output: Developer::Dashboard::CLI::Progress object or undef.
sub _lifecycle_progress {
    my (%args) = @_;
    my $enabled = $ENV{DEVELOPER_DASHBOARD_PROGRESS} ? 1 : 0;
    return if !$enabled && !-t STDERR;
    return Developer::Dashboard::CLI::Progress->new(
        title   => $args{title} || 'dashboard progress',
        tasks   => $args{tasks} || [],
        stream  => \*STDERR,
        dynamic => ( -t STDERR ? 1 : 0 ),
        color   => ( -t STDERR ? 1 : 0 ),
    );
}

# _lifecycle_summary_table($result)
# Renders one runtime stop or restart result as the default terminal summary table.
# Input: runtime result hash reference.
# Output: formatted multi-line table text.
sub _lifecycle_summary_table {
    my ($result) = @_;
    my @rows;
    if ( my $web = $result->{web} ) {
        push @rows, [
            'web',
            'dashboard',
            $web->{status} || '-',
            defined $web->{pid} ? $web->{pid} : '-',
            $web->{details} || '-',
        ];
    }
    for my $collector ( @{ $result->{collectors} || [] } ) {
        push @rows, [
            'collector',
            $collector->{name} || '-',
            $collector->{status} || '-',
            defined $collector->{pid} ? $collector->{pid} : '-',
            $collector->{details} || '-',
        ];
    }
    return _render_table( [ 'Component', 'Target', 'Status', 'PID', 'Details' ], \@rows );
}

# _render_table($header, $rows)
# Formats a rectangular dataset as a padded terminal table.
# Input: header array reference and row array reference.
# Output: formatted table string.
sub _render_table {
    my ( $header, $rows ) = @_;
    my @widths;
    for my $row ( $header, @{$rows} ) {
        for my $index ( 0 .. $#{$row} ) {
            my $value = defined $row->[$index] ? $row->[$index] : '';
            my $length = length $value;
            $widths[$index] = $length if !defined $widths[$index] || $length > $widths[$index];
        }
    }
    my @lines = (
        _pad_row( $header, \@widths ),
        _pad_row( [ map { '-' x $widths[$_] } 0 .. $#widths ], \@widths ),
    );
    push @lines, map { _pad_row( $_, \@widths ) } @{$rows};
    return join( "\n", @lines ) . "\n";
}

# _pad_row($row, $widths)
# Pads one table row to the configured column widths.
# Input: row array reference and widths array reference.
# Output: padded row string.
sub _pad_row {
    my ( $row, $widths ) = @_;
    return join '  ', map {
        my $value = defined $row->[$_] ? $row->[$_] : '';
        sprintf "%-*s", $widths->[$_], $value;
    } 0 .. $#{$widths};
}

# _lifecycle_usage($command)
# Returns the user-facing usage text for dashboard restart and stop.
# Input: command name string.
# Output: usage text string.
sub _lifecycle_usage {
    my ($command) = @_;
    return "Usage: dashboard $command [web|collector [name]] [-o json|table] [--host <host>] [--port <port>] [--workers <count>] [--ssl|--no-ssl]\n";
}

# _log_usage()
# Returns the user-facing usage text for dashboard log and logs.
# Input: none.
# Output: usage text string.
sub _log_usage {
    return "Usage: dashboard log[s] [web|collector [name]] [-n <lines>] [-f]\n";
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::RuntimeControl - shared restart, stop, and log command runtime for Developer Dashboard

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::RuntimeControl;
  Developer::Dashboard::CLI::RuntimeControl::run_runtime_command(
      command    => 'restart',
      args       => \@ARGV,
      runtime    => $runtime,
      config     => $config,
      collectors => $collectors,
  );

=head1 DESCRIPTION

Owns the command parsing and default human-facing output for the built-in
runtime control commands: C<dashboard restart>, C<dashboard stop>,
C<dashboard log>, and C<dashboard logs>.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module centralizes the public runtime-control command contract so restart,
stop, and log flows stay thin in the staged helper runtime while still sharing
one consistent parser, progress board hookup, JSON mode, and default summary
table behavior.

=head1 WHY IT EXISTS

It exists because restart and stop now need scoped variants such as
C<dashboard restart web> and C<dashboard stop collector NAME>, and those flows
should not be duplicated inside the private switchboard. Keeping the logic here
makes the contract testable and keeps the thin helper loader honest.

=head1 WHEN TO USE

Use this file when changing the public restart/stop/log CLI verbs, scoped
lifecycle semantics, progress board wiring, or the default summary table
printed after runtime-control commands finish.

=head1 HOW TO USE

Call C<run_runtime_command> with the command name, raw argv array reference,
runtime manager, config object, and collector store. The helper parses the
scope, optional collector target, lifecycle flags, and output mode, then
prints either JSON or a terminal table.

=head1 WHAT USES IT

It is used by the private C<_dashboard-core> helper for top-level lifecycle and
log commands, by CLI smoke tests that pin public operator behavior, and by
runtime-manager tests that verify scoped restart and stop progress plans.

=head1 EXAMPLES

  dashboard restart
  dashboard restart web --port 7901
  dashboard restart collector housekeeper -o json
  dashboard stop collector
  dashboard log
  dashboard log collector alpha.collector
  dashboard log web -n 50

=for comment FULL-POD-DOC END

=cut
