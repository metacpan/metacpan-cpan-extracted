package Linux::Event::Kernel::Process;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use Errno ();
use Fcntl qw(F_GETFD F_GETFL F_SETFD F_SETFL FD_CLOEXEC O_NONBLOCK);
use POSIX qw(SIGKILL SIGRTMAX);
use Scalar::Util qw(blessed);
use utf8 ();

require Linux::Event::Loop;
use Linux::Event::Error;
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

my %CLASS_DESCRIPTOR;
my @CALLBACK = qw(
    on_exit on_stdout on_stderr on_stdout_eof on_stderr_eof
    on_stdin_drain on_error
);
# Private control retained only for the paired pipe-drain benchmark.
our $_PIPE_DRAIN_ENGINE = 'native';

sub _integer ($target, $name, $value, $minimum, $maximum = 2_147_483_647) {
    croak "$target $name must be an integer"
        if !defined($value) || ref($value) || $value !~ /\A\d+\z/;
    my $digits = "$value";
    $digits =~ s/\A0+(?=\d)//;
    croak "$target $name must be at most $maximum"
        if length($digits) > length("$maximum")
        || (length($digits) == length("$maximum")
            && $digits gt "$maximum");
    $value = 0 + $value;
    croak "$target $name must be at least $minimum" if $value < $minimum;
    return $value;
}

sub _descriptor_for ($class) {
    return $CLASS_DESCRIPTOR{$class} if exists $CLASS_DESCRIPTOR{$class};
    croak "$class is not a Linux::Event::Kernel::Process subclass"
        if !$class->isa(__PACKAGE__);
    my %callback = map { $_ => scalar $class->can($_) } @CALLBACK;
    my %option = (
        read_size            => 65_536,
        max_reads_per_tick   => 64,
        stdin_high_watermark => 1_048_576,
        stdin_low_watermark  => 262_144,
        max_pending_stdin    => 0,
    );
    if (my $configure = $class->can('process_options')) {
        my @configured = $configure->($class);
        my %configured;
        if (@configured == 1 && ref($configured[0]) eq 'HASH') {
            %configured = %{ $configured[0] };
        } else {
            croak "$class process_options() returned an odd option list"
                if @configured % 2;
            %configured = @configured;
        }
        my @unknown = grep { !exists $option{$_} } keys %configured;
        croak "$class process_options() returned unknown options: "
            . join(', ', sort @unknown) if @unknown;
        @option{keys %configured} = values %configured;
    }
    $option{read_size} = _integer($class, 'read_size', $option{read_size}, 1);
    $option{max_reads_per_tick} = _integer(
        $class, 'max_reads_per_tick', $option{max_reads_per_tick}, 1,
    );
    for my $name (qw(stdin_high_watermark stdin_low_watermark
        max_pending_stdin)) {
        $option{$name} = _integer($class, $name, $option{$name}, 0);
    }
    croak "$class stdin_low_watermark must be <= stdin_high_watermark"
        if $option{stdin_low_watermark} > $option{stdin_high_watermark};
    return $CLASS_DESCRIPTOR{$class} = {
        class => $class, callbacks => \%callback, options => \%option,
    };
}

sub _effective_descriptor ($class, $method, $option) {
    my $descriptor = _descriptor_for($class);
    my %override;
    for my $name (@CALLBACK) {
        next if !exists $option->{$name};
        my $callback = delete $option->{$name};
        croak "$method(): $name must be a coderef"
            if ref($callback) ne 'CODE';
        $override{$name} = $callback;
    }
    my %callback = (%{ $descriptor->{callbacks} }, %override);
    croak "$method(): on_exit callback is required"
        if !$callback{on_exit};
    return $descriptor if !%override;
    return { %$descriptor, callbacks => \%callback };
}

sub new ($class, %option) {
    croak 'new(): must be called as a class method' if ref $class;
    my $descriptor = _effective_descriptor($class, 'new', \%option);
    my $loop = delete $option{loop};
    croak 'new(): loop must be an object implementing add() and watch()'
        if defined($loop) && (!ref($loop) || !$loop->can('add')
            || !$loop->can('watch'));
    my $data = delete $option{data};
    my $pid = delete $option{pid};
    croak 'new(): pid is required' if !defined $pid;
    $pid = _integer('new():', 'pid', $pid, 1);
    my $reap = exists($option{reap}) ? delete($option{reap}) : 1;
    croak 'new(): reap must be zero or one'
        if !defined($reap) || ref($reap) || $reap !~ /\A[01]\z/;
    my $callback = $descriptor->{callbacks};
    for my $name (qw(
        on_stdout on_stderr on_stdout_eof on_stderr_eof on_stdin_drain
    )) {
        croak "new(): $name is unavailable when observing an existing process"
            if $callback->{$name};
    }
    croak 'new(): unknown options: ' . join(', ', sort keys %option)
        if %option;
    my $self = $class->_new_object(
        descriptor => $descriptor, loop => $loop, data => $data,
        mode => 'observe', pid => $pid, reap => $reap ? 1 : 0,
    );
    return $self;
}

sub spawn ($class, %option) {
    croak 'spawn(): must be called as a class method' if ref $class;
    my $descriptor = _effective_descriptor($class, 'spawn', \%option);
    my $loop = delete $option{loop};
    croak 'spawn(): loop must be an object implementing add() and watch()'
        if defined($loop) && (!ref($loop) || !$loop->can('add')
            || !$loop->can('watch'));
    my $data = delete $option{data};
    my $command = delete $option{command};
    croak 'spawn(): command must be a nonempty array reference'
        if ref($command) ne 'ARRAY' || !@$command;
    my @command;
    for my $index (0 .. $#$command) {
        my $argument = $command->[$index];
        croak 'spawn(): every command argument must be a defined scalar'
            if !defined($argument) || ref($argument);
        croak 'spawn(): command arguments cannot contain NUL bytes'
            if "$argument" =~ /\0/;
        my $bytes = "$argument";
        croak 'spawn(): command arguments must be byte strings'
            if !utf8::downgrade($bytes, 1);
        croak 'spawn(): command executable must be a non-empty string'
            if $index == 0 && $bytes eq '';
        push @command, $bytes;
    }
    my $cwd = delete $option{cwd};
    croak 'spawn(): cwd must be a non-empty path'
        if defined($cwd) && (ref($cwd) || $cwd eq '' || $cwd =~ /\0/);
    if (defined $cwd) {
        $cwd = "$cwd";
        croak 'spawn(): cwd must be a byte-string path'
            if !utf8::downgrade($cwd, 1);
    }
    my $env = delete $option{env};
    if (defined $env) {
        croak 'spawn(): env must be a hash reference' if ref($env) ne 'HASH';
        my %copy;
        for my $name (keys %$env) {
            croak 'spawn(): environment names must be nonempty and cannot contain = or NUL'
                if $name eq '' || $name =~ /[=\0]/;
            my $value = $env->{$name};
            croak 'spawn(): environment values must be defined scalars without NUL'
                if !defined($value) || ref($value) || "$value" =~ /\0/;
            my ($byte_name, $byte_value) = ("$name", "$value");
            croak 'spawn(): environment names and values must be byte strings'
                if !utf8::downgrade($byte_name, 1)
                || !utf8::downgrade($byte_value, 1);
            $copy{$byte_name} = $byte_value;
        }
        $env = \%copy;
    }

    my %stdio;
    for my $name (qw(stdin stdout stderr)) {
        $stdio{$name} = exists($option{$name})
            ? delete($option{$name}) : 'inherit';
        _validate_stdio($name, $stdio{$name});
    }
    my %configured = %{ $descriptor->{options} };
    for my $name (keys %configured) {
        next if !exists $option{$name};
        $configured{$name} = delete $option{$name};
    }
    $configured{read_size} = _integer(
        'spawn():', 'read_size', $configured{read_size}, 1,
    );
    $configured{max_reads_per_tick} = _integer(
        'spawn():', 'max_reads_per_tick', $configured{max_reads_per_tick}, 1,
    );
    for my $name (qw(stdin_high_watermark stdin_low_watermark
        max_pending_stdin)) {
        $configured{$name} = _integer(
            'spawn():', $name, $configured{$name}, 0,
        );
    }
    croak 'spawn(): stdin_low_watermark must be <= stdin_high_watermark'
        if $configured{stdin_low_watermark}
        > $configured{stdin_high_watermark};
    croak 'spawn(): unknown options: ' . join(', ', sort keys %option)
        if %option;
    $descriptor = { %$descriptor, options => \%configured };

    my $callback = $descriptor->{callbacks};
    croak 'spawn(): on_stdout requires stdout => pipe'
        if $callback->{on_stdout} && $stdio{stdout} ne 'pipe';
    croak 'spawn(): on_stdout_eof requires stdout => pipe'
        if $callback->{on_stdout_eof} && $stdio{stdout} ne 'pipe';
    croak 'spawn(): on_stderr requires stderr => pipe'
        if $callback->{on_stderr} && $stdio{stderr} ne 'pipe';
    croak 'spawn(): on_stderr_eof requires stderr => pipe'
        if $callback->{on_stderr_eof} && $stdio{stderr} ne 'pipe';
    croak 'spawn(): on_stdin_drain requires stdin => pipe'
        if $callback->{on_stdin_drain} && $stdio{stdin} ne 'pipe';

    return $class->_new_object(
        descriptor => $descriptor, loop => $loop, data => $data,
        mode => 'spawn', command => \@command, cwd => $cwd, env => $env,
        stdio => \%stdio, reap => 1,
    );
}

sub _validate_stdio ($name, $value) {
    return if ref($value) && defined(fileno($value));
    croak "spawn(): $name must be inherit, pipe, null, or a filehandle"
        if !defined($value) || ref($value)
        || ($value ne 'inherit' && $value ne 'pipe' && $value ne 'null'
            && !($name eq 'stderr' && $value eq 'stdout'));
    return;
}

sub _new_object ($class, %argument) {
    my $loop = delete $argument{loop};
    my $self = bless {
        %argument,
        loop => undef,
        state => 'unattached',
        pidfd => undef,
        pid_watcher => undef,
        stdin_fh => undef,
        stdout_fh => undef,
        stderr_fh => undef,
        stdin_watcher => undef,
        stdout_watcher => undef,
        stderr_watcher => undef,
        stdin_queue => [],
        pending_stdin_bytes => 0,
        stdin_above_high => 0,
        stdin_closing => 0,
        stdin_closed => 0,
        stdout_closed => 1,
        stderr_closed => 1,
        exit_observed => 0,
        exit_code => undef,
        term_signal => undef,
        core_dumped => 0,
        raw_status => undef,
        last_error => undef,
    }, $class;
    $loop->add($self) if defined $loop;
    return $self;
}

sub _set_cloexec ($fh) {
    my $flags = fcntl($fh, F_GETFD, 0);
    die "fcntl(F_GETFD): $!" if !defined $flags;
    fcntl($fh, F_SETFD, $flags | FD_CLOEXEC)
        or die "fcntl(F_SETFD): $!";
    return;
}

sub _set_nonblocking ($fh) {
    my $flags = fcntl($fh, F_GETFL, 0);
    die "fcntl(F_GETFL): $!" if !defined $flags;
    fcntl($fh, F_SETFL, $flags | O_NONBLOCK)
        or die "fcntl(F_SETFL): $!";
    return;
}

sub _pipe_for ($direction) {
    my ($read_fd, $write_fd) = @{ _pipe_cloexec() };
    my ($read, $write);
    if (!open($read, '<&=', $read_fd)) {
        my $failure = "$!";
        eval { _close_fd($read_fd) };
        eval { _close_fd($write_fd) };
        die "open pipe read handle: $failure";
    }
    if (!open($write, '>&=', $write_fd)) {
        my $failure = "$!";
        close $read;
        eval { _close_fd($write_fd) };
        die "open pipe write handle: $failure";
    }
    _set_cloexec($read);
    _set_cloexec($write);
    if ($direction eq 'stdin') {
        _set_nonblocking($write);
        return ($write, $read, [$read, $write]);
    }
    _set_nonblocking($read);
    return ($read, $write, [$read, $write]);
}

sub _attachment_error ($failure, $default_operation) {
    return $failure if blessed($failure)
        && $failure->isa('Linux::Event::Error');
    my $message = "$failure";
    $message =~ s/\s+\z//;
    my $operation = $default_operation;
    if ($message =~ s/\A([A-Za-z][A-Za-z0-9_]*)(?:\([^)]*\))?:\s*//) {
        $operation = $1;
    }
    return Linux::Event::Error->new(
        type => 'process', operation => $operation,
        message => $message || 'process setup failed',
    );
}

sub _stdio_source ($self, $name, $owned, $close_fds) {
    my $mode = $self->{stdio}{$name};
    return -1 if $mode eq 'inherit';
    return -2 if $name eq 'stderr' && $mode eq 'stdout';
    if ($mode eq 'pipe') {
        my ($parent, $child, $all) = _pipe_for($name);
        $self->{"${name}_fh"} = $parent;
        $self->{"${name}_closed"} = 0 if $name ne 'stdin';
        push @$owned, $child;
        push @$close_fds, map { fileno($_) } @$all;
        return fileno($child);
    }
    if ($mode eq 'null') {
        my $operator = $name eq 'stdin' ? '<' : '>';
        open(my $null, $operator, '/dev/null') or die "open /dev/null: $!";
        _set_cloexec($null);
        push @$owned, $null;
        push @$close_fds, fileno($null);
        return fileno($null);
    }
    my $fd = fileno($mode);
    push @$close_fds, $fd;
    return $fd;
}

sub _attach_to_loop ($self, $loop) {
    croak 'add(): Process is not unattached'
        if $self->{state} ne 'unattached' || $self->{loop};
    $self->{loop} = $loop;
    if ($self->{mode} eq 'observe') {
        my $pidfd = eval { _pidfd_open($self->{pid}) };
        if (!defined $pidfd) {
            my $failure = _attachment_error($@, 'pidfd_open');
            $self->{loop} = undef;
            die $failure;
        }
        $self->{pidfd} = $pidfd;
    } else {
        my (@owned, @close_fds);
        my ($stdin_fd, $stdout_fd, $stderr_fd);
        my $ok = eval {
            $stdin_fd = $self->_stdio_source('stdin', \@owned, \@close_fds);
            $stdout_fd = $self->_stdio_source('stdout', \@owned, \@close_fds);
            $stderr_fd = $self->_stdio_source('stderr', \@owned, \@close_fds);
            my $result = _spawn(
                $self->{command}, $self->{env}, $self->{cwd},
                $stdin_fd, $stdout_fd, $stderr_fd, \@close_fds,
            );
            ($self->{pid}, $self->{pidfd}) = @$result;
            1;
        };
        my $failure = $@;
        close $_ for @owned;
        if (!$ok) {
            close(delete $self->{stdin_fh}) if $self->{stdin_fh};
            close(delete $self->{stdout_fh}) if $self->{stdout_fh};
            close(delete $self->{stderr_fh}) if $self->{stderr_fh};
            $self->{loop} = undef;
            die _attachment_error($failure, 'spawn');
        }
    }
    $self->{state} = 'running';
    my $registered = eval { $self->_register_watchers; 1 };
    if (!$registered) {
        my $failure = $@ || 'could not register Process descriptors';
        if ($self->{mode} eq 'spawn' && defined $self->{pid}) {
            if (defined $self->{pidfd}) {
                eval { _pidfd_send($self->{pidfd}, SIGKILL); 1 };
            } else {
                kill SIGKILL, $self->{pid};
            }
            while (waitpid($self->{pid}, 0) < 0 && $! == Errno::EINTR()) { }
        }
        $self->{state} = 'failed';
        $self->_release_handles;
        $self->{loop} = undef;
        die _attachment_error($failure, 'watch');
    }
    return $self;
}

sub _register_watchers ($self) {
    my $loop = $self->{loop};
    $self->{pid_watcher} = $loop->watch(
        fd => $self->{pidfd}, _internal => 1, data => $self,
        read => \&_pid_ready, error => \&_pid_ready,
        _callback_data_arg => 1,
    );
    if ($self->{stdout_fh}) {
        $self->{stdout_watcher} = $loop->watch(
            fh => $self->{stdout_fh}, _internal => 1, data => $self,
            read => \&_stdout_ready, error => \&_stdout_ready,
            _callback_data_arg => 1,
        );
    }
    if ($self->{stderr_fh}) {
        $self->{stderr_watcher} = $loop->watch(
            fh => $self->{stderr_fh}, _internal => 1, data => $self,
            read => \&_stderr_ready, error => \&_stderr_ready,
            _callback_data_arg => 1,
        );
    }
    if ($self->{stdin_fh}) {
        if ($self->{stdin_closed}) {
            close delete $self->{stdin_fh};
        } else {
            $self->{stdin_watcher} = $loop->watch(
                fh => $self->{stdin_fh}, _internal => 1, data => $self,
                write => \&_stdin_ready, error => \&_stdin_error,
                _callback_data_arg => 1,
            );
            $self->{stdin_watcher}->disable_write
                if !@{ $self->{stdin_queue} };
            $self->_flush_stdin;
        }
    }
    return;
}

sub _stdout_ready ($self) { $self->_read_output('stdout', 0) }
sub _stderr_ready ($self) { $self->_read_output('stderr', 0) }

sub _read_output ($self, $name, $unbounded) {
    my $fh = $self->{"${name}_fh"} or return;
    my $maximum = $unbounded ? 0 : $self->{descriptor}{options}{max_reads_per_tick};
    if ($_PIPE_DRAIN_ENGINE eq 'native') {
        my $callback = $self->{descriptor}{callbacks}{"on_$name"};
        my ($status, $errno) = _drain_pipe(
            $self, $callback, fileno($fh),
            $self->{descriptor}{options}{read_size}, $maximum,
        );
        if ($status == 1) {
            $self->_close_output($name, 1);
        } elsif ($status == 2) {
            $self->_close_output($name, 1);
            $self->_report(Linux::Event::Error->new(
                type => 'process_io', operation => "read_$name",
                errno => $errno, message => _message($errno),
            ));
        }
        return;
    }
    my $reads = 0;
    while (!$maximum || $reads++ < $maximum) {
        my $count = sysread(
            $fh, my $bytes, $self->{descriptor}{options}{read_size},
        );
        if (defined($count) && $count > 0) {
            my $callback = $self->{descriptor}{callbacks}{"on_$name"};
            $callback->($self, $bytes) if $callback;
            next;
        }
        if (defined($count) && $count == 0) {
            $self->_close_output($name, 1);
            last;
        }
        last if $! == Errno::EAGAIN() || $! == Errno::EWOULDBLOCK();
        my $errno = 0 + $!;
        $self->_close_output($name, 1);
        $self->_report(Linux::Event::Error->new(
            type => 'process_io', operation => "read_$name", errno => $errno,
            message => _message($errno),
        ));
        last;
    }
    return;
}

sub _close_output ($self, $name, $fire_eof) {
    if (my $watcher = delete $self->{"${name}_watcher"}) {
        $watcher->cancel;
    }
    if (my $fh = delete $self->{"${name}_fh"}) {
        close $fh;
    }
    return if $self->{"${name}_closed"}++;
    my $callback = $self->{descriptor}{callbacks}{"on_${name}_eof"};
    $callback->($self) if $fire_eof && $callback;
    return;
}

sub write_stdin ($self, $bytes) {
    croak 'write_stdin(): stdin is not configured as a pipe'
        if $self->{mode} ne 'spawn' || $self->{stdio}{stdin} ne 'pipe';
    croak 'write_stdin(): stdin is closing or closed'
        if $self->{stdin_closing} || $self->{stdin_closed};
    croak 'write_stdin(): bytes must be a defined scalar'
        if !defined($bytes) || ref($bytes);
    $bytes = "$bytes";
    croak 'write_stdin(): bytes must be a byte string'
        if !utf8::downgrade($bytes, 1);
    return 1 if $bytes eq '';
    if ($self->{stdin_fh} && !@{ $self->{stdin_queue} }) {
        my ($written, $errno) = _write_pipe(fileno($self->{stdin_fh}), $bytes);
        return 1 if $written == length($bytes);
        if ($written > 0) {
            $bytes = substr($bytes, $written);
        } elsif ($errno != Errno::EAGAIN() && $errno != Errno::EWOULDBLOCK()) {
            $self->_stdin_failure($errno);
            return undef;
        }
    }
    return $self->_queue_stdin($bytes);
}

sub _queue_stdin ($self, $bytes) {
    my $pending = $self->{pending_stdin_bytes} + length($bytes);
    my $limit = $self->{descriptor}{options}{max_pending_stdin};
    if ($limit && $pending > $limit) {
        my $error = Linux::Event::Error->new(
            type => 'output_limit', operation => 'write_stdin',
            message => "pending stdin would exceed $limit bytes",
            pending_bytes => $pending, limit => $limit,
        );
        $self->_close_stdin_handle;
        $self->_report($error);
        return undef;
    }
    push @{ $self->{stdin_queue} }, $bytes;
    $self->{pending_stdin_bytes} = $pending;
    $self->{stdin_above_high} = 1
        if $pending > $self->{descriptor}{options}{stdin_high_watermark};
    $self->{stdin_watcher}->enable_write if $self->{stdin_watcher};
    return $self->{stdin_above_high} ? 0 : 1;
}

sub _stdin_ready ($self) { $self->_flush_stdin }
sub _stdin_error ($self) { $self->_stdin_failure(Errno::EPIPE()) }

sub _flush_stdin ($self) {
    my $fh = $self->{stdin_fh} or return;
    while (defined(my $bytes = $self->{stdin_queue}[0])) {
        my ($written, $errno) = _write_pipe(fileno($fh), $bytes);
        if ($written == length($bytes)) {
            shift @{ $self->{stdin_queue} };
            $self->{pending_stdin_bytes} -= length($bytes);
            next;
        }
        if ($written > 0) {
            substr($self->{stdin_queue}[0], 0, $written, '');
            $self->{pending_stdin_bytes} -= $written;
            next;
        }
        last if $errno == Errno::EAGAIN() || $errno == Errno::EWOULDBLOCK();
        $self->_stdin_failure($errno);
        return;
    }
    $self->{stdin_watcher}->disable_write
        if $self->{stdin_watcher} && !@{ $self->{stdin_queue} };
    if ($self->{stdin_above_high}
        && $self->{pending_stdin_bytes}
            <= $self->{descriptor}{options}{stdin_low_watermark}) {
        $self->{stdin_above_high} = 0;
        my $callback = $self->{descriptor}{callbacks}{on_stdin_drain};
        $callback->($self) if $callback;
    }
    $self->_close_stdin_handle
        if $self->{stdin_closing} && !@{ $self->{stdin_queue} };
    return;
}

sub _stdin_failure ($self, $errno) {
    $self->_close_stdin_handle;
    $self->_report(Linux::Event::Error->new(
        type => 'process_io', operation => 'write_stdin', errno => $errno,
        message => _message($errno),
    ));
    return;
}

sub _close_stdin_handle ($self) {
    if (my $watcher = delete $self->{stdin_watcher}) {
        $watcher->cancel;
    }
    if (my $fh = delete $self->{stdin_fh}) {
        close $fh;
    }
    $self->{stdin_closed} = 1;
    $self->{stdin_queue} = [];
    $self->{pending_stdin_bytes} = 0;
    return;
}

sub close_stdin ($self) {
    croak 'close_stdin(): stdin is not configured as a pipe'
        if $self->{mode} ne 'spawn' || $self->{stdio}{stdin} ne 'pipe';
    return $self if $self->{stdin_closing} || $self->{stdin_closed};
    $self->{stdin_closing} = 1;
    $self->_close_stdin_handle
        if $self->{stdin_fh} && !@{ $self->{stdin_queue} };
    return $self;
}

sub _pid_ready ($self) {
    return if $self->{state} ne 'running';
    if ($self->{reap}) {
        my $status = eval { _pidfd_reap($self->{pidfd}) };
        if ($@) {
            my $message = "$@";
            $self->_runtime_fail(Linux::Event::Error->new(
                type => 'process', operation => 'waitid',
                message => $message,
            ));
            return;
        }
        return if !defined $status;
        my ($code, $value) = @$status;
        if ($code == 1) {
            $self->{exit_code} = $value;
            $self->{raw_status} = $value << 8;
        } elsif ($code == 2 || $code == 3) {
            $self->{term_signal} = $value;
            $self->{core_dumped} = $code == 3 ? 1 : 0;
            $self->{raw_status} = $value | ($code == 3 ? 0x80 : 0);
        }
    }
    $self->{exit_observed} = 1;
    if (my $watcher = delete $self->{pid_watcher}) {
        $watcher->cancel;
    }
    if (defined(my $pidfd = delete $self->{pidfd})) {
        _close_fd($pidfd);
    }
    $self->_close_stdin_handle if !$self->{stdin_closed};
    my $failure;
    for my $name (qw(stdout stderr)) {
        my $drained = eval {
            $self->_read_output($name, 1) if $self->{"${name}_fh"};
            $self->_close_output($name, 1) if $self->{"${name}_fh"};
            1;
        };
        $failure //= $@ if !$drained;
        $self->_close_output($name, 0) if $self->{"${name}_fh"};
    }
    $self->{state} = 'exited';
    my $callback = $self->{descriptor}{callbacks}{on_exit};
    my $called = eval { $callback->($self); 1 };
    $failure //= $@ if !$called;
    undef $callback;
    $self->{descriptor} = undef;
    $self->{loop} = undef;
    die $failure if defined $failure;
    return;
}

sub _message ($errno) { local $! = $errno; return "$!" }

sub _report ($self, $error) {
    $self->{last_error} = $error;
    if (my $callback = $self->{descriptor}{callbacks}{on_error}) {
        $callback->($self, $error);
    } else {
        warn "$error\n";
    }
    return;
}

sub _runtime_fail ($self, $error) {
    $self->{state} = 'failed';
    $self->_release_handles;
    my $reported = eval { $self->_report($error); 1 };
    my $failure = $@;
    $self->{descriptor} = undef;
    $self->{loop} = undef;
    die $failure if !$reported;
    return;
}

sub _fork_preflight ($self, $mode, $loop) {
    croak "fork(): Process does not support '$mode'" if $mode ne 'drop';
    croak 'fork(): Process is not active in this Loop'
        if $self->{state} ne 'running' || !$self->{loop}
        || Scalar::Util::refaddr($self->{loop}) != Scalar::Util::refaddr($loop);
    return 1;
}

sub _fork_child_drop ($self, $loop) {
    delete @$self{qw(pid_watcher stdin_watcher stdout_watcher stderr_watcher)};
    if (defined(my $pidfd = delete $self->{pidfd})) {
        eval { _close_fd($pidfd) };
    }
    for my $name (qw(stdin stdout stderr)) {
        my $key = $name . '_fh';
        close delete $self->{$key} if $self->{$key};
    }
    $self->{stdin_queue} = [];
    $self->{pending_stdin_bytes} = 0;
    $self->{stdin_above_high} = 0;
    $self->{loop} = undef;
    $self->{descriptor} = undef;
    $self->{state} = 'not_inherited';
    return;
}

sub _release_handles ($self) {
    for my $name (qw(pid stdin stdout stderr)) {
        if (my $watcher = delete $self->{"${name}_watcher"}) {
            $watcher->cancel;
        }
    }
    if (defined(my $pidfd = delete $self->{pidfd})) {
        eval { _close_fd($pidfd) };
    }
    for my $name (qw(stdin stdout stderr)) {
        close delete $self->{"${name}_fh"} if $self->{"${name}_fh"};
    }
    $self->{stdin_queue} = [];
    $self->{pending_stdin_bytes} = 0;
    $self->{stdin_above_high} = 0;
    return;
}

sub signal ($self, $number) {
    croak 'signal(): Process is not running'
        if $self->{state} ne 'running' || !defined($self->{pidfd});
    croak 'signal(): signal must be a positive integer'
        if !defined($number) || ref($number) || $number !~ /\A\d+\z/
        || $number == 0;
    my $sent = eval {
        croak 'signal(): signal must be a valid Linux signal number'
            if $number > SIGRTMAX;
        _pidfd_send($self->{pidfd}, 0 + $number);
        1;
    };
    if (!$sent) {
        my $message = "$@";
        $message =~ s/\s+\z//;
        die Linux::Event::Error->new(
            type      => 'process',
            operation => 'signal',
            message   => $message || 'pidfd signal failed',
        );
    }
    return $self;
}

sub pid ($self) { $self->{pid} }
sub loop ($self) { $self->{loop} }
sub state ($self) { $self->{state} }
sub last_error ($self) { $self->{last_error} }
sub raw_status ($self) { $self->{raw_status} }
sub exit_code ($self) { $self->{exit_code} }
sub term_signal ($self) { $self->{term_signal} }
sub core_dumped ($self) { !!$self->{core_dumped} }
sub exited ($self) { $self->{state} eq 'exited' }
sub is_running ($self) { $self->{state} eq 'running' }
sub is_terminal ($self) {
    return $self->{state} eq 'exited' || $self->{state} eq 'failed'
        || $self->{state} eq 'not_inherited' || $self->{state} eq 'moved';
}
sub pending_stdin_bytes ($self) { $self->{pending_stdin_bytes} }

sub data ($self, @argument) {
    $self->{data} = $argument[0] if @argument;
    return $self->{data};
}

sub CLONE_SKIP ($class) { 1 }

sub DESTROY ($self) {
    $self->_release_handles if !$self->is_terminal;
    return;
}

1;
__END__

=head1 NAME

Linux::Event::Kernel::Process - Spawn or monitor processes through the event loop

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::Kernel::Process;

  my $loop = Linux::Event::Loop->new;

  my $process = Linux::Event::Kernel::Process->spawn(
      loop    => $loop,
      command => ['/usr/bin/printf', "hello\n"],
      stdout  => 'pipe',

      on_stdout => sub ($self, $bytes) {
          print "child said: $bytes";
      },

      on_exit => sub ($self) {
          say "exit code: " . $self->exit_code;
          $loop->stop;
      },
  );

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::Kernel::Process> integrates process lifecycle and optional
standard I/O with a L<Linux::Event::Loop>.

There are two main ways to use it:

=over 4

=item *

Spawn a new child with C<spawn>.

=item *

Observe an existing process with C<new(pid =E<gt> ...)>.

=back

A spawned Process can also manage asynchronous standard input, standard output,
and standard error.

Linux::Event uses Linux pidfds to track the actual process rather than relying
only on its numeric PID.

=head1 SPAWNING A CHILD

Use C<spawn> when Linux::Event should create the process:

  my $process = Linux::Event::Kernel::Process->spawn(
      loop    => $loop,
      command => ['/usr/bin/make', '-j4'],

      on_exit => sub ($self) {
          ...
      },
  );

C<command> is required.

C<on_exit> is also required unless the class provides an C<on_exit> method.

=head1 COMMAND ARGUMENTS

=head2 command

C<command> is an array reference containing the executable and its arguments:

  command => [
      '/usr/bin/git',
      'status',
      '--short',
  ]

Linux::Event does B<not> automatically insert a shell.

For example:

  command => ['echo', '$HOME']

passes the literal string C<$HOME> as an argument. It does not perform shell
variable expansion.

This is intentional and avoids shell quoting and injection surprises.

If shell syntax is actually desired, invoke a shell explicitly:

  command => [
      '/bin/sh',
      '-c',
      'printf "%s\n" "$HOME"',
  ]

=head1 WHEN THE CHILD IS ACTUALLY STARTED

A detached C<spawn> call creates a Process specification but does not
immediately start the child:

  my $process = Linux::Event::Kernel::Process->spawn(
      command => ['/usr/bin/sleep', '10'],

      on_exit => sub ($self) {
          ...
      },
  );

At this point, C<< $process->pid >> is undefined.

The child is created when the Process is attached:

  $loop->add($process);

If C<loop> is supplied to C<spawn>:

  my $process = Linux::Event::Kernel::Process->spawn(
      loop    => $loop,
      command => ['/usr/bin/sleep', '10'],

      on_exit => sub ($self) {
          ...
      },
  );

attachment happens as part of construction, so the child is started before
C<spawn> returns successfully.

=head1 WORKING DIRECTORY

=head2 cwd

Set the child's working directory with the top-level C<cwd> option:

  my $process = Linux::Event::Kernel::Process->spawn(
      loop    => $loop,
      command => ['/usr/bin/make'],
      cwd     => '/srv/project',

      on_exit => sub ($self) {
          ...
      },
  );

C<cwd> must be a non-empty path.

=head1 ENVIRONMENT

=head2 env

Supply a complete replacement environment:

  my $process = Linux::Event::Kernel::Process->spawn(
      loop    => $loop,
      command => ['/usr/bin/env'],

      env => {
          PATH       => '/usr/bin:/bin',
          BUILD_MODE => 'test',
      },

      on_exit => sub ($self) {
          ...
      },
  );

When C<env> is supplied, it B<replaces> the child's complete environment. It is
not merged with C<%ENV> automatically.

To inherit the current environment, omit C<env>.

If a mostly inherited environment with a few changes is desired, construct that
hash explicitly:

  env => {
      %ENV,
      BUILD_MODE => 'test',
  }

=head1 STANDARD I/O

The C<stdin>, C<stdout>, and C<stderr> options are top-level C<spawn> options:

  my $process = Linux::Event::Kernel::Process->spawn(
      loop    => $loop,
      command => ['/usr/bin/some-program'],

      stdin  => 'pipe',
      stdout => 'pipe',
      stderr => 'pipe',

      on_stdout => sub ($self, $bytes) {
          ...
      },

      on_stderr => sub ($self, $bytes) {
          ...
      },

      on_exit => sub ($self) {
          ...
      },
  );

Each standard stream defaults to C<inherit>.

=head2 inherit

  stdout => 'inherit'

The child inherits the corresponding parent standard descriptor.

Linux::Event does not create a Process pipe for it.

=head2 pipe

  stdout => 'pipe'

Linux::Event creates a pipe and manages the parent end asynchronously.

Use this when application callbacks should receive output or write child input.

=head2 null

  stdout => 'null'

Connect that child descriptor to C</dev/null>.

=head2 Filehandle

A caller-provided filehandle may be used directly:

  stdout => $log_fh

The child receives that descriptor.

The caller retains ownership of its original Perl filehandle.

=head2 stderr => stdout

Child stderr may be merged into child stdout:

  stdout => 'pipe',
  stderr => 'stdout',

Both streams then use the child's stdout destination.

=head1 READING CHILD STDOUT

To receive stdout, configure C<stdout =E<gt> 'pipe'> and provide
C<on_stdout>:

  my $process = Linux::Event::Kernel::Process->spawn(
      loop    => $loop,
      command => ['/usr/bin/some-program'],
      stdout  => 'pipe',

      on_stdout => sub ($self, $bytes) {
          print "stdout: $bytes";
      },

      on_exit => sub ($self) {
          ...
      },
  );

=head2 on_stdout

  on_stdout => sub ($self, $bytes) {
      ...
  }

C<$bytes> contains the next available chunk of stdout.

It is a byte stream. One callback does not necessarily correspond to one line
or one write performed by the child.

If line-oriented parsing is desired, the application must provide that parsing
or use an appropriate abstraction above Process.

=head1 READING CHILD STDERR

Configure:

  stderr => 'pipe'

and provide:

  on_stderr => sub ($self, $bytes) {
      warn "stderr: $bytes";
  }

As with stdout, callback boundaries are read boundaries rather than message or
line boundaries.

=head1 OUTPUT EOF CALLBACKS

Optional callbacks may detect the end of each output pipe:

  on_stdout_eof => sub ($self) {
      say "stdout closed";
  }

  on_stderr_eof => sub ($self) {
      say "stderr closed";
  }

These callbacks require the corresponding descriptor to be configured as
C<pipe>.

=head1 WRITING CHILD STDIN

Configure:

  stdin => 'pipe'

Then write with:

=head2 write_stdin

  $process->write_stdin("hello\n");

Linux::Event attempts to write immediately.

If the child cannot currently accept all the bytes, the remainder is queued and
written later.

Output order is preserved.

C<write_stdin> may even be used while a spawned Process is still detached:

  my $process = Linux::Event::Kernel::Process->spawn(
      command => ['/usr/bin/my-program'],
      stdin   => 'pipe',

      on_exit => sub ($self) {
          ...
      },
  );

  $process->write_stdin("initial input\n");

  $loop->add($process);

The queued bytes are written after the child is started and the pipe is
attached.

=head1 CLOSING CHILD STDIN

=head2 close_stdin

  $process->close_stdin;

C<close_stdin> is graceful.

It:

=over 4

=item *

Rejects new C<write_stdin> calls.

=item *

Allows already accepted bytes to drain.

=item *

Closes the child's stdin pipe after those bytes have drained.

=back

Closing the pipe delivers EOF to the child.

For example:

  $process->write_stdin($request);
  $process->close_stdin;

=head1 STDIN BACKPRESSURE

Process stdin has high- and low-watermark flow control.

When queued stdin grows beyond the high watermark, C<write_stdin> begins
returning false.

The bytes are still accepted unless the hard pending-input limit would be
exceeded.

When the queue later falls to the low watermark, C<on_stdin_drain> fires:

  on_stdin_drain => sub ($self) {
      # It is reasonable to produce more child input again.
  }

=head2 pending_stdin_bytes

  my $bytes = $process->pending_stdin_bytes;

Return the number of bytes currently waiting to be written to child stdin.

=head1 EXIT CALLBACK

=head2 on_exit

Every Process requires an effective C<on_exit> callback:

  on_exit => sub ($self) {
      ...
  }

C<on_exit> runs after Linux::Event observes the process exit.

For a spawned child with stdout or stderr pipes, Linux::Event first drains bytes
that are already available at the current nonblocking boundary and closes its
remaining Process-owned stdio handles.

Then C<on_exit> runs.

The owning Loop is still available during the callback:

  on_exit => sub ($self) {
      $self->loop->stop;
  }

After C<on_exit> completes, the Process releases its Loop reference.

=head1 EXIT STATUS

For a child whose status Linux::Event reaps, inspect the termination result with
the following methods.

=head2 exit_code

  my $code = $process->exit_code;

Defined when the child exited normally:

  on_exit => sub ($self) {
      if (defined(my $code = $self->exit_code)) {
          say "exited with code $code";
      }
  }

=head2 term_signal

  my $signal = $process->term_signal;

Defined when the process was terminated by a signal:

  on_exit => sub ($self) {
      if (defined(my $signal = $self->term_signal)) {
          say "terminated by signal $signal";
      }
  }

=head2 core_dumped

  if ($process->core_dumped) {
      ...
  }

Return true when the recorded wait status indicates that termination produced a
core dump.

=head2 raw_status

  my $status = $process->raw_status;

Return the conventional raw wait-status value when Linux::Event owns and
obtains that status.

=head2 exited

  if ($process->exited) {
      ...
  }

Return true after a normal observed process exit.

=head1 SENDING A SIGNAL TO THE PROCESS

=head2 signal

Send a Linux signal using the Process's pidfd:

  use POSIX qw(SIGTERM);

  $process->signal(SIGTERM);

C<signal> returns the Process object.

Linux::Event uses C<pidfd_send_signal> rather than merely doing:

  kill $signal, $pid;

This matters because a pidfd identifies the specific process instance.

A reused numeric PID cannot accidentally redirect the signal to an unrelated
later process.

=head1 THERE IS NO GENERIC cancel

Process deliberately does not provide:

  $process->cancel;

because several very different actions could be meant by "cancel":

=over 4

=item *

Stop sending stdin.

=item *

Stop observing the child.

=item *

Ask the child to terminate politely.

=item *

Kill the child immediately.

=item *

Reap an exited child.

=back

Linux::Event does not guess which policy the application wants.

For example, graceful shutdown might begin with:

  $process->signal(SIGTERM);

The application then continues running the Loop until C<on_exit> confirms that
the process actually exited.

=head1 OBSERVING AN EXISTING PROCESS

Use C<new> rather than C<spawn> when the process already exists:

  my $process = Linux::Event::Kernel::Process->new(
      loop => $loop,
      pid  => $pid,

      on_exit => sub ($self) {
          say "process exited";
      },
  );

C<pid> is required.

No stdin, stdout, or stderr management is provided in this mode.

The object observes lifecycle through a pidfd.

=head1 REAPING AN OBSERVED PROCESS

=head2 reap

The default is:

  reap => 1

This means Linux::Event owns obtaining the child's wait status.

Use this for a process that is actually a child of the current process and whose
wait status should be owned by this Process object:

  my $process = Linux::Event::Kernel::Process->new(
      loop => $loop,
      pid  => $child_pid,
      reap => 1,

      on_exit => sub ($self) {
          say $self->exit_code;
      },
  );

Do not also use an independent C<wait>, C<waitpid>, or C<SIGCHLD> reaper for
that same child.

=head2 reap => 0

For a process whose wait status belongs elsewhere:

  my $process = Linux::Event::Kernel::Process->new(
      loop => $loop,
      pid  => $pid,
      reap => 0,

      on_exit => sub ($self) {
          say "process is gone";
      },
  );

Linux::Event observes pidfd lifecycle but does not reap the process.

In that mode, decoded wait-status methods such as C<exit_code>,
C<term_signal>, and C<raw_status> remain undefined.

This is useful for a non-child process or when another component owns reaping.

=head1 PID

=head2 pid

  my $pid = $process->pid;

Return the numeric process ID.

For an attached observed Process, this is the PID supplied to C<new>.

For a spawned Process, it becomes available after the child has actually been
created.

A detached spawn specification therefore has no PID yet.

=head1 ATTACHING TO A LOOP

Both spawning and observation may be configured detached.

For a spawn:

  my $process = Linux::Event::Kernel::Process->spawn(
      command => ['/usr/bin/sleep', '5'],

      on_exit => sub ($self) {
          ...
      },
  );

  $loop->add($process);

For an existing PID:

  my $process = Linux::Event::Kernel::Process->new(
      pid => $pid,

      on_exit => sub ($self) {
          ...
      },
  );

  $loop->add($process);

Supplying C<loop =E<gt> $loop> performs that attachment during construction.

=head1 CONSTRUCTOR CALLBACKS OR SUBCLASS METHODS

Callbacks can be supplied directly:

  my $process = Linux::Event::Kernel::Process->spawn(
      command => ['/usr/bin/make'],
      stdout  => 'pipe',

      on_stdout => sub ($self, $bytes) {
          print $bytes;
      },

      on_exit => sub ($self) {
          ...
      },
  );

or implemented in a subclass:

  package BuildProcess;

  use parent 'Linux::Event::Kernel::Process';

  sub on_stdout ($self, $bytes) {
      print "build: $bytes";
  }

  sub on_stderr ($self, $bytes) {
      warn "build: $bytes";
  }

  sub on_exit ($self) {
      if (defined(my $code = $self->exit_code)) {
          say "build exited with $code";
      }
      else {
          say "build received signal " . $self->term_signal;
      }
  }

A constructor callback overrides a same-named subclass method for that Process.

=head1 CALLBACKS

The complete callback set is:

=over 4

=item C<on_exit($self)>

Required. The process exit was observed.

=item C<on_stdout($self, $bytes)>

Optional. Requires C<stdout =E<gt> 'pipe'>.

=item C<on_stderr($self, $bytes)>

Optional. Requires C<stderr =E<gt> 'pipe'>.

=item C<on_stdout_eof($self)>

Optional. The child stdout pipe reached EOF.

Requires C<stdout =E<gt> 'pipe'>.

=item C<on_stderr_eof($self)>

Optional. The child stderr pipe reached EOF.

Requires C<stderr =E<gt> 'pipe'>.

=item C<on_stdin_drain($self)>

Optional. Pending stdin fell to the configured low watermark after
high-watermark backpressure.

Requires C<stdin =E<gt> 'pipe'>.

=item C<on_error($self, $error)>

Optional. An asynchronous Process or stdio error occurred.

C<$error> is a L<Linux::Event::Error>.

=back

=head1 ERROR HANDLING

=head2 on_error

An asynchronous error may be handled with:

  on_error => sub ($self, $error) {
      warn "child error: $error\n";
  }

Linux::Event also retains the most recent error.

=head2 last_error

  my $error = $process->last_error;

When no C<on_error> callback exists, Linux::Event warns about asynchronous
Process errors.

Some synchronous API failures, such as failure of C<signal>, are thrown
directly as structured L<Linux::Event::Error> objects.

=head1 APPLICATION DATA

=head2 data

Attach arbitrary application state:

  my $process = Linux::Event::Kernel::Process->spawn(
      command => ['/usr/bin/make'],

      data => {
          build_id => 42,
      },

      on_exit => sub ($self) {
          say "finished build " . $self->data->{build_id};
      },
  );

Retrieve or replace it with:

  my $data = $process->data;

  $process->data($new_data);

=head1 PROCESS STATE

=head2 state

  my $state = $process->state;

Common lifecycle states are C<unattached>, C<running>, C<exited>, and
C<failed>.

A Process discarded from a managed-fork child uses C<not_inherited> as its
terminal state there.

=head2 is_running

  if ($process->is_running) {
      ...
  }

Return true while the Process is actively being monitored.

=head2 is_terminal

  if ($process->is_terminal) {
      ...
  }

Return true after normal exit, terminal failure, or a managed-fork disposition
that makes the object unusable in the current process.

=head1 LOOP OWNERSHIP

The Loop retains a running Process.

Dropping the application's reference does not silently stop process monitoring.

Conversely, destroying the Loop does B<not> choose a signal and kill the child
for you.

Process shutdown policy belongs to the application.

If your program owns children that must be reaped, keep the Loop running until
their C<on_exit> callbacks confirm completion.

=head1 PROCESS I/O TUNING

Process stdout/stderr and stdin queue policy have their own Process-specific
settings.

They are B<not> placed inside a nested C<tuning> hash.

Reusable defaults belong in a Process subclass through C<process_options>:

  package BuildProcess;

  use parent 'Linux::Event::Kernel::Process';

  sub process_options ($class) {
      return (
          read_size          => 131_072,
          max_reads_per_tick => 32,
          max_pending_stdin  => 8_388_608,
      );
  }

For one spawned Process, the same option names may instead be supplied directly
as top-level C<spawn> options:

  my $process = BuildProcess->spawn(
      command => ['/usr/bin/make'],
      stdout  => 'pipe',
      stdin   => 'pipe',

      read_size          => 32_768,
      max_reads_per_tick => 16,
      max_pending_stdin  => 2_097_152,

      on_exit => sub ($self) {
          ...
      },
  );

Direct C<spawn> values override the subclass defaults for that object.

=head2 read_size

Default: C<65_536>.

Maximum number of bytes in one stdout or stderr read callback payload.

=head2 max_reads_per_tick

Default: C<64>.

Maximum number of successful reads from each active child output pipe during
one readiness dispatch.

This is a fairness control so one noisy child cannot monopolize the Loop
indefinitely.

=head2 stdin_high_watermark

Default: C<1_048_576>.

Pending-stdin level above which C<write_stdin> starts returning false to signal
backpressure.

The bytes are still accepted unless the hard limit would be exceeded.

=head2 stdin_low_watermark

Default: C<262_144>.

After high-watermark backpressure has occurred, C<on_stdin_drain> fires when
pending stdin falls to or below this value.

It may not exceed C<stdin_high_watermark>.

=head2 max_pending_stdin

Default: C<0>.

Hard limit on queued stdin bytes.

Zero means no hard queue limit.

If a nonzero hard limit would be exceeded, the unsent bytes are rejected,
Process stdin is closed according to the Process error contract, and an
C<output_limit> error is reported.

=head1 SPAWN FAILURE SAFETY

Linux::Event spawning is designed so arbitrary Perl application code does not
run in a post-fork child setup path.

Native spawning establishes the configured descriptors, environment, and
working directory.

If the child has been created but Linux::Event cannot complete its Process
setup, Linux::Event kills and reaps that exact child before propagating the
setup failure.

Partially created Process-owned descriptors are also cleaned up.

This avoids leaving an accidentally unmanaged child behind after a failed
attachment.

=head1 PIDFD PROCESS IDENTITY

A numeric PID can eventually be reused by Linux.

Process therefore opens or receives a pidfd and uses that kernel process
identity for lifecycle notification.

C<signal> also uses the pidfd.

This avoids the following race:

=over 4

=item 1.

Process A exits.

=item 2.

Its numeric PID is reused by process B.

=item 3.

Application code signals the old numeric PID.

=item 4.

Process B receives the signal accidentally.

=back

The pidfd continues to refer to the intended process instance.

=head1 LOOP-AWARE FORKING

Process currently supports only the default parent-only behavior during
L<Linux::Event::Loop> managed C<fork>.

It does not currently support C<share>, C<clone>, or C<move>.

An active Process should therefore be omitted from those disposition lists:

  my $pid = $loop->fork(
      clone => [$timer],
  );

The Process remains active in the parent.

Its inherited child-side Loop registrations, pidfd, Process-owned stdio
handles, callback state, and queued stdin are discarded during child
reconstruction.

The child copy becomes terminal with state C<not_inherited>.

This does not kill the real process being monitored by the parent.

=head1 PLATFORM

Process uses Linux pidfds.

The lifecycle and status path targets Linux 5.4 or newer.

The distribution also requires the build and libc support used by its native
process-spawn implementation.

There is intentionally no fallback that runs arbitrary Perl child setup code
after a traditional fork merely to support older process facilities.

=head1 IMPLEMENTATION MODEL

One Process object owns the pieces associated with one process:

=over 4

=item *

Pidfd lifecycle notification.

=item *

Optional stdin pipe.

=item *

Optional stdout pipe.

=item *

Optional stderr pipe.

=item *

Pending stdin queue state.

=item *

Decoded exit status.

=item *

Process callbacks.

=item *

Application C<data>.

=back

The child pipe descriptors are implementation details of the Process resource;
they are not exposed as separate public L<Linux::Event::IO::Pipe> objects.

Use L<Linux::Event::IO::Pipe> directly when the application independently owns
an unrelated pipe.

=head1 PERFORMANCE MODEL

Stdout and stderr mechanical read draining is handled below the semantic Perl
callback boundary.

Each successful read still reaches the configured application callback as a
byte string, while C<read_size> and C<max_reads_per_tick> preserve application
chunking and fairness policy.

Callback methods and C<process_options> are resolved and cached by concrete
subclass. Constructor callbacks override them for one Process without adding
per-event method lookup.

These details normally require no application action.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::Kernel::Signal>,
L<Linux::Event::Error>,
F<docs/PROCESS-DESIGN.md>.

=cut
