package Message::Passing::Exception::Decoding;
use Moo;
use Data::Dumper ();
use MooX::Types::MooseLike::Base qw/ Str /;
use namespace::clean -except => 'meta';

with 'Message::Passing::Exception';

has exception => (
    is => 'ro',
    required => 1,
    isa => Str,
);

has packed_data => (
    is => 'ro',
    isa => Str,
    required => 1,
);

1;

=head1 NAME

Message::Passing::Exception::Decoding - An issue when decoding data

=head1 ATTRIBUTES

=head2 exception

The exception encountered when trying to encode the message

=head2 packed_data

The original message.

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut

