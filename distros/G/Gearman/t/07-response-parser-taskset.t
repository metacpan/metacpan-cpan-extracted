use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($mn, $tsn, $cn, $s) = qw/
    Gearman::ResponseParser::Taskset
    Gearman::Taskset
    Gearman::Client
    foo
    /;

use_ok($tsn);
use_ok($cn);
use_ok($mn);
isa_ok($mn, "Gearman::ResponseParser");

can_ok(
    $mn, qw/
        on_packet
        on_error
        /
);

my $ts = new_ok($tsn, [new_ok($cn)]);
my $m = new_ok($mn, [source => $s, taskset => $ts]);
throws_ok { $m->on_error($s) } qr/^ERROR: $s/, "caught die off in on_error";

throws_ok { $mn->new(source => $s, taskset => $s) }
qr/is not a Gearman::Taskset reference/, "caught die of on taskset check";

done_testing();

