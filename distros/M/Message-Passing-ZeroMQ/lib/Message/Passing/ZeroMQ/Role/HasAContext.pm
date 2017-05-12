package Message::Passing::ZeroMQ::Role::HasAContext;
use Moo::Role;
use Message::Passing::ZeroMQ ();
use MooX::Types::MooseLike::Base qw/ :all /;
use ZMQ::FFI;
use Scalar::Util qw/ weaken /;
use namespace::clean -except => 'meta';

## TODO - Support (default to?) shared contexts

has zmq_major_version => (
    is          => 'lazy',
    isa         => Num,
);

has _ctx => (
    is => 'ro',
#    isa => 'ZMQ::FFI',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $ctx = ZMQ::FFI->new();
        push(@Message::Passing::ZeroMQ::_WITH_CONTEXTS, $self);
        weaken($Message::Passing::ZeroMQ::_WITH_CONTEXTS[-1]);
        $ctx;
    },
    clearer => '_clear_ctx',
);

sub _build_zmq_major_version {
    my ($self) = @_;
    my ($major, $minor, $patch) = $self->_ctx->version;
    return $major;
}

1;

=head1 NAME

Message::Passing::ZeroMQ::Role::HasAContext - Components with a ZeroMQ context consume this role.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::ZeroMQ>.

=cut

