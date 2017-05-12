package Message::Passing::Exception::ConnectionTimeout;
use Moo;
use Data::Dumper ();
use MooX::Types::MooseLike::Base qw/ Str Num /;
use namespace::clean -except => 'meta';

with 'Message::Passing::Exception';

has after => (
    isa => Num,
    is => 'ro',
    required => 1,
);

1;

=head1 NAME

Message::Passing::Exception::ConnectionTimeout - A connection timed out

=head1 ATTRIBUTES

=head2 after

How long we waited before the connection was timed out.

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut

