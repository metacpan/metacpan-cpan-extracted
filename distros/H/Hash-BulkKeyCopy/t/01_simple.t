use strict;
use warnings;

use Test::More;
use Hash::BulkKeyCopy qw(hash_bulk_keycopy);

sub pp_hash_bulk_keycopy($$$$) {
    my ($h1,$h2,$ht_ka,$hs_ka) = @_; 
    my $a1len = scalar @$ht_ka;
    my $a2len = scalar @$hs_ka;
    return if ($a1len != $a2len || $a1len == 0); 
    for (0 .. $a1len-1) {
        my $k1 = $ht_ka->[$_];
        my $k2 = $hs_ka->[$_];
        my $v = $h2->{$k2};
        $h1->{$k1} = $v;
    }   
}

my $ht_ka = ["k1_1","k1_2","k1_3"];
my $hs_ka = ["k2_1","k2_2","k2_3"];

my ($h1,$h2) = ({},{"k2_1"=>1,"k2_2"=>undef,"k2_3"=>[]});
hash_bulk_keycopy($h1,$h2,$ht_ka,$hs_ka);
is_deeply $h1, {'k1_1' => 1,'k1_2' => undef,'k1_3' => []}, 'normal test';

my ($pp_h1,$pp_h2) = ({},{"k2_1"=>1,"k2_2"=>undef,"k2_3"=>[]});
pp_hash_bulk_keycopy($pp_h1,$pp_h2,$ht_ka,$hs_ka);

is_deeply $h1, $pp_h1;

($h1,$h2) = ({"otherkey"=>123},{"k2_1"=>1,"k2_2"=>undef,"k2_3"=>[]});
hash_bulk_keycopy($h1,$h2,$ht_ka,$hs_ka);
is_deeply $h1, {'k1_1' => 1,'k1_2' => undef,'k1_3' => [],'otherkey' => 123}, 'normal test 2';

($h1,$h2) = ({},{"k2_1"=>1,"k2_2"=>2,"k2_3"=>3});
hash_bulk_keycopy($h1,$h2,["k1_1","k1_2"],$hs_ka);
is_deeply $h1, {}, 'diff keys return test';

($h1,$h2) = ({},{});
hash_bulk_keycopy($h1,$h2,$ht_ka,$hs_ka);
is_deeply $h1, {}, 'empty test';

done_testing;
