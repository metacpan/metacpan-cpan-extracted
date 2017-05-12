package Message::Passing::Filter::Decoder::Null;
use Moo;
use namespace::clean -except => 'meta';

extends 'Message::Passing::Filter::Null';


1;

=head1 NAME

Message::Passing::Filter::Deccoder::Null

=head1 DESCRIPTION

Does no Decoding

=head1 ATTRIBUTES

=head1 METHODS

=head2 filter

Returns message it's passed, verbatim

=head1 SEE ALSO

=over

=item L<Message::Passing::Filter::Null>

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