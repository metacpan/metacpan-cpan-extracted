package Message::Passing::Filter::Decoder::Bzip2;
use Moo;
use Compress::Bzip2;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Filter';

sub filter {
    my ($self, $message) = @_;
    Compress::Bzip2::memBunzip($message);
}


1;

=head1 NAME

Message::Passing::Decoder::Bzip2 - Use Compress:Bzip2 to encrypt messages


=head1 SYNOPSIS

    message-pass --input STDIN --decoder Bzip2 \
        --output ZeroMQ --output_options '...'

=head1 DESCRIPTION

Uncompresses messages with Compress::Bzip2.

=head1 METHODS

=head2 filter

Uncompresses the message

=head1 SEE ALSO

=over

=item L<Message::Passing::Role::Filter>

=back

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Message::Passing>.

=cut