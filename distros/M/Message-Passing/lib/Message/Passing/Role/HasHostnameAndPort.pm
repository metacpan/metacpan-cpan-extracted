package Message::Passing::Role::HasHostnameAndPort;
use Moo::Role;
use MooX::Types::MooseLike::Base qw/ Str Int /;
use namespace::clean -except => 'meta';

requires '_default_port';

has hostname => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has port => (
    is => 'ro',
    isa => Int,
    builder => '_default_port',
);

1;

=head1 NAME

Message::Passing::Role::HasHostnameAndPort

=head1 DESCRIPTION

Adds a C<hostname> and a C<port> attributes to your class.

=head1 METHODS

=head2 hostname

=head2 port

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut