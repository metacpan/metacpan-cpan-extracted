package IO::Trace;

use 5.006000;
use strict;
use warnings;
use base qw(Exporter);
use Getopt::Long qw(GetOptionsFromArray);
use IPC::Open3 qw(open3);
use IO::Select;
use IO::Handle;
use IO::File qw(O_WRONLY O_TRUNC O_CREAT);

our @EXPORT = qw(iotrace);
our $VERSION = '0.021';

# Magic Timer Settings
our $has_hires = eval { require Time::HiRes; 1 };
our $patience_idle = 8000; # Seconds to wait for I/O while process is still running
our $patience_kill_mute = $has_hires ? 5.2 : 6; # Seconds to wait for "mute" process to terminate. If all its handles are closed, then force SIGTERM and SIGKILL if still running after waiting this long.
our $heartbeat_grind_mute = 0.2; # Interval Seconds between SIGCHLD check to test if "mute" child died yet.
our $implicit_close_before_chld = 0.08; # Maximum Seconds to wait for SIGCHLD after all handles have been closed in order to consider it an implicit close instead of explicit close.
our $implicit_chld_before_close = $has_hires ? 0.25 : 1; # Maximum Seconds after receiving SIGCHLD to consider a close to be implicit. Any longer is considered an explicit close.
our $patience_zombie_breather = $has_hires ? 5.6 : 7; # Maximum Seconds of uninterrupted silence after receiving SIGCHLD to wait for the process to close all handles. Any longer, then all open pipes are implicitly slapped closed to sufficate the zombie process. Then it is reaped to log the correct exit status, and the descent process should receive a SIGPIPE if ever attempting to write to its output handle in the future.

sub now { $has_hires ? Time::HiRes::time() : time }

sub usage {
    die "Usage> $0 -o <output_log> CMD [ARGS]\n";
}

sub iotrace {
    my $self = __PACKAGE__->new;
    my @args = @_ ? @_ : @ARGV or usage;
    $self->parse_commandline(@args) or usage;
    $self->{child_died} = 0;
    local $SIG{CHLD} = sub { $self->{child_died} = now; };
    $self->run_trace;
    my $exit_status = $self->finish_child;
    if (defined wantarray) {
        return $exit_status;
    }
    exit $exit_status;
}

sub new {
    my $self = shift;
    my $args = shift || {};
    return bless $args, $self;
}

sub parse_commandline {
    my $self = shift;
    Getopt::Long::Configure("require_order");
    Getopt::Long::Configure("bundling");
    GetOptionsFromArray
        \@_,
        "o=s"   => \($self->{output_log_file}),
        "v+"    => \($self->{verbose} = 0),
        "x+"    => \($self->{heX_ify} = 0),
        "t+"    => \($self->{timing} = 0),
        "f+"    => \($self->{follow_fork} = 0),
        "q+"    => \($self->{quiet} = 0), # Ignored
        "s=i"   => \($self->{size_of_strings}), # Ignored
        "e=s"   => \($self->{events}),  # Ignored
        or return;
    $self->{run} = [@_];
    return @_;
}

sub t {
    my $self = shift;
    my $h = "";
    if ($self->{follow_fork} == 1) { $h .= "$self->{pid} "; }
    if ($self->{timing}) {
        my $now = $self->{timing} > 1 ? now : time;
        my @t = localtime $now;
        $h .= sprintf "%02d:%02d:%02d", $t[2], $t[1], $t[0];
        $h .= sprintf ".%06d", 1000000*($now - int($now)) if $self->{timing} > 1;
        $h .= " ";
    }
    return $h;
}

sub log {
    my $self = shift;
    my $line = join "", @_;
    $line =~ s/\s*$/\n/;
    $self->{log}->print($self->t().$line);
}

# Escape strings like strace does
sub e {
    my $self = shift;
    my $chars = shift;
    if ($self->{heX_ify} > 1) {
        # -xx: Super Hex Encode everything
        $chars =~ s/([\s\S])/sprintf "\\x%02x", ord($1)/eg;
    }
    else {
        # Both \\ and \" really need to be escaped
        # But add other helpful chars to make it easier for Perl to read too.
        $chars =~ s/([\\\"\'\$\@])/\\$1/g;
        # Special backslash escape chars for easy legibility
        $chars =~ s/\t/\\t/g;
        $chars =~ s/\r/\\r/g;
        $chars =~ s/\n/\\n/g;
        if ($self->{heX_ify}) {
            # -x: Hex Encode only non-ascii chars
            $chars =~ s/([^\ -\~])/sprintf "\\x%02x", ord $1/eg;
        }
        else {
            # Default is octal encoding non-ascii only
            $chars =~ s/([^\ -\~])/sprintf "\\%03o", ord $1/eg;
        }
   }
   return qq{"$chars"};
}

sub run_trace {
    my $self = shift;
    if ($self->{timing} > 1 and not $has_hires) {
        # If requesting to log high precision, but without HiRes, then just change "-tt" to "-t" to show integer time
        $self->{timing} = 1;
    }
    $self->spawn;
    $self->open_output_log;
    $self->log("execve(".$self->e($self->{full}).", [".join(', ', map { $self->e($_) } @{ $self->{run} }).'], '.(
        $self->{verbose} ? (
            '['.join(', ', map { $self->e("$_=$ENV{$_}") } sort keys %ENV).']'
        ) :
        \%ENV.' /* '.(scalar keys %ENV).' vars */'
    ).") = 0");
    $self->io_loop;
}

sub spawn {
    my $self = shift;
    my $full = $self->{run}->[0];
    if (eval { require File::Which; 1; } and $full =~ m{^([\w\-\.]+)$}) {
        $full = File::Which::which($1);
    }
    if (!$full or $full =~ m{^/} && !-x $full) {
        die "$self->{run}->[0]: No such file or directory\n";
    }
    $self->{in}  = IO::Handle->new;
    $self->{out} = IO::Handle->new;
    $self->{err} = IO::Handle->new;
    # open3 can't vivify STDERR from undef for some reason
    my @r = @{ $self->{run} };
    $r[0] = $full if $full;
    $self->{full} = $full // $r[0];
    # Launch target program
    $self->{pid} = open3 $self->{in}, $self->{out}, $self->{err}, @r or die "$r[0]: fork exec failure: $!\n";
    # Map each handle to its corresponding handle
    $self->{proxy} = {
        fileno($self->{in})   => *STDIN,
        fileno($self->{out})  => *STDOUT,
        fileno($self->{err})  => *STDERR,

        fileno(*STDIN)        => $self->{in},
        fileno(*STDOUT)       => $self->{out},
        fileno(*STDERR)       => $self->{err},
    };
    $self->{implicitly_closed} = {};
    $self->{sel} = IO::Select->new(values %{ $self->{proxy} });
    $self->{writers} = IO::Select->new($self->{in}, \*STDOUT, \*STDERR);
    return $self->{pid};
}

sub open_output_log {
    my $self = shift;
    my $output_log_file = $self->{output_log_file};
    if (defined $output_log_file) {
        $output_log_file .= ".$self->{pid}" if $self->{follow_fork} > 1;
        $self->{log} = IO::File->new($output_log_file, O_WRONLY | O_TRUNC | O_CREAT ) or die "$output_log_file: open failure: $!\n";;
    }
    else {
        # XXX - Is it ok to spew all the trace lines out to STDERR if no -o option provided?
        $self->{log} = IO::File->new(">&STDERR");
    }
    $self->{log}->autoflush(1);
    return $self->{log};
}

sub io_loop {
    my $self = shift;
    # Loop while still open handles or during brief implicit close detection
    while ($self->{sel}->handles or keys %{ $self->{implicitly_closed} }) {
        my $maximum_timeout =
            keys %{ $self->{implicitly_closed} } ? $implicit_close_before_chld :
            $self->{child_died} ? $patience_zombie_breather :
            $patience_idle;
        my @ready = $self->{sel}->count ? $self->{sel}->can_read($maximum_timeout) : do {select undef,undef,undef, $maximum_timeout; ()};
        foreach my $fh (@ready) {
            my $fn = fileno($fh) // next;
            my $pr = $self->{proxy}->{$fn} or die "Fileno $fn: Impossible Implementation Crash! $!\n";;
            # Find original fileno (STDIN=0, STDOUT=1, STDERR=2):
            my $real_fileno = $fn < 3 ? $fn : fileno($pr);
            if ($self->{writers}->exists($fh)) {
                # $fh should only be written to, so if it's suddenly "READABLE",
                # that means it woke up due to the pipe being close()d on the other end.
                # Never attempt to actually read from a "writers" handle.
                # Only log explicit close(). Don't bother if it's probably just an implicit close() upon exit.
                $self->log("close($real_fileno) = 0") if !$self->{child_died};
                # Close both sides since there's nowhere for any data to go anymore:
                $self->{sel}->remove($fh);
                $self->{sel}->remove($pr);
                $self->{writers}->remove($fh);
                close $fh;
                close $pr;
                next;
            }
            my $bytes = sysread($fh, (my $buffer), 16384);
            # Only STDIN (fileno = 0) is "read", otherwise "write"
            my $op = $real_fileno ? "write" : "read";
            $self->log("$op($real_fileno, ".$self->e($buffer).", $bytes) = $bytes") if $bytes or $op eq "read";
            if ($bytes) {
                # Forward non-empty packet to the proxy file handle
                syswrite($pr, $buffer, $bytes);
            }
            else {
                # Getting ZERO bytes always means the file handle just closed.
                # Quit listening to this anymore:
                $self->{sel}->remove($fh);
                # And then close the file handle for real:
                close($fh);

                # And quit listening on the corresponding handle too:
                $self->{sel}->remove($pr);

                if ($real_fileno == 0 # Immediately close corresponding handle for STDIN immediately in order to signal target program its input stream has ended.
                    or $self->{child_died} && now > $self->{child_died} + $implicit_chld_before_close) { # Or if it exited long enough ago, then this must have been an explicit output handle close from a backgrounded process, and it's safe to log, (even if it was implicitly closed by the grandchild or descendent process).
                    close($pr);

                    # If it was STDIN (fd 0), then the invoker probably closed it before the target program. But just log the close acting like the target program called close itself (even if STDIN is being ignored by the target program).
                    $self->log("close($real_fileno) = 0");
                }
                else {
                    # An output handle (STDOUT fd 1 or STDERR fd 2) was just closed, but it might have just been an implicit close since the process is still running or exited too recently.
                    # So don't log it yet. Just flag it for now. Then keep a close eye on the {child_died} timer to determine which way it was.
                    # The goal is to mimic the same behavior as the target process whether to do an implicit or explicit close.
                    $self->{implicitly_closed}->{$real_fileno} = $pr;
                }
            }
        }
        if (!@ready and keys %{ $self->{implicitly_closed} }) {
            # Implicit detection timeout exceeded. No more waiting allowed.
            # All implicitly_closed file handles must be imminently closed!
            if (!$self->{sel}->count and $self->{child_died}) {
                # Must exit immediately in order to implicitly close any implicitly_closed handles
                last;
            }
            # Otherwise, must explicitly close them all now and log it, then continue the select loop.
            foreach my $fileno (keys %{ $self->{implicitly_closed} }) {
                close(delete $self->{implicitly_closed}->{$fileno});
                $self->log("close($fileno) = 0");
            }
        }
        if ($self->{child_died}) {
            if (now > $self->{child_died} + $patience_zombie_breather) {
                # Ran out of patience. Just leave to implicitly close all handles.
                last;
            }
            else {
                # Zombie handle said something, so restart the timer, and start the waiting all over again..
                $self->{child_died} = now;
            }
        }
    }
}

sub finish_child {
    my $self = shift;
    if (!$self->{child_died}) {
        # If process still running, then all handles must have already been closed. So just wait a little bit for termination.
        my $patient = $patience_kill_mute + now;
        select undef,undef,undef,$heartbeat_grind_mute while !$self->{child_died} and $patient > now;

        # If STILL running, then offer a little bit more help to terminate
        !$self->{child_died} and kill TERM => $self->{pid} and sleep 1 and kill KILL => $self->{pid};
    }

    # Block waiting for process to exit
    waitpid( $self->{pid}, 0 );
    $self->{child_error} = $?;
    my $signal = $self->{child_error} & 127;
    my $child_exit_status = $self->{child_error} >> 8;
    if ($signal) {
        my $sig_name = eval { require Config; %Config::Config and [split / /, $Config::Config{sig_name}]->[$signal] } || $signal;
        $self->log("--- GOT SIG$sig_name ($signal) ---");
    }
    $self->log("+++ exited with $child_exit_status +++");
    $self->{log}->close;
    return $child_exit_status;
}

1;
__END__

=pod

=head1 NAME

IO::Trace - Log I/O of an arbitrary process.

=head1 SYNOPSIS

  # Simple case:
  use IO::Trace;
  exit iotrace @ARGV;

  # Advanced use:
  use IO::Trace qw(iotrace);
  my $exit_sort = iotrace qw[-f -v -s9000 -tt -e execve,clone,openat,close,read,write -o /tmp/sort.iotrace.log sort];
  warn `wc /tmp/sort.iotrace.log`;
  exit $exit_editor;

=head1 DESCRIPTION

This utility is intended to be used to record STDIN STDOUT STDERR
actvity (read,write,close) of an arbitrary command which it spawns.
It does not alter any packets on the streams.

The log file format is similar to Linux's strace utility but more
platform-independent. So iotrace should work on Windows, MacOSX,
GitBash, FreeBSD, Msys2, MinGW, Solaris, Cygwin, ChromeOS,
as well as Linux.

This is implemented using IPC::Open3::open3 instead of Linux ptrace.

=head1 CAVEATS

It breaks terminal commands that rely on STDIN being a TTY because
it is converted into a pipe.

It will NOT log reads and writes to other files opened during
the command execution, like strace does.
It only logs STDIN, STDOUT, STDERR.

=head1 SEE ALSO

strace - Based on this commandline utility,
but this only works on Linux platform.

Capture::Tiny - Similar in that it can log STDOUT and STDERR,
but this is difficult to capture STDIN.

IPC::Run - Almost powerful enough to handle what I needed, but it
couldn't handle detecting closed streams very gracefully, and the
STDIN exponential backoff heartbeat CODE grinder is too sloppy.

=head1 AUTHOR

Rob Brown, E<lt>bbb@cpan.orgE<gt>

=head1 DEVELOPMENT

This module is maintained on github:

https://github.com/hookbot/IO-Trace

Report feature requests or bugs here:

https://github.com/hookbot/IO-Trace/issues

Pull requests welcome.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Rob Brown

This library is free software; you can redistribute it and/or
modify it under the terms of The Artistic License 2.0.

=head1 DISCLAIMER

Use at your own risk! The author will not be liable for any
damages caused by misuse of this application nor any illegal
monitoring or logging of any private communications or
data packets or IO streams.

=cut
