use strict;
use warnings;
use Test::More;
use Math::Basic::XS qw/all/;

{ my $got = sum { $_ } (1.5, 2.25); is($got, 3.75, 'sum keeps decimals'); }
{ my $got = min { $_ } (2.5, 1.5, 3); is($got, 1.5, 'min keeps decimals'); }
{ my $got = max { $_ } (2.5, 3.75, 1); is($got, 3.75, 'max keeps decimals'); }
{ my $got = min { $_ } (-3, -7, 2); is($got, -7, 'min with negatives'); }
{ my $got = max { $_ } (-3, -7, -2); is($got, -2, 'max with only negatives'); }

{ my $got = median { $_ } (3, 1, 2); is($got, 2, 'median of three'); }
{ my $got = median { $_ } (7, 1, 5, 3, 6, 2, 4); is($got, 4, 'median of seven'); }
{ my $got = median { $_ } (6, 1, 5, 2, 4, 3); is($got, 4, 'median of six is the upper middle'); }
{ my $got = median { $_ } (9); is($got, 9, 'median of one'); }

{ my $got = sum { $_ } (); is($got, 0, 'sum of nothing'); }
{ my $got = min { $_ } (); is($got, undef, 'min of nothing'); }
{ my $got = max { $_ } (); is($got, undef, 'max of nothing'); }
{ my $got = mean { $_ } (); is($got, undef, 'mean of nothing'); }
{ my $got = median { $_ } (); is($got, undef, 'median of nothing'); }
{ my $got = mode { $_ } (); is($got, undef, 'mode of nothing'); }

{
	local $_ = 'outer';
	sum { $_ } 1, 2;
	median { $_ } 1, 2;
	is($_, 'outer', '$_ is restored');
}

my @values = (1, 2, 3);
sum { $_ *= 10 } @values;
is_deeply(\@values, [1, 2, 3], 'the block works on a copy');

my @big = (1 .. 20000);
{ my $got = sum { $_ } @big; is($got, 200010000, 'sum of a long list'); }
{ my $got = median { $_ } reverse @big; is($got, 10001, 'median of a long list'); }

{ my $got = sum { my @x = (1) x 500; $_ } 1, 2, 3; is($got, 6, 'a block that grows the stack'); }
{ my $got = median { my @x = (1) x 500; $_ } 5, 1, 3; is($got, 3, 'median with a block that grows the stack'); }

done_testing();
