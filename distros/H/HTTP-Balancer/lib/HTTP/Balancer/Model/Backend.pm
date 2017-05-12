package HTTP::Balancer::Model::Backend;
use Modern::Perl;
use Moose;
use MooseX::Storage;
extends qw( HTTP::Balancer::Model );

with Storage(
    format  => 'YAML',
    io      => 'File',
);

has id => (
    is  => "rw",
    isa => "Num",
);

has name => (
    is  => "rw",
    isa => "Str",
);

has address => (
    is  => "rw",
    isa => "Str",
);

has port => (
    is  => "rw",
    isa => "Str"
);

has host_id => (
    is  => "rw",
    isa => "Str",
);

1;
__END__

=head1 NAME

HTTP::Balancer::Model::Backend

=head1 SYNOPSIS

    use Moose;
    with qw(HTTP::Balancer::Role);
    $self->model("Backend");

=cut
