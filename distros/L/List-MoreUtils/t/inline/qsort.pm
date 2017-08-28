
use Test::More;
use Test::LMU;

plan skip_all => "It's insane to use a pure-perl qsort" unless $INC{'List/MoreUtils/XS.pm'};

my @ltn_asc = qw(2 3 5 7 11 13 17 19 23 29 31 37);
my @ltn_des = reverse @ltn_asc;
my @l;

@l = @ltn_des;
qsort sub { $a <=> $b }, @l;
is_deeply(\@l, \@ltn_asc, "sorted ascending");

@l = @ltn_asc;
qsort sub { $b <=> $a }, @l;
is_deeply(\@l, \@ltn_des, "sorted descending");

done_testing;
