#!/usr/bin/env perl
use strict;
use warnings;
use JSON::YY ':doc';

my $doc = jdoc q({
    "config": {
        "host": "localhost",
        "port": 8080,
        "debug": false
    },
    "data": [[1,2,3],[4,5,6],[7,8,9]]
});

# iterate object keys
print "config keys:\n";
my $it = jiter $doc, "/config";
while (defined(my $val = jnext $it)) {
    my $key = jkey $it;
    printf "  %s = %s\n", $key, jencode $val, "";
}

# iterate array
print "\ndata rows:\n";
$it = jiter $doc, "/data";
while (defined(my $row = jnext $it)) {
    # nested iteration
    my $inner = jiter $row, "";
    my @nums;
    while (defined(my $n = jnext $inner)) {
        push @nums, jgetp $n, "";
    }
    printf "  [%s] sum=%d\n", join(",", @nums), eval { my $s; $s += $_ for @nums; $s };
}

# inspect without full decode
print "\ndata type: ", jtype $doc, "/data",     "\n";  # array
print "data len:  ",  jlen  $doc, "/data",     "\n";  # 3
print "row type:  ",  jtype $doc, "/data/0",   "\n";  # array
print "row len:   ",  jlen  $doc, "/data/0",   "\n";  # 3
