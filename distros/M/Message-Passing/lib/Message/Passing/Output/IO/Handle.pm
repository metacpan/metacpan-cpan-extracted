package Message::Passing::Output::IO::Handle;
use Moo;
#use Moose::Util::TypeConstraints;
use namespace::clean -except => 'meta';

with 'Message::Passing::Role::Output';

has fh => (
#    isa => duck_type([qw/ print /]),
    is => 'ro',
    required => 1,
);

has append => (
    is => 'ro',
    default => sub { "\n" },
);

sub consume {
    my $self = shift;
    $self->fh->print(shift() . $self->append);
}


1;

=head1 NAME

Message::Passing::Output::IO::Handle - output to an IO handle

=head1 SYNOPSIS

    my $out = Message::Passing::Output::IO::Handle->new(
        fh => \*STDOUT,
        append => "\n",
    );
    # $out will now act like Message::Passing::Output::STDOUT

=head1 DESCRIPTION

Output messages to an L<IO::Handle> like handle, i.e. any class
which implements a C<< ->print($stuff) >> method.

=head1 ATTRIBUTES

=head2 fh

The file handle object. Required.

=head2 append

String to append to each message. Defaults to "\n"

=head1 METHODS

=head2 consume

Consumes a message by printing it, followed by \n

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