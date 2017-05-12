use Modern::Perl;
use Test::More;
use Test::Exception;
use local::lib 'local';
use lib qw(t/lib);

use Proc::ProcessTable;
use Path::Tiny;

BEGIN {
    use_ok 'HTTP::Balancer::Actor';
}

{
    package HTTP::Balancer::Actor::Foo;
    use Modern::Perl;
    use Moose;
    extends qw(HTTP::Balancer::Actor);
}

throws_ok (
    sub { HTTP::Balancer::Actor::Foo->start },
    qr{you do not implement the start\(\) for HTTP::Balancer::Actor::Foo},
    "die if not implement start()",
);

throws_ok (
    sub { HTTP::Balancer::Actor::Foo->stop },
    qr{you do not implement the stop\(\) for HTTP::Balancer::Actor::Foo},
    "die if not implement stop()",
);

throws_ok (
    sub { HTTP::Balancer::Actor::Foo->executable },
    qr{HTTP::Balancer::Actor::Foo::NAME not defined yet},
    "die if not provided \$NAME",
);

{
    my $test_pidfile = "/tmp/http-balancer-test.pid";

    path($test_pidfile)->remove;

    my $script = qq[
        use Path::Tiny;
        path("$test_pidfile")->spew(\$\$);
        while (1) {
        }
    ];

    system("perl -E '$script' &");

    while (1) {
        last if path($test_pidfile)->exists;
    }

    my $test_pid = path($test_pidfile)->slurp;

    is (
        scalar(grep { $_->pid == $test_pid } @{Proc::ProcessTable->new->table}),
        1,
        "process exists before kill",
    );

    HTTP::Balancer::Actor::Foo->new->kill($test_pid);

    is (
        scalar(grep { $_->pid == $test_pid } @{Proc::ProcessTable->new->table}),
        0,
        "process do not exist after kill",
    );

    path($test_pidfile)->remove;

}

use HTTP::Balancer::Actor::Buzz;

my $actor_buzz = HTTP::Balancer::Actor::Buzz->new;

like (
    $actor_buzz->template,
    qr{^Buzz Config\n: for \$backends -> \$backend \{\nbackend \<: \$backend \:\>;\n: \}},
    "can read the DATA handle as the template",
);

like (
    $actor_buzz->render(backends => ["localhost:3000", "localhost:3001"]),
    qr{^Buzz Config\nbackend localhost:3000;\nbackend localhost:3001;},
    "can render xslate template",
);

done_testing;
