use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($mn, $s) = qw/
    Gearman::ResponseParser
    foo
    /;

use_ok($mn);
my $m = new_ok($mn, [source => $s]);

throws_ok { $mn->new(source => $s, $s => 1, bla => 1) }
qr/^unsupported arguments/, "caught die of on arguments check";

can_ok(
    $m, qw/
        eof
        on_error
        on_packet
        parse_data
        parse_sock
        reset
        source
        /
);

foreach (qw/eof on_packet on_error/) {
    throws_ok { $m->$_ } qr/^SUBCLASSES SHOULD OVERRIDE THIS/,
        "caught die off in $_";
}

is($m->source, $s, "source");

subtest "reset", sub {
    $m->{$_} = $s for qw/
        header
        pkt
        /;

    $m->reset;

    is($m->{header}, '',    "header");
    is($m->{pkt},    undef, "pkt");
};

done_testing();
