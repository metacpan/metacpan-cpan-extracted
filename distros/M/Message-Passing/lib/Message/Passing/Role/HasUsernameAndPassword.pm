package Message::Passing::Role::HasUsernameAndPassword;
use Moo::Role;
use MooX::Types::MooseLike::Base qw/ Str /;
use namespace::clean -except => 'meta';

foreach my $name (qw/ username password /) {
    has $name  => (
        is => 'ro',
        isa => Str,
        required => 1,
    );
}

1;

=head1 NAME

Message::Passing::Role::HasUsernameAndPassword - common username and password attributes

=head1 SYNOPSIS

    package Message::Passing::Output::MyOutput;
    use Moo;
    use namespace::clean -except => 'meta';

    with 'Message::Passing::Role::HasUsernameAndPassword';

=head1 METHODS

=head2 username

The username for a connection. Required, Str.

=head2 password

The password for a connection. Required, Str.

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut