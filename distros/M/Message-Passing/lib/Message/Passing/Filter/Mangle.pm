package Message::Passing::Filter::Mangle;
use Moo;
use MooX::Types::MooseLike::Base qw/ CodeRef /;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Filter';

has filter_function => (
    isa      => CodeRef,
    is       => 'ro',
    required => 1,
);

sub filter {
    my $self = shift;

    return $self->filter_function->(@_);
}

1;

=head1 NAME

Message::Passing::Filter::Mangle - Filter and/or mangle messages the way you
want.

=head1 DESCRIPTION

This filter takes a sub which is called with the same arguments as
L<Message::Passing::Role::Filter/filter> minus $self.

It's intended for use with L<Message::Passing::DSL> when you don't want to write
a named filter.

=head1 ATTRIBUTES

=head2 filter_function

=head1 METHODS

=head2 filter

Calls filter_function passing on all received arguments but $self.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut
