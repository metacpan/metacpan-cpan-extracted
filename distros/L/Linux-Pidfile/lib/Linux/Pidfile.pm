package Linux::Pidfile;
{
  $Linux::Pidfile::VERSION = '0.16';
}
BEGIN {
  $Linux::Pidfile::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Pidfile handling to help control processes.

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Carp;
use File::Blarf;

has 'pidfile' => (
    'is'       => 'ro',
    'isa'      => 'Str',
    'required' => 1,
);

has 'timeout' => (
    'is'      => 'rw',
    'isa'     => 'Num',
    'default' => 1,
);

has 'restart_timeout' => (
    'is'    => 'rw',
    'isa'   => 'Num',
    'default' => 30,
);

has 'force_restart' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 0,
);

with qw(Log::Tree::RequiredLogger);

sub BUILD {
    my $self = shift;

    if ( !-f $self->pidfile() ) {
        my @path         = split /\//, $self->pidfile();
        my $pidfile_name = pop @path;
        my $pidfile_dir  = join( '/', @path );
        if ( !-w $pidfile_dir && -w '/tmp' ) {
            $self->{'pidfile'} = '/tmp/' . $pidfile_name;
        }
    }
    return 1;
}

sub DEMOLISH {
    #
    # BIG FAT WARNING
    #
    # YOU MUST NOT REMOVE THE PIDFILE ON DEMOLISH!
    #
    # THIS WOULD RENDER THIS MODULE USELESS!
    #

    return 1;
}

# Write a pidfile containig this process pid
# and return false if the file exists and a process
# with the name of this script and this pid (i.e. this script)
# is already running.
sub create {
    my $self = shift;

    # Check if this script is already running.
    if ( my $pid_from_file = $self->this_script_is_running() ) {
        $self->logger()->log( message => 'This script is already running with the PID '.$pid_from_file.'. Checking if its myself or a timeout ...', level => 'debug', );
        # if the enclosing script is called by e.g. start-stop-daemon
        # this MAY have already created an (correct) pidfile.
        # in that case we should just keep it and go on
        if($pid_from_file == $$) {
            # IT's ME!
            $self->logger()->log( message => 'This script already has a correct pidfile aborting w/ success', level => 'debug', );
            return 1;
        }

        # Check if the script is running too long.
        my $timeout = $self->timeout() || 1;
        if ( -M $self->pidfile() >= $timeout ) {
            my $runtime = -M $self->pidfile();
            $self->logger()->log( message => 'Script is running too long, running since '.$runtime.' days.', level => 'warning', );

            # Should we kill the long-running script and start again?
            # This can be dangerous since it can lead to corrupt backups.
            if ( $self->force_restart() ) {
                $self->logger()->log( message => 'force_restart requested. Killing long-running precedessor and restarting.', level => 'notice', );
                my $cmd    = 'kill '.$pid_from_file;
                my $retval = system($cmd) >> 8;
                $self->logger()->log( message => 'CMD '.$cmd.' gave NON-SUCCESS retval: '.$retval, level => 'warning', ) unless ( $retval == 0 );

                if($self->pid_is_running($pid_from_file)) {
                    $self->logger()->log( message => 'Sleeping '.$self->restart_timeout().' seconds to let kill take effekt.', level => 'info', );
                    sleep($self->restart_timeout());

                    if($self->pid_is_running($pid_from_file)) {
                        $cmd    = 'kill -9 '.$pid_from_file;
                        $retval = system($cmd) >> 8;
                        $self->logger()->log( message => 'CMD '.$cmd.' gave NON-SUCCESS retval: '.$retval, level => 'warning', ) unless ( $retval == 0 );
                        $self->logger()->log( message => 'Sleeping '.$self->restart_timeout().' seconds to let kill take effekt.', level => 'info', );
                        sleep($self->restart_timeout());
                    }
                }
                $self->remove();
                return $self->_write();
            }
        } else {
            $self->logger()->log( message => 'Script already running w/ pid '.$pid_from_file, level => 'warning', );
            # Abort - script is already running
            return;
        }
    } else {
        $self->logger()->log( message => 'Stale Pidfile. Previous run exited abnormaly. Removing pidfile at '.$self->pidfile(), level => 'warning', );
        $self->remove();
    }
    $self->logger()->log( message => 'Writing pid '.$$.' to pidfile at '.$self->pidfile(), level => 'debug', );

    return $self->_write();
}

sub this_script_is_running {
    my $self = shift;

    my $pid_from_file;
    if($pid_from_file = $self->pidfile_is_running()) {
        my $cmdline_file = '/proc/'.$pid_from_file.'/cmdline';
        $self->logger()->log( message => 'Reading from file '.$cmdline_file, level => 'debug', );
        my $cmdline = File::Blarf::slurp( $cmdline_file );
        if($cmdline =~ m/\Q$0\E/i) {
            $self->logger()->log( message => 'This script ('.$0.'/'.$cmdline.') is alread running w/ pid '.$pid_from_file, level => 'debug', );
            return $pid_from_file;
        }
    }

    return;
}

sub pidfile_is_running {
    my $self = shift;

    # no pidfile defined, can't check
    if(!$self->pidfile()) {
        return;
    }

    # no pidfile exists, can't be running
    # note: if the pidfile is gone it's not our fault!
    if(!-e $self->pidfile()) {
        return;
    }

    my $pid_from_pidfile = File::Blarf::slurp( $self->pidfile(), { Chomp => 1, Flock => 1, } );

    # no valid pid in pidfile
    if(!$pid_from_pidfile || $pid_from_pidfile !~ m/^\d+$/) {
        return;
    }

    if(!-e '/proc/'.$pid_from_pidfile) {
        return;
    }

    return $pid_from_pidfile;
}

sub pid_is_running {
    my $self = shift;
    my $pid  = shift;

    return unless $pid;

    if(-e '/proc/'.$pid) {
        return 1;
    }

    return;
}

sub _write {
    my $self = shift;

    # Write this scripts pid.
    return File::Blarf::blarf( $self->pidfile(), $$, { Flock => 1, } );
}

sub remove {
    my $self = shift;
    my $force = shift || 0;

    if ( -f $self->pidfile() ) {

        # Check content
        my $pid = File::Blarf::slurp( $self->pidfile(), { Chomp => 1, } );

        # A pidfile should only contain numbers
        if ( $pid =~ m/^\d+$/ ) {

            # our pid or force
            if ( $pid == $$ || $force ) {
                unlink( $self->pidfile() );
                return 1;
            }

            # parent pid
            elsif ( $pid == getppid() ) {
                unlink( $self->pidfile() );
                return 2;
            }
            else {

                # Not our pidfile
                return 0;
            }
        }
        else {

            # Invalid content. Doesn't look like a pidfile.
            return 0;
        }
    }
    else {

        # File not found
        return 0;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Linux::Pidfile - Pidfile handling to help control processes.

=head1 SYNOPSIS

    use Linux::Pidfile;
    my $Pid = Linux::Pidfile::->new();
    $Pid->create() or die('Already running!');
    # ...
    $Pid->remove();

=head1 DESCRIPTION

Pidfile handling to help processes avoid running multiple times.

=head1 METHODS

=head2 BUILD

Initialize the pidfile location.

=head2 DEMOLISH

Placeholder.

=head2 create

Try to create a new pidfile, if the proc is already running exit with false.

=head2 pid_is_running

Return true if a process with the given pid is already running.

=head2 pidfile_is_running

Return true if the pidfile is configured, exists
and a process with this pid is running.

=head2 this_script_is_running

Return true if this script is running.

=head2 remove

Remove the pidfile. Should be called when the invoking process is about to exit.

=head1 NAME

Linux::Pidfile - Pidfile handling to help processes avoid running multiple times.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
