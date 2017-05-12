package Message::Passing::Filter::Encoder::Crypt::CBC;
use Moo;
use Compress::Zlib;
use namespace::clean -except => 'meta';

with qw/
    Message::Passing::Role::Filter
    Message::Passing::Role::Crypt::CBC
/;

sub filter {
    my ($self, $message) = @_;
    $self->cbc->encrypt($message);
}


1;

=head1 NAME

Message::Passing::Encoder::Crypt::CBC - Use Crypt::CBC to encrypt messages

=head1 SYNOPSIS

    message-pass --input STDIN --encoder Crypt::CBC \
        --encoder_options '{}' \
        --output ZeroMQ --output_options '...'

=head1 DESCRIPTION

Encrypts messages with Crypt::CBC.

=head1 SEE ALSO

=over

=item L<Message::Passing::Role::Filter>

=item L<Message::Passing::Role::Crypt::CBC>

=back

=head1 METHODS

=head2 filter

Encrypts the message

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Message::Passing>.

=cut