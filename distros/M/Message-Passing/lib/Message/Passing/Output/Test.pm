package Message::Passing::Output::Test;
use Moo;
use MooX::Types::MooseLike::Base qw/ ArrayRef /;
use namespace::clean -except => 'meta';

extends 'Message::Passing::Output::Callback';

has '+cb' => (
    default => sub { sub {} },
);

has _messages => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
    clearer => 'clear_messages',
    lazy => 1,
);

sub messages { @{ $_[0]->_messages } }
sub consume_test { push(@{$_[0]->_messages }, $_[1]) }
sub message_count { scalar @{ $_[0]->_messages } }


after consume => sub {
    shift()->consume_test(@_);
};


1;

=head1 NAME

Message::Passing::Output::Test - Output for use in unit tests

=head1 SYNOPSIS

    You only want this if you're writing tests...
    See the current tests for examples..

=head1 METHODS

=head2 messages

=head2 clear_messages

Clears all stores messages. Useful to speed up tests by resetting the
instance instead of re-instantiating it.

=head2 consume_test

=head2 message_count

=head1 SEE ALSO

L<Message::Passing>

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API -
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut
