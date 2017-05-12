package Message::Passing::Filter::T;
use Moo;
use MooX::Types::MooseLike::Base qw/ ArrayRef /;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Input';
with 'Message::Passing::Role::Output';

has '+output_to' => (
#    isa => ArrayRef[role_type('Message::Passing::Role::Output')],
    is => 'ro',
    required => 1,
);

sub consume {
    my ($self, $message) = @_;
    foreach my $output_to (@{ $self->output_to }) {
        $output_to->consume($message);
    }
}


1;

=head1 NAME

Message::Passing::Filter::T - Send a message stream to multiple outputs.

=head1 DESCRIPTION

This filter is used to duplicate a message stream to two or more outputs.

All messages are duplicated to all output streams, so you may want to follow
this with L<Message::Passing::Filter::Key> to one or more of those streams.

=head1 ATTRIBUTES

=head2 output_to

Just like a normal L<Message::Passing::Role::Input> class, except takes an array of outputs.

=head1 METHODS

=head2 consume

Sends the consumed message to all output_to instances.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut