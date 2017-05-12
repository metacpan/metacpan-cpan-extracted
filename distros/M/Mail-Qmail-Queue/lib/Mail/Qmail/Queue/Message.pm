package Mail::Qmail::Queue::Message;
our $VERSION='0.02';
#
# Copyright 2006 Scott Gifford
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME

Mail::Qmail::Queue::Message - Send and/or receive a complete qmail-queue message.

=head1 SYNOPSIS

  use Mail::Qmail::Queue::Send;

  # Read the message
  my $msg = Mail::Qmail::Queue::Message->receive()
    or die "Invalid message\n";

  # Change the from
  my $fr = $msg->from_ref();
  $$fr =~ s/\$/-\@[]/;   # Enable VERPs

  # Change the to
  my $to = $msg->to_ref();
  push(@$to,'GIFF@cpan.org');

  # Change the body
  my $br = $msg->body_ref();
  $$br =~ s/perl/Pathologically Eclectic Rubbish Lister/ig;

  # Now send
  $msg->send() == 0
    or die "Couldn't send message: Exit status $?\n";

=cut

use Mail::Qmail::Queue::Error qw(:errcodes :fail);
use Mail::Qmail::Queue::Receive::Body;
use Mail::Qmail::Queue::Receive::Envelope;
use Mail::Qmail::Queue::Send;

=head1 DESCRIPTION

This module handles mail messages sent and/or received by a program
implementing the L<qmail-queue|qmail-queue(8)> interface.

You can create a message by providing the body and envelope to the
constructor L<new|new>, or from the file
descriptors provided by the qmail-queue interface with the constructor
L<receive|receive>.

You can then modify the message and its envelope, if desired, by
getting references to the various parts and modifying their referents.

Finally, you can send the message with the L<send|send> method.

=head2 CONSTRUCTORS

=over 4

=item new ( $body, $from, @to )

Create a new mail message with the provided body, from, and to.

=cut

sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    ($self->{_body},$self->{_from},@{$self->{_to}})=@_;
    $self;
}

=item receive ( %options )

Receive a message with the L<qmail-queue|qmail-queue(8)> protocol.

This will read the entire message into memory; for very large messages
and/or a lot of recipients, see L<Mail::Qmail::Queue::Send>,
L<Mail::Qmail::Queue::Receive::Envelope>, and
L<Mail::Qmail::Queue::Receive::Body>.

Available options are:

=over 4

=item EnvelopeFileHandle

Read the envelope from the provided FileHandle, instead of the default.

=item BodyFileHandle

Read the body from the provided FileHandle, instead of the default.

=back

=back

=cut

sub receive
{
    my $class = shift;
    my(%o) = @_;
    my(@qq_env_args,@qq_body_args);
    if ($o{EnvelopeFileHandle}) 
    {
	push(@qq_env_args,FileHandle => $o{EnvelopeFileHandle});
    }

    if ($o{BodyFileHandle})
    {
	push(@qq_body_args,FileHandle => $o{BodyFileHandle});
    }
    my $qq_env = Mail::Qmail::Queue::Receive::Envelope->new(@qq_env_args)
	or die "Couldn't get envelope reader: $!\n";
    my $qq_body = Mail::Qmail::Queue::Receive::Body->new(@qq_body_args)
	or die "Couldn't get body reader: $!\n";
    $class->new($qq_body->body,$qq_env->from,$qq_env->to);
}

=head2 METHODS

=over 4

=item send ( %options )

Send the message using the L<qmail-queue|qmail-queue(8)> protocol.
The exit status from the C<qmail-queue> program will be returned, so 0
indicates success.  Valid options are the options for
L<Mail::Qmail::Queue::Send-E<gt>new|Mail::Qmail::Queue::Send/new>.

=cut

sub send
{
    my $self = shift;
    my $qq_send = Mail::Qmail::Queue::Send->new(@_)
	or return undef;
    return $qq_send->send($self->body,$self->from,$self->to);
}

=item from ( )

Get the from part of the envelope.

=cut

sub from
{
    my $self = shift;
    return $self->{_from};
}

=item from_ref ( )

Get a reference to the from part of the envelope.  By operating on
this reference, you can change the value stored in this object.

=cut

sub from_ref
{
    my $self = shift;
    return \$self->{_from}
}

=item to ( )

Get all to parts of the envelope.

=cut

sub to
{
    my $self = shift;
    return @{$self->{_to}};
}

=item to_ref ( )

Get a reference to the list of envelope to items.  By modifying this
list or its contents, you can change the values within this object.

=cut

sub to_ref
{
    my $self = shift;
    return $self->{_to};
}

=item body ( )

Get the body of the message.

=cut

sub body
{
    my $self = shift;
    return $self->{_body};
}

=item body_ref ( )

Get a reference to the body of the message.  By modifying this
reference, you can change the value of the body within this object.

=cut

sub body_ref
{
    my $self = shift;
    return \$self->{_body};
}


=back

=head1 SEE ALSO

L<qmail-queue(8)>, L<Mail::Qmail::Queue::Receive::Envelope>,
L<Mail::Qmail::Queue::Receive::Body>, L<Mail::Qmail::Queue::Send>.

=head1 COPYRIGHT

Copyright 2006 Scott Gifford.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;


1;

