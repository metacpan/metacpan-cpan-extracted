package Developer::Dashboard::RuntimeManager;

use strict;
use warnings;

our $VERSION = '2.26';

use Capture::Tiny qw(capture);
use File::Spec;
use POSIX qw(setsid strftime);
use Time::HiRes qw(sleep time);

use Developer::Dashboard::JSON qw(json_encode json_decode);

our $SIGNAL_MANAGER;

# new(%args)
# Constructs the runtime lifecycle manager.
# Input: config, files, paths, runner, and app_builder objects/callbacks.
# Output: Developer::Dashboard::RuntimeManager object.
sub new {
    my ( $class, %args ) = @_;
    my $config      = $args{config}      || die 'Missing config';
    my $files       = $args{files}       || die 'Missing file registry';
    my $paths       = $args{paths}       || die 'Missing path registry';
    my $runner      = $args{runner}      || die 'Missing collector runner';
    my $app_builder = $args{app_builder} || die 'Missing app builder';

    return bless {
        app_builder => $app_builder,
        config      => $config,
        files       => $files,
        paths       => $paths,
        runner      => $runner,
    }, $class;
}

# start_web(%args)
# Starts the dashboard web service in foreground or background mode.
# Input: host, port, worker count, ssl flag, and foreground options.
# Output: server return value in foreground mode or child pid in background mode.
sub start_web {
    my ( $self, %args ) = @_;
    my $host = '0.0.0.0';
    if ( defined $args{host} ) {
        $host = $args{host};
    }
    my $port = 7890;
    if ( defined $args{port} ) {
        $port = $args{port};
    }
    my $workers = 1;
    if ( defined $args{workers} ) {
        $workers = $args{workers};
    }
    my $ssl = $args{ssl} ? 1 : 0;
    die 'Worker count must be a positive integer' if $workers !~ /^\d+$/ || $workers < 1;
    my $foreground = $args{foreground} ? 1 : 0;

    if ($foreground) {
        my $server = $self->{app_builder}->( host => $host, port => $port, workers => $workers, ssl => $ssl );
        return $server->run;
    }

    my $running = $self->running_web;
    return $running->{pid}
      if $running
      && $running->{host} eq $host
      && $running->{port} == $port
      && ( ( $running->{workers} || 1 ) == $workers )
      && ( ( $running->{ssl} || 0 ) == $ssl );

    $self->_cleanup_web_files;

    pipe my $reader, my $writer or die "Unable to create startup pipe: $!";
    my $pid = fork();
    die "Unable to fork dashboard web service: $!" if !defined $pid;

    if ($pid) {
        close $writer;
        my $line = <$reader>;
        close $reader;
        die "Unable to start dashboard web service\n" if !defined $line;
        chomp $line;
        die "$line\n" if $line =~ /^err:/;
        my ( undef, $started_pid, $bound_host, $bound_port ) = split /\|/, $line, 4;
        my $state = {
            host         => $host,
            pid          => $started_pid,
            port         => $bound_port + 0,
            process_name => $self->_web_process_title( $host, $port ),
            started_at   => _now_iso8601(),
            status       => 'running',
            bound_host   => $bound_host,
            workers      => $workers + 0,
            ssl          => $ssl + 0,
        };
        $self->{files}->write( 'web_pid', "$started_pid\n" );
        $self->_write_web_state($state);
        return $started_pid;
    }

    close $reader;
    exit $self->_run_web_child( $writer, $host, $port, workers => $workers, ssl => $ssl );
}

# running_web()
# Discovers the currently running managed web service if present.
# Input: none.
# Output: web state hash reference or undef.
sub running_web {
    my ($self) = @_;

    my $state = $self->web_state || {};
    if ( my $pid = $self->{files}->read('web_pid') ) {
        chomp $pid;
        if ( $pid && kill 0, $pid ) {
            if ( $self->_is_managed_web($pid) || ( $state->{status} || '' ) eq 'running' ) {
                return {
                    %$state,
                    pid => $pid + 0,
                };
            }
        }
    }

    for my $proc ( $self->_find_web_processes ) {
        if ( $proc->{args} =~ /^dashboard web:\s+(\S+):(\d+)$/ ) {
            return {
                %$state,
                pid          => $proc->{pid},
                host         => $1,
                port         => $2 + 0,
                process_name => $proc->{args},
                status       => 'running',
            };
        }

        return {
            %$state,
            pid          => $proc->{pid},
            host         => $state->{host} || '0.0.0.0',
            port         => $state->{port} || 7890,
            process_name => $proc->{args},
            status       => 'running',
        };
    }

    $self->_cleanup_web_files;
    return;
}

# stop_web()
# Stops the managed web service, including older compatible process shapes.
# Input: none.
# Output: stopped pid or undef.
sub stop_web {
    my ($self) = @_;
    my $running = $self->running_web;
    my $pid = $running ? $running->{pid} : undef;
    my $port = $running ? $running->{port} : undef;
    my @listener_pids = $running && $running->{port}
      ? $self->_listener_pids_for_port( $running->{port} )
      : ();

    kill 'TERM', $pid if $pid;
    kill 'TERM', $_ for @listener_pids;
    $self->_pkill_perl('^dashboard web:');
    $self->_pkill_perl('^dashboard ajax:');
    for my $proc ( $self->_find_legacy_web_processes ) {
        kill 'TERM', $proc->{pid};
    }
    for ( 1 .. 30 ) {
        last if !$self->running_web && !scalar $self->_find_processes_by_prefix('dashboard ajax:');
        sleep 0.1;
    }

    my $still_running = $self->running_web;
    if ($still_running) {
        kill 'KILL', $still_running->{pid};
        sleep 0.1;
    }
    for my $proc ( $self->_find_processes_by_prefix('dashboard ajax:') ) {
        kill 'KILL', $proc->{pid};
    }
    my @still_listening = grep { kill 0, $_ } @listener_pids;
    kill 'KILL', $_ for @still_listening;
    for my $proc ( $self->_find_legacy_web_processes ) {
        kill 'KILL', $proc->{pid};
    }
    my $released = $self->_wait_for_port_release($port);
    if ( !$released && $port ) {
        my @late_listeners = grep { kill 0, $_ } $self->_listener_pids_for_port($port);
        kill 'KILL', $_ for @late_listeners;
        $self->_wait_for_port_release($port);
    }

    $self->_cleanup_web_files;
    return $pid;
}

# start_collectors()
# Starts configured non-manual collectors in the background.
# Input: none.
# Output: list of started collector hashes.
sub start_collectors {
    my ($self) = @_;
    my @started;
    for my $job ( @{ $self->{config}->collectors } ) {
        next if ref($job) ne 'HASH';
        my $schedule = $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' );
        next if $schedule eq 'manual';
        my $pid = eval { $self->{runner}->start_loop($job) };
        if ($@) {
            my $error = $@;
            chomp $error;
            for my $started (@started) {
                eval { $self->{runner}->stop_loop( $started->{name} ) };
            }
            my $name = $job->{name} || '(unnamed)';
            die "Failed to start collector '$name': $error\n";
        }
        push @started, { name => $job->{name}, pid => $pid } if defined $pid;
    }
    return @started;
}

# serve_all(%args)
# Starts the web service and ensures configured collector loops follow the same
# lifecycle action.
# Input: host, port, worker count, ssl flag, and foreground options.
# Output: hash reference describing the started web pid/result and collector actions.
sub serve_all {
    my ( $self, %args ) = @_;
    my $host = '0.0.0.0';
    $host = $args{host} if defined $args{host};
    my $port = 7890;
    $port = $args{port} if defined $args{port};
    my $workers = 1;
    $workers = $args{workers} if defined $args{workers};
    my $ssl = $args{ssl} ? 1 : 0;
    my $foreground = $args{foreground} ? 1 : 0;

    if ($foreground) {
        my @collectors = $self->start_collectors;
        my $result = eval {
            $self->start_web(
                foreground => 1,
                host       => $host,
                port       => $port,
                workers    => $workers,
                ssl        => $ssl,
            );
        };
        my $error = $@;
        my @stopped_collectors = $self->stop_collectors;
        die $error if $error;
        return {
            foreground         => 1,
            host               => $host,
            port               => $port,
            workers            => $workers,
            ssl                => $ssl,
            collectors         => \@collectors,
            stopped_collectors => \@stopped_collectors,
            result             => $result,
        };
    }

    my $pid = $self->start_web(
        foreground => 0,
        host       => $host,
        port       => $port,
        workers    => $workers,
        ssl        => $ssl,
    );
    my @collectors = $self->start_collectors;
    return {
        host       => $host,
        port       => $port,
        workers    => $workers,
        ssl        => $ssl,
        pid        => $pid,
        collectors => \@collectors,
    };
}

# stop_collectors()
# Stops all managed collector loops.
# Input: none.
# Output: list of stopped collector name strings.
sub stop_collectors {
    my ($self) = @_;
    my @running = $self->{runner}->running_loops;
    my @names = map { $_->{name} } @running;
    for my $name (@names) {
        eval { $self->{runner}->stop_loop($name) };
    }
    $self->_pkill_perl('^dashboard collector:');
    for ( 1 .. 30 ) {
        last if !scalar $self->_find_processes_by_prefix('dashboard collector:');
        sleep 0.1;
    }
    for my $proc ( $self->_find_processes_by_prefix('dashboard collector:') ) {
        kill 'KILL', $proc->{pid};
    }
    return @names;
}

# stop_all()
# Stops the web service and all managed collectors.
# Input: none.
# Output: hash reference describing stopped processes.
sub stop_all {
    my ($self) = @_;
    return {
        web_pid   => $self->stop_web,
        collectors => [ $self->stop_collectors ],
    };
}

# restart_all(%args)
# Restarts collectors and the web service together.
# Input: host, port, worker-count, and ssl options.
# Output: hash reference describing stopped and restarted processes.
sub restart_all {
    my ( $self, %args ) = @_;
    my $host = '0.0.0.0';
    if ( defined $args{host} ) {
        $host = $args{host};
    }
    my $port = 7890;
    if ( defined $args{port} ) {
        $port = $args{port};
    }
    my $workers = 1;
    if ( defined $args{workers} ) {
        $workers = $args{workers};
    }
    my $ssl = $args{ssl} ? 1 : 0;
    my $stopped = $self->stop_all;
    my @collectors = $self->start_collectors;
    my $web_pid = $self->_restart_web_with_retry( host => $host, port => $port, workers => $workers, ssl => $ssl );
    return {
        stopped   => $stopped,
        collectors => \@collectors,
        web_pid   => $web_pid,
    };
}

# web_state()
# Loads the persisted web service state file.
# Input: none.
# Output: state hash reference or undef.
sub web_state {
    my ($self) = @_;
    my $file = $self->{files}->web_state;
    return if !-f $file;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    return json_decode( scalar <$fh> );
}

# _shutdown_web($status)
# Persists final web state and exits the web child.
# Input: final status string.
# Output: never returns.
sub _shutdown_web {
    my ( $self, $status ) = @_;
    my $state = $self->web_state;
    if ( !$state ) {
        $state = {};
    }
    my $final_status = 'stopped';
    if ( defined $status && $status ne '' ) {
        $final_status = $status;
    }
    $self->_write_web_state(
        {
            %$state,
            pid        => $$,
            status     => $final_status,
            updated_at => _now_iso8601(),
        }
    );
    exit 0;
}

# _run_web_child($writer, $host, $port, %args)
# Runs the daemonized web child lifecycle and reports startup status.
# Input: pipe writer handle, host, port, worker count, ssl flag, and detach/redirect options.
# Output: process exit code.
sub _run_web_child {
    my ( $self, $writer, $host, $port, %args ) = @_;
    my $detach   = exists $args{detach}   ? $args{detach}   : 1;
    my $redirect = exists $args{redirect} ? $args{redirect} : 1;
    my $workers  = exists $args{workers}  ? $args{workers}  : 1;
    my $ssl      = exists $args{ssl}      ? $args{ssl}      : 0;
    if ($detach) {
        setsid() or die "Unable to detach dashboard web service: $!";
        my $pid = fork();
        die "Unable to complete dashboard web daemonize: $!" if !defined $pid;
        return 0 if $pid;
    }
    if ($redirect) {
        open STDIN, '<', File::Spec->devnull() or die $!;
        open STDOUT, '>>', $self->{files}->dashboard_log or die $!;
        open STDERR, '>>', $self->{files}->dashboard_log or die $!;
    }

    $ENV{DEVELOPER_DASHBOARD_WEB_SERVICE} = 1;
    $ENV{DEVELOPER_DASHBOARD_WEB_HOST}    = $host;
    $ENV{DEVELOPER_DASHBOARD_WEB_PORT}    = $port;
    $ENV{DEVELOPER_DASHBOARD_WEB_WORKERS} = $workers;
    $ENV{DEVELOPER_DASHBOARD_WEB_SSL}     = $ssl;
    local $0 = $self->_web_process_title( $host, $port );
    local $SIGNAL_MANAGER = $self;
    my $shutdown = sub { $self->_shutdown_web('stopped') };
    local $SIG{TERM} = $shutdown;
    local $SIG{INT}  = $shutdown;
    local $SIG{HUP}  = $shutdown;

    my $server = eval { $self->{app_builder}->( host => $host, port => $port, workers => $workers, ssl => $ssl ) };
    if ($@) {
        print {$writer} "err: $@";
        close $writer;
        return 1;
    }

    my $daemon = eval { $server->start_daemon };
    if ($@) {
        print {$writer} "err: $@";
        close $writer;
        return 1;
    }

    my $bound_host = $daemon->sockhost;
    my $bound_port = $daemon->sockport;
    print {$writer} join( '|', 'ok', $$, $bound_host, $bound_port ), "\n";
    close $writer;

    $self->_write_web_state(
        {
            host         => $host,
            pid          => $$,
            port         => $bound_port + 0,
            process_name => $self->_web_process_title( $host, $port ),
            started_at   => _now_iso8601(),
            status       => 'running',
            bound_host   => $bound_host,
            workers      => $workers + 0,
            ssl          => $ssl + 0,
        }
    );

    eval { $server->serve_daemon($daemon) };
    if ($@) {
        my $message = sprintf "[%s][web] %s\n", _now_iso8601(), $@;
        $self->{files}->append( 'dashboard_log', $message );
        $self->_write_web_state(
            {
                host       => $host,
                pid        => $$,
                port       => $bound_port + 0,
                status     => 'error',
                error      => "$@",
                updated_at => _now_iso8601(),
                bound_host => $bound_host,
                workers    => $workers + 0,
            }
        );
        return 1;
    }

    $self->_write_web_state(
        {
            host       => $host,
            pid        => $$,
            port       => $bound_port + 0,
            status     => 'stopped',
            updated_at => _now_iso8601(),
            bound_host => $bound_host,
            workers    => $workers + 0,
        }
    );
    return 0;
}

# web_log(%args)
# Returns dashboard web-service log output, with optional tailing and follow mode.
# Input: optional lines count and follow flag.
# Output: log text string for non-follow mode, or streamed output via STDOUT in follow mode.
sub web_log {
    my ( $self, %args ) = @_;
    my $file = $self->{files}->resolve_file('dashboard_log');
    my $lines = $args{lines};
    my $follow = $args{follow} ? 1 : 0;
    if ( defined $lines ) {
        die 'Line count must be a positive integer' if $lines !~ /^\d+$/ || $lines < 1;
    }
    return '' if !$follow && !-f $file;

    my $log = $self->{files}->read('dashboard_log');
    $log = '' if !defined $log;
    $log = $self->_tail_text( $log, $lines ) if defined $lines;
    return $log if !$follow;

    my $old_stdout = select STDOUT;
    $| = 1;
    select $old_stdout;
    print $log if $log ne '';
    $self->_follow_log_file( file => $file );
    return '';
}

# _tail_text($text, $lines)
# Returns the last N logical lines from a text buffer.
# Input: text string and positive integer line count.
# Output: tailed text string.
sub _tail_text {
    my ( $self, $text, $lines ) = @_;
    return '' if !defined $text || $text eq '';
    return $text if !defined $lines;
    my @parts = split /\n/, $text, -1;
    my $had_trailing_newline = @parts && $parts[-1] eq '' ? 1 : 0;
    pop @parts if $had_trailing_newline;
    my $start = @parts - $lines;
    $start = 0 if $start < 0;
    my $tail = join "\n", @parts[ $start .. $#parts ];
    $tail .= "\n" if $had_trailing_newline && $tail ne '';
    return $tail;
}

# _follow_log_file(%args)
# Streams appended content from one log file until interrupted.
# Input: file path plus optional poll interval seconds.
# Output: never returns under normal command use; prints new log chunks to STDOUT.
sub _follow_log_file {
    my ( $self, %args ) = @_;
    my $file = $args{file} || die 'Missing log file';
    my $interval = defined $args{interval} ? $args{interval} : 0.1;
    my $fh;
    if ( !open( $fh, '<', $file ) ) {
        open my $create_fh, '>>', $file or die "Unable to create $file: $!";
        close $create_fh;
        $self->{paths}->secure_file_permissions($file);
        open( $fh, '<', $file ) or die "Unable to read $file: $!";
    }
    seek $fh, 0, 2 or die "Unable to seek $file: $!";
    local $SIG{TERM} = sub { exit 0 };
    local $SIG{INT}  = sub { exit 0 };
    local $SIG{HUP}  = sub { exit 0 };
    while (1) {
        my $chunk = '';
        my $read = sysread( $fh, $chunk, 8192 );
        if ( defined $read && $read > 0 ) {
            print $chunk;
            next;
        }
        sleep $interval;
    }
}

# _write_web_state($state)
# Atomically persists the web service state snapshot.
# Input: state hash reference.
# Output: true value.
sub _write_web_state {
    my ( $self, $data ) = @_;
    my $payload = {};
    if ($data) {
        $payload = $data;
    }
    my $file = $self->{files}->web_state;
    my $tmp = sprintf '%s.%s.%s.pending', $file, $$, time;
    open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
    print {$fh} json_encode($payload);
    close $fh;
    $self->{paths}->secure_file_permissions($tmp);
    rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
    $self->{paths}->secure_file_permissions($file);
    return $payload;
}

# _cleanup_web_files()
# Removes persisted web pid and state files.
# Input: none.
# Output: true value.
sub _cleanup_web_files {
    my ($self) = @_;
    $self->{files}->remove('web_pid');
    $self->{files}->remove('web_state');
    return 1;
}

# _web_process_title($host, $port)
# Builds the managed web process title string.
# Input: host and port values.
# Output: process title string.
sub _web_process_title {
    my ( $self, $host, $port ) = @_;
    return "dashboard web: $host:$port";
}

# _is_managed_web($pid)
# Checks whether a pid belongs to a managed dashboard web process.
# Input: process id integer.
# Output: boolean managed flag.
sub _is_managed_web {
    my ( $self, $pid ) = @_;
    return 0 if !$pid || !kill 0, $pid;
    my $marker = $self->_read_process_env_marker( $pid, 'DEVELOPER_DASHBOARD_WEB_SERVICE' );
    return 1 if defined $marker && $marker eq '1';
    my $title = $self->_read_process_title($pid);
    return 0 if !defined $title || $title eq '';
    return $title =~ /^dashboard web:/ ? 1 : 0;
}

# _pkill_perl($pattern)
# Kills Perl processes whose command lines match a pattern.
# Input: regular-expression pattern string.
# Output: true value.
sub _pkill_perl {
    my ( $self, $pattern ) = @_;
    my ( undef, $stderr, $exit_code ) = capture {
        my $ok = system 'pkill', '-TERM', '-f', $pattern;
        return $ok == -1 ? -1 : ($? >> 8);
    };
    return 1 if $exit_code == 0 || $exit_code == 1;
    if ( $exit_code < 0 || $exit_code == 127 || ( defined $stderr && $stderr =~ /not found/i ) ) {
        for my $proc ( $self->_ps_processes ) {
            next if $proc->{args} !~ /$pattern/;
            kill 'TERM', $proc->{pid};
        }
        return 1;
    }
    return;
}

# _find_processes_by_prefix($prefix)
# Returns running processes whose command lines start with a prefix.
# Input: prefix string.
# Output: list of process hash references.
sub _find_processes_by_prefix {
    my ( $self, $prefix ) = @_;
    return grep { $_->{args} =~ /^\Q$prefix\E/ } $self->_ps_processes;
}

# _find_web_processes()
# Returns managed or older-compatible dashboard web processes.
# Input: none.
# Output: list of process hash references.
sub _find_web_processes {
    my ($self) = @_;
    my @seen;
    my %seen_pid;
    for my $proc ( $self->_ps_processes ) {
        next if $proc->{pid} == $$;
        next if $seen_pid{ $proc->{pid} }++;
        next if !$self->_looks_like_web_process($proc);
        push @seen, $proc;
    }
    return @seen;
}

# _find_legacy_web_processes()
# Returns older-style dashboard serve processes.
# Input: none.
# Output: list of process hash references.
sub _find_legacy_web_processes {
    my ($self) = @_;
    return grep { $_->{args} !~ /^dashboard web:/ } $self->_find_web_processes;
}

# _looks_like_web_process($proc)
# Determines whether a process record matches known web worker forms.
# Input: process hash reference with args.
# Output: boolean match flag.
sub _looks_like_web_process {
    my ( $self, $proc ) = @_;
    return 0 if !$proc || !$proc->{pid} || !$proc->{args};
    return 1 if $proc->{args} =~ /^dashboard web:\s+\S+:\d+$/;
    return 1 if $proc->{args} =~ m{^(?:\S+/env\s+)?perl(?:\s+-\S+)*\s+(?:\S+/)?dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 1 if $proc->{args} =~ m{^(?:\S+/env\s+)?perl(?:\s+-\S+)*\s+bin/dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 1 if $proc->{args} =~ m{^(?:\S+/)?dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 1 if $proc->{args} =~ m{^bin/dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 0;
}

# _ps_processes()
# Reads the process table into normalized process records.
# Input: none.
# Output: list of process hash references.
sub _ps_processes {
    my ($self) = @_;
    my ( $stdout, undef, $exit_code ) = capture {
        system 'ps', '-eo', 'pid=,args=';
        return $? >> 8;
    };
    return if $exit_code != 0;
    my @procs;
    for my $line ( split /\n/, $stdout ) {
        next if $line !~ /^\s*(\d+)\s+(.*)$/;
        push @procs, {
            pid  => $1 + 0,
            args => $2,
        };
    }
    return @procs;
}

# _managed_listener_pids_for_port($port)
# Returns managed web-service listener pids bound to one TCP port.
# Input: TCP port integer.
# Output: list of managed process ids.
sub _managed_listener_pids_for_port {
    my ( $self, $port ) = @_;
    return grep { $self->_is_managed_web($_) } $self->_listener_pids_for_port($port);
}

# _listener_pids_for_port($port)
# Returns TCP listener process ids bound to one port.
# Input: TCP port integer.
# Output: list of process ids.
sub _listener_pids_for_port {
    my ( $self, $port ) = @_;
    return () if !$port;
    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'ss', '-ltnp', "( sport = :$port )";
        return $? >> 8;
    };
    my @pids;
    my $has_stdout = defined $stdout && $stdout ne '';
    if ( $exit_code == 0 && $has_stdout ) {
        my %seen;
        @pids = grep { !$seen{$_}++ } ( $stdout =~ /pid=(\d+)/g );
    }
    else {
        my $ss_missing = 0;
        if ( $exit_code == 127 ) {
            $ss_missing = 1;
        }
        elsif ( defined $stderr && $stderr =~ /not found/i ) {
            $ss_missing = 1;
        }
        if ($ss_missing) {
            @pids = $self->_listener_pids_for_port_via_proc($port);
        }
    }
    return @pids;
}

# _listener_pids_for_port_via_proc($port)
# Resolves TCP listener process ids from /proc when ss is unavailable.
# Input: TCP port integer.
# Output: list of process ids.
sub _listener_pids_for_port_via_proc {
    my ( $self, $port ) = @_;
    my %inode = map { $_ => 1 } $self->_listener_socket_inodes_for_port($port);
    return () if !%inode;
    return $self->_process_pids_for_socket_inodes( \%inode );
}

# _listener_socket_inodes_for_port($port)
# Reads /proc TCP tables and returns listener socket inodes for one port.
# Input: TCP port integer.
# Output: list of socket inode integers.
sub _listener_socket_inodes_for_port {
    my ( $self, $port ) = @_;
    return () if !$port;
    my $hex_port = sprintf '%04X', $port;
    my %seen;
    my @inodes;
    for my $file ( $self->_listener_socket_table_paths ) {
        next if !-r $file;
        open my $fh, '<', $file or next;
        while ( my $line = <$fh> ) {
            next if $line !~ /\S/;
            my @fields = split ' ', $line;
            next if @fields < 10;
            next if !defined $fields[1] || !defined $fields[3] || !defined $fields[9];
            my ( undef, $local_port ) = split /:/, $fields[1], 2;
            next if !defined $local_port || uc($local_port) ne $hex_port;
            next if $fields[3] ne '0A';
            my $inode = $fields[9];
            next if !$inode || $seen{$inode}++;
            push @inodes, $inode + 0;
        }
        close $fh;
    }
    return @inodes;
}

# _listener_socket_table_paths()
# Returns the procfs TCP table files used for listener discovery.
# Input: none.
# Output: list of file path strings.
sub _listener_socket_table_paths {
    return ( '/proc/net/tcp', '/proc/net/tcp6' );
}

# _process_pids_for_socket_inodes($inode_lookup)
# Maps socket inode values back to owning process ids through /proc fd links.
# Input: hash reference keyed by socket inode.
# Output: list of process ids.
sub _process_pids_for_socket_inodes {
    my ( $self, $inode_lookup ) = @_;
    return () if !$inode_lookup || ref($inode_lookup) ne 'HASH' || !%{$inode_lookup};
    my %seen;
    my @pids;
    for my $fd_path ( $self->_process_fd_paths ) {
        next if $fd_path !~ m{/(?:proc/)?(\d+)/fd/[^/]+$};
        my $pid = $1 + 0;
        my $target = readlink $fd_path;
        next if !defined $target || $target !~ /^socket:\[(\d+)\]$/;
        next if !$inode_lookup->{$1};
        next if $seen{$pid}++;
        push @pids, $pid;
    }
    return @pids;
}

# _process_fd_paths()
# Returns the procfs file-descriptor paths used for socket owner discovery.
# Input: none.
# Output: list of file path strings.
sub _process_fd_paths {
    return glob '/proc/[0-9]*/fd/*';
}

# _wait_for_port_release($port)
# Waits for a TCP port listener set to disappear after shutdown signals are sent.
# Input: TCP port integer.
# Output: true when the port is no longer listening.
sub _wait_for_port_release {
    my ( $self, $port ) = @_;
    return 1 if !$port;
    for ( 1 .. 50 ) {
        return 1 if !scalar $self->_listener_pids_for_port($port);
        sleep 0.1;
    }
    return !scalar $self->_listener_pids_for_port($port);
}

# _restart_web_with_retry(%args)
# Restarts the web listener with retries for transient port-release races.
# Input: host, port, worker-count, and ssl values.
# Output: restarted web pid.
sub _restart_web_with_retry {
    my ( $self, %args ) = @_;
    my $host = '0.0.0.0';
    if ( defined $args{host} ) {
        $host = $args{host};
    }
    my $port = 7890;
    if ( defined $args{port} ) {
        $port = $args{port};
    }
    my $workers = 1;
    if ( defined $args{workers} ) {
        $workers = $args{workers};
    }
    my $ssl = $args{ssl} ? 1 : 0;
    my $attempts = 20;
    for my $attempt ( 1 .. $attempts ) {
        my $pid = eval { $self->start_web( host => $host, port => $port, workers => $workers, ssl => $ssl ) };
        return $pid if defined $pid && !$@;
        my $error = $@;
        if ( !$error ) {
            $error = "Unable to restart dashboard web service on $host:$port\n";
        }
        die $error if $error !~ /Address already in use/;
        die $error if $attempt == $attempts;
        sleep 0.25;
    }
}

# _read_process_env_marker($pid, $key)
# Reads a specific environment variable from a running process when possible.
# Input: process id integer and env key string.
# Output: env value string or undef.
sub _read_process_env_marker {
    my ( $self, $pid, $key ) = @_;
    my $proc = "/proc/$pid/environ";
    return if !-r $proc;
    open my $fh, '<', $proc or return;
    local $/;
    my $env = scalar <$fh>;
    return if !defined $env || $env eq '';
    for my $pair ( split /\0/, $env ) {
        next if $pair !~ /^([^=]+)=(.*)$/s;
        return $2 if $1 eq $key;
    }
    return;
}

# _read_process_title($pid)
# Reads a process command line for matching and diagnostics.
# Input: process id integer.
# Output: command line string or undef.
sub _read_process_title {
    my ( $self, $pid ) = @_;
    my $proc = "/proc/$pid/cmdline";
    if ( -r $proc ) {
        open my $fh, '<', $proc or return;
        local $/;
        my $cmdline = scalar <$fh>;
        if ( defined $cmdline && $cmdline ne '' ) {
            $cmdline =~ s/\0/ /g;
            $cmdline =~ s/\s+$//;
            return $cmdline;
        }
    }

    my ( $stdout, undef, $exit_code ) = capture {
        system 'ps', '-o', 'args=', '-p', $pid;
        return $? >> 8;
    };
    return if $exit_code != 0;
    $stdout =~ s/\s+$// if defined $stdout;
    return $stdout;
}

# _now_iso8601()
# Returns the current UTC timestamp in ISO-8601 form.
# Input: none.
# Output: timestamp string.
sub _now_iso8601 {
    my @t = gmtime();
    return strftime( '%Y-%m-%dT%H:%M:%SZ', @t );
}

1;

__END__

=head1 NAME

Developer::Dashboard::RuntimeManager - runtime lifecycle manager

=head1 SYNOPSIS

  my $runtime = Developer::Dashboard::RuntimeManager->new(...);
  my $pid = $runtime->start_web;

=head1 DESCRIPTION

This module manages the lifecycle of the dashboard web service and managed
collector loops, including stop and restart orchestration.

=head1 METHODS

=head2 new, start_web, running_web, stop_web, start_collectors, serve_all, stop_collectors, stop_all, restart_all, web_state, web_log

Construct and manage the dashboard runtime.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module manages the dashboard runtime processes. It starts, stops, and restarts the web listener, tracks the web pid, coordinates collector lifecycle around restart/stop flows, and exposes the process-management behavior behind the serve/restart/stop command family.

=head1 WHY IT EXISTS

It exists because runtime lifecycle management needs one owner for pid files, process validation, restart ordering, and port-release races. That keeps the browser server and collector loops moving together instead of leaving each command to improvise process control.

=head1 WHEN TO USE

Use this file when changing how the web process is launched, how restart waits for ports to free up, how collectors are stopped and restarted with the web process, or how runtime state is validated before a lifecycle command acts.

=head1 HOW TO USE

Construct it with the path registry and any required collaborators, then call the lifecycle methods from CLI helpers. Keep process orchestration here and let the command wrappers only parse arguments and print results.

=head1 WHAT USES IT

It is used by the C<dashboard serve>, C<dashboard restart>, and C<dashboard stop> helpers, by integration smoke that exercises lifecycle commands, and by tests that cover pid handling and process validation.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::RuntimeManager -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/00-load.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
