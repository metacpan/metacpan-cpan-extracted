package HTTP::Balancer::Model::Host;
use Modern::Perl;
use Moose;
use MooseX::Storage;
extends qw( HTTP::Balancer::Model );

with Storage(
    format  => 'YAML',
    io      => 'File',
);

has [qw(id port)] => (
    is  => "rw",
    isa => "Num",
);

has [qw(name fullname address)] => (
    is  => "rw",
    isa => "Str",
);

before remove => sub {
    my $self = shift;
    map { say $_->remove } $self->backends;
};

sub backends {
    my ($self, ) = @_;
    $self->model("Backend")
         ->where(host_id => $self->id);
}

sub hash {
    my ($self, ) = @_;
    return {
        name        => $self->name,
        fullname    => $self->fullname,
        address     => $self->address,
        port        => $self->port,
        backends    => [map {$_->address . ":" . $_->port} $self->backends],
    };
}

1;
__END__

=head1 NAME

HTTP::Balancer::Model::Host

=head1 SYNOPSIS

    use Moose;
    with qw(HTTP::Balancer::Role);
    $self->model("Host")

=cut
