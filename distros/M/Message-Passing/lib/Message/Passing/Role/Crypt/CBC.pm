package Message::Passing::Role::Crypt::CBC;
use Moo::Role;
use MooX::Types::MooseLike::Base qw/ Str /;
use Crypt::CBC;
use namespace::clean -except => 'meta';

foreach my $name (qw/
    encryption_key
    encryption_cipher
/) {
    has $name => (
        isa => Str,
        is => 'ro',
        required => 1,
    );
}

# NOTE - We need a new CBC object per message, otherwise if we _EVER_ drop
#        messages then we totally screw ourselves!
sub cbc {
    my $self = shift;
    Crypt::CBC->new(
        -key    => $self->encryption_key,
        -cipher => $self->encryption_cipher,
    );
}

1;

=head1 NAME

Message::Passing::Role::Crypt::CBC - Common attributes for encoding or decoding encrypted messages

=head1 ATTRIBUTES

=head2 encryption_key

The key for encryption (this is a shared secret key between both sides)

=head2 encryption_cipher

Any cipher supported by L<Crypt::CBC>.

=head1 METHODS

=head2 cbc

Returns a new L<Crypt::CBC> object.

=head1 SEE ALSO

=over

=item L<Message::Passing::Filter::Encoder::Crypt::CBC>

=item L<Message::Passing::Filter::Decoder::Crypt::CBC>

=item L<Crypt::CBC>

=back

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Message::Passing>.

=cut

