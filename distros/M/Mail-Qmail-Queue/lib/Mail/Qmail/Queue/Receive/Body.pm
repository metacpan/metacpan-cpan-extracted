package Mail::Qmail::Queue::Receive::Body;
our $VERSION = 0.02;
#
# Copyright 2006 Scott Gifford
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings;
use strict;

use constant QQ_BODY_FD => 0;

=head1 NAME

Mail::Qmail::Queue::Receive::Body - Receive message body when emulating qmail-queue

=head1 SYNOPSIS

  use Mail::Qmail::Queue::Receive::Body;

  my $qq_body = Mail::Qmail::Queue::Receive::Body->new
    or die "Couldn't get qmail-queue body\n"

  print "Message body: ",$qq_body->body,"\n";

  my $fh = $qq_body->body_fh
    or die "Error getting body handle: $!\n";
  while (<$fh>) {
    s/perl/Pathologically Eclectic Rubbish Lister/gi;
    print;
  }
  $fh->close
    or die "Error closing message: $!\n";

=head1 DESCRIPTION

C<Mail::Qmail::Queue::Receive::Body> is designed for use in
C<qmail-queue> emulation.  This is a way of modifying the behavior of
qmail by replacing its queueing mechanism with your own program, which
may modify or reject the message, then call the real C<qmail-queue>
program to queue the message.  This is commonly done with Bruce
Guenter's QMAILQUEUE patch
(L<http://www.qmail.org/top.html#qmailqueue>), also included in
netqmail (L<http://www.qmail.org/netqmail/>).  This patch
lets you override the standard C<qmail-queue> program by setting the
environment variable C<QMAILQUEUE>.  It can also be done by renaming
the original C<qmail-queue>, installing your script in its place, and
having your script call the renamed C<qmail-queue> to inject the
message.

For a simplified interface, see L<Mail::Qmail::Queue::Message>.  To
read the message envelope, see L<Mail::Qmail::Queue::Receive::Envelope>.
To re-inject the message, see L<Mail::Qmail::Queue::Send>.

Note that the specifications for C<qmail-queue>'s interface require
that the message be read before the envelope.

The constructor and methods of this class will C<die> if they
encounter a serious error.  If you would prefer different behavior,
use C<eval> to catch these and handle them as exceptions.

=cut

use Mail::Qmail::Queue::Error qw(:errcodes :fail);

=head2 CONSTRUCTOR

=over 4

=item new ( %options )

Creates a new qmail-queue message body reader, but does not start
reading it.  

Available options are:

=over 4

=item FileHandle

Read the body from the specified file handle, instead of the default
of file desriptor 0.

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
	$self->{_fh} = FileHandle->new_from_fd(QQ_BODY_FD,"r")
	    or permfail QQ_EXIT_READERR, "Couldn't open FD 0 to read message: $!\n";
    }
    $self;
}

=head2 METHODS

=over 4

=item body_fh( )

Returns a filehandle from which the body can be read.

=cut

sub body_fh
{
    my $self = shift;
    return $self->{_fh};
}


=item close( )

Closes the filehandle with the message body, and returns the result of
the C<close>.

=cut

sub close
{
    my $self = shift;
    return close($self->{_fh});
}


=item body( )

Returns the entire body as a string, then closes the filehandle.  Note
that this can consume a lot of memory for a very large message;
reading it from the handle returned by the C<body_fh> method will be
more efficient.

=cut

sub body
{
    my $self = shift;
    my $fh = $self->{_fh};
    local $/ = undef;
    my $body = <$fh>;
    $self->close()
        or die "Error closing message body filehandle: $!\n";
    return $body;
}

=back

=head1 SEE ALSO

L<qmail-queue(8)>, L<Mail::Qmail::Queue::Message>,
L<Mail::Qmail::Queue::Receive::Envelope>, L<Mail::Qmail::Queue::Send>.

=head1 COPYRIGHT

Copyright 2006 Scott Gifford.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
