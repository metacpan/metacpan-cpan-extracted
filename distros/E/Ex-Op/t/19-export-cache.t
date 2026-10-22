#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Twin qw(imp fresh);

no strict 'refs';

{
    package EO::C1;
    use Ex::Op;
    our @EXPORT_OK = qw(one two);
    sub one { 1 } sub two { 2 } sub three { 3 } sub four { 4 } sub five { 5 }
}

is( imp('EO::C1', fresh(), 'one'), undef, 'first import builds the cache' );

push @EO::C1::EXPORT_OK, 'three';
is( imp('EO::C1', fresh(), 'three'), undef, 'a name pushed later is importable' );

$EO::C1::EXPORT_OK[0] = 'four';
is( imp('EO::C1', fresh(), 'four'), undef, 'a name changed in place is found on a miss' );

$EO::C1::EXPORT_OK[0] = 'five';
is( imp('EO::C1', fresh(), 'four'), undef, 'a name changed away is still in the cache, as with Exporter' );
is( imp('EO::C1', fresh(), 'five'), undef, 'the new name is found on a miss' );
like( imp('EO::C1', fresh(), 'four'), qr/^"four" is not exported/, '... and the miss rebuilt the cache' );

imp('EO::C1', fresh(), 'two');
$EO::C1::EXPORT_OK[1] = 'one';
is( imp('EO::C1', fresh(), 'two'), undef, 'a name removed in place is still accepted from the cache, as with Exporter' );
Ex::Op::reset_cache('EO::C1');
like( imp('EO::C1', fresh(), 'two'), qr/^"two" is not exported/, 'reset_cache forgets it' );

*EO::C1::EXPORT_OK = [qw(one)];
like( imp('EO::C1', fresh(), 'five'), qr/^"five" is not exported/, 'a replaced array is noticed' );

@EO::C1::EXPORT_OK = qw(one two three four);
my $p = fresh();
is( imp('EO::C1', $p, '/^t/'), undef, 'a pattern after the array grew' );
ok( defined &{"${p}::two"} && defined &{"${p}::three"}, '... sees the new names' );

Ex::Op::reset_cache();
is( imp('EO::C1', fresh(), 'four'), undef, 'reset_cache with no package clears every cache' );

done_testing;
