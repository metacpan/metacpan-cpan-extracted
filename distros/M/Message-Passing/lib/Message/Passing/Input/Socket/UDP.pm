package Message::Passing::Input::Socket::UDP;
use Moo;
use AnyEvent;
use AnyEvent::Handle::UDP;
use Scalar::Util qw/ weaken /;
use namespace::clean -except => 'meta';

with qw/
    Message::Passing::Role::Input
    Message::Passing::Role::HasHostnameAndPort
    Message::Passing::Role::HasErrorChain
/;

has '+hostname' => (
    default => sub { 'localhost' },
);

has '+port' => (
    required => 1,
);

sub _default_port { die "You must supply a port #" }

has handle => (
    is => 'ro',
    builder => '_build_handle',
    lazy => 1,
);

sub BUILD {
    my $self = shift;
    $self->handle;
}

sub _send_data {
    my ($self, $data, $from_addr) = @_;
    $self->output_to->consume($data);
}

sub _build_handle {
    my $self = shift;
    weaken($self);
    AnyEvent::Handle::UDP->new(
        bind => [ $self->hostname, $self->port ],
        on_recv => sub {
            my ($data, $h, $from_addr) = @_;
            # The output can optionally drop from addr.
            $self->_send_data($data, $from_addr);
        },
        on_error => sub {
            my ($h, $fatal, $msg) = @_;
            $self->error->consume($msg);
        },
    );
}

1;

=head1 NAME

Message::Passing::Input::Socket::UDP - UDP input

=head1 DESCRIPTION

An input which gets messages from a UDP network socket using
L<AnyEvent::Handle::UDP>.

=head1 ATTRIBUTES

=head2 hostname

The hostname L<AnyEvent::Handle::UDP/new> will bind to.

=head2 port

The port L<AnyEvent::Handle::UDP/new> will bind to.

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

