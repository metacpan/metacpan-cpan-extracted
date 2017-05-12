package Message::Passing::Output::Null;
use Moo;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Output';

sub consume {}


1;

=head1 NAME

Message::Passing::Output::Null - /dev/null for messages

=head1 SYNOPSIS

    message-pass --input STDIN --output Null
    {"foo": "bar"}

    # Note noting is printed...

=head1 DESCRIPTION

Throws away all messages passed to it.

=head1 METHODS

=head2 consume

Takes a message and discards it silently.

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