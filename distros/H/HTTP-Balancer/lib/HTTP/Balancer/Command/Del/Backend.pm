package HTTP::Balancer::Command::Del::Backend;
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

    my $backend = $self->model("Backend")->find(name => $self->name);
    $backend ? $backend->remove : say "not found";
}


1;
