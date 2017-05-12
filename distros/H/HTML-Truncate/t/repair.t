use strict;
use warnings;
use Test::More tests => 14;
use HTML::Truncate;

my $cases = {
    1 => [ '<b><i>foobar</i></b>',
           '<b><i>foobar</i></b>'],
    2 => [ '<p><b><i>foobar</i></b></p>',
           '<p><b><i>foobar</i></b></p>'],
    3 => [ 'foo</i>bar',
           'foobar'],
    4 => [ '<b><i>foobar</b>',
           '<b><i>foobar</i></b>'],
    5 => [ '<b><i>foobar</b></i>',
           '<b><i>foobar</i></b>'],
    6 => [ '<b><u><i>foobar</b></i> quux',
           '<b><u><i>foobar</i></u></b> quux'],
    7 => [ '<p><b><u><i>foobar</b><hr /> quux</p>',
           '<p><b><u><i>foobar</i></u></b><hr /> quux</p>'],
    8 => [ '<p><b><u><i>foobar</b><br /> quux<br>.<br/>.</p>',
           '<p><b><u><i>foobar</i></u></b><br /> quux<br>.<br/>.</p>' ],
};

ok( my $ht = HTML::Truncate->new(), "HTML::Truncate->new()" );

isa_ok( $ht, 'HTML::Truncate' );

ok( !$ht->repair, '$ht->repair defaults properly' );

$ht->repair(1);

ok( $ht->repair, '$ht->repair(1)' );

$ht->repair();

ok( $ht->repair, 'No change' );

$ht->repair(0);

ok( !$ht->repair, '$ht->repair(0)' );

$ht->repair(1);

for my $key (sort keys %{$cases}) {
    is( $ht->truncate($cases->{$key}->[0]), $cases->{$key}->[1],
        "Repaired case $key");
}

1;
