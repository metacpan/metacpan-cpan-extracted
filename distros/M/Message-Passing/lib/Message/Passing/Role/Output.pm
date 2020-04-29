package Message::Passing::Role::Output;
use Moo::Role;
use Scalar::Util qw/ blessed /;
#use namespace::clean -except => 'meta';

requires 'consume';

no Moo::Role;

1;

=head1 NAME

Message::Passing::Role::Output - Consumes messages

=head1 DESCRIPTION

This is a role for classes which consumer messages (e.g. a Message::Passing output)

=head1 REQUIRED METHODS

=head2 consume

Consume a message

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