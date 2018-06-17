package Forks::Super::Job::Emulate;
use strict;
use warnings;
use base 'Forks::Super::Job';
use Carp;
use Forks::Super::Debug ':all';
use Forks::Super::Util ':all';

our $VERSION = '0.94';

my $emulate_id = 0;

sub emulate {
    my $job = shift;
    $emulate_id += 4;
    $job->{real_pid} = $job->{pid} = $$ * 1000000 + $emulate_id;
    $job->{is_emulation} = 1;
    local $Forks::Super::Job::Ipc::USE_TIE_FH = 0;
    local $Forks::Super::Job::Ipc::USE_TIE_SH = 0;
    local $Forks::Super::Job::Ipc::USE_TIE_PH = 0;

    $_->() for @Forks::Super::Jobs::POSTFORK_CHILD;
    if (!$job->{cmd} && !$job->{exec} && !$job->{sub}) {
        croak "FSJ::Emulate: must use cmd/exec/sub option with emulate";
    }
    Forks::Super::Job::_postlaunch_parent1($job->{pid}, $job);
    {
        package Forks::Super::Job::Ipc;
        local (our(%IPC_FILES, @IPC_FILES, $IPC_DIR_DEDICATED,
                   @SAFEOPEN, %SIG_OLD));
        local $Forks::Super::Debug::EM = 1;
        local *STDIN = *STDIN;
        local *STDOUT = *STDOUT;
        local *STDERR = *STDERR;

        $SIG{ALRM} = sub { die "emulation timeout\n" };
        my $timeout = delete $job->{timeout};
        if ($timeout) {
            alarm $timeout;
        }
        $job->{is_child} = 1;
        eval {
            $job->_postlaunch_child;
        };
        alarm 0;
        if ($@ && $@ =~ /emulation timeout/) {
            $job->{status} = 255 << 8;
            $job->{error} = $@;
        }
        Forks::Super::Job::Ipc::_child_share($job);
        delete $job->{is_child};
    }
    $job->_postlaunch_parent2;
    $_->() for @Forks::Super::Jobs::POSTFORK_PARENT;
    return $job;
}

sub _postlaunch_child_to_exec {
    # exec must be interpreted as cmd in emulation mode
    my $job = shift;
    $job->{cmd} ||= delete $job->{exec};
    carp "Forks::Super: exec option changed to cmd in emulation mode";
    return $job->_postlaunch_child_to_cmd;
}

sub _postlaunch_child_to_cmd {
    my $job = shift;
    if ($job->{debug}) {
        debug("Executing command [ @{$job->{cmd}} ] {EMULATION MODE}");
    }

    my $c1;
    if (&IS_WIN32) {

        $job->set_signal_pid($$);
        $c1 = system( @{$job->{cmd}} );
	Forks::Super::Job::Ipc::_close_child_fh($job);
	Forks::Super::Sigchld::_preliminary_reap($job,$c1);
	debug("WIN32 returned, exit code of $$ was $c1 ", $c1>>8)
	    if $job->{debug};

    } elsif (1) {

        our %EMULATE_PID;
	my $this_pid = $$;
        my $retries = $job->{retries} || 0;
	my $exec_pid = Forks::Super::Job::_CORE_fork();
	while (!defined $exec_pid && $retries-- > 0) {
            warn "Forks::Super::Job::_postlaunch_child_to_cmd: ",
                "system fork call returned undef. Retrying ...\n";
            Forks::Super::Util::pause(1.0);
            $exec_pid = Forks::Super::Job::_CORE_fork();
        }
        if (!defined $exec_pid) {
            croak "Forks::Super::Job::_postlaunch_child_to_cmd: ",
                "Child process unable to create new fork to run cmd";
        }
        $EMULATE_PID{$exec_pid} = $job;
        if ($$ != $this_pid) {
            if ($job->{_indirect} && @{$job->{cmd}}==1) {
                exec { $job->{cmd}[0] } @{$job->{cmd}} or
                    Carp::confess 'exec for cmd-style fork failed ';
            } else {
                exec( @{$job->{cmd}} ) or
                    Carp::confess 'exec for cmd-style fork failed ';
            }
        }
        $job->{debug} && debug("  exec pid is $exec_pid for job $job");
        $job->set_signal_pid($exec_pid);
        $job->{exec_pid} = $exec_pid;

        $Forks::Super::Job::CHILD_EXEC_PID = $exec_pid; 
        # XXX - do something with this in _cleanup_child?

        my $z = CORE::waitpid $exec_pid, 0;
        if ($z == $exec_pid) {
            # reaped here
            $c1 = $?;
            Forks::Super::Job::Ipc::_close_child_fh($job);
            Forks::Super::Sigchld::_preliminary_reap($job,$c1);
            debug("waitpid returned $z, exit code of $$ was $c1 ", $c1>>8)
                if $job->{debug};
        } elsif ($job->{debug}) {
            # not reaped here
            debug("$$ was reaped in SIGCHLD handler status=$job->{status}");
        }
    } else {
        if ($job->{_indirect}) {
            my $prog = shift @{$job->{cmd}};
            my $name = $job->{name} || $prog;
            $c1 = system { $prog } ($name,@{$job->{cmd}});
        } else {            
            $c1 = system( @{$job->{cmd}} );
        }
        Forks::Super::Job::Ipc::_close_child_fh($job);
        Forks::Super::Sigchld::_preliminary_reap($job,$c1);
    }
}

sub _config_callback_child {
    my $job = shift;
    # no op in emulation mode
    return;
}

1;

=head1 NAME

Forks::Super::Job::Emulate - support emulation mode for Job object

=head1 VERSION

0.94

=head1 DESCRIPTION

In I<emulation> mode (when a non-zero C<emulate> argument is passed
to L<fork|Forks::Super/"fork">), no background process is created.
Rather, the C<fork> call performs the background task in the main
process and returns a L<Forks::Super::Job|Forks::Super::Job> object
that resembles a completed background job. See 
L<< the "emulate" option to C<fork>|Forks::Super/"emulate" >> for
more information.

This package is part of the L<Forks::Super|Forks::Super>
distribution. Most users will have little reason to directly
call the methods of this package.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016-2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut

__END__

emulation tests:

    job should be added to @Forks::Super::ALL_JOBS

    with external command
        can set cpu affinity and os priority of external command

    with subroutine call
        can set cpu affinity and os priority while sub is running
        ! may not exit from sub call in emulation mode

    back in the parent
        signal (kill) should fail
        cpu affinity should be restored
        os priority should be restored
        can wait or waitpid on job one time
        overloaded FSJ functions work

    bg_qx
    bg_eval

    emulated process respects timeout
x    emulated jobs can be named
x    emulated jobs can be delayed for deterministic amount of time
x    share respected, but easier to implement
    after chdir in emulated job, parent dir should be restored
