package HTTP::Balancer::Command::Add::Host;
use Modern::Perl;
use Moose;
with qw(HTTP::Balancer::Role::Command);

has name => (
    is      => "rw",
    traits  => [ 'NoGetopt' ],
    default => sub { shift->argv(2) },
);

has fullname => (
    is              => "rw",
    isa             => "Str",
    metaclass       => "Getopt",
    cmd_aliases     => "f",
    default         => "",
    documentation   => "full virtual host name used to filter requests. default: empty string. make sure only one host has empty fullname.",
);

has address => (
    is              => "rw",
    isa             => "Str",
    metaclass       => "Getopt",
    cmd_aliases     => "a",
    default         => "0.0.0.0",
    documentation   => "the address this virtual host listens to. default: 0.0.0.0",
);

has port => (
    is              => "rw",
    isa             => "Str",
    metaclass       => "Getopt",
    cmd_aliases     => "p",
    default         => "80",
    documentation   => "the TCP port this host listens to. default: 80",
);

sub ordinary_args {
    qw(name);
}

sub run {
    my ($self, ) = @_;

    my @columns = grep {!/^id$/} $self->model("Host")->columns;

    my %params; @params{@columns} = @$self{@columns};

    $self
    ->model("Host")
    ->new(%params)
    ->save;
}

1;
