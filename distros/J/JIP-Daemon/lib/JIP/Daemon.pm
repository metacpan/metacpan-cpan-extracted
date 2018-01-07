package JIP::Daemon;

use 5.006;
use strict;
use warnings;
use JIP::ClassField 0.05;
use File::Spec;
use POSIX ();
use Carp qw(carp croak);
use English qw(-no_match_vars);

our $VERSION = '0.041';

my $maybe_set_subname = sub { $ARG[1]; };

# Supported on Perl 5.22+
eval {
    require Sub::Util;

    if (my $set_subname = Sub::Util->can('set_subname')) {
        $maybe_set_subname = $set_subname;
    }
};

my $default_log_callback = sub {
    my ($self, @params) = @ARG;

    if (defined(my $logger = $self->logger)) {
        my $msg;

        if (@params == 1) {
            $msg = shift @params;
        }
        elsif (@params) {
            my $format = shift @params;
            $msg = sprintf $format, @params;
        }

        $logger->info($msg) if defined $msg;
    }
};

has [qw(
    pid
    uid
    gid
    cwd
    umask
    logger
    dry_run
    is_detached
    log_callback
    on_fork_callback
    stdout
    stderr
    program_name
)] => (get => q{+}, set => q{-});

has devnull => (get => q{+}, set => q{-}, default => File::Spec->devnull);

sub new {
    my ($class, %param) = @ARG;

    # Perform a trial run with no changes made (foreground if dry_run)
    my $dry_run = (exists $param{'dry_run'} and $param{'dry_run'}) ? 1 : 0;

    my $uid;
    if (exists $param{'uid'}) {
        $uid = $param{'uid'};

        croak q{Bad argument "uid"}
            unless defined $uid and $uid =~ m{^\d+$}x;
    }

    my $gid;
    if (exists $param{'gid'}) {
        $gid = $param{'gid'};

        croak q{Bad argument "gid"}
            unless defined $gid and $gid =~ m{^\d+$}x;
    }

    my $cwd;
    if (exists $param{'cwd'}) {
        $cwd = $param{'cwd'};

        croak q{Bad argument "cwd"}
            unless defined $cwd and length $cwd;
    }

    my $umask;
    if (exists $param{'umask'}) {
        $umask = $param{'umask'};

        croak q{Bad argument "umask"}
            unless defined $umask and length $umask;
    }

    my $logger;
    if (exists $param{'logger'}) {
        $logger = $param{'logger'};

        croak q{Bad argument "logger"}
            unless defined $logger and ref $logger and $logger->can('info');
    }

    my $log_callback;
    if (exists $param{'log_callback'}) {
        $log_callback = $param{'log_callback'};

        croak q{Bad argument "log_callback"}
            unless defined $log_callback and ref($log_callback) eq 'CODE';

        $log_callback = $maybe_set_subname->('custom_log_callback', $log_callback);
    }
    else {
        $log_callback = $maybe_set_subname->('default_log_callback', $default_log_callback);
    }

    my $on_fork_callback;
    if (exists $param{'on_fork_callback'}) {
        $on_fork_callback = $param{'on_fork_callback'};

        croak q{Bad argument "on_fork_callback"}
            unless defined $on_fork_callback and ref($on_fork_callback) eq 'CODE';

        $on_fork_callback = $maybe_set_subname->('on_fork_callback', $on_fork_callback);
    }

    my $stdout;
    if (exists $param{'stdout'}) {
        $stdout = $param{'stdout'};

        croak q{Bad argument "stdout"}
            unless defined $stdout and length $stdout;
    }

    my $stderr;
    if (exists $param{'stderr'}) {
        $stderr = $param{'stderr'};

        croak q{Bad argument "stderr"}
            unless defined $stderr and length $stderr;
    }

    my $program_name = $PROGRAM_NAME;
    if (exists $param{'program_name'}) {
        $program_name = $param{'program_name'};

        croak q{Bad argument "program_name"}
            unless defined $program_name and length $program_name;
    }

    return bless({}, $class)
        ->_set_dry_run($dry_run)
        ->_set_uid($uid)
        ->_set_gid($gid)
        ->_set_cwd($cwd)
        ->_set_umask($umask)
        ->_set_logger($logger)
        ->_set_log_callback($log_callback)
        ->_set_on_fork_callback($on_fork_callback)
        ->_set_pid($PROCESS_ID)
        ->_set_is_detached(0)
        ->_set_stdout($stdout)
        ->_set_stderr($stderr)
        ->_set_program_name($program_name)
        ->_set_devnull;
}

sub daemonize {
    my $self = shift;

    return $self if $self->is_detached;

    # Fork and kill parent
    if (not $self->dry_run) {
        $self->_log('Daemonizing the process');

        my $pid = POSIX::fork(); # returns child pid to the parent and 0 to the child

        croak q{Can't fork} if not defined $pid;

        # fork returned 0, so this branch is the child
        if ($pid == 0) {
            POSIX::setsid()
                or croak(sprintf q{Can't start a new session: %s}, $OS_ERROR);

            $self->reopen_std;
            $self->change_program_name;

            $self->_set_pid(POSIX::getpid())->_set_is_detached(1);
        }

        # this branch is the parent
        else {
            $self->_log('Spawned process pid=%d. Parent exiting', $pid);
            $self->_set_pid($pid)->_set_is_detached(1);

            if (defined(my $cb = $self->on_fork_callback)) {
                $cb->($self);
            }

            POSIX::exit(0);
        }
    }
    else {
        $self->_set_pid($PROCESS_ID);
    }

    return $self->drop_privileges;
}

sub reopen_std {
    my $self = shift;

    my $stdin = q{<}. $self->devnull;

    my $stdout;
    if (defined $self->stdout) {
        $stdout = $self->stdout;
        $self->_log('Reopen STDOUT to: %s', $stdout);
    }
    else {
        $stdout = q{+>}. $self->devnull;
    }

    my $stderr;
    if (defined $self->stderr) {
        $stderr = $self->stderr;
        $self->_log('Reopen STDERR to: %s', $stderr);
    }
    else {
        $stderr = q{+>}. $self->devnull;
    }

    open STDIN,  $stdin  or croak(sprintf q{Can't reopen STDIN: %s},  $OS_ERROR);
    open STDOUT, $stdout or croak(sprintf q{Can't reopen STDOUT: %s}, $OS_ERROR);
    open STDERR, $stderr or croak(sprintf q{Can't reopen STDERR: %s}, $OS_ERROR);

    return $self;
}

sub drop_privileges {
    my $self = shift;

    if (defined(my $uid = $self->uid)) {
        $self->_log('Set uid=%d', $uid);
        POSIX::setuid($uid)
            or croak(sprintf q{Can't set uid "%s": %s}, $uid, $OS_ERROR);
    }

    if (defined(my $gid = $self->gid)) {
        $self->_log('Set gid=%d', $gid);
        POSIX::setgid($gid)
            or croak(sprintf q{Can't set gid "%s": %s}, $gid, $OS_ERROR);
    }

    if (defined(my $umask = $self->umask)) {
        $self->_log('Set umask=%s', $umask);
        POSIX::umask($umask)
            or croak(sprintf q{Can't set umask "%s": %s}, $umask, $OS_ERROR);
    }

    if (defined(my $cwd = $self->cwd)) {
        $self->_log('Set cwd=%s', $cwd);
        POSIX::chdir($cwd)
            or croak(sprintf q{Can't chdir to "%s": %s}, $cwd, $OS_ERROR);
    }

    return $self;
}

sub try_kill {
    my ($self, $signal) = @ARG;

    if (defined(my $pid = $self->pid)) {
        # parameter order in POSIX.pm
        # CORE::kill($signal, $pid);
        # POSIX::kill($pid, $signal);
        return POSIX::kill($pid, defined $signal ? $signal : q{0});
    }
    else {
        carp q{No subprocess running};
        return;
    }
}

sub status {
    my $self = shift;
    my $pid  = $self->pid;

    return $pid, POSIX::kill($pid, 0) ? 1 : 0, $self->is_detached;
}

sub change_program_name {
    my $self = shift;

    my $old_program_name = $PROGRAM_NAME;
    my $new_program_name = $self->program_name;

    if ($new_program_name ne $old_program_name) {
        $self->_log(
            'The program name changed from %s to %s',
            $old_program_name,
            $new_program_name,
        );
        $PROGRAM_NAME = $new_program_name;
    }

    return $self;
}

# private methods
sub _log {
    my $self = shift;

    $self->log_callback->($self, @ARG);

    return $self;
}

1;

__END__

=head1 NAME

JIP::Daemon - Daemonize server process.

=head1 VERSION

This document describes C<JIP::Daemon> version C<0.041>.

=head1 SYNOPSIS

Just run:

    use JIP::Daemon;

    my $proc = JIP::Daemon->new;

    # Send program to backgroung.
    $proc = $proc->daemonize;

    # In the backgroung process:
    $proc->is_detached; # 1
    $proc->try_kill(0); # 1
    printf qq{pid(%s), is_alive(%d), is_detached(%d)\n}, $proc->status;

    # If the program is already a running background job, the daemonize method shall have no effect.
    $proc = $proc->daemonize;

Dry run:

    use JIP::Daemon;

    my $proc = JIP::Daemon->new(dry_run => 1);

    $proc->daemonize;

    # In the same process
    $proc->is_detached; # 0

With logger:

    use Mojo::Log;
    use JIP::Daemon;

    my $proc = JIP::Daemon->new(logger => Mojo::Log->new);

    $proc->daemonize;

With on_fork_callback:

    use JIP::Daemon;

    my $proc = JIP::Daemon->new(
        on_fork_callback => sub {
            # After daemonizing, and before exiting,
            # run the given code in parent process
            print $proc->pid;
        },
    )->daemonize;

=head1 ATTRIBUTES

C<JIP::Daemon> implements the following attributes.

=head2 pid

    my $pid = $proc->pid;

=head2 is_detached

    my $is_detached => $proc->is_detached;

Process is detached from the controlling terminal.

=head2 dry_run

    my $dry_run = $proc->dry_run;

Perform a trial run with no changes made (foreground if dry_run).

=head2 uid

    my $uid = $proc->uid;

The real user identifier and the effective user identifier for this process.

=head2 gid

    my $gid = $proc->gid;

The real group identifier and the effective group identifier for this process.

=head2 cwd

    my $cwd = $proc->cwd;

Change the current working directory.

=head2 umask

    my $umask = $proc->umask;

Most Daemon processes runs as super-user, for security reasons they should protect files that they create. Setting user mask will prevent unsecure file priviliges that may occur on file creation.

=head2 logger

    JIP::Daemon->new(logger => Mojo::Log->new)->logger->info('Hello');

Simple logger, based on L<Mojo::Log> interface.

=head2 log_callback

With default callback:

    my $proc = JIP::Daemon->new(logger => Mojo::Log->new);

    # $proc->logger->info('Hello');
    $proc->log_callback->($proc, 'Hello');

    # $proc->logger->info(sprintf 'format %s', 'line');
    $proc->log_callback->($proc, 'format %s', 'line');

With custom callback:

    my $proc = JIP::Daemon->new(
        logger       => Mojo::Log->new,
        log_callback => sub {
            my ($proc, @lines) = @_;
            $proc->logger->debug(@lines);
        },
    );
    $proc->log_callback->($proc, 'Hello');

=head2 on_fork_callback

After daemonizing, and before exiting, run the given code in parent process.

=head2 devnull

    my $devnull = $proc->devnull;

Returns a string representation of the null device.

=head2 stdout

    my $stdout = $proc->stdout;

If this parameter is supplied, redirect STDOUT to file.

=head2 stderr

    my $stderr = $proc->stderr;

If this parameter is supplied, redirect STDERR to file.

=head2 program_name

    my $program_name = $proc->program_name;

Returns a string with name of the process.

=head1 SUBROUTINES/METHODS

=head2 new

    my $proc = JIP::Daemon->new;
    my $proc = JIP::Daemon->new(dry_run => 1);

Construct a new C<JIP::Daemon> object.

=head2 daemonize

    $proc = $proc->daemonize;

Daemonize server process.

=head2 reopen_std

    $proc = $proc->reopen_std;

Reopen STDIN, STDOUT, STDERR to /dev/null.

    my $proc = JIP::Daemon->new(
        stdout => '+>/path/to/out.log',
        stderr => '+>/path/to/err.log',
    );

    $proc = $proc->reopen_std;

The C<stdout> and C<stderr> arguments are file names that will be opened and be used to replace the standard file descriptors. These special modes only work with two-argument form of C<open>.

=head2 drop_privileges

    my $proc = JIP::Daemon->new(uid => 1000, gid => 1000, umask => 0, cwd => q{/});
    $proc = $proc->drop_privileges;

Change C<uid>/C<gid>/C<umask>/C<cwd> on demand.

=head2 try_kill

    my $is_alive = $proc->try_kill(0);

This is identical to Perl's builtin C<kill()> function for sending signals to processes (often to terminate them).

=head2 change_program_name

    my $proc = JIP::Daemon->new(program_name => 'tratata');
    $proc = $proc->change_program_name;

Changes the name of the program.

=head2 status

    my ($pid, $is_alive, $is_detached) = $proc->status;

Returns a list of process attributes: PID, is alive, is detached (in backgroung).

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

C<JIP::Daemon> requires no configuration files or environment variables.

=head1 SEE ALSO

L<POSIX>, L<Privileges::Drop>, L<Object::ForkAware>, L<Proc::Daemon>, L<Daemon::Daemonize>.

=head1 AUTHOR

Vladimir Zhavoronkov, C<< <flyweight at yandex.ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2018 Vladimir Zhavoronkov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


