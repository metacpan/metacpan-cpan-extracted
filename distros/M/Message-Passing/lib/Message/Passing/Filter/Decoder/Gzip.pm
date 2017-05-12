package Message::Passing::Filter::Decoder::Gzip;
use Moo;
use Compress::Zlib;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Filter';

sub filter {
    my ($self, $message) = @_;
    Compress::Zlib::memGunzip($message);
}


1;

=head1 NAME

Message::Passing::Filter::Decoder::Gzip - Decompresses messages with Compress::Zlib

=head1 SYNOPSIS

    message-pass --input STDIN --decoder Gzip \
        --output ZeroMQ --output_options '...'

=head1 DESCRIPTION

Decompresses messages with Compress::Zlib.

=head1 METHODS

=head2 filter

Decompresses the message

=head1 SEE ALSO

=over

=item L<Message::Passing::Role::Filter>

=back

=cut