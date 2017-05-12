use warnings;
use strict;

use Test::More 'no_plan';
use Digest::MurmurHash2::Neutral qw(murmur_hash2_neutral);

use constant { ITERATIONS => 1000 };

sub randstr {
    my ($len) = @_;
    my @chars = ("a".."z", 'A'..'Z', '0'..'9');
    my $buf = ""; 

    foreach (1..$len) {
        $buf .= $chars[rand @chars];
    }
    return $buf;
}

my ($test_str, $i);
my %results = ();

for ($i=0; $i<ITERATIONS; $i++) {
    $test_str = randstr(2048);
    $results{$test_str} = murmur_hash2_neutral($test_str); 
}

is(keys(%results), ITERATIONS, "Collision Found");

# Test for consistent result.
for my $key (keys %results) {
    is(murmur_hash2_neutral($key), $results{$key}, "Inconsistent Hash");
}
