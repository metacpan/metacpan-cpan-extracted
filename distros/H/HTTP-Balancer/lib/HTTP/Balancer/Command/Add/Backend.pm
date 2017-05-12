package HTTP::Balancer::Command::Add::Backend;
use Modern::Perl;
use Moose;
with qw(HTTP::Balancer::Role::Command);

has name => (
    is      => "rw",
    traits  => [ 'NoGetopt' ],
    default => sub { shift->argv(2) },
);

has host => (
    is            => "rw",
    isa           => "Str",
    required      => 1,
    traits        => ['Getopt'],
    cmd_aliases   => 'h',
    documentation => "the virtual host this backend belongs to",
);

has address => (
    is            => "rw",
    isa           => "Str",
    required      => 1,
    traits        => ['Getopt'],
    cmd_aliases   => 'a',
    documentation => "the address of this backend",
);

has port => (
    is            => "rw",
    isa           => "Num",
    traits        => ['Getopt'],
    cmd_aliases   => 'p',
    default       => "80",
    documentation => "the port of this backend listens to. default: 80",
);

sub ordinary_args {
    qw(name)
};

sub run {
    my ($self, ) = @_;

    my $host = $self->model("Host")->find(name => $self->host);

    $self->model("Backend")
         ->new(
             name    => $self->name,
             address => $self->address,
             port    => $self->port,
             host_id => $host->id,
         )
         ->save;
}

1;
