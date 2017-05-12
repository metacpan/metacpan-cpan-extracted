package Git::PurePerl::Protocol::SSH;
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use IPC::Open2;
use namespace::autoclean;

extends 'Git::PurePerl::Protocol';

has 'hostname' => ( is => 'ro', isa => 'Str', required => 1 );
has 'username' => ( is => 'ro', isa => 'Str', required => 0 );
has 'path' => ( is => 'ro', isa => 'Str', required => 1 );

sub connect_socket {
    my $self = shift;

    my ($read, $write);
    my $connect = join('@', grep {defined} $self->username, $self->hostname);
    my $pid = open2(
        $read, $write,
        "ssh", $connect,
        "-o", "BatchMode yes",
        "git-upload-pack", $self->path,
    );

    $read->autoflush(1);
    $write->autoflush(1);
    $self->read_socket($read);
    $self->write_socket($write);
}

1;
