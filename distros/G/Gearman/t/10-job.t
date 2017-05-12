use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($mn) = qw/
    Gearman::Job
    /;

use_ok($mn);

can_ok(
    $mn, qw/
        set_status
        argref
        arg
        handle
        /
);

my %arg = (
    func   => "foo",
    argref => \rand(10),
    handle => "H:127.0.0.1:123",
    js     => "127.0.0.1:4730",
    jss    => "sock"
);

my $j = new_ok($mn, [%arg]);
is($j->handle(), $arg{handle});
is($j->argref(), $arg{argref});
is($j->arg(),    ${ $arg{argref} });
is($j->{jss},    $arg{jss});
is($j->{js},     $arg{js});

dies_ok { $j->set_status(qw/a b/) };

done_testing();

