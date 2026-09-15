package Linux::Event::Kernel::Process;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.114';

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
    return $self->{state} eq 'exited' || $self->{state} eq 'failed';
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

Linux::Event::Kernel::Process - pidfd process lifecycle and asynchronous stdio

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::Kernel::Process;

  my $loop = Linux::Event::Loop->new;
  my $worker = Linux::Event::Kernel::Process->spawn(
      loop    => $loop,
      command => [$^X, '-e', 'print "hello\\n"'],
      stdout  => 'pipe',
      on_stdout => sub ($process, $bytes) {
          print $bytes;
      },
      on_exit => sub ($process) {
          say 'exit code: ' . $process->exit_code
              if defined $process->exit_code;
          $process->loop->stop;
      },
  );
  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::Kernel::Process> is the public process leaf. One object combines
process creation or observation, pidfd identity-safe lifecycle notification,
optional asynchronous stdin/stdout/stderr, decoded exit status, and
pidfd-based signaling.

Linux::Event uses C<posix_spawnp> for spawned children and never runs Perl code
in a post-fork child. pidfd operations avoid directing signals or lifecycle
state at an unrelated process after numeric PID reuse.

=head1 CALLBACKS, SUBCLASSING, AND TUNING

C<new> accepts C<on_exit> and C<on_error> as constructor coderefs. C<spawn>
also accepts the stdout, stderr, EOF, and stdin-drain callbacks listed below.
Closures are convenient for per-process lexical state; subclasses provide
reusable named behavior and a single place for Process I/O tuning:

  package BuildProcess;
  use parent 'Linux::Event::Kernel::Process';

  sub on_stdout ($process, $bytes) { print "build: $bytes" }
  sub on_exit ($process) { report_status($process) }

C<process_options> also configures stdin high/low watermarks and the maximum
pending stdin bound. Linux::Event validates and caches this policy and the
class callbacks once per subclass. Constructor callbacks override same-named
methods for one object and are retained once in its effective descriptor; no
event-time method lookup or callback-style branch is added.

=head2 process_options

Define C<process_options> as a class method on the Process subclass. It returns
key/value pairs, or one hash reference:

  package BuildProcess;
  use parent 'Linux::Event::Kernel::Process';

  sub process_options ($class) {
      return (
          read_size            => 131_072,
          max_reads_per_tick   => 32,
          max_pending_stdin    => 8_388_608,
      );
  }

C<spawn> accepts the same names as per-process overrides. The complete option
set is:

=over 4

=item * C<read_size> (default 65,536)

Positive maximum byte size of one stdout or stderr callback payload.

=item * C<max_reads_per_tick> (default 64)

Positive maximum successful reads from each child output pipe during one
readiness dispatch, providing fairness between active resources.

=item * C<stdin_high_watermark> (default 1,048,576)

Non-negative pending-stdin byte level at which C<write_stdin> begins returning
false while still accepting the bytes.

=item * C<stdin_low_watermark> (default 262,144)

Non-negative pending-stdin byte level at or below which C<on_stdin_drain>
fires after high-watermark backpressure. It must not exceed
C<stdin_high_watermark>.

=item * C<max_pending_stdin> (default 0)

Hard non-negative pending-stdin byte limit. Zero means unbounded.

=back

Linux::Event validates and caches these integer values once per concrete
subclass.

=head1 SPAWNING

C<spawn> accepts a command argument vector and does not insert a shell:

  my $process = Linux::Event::Kernel::Process->spawn(
      loop    => $loop,                       # optional
      command => ['/usr/bin/make', '-j4'],    # required
      cwd     => '/srv/project',              # optional
      env     => { BUILD_MODE => 'test' },    # optional replacement env
      stdin   => 'pipe',                      # optional
      stdout  => 'pipe',                      # optional
      stderr  => 'pipe',                      # optional
      data    => $state,                      # optional
      on_stdout => sub ($process, $bytes) { print $bytes },
      on_exit   => sub ($process) { $process->loop->stop },
  );

Construction is side-effect free while detached. The child is created when the
object attaches through C<loop =E<gt> $loop> or C<< $loop->add($process) >>.
Consequently C<pid> is undefined before attachment.

C<env> replaces the complete environment when supplied; omit it to inherit the
current environment. Use an explicit shell in C<command> only when shell syntax
is intentionally required.

=head1 STANDARD I/O

Each stdio option accepts C<inherit>, C<pipe>, C<null>, or a caller filehandle.
C<stderr> may additionally be C<stdout> to merge child stderr into child
stdout.

Pipe callbacks are:

  sub on_stdout ($process, $bytes) { ... }
  sub on_stdout_eof ($process) { ... }
  sub on_stderr ($process, $bytes) { ... }
  sub on_stderr_eof ($process) { ... }
  sub on_stdin_drain ($process) { ... }

Readable child pipes are drained by the native process I/O helper while
preserving C<read_size> callback chunking and C<max_reads_per_tick> fairness.

C<write_stdin($bytes)> writes immediately when possible and queues the remainder.
High/low watermarks provide cooperative flow control and C<max_pending_stdin>
can impose a hard safety bound. C<close_stdin> drains already accepted input,
then closes the child's input pipe to deliver EOF.

=head1 OBSERVING AN EXISTING PROCESS

An existing PID may be observed instead of spawned:

  my $process = Linux::Event::Kernel::Process->new(
      pid  => $pid,
      reap => 1,
      on_exit => sub ($process) { ... },
  );
  $loop->add($process);

C<reap =E<gt> 1> is the default and requires a child process whose status this
object owns. C<reap =E<gt> 0> permits lifecycle notification for a non-child but
leaves decoded wait-status fields undefined.

=head1 EXIT CALLBACK AND STATUS

A subclass defines C<on_exit($process)>, or construction supplies
C<on_exit =E<gt> sub ($process) { ... }>. When a reaped child exits,
Linux::Event records either C<exit_code> or C<term_signal>, plus the core-dump
flag and conventional raw wait status. Remaining available stdout/stderr bytes
are drained before C<on_exit>.

The Loop remains available during C<on_exit> and is released after callback
completion. Callback exceptions propagate after native cleanup.

=head1 SIGNALS

C<signal($number)> uses C<pidfd_send_signal> rather than a bare numeric PID and
returns the Process object. Failures are structured L<Linux::Event::Error>
values.

There is deliberately no generic C<cancel>. Stopping observation, closing
stdin, asking a child to terminate, and confirming process exit are distinct
operations. Applications choose an explicit signal and continue running the
Loop until C<on_exit> confirms lifecycle completion.

=head1 ERRORS AND OWNERSHIP

Optional C<on_error($process, $error)> receives asynchronous process or stdio
failures. Without it Linux::Event warns and retains C<last_error>.

The Loop retains a running Process. Destroying the Loop closes Linux::Event
resources but does not secretly kill the child. Spawned processes and observed
children with C<reap =E<gt> 1> exclusively own their wait status; do not also
use a competing C<waitpid> or SIGCHLD reaper for the same child.

=head1 PLATFORM

Process requires Linux pidfd support and build headers for C<pidfd_open> and
C<pidfd_send_signal>. The runtime lifecycle/status path targets Linux 5.4 or
newer. The build also requires libc support for
C<posix_spawn_file_actions_addchdir_np>.

=head1 SEE ALSO

L<Linux::Event::Loop>, F<docs/PROCESS-DESIGN.md>.

=cut
