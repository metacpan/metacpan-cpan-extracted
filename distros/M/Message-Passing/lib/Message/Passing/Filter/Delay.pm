package Message::Passing::Filter::Delay;
use Moo;
use MooX::Types::MooseLike::Base qw( :all );
use AnyEvent;
use Scalar::Util qw/ weaken /;
use namespace::clean -except => 'meta';

with qw/
    Message::Passing::Role::Input
    Message::Passing::Role::Output
/;

has delay_for => (
    isa => Num,
    is => 'ro',
    required => 1,
);

sub consume {
    my ($self, $message) = @_;
    weaken($self);
    my $t; $t = AnyEvent->timer(
        after => $self->delay_for,
        cb => sub {
            undef $t;
            $self->output_to->consume($message);
        },
    );
}


1;

=head1 NAME

Message::Passing::Filter::Delay - Delay messages for some time.

=head1 DESCRIPTION

This filter passes all incoming messages through with no changes, however
not immediately - they are delayed .

You would normally never want to use this, but it can be useful for
testing occasionally, or avoiding race conditions.

=head1 ATTRIBUTES

=head2 delay_for

Floating point number, indicating how many seconds to delay messages for.

=head1 METHODS

=head2 consume ($msg)

Sets up a timed callback in the event loop, which passes the message
to the output (and deletes itself) once the timeout has expired

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut