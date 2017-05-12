package Hg::Lib::Server;

use 5.10.1;

use Carp;

use Moo;
use MooX::Types::MooseLike::Base qw[ :all ];

use Hg::Lib::Server::Pipe;

Hg::Lib::Server::Pipe->shadow_attrs;

has server => (
    is => 'ro',
    lazy     => 1,
    init_arg => undef,
    handles  => [qw[ get_chunk write ]],
    default  => sub {
        Hg::Lib::Server::Pipe->new( Hg::Lib::Server::Pipe->xtract_attrs($_[0]) );
    },
);

has capabilities => (
    is        => 'rwp',
    predicate => 1,
    init_arg  => undef,
);

has encoding => (
    is        => 'rwp',
    predicate => 1,
    init_arg  => undef,
);


sub BUILD {

    $_[0]->_get_hello;
}

sub _get_hello {

    my $self = shift;

    my $buf;
    my $ch = $self->get_chunk($buf);

    croak("corrupt or incomplete hello message from server\n")
      unless $ch eq 'o' && length $buf;

    for my $item ( split( "\n", $buf ) ) {

        my ( $field, $value ) = $item =~ /([a-z0-9]+):\s*(.*)/;

        if ( $field eq 'capabilities' ) {

            $self->_set_capabilities(
                { map { $_ => 1 } split( ' ', $value ) } );
        }

        elsif ( $field eq 'encoding' ) {

            $self->_set_encoding($value);

        }

        # ignore anything else 'cause we don't know what it means

    }

    # make sure hello message meets minimum standards
    croak("server did not provide capabilities?\n")
      unless $self->has_capabilities;

    croak("server is missing runcommand capability\n")
      unless exists $self->capabilities->{runcommand};

    croak("server did not provide encoding?\n")
      unless $self->has_encoding;

    return;
}

1;
