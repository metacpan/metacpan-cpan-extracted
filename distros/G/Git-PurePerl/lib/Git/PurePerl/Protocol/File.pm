package Git::PurePerl::Protocol::File;
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use IPC::Open2;
use namespace::autoclean;

extends 'Git::PurePerl::Protocol';

has 'path' => ( is => 'ro', isa => 'Str', required => 1 );

sub connect_socket {
    my $self = shift;

    my ($read, $write);
    my $pid = open2(
        $read, $write,
        "git-upload-pack",
        $self->path,
    );

    $read->autoflush(1);
    $write->autoflush(1);
    $self->read_socket($read);
    $self->write_socket($write);
}

1;
