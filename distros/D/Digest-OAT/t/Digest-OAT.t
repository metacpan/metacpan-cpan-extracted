use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('Digest::OAT', 'oat') };

my %hash_vals = ( key1 => 3203718188,
                  key2 => 2905880747,
                  key3 => 3682768199,
                  key4 => 3386175980,
                );

for (keys %hash_vals) {
    is( oat($_), $hash_vals{$_}, "Got back the right values from '$_', this is good.");
}



