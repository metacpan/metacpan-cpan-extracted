package HTTP::Balancer::Command::Del::Host;
use Modern::Perl;
use Moose;
with qw(HTTP::Balancer::Role::Command);

has name => (
    is      => "rw",
    traits  => [ 'NoGetopt' ],
    default => sub { shift->argv(2) },
);

sub ordinary_args {
    qw(name);
}

sub run {
    my ($self, ) = @_;

    my $host = $self->model("Host")->find(name => $self->name);
    $host ? $host->remove : say "not found";
}

1;
