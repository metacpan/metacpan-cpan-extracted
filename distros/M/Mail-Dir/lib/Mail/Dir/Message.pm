# Copyright (c) 2016 cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.

package Mail::Dir::Message;

use strict;
use warnings;

use File::Basename ();

=head1 NAME

Mail::Dir::Message - A message in a Maildir queue

=head1 SYNOPSIS

    #
    # Mark message as Draft
    #
    $message->mark('D');

    #
    # Verify that message was marked as Draft
    #
    print "Message is a draft\n" if $message->draft;

=head1 DESCRIPTION

C<Mail::Dir::Message> objects represent messages delivered to a Maildir mailbox,
and are created queries to the mailbox as issued by the method
C<L<Mail::Dir>-E<gt>messages()>.  C<Mail::Dir::Message> objects are not
presently meant to be instantiated directly.

=cut

sub from_file {
    my ( $class, %args ) = @_;

    die('No Maildir object specified')           unless defined $args{'maildir'};
    die('Maildir object is of incorrect type')   unless $args{'maildir'}->isa('Mail::Dir');
    die('No mailbox specified')                  unless defined $args{'mailbox'};
    die('No message filename specified')         unless defined $args{'file'};
    die('No message name specified')             unless defined $args{'name'};
    die('No stat() object provided for message') unless defined $args{'st'};
    die('stat() object is not an ARRAY')         unless ref( $args{'st'} ) eq 'ARRAY';

    if ( defined $args{'dir'} ) {
        die('"dir" may only specify "tmp", "new" or "cur"') unless $args{'dir'} =~ /^(?:tmp|new|cur)$/;
    }

    my $flags = '';

    if ( $args{'flags'} ) {
        $flags = parse_flags( $args{'flags'} );
    }
    elsif ( $args{'name'} =~ /:(?:1,.*)2,(.*)$/ ) {
        $flags = parse_flags($1);
    }

    return bless {
        'maildir' => $args{'maildir'},
        'mailbox' => $args{'mailbox'},
        'dir'     => $args{'dir'},
        'file'    => $args{'file'},
        'name'    => $args{'name'},
        'size'    => $args{'st'}->[7],
        'atime'   => $args{'st'}->[8],
        'mtime'   => $args{'st'}->[9],
        'ctime'   => $args{'st'}->[10],
        'flags'   => $flags
    }, $class;
}

=head1 READING MESSAGES

=over

=item C<$message-E<gt>open()>

Open the current message, returning a file handle.  Will die() if any errors
are encountered.  It is the caller's responsibility to subsequently close the
file handle when it is no longer required.

=cut

sub open {
    my ($self) = @_;

    CORE::open( my $fh, '<', $self->{'file'} ) or die("Unable to open message file $self->{'file'} for reading: $!");

    return $fh;
}

=back

=head1 MOVING MESSAGES

=over

=item C<$message-E<gt>move(I<$mailbox>)>

Move the current message to a different Maildir++ mailbox.  This operation is
only supported when the originating mailbox is created with Maildir++
extensions.

=back

=cut

sub move {
    my ( $self, $mailbox ) = @_;

    die('Maildir++ extensions not supported') unless $self->{'maildir'}->{'maildir++'};
    die('Specified mailbox is same as current mailbox') if $mailbox eq $self->{'maildir'}->{'mailbox'};

    my $mailbox_dir = $self->{'maildir'}->mailbox_dir($mailbox);
    my $new_file    = "$mailbox_dir/cur/$self->{'name'}:2,$self->{'flags'}";

    unless ( rename( $self->{'file'}, $new_file ) ) {
        die("Unable to rename() $self->{'file'} to $new_file: $!");
    }

    $self->{'file'} = $new_file;

    return $self;
}

sub parse_flags {
    my ($flags) = @_;
    my $ret = '';

    die('Invalid flags') unless $flags =~ /^[PRSTDF]*$/;

    foreach my $flag (qw(D F P R S T)) {
        $ret .= $flag if index( $flags, $flag ) >= 0;
    }

    return $ret;
}

=head1 REMOVING MESSAGES

=over

=item C<$message-E<gt>remove()>

Unlink the current message.
This method has the same return value as L<perlfunc/unlink>.
B<Note:> if removal succeeds, the object is no longer valid and should be disposed of.

Do not use this to soft-delete messages. For that, set the C<T> flag instead.

=back

=cut

sub remove {
    my ( $self ) = @_;
    return unlink $self->{'file'};
}

=head1 SETTING MESSAGE FLAGS

=over

=item C<$message-E<gt>mark(I<$flags>, I<$queue>)>

Set any of the following message status flags on the current message.  More
than one flag may be specified in a single call, in any order.

=over

=item * C<P>

Mark the message as "Passed".

=item * C<R>

Mark the message as "Replied".

=item * C<S>

Mark the message as "Seen".

=item * C<T>

Mark the message as "Trashed".

=item * C<D>

Mark the message as a "Draft".

=item * C<F>

Mark the message as "Flagged".

=back

You can also specify the queue to which the message will be moved:

=over

=item * Missing or undefined

Move the message to C<cur>.

=item * C<tmp>

Move the message to C<tmp>.

=item * C<new>

Move the message to C<new>.

=item * C<cur>

Move the message to C<cur>.

=item * C<keepq>

Keep the message in the same queue, do not move it.

=back

=cut

sub mark {
    my ( $self, $flags, $dir ) = @_;
    $flags = parse_flags($flags);

    if ( defined $dir ) {
        die('Queue may only be "keepq", "tmp", "new" or "cur"') unless $dir =~ /^(?:keepq|tmp|new|cur)$/;
        $dir = $self->{'dir'} if $dir eq 'keepq';
    }
    else {
        $dir = 'cur';
    }

    my $mailbox_dir = $self->{'maildir'}->mailbox_dir( $self->{'mailbox'} );
    my $new_file    = "$mailbox_dir/$dir/$self->{'name'}:2,$flags";

    unless ( rename( $self->{'file'}, $new_file ) ) {
        die("Unable to rename() $self->{'file'} to $new_file: $!");
    }

    $self->{'dir'}   = $dir;
    $self->{'file'}  = $new_file;
    $self->{'flags'} = $flags;

    return $self;
}

=head1 CHECKING MESSAGE STATE

The following methods can be used to quickly check for specific message state
flags.

=over

=item C<$message-E<gt>flags()>

Returns a string containing all the flags set for the current message.

=cut

sub flags {
    shift->{'flags'};
}

=item C<$message-E<gt>passed()>

Returns 1 if the message currently has the "Passed" flag set.

=cut

sub passed {
    shift->{'flags'} =~ /P/;
}

=item C<$message-E<gt>replied()>

Returns 1 if the message has been replied to.

=cut

sub replied {
    shift->{'flags'} =~ /R/;
}

=item C<$message-E<gt>seen()>

Returns 1 if a client has read the current message.

=cut

sub seen {
    shift->{'flags'} =~ /S/;
}

=item C<$message-E<gt>trashed()>

Returns 1 if the message is currently trashed after one helluva wild night with
its best buds.

=cut

sub trashed {
    shift->{'flags'} =~ /T/;
}

=item C<$message-E<gt>draft()>

Returns 1 if the message is a draft.

=cut

sub draft {
    shift->{'flags'} =~ /D/;
}

=item C<$message-E<gt>flagged()>

Returns 1 if the message is flagged as important.

=cut

sub flagged {
    shift->{'flags'} =~ /F/;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Alexandra Hrefna Hilmisdóttir <xan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2016, cPanel, Inc.  Distributed under the terms of the MIT
license.  See the LICENSE file for further details.
