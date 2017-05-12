# Log::Rolling
# Written by Fairlight <fairlite@fairlite.com>
# Copyright 2008-2009, Fairlight Consulting
# Last Modified:  07/27/09
##############################################################################

########## Initialise.
##### Package name.
package Log::Rolling;

##### Pragmas.
use 5.006;
use warnings;
use strict;

##### Need a few modules.
use Fcntl;
use Fcntl qw(:seek :flock);
use Carp;

=head1 NAME

Log::Rolling - Log to simple and self-limiting logfiles.

=head1 VERSION

Version 1.02

=cut

##### Set version.
our $VERSION = '1.02';


########## Begin meat of module.

=head1 SYNOPSIS

Log::Rolling is a module designed to give programs lightweight, yet
powerful logging facilities.  One of the primary benefits is that, while the
logs I<can> be infinitely long and handled by something like C<logrotate>,
the module is capable of limiting the number of lines in the log in a fashion
where by the oldest lines roll off to keep the size constant at the maximum
allowed size, if so tuned.

This module is particularly useful when you need to keep logs around for a 
certain amount of available data, but do not need to incur the complexity
and overhead of using something as heavy as C<logrotate> or other methods
of archiving.  Since the rolling is built into the logging facility, no
extra cron jobs or the like are necessary.

Data is buffered throughout the run of a program with each call to C<entry()>.
Once C<commit()> is called, that buffer is written to the log file, and the
log buffer is cleared.  The C<commit()> method may be called as many times as
necessary; however, it is best to do so as few times as required due to the
overhead of file operations involved in rolling the log--hence the reason the
entries are stored in memory until manually committed in the first place.

     use Log::Rolling;
     my $log = Log::Rolling->new('/path/to/logfile.txt');

     # Define the maximum log size in lines.  Default is 0 (infinite).
     $log->max_size(50000);

     # Add a log entry line.
     $log->entry("Log information string here...");

     # Commit all log entry lines in memory to file and roll the log lines
     # to accomodate max_size.
     $log->commit;

=head1 METHODS

=head2 new()
    
     my $log = Log::Rolling->new('/path/to/logfile.txt'); 
     my $log = Log::Rolling->new(log_file => '/path/to/file',
                                 max_size => 5000,
                                 wait_attempts => 30,
                                 wait_interval => 1,
                                 mode => 0600
                                 pid => 1);

If no logfile is given, or if the logfile is unusable, the constructor 
returns false (0).

=cut

sub new {
     my $class = shift;
     my $self = {};
     ${self}->{'log_file'} = undef;
     ${self}->{'max_size'} = 0;  # Unlimited by default.
     ${self}->{'wait_attempts'} = 30;
     ${self}->{'wait_interval'} = 1;
     ${self}->{'mode'} = 0600;
     ${self}->{'acc'} = '';
     ${self}->{'pid'} = 0;
     ${self}->{'roll_allowed'} = 0;
     if (scalar(@_) % 2) {
          ${self}->{'log_file'} = shift if scalar(@_) == 1;
     } else {
          my %attrs = @_;
          while (my ($key, $val) = each %attrs) {
               if (${key} eq 'log_file') {
                    ${self}->{'log_file'} = ${val};
               } elsif (${key} eq 'max_size' and ${val} =~ /^\d+$/) {
                    ${self}->{'max_size'} = ${val};
               } elsif (${key} eq 'wait_attempts' and ${val} =~ /^\d+$/) {
                    ${self}->{'wait_attempts'} = ${val};
               } elsif (${key} eq 'wait_interval' and ${val} =~ /^\d+$/) {
                    ${self}->{'wait_interval'} = ${val};
               } elsif (${key} eq 'pid' and ${val} =~ /^(?:0|1)$/) {
                    ${self}->{'pid'} = ${val};
               } elsif (${key} eq 'mode' and ${val} =~ /^\d{4}$/) {
                    ${self}->{'mode'} = ${val};
               } 
          }
     }
     return(0) unless defined(${self}->{'log_file'});
     if (not sysopen(LOG,${self}->{'log_file'},O_CREAT|O_WRONLY,${self}->{'mode'})) {
          return(0);
     } else {
          close(LOG) or croak('Could not close log file.');
     }
     bless(${self},${class});
     return(${self});
}

=head2 log_file()

This method defines the path of the logfile.  Returns the value of the
logfile, or false (0) if the logfile is unusable.

=cut

sub log_file {
     my $self = shift;
     if (@_) {
          ${self}->{'log_file'} = shift;
     } 
     if (not sysopen(LOG,${self}->{'log_file'},O_CREAT|O_WRONLY,${self}->{'mode'})) {
          return(0);
     } else {
          close(LOG) or croak('Could not close log file.');
     }
     return(${self}->{'log_file'});
}

=head2 max_size()

This method sets the maximum size of the logfile in lines.  The size
is infinite (0) unless this method is called, or unless the size was
defined using C<new()>.  Returns the maximum size.

=cut

sub max_size {
     my $self = shift;
     if (@_) {
          ${self}->{'max_size'} = shift;
     } 
     ${self}->{'max_size'} = 0, return(0) if defined(${self}->{'max_size'}) and ${self}->{'max_size'} !~ /^\d+$/;
     return(${self}->{'max_size'});
}

=head2 wait_attempts()

This method sets the maximum number of attempts to wait for a lock on
the logfile.  Returns the maximum wait attempt setting.

=cut

sub wait_attempts {
     my $self = shift;
     if (@_) {
          ${self}->{'wait_attempts'} = shift;
     } 
     ${self}->{'wait_attempts'} = 30, return(0) if defined(${self}->{'wait_attempts'}) and ${self}->{'wait_attempts'} !~ /^\d+$/;
     return(${self}->{'wait_attempts'});
}

=head2 wait_interval()

This method sets the interval in seconds between attempts to wait for 
a lock on the logfile.  Returns the wait interval setting.

=cut

sub wait_interval {
     my $self = shift;
     if (@_) {
          ${self}->{'wait_interval'} = shift;
     } 
     ${self}->{'wait_interval'} = 1, return(0) if defined(${self}->{'wait_interval'}) and ${self}->{'wait_interval'} !~ /^\d+$/;
     return(${self}->{'wait_interval'});
}

=head2 mode()

This method sets the file mode to be used when creating the log file
if the file does not yet exist.  The value should be an octal value
(e.g., 0644).  Returns the file mode.

=cut

sub mode {
     my $self = shift;
     if (@_) {
          ${self}->{'mode'} = shift;
     } 
     ${self}->{'mode'} = 0600, return(0) if defined(${self}->{'mode'}) and ${self}->{'mode'} !~ /^\d{4}$/;
     return(${self}->{'mode'});
}

=head2 pid()

This method sets whether the process ID will be recorded in the log 
entry.  Enable PID with 1, disable with 0.  Returns the value of the 
setting.

=cut

sub pid {
     my $self = shift;
     if (@_) {
          my $pset = shift;
          ${self}->{'pid'} = ${pset} if ${pset} =~ /^(?:0|1)$/;
     }
     return(${self}->{'pid'});
}

=head2 entry()

Adds an entry to the log file accumulation buffer B<in memory>.  No 
entries are ever written to disk unless and until C<commit()> is 
called.

=cut

sub entry {
     my $self = shift;
     my $pid = "[$$] - ";
     $pid = '' unless ${self}->{'pid'};
     if (@_) {
          my @entries = @_;
          foreach my $item (@entries) {
               chomp(${item});
               ${self}->{'acc'} .= scalar(localtime(time)). ": ${pid}" . ${item} . "\n";
          } 
     }
     return(1);
}

=head2 commit()

Commits the current log file data in memory to the actual file on 
disk, and clears the log accumulation buffer.

=cut

sub commit {
     my $self = shift;
     return(0) unless defined(${self}->{'log_file'});
     my $track_waits = 0;
     my $fres = 0;
     sysopen(LOG,${self}->{'log_file'},O_RDWR|O_CREAT|O_APPEND,${self}->{'mode'}) or croak('Could not open log file.');
     my $switchhandle = select(LOG);
     $| = 1;
     select(${switchhandle});
     ${self}->{'roll_allowed'} = 1;
     $fres = flock(LOG,LOCK_EX|LOCK_NB);
     while (${fres} != 1 and ${track_waits} < ${self}->{'wait_attempts'}) {
          sleep(${self}->{'wait_interval'});
          $track_waits++;
          $fres = flock(LOG,LOCK_EX|LOCK_NB);
     }
     croak('Could not lock log file.') if ${track_waits} == ${self}->{'wait_attempts'};
     print LOG (${self}->{'acc'});
     ${self}->{'acc'} = '';
     &roll(${self}) if defined(${self}->{'max_size'}) and ${self}->{'max_size'} =~ /^\d+$/ and ${self}->{'max_size'} > 0;
     ${self}->{'roll_allowed'} = 0;
     flock(LOG,LOCK_UN) or croak('Could not unlock log file.')
;
     close(LOG) or croak('Could not close log file.');
     return(1);
}

=head2 roll()

This method rolls the oldest entries out of the logfile and leaves
only up to max_size lines (or less, if the contents are not that 
long) within the logfile.  Returns true (1) if log was successfully 
rolled, or false (0) if it was not.  B<This method is not meant to be 
called independantly.  Doing so will simply return false (0).>

=cut

sub roll {
     my $self = shift;
     return(0) unless ${self}->{'roll_allowed'};
     my (@loglines,$line);
     seek(LOG,0,SEEK_SET) or croak('Unable to seek to zero to roll logfile.');
     @loglines = <LOG>;
     seek(LOG,0,SEEK_END), return(0) if not defined(${self}->{'log_file'});
     seek(LOG,0,SEEK_END), return(0) if scalar(@loglines) < ${self}->{'max_size'};
     my $length_delete_log = (scalar(@loglines)-${self}->{'max_size'});
     splice(@loglines,0,${length_delete_log});
     truncate(LOG,0) or croak('Unable to truncate while rolling logfile.')
;
     seek(LOG,0,SEEK_SET) or croak('Unable to seek to zero after truncation while rolling logfile.');
     print LOG (@loglines);
     return(1);
}

=head2 clear()

This method clears the buffered log entries B<without> writing them 
to file, should it be deemed necessary to "revoke" log entries 
already made but not yet committed to file.  Returns true (1).

=cut

sub clear {
     my $self = shift;
     ${self}->{'acc'} = '';
     return(1);
}

=head1 AUTHOR

Mark Luljak, <fairlite at fairlite.com>

Fairlight Consulting - L<http://www.fairlite.com/>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-selfmaintaining at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Rolling>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Rolling


You can also look for information at:

=over 5

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Rolling>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Rolling>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Rolling>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Rolling/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Mark Luljak, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Log::Rolling
