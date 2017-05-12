#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

BEGIN {
    use_ok('Benchmark', qw(timediff timestr timesum));
    use_ok('Geo::CEP', qw(memoize));
}

my $gc = Geo::CEP->new;
isa_ok($gc, 'Geo::CEP');
can_ok($gc, qw(find list));

my $benchmark = timediff(new Benchmark, new Benchmark);
isa_ok($benchmark, 'Benchmark');

my $list = $gc->list;

my $size = scalar keys %{$list};
is($size, 9608, 'database size');
diag("database has $size cities");

is($gc->find(0), undef, 'non-existent CEP');
is($gc->find(-1), undef, 'below valid CEP');
is($gc->find(999_999_999), undef, 'above valid CEP');

is_deeply(
    $gc->find(12420010),
    {
        cep_initial => 12400000,
        cep_final   => 12449999,
        city        => 'Pindamonhangaba',
        ddd         => 12,
        lat         => -22.9166667,
        lon         => -45.4666667,
        state       => 'SP',
        state_long  => join(' ', map { ucfirst lc } qw(SÃO PAULO)),
    },
    'CEP 12420010 w/Unicode',
);

my $i = 0;
srand 42;
while (my ($name, $row) = each %{$list}) {
    my $test = $row->{cep_initial} + int(rand($row->{cep_final} - $row->{cep_initial}));

    my $t0      = Benchmark->new;
    my $r       = $gc->find($test);
    my $t1      = Benchmark->new;
    $benchmark  = timesum($benchmark, timediff($t1, $t0));

    is(ref($r), 'HASH', 'found');
    next unless $r;

    is_deeply($row => $r, "CEP $test");
} continue {
    ++$i;
}

diag('benchmark: ' . timestr($benchmark));
diag(sprintf('speed: %0.2f queries/second', $i / ($benchmark->[1] + $benchmark->[2])));

done_testing(10 + ($i * 2));
