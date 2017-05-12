use strict;
use warnings;

use Test::More;
use Test::LeakTrace;
use Hash::BulkKeyCopy qw(hash_bulk_keycopy);

local $SIG{__WARN__} = sub {};

my $h1_ka = ["k1_1","k1_2","k1_3"];
my $hs_ka = ["k2_1","k2_2","k2_3"];
my ($h1,$h2) = ({},{"k2_1"=>1,"k2_2"=>undef,"k2_3"=>[]});
no_leaks_ok {
    hash_bulk_keycopy($h1,$h2,$h1_ka,$hs_ka);
} 'no memory leaks';

done_testing;
