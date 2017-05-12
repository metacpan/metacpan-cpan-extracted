package Message::Passing::Filter::Decoder::JSON;
use Moo;
use JSON::MaybeXS qw( decode_json );
use Try::Tiny;
use Message::Passing::Exception::Decoding;
use namespace::clean -except => 'meta';

with qw/
    Message::Passing::Role::Filter
    Message::Passing::Role::HasErrorChain
/;

sub filter {
    my ($self, $message) = @_;
    try {
        ref($message) ? $message : decode_json( $message )
    }
    catch {
        $self->error->consume(Message::Passing::Exception::Decoding->new(
            exception => $_,
            packed_data => $message,
        ));
        return; # Explicit return undef
    };
}

1;

=head1 NAME

Message::Passing::Role::Filter::Decoder::JSON

=head1 DESCRIPTION

Decodes string messages from JSON into data structures.

=head1 ATTRIBUTES

=head1 METHODS

=head2 filter

JSON decodes a message supplied as a parameter.

=head1 SEE ALSO

=over

=item L<Message::Passing>

=item L<Message::Passing::Manual::Concepts>

=back

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API -
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut

