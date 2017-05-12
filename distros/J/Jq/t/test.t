use Test::More;

use Jq;

my $got = jq '[.[] | "XXX " + .]', \@INC;
my $want = [map {"XXX " . $_} @INC];

is_deeply $got, $want, 'Basic jq filter works';

done_testing;
