package Message::Passing::Role::Filter;
use Moo::Role;
use namespace::clean -except => 'meta';

requires 'filter';

with qw/
    Message::Passing::Role::Input
    Message::Passing::Role::Output
/;

sub consume {
    my ($self, $message) = @_;
    my $new = $self->filter($message);
    return unless $new;
    $self->output_to->consume($new);
}

1;

=head1 NAME

Message::Passing::Role::Filter - Simple abstraction for filtering messages

=head1 SYNOPSIS

    package My::Filter;
    use Moo;
    use namespace::clean -except => 'meta';

    with 'Message::Passing::Role::Filter';

    sub filter {
        my ($self, $message) = @_;
        # Do something with $message
        return $message; # Or return undef to halt message!
    }

    1;

=head1 DESCRIPTION

Both a producer and a consumer of messages, able to filter out messages based upon their contents,
or permute the structure of messages.

=head1 REQUIRED METHODS

=head2 filter

Called to filter the message. Returns the mangled message.

Note if you return undef then the message is not propagated further up the chain, which may be used
for filtering out unwanted messages.

=head1 REQUIRED ATTRIBUTES

=head2 output_to

From L<Message::Passing::Role::Input>.

=head1 METHODS

=head2 consume

Consumers a message, calling the filter method provided by the user with the message.

In the case where the filter returns a message, outputs the message to the next step in the chain.

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