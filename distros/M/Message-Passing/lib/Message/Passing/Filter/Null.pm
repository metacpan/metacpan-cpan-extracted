package Message::Passing::Filter::Null;
use Moo;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Filter';

sub filter { $_[1] }


1;

=head1 NAME

Message::Passing::Filter::Null - Filter no messages out.

=head1 DESCRIPTION

This filter does nothing, passing all incoming messages through with no changes.

You would normally never want to use this, but it can be useful for
testing occasionally.

=head1 METHODS

=head2 filter

Returns the message passed to it.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut