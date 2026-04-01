package Developer::Dashboard::RuntimeManager;
$Developer::Dashboard::RuntimeManager::VERSION = '0.94';
use strict;
use warnings;

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
# Input: host, port, and foreground options.
# Output: server return value in foreground mode or child pid in background mode.
sub start_web {
    my ( $self, %args ) = @_;
    my $host       = $args{host} || '0.0.0.0';
    my $port       = $args{port} || 7890;
    my $foreground = $args{foreground} ? 1 : 0;

    if ($foreground) {
        my $server = $self->{app_builder}->( host => $host, port => $port );
        return $server->run;
    }

    my $running = $self->running_web;
    return $running->{pid} if $running && $running->{host} eq $host && $running->{port} == $port;

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
        };
        $self->{files}->write( 'web_pid', "$started_pid\n" );
        $self->_write_web_state($state);
        return $started_pid;
    }

    close $reader;
    exit $self->_run_web_child( $writer, $host, $port );
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
        if ( $pid && $self->_is_managed_web($pid) ) {
            return {
                %$state,
                pid => $pid + 0,
            };
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
# Stops the managed web service, including legacy compatible process shapes.
# Input: none.
# Output: stopped pid or undef.
sub stop_web {
    my ($self) = @_;
    my $running = $self->running_web;
    my $pid = $running ? $running->{pid} : undef;

    $self->_pkill_perl('^dashboard web:');
    for my $proc ( $self->_find_legacy_web_processes ) {
        kill 'TERM', $proc->{pid};
    }
    for ( 1 .. 30 ) {
        last if !$self->running_web;
        sleep 0.1;
    }

    my $still_running = $self->running_web;
    if ($still_running) {
        kill 'KILL', $still_running->{pid};
        sleep 0.1;
    }
    for my $proc ( $self->_find_legacy_web_processes ) {
        kill 'KILL', $proc->{pid};
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
        push @started, { name => $job->{name}, pid => $pid } if defined $pid;
    }
    return @started;
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
# Input: host and port options.
# Output: hash reference describing stopped and restarted processes.
sub restart_all {
    my ( $self, %args ) = @_;
    my $host = $args{host} || '0.0.0.0';
    my $port = $args{port} || 7890;
    my $stopped = $self->stop_all;
    my @collectors = $self->start_collectors;
    my $web_pid = $self->start_web( host => $host, port => $port );
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
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    return json_decode( scalar <$fh> );
}

# _shutdown_web($status)
# Persists final web state and exits the web child.
# Input: final status string.
# Output: never returns.
sub _shutdown_web {
    my ( $self, $status ) = @_;
    my $state = $self->web_state || {};
    $self->_write_web_state(
        {
            %$state,
            pid        => $$,
            status     => $status || 'stopped',
            updated_at => _now_iso8601(),
        }
    );
    exit 0;
}

# _run_web_child($writer, $host, $port, %args)
# Runs the daemonized web child lifecycle and reports startup status.
# Input: pipe writer handle, host, port, and detach/redirect options.
# Output: process exit code.
sub _run_web_child {
    my ( $self, $writer, $host, $port, %args ) = @_;
    my $detach   = exists $args{detach}   ? $args{detach}   : 1;
    my $redirect = exists $args{redirect} ? $args{redirect} : 1;
    if ($detach) {
        setsid() or die "Unable to detach dashboard web service: $!";
        my $pid = fork();
        die "Unable to complete dashboard web daemonize: $!" if !defined $pid;
        return 0 if $pid;
    }
    if ($redirect) {
        open STDIN, '<', '/dev/null' or die $!;
        open STDOUT, '>>', $self->{files}->dashboard_log or die $!;
        open STDERR, '>>', $self->{files}->dashboard_log or die $!;
    }

    $ENV{DEVELOPER_DASHBOARD_WEB_SERVICE} = 1;
    $ENV{DEVELOPER_DASHBOARD_WEB_HOST}    = $host;
    $ENV{DEVELOPER_DASHBOARD_WEB_PORT}    = $port;
    local $0 = $self->_web_process_title( $host, $port );
    local $SIGNAL_MANAGER = $self;
    my $shutdown = sub { $self->_shutdown_web('stopped') };
    local $SIG{TERM} = $shutdown;
    local $SIG{INT}  = $shutdown;
    local $SIG{HUP}  = $shutdown;

    my $server = eval { $self->{app_builder}->( host => $host, port => $port ) };
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
        }
    );
    return 0;
}

# _write_web_state($state)
# Atomically persists the web service state snapshot.
# Input: state hash reference.
# Output: true value.
sub _write_web_state {
    my ( $self, $data ) = @_;
    my $file = $self->{files}->web_state;
    my $tmp = sprintf '%s.%s.%s.pending', $file, $$, time;
    open my $fh, '>', $tmp or die "Unable to write $tmp: $!";
    print {$fh} json_encode( $data || {} );
    close $fh;
    rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
    return $data;
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
# Returns managed or legacy-compatible dashboard web processes.
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
# Returns legacy-style dashboard serve processes.
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
    return 1 if $proc->{args} =~ m{^(?:\S+/env\s+)?perl(?:\s+-\S+)*\s+(?:\S+/)?dashboard\s+serve(?:\s|$)};
    return 1 if $proc->{args} =~ m{^(?:\S+/env\s+)?perl(?:\s+-\S+)*\s+bin/dashboard\s+serve(?:\s|$)};
    return 1 if $proc->{args} =~ m{^(?:\S+/)?dashboard\s+serve(?:\s|$)};
    return 1 if $proc->{args} =~ m{^bin/dashboard\s+serve(?:\s|$)};
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

=head2 new, start_web, running_web, stop_web, start_collectors, stop_collectors, stop_all, restart_all, web_state

Construct and manage the dashboard runtime.

=cut
