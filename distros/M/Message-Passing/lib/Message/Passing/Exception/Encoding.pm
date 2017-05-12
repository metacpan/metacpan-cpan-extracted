package Message::Passing::Exception::Encoding;
use Moo;
use Data::Dumper ();
use MooX::Types::MooseLike::Base qw/ Str /;
use namespace::clean -except => 'meta';

with 'Message::Passing::Exception';

has exception => (
    is => 'ro',
    required => 1,
);

has stringified_data => (
    is => 'ro',
    isa => Str,
    coerce => sub {
        Data::Dumper::Dumper($_[0]);
    },
);

1;

=head1 NAME

Message::Passing::Exception::Encoding - An issue when encoding data

=head1 ATTRIBUTES

=head2 exception

The exception encountered when trying to encode the message

=head2 stringified_data

The original message, dumped using L<Data::Dumper>.

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut

