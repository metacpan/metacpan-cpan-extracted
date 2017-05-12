use strict;
use warnings;

use Test::More;
use Hash::BulkKeyCopy qw(hash_bulk_keycopy);

my $ht_ka = [];
my $hs_ka = ["k2_1","k2_2","k2_3"];

my ($h1,$h2) = ({},{"k2_1"=>1,"k2_2"=>undef,"k2_3"=>[]});
hash_bulk_keycopy($h1,$h2,$ht_ka,$hs_ka);

is_deeply $h1, {
    'k2_3' => [],
    'k2_1' => 1,
    'k2_2' => undef
};

done_testing;
