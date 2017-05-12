package Message::Passing::Filter::All;
use Moo;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Filter';

sub filter {
    return;
}


1;

=head1 NAME

Message::Passing::Filter::All - Filter all messages out.

=head1 DESCRIPTION

This filter just removes all messages, not passing any through.

You would normally never want to use this, but it can be useful for
testing occasionally.

=head1 METHODS

=head2 filter

Universally returns undef

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut