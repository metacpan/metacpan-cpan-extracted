use strict;
use Test::More 0.98;
use Katsubushi::Converter;

my $ids_in_msec = 2 ** (10 + 12); # worker 10bit, seq 12bit
my $ids_in_sec  = $ids_in_msec * 1000;

my @case = (
    {
        id         => 189608755200000000,
        epoch      => 1465276650,
        epoch_msec => 1465276650_000,
    },
    {
        id         => 189611295782211584,
        epoch      => 1465277255,
        epoch_msec => 1465277255_722,
    }
);

sub between {
    my ($b, $v, $t) = @_;
    note "$b <= $v && $v < $t";

    $b <= $v && $v < $t;
}

for my $c (@case) {
    my $e = Katsubushi::Converter::id_to_epoch($c->{id});
    ok between($c->{epoch}, $e, $c->{epoch} + 1);

    my $m = Katsubushi::Converter::id_to_epoch_msec($c->{id});
    ok between($c->{epoch_msec}, $m, $c->{epoch_msec} + 1);

    my $id1 = Katsubushi::Converter::epoch_to_id($c->{epoch});
    ok between($id1, $c->{id}, $id1 + $ids_in_sec);

    my $id2 = Katsubushi::Converter::epoch_msec_to_id($c->{epoch_msec});
    ok between($id2, $c->{id}, $id2 + $ids_in_msec);
}

done_testing;
