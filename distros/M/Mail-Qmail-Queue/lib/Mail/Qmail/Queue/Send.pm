package Mail::Qmail::Queue::Send;
our $VERSION = 0.02;
#
# Copyright 2006 Scott Gifford
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings;
use strict;

use constant DEFAULT_QMAIL_QUEUE => '/var/qmail/bin/qmail-queue';
use constant QQ_ENV_FD => 1;
use constant QQ_BODY_FD => 0;

=head1 NAME

Mail::Qmail::Queue::Send - Send a message to a program implementing the qmail-queue interface

=head1 SYNOPSIS

  use Mail::Qmail::Queue::Send;

  my $qq = Mail::Qmail::Queue::Send->new()
      or die "Couldn't create qmail-queue sender: $!\n";

  $qq_send->body("Test message\n")
      or die "Couldn't write body: $!\n";

  $qq_send->from('sgifford@suspectclass.com')
      or die "Couldn't write envelope from: $!\n";
  $qq_send->to('GIFF@cpan.org')
      or die "Couldn't write envelope to #1: $!\n";
  $qq_send->to('gifford@umich.edu')
      or die "Couldn't write envelope to #2: $!\n";
  $qq_send->envelope_done()
      or die "Couldn't finish writing envelope: $!\n";

  $qq_send->wait_exitstatus() == 0
      or die "Error sending message: exit status $?\n";

Note that the L<qmail-queue(8)> specifications require that the body
be read first, then the envelope.

=cut

use POSIX;
use FileHandle;

use Mail::Qmail::Queue::Error qw(:errcodes :fail);

=head1 DESCRIPTION

This module sends a message to a program implementing the
L<qmail-queue(8)|qmail-queue> protocol.  You must send the body first,
then the envelope.

=head2 CONSTRUCTOR

=over 4

=item new ( %options )

Creates a new qmail-queue sender.  Executes C<qmail-queue> or the
equivalent, and sets up the file descriptors to prepare to talk to it.
If a C<QmailQueue> option is given, that will be used as the path to
the C<qmail-queue> program.  Otherwise, the contents of the
environment variable C<QMAILQUEUE> will be used; if that is unset,
C</var/qmail/bin/qmail-queue> is the default.

Available options are:

=over 4

=item QmailQueue

Specifies the path to the program that will handle the message.

=item LeaveEnvHandle

Do not open up file descriptor 1 to C<qmail-queue>'s envelope reader;
instead the current process's file descriptor 1 will be connected to
it.  This is useful if you are writing a filter to change the body,
but want to leave the envelope alone.

=item LeaveBodyHandle

Do not open up file descriptor 0 to C<qmail-queue>'s body reader;
instead the current process's file descriptor 0 will be connected to
it.  This is useful if you are writing a filter to change the
envelope, but want to leave the body alone.

=back

=back

=cut

sub new
{
    my $class = shift;
    my %o = @_;
    my $self = bless {}, $class;
    
    my $qq_path = $o{QmailQueue} || $ENV{QMAILQUEUE} || DEFAULT_QMAIL_QUEUE;
    $self->{_qq_pid} = $self->_start_qmail_queue($qq_path,\%o)
	or tempfail QQ_EXIT_NETFAIL, "Couldn't start up '$qq_path': $!\n";
    $self;
}

=head2 METHODS

=over 4

=item send ( $body, $from, @to )

Sends a complete message, and returns the exit status of the
C<qmail-queue> program.

=cut

sub send
{
    my $self = shift;
    $self->body(shift)
	or return undef;
    $self->from(shift)
	or return undef;
    $self->to(@_)
	or return undef;
    $self->envelope_done
	or return undef;
    return $self->wait_exitstatus;
}


=item body_fh ( )

Retrieves a Perl filehandle to which the message body can be written.

=cut

sub body_fh
{
    my $self = shift;
    return $self->{_msg_fh};
}

=item body_close ( )

Close the body filehandle.  You must use this when you're done sending
the body filehandle, to indicate to the C<qmail-queue> program that
you're done, and to tell this module that it's ready to accept the
envelope.

=cut

sub body_close
{
    my $self = shift;

    $self->{_body_sent}=1;
    return close($self->{_msg_fh});
}

=item body ( @body )

Send the provided string or strings as the complete body of the
message, closing the filehandle after sending it.

If you are working with a very large message, it may be more efficient
to write the body in smaller pieces to the filehandle returned by
C<body_fh>.

=cut

sub body
{
    my $self = shift;
    my $fh = $self->{_msg_fh}
        or tempfail QQ_EXIT_BUG,"Body filehandle not available!";
    print $fh @_
	or tempfail QQ_EXIT_WRITEERR,"Write error: $!\n";
    $self->body_close()
	or tempfail QQ_EXIT_WRITEERR,"Error closing write pipe: $!\n";
    return 1;
}

=item from ( $from )

Send the provided email address as the envelope from.  You must send
the body first.

=cut

sub from
{
    my $self = shift;

    my($from)=@_;
    $self->{_from}=$from;
    $self->put_envelope_entry('F'.$from);
}

=item to ( @to )

Send the provided email address or addresses as the envelope to.  You
must send the body and the envelope from first.

=cut

sub to
{
    my $self = shift;
    defined($self->{_from})
	or tempfail QQ_EXIT_BUG,"envelope from must be set before envelope to\n";
    $self->put_envelope_entry(map { 'T'.$_ } @_);
}

=item envelope_done ( )

Indicate that you have sent all of the envelope, and are now done.
The filehandle will be closed, and C<qmail-queue> will probably begin
processing the message.

=cut

sub envelope_done
{
    my $self = shift;
    $self->put_envelope_entry('')
	or return undef;
    my $fh = $self->{_env_fh}
        or tempfail QQ_EXIT_BUG, "No envelope filehandle\n";
    close($fh)
	or tempfail QQ_EXIT_WRITEERR,"Error closing envelope filehandle: $!\n";
    return 1;
}

=item put_envelope_entry ( @entries )

Send the provided envelope entries.  They must be properly formatted
entries, or else they will confuse the called C<qmail-queue> program.
The null character will be inserted between the entries by this
method, and you should not set it.

Note that if you use this method instead of C<from>, you cannot use
the C<to> method, because this module won't know that you've already
sent an envelope from.

L<Mail::Qmail::Queue::Receive::Envelope's read_envelope_string method|Mail::Qmail::Queue::Receive::Envelope/read_envelope_string> will
return strings that can be passed to this method.

=cut

sub put_envelope_entry
{
    my $self = shift;

    $self->envelope_write(join("\0",@_)."\0");
}

=item envelope_write ( @str )

Send the provided string or strings directly to the C<qmail-queue>
envelope filehandle.  This requires a knowledge of the
L<qmail-queue(8)> protocol.

=cut

sub envelope_write
{
    my $self = shift;
    my $fh = $self->{_env_fh}
        or tempfail QQ_EXIT_BUG, "No envelope filehandle\n";
    return print $fh @_;
}

=item envelope_fh

Retrieve a Perl filehandle to which the message envelope can be
written.  Using this filehandle requires knowledge of the envelope
format; see L<qmail-queue(8)> for details.

=cut

sub envelope_fh
{
    my $self = shift;
    return $self->{_env_fh};
}


=item wait_exitstatus ( )

Wait for the C<qmail-queue> program to finish, and return its exit
status.  If the program is killed by a signal, L<QQ_EXIT_BUG|Mail::Qmail::Queue::Error/QQ_EXIT_BUG> 
will be returned.

=cut

sub wait_exitstatus
{
    my $self = shift;

    $self->wait;
    if ($? == 0)
    {
	return 0;
    }
    elsif ($? >> 8)
    {
	return $? >> 8;
    }
    else
    {
	return QQ_EXIT_BUG;
    }
}

=item wait ( )

Wait for the C<qmail-queue> program to finish, and return the value
from C<waitpid>.

=cut

sub wait
{
    my $self = shift;
    waitpid($self->{_qq_pid},@_);
}

sub _start_qmail_queue
{
    my $self = shift;
    my($path,$o)=@_;
    my(@env_pipe,@body_pipe);
    
    unless ($o->{LeaveEnvHandle})
    {
	@env_pipe = POSIX::pipe()
	    or tempfail QQ_EXIT_WRITEERR, "Couldn't create envelope pipe: $!\n";
    }
    unless ($o->{LeaveMsgHandle})
    {
	@body_pipe = POSIX::pipe()
	    or tempfail QQ_EXIT_WRITEERR, "Couldn't create envelope pipe: $!\n";
    }
    
    my $f = fork();

    if (!defined($f))
    {
	tempfail QQ_EXIT_TEMPREFUSE, "Fork failed: $!\n";
    }
    elsif ($f)
    {
	# Parent
	if (@body_pipe)
	{
	    POSIX::close($body_pipe[0])
		or tempfail QQ_EXIT_READERR, "Couldn't close body pipe reader in parent: $!\n";
	    $self->{_msg_fh} = FileHandle->new_from_fd($body_pipe[1],"w")
		or tempfail QQ_EXIT_READERR, "Couldn't create FileHandle for body writer fd $body_pipe[1] in parent: $!\n";
	}
	if (@env_pipe)
	{
	    POSIX::close($env_pipe[0])
		or tempfail QQ_EXIT_READERR, "Couldn't close envelope pipe reader in parent: $!\n";
	    $self->{_env_fh} = FileHandle->new_from_fd($env_pipe[1],"w")
		or tempfail QQ_EXIT_READERR, "Couldn't create FileHandle for envelope pipe writer fd $env_pipe[1] in parent: $!\n";
	}
	return $f;
    }
    else
    {
	# Child
	if (@body_pipe)
	{
	    POSIX::close($body_pipe[1])
		or tempfail QQ_EXIT_WRITEERR, "Couldn't close body pipe writer in child: $!\n";
            POSIX::close(QQ_BODY_FD); # Ignore errors
	    POSIX::dup2($body_pipe[0],QQ_BODY_FD)
		or tempfail QQ_EXIT_WRITEERR, "Couldn't dup body pipe reader to fd 1 in child: $!\n";
	    POSIX::close($body_pipe[0])
		or tempfail QQ_EXIT_WRITEERR, "Couldn't close body pipe reader after dup in child: $!\n";
	}
	if (@env_pipe)
	{
	    POSIX::close($env_pipe[1])
		or tempfail QQ_EXIT_WRITEERR, "Couldn't close envelope pipe writer in child: $!\n";
            POSIX::close(QQ_ENV_FD); # Ignore errors
	    POSIX::dup2($env_pipe[0],QQ_ENV_FD)
		or tempfail QQ_EXIT_WRITEERR, "Couldn't dup envelope pipe reader to fd 0 in child: $!\n";
	    POSIX::close($env_pipe[0])
		or tempfail QQ_EXIT_WRITEERR, "Couldn't close envelope pipe reader after dup in child: $!\n";
	}
	exec($path)
	    or tempfail QQ_EXIT_TEMPREFUSE, "exec failed: $!\n";
    }
}

=back

=head1 SEE ALSO

L<qmail-queue(8)>, L<Mail::Qmail::Queue::Message>,
L<Mail::Qmail::Queue::Receive::Body>, L<Mail::Qmail::Queue::Receive::Envelope>.

=head1 COPYRIGHT

Copyright 2006 Scott Gifford.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
