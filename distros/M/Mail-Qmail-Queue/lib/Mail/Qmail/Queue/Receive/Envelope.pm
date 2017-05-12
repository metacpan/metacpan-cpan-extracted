package Mail::Qmail::Queue::Receive::Envelope;
our $VERSION = 0.02;
#
# Copyright 2006 Scott Gifford
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings;
use strict;

use constant QQ_ENV_FD => 1;

=head1 NAME

Mail::Qmail::Queue::Receive::Envelope - Receive envelope information when emulating qmail-queue

=head1 SYNOPSIS

  use Mail::Qmail::Queue::Receive::Envelope;

  my $qq_env = Mail::Qmail::Queue::Receive::Envelope->new
    or die "Couldn't get qmail-queue envelope\n"

  print "Message from: ",$qq_env->from,"\n";
  foreach ($qq_env->to) {
    print "Message to: $_\n"
  }

=head1 DESCRIPTION

C<Mail::Qmail::Queue::Receive::Envelope> is designed for use in
C<qmail-queue> emulation.  This is a way of modifying the behavior of
qmail by replacing its queueing mechanism with your own program, which
may modify or reject the message, then call the real C<qmail-queue>
program to queue the message.  This is commonly done with Bruce
Guenter's QMAILQUEUE patch (L<http://www.qmail.org/top.html#qmailqueue>), also included in netqmail (L<http://www.qmail.org/netqmail/>).  This patch lets
you override the standard C<qmail-queue> program by setting the
environment variable C<QMAILQUEUE>.  It can also be done by renaming
the original C<qmail-queue>, installing your script in its place, and
having your script call the renamed C<qmail-queue> to inject the
message.

For a simplified interface, see L<Mail::Qmail::Queue::Message>.  To
read the body of the message, see L<Mail::Qmail::Queue::Receive::Body>.
To re-inject the message, see L<Mail::Qmail::Queue::Send>.

Note that the specifications for C<qmail-queue>'s interface require
that the message be read before the envelope (perhaps with
L<Mail::Qmail::Queue::Receive::Body|Mail::Qmail::Queue::Receive::Body>)

If the environment variable C<QMAILQUEUE_CHAIN> is set, this module
will treat it as a space-seperated list, remove its first item, and
place that item into the environment variable C<QMAILQUEUE>; if
C<QMAILQUEUE_CHAIN> is unset or empty, C<QMAILQUEUE> will be removed
from the environment.  This allows chaining of qmail-queue processors.

The constructor and methods of this class will C<die> if they
encounter a serious error.  If you would prefer different behavior,
use C<eval> to catch these and handle them as exceptions.

=cut

use Mail::Qmail::Queue::Error qw(:errcodes :fail);
use FileHandle;

=head2 CONSTRUCTOR

=over 4

=item new ( %options )

Creates a new qmail-queue envelope reader, but does not start reading
it.  This constructor will also modify the C<QMAILQUEUE> and
C<QMAILQUEUE_CHAIN> environment variables, as described above.

Available options are:

=over 4

=item FileHandle

Read the envelope from the specified file handle, instead of the
default of file desriptor 1.

=back

=back

=cut

sub new
{
    my $class = shift;
    my %o = @_;
    my $self = bless {}, $class;
    
    if ($o{FileHandle})
    {
	$self->{_fh} = $o{FileHandle};
    }
    else
    {
	$self->{_fh} = FileHandle->new_from_fd(QQ_ENV_FD,"r")
	    or tempfail QQ_EXIT_READERR, "Couldn't open FD 1 to read envelope: $!\n";
    }
    # Special handling of QMAILQUEUE
    if ($ENV{QMAILQUEUE_CHAIN})
    {
	my(@qqchain)=split(' ',$ENV{QMAILQUEUE_CHAIN});
	$ENV{QMAILQUEUE}=shift(@qqchain);
	$ENV{QMAILQUEUE_CHAIN}=join(' ',@qqchain);
    }
    else
    {
	delete $ENV{QMAILQUEUE};
    }

    $self;
}

=head2 METHODS

=over 4

=item from ( )

Returns the sender of the incoming message.

=cut

sub from
{
    my $self = shift;

    if (!defined($self->{_from}))
    {
	my $e = $self->read_envelope_string()
	    or tempfail QQ_EXIT_BADENVELOPE, "Couldn't read envelope string: $!\n";
	my($type,$val)=_parse_envelope($e);
	if ($type ne 'F')
	{
	    tempfail QQ_EXIT_BADENVELOPE, "Invalid envelope: No From entry\n";
	}
	$self->{_from} = $val;
    }
    $self->{_from};
}

=item to ( )

Returns the next recipient of the message, or C<undef> if there are no
more recipients.  In a list context, returns all remaining recipients
of the message.

=cut

sub to
{
    my $self = shift;
    
    if (wantarray)
    {
	my @ret;
	while(my $r = $self->to())
	{
	    push(@ret,$r);
	}
	return @ret;
    }
    # Make sure we've read the sender
    $self->from();
    my $e;
    $e = $self->read_envelope_string()
	or return $e;
    if ($e eq '')
    {
	return undef;
    }
    my($type,$val)=_parse_envelope($e);

    if ($type ne 'T')
    {
	tempfail QQ_EXIT_BADENVELOPE, "Invalid envelope: Expected To entry, but got something else!\n";
    }
    return $val;
}

=item read_envelope_string ( )

Reads and returns the next envelope entry.  The entry will be a type
code followed by the value.  If all envelope entries have been read,
C<undef> will be returned.

These strings can be passed to L<Mail::Qmail::Queue's put_envelope
method|Mail::Qmail::Queue::Send/put_envelope_entry> to send them along
to another C<qmail-queue> filter.

Note that this method does not return the empty item at the end of the
list; it detects it, verifieds it's at the end of the envelope, and
returns C<undef>.  If an empty envelope entry occurs someplace other
than the end of the envelope, or if the envelope ends before reading
an empty entry, this method will C<die>.

=cut

sub read_envelope_string
{
    my $self = shift;
    local $/ = "\0";
    my $fh = $self->{_fh};
    my $line = <$fh>;
    if (!defined($line))
    {
	tempfail QQ_EXIT_BADENVELOPE, "Invalid envelope: EOF appeared before null entry\n";
    }
    chomp($line);
    if ($line eq '')
    {
	# This should be the last entry
	$line = <$fh>;
	if (defined($line))
	{
	    tempfail QQ_EXIT_BADENVELOPE, "Invalid envelope: null entry appeared before EOF\n";
	}
	close($fh)
	    or tempfail QQ_EXIT_BADENVELOPE,"Error closing envelope filehandle: $!\n";
    }
    $line;
}

# Helper method
sub _parse_envelope
{
    return unpack("aa*",$_[0]);
}

=back

=head1 SEE ALSO

L<qmail-queue(8)>, L<Mail::Qmail::Queue::Message>,
L<Mail::Qmail::Queue::Receive::Body>, L<Mail::Qmail::Queue::Send>.

=head1 COPYRIGHT

Copyright 2006 Scott Gifford.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
