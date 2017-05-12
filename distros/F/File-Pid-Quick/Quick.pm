package File::Pid::Quick;

use 5.006;
use strict;
use warnings;

=head1 NAME

File::Pid::Quick - Quick PID file implementation

=head1 SYNOPSIS

use File::Pid::Quick;

use File::Pid::Quick qw( /var/run/myjob.pid );

use File::Pid::Quick qw( /var/run/myjob.pid verbose );

use File::Pid::Quick qw( /var/run/myjob.pid timeout 120 );

File::Pid::Quick->recheck;

File::Pid::Quick->check('/var/run/myjob.pid');
  
=cut

our $VERSION = '1.02';

use Carp;
use Fcntl qw( :flock );
use File::Basename qw( basename );
use File::Spec::Functions qw( tmpdir catfile );

=head1 DESCRIPTION

This module associates a PID file with your script for the purpose of
keeping more than one copy from running (concurrency prevention).  It
creates the PID file, checks for its existence when the script is run,
terminates the script if there is already an instance running, and
removes the PID file when the script finishes.

This module's objective is to provide a completely simplified interface
that makes adding PID-file-based concurrency prevention to your script
as quick and simple as possible; hence File::Pid::Quick.  For a more
nuanced implementation of PID files, please see File::Pid.

The absolute simplest way to use this module is:

    use File::Pid::Quick;

A default PID file will be used, located in C<< File::Spec->tmpdir >> and
named C<< File::Basename::basename($0) . '.pid' >>; for example, if
C<$0> is F<~/bin/run>, the PID file will be F</tmp/run.pid>.  The PID file
will be checked and/or generated immediately on use of the module.

Alternately, an import list may be provided to the module.  It can contain
three kinds of things:

    use File::Pid::Quick qw( verbose );

If the string 'verbose' is passed in the import list, the module will do
more reporting on its activities than otherwise.  It will use warn() for
its verbose output.

    use File::Pid::Quick qw( timeout 60 );

If the string 'timeout' is passed in the import list, the next item in
the import list will be interpreted as a timeout after which, instead of
terminating itself because another instance was found, the script should
send a SIGTERM to the other instance and go ahead itself.  The timeout
must be a positive integer.

    use File::Pid::Quick qw( manual );

If the string 'manual' is passed in the import list, the normal behavior
of generating a default PID file will be suppressed.  This is essentially
for cases where you want to control exactly when the PID file check is
performed by using File::Pid::Quick->check(), below.  The check will still
be performed immediately if a filename is also provided in the import list.

    use File::Pid::Quick qw( /var/run/myscript.pid );

Any other string passed in the import list is interpreted as a filename
to be used instead of the default for the PID file.  If more than one such
string is found, this is an error.

Any combination of the above import list options may be used.

=cut

our @pid_files_created;
our $verbose;
our $timeout;

sub import($;@) {
    my $package = shift;
    my $filename;
    my $manual;
    while(scalar @_) {
        my $item = shift;
        if($item eq 'verbose') {
            $verbose = 1;
        } elsif($item eq 'manual') {
            $manual = 1;
        } elsif($item eq 'timeout') {
            $timeout = shift;
            unless(defined $timeout and $timeout =~ /^\d+$/ and int($timeout) eq $timeout and $timeout > 0) {
                carp 'Invalid timeout ' . (defined $timeout ? '"' . $timeout . '"' : '(undefined)');
                exit 1;
            }
        } else {
            if(defined $filename) {
                carp 'Invalid option "' . $item . '" (filename ' . $filename . ' already set)';
                exit 1;
            }
            $filename = $item;
        }
    }
    __PACKAGE__->check($filename, $timeout, 1)
        unless $^C or ($manual and not defined $filename);
}

END {
    foreach my $pid_file_created (@pid_files_created) {
        next
            unless open my $pid_in, '<', $pid_file_created;
        my $pid = <$pid_in>;
        chomp $pid;
        $pid =~ s/\s.*//o;
        if($pid == $$) {
	        if($^O =~ /^MSWin/) {
		        close $pid_in;
		        undef $pid_in;
			}
            if(unlink $pid_file_created) {
                warn "Deleted $pid_file_created for PID $$\n"
                    if $verbose;
            } else {
                warn "Could not delete $pid_file_created for PID $$\n";
            }
        } else {
            warn "$pid_file_created had PID $pid, not $$, leaving in place\n"
                if $verbose;
        }
        close $pid_in
	        if defined $pid_in;
    }
}

=head2 check

    File::Pid::Quick->check('/var/run/myjob.pid', 60);

    File::Pid::Quick->check(undef, undef, 1);

Performs a check of the specified PID file, including generating it
if necessary, finding whether another instance is actually running,
and terminating the current process if necesasry.

All arguments are optional.

The first argument, $pid_file, is the filename to check; an undefined
value results in the default (described above) being used.

The second argument, $use_timeout, is a PID file timeout.  If an
already-running script instance started more than this many seconds
ago, don't terminate the current instance; instead, terminate the
already-running instance (by sending a SIGTERM) and proceed.  If
defined, this must be a non-negative integer.  An undefined value
results in the timeout value set by this module's import list being
used, if any; a value of 0 causes no timeout to be applied, overriding
the value set by the import list if necessary.

The third argument, $warn_and_exit, controls how the script terminates.
If it is false, die()/croak() is used.  If it is true, warn()/carp() is
used to issue the appropriate message and exit(1) is used to terminate.
This allows the module to terminate the script from inside an eval();
PID file checks performed based on the module's import list use this
option.

=cut

sub check($;$$$) {
    my $package = shift;
    my $pid_file = shift;
    my $use_timeout = shift;
    my $warn_and_exit = shift;
    $pid_file = catfile(tmpdir, basename($0) . '.pid')
        unless defined $pid_file;
    $use_timeout = $timeout
        unless defined $use_timeout;
    if(defined $use_timeout and ($use_timeout =~ /\D/ or int($use_timeout) ne $use_timeout or $use_timeout < 0)) {
        if($warn_and_exit) {
            carp 'Invalid timeout "' . $use_timeout . '"';
            exit 1;
        } else {
            croak 'Invalid timeout "' . $use_timeout . '"';
        }
    }
    if(open my $pid_in, '<', $pid_file) {
        flock $pid_in, LOCK_SH;
        my $pid_data = <$pid_in>;
        chomp $pid_data;
        my $pid;
        my $ptime;
        if($pid_data =~ /(\d+)\s+(\d+)/o) {
            $pid = $1;
            $ptime = $2;
        } else {
            $pid = $pid_data;
        }
        if($pid != $$ and kill 0, $pid) {
            my $name = basename($0);
            if($timeout and $ptime < time - $timeout) {
                my $elapsed = time - $ptime;
                warn "Timing out current $name on $timeout sec vs. $elapsed sec, sending SIGTERM and rewriting $pid_file\n"
                    if $verbose;
                kill 'TERM', $pid;
            } else {
                if($warn_and_exit) {
                    warn "Running $name found via $pid_file, process $pid, exiting\n";
                    exit 1;
                } else {
                    die "Running $name found via $pid_file, process $pid, exiting\n";
                }
            }
        }
        close $pid_in;
    }
    unless(grep { $_ eq $pid_file } @pid_files_created) {
	    my $pid_out;
        unless(open $pid_out, '>', $pid_file) {
            if($warn_and_exit) {
                warn "Cannot write $pid_file: $!\n";
                exit 1;
            } else {
                die "Cannot write $pid_file: $!\n";
            }
        }
        flock $pid_out, LOCK_EX;
        print $pid_out $$, ' ', time, "\n";
        close $pid_out;
        push @pid_files_created, $pid_file;
        warn "Created $pid_file for PID $$\n"
            if $verbose;
    }
}

=head2 recheck

    File::Pid::Quick->recheck;

    File::Pid::Quick->recheck(300);

    File::Pid::Quick->recheck(undef, 1);

Used to reverify that the running process is the owner of the
appropriate PID file.  Checks all PID files which were created by
the current process.

All arguments are optional.

The first argument, $timeout, is a timeout value which will be
applied to PID file checks in exactly the same manner as describe
for check() above.

The second argument, $warn_and_exit, works identically to the
$warn_and_exit argument described for check() above.

=cut

sub recheck($;$$) {
    my $package = shift;
    my $timeout = shift;
    my $warn_and_exit = shift;
    warn "no PID files created\n"
        unless scalar @pid_files_created;
    foreach my $pid_file_created (@pid_files_created) {
        $package->check($pid_file_created, $timeout, $warn_and_exit);
    }
}

1;

__END__

=head1 SEE ALSO

L<perl>, L<File::Pid>

=head1 AUTHOR

Matthew Sheahan, E<lt>chaos@lostsouls.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2007, 2010 Matthew Sheahan.  All rights reserved.
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
