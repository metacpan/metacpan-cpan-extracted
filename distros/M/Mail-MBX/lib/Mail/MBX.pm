package Mail::MBX;

=head1 NAME

Mail::MBX - Read MBX mailbox files

=head1 SYNOPSIS

    use Mail::MBX ();

    my $mbx = Mail::MBX->open('mailbox.mbx');

    while (my $message = $mbx->message) {
        while ($message->read(my $buf, 4096)) {
            # Do something with the message body
        }
    }

    $mbx->close;

=head1 DESCRIPTION

C<Mail::MBX> provides a reasonable way to read mailboxes in the MBX format, as
used by the University of Washington's UW-IMAP reference implementation.  At
present, only sequential reading is supported, though this is ideal for mailbox
format conversion tasks.

=head1 OPENING MAILBOXES

=over

=cut

use strict;
use warnings;

use Mail::MBX::Message ();

our $VERSION = '0.01';

=item C<Mail::MBX-E<gt>open(I<$file>)>

Open an MBX mailbox file, returning a new C<Mail::MBX> object.

=cut

sub open {
    my ( $class, $file ) = @_;

    my $uidvalidity;
    my @keywords;

    open( my $fh, '<', $file ) or die("Unable to open mailbox file $file: $!");

    my $line = readline($fh);

    #
    # If the first line of the file is empty, then
    #
    if ( !defined $line ) {
        return;
    }

    elsif ( $line ne "*mbx*\r\n" ) {
        die("File $file is not an MBX file");
    }

    $line = readline($fh);

    if ( $line =~ /^([[:xdigit:]]{8})([[:xdigit:]]{8})\r\n$/ ) {
        $uidvalidity = hex($1);
    }
    else {
        die("File $file has invalid UID line");
    }

    foreach ( 0 .. 29 ) {
        chomp( $line = readline($fh) );

        if ( $line ne '' ) {
            push( @keywords, $line );
        }
    }

    seek( $fh, 2048, 0 );

    return bless {
        'file'        => $file,
        'fh'          => $fh,
        'uidvalidity' => $uidvalidity,
        'keyword'     => \@keywords,
        'uid'         => 0
    }, $class;
}

=item C<$mbx-E<gt>close()>

Close the current mailbox object.

=cut

sub close {
    my ($self) = @_;

    if ( defined $self->{'fh'} ) {
        close $self->{'fh'};
        undef $self->{'fh'};
    }

    return;
}

sub DESTROY {
    my ($self) = @_;

    $self->close;

    return;
}

=item C<$mbx-E<gt>message()>

Return the current MBX message, in the form of a C<L<Mail::MBX::Message>>
object, and move the internal file handle to the next message.

See C<L<Mail::MBX::Message>> for further details on accessing message contents.

=cut

sub message {
    my ($self) = @_;

    if ( eof $self->{'fh'} ) {
        return;
    }

    my $message = Mail::MBX::Message->parse( $self->{'fh'} );

    if ( $message->{'uid'} == 0 ) {
        $message->{'uid'} = ++$self->{'uid'};
    }

    return $message;
}

=back

=cut

1;

__END__

=head1 AUTHOR

Written by Xan Tronix <xan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014 cPanel, Inc.  Distributed under the terms of the MIT license.
