use Modern::Perl;
use Test::More;
use Test::Exception;
use local::lib qw(local);

BEGIN {
    use_ok 'HTTP::Balancer::Role';
}

{
    package HTTP::Balancer::Any;
    use Modern::Perl;
    use Moose;
    with qw(HTTP::Balancer::Role);
}

my $any = HTTP::Balancer::Any->new;

is (
    $any->model("Host"),
    "HTTP::Balancer::Model::Host",
    "modules have model(\$name) shortcut",
);

throws_ok (
    sub { $any->model("None") },
    qr{Can't locate HTTP\/Balancer\/Model\/None.pm in \@INC},
    "must die if model not exists",
);

is (
    ref($any->config),
    'HTTP::Balancer::Config',
    'modules have config() shortcut to get the configuration',
);

is (
    $any->config->pidfile,
    "/var/run/http-balancer.pid",
    "has default pidfile",
);

done_testing;
