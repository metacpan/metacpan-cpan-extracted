use Modern::Perl;
use Test::More;

BEGIN {
    use_ok 'HTTP::Balancer::Role::Command';
}

ok (
    HTTP::Balancer::Role::Command->meta->does_role("Namespace::Dispatch")
);

done_testing;
