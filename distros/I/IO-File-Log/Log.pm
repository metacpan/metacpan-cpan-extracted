package IO::File::Log;

require 5.005_62;
use Carp;
use strict;
use warnings;
use IO::File;
use IO::Select;
use vars qw($AUTOLOAD);

our $VERSION = '1.01';

our $TIMEOUT = 5;		# Seconds between checks for changed file

sub new ($) {
    my $type	= $_[0];
    my $class	= ref($type) || $type || "IO::File::Log";
    my $file	= $_[1];

    return undef unless -f $file;

    my $fh = new IO::File $file or return undef;
    my $sel = new IO::Select or return undef;

    $sel->add($fh);

    return bless { 

	file	=> $file, 
	sel	=> $sel, 
	fh	=> $fh, 
	stat	=> [ _stat($file) ] 

	}, $class;
}

sub _stat ($) {
    return (stat $_[0])[0, 1, 6];
}

sub _dcomp {
    my $l1 = shift;
    my $l2 = shift;

    return 0 unless @$l1 and @$l2;

    for (@$l1 < @$l2 ? 0 .. @$l1 : 0 .. @$l2) {
 	return 0 if 
 	    defined $l1->[$_] and defined $l2->[$_] and $l1->[$_] ne $l2->[$_];
    }

    return 1;
}

				# Tell the module to close the current log
				# and re-open it, possibly getting a
				# different file

sub _reset {
    my $self = shift;

    $self->{sel}->remove($self->{fh});
    $self->{fh}->close;
    $self->{fh} = new IO::File $self->{file}
    or croak "Cannot re-open changed file ", $self->{file}, ": $!";
    $self->{stat} = [ _stat($self->{file}) ];
    $self->{sel}->add($self->{fh});
}

				# At EOF, wait for either more output
				# or a new file with the same name, then
				# do the right thing.
sub _loop_on_end {
    my $self = shift;

    seek($self->{fh}, 0, 1);
    $self->{fh}->clearerr;
    return unless $self->{fh}->eof;

				# At EOF, select with a small timeout, while
				# checking for a new file...
    
    while (1) {

#	warn "# ostat = (", join(',', @{$self->{stat}}), ")\n";
#	warn "# nstat = (", join(',', (stat($self->{file}))[0, 1, 6]), ")\n";

	if (-f $self->{file} and 
	    ! _dcomp([(stat($self->{file}))[0, 1, 6]], 
		     $self->{stat})) 
	{
#	    warn "# File changed\n";

	    $self->_reset;

	}

				# The following might help to refresh
				# the error condition on some systems

	$self->{fh}->clearerr;
	seek($self->{fh}, 0, 1);

	my $fh = ($self->{sel}->can_read($TIMEOUT))[0];

#	warn "# select returned\n";

	unless (defined $fh) {
#	    warn "#select returned undef\n";
	    next;
	}

	unless ($fh->eof) {
	    return if ($fh eq $self->{fh});
	}

	sleep $TIMEOUT;
    }

}

				# Execute the named function on the
				# IO::File object
sub _drive {
    my $self = shift;
    my $func = shift;

#    warn "# Invoke $func on $self->{fh}\n";

    return $self->{fh}->$func(@_);
}

sub AUTOLOAD {

    my $self = shift;

    $AUTOLOAD =~ s/^IO::File::Log:://;

    if (grep { $AUTOLOAD eq $_ } 
	qw( 
	    eof 
	    stat
	    seek
	    tell
	    close 
	    error
	    fileno 
	    syssek
	    untaint
	    DESTROY 
	    getlines 
	    clearerr

	    )) {

				# Functions that can be executed at
				# any point...

	return $self->_drive($AUTOLOAD, @_);

    }
    elsif (grep { $AUTOLOAD eq $_ } 
	   qw( 
	       getline 
	       read 
	       getc 
	       sysread
	       
	       )) {

				# Functions that must be executed
				# at the end of the file...

	$self->_loop_on_end;
	return $self->_drive($AUTOLOAD, @_);
    }
    else {

				# Let the user know that we do not
				# support just anything

	croak "Function $AUTOLOAD not supported";

    }
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

IO::File::Log - IO::File abstraction on logging files

=head1 SYNOPSIS

  use IO::File::Log;

  my $fh = new IO::File::Log "mylogfile";

  while (my $line = $fh->readline) {
      # Your code here...
  }

  my @remaining = $fh->getlines;

=head1 DESCRIPTION

Under this discussion, a log file refers to the classical notion of a
daemon's log file, that is, a file that can be appended to at any time
or that can be "rotated" (ie, the original file can be C<rename()>d
and a new file with the same name created in its place).

This method provides an abstraction that allows reading operations to
occur almost transparently from those files (see CAVEATS later on for
more information). This extension deals with the possibility of the
file being rotated, appended to, etc.

Note however that the basic assumption for reading a log file, is that
it B<never ends>. The general algorythm for this module is as follows:

=over

=item At -E<gt>new(), set the file pointer to the beginning of the file
and store the file's metadata as object state.

=item At any traditional C<IO::File> operation, perform it on the
current file position and store the resulting file ponter's position.

=item At EOF, poll the system to detect a new file with the same name
given to -E<gt>new() but different metadata. When found, open this new
file and fulfill the pending operation in the new file.

=back

=head1 CAVEATS

Note that -E<gt>getlines() will only return the list of lines on the
file, up to the EOF. Otherwise, this method would block forever as the
basic assumption is that log files always grow. It is important to
note that if the daemon (or the sysadmin) is not careful about proper
log rotation, it might be possible to hang or to read a block of text
in an unexpected format.

As a caveat, C<IO::File::Log> only supports reading from standard
files, therefore the only valid way to call C<-E<gt>new()> is to
specify the desired file name of the log file to read. Writing may or
may not work, and is unsupported and deprecated.

Also, not all the functions of the C<IO::*> family are
supported. Currently, only C<getlines> and C<getline> are
supported. More functions may be added in the future, as the need
arise.

Care must be taken when working with C<seek()> and friends. It might
be possible for a log to be rotated between a C<tell()> and a
C<seek()>. This would cause unexpected results.

Note that if the log file is truncated, there's a very good chance of
this event being missed altogether, as in this case the file's
metadata does not change. In order to try to catch this event in more
situations, the current file length is compared with the current file
position. If the file position is beyond the current file length, the
file is assumed to have changed.

Users are encouraged to write the login of the program that uses this
module to reset the log file manually when a read from it returns
undef or whenever an EOF condition is seen. The C<-E<gt>_reset()>
method can be used to force the module to close and re-open the log
file.

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 1.00

Original version; created by h2xs 1.1.1.4 with options

  -ACOXcfkn
	IO::File::Log
	-v
	1.00

Tested under Darwin (Mac OS X 10.1.3).

=item 1.01

Fixes for cases where log rotation is too slow (ie, a lot of time
passes between the C<rename()> of the existing log file and its
creation). This produced a small change on semantics, where an
operation blocked at the enf-of-file will return as soon as the new
file is created and data is written to it.

=back


=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
