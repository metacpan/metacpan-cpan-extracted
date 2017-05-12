use 5.006;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings;
use Test::Deep '!blessed';
use Test::Fatal;
binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use Hash::Ordered;

use constant HO => "Hash::Ordered";

my %hash;

tie %hash, HO;
isa_ok( tied(%hash), HO, "tied hash" );
ok( !scalar %hash, "scalar \%hash is false when empty" );

tie %hash, "Hash::Ordered", 'a' .. 'z';
isa_ok( tied(%hash), HO, "tied hash" );
ok( scalar %hash, "scalar \%hash is true when populated" );

cmp_deeply( [%hash], [ 'a' .. 'z' ], 'tied hash is order-preserving' );

$hash{'zz'} = 42;

cmp_deeply( [%hash], [ 'a' .. 'z', zz => 42 ], 'new keys append' );

is( $hash{'y'} = 23, 23, "setting returns value" );

cmp_deeply(
    [%hash],
    [ 'a' .. 'x', y => 23, zz => 42 ],
    'setting replaces original value'
);

ok( exists $hash{y}, "exists finds existing key" );
is( delete $hash{y}, 23, "deleting returns last value" );
ok( !exists $hash{y}, "exists doesn't find deleted key" );

done_testing;

# vim: ts=4 sts=4 sw=4 et tw=75:
