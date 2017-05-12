package Message::Passing::Role::HasTimeoutAndReconnectAfter;
use Moo::Role;
use MooX::Types::MooseLike::Base qw/ Num /;
use namespace::clean -except => 'meta';

has timeout => (
    isa => Num,
    is => 'ro',
    default => sub { 30 },
);

has reconnect_after => (
    isa => Num,
    is => 'ro',
    default => sub { 2 },
);

1;

=head1 NAME

Message::Passing::Role::HasTimeoutAndReconnectAfter

=head1 DESCRIPTION

Adds a C<timeout> and a C<reconnect_after> attributes to your class.

=head1 METHODS

=head2 timeout

=head2 reconnect_after

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut