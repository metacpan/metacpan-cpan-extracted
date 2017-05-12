package Message::Passing::Role::HasErrorChain;
use Moo::Role;
use Module::Runtime qw/ require_module /;
use namespace::clean -except => 'meta';

has error => (
    is => 'ro',
    lazy => 1,
    builder => '_build_default_error_chain',
);

sub _build_default_error_chain {
    require_module 'Message::Passing::Output::STDERR';
    require_module 'Message::Passing::Filter::Encoder::JSON';
    Message::Passing::Filter::Encoder::JSON->new(
        output_to => Message::Passing::Output::STDERR->new,
    );
}

1;

=head1 NAME

Message::Passing::Role::HasErrorChain - A role for components which can report errors

=head1 SYNOPSIS

    # Note this is an example package, and does not really exist!
    package Message::Passing::Output::ErrorAllMessages;
    use Moo;
    use namespace::clean -except => 'meta';

    with qw/
        Message::Passing::Role::Output
        Message::Passing::Role::HasErrorChain
    /;

    sub consume {
        my ($self, $message) = @_;
        $self->error->consume($message);
    }

=head1 DESCRIPTION

Some components can create an error stream in addition to a message stream.

=head1 METHODS

=head2 error

An attribute containing the error chain.

By default, this is a chain of:

=over

=item Message::Passing::Filter::Encoder::JSON

=item Message::Passing::Output::STDOUT

=back

=head1 WARNINGS

=head2 ERROR CHAINS CAN LOOP

If you override the error chain output, be sure that the error chain does not go into your
normal log path! This is because if you suddenly have errors in your normal log path, and you
then start logging these errors, this causes more errors - causing you to generate a message loop.

=head2 ENCODING IN ERROR CHAINS

If you emit something which cannot be encoded to an error chain then the encoding
error will likely be emitted by the error chain - this can again cause loops and other
issues.

All components which use error chains should be very careful to output data which
they are entirely certain will be able to be encoded.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API -
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut

