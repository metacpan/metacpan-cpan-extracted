package LibTmux::Transport;
use v5.44;
use POSIX qw(:sys_wait_h :signal_h setpgid _exit);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK F_SETFD FD_CLOEXEC);
use IO::Select;
use Errno        qw(EINTR EAGAIN EWOULDBLOCK ECHILD EPIPE ESRCH);
use Time::HiRes  qw(clock_gettime CLOCK_MONOTONIC);
use JSON::PP     ();
use MIME::Base64 qw(encode_base64 decode_base64);
use Encode       qw(encode FB_CROAK LEAVE_SRC);
use Scalar::Util qw(blessed);
use LibTmux::X;
use LibTmux::CommandResult;

sub _now () { clock_gettime(CLOCK_MONOTONIC) }

sub _nonblock ($fh) {
    my $flags = fcntl($fh, F_GETFL, 0);
    die "fcntl: $!"
        unless defined($flags)
        && defined fcntl($fh, F_SETFL, $flags | O_NONBLOCK);
}

sub _pipe () {
    pipe(my $read, my $write) or die "pipe: $!";
    binmode $read;
    binmode $write;
    fcntl($_, F_SETFD, FD_CLOEXEC) // die "close-on-exec: $!"
        for ($read, $write);
    return ($read, $write);
}

sub _configuration ($class, %args) {
    $args{timeout}    //= 5;
    $args{max_output} //= 8 * 1024 * 1024;
    LibTmux::X::InvalidArgument->throw(
        message => 'timeout must be positive decimal seconds, at most 86400')
        unless !ref($args{timeout})
        && "$args{timeout}" =~ /\A(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)\z/
        && $args{timeout} > 0
        && $args{timeout} <= 86400;
    LibTmux::X::InvalidArgument->throw(
        message => 'max_output must be an integer from 1 to 1073741824')
        unless !ref($args{max_output})
        && "$args{max_output}" =~ /\A[1-9][0-9]*\z/
        && length("$args{max_output}") <= 10
        && $args{max_output} <= 1073741824;
    $args{env} //= {};
    LibTmux::X::InvalidArgument->throw(
        message => 'env must be a hash reference')
        unless ref($args{env}) eq 'HASH';
    for my $key (keys $args{env}->%*) {
        my $value = $args{env}{$key};
        LibTmux::X::InvalidArgument->throw(
            message => 'environment names and values must be NUL-free scalars')
            if !length($key)
            || $key =~ /[=\0]/
            || !defined($value)
            || ref($value)
            || $value =~ /\0/;
    }
    return %args;
}

sub _arguments ($class, %args) {
    %args = $class->_configuration(%args);
    my $argv = $args{argv};
    LibTmux::X::InvalidArgument->throw(
        message => 'argv must be a nonempty array')
        unless ref($argv) eq 'ARRAY' && @$argv;
    my @argv;
    for my $arg (@$argv) {
        LibTmux::X::InvalidArgument->throw(
            message => 'arguments must be defined NUL-free scalars')
            if !defined($arg) || ref($arg) || index($arg, "\0") >= 0;
        push @argv,
            utf8::is_utf8($arg)
            ? encode('UTF-8', $arg, FB_CROAK | LEAVE_SRC)
            : "$arg";
    }
    $args{argv} = \@argv;
    $args{timeout}    //= 5;
    $args{max_output} //= 8 * 1024 * 1024;
    $args{stdin}      //= '';
    LibTmux::X::InvalidArgument->throw(message => 'stdin must contain octets')
        if ref($args{stdin}) || utf8::is_utf8($args{stdin});
    LibTmux::X::Unsupported->throw(
        message => 'SIGCHLD=IGNORE prevents reliable process status')
        if defined($SIG{CHLD}) && !ref($SIG{CHLD}) && $SIG{CHLD} eq 'IGNORE';
    LibTmux::X::InvalidArgument->throw(
        message => 'cancel_fh must be an open handle')
        if exists($args{cancel_fh}) && !defined(fileno($args{cancel_fh}));
    return %args;
}

sub start ($class, %args) {
    require LibTmux::ProcessJob;
    return LibTmux::ProcessJob->start(%args);
}
sub run ($class, %args) { $class->start(%args)->wait }

sub _supervise ($args, $alive_r, $result_w) {
    require LibTmux::Platform::Linux;
    LibTmux::Platform::Linux::_subreaper();
    my ($in_r, $in_w)     = _pipe();
    my ($out_r, $out_w)   = _pipe();
    my ($err_r, $err_w)   = _pipe();
    my ($exec_r, $exec_w) = _pipe();
    my ($go_r, $go_w)     = _pipe();
    my @signals = (SIGCHLD, SIGINT, SIGTERM);
    my $block   = POSIX::SigSet->new(@signals);
    my $old     = POSIX::SigSet->new;
    POSIX::sigprocmask(SIG_BLOCK, $block, $old)
        // die "block supervisor signals: $!";
    local $SIG{CHLD} = 'DEFAULT';
    local $SIG{INT}  = 'DEFAULT';
    local $SIG{TERM} = 'DEFAULT';
    my $notice_r = LibTmux::Platform::Linux::_signal_handle(@signals);
    fcntl($notice_r, F_SETFD, FD_CLOEXEC) // die "signal close-on-exec: $!";
    _nonblock($_)
        for ($in_w, $out_r, $err_r, $exec_r, $notice_r, $alive_r);
    my $reason;

    # Allocate every pipe before raw descriptor closure. PerlIO still tracks
    # inherited handles; reusing their numbers can retain protocol pipe ends.
    LibTmux::Platform::Linux::_close_fds_except(
        $alive_r,           $result_w,
        $args->{_cancel_r}, $in_r,
        $in_w,              $out_r,
        $out_w,             $err_r,
        $err_w,             $exec_r,
        $exec_w,            $go_r,
        $go_w,              $notice_r,
        exists($args->{cancel_fh}) ? ($args->{cancel_fh}) : ()
    );
    my $pid = fork();
    die "fork program: $!" unless defined $pid;
    if (!$pid) {
        $SIG{CHLD} = 'DEFAULT';
        $SIG{INT}  = 'DEFAULT';
        $SIG{TERM} = 'DEFAULT';
        $SIG{PIPE} = 'DEFAULT';
        close $in_w;
        close $out_r;
        close $err_r;
        close $exec_r;
        close $go_w;
        close $notice_r;
        close $alive_r;
        close $args->{_cancel_r} if $args->{_cancel_r};
        my $fail =
            sub ($message) { syswrite($exec_w, 'E' . $message); _exit(127) };
        POSIX::sigprocmask(SIG_SETMASK, $old)
            // $fail->("restore program signal mask: $!");
        my $group = setpgid(0, 0);
        $fail->("setpgid: $!") unless defined($group) && $group == 0;
        syswrite($exec_w, 'G') == 1 or _exit(127);
        my $n;
        do { $n = sysread($go_r, my $unused, 1) }
            while (!defined($n) && $! == EINTR);
        _exit(127) unless defined($n) && $n == 1;
        close $go_r;
        open STDIN,  '<&', $in_r  or $fail->("stdin: $!");
        open STDOUT, '>&', $out_w or $fail->("stdout: $!");
        open STDERR, '>&', $err_w or $fail->("stderr: $!");
        close $in_r;
        close $out_w;
        close $err_w;
        try { LibTmux::Platform::Linux::_close_fds_except($exec_w) }
        catch ($error) { $fail->("$error") }
        %ENV = (%ENV, %{$args->{env} // {}});
        delete @ENV{qw(TMUX TMUX_PANE)};
        exec {$args->{argv}[0]} $args->{argv}->@* or $fail->("exec: $!");
    }
    close $in_r;
    close $out_w;
    close $err_w;
    close $exec_w;
    close $go_r;
    setpgid($pid, $pid);

    # Kernel signal readiness survives the final Perl safe point before
    # select. A deferred Perl handler writing a self-pipe does not.
    my $reads = IO::Select->new($out_r, $err_r, $exec_r, $notice_r, $alive_r);
    $reads->add($args->{cancel_fh}) if exists $args->{cancel_fh};
    $reads->add($args->{_cancel_r}) if $args->{_cancel_r};
    my $writes = IO::Select->new;
    if   (length $args->{stdin}) { $writes->add($in_w) }
    else                         { close $in_w }
    my %stream = (
        fileno($out_r)  => 'stdout',
        fileno($err_r)  => 'stderr',
        fileno($exec_r) => 'exec'
    );
    my %data = (stdout => '', stderr => '', exec => '');
    my ($offset,     $done, $group_ready, $released, $killed) = (0, 0, 0, 0, 0);
    my ($raw_status, $grace, $cleanup_deadline);
    my ($group_complete, $direct_reaped) = (false, false);
    my $deadline = _now() + $args->{timeout};
    my $terminate =
        sub ($signal) { kill $signal, ($group_ready ? -$pid : $pid) };

    while (!$done || keys %stream || !$group_complete) {
        my $waited = waitpid($pid, WNOHANG);
        if ($waited == $pid) {
            $raw_status    = $?;
            $done          = 1;
            $direct_reaped = true;
        }
        elsif ($waited < 0 && $! == ECHILD && !$done) {
            $reason //= 'Transport';
            $raw_status = undef;
            $done       = 1;
        }
        my $now = _now();
        if ($done) {
            if (!$group_ready) { $group_complete = true }
            else {
                my $adopted;
                do { $adopted = waitpid(-$pid, WNOHANG) }
                    while $adopted > 0 || ($adopted < 0 && $! == EINTR);
                $group_complete = true
                    if $adopted < 0
                    && $! == ECHILD
                    && !kill(0, -$pid)
                    && $! == ESRCH;
                $reason //= 'Transport' unless $group_complete;
            }
        }
        $reason //= 'Timeout' if $now >= $deadline;
        if ($reason && !defined $grace) {
            $terminate->('TERM');
            $grace            = $now + 0.05;
            $cleanup_deadline = $now + 0.55;
            if ($writes->count) { $writes->remove($in_w); close $in_w }
            close $go_w if !$released && defined fileno($go_w);
        }
        if (defined($grace) && $now >= $grace && !$killed) {
            $terminate->('KILL');
            $killed = 1;
        }
        last if $done && $group_complete && ($reason || !keys(%stream));
        if (defined($cleanup_deadline) && $now >= $cleanup_deadline) {
            $reason = 'Transport';
            last;
        }
        my $until =
            defined($grace)
            ? ($killed ? $cleanup_deadline : $grace)
            : $deadline;
        my ($ready_r, $ready_w) = IO::Select->select($reads, $writes, undef,
            ($until > $now ? $until - $now : 0));
        next unless defined $ready_r;
        for my $fh (@$ready_r) {
            my $fd = fileno($fh);
            my $n  = sysread($fh, my $chunk, 65536);
            next
                if !defined($n)
                && ($! == EAGAIN || $! == EWOULDBLOCK || $! == EINTR);
            if ($fd == fileno($alive_r)) {
                $reason //= 'Cancelled' unless $n;
                $reads->remove($fh)     unless $n;
                next;
            }
            if (
                (
                    exists($args->{cancel_fh})
                    && $fd == fileno($args->{cancel_fh})
                )
                || ($args->{_cancel_r} && $fd == fileno($args->{_cancel_r}))
                )
            {
                $reason //= 'Cancelled';
                $reads->remove($fh);
                next;
            }
            if ($fd == fileno($notice_r)) {
                if (!defined($n) || !$n || $n % 128) {
                    $reason //= 'Transport';
                    $reads->remove($fh);
                }
                else {
                    for (my $offset = 0 ; $offset < $n ; $offset += 128) {
                        my $signal = unpack('L<', substr($chunk, $offset, 4));
                        $reason //= 'Cancelled'
                            if $signal == SIGINT || $signal == SIGTERM;
                    }
                }
                next;
            }
            if (!defined($n) || !$n) {
                $reads->remove($fh);
                delete $stream{$fd};
                close $fh;
                next;
            }
            my $which = $stream{$fd};
            if ($which eq 'stdout' || $which eq 'stderr') {
                my $remaining =
                    $args->{max_output} -
                    length($data{stdout}) -
                    length($data{stderr});
                $data{$which} .= substr($chunk, 0, $remaining);
                $reason //= 'OutputLimit' if length($chunk) > $remaining;
            }
            else {
                $data{$which} .=
                    substr($chunk, 0, 65536 - length($data{$which}));
                $reason //= 'Transport'
                    if length($chunk) + length($data{$which}) > 131072;
            }
            if ($which eq 'exec' && !$group_ready && $data{exec} =~ s/^G//) {
                $group_ready = 1;
                unless ($reason) {
                    if (syswrite($go_w, '1') == 1) { $released = 1 }
                    else                           { $reason //= 'Spawn' }
                }
                close $go_w if defined fileno($go_w);
            }
            if (
                length($data{stdout}) + length($data{stderr}) >
                $args->{max_output})
            {
                $reason //= 'OutputLimit';
            }
        }
        for my $fh (@$ready_w) {
            my $n =
                syswrite($fh, $args->{stdin}, length($args->{stdin}) - $offset,
                $offset);
            next
                if !defined($n)
                && ($! == EINTR || $! == EAGAIN || $! == EWOULDBLOCK);
            if (!defined($n) || !$n) { $writes->remove($fh); close $fh; next }
            $offset += $n;
            if ($offset == length($args->{stdin})) {
                $writes->remove($fh);
                close $fh;
            }
        }
    }
    my $record = {
        cleanup_complete => $direct_reaped && $group_complete ? true : false,
        stdout           => encode_base64($data{stdout}, ''),
        stderr           => encode_base64($data{stderr}, ''),
        raw_status       => $raw_status,
        exit_code        => (defined($raw_status) ? $raw_status >> 8  : undef),
        signal           => (defined($raw_status) ? $raw_status & 127 : undef)
    };
    if ($data{exec} =~ s/^E//) {
        $record->{error} =
            {type => 'Spawn', message => $data{exec}, dispatched => false};
        return $record;
    }
    if ($reason) {
        $record->{error} = {
            type       => $reason,
            message    => lc($reason) . ' during process execution',
            dispatched => $released ? true : false
        };
        return $record;
    }
    return $record;
}

=head1 NAME

LibTmux::Transport - Supervised literal process execution

=head1 METHODS

=head2 run

C<run(argv =E<gt> [...], stdin =E<gt> $octets, timeout =E<gt> $seconds,
max_output =E<gt> $bytes, cancel_fh =E<gt> $handle)> returns a
L<LibTmux::CommandResult>.
Stdout/stderr are separate octet strings. Nonzero exits are results; spawn,
timeout, cancellation, output limits, and supervision failures throw
L<LibTmux::X> exceptions. C<timeout> bounds one command's execution loop,
excluding supervisor setup, async queue waiting, and separate cleanup time.

=head2 start

Return a L<LibTmux::ProcessJob> for an executor adapter.

=head1 RESULTS

L<LibTmux::CommandResult> exposes stdout, stderr, exit_code, signal, raw_status,
and success. Output remains octets.

The private supervisor owns program signals/groups and reaps the program.
It receives CHLD, INT and TERM through a Linux signal descriptor, so child
exit cannot wait for a deferred Perl handler. This mask belongs only to the
supervisor; the command restores its inherited mask before execution.
Application SIGCHLD handlers remain intact; SIGCHLD=IGNORE is refused.
Cancellation handles are borrowed and remain open. Cancellation after release
can have effects and never implies rollback. Parent death triggers cleanup.

Owned supervisor and command branches close unrelated inherited descriptors
through Linux C</proc/self/fd>, preserving the caller's handles. Native
descriptors without close-on-exec cannot leak into a newly started tmux daemon.
Only standard streams and each branch's required protocol/cancellation pipes
remain open. Enumeration or closure failures prevent execution and throw
L<LibTmux::X/Transport> or L<LibTmux::X/Spawn>. No arbitrary descriptor-passing
API is selected. Forking hosts with native threads remains unqualified.

=cut
