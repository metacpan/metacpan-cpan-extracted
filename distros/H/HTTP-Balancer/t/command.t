use Modern::Perl;
use Test::More;

BEGIN {
    use_ok 'HTTP::Balancer::Command';
}

is (
    HTTP::Balancer::Command->dispatch(qw(add)),
    "HTTP::Balancer::Command::Add",
    "can run add",
);

is (
    HTTP::Balancer::Command->dispatch(qw(add host)),
    "HTTP::Balancer::Command::Add::Host",
    "can run add host",
);

is (
    HTTP::Balancer::Command->dispatch(qw(add backend)),
    "HTTP::Balancer::Command::Add::Backend",
    "can run add backend",
);

is (
    HTTP::Balancer::Command->dispatch(qw(del)),
    "HTTP::Balancer::Command::Del",
    "can run del",
);

is (
    HTTP::Balancer::Command->dispatch(qw(del host)),
    "HTTP::Balancer::Command::Del::Host",
    "can run del host",
);

is (
    HTTP::Balancer::Command->dispatch(qw(del backend)),
    "HTTP::Balancer::Command::Del::Backend",
    "can run del backend",
);

done_testing;
