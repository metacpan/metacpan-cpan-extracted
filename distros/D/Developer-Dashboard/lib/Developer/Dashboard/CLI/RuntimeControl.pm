package Developer::Dashboard::CLI::RuntimeControl;

use strict;
use warnings;

our $VERSION = '6.06';

use Getopt::Long qw(GetOptionsFromArray);
use Time::HiRes qw(sleep);

use Developer::Dashboard::CLI::Progress;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::TimeUtils qw(_now_iso8601);

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
        command    => $command,
        args       => $argv,
        runtime    => $runtime,
        config     => $config,
        collectors => $collectors,
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
    my $collectors = $args{collectors} || die "Missing collector store\n";

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
    # $target is already guaranteed non-empty here whenever it is defined and
    # scope is 'collector' - the die immediately above this one exits first
    # for the empty-string case, so an extra `$target ne ''` check here would
    # be permanently-true dead weight rather than a real guard.
    die "Unknown collector '$target'\n"
      if $scope eq 'collector' && defined $target
      && !_collector_known( $collectors, $config, $target );

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
# log stream, optionally timestamped, followed, or limited to trailing lines.
# Input: command name, argv array reference, runtime manager, config object,
# and collector store.
# Output: numeric process exit code.
sub _run_log_command {
    my (%args) = @_;
    my @argv = @{ $args{args} };
    my $runtime    = $args{runtime};
    my $config     = $args{config};
    my $collectors = $args{collectors};

    my $follow = 0;
    my $timestamps = 0;
    my $lines;
    my $options_ok = GetOptionsFromArray(
        \@argv,
        'f'        => \$follow,
        't'        => \$timestamps,
        'tail|n=i' => \$lines,
    );
    die _log_usage() if !$options_ok;
    die _log_usage() if defined $lines && $lines < 0;

    my $scope = @argv && $argv[0] !~ /^-/ ? shift @argv : 'all';
    my $name;
    if ( $scope eq 'collector' && @argv && $argv[0] !~ /^-/ ) {
        $name = shift @argv;
    }

    die _log_usage() if @argv;
    die _log_usage() if $scope !~ /\A(?:all|web|collector)\z/;

    my $sources = _read_log_sources(
        scope      => $scope,
        name       => $name,
        runtime    => $runtime,
        config     => $config,
        collectors => $collectors,
    );
    my $output = _render_log_sources( $sources, $scope, $name );
    $output = _timestamp_log_text($output) if $timestamps;
    $output = _tail_log_text( $output, $lines ) if defined $lines;
    print $output;
    _follow_log_sources(
        sources     => $sources,
        scope       => $scope,
        name        => $name,
        runtime     => $runtime,
        config      => $config,
        collectors  => $collectors,
        timestamps  => $timestamps,
    ) if $follow;
    return 0;
}

# _read_log_sources(%args)
# Reads each selected log independently so follow mode can poll web and
# collector streams without blocking on one source. Input: scope, optional
# collector name, runtime, config, and collector store. Output: source-keyed
# hash reference containing the current complete text for each selected log.
sub _read_log_sources {
    my (%args) = @_;
    my $scope = $args{scope};
    my %sources;
    $sources{web} = $args{runtime}->web_log if $scope eq 'web' || $scope eq 'all';
    return \%sources if $scope eq 'web';

    my @names;
    if ( defined $args{name} ) {
        die "Unknown collector '$args{name}'\n"
          if !_collector_known( $args{collectors}, $args{config}, $args{name} );
        @names = ( $args{name} );
    }
    else {
        @names = _known_collector_names( $args{collectors}, $args{config} );
    }
    for my $collector_name (@names) {
        my $text = $args{collectors}->read_log($collector_name);
        $sources{"collector:$collector_name"} = defined $text ? $text : '';
    }
    return \%sources;
}

# _render_log_sources($sources, $scope, $name)
# Renders the current snapshot in the existing non-follow command layout.
# Input: source snapshot, selected scope, and optional collector name. Output:
# combined or scoped human-readable log text.
sub _render_log_sources {
    my ( $sources, $scope, $name ) = @_;
    if ( $scope eq 'web' ) {
        return defined $sources->{web} ? $sources->{web} : '';
    }
    if ( $scope eq 'collector' ) {
        if ( defined $name ) {
            my $text = $sources->{"collector:$name"} // '';
            return $text ne '' ? $text : "No log entries are available yet for collector '$name'.\n";
        }
        my @names = sort map { s/^collector://r } grep { /^collector:/ } keys %$sources;
        return "No collector logs are available yet.\n" if !@names;
        my @logs = map {
            my $text = $sources->{"collector:$_"} // '';
            $text ne '' ? $text : "No log entries are available yet for collector '$_'.\n"
        } @names;
        return join "\n", @logs;
    }
    my @parts;
    my $web_log = $sources->{web};
    push @parts, "=== dashboard web ===\n$web_log" if defined $web_log && $web_log ne '';
    my @names = sort map { s/^collector://r } grep { /^collector:/ } keys %$sources;
    my $collector_log = @names
      ? join "\n", map {
          my $text = $sources->{"collector:$_"} // '';
          $text ne '' ? $text : "No log entries are available yet for collector '$_'.\n"
        } @names
      : "No collector logs are available yet.\n";
    push @parts, $collector_log;
    return join "\n", @parts;
}

# _follow_log_sources(%args)
# Polls selected source snapshots and writes only appended content until the
# process receives a normal termination signal. Input: initial snapshots,
# scope, optional collector name, and the source readers. Output: streamed
# stdout; returns only if the process is externally interrupted by an exception.
sub _follow_log_sources {
    my (%args) = @_;
    my %offset = map { $_ => length( $args{sources}{$_} // '' ) } keys %{ $args{sources} };
    my $old_stdout = select STDOUT;
    $| = 1;
    select $old_stdout;
    while (1) {
        sleep 0.1;
        my $current = _read_log_sources(
            scope      => $args{scope},
            name       => $args{name},
            runtime    => $args{runtime},
            config     => $args{config},
            collectors => $args{collectors},
        );
        for my $source ( _sort_log_source_names( keys %$current ) ) {
            my $text = $current->{$source} // '';
            my $old_offset = $offset{$source} // 0;
            $old_offset = 0 if length($text) < $old_offset;
            my $new_text = substr( $text, $old_offset );
            if ( $new_text ne '' ) {
                $new_text = _timestamp_log_text($new_text) if $args{timestamps};
                print $new_text;
            }
            $offset{$source} = length $text;
        }
    }
}

# _sort_log_source_names(@sources)
# Orders snapshot source names with the web stream first and collector streams
# in lexical order. Input: list of source-name strings. Output: ordered list.
sub _sort_log_source_names {
    my @sources = @_;
    return sort {
        my $a_web = $a eq 'web' ? 0 : 1;
        my $b_web = $b eq 'web' ? 0 : 1;
        my $priority = $a_web <=> $b_web;
        return $priority if $priority != 0;
        return $a cmp $b;
    } @sources;
}

# _timestamp_log_text($text)
# Prefixes every output line with a UTC timestamp; collector record lines use
# their persisted event timestamp when one is present, while raw web output is
# stamped at the time it is read. Input: log text string. Output: timestamped
# log text preserving each original line ending.
sub _timestamp_log_text {
    my ($text) = @_;
    return '' if !defined $text || $text eq '';
    my $fallback = _now_iso8601( tz => 'utc' );
    my $record_time = $fallback;
    my @lines = split /(?<=\n)/, $text, -1;
    pop @lines if $lines[-1] eq '';
    my $out = '';
    for my $line (@lines) {
        if ( $line =~ /^=== collector \S+ \| \@ (\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:Z|[+-]\d{4}))\b/ ) {
            $record_time = $1;
        }
        $out .= $record_time . ' ' . $line;
    }
    return $out;
}

# _tail_log_text($text, $lines)
# Returns the last requested number of complete output lines.
# Input: log text string and a non-negative integer line count.
# Output: the trailing log text, preserving whether it ended in a newline.
sub _tail_log_text {
    my ( $text, $lines ) = @_;
    return '' if !defined $text || $text eq '' || $lines == 0;

    my @parts = split /\n/, $text, -1;
    my $had_trailing_newline = $parts[-1] eq '' ? 1 : 0;
    pop @parts if $had_trailing_newline;
    my $start = @parts - $lines;
    $start = 0 if $start < 0;
    my @tail_parts = @parts[ $start .. $#parts ];
    my $tail = join "\n", @tail_parts;
    $tail .= "\n" if $had_trailing_newline;
    return $tail;
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

# _stderr_is_tty()
# Reports whether STDERR is attached to a terminal.
# Input: none.
# Output: true when STDERR is a controlling terminal, false otherwise.
sub _stderr_is_tty {
    return -t STDERR;
}

# _lifecycle_progress(%args)
# Builds the optional progress board for dashboard restart and stop commands.
# Input: title string and ordered task array reference.
# Output: Developer::Dashboard::CLI::Progress object or undef.
sub _lifecycle_progress {
    my (%args) = @_;
    my $enabled = $ENV{DEVELOPER_DASHBOARD_PROGRESS} ? 1 : 0;
    # The terminal probe goes through _stderr_is_tty so tests can drive both
    # the interactive and the non-interactive path deterministically.
    my $tty = _stderr_is_tty();
    return if !$enabled && !$tty;
    my $interactive = $tty ? 1 : 0;
    return Developer::Dashboard::CLI::Progress->new(
        title   => $args{title} || 'dashboard progress',
        tasks   => $args{tasks} || [],
        stream  => \*STDERR,
        dynamic => $interactive,
        color   => $interactive,
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
    return "Usage: dashboard log[s] [-t] [-f] [web|collector [name]] [--tail <lines>|--tail=<lines>] [-n <lines>]\n";
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

Log commands accept C<--tail N> and C<--tail=N> to limit the printed output to
the last N lines. C<-n N> remains an alias. The limit applies to the selected
web or collector stream; with the default combined scope, it applies to the
final combined output. A count of zero prints no lines. Negative and malformed
counts are rejected with usage text. C<-t> prefixes log lines with UTC
timestamps; collector entries use their recorded event time and raw web output
uses the time it is read. C<-f> follows newly appended lines in web, collector,
or combined scope; when combined, it polls both sources without blocking on one.
Follow output places the web stream first, then collector streams alphabetically.

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
  dashboard logs --tail 100
  dashboard logs --tail=100
  dashboard log -t web -n 20 -f
  dashboard log -t collector alpha.collector --tail=50
  dashboard logs -f --tail=20
  dashboard log web -n 50

=for comment FULL-POD-DOC END

=cut
